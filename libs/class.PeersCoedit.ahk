; class PeersCoedit by Jimm Chen, 2024
;
; Two machines, via Samba share etc, can "co-operatively" edit the same doc-file
; (a pdf file for example). We do not break the file-open locking law, but 
; when mineside user wants to save the pdf, mineside AHK tells the peerside to close
; the pdf first; when mineside-saving done, mineside AHK tells the peerside to re-open
; the pdf. So it simulates the effect of editing the same pdf at the "same" time.
;
; This is quite suitable for a single-person workflow that operates on the same doc 
; via two different editing software in turn.
;
; == Terminology ==
; If at one timepoint, user launches doc-saving at sideA, then 
; sideA is called proactive-side. (PRO_xxx) 
; sideB is called passive-side.  (PAS_xxx)
;
; == Save-session detailed state migration ==
;   PRO_Start
;   PRO_WaitPeerClose     ->
;                                   PAS_DoMineClose
;                         <-        PAS_WaitPeerSave
;   PRO_DoMineSave
;   PRO_WaitPeerOpen      ->
;                                   PAS_DoMineOpen
;                         <-        PAS_Success
;   PRO_Success
;                                   (can be PAS_Fail)
;
; Some caveats on PeersCoedit implementation:
; * Try not to write a file constantly(once every second) when the system is idle.
;   Reading a file constantly is inevitable.
;

class PeersCoedit
{
	; static >>>
	static DEFAULT_TOS_CLOSEDOC := 3
	static DEFAULT_TOS_OPENDOC := 4
	static DEFAULT_TOS_SAVEDOC := 5
	; static <<<

	mineside := "" ; "sideA" or "sideB"
	
	state := "" ; "Syncing" -> Handshaked -> [A] ProSaving -> Handshaked
	;                                        [B] PasReload -> Handshaked
	
	timer := "" ; a BoundFunc object used to start/stop AHK timer
	
	tos_pas_closedoc := PeersCoedit.DEFAULT_TOS_CLOSEDOC
	tos_pas_opendoc := PeersCoedit.DEFAULT_TOS_OPENDOC
	tos_pro_savedoc := PeersCoedit.DEFAULT_TOS_SAVEDOC
	
	wtSyncStart := "" ; init with A_Now
	proseq := 0 ; mineside proactive sequence
	passeq := 0 ; mineside passive sequence

	docpath := ""
	
	peerdict := {}
	
	fndoc := {} ; Callables for real doc-operation.
	            ; keys: .syncsucc .savedoc .closedoc .opendoc .notify_ssstate
	;
	; Note: SSState: saved-session state (dstate, detailed-state)
	
	cancel_flag := false
	
	dbg(msg, lv) {
		AmDbg_output("PeersCoedit", msg, lv)
	}
	dbg0(msg) {
		this.dbg(msg, 0)
	}
	dbg1(msg) {
		this.dbg(msg, 1)
	}
	dbg2(msg) {
		; Dbg messages occurring in periodic timer use this level.
		this.dbg(msg, 2)
	}

	peerside[]
	{
		get {
			return this.mineside=="sideA" ? "sideB" : "sideA"
		}
	}
	
	mine_ini[]
	{
		get {
			return this.docpath "." this.mineside
		}
	}

	peer_ini[]
	{
		get {
			return this.docpath "." this.peerside
		}
	}

	IniReadPeer(key, default_val:=0)
	{
		return dev_IniRead(this.peer_ini, "cfg", key, default_val)
	}
	
	IniReadMine(key, default_val:=0)
	{
		return dev_IniRead(this.mine_ini, "cfg", key, default_val)
	}
	
	IniWriteMine(key, val)
	{
		return dev_IniWrite(this.mine_ini, "cfg", key, val)
	}

	SetMineProseq(newval)
	{
		this.proseq := newval
		this.IniWriteMine("proseq", newval)
	}

	SetMinePasseq(newval)
	{
		this.passeq := newval
		this.IniWriteMine("passeq", newval)
	}
	
	IniIncreaseVal(key, inc:=1)
	{
		val0 := this.IniReadMine(key)
		val1 := val0 + inc
		this.IniWriteMine(key, val1)
		return val1
	}
	
	WaitPeerIni(key, val, dstate, msec_start, msec_sub_start)
	{
		; Repeatedly check peer's ini, until we see `key=val` present, or see user-cancel.
		; If canceled, throw Exception.
		
		Loop
		{
			this.DoNotifySSState(dstate, msec_start, msec_sub_start)

			peerval := this.IniReadPeer(key)
;AmDbg0("In WaitPeerIni(), peerval=" peerval)
			if(peerval==val)
			{
				return true
			}
			else if(peerval==0)
			{
				throw Exception(Format("When in {}, peerside asserts failure.", dstate))
			}
			
			if(this.cancel_flag)
			{
				throw Exception(Format("You canceled {} before peerside responds.", dstate))
			}
			
			dev_Sleep(1000)
		}
	}
	
	SetTimeouts(opensecs, savesecs, closesecs:=0)
	{
		this.tos_pas_opendoc := opensecs>0 ? opensecs : PeersCoedit.DEFAULT_TOS_OPENDOC
		
		this.tos_pro_savedoc := savesecs>0 ? savesecs : PeersCoedit.DEFAULT_TOS_SAVEDOC

		this.tos_pas_closedoc := closesecs>0 ? closesecs : PeersCoedit.DEFAULT_TOS_CLOSEDOC
	}

	; User API:
	Activate(which_side, docpath, dict_fndoc)
	{
		if(which_side=="sideA" or which_side=="A") {
			this.mineside := "sideA"
		}
		else if(which_side=="sideB" or which_side=="B") {
			this.mineside := "sideB"
		}
		else {
			throw Exception("which_side given wrong value, should be ""sideA"" or ""sideB"".")
		}

		this.docpath := docpath
		
		this.ResetSyncState()
		
		this.fndoc := dict_fndoc
		dev_assert(this.fndoc.savedoc)
		dev_assert(this.fndoc.closedoc)
		dev_assert(this.fndoc.opendoc)
		
		this.timer := Func("PeersCoedit.RootTimerCallback").Bind(this) ; a BoundFunc object
		dev_StartTimerPeriodic(this.timer, 1000, true)
	}
	
	; User API:
	Deactivate()
	{
		this.dbg2(Format("{} Deactivate().", this.mineside))
	
		dev_StopTimer(this.timer)
		this.timer := ""
		
		this.minside := ""
		this.docpath := ""
		
		this.fndoc := ""
	}
	
	; User API:
	ResetSyncState()
	{
		this.wtSyncStart := dev_walltime_now()

		this.dbg1(Format("{} Start syncing()... at {}"
			, this.mineside, this.wtSyncStart))
	
		this.proseq := 0
		this.passeq := 0
		this.state := "Syncing"
		
		dev_IniWriteSectionVA(this.mine_ini, "cfg"
			, "proseq=0"
			, "passeq=0"
			, "SyncStart=" this.wtSyncStart
			, "SyncSucc=" )
	}

	RootTimerCallback()
	{
;		AmDbg0("RootTimerCallback... " this.mineside) ; debug

		this.peerdict := dev_IniReadSectionIntoDict(this.peer_ini, "cfg")
		; -- This is useful, FoxitCoedit's "editing conflict detection" requires
		;    us to know peer's state constantly.

		if(this.state=="Syncing")
		{
			this.SyncTimerCallback()
			; todo? If false(INI write fail etc), then deactivate.
		}
		else if(this.state=="Handshaked")
		{
			is_succ := this.MonitorTimerCallback()
;			if(not is_succ)
;				this.ResetSyncState()
		}
	}
	
	SyncTimerCallback()
	{
		is_succ := false
		
		this.dbg2(Format("[{}.Syncing] Now peer state:`n"
			. "    proseq={}"
			. "    passeq={}"
			. "    SyncStart={}"
			. "    SyncSucc={}"
			, this.mineside
			, this.peerdict.proseq
			, this.peerdict.passeq
			, this.peerdict.SyncStart
			, this.peerdict.SyncSucc))
		
		peer_start_diff := dev_walltime_elapsec(this.wtSyncStart, this.peerdict.SyncStart)
		peer_succ_diff  := dev_walltime_elapsec(this.wtSyncStart, this.peerdict.SyncSucc)
		
		if(peer_start_diff>=0)
		{
			is_succ := true

			; tell the peer we are success.
			this.IniWriteMine("SyncSucc", this.peerdict.SyncStart)

			this.dbg1(Format("Sync SUCCESS. Peer-start is ahead of our-start +{} seconds", peer_start_diff))
		}
		else if(peer_succ_diff>=0)
		{
			is_succ := true

			; tell the peer we are success.
			this.IniWriteMine("SyncSucc", this.peerdict.SyncSucc)

			this.dbg1(Format("Sync SUCCESS. Peer-success is ahead of our-success +{} seconds", peer_succ_diff))
		}
		else
		{
			this.dbg2(Format("Still waiting for peer. Peer is behind our-start {} seconds", peer_start_diff))
		}
	
		if(is_succ)
		{
			; We start from 2, bcz 0 is used to indicate "failure".
			this.SetMineProseq(2)
			this.SetMinePasseq(2)
			
			this.state := "Handshaked"
			this.fndoc.syncsucc.()
		}
	}
	

	LaunchSaveDocSession(byref is_conn_lost, byref ret_errmsg)
	{
		this.cancel_flag := false
		is_conn_lost := false
		ret_errmsg := ""
	
		if(this.state!="Handshaked")
		{
			this.dbg1(Format("PeersCoedit.LaunchSaveDocSession() called with state={}, ignore it.", this.state))
			return false
		}

		dev_assert(this.state=="Handshaked")
	
		try 
		{
			msec_start := dev_GetTickCount64()
			msec_sub_start := msec_start
			
			this.state := "ProSaving"
			this.dbg1(Format("Start saving session ... (proseq={})", this.proseq))
			this.DoNotifySSState("PRO_Start", msec_start, msec_sub_start)
			
			nowseq := this.IniReadMine("proseq")
			dev_assert(this.proseq==nowseq)
		
			this.IniIncreaseVal("proseq")
			
			this.dbg1(Format("Waiting peerside close doc..."))
			msec_sub_start := dev_GetTickCount64()

			this.WaitPeerIni("passeq", this.proseq+1, "PRO_WaitPeerClose", msec_start, msec_sub_start)

			this.dbg1("Waiting peerside close doc, success.")
			
			this.dbg1("Now saving mineside doc...")
			msec_sub_start := dev_GetTickCount64()
			this.DoNotifySSState("PRO_DoMineSave", msec_start, msec_sub_start)
			;
			this.fndoc.savedoc.() ; throw on error 
			;
			this.dbg1("Done saving mineside doc.")
			
			this.IniIncreaseVal("proseq")
			
			this.dbg1("Waiting peerside reopen doc...")
			msec_sub_start := dev_GetTickCount64()
			
			this.WaitPeerIni("passeq", this.proseq+2, "PRO_WaitPeerOpen", msec_start, msec_sub_start)

			this.dbg1("Waiting peerside reopen doc, success.")

			this.dbg1(Format("Done saving session. (proseq={})", this.proseq+2))
			
			this.proseq += 2
			
			msec_end := dev_GetTickCount64()
			this.dbg1(Format("Done saving session. (proseq={}) [time cost: {:.1f}s]"
				, this.proseq, (msec_end-msec_start)/1000))

			this.DoNotifySSState("PRO_Success", msec_start, msec_end)

			this.state := "Handshaked"
			return true
		}
		catch e 
		{
			this.state := "Handshaked" ; so that it is not "ProSaving"
		
			ret_errmsg := e.Message
			this.dbg1("LaunchSaveDocSession() got exception:`n" . dev_fileline_syse(e))
			
			is_conn_lost := true
			return false
		}
	}
	
	MonitorTimerCallback()
	{
;		AmDbg0("---- MonitorTimerCallback() ...")

		if(this.state=="ProSaving")
			return true

		dev_assert(this.state=="Handshaked")
		
		try
		{
			this.cancel_flag := false
			
			if(this.passeq==0)
			{
;AmDbg0("MonitorTimerCallback(): this.passeq==0")
				return false
			}
			
			peer_proseq := this.IniReadPeer("proseq")
			peer_passeq := this.IniReadPeer("passeq")
			
			if(peer_passeq==0)
			{
;AmDbg0("MonitorTimerCallback(): peer_passeq==0")
				return false ; peer has gone wrong, nothing to do
			}
			
			if(peer_proseq==this.passeq)
			{
				return true ; peer is silent, nothing to do
			}
			
			if(peer_proseq != this.passeq+1)
			{
				throw Exception(Format("Peer proseq out of sync! (Mine:{} , Peer:{})", this.passeq, peer_proseq))
			}
			
			msec_start := dev_GetTickCount64()
			msec_sub_start := msec_start
			
			this.state := "PasReload"
			
			this.dbg1(Format("Mineside is alerted to relinquish doc. (passeq={})", this.passeq))
			
			dev_assert(peer_proseq == this.passeq+1)
			
			this.dbg1("Now closing doc...")
			this.DoNotifySSState("PAS_DoMineClose", msec_start, msec_sub_start)
			this.fndoc.closedoc.() ; throw on error 
			this.dbg1("Done closing doc.")
			
			this.IniIncreaseVal("passeq")
			
			this.dbg1("Waiting peer's writing doc...")
			msec_sub_start := dev_GetTickCount64()
			;
			this.WaitPeerIni("proseq", this.passeq+2, "PAS_WaitPeerSave", msec_start, msec_sub_start)

			this.dbg1("Waiting peer's writing doc, success.")
			
			this.dbg1("Now re-opening doc...")
			msec_sub_start := dev_GetTickCount64()
			this.DoNotifySSState("PAS_DoMineOpen", msec_start, msec_sub_start)
			this.fndoc.opendoc.() ; throw on error 
			this.dbg1("Done re-opening doc...")
			
			this.IniIncreaseVal("passeq")
			this.passeq += 2
			
			msec_end := dev_GetTickCount64()
			this.dbg1(Format("Mineside just refreshed the doc. (passeq={}) [time cost: {:.1f}s]"
				, this.passeq, (msec_end-msec_start)/1000))
			
			this.DoNotifySSState("PAS_Success", msec_start, msec_end)
			
			this.state := "Handshaked"
			
			return true
		}
		catch e 
		{
			msec_end := dev_GetTickCount64()
			this.dbg1("MonitorTimerCallback() got exception:`n" . dev_fileline_syse(e))
			
			this.DoNotifySSState("PAS_Fail", msec_start, msec_end, e.Message) 
			; -- Here, we pass extra e.Message to outer-layer.
			
			this.state := "Handshaked" ; so that it is not "PasReload"
			return false
		}
	}
	
	DoNotifySSState(dstate, msec_start, msec_sub_start, errmsg:="")
	{
		; dstate: detailed-state
		; errmsg is only for PAS_Fail
		
		msec_now := dev_GetTickCount64()
		
		start_secs := (msec_now - msec_start) // 1000
		; -- total seconds since saving-session starts.
		
		sub_start_secs := (msec_now - msec_sub_start) // 1000
		; -- seconds since current PRO_/PAS_ state starts.
		
		this.fndoc.notify_ssstate.(start_secs, dstate, sub_start_secs, errmsg)
	}

	IsInSavingSession() ; FoxitCoedit calls this to query my state
	{
		if(this.state=="ProSaving" or this.state=="PasReload")
			return true
		else
			return false
	}
	
	CancelSavingSession()
	{
		this.cancel_flag := true
	}
}

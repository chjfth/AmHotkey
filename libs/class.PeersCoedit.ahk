
; Two machines, via Samba share etc, can "co-operatively" edit the same doc-file
; (a doc file for example). We do not break the file-open locking law, but 
; when self-side AHK detects that sideA wants to save the doc, AHK tells the peer-side
; to close the doc first; when self-side saving done, AHK tell the peer-side 
; to open the doc again. So it simulates that edit the same doc at the "same" time.
; This is quite suitable for a single-person workflow that operates on the same doc 
; via two different editing software in turn.
;
; Some cavets on PeersCoedit
; * Try not to write a file constantly(once every second) when the system is idle.
;   Reading a file constantly is invevitable.

class PeersCoedit
{
	mineside := "" ; "sideA" or "sideB"
	
	state := "" ; "Syncing" -> Handshaked -> [A] ProSaving  -> Handshaked
	;                                        [B] PasReload -> Handshaked
	
	timer := "" ; a BoundFunc object used to start/stop AHK timer
	
	tos_pas_closedoc := 3 ; timeout-seconds saving doc
	tos_pas_opendoc := 3
	tos_pro_savedoc := 5
	
	wtSyncStart := "" ; init with A_Now
	proseq := 0 ; mineside proactive sequence
	passeq := 0 ; mineside passive sequence

	docpath := ""
	
	peerdict := {}
	
	fndoc := {} ; Callables for real doc-operation.
	            ; keys: .syncsucc .savedoc .closedoc .opendoc
	
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

	IniIncreaseVal(key, inc:=1)
	{
		val0 := this.IniReadMine(key)
		val1 := val0 + inc
		this.IniWriteMine(key, val1)
		return val1
	}
	
	WaitPeerIni(key, val, wait_seconds:=5)
	{
		; Repeatedly check peer's ini, until we see `key=val` present.
		; return true if see desired, false if timeout.
		
		end_tick := dev_GetTickCount64() + wait_seconds*1000
		Loop
		{
			peerval := this.IniReadPeer(key)
			if(val==peerval)
				return true
			
			if(dev_GetTickCount64() > end_tick)
				return false
			
			dev_Sleep(1000)
		}
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
		this.dbg1(Format("{} Start syncing()... at {}"
			, this.mineside, this.wtSyncStart))
	
		this.wtSyncStart := dev_walltime_now()
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
			; todo : If false(INI write fail etc), then deactivate,
		}
		else if(this.state=="Handshaked")
		{
			is_succ := this.MonitorTimerCallback()
			if(not is_succ)
				this.ResetSyncState()
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
			this.state := "Handshaked"
			this.fndoc.syncsucc.()
		}
	}
	

	LaunchSaveDocSession(byref is_conn_lost)
	{
		is_conn_lost := false
	
		if(this.state!="Handshaked")
		{
			this.dbg1(Format("PeersCoedit.LaunchSaveDocSession() called with state={}, ignore it.", this.state))
			return false
		}

		dev_assert(this.state=="Handshaked")
	
		try 
		{
			this.state := "ProSaving"
			this.dbg1(Format("Start saving session ... (proseq={})", this.proseq))
			
			nowseq := this.IniReadMine("proseq")
			dev_assert(this.proseq==nowseq)
		
			this.IniIncreaseVal("proseq")
			
			this.dbg2(Format("Waiting peerside to close doc..."))
			
			is_succ := this.WaitPeerIni("passeq", this.proseq+1)
			if(not is_succ)
			{
				throw Exception(Format("Peerside(close-doc) no response after {} seconds", this.tos_pas_closedoc))
			}

			this.dbg2("Waiting peerside to close doc, success.")
			
			this.dbg2("Now saving doc...")
			this.fndoc.savedoc.() ; throw on error 
			this.dbg2("Done saving doc.")
			
			this.IniIncreaseVal("proseq")
			
			this.dbg2("Waiting peerside to reopen doc...")
			
			is_succ := this.WaitPeerIni("passeq", this.proseq+2)
			if(not is_succ)
			{
				throw Exception(Format("Peerside(open-doc) no response after {} seconds", this.tos_pas_opendoc))
			}

			this.dbg2("Waiting peerside to reopen doc, success.")

			this.dbg1(Format("Saving doc SUCCESS. (proseq={})", this.proseq+2))
			
			this.proseq += 2
			this.dbg1(Format("Done saving session. (proseq={})", this.proseq))

			this.state := "Handshaked"
			
			return true
		}
		catch e 
		{
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
			peer_proseq := this.IniReadPeer("proseq")
			if(peer_proseq == this.passeq)
				return true ; peer is silent, nothing to do
			
			if(peer_proseq != this.passeq+1)
			{
				throw Exception(Format("Peer proseq out of sync! (Mine:{} , Peer:{})", this.passeq, peer_proseq))
			}
			
			this.state := "PasReload"
			
			this.dbg1(Format("Mineside is alerted to relinquish doc. (passeq={})", this.passeq))
			
			dev_assert(peer_proseq == this.passeq+1)
			
			this.dbg2("Now closing doc...")
			this.fndoc.closedoc.() ; throw on error 
			this.dbg2("Done closing doc.")
			
			this.IniIncreaseVal("passeq")
			
			this.dbg2("Waiting peer's writing doc...")
			
			is_succ := this.WaitPeerIni("proseq", this.passeq+2)
			if(not is_succ)
			{
				throw Exception(Format("Peerside(save-doc) no response after {} seconds", this.tos_pro_savedoc))
			}

			this.dbg2("Waiting peer's writing doc, success.")
			
			this.dbg2("Now re-opening doc...")
			this.fndoc.opendoc.() ; throw on error 
			this.dbg2("Done re-opening doc...")
			
			this.IniIncreaseVal("passeq")
			this.passeq += 2
			
			this.dbg1(Format("Mineside just refreshed the doc. (passeq={})", this.passeq))

			this.state := "Handshaked"
			
			return true
		}
		catch e 
		{
			this.dbg1("MonitorTimerCallback() got exception:`n" . dev_fileline_syse(e))
			
			return false
		}
	}

}
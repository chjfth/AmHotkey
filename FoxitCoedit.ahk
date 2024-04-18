AUTOEXEC_FoxitCoedit: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.
; -- naming: Foxit PDF reader/editor from two machines, co-operatively edit the same PDF file

/* APIs:

*/

;;;;;;;; Foco global vars ;;;;;;;;;;

global g_foco ; The single object responsible for the Foco GUI
global FoxitCoedit_Id := "FoxitCoedit"

global g_HwndFOCOGui

global gu_focoBtnSavePdf
global gu_focoBtnSync
global gu_focoBtnTest
global gu_focoMleInfo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include %A_LineFile%\..\pdfreader.ahk


class FoxitCoedit
{
	; static vars as constant
	
	isGuiVisible := false
	
	pdfpath := ""
	mineside := "" ; "sideA" or "sideB"
	
	state := "" ; "Syncing" -> Monitoring -> [A] ProSaving  -> Monitoring
	;                                        [B] PasLoading -> Monitoring
	
	timer := "" ; a BoundFunc object used to start/stop AHK timer
	
	tos_pas_closepdf := 3 ; timeout-seconds saving pdf
	tos_pas_openpdf := 3
	tos_pro_savepdf := 5
	
	wtSyncStart := "" ; A_Now
	proseq := 0 ; mineside proactive sequence
	passeq := 0 ; mineside passive sequence
	
	dbg(msg, lv) {
		AmDbg_output(FoxitCoedit_Id, msg, lv)
	}
	dbg0(msg) {
		FoxitCoedit.dbg(msg, 0)
	}
	dbg1(msg) {
		FoxitCoedit.dbg(msg, 1)
	}
	dbg2(msg) {
		FoxitCoedit.dbg(msg, 2)
	}

	Activate(which_side, pdfpath)
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

		this.pdfpath := pdfpath
		
		this.ResetSyncState()
		
		this.timer := Func("FoxitCoedit.RootTimerCallback").Bind(this) ; a BoundFunc object
		dev_StartTimerPeriodic(this.timer, 1000, true)
	}
	
	Deactivate()
	{
		dev_StopTimer(this.timer)
		this.timer := ""
		
		this.minside := ""
		this.pdfpath := ""
	}
	
	ResetSyncState()
	{
		this.dbg1(Format("{} Start syncing()... at {}"
			, this.mineside, this.wtSyncStart))
	
		this.wtSyncStart := dev_walltime_now()
		this.state := "Syncing"
		dev_IniWriteSectionVA(this.mine_ini, "cfg"
			, "proseq=0"
			, "passeq=0"
			, "SyncStart=" this.wtSyncStart
			, "SyncSucc=" )
		
	}

	CreateGui()
	{
		GuiName := "FOCO"
		
		Gui_New(GuiName)
		Gui_ChangeOpt(GuiName, "+Resize +MinSize")
		Gui_AssociateHwndVarname(GuiName, "g_HwndFOCOGui")
		
		fullwidth := 500
		Gui_Add_Button(  GuiName, "gu_focoBtnSavePdf",  120, "xm " gui_g("Foco_OnBtnSavePdf"), "Save &pdf")
		Gui_Add_Button(  GuiName, "gu_focoBtnSync",  50, "x+10 " gui_g("Foco_OnBtnSync"), "&Sync")
		Gui_Add_Button(  GuiName, "gu_focoBtnTest",  50, "x+10 " gui_g("Foco_OnBtnTest"), "&Test")
		Gui_Add_Editbox( GuiName, "gu_focoMleInfo", fullwidth, "xm r10" , "...")
	}

	ShowGui()
	{
		GuiName := "FOCO"
		if(this.isGuiVisible)
			return ; already shown
		
		if(!g_HwndFOCOGui) {
			this.CreateGui()
		}
		
		Gui_Show(GuiName, "AutoSize", "FOCO")
		
		this.isGuiVisible := true
	}
	
	HideGui()
	{
		Gui_Hide("FOCO")
		this.isGuiVisible := false
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
			return this.pdfpath "." this.mineside
		}
	}

	peer_ini[]
	{
		get {
			return this.pdfpath "." this.peerside
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
			
			Sleep, 1000
		}
	}

	OnBtnSync()
	{
		AmDbg0("Force ResetSyncState()")
		this.ResetSyncState()
	}
	
	RootTimerCallback()
	{
;		AmDbg0("RootTimerCallback... " this.mineside)
		if(this.state=="Syncing")
		{
			this.SyncTimerCallback()
			; todo : If false(INI write fail), then deactivate,
		}
		else if(this.state=="Monitoring")
		{
			is_succ := this.MonitorTimerCallback()
			if(not is_succ)
				this.ResetSyncState()
		}
	}
	
	SyncTimerCallback()
	{
		is_succ := false
		
		peer := dev_IniReadSectionIntoDict(this.peer_ini, "cfg")
		this.dbg2(Format("[{}.Syncing] Now peer state:`n"
			. "    proseq={}"
			. "    passeq={}"
			. "    SyncStart={}"
			. "    SyncSucc={}"
			, this.mineside
			, peer.proseq
			, peer.passeq
			, peer.SyncStart
			, peer.SyncSucc))
		
		peer_start_diff := dev_walltime_elapsec(this.wtSyncStart, peer.SyncStart)
		peer_succ_diff  := dev_walltime_elapsec(this.wtSyncStart, peer.SyncSucc)
		
		
		if(peer_start_diff>=0)
		{
			is_succ := true

			; tell the peer we are success.
			this.IniWriteMine("SyncSucc", peer.SyncStart)

			this.dbg1(Format("Sync SUCCESS. Peer-start is ahead of our-start +{} seconds", peer_start_diff))
		}
		else if(peer_succ_diff>=0)
		{
			is_succ := true

			; tell the peer we are success.
			this.IniWriteMine("SyncSucc", peer.SyncSucc)

			this.dbg1(Format("Sync SUCCESS. Peer-success is ahead of our-success +{} seconds", peer_succ_diff))
		}
		else
		{
			this.dbg2(Format("Still waiting for peer. Peer is behind our-start {} seconds", peer_start_diff))
		}
	
		if(is_succ)
		{
			; tell the peer we are success.
			; this.IniWriteMine("SyncSucc", dev_walltime_now()) ; moved above
		
			this.state := "Monitoring"
		
;			GuiControl_Enable(GuiName, "gu_focoBtnSync")
			
;			this.dbg2("Start timer for FoxitCoedit.MonitorTimerCallback().")
;			dev_StartTimerPeriodicEx(1000, true, "FoxitCoedit.MonitorTimerCallback", this)
		}
	}
	
	OnBtnSavePdf()
	{
		GuiName := "FOCO"
;		GuiControl_Disable(GuiName, "gu_focoBtnSavePdf")

		is_succ := this.LaunchSavePdfSession()
		
		if(is_succ)
		{
			; todo : UI update
		}
		else
		{
			this.ResetSyncState()
			dev_MsgBoxWarning("Peer connection lost. Will resync now.")
			
		}
	}
	
	LaunchSavePdfSession()
	{
		; todo: If it is in Syncing state, refuse to do.

		if(this.state=="PasLoading")
			return false

		dev_assert(this.state=="Monitoring")
	
		try 
		{
			this.state := "ProSaving"
			this.dbg1(Format("Start saving session ... (proseq={})", this.proseq))
			
			nowseq := this.IniReadMine("proseq")
			dev_assert(this.proseq==nowseq)
		
			this.IniIncreaseVal("proseq")
			
			this.dbg2(Format("Waiting peerside to close pdf..."))
			
			is_succ := this.WaitPeerIni("passeq", this.proseq+1)
			if(not is_succ)
			{
				throw Exception(Format("Peerside(close-pdf) no response after {} seconds", this.tos_pas_closepdf))
			}

			this.dbg2("Waiting peerside to close pdf, success.")
			
			this.dbg2("Now writing pdf...")
			Sleep, 2000
			this.dbg2("Done writing pdf.")
			
			this.IniIncreaseVal("proseq")
			
			this.dbg2("Waiting peerside to reopen pdf...")
			
			is_succ := this.WaitPeerIni("passeq", this.proseq+2)
			if(not is_succ)
			{
				throw Exception(Format("Peerside(open-pdf) no response after {} seconds", this.tos_pas_openpdf))
			}

			this.dbg2("Waiting peerside to reopen pdf, success.")

			this.dbg1(Format("Saving pdf SUCCESS. (proseq={})", this.proseq+2))
			
			this.proseq += 2
			this.dbg1(Format("Done saving session. (proseq={})", this.proseq))

			this.state := "Monitoring"
			
			return true
		}
		catch e 
		{
			this.dbg1("OnBtnSavePdf() got exception:`n" . dev_fileline_syse(e))
			this.ResetState()
			return false
		}
	}
	
	MonitorTimerCallback()
	{
;		AmDbg0("---- MonitorTimerCallback() ...")

		if(this.state=="ProSaving")
			return true

		dev_assert(this.state=="Monitoring")
		
		try
		{
			peer_proseq := this.IniReadPeer("proseq")
			if(peer_proseq == this.passeq)
				return true ; peer is silent, nothing to do
			
			if(peer_proseq != this.passeq+1)
			{
				throw Exception(Format("Peer proseq out of sync! (Mine:{} , Peer:{})", this.passeq, peer_proseq))
			}
			
			this.state := "PasLoading"
			
			this.dbg1(Format("Mineside is alerted to relinquish pdf. (passeq={})", this.passeq))
			
			dev_assert(peer_proseq == this.passeq+1)
			
			this.dbg2("Now closing pdf...")
			Sleep, 2000
			this.dbg2("Done closing pdf.")
			
			this.IniIncreaseVal("passeq")
			
			this.dbg2("Waiting peer's writing pdf...")
			
			is_succ := this.WaitPeerIni("proseq", this.passeq+2)
			if(not is_succ)
			{
				throw Exception(Format("Peerside(save-pdf) no response after {} seconds", this.tos_pro_savepdf))
			}

			this.dbg2("Waiting peer's writing pdf, success.")
			
			this.dbg2("Now re-opening pdf...")
			Sleep, 2000
			this.dbg2("Done re-opening pdf...")
			
			this.IniIncreaseVal("passeq")
			this.passeq += 2
			
			this.dbg1(Format("Mineside just refreshed the pdf. (passeq={})", this.passeq))

			this.state := "Monitoring"
			
			return true
		}
		catch e 
		{
			this.dbg1("MonitorTimerCallback() got exception:`n" . dev_fileline_syse(e))
			this.ResetState()
			
			return false
		}
	}
	
	ResetState() ; todo : Deprecate
	{
		; Restart syncing timer. 
		;
		; dev_StopTimer() // not suitable for proactive side
	}
	
	OnBtnTest()
	{
		; ------ dev_StopTimer()
		dev_StartTimerPeriodicEx(1000, true, "FoxitCoedit.TestTimerCallback", this)
	}
	
	TestTimerCallback()
	{
		static si := 0
		
		now_si := si
		si++
		
		AmDbg0(Format("[#now_si={}] enter <{}>", now_si, p1))

		Sleep, 2000

		AmDbg0(Format("[#now_si={}] leave <{}>", now_si, p1))
		
		if(now_si==3)
		{
			dev_StopTimer()
			si := 0
		}
	}

} ; class FoxitCoedit


FoxitCoedit_Init(which_side, pdfpath)
{
	g_foco := new FoxitCoedit()
	g_foco.Activate(which_side, pdfpath)
}

FoxitCoedit_Deactivate()
{
	AmDbg0("FoxitCoedit_Deactivate()")
	g_foco.Deactivate()
}

#!y:: FoxitCoedit_Deactivate()


FoxitCoedit_LaunchUI()
{
	if(!g_foco)
	{
		dev_MsgBoxError("FoxitCoedit_Init() not called yet!")
		;dev_assert(g_foco, "FoxitCoedit class instance creation fail!")
	}

	g_foco.ShowGui()
}

Foco_OnBtnSavePdf()
{
	g_foco.OnBtnSavePdf()
}

Foco_OnBtnSync()
{
	g_foco.OnBtnSync()
}

foco_SyncTimerCallback()
{
	g_foco.SyncTimerCallback()
}


Foco_OnBtnTest()
{
	g_foco.OnBtnTest()
}

FOCOGuiSize()
{
	rsdict := {}
	rsdict.gu_focoMleInfo := JUL.LeftTop_DynWidthHeight
	
	dev_GuiAutoResize("FOCO", rsdict, A_GuiWidth, A_GuiHeight)
}

FOCOGuiClose()
{
	g_foco.HideGui()
}

FOCOGuiEscape()
{
	g_foco.HideGui()
}



/*
FOCO_OnBtnOK()
{
	g_foco.OnBtnOK()
}

*/

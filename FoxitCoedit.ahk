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
global gu_focoMleInfo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include %A_LineFile%\..\pdfreader.ahk


class FoxitCoedit
{
	; static vars as constant
	
	isGuiVisible := false
	
	imine := -1 ; 0 or 1
	ipeer := -1
	
	pdfpath := ""
	
	sides_info := [] ; only two elements [0] for sideA , [1] for sideB
	
	state := "Syncing"
	
	wtSyncStart := "" ; A_Now
	
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

	__New(which_side, pdfpath)
	{
		if(which_side=="A") {
			this.imine := 0
			this.ipeer := 1
		}
		else if(which_side=="B") {
			this.imine := 1
			this.ipeer := 0
		}
		else {
			throw Exception("which_side given wrong value, should be ""A"" or ""B"".")
		}
		
		this.pdfpath := pdfpath
	}

	CreateGui()
	{
		GuiName := "FOCO"
		
		Gui_New(GuiName)
		Gui_ChangeOpt(GuiName, "+Resize +MinSize")
		Gui_AssociateHwndVarname(GuiName, "g_HwndFOCOGui")
		
		fullwidth := 500
		Gui_Add_Button(  GuiName, "gu_focoBtnSavePdf",  120, "xm " gui_g("Foco_OnBtnSavePdf"), "&Save pdf")
		Gui_Add_Button(  GuiName, "gu_focoBtnSync",  50, "x+10 " gui_g("Foco_OnBtnSync"), "&Sync")
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

	mineside[]
	{
		get {
			return this.imine==0 ? "sideA" : "sideB"
		}
	}

	peerside[]
	{
		get {
			return this.imine==0 ? "sideB" : "sideA"
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
		GuiName := "FOCO"
		this.wtSyncStart := dev_walltime_now()

		this.dbg1(Format("{} Sync start at {}"
			, this.mineside, this.wtSyncStart))
	
		dev_IniWriteSectionVA(this.mine_ini, "cfg"
			, "proseq=0"
			, "passeq=0"
			, "SyncStart=" this.wtSyncStart
			, "SyncSucc=" )
		
		dev_StartTimerPeriodic("foco_SyncTimerCallback", 1000, true) ;zzz
		
		GuiControl_Disable(GuiName, "gu_focoBtnSync")
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
			this.dbg1(Format("Sync SUCCESS. Peer-start is ahead of our-start +{} seconds", peer_start_diff))
		}
		else if(peer_succ_diff>=0)
		{
			is_succ := true
			this.dbg1(Format("Sync SUCCESS. Peer-success is ahead of our-success +{} seconds", peer_succ_diff))
		}
		else
		{
			this.dbg2(Format("Still waiting for peer. Peer is behind our-start {} seconds", peer_start_diff))
		}
	
		if(is_succ)
		{	; tell the peer we are success.
			this.IniWriteMine("SyncSucc", dev_walltime_now())
			dev_StopTimer("foco_SyncTimerCallback")
		
			GuiControl_Enable(GuiName, "gu_focoBtnSync")
			
			;dev_StartTimerPeriodic("foco_MonitorPeerPdf", 1000, true)
		}
	}
	
	OnBtnSavePdf()
	{
		GuiName := "FOCO"
		GuiControl_Disable(GuiName, "gu_focoBtnSavePdf")

		try 
		{
			proseq := this.IniReadMine("proseq")
			this.dbg1(Format("Start saving pdf ... (proseq={})", proseq))
		
			proseq_plus1 := this.IniIncreaseVal("proseq")
			
			; Wait for peer's closing pdf
			this.WaitPeerIni("passeq", proseq_plus1)
			
			this.dbg2("Simu saving pdf...")
			Sleep, 2000
			this.dbg2("Simu saving pdf Done...")
			
			proseq_plus2 := this.IniIncreaseVal("proseq")
			
			; Wait for peer's re-opening pdf
			this.WaitPeerIni("passeq", proseq_plus2)

			this.dbg1(Format("Saving pdf SUCCESS (proseq={})", proseq_plus2))
		}
		catch e 
		{
			this.dbg1("OnBtnSavePdf got exception:`n" e.Message)
		}
		
		
		GuiControl_Enable(GuiName, "gu_focoBtnSavePdf")
	}
	
	MonitorPeerPdf()
	{
	
	}

} ; class FoxitCoedit


FoxitCoedit_Init(which_side, pdfpath)
{
	g_foco := new FoxitCoedit(which_side, pdfpath)
}

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
FOCO_OnEditChange()
{
	g_foco.OnEditChange()
}

FOCO_OnBtnOK()
{
	g_foco.OnBtnOK()
}


FOCO_WM_KEYDOWN(wParam, lParam, msg, hwnd)
{
	g_foco.On_WM_KEYDOWN(wParam, lParam, msg, hwnd)
}

FOCO_OnCkbRecent()
{
	g_foco.OnCkbRecent()
}

FOCO_OnBtnCopyTag()
{
	g_foco.OnBtnCopyTag()
}

FOCO_OnBtnChgDesc()
{
	g_foco.OnBtnChgDesc()
}


Everlink_Clipmon()
{
	g_foco.ClipmonCallback()
}

*/

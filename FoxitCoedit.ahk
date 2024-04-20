AUTOEXEC_FoxitCoedit: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.
; -- naming: Foxit PDF reader/editor from two machines, co-operatively edit the same PDF file

/* APIs:
FoxitCoedit_LaunchUI()

*/

;;;;;;;; Foco global vars ;;;;;;;;;;

global g_foco ; The single object responsible for the Foco GUI
global FoxitCoedit_Id := "FoxitCoedit"

global gu_focoLblHeadline
global g_HwndFOCOGui

;global gu_focoBtnTest
global gu_focoMleInfo
global gu_focoLblActivate
global gu_focoCkbLside
global gu_focoCkbRside
global gu_focoBtnSavePdf
global gu_focoBtnSync

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include %A_LineFile%\..\pdfreader.ahk
#Include %A_LineFile%\..\libs\class.PeersCoedit.ahk

class FoxitCoedit
{
	; static vars as constant
	
	isGuiVisible := false
	
	state := "" ; "Detecting" , "EditorDetected", "CoeditActivated", "CoeditHandshaked", "Freezing"
	
	testmember := "testmember" ; temp to-del
	
	coedit := "" ; the PeersCoedit class instance
	
	timer := ""
	
	pedHwnd := "" ; ped: pdf editor
	pedWinTitle := "" 
	
	prev_mletext := ""
	
	ischk_Lside := 0   ; 0 or 1, reflecting Coedit-sideA-Activate
	ischk_Rside := 0  ; 0 or 1, reflecting Coedit-sideB-Activate
	
	was_doc_modified := 0 ; pdf modified and unsaved state(denoted by asterisk symbol)
	
	prev_peerHwnd := 0
	
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

	__New()
	{
		this.coedit := new PeersCoedit()
	}
	
	pdfpath[]
	{
		get {
			return this.coedit.docpath
		}
	}

	peerHwnd[]
	{
		get {
			return this.state=="CoeditHandshaked" ? this.coedit.peerdict.HWND : ""
		}
	}
	
	peerDocModified[]
	{
		get {
			return this.state=="CoeditHandshaked" ? this.coedit.peerdict.is_modified : ""
		}
	}

	CreateGui()
	{
		GuiName := "FOCO"
		
		Gui_New(GuiName)
		Gui_ChangeOpt(GuiName, "+Resize +MinSize")
		Gui_AssociateHwndVarname(GuiName, "g_HwndFOCOGui")
		
		fullwidth := 400
		
		Gui_Add_TxtLabel(GuiName, "gu_focoLblHeadline", fullwidth, "", "Detecting Foxit Reader/Editor...")
		
		Gui_Add_Editbox( GuiName, "gu_focoMleInfo", fullwidth, "xm r10 readonly" , "...")
		
		Gui_Add_TxtLabel(GuiName, "gu_focoLblActivate", 0, "xm", "Activate Coedit for above pdf")
		Gui_Add_Checkbox(GuiName, "gu_focoCkbLside", 0, "x+10 yp " gui_g("Foco_CkbActivateCoedit"), "as &Left-side")
		Gui_Add_Checkbox(GuiName, "gu_focoCkbRside", 0, "x+10 yp " gui_g("Foco_CkbActivateCoedit"), "as &Right-side")

		Gui_Add_Button(  GuiName, "gu_focoBtnSavePdf",  98, "xm y+30 default " gui_g("Foco_OnBtnSavePdf"), "&Save pdf now")
		sync_btn_width := 60
		xgap := fullwidth - 98 - sync_btn_width
		Gui_Add_Button(  GuiName, "gu_focoBtnSync", sync_btn_width, Format("x+{} ", xgap) gui_g("Foco_OnBtnSync"), "R&e-sync")

		;
		; init base facility
		;
		this.state := "Detecting"
		this.RefreshUic()
		
		; The timer must be run all the time, bcz, even if the GUI is hidden, 
		; it should be able to detect situations like [handshake lost], [conflicting modifying doc] etc.
		this.timer := Func("FoxitCoedit.RootTimerCallback").Bind(this) ; a BoundFunc object
		dev_StartTimerPeriodic(this.timer, 1000, true)
		
	}

	ShowGui()
	{
		GuiName := "FOCO"
		if(this.isGuiVisible)
		{
			dev_WinActivateHwnd(g_HwndFOCOGui) ; bring it to front
			return ; already shown
		}
		
		if(!g_HwndFOCOGui) {
			this.CreateGui()
		}
		
		Gui_Show(GuiName, "AutoSize", "FoxitCoedit")
		
		Editbox_ClearSelection(GuiName, "gu_focoMleInfo") 
		; -- to avoid seeing all text in Mle defaultly selected on first sight, effective only after Gui_Show()

		this.isGuiVisible := true
	}
	
	HideGui()
	{
		Gui_Hide("FOCO")
;		dev_StopTimer(this.timer) ; should NOT stop the timer
		
		this.isGuiVisible := false
	}

	RefreshUic()
	{
		GuiName := "FOCO"
		
		; assume all false(disabled)
		focoLblActive := focoCkbLside := focoCkbRside := false
		focoBtnSavePdf := focoBtnSync := false

		if(this.state=="Detecting")
		{
			; still all false
		}
		else if(this.state=="EditorDetected")
		{
			focoLblActive := focoCkbLside := focoCkbRside := true
		}
		else if(this.state=="CoeditActivated" or this.state=="CoeditHandshaked")
		{
			focoLblActive := true

			dev_assert(not (this.ischk_Lside and this.ischk_Rside))
			if(this.ischk_Lside)
				focoCkbLside := true
			if(this.ischk_Rside)
				focoCkbRside := true
			
			if(this.coedit.state!="Syncing")
			{
				focoBtnSavePdf := focoBtnSync := true
			}
		}
		else
		{
			dev_assert(this.state=="Freezing")
			; -- all UIC should be disabled.
		}
		
		GuiControl_Enable(GuiName, "gu_focoLblActivate", focoLblActive)
		GuiControl_Enable(GuiName, "gu_focoCkbLside", focoCkbLside)
		GuiControl_Enable(GuiName, "gu_focoCkbRside", focoCkbRside)
		GuiControl_Enable(GuiName, "gu_focoBtnSavePdf", focoBtnSavePdf)
		GuiControl_Enable(GuiName, "gu_focoBtnSync", focoBtnSync)

		this.RefreshMleDetail()
	}

	RefreshMleDetail()
	{
		detail := ""
		
		if(this.state=="Detecting")
		{
			detail := "No Foxit Reader/Editor is running yet.`n`n"
				. "Just run Foxit and open a PDF file, this program will detect it automatically."
		}
		else
		{
			detail .= Format("HWND:`n0x{:08X}", this.pedHwnd)
			if(this.peerHwnd)
			{
				detail .= Format("  (peer: 0x{:08X})", this.peerHwnd)
			}
			detail .= "`n`n"
		
			detail .= Format("TITLE:`n{}`n`n", this.pedWinTitle)
				
			if(this.pdfpath) 
				detail .= "FILEPATH:`n" this.pdfpath
		}
		
		if(this.prev_mletext != detail)
		{	
			; This `if` to avoid clearing out user mouse text selection.
			this.prev_mletext := detail
			GuiControl_SetText("FOCO", "gu_focoMleInfo", detail)
		}
	}

	IsPdfModified()
	{
		wintitle := dev_WinGetTitle_byHwnd(this.pedHwnd)
		dev_SplitPath(this.pdfpath, pdfnam)
		
		is_nam := StrIsStartsWith(wintitle, pdfnam)
		is_ast := dev_IsSubStr(wintitle, "*")
		
		if(is_nam and is_ast)
			return true
		else
			return false
	}


	ActivateCoedit(which_side, pdfpath)
	{
		fndoc := { "syncsucc" : Func("FoxitCoedit.fndocSyncSucc").Bind(this)
			, "savedoc" : Func("FoxitCoedit.fndocSavePdf").Bind(this)
			, "closedoc" : Func("FoxitCoedit.fndocClosePdf").Bind(this)
			, "opendoc" : Func("FoxitCoedit.fndocOpenPdf").Bind(this) }

		this.prev_peerHwnd := 0
		
		this.coedit.Activate(which_side, pdfpath, fndoc) ; this does not block
		this.state := "CoeditActivated"
		
		this.StoreMinesideIni("", "")
		
		; Override Ctrl+S for Foxit Reader/Editor 
		fxhk_DefineHotkeyCondComment("^s", "FoxitCoedit_SaveDoc_hotkey", "assigned by FoxitCoedit"
			, false	, "foxit_IsWinActive", "FoxitCoedit_LaunchUI")
	}
	
	DeactivateCoedit()
	{
		dev_assert(this.coedit)

		this.coedit.IniWriteMine("HWND", "") ; must before .Deactivate()
		
		this.coedit.Deactivate()
		this.state := "Detecting"
		
		fxhk_UnDefineHotkey("^s", "FoxitCoedit_SaveDoc_hotkey")
	}

	StoreMinesideIni(is_doc_modified, myHwnd)
	{
		; The parameters determine what values we'd like the peer to see.
		
		this.coedit.IniWriteMine("is_modified", is_doc_modified)
		
		this.coedit.IniWriteMine("HWND"
			, (myHwnd=="" or myHwnd==0) ? "" : Format("0x{:08X}", myHwnd))
	}

	OnBtnSavePdf()
	{
		GuiName := "FOCO"
		Gui_ChangeOpt(GuiName, "+OwnDialogs")

		if(not this.IsPdfModified())
		{
			dev_MsgBoxInfo("The PDF file looks unmodified, not action needed.")
			return
		}

		oldstate := this.state
		this.state := "Freezing"
		GuiControl_Enable(GuiName, "gu_focoBtnSavePdf", false)
		;
		is_succ := this.coedit.LaunchSaveDocSession(ret_is_conn_lost) ; this will block for some time.
		;
		GuiControl_Enable(GuiName, "gu_focoBtnSavePdf", true)
		this.state := oldstate
		
		if(is_succ)
		{
			GuiControl_SetFocus(GuiName, "gu_focoBtnSavePdf")
		}
		else
		{
			if(ret_is_conn_lost)
			{
				this.ResyncCoedit()
				dev_MsgBoxWarning("Handshake lost! Now re-syncing.", FoxitCoedit_Id)
			}
			else
			{
				dev_assert(0, "FoxitCoedit bug: Re-entrant calling of OnBtnSavePdf !")
			}
		}
		
		this.RefreshUic()
	}
	

	RootTimerCallback()
	{
		GuiName := "FOCO"
		
		if(this.state=="Detecting" or this.state=="EditorDetected")
		{
			this.DetectFoxitPresent()
		}
		else if(this.state=="CoeditActivated")
		{
			GuiControl_SetText(GuiName, "gu_focoLblHeadline", "[ Activated ] Syncing...")
		}
		else if(this.state=="CoeditHandshaked")
		{
			GuiControl_SetText(GuiName, "gu_focoLblHeadline", "[ Activated ] Handshaked")
			
			this.RefreshUic()
			
			;
			; To detect HWND lost
			;

			if(this.peerHwnd)
				this.prev_peerHwnd := this.peerHwnd
			
			if(this.prev_peerHwnd and not this.peerHwnd)
			{
				; If we once saw prev_peerHwnd valid, but now it becomes null, then the peer is lost.

				dev_MsgBoxWarning("Peer HWND lost. Handshake lost! Click OK to re-sync.", FoxitCoedit_Id)
				this.ResyncCoedit()
				return
			}
			
			;
			; Check editing conflict
			;
			
			is_modified := this.IsPdfModified()
			if(this.was_doc_modified != is_modified)
			{
				; Write to INI to indicate to other side
				this.was_doc_modified := is_modified
				this.coedit.IniWriteMine("is_modified", is_modified)
			}
			
			if(this.was_doc_modified and this.peerDocModified)
			{
				dev_MsgBoxWarning("Both sides pdf are being modified, you are doing conflict editing!`n`n"
					. "This warning keeps pop-up until you discard one-side's modification.`n`n"
					, FoxitCoedit_Id)
			}
		}
	}
	
	DetectFoxitPresent()
	{
		GuiName := "FOCO"
		hwnd := dev_WinGet_Hwnd("ahk_class classFoxitReader")
		if(hwnd) {
		}
		else {
			hwnd := dev_WinGet_Hwnd("ahk_class classFoxitPhantom")
		}
		
		this.pedHwnd := hwnd
		
		if(hwnd)
		{
			this.state := "EditorDetected"

			wintitle := dev_WinGetTitle_byHwnd(hwnd)
			
			this.pedWinTitle := FoxitCoedit.StripAsterisk(wintitle)
			
			GuiControl_SetText(GuiName, "gu_focoLblHeadline", "Detected Foxit Reader/Editor:")
			this.RefreshMleDetail()
		}
		else
		{
			this.state := "Detecting"
		}
		
		this.RefreshUic()
	}
	
	StripAsterisk(wintitle) ; static
	{
		return StrReplace(wintitle, " *", "")
	}
	
	GuessPdfFilenameFromTitle(wintitle)
	{
		; Wintite example:
		;	"The Unix Manual.pdf - Foxit Reader"
		;	"Learning EBPF - Foxit PDF Editor"
		;	"Learning EBPF * - Foxit PDF Editor"
		;
		; so we take "- Foxit" as signature.
		
		foundpos := InStr(wintitle, "- Foxit")
		if(foundpos>0)
			return SubStr(wintitle, 1, foundpos-1)
		else
			return wintitle
	}
	
	
	get_ckbstate(which_ctlid)
	{
		dev_assert(which_ctlid=="gu_focoCkbLside" or which_ctlid=="gu_focoCkbRside")
		return which_ctlid=="gu_focoCkbLside" ? this.ischk_Lside : this.ischk_Rside
	}
	
	set_ckbstate(which_ctlid, state)
	{
		dev_assert(which_ctlid=="gu_focoCkbLside" or which_ctlid=="gu_focoCkbRside")
		
		if(which_ctlid=="gu_focoCkbLside")
			this.ischk_Lside := state
		else
			this.ischk_Rside := state
		
		Checkbox_SetCheckState("FOCO", which_ctlid, state)
	}
	
	CkbActivateCoedit()
	{
		; We'll distinguish left-side or right-side according to A_GuiControl
	
		GuiName := "FOCO"
		
		Gui_ChangeOpt(GuiName, "+OwnDialogs")
		
		ctlid_ckb := A_GuiControl
		isLeftside := (ctlid_ckb=="gu_focoCkbLside") ? true : false
		
		ischecked := this.get_ckbstate(ctlid_ckb)

		this.set_ckbstate(ctlid_ckb, ischecked)
		; -- Do it bcz we want it to be a BS_CHECKBOX instead of a BS_AUTOCHECKBOX.
		;    We must set checkbox's UI state according to our own class member.
		
		if(not ischecked)
		{
			; Ask user the real location of the PDF file, bcz AHK code here has no way to know it automatically.
			pdfnam := this.GuessPdfFilenameFromTitle(this.pedWinTitle)

			pdfpath_real := dev_OpenSelectFileDialog(pdfnam
				, "Please tell me the actual filepath of the PDF file on the disk"
				, "PDF files (*pdf)")
			
			if(not pdfpath_real)
				return ; user cancels, do nothing
			
			if(not FileExist(pdfpath_real))
			{
				dev_MsgBoxWarning("The filepath you picked does not exist yet:`n`n" pdfpath_real
					, FoxitCoedit_Id)
				return
			}
			
			this.ActivateCoedit(isLeftside ? "sideA" : "sideB", pdfpath_real)
			
			this.set_ckbstate(ctlid_ckb, true)
			
			this.RefreshMleDetail()
		}
		else
		{
			this.DeactivateCoedit()
		
			this.set_ckbstate(ctlid_ckb, false)
		}
		
		this.RefreshUic()
	}
	
	
	ResyncCoedit()
	{
		this.state := "CoeditActivated"
		this.prev_peerHwnd := 0
		
		this.StoreMinesideIni("", "")
		
		this.coedit.ResetSyncState()
		
		this.RefreshUic()
	}
	
	
	fndocSyncSucc()
	{
		this.state := "CoeditHandshaked"
		
		this.was_doc_modified := this.IsPdfModified()
		
		this.StoreMinesideIni(this.was_doc_modified, this.pedHwnd)

		this.RefreshUic()
	}
	
	fndocSavePdf()
	{
		this.dbg1("FoxitCoedit.fndocSavePdf() executing...")
		
		if(this.IsPdfModified())
		{
			this.Try_SaveCurrentPdf()
			
			; And wait until wintitle's "*" disappears.
			Loop, 10
			{
				dev_Sleep(500)
				if(not this.IsPdfModified())
				{
					this.dbg1("FoxitCoedit.fndocSavePdf() success , PDF modified.")
					return true
				}
				
			}
			throw Exception("FoxitCoedit.fndocSavePdf() operation fail.")
		}

		this.dbg1("FoxitCoedit.fndocSavePdf() success , no modify.")
	}
	
	fndocClosePdf()
	{
		hwnd := this.pedHwnd
		this.dbg1(Format("FoxitCoedit.fndocClosePdf() executing..."))
		
		close_ok := dev_WinClose("ahk_id " hwnd, 5000) ; todo: make this timeout configurable
		
		if(close_ok)
			this.dbg1("FoxitCoedit.fndocClosePdf() success.")
		else
			throw Exception("FoxitCoedit.fndocClosePdf() fail!")
	}

	fndocOpenPdf()
	{
		GuiName := "FOCO"
		this.dbg1("FoxitCoedit.fndocOpenPdf() executing...")
		
		exepath := ""
		exepath1 := "D:\PFNoInst\Foxit Reader 7.1.5\FoxitReader.exe"
		exepath2 := "C:\Program Files\Foxit Software\Foxit PDF Editor\FoxitPDFEditor.exe"
		; todo: make the path configurable
		
		if(FileExist(exepath1))
			exepath := exepath1
		else if(FileExist(exepath2))
			exepath := exepath2
		else
			throw Exception("FoxitCoedit.fndocOpenPdf() fail! Bad exepath configured.")

		; First, ensure that no process of exepath is running.
		if(WinExist("ahk_exe " exepath))
			throw Exception(Format("Unexpected! fndocOpenPdf() sees ""{}"" still running.", exepath))
		
		Run % exepath
		
		; Second, check that the new process really runs.
		
		Loop, 10
		{
			dev_Sleep(500)
			
			query_title := "ahk_exe " exepath
			newhwnd := dev_GetHwndByWintitle(query_title)
			if(not newhwnd)
				continue
			
			newtitle := dev_WinGetTitle_byHwnd(newhwnd)
			
			newpdfnam := this.GuessPdfFilenameFromTitle(newtitle)
			oldpdfnam := this.GuessPdfFilenameFromTitle(this.pedWinTitle)
			
			; note: When the Foxit Editor 11 launching involves some bigs PDFs, the first-seen 
			; newtitle may be the small progress-bar's title, and we need to ignore it.
			
			if( newpdfnam==oldpdfnam )
			{
				this.dbg1("FoxitCoedit.fndocOpenPdf() success.")
				
				; Third, grab new-process's HWND
				this.pedHwnd := dev_WinGet_Hwnd("ahk_exe " exepath)
				
				this.dbg1(Format("Foxit HWND updated to be: {}", this.pedHwnd))
				this.coedit.IniWriteMine("HWND", Format("0x{:08X}", this.pedHwnd))
				
				this.RefreshMleDetail() ; bcz the HWND has changed
				
				return true
			}
			else
			{
				this.dbg2("[Dbginfo] Skip Foxit new process's title: " newtitle)

;				On an Foxit Editor 11 machine opening two document-tabs, and we are editing 
;				2nd tab document, I once see this:
;
;				2*[20240419_15:50:29.477] (+1.996s) Waiting peer's writing doc, success.
;				2*[20240419_15:50:29.477] (+0.000s) Now re-opening doc...
;				1*[20240419_15:50:29.477] (+0.000s) FoxitCoedit.fndocOpenPdf() executing...
;				2*[20240419_15:50:29.977] (+0.500s) [Dbginfo] Skip Foxit new process's title: Progress
;				2*[20240419_15:50:30.476] (+0.499s) [Dbginfo] Skip Foxit new process's title: Progress [53%]
;				2*[20240419_15:50:30.975] (+0.499s) [Dbginfo] Skip Foxit new process's title: Progress [61%]
;				2*[20240419_15:50:31.474] (+0.499s) [Dbginfo] Skip Foxit new process's title: Progress [71%]
;				2*[20240419_15:50:31.973] (+0.499s) [Dbginfo] Skip Foxit new process's title: Progress [80%]
;				2*[20240419_15:50:32.473] (+0.500s) [Dbginfo] Skip Foxit new process's title: Progress [88%]
;				2*[20240419_15:50:32.972] (+0.499s) [Dbginfo] Skip Foxit new process's title: Progress [96%]
;				2*[20240419_15:50:33.471] (+0.499s) [Dbginfo] Skip Foxit new process's title: [TLPI] The Linux (...this is first tab doc...) - Foxit PDF Editor
;				1*[20240419_15:50:33.970] (+0.499s) FoxitCoedit.fndocOpenPdf() success.
;				1*[20240419_15:50:33.970] (+0.000s) Foxit HWND updated to be: 0xce09d2
;				2*[20240419_15:50:33.970] (+0.000s) Done re-opening doc...
;				1*[20240419_15:50:33.970] (+0.000s) Mineside just refreshed the doc. (passeq=2)
				
			}
		}

		throw Exception(Format("Bad! Foxit process ""{}"" did not launch.", exepath))
	}
	
	Try_SaveCurrentPdf()
	{
		hwnd := this.pedHwnd
	
		; For legacy Foxit 7.1.5 UI, We send Ctrl+S to save the doc.
		dev_SendKeyToExeMainWindow("{Ctrl down}{s}{Ctrl up}", "ahk_id " hwnd)
		
		; For Foxit 9+ Ribbon UI, we need to click on window-title's small "Save" button.
		; and this is not harmful to legacy Foxit 7.1.5 .
		active_ok := dev_WinActivateHwnd(hwnd, 1000) ; todo: make it configurable
		if(not active_ok)
			throw Exception(Format("Foxit HWND {} cannot be activated.", hwnd))
		
		dev_Sleep(100) ; to play it safe
		ClickInActiveWindow(64, 16, false)
	}

} ; class FoxitCoedit


FoxitCoedit_LaunchUI()
{
	if(!g_foco)
	{
		g_foco := new FoxitCoedit()
	}

	g_foco.ShowGui()
}

Foco_OnBtnSavePdf()
{
	g_foco.OnBtnSavePdf()
}

Foco_OnBtnSync()
{
	g_foco.ResyncCoedit()
}


FOCOGuiSize()
{
	rsdict := {}
	rsdict.gu_focoMleInfo := JUL.LeftTop_DynWidthHeight
	rsdict.gu_focoLblActivate := JUL.PinToLeftBottom
	rsdict.gu_focoCkbLside := JUL.PinToLeftBottom
	rsdict.gu_focoCkbRside := JUL.PinToLeftBottom
	rsdict.gu_focoBtnSavePdf := JUL.PinToLeftBottom
	rsdict.gu_focoBtnSync := JUL.PinToRightBottom
	
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


Foco_CkbActivateCoedit()
{
	g_foco.CkbActivateCoedit()
}



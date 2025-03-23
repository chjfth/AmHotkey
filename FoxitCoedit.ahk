AUTOEXEC_FoxitCoedit: ; Workaround for Autohotkey's ugly auto-exec feature. Must be first line.
; -- naming: Foxit PDF reader/editor from two machines, co-operatively edit the same PDF file

/* APIs:
FoxitCoedit_LaunchUI()

Example:
	fxhk_DefineComboHotkey("AppsKey", "s", "FoxitCoedit_LaunchUI")

*/

;;;;;;;; Foco global vars ;;;;;;;;;;

global g_foco ; The single object responsible for the Foco GUI

global gu_focoLblHeadline
global g_HwndFOCOGui

;global gu_focoBtnTest
global gu_focoMleInfo
global gu_focoLblActivate
global gu_focoCkbLside
global gu_focoCkbRside
global gu_focoLblPeerFollow
global gu_focoDdlPeerFollowMe
global gu_focoBtnSavePdf
global gu_focoBtnResync
global gu_focoBottomStatus

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include %A_LineFile%\..\pdfreader.ahk
#Include %A_LineFile%\..\libs\class.PeersCoedit.ahk

class FoxitCoedit
{
	static Id := "FoxitCoedit"

	; static vars as constant >>>
	static BtnTextResync := "R&e-sync"
	static is_simulate_reopen_pdf_fail := false ; debugging purpose
	static PdfBackups := 5
	; static vars as constant <<<
	
	isGuiVisible := false
	
	state := "" ; "Detecting" , "EditorDetected", "CoeditActivated", "CoeditHandshaked", "Freezing"
	; --[2024-06-05] Freezing unused yet.
	
	tsSyncSuccss := "" ; A_Now
	
	coedit := "" ; the PeersCoedit class instance
	
	timer := ""
	
	pedHwnd := "" ; ped: pdf editor
	pedWinTitle := "" 
	pedExepath := ""
	
	prev_mletext := ""
	
	txtHeadline := ""
	txtBottomline := ""
	
	ischk_Lside := 0   ; 0 or 1, reflecting Coedit-sideA-Activate
	ischk_Rside := 0  ; 0 or 1, reflecting Coedit-sideB-Activate
	
	was_doc_modified := 0 ; pdf modified and unsaved state(denoted by asterisk symbol)
	
	prev_peerHwnd := 0
	
	is_showing_syncerr_msgbox := false ; just for optimized Error popup
	
	mine_prev_PdfPageNum := ""
	mine_pagenum_seq := 0
	;
	peer_prev_pagenum_seq := 0
	peer_prev_pagenum := ""
	;
	msec_passive_followed := 0 		;msec_freeze_following_before := 0

	; peer-follow-me user preference
	static PEERFM_ALWAYS := 1
	static PEERFM_AFTERSAVEPDF := 2
	static PEERFM_NO := 3
	peerfm_selection := FoxitCoedit.PEERFM_ALWAYS
	
	is_closing_pdf := false
	was_activepdf := -1 ; -1 as an invalid value
	
	dbg(msg, lv) {
		AmDbg_output(FoxitCoedit.Id, msg, lv)
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
		
		if(FoxitCoeditCfg.PdfBackups>0)
		{
			; User can define FoxitCoeditCfg.PdfBackups in custom_env.ahk .
			FoxitCoedit.PdfBackups := FoxitCoeditCfg.PdfBackups
		}
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
		GuiName := FoxitCoedit.Id
		
		Gui_New(GuiName)
		Gui_ChangeOpt(GuiName, "+Resize +MinSize")
		Gui_AssociateHwndVarname(GuiName, "g_HwndFOCOGui")
		
		fullwidth := 400
		
		Gui_Add_TxtLabel(GuiName, "gu_focoLblHeadline", fullwidth, "", "...")
		
		Gui_Add_Editbox( GuiName, "gu_focoMleInfo", fullwidth, "xm r10 readonly -0x1000" , "...") 
		; -- 0x1000 ES_WANTRETURN: we don't want this style bcz we want Enter to trigger default btn, even if Editbox has focus.
		
		Gui_Add_TxtLabel(GuiName, "gu_focoLblActivate", 0, "xm", "Activate Coedit for above pdf")
		Gui_Add_Checkbox(GuiName, "gu_focoCkbLside", 0, "x+10 yp " gui_g("Foco_CkbActivateCoedit"), "as &Left-side")
		Gui_Add_Checkbox(GuiName, "gu_focoCkbRside", 0, "x+10 yp " gui_g("Foco_CkbActivateCoedit"), "as &Right-side")

		Gui_Add_TxtLabel(GuiName, "gu_focoLblPeerFollow", 0, "xm y+30", "Peer PDF page &follows me:")
		Gui_Add_DropDownList(GuiName, "gu_focoDdlPeerFollowMe", 137, "x+5 yp-2 AltSubmit " gui_g("Foco_OnDdlPeerFollowMe")
			, "Always||Only after saving PDF|No")

		save_btn_width := 98
		sync_btn_width := 98
		Gui_Add_Button(  GuiName, "gu_focoBtnSavePdf",  save_btn_width, "xm y+6 default " gui_g("Foco_OnBtnSavePdf"), "&Save pdf now")
		xgap := fullwidth - save_btn_width - sync_btn_width
		Gui_Add_Button(  GuiName, "gu_focoBtnResync", sync_btn_width, Format("x+{} ", xgap) gui_g("Foco_OnBtnResync"), FoxitCoedit.BtnTextResync)
		
		Gui_Add_Editbox( GuiName, "gu_focoBottomStatus", fullwidth, "xm readonly -E0x200", "...") ; -E0x200: turn off WS_EX_CLIENTEDG
		GuiControl_SetColor(GuiName, "gu_focoBottomStatus", "8464B4") ; set grey text

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
		GuiName := FoxitCoedit.Id
		if(this.isGuiVisible)
		{
			dev_WinActivateHwnd(g_HwndFOCOGui) ; bring it to front
			return ; already shown
		}
		
		if(!g_HwndFOCOGui) {
			this.CreateGui()
		}
		
		Gui_Show(GuiName, "AutoSize", FoxitCoedit.Id)
		
		Editbox_ClearSelection(GuiName, "gu_focoMleInfo") 
		; -- to avoid seeing all text in Mle defaultly selected on first sight, effective only after Gui_Show()

		this.isGuiVisible := true
	}
	
	HideGui()
	{
		Gui_Hide(FoxitCoedit.Id)
;		dev_StopTimer(this.timer) ; should NOT stop the timer
		
		this.isGuiVisible := false
	}

	RefreshUic()
	{
		GuiName := FoxitCoedit.Id
		
		; assume all false(disabled)
		focoLblActive := focoCkbLside := focoCkbRside := false
		focoBtnSavePdf := focoDdlPeerFollowMe := focoBtnSync := false

		if(this.state=="Detecting")
		{
			this.txtHeadline := "Detecting Foxit Reader/Editor..."
			this.txtBottomline := "..."
		}
		else if(this.state=="EditorDetected")
		{
		 	this.txtHeadline := "Detected Foxit Reader/Editor:"
			this.txtBottomline := "Hint: Click ""as Left-side"" or ""as Right-side"" to coedit that PDF."

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
				focoBtnSavePdf := focoDdlPeerFollowMe := focoBtnSync := true
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
		GuiControl_Enable(GuiName, "gu_focoDdlPeerFollowMe", focoDdlPeerFollowMe)
		GuiControl_Enable(GuiName, "gu_focoBtnSavePdf", focoBtnSavePdf)
		GuiControl_Enable(GuiName, "gu_focoBtnResync", focoBtnSync)

		GuiControl_SetText(GuiName, "gu_focoLblHeadline", this.txtHeadline)
		GuiControl_SetText(GuiName, "gu_focoBottomStatus", this.txtBottomline)

		this.RefreshMleDetail()
	}

	FormatHwnd(hwnd) ; static
	{
		if(hwnd=="" or hwnd==0)
			val := ""
		else if(hwnd=="*")
			val := "*"
		else
			val := Format("0x{:0X}", hwnd)
		return val
	}
	
	RefreshMleDetail()
	{
		GuiName := FoxitCoedit.Id
		detail := ""
		
		if(this.state=="Detecting")
		{
			detail := "No Foxit Reader/Editor is running yet.`n`n"
				. "Just run Foxit and open a PDF file, this program will detect it automatically."
		}
		else
		{
			detail .= Format("HWND:`n{}", FoxitCoedit.FormatHwnd(this.pedHwnd))
			if(this.peerHwnd)
			{
				detail .= Format("  (peer: {})", FoxitCoedit.FormatHwnd(this.peerHwnd))
			}
			detail .= "`n`n"
		
			detail .= Format("TITLE:`n{}`n`n", this.pedWinTitle)
				
			if(this.pdfpath) 
			{
				detail .= "FILEPATH:`n" this.pdfpath
				detail .= "`n`n"
			}
		}
		
		detail .= "PdfBackups: " FoxitCoedit.PdfBackups
;		detail .= "`n`n"
		
		if(this.prev_mletext != detail)
		{	
			; This `if` to avoid clearing out user mouse text selection.
			this.prev_mletext := detail
			GuiControl_SetText(GuiName, "gu_focoMleInfo", detail)
		}
	}

	IsPdfModified()
	{
		wndtitle := dev_WinGetTitle_byHwnd(this.pedHwnd)
		
		; Note: the Foxit's wndtitle text MAY diverge from the PDF filename,
		; -- this can happen if the PDF has explicit Title property.
		; For example, "[LLEBPF2023] OReilly - Learning eBPF by Liz Rice.pdf" 
		; has Foxit wndtitle text "Learning EBPF - Foxit Reader".
		; When the PDF is modified, the wndtitle becomes:
		;     "Learning EBPF * - Foxit Reader"
		;
		; So we need to compare this.pedWinTitle instead of this.pdfpath .
		
		is_ast := dev_IsSubStr(wndtitle, "*")
		if(is_ast)
		{
			wndtitle_noast := FoxitCoedit.StripAsterisk(wndtitle)

			if(wndtitle_noast==this.pedWinTitle)
				return true
		}
		
		return false
	}
	
	IsPdfModified_msgbox()
	{
		if(this.IsPdfModified())
			return true
		
		dev_MsgBoxInfo("The PDF file looks unmodified, not action needed.")
		return false
	}

	ActivateCoedit(which_side, pdfpath)
	{
		fndoc := { "syncsucc" : Func("FoxitCoedit.fndocSyncSucc").Bind(this)
			, "savedoc" : Func("FoxitCoedit.fndocSavePdf").Bind(this)
			, "closedoc" : Func("FoxitCoedit.fndocClosePdf").Bind(this)
			, "opendoc" : Func("FoxitCoedit.fndocOpenPdf").Bind(this)
			, "notify_ssstate" : Func("FoxitCoedit.fndocNotifySSState").Bind(this) }

		this.prev_peerHwnd := 0
		
		this.coedit.Activate(which_side, pdfpath, fndoc) ; this does not block
		this.state := "CoeditActivated"
		
		this.StoreMinesideIni("", "")
		
		; Override Ctrl+S for Foxit Reader/Editor 
		fxhk_DefineHotkeyCondComment("^s", "FoxitCoedit_SaveDoc_hotkey", "assigned by FoxitCoedit"
			, false	, "foxit_IsWinActive", "FoxitCoedit_CtrlS")
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

	CtrlS()
	{
		if(this.IsTargetPdfActive())
		{
			if(not this.IsPdfModified_msgbox())
				return
			
			; PDF has modification asterisk:
			this.ShowGui()
		}
		else
		{
			Send ^s
			return
		}
	}

	OnBtnSavePdf()
	{
		GuiName := FoxitCoedit.Id
		Gui_ChangeOpt(GuiName, "+OwnDialogs")

		if(not this.IsPdfModified_msgbox())
		{
			return
		}

		is_ctrldown := dev_IsCtrlKeyDown()
		if(is_ctrldown)
			this.HideGui()

		docpath_now := this.coedit.docpath
		
		; Make a backup of the original pdf content.
		;
		pdfdir := dev_SplitPath(docpath_now, ret_pdfname)
		dir_prebackup := Format("{}\_prebackup", pdfdir)
		dev_CreateDirIfNotExist(dir_prebackup)
		docpath_prebackup := Format("{}\{}", dir_prebackup, ret_pdfname)
		dev_FileDelete(docpath_prebackup)
		
		saving_succ := dev_Copy1File(docpath_now, docpath_prebackup)
		if(not saving_succ)
		{
			dev_MsgBoxError(Format("[ERROR] Cannot backup orignal PDF! I will not go on saving current pdf in case Foxit Reader/Editor could cause damage to your PDF content."
				. "`n`nFail to create the backup file:`n`n{}", docpath_prebackup))
			return
		}
		this.dbg1("Created prebackup file: " docpath_prebackup)
		
		oldstate := this.state
		this.state := "Freezing"
		GuiControl_Enable(GuiName, "gu_focoBtnSavePdf", false)
		GuiControl_SetText(GuiName, "gu_focoBtnSavePdf", "Saving...")
		GuiControl_SetText(GuiName, "gu_focoBtnResync", "Cancel Saving")
		
		;
		is_succ := this.coedit.LaunchSaveDocSession(ret_is_conn_lost, ret_errmsg)
		; -- this will block for some time, but can be canceled by calling this.coedit.CancelSavingSession() .
		;    Note: I require NO exception be thrown. Statements below must be executed, no matter success of failure.
		;
		GuiControl_SetText(GuiName, "gu_focoBtnSavePdf", "&Save pdf now")
		GuiControl_Enable(GuiName, "gu_focoBtnSavePdf", true)
		GuiControl_SetText(GuiName, "gu_focoBtnResync", FoxitCoedit.BtnTextResync)
		GuiControl_Enable(GuiName, "gu_focoBtnResync") ; may have been disabled in OnBtnResync()
		this.state := oldstate

		; We want to move the prebackup pdf to subdir backupA/backup.B ,
		; no matter LaunchSaveDocSession() succeeds.
		;
		if(not dev_IsFileModifyTimeSame(docpath_now, docpath_prebackup))
		{
			try 
			{
				pb := new PiledBackup(docpath_prebackup
					, docpath_now . (this.ischk_Lside ? ".backupA" : ".backupB")
					, FoxitCoedit.PdfBackups
					, PiledBackup.DoMove)
				this.dbg1("Moving backup pdf to folder: " pb.dirbackup)
				
				pb.SaveOneBackup()
			}
			catch e 
			{
				errmsg := Format("After PDF saving, FoxitCoedit cannot move the prebackup file"
					. "`n`n  {}`n`n"
					. "to backup folder:"
					. "`n`n  {}`n`n"
					. "Error message is:`n`n{}`n`n"
					. "So, before solving the problem, please manually set-aside the prebackup file, to prevent it being overwritten."
					, docpath_prebackup
					, pb.dirbackup
					, e.Message)
				dev_MsgBoxWarning(errmsg)
			}
		}
		
		; Some error-recovering action on failure
		;
		if(!is_succ)
		{
			if(is_ctrldown)
			{
				; Since fail, we should represent the UI for user to take further action.
				this.ShowGui()
			}
		
			if(ret_is_conn_lost)
			{
				this.DisplaySyncLostPopup(ret_errmsg)
				
				this.ResyncCoedit()
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
		GuiName := FoxitCoedit.Id
		
		if(this.state=="Detecting" or this.state=="EditorDetected")
		{
			this.InitDetectFoxitPresent()
		}
		else if(this.state=="CoeditActivated")
		{
			GuiControl_SetText(GuiName, "gu_focoLblHeadline", "[ Activated ] Waiting for peer...")
			GuiControl_SetText(GuiName, "gu_focoBottomStatus", "Waiting for peer to connect...")
		}
		else if(this.state=="CoeditHandshaked")
		{
			this.RefreshMineFoxitHwnd()
			
			this.RefreshUic()
			
			GuiControl_SetText(GuiName, "gu_focoLblHeadline", this.txtHeadline)
			GuiControl_SetText(GuiName, "gu_focoBottomStatus", this.txtBottomline)
			
			;
			; To detect HWND lost
			;

			if(this.peerHwnd)
				this.prev_peerHwnd := this.peerHwnd
			
			if(this.prev_peerHwnd and this.peerHwnd=="")
			{
				; If we once saw prev_peerHwnd valid, but now it becomes null, then the peer is lost.
				; HWND=* is not considered lost.

				if(not this.is_showing_syncerr_msgbox)
				{
					; If OnBtnSavePdf() has been showing similar popup, we will not do that repeatedly.
					
					this.ModalMsgBox_ShowWarning("Peer HWND lost. Handshake lost! Click OK to re-sync.", FoxitCoedit.Id)
					this.ResyncCoedit()
				}
				return
			}
			
			if(not this.IsTargetPdfActive())
			{
				; Foxit user is now viewing another pdf, so nothing more to do.
				return 
			}
			;
			; Check editing conflict
			;
			
			is_modified := this.RecheckPdfModifiedState()
			
			if(is_modified and this.peerDocModified)
			{
				temp_timer := Func("FoxitCoedit.RecheckPdfModifiedState").Bind(this) ; a BoundFunc object
				dev_StartTimerPeriodic(temp_timer, 2000, true)
				; -- this temp_timer is required, bcz, when ModalMsgBox_ShowWarning() blocks current AHK-thread,
				;    and RootTimerCallback() no longer executes every second. So an extra timer is required
				;    to check for this.IsPdfModified(), so that we can reset [INI] to is_modified=0 during the pop-up.
				
				this.ModalMsgBox_ShowWarning("Both sides pdf are being modified, you are doing conflicting editing!`n`n"
					. "This warning keeps pop-up until you discard one-side's modification.`n`n"
					. "Suggestion: If you decide to discard this-side's modification, go to Foxit, close the pdf without saving it, then reopen that pdf.`n`n"
					, FoxitCoedit.Id)
				
				dev_StopTimer(temp_timer)
				return
			}
			
			;
			; Notify my PDF page number to peer, and/or, follow peer's PDF page number.
			;
			
			Critical On
			if(not this.is_closing_pdf)
			{
				if(this.peerfm_selection==FoxitCoedit.PEERFM_ALWAYS) 
				{
					this.record_pagenum_for_peer()
				}
				
				this.FollowPeerzPageNum()
			}
			Critical Off
		}
	}

	IsTargetPdfActive()
	{
		; Foxit EXE can open multiple PDFs as individual tabs. 
		; The target pdf we are following may be switched to background so that it 
		; becomes "not active". In such case, the Foxit window-title will not reflect 
		; the target pdf's filename. 
		
		if(not this.pedHwnd)
			return false
		
		dev_assert(this.pedWinTitle)
		
		nowtitle := dev_WinGetTitle_byHwnd(this.pedHwnd)

		if(FoxitCoedit.IsTitleStemMatch(nowtitle, this.pedWinTitle))
			return true
		else
			return false
	}
	
	IsTitleStemMatch(wintitle1, wintitle2) ; static
	{
		stem1 := FoxitCoedit.TitleStemFromWinTitle(wintitle1)
		stem2 := FoxitCoedit.TitleStemFromWinTitle(wintitle2)

		return stem1==stem2 ? true : false
	}
	
	FindFoxitHwnd() ; static
	{
		hwnd := dev_WinGet_Hwnd("ahk_class classFoxitReader")
		if(hwnd) {
		}
		else {
			hwnd := dev_WinGet_Hwnd("ahk_class classFoxitPhantom")
		}
		return hwnd ; may return null
	}
	
	InitDetectFoxitPresent() ; only before Activate.
	{
		GuiName := FoxitCoedit.Id
		this.pedHwnd := FoxitCoedit.FindFoxitHwnd()
		
		if(this.pedHwnd)
		{
			this.state := "EditorDetected"

			wintitle := dev_WinGetTitle_byHwnd(this.pedHwnd)
			
			this.pedWinTitle := FoxitCoedit.StripAsterisk(wintitle)
			
			this.pedExepath := dev_GetExeFilepath("ahk_id " this.pedHwnd)
			
			this.RefreshMleDetail()
		}
		else
		{
			this.state := "Detecting"
		}
		
		this.RefreshUic()
	}
	
	StripAsterisk(wndtitle) ; static
	{
		return StrReplace(wndtitle, " *", "")
	}
	
	TitleStemFromWinTitle(wintitle) ; static
	{
		; Wintitle example:
		;	"The Unix Manual.pdf - Foxit Reader"
		;	"Learning EBPF - Foxit PDF Editor"
		;	"Learning EBPF * - Foxit PDF Editor"
		;
		; so we strip off "- Foxit" suffix.
		
		foundpos := InStr(wintitle, "- Foxit")
		if(foundpos>0)
			stem := SubStr(wintitle, 1, foundpos-1)
		else
			stem := wintitle
		
		; Strip of trailing modification asterisk
		return FoxitCoedit.StripAsterisk(stem)
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
		
		Checkbox_SetCheckState(FoxitCoedit.Id, which_ctlid, state)
	}
	
	CkbActivateCoedit()
	{
		; We'll distinguish left-side or right-side according to A_GuiControl
	
		GuiName := FoxitCoedit.Id
		
		Gui_ChangeOpt(GuiName, "+OwnDialogs")
		
		ctlid_ckb := A_GuiControl
		isLeftside := (ctlid_ckb=="gu_focoCkbLside") ? true : false
		
		ischecked := this.get_ckbstate(ctlid_ckb)

		this.set_ckbstate(ctlid_ckb, ischecked)
		; -- Do it bcz we want it to be a BS_CHECKBOX instead of a BS_AUTOCHECKBOX.
		;    We must set checkbox's UI state according to our own class member.
		
		if(not ischecked)
		{
			; Was not checked, and user is now checking/ticking it.
		
			; Ask user the real location of the PDF file, bcz AHK code here has no way to know it automatically.
			pdfnam := this.TitleStemFromWinTitle(this.pedWinTitle)
			
			pdfnam_safe := dev_ReplaceBadChars(pdfnam, "/<:>", "_")
			; -- If pdfnam is sth like "Caution: Danger", that will cause dev_OpenSelectFileDialog() error.

			pdfpath_real := dev_OpenSelectFileDialog(pdfnam_safe
				, "Please tell me the actual filepath of the PDF file on the disk"
				, "PDF files (*.pdf)")
			
			if(not pdfpath_real)
				return ; user cancels, do nothing
			
			if(not FileExist(pdfpath_real))
			{
				dev_MsgBoxWarning("The filepath you picked does not exist yet:`n`n" pdfpath_real
					, FoxitCoedit.Id)
				return
			}
			
			this.dbg1("Now activate FoxitCoedit for: " pdfpath_real)
			this.ActivateCoedit(isLeftside ? "sideA" : "sideB", pdfpath_real)
			
			this.LoadStaticCfg()
			
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
	
	OnBtnResync()
	{
		GuiName := FoxitCoedit.Id
		if(this.coedit.state=="ProSaving" or this.coedit.state=="PasReload")
		{
			this.coedit.CancelSavingSession()
			GuiControl_Disable(GuiName, "gu_focoBtnResync")
		}
		else
		{
			this.ResyncCoedit()
		}
	}
	
	ResyncCoedit()
	{
		this.state := "CoeditActivated"
		this.prev_peerHwnd := 0
		
		this.StoreMinesideIni("0", "")
		
		this.coedit.ResetSyncState()
		
		this.RefreshUic()
	}
	
	
	fndocSyncSucc()
	{
		this.state := "CoeditHandshaked"
		this.tsSyncSuccss := A_Now
		
		this.txtHeadline := "[ Activated ] Handshaked"
		this.txtBottomline := Format("[{}] Start monitoring PDF.", dev_GetDateTimeStr("_", this.tsSyncSuccss))
	
		this.mine_prev_PdfPageNum := ""
		this.mine_pagenum_seq := 0
		
		this.is_closing_pdf := false
		
		this.was_doc_modified := this.IsPdfModified()
		
		this.StoreMinesideIni(this.was_doc_modified, this.pedHwnd)

		this.RefreshUic()
	}
	
	fndocSavePdf()
	{
		GuiName := FoxitCoedit.Id
		this.dbg1("FoxitCoedit.fndocSavePdf() executing...")
		
		if(this.IsPdfModified())
		{
			; And wait until wintitle's "*" disappears.
			msec_start := dev_GetTickCount64()
			
			Loop
			{
				this.Try_SaveCurrentPdf()
			
				dev_Sleep(500)
				if(not this.IsPdfModified())
				{
					this.dbg1("FoxitCoedit.fndocSavePdf() success , PDF saved.")
					
					if(this.peerfm_selection==FoxitCoedit.PEERFM_ALWAYS 
						or this.peerfm_selection==FoxitCoedit.PEERFM_AFTERSAVEPDF)
					{
						if(not this.is_closing_pdf)
						{
							this.record_pagenum_for_peer(true)
						}
					}
					
					return true
				}
				
				msec_used := dev_GetTickCount64() - msec_start
				info := Format("Mineside PDF saving (+{} seconds)...", msec_used//1000)
				GuiControl_SetText(GuiName, "gu_focoBottomStatus", info)

				; todo? (ProSaving side) detect cancel flag, then break.
			}

			dev_assert(0) ; should not get here.
		}

		this.dbg1("FoxitCoedit.fndocSavePdf() success , no modify.")
	}
	
	fndocClosePdf()
	{
		Critical On
		
		this.is_closing_pdf := true
		this.was_activepdf := this.IsTargetPdfActive()
		
		Critical Off

		GuiName := FoxitCoedit.Id
	
		hwnd := this.pedHwnd
		this.dbg1(Format("FoxitCoedit.fndocClosePdf() executing..."))
		
		msec_start := dev_GetTickCount64()
		wintitle := "ahk_id " hwnd
		close_ok := false
		
		dev_WinClose(wintitle)
		
		Loop 
		{
			info := Format("[{}] Closing mineside PDF, +{} seconds"
				, dev_GetDateTimeStr(), (dev_GetTickCount64()-msec_start)//1000)
			this.txtBottomline := info
			GuiControl_SetText(GuiName, "gu_focoBottomStatus", info)
			
			close_ok := dev_WinWaitClose(wintitle, 1000) ; this delays 1 second
			if(close_ok)
			{
				this.dbg1("FoxitCoedit.fndocClosePdf() success.")
				return true
			}
			
			if(this.coedit.cancel_flag)
			{
				this.dbg1("FoxitCoedit.fndocClosePdf() canceled by user.")
				throw Exception("You canceled mineside PDF saving.")
			}
		}
	}

	fndocOpenPdf()
	{
		GuiName := FoxitCoedit.Id
		this.dbg1("FoxitCoedit.fndocOpenPdf() executing... ")
		
		if(FoxitCoedit.is_simulate_reopen_pdf_fail)
		{
			info := "FoxitCoedit.is_simulate_reopen_pdf_fail==true, so re-open pdf fails!"
			this.dbg1(info)
			throw Exception(info)
		}
		
		is_succ := false
		
		exepath := this.pedExepath
		
		; First, ensure that no process of exepath is running.
		if(WinExist("ahk_exe " exepath))
		{
			throw Exception(Format("Unexpected! fndocOpenPdf() sees ""{}"" still running.", exepath))
		}
		
		Run % exepath
		
		; Second, check that the new process really runs.
		
		Loop, 100
		{
			dev_Sleep(500)
			
			if(this.coedit.cancel_flag)
			{
				this.dbg1("FoxitCoedit.fndocOpenPdf() canceled by user.")
				throw Exception("You canceled mineside PDF Re-opening.")
			}
			
			query_title := "ahk_exe " exepath
			newhwnd := dev_GetHwndByWintitle(query_title)
			if(not newhwnd)
				continue
			
			newtitle := dev_WinGetTitle_byHwnd(newhwnd)
			
			newpdf_title := FoxitCoedit.TitleStemFromWinTitle(newtitle)
			oldpdf_title := FoxitCoedit.TitleStemFromWinTitle(this.pedWinTitle)
			
			; note: When the Foxit Editor 11 launching involves some bigs PDFs, the first-seen 
			; newtitle may be the small progress-bar's title, and we need to ignore it.
			
			if( newpdf_title==oldpdf_title )
			{
				this.dbg2("[Dbginfo] See revived Foxit new process's title: " newpdf_title)
				this.dbg1("FoxitCoedit.fndocOpenPdf() success.")
				
				; Third, grab new-process's HWND
				
				this.pedHwnd := dev_WinGet_Hwnd("ahk_exe " exepath)
				
				this.dbg1(Format("Foxit HWND updated to be: {}", this.pedHwnd))
				this.coedit.IniWriteMine("HWND", Format("0x{:X}", this.pedHwnd))
				
				this.RefreshMleDetail() ; bcz the HWND has changed
				
				; Make a diagnose
				dbgHwnd := FoxitCoedit.FindFoxitHwnd()
				if(dbgHwnd!=this.pedHwnd)
				{
					this.dbg1(Format("Strange! Hwnd by ahk_exe({}) != Hwnd by wndclass({})", this.pedHwnd, dbgHwnd))
				}
				
				is_succ := true
				break
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

				; [2024-05-29]
				if(not this.was_activepdf)
				{
					; There is no hope that Foxit UI title can match our target pdf.
					; Just assume success.
					is_succ := true
					break
				}
			}
		}

		this.is_closing_pdf := false
		this.was_activepdf := -1

		if(is_succ)
		{
			this.FollowPeerzPageNum()
			return true
		}
		else
		{
			throw Exception(Format("Bad! Foxit process ""{}"" did not launch.", exepath))
		}
	}
	
	Try_SaveCurrentPdf()
	{
		hwnd := this.pedHwnd
	
		wParam := 0xE103 ; We know it by using SpyEx on Foxit main-window.
		
		this.dbg2(Format("Sending WM_COMMAND to HWND=0x{:X}, wParam=0x{:X} (Save PDF)", hwnd, wParam))
		dev_PostMessage(hwnd, win32c.WM_COMMAND, wParam, 0)
		; -- Using WM_COMMAND is much more reliable than simulating Ctrl+S keypress.
		;    Effective for both Foxit Reader 7 and Foxit Editor 11
	}
	
	RefreshMineFoxitHwnd()
	{
		; Imagine, user may close and re-open Foxit Reader/Editor process out of FoxitCoedit's control
		; (e.g. Foxit crashes and user reopens it). In this case, our recorded this.pedHwnd becomes 
		; invalid, and, to avoid the hassle of requiring both sides to re-sync, we can make better 
		; UI experience by auto-detecting new Foxit window and updating our this.pedHwnd automatically.
		; We'll do this in our Timer proc.
		
		old_hwnd := this.pedHwnd
		
		if(this.pedHwnd and this.pedHwnd!="*")
		{
			nowtitle := dev_WinGetTitle_byHwnd(this.pedHwnd)
			if(nowtitle)
			{
				; Current this.peHwnd still valid. 
				; Do not care its title content, bcz user may temporarily switch to another doc tab.
				return 
			}
		}
		
		hwnd := FoxitCoedit.FindFoxitHwnd()
		if(!hwnd) 
		{
			this.pedHwnd := "*"
		}
		else
		{
			nowtitle := dev_WinGetTitle_byHwnd(hwnd)
			
			if(FoxitCoedit.IsTitleStemMatch(nowtitle, this.pedWinTitle))
			{
				this.pedHwnd := hwnd ; OK, update old this.pedHwnd
			}
			else
			{
				this.pedHwnd := "*"
			}
		}
		
		if(old_hwnd != this.pedHwnd)
		{
			this.coedit.IniWriteMine("HWND", FoxitCoedit.FormatHwnd(this.pedHwnd))
		}
	}
	
	GetFoxit_PageNum_Editbox() ; return its hwnd
	{
		; The PageNum editbox is a child-window of a HWND with class name like "BCGPRibbonStatusBar:1230000:8:10007:10"
		; So we go through all "Edit" window-classes, checking their parent class of that "BCGPRibbonStatusBar"
		
		wintitle := "ahk_id " this.pedHwnd ; the foxit top-level window
		arClassnn := dev_WinGet_ControlList(wintitle)
		
		childwnds := arClassnn.Length()
		if(childwnds<10)
		{
			; [2024-05-28] This can happen when Foxit process has just started 
			; (Seen on Foxit 11, array length just 3), so the Editbox has not been created.
			this.dbg1(Format("Info: GetFoxit_PageNum_Editbox() sees childwins only {}, maybe Foxit is just starting up.", childwnds))
		}

		arEditHwnds := []

		for index,classnn in arClassnn
		{
			if(not StrIsStartsWith(classnn, "Edit"))
				continue
		
			hEdit := dev_GetHwndFromClassNN(classnn, wintitle)
			
			hctlp := dev_GetParentHwnd(hEdit)
			
			classp := dev_GetClassNameFromHwnd(hctlp)

;			AmDbg0(Format("{} : class={} , classp={}", index, classnn, classp))

			if(not StrIsStartsWith(classp, "BCGPRibbonStatusBar"))
				continue
			
			arEditHwnds.Push(hEdit)
		}
		
		; Now consider arEditHwnds[]
		; [CASE 1] For Foxit Reader 7.1.5, len(arEditHwnds) should be one, and that is the PageNum editbox.
		; [CASE 2] For Foxit Editor 11, len(arEditHwnds) should be two, one is the PageNum, the other is the PageZoom.
		;          The PageZoom text is like "100%", "66.67%" etc.
		;          Note: PageZoom text may be blank string when Foxit Editor 11 exe is just starting up.
		
		count := arEditHwnds.Length()
		if(count==0)
			return 0
		
		if(count==1)
			return arEditHwnds[1]
		
		; Now for count==2
		text1 := dev_ControlGetText_hwnd(arEditHwnds[1])
		text2 := dev_ControlGetText_hwnd(arEditHwnds[2])

		hasSlash1 := InStr(text1, "/") ; example: "xi (13 / 179)"
		hasSlash2 := InStr(text2, "/") 

		hasPct1 := InStr(text1, "%")
		hasPct2 := InStr(text2, "%")
		
		if(!hasPct1 and !hasPct2)
		{
			this.dbg1(Format("PdfPageNum: Two editbox both lack '%': '{}' | '{}'", text1, text2))
			; Sometimes, I saw in Foxit Editor 11:
			/*
0*[20240531_11:36:59.044] (+0.016s) PdfPageNum: Two editbox both lack '%': '' | '64 (82 / 237)'
0*[20240531_11:36:59.621] (+0.000s) PdfPageNum: Two editbox both lack '%': '63.00' | '64 (82 / 237)'
			*/
		}
		
		if(hasSlash1)
			return arEditHwnds[1]
		else if(hasSlash2)
			return arEditHwnds[2]

		if(!hasPct1)
			return arEditHwnds[1]
		else if(!hasPct2)
			return arEditHwnds[2]
		else
			return 0 ; unlikely
	}
	
	record_pagenum_for_peer(is_force:=false)
	{
		; Write mineside PDF page number to INI, to tell peer Foxit jump to that very page.
		; The Foxit pagenum editbox may have text like this: "xi (13 / 179)" .
		; In INI, we will write item like:
		;	
		;	PdfPageNum = Seq1#xi (13 / 179)
		;	PdfPageNum = Seq2#xi (13 / 179)
		; etc.
		; The Seq-ordinal (1,2,3...) is recognized by peer. Only if the ordinal increases does
		; the peer know that our-side have turned to a new pagenum.
		;
		; We increase Seq in two cases.
		; Case 1: is_force==true. 
		;         This happens when our behavior is PEERFM_ALWAYS or PEERFM_AFTERSAVEPDF,
		;         and our-side has just saved a piece of new content for the PDF.
		;         We increase the Seq even if current pagenum remains the same since previous save,
		;         --this is to force peer to follow to that pagenum.
		; Case 2: is_force==false, and our behavior is PEERFM_ALWAYS, and the pagenum now 
		;         differs to the previous write-to-ini pagenum. 
		;         This mean, our-side user has really flipped to a new PDF page a moment ago, 
		;         so, the peer should follow that pagenum.

		dev_assert(this.IsTargetPdfActive()) ; sometimes we fails on it? pending.
		if(not this.IsTargetPdfActive())
		{
			; If current window-title does not match the observing PDF, 
			; the PdfPageNum editbox may not exist, or does not reflect that of our target-pdf.
			; So do nothing.
			return false
		} 

		PdfPageNum := "" 
		hwndEdit := this.GetFoxit_PageNum_Editbox()
		
		if(hwndEdit)
		{
			PdfPageNum := dev_ControlGetText_hwnd(hwndEdit)
			
			; We may get PdfPageNum = "73 (89 / 179)" or "4 / 25", 
			; and we do not try to extract the number "73" or "4", we just transfer it to the peer verbatim.
			
			if(PdfPageNum=="")
			{
				; May be user is editing that text, just give a tooltip and ignore it.
				dev_TooltipAutoClear("Debug-info: Foxit's pagenum editbox is empty.")
				return false
			}
		}
		else
		{
			; AmDbg0( "PdfPageNum-null:`n" dev_getCallStack() )
			this.ModalMsgBox_ShowWarning("Unexpect! Cannot locate Foxit's PageNum editbox.")
		}
		
		if(!is_force)
		{
			if(PdfPageNum==this.mine_prev_PdfPageNum)
			{
				this.dbg2(Format("Mine PdfPageNum not changed since last check. No writing to INI. '{}'", PdfPageNum))
				return false
			}
			
			if(PdfPageNum==this.peer_prev_pagenum)
			{
				this.dbg2(Format("Mine PdfPageNum equals .peer_prev_pagenum '{}', so don't echo back. No writing to INI.", PdfPageNum))
				this.mine_prev_PdfPageNum := PdfPageNum
				return false
			}
		}
		
		; Write to INI.
		
		this.mine_prev_PdfPageNum := PdfPageNum
		
		this.mine_pagenum_seq++
		pagenum_spec := Format("Seq#{};{}", this.mine_pagenum_seq, PdfPageNum)
		
		this.dbg1(Format("Writing to INI new pagenum-spec: '{}'", pagenum_spec))
		this.coedit.IniWriteMine("PdfPageNumSpec", pagenum_spec)
		
		this.peer_prev_pagenum := "" ; eliminate its influence. If kept(e.g. page 24), it block us from suggesting page 24 in the future.
		
		return PdfPageNum ? true : false
	}
	
	FollowPeerzPageNum()
	{
		pagenum_spec := this.coedit.IniReadPeer("PdfPageNumSpec", "")
		if(not pagenum_spec)
			return

		hwndEditbox := this.GetFoxit_PageNum_Editbox()
		if(not hwndEditbox)
			return
		
		parts := StrSplit(pagenum_spec, ";") ; Example: Seq#6;19 (35 / 179)
		seqpart := parts[1]
		PdfPageNum := parts[2]
		
		if(SubStr(seqpart, 1, 4)=="Seq#")
		{
			peer_now_pagenum_seq := SubStr(seqpart, 5)
			
			if(peer_now_pagenum_seq == this.peer_prev_pagenum_seq)
			{
				this.dbg2(Format("Peer PdfPageNum 'Seq#{}' has not updated, no need to follow.", peer_now_pagenum_seq))
				return
			}
		}
		else
		{
			this.dbg1(Format("Wrong PdfPageNum-spec from INI: '{}'", pagenum_spec))
			return
		}
		
		this.peer_prev_pagenum_seq := peer_now_pagenum_seq
		this.peer_prev_pagenum := PdfPageNum
		
		this.dbg1(Format("Peer has updated PdfPageNum to 'Seq#{};{}', now follow it.", peer_now_pagenum_seq, PdfPageNum))

		dev_ControlSetText_hwnd(hwndEditbox, PdfPageNum)
		dev_ControlSend_hwnd(hwndEditbox, "{Enter}")
		
		this.msec_passive_followed := dev_GetTickCount64()
	}
	
	
	LoadStaticCfg()
	{
		dev_assert(this.coedit.docpath!="")
		cfgfile := dev_SplitExtname(this.coedit.docpath) . ".FoxitCoEdit.ini"
		; cfgfile: "somebook.FoxitCoEdit.ini"

;		[cfg]
;		OpenSecs=6
;		SaveSecs=20
		
		cfgdict := dev_IniReadSectionIntoDict(cfgfile, "cfg")
		; -- [2024-06-05] currently no cfg-item is defined.
	}
	
	DdlPeerFollowMeSelect()
	{
		this.peerfm_selection := GuiControl_GetValue(FoxitCoedit.Id, "gu_focoDdlPeerFollowMe")
		; AmDbg0(".peerfm_selection=" this.peerfm_selection )
	}
	
	ModalMsgBox_ShowWarning(text, title:="")
	{
		if(title=="")
			title := "FoxitCoedit Warning"
		
		GuiName := FoxitCoedit.Id
		Gui_Show(GuiName, "AutoSize", FoxitCoedit.Id)
		Gui_ChangeOpt(GuiName, "+OwnDialogs")
		dev_MsgBoxWarning(text, title)
	}
	
	fndocNotifySSState(start_secs, dstate, sub_start_secs, errmsg)
	{
		GuiName := FoxitCoedit.Id
		
		;
		; == General operation: Update bottom-line text. ==
		;
;AmDbg0("===this.coedit.state: " this.coedit.state)
		dev_assert(this.coedit.state=="ProSaving" or this.coedit.state=="PasReload")
		is_prosave := this.coedit.state=="ProSaving" ? true : false
		
		info := Format("[{}] Elapsed {} seconds ({} +{} secs)..."
			, is_prosave ? "Saving PDF" : "Reloading PDF"
			, start_secs, dstate, sub_start_secs)
		
		; some override:
		if(dstate=="PRO_Success") {
			info := Format("[{}] PDF saved, cost {} seconds.", dev_GetDateTimeStr(), start_secs)
		}
		else if(dstate=="PAS_Success") {
			info := Format("[{}] PDF reloaded, cost {} seconds.", dev_GetDateTimeStr(), start_secs)
		}
		
		GuiControl_SetText(GuiName, "gu_focoBottomStatus", info)
		this.txtBottomline := info
		
		;
		; == Special operation for passive side: == (pattern similar to calling LaunchSaveDocSession)
		;
		
		if(dstate=="PAS_DoMineClose")
		{
			GuiControl_SetText(GuiName, "gu_focoBtnResync", "Cancel Reloading")
		}
		else if(dstate=="PAS_Success" or dstate=="PAS_Fail")
		{
;AmDbg0("===EEEEEEEEEEnd:" dstate)
			GuiControl_SetText(GuiName, "gu_focoBtnResync", FoxitCoedit.BtnTextResync)
			GuiControl_Enable(GuiName, "gu_focoBtnResync") ; may have been disabled in OnBtnResync()
			
			if(dstate=="PAS_Fail")
			{
				this.coedit.SetMinePasseq(0) ; Indicate mineside failure to peer.
				
				this.DisplaySyncLostPopup(errmsg)
				
				; this.ResyncCoedit() 
				; Code improvement pending: Currently, we are in PeersCoedit's callback,
				; so we should not call this.ResyncCoedit() immediately, user should click Re-sync button manually.
			}
		}
	}
	
	DisplaySyncLostPopup(errmsg)
	{
		this.is_showing_syncerr_msgbox := true
		
		full_errmsg := Format("{}`n`nSomething has gone wrong! Click OK to re-sync.", errmsg)
		this.ModalMsgBox_ShowWarning(full_errmsg, FoxitCoedit.Id)

		this.txtBottomline := "Something gone wrong, you should Re-sync."
		
		this.is_showing_syncerr_msgbox := false
	}
	
	RecheckPdfModifiedState()
	{
		is_modified := this.IsPdfModified()
		this.dbg2(Format("this.was_doc_modified={} , (now) is_modified={}", this.was_doc_modified, is_modified))

		if(this.was_doc_modified != is_modified)
		{
			; Write to INI to indicate to other side
			this.was_doc_modified := is_modified
			this.coedit.IniWriteMine("is_modified", is_modified)
		}
		
		return is_modified
	}
	
} ; class FoxitCoedit


Foxit_testFollowPagenum()
{
	g_foco.FollowPeerzPageNum()
}

 
FoxitCoedit_LaunchUI()
{
	if(!g_foco)
	{
		g_foco := new FoxitCoedit()
	}

	g_foco.ShowGui()
}

FoxitCoedit_CtrlS()
{
	if(!g_foco)
	{
		g_foco := new FoxitCoedit()
	}

	g_foco.CtrlS()
}

Foco_OnBtnSavePdf()
{
	g_foco.OnBtnSavePdf()
}

Foco_OnBtnResync()
{
	g_foco.OnBtnResync()
}


FoxitCoeditGuiSize()
{
	rsdict := {}
	rsdict.gu_focoMleInfo := JUL.FillArea
	rsdict.gu_focoLblActivate := JUL.PinToLeftBottom
	rsdict.gu_focoCkbLside := JUL.PinToLeftBottom
	rsdict.gu_focoCkbRside := JUL.PinToLeftBottom
	rsdict.gu_focoLblPeerFollow := JUL.PinToLeftBottom
	rsdict.gu_focoDdlPeerFollowMe := JUL.PinToLeftBottom
	rsdict.gu_focoBtnSavePdf := JUL.PinToLeftBottom
	rsdict.gu_focoBtnResync := JUL.PinToRightBottom
	rsdict.gu_focoBottomStatus := JUL.FillWidth_AtBottom
	
	dev_GuiAutoResize(FoxitCoedit.Id, rsdict, A_GuiWidth, A_GuiHeight)
}

FoxitCoeditGuiClose()
{
	g_foco.HideGui()
}

FoxitCoeditGuiEscape()
{
	g_foco.HideGui()
}


Foco_CkbActivateCoedit()
{
	g_foco.CkbActivateCoedit()
}

Foco_OnDdlPeerFollowMe()
{
	g_foco.DdlPeerFollowMeSelect()
}

; !#y:: g_foco.fndocSavePdf()

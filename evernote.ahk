
AUTOEXEC_Evernote: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

/* APIs:
Evp_LaunchUI()
;
EverTable_LaunchUI()
PreviewHtml_ShowGui(html)
ColorMatrix_ShowGui()
;
evernote_InitEvxLinks() ; optional, auto called by the following two:
Evernote_PopLinkShowMenu()
Evernote_PopLinkShowAutoPickupMenu()
;
Evernote_PopupInlinePasteMenu()
Evernote_PopupBlockPasteMenu()

Evernote_PasteSingleLineCode(bgcolor, is_monofont, keep_orig_clipboard)
Evernote_PasteSingleLineWithHtmlDeco(str_decofunc)

*/

; User can define g_evtblColorCustoms[] to append custom colors to g_evtblColorPresets
global g_evtblColorPresets := [ "#f0f0f0,清淡灰" 
	, "#e0e0e0,代码灰"
	, "#c6e2ff,多云蓝"
	, "#ecf8ff,晴空蓝"
	, "#e0f0f0,灰蓝"
	, "#f0e0f0,暗紫"
	, "#f0f0ff,灰紫"
	, "#fefedc,淡雅黄"
	, "#fff8e0,淡橙"
	, "#f0e0e0,浅栗红"
	, "#e0f0e0,薄荷绿"
	, "#f0f0e0,药片黄"
	, "#e0c0ff,罗兰紫"
	, "#f8e8ff,淡紫"
	, "#ffe0b0,霞光橙"
	, "#deffbe,青芽绿"
	, "#ffe6e6,粉饼红"
	, "#EEe0c0,浅棕" 
	, "#f890c0,胭脂红"
	, "#FFA090,石榴红"
	, "#FEFE8C,明亮黄"
	, "#FFE266,日落黄"
	, "#F2F8b4,枯叶黄"
	, "#B0E0B0,青瓷绿(celadon)"
	, "#74C4C4,深海绿"
	, "#C0FF00,荧光绿"
	, "#40A0FF,水手蓝"
	, "#AAE8FF,深空蓝"
	, "#F86030,深橙色"
	, "#D46262,深栗红"
	, "#DC143C,深红(crimson)"
	, "#704214,深褐色(sepia)"
	, "#614051,茄紫色(eggplant Ubuntu)"
	, "#50C878,祖母绿(Emerald)"
	, "#40E0D0,绿松石(turquoise)"
	, "#C8A2C8,丁香紫(lilac)"
	, ""
	, ""
	, "#FFFFFF,Pure White" ]


global g_evpAppsKeyPressdownTick := 0

;;;;;;;; Everpic global vars ;;;;;;;;;;

global g_evpTempDir := A_Temp "\Everpic"
global gc_evpBatchConvertExecpath := A_ScriptDir "\exe\everpic-batch-prepare.bat"

global g_evpBaseImageFilepath_100pct
	; If user choose a new scale, we use g_evpBaseImageFilepath_100pct to re-generate
	; new scaled images, instead of re-generate from clipboard.
	; Note: The so-called "BaseImage", is always in g_evpTempDir.
;global g_evpBaseImageFilepath_scaled ; no use

global g_evpImageWidth
global g_evpImageHeight

global g_evpImglistTxtPath
global g_evpBatchProgressFilepath
global g_evpImageSig := ""
	; need it as "signature" in Evernote image footnote. by Evp_GenImageSigByTimestamp().
	; Example: "everpic-20221205_150413"

global g_evpTempPreserveMinutes := 60*24 ; default to one day

global g_evpHwndToPaste

global gc_evpImgpaneDefWidth  := 400 ; image-pane default width
global gc_evpImgpaneDefHeight := 300
global g_evpImgpaneWidth      := gc_evpImgpaneDefWidth  ; To be filled in Evp_ShowGui()
global g_evpImgpaneHeight     := gc_evpImgpaneDefHeight ; To be filled in Evp_ShowGui()
global gc_evpCol1Width     := 160 ; EVP GUI Column 1 width in pixels
global gc_evpGapX := 10 ; const, gap between listbox and pic-control
global gc_evpGapY := 10 ; const, gap between listbox and pic-control
global gc_evp_GUIDefWidth := gc_evpGapX*2 + gc_evpCol1Width + gc_evpImgpaneDefWidth ; GUI default width

global gar_evpScalePcts := [ 100, 75, 50, 40, 30, 20 ]

global gc_evpMarginX := 10 ; const
global gc_evpMarginY := 10 ; const
global g_evpWindowBorder := 14 ; assume, may not be accurate yes
global g_evpBottomLineHeight := 16 ; for Button OK/Dismiss/Use_This

global g_HwndEVPGui

global gc_evp_CF_BITMAP := 2

; First column controls:
;
global gu_evpBtnCvtFromClipbrd := ""  ; The top-left corner "Convert from Clipboard" button
global gu_evpCkbAutoConvert    := 0
global gu_evpTxtScale   := ""  ; the small "Scale:" text label
global gu_evpCbxScalePct := 0  ; The image-scale percent combobox
global gu_evpBtnCvtFromBaseImg := ""  ; The Refresh button that converts from existing Base-image
global g_evpCurrentScalePct := 100
global gu_evpLbxImages   := 0  ; Image-candidates list listbox 
global gu_evpEdrLoadStat := "" ; Small text label, result statistics, e.g, "640*480, 0.2s"
;
; Second column controls:
;
global gu_evpTxtClipbState := "" ; Text label showing clipboard state.
global gu_evpIcnWarnNoTranspixel := "" ; Icon warning "no transparent pixel in png"
global gu_evpCkbKeepPngTrans := ""

global gu_evpEdrBaseImgFilepath := "" ; Currently previewing image filepath (readonly editbox)
global gu_evpPicPreview ; gui-assoc, Picture control
global g_evpCurPngHasTranspx := false ; Current png has transparent pixel? Detected by Evp_TimerProcCheckPngfileTranspixel()
;
global gu_evpBtnOK := "" ; Left-bottom "Use This" button
global gu_evpCkbAutoPaste  := ""
global gu_evpCkbKeepWindow := ""

global gu_evpEdrFootline   := "" ; current select image filepath
global gu_evpBtnCopyFile   := "" ; the button at right edge of gu_evpEdrFootline

global gc_evpIconBtnWidth := 25

global g_evpIsGuiVisible := false
global g_evpConvertStartCount := 0 ; increase one each time Launch convert.
global g_evpConvertSuccCount := 0

global gc_evpConvertBtnText := "&Convert from Clipboard"
global g_evpTimerStage := "Monitoring" 
	; "Monitoring" : Periodically check(monitor) the clipboard for image or CF_BITMAP or image-filepath.
	; "ConvertStarting" : External everpic-batch-prepare.bat launched, waiting for <basename>.progress.done.txt .
	; "ConvertStarted"  : <basename>.progress.done.txt detected, checking its content for progress.
global g_evpTickConvertStart := 0
global g_evpIsCancelling := false

global gc_evpFileSuffix_progressdone := ".progress.done.txt"
global gc_evpFileSuffix_imagelist    := ".imagelist.txt"

global gc_evpStartingTimeoutSec := 3
global g_evpBgCvtProcessId := 0

global g_evp_arImageStore := [] ; g_evp_arImageStore[1] refers to the first previewed image.
	; members: .hint .filelen_desc .path
global g_evpImageZoom := 1

global gut_progressbar := ""

global g_isKeepPngTransparent
global gc_KeepPngTransparent := true ; as synonym for true

global g_evpIsFullUIExpaned := -1 ; -1 means unset

global g_evp_hClipmon ; Clipboard monitor handle
global g_evp_ClipmonSeqNow := 0 ; Clipboard change sequence-number
global g_evp_ClipmonSeqAct := 0 ; The sequence-number on which we have done image-conversion.

global g_evpDbgCfg := {"showdbginfo":false, "showdbgcleanup":false, "showbgcmd":false, "slowbgcmd":0}

global g_evpSuppressUicTooltipBfrThis := A_Now ; will store A_Now format string

; =======

global g_HwndEvtbl

global text_ColorPreview := "Color Preview"

global g_evtblComboColor
global g_evtblHwndComboColor
global g_evtblComboColor2
global g_evtblHwndComboColor2
global g_evtblPreviewBox
global g_evtblPreviewText
global g_evtblPreviewBox2
global g_evtblPreviewText2
global g_evtblPreviewMix ; embed IE html
global g_evtblIsBlackText
global g_evtblUse2ndColor
global g_evtblIsWhiteText
global g_evtblBtnColorMatrix
global g_evtblBtnColorMatrix2

global g_evtblIsDiv         ; <DIV>
global g_evtblIsTable       ; <TABLE>
global g_evtblIsCssTable    ; This is for CssTable
global g_evtblIsSpan        ; <span> inline text with bgcolor
global g_evtblSpanText      ; User text that will appear in resulting html <span> tag
global g_evtblIsSpanMono    ; Whether use monospaced text in <span>
;
global Evtbl_OnTableDivSwitch
;
global g_evtblEdtCsstableRows
global g_evtblLblCsstableRows
global g_evtblChkboxCsstableHead

global lbl_TableColumnSpec, lbl_TableCellPadding, lbl_TableBorderPx
global g_evtblTableColumnSpec
global g_evtblCssTableColumnSpec ; This is for CssTable
global g_evtblIsFirstColumnColor
global g_evtblBorder1px
global g_evtblBorder2px
global g_evtblIsPaddingSparse
global g_evtblIsPaddingDense

global g_evtblBtnOK
global g_evtblChkboxTSV

global g_evtblHwndToPaste

global g_HwndPreviewHtml ; GuiName: PvHtml
global g_PvhtmlEdit
global g_PvhtmlClipboard
global g_PvhtmlMsg

global g_HwndColorMatrix
 ; global gar_ColorCellHwnd:=[]
global gar_colordict := [] ; to be filled according to g_evtblColorPresets
global COLORCELLs_perline := 5
global COLORCELL_width := 130
global COLORCELL_xgap := 20 ; exp with 60
global COLORCELL_xmargin := 10 ; exp with 40
global COLORCELL_xspan := (COLORCELL_width+COLORCELL_xgap)
global COLORCELL_height := 30
global COLORCELL_ygap := 10
global COLORCELL_ymarginTop := 36
global g_HiddenCtrlYD
global COLORCELL_yspan := (COLORCELL_height+COLORCELL_ygap)
global g_colormatrixIsWhiteText
;
global g_varnameComboColorOut := "" ; output-target for color-matrix GUI (just like a return value)
global g_evtblBox1HalfPos := {} ; Box x,y,w,h when only 1st color is used.
global g_evtblBox1FullPos := {} ; Box x,y,w,h when 1st and 2nd color is used.

global g_evtblIdxDefaultColor1 := 2
global g_evtblIdxDefaultColor2 := 1

global g_evtbl_IE11_ok := false

global g_matrixColor1, g_matrixColor2, g_matrixColor3, g_matrixColor4, g_matrixColor5, g_matrixColor6, g_matrixColor7, g_matrixColor8, g_matrixColor9, g_matrixColor10
global g_matrixColor11, g_matrixColor12, g_matrixColor13, g_matrixColor14, g_matrixColor15, g_matrixColor16, g_matrixColor17, g_matrixColor18, g_matrixColor19, g_matrixColor20
global g_matrixColor21, g_matrixColor22, g_matrixColor23, g_matrixColor24, g_matrixColor25, g_matrixColor26, g_matrixColor27, g_matrixColor28, g_matrixColor29, g_matrixColor30
global g_matrixColor31, g_matrixColor32, g_matrixColor33, g_matrixColor34, g_matrixColor35, g_matrixColor36, g_matrixColor37, g_matrixColor38, g_matrixColor39, g_matrixColor40
global g_matrixColor41, g_matrixColor42, g_matrixColor43, g_matrixColor44, g_matrixColor45, g_matrixColor46, g_matrixColor47, g_matrixColor48, g_matrixColor49, g_matrixColor50
global g_matrixColor51, g_matrixColor52, g_matrixColor53, g_matrixColor54, g_matrixColor55, g_matrixColor56, g_matrixColor57, g_matrixColor58, g_matrixColor59, g_matrixColor60
global g_matrixColor61, g_matrixColor62, g_matrixColor63, g_matrixColor64, g_matrixColor65, g_matrixColor66, g_matrixColor67, g_matrixColor68, g_matrixColor69, g_matrixColor70
global g_matrixColor71, g_matrixColor72, g_matrixColor73, g_matrixColor74, g_matrixColor75, g_matrixColor76, g_matrixColor77, g_matrixColor78, g_matrixColor79, g_matrixColor80
global g_matrixColor81, g_matrixColor82, g_matrixColor83, g_matrixColor84, g_matrixColor85, g_matrixColor86, g_matrixColor87, g_matrixColor88, g_matrixColor89, g_matrixColor90
; ======

global g_HwndSupsub
global g_SupsubBaseText
global g_SupsubSupText
global g_SupsubSubText

; ======

global g_evernotePopLinksFile := "EvernotePopupLinks.csv.txt"
; -- In customize.ahk, you can override this global var to point to your own file.

class Evnt
{
	static MAX_AutoEvxlinks := 20
	static arAutoEvxlinks := []
	; -- each element is a dict, d.word="AmHotkey" d.link="https://www.evernote.com/shard/s21/nl/2425275/..."
	
	static hcmEvxlink := 0 ; HANDLE from Clipmon_CreateMonitor()
	
	static filenamEvxlinks := "EvernoteAutoEvxLinks.txt"
	
	static pastecode_start_numline := 1
}


QSA_DefineActivateSingle_Caps("m", "ENMainFrame", "Evernote")
QSA_DefineActivateGroupFlex_Caps("n", "ENSingleNoteView", QSA_NO_WNDCLS_REGEX, "^(?!#ENS).+", "Evernote Single-note")
	; Match any single note whose title does NOT starts with #ENS

Evernote_InitThisModule()


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


#Include %A_LineFile%\..\libs\CtlColorStatic.ahk
#Include %A_LineFile%\..\libs\Gdip_All.ahk
#Include %A_LineFile%\..\libs\GenHtmlSnippet.ahk
#Include %A_LineFile%\..\libs\ClipboardMonitor.ahk

Evernote_InitThisModule()
{
	evernote_InlinePaste_InitMenu()

	evernote_InitHotkeys()
	
;	evernote_InitEvxLinks()
	; -- This will create a clipboard monitor client, which is a cost of system-resource,
	;    so postpone it to Evernote_PopLinkShowMenu() and Evernote_PopLinkShowAutoPickupMenu()
	;    If you really need it as early as possible, please call it in customize.ahk .
}


evernote_InitHotkeys()
{
	; App+t to callup EverTable UI
	fxhk_DefineComboHotkeyCond("AppsKey", "t", "Evernote_IsMainFrameOrSingleActive", "EverTable_LaunchUI")
	
	; App+c to callup Everpic UI, we make it global hotkey.
	; This converts in-clipboard image to your preferred format(png/jpg) and put CF_HTML content into clipboard,
	; so Ctrl+v pasting it into Evernote saves quite much space (Evernote defaultly gives you very big PNG-32).
	fxhk_DefineComboHotkey("AppsKey", "c", "Evp_LaunchUI")

}

;
; [2021-12-24] Load EvernotePopupLinks.csv.txt and popup a live menu for user to select a shortcut link,
; then send the corresponding html snippet to clipboard so to paste into Evernote, the final result is: 
; we get a real Evernote link in our Evernote clip(n.). I find myself need to frequently insert topic-link 
; like [WinGUI] [AutoHotkey] [MSBuild] etc in my clip, and this becomes a great time saver.
;
#If Evernote_IsMainFrameOrSingleActive()
AppsKey & k:: Evernote_PopLinkShowMenu()
#If


Evp_WinTitle()
{
	return "Everpic v2023.01"
}

evpdbg(msg)
{
	if(g_evpDbgCfg.showdbginfo)
		Dbgwin_Output(msg)
}

Evp_LaunchUI()
{
	if(!dev_CreateDirIfNotExist(g_evpTempDir))
	{
		dev_MsgBoxError("Error. Cannot create folder: " g_evpTempDir)
		return
	}
	
	; Remember current active window, it becomes paste target later
	g_evpHwndToPaste := dev_GetActiveHwnd()
	
	was_gui_visible := g_evpIsGuiVisible

	Evp_ShowGui()

	Gui_Show("EVP", "", Evp_WinTitle()) ; This ensures EVP is brought to front(not passing "NoActive" option)

	; If the EVP GUI has been on screen, and user calls up Evp_LaunchUI(), and there is currently
	; no bitmap in the clipboard, our UI will keep *silent* (=not popping a msgbox saying clipboard is empty).
	; This decision matches such a usage scenario: 
	; * User ticks [Keep window], wanting to keep EVP GUI on the screen (perhaps on his secondary monitor);
	; * Then user picks "png (8 colors)" to paste into Evernote, leaving EVP GUI on screen;
	;   (Now, clipboard has CF_HTML, not a bitmap or bitmap-filepath.)
	; * After some Evernote editing, user calls up Evp_LaunchUI( AppsKey&c ), this time, he probably wants 
	;   to pick another image vairant to use, "jpg (60%)" for example. 
	; -- At this point, we'd better not telling the user "No bitmap in clipboard", instead we'd better 
	;    keep the EVP UI silent so the user can pick "jpg (60%") from last time.
	
	if(was_gui_visible)
	{
		hasbm := Evp_IsBitmapInClipboard(bitmap_filepath)
		if(!hasbm and !bitmap_filepath)
			return ; keep EVP UI silent
	}

	Evp_LaunchConvert_fromClipboard()
}

Evp_ShowGui()
{
	if(g_evpIsGuiVisible)
		return

	if(!g_HwndEVPGui) {
		
		Evp_CreateGui()
		
	} else {
;		MsgBox, % "Skip Evp_CreateGui()"
	}

	Evp_AutosizeNowUI() ; Gui, EVP:Show inside

	g_evpIsGuiVisible := true
	
	dev_OnMessageRegister(0x200, "Evp_WM_MOUSEMOVE")
	dev_OnMessageRegister(0x111, "Evp_WM_COMMAND")
	dev_OnMessageRegister(0x205, "Evp_WM_RBUTTONUP")

	g_evp_hClipmon := Clipmon_CreateMonitor(Func("Evp_ClipmonCallback"), "Evp_ShowGui")
	g_evp_ClipmonSeqNow := 0
	g_evp_ClipmonSeqAct := 0
	
	Evp_TimerOn()
}

Evp_CleanupUI()
{
	Evp_TimerOff()
	
	Clipmon_DeleteMonitor(g_evp_hClipmon)
	
	dev_OnMessageUnRegister(0x200, "Evp_WM_MOUSEMOVE")
	dev_OnMessageUnRegister(0x111, "Evp_WM_COMMAND")
	dev_OnMessageUnRegister(0x205, "Evp_WM_RBUTTONUP")
	
	Gui, EVP:Hide	; I will not do EVP:Destroy. If really want, just Reload the AHK script.
	g_evpIsGuiVisible := false
}

EVPGuiEscape(hwndGui)
{
;	dev_TooltipAutoClear("EVPGuiEscape() called")
	Evp_CleanupUI()
}

EVPGuiClose(hwndGui)
{
;	dev_TooltipAutoClear("EVPGuiClose() called")
	Evp_CleanupUI()
}



Evp_CreateGui()
{
	; Evp: short for "Everpic"
	; This UI will generate a series of image previews with different quality,
	; then user can pick the "best" one to use(paste it into Evernote).

	Gui, EVP:New ; Destroy old window if any
	Gui_AssociateHwndVarname("EVP", "g_HwndEVPGui") ; Gui hwnd generated in g_HwndEVPGui
	Gui_SetXYMargin("EVP", gc_evpMarginX, gc_evpMarginY)
	Gui_Switch_Font("EVP", 9, "Black", "Tahoma") ; Gui, EVP:Font, s9 cBlack, Tahoma

	fullwidth := Evp_CalCtrlFullWidth()
	
	; ==== Create Column1 controls. ====
	;
	col1w := gc_evpCol1Width
	Gui_Add_Button(  "EVP", "gu_evpBtnCvtFromClipbrd", col1w, "Section xm ym g" . "Evp_evtCvtFromClipboard" , gc_evpConvertBtnText)
	Gui_Add_Checkbox("EVP", "gu_evpCkbAutoConvert",    col1w, "xm+16 y+5 Hidden", "&Auto Convert")
	Gui_Add_Editbox( "EVP", "gu_evpEdrBaseImgFilepath", fullwidth, "xm y+34 Readonly -E0x200", "Base-image file path (to fill)")
	;
	lwScale := 42 ; label-width
	lwRefresh := 30
	Gui_Add_TxtLabel("EVP", "gu_evpTxtScale", lwScale, "xm+2 y+4", "&Scale:")
	Gui_Add_Combobox("EVP", "gu_evpCbxScalePct", col1w-lwScale-lwRefresh-gc_evpGapX
		, Format("x+{} yp-2 AltSubmit g{}", 0, "Evp_evtCbxScalepctChanged"))
	Gui_Add_Button(  "EVP", "gu_evpBtnCvtFromBaseImg", lwRefresh
		, Format("x+{} yp-1 g{}", gc_evpGapX, "Evp_evtCvtFromBaseImg"), "→") ; "↻" (the Refresh Unicode char) is rendered ugly, so use right-arrow instead
	;
	Gui_Add_Listbox( "EVP", "gu_evpLbxImages",   col1w, Format("xs r12 AltSubmit g{}", "Evp_RefreshImgpane"))
	Gui_Add_Editbox( "EVP", "gu_evpEdrLoadStat",  col1w, "Readonly -E0x200", "")
	Gui_Add_Button(  "EVP", "gu_evpBtnOK",       col1w, "default g" . "Evp_BtnOK", "&Use This (or press Enter)")
	;
	; Two checkboxes beside BtnOK
	Gui_Add_Checkbox("EVP", "gu_evpCkbAutoPaste", -1, "x+5 yp+5 Checked", "Auto &paste") ; Auto paste
	Gui_Add_Checkbox("EVP", "gu_evpCkbKeepWindow",-1, "x+5 yp", "Keep &window") ; Keep window

	; ==== Create Column2 controls. ====
	;
	col2w := gc_evpImgpaneDefWidth
	Gui_Add_TxtLabel("EVP", "gu_evpTxtClipbState",  col2w, Format("xs+{} ys+5 section +0x8000", col1w+gc_evpGapX), "Clipboard state")
	;
	Gui_Add_Picture( "EVP", "gu_evpIcnWarnNoTranspixel", 16, "h16 hidden +0x100") ; 0x100: SS_NOTIFY, for hovering tooltip
		Gui_Picture_SetIconFromDll("EVP", "gu_evpIcnWarnNoTranspixel", "user32.dll", 2) ; 2: yellow exclamation triangle
	Gui_Add_Checkbox("EVP", "gu_evpCkbKeepPngTrans", -1, "x+4 yp+1 c666666 Hidden g" . "Evp_ToggleKeepPngTransparent"
		, "&Keep transparent pixels when converting png file.")
	;
	Gui_Add_Picture( "EVP", "gu_evpPicPreview",     col2w, "h" g_evpImgpaneHeight) 
	
	; FootLine
	Gui_Add_Editbox( "EVP", "gu_evpEdrFootline", fullwidth-gc_evpIconBtnWidth, "xm Readonly", "Footline")
	Gui_Add_Button(  "EVP", "gu_evpBtnCopyFile", gc_evpIconBtnWidth, "x+2 g" . "Evp_CopyConvertedImageFileToClipboard", "")
	GuiButton_SetIconFromDll("EVP", "gu_evpBtnCopyFile", "shell32.dll", 243, 16, true) ; #243 is the [Copy] icon, 16 is icon size
	
	; The above GUI control layout will later be updated by Evp_SyncGuiByBaseImage()
	
	; Fill gu_evpCbxScalePct combobox
	for index,value in gar_evpScalePcts
	{
		if(index==1)
			jstr := value . "%|" ; extra "|" means default selection
		else
			jstr := jstr "|" value "%"
	}
	GuiControl_SetText("EVP", "gu_evpCbxScalePct", jstr)
	
	; Set default states of the controls:
	;
	evpdbg("UIC Disable: gu_evpBtnCvtFromClipbrd")
	GuiControl_Enable("EVP","gu_evpBtnCvtFromClipbrd", false) ; Not enabled until image in clipboard
	GuiControl_Enable("EVP","gu_evpBtnOK", false) ; Not enabled until image previews all generated
	;
	Evp_ShowAllControls(false)
	
	Gui_Show("EVP", "xCenter yCenter", Evp_WinTitle()) ; only center it when first created
	
	g_evpConvertStartCount := 0
	g_evpConvertSuccCount := 0	
}

Evp_ShowAllControls(is_show:=true)
{
	if(is_show==g_evpIsFullUIExpaned)
		return

	g_evpIsFullUIExpaned := is_show

	ctls := [ "gu_evpCkbAutoConvert"
		, "gu_evpTxtScale", "gu_evpCbxScalePct", "gu_evpBtnCvtFromBaseImg"
		, "gu_evpLbxImages", "gu_evpEdrLoadStat"
		, "gu_evpBtnOK", "gu_evpCkbAutoPaste", "gu_evpCkbKeepWindow"
		, "gu_evpEdrBaseImgFilepath"
;		, "gu_evpCkbKeepPngTrans"
		, "gu_evpPicPreview", "gu_evpEdrFootline", "gu_evpBtnCopyFile" ] 
	
	for index,value in ctls
	{
		GuiControl_Show("EVP", value, is_show)
	}
	
	Evp_AutosizeNowUI()
}

Evp_AutosizeNowUI()
{
	is_auto := GuiControl_GetValue("EVP", "gu_evpCkbAutoConvert")

	showopt := "AutoSize" . (is_auto ? " NoActivate" : "")

	Gui_Show("EVP", showopt, Evp_WinTitle())
}


Evp_CalCtrlFullWidth()
{
	; Calculate from g_evpImgpaneWidth
	;
	return gc_evpCol1Width + gc_evpGapX + g_evpImgpaneWidth
}

Evp_CalGuiFullWidth()
{
	return 2 * gc_evpMarginX + Evp_CalCtrlFullWidth()
}

Evp_GenImageSigByTimestamp()
{
	; Example: everpic-20221205_150413
	
	FormatTime, dt, , % "yyyyMMdd_HHmmss"
	return "everpic-" dt
}

Evp_BaseImageFilepathPrefix(imgsig)
{
	return Format("{}\{}", g_evpTempDir, imgsig)
}

Evp_ScaleDownImage(scale_pct, srcimgpath, dstimgpath, isKeepPngTransparent)
{
	; 2022.12.09 https://www.autohotkey.com/board/topic/52033-convertresize-image-with-gdip-solved/

	If !pToken := Gdip_Startup()
		return false

	is_succ := false

	sBitmap := Gdip_CreateBitmapFromFile(srcimgpath)
	if(sBitmap<=0)
		goto Evp_ScaleDownImage_END
	
	sWidth  := Gdip_GetImageWidth(sBitmap)
	sHeight := Gdip_GetImageHeight(sBitmap)
	
	dWidth  := sWidth  * scale_pct // 100
	dHeight := sHeight * scale_pct // 100

	dBitmap := Gdip_CreateBitmap(dWidth, dHeight)
	G := Gdip_GraphicsFromImage(dBitmap)
	
	if(!isKeepPngTransparent)
	{
		; If not isKeepPngTransparent, we set white background for it.
;pBrush2 := Gdip_BrushCreateSolid(0x80FF2000)
	
		pBrushClear := Gdip_BrushCreateSolid(0xFFffffff) 
		; -- Fill ARGB(255,255,255,255), alpha-value=255 is required.
		;    Otherwise, the default ARGB is (0,0,0,0), which will result in black bg onto jpg.
		Gdip_FillRectangle(G, pBrushClear, 0, 0, dWidth, dHeight)
;Gdip_FillRectangle(G, pBrush2, 0, 0, dWidth, dHeight)

		Gdip_DeleteBrush(pBrushClear)
;Gdip_DeleteBrush(pBrush2)
	}
	
	
	Gdip_DrawImage(G, sBitmap, 0, 0, dWidth, dHeight, 0, 0, sWidth, sHeight)
	
	err := Gdip_SaveBitmapToFile(dBitmap, dstimgpath)
	if(err)
		goto Evp_ScaleDownImage_END
		
	is_succ := true

Evp_ScaleDownImage_END:
	Gdip_DisposeImage(sBitmap)
	Gdip_DisposeImage(dBitmap)
	Gdip_DeleteGraphics(G)
	Gdip_Shutdown(pToken)
	
	return is_succ
}


Evp_evtCvtFromClipboard(CtrlHwnd, GuiEvent, EventInfo, ErrLevel:="")
{
	evpdbg(Format("In Evp_evtCvtFromClipboard().")) ; debug

	Evp_LaunchConvert_fromClipboard()
}

Evp_evtCvtFromBaseImg(CtrlHwnd, GuiEvent, EventInfo, ErrLevel:="")
{
	dev_assert(g_evpBaseImageFilepath_100pct)

	Evp_LaunchConvert_fromBaseImage(g_evpBaseImageFilepath_100pct)
}

Evp_GetUIScalePct()
{
	GuiControl_ChangeOpt("EVP", "gu_evpCbxScalePct", "-AltSubmit")
	text := GuiControl_GetText("EVP", "gu_evpCbxScalePct")
	GuiControl_ChangeOpt("EVP", "gu_evpCbxScalePct", "+AltSubmit")
	
	scale_pct := dev_str2num(text)
	return scale_pct
}

Evp_ToggleKeepPngTransparent()
{
	is_checked := GuiControl_GetValue("EVP", "gu_evpCkbKeepPngTrans")
	g_isKeepPngTransparent := is_checked ? true : false
}

Evp_CheckAndWarnConvertBusy()
{
	if(g_evpTimerStage!="Monitoring") 
	{
		is_yes := dev_MsgBoxYesNo("Previous converting is in progress. Really cancel?")
		
		if(g_evpTimerStage=="Monitoring")
		{
			; During above dialog displaying period, the conversion have been completed.
			return true ; true means "was busy"
		}

		if(is_yes)
		{
			g_evpIsCancelling := true
			
			GuiControl_Enable("EVP", "gu_evpBtnCvtFromClipbrd", false)
			; -- so to avoid "repetitive" user-cancel.
	
			is_succ := dev_KillProcessByPid(g_evpBgCvtProcessId, winerr)
			if(!is_succ)
			{
				dev_MsgBoxWarning(Format("dev_KillProcessByPid(pid={}) fails with winerr={}", g_evpBgCvtProcessId, winerr))
			}
		}
		
		return true ; true means "was busy"
	}
	else
		return false
}

Evp_LaunchConvert_fromClipboard()
{
;	evpdbg("In Evp_LaunchConvert_fromClipboard().")

	Gui_ChangeOpt(  "EVP", "+OwnDialogs")

	if(Evp_CheckAndWarnConvertBusy())
		return ""

	; make it show blank
	GuiControl_Show("EVP", "gu_evpIcnWarnNoTranspixel", false)
	; -- Memo: Using 
	;		GuiControl_SetText("EVP", "gu_evpIcnWarnNoTranspixel" , "") 
	; is problematic, bcz it will make the control-window become 0-width,
	; so when we next do Gui_Picture_SetIconFromDll(), its width *changes* to 
	; icon's actual width(no longer 16).
	
	g_evpCurPngHasTranspx := false
	
	Evp_LaunchBatchConvert()
}

Evp_LaunchConvert_fromBaseImage(fpBaseImage)
{
	Gui_ChangeOpt(  "EVP", "+OwnDialogs")

	if(Evp_CheckAndWarnConvertBusy())
		return ""

	Evp_LaunchBatchConvert(fpBaseImage)
}

Evp_LaunchConvertResetUI()
{
	g_evpConvertStartCount++

	; Clear listbox
	hwndListbox := GuiControl_GetHwnd("EVP", "gu_evpLbxImages")
	dev_assert(hwndListbox)
	dev_Listbox_Clear(hwndListbox)

	GuiControl_Enable("EVP", "gu_evpLbxImages", true)
}

Evp_LaunchBatchConvert(fpFromImage:="", scale_pct:=0)
{
	; Return BaseImage filepath, empty string if launching fail.
	
	if(scale_pct==0) {
		scale_pct := Evp_GetUIScalePct()
	}

	if(scale_pct<=1 || scale_pct>100) {
		dev_MsgBoxError("Bad Scale percent value(should be 2 ~ 100): " scale_pct)
		return ""
	}
	
	if(Evp_CheckAndWarnConvertBusy())
		return ""

	evpdbg(Format("In Evp_LaunchBatchConvert(). `r`n"
		. "    fpFromImage = {}`r`n"
		. "    scale_pct = {}"
		, fpFromImage, scale_pct))
	
	g_evp_ClipmonSeqAct := g_evp_ClipmonSeqNow ; even if fpimg100pct fails

	imgsig := Evp_GenImageSigByTimestamp()

	fpimg100pct := Evp_GenerateBaseImage(fpFromImage, scale_pct, imgsig, g_isKeepPngTransparent
		, imgw, imgh, fpimgScaled) ; these three are output-vars
		; -- filepath of the base-image, example:
		; C:\Users\win7evn\AppData\Local\Temp\Everpic\everpic-20221204_150000.png

	if(!fpimg100pct)
		return "" ; Error should have been pop-up-ed in Evp_GenerateBaseImage()

	Evp_LaunchConvertResetUI()

	dev_assert(FileExist(fpimgScaled))

	; Note: fpimgScaled has wide meaning including 100% or less-than-100% scaling.
	; We will pass this fpimgScaled image to .bat .
		
	fpImageStem := dev_SplitExtname(fpimgScaled)
		
	fpImageList := fpImageStem . gc_evpFileSuffix_imagelist
	
	stageline_png32b := Format("PNG (32-bit)*{}`r`n", fpimgScaled)

	FileDelete, % fpImageList
	FileAppend, % stageline_png32b, % fpImageList

	fpbat := gc_evpBatchConvertExecpath
	fpbatlog := fpbat ".log"
	
	; TODO: this batchcmd is NOT space-char-tolerable in its path.
	;
	stdout_to_log := "> " fpbatlog
	batchcmd := Format("cmd /c ""{} {} {}"""
		, fpbat
		, fpimgScaled
		, g_evpDbgCfg.showbgcmd ? "" : stdout_to_log)

	; We use `Run`, not `RunWait`, to avoid blocking ourselves. 
	; `Run` reports success as long as CreateProcess() succeeds. That means,
	; only when the target exe/bat(cmd.exe in this case) does not exists will we get ErrorLevel.
	; In turn, for `cmd /c foo.bat`, even if foo.bat does not exist, `Run` still report success.
	;
	; So, we'd better explictly check for .bat existence here.
	;
	if(!FileExist(fpbat))
	{
		dev_MsgBoxError(Format("Everpic missing required file: ""{}""", fpbat))
		return false
	}
	;
	opt_hidewindow := g_evpDbgCfg.showbgcmd ? "" : "Hide"
	dev_SetEnvVar("EverpicSimulateSlowCmd", g_evpDbgCfg.slowbgcmd>0 ? g_evpDbgCfg.slowbgcmd : "") ; .bat code will check this env-var
	;
	Run, % batchcmd, , UseErrorLevel %opt_hidewindow%, g_evpBgCvtProcessId
	if(ErrorLevel)
	{	; Not likely to get this.
		dev_MsgBoxError(Format("{} launch error.`n`nSee log file for reason:`n`n{}", fpbat, fpbatlog))
		return false
	}
	
	evpdbg("Everpic has launched bg-process with pid=" g_evpBgCvtProcessId)
	
	g_evpImageSig := imgsig
	g_evpBaseImageFilepath_100pct := fpimg100pct
;	g_evpBaseImageFilepath_scaled := fpimgScaled
	g_evpCurrentScalePct := scale_pct
	g_evpImageWidth  := imgw
	g_evpImageHeight := imgh
	g_evpImglistTxtPath := fpImageList
	
	g_evpBatchProgressFilepath := fpImageStem . gc_evpFileSuffix_progressdone
	if(FileExist(g_evpBatchProgressFilepath))
		FileDelete, % g_evpBatchProgressFilepath
	
	g_evpTimerStage := "ConvertStarting"
	g_evpTickConvertStart := A_TickCount

	evpdbg("UIC Enable: gu_evpBtnCvtFromClipbrd")
	GuiControl_Enable ("EVP", "gu_evpBtnCvtFromClipbrd", true)
	GuiControl_SetText("EVP", "gu_evpBtnCvtFromClipbrd", "Cancel converting")
	
	GuiControl_SetText("EVP", "gu_evpTxtClipbState", "Convert starting...")
	
	Evp_SyncGuiByBaseImage(fpimgScaled, imgw*scale_pct//100, imgh*scale_pct//100)
	
	Evp_ShowAllControls(true)
	
	if(g_evpConvertStartCount==1)
	{	; Center the UI only at the first run.
		Gui_Show("EVP", "xCenter yCenter", Evp_WinTitle())
	}
	
	return true
}

Evp_GenerateBaseImage(fpFromImage, scale_pct, imgsig, is_keeppngtrans
	, byref imgw, byref imgh, byref ofpScaled)
{
	; If fpFromImage is empty, generate the base .png image from clipboard.
	; Else, fpFromImage is the existing image file to use.
	; Return that 100pct .png filepath, empty string if fail.
	;
	; Return in `ofpScaled` the scaled 32-bit png filepath. 'o' implied output var.
	;
	; Memo: Whether scale_pct is 100, we always generate 100pct image, so that when 
	; user changes scale,we can use that 100pct image instead of re-generate from clipboard.
	;
	; This function does NOT change global vars.
	
	ofpprefix := Evp_BaseImageFilepathPrefix(imgsig)
	ptp_suffix := "-ptp"
	fp_100pctimg := ofpprefix . (is_keeppngtrans ? ptp_suffix  : "") ".png"
	fp_scaledimg := dev_AppendToStemname(fp_100pctimg, "-s" scale_pct)  ;fp_scaledimg := Format("{}-z{}.png", ofpprefix, scale_pct)

	ofpScaled := scale_pct==100 ? fp_100pctimg : fp_scaledimg

	if(FileExist(fp_100pctimg) && FileExist(ofpScaled))
	{
		dev_TooltipAutoClear("BaseImage already exists: " ofpScaled)
		return fp_100pctimg
	}

	is_100pct_succ := false ; assume fail
	
	if(!FileExist(fp_100pctimg))
	{
		If !pToken := Gdip_Startup()
		{
			dev_MsgBoxError("Gdip_Startup() failed. GDI+ problem!")
			return ""
		}

		Evp_IsBitmapInClipboard(bitmap_filepath)
		
		if(!fpFromImage && bitmap_filepath)
			fpFromImage := bitmap_filepath

		if(fpFromImage)
		{
			if(!FileExist(fpFromImage))	{
				dev_MsgBoxError("Image file does not exist:`n`n" fpFromImage)
				goto EVP_CLEANUP_20221204
			}
			
			; fpFromImage can be any format(bmp, jpg, gif, png etc)
			; We need to first save it as 32-bit png, via Gdip libray.

			bitmap := Gdip_CreateBitmapFromFile(fpFromImage)
			if(bitmap<=0) {
				dev_MsgBoxError(Format("Gdip_CreateBitmapFromFile(""{}"") fail, errcode={}.", fp_100pctimg, bitmap))
				goto EVP_CLEANUP_20221204
			}

			Gdip_GetImageDimensions(bitmap, imgw, imgh)

			dev_assert(StrIsEndsWith(fp_100pctimg, ".png", true))
			
			if(is_keeppngtrans)
			{
				err := Gdip_SaveBitmapToFile(bitmap, fp_100pctimg) ; this does not destroy png transparent pixels.
				if(err) {
					dev_MsgBoxError(Format("Gdip_SaveBitmapToFile(""{}"") fail, errcode={}.", fp_100pctimg, err))
					goto EVP_CLEANUP_20221204
				}
			}
			else 
			{
				; Inside Evp_ScaleDownImage, we call Gdip_DrawImage(), which will remove all png transparent pixels.
				; so fp_100pctimg will be non-transparent.
				succ := Evp_ScaleDownImage(100, fpFromImage, fp_100pctimg, !gc_KeepPngTransparent)
				if(!succ) {
					goto EVP_CLEANUP_20221204 ; error reported in Evp_ScaleDownImage()
				}
			}
			
			is_100pct_succ := true
		}
		else ; will get CF_BITMAP from Clipboard
		{
			bitmap := Gdip_CreateBitmapFromClipboard()
			if(bitmap<=0)
			{
				if(g_evpConvertStartCount>0)
				{
					dev_MsgBoxWarning("No bitmap in clipboard yet. Nothing to convert by Everpic.")
				}
				goto EVP_CLEANUP_20221204
			}

			Gdip_GetImageDimensions(bitmap, imgw, imgh)
			
			err := Gdip_SaveBitmapToFile(bitmap, fp_100pctimg)
			if(err) {
				dev_MsgBoxError(Format("Gdip_SaveBitmapToFile(""{}"") fail, errcode={}.", fp_100pctimg, err))
				goto EVP_CLEANUP_20221204
			}
			
			is_100pct_succ := true
		}

	EVP_CLEANUP_20221204:
	
		Gdip_DisposeImage(bitmap)
		Gdip_Shutdown(pToken)
		
	} ; if(!FileExist(fp_100pctimg))

	is_succ := false ; Re-assume faile
	
	;;; Do scale_pct if required to
	;
	if(is_100pct_succ)
	{
		if(scale_pct!=100 && !FileExist(fp_scaledimg))
		{
			succ := Evp_ScaleDownImage(scale_pct, fp_100pctimg, fp_scaledimg, is_keeppngtrans)
			if(!succ)
				return "" ; Error should have been reported inside Evp_ScaleDownImage()
		}

		is_succ := true
	}
	
	;;; Launch timer to check for png-transparent.
	; This checking is very slow, and we do NOT want to block here, so use a timer.
	;
	if(is_succ && StrIsEndsWith(fpFromImage, ".png", true) && is_keeppngtrans)
	{
		fn := Func("Evp_TimerProcCheckPngfileTranspixel").Bind(fpFromImage, g_evpConvertStartCount)
		SetTimer, % fn, -99 ; one-time timer, start after(99 ms)
	}
	
	return is_succ ?  fp_100pctimg : ""
}


Evp_WM_MOUSEMOVE(wParam, lParam, msg, hwnd)
{
	if(A_Now >= g_evpSuppressUicTooltipBfrThis)
	{
		evp_ShowUicTooltips(wParam, lParam, msg, hwnd)
	}
}

evp_ShowUicTooltips(wParam, lParam, msg, hwnd)
{
	static s_prev_tooltiping_uic := 0

	is_from_tooltiping_uic := true ; assume message is from a GuiControl

	if(A_GuiControl=="gu_evpCkbAutoPaste")
	{
		dev_TooltipAutoClear("If ticked, ""Use this"" button will paste the selected image into where you have come from(e.g. Evernote window).`r`n"
			. "If not ticked, you have to strike Ctrl+V to paste into your target application.")
	}
	else if(A_GuiControl=="gu_evpCkbKeepWindow")
	{
		dev_TooltipAutoClear("If ticked, after clicking ""Use this"" button, this Everpic window will remain visible instead of close itself.")
	}
	else if(A_GuiControl=="gu_evpCkbAutoConvert")
	{
		dev_TooltipAutoClear("Auto convert when new content in clipboard is detected.")
	}
	else if(A_GuiControl=="gu_evpBtnCvtFromBaseImg")
	{
		dev_TooltipAutoClear("Convert from current Base-image using new Scale value.")
	}
	else if(A_GuiControl=="gu_evpCkbKeepPngTrans")
	{
		dev_TooltipAutoClear("If ticked, an input png file's transparent pixels remains transparent in output pngs.`n"
			. "If not ticked, input transparent pixels becomes white pixels in output pngs.`n`n"
			. "This takes effect next time you Convert from Clipboard.")
	}
	else if(A_GuiControl=="gu_evpIcnWarnNoTranspixel")
	{
		dev_TooltipAutoClear("This input png file does NOT seem to have transparent pixels.")
	}
	else if(A_GuiControl=="gu_evpBtnCopyFile")
	{
		dev_TooltipAutoClear("Copy this file to Clipboard, so that you can paste the file to another folder.")
	}
	else
		is_from_tooltiping_uic := false
	
	if(A_Gui=="EVP")
	{
		; If mouse has *just* moved off a tooltiping UIC, we turn off the tooltip.
		; But,
		; we cannot blindly turn off tooltip here, bcz we would get constant WM_MOUSEMOVE 
		; even if we do not move the mouse; turning off tooltip blindly would cause 
		; other function's dev_TooltipAutoClear() to vanish immediately.
		;
		if(is_from_tooltiping_uic)
			s_prev_tooltiping_uic := A_GuiControl
		else if(s_prev_tooltiping_uic) {
			tooltip ; turn off tooltip
			s_prev_tooltiping_uic := 0
		}

;		xmouse := lParam & 0xFFFF , ymouse := (lParam >> 16) & 0xFFFF 
;		Dbgwin_Output(Format("In Evp_WM_MOUSEMOVE(), A_Gui==EVP, A_GuiControl={}, xmouse={}, ymouse={}. (sPrev={})"
;			, A_GuiControl, xmouse, ymouse, s_prev_tooltiping_uic))
	}
}

Evp_WM_COMMAND(wParam, lParam, msg, hwnd)
{
	hctrl := lParam
	notify_code := wParam >> 16

;	Dbgwin_Output(Format("Evp_WM_COMMAND: hwndctrl=0x{:08X} , notify_code={}", hctrl, notify_code)) ; debug
	; -- Yes, we will see lots of WM_COMMAND activity.

;	if(hctrl==g_evtblHwndComboColor && notify_code==4) ; CBN_KILLFOCUS=4
;	{
;	    Evtbl_ColorComboSetColorDualFormat()
;	}   
}

Evp_WM_RBUTTONUP(wParam, lParam, msg, hwnd)
{
	menuname := "Everpic Right-click Menu object"
	
	Evp_CreateContextMenu(menuname)
	dev_MenuShow(menuname)
}

Evp_CopyConvertedImageFileToClipboard()
{
	select_filepath := GuiControl_GetText("EVP", "gu_evpEdrFootline")
	
	Clipboard := ""
	WinClip.SetFiles(select_filepath)
	if(Clipboard==select_filepath)
	{
		g_evpSuppressUicTooltipBfrThis := dev_YMDHMS_AddSeconds(A_Now, 2)
		; -- increase g_evpSuppressUicTooltipBfrThis so that the button's stock(static) 
		; tooltip is temporarily turned off, otherwise, we would not be able to see the 
		; following new tooltip
		
		dev_TooltipAutoClear("File copied to Clipboard.")
	}
	else
	{
		dev_MsgBoxWarning("Unexpect! Copy file to Clipboard failed.")
	}
}

Evp_CreateContextMenu(menuname)
{
	menuitem := "Show Debug info"
	fnobj := Func("Evp_ToggleOnOff").Bind("g_evpDbgCfg", "showdbginfo")
	dev_MenuAddItem(menuname, menuitem, fnobj)
	dev_MenuTickItem(menuname, menuitem, g_evpDbgCfg.showdbginfo ? true : false)

	menuitem := "Show TempDir cleanup debug info"
	fnobj := Func("Evp_ToggleOnOff").Bind("g_evpDbgCfg", "showdbgcleanup")
	dev_MenuAddItem(menuname, menuitem, fnobj)
	dev_MenuTickItem(menuname, menuitem, g_evpDbgCfg.showdbgcleanup ? true : false)

	menuitem := "Show background converting CMD window"
	fnobj := Func("Evp_ToggleOnOff").Bind("g_evpDbgCfg", "showbgcmd")
	dev_MenuAddItem(menuname, menuitem, fnobj)
	dev_MenuTickItem(menuname, menuitem, g_evpDbgCfg.showbgcmd ? true : false)

	menuitem := "Simulate slow background converting"
	fnobj := Func("Evp_ToggleOnOff").Bind("g_evpDbgCfg", "slowbgcmd")
	dev_MenuAddItem(menuname, menuitem, fnobj)
	dev_MenuTickItem(menuname, menuitem, g_evpDbgCfg.slowbgcmd ? true : false)
}

Evp_ToggleOnOff(sobj, smember)
{
	; sobj and smember are both in string.

	obj := %sobj%
	obj[smember] := not obj[smember]
}

Evp_TimerOn()
{
	SetTimer, Evp_TimerProc, 500
}

Evp_TimerOff()
{
	SetTimer, Evp_TimerProc, Off
}

Evp_TimerProc()
{
	Gui_ChangeOpt(  "EVP", "+OwnDialogs")

	if(g_evpTimerStage=="Monitoring")
	{
		Evp_CheckClipboardStateUpdateUI()
		
		; ==== Check whether do Auto-convert. ====
		
		is_auto := GuiControl_GetValue("EVP", "gu_evpCkbAutoConvert")

		isnewclip := g_evp_ClipmonSeqNow > g_evp_ClipmonSeqAct ? true : false
		
		if(is_auto && isnewclip)
		{
			hasbm := Evp_IsBitmapInClipboard(bitmap_filepath)

			if(hasbm || bitmap_filepath)
			{
;				Dbgwin_Output(Format("Auto-convert again, act={} seq={} ...", g_evp_ClipmonSeqAct, g_evp_ClipmonSeqNow)) ; debug
				Evp_LaunchBatchConvert()
			}
		}
	}
	else if(g_evpTimerStage=="ConvertStarting" || g_evpTimerStage=="ConvertStarted")
	{
		Evp_CheckConvertingProgressUpdateUI()
	}
	else 
	{
		dev_MsgBoxError("Bad value of g_evpTimerStage: " g_evpTimerStage)
		dev_assert(("Bad value of g_evpTimerStage") ?0:0)
	}
	
	Evp_CleanupTempDir_withInterval()
	
}

Evp_ClipmonCallback()
{
	g_evp_ClipmonSeqNow++
}

Evp_IsImagefileSuffix(filepath)
{
	arsuffix := ["bmp", "png", "jpg", "gif"]

	if(StrLen(filepath)<8)
		return ""
   	
   	if(SubStr(filepath, 2, 1)!=":")
   		return "" ; No drive letter prefix
	
	for index,extname in arsuffix
    {
    	if(StrIsEndsWith(filepath, "." extname, true))
    		return extname
    }
    return ""
}


Evp_IsBitmapInClipboard(byref filepath_bitmap)
{
	; Two output values:
	; Return value: whether CF_BITMAP in clipboard.
	; [out] filepath_bitmap: will be a image filepath if there is one in clipboard text.
	
	filepath_bitmap := ""
	if( WinClipAPI.IsClipboardFormatAvailable(gc_evp_CF_BITMAP) )
	{
		return true
	}
	else
	{
		filepath := Clipboard ; assume filepath and check
		if(filepath && StrLen(filepath)<260 && Evp_IsImagefileSuffix(filepath))
		{
			filepath_bitmap := filepath
		}
		return false
	}
}

gdip_BitmapFindTransparentPixel(bitmap, xstart, ystart, xend_, yend_, xskip, yskip, msec_limit)
{
	; x/y param is 0-based, Gdip-style.
	; return an object(.is_found .x .y) telling the position of the first-found transparent pixel
	
	msec_start := A_TickCount
	
	y := ystart
	Loop ; y-loop
	{
		x := xstart
		Loop ; x-loop 
		{
			
			ARGB := Gdip_GetPixel(bitmap, x, y) ; Gdip
			if( (ARGB & 0xFF000000) != 0xFF000000 ) 
				return {"is_found":true, "x":x , "y":y}
			
			x += xskip
			if(x>=xend_)
				break
		}
		
		y += yskip
		if(y>=yend_)
			break
	
		if(A_TickCount-msec_start >= msec_limit)
			break
	}
	
	return {"is_found":false, "x":0, "y":y} ; y tells "next"-y to continue search
}

Evp_HasTransparentPixel(fpimg)
{
	; Baffle: This function runs very slow, but I don't know why.
	; Weird: The CPU usage during the run is far less from a whole core.
	; Due to its slowness, I have to limit the time-cost, so not every pixel is checked.
	scan1_msec_limit := 500
	scan2_msec_limit := 300

	If !pToken := Gdip_Startup()
	{
		dev_MsgBoxWarning("Evp_HasTransparentPixel(): Gdip_Startup FAIL.")
		return false
	}

	bitmap := Gdip_CreateBitmapFromFile(fpimg)
	if(bitmap<=0) {
		dev_MsgBoxError(Format("Gdip_CreateBitmapFromFile(""{}"") fail, errcode={}.", fpimg, bitmap))
		return false
	}

	imgw := 0 , imgh := 0
	Gdip_GetImageDimensions(bitmap, imgw, imgh)
	if(imgw==0 || imgh==0)
		dev_MsgBoxError("In Evp_HasTransparentPixel(), Gdip_GetImageDimensions() fails!")

	skip := 2
	scan_result := gdip_BitmapFindTransparentPixel(bitmap, 0,0, imgw, imgh, skip, skip, scan1_msec_limit)

	if(scan_result.is_found==false and scan_result.y<imgh)
	{
		dev_assert(scan_result.y>0)
		
;		if(scan_result.y>=imgh) { ; test
;			dev_assert(scan_result.y<imgh)
;		}
		
;		dev_TooltipAutoClear("Phase-two scan from image-y (0-based): " scan_result.y, 5000) ; debug
		
		; Now we search "image left-side"(100-pixel column)
		scan_width := 100
		scan_result := gdip_BitmapFindTransparentPixel(bitmap
			, 0,           scan_result.y
			, scan_width,  imgh
			, skip,        skip
			, scan2_msec_limit)
	}
	
	Gdip_DisposeImage(bitmap)
	Gdip_Shutdown(pToken)

	if(scan_result.is_found)
	{
;		Dbgwin_Output(Format("{}: transpx at {},{}", fpimg, scan_result.x, scan_result.y)) ; debug
	}

	return scan_result.is_found
}

Evp_TimerProcCheckPngfileTranspixel(pngfilepath, from_startcount)
{
	if(from_startcount!=g_evpConvertStartCount)
	{
		; We have been lagged, input pngfilepath no longer match "latest", so nothing to do here.
;		Dbgwin_Output(Format("### from_startcount={} , g_evpConvertStartCount={}", from_startcount, g_evpConvertStartCount)) ; debug
		return
	}

	Gui_ChangeOpt(  "EVP", "+OwnDialogs")

;	Dbgwin_Output("Evp_TimerProcCheckPngfileTranspixel(), " pngfilepath) ; debug
	
	hastranspx := Evp_HasTransparentPixel(pngfilepath)

;	Dbgwin_Output("Evp_TimerProcCheckPngfileTranspixel() = " (hastranspx?"Yes":"No")) ; debug
	
	; show warning icon if not hastranspx.
	GuiControl_Show("EVP", "gu_evpIcnWarnNoTranspixel", !hastranspx?true:false)
	
	if(hastranspx)
		g_evpCurPngHasTranspx := true
}


Evp_CheckClipboardStateUpdateUI()
{
	hint := ""
	is_pngpath := false
	
	if( Evp_IsBitmapInClipboard(bitmap_filepath) )
	{
		hint := "Bitmap in Clipboard. You can now [Convert from Clipboard]."
	}
	else if(bitmap_filepath)
	{
		hint := "Clipboard has filepath: " bitmap_filepath
		
		if(StrIsEndsWith(bitmap_filepath, ".png", true))
			is_pngpath := true
	}

	if(hint)
	{
		GuiControl_Enable("EVP","gu_evpBtnCvtFromClipbrd", true)
		fgcolor := "8888cc"
;		Evp_ShowAllControls(true) ; not so fast
	}
	else 
	{
		GuiControl_Enable("EVP","gu_evpBtnCvtFromClipbrd", false)
		hint := "Copy an image, or a filepath into system Clipboard so to convert it."
		fgcolor := "CC8888"
	}
	
	GuiControl_SetColor("EVP", "gu_evpTxtClipbState", fgcolor)
	GuiControl_SetText( "EVP", "gu_evpTxtClipbState", hint)
	
	uivis_pngtrans := (is_pngpath && g_evpIsFullUIExpaned) ? true : false
	GuiControl_Show("EVP", "gu_evpCkbKeepPngTrans", uivis_pngtrans)
	
	if(not uivis_pngtrans)
		GuiControl_Show("EVP", "gu_evpIcnWarnNoTranspixel", false)
}

Evp_CheckConvertingProgressUpdateUI()
{
	fpProgress := g_evpBatchProgressFilepath ; was set in Evp_LaunchBatchConvert()
	; 	C:\Users\win7evn\AppData\Local\Temp\Everpic\everpic-20221204_165806.progress.done.txt
	dev_assert(fpProgress) 

	progtext := dev_FileReadLine(fpProgress, 1)
	
	if(g_evpTimerStage=="ConvertStarting"
		&& A_TickCount-g_evpTickConvertStart > gc_evpStartingTimeoutSec*1000)
	{
		is_yes := dev_MsgBoxYesNo(Format("Unexpect! Background conversion process fails to start in {} seconds.`r`n`r`n"
			. "Do you want to cancel conversion now?", gc_evpStartingTimeoutSec)
			, true, Amhk.mbopt_IconExclamation)
		if(is_yes)
		{
			dev_assert(g_evpBgCvtProcessId)
			dev_KillProcessByPid(g_evpBgCvtProcessId)
			
			Evp_BatchConvertDone(false)
		}
	}

	if(!progtext)
	{
		; Possible situation: Above dev_FileReadLine() failed, due to file being written(file locked)
		; by background converting process. So we just neglect this case, and retry on next timer tick.
		return
	}
	

	if(g_evpTimerStage=="ConvertStarting")
	{
		; Check file content of fpProgress to see whether it has "0/9", "0/10" etc. 
		; If so, we move to next timer-stage; If not after some timeout, we claim it error.

		if(progtext ~= "^[0-9]+/[0-9]+$")
		{
			g_evpTimerStage := "ConvertStarted"
			
			GuiControl_SetText("EVP", "gu_evpTxtClipbState", "Converting " progtext " ...")
		}
	}
	
	; Check file content in fpProgress to see whether the background
	; image-list generation has completed. Sample file:
	; 	C:\Users\win7evn\AppData\Local\Temp\Everpic\everpic-20221204_165806.progress.done.txt
	; File content, just one line, can be:
	; 1/9
	; 2/9
	; ...
	; 9/9
	;
	; If 9/9 is reached, it means completed.

	nums := StrSplit(progtext, "/")
	nDone := nums[1]
	nTotal := nums[2]

	if(!nTotal)
	{
		dev_MsgBoxError(Format("Bad content in progress file: {}`r`n`r`n{}", fpProgress, progtext)
			, "Something Wrong!")
		Evp_BatchConvertDone(false)
		return
	}
	
	msecs := A_TickCount - g_evpTickConvertStart
	
	if(nDone<nTotal)
	{
		GuiControl_SetText("EVP", "gu_evpBtnCvtFromClipbrd", Format("Cancel converting (+{}s)", msecs//1000))
	
		GuiControl_SetText("EVP", "gu_evpTxtClipbState"
			, Format("Converting {}/{} ...", nDone, nTotal))
	}
	else if(nDone==nTotal)
	{
		; All (background) image conversion done successfully.

		zoomhint := ""
		if(g_evpImageZoom!=1)
			zoomhint := Format("({}% zoom)",floor(g_evpImageZoom*100)) ; note Zoom-pct is not Scale-pct
		
		GuiControl_SetText("EVP", "gu_evpEdrLoadStat"
			, Format("{}*{} , {}.{:03}s {}"
				, Evp_ImgScaledWidth(), Evp_ImgScaledHeight()
				, floor(msecs/1000), Mod(msecs,1000)
				, zoomhint))
		
		Evp_RefreshPreviewAllGui()
		
		Evp_BatchConvertDone(true)
		
		return
	}
	
	; Note: We have to check process-alive AFTER `if(nDone==nTotal)`, bcz `nDone==nTotal` signify success.
	;
	if(!dev_IsProcessAlive(g_evpBgCvtProcessId))
	{
		if(!g_evpIsCancelling)
		{
			dev_MsgBoxError(Format("Unexpect! Background process has terminated, but image conversion is not finished.`r`n`r`n"
				. "Error reason may be revealed from everpic-batch-prepare.bat.log ."))
		}
		
		Evp_BatchConvertDone(false)
	}
}

Evp_ImgScaledWidth()
{
	return g_evpImageWidth*g_evpCurrentScalePct//100
}

Evp_ImgScaledHeight()
{
	return g_evpImageHeight * g_evpCurrentScalePct // 100
}

Evp_BatchConvertDone(is_succ)
{
	; Set some shared-status after convert is done.
	
	evpdbg("Evp_BatchConvertDone(), " (is_succ ? "success." : "fail!"))

	dev_assert(g_evpBgCvtProcessId!=0)
	dev_WaitUntilProcessExit(g_evpBgCvtProcessId)
	; -- This is important, bcz everpic-batch-prepare.bat process's exist ensures that 
	;    everpic-batch-prepare.bat.log' file handle is closed by CMD shell's '>' operator,
	;    so that the next run of everpic-batch-prepare.bat can be sure to success.
	g_evpBgCvtProcessId := 0

	g_evpTimerStage := "Monitoring"
	g_evpTickConvertStart := 0
	g_evpIsCancelling := false

	GuiControl_Enable ("EVP", "gu_evpBtnCvtFromClipbrd", true)
	GuiControl_SetText("EVP", "gu_evpBtnCvtFromClipbrd", gc_evpConvertBtnText)

	if(is_succ)
	{
		g_evpConvertSuccCount++

		GuiControl_SetText("EVP", "gu_evpEdrBaseImgFilepath", "Base-image: " g_evpBaseImageFilepath_100pct)

		Evp_RefreshImgpane()
	}
}

Evp_SyncGuiByBaseImage(imgfilepath, imgw_scaled, imgh_scaled)
{
	; This function adjusts(Increase or decrease)  EVP GUI's window size 
	; so that the image can be display at 100% Zoom level. 
	; But if the image is larger than monitor area, I have to shrink it. 
	;
	; imgfilepath can be empty, this will change the UI to its default(blank) size.
	;
	; This function changes global vars: g_evpImgpaneWidth, g_evpImgpaneWidth
	
	
	; //// Set new content into controls according to imgfilepath ////
	
	if(imgfilepath)
	{
		wa := GetMonitorWorkArea(1)
		
		max_gui_width := wa.width - 2*g_evpWindowBorder
		
		imgw_gui_units := imgw_scaled / Get_DPIScale()
		imgh_gui_units := imgh_scaled / Get_DPIScale()
			; For example, on an 120-dpi monitor setting Windows(125% scale), for a 125-pixel width image,
			; you need to only pass w100 for the picture control to show it perfectly.
		
		stock_width := 2*gc_evpMarginX + gc_evpCol1Width + gc_evpGapX
		gui_wreq := stock_width + imgw_gui_units
		if(gui_wreq > max_gui_width)
			gui_wreq := max_gui_width ; not execeed primary monitor workarea width

		wimgpane := imgw_gui_units

		himgpane := imgh_gui_units
		if(wimgpane > gui_wreq-stock_width)
		{	
		; shrink wimgpane to fit in monitor
			wimgpane := round(gui_wreq - stock_width) ; preview(pic control) width
			himgpane := round(wimgpane * imgh_scaled/imgw_scaled) ; preview height
			
			g_evpImageZoom := wimgpane / imgw_gui_units
		}
		else 
		{
			g_evpImageZoom := 1
		}
		
		; todo optimize: adjust y position ,
		; todo optimize: deal with long portrait image scaling
	}
	else ; imgfilepath is empty, reset UI to default
	{
;		dev_assert(0) ; dead code? No, use at init stage
		wimgpane := gc_evpImgpaneDefWidth
		himgpane := gc_evpImgpaneDefHeight
	}
	
	ximgpane := gc_evpMarginX + gc_evpCol1Width + gc_evpGapX

	rScaleLabel := GuiControl_GetPos("EVP", "gu_evpTxtScale")
	yRef := rScaleLabel.y
	
	GuiControl_SetPos("EVP", "gu_evpPicPreview", ximgpane, yRef, wimgpane, himgpane) ; same vertical pos

	g_evpImgpaneWidth := round(wimgpane) 
	g_evpImgpaneHeight := round(himgpane)

	col2w := dev_max(wimgpane, gc_evpImgpaneDefWidth)
	gui_fullwidth := dev_max(Evp_CalCtrlFullWidth(), gc_evp_GUIDefWidth)
	
	GuiControl_SetPos("EVP", "gu_evpTxtClipbState", -1, -1, col2w, -1)
	GuiControl_SetPos("EVP", "gu_evpEdrBaseImgFilepath", -1, -1, gui_fullwidth, -1)
	
	GuiControl_SetText("EVP", "gu_evpPicPreview", imgfilepath) ; this actually changes Pic control's picture appearance

	footy := yRef + dev_max(gc_evpImgpaneDefHeight, himgpane) + gc_evpGapY
	GuiControl_SetPos("EVP", "gu_evpEdrFootline"
		, -1, footy
		, gui_fullwidth-gc_evpIconBtnWidth-9, -1)
	;
	rFootline := GuiControl_GetPos("EVP", "gu_evpEdrFootline")
	;
	GuiControl_SetPos("EVP", "gu_evpBtnCopyFile"
		, rFootline.x + rFootline.w + 2, footy - 1
		, -1, -1)

	yBtnOK := rFootline.y + rFootline.h + gc_evpGapY
	GuiControl_SetPos("EVP", "gu_evpBtnOK"
		, -1, yBtnOK
		, -1, -1)
	GuiControl_SetPos("EVP", "gu_evpCkbAutoPaste" , -1, yBtnOK+5, -1, -1)
	GuiControl_SetPos("EVP", "gu_evpCkbKeepWindow", -1, yBtnOK+5, -1, -1)
	
	Evp_AutosizeNowUI()

	if(imgfilepath)
	{
		; Some quick tweak: If the window is too tall, we move down the window to y=0, 
		; so that its title bar can be seen on primary monitor.
		WinGetPos, x,y,w,h, ahk_id %g_HwndEVPGui%
		if(h>wa.height)
			WinMove, ahk_id %g_HwndEVPGui%, , %x%, 0
	}
}

Evp_RefreshPreviewAllGui()
{
	if(not g_evpImglistTxtPath)
	{
		MsgBox, % "BUG found in Evp_RefreshPreviewAllGui()."
		return
	}
	
	g_evp_arImageStore := []
	
	Loop, Read, % g_evpImglistTxtPath
	{
		field := StrSplit(A_LoopReadLine, "*")
		desc := field[1]	; Example: "PNG (32-bit), 80KB"
		imgfile := field[2]
		
		filelen := dev_FileGetSize(imgfile)
		if(filelen>=1024)
			filelen_desc := Format("{} KB", filelen//1024)
		else 
			filelen_desc := Format("{} B", filelen)
		
		; Add desc(image variant description) to listbox
		GuiControl, EVP:, gu_evpLbxImages, % Format("{}, {}", desc, filelen_desc)
		
		g_evp_arImageStore[A_Index] := {"hint":desc, "filelen_desc":filelen_desc, "path":imgfile}
		; -- hint will be displayed as small-font footnote beneath each image in Evernote clip.
	}
	
	; Choose and display PNG-32bit by default
	GuiControl, EVP:Choose, gu_evpLbxImages, 1
	GuiControl, EVP:, gu_evpPicPreview, % g_evp_arImageStore[1].path
	GuiControl, EVP:Focus, gu_evpLbxImages
	
	GuiControl_Enable("EVP","gu_evpBtnOK", true)
}

Evp_evtCbxScalepctChanged()
{
	scale_pct := Evp_GetUIScalePct()
	
	if(scale_pct==g_evpCurrentScalePct)
		GuiControl_Enable("EVP", "gu_evpLbxImages", true)
	else
		GuiControl_Enable("EVP", "gu_evpLbxImages", false)
}

Evp_RefreshImgpane()
{
	idx := GuiControl_GetText("EVP", "gu_evpLbxImages")
	
	cur_imagefile := g_evp_arImageStore[idx].path
	
	GuiControl_SetText("EVP", "gu_evpPicPreview",  cur_imagefile)
	
	GuiControl_SetText("EVP", "gu_evpEdrFootline", cur_imagefile)
}

Evp_BtnOK()
{
	GuiControlGet, gu_evpLbxImages
	imgfilepath := g_evp_arImageStore[gu_evpLbxImages].path
	dev_SplitPath(imgfilepath, imgfilename)
	imghint := g_evp_arImageStore[gu_evpLbxImages].hint ; "PNG(32-bit)" etc
	filelen_desc := g_evp_arImageStore[gu_evpLbxImages].filelen_desc

	dev_assert(StrIsStartsWith(imgfilename, g_evpImageSig))
	
	if(StrIsEndsWith(imgfilename, ".png", true) && g_evpCurPngHasTranspx==true)
		imghint .= "(PTP)" ; =Preserve Transparent Pixels

	html_fmt = 
(
<div><img src="http://localhost:2017/Everpic-save/{1}" alt="max-width:{2}px" /><br>
<span style="font-size: 10px; color: rgb(144,144,144)">
{4}, {2}*{3}, {5}, {6} ({7})
</span></div>~
)
	html := Format(html_fmt
		, imgfilename ; {1}
		, Evp_ImgScaledWidth(), Evp_ImgScaledHeight() ; {2}, {3} width and height
		, filelen_desc ; {4} "33 KB" etc
		, imghint ; {5} 
		, g_evpImageSig ; {6}
		, dev_LocalTimeZoneMinutesStr()) ;{7} timezone 

	; Save the used picture to a permanent directory, so that we can get it back 
	; in case Evernote fail to actually store my picture in the note.
	dir_everpic_save := A_AppData "\Everpic-save"
	FileCreateDir, %dir_everpic_save%
	FileCopy, %imgfilepath%, %dir_everpic_save%, 1 ; 1=overwrite
	if(ErrorLevel) {
		; Note: We did a non-overwrite copy, if destination file exist, we get ErrorLevel.
		dev_MsgBoxInfo("Unexpect: Fail to copy your image file to " dir_everpic_save)
		return
	}
	
	is_autopaste  := GuiControl_GetValue("EVP", "gu_evpCkbAutoPaste")
	is_keepwindow := GuiControl_GetValue("EVP", "gu_evpCkbKeepWindow")
	
	dev_ClipboardSetHTML(html
		, is_autopaste ? true : false
		, g_evpHwndToPaste)
	
	if(!is_autopaste && is_keepwindow)
	{
		dev_TooltipAutoClear("HTML content with this image has been placed into Clipboard.", 3000)
	}

	if(!is_keepwindow)
	{
		Evp_CleanupUI()
	}

	Evp_CleanupTempDir()
}

Evp_CleanupTempDir_withInterval()
{
	static s_msecPrevCleanup := 0
	
	; To reduce disk access, we do a cleanup only after one minute has elapsed since last cleanup.
	
	msec_now := A_TickCount
	msec_since_prev_cleanup := msec_now - s_msecPrevCleanup
	
	Evp_DbgCleanup(Format("EVP-cleantemp(every {} seconds): prev={}, now={}, diff={}", g_evpTempPreserveMinutes*60, msec_now//1000, s_msecPrevCleanup//1000, msec_since_prev_cleanup//1000)) ; debug
	
	one := 1
	if(msec_since_prev_cleanup >= one*60*1000)
	{
		Evp_CleanupTempDir()
	
		s_msecPrevCleanup := msec_now
	}
}

Evp_CleanupTempDir()
{
	; Cleanup stale everpic-... files in C:\Users\win7evn\AppData\Local\Temp\Everpic

	Loop, Files, % g_evpTempDir "\*"
	{
		filename := A_LoopFileName ; example: "everpic-20221204_220000.q40.jpg"
		
		foundpos := RegExMatch(filename, "^everpic-([0-9]+)_([0-9]+)", subpat)
		if(foundpos>0)
		{
			file_datetime := subpat1 . subpat2
			
			diff_seconds := A_Now
			EnvSub diff_seconds, file_datetime, Seconds
			
			N := g_evpTempPreserveMinutes

			if(diff_seconds >= N*60)
			{
				pathdel := g_evpTempDir "\" filename
			
				Evp_DbgCleanup("Evp_CleanupTempDir(), FileDelete: " pathdel) ; debug
				
				FileDelete, % pathdel
			}
		}

	}
}

Evp_DbgCleanup(msg)
{
	if(g_evpDbgCfg.showdbgcleanup)
		Dbgwin_Output(msg)
}

; ========================= EverTable(Evtbl) code starts =========================

EverTable_LaunchUI()
{
	Evtbl_FixIE(11) ; gradient background is supported only in IE11.
	
	; Remember current active window, will be paste target later
	g_evtblHwndToPaste := dev_GetActiveHwnd()
	
	Evtbl_ShowGui()
}

Evtbl_FixIE(Version=0, ExeName="")
{
	; https://autohotkey.com/board/topic/93660-embedded-ie-shellexplorer-render-issues-fix-force-it-to-use-a-newer-render-engine/
	static Key := "Software\Microsoft\Internet Explorer"
	. "\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION"
	, Versions := {7:7000, 8:8888, 9:9999, 10:10001, 11:11001}
	
	if Versions.HasKey(Version)
		Version := Versions[Version]
	
	if !ExeName
	{
		if A_IsCompiled
			ExeName := A_ScriptName
		else
			SplitPath, A_AhkPath, ExeName
	}
	
	RegRead, PreviousValue, HKCU, %Key%, %ExeName%
	if (Version = "")
		RegDelete, HKCU, %Key%, %ExeName%
	else
		RegWrite, REG_DWORD, HKCU, %Key%, %ExeName%, %Version%
	return PreviousValue
}


Evtbl_ShowGui()
{
	if(!g_HwndEvtbl) {
		Evtbl_CreateGui()
	}

	Gui, EVTBL:Show, , % "EverTable"
	
	; Always set keyboard focus to color Combobox on GUI showing.
	GuiControl, EVTBL:Focus, g_evtblComboColor
	Evtbl_SyncUserInputToColorPreview()
	
	; Initially turn off these checkbox:
	GuiControl, EVTBL:, g_evtblChkboxTSV, 0
	
;	SetTimer, timer_EvtblSyncColor, 200
	
	OnMessage(0x200, Func("Evtbl_WM_MOUSEMOVE")) ; add message hook
	
	OnMessage(0x111, Func("Evtbl_WM_COMMAND")) ; to get WM_COMMAND -> EN_KILLFOCUS notification
}

Evtbl_HideGui(html_clipboard:="")
{
;	SetTimer, timer_EvtblSyncColor, Off
	
	Gui, EVTBL:Hide
	
	OnMessage(0x200, Func("Evtbl_WM_MOUSEMOVE"), 0) ; remove message hook
	OnMessage(0x111, Func("Evtbl_WM_COMMAND"), 0)
	tooltip ; turn off possible dangling tooltip
	
	if(html_clipboard)
	{
		; We should do clipboard paste *after* Evtbl GUI has been hidden,
		; otherwise, the selected-text in Combobox may probably be cleared.
		dev_ClipboardSetHTML(html_clipboard, true, g_evtblHwndToPaste)
	}
}

Evtbl_CreateGui()
{
	Gui, EVTBL:New ;Destroy old window if any
	Gui, EVTBL:+Hwndg_HwndEvtbl
	
	;
	; Global Windows Dialog options
	;
	Gui, EVTBL:Color, white ; Set whole GUI background color, bcz Evernote evclip's background is always white.

	Gui, EVTBL:Font, s9 c909090, Tahoma
	Gui, EVTBL:Add, Text, w500, % "EverTable generates visually appealing <TABLE> and <DIV> HTML snippets for Evernote."

	Gui, EVTBL:Font, s9 cBlack, Tahoma
	
	;
	; Background color:              Text color:
	; [combobox selecting color    ] (x)Black ( )White  [~]
	; [combobox selecting 2nd color] [x]Second color  [~]
	; [[                  Color Preview                ]]
	;
	Gui, EVTBL:Add, Text, xm w320 , % "Background &color:"
	Gui, EVTBL:Add, Text, X+10 w160 , % "Text color:"
	;
	; Add a Combobox with fixed-width font(Consolas), and set its event handler:
	Gui, EVTBL:Font, s9 cBlack, Consolas
	Gui, EVTBL:Add, ComboBox, xm w320 vg_evtblComboColor Hwndg_evtblHwndComboColor gEvtbl_OnComboColorChange
	;
	Gui, EVTBL:Font, s9 cBlack, Tahoma 
	Gui, EVTBL:Add, Radio, X+10 yp+4 Group Checked vg_evtblIsBlackText gEvtbl_procTextColor, % "&Black"
	Gui, EVTBL:Add, Radio, X+10                    vg_evtblIsWhiteText gEvtbl_procTextColor, % "&White"
	Gui, EVTBL:Add, Button, xm+470 yp-4 vg_evtblBtnColorMatrix gEvtbl_ShowColorMatrix, % "~"

	; 2nd color combobox + [x]checkbox + [~]
	Gui, EVTBL:Font, s9 cBlack, Consolas
	Gui, EVTBL:Add, ComboBox, xm y+10 w320 vg_evtblComboColor2 Hwndg_evtblHwndComboColor2 gEvtbl_OnComboColorChange,
	Gui, EVTBL:Font, s9 cBlack, Tahoma 
	Gui, EVTBL:Add, Checkbox, x+10 yp+4 w118 vg_evtblUse2ndColor gEvtbl_SyncUserInputToColorPreview, % "&Use second color"
	Gui, EVTBL:Add, Button, xm+470 yp-4 vg_evtblBtnColorMatrix2 gEvtbl_ShowColorMatrix2, % "~"
	; 

	; Add "Preview" labels with a bit larger font: 
	; Note: A preview-label is a Progress-bar overlayed with a transparent Text label.
	; We use Progress-bar bcz we can set its background color individually.
	Gui, EVTBL:Font, s12 cBlack, Tahoma
	Gui, EVTBL:Add, Progress, xm y+15 w160 vg_evtblPreviewBox
	Gui, EVTBL:Add, Text, xp yp wp hp Center +Border BackgroundTrans vg_evtblPreviewText, % text_ColorPreview
	; -- Center: Text at control center; xs ys: x,y@saved position ; xp yp wp hp: x,y,width,height same as previous
	; 2nd color:
	Gui, EVTBL:Add, Progress, x+10 w160 hp vg_evtblPreviewBox2
	Gui, EVTBL:Add, Text, xp yp wp hp Center +Border BackgroundTrans vg_evtblPreviewText2, % text_ColorPreview
	; 3rd, mix color with IE ActiveX ctrl
	Gui, EVTBL:Add, ActiveX, x+10 yp w160 hp vg_evtblPreviewMix, Shell.Explorer ; demo code uses vWB
	Evtbl_HtmlInitContent(g_evtblPreviewMix)
	
	; Restore default font size for GUI
	Gui, EVTBL:Font, s9 cBlack, Tahoma

	;
	; HTML content selection: <TABLE> , <DIV> , CSS-Table , <span>
	;
	Gui, EVTBL:Add, Text, xm Y+15 , % "HTML content:"
	Gui, EVTBL:Add, Radio, X+10 Group Checked vg_evtblIsTable gEvtbl_OnTableDivSwitch, % "<&TABLE>"
	Gui, EVTBL:Add, Radio, X+10                 vg_evtblIsDiv gEvtbl_OnTableDivSwitch, % "<&DIV>"
	Gui, EVTBL:Add, Radio, X+25            vg_evtblIsCsstable gEvtbl_OnTableDivSwitch, % "CSS-t&able"
	Gui, EVTBL:Add, Radio, X+10                vg_evtblIsSpan gEvtbl_OnTableDivSwitch, % "<spa&n>"
	; // set CSS-table rows //
	Gui, EVTBL:Add, Edit, xp yp-3 w30 Hidden vg_evtblEdtCsstableRows, % "3"
	Gui, EVTBL:Add, Text, x+5 yp+3      Hidden vg_evtblLblCsstableRows, % "rows"
	Gui, EVTBL:Add, CheckBox, x+5  Checked Hidden vg_evtblChkboxCsstableHead, % "Add header"

	; 2022.03 span-text editbox
	Gui, EVTBL:Add, Edit, xm y+9 w415       Hidden vg_evtblSpanText  , % "span text"
	Gui, EVTBL:Add, Checkbox, x+3 yp+2 w80  Hidden vg_evtblIsSpanMono, % "mono-f&ont"
	;
	; Table Columns: ____24,360,540____  [x] First column in color // reuse the same position as span-text
	;
	Gui, EVTBL:Add, Text, xm yp+2 vlbl_TableColumnSpec, % "Table Column&s:"
	Gui, EVTBL:Add, Edit, x+10 yp-2 w240 vg_evtblTableColumnSpec, % "24:#,360:Brief,540:Detail"
	Gui, EVTBL:Add, Edit, xp yp wp Hidden vg_evtblCssTableColumnSpec, % "30%,30%,30%" ; yes, overlap with previous
	Gui, EVTBL:Add, Checkbox, x+20 yp+4 vg_evtblIsFirstColumnColor, % "&First column in color"
;	Gui, EVTBL:Add, Text, x+10 yp+2,      % "Table width(%):"
;	Gui, EVTBL:Add, Edit, x+10 yp-2 w40,  % "100"
	
	;
	; Table border: (x)1px ( )2px  Table cell padding: (x)sparse ( )dense
	;
	Gui, EVTBL:Add, Text, xm y+12 vlbl_TableCellPadding, % "Table cell &padding:"
	Gui, EVTBL:Add, Radio, x+10 Group Checked vg_evtblIsPaddingSparse, % "Sparse"
	Gui, EVTBL:Add, Radio, x+10               vg_evtblIsPaddingDense , % "Dense"
	;
	Gui, EVTBL:Add, Text, x+22 vlbl_TableBorderPx, % "Table borde&r:"
	Gui, EVTBL:Add, Radio, x+10 Group         vg_evtblBorder1px, % "1px"
	Gui, EVTBL:Add, Radio, x+10       Checked vg_evtblBorder2px, % "2px"

	; [ Paste HTML ] ... [ Preview HTML ]
	Gui, EVTBL:Add, Button, xm Y+10 Default vg_evtblBtnOK gEvtbl_BtnOK, % "Paste HTML (Enter)"
	Gui, EVTBL:Add, Checkbox, x+10 yp+6     vg_evtblChkboxTSV, % "fro&m TSV/CSV"
	Gui, EVTBL:Add, Button, x420 yp-6        gEvtbl_BtnPreviewHtml, % "Preview &HTML"

	Evtbl_ComboboxFillColorPresets("g_evtblComboColor", g_evtblIdxDefaultColor1)
	Evtbl_ComboboxFillColorPresets("g_evtblComboColor2", g_evtblIdxDefaultColor2)

	; Special: Save Preview box's position for later use.
	GuiControlGet, box1, EVTBL:Pos, g_evtblPreviewBox
	GuiControlGet, box3, EVTBL:Pos, g_evtblPreviewMix
	;
	g_evtblBox1HalfPos.x := box1X
	g_evtblBox1HalfPos.y := box1Y
	g_evtblBox1HalfPos.w := box1W
	g_evtblBox1HalfPos.h := box1H
	;   dev_TooltipAutoClear( Format("box1: {} {} {} {}", box1X, box1Y, box1W, box1H))
	g_evtblBox1FullPos.x := box1X
	g_evtblBox1FullPos.y := box1Y
	g_evtblBox1FullPos.w := box3X+box3W - box1X
	g_evtblBox1FullPos.h := box3H

	return
	
;timer_EvtblSyncColor:
;	Evtbl_SyncUserInputToColorPreview()
;	return
}

Evtbl_OnTableDivSwitch()
{
	; Memo: Initial hidden ctrls is controlled in Evtbl_CreateGui()

	tablectls_share := [ "lbl_TableColumnSpec", "g_evtblIsFirstColumnColor",
		, "lbl_TableCellPadding", "g_evtblIsPaddingSparse", "g_evtblIsPaddingDense"
		, "lbl_TableBorderPx", "g_evtblBorder1px", "g_evtblBorder2px" ]
		; share by traditional <TABLE> and CssTable

	GuiControlGet, g_evtblIsTable, EVTBL:
	GuiControlGet, g_evtblIsCssTable, EVTBL:
	GuiControlGet, g_evtblIsSpan, EVTBL:
	
	hideORshow := (g_evtblIsTable || g_evtblIsCssTable) ? "Show" : "Hide"
	;
	Loop, % tablectls_share.Length()
	{
		ctlvar := tablectls_share[A_Index]
		GuiControl, EVTBL:%hideORshow%, %ctlvar%
	}
	
	hideORshow := g_evtblIsTable ? "Show" : "Hide"
	GuiControl, EVTBL:%hideORshow%, g_evtblTableColumnSpec
	
	hideORshow := g_evtblIsCssTable ? "Show" : "Hide"
	GuiControl, EVTBL:%hideORshow%, g_evtblCssTableColumnSpec
	GuiControl, EVTBL:%hideORshow%, g_evtblEdtCsstableRows
	GuiControl, EVTBL:%hideORshow%, g_evtblLblCsstableRows
	GuiControl, EVTBL:%hideORshow%, g_evtblChkboxCsstableHead
	;
	if(g_evtblIsCssTable)
	{
		hide_more_ctls := [ "lbl_TableCellPadding", "g_evtblIsPaddingSparse", "g_evtblIsPaddingDense"
			, "lbl_TableBorderPx", "g_evtblBorder1px", "g_evtblBorder2px", "g_evtblIsSpan" ]
		Loop, % hide_more_ctls.Length()
		{
			GuiControl, EVTBL:Hide, % hide_more_ctls[A_Index]
		}
		
	}
	else 
	{
		GuiControl, EVTBL:Show, % "g_evtblIsSpan"
	}
	
	hideORshow := g_evtblIsSpan ? "Show" : "Hide"
	GuiControl, EVTBL:%hideORshow%, g_evtblSpanText
	GuiControl, EVTBL:%hideORshow%, g_evtblIsSpanMono
}

Evtbl_ParseTableColumnWidth(ColumnSpec)
{
	; ColumnSpec is like: "24,360,540" or "24:#,360:Brief,540:Detail"

	token := StrSplit(ColumnSpec, ",")
	
	if (token.Length() == 0) {
		return
	}
	
	ar_colinfo := []
	Loop, PARSE, ColumnSpec, `,
	{
		; A_LoopField will be "24" or "360:Brief" etc
		
		tkn := [ "" , "#" A_Index ]
		; -- tkn[2] : set default column header text #1, #2, #3 ...
		
		tkn := StrSplit(A_LoopField, ":")
		ar_colinfo.Push({ "width_px" : tkn[1], "text" : tkn[2] })
	}
	return ar_colinfo
}

make_css_bg_rule(hexcolor1, hexcolor2)
{
	if(hexcolor2)
		css_bg_rule := Format("background: linear-gradient(15deg, {}, {});", hexcolor1, hexcolor2)
	else
		css_bg_rule := Format("background-color: {};", hexcolor1)
	return css_bg_rule
}

Evtbl_GenHtml_Table(hexcolor1, hexcolor2)
{
	ar_colinfo := Evtbl_ParseTableColumnWidth(g_evtblTableColumnSpec)
	if(!ar_colinfo) {
		MsgBox, % "Wrong input: Empty table columns assignment."
		return
	}

/*
	html_table_complete_sample = 
(
+<table border="2" style="border-collapse:collapse; border-color:#3C965A; width:100%;">
	<colgroup><col style="width:24px;"></col><col style="width:360px;"></col><col style="width:540px;"></col></colgroup>
	<thead>
		<tr> <!-- 20190722: Do NOT use <th> inside <thead>, which will cause column widths skew after typing words into cells. -->
			<td style="padding:0.5em; background-color:#50C878; color:black; text-align:center; font-weight:bold; border-color:#3C965A;">#</td>
			<td style="padding:0.5em; background-color:#50C878; color:black; text-align:center; font-weight:bold; border-color:#3C965A;">Brief</td>
			<td style="padding:0.5em; background-color:#50C878; color:black; text-align:center; font-weight:bold; border-color:#3C965A;">Detail</td>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td style="vertical-align:top; padding:0.5em; border-color:#3C965A;">20190722</td>
			<td style="vertical-align:top; padding:0.5em; border-color:#3C965A;">.</td>
			<td style="vertical-align:top; padding:0.5em; border-color:#3C965A;">.</td>
		</tr>
	</tbody>
</table>~
) 
*/
	htmline_colgroup := "" ; {1}
	colwidth_count := ar_colinfo.Length()
	
	css_bg_rule := make_css_bg_rule(hexcolor1, hexcolor2) ; maybe pure color or color gradient
	
	Loop, %colwidth_count%
	{
		ptn_colgroup = 
(
<col style="width: {1}px;"></col>
)
		htmline_colgroup .= Format(ptn_colgroup, ar_colinfo[A_Index].width_px)
	}

	padding_em := g_evtblIsPaddingSparse ? "0.5" : "0.2"
	tableborder := g_evtblBorder1px ? "1" : "2"
	bordercolor := Evtbl_CalBorderColorFromBgColor(hexcolor1)
	pb_text_color := g_evtblIsWhiteText ? "white" : "black" ; text-color for those background-painted cells
	
	thead_tds := "" ; the <td>s inside <thead><tr>
	Loop, %colwidth_count%
	{
		ptn_tds =
(
<td style="padding:{1}em; {2}; color:{3}; text-align:center; font-weight:bold; border-color:{4};">{5}</td>

)
		thead_tds .= Format(ptn_tds, padding_em, css_bg_rule, pb_text_color, bordercolor, ar_colinfo[A_Index].text)
	}

	tbody_tds := "" ; the <td>s inside <tbody><tr>
	Loop, %colwidth_count%
	{
		ptn_tds =
(
<td style="vertical-align:top; padding:{1}em; border-color:{2}; color:{3}; {4}">{5}</td>

)
		cell_bgcolor := ""
		cell_textcolor := "black"
		datestr := ""
		if(A_Index==1)
		{
			if(g_evtblIsFirstColumnColor)
			{
				cell_bgcolor := css_bg_rule
				cell_textcolor := pb_text_color
			}
			
			FormatTime, datestr, , % "yyyyMMdd"
		}
		
		tbody_tds .= Format(ptn_tds, padding_em, bordercolor, cell_textcolor, cell_bgcolor, datestr)
	}

	html_ptn =
(
+<table border="{4}" style="border-collapse:collapse; border-color:{5}; width:100`%; chjid:{6};">
	<colgroup>{1}</colgroup>
	<thead>
		<tr> <!-- 20190722: Do NOT use <th> inside <thead>, which will cause column widths skew after typing words into cells. -->
{2}
		</tr>
	</thead>
	<tbody>
		<tr>
{3}
		</tr>
	</tbody>
</table>~
) ; memo: The leading + and trailing ~ is for Evernote 6.13's sane purpose.
	
	html := Format(html_ptn
		, htmline_colgroup, thead_tds, tbody_tds
		, tableborder, bordercolor
		, "evertbl_" dev_GetDateTimeStrCompact())

	; [2022-10-30] Embed `chjid` timestamp into <table>, so that Evernote 6.5.4 preserves it.
	; Note: I have to use chjid inside style="...", instead of regular id attribute of <table>,
	; bcz Evernote 6.5.4 will drop the "id=... " when I export the clip to .enex.
	; Caution: Editing the <table> with Evernote 6.6+ will ruin chjid .

	return html
}

Evtbl_GenHtml_Div(hexcolor1, hexcolor2)
{
	htmlptn = 
(
+<div style="padding: 0.8em; border: 1px solid rgb(220, 220, 220); {1};"><div><span>DIV</span></div></div><div>-</div>
) ; will be feed to Format, {1} will be replaced
	
	css_bg_rule := make_css_bg_rule(hexcolor1, hexcolor2)

	html := Format(htmlptn, css_bg_rule)
	return html
}

Evtbl_GenHtml()
{
	GuiControlGet, colortext, EVTBL:, g_evtblComboColor
	hexcolor1 := Evtbl_GetHexcolorFromStr(colortext) ; -- e.g. hexcolor="#f0f0ff"
	if(!hexcolor1)
	{
		MsgBox, % "Invalid hex color1 input, cannot generate HTML."
		return
	}

	hexcolor2 := "" ; assume no 2nd color
	GuiControlGet, g_evtblUse2ndColor, EVTBL:
	if(g_evtblUse2ndColor)
	{	
		GuiControlGet, colortext, EVTBL:, g_evtblComboColor2
		hexcolor2 := Evtbl_GetHexcolorFromStr(colortext)
		if(!hexcolor2) {
			MsgBox, % "Invalid hex color2 input, cannot generate HTML."
			return
		}
	}
	
	Gui, EVTBL:Submit, NoHide

	if(g_evtblIsTable)
	{
		if(!g_evtblChkboxTSV)
			html := Evtbl_GenHtml_Table(hexcolor1, hexcolor2)
		else
			html := Evtbl_GenHtml_FromTSV(hexcolor1, hexcolor2)
	}
	else if(g_evtblIsDiv)
	{
		html := Evtbl_GenHtml_Div(hexcolor1, hexcolor2)
	}
	else if(g_evtblIsCssTable)
	{
		rows := g_evtblEdtCsstableRows + 0
		
		GuiControlGet, g_evtblChkboxCsstableHead, EVTBL:
		isAddHead := g_evtblChkboxCsstableHead ? 1 : 0
		
		html := Evtbl_GenHtml_CssTable(rows, isAddHead, hexcolor1, hexcolor2)
	}
	else if(g_evtblIsSpan)
	{
		GuiControlGet, spantext, EVTBL:, g_evtblSpanText
		if (spantext=="")
			spantext := "~~"
		
		GuiControlGet, g_evtblIsSpanMono, EVTBL:
			
		html := Evtbl_GenHtml_Span(hexcolor1, hexcolor2, spantext, g_evtblIsSpanMono)
	}
	
	return html
}

Evtbl_GenHtml_CssTable(rows, isAddHead, hexcolor1, hexcolor2)
{
/* This function enables embedding nesting "tables" into an Evernote <table>. Great idea!

But since CSS-table in Evernote is a tweak, so it has limitations:
* We cannot add or delete rows and columns.
* We cannot drag CSS-table cell border to adjust their width.

So plan carefully before you insert one. If you find the layout unsatisfied, you have to re-insert the
whole csstable and fill its content from the beginning.
*/
	
	; Parsing ColumnSpec. If logic changes here, 
	; tooltip for `g_evtblCssTableColumnSpec` in Evtbl_WM_MOUSEMOVE() should be updated accordingly.

	ColumnSpec := g_evtblCssTableColumnSpec
	
	if( Instr(ColumnSpec, ",") ) 
	{
		ar_colinfo := Evtbl_ParseTableColumnWidth(ColumnSpec)
		if(!ar_colinfo) {
			MsgBox, % "Wrong input: Empty table columns assignment."
			return
		}
	}
	else
	{
		; No separator in ColumnSpec, so we think it a column count.
		; In this case we do not set "width:30%" as table-cell style, so we have "auto fit-width" effect, 
		; i.e. column width ajusted automatically  according to text amount in cell.
		
		columns := ColumnSpec + 0
		
		if(columns<=0) {
			MsgBox, % "Wrong input: Empty table columns assignment. If no comma, should be a integer."
			return
		}
		
		ar_colinfo := {}
		Loop, %columns% {
			ar_colinfo.Push({ "width_px":"any", "text":"any" })
		}
	}

/*
	html_csstable_complete_sample = 
(
+<div style="display:table; border:1px solid lightgray;">
  <div style="display:table-row">
    <div style="display:table-cell; padding:3px; border:1px solid lightgray; width:50%; background-color:#fefe8c;">Cell</div>
    <div style="display:table-cell; padding:3px; border:1px solid lightgray; width:50%; background-color:#fefe8c;">Cell</div>
  </div>
  <div style="display:table-row">
    <div style="display:table-cell; padding:3px; border:1px solid lightgray; background-color:#fefe8c;">Cell</div>
    <div style="display:table-cell; padding:3px; border:1px solid lightgray;">-</div>
  </div>
</div>~
) 
*/
	css_bg_rule := make_css_bg_rule(hexcolor1, hexcolor2) ; maybe pure color or color gradient

	html_tablerows := ""
	Loop, % rows+isAddHead
	{
		is_first_line := A_Index==1
		is_color_row := is_first_line && isAddHead
		
		html_onerow := Evtbl_GenHtml_CssTable_OneRow(ar_colinfo, css_bg_rule, is_first_line, is_color_row)
		
		html_tablerows .= html_onerow
	}
	
	fmt_html = 
(
+<div style="display:table; border:1px solid lightgray;">
{1}
</div>~
)
	html := Format(fmt_html, html_tablerows)
	return html
}
;
Evtbl_GenHtml_CssTable_OneRow(ar_colinfo, css_bg_rule, is_first_line, is_color_row)
{
	fmt_tablecell = 
(

    <div style="display:table-cell; padding:3px; border:1px solid lightgray; width:{1}; vertical-align:top; {2}; {3}">{4}</div>
)

	colwidth_count := ar_colinfo.Length()
	
	tablecells_onerow := ""
	
	Loop, %colwidth_count%
	{
		bg_rule := (is_color_row || (A_Index==1 && g_evtblIsFirstColumnColor)) ? css_bg_rule : ""
		
		width_value := ar_colinfo[A_Index].width_px
		if(!StrIsEndsWith(width_value, "%"))
			width_value .= "%" ; turn 30 into 30%, etc
		
		tablecells_onerow .= Format(fmt_tablecell
			, width_value
			, (is_first_line && is_color_row) ? "text-align:center" : ""
			, bg_rule
			, is_first_line ? Format("Column{1}", A_Index) : "-")
	}
	
	fmt_tablerow = 
(

  <div style="display:table-row">
{1}
  </div>
)
	tablerow := Format(fmt_tablerow, tablecells_onerow)
	return tablerow
}

Evtbl_GenHtml_Span(hexcolor1, hexcolor2, spantext, is_monofont)
{
	htmlptn = 
(
<span style="{1}; color:{2}; {3}">{4}</span>&nbsp;
)	; Note: an extra "&nbsp" at tail, so that user's continued typing after the <span> is in normal text style.
	; But a little drawback: If there has already been normal text after pasting the <span>, there will be TWO space-chars after <span>.
	
	spanhtml := dev_EscapeHtmlChars(spantext)

;	spanhtml := "<tt>" spanhtml "</tt>" ; This renders extra borders on span text, not good.
	monofont := is_monofont ? "font-family:consolas,monospace;" : ""

	css_bg_rule := make_css_bg_rule(hexcolor1, hexcolor2)
	html := Format(htmlptn
		, css_bg_rule
		, g_evtblIsWhiteText?"white":"black"
		, monofont
		, spanhtml)
	return html
}

Evtbl_BtnOK()
{
;	dev_TooltipAutoClear("Evtbl_BtnOK", 1000)

	html := Evtbl_GenHtml()
	
	if(html) ; if html is null, leave the GUI on so that user can do fix.
	{
		Evtbl_HideGui(html)
	}
}

Evtbl_OnComboColorChange()
{
	Evtbl_SyncUserInputToColorPreview()
}

EVTBLGuiEscape() ; The GuiEscape hook
{
;	msgbox, % "EVTBLGuiEscape()"
	Evtbl_HideGui(html)
}


EVTBLGuiClose() ; The GuiClose hook
{
;	msgbox, % "EVTBLGuiClose()"
	Evtbl_HideGui()
}

Evtbl_BtnPreviewHtml()
{
	html := Evtbl_GenHtml()

	PreviewHtml_ShowGui(html)
}

Evtbl_procTextColor()
{
	Evtbl_SyncUserInputToColorPreview()
}

_validate_color_triple(cobj)
{
	if(cobj.red>=0 && cobj.red<=255 && cobj.green>=0 && cobj.green<=255 && cobj.blue>=0 && cobj.blue<=255)
		return cobj
	else
		return
}

util_GetRgbTripleFromStr(colortext)
{
	; colortext can be "#f0f0f0...", or "rgb(0,128,255)..." // should not be "f0f0f0..."
	; note: "#f0f0f0a" or "#f0f0f011..." is not valid
	; Return an object with three members of .red .green .blue
	
	cobj := {}
	
	; Check for "#f0f0f0"
	;
	RegExMatch(colortext, "^#[0-9a-fA-F]{6}(?!\w)", hexcolor)
	; -- hexcolor will be "#f0f0f0" etc if colortext is valid.
	if(hexcolor)
	{
		cobj.red := dev_Hex2Num(SubStr(hexcolor, 2, 2))
		cobj.green := dev_Hex2Num(SubStr(hexcolor, 4, 2))
		cobj.blue := dev_Hex2Num(SubStr(hexcolor, 6, 2))
		return _validate_color_triple(cobj)
	}
	
	; Check for "rgb(...)"
	;
	RegExMatch(colortext, "i)^rgb\(([0-9]{1,3})[ ,]+([0-9]{1,3})[ ,]+([0-9]{1,3})\)", subpat)
	if(subpat)
	{
		cobj.red := subpat1
		cobj.green := subpat2
		cobj.blue := subpat3
		return _validate_color_triple(cobj)
	}
}

util_ColorTripleToHex(ctriple, is_prefix_sharp:=false)
{
	rgbstr := Format("{:02X}{:02X}{:02X}", ctriple.red, ctriple.green, ctriple.blue)
	return (is_prefix_sharp ? "#" : "") . rgbstr
}

util_ColorTripleToRGB(ctriple, is_prefix_sharp:=false)
{
	rgbstr := Format("rgb({},{},{})", ctriple.red, ctriple.green, ctriple.blue)
	return rgbstr
}

Evtbl_GetHexcolorFromStr(colortext)
{
	ctriple := util_GetRgbTripleFromStr(colortext)
	if(!ctriple)
	{	; if colortext contains invalid RGB values, will return null
		return ""
	}

	hexcolor := util_ColorTripleToHex(ctriple, true)
	return hexcolor
}


Evtbl_GetColorDicts()
{
	ar_colordict := []
	presets := g_evtblColorPresets.Length()
	
	arinput := []
	arinput.Push(g_evtblColorPresets*)
	
	if(g_evtblColorCustoms)
	{
		arinput.Push(g_evtblColorCustoms*)
	}

	colors := arinput.Length()
	
	Loop, %colors%
	{
		; For an item like "#f0f0ff,灰蓝", convert it into "#f0f0ff, rgb(240,240,255) 灰蓝",
		; so that user sees both color hex code and RGB code.
		
		itemstr := arinput[A_Index] ; itemstr is like "#f0f0ff,灰蓝" or just "#f0f0ff"
		if(itemstr=="")
			continue
		
		token := StrSplit(itemstr , ",")
		; -- token[1]="#f0f0ff" , token[2]="灰蓝"
		
		ctriple := util_GetRgbTripleFromStr(token[1])
		
		if(!StrIsStartsWith(token[1], "#") || !ctriple)
		{
			if(A_Index<=presets)
			{
				MsgBox, % Format("g_evtblColorPresets[{1}]=""{2}"" does not contain a valid color code. (Should start with sth like #80F0FF)"
					, A_Index, g_evtblColorPresets[A_Index])
			}
			else 
			{
				MsgBox, % Format("g_evtblColorCustoms[{1}]=""{2}"" does not contain a valid color code. (Should start with sth like #80F0FF)"
					, A_Index-presets, g_evtblColorCustoms[A_Index-presets])
			}
			continue
		}
		
		dict := {}
		dict.hexcode := util_ColorTripleToHex(ctriple, true)
		dict.rgbcode := util_ColorTripleToRGB(ctriple)
		dict.desc := token[2]
		ar_colordict.Push(dict)
	}
	
	extras := g_evtblColorCustoms.Length()
	Loop, %extras%
	{
	
	}
	
	return ar_colordict
}

Evtbl_ComboboxFillColorPresets(varname_combobox, default_idx)
{
	combostr := ""
	ar_colordict := Evtbl_GetColorDicts()
	colors := ar_colordict.Length()
	
	Loop, %colors%
	{
		; For an item like "#f0f0ff,灰蓝", convert it into "#f0f0ff, rgb(240,240,255) 灰蓝",
		; so that user sees both color hex code and RGB code.
		
		d := ar_colordict[A_Index]
		itemstr := Format("{1}, {2} {3}", d.hexcode, d.rgbcode, d.desc)
		
		combostr .= "|" itemstr
	}

	; Add color strings to combo dropdown list:
	
	GuiControl, EVTBL:, %varname_combobox%, % combostr

	GuiControl, EVTBL:Choose, %varname_combobox%, % default_idx
	
;	Evtbl_RedrawPreviewBox(..., "00f0f0") ;// test
}

Evtbl_RedrawPreviewBox(varname_bg, varname_text, hexcolor, is_black_text:=true, text:="")
{
	; varname_bg: the progress-bar varname as colored background.
	; varname_text: the text-label varname to draw foreground text.

	; hexcolor can be "#f0f0ff" or "f0f0ff"
	if( SubStr(hexcolor, 1, 1) == "#" )
		hexcolor := SubStr(hexcolor, 2) ; strip leading "#"
	
	if(!text)
		text := text_ColorPreview

;	GuiControl, +BackgroundFF9977, g_evtblPreviewBox ;// just test
	GuiControl, EVTBL:+Background%hexcolor%, %varname_bg%
	
	; I need to redraw the Text, otherwise, the text is wiped off by the Progress control.
	text_color := is_black_text ? "000000" : "FFFFFF"
	GuiControl, EVTBL:+c%text_color%, %varname_text%
	GuiControl, EVTBL:, %varname_text%, % text
}

Evtbl_SyncUserInputOneColor(varname_combobox, varname_bgbox, varname_text, is_black_text, text)
{
	; All parameters are strings, not variable token.
	; varname_combobox: the combobox containing user input.
	; varname_bgbox: the progress-bar varname as colored background.
	; varname_text: the text-label varname to draw foreground text.
	; text: text to show on text-label.
	; Return hexcolor("#AAE8FF" etc) for caller use.

	; Grab the color assignment in Combobox, and update the Preview-box accordingly.
	GuiControlGet, colortext, EVTBL:, %varname_combobox%
	;	dev_TooltipAutoClear("$==" colortext)
	
	; colortext is sth like: "#f0f0f0, rgb(240,240,240) 灰", and we only 
	; care the "#f0f0f0" part which is enough to represent a color value.
	; Alternatively, colortext=="rgb(nnn,nnn,nnn)" is accepted.

	hexcolor := Evtbl_GetHexcolorFromStr(colortext)
	if(!hexcolor)
	{
		Evtbl_RedrawPreviewBox(varname_bgbox, varname_text, "#000000", false, "Invalid color code")
		return ""
	}
;	dev_TooltipAutoClear(">>>" hexcolor, 1000) ;// debug, enable this to verify whether the sync-timer has stopped.
	
	Evtbl_RedrawPreviewBox(varname_bgbox, varname_text, hexcolor, is_black_text, text)
	
	return hexcolor
}

Evtbl_SyncUserInputToColorPreview() ; key UI update function
{
	GuiControlGet, g_evtblIsWhiteText, EVTBL:
	is_black_text := g_evtblIsWhiteText ? false : true
	
	GuiControlGet, g_evtblUse2ndColor, EVTBL:
	u2 := g_evtblUse2ndColor

	color1text := u2 ? "1st color" : "Color Preview"
	
	hexcolor1 := Evtbl_SyncUserInputOneColor("g_evtblComboColor", "g_evtblPreviewBox", "g_evtblPreviewText", is_black_text, color1text)

	if(u2==1)
	{	; Use 2nd color
		hexcolor2 := Evtbl_SyncUserInputOneColor("g_evtblComboColor2", "g_evtblPreviewBox2", "g_evtblPreviewText2", is_black_text, "2nd color")

		box := g_evtblBox1HalfPos
		GuiControl, EVTBL:Show, g_evtblPreviewBox2
		GuiControl, EVTBL:Show, g_evtblPreviewText2
		GuiControl, EVTBL:Show, g_evtblPreviewMix
		GuiControl, EVTBL:Enable, g_evtblComboColor2
	}
	else 
	{
		box := g_evtblBox1FullPos
		GuiControl, EVTBL:Hide, g_evtblPreviewBox2
		GuiControl, EVTBL:Hide, g_evtblPreviewText2
		GuiControl, EVTBL:Hide, g_evtblPreviewMix
		GuiControl, EVTBL:Disable, g_evtblComboColor2
	}
	
	boxpos := Format("x{} y{} w{} h{}", box.x, box.y, box.w, box.h)
	GuiControl, EVTBL:Move, g_evtblPreviewBox, % boxpos
	GuiControl, EVTBL:Move, g_evtblPreviewText, % boxpos

	Evtbl_HtmlShowMixColor(hexcolor1, hexcolor2, is_black_text)
}

Evtbl_HtmlShowMixColor(hexcolor1, hexcolor2, is_black_text)
{
	; hexcolor can be "#f0f0ff" or "f0f0ff"
	if( SubStr(hexcolor1, 1, 1) != "#" )
		hexcolor1 := "#" hexcolor1 ; add leading "#"
	if( SubStr(hexcolor2, 1, 1) != "#" ) 
		hexcolor2 := "#" hexcolor2 ; add leading "#"

	WB := g_evtblPreviewMix
	div := WB.document.body.firstChild
	div.style.color := is_black_text ? "black" : "white"

	try {
		div.style.background := Format("linear-gradient(15deg, {}, {})", hexcolor1, hexcolor2)
		g_evtbl_IE11_ok := true
	} catch e {
		; That means IE11 is not installed on this computer. So modify the preview text to tell user.
		g_evtbl_IE11_ok := false
		div.style.fontSize := "small"
		div.style.color := "red"
		div.innerHTML := "No IE11, no gradient color!"
	}
}

Evtbl_HtmlInitContent(WB)
{
	; A piece of html code to place "Mixed Color" text always in middle of the viewport.
	html_tmpl =
( Ltrim Join
<!DOCTYPE html>
<html>
<head>
<style>
div {
	position: fixed;
	left: 0px; right: 0px; top: 0px; bottom: 0px;
    text-align: center;
    vertical-align: middle;
}
table {
	width: 100`%;
	height: 100`%;
}
</style>
</head>
<body>
	<div><table><tr><td>Mixed color</td></tr></table></div>
</body>
</html>
)
	html_code := html_tmpl

	WB.silent := true ;Surpress JS Error boxes
	WB.Navigate("about:blank") ; do it once
	WB.document.write(html_code)

;	ComObjConnect(WB, WB_events)  ; Connect WB's events to the WB_events class object, not required here.
}

Evtbl_CalBorderColorFromBgColor(hexcolor)
{
	; hexcolor can be "#f0f0ff" or "f0f0ff"
	if( SubStr(hexcolor, 1, 1) == "#" )
		hexcolor := SubStr(hexcolor, 2) ; strip leading "#"

	ctriple := util_GetRgbTripleFromStr("#" hexcolor)

	factor := 0.75
	newr := Round(ctriple.red * factor)
	newg := Round(ctriple.green * factor)
	newb := Round(ctriple.blue * factor)

	newcolor := Format("#{:02X}{:02X}{:02X}", newr, newg, newb)

	return newcolor
}


Evtbl_WM_MOUSEMOVE()
{
	if(A_GuiControl=="g_evtblBtnColorMatrix" || A_GuiControl=="g_evtblBtnColorMatrix2")
	{
		tooltip, % "Show color matrix for easier picking."
	}
	else if(A_GuiControl=="g_evtblTableColumnSpec")
	{
		GuiControlGet, g_evtblTableColumnSpec, EVTBL:
		
		ar_colinfo := Evtbl_ParseTableColumnWidth(g_evtblTableColumnSpec)
		if(!ar_colinfo) {
			tooltip, % "Wrong input: Empty table columns assignment."
			return
		}
		
		tipstr := ""
		Loop, % ar_colinfo.Length()
		{
			tipstr .= Format("Column {1}: width={2}px, header text={3}`n"
				, A_Index, ar_colinfo[A_Index].width_px, ar_colinfo[A_Index].text)
		}
		tooltip, % tipstr
	}
	else if(A_GuiControl=="g_evtblCssTableColumnSpec")
	{
		GuiControlGet, g_evtblCssTableColumnSpec, EVTBL:
		ColumnSpec := g_evtblCssTableColumnSpec
		
		if( Instr(ColumnSpec, ",") )
		{
			ar_colinfo := Evtbl_ParseTableColumnWidth(ColumnSpec)
			if(!ar_colinfo) {
				tooltip, % "Wrong input! Should be a single integer(column count), or comma separated values(column width proportions)."
				return
			}
			
			; Show proportion of each column 
			tipstr := "Will insert CSS-table:`n"
			Loop, % ar_colinfo.Length()
			{
				width_value := ar_colinfo[A_Index].width_px
				tipstr .= Format("Column {1}: width {2}{3}`n", A_Index, width_value
					, StrIsEndsWith(width_value, "%") ? "" : "%")
			}
			tooltip, % tipstr
			return
		}
		else
		{
			columns := ColumnSpec + 0
			
			if(columns<=0) {
				tooltip, % "Wrong input value, should be a positive integer: 2, 3, 4 etc."
				return
			}
			
			tipstr := Format("Will insert CSS-table, {1} columns. `nColumn widths will be adjusted by cell content automatically.", columns)
			tooltip, % tipstr
			return
		}
	}
	else if(A_GuiControl=="g_evtblBtnOK")
	{
		dev_TooltipAutoClear("In case pasted content does not appear, please manually strike Ctrl+V inside your Evernote clip, one or two times.", 3000)
	}
	else if(A_Gui=="EVTBL")
	{
		tooltip ; hide previous tooltip
	}
}

Evtbl_ColorComboSetColorDualFormat()
{
	; Check combobox content. If it contains a color code but not in dual-format,
	; (for example "#f0f0ff" or "rgb(240,240,255)")
	; convert it to dual-format like "#f0f0ff, rgb(240,240,255)"
	
	GuiControlGet, g_evtblComboColor, EVTBL:

	ctriple := util_GetRgbTripleFromStr(g_evtblComboColor)
	if(!ctriple)
		return ; bad color format, do nothing
	
	hexstr := util_ColorTripleToHex(ctriple, true)
	rgbstr := util_ColorTripleToRGB(ctriple)
	
	if(SubStr(g_evtblComboColor,1,1)=="#")
		newstr := Format("{1}, {2}", hexstr, rgbstr)
	else
		newstr := Format("{2}, {1}", hexstr, rgbstr)
	
	if(!StrIsStartsWith(g_evtblComboColor, newstr, true))
	{
		GuiControl, EVTBL:Text, g_evtblComboColor, % newstr
	}
}

Evtbl_WM_COMMAND(wParam, lParam, msg, hwnd)
{
	hctrl := lParam
	notify_code := wParam >> 16
	
	if(hctrl==g_evtblHwndComboColor && notify_code==4) ; CBN_KILLFOCUS=4 , CBN_SETFOCUS=3
	{
;		MsgBox, CBN_KILLFOCUS=4 hctrl=%hctrl% g_evtblHwndComboColor=%g_evtblHwndComboColor%
		Evtbl_ColorComboSetColorDualFormat()
	}
	
;	Msgbox, % Format("WM_COMMAND: wParam={:X} lParam={:X}", wParam, lParam)
;	dev_TooltipAutoClear( Format("WM_COMMAND: wParam={:X} lParam={:X}", wParam, lParam) )
}

PreviewHtml_ShowGui(html)
{
	if(!g_HwndPreviewHtml)
		PreviewHtml_CreateGui()
	
	GuiControl, PvHtml:, g_PvhtmlEdit, % html
	
	Gui, PvHtml:Show, , % "Preview CF_HTML Content"

	if(g_HwndEvtbl)
	{
		; Simulate that PvHtml is a Model dialog box from EVTBL.
		Gui, PvHtml:+OwnerEVTBL
		Gui, EVTBL:+Disabled
	}
}

PreviewHtml_CreateGui()
{
	; Create the Preview HTML(CF_HTML raw content) GUI
	
	Gui, PvHtml:New
	
	Gui, PvHtml:+Hwndg_HwndPreviewHtml
	
	Gui, PvHtml:Add, Text, , % "CF_HTML raw content:"
	Gui, PvHtml:Add, Edit, xm w760 r10 vg_PvhtmlEdit, % "dyn content"

	Gui, PvHtml:Font, s8 cBlack, Tahoma
	Gui, PvHtml:Add, Button, xm vg_PvhtmlClipboard gPvhtml_SendtoClipboard , % "&Send to Clipboard as CF_HTML"
	Gui, PvHtml:Add, Text, x+10 w500 vg_PvhtmlMsg, % ""

	; Make the GUI resizable with current size as minimum size.
	Gui, PvHtml:+Resize +MinSize
	
	; Gui auto-resize data:
;	Gui, PvHtml:Show ; So that the HWND is created then we know each ctrl's position
;	Gui, PvHtml:Hide
;WinGetPos, x,y,w,h, ahk_id %g_HwndPreviewHtml% ; Why? cannot get x,y,w,h here! Leave it alone.
;MsgBox, % "!!! " . w . "  " . h . " ^ " . g_HwndPreviewHtml ; g_HwndPreviewHtml is not null
}

Pvhtml_SendtoClipboard()
{
	Gui, PvHtml:Submit, NoHide
	
	dev_ClipboardSetHTML(g_PvhtmlEdit, false)

	; Set prompt message and clear it after 1000ms
	GuiControl_SetText("PvHtml", "g_PvhtmlMsg", "Sent to clipboard done.")

	fn_clearmsg := Func("GuiControl_SetText").Bind("PvHtml", "g_PvhtmlMsg", "")
	SetTimer, %fn_clearmsg%, -1000
}

PvHtmlGuiSize() ; Window resizing hook: PvHtml++GuiSize
{
;	dev_TooltipAutoClear("PvHtmlGuiSize():" . A_Gui . " " . g_HwndPreviewHtml) ;// A_Gui="PvHtml"

;WinGetPos, x,y,w,h, ahk_id %g_HwndPreviewHtml% ; get x,y,w,h here OK!
;MsgBox, % "@@@ " . w . "  " . h
	
;	newpos := Format("x{} y{} w{} h{}", 10, 20, A_GuiWidth-20, A_GuiHeight-50)
;	ctrlvar := "g_PvhtmlEdit"
;	GuiControl, PvHtml:Move, %ctrlvar% , % newpos ;

	rsdict := {}
	rsdict.g_PvhtmlEdit := "0,0,100,100" ; Left/Top/Right/Bottom
	rsdict.g_PvhtmlClipboard := "0,100,0,100"
	rsdict.g_PvhtmlMsg := "0,100,0,100"
	dev_GuiAutoResize("PvHtml", rsdict, A_GuiWidth, A_GuiHeight)
}

PvHtml_MyCleanup()
{
	dev_GuiAutoResizeRemove("PvHtml")
	g_HwndPreviewHtml := ""
	
	Gui, EVTBL:-Disabled ; Revert the +Disabled status in PreviewHtml_ShowGui()
}

PvHtmlGuiEscape()
{
	PvHtml_MyCleanup()
	
	Gui, PvHtml:Destroy ; Note: This will not call PvHtmlGuiClose() internally
}

PvHtmlGuiClose()
{
;	MsgBox, % "PvHtmlGuiClose()"
	PvHtml_MyCleanup()
}

Evtbl_ShowColorMatrix()
{
	g_varnameComboColorOut := "g_evtblComboColor"
		; This global var will be used inside ColorMatrix_HideGui()

	ColorMatrix_ShowGui()
}

Evtbl_ShowColorMatrix2()
{
	g_varnameComboColorOut := "g_evtblComboColor2"
	ColorMatrix_ShowGui()
}

ColorMatrix_ShowGui()
{
	GuiControlGet, g_evtblIsWhiteText, EVTBL:
	is_black_text = g_evtblIsWhiteText ? false : true
	
	if(!g_HwndColorMatrix) {
		ColorMatrix_CreateGui()
	}

	Gui, ColorMatrix:Show, , % "EverTable ColorMatrix"
	
	OnMessage(0x200, Func("ColorMatrix_WM_MOUSEMOVE")) ; add message hook
	
	GuiControl, ColorMatrix:, g_colormatrixIsWhiteText, % is_black_text?0:1
	
	ColorMatrix_RepaintLabels()
}

cmutil_xy_index0b(linear_index) ; 1-based input, 0-based output
{
	xyi := {}
	xyi.x := Mod(linear_index-1, COLORCELLs_perline)
	xyi.y := (linear_index-1) // COLORCELLs_perline
	return xyi
}

cmutil_xy_index1b(linear_index) ; 1-based input & output
{
	xyi := {}
	xyi.x := Mod(linear_index-1, COLORCELLs_perline) + 1
	xyi.y := (linear_index-1) // COLORCELLs_perline + 1
	return xyi
}

ColorMatrix_CreateGui()
{
	gar_colordict := Evtbl_GetColorDicts() ; return a dict array
	
	Gui, ColorMatrix:New ; Destroy old if existed
	Gui, ColorMatrix:+Hwndg_HwndColorMatrix +Resize +MinSize
	Gui, ColorMatrix:Color, white ; bcz Evernote evclip's background is always white
	
	Gui, ColorMatrix:Margin, % COLORCELL_xmargin, % COLORCELL_ymargin
	
	Gui, ColorMatrix:Font, s9 cBlack, % "Tahoma" ; "Sans Serif"
	
	Gui, ColorMatrix:Add, Text, Section, % "Double click a color to use."
	
	xgap_half := Round(COLORCELL_xgap/2)
	
	colors := gar_colordict.Length()
	Loop, %colors%
	{
		dcolor := gar_colordict[A_Index]
		xy0 := cmutil_xy_index0b(A_Index)
	
		ctrlpos := Format("x{} y{} w{} h{}"
			, COLORCELL_xmargin    + xy0.x*COLORCELL_xspan + xgap_half
			, COLORCELL_ymarginTop + xy0.y*COLORCELL_yspan
			, COLORCELL_width, COLORCELL_height)
		
		label_text := dcolor.desc ? dcolor.desc : dcolor.hexcode
		
		Gui, ColorMatrix:Add, Text
			, % Format("{} Center +Border gColorLabelClicked hwndHWND vg_matrixColor{}", ctrlpos, A_Index)
			, % label_text

		if(Mod(A_Index, COLORCELLs_perline)==0) 
		{
			; I need to add a "hidden" ctrl per line to make dev_GuiAutoResize's proportion+offset 
			; algorithm work. (comment out the "Hidden" option below to see these hidden ctrl)
			
			Gui, ColorMatrix:Add, Progress, x+0 w%xgap_half% BackgroundRed Hidden
		}
		
		dcolor.hwnd := HWND
	}
	
	; Same idea, create a Y-direction hidden ctrl for dev_GuiAutoResize's algorithm
	Gui, ColorMatrix:Add, progress, xm yp+%COLORCELL_height% h%COLORCELL_ygap% vg_HiddenCtrlYD BackgroundRed Hidden
	
	Gui, ColorMatrix:Add, Checkbox, xm vg_colormatrixIsWhiteText gColormatrix_IsWhiteText, % "White text"
}


ColorLabelClicked()
{
;	Msgbox, % Format("ColorLabelClicked({}) A_GuiEvent={}", A_GuiControl, A_GuiEvent)

	; [2018-08-18] Weird on Autohotkey 1.1.24: Executing a dbclick for a Text label will cause
	; Text label content to be put into clipboard. Reason unknown yet.
	
	if(A_GuiEvent=="DoubleClick")
	{
		RegExMatch(A_GuiControl, "^g_matrixColor([0-9]+)", subpat)
		
		if(subpat)
		{
			ColorMatrix_HideGui(subpat1)
		}
	}
}

ColorMatrix_WM_MOUSEMOVE()
{
	RegExMatch(A_GuiControl, "^g_matrixColor([0-9]+)", subpat)
	idxColorLabel := subpat ? subpat1 : 0

    if(idxColorLabel>0)
    {
    	d := gar_colordict[idxColorLabel]
    	
    	tipstr := Format("{1}, {2} {3}", d.hexcode, d.rgbcode, d.desc)
        tooltip, % tipstr
    }
    else if(A_Gui=="ColorMatrix")
    {
        tooltip ; hide previous tooltip
    }
}

Colormatrix_IsWhiteText()
{
	Gui, ColorMatrix:Submit, NoHide
	
	ColorMatrix_RepaintLabels()
}

ColorMatrix_RepaintLabels()
{
	; Repaint according to g_colormatrixIsWhiteText's value
	GuiControlGet, g_colormatrixIsWhiteText, ColorMatrix:
	
	colors := gar_colordict.Length()
	Loop, %colors%
	{
		bgcolor0x := "0x" SubStr(gar_colordict[A_Index].hexcode,2,6) ; bgcolor0x="0xF0F0FF" etc
		
		foregroundcolor := g_colormatrixIsWhiteText ? 0xFFffFF : 0
		
		CtlColorStatic(gar_colordict[A_Index].hwnd
			, bgcolor0x ; I cannot use "" to indicate "keep original background color".
			, foregroundcolor) 
	}
}

ColorMatrixGuiSize() ; Window resizing hook: ColorMatrix++GuiSize
{
	xmg := COLORCELL_xmargin
	ymg1 := COLORCELL_ymarginTop
	GuiControlGet, rect, ColorMatrix:Pos, g_HiddenCtrlYD
	static ymg2 := 0 ; Use static bcz A_GuiHeight varies each time
;	MsgBox, % Format("Wzz: {} , {} | {}", rectY, rectH, ymg2)

	static rsdict := ""
	if(!rsdict)
	{
		; Initialize once
		rsdict := {}
		colors := gar_colordict.Length()

		ymg2 := A_GuiHeight - (rectY+rectH)

		Loop, %colors%
		{
			xyi := cmutil_xy_index0b(A_Index)
			idxrow := xyi.y
			idxcol := xyi.x
			
			; x0, y0: left-top corner of this ctrl
			pixelx0 := idxcol * COLORCELL_xspan
			pixely0 := idxrow * COLORCELL_yspan
			
			; x1, y1: (pseudo)right-bottom corner of this ctrl
			pixelx1 := (idxcol+1) * COLORCELL_xspan
			pixely1 := (idxrow+1) * COLORCELL_yspan

			x0pct := Round(pixelx0 / (A_GuiWidth-xmg*2) * 100)
			y0pct := Round(pixely0 / (A_GuiHeight-ymg1-ymg2) * 100)
			x1pct := Round(pixelx1 / (A_GuiWidth-xmg*2) * 100)
			y1pct := Round(pixely1 / (A_GuiHeight-ymg1-ymg2) * 100)

			rsdict["g_matrixColor" A_Index] := Format("{},{},{},{}", x0pct, y0pct, x1pct, y1pct)
		}
		
		rsdict.g_colormatrixIsWhiteText := "0,100,0,100" ; stick to left bottom
	}

	qmargin := Format("{},{},{},{}", xmg, ymg1, xmg, ymg2)

	dev_GuiAutoResize("ColorMatrix", rsdict, A_GuiWidth, A_GuiHeight, false, qmargin)
	
	; Note: Passing true as dev_GuiAutoResize's final param causes serious flicking.
	; Calling ColorMatrix_RepaintLabels() once has less flickering.
	ColorMatrix_RepaintLabels() 
}

ColorMatrix_HideGui(idx_select:=0)
{
	GuiControlGet, g_colormatrixIsWhiteText, ColorMatrix:

	Gui, ColorMatrix:Hide
	OnMessage(0x200, Func("ColorMatrix_WM_MOUSEMOVE"), 0) ; remove message hook
	tooltip
	
	if(idx_select>0)
	{
		varname := g_varnameComboColorOut ; maybe "g_evtblComboColor" or "g_evtblComboColor2"
;		dev_TooltipAutoClear("varname=" varname)
		GuiControl, EVTBL:Choose,  %varname% , % idx_select
		
		iswhite := g_colormatrixIsWhiteText ? 1 : 0
		GuiControl, EVTBL:, g_evtblIsWhiteText, % iswhite

		Evtbl_SyncUserInputToColorPreview()
	}
}

ColorMatrixGuiEscape() 
{
	ColorMatrix_HideGui()
}

ColorMatrixGuiClose() 
{
	ColorMatrix_HideGui()
}

; ========================= Evtbl code ends =========================




;==============================================================
; Evernote 5.x
;==============================================================

Evernote_InsertOneCellTable()
{
	Send !ot 
	WinWaitActive, Insert Table, , 2
	ControlSetText, Edit1, 1, A
	ControlSetText, Edit2, 1, A
	Send {enter}
}

Evernote_IsMainFrameActive()
{
	return IsWinClassActive("ENMainFrame")
}

Evernote_IsSingleNoteActive()
{
	return IsWinClassActive("ENSingleNoteView")
}

Evernote_IsMainFrameOrSingleActive()
{
	if( Evernote_IsMainFrameActive() or Evernote_IsSingleNoteActive() )
		return true
	else
		return false
}


Evernote_ClickEditingArea()
{
	; Editing area is the biggest pane(typically at right side) you view and edit your clip content.
	;
	ControlGetPos, xe, ye, we, he, WebViewHost1, A
	ControlGetPos, xf, yf, wf, hf, ENNoteScrollView1, A ; f: the Frame-window surrounding the editing area, only in Evernote 6.3 and earlier
	ControlGetPos, xn, yn, wn, hn, ENHtmlNoteCtrl1, A ; In Evernote 6.5

	;msgbox, WebViewHost1 %xe%,%ye%[%we%,%he%] // ENNoteScrollView1 %xf%,%yf%[%wf%,%hf%] // ENHtmlNoteCtrl1 %xn%,%yn%[%wn%,%hn%]
		; Evernote 6.5.4: ENHtmlNoteCtrl1 618,246[829,746]

	;The upper border of the editing-area should overlap the ENNoteScrollView childwin upper border. // Evernote 5.9
	;msgbox, %ye% / %yf%  ; 214 /129 for evernote 5.9
	
	if (wn>300 and hn>300) {
		classnn_to_click := "ENHtmlNoteCtrl1" ; [2017-08-23] Evernote 6.5.4
	}
	else if (wf==0 and hf==0) {
		classnn_to_click := "WebViewHost1" ; [2015-09-03] This occurs on Evernote 5.9
	}
	else if( abs(ye-yf)<20 ) { 
		classnn_to_click := "WebViewHost1" ; Evernote 5.8.x verify ok
	}
	else {
		classnn_to_click := "WebViewHost2" ; Evernote 5.8.x verify ok
		; Sometime WebViewHost1 is the "related notes hidden pane".
	}
	
	; ControlClick, %classnn_to_click%, A, , LEFT
	ClickInActiveControl(classnn_to_click, 0.5, 0.5)
}

Evernote_AlignCenter()
{
	; Sigh, no keyboard driven method available.
	
	ControlGetPos, tbx, tby, tbw, tbh, ENHtmlToolbarCtrl1, A
	ClickInActiveWindow(tbx+520, tby+16)
	Sleep, 500 ; In hope the drop down appears
	ClickInActiveWindow(tbx+520, tby+96)
}

Evernote_PastePlainText()
{
	; Evernote 6.5.4: Paste plain text.
	; via Evernote internal hotkey: Ctrl+Shift+v , Paste and matching style.
	
	dev_SendKeyToExeMainWindow("{Ctrl down}{Shift down}v{Shift up}{Control up}")
	; -- by using ControlSend to specific target, we will not trigger global hotkey Ctrl+Shift+v, great.
	
	;Send !em ;// -- old style, Popping up main menu is not so reliable.
}

Evernote_ClickNoteListArea()
{
	; ControlClick, ENSnippetListCtrl1, A, , LEFT
		; [2015-01-22] In Evernote 5.8.1, this is danger! Although it seems to work, but sometimes 
		; it moves some clip to a strange location.
		; So use ClickInActiveWindow() instead.
	ClickInActiveWindow(1/5, 1/2, false)
}

Evernote_GotoNoteListFirstItem()
{
	; In my convention, this causes ENMainFrame go to the newest clip.
	; I conventionally sort all my notes in last-updated order.

	Send {F6}
	; -- This clears current Notebook selection, so that note-list area displays
	; all clips, not just clips from a single Notebook.
	
	Evernote_ClickNoteListArea()
	
	Send {Home}
	; -- Go to first item in the list.
}

#IfWinActive ahk_class ENMainFrame

CapsLock & Left:: Evernote_ClickNoteListArea()

CapsLock & Right:: 
	Evernote_ClickEditingArea()
	; Tip: Press Caps+(Right Arrow, 2 or more times) to clearly see where the caret is,
	; because double click select(highlight) a word, triple click select a whole line.
return

CapsLock & Up:: Evernote_GotoNoteListFirstItem()

^!s:: Send +!n ; Jump to Notebook(dropdown list)

^F6:: 
	ControlFocus, ENAutoCompleteEditCtrl1, A
return

^F1:: 
	KeyWait, Ctrl ; otherwise, the note will pop-up in a separate window
	ClickInActiveControl("EnShortcutsBar1", 54, -8, true) ; Click on "first"(hopefully) shortcut link.
return

#IfWinActive


#IfWinActive ahk_class ENSingleNoteView

CapsLock & Right:: Evernote_ClickEditingArea()


ESC:: ; Do not allow ESC to close snippet window
	if(Is_PinyinJiaJia_Floatbar_Visible() || dev_IsWinclassExist("QQPinyinCompWndTSF"))
	{
		; If doing Pinyin JiaJia or QQ pinyin typing(a floating IME small window on screen), Esc is allowed.
		; The window class name "PYJJ_COMPUI_WND" can be probed by checking the HWND value under mouse cursor.
		; 	MouseGetPos, tmpX, tmpY, hwndUnderMouse
		;	WinGetClass, wndclass, ahk_id %hwndUnderMouse%
		SendInput {ESC}
	}
	; [2019-03-30] If ESC is pressed twice within a short time(e.g. 500ms), one ESC is always sent.
	
;	dev_TooltipAutoClear("PRior hotkey: " A_PriorHotkey)
	
	if (A_PriorHotkey == "Esc" and A_TimeSincePriorHotkey <= 500) {
	    ; This is a double-press.
		Send {ESC}
	}
return 

#IfWinActive ; ENSingleNoteView



#If Evernote_IsMainFrameOrSingleActive()

; 2013-09-26 F10, F11, F12 on Evernote(v5) to change font, font-size, font-color, F9 click into note-title
F10:: 
	ControlClick ENHtmlToolbarFontFace1, A, , LEFT, 1, X148 Y18
	ControlSend ENHtmlToolbarFontFace1, Consolas{enter}, A
return 

;+F10:: ; Set Tahoma font // [2023-04-29] use this for Evernote_CutAndPasteInlineCode_DynBg()
;	ControlClick ENHtmlToolbarFontFace1, A, , LEFT, 1, X148 Y18
;	ControlSend ENHtmlToolbarFontFace1, Tahoma{enter}, A
;return 
;
F11:: ControlClick ENHtmlToolbarFontSize1, A, , LEFT, 1, X44 Y18
F12:: Evernote_BringupPalette()
Evernote_BringupPalette()
{ 
	ControlClick ENHtmlToolbarCtrl1, A, , LEFT, 1, X240 Y18
}

+F12::
	Evernote_BringupPalette()
	Sleep, 500
	ClickInActiveControlEx("ENHtmlToolbarCtrl1", 240,false, 17,true, false) ; try to click on [Automatic color], which is keyboard unreachable
	; last-param false(don't move mouse) is desired, because when mouse is hovered over the palette popout area, the next time I F12 pop-out 
	; the palette, the previous color selection is perserved(so I can Enter to select it, convenient), and this feature will be
	; ruined if I leave the mouse pointer on the "Automatic color" area.
	; -- verified on Evernote 6.1.2 .
return

F8::  ControlClick ENHtmlToolbarCtrl1, A, , LEFT, 1, X524 Y18 ; Align style button(but Sigh, we cannot keyboard select the control list)
^F10:: Send !opb
^F11:: Send !opn
^t:: 
	Send !ot ; Insert Table
return
^]:: Send !opi ; Increase indent
^[:: Send !opd ; Decrease indent

^F12:: Evernote_AlignCenter()


^=:: Evernote_InsertOneCellTable()

^s:: MoveToNotebook()
MoveToNotebook()
{
	; This selects which notebook to place current clip.

	;ControlClick ENNoteInfoCtrl1, A, , LEFT, 1, X32 Y16 
		; This is only valid for Evernote 5. 
		; Evernote 6 changed the layout and fails it.

	; Evernote 6's new layout: should click around 18 pixels *above* ENHtmlToolbarCtrl.
	ClickInActiveControlEx("ENHtmlToolbarCtrl1", 9,false, -18,true)

	; [Menu item method] (not reliable)
	; Evernote 6 can use menu item "Note -> Move to notebook ...", but strangely this menu item 
	; sometimes greys out for some unknown reason. 
	
}

^!c:: Send ^+l ; Evernote 6: Apply code block to selected text.

; ^!p:: dev_ClipboardSetHTML("__<sup>^^</sup> =", true)
; ^!b:: dev_ClipboardSetHTML("^^<sub>__</sub> =", true)
^!':: Evernote_InsertSupSub()


#If ; Evernote_IsMainFrameOrSingleActive()


Evernote_InsertSupSub()
{
	; Create a "Supsub" GUI if not exist
	if(!g_HwndSupsub)
	{
		Gui, Supsub:New
		Gui, Supsub:+Hwndg_HwndSupsub
		Gui, Supsub:Add, Text, , % "Insert superscript or subscript into Evernote:"
		
		Gui, Supsub:Add, Text, xm y50 w160, % "Base text(optional):"
		Gui, Supsub:Add, Edit, xm y+2 w160 vg_SupsubBaseText, % ""
		
		Gui, Supsub:Add, Edit, x180 y50 w70 vg_SupsubSupText, % ""
		Gui, Supsub:Add, Text, x+5, % "<sup>...</sup>"
		
		Gui, Supsub:Add, Edit, x180 y80 w70 vg_SupsubSubText, % ""
		Gui, Supsub:Add, Text, x+5, % "<sub>...</sub>"
		
		Gui, Supsub:Add, Button, x150 y110 Default gBtnSupsubOK, % "Insert"
	}
	
	Gui, Supsub:Show, , % "Insert <sup> or <sub>"
}

BtnSupsubOK()
{
	Gui, Supsub:Submit
	
	if(g_SupsubSupText=="" and g_SupsubSubText=="") {
		MsgBox, "Nothing to do. <sup> text and <sub> text are both empty."
		; Q: How to prevent the GUI from closing?
;		Gui, Supsub:Show
		return
	}
	
	if(g_SupsubSupText!="" and g_SupsubSubText!="") {
		MsgBox, "Wrong input. <sup> text and <sub> text both contain text."
		return
	}
	
	if(g_SupsubSupText!="") {
		; Note: If I use a space instead of &nbsp; , later-typed words will appear in superscript format
		; -- which is not desired. // Evernote 6.5.4 .
		html := Format("{}<sup>{}</sup>&nbsp;", g_SupsubBaseText, g_SupsubSupText)
	} else {
		html := Format("{}<sub>{}</sub>&nbsp;", g_SupsubBaseText, g_SupsubSubText)
	}
	
	dev_ClipboardSetHTML(html, true)
}

SupsubGuiEscape()
{
	Gui, Supsub:Hide
}


; ^!\:: Evernote_InsertSideBySideDivs() ; old function
Evernote_InsertSideBySideDivs()
{
	; Evernote 6.5 does not allow table inside table. In case you want to have a simple 
	; one-row table inside a table, you can create a one-row table using this function.
	;
	; [2021-12-03] This has been superseded by Evtbl_GenHtml_CssTable().
	
	InputBox, cellwidths, % "Insert a side-by-side DIVs row", % "Input widths of your DIV cells, separated by commas.",, 384, 144, , , , , 100`,200
	
	if ErrorLevel {
		return
	}
	
	w := StrSplit(cellwidths, ",")
	if (w.Length() == 0) {
		return
	}
	
	div_fmt = 
(
	<div style='vertical-align: top; background-color: #f4f4f4; width: {1}px; border: 1px solid #c0c0c0; padding: 2px; margin: 3px; display: inline-block;'>{1}px</div>
)
	
	divs := ""
	Loop, PARSE, cellwidths, `,
	{
		divs .= Format(div_fmt, A_LoopField)
	}
	
;	dev_TooltipAutoClear(divs) ; debug
	
	html_fmt = 
(
<div style='background-color: white; border: 1px solid #eeeecc;'>
	{1}
</div>
-
)
;	dev_TooltipAutoClear(html_fmt)
	html := Format(html_fmt, divs)
	dev_ClipboardSetHTML(html, true)
}


Evtbl_GenHtml_FromTSV(hexcolor1, hexcolor2)
{
	html := Evernote_TSVtoHtml(Clipboard, "", hexcolor1, hexcolor2)
	return html
}
;
Evernote_TSVtoHtml(input_string, sepchar:="", hexcolor1="", hexcolor2="")
{
	; Result will be sent to clipboard
	; If sepchar==",", this do CSV converting.
	
	; Check input_string length first, if too big, it may be a user misoperation.
	warn_size := 128*1024
	inputlen := StrLen(input_string)
	if(inputlen>warn_size)
	{
		msg := Format("Text to convert exceeds {1} KB, which is {2}. Sure?", Floor(warn_size/1024), inputlen)
		goon := dev_MsgBoxYesNo(msg, false)
		if(!goon)
			return ""
	}
	
	if(!sepchar)
	{
		; If sepchar is empty, try to search for a Tab or a space.
		tabpos := InStr(input_string, "`t")
		commapos := InStr(input_string, ",")
		
		if(tabpos>0)
			sepchar := "`t"
		else if(commapos>0)
			sepchar := ","
		else {
			dev_MsgBoxWarning("No Tab or Comma found in your input(Clipboard). Nothing to do.")
			return ""
		}
	}

	omitchars := A_Space ; . A_Tab

	Loop, PARSE, % input_string , `n, `r
	{
		fields := StrSplit(A_LoopField, sepchar, omitchars)
		break
	}

	totcols := fields.Length()

	css_bg_rule := make_css_bg_rule(hexcolor1, hexcolor2) ; maybe pure color or color gradient

	theadline := ""
	Loop, % totcols
	{
		td_ptn = 
(
<td style="text-align:center; font-weight:bold; {1}">#{2}</td>
)
		theadline .= Format(td_ptn, css_bg_rule, A_Index-1)
	}
	theadline := "<tr>" theadline "</tr>`n"
	
	tbodylines := ""
	
	Loop, PARSE, % input_string, `n, `r
	{
		tds := ""

		tsv_line := A_LoopField
		fields := StrSplit(A_LoopField, sepchar, omitchars)
		
		Loop, % fields.Length()
		{
			 tds .= Format("<td>{1}</td>", fields[A_Index])
		}
		
		if(tds)
		{	; only add <tr> if this line is not empty
			tbodylines .= "<tr>" tds "</tr>`n"
		}
	}
	
	html_ptn =
(
+<table border="1" style="border-collapse:collapse; border-color:{1}; width:100`%;">
  {2}
  {3}
</table>~
) ; memo: The leading + and trailing ~ is for Evernote 6.13's sane purpose.
	
	html := Format(html_ptn, hexcolor1, theadline, tbodylines)
	return html
}


Evernote_PopLinkShowMenu_2x()
{
	; [2023-01-25] This function does not work as expected yet.
	; Reason: When a tracking popup-menu is shown, the Autohotkey's thread is blocked
	; inside WinAPI TrackPopupMenu(), so it cannot respond to any other keypress, 
	; until the popup-menu is dismissed.
	
	; [PURPOSE] On called first-time, full menu is shown.
	; If called a second-time in one second, Auto-pickup menu is displaye instead.

	static s_prevmsec := 0
	
	nowmsec := dev_GetTickCount64()

;	Dbgwin_Output(Format("Pop2x: now={} , diff={}", nowmsec, nowmsec-s_prevmsec))

	if(nowmsec - s_prevmsec > 1000)
	{
		if(Evernote_IsMainFrameOrSingleActive())
		{
			Evernote_PopLinkShowMenu()
; Dbgwin_Output(Format("Pop2x: Done"))
			
			s_prevmsec := nowmsec
		}
	}
	else 
	{
		Evernote_PopLinkShowAutoPickupMenu()
	}
	
}

Evernote_PopLinkShowMenu()
{
	evernote_InitEvxLinks()

	submenus_seen := []

	try {
		Menu, EvernotePoplinksMenu, DeleteAll ; Delete old items first
	} catch {
	}
	menuhead := Format("== {} ==",  g_evernotePopLinksFile)
	Menu, EvernotePoplinksMenu, Add, %menuhead%, Evernote_PopLinkFile_OpenEditor
	
	if(not FileExist(g_evernotePopLinksFile))
	{
		dev_MsgBoxWarning(Format("This file assigned in g_evernotePopLinksFile does NOT exit: {}", g_evernotePopLinksFile))
	}
	
	;
	; Load Auto-pickup evxlink files
	;
		
	if(evernote_ConstructAutoPickupMenu())
	{
		dev_MenuAddItem("EvernotePoplinksMenu", "Auto pickup", ":EvernoteAutopickupEvx")
	}
	
	;
	; Load static poplink files
	;
	
	Loop, read, % g_evernotePopLinksFile
	{
		if(SubStr(A_LoopReadLine, 1, 1)==";")
			continue ; this is a comment line, skip it.
		
	    fields := StrSplit(A_LoopReadLine, ",", " `t")

	    url := fields[1] ; sth like: https://www.evernote.com/shard/s21/nl/2425275/4586fb5e-4414-4e81-8ea8-75bf28d9d666
	    menutext := fields[2] ; e.g: MSBuild, WinGUI, Books:PRWIN5
	    desctext := fields[3] 
	    if(fields[4]) 
	    	desctext .= ", " fields[4]
	    if(fields[5]) 
	    	desctext .= ", " fields[5] 
	    
	    if (!url)
	    	continue
	    
	    ; If menutext has a colon in it, then I will create a submenu for it.
	    ; Word before the colon becomes the submenu name, word after the colon becomes menutext beneath the submenu.
	    
	    colonpos := InStr(menutext, ":")
	    ;
	    if(colonpos==0) ; no colon
	    {
			menutextfull := Format("&{1}`t{2}", menutext, desctext)

			fn := Func("Evernote_EvxLinkPaste").Bind(menutext, url)
			Menu, EvernotePoplinksMenu, Add, %menutextfull%, %fn%
	    
	    }
	    else
	    {
	    	submenuname := SubStr(menutext, 1, colonpos-1)
	    	menutext := SubStr(menutext, colonpos+1)
	    	
	    	if(!dev_hasValue(submenus_seen, submenuname))
	    	{
	    		try {
					Menu, %submenuname%, DeleteAll ; Delete old submenu-items first
				} catch {
				}
				submenus_seen.Push(submenuname)
			}
			
			menutextfull := Format("&{1}`t{2}", menutext, desctext)
	    	
	    	; Create submenu
	    	fn := Func("Evernote_EvxLinkPaste").Bind(menutext, url)
	    	Menu, %submenuname%, Add, %menutextfull%, %fn%
	    	
	    	; Create and add to parent menu
	    	Menu, EvernotePoplinksMenu, Add, &%submenuname%, :%submenuname%
	    }
	}
	
	Menu, EvernotePoplinksMenu, Show
}

Evernote_PopLinkShowAutoPickupMenu()
{
	evernote_InitEvxLinks()

	if(evernote_ConstructAutoPickupMenu())
	{
		dev_MenuShow("EvernoteAutopickupEvx")
	}
}

evernote_ConstructAutoPickupMenu()
{
	dev_Menu_DeleteAll("EvernoteAutopickupEvx")
	
	if(Evnt.arAutoEvxlinks.Length()>0)
	{
	  	for index,evx in Evnt.arAutoEvxlinks
		{
			fn := Func("Evernote_EvxLinkPaste").Bind(evx.word, evx.link, index)
			dev_MenuAddItem("EvernoteAutopickupEvx"
				, Format("&{}`t({})", evx.word, index)
				, fn)
		}

	    evernote_EvxArrayTruncateBeyondMax()

		return true 
	}
	else
		return false
}

Evernote_EvxLinkPaste(text, url, delete_index:=-1)
{
	html := Format("<span>[<a href='{1}'>{2}</a>]&nbsp;</span>", url, text)
	dev_ClipboardSetHTML(html, true)

	evernote_InsertEvxAtHead(text, url, delete_index)
}

Evernote_PopLinkFile_OpenEditor()
{
	if(not FileExist(g_evernotePopLinksFile))
	{
		dev_WriteWholeFile(g_evernotePopLinksFile, "")
	}

	Run, open "%g_evernotePopLinksFile%"
	
	Sleep, 500
	
	; Try to see whether current clipboard contains an Evernote link. If so, extract that link
	; and report it to user.
	
	html := WinClip.GetHtml("UTF-8")
	
	ptn := "<a href=""(https://www.evernote.com/shard/s21/nl/[0-9a-z-/]+)""[^>]*>(.+?)</a>"

	foundpos := RegExMatch(html, ptn, outfound)
	if( foundpos>0 )
	{
		; Msgbox, % "outfound1=" outfound1 ; debug
		url := outfound1
		evxlink := outfound2
		
		Clipboard := url
		
		MsgBox, % "Found Evernote in-clip url, and copied to clipboard:`n`n" url "`n`n" evxlink
	}
}


evernote_GetClipboardSingleLine()
{
	codetext := ""
	if(dev_CutToOrUseClipboard())
		codetext := Trim(Clipboard, "`r`n")
	
	if(!codetext) {
		dev_MsgBoxInfo("Clipboard is empty, nothing to paste.")
		return ""
	}
	
	if(InStr(codetext, "`n")) {
		dev_MsgBoxWarning("Clipboard text has multiple lines. To avoid pasting large chunks of text, inline code pasting is forbidden.")
		return ""
	}

	return codetext
}

Evernote_PasteSingleLineCode(bgcolor:="#e0e0e0", is_monofont:=true, keep_orig_clipboard:=true)
{
	; This is a special-case shortcut for Evtbl_GenHtml_Span() .
	; We paste clipboard text in colored background. 
	;
	; Current Shift-key state will force using mono-font.

	isShiftDown := GetKeyState("Shift")
	if(isShiftDown)
		is_monofont := true
	
	dev_WaitKeyRelease("Shift") ; to avoid triggering Ctrl+Shift+X (Encrypt selected text)
	
	codetext := evernote_GetClipboardSingleLine()
	if(!codetext)
		return
	
	html := Evtbl_GenHtml_Span(bgcolor, "", codetext, is_monofont ? true : false)

	dev_ClipboardSetHTML(html, true)

	if(keep_orig_clipboard) {
		; Restore plain-text to clipboard, bcz dev_ClipboardSetHTML() has .
		; [2023-04-28] We need to delay the restore a bit(500ms), bcz, 
		; the target process receiving Ctrl+V needs some time to fetch that
		; HTML content from clipboard.
		fn := Func("evernote_RestoreClipboardText").Bind(codetext)
		dev_StartTimerOnce(fn, 500)
	} 
}

evernote_RestoreClipboardText(text)
{
	Clipboard := text
}

Evernote_PasteSingleLineWithHtmlDeco(str_decofunc)
{
	puretext := evernote_GetClipboardSingleLine()
	if(!puretext)
		return
	
	puretext := dev_EscapeHtmlChars(puretext)
	
	html := %str_decofunc%(puretext)

	dev_ClipboardSetHTML(html, true)
}

Htmldeco_Kbd(puretext)
{
	style := Format("border: 1px solid #ccc;"
		. "padding: 0em 0.2em;"
		. "border-radius: 3px;"
		. "box-shadow: 1px 1px 0 rgba(0, 0, 0, 0.4);"
		. "background: linear-gradient(315deg, #fff, #ddd);"
		. "")

	html := Format("<span style=""{}"">{}</span>&nbsp;", style, puretext)
	return html
}

evernote_PasteInlineCode_AddMenuItem(bgcolor, desctext, idx)
{
	menutext := Format("&{1}. Bgcolor: {2} {3}", idx, bgcolor, desctext)
	
	fn := Func("Evernote_PasteSingleLineCode").Bind(bgcolor, "")
	dev_MenuAddItem("evernote_menuInlinePaste", menutext, fn)
}

evernote_InlinePaste_InitMenu()
{
	color_presets := [ "#e0e0e0,代码灰"
	, "#F0F0E0,药片黄"
	, "#C6E2FF,多云蓝"
	, "#B0E0B0,青瓷绿(celadon)"
	, "#FFE0B0,霞光橙"
	, "#F49292,故障红" ]
	
	dev_MenuAddItem("evernote_menuInlinePaste", "Paste as plain text (or F1 outside)", "Evernote_PastePlainText")
	
	fn := Func("Evernote_PasteSingleLineWithHtmlDeco").Bind("Htmldeco_Kbd")
	dev_MenuAddItem("evernote_menuInlinePaste", "&Kbd style it", fn)
	
	dev_MenuAddSepLine("evernote_menuInlinePaste")
	dev_MenuAddItem("evernote_menuInlinePaste", "(Hold down Shift to use mono-font below)", "dev_nop")
	
	for idx, colorspec in color_presets
	{
		token := StrSplit(colorspec, ",")
		; -- token[1]="#e0e0e0" , token[2]="代码灰"
		
		evernote_PasteInlineCode_AddMenuItem(token[1], token[2], idx)
	}
}


Evernote_PopupInlinePasteMenu()
{
	Menu, evernote_menuInlinePaste, Show
}


Evernote_PopupBlockPasteMenu()
{
	mn := "evernote_menuBlockPaste"
	fn := "CF_HTML_PasteCodeBlock"
	lnstart := Evnt.pastecode_start_numline
	
	dev_Menu_DeleteAll(mn)
	
	dev_MenuAddItem(mn, "==== Paste code block ====", "dev_nop")
	
	dev_MenuAddItem(mn, "&1. Paste code block // ...",  Func(fn).Bind("//", ["/*","*/"], 0))
	dev_MenuAddItem(mn, "&2. Paste code block `; ..." ,  Func(fn).Bind(";",  ["/*","*/"], 0))
	dev_MenuAddItem(mn, "&3. Paste code block # ..." ,  Func(fn).Bind("#",  ["""""""",""""""""], 0))

	dev_MenuAddItem(mn, "&4. Paste code block //... (line number)",  Func(fn).Bind("//", ["/*","*/"], lnstart))
	dev_MenuAddItem(mn, "&5. Paste code block `; ... (line number)" ,  Func(fn).Bind(";",  ["/*","*/"], lnstart))
	dev_MenuAddItem(mn, "&6. Paste code block # ... (line number)" ,  Func(fn).Bind("#",  ["""""""",""""""""], lnstart))

	dev_MenuAddItem(mn, Format("&0. Change start line-number (current: {})", lnstart), "Evernote_ChangeStartLinenum")

	dev_MenuShow(mn)
}

Evernote_ChangeStartLinenum()
{
	ln := evnt.pastecode_start_numline

	isok := dev_InputBox_DefaultText("", "New paste-code starting line-number:", ln)
	if(isok)
		Evnt.pastecode_start_numline := ln
}


#If Evernote_IsMainFrameOrSingleActive()

F1:: Evernote_PastePlainText()

; +Ins up:: Evernote_PastePlainText_exwait()
Evernote_PastePlainText_exwait()
{
	KeyWait, Shift, T1
	if (ErrorLevel==0) {
		; note: If not waiting Shift to be released, Shift+Ins's triggering Evernote_PastePlainText() 
		; will always paste like Ctrl+V, -- can't explain why yet.
		Evernote_PastePlainText()
	}
	else {
		dev_TooltipAutoClear("Evernote_PastePlainText_exwait() fails bcz Shift key is not released by user.")
	}
}

Ins up:: Evernote_PasteInlineCode_DynBg()

Evernote_PasteInlineCode_DynBg()
{
	codetext := Clipboard
	ilen := strlen(codetext)
	if(ilen==1)
		bgcolor := "#c0c0c0"
	else if(ilen==2)
		bgcolor := "#d0d0d0"
	else 
		bgcolor := "#e0e0e0"
	
	Evernote_PasteSingleLineCode(bgcolor, "monofont")
}



^Ins up:: Evernote_PopupInlinePasteMenu()

+Ins up:: Evernote_PopupBlockPasteMenu()

#Ins up:: CF_HTML_PasteCodeBlockPure()

Ins & 1:: CF_HTML_PasteCodeBlock("//", ["/*","*/"])
Ins & 2:: CF_HTML_PasteCodeBlock(";", ["/*","*/"])
Ins & 3:: CF_HTML_PasteCodeBlock("#" , ["""""""",""""""""])

CF_HTML_PasteCodeBlockPure(lnprefix_start:=0)
{
	codetext := Clipboard
	html := genhtml_code2pre_pure(codetext, lnprefix_start, 4, true)
	if(html)
	{
		dev_ClipboardSetHTML(html, true)
	}
}

CF_HTML_PasteCodeBlock(line_comment, block_comment:="", lnprefix_start:=0)
{
	codetext := Clipboard
	html := genhtml_code2pre_2022(codetext, lnprefix_start, line_comment, block_comment, 4, true)
	
	if(html)
	{
		dev_ClipboardSetHTML(html, true)
	
		Evnt.pastecode_start_numline := 1 ; reset it
	}
}

; [2023-04-29] Shift+F10 : cut current (single-line) text, then paste it as inline <code> style
+F10:: Evernote_CutAndPasteInlineCode_DynBg()
Evernote_CutAndPasteInlineCode_DynBg()
{
	dev_WaitKeyRelease("Ctrl") ; to avoid triggering Ctrl+Shift+X (Encrypt selected text)

	if(!dev_CutToClipboard()) ; will send Ctrl+X internally
		return
	
	nowtext := Clipboard
	if(!nowtext)
	{
		dev_MsgBoxWarning("Unexpect! No text cut to Clipboard.") ; user may have cut an image etc
		return
	}

	Evernote_PasteInlineCode_DynBg()
}

#If


evernote_InitEvxLinks()
{
	static s_inited := false
	if(s_inited)
		return

	s_inited := true

	Evnt.hcmEvxlink := Clipmon_CreateMonitor("evernote_PickupEvxlink", "evernote_InitEvxLinks")
	dev_assert(Evnt.hcmEvxlink)
	
	Loop, Read, % Evnt.filenamEvxlinks
	{
		ss := StrSplit(A_LoopReadLine, "`t")
		Evnt.arAutoEvxlinks.Push({"word":ss[1], "link":ss[2]})
	}
	
	; evernote_EvxArrayTruncateBeyondMax()
	; -- Don't truncate the list here, bcz customize.ahk may set(override) a larger value of MAX_AutoEvxlinks.
	; The truncation has been moved to evernote_ConstructAutoPickupMenu().
}

evernote_PickupEvxlink()
{
	; This acts as a Clipmon callback.
	; It checks if [Clipboard has CF_HTML content and has a piece of short text with 
	; Evernote internal-cross-link(call it evxlink) in it. If it has, then pick up
	; the evxlink and add it to Evnt.arAutoEvxlinks{} .

	; [2023-01-22] If no Sleep, following WinClip.GetHtml() may probably returns empty.
	; Just don't know why.
;	Sleep, 100 ; [2023-04-28] Removed this, seems no problem.
	
	cfhtml := WinClip.GetHtml("UTF-8")
	if(not cfhtml)
	{
		AmDbg_Lv2(A_ThisFunc, A_ThisFunc "(), WinClip.GetHtml() returns empty.")
		return
	}

	AmDbg_Lv2(A_ThisFunc, A_ThisFunc "() got: " cfhtml)

	ptn := "<!--StartFragment-->`r`n<span><span>.{0,5}<a href=""(https://www.evernote.com/shard/s21/nl/[0-9a-z-/]+)""[^>]*>([^<]+?)</a>"
	; -- allow only 5 (as in .{0,5}) chars before the link-text.
	foundpos := RegExMatch(cfhtml, ptn, outfound)
	if( foundpos==0 )
	{
		AmDbg_Lv2(A_ThisFunc, "RegEx not match")
		return
	}
	
	newlink := outfound1 ; https://www.evernote.com/shard/s21/nl/2425275/...
	newword := outfound2 ; AmHotkey 
	
	newword := Trim(newword, "[()]")
	
	AmDbg_Lv1(A_ThisFunc, Format("RegEx match: [{}] {}", newword, newlink))
	
	if(strlen(newword)>20)
		return ; ignore it

	evernote_InsertEvxAtHead(newword, newlink)

	dev_TooltipAutoClear(Format("Auto pickup evxlink: [{}]", newword))
}

evernote_InsertEvxAtHead(newword, newlink, delete_index:=-1)
{
	newevx := {"word":newword , "link":newlink }

	if(delete_index==-1)
	{
		; Remove old dup entry.
	  	for index,evx in Evnt.arAutoEvxlinks
	    {
	        if(newword==evx.word)
	        {
	        	Evnt.arAutoEvxlinks.RemoveAt(index)
	        	break
	        }
	    }
    }
    else if(delete_index>0)
    {
       	Evnt.arAutoEvxlinks.RemoveAt(delete_index)
    }
    
    ; Insert newlink at HEAD
    Evnt.arAutoEvxlinks.InsertAt(1, newevx)
    
    ; Delete beyond MAX 
    evernote_EvxArrayTruncateBeyondMax()

    ; Save the list to file.
    filecontent := ""
  	for index,evx in Evnt.arAutoEvxlinks
    {
;    	Dbgwin_Output(evx.word) ; debug
		filecontent .= Format("{}`t{}`r`n", evx.word, evx.link)
    }
    dev_WriteWholeFile(Evnt.filenamEvxlinks, filecontent)
}

evernote_EvxArrayTruncateBeyondMax()
{
	dev_ArrayTruncateAt_(Evnt.arAutoEvxlinks, Evnt.MAX_AutoEvxlinks)
}


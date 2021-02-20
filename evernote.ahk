
AUTOEXEC_Evernote: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

/* APIs:
Evp_ImagePreviewCreateGui()
;
EverTable_Start()
PreviewHtml_ShowGui(html)
ColorMatrix_ShowGui()
*/

; User can define g_evtblColorCustoms[] to append custom colors to g_evtblColorPresets
global g_evtblColorPresets := [ "#f0f0f0,灰白" 
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
	, "#FEFE8C,明亮黄"
	, "#FFE266,日落黄"
	, "#F2F8b4,枯叶黄"
	, "#B0E0B0,青瓷绿(celadon)"
	, "#74C4C4,深海绿"
	, "#C0FF00,荧光绿"
	, "#40A0FF,水手蓝"
	, "#AAE8FF"
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


global g_dirEverpic := A_ScriptDir . "\Everpic" ; chj's default
global g_pyEverpicBatch := "everpic_batch.pyw"
global g_pyEverpic_w := "everpic_w.pyw"
; global g_isEverpicCwdWarn := true ; Retired since Evernote 6.13, and we need a real http server since 6.13

; Q: How to debug everpic.py program?
; A: Step 1
; Run the Python scripts from command line and see the error message.
;
;	everpic_w.pyw --input=c:\users\chj\appdata\local\temp\Everpic\mytest.png
;
; or, when you have a image/image-filepath in clipboard, just run
;
;   everpic_w.pyw
;
; -- CF_HTML content should be generated in clipboard, and Ctrl+V should paste 
;    that CF_HTML content into Evernote clip.
;    Note: If input png is not in dir %LocalAppData%\temp\Everpic , the pasted
;    content may probably contains broken image.
;
; In case it failed, you can see error information by calling text-mode py-script:
;
;   everpic.py
;
;
; Step 2, run everpic_batch.pyw when you have a image/image-filepath in clipboard:
;
;	python everpic_batch.pyw 
;
; -- you should see some text printed on CMD window like this:
;	txtpath= c:\users\chj\appdata\local\temp\Everpic\imagelist-20150319_212257.467.(455x245).txt
; and check that .txt(containing imgspec list) to diagnose.

;;;;;;;; Everpic global vars ;;;;;;;;;;

global g_evpGuiDefaultWidth := 600 ; const
global g_evpMarginX := 10 ; const
global g_evpMarginY := 10 ; const
global g_evpListboxWidth := 140 ; const
global g_evpGapX := 10 ; const, gap between listbox and pic-control
global g_evpWindowBorder := 14
global g_evpBottomLineHeight := 16 ; for Button OK/Dismiss/Use_This

global g_evpRandomId ; not used yet

global g_HwndEVPGui

global g_evpTitleLine ; gui-assoc
;global g_evpTitleStatus ; gui-assoc
global g_evpSecondLine ; gui-assoc
global g_evpBtnDismiss ; gui-assoc
global g_evpBtnOK ; gui-assoc

;global g_evpc_NotUsedYet = "not-used-yet"
global g_evpImageList
global g_evpPic ; gui-assoc, Picture control
global g_evp_isPicControlCreated := false

global g_evpLaunchTimeoutSec := 3
global g_evpIsPyLaunched := false
global g_evpTotalWaitedSec := 0.0 ; seconds
global g_evpClipboardLastOKSec ; todo: later (workaround for clipboard robbing by other program)

global g_evpImglistTxtPath
global g_evp_arImageStore := [] ; g_evp_arImageStore[1] refers to the first previewed image.
	; members: .hint .path
global g_evpCurImageFile ; current select image filepath
global g_evpImageZoom := 1

global g_evpDetailMsg

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

global g_evtblIsDiv
global g_evtblIsTable
global Evtbl_OnTableDivSwitch

global lbl_TableColumnSpec, lbl_TableCellPadding, lbl_TableBorderPx
global g_evtblTableColumnSpec
global g_evtblIsFirstColumnColor
global g_evtblBorder1px
global g_evtblBorder2px
global g_evtblIsPaddingSparse
global g_evtblIsPaddingDense

global g_evtblBtnOK

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

; ======

global g_HwndSupsub
global g_SupsubBaseText
global g_SupsubSupText
global g_SupsubSubText


QSA_DefineActivateSingle_Caps("m", "ENMainFrame", "Evernote")
QSA_DefineActivateGroupFlex_Caps("n", "ENSingleNoteView", QSA_NO_WNDCLS_REGEX, "^(?!#ENS).+", "Evernote Single-note")
	; Match any single note whose title does NOT starts with #ENS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; App+C to convert in-clipboard image to your preferred format(png/jpg) and put CF_HTML content into clipboard,
; so Ctrl+V pasting it into Evernote saves quite much space (Evernote defaultly gives you very big PNG-32).
AppsKey & c:: Evp_ImagePreviewCreateGui()


Evp_ImagePreviewCreateGui()
{
	; Evp: short for "Everpic"
	; This will generate a series of image previews with different quality, with Gui,
	; then user can pick the "best" one to use(to paste into Evernote).

	g_evpTotalWaitedSec := 0
	g_evp_isPicControlCreated := false
	g_evpImglistTxtPath := ""
	Random, g_evpRandomId

	Gui, EVP:Destroy ; destroy old
	Gui, EVP:+Hwndg_HwndEVPGui ; Gui hwnd generated in g_HwndEVPGui
	Gui, EVP:Margin, %g_evpMarginX%, %g_evpMarginY%
	Gui, EVP:Font, s9 cBlack, Tahoma
	fullwidth := g_evpGuiDefaultWidth - 2*g_evpMarginX
	Gui, EVP:Add, Text, % "xm vg_evpTitleLine w" . fullwidth, % "Generating image previews from clipboard... "
	Gui, EVP:Add, Text, % "xm vg_evpSecondLine w" . fullwidth ; text later
	
	Gui, EVP:Add, Button, Section vg_evpBtnDismiss gEVPGuiEscape, % "Dismiss"
	
	Gui, EVP:Show, % " xCenter w" . g_evpGuiDefaultWidth, % Evp_WinTitle()
	
	everpy_path := g_dirEverpic . "\" . g_pyEverpicBatch
	dev_TooltipAutoClear(everpy_path, 5000)
	Run, % everpy_path . " --id=" . g_evpRandomId, , UseErrorLevel
	if(ErrorLevel) {
		MsgBox, "%everpy_path%" launch failed! You have to install Python and PIL library.
		return
		; todo: distinguish python not installed OR py exec fail
	}

	SetTimer, timer_EvpCheckProgress, 500
}

Evp_TimerOff()
{
	SetTimer, timer_EvpCheckProgress, Off
}

Evp_Cleanup()
{
	Evp_TimerOff()
	Gui, EVP:Destroy
}

EVPGuiEscape:
	Evp_Cleanup()
	return

Evp_WinTitle()
{
	return "Everpic"
}

Evp_WaitingPreviewShowErrMsg(msg, detail:="")
{
	GuiControl, EVP:, g_evpTitleLine, % msg
	
	if(not detail)
		return

	; Create detail error-info box.
	GuiControl, EVP:Hide, g_evpBtnDismiss
	Gui, EVP:Font, s9 cBlack, % "Consolas"
	Gui, EVP:Add, Edit, % "xm ys Section vg_evpDetailMsg HScroll r12 Readonly -Wrap w" . g_evpGuiDefaultWidth-2*g_evpMarginX
		; ys: Let it place where the Dismiss button was.
	Gui, EVP:Show, % "xCenter yCenter Autosize" 
	GuiControl, EVP:, g_evpDetailMsg, % detail
}

Evp_SecondLineShowMsg(msg)
{
	GuiControl, EVP:, g_evpSecondLine, % msg
}

timer_EvpCheckProgress:
	Evp_CheckProgress()
	return

Evp_GetClipboardSafe()
{
	count := 0
	while true
	{
		try {
			data := Clipboard
				; May get temporary error of "Can't open clipboard for reading", so catch it and retry
		} catch e {
			count += 1
			tooltip, % "evernote.ahk: Retrying(" . count . ") fetching clipboard content..."
			Sleep, 500
			continue
		}
		break
	}
	tooltip
	return data
}

Evp_CheckProgress()
{
	; Check clipboard text for progress.
	; Clipboard should have content like
	;
	;	[EverpicDone:1/8]PNG,32-bit,88KB|c:\users\...\everpic-20150318_111149.509.png
	;
	; When it reaches
	;
	;	[EverpicDone:8/8]....
	;
	; I'll consider it done.
	
	g_evpTotalWaitedSec += 0.5
	
	proghint := Evp_GetClipboardSafe() ; proghint := Clipboard

	foundpos := RegExMatch(proghint, "^\[EverpicDone:([0-9#]+)/([0-9#]+)\]", subpat)
	if(foundpos>0)
	{
		if(subpat1=="0" and subpat2=="0")
		{
			Evp_WaitingPreviewShowErrMsg("Nothing to convert. No image or image-filename in clipboard.")
			Evp_TimerOff()
			return ; User should dismiss the preview dialog manually
		}
	}
	else
	{
		if((not g_evpIsPyLaunched) and g_evpTotalWaitedSec>=g_evpLaunchTimeoutSec)
		{
			Evp_WaitingPreviewShowErrMsg("Python script '" . g_pyEverpicBatch . "' possibly fails to launch. Continue waiting or dismiss.")
		}
		return
	}

	g_evpIsPyLaunched := true
	
	foundpos := RegExMatch(proghint, "^\[EverpicDone:([0-9#]+)/([0-9#]+)\]\(([0-9]+)x([0-9]+)\)(.+)\|(.+)", subpat)
		; Sample:
		;	[EverpicDone:1/8](640x480)PNG,32-bit,88KB|c:\users\....png
	if(foundpos==0)
	{
		; Perphaps other program rob the clipboard(not fatal)
		; todo: check success by .txt file existence(in case clipboard robbed by other program).
		return
	}

	g_evpClipboardLastOKSec := g_evpTotalWaitedSec
	
	done := subpat1
	total := subpat2
	imgw := subpat3
	imgh := subpat4
	desc := subpat5
	imgfile := subpat6
	; FileDelete, check.txt ;debug
	; FileAppend, %subpat1%;%subpat2%;%subpat3%;%subpat4%;`n, check.txt ;debug
;tooltip, EVPGOT: %done% / %total% // %imgw% / %imgh% @ %imgfile% ; debugging

	if(done=="#" and total=="#")
	{
		; All previews generated successfully.
		Evp_DisplayInitPreview(imgw, imgh, None)
		g_evpImglistTxtPath := imgfile

		Evp_WaitingPreviewShowErrMsg("")
		tailtext := "All previews generated. Pick one to use. (paste into Evernote etc)"
		
		if(g_evpImageZoom!=1)
			zoomhint := "(Zoom " . floor(g_evpImageZoom*100) . "%) "
		Evp_SecondLineShowMsg("[" . imgw . "x" . imgh . "] " . zoomhint . tailtext )
		
		Evp_RefreshPreviewAllGui()
		
		Evp_TimerOff()
		return
	}
	else if(done<=total)
	{
		Evp_SecondLineShowMsg("Loading " . done . "/" . total . " ...")
		Evp_DisplayInitPreview(imgw, imgh, imgfile)
			; just to let the user know the image dimension with an arbitrary preview
	}
	else ; done>total (error occurred)
	{
		; The second line from clipboard(proghint) starts detail error info.
		detail := RegExReplace(proghint, "^[^\n]+\n") ; remove first line
		Evp_WaitingPreviewShowErrMsg("Error occurred executing '" . g_pyEverpicBatch . "'. Error detail below.", detail)
		Evp_TimerOff()
	}
}

Evp_DisplayInitPreview(imgw, imgh, imgfile)
{
	; Do it only when the preview Pic control has not been created.
	if(g_evp_isPicControlCreated )
		return

	g_evp_isPicControlCreated := true

	; Now enlarge the Gui to fit the preview-image but not exceeding the size of main screen.
	
	wa := GetMonitorWorkArea(1)
	
	max_gui_width := wa.width - 2*g_evpWindowBorder
	
	imgw_gui_units := imgw / Get_DPIScale()
	imgh_gui_units := imgh / Get_DPIScale()
		; For example, on an 120-dpi monitor setting Windows(125% scale), for a 125-pixel width image,
		; you need to only pass w100 for the picture control to show it perfectly.
	
	stock_width := 2*g_evpMarginX + g_evpListboxWidth + g_evpGapX
	gui_wreq := stock_width + imgw_gui_units
	if(gui_wreq<=g_evpGuiDefaultWidth)
		gui_wreq := g_evpGuiDefaultWidth
	else if(gui_wreq > max_gui_width)
		gui_wreq := max_gui_width ; not execeed primary monitor workarea width

	wpreview := imgw_gui_units
	hpreview := imgh_gui_units
	if(wpreview > gui_wreq-stock_width)
	{	; shrink wpreview to fit in monitor
		wpreview := gui_wreq - stock_width ; preview(pic control) width
		hpreview := wpreview * imgh/imgw ; preview height
		
		g_evpImageZoom := wpreview / imgw_gui_units
	}
	else 
	{
		g_evpImageZoom := 1
	}
	
	xpreview := g_evpMarginX + g_evpListboxWidth + g_evpGapX

	; Create left-side listbox and right-side picture-control.
	GuiControl, EVP:Hide, g_evpBtnDismiss
	Gui, EVP:Add, ListBox, % "ys xm Section r9 vg_evpImageList glb_evpListboxSelChange AltSubmit w" . g_evpListboxWidth 
		; ys: Let it place where the Dismiss button was.
	Gui, EVP:Add, Pic, % "ys vg_evpPic w" . wpreview . " h" . hpreview, % imgfile
	;
	Gui, EVP:Add, Edit, xm ReadOnly vg_evpCurImageFile w0
	Gui, EVP:Add, Button, xm vg_evpBtnOK default glb_evpBtnOK, % "Use This (or press Enter)"
	GuiControl, EVP:Disable, g_evpBtnOK ; Not enabled until all previews generated

	; todo: adjust y position ,
	; todo: deal with long portrait image scaling
	Gui, EVP:Show, xCenter yCenter Autosize, % Evp_WinTitle()
	; Some quick tweak: If the window is too tall, we move down the window so that 
	; its title bars can be seen on primary monitor.
	WinGetPos, x,y,w,h, ahk_id %g_HwndEVPGui%
	if(h>wa.height)
		WinMove, ahk_id %g_HwndEVPGui%, , %x%, 0
	
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
		StringSplit, field, A_LoopReadLine, |
		desc := field1
			; Example: "PNG(32-bit), 80KB"
		imgfile := field2
		
		RegExMatch(desc, "^([^,]+)", subpat)
		hint := subpat1
			; Example: "PNG(32-bit)"
		
		; Add desc(image variant description) to listbox
		GuiControl, EVP:, g_evpImageList, % desc
		
		g_evp_arImageStore[A_Index] := {"hint":hint, "path":imgfile}
	}
	
	; Choose and display PNG-32 by default
	GuiControl, EVP:Choose, g_evpImageList, 1
	GuiControl, EVP:, g_evpPic, % g_evp_arImageStore[1].path
	GuiControl, EVP:Focus, g_evpImageList
	
	GuiControl, EVP:Enable, g_evpBtnOK
}

lb_evpListboxSelChange:
	Evp_ListboxSelChange()
	return
	
Evp_ListboxSelChange()
{
	GuiControlGet, g_evpImageList
;	tooltip, imglist=%g_evpImageList%
	cur_imagefile := g_evp_arImageStore[g_evpImageList].path
	
	GuiControl, EVP:, g_evpPic, % cur_imagefile
	
	WinGetPos, x,y,w,h, ahk_id %g_HwndEVPGui%
	GuiControl, EVP:Move, g_evpCurImageFile, % "w" . w-2*(g_evpMarginX*g_evpWindowBorder)
	GuiControl, EVP:, g_evpCurImageFile, % cur_imagefile
}

lb_evpBtnOK:
	Evp_BtnOK()
	return
	
Evp_BtnOK()
{
;	if(!g_isEverpicCwdWarn) 
;		g_isEverpicCwdWarn := true
;		
;	if(not Evp_CheckEvernoteCurrentWorkingDir()) { 
;		return
;	}

	GuiControlGet, g_evpImageList
	cur_imagefile := g_evp_arImageStore[g_evpImageList].path
	hint := g_evp_arImageStore[g_evpImageList].hint

	everpy_path := g_dirEverpic . "\" . g_pyEverpic_w
	cmd := everpy_path . " --input=" . cur_imagefile . " --hint=" . hint
;	msgbox, % ">>> " . cmd ; debug
	Run, %cmd%, , UseErrorLevel
	if(ErrorLevel) {
		MsgBox, "%everpy_path%" launch failed! You have to install Python and PIL library.
		return
		; todo: distinguish python not installed OR py exec fail
	}
	
	; Save the used picture to a permanent directory, so that we can get it back 
	; in case Evernote fail to actually store my picture in the note.
	dir_everpic_save := A_AppData . "\Everpic-save"
	FileCreateDir, %dir_everpic_save%
	FileCopy, %cur_imagefile%, %dir_everpic_save%
	if(ErrorLevel) {
		; Note: We did a non-overwrite copy, if destination file exist, we get ErrorLevel.
		MsgBox, % "Unexpect: Fail to copy(overwrite) your image file to " . dir_everpic_save
	}
	
	Evp_Cleanup()
}


; ========================= EverTable(Evtbl) code starts =========================

EverTable_Start()
{
	Evtbl_FixIE(11) ; gradient background is supported only in IE11.
	
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
	
;	SetTimer, timer_EvtblSyncColor, 200
	
	OnMessage(0x200, Func("Evtbl_WM_MOUSEMOVE")) ; add message hook
	
	OnMessage(0x111, Func("Evtbl_WM_COMMAND")) ; to get WM_COMMAND -> EN_KILLFOCUS notification
}

Evtbl_HideGui(html_clipboard:="")
{
;	SetTimer, timer_EvtblSyncColor, Off
	
	Gui, EVTBL:Hide
	
	OnMessage(0x200, Func("Evtbl_WM_MOUSEMOVE"), 0) ; remove message hook
	OnMessage(0x08, Func("Evtbl_WM_COMMAND"), 0)
	tooltip ; turn off possible dangling tooltip
	
	if(html_clipboard)
	{
		; We should do clipboard paste *after* Evtbl GUI has been hidden,
		; otherwise, the selected-text in Combobox may probably be cleared.
		dev_ClipboardSetHTML(html_clipboard, true)
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
	; HTML content selection: TABLE or DIV
	;
	Gui, EVTBL:Add, Text, xm Y+15 , % "HTML content:"
	Gui, EVTBL:Add, Radio, X+10 Group Checked vg_evtblIsTable gEvtbl_OnTableDivSwitch, % "<&TABLE>"
	Gui, EVTBL:Add, Radio, X+10                 vg_evtblIsDiv gEvtbl_OnTableDivSwitch, % "<&DIV>"

	;
	; Table Columns: ____24,360,540____  [x] First column in color
	;
	Gui, EVTBL:Add, Text, xm y+15 vlbl_TableColumnSpec, % "Table Column&s:"
	Gui, EVTBL:Add, Edit, x+10 yp-2 w240 vg_evtblTableColumnSpec, % "24:#,360:Brief,540:Detail"
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
	Gui, EVTBL:Add, Button, x420 yp gEvtbl_BtnPreviewHtml, % "Preview &HTML"

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
	tablectls := [ "lbl_TableColumnSpec", "g_evtblTableColumnSpec", "g_evtblIsFirstColumnColor",
		, "lbl_TableCellPadding", "g_evtblIsPaddingSparse", "g_evtblIsPaddingDense"
		, "lbl_TableBorderPx", "g_evtblBorder1px", "g_evtblBorder2px" ]

	GuiControlGet, g_evtblIsTable, EVTBL:
	
	hideORshow := g_evtblIsTable ? "Show" : "Hide"

	Loop, % tablectls.Length()
	{
		ctlvar := tablectls[A_Index]
		GuiControl, EVTBL:%hideORshow%, %ctlvar%
	}
}

Evtbl_ParseTableColumnWidth(ColumnSpec)
{
	; ColumnSpec is like: "24,360,540" or "24:#,360:Brief,540:Detail"

	StringSplit, token, ColumnSpec, `,
	
	if (token0 == 0) {
		return
	}
	
	ar_colinfo := []
	Loop, PARSE, ColumnSpec, `,
	{
		; A_LoopField will be "24" or "360:Q" etc
		
		tkn1 := ""
		tkn2 := "#" . A_Index ; set default column header text #1, #2, #3 ...
		StringSplit, tkn, A_LoopField, :
		ar_colinfo.Push({ "width_px" : tkn1, "text" : tkn2 })
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
+<table border="{4}" style="border-collapse:collapse; border-color:{5}; width:100`%;">
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
		, tableborder, bordercolor)

	return html
}

Evtbl_GenHtml_Div(hexcolor1, hexcolor2)
{
	htmlptn = 
(
+<div style="padding: 1em; border: 1px solid rgb(220, 220, 220); {1};"><div><span>DIV</span></div></div><div>-</div>
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
		html := Evtbl_GenHtml_Table(hexcolor1, hexcolor2)
	}
	else if(g_evtblIsDiv)
	{
		html := Evtbl_GenHtml_Div(hexcolor1, hexcolor2)
	}
	
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
		
		token1:= "", token2 := "" ; reset stale value
		StringSplit, token, itemstr , `,
		; -- token1="#f0f0ff" , token2="灰蓝"
		
		ctriple := util_GetRgbTripleFromStr(token1)
		
		if(!StrIsStartsWith(token1, "#") || !ctriple)
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
		dict.desc := token2
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
		
		combostr .= "|" . itemstr
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
	;	dev_TooltipAutoClear("$==" . colortext)
	
	; colortext is sth like: "#f0f0f0, rgb(240,240,240) 灰", and we only 
	; care the "#f0f0f0" part which is enough to represent a color value.
	; Alternatively, colortext=="rgb(nnn,nnn,nnn)" is accepted.

	hexcolor := Evtbl_GetHexcolorFromStr(colortext)
	if(!hexcolor)
	{
		Evtbl_RedrawPreviewBox(varname_bgbox, varname_text, "#000000", false, "Invalid color code")
		return ""
	}
;	dev_TooltipAutoClear(">>>" . hexcolor, 1000) ;// debug, enable this to verify whether the sync-timer has stopped.
	
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
		hexcolor1 := "#" . hexcolor1 ; add leading "#"
	if( SubStr(hexcolor2, 1, 1) != "#" ) 
		hexcolor2 := "#" . hexcolor2 ; add leading "#"

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

	ctriple := util_GetRgbTripleFromStr("#" . hexcolor)

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
	dev_GuiLabelSetText("PvHtml", "g_PvhtmlMsg", "Sent to clipboard done.")

	fn_clearmsg := Func("dev_GuiLabelSetText").Bind("PvHtml", "g_PvhtmlMsg", "")
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
;	GuiControlGet, g_evtblIsWhiteText, EVTBL:
;	MsgBox, % "g_evtblIsWhiteText=" . g_evtblIsWhiteText
	
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
;		MsgBox, % xy0.x . " | " . xy0.y
	
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
		bgcolor0x := "0x" . SubStr(gar_colordict[A_Index].hexcode,2,6) ; bgcolor0x="0xF0F0FF" etc
		
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

			rsdict["g_matrixColor" . A_Index] := Format("{},{},{},{}", x0pct, y0pct, x1pct, y1pct)
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
;		dev_TooltipAutoClear("varname=" . varname)
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

Evernote_PastePlainText() ; not successful
{
	KeyWait, Alt
	KeyWait, Ctrl
	sleep, 500
	ControlSend , , +^v, A 
	; Send +^v ; This triggers global hotkey, calling my Clipcache global Ctrl+Shift+V
}


#IfWinActive ahk_class ENMainFrame

CapsLock & Left:: 
	; ControlClick, ENSnippetListCtrl1, A, , LEFT
		; [2015-01-22] In Evernote 5.8.1, this is danger! Although it seems to work, but sometimes 
		; it moves some clip to a strange location.
		; So use ClickInActiveWindow() instead.
	ClickInActiveWindow(1/5, 1/2, false)
return
CapsLock & Right:: 
	Evernote_ClickEditingArea()
	; Tip: Press Caps+(Right Arrow, 2 or more times) to clearly see where the caret is,
	; because double click select(highlight) a word, triple click select a whole line.
return

^!s:: Send +!n ; Jump to Notebook(dropdown list)

^F6:: 
	ControlFocus, ENAutoCompleteEditCtrl1, A
return

F1:: ClickInActiveControl("EnShortcutsBar1", 54, -8, true) ; Click on "first"(hopefully) shortcut link.
	; -4 is enough for Evernote 6.1.2, but -8 is required for 6.3.3

^F1:: 
	KeyWait, Ctrl ; otherwise, the note will pop-up in a separate window
	ClickInActiveControl("EnShortcutsBar1", 124, -8, true) 
return

#IfWinActive


#IfWinActive ahk_class ENSingleNoteView

CapsLock & Right:: 
	Evernote_ClickEditingArea()
return
ESC:: ; Do not allow ESC to close snippet window
	if(dev_IsWinclassExist("PYJJ_COMPUI_WND") || dev_IsWinclassExist("QQPinyinCompWndTSF"))
	{
		; If doing Pinyin JiaJia or QQ pinyin typing(a floating IME small window on screen), Esc is allowed.
		; The window class name "PYJJ_COMPUI_WND" can be probed by checking the HWND value under mouse cursor.
		; 	MouseGetPos, tmpX, tmpY, hwndUnderMouse
		;	WinGetClass, wndclass, ahk_id %hwndUnderMouse%
		SendInput {ESC}
	}
	; [2019-03-30] If ESC is pressed twice within a short time(e.g. 500ms), one ESC is always sent.
	
;	dev_TooltipAutoClear("PRior hotkey: " . A_PriorHotkey)
	
	if (A_PriorHotkey == "Esc" and A_TimeSincePriorHotkey <= 500) {
	    ; This is a double-press.
		Send {ESC}
	}
return 

^F1:: Send {ESC}

#IfWinActive ; ENSingleNoteView



#If Evernote_IsMainFrameOrSingleActive()

; 2013-09-26 F10, F11, F12 on Evernote(v5) to change font, font-size, font-color, F9 click into note-title
F10:: 
	ControlClick ENHtmlToolbarFontFace1, A, , LEFT, 1, X148 Y18
	ControlSend ENHtmlToolbarFontFace1, Consolas{enter}, A
return 
+F10:: ; Set Tahoma font
	ControlClick ENHtmlToolbarFontFace1, A, , LEFT, 1, X148 Y18
	ControlSend ENHtmlToolbarFontFace1, Tahoma{enter}, A
return 

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

; ^!v:: Evernote_PastePlainText() ; not effective

^!F1:: Everpic_LoadTempDirToClipboard()
Everpic_LoadTempDirToClipboard()
{
	; Call this so that I can quickly change evernote.exe's working dir to Everpic'tempdir
	; -- by manually export some .enex there.
	
	EnvGet, dir_localapp, LOCALAPPDATA
	Clipboard := dir_localapp . "\temp\Everpic"
	MsgBox, % "Copied to clipboard: " . Clipboard
}

^!F3:: ClickInActiveControl("ENFindInNoteCtrl1", 7,7, false, false)

^!c:: Send ^+l ; Evernote 6: Apply code block to selected text.

Ins:: Send !em ; Evernote 5.9+ Paste plain text

; ^!p:: dev_ClipboardSetHTML("__<sup>^^</sup> =", true)
; ^!b:: dev_ClipboardSetHTML("^^<sub>__</sub> =", true)
^!':: Evernote_InsertSupSub()
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


^!\:: Evernote_InsertSideBySideDivs()
Evernote_InsertSideBySideDivs()
{
	; Evernote 6.5 does not allow table inside table. In case you want to have a simple 
	; one-row table inside a table, you can create a one-row table using this function.
	InputBox, cellwidths, % "Insert a side-by-side DIVs row", % "Input widths of your DIV cells, separated by commas.",, 384, 144, , , , , 100`,200
	
	if ErrorLevel {
		return
	}
	
	StringSplit, w, cellwidths , `,

	if (w0 == 0) {
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

; App+T to bring up DIV/TABLE html generating dialog.
AppsKey & t:: EverTable_Start()

#If ; Evernote_IsMainFrameOrSingleActive()



#If Evernote_IsSingleNoteActive()
F3::        MPC_Bg_PausePlay(true)
F1::        MPC_Bg_PausePlay_front(true)
; NumpadSub:: MPC_Bg_PausePlay_front(true)
F2::         Evernote_MPC_PasteCurrentPlaytime("{F2}") ; F2 defaults to Evernote clip rename
; NumpadAdd::  Evernote_MPC_PasteCurrentPlaytime()
F4::        MPC_Bg_Back5sec(true)
NumpadDiv:: MPC_Bg_Back5sec(true)
F5::         MPC_Bg_Forward5sec(true)
NumpadMult:: MPC_Bg_Forward5sec(true)

Evernote_MPC_PasteCurrentPlaytime(bypass_hotkey="")
{
	if(MPC_IsRunning()) 
		MPC_PasteCurrentPlaytime()
	else if(bypass_hotkey) {
;		dev_TooltipAutoClear("bypass_hotkey=" . bypass_hotkey) ; debug
		Send % bypass_hotkey
	}
}


NumpadSub:: Evernote_MoveYClick(-24) ; in hope to click onto prev table Row
NumpadAdd:: Evernote_MoveYClick(24)  ; in hope to click onto next table Row
Evernote_MoveYClick(movey)
{
	WinGet, Awinid, ID, A ; cache active window unique id
	MouseGetPos, mx, my, mwin

	if (Awinid != mwin)
	{	; move the mouse into Evernote window, so that we won't `Click` to activate other window
		MouseMoveInActiveWindow(A_CaretX, A_CaretY)
	}
	
	MouseMove, 0, %movey%, , R
	Click
}

^\:: 
	; close the "Find Text" bottom bar.
	; I have to use this bcz ESC has been disabled by me for ENSingleNoteView.
	ClickInActiveWindow(18, -48, false) 
return

#If



; CapsLock & ,:: Evernote_BringupMyShortcut()
Evernote_BringupMyShortcut()
{
	; [2017-11-18] Evernote 6.5.4:
	; I name my frequently-using clips "#ENS Color Divs", "#ENS Tables" etc.
	; Poping these notes in their standlone windows; 
	; then, I can use ``CapsLock & ,`` to quickly access them.
	
;	DetectHiddenWindows, On
	MyActivateWindowGroupFlex("ENSingleNoteView", QSA_NO_WNDCLS_REGEX, "^#ENS", "Evernote ENS# quick note")
;	DetectHiddenWindows, Off
}


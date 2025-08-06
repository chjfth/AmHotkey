
AUTOEXEC_Evernote: ; Workaround for Autohotkey's ugly auto-exec feature. Must be first line.

/* APIs:

EverTable_LaunchUI()
PreviewHtml_ShowGui(html)
ColorMatrix_ShowGui()
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

global g_evtblDivFullWidth
global g_evtblDivLeftSide
global g_evtblDivRightSide
global g_evtblDivQAstyle

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
global gu_PvhtmlMsg

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

Evernote_InitThisModule()


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


#Include %A_LineFile%\..\libs\CtlColorStatic.ahk
#Include %A_LineFile%\..\libs\Gdip_All.ahk
#Include %A_LineFile%\..\libs\GenHtmlSnippet.ahk
#Include %A_LineFile%\..\libs\ClipboardMonitor.ahk
#Include %A_LineFile%\..\libs\AHKhttp.ahk
#Include %A_LineFile%\..\libs\chjfuncs.ahk

class Evnt
{
	static Id := "Evernote"

	static pastecode_start_numline := 1
	
	static pastecode_retry_delaymsec := 200
	static pastecode_restore_plaintext_delaymsec := 500

	dbg(msg, lv) {
		AmDbg_output(Evnt.Id, msg, lv)
	}
	dbg0(msg) {
		Evnt.dbg(msg, 0)
	}
	dbg1(msg) {
		Evnt.dbg(msg, 1)
	}
	dbg2(msg) {
		Evnt.dbg(msg, 2)
	}
	ethrow(msg) {
		Evnt.dbg1(msg)
		throw Exception(msg, -1)
	}
}


Evernote_InitThisModule()
{
	evernote_InlinePaste_InitMenu()

	evernote_InitHotkeys()
}


evernote_InitHotkeys()
{
	QSA_DefineActivateSingle_Caps("m", "ENMainFrame", "Evernote")
	QSA_DefineActivateGroupFlex_Caps("n", "ENSingleNoteView", QSA_NO_WNDCLS_REGEX, "^(?!#ENS).+", "Evernote Single-note")
		; Match any single note whose title does NOT starts with #ENS


	; App+t to callup EverTable UI
	fxhk_DefineComboHotkeyCond("AppsKey", "t", "Evernote_IsMainFrameOrSingleActive", "EverTable_LaunchUI")
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
	; 2024.07 DIV talk-leftside/talk-rightside
	Gui, EVTBL:Add, Radio, xm+179 yp Group Checked Hidden vg_evtblDivFullWidth, % "&Full width"
	Gui, EVTBL:Add, Radio, x+10                    Hidden vg_evtblDivLeftSide, % "&Left side"
	Gui, EVTBL:Add, Radio, x+10                    Hidden vg_evtblDivRightSide, % "&Right side"
	Gui, EVTBL:Add, Radio, x+10                    Hidden vg_evtblDivQAstyle, % "&Q&&A Style"
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
	; Memo: Initial hidden ctrls is controlled in Evtbl_CreateGui() ;
	
	all_ctls := [ "g_evtblEdtCsstableRows", "g_evtblLblCsstableRows", "g_evtblChkboxCsstableHead"
		,			"g_evtblIsSpan"
		, "lbl_TableColumnSpec", "g_evtblTableColumnSpec", "g_evtblCssTableColumnSpec", "g_evtblIsFirstColumnColor"
		,		"g_evtblSpanText", "g_evtblIsSpanMono",  "g_evtblDivFullWidth", "g_evtblDivLeftSide", "g_evtblDivRightSide", "g_evtblDivQAstyle"
		, "lbl_TableCellPadding", "g_evtblIsPaddingSparse", "g_evtblIsPaddingDense"
		, 		"lbl_TableBorderPx", "g_evtblBorder1px", "g_evtblBorder2px" ]
	; ------------------------------------------------------------------------------------------
	table_ctls := [ "_", "_", "_"
		,			"g_evtblIsSpan"
		, "lbl_TableColumnSpec", "g_evtblTableColumnSpec", "_", "g_evtblIsFirstColumnColor"
		,		"_", "_" , "_", "_", "_"
		, "lbl_TableCellPadding", "g_evtblIsPaddingSparse", "g_evtblIsPaddingDense"
		, 		"lbl_TableBorderPx", "g_evtblBorder1px", "g_evtblBorder2px" ]
	; ------------------------------------------------------------------------------------------
	csstbl_ctls := [ "g_evtblEdtCsstableRows", "g_evtblLblCsstableRows", "g_evtblChkboxCsstableHead"
		,			"_"
		, "lbl_TableColumnSpec", "", "_", "g_evtblCssTableColumnSpec", "g_evtblIsFirstColumnColor"
		,		"_", "_", "_", "_", "_"
		, "_", "_", "_"
		, 		"_", "_", "_" ]
	; ------------------------------------------------------------------------------------------
	div_ctls := [ "_", "_", "_"
		,			"g_evtblIsSpan"
		, "_", "_", "_", "_"
		,		"_", "_", "g_evtblDivFullWidth", "g_evtblDivLeftSide", "g_evtblDivRightSide", "g_evtblDivQAstyle"
		, "_", "_", "_"
		, 		"_", "_", "_" ]
	; ------------------------------------------------------------------------------------------
	span_ctls := [ "_", "_", "_"
		,			"g_evtblIsSpan"
		, "_", "_", "_", "_"
		,		"g_evtblSpanText", "g_evtblIsSpanMono", "_", "_", "_"
		, "_", "_", "_"
		, 		"_", "_", "_" ]

	Gui, EVTBL:Submit, NoHide
	
	if(g_evtblIsTable)
		need_ctls := table_ctls
	else if(g_evtblIsDiv)
		need_ctls := div_ctls
	else if(g_evtblIsCssTable)
		need_ctls := csstbl_ctls
	else if(g_evtblIsSpan)
		need_ctls := span_ctls
	else
		dev_assert(0)
	
	Loop, % all_ctls.Length()
	{
		ctlvar := all_ctls[A_Index]
		isshow := dev_IsEleInArray(ctlvar, need_ctls)

		hideORshow := isshow ? "Show" : "Hide"
		GuiControl, EVTBL:%hideORshow%, %ctlvar%
		
		; Disable a Uic, so to make its Alt-hotchar in-effective.
		; This is beneficial when two Uic-s share a single hotchar. 
		; If one is disabled, the other will get instant response on that hotchar.
		dis_enable := isshow ? "Enable" : "Disable"
		GuiControl, EVTBL:%dis_enable%, %ctlvar%
	}

	GuiControl, % "EVTBL:" (g_evtblIsTable?"Show":"Hide"), g_evtblChkboxTSV
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

Evtbl_GenHtml_Div_once(hexcolor1, hexcolor2, align:="FullWidth", add_tail_dash:=true)
{
	cssmargin := ""
	if(align=="LeftSide")
		cssmargin := "margin-right: 20`%;"
	else if(align=="RightSide")
		cssmargin := "margin-left: 20`%;"

	htmlptn = 
(
-<div style="padding: 0.8em; {1} border: 1px solid rgb(220, 220, 220); {2};"><span>DIV</span></div>
) ; will be feed to Format(), {1} will be replaced
	
	if(add_tail_dash)
		htmlptn .= "<div>-</div>"
	
	css_bg_rule := make_css_bg_rule(hexcolor1, hexcolor2)

	html := Format(htmlptn, cssmargin, css_bg_rule)
	return html
}

Evtbl_GenHtml_Div(hexcolor1, hexcolor2, align:="FullWidth")
{
	is_QAstyle := (align=="QAstyle")
	
	if(not is_QAstyle)
	{
		return Evtbl_GenHtml_Div_once(hexcolor1, hexcolor2, align)
	}
	else
	{
		Qhtml := Evtbl_GenHtml_Div_once(hexcolor1, "", "LeftSide", false)
		
		if(not hexcolor2)
			hexcolor2 := hexcolor1
		
		Ahtml := Evtbl_GenHtml_Div_once(hexcolor2, "", "RightSide")
		
		return Qhtml . Ahtml
	}
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
		align := ""
		if(g_evtblDivLeftSide)
			align := "LeftSide"
		else if(g_evtblDivRightSide)
			align := "RightSide"
		else if(g_evtblDivQAstyle)
			align := "QAstyle"
		
		html := Evtbl_GenHtml_Div(hexcolor1, hexcolor2, align)
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
		tooltip, % "Pick background color visually."
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
		dev_TooltipAutoClear("In case pasted content does not appear, please manually strike Ctrl+V inside your Evernote clip.", 3000)
	}
	else if(A_GuiControl=="g_evtblChkboxTSV")
	{
		dev_TooltipAutoClear("If Clipboard has plain text in TSV or CSV format, this will convert the to HTML table and paste it into Evernote.")
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
	
	GuiName := "PvHtml"
	
	Gui, PvHtml:New
	
	Gui, PvHtml:+Hwndg_HwndPreviewHtml
	
	Gui, PvHtml:Add, Text, , % "CF_HTML raw content:"
	Gui, PvHtml:Add, Edit, xm w760 r10 vg_PvhtmlEdit, % "dyn content"

	Gui, PvHtml:Font, s8 cBlack, Tahoma
	Gui, PvHtml:Add, Button, xm vg_PvhtmlClipboard gPvhtml_SendtoClipboard , % "&Send to Clipboard as CF_HTML"
	Gui_Add_TxtLabel(GuiName, "gu_PvhtmlMsg", 500, "x+10")

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
	GuiControl_SetText("PvHtml", "gu_PvhtmlMsg", "Sent to clipboard done.")

	fn_clearmsg := Func("GuiControl_SetText").Bind("PvHtml", "gu_PvhtmlMsg", "")
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
	rsdict.gu_PvhtmlMsg := "0,100,0,100"
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

; ==================================================================
; Memo: Evernote 6.5.4's default hotkey behavior:
; F5 : Switch MainFrame view style: Snippet View -> Card View -> Top List ...
;	-- This is used pretty rarely, so I override F5 to call Evernote_GotoNoteListFirstItem().
;
; F6 : Goto full-text search box, clearing existing text in search box. 
;	-- This is convenient and I do not override it.
; ==================================================================

#If Evernote_IsMainFrameActive()

CapsLock & Left:: Evernote_ClickNoteListArea()

CapsLock & Right:: 
	Evernote_ClickEditingArea()
	; Tip: Press Caps+(Right Arrow, 2 or more times) to clearly see where the caret is,
	; because double click select(highlight) a word, triple click select a whole line.
return

CapsLock & Up:: Evernote_GotoNoteListFirstItem()

^!s:: Send +!n ; Jump to Notebook(dropdown list)

F5:: Evernote_MainFrameF5()
Evernote_MainFrameF5()
{
	dev_TooltipAutoClear("evernote.ahk: F5 hotkey is overridden to be Evernote_GotoNoteListFirstItem()")
	Evernote_GotoNoteListFirstItem()
}

^F6:: 
	ControlFocus, ENAutoCompleteEditCtrl1, A ; no clearing search-box text content
return

^F1:: 
	dev_WaitKeyRelease("Ctrl") ; otherwise, the note will pop-up in a separate window
	ClickInActiveControl("EnShortcutsBar1", 54, -8, true) ; Click on "first"(hopefully) shortcut link.
return

#If


#If Evernote_IsSingleNoteActive()

CapsLock & Right:: Evernote_ClickEditingArea()

F5:: Evernote_SingleNoteF5()
Evernote_SingleNoteF5()
{
	dev_TooltipAutoClear("evernote.ahk: F5 hotkey goes to MainFrame first-item.")
	Evernote_GotoNoteListFirstItem()
}

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

#If 



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


evernote_GetClipboardSingleLine()
{
	codetext := ""
	if(dev_GrabTextToClipboardIfAny())
		codetext := Trim(Clipboard, "`r`n")
	
	if(StrLen(codetext)==0) {
		dev_MsgBoxInfo("Clipboard is empty, nothing to paste.")
		return ""
	}
	
	if(InStr(codetext, "`n")) {
		dev_MsgBoxWarning("Clipboard text has multiple lines. To avoid pasting large chunks of text, inline code pasting is forbidden.")
		return ""
	}

	return codetext
}

Evernote_PasteHTML(html)
{
	oldpos := win32help_GetCaretPos()

	; First paste try:
	dev_ClipboardSetHTML(html, true)
	
	; Now we check to see whether we need a second paste try.
	
	; [2024-12-27] Strange! The win32help_GetCaretPos() result is unstable when 
	; Evernote is activate. E.g:
	; * sometimes it has value, 
	; * other times results in (0,0) -- even if AttachThreadInput() returns TRUE.
	; * win32help_GetCaretPos Win32API can even fail.
	;
	; If win32help_GetCaretPos fails or reports (0,0), we do not know what 
	; stupid thing has happened, so just give up.
	;
	if(not oldpos)
	{
		Evnt.dbg1("Unexpect! Evernote_PasteHTML() fails on win32help_GetCaretPos(). Ignore it.")
		return
	}
	else if(oldpos.x==0 and oldpos.y==0)
	{
		Evnt.dbg1("Unexpect! Evernote_PasteHTML() sees editing-area caret pos (0,0). Ignore it.")
		return
	}
	
	; OK, go on checking. If the caret-pos did not change after first paste, we retry the paste.
	
	dev_Sleep(Evnt.pastecode_retry_delaymsec)
	
	newpos := win32help_GetCaretPos(fromHwnd, fromTid) ; fromHwnd, fromTid are output vars
	if(not newpos)
	{
		Evnt.dbg1("Shit! Evernote_PasteHTML() fails on Second win32help_GetCaretPos(). Give up retry.")
		return
	}
	else if(newpos.x==0 and newpos.y==0)
	{
		Evnt.dbg1("Shit! Evernote_PasteHTML() sees editing-area caret pos (0,0). Give up retry.")
		return
	}
	
	if(newpos.x==oldpos.x and newpos.y==oldpos.y)
	{
		msg := Format("Evernote_PasteHTML() retry pasting again, bcz Caret position has not changed. ({} , {})", newpos.x, newpos.y)
		dev_TooltipAutoClear(msg)
		Evnt.dbg1(msg)
		WinClip.Paste()
	}
	else
	{
		msg2 := Format("Evernote_PasteHTML() good seeing: caret ({},{}) to ({},{})", oldpos.x, oldpos.y, newpos.x, newpos.y)
		Evnt.dbg2(msg2) ; Level 2 verbose
	}

	Evnt.dbg2(Format("Caret from thread-id={}, Hwnd=0x{:08X} '{}'", fromTid, fromHwnd, dev_GetClassNameFromHwnd(fromHwnd)))
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
	if(StrLen(codetext)==0)
		return
	
	html := Evtbl_GenHtml_Span(bgcolor, "", codetext, is_monofont ? true : false)
	
	Evernote_PasteHTML(html)
	
	if(keep_orig_clipboard) {
		; Restore plain-text to clipboard, bcz dev_ClipboardSetHTML() has ruined.
		; the plain codtext with CF_HTML content.
		
		; [2023-04-28] We need to delay the restore a bit(500ms), bcz, 
		; the target process receiving Ctrl+V needs some time to fetch that
		; HTML content from clipboard.
		fn := Func("evernote_RestoreClipboardText").Bind(codetext)
		dev_StartTimerOnce(fn, Evnt.pastecode_restore_plaintext_delaymsec)
	} 
}

evernote_RestoreClipboardText(text)
{
	Clipboard := text
}

Evernote_PasteSingleLineWithHtmlDeco(str_decofunc)
{
	puretext := evernote_GetClipboardSingleLine()
	if(StrLen(puretext)==0)
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

Htmldeco_Protohex(puretext)
{
	style := Format("border: 1px solid #ccc;"
		. "padding: 0em 0.2em;"
		. "border-radius: 3px;"
		. "box-shadow: 1px 1px 0 rgba(0, 0, 0, 0.4);"
		. "background: linear-gradient(0deg, #fff, #ccddbb);"
		. "")

	html := Format("<span style=""{}"">{}</span>&nbsp;", style, puretext)
	return html
}

Htmldeco_chs_translate(puretext)
{
	style := Format("border: 1px solid #eee;"
		. "padding: 0em 0.2em;"
		. "border-radius: 3px;"
		. "box-shadow: 1px 1px 0 rgba(0, 0, 0, 0.4);"
		. "background: linear-gradient(180deg, #fff, #ccbbee);"
		. "")

	html := Format("<span style=""{}"">({})</span>&nbsp;", style, puretext)
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
	, "#EE99DD,暗洋红"
	, "#F49292,故障红" 
	, "#E0C0F8,修补紫" 
	, "#c0d0c0,实物灰" ]
	
	dev_MenuAddItem("evernote_menuInlinePaste", "Paste as plain text (or F1 outside)", "Evernote_PastePlainText")
	
	dev_MenuAddSepLine("evernote_menuInlinePaste") ; ----
	
	fn := Func("Evernote_PasteSingleLineWithHtmlDeco").Bind("Htmldeco_Kbd")
	dev_MenuAddItem("evernote_menuInlinePaste", "&Kbd style it", fn)
	
	fn := Func("Evernote_PasteSingleLineWithHtmlDeco").Bind("Htmldeco_Protohex")
	dev_MenuAddItem("evernote_menuInlinePaste", "&Protohex it", fn)
	
	fn := Func("Evernote_PasteSingleLineWithHtmlDeco").Bind("Htmldeco_chs_translate")
	dev_MenuAddItem("evernote_menuInlinePaste", "&Chs Translate style", fn)
	
	; Check if user hooking function Evernote_AddExtraInlineStyles exists, if so, call it.
	; User normally define this function in customize.ahk
	if(IsFunc("Evernote_AddExtraInlineStyles"))
	{
		Func("Evernote_AddExtraInlineStyles").()
	}
	
	dev_MenuAddSepLine("evernote_menuInlinePaste") ; ----

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

	isok := dev_InputBox_InitText("", "New paste-code starting line-number:", ln)
	if(isok)
		Evnt.pastecode_start_numline := ln
}


#If Evernote_IsMainFrameOrSingleActive()

F1:: Evernote_PastePlainText()

; +Ins up:: Evernote_PastePlainText_exwait()
Evernote_PastePlainText_exwait()
{
	dev_WaitKeyRelease("Shift", "T1")
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


#If



AUTOEXEC_hypersnap: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

global Hs7_colorcell_width = 18 ; Hypersnap 7, color cell width&height
global Hs7_main_colorpicker_margin_height = 37

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;==============================================================
; 2015-01-05: HyperSnap 7 shortcuts
;==============================================================

#IfWinActive Edit Text ; For the "Edit Text" dialog(when you Draw Text or Draw Callout)

IsHs7FrameTab()
{
	ControlGetText, text, Static1, A
	if (text=="Frame color:")
		return 1 ; Frame Tab
	else
		return 0 ; Text Tab
}

^Enter:: 
	; It's disgusting that the OK button's ButtonNN on "Edit Text" dialog is dynamic, 
	; Button15, Button19, or Button5 etc. So I use a trick: Set focus to a checkbox first,
	; then send an Enter, this always works as sending IDOK current dialog.
	If IsHs7FrameTab()
		ControlFocus, Button4 ; "Resize to contain text"
	else
		ControlFocus, Button14 ; "Update text immediately"
	Send {Enter}
return


Hs7_EditText_DropdownColorPicker()
{
	color_picker_title := "Choose Color"
	classnn_palette := IsHs7FrameTab() ? "Static2" : "Static1"
	ClickInActiveControl(classnn_palette, -3, 3) ; quotes around Static2 is a must
	; Sigh, HS7's palette is NOT keyboard navigable!
	; So, I have to use mouse(driven by my ahk script) for color selection; and not so bad,
	; you can use Numpad keys to navigate cell-by-cell then click to select.
	; (todo) -- g_MouseNudgeUnitAM
	isok := dev_WinWaitActive_with_timeout(color_picker_title)
	If(!isok) {
		MsgBox, Unexpected! Color palette pop-up not detected.
		return false
	}
	else {
		ModifyMouseNudgeUnitAM(Hs7_colorcell_width)
		return true
	}
}

Hs7_EditText_ColorPick(cx, cy) ; cx, cy is color-cell position, 0,1,2,3...
{
	dropdown_ok := Hs7_EditText_DropdownColorPicker()
	if dropdown_ok {
		px :=    (cx+1)*Hs7_colorcell_width-2
		py := 10+(cy+1)*Hs7_colorcell_width-2
		Click %px%, %py% ;MouseMove %px%, %py%
	}
}

Hs7_EditText_ChooseLineWidth(width) ; width in pixel
{
	If IsHs7FrameTab() {
		ControlSetText, Edit1, %width%, A
		Control, Uncheck, , Button1 ; Clear "Make it transparent checkbox"
		Control, Check, , Button4 ; Tick "Resize to contain text"
	}
}

^0:: 
	If IsHs7FrameTab() {
		ControlSetText, Edit1, 0, A ; Set "Width (in pixels)" to 0
		Control, Check, , Button1 ; Tick "Make it transparent checkbox"
		Control, Check, , Button4 ; Tick "Resize to contain text"
	}
return

^1:: Hs7_EditText_ChooseLineWidth(1)
^2::
	If IsHs7FrameTab() {
		ControlSetText, Edit1, 2, A ; Set "Width (in pixels)" to 2
		Control, Uncheck, , Button1 ; UnTick "Make it transparent checkbox"
		Control, Check, , Button4 ; Tick "Resize to contain text"
	} else  {
		Hs7_EditText_ChooseLineWidth(2)
	}
return
^3:: Hs7_EditText_ChooseLineWidth(3)

^t:: ControlFocus, Edit1 ; Move focus to text height editbox
^f:: ControlClick, ComboBox1
^!a:: ; Set Arial font
	ControlClick, ComboBox1
	SendInput Arial{enter} ; Strange: {enter} here does not confirm the dropdown selection.
return

F12:: ; show color-picker popup
	dropdown_ok := Hs7_EditText_DropdownColorPicker()
	if dropdown_ok
		Hs7_colorcell_op(3, 2, 10, false)
return
^r:: Hs7_EditText_ColorPick(0, 2) ; red
^b:: Hs7_EditText_ColorPick(5, 1) ; blue
^g:: Hs7_EditText_ColorPick(2, 2) ; green
^m:: Hs7_EditText_ColorPick(6, 3) ; magenta
^o:: Hs7_EditText_ColorPick(1, 2) ; orange
^h:: Hs7_EditText_ColorPick(2, 3) ; yellow (h=Huang se) Ctrl+Y is for Redo.

#IfWinActive ; Hypersnap 7 "Edit Text"


#IfWinActive ahk_class HyperSnap 7 Window Class

;F8:: Send ^{Tab}  ; previous captured image
;F9:: Send +^{Tab} ; nextab captured image

Hs7_ClickDrawbarCell(cellx, celly, is_click=true)
{	; cellx, celly may be decimal so that we can click onto any area of the toolbar.
	;
	; Prerequisite: The drawbar must be visible and has a vertical visual layout, and docked, not floated.
	;
	; Hint: Bigger Windows font DPI, bigger the drawbar and its cells(buttons)
	WinGet, Awinid, ID, A
	WinGet, ControlList, ControlList, ahk_id %Awinid%
	Loop, Parse, ControlList, `n
	{
		classnn := A_LoopField
		ControlGetPos, left, top, width, height, %classnn%, ahk_id %Awinid%
        If (width*4<height) ; so it must be a visually vertical toolbar
        {
        	; classnn of the draw-bar is like "BCGPToolBar:400000:8:10007:104"
        	foundpos := RegExMatch(classnn, "BCGPToolBar:")
        	If (foundpos==1)
	        {	; Now we consider it the drawbar
	        	cellsize1 := 24 ; single button width&height, when Windows system text scale is 100%
	        	borderx := 6 , bordery := 10
	        	; scale := width / (cellsize1*3 + 2*borderx) ; HS7's drawbar has 3 cells per line // not accurate!
    	        ;RegRead, AppliedDPI, HKEY_CURRENT_USER, Control Panel\Desktop\WindowMetrics, AppliedDPI
				scale := A_ScreenDPI / 96 ; 96dpi corresponds to 100%
	        	
	        	clickx := left + (borderx+cellx*cellsize1) * scale
	        	clicky := top  + (bordery+celly*cellsize1) * scale + (5*scale) ; 5 is the grib size
        		MouseMove %clickx%, %clicky%, 2
	        	if(is_click)
	        		Click
	        	break
	        }
	    }
	}
}

Hs7_Main_DropdownColorPicker(is_foreground)
{
	color_picker_title := is_foreground ? "Foreground Color" : "Background Color"
	if(is_foreground)
		Hs7_ClickDrawbarCell(1.2, 12.6)
	else 
		Hs7_ClickDrawbarCell(2.8, 12.6)
	
	isok := dev_WinWaitActive_with_timeout(color_picker_title)
	if(!isok) {
		MsgBox, Unexpected! Color picker pop-up not detected.
		return false
	}
	else {
		ModifyMouseNudgeUnitAM(Hs7_colorcell_width, color_picker_title)
		return true
	}
}

Hs7_colorcell_op(cx, cy, margin_height, is_click)
{
	px := (cx+1)*Hs7_colorcell_width-2
	py := (cy+1)*Hs7_colorcell_width-2 + margin_height
	if(is_click)
		Click %px%, %py% 
	else
		MouseMove %px%, %py%
}

Hs7_Main_ColorPick(cx, cy, is_foreground) ; cx, cy is color-cell position, 0,1,2,3...
{
	MouseGetPos origx, origy
	dropdown_ok := Hs7_Main_DropdownColorPicker(is_foreground)
	if(dropdown_ok) {
		Hs7_colorcell_op(cx, cy, Hs7_main_colorpicker_margin_height, true)
	}
	MouseMove %origx%, %origy%
}

F12:: ; show foreground color-picker popup
	dropdown_ok := Hs7_Main_DropdownColorPicker(true)
	if(dropdown_ok) {
		Hs7_colorcell_op(3, 2, Hs7_main_colorpicker_margin_height, false)
	}
return

^F12:: ; show background color-picker popup
	dropdown_ok := Hs7_Main_DropdownColorPicker(false)
	if(dropdown_ok) {
		Hs7_colorcell_op(3, 2, Hs7_main_colorpicker_margin_height, false)
	}
return

^r:: Hs7_Main_ColorPick(0, 2, true) ; red foreground
^b:: Hs7_Main_ColorPick(5, 1, true) ; blue
^g:: Hs7_Main_ColorPick(2, 2, true) ; green
^m:: Hs7_Main_ColorPick(6, 3, true) ; magenta
^o:: Hs7_Main_ColorPick(1, 2, true) ; orange
^h:: Hs7_Main_ColorPick(2, 3, true) ; yellow (y=Huang se)

Hs7_PickCustomHighlight(cx, cy)
{
	MouseGetPos origx, origy
	Hs7_Main_ColorPick(cx, cy, false)
	; Hs7_ClickDrawbarCell(1.2, 11.6) ; strange, a single call usually fails, so use move+click instead
	Hs7_ClickDrawbarCell(1.2, 11.6, false) 
	Click
	Send {up}{enter}
	MouseMove origx, origy
}

!^r:: Hs7_PickCustomHighlight(0, 2) ; red highlight
!^o:: Hs7_PickCustomHighlight(1, 2) ; orange
!^b:: Hs7_PickCustomHighlight(4, 2) ; blue
!^g:: Hs7_PickCustomHighlight(3, 3) ; green
!^m:: Hs7_PickCustomHighlight(0, 3) ; ~ magenta
!^h:: Hs7_PickCustomHighlight(2, 3) ; yellow
!^w:: Hs7_PickCustomHighlight(7, 4) ; white background



; Set focus to Thumbnail pane:
CapsLock & Left:: Hs7_FocusThumbnailPane()
Hs7_FocusThumbnailPane()
{
	ControlFocus, SysListView321, A
	ControlGetPos, x,y,w,h, SysListView321, A
	
	MouseGetPos, mousex, mousey
	if(not Is_XY_in_Rect(mousex,mousey, x,y,w,h))
		MouseMoveInActiveWindow(x+w/2, y+h/2)
}

#IfWinActive ; HyperSnap 7


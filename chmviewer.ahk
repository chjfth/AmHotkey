
AUTOEXEC_chmviewer: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

global chmedt_ToolbarX0 := 300 ; change this to the same width of UI's left pane
global chmedt_ToolbarY := 104
global chmedt_Xcolor := chmedt_ToolbarX0 + 268

Init_ChmEditor()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;==============================================================
; CHM Viewer (hh.exe)
;==============================================================
; For CHM viewer: F9 - Content Tab, F10 - Index Tab, F11 - Search Tab,
; so that you can use keyboard to scroll the webpage. 

#IfWinActive ahk_class HH Parent
F9:: Send !c
F10:: 
	Send !c!n ; This will move focus to the search box
	Send {Home}{Shift down}{End}{Shift up} ; Make all text in box selected, so easyily to type new
return
F11:: Send !c!s
; For F12, we toggle HH's Tab display, which can be accomplish in two ways:
; (1) Alt+o then T . This is effective if toolbar button [Option] exist.
; (2) Alt+V then N . This is effective only if MSDN menu is display(the case for MSDN Oct 2001).
; So we try (1) first. In case no effect(windows size not changed) then try (2).
; But if neither [Option] button or MSDN menu exist, F12 will not take any effect.
F12:: Send !c!i ; Favorites tab

^F12:: ; Hide/Show navigation pane
  WinGetPos, x, y, old_width, height, A
  Send !ot
  Sleep 100 ; Wait for the window move, otherwise, an HH window supports both hotkeys will have double effect.
  WinGetPos, x, y, new_width, height, A
  If (old_width==new_width) {
    Send ^z ; revert the effect of the verbose 'n' character(best bet)
    Send !vn
  }
return

chm_IsTriggerDoubleLR(prev_hotkey)
{
	WinGet, Awinid, ID, A ; cache active window unique id
	ControlGetFocus, focusNN, ahk_id %Awinid%
	if(focusNN ~= "Edit")
	{
		; trigger ON only if the carret is at end of text 
		ControlGetText, edittext, %focusNN%, ahk_id %Awinid%
		ControlGet, carretpos, CurrentCol, , %focusNN%, ahk_id %Awinid%
			;tooltip, carretpos %carretpos%
		if(strlen(edittext)+1 != carretpos) ; carret not at end of text
			return false
	}

	if(A_PriorHotkey == prev_hotkey and A_TimeSincePriorHotkey < 500) 
		return true
	else
		return false

}

Chm_SetFocusToRightPane()
{
	;[2015-02-06] This supercedes "pressing ^F12 twice"
	ClickInActiveControl("Internet Explorer_Server1", 2, 2, true)
}
CapsLock & Right UP:: Chm_SetFocusToRightPane() 

~Right UP::
	if(chm_IsTriggerDoubleLR("~Right UP"))
		Chm_SetFocusToRightPane()
return

Chm_SetFocusToLeftPane()
{
	chm_leftpane_ctls = SysTreeView321,hh_kwd_vlist1,SysListView321,SysListView322
	Loop, parse, chm_leftpane_ctls, `,
	{
		;classnn = %A_LoopField% ; Q: Any way to avoid an extra assignment? 
		if (CheckControlBool(A_LoopField, "Visible")) {
			ControlFocus, %A_LoopField%
			
			; Some CHMs need a "click" on the left pane so to really get focus(respond to Up/Down).
			; Cases: httpd-docs-2.2.29.en.chm , MSDN Oct 2001
			ClickInActiveControl(A_LoopField, -2, 2, true)
		}
	}
	
}
CapsLock & Left UP:: Chm_SetFocusToLeftPane() 

~Left UP::  
	if(chm_IsTriggerDoubleLR("~Left UP"))
		Chm_SetFocusToLeftPane()
return

#IfWinActive


;==============================================================
; CHMEditor v3
; Hardcoded mouse clicking coord, only suitable on my chja20 Win10.
;==============================================================

#If dev_IsExePathMatchRegex("chmeditor.*\.exe")

Init_ChmEditor()
{

;	fn := Func("ChmEditor_SetTextColor").Bind(228, 160, 50)
;	Menu, ChmedtMenu_SelectColor, Add, % "Brown", %fn%

	; Add a bunch of text-color menu items (call out by F12)

	arItems := [ ["Grey",  128, 128, 128]
		, ["Dim Purple",   180, 100, 255]
		, ["Blue",           0, 128, 255] 
		, ["Dark Blue",      0,  60, 160]
		, ["Magenta",      255,   0, 255]
		, ["Dark Purple",  128,  40, 128]
		, ["Brown",        228, 160,  50]
		, ["Dark Green",     0, 128, 128]
		, ["Orange",       255, 128, 64] ]

	nItems := arItems.Length()
	
	Loop, %nItems%
	{
		item := arItems[A_Index]
		menutext := Format("&{1}. {2}", A_Index, item[1])
		ChmEditor_ColorMenuAddItem(menutext, item[2], item[3], item[4])
	}
}

ChmEditor_ColorMenuAddItem(colorname, red, green, blue)
{
	fn := Func("ChmEditor_SetTextColor").Bind(red, green, blue)
	Menu, ChmedtMenu_SelectColor, Add, %colorname%, %fn%
}

ChmEditor_PopupColorCombo()
{
	ClickInActiveWindow(chmedt_Xcolor, chmedt_ToolbarY, true) ; Popup the color selection combobox
}

^F12:: ChmEditor_SetTextColor(128, 128, 128) ;grey
^p::   ChmEditor_SetTextColor(180, 100, 255) ;purple

F10:: ChmEditor_ApplyCodeFont()
ChmEditor_ApplyCodeFont()
{
	ClickInActiveWindow(433, chmedt_ToolbarY, true)
	Send c
}

^F10:: ClickInActiveWindow(chmedt_ToolbarX0+660, chmedt_ToolbarY, false) ; Unordered list
^F11:: ClickInActiveWindow(chmedt_ToolbarX0+630, chmedt_ToolbarY, false) ; Ordered list

^]:: ClickInActiveWindow(chmedt_ToolbarX0+588, chmedt_ToolbarY, false) ; Indent (blockquote)

NumpadSub:: Send ^u
NumpadMult:: Send ^b


F12:: ChmEditor_PopupTextColorMenu()
ChmEditor_PopupTextColorMenu()
{
	Menu, ChmedtMenu_SelectColor, Show
}


ChmEditor_SetTextColor(red, green, blue)
{

	dev_SaveMouseScreenPos()

	ChmEditor_PopupColorCombo()

	; Hint: First move mouse pointer to dropdown listbox area,
	; Then issue WheelUp command, and (most of the time) we DON'T have to Sleep 
	; before we can click on its first item(named "Custom...").
	;
	MouseMove, 0, 12, , R

	Loop, 5
		Send {WheelUp}
	
	Sleep, 100 ; just play it safe

	Send {Click}
	
	; Wait for system's ChooseColor dialogbox to popup.
	if(! dev_WinWaitActive_with_timeout("Color") )
	{
		Msgbox, % "AHK miss! Not seeing ChooseColor dialogbox."
		return
	}
	
;	dev_TooltipAutoClear("OooK")

	Send !d ; [button] Define Custom Colors

	ControlSetText, Edit4, %red%, A ; [edit] Red
	ControlSetText, Edit5, %green%, A ; [edit] Green
	ControlSetText, Edit6, %blue%, A ; [edit] Blue
	
	Send {enter} ; [button] OK
	
	dev_RestoreMouseScreenPos()
}



#If ; ChmEditor END

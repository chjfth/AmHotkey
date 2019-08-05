
AUTOEXEC_chmviewer: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

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



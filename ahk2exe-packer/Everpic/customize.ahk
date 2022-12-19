; Note: If this file contains non-ASCII characters, you must saved it in UTF8 with BOM,
; in order for the Unicode characters to be recognized by Autohotkey engine.

AUTOEXEC_customize: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.
	; When duplicating this file, you MUST: Change the above ahk label to a unique one, 
	; such as AUTOEXEC_foobar_ahk.

; Something to place here:
; * Customize these global vars according to your running machine:
; * Call the run-once functions.

; Something NOT to place here:
; * Hotkey definition, like 
;		#!t:: DoSomething()
; * Function definition.
;
; If you violate this "NOT" rule, .e.g, you define foo(){...} , then all `global`s 
; after this foo will be ignored.

global g_myglobal1 := 123

Init_ExeEverpicEnv()
; -- This function's body is defined after the first "return",
;    but we have to call it *before* the first "return".

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; If you define any global variables, you MUST define them ABOVE this line.
;
return ; The first return in this ahk. It marks the End of auto-execute section.
;
; After this line, you can define hotkeys and functions, 
; or #Include somebody else's AHK partial file(s).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#SingleInstance force

Init_ExeEverpicEnv()
{
	; Add a systray menu item
	Menu, tray, add  ; Creates a separator line.
	Menu, tray, add, % "Bring up Everpic UI", Evp_LaunchUI

	;

	hotkeyspec := EverpicExe_ReadInikey("hotkey")

	if(!hotkeyspec)
		hotkeyspec := "^#c"

	dev_DefineHotkey(hotkeyspec, "Evp_LaunchUI")
	
	if(g_evpTempPreserveMinutes>0) 
	{
		; evernote.ahk should have set this value.
		val := EverpicExe_ReadInikey("TempPreserveMinutes")
		minutes := dev_str2num(val)
		if(minutes>0)
			g_evpTempPreserveMinutes := minutes
	}
	else
	{
		dev_MsgBoxWarning("Code out-of-sync. g_evpTempPreserveMinutes is 0 !")
	}
	
	g_evp_isDbgCleanupTimer := dev_str2num(EverpicExe_ReadInikey("DbgTimerMsgOn"))
	
	desc := dev_InterpretHotkeySpec(hotkeyspec)
	
	dev_MsgBoxInfo("Hotkey to bring up Everpic UI:`r`n`r`n    " desc "`r`n`r`n"
		. "You can configure this hotkey in Everpic.ini ." 
		, "Everpic Launch tip")
	
	Evp_LaunchUI()
	
	GuiControl_SetValue("EVP", "gu_evpCkbKeepWindow", 1)
	; -- this should be done after Evp_LaunchUI()
}


EverpicExe_ReadInikey(keyname)
{
	return dev_IniRead("Everpic.ini", "cfg", keyname)
}


; :::: Add your OWN hotkey definition below ::::


; RCtrl & RAlt:: Send {AppsKey}
; -- Workaround for the no AppsKey keyboard


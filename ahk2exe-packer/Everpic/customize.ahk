﻿; Note: If this file contains non-ASCII characters, you must saved it in UTF8 with BOM,
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


Init_ExeEverpicEnv()
{
	; Write your initialization statements here.

	dev_MsgBoxInfo("Type hotkey Ctrl+Win+c to call up Everpic UI."
		,"Everpic Launch tip")
	
	dev_DefineHotkey("^#c", "Evp_LaunchUI")
	Evp_LaunchUI()
}



; :::: Add your OWN hotkey definition below ::::


; RCtrl & RAlt:: Send {AppsKey}
; -- Workaround for the no AppsKey keyboard


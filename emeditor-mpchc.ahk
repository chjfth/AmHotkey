; Note: If this file contains non-ASCII characters, you must save it in UTF8 with BOM,
; in order for the Unicode characters to be recognized by Autohotkey engine.
;
AUTOEXEC_EmMpc: 
	; Workaround for Autohotkey's ugly auto-exec feature. Don't delete above line.
	; IMPORTANT: It must be the *first* non-comment line so that 
	; Amhotkey_ScanAndLoadAutoexecLabels() can recognize this file to be a "module".
	; Even /* ... */ comment block can not be used above.
	;
	; After duplicating this file, you MUST change the above AUTOEXEC_xxx label to 
	; be a unique one, such as AUTOEXEC_foobar. Otherwise, AHK engine will assert 
	; error on loading AHK source file.

; Something to place here:
; * Customize these global vars according to your running machine:
; * Call the run-once functions.

global mpcwin := "ahk_class MediaPlayerClassicW"

Init_EmMpcEnv()
; -- This function's body is defined after the first "return",
;    but we have to call it *before* the first "return".

; Something NOT to place here:
; * Hotkey definition, like 
;		#!t:: DoSomething()
; * Function definition.
;
; If you violate that "NOT" rule, .e.g, you define foo(){...} here, then all 
; `global` vars above will receive *empty* initial value.

;
return ; The first return in this ahk. It marks the End of auto-execute section.
;
; After this line, you can define hotkeys and functions, 
; or #Include somebody else's AHK partial file(s).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include %A_LineFile%\..\mediaplayer.ahk ; need MPC_txc_GetPlaytime()

class EmeMpc
{
	static default_srt_hand_delay_millis := 1000
	static default_srt_duration_millis := 2000
}


Init_EmMpcEnv()
{
	; Write your initialization statements here.
}


#If Eme_IsActive() and MPC_IsRunning()


F2:: dev_ControlSend(mpcwin, "", "^!{Left}")  ; Jump Backward (small)
F4:: dev_ControlSend(mpcwin, "", "^!{Right}") ; Jump Forward (small)

F3:: dev_ControlSend(mpcwin, "", "{Space}")

`:: emmpc_PasteMpcCurrentTime()
emmpc_PasteMpcCurrentTime()
{
	hwnd := dev_WinGet_Hwnd("ahk_class MediaPlayerClassicW")
	text := dev_ControlGetText_hc(hwnd, "Static2")
	; dev_MsgBoxInfo(text)
	
	; Play-time text from MPC Static2(right-bottom) corner example:
	;
	; Default:
	;	00:48 / 01:08
	;	00:01:23 / 01:43:52
	;
	; High precision (from right-clicking Static2):
	;	00:48 / 01:08
	;	00:01:23 / 01:43:52
	;
	; If [Remaining time] is ticked, a minus sign appears first, e.g:
	;	-00:19 / 01:08
	
	mpctimes := MPC_txc_GetPlaytime(mpcwin)
	tnow := mpctimes[2]
	tnowstr := Format("{:02d}:{:02d}:{:02d},{:03d}", tnow.hour, tnow.minute, tnow.second, tnow.millis)
	
	; One srt time-stamp line will be [ t1 --> t2 ]
	
	t1 := MPC_AddMillis(tnow.hour, tnow.minute, tnow.second, tnow.millis
		, 0 - EmeMpc.default_srt_hand_delay_millis)
	
	t2 := MPC_AddMillis(tnow.hour, tnow.minute, tnow.second, tnow.millis
		, EmeMpc.default_srt_duration_millis - EmeMpc.default_srt_hand_delay_millis)

	t1str := Format("{:02d}:{:02d}:{:02d},{:03d}", t1.hour, t1.minute, t1.second, t1.millis)
	t2str := Format("{:02d}:{:02d}:{:02d},{:03d}", t2.hour, t2.minute, t2.second, t2.millis)
	
	srt_ts_line := Format("{} --> {}", t1str, t2str)
	paste_text := "1`n" . srt_ts_line . "`n"

	dev_PasteTextViaClipboard(paste_text)
}


#If ; Eme_IsActive()


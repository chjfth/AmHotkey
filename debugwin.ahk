﻿; Note: If this file contains non-ASCII characters, you must saved it in UTF8 with BOM,
; in order for the Unicode characters to be recognized by Autohotkey engine.

AUTOEXEC_debugwin_ahk: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.
	; When duplicate, you MUST: Change the above ahk label to a unique one, such as AUTOEXEC_foobar_ahk.

; Something to place here.
; * Customize these global vars according to your running machine:
; * Call the run-once functions.

global g_dbgwinHwnd

global gu_dbgwinMLE

global gc_dbgwinIniFile := "debugwin.ini"
global gc_dbgwinIniSection := "cfg"

Init_DebugwinEnv()
; -- This function's body is defined after the first "return",
;    but we have to call it before the first "return".

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; If you define any global variables, you MUST define them ABOVE this line.
;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init_DebugwinEnv()
{
	; Write your initialization statements here.
}

Dbgwin_Output(msg)
{
	; This function will append msg to end of curent multiline-editbox,
	; adding time-stamp prefix and \r\n suffix .
	
	; I will report millisecond fraction, so need some extra work.
	;
	static s_start_msec   := A_TickCount
	static s_start_ymdhms := A_Now
	static s_prev_msec    := s_start_msec

	now_tick := A_TickCount
	msec_from_prev := now_tick - s_prev_msec
	
	sec_from_start := (A_TickCount-s_start_msec) // 1000
	msec_frac := Mod(A_TickCount-s_start_msec, 1000)
	
	now_ymdhsm := s_start_ymdhms
	EnvAdd, now_ymdhsm, sec_from_start, Seconds

	; now_ymdhsm is like "20221212115851"
;	year := substr(now_ymdhsm, 1, 4)
;	mon  := substr(now_ymdhsm, 5, 2)
;	day  := substr(now_ymdhsm, 7, 2)
	ymd  := substr(now_ymdhsm, 1, 8)
	hour := substr(now_ymdhsm, 9, 2)
	minu := substr(now_ymdhsm, 11, 2)
	sec  := substr(now_ymdhsm, 13, 2)
	
	stimestamp := Format("{}_{}:{}:{}.{:03}", ymd, hour, minu, sec, msec_frac)
	stimeplus  := Format("+{}.{:03}s", msec_from_prev//1000, Mod(msec_from_prev,1000)) ; "+1.002s" etc
	
;	msg := now_ymdhsm "  " msg . "`r`n"
	
	soutput := Format("{1}[{2}] ({3}) {4}`r`n"
		, msec_from_prev>=1000 ? ".`r`n" : ""
		, stimestamp, stimeplus, msg)

	Dbgwin_ShowGui()
	
	; We we append msg to end of curent multiline-editbox. Using WinAPI like this:
	;
    ; int pos = GetWindowTextLength (hedit);
    ;
    ; Edit_SetSel(hedit, pos, pos);
    ; Edit_ReplaceSel(hedit, text);
    
    hwndEdit := GuiControl_GetHwnd("Dbgwin", "gu_dbgwinMLE")
;	msgbox,  % "hwndEdit=" hwndEdit
    pos := DllCall("GetWindowTextLength", "Ptr", hwndEdit)
    
    EM_SETSEL := 0x00B1
    EM_REPLACESEL := 0x00C2
    SendMessage, % EM_SETSEL, % pos, % pos, , ahk_id %hwndEdit%
    SendMessage, % EM_REPLACESEL, 0, &soutput, , ahk_id %hwndEdit%
    
    s_prev_msec := now_tick
}	


Dbgwin_CreateGui()
{
	Gui, Dbgwin:New ; Destroy old window if any
	Gui_ChangeOpt("Dbgwin", "+Resize +MinSize +E0x0080 +E0x40000")
	; -- +E0x0080: WS_EX_TOOLWINDOW (thin title);  +E0x40000: WS_EX_APPWINDOW (want taskbar thumbnail)
	
	Gui_AssociateHwndVarname("Dbgwin", "g_dbgwinHwnd")
	Gui_Switch_Font("Dbgwin", 8, "Black", "Tahoma") 
	
	Gui_Add_StaticLabel("Dbgwin", "Message from Dbgwin_Output():")
	Gui_Add_Editbox("Dbgwin", "gu_dbgwinMLE", 400, "r10")

	Gui_Show("Dbgwin")
	Dbgwin_LoadWindowPos()
}

Dbgwin_ShowGui()
{
	if(!g_dbgwinHwnd)
	{
		Dbgwin_CreateGui()
	}
	
	Gui_Show("Dbgwin", "NoActivate", "AmHotkey Dbgwin")
}

Dbgwin_HideGui()
{
	Dbgwin_SaveWindowPos()

	Gui_Hide("Dbgwin")
}

Dbgwin_SaveWindowPos()
{
	WinGetPos, x,y,w,h, ahk_id %g_dbgwinHwnd%
;Msgbox, % "g_dbgwinHwnd=" g_dbgwinHwnd " x=" x " y=" y " w=" w " h=" h
	if(w!=0 and h!=0)
	{
		xywh := Format("{},{},{},{}", x,y,w,h)
		dev_IniWrite(gc_dbgwinIniFile, gc_dbgwinIniSection, "WinposXYWH", xywh)
	}
}

Dbgwin_LoadWindowPos()
{
	xywh := dev_IniRead(gc_dbgwinIniFile, gc_dbgwinIniSection, "WinposXYWH")
	num := StrSplit(xywh, ",")
	x := num[1] , y := num[2] , w := num[3] , h := num[4]
	if(w>0 and h>0)
	{
		dev_WinMoveHwnd(g_dbgwinHwnd, x,y, w,h)
	}
}

DbgwinGuiClose:
DbgwinGuiEscape:
	; This enables ESC to close AHK window.
	Dbgwin_HideGui()
	return 

DbgwinGuiSize()
{
;	dev_TooltipAutoClear("DbgwinGuiSize()...")
	rsdict := {}
	rsdict.gu_dbgwinMLE:= "0,0,100,100" ; Left/Top/Right/Bottom
	dev_GuiAutoResize("Dbgwin", rsdict, A_GuiWidth, A_GuiHeight)
}
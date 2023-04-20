; Note: If this file contains non-ASCII characters, you must saved it in UTF8 with BOM,
; in order for the Unicode characters to be recognized by Autohotkey engine.

/* APIs:

Dbgwin_Output("Your debug message.")
	; This debug-message window will be created automatically.
	; On first call, the dbg-window is popped to front;
	; on second call, the dbg-window remains in background so it does not disturb your active window.
	; To force second call window foreground, call Dbgwin_Output_fg() or Dbgwin_Output(msg, true) .

Dbgwin_Output_fg("Your msg") ; Force debug-window bring to front.
	
Dbgwin_ShowGui(true)
	; Show the Gui, in case it was hidden(closed by user).
	; Parameter: `true` to bring it to front; `false` to keep it background(not have keyboard focus).

Dbgvar_ShowGui()
	; Pop up the dialog UI that allows user to change AHK global vars on the fly.

Dbgvar_AddVarname(uservar, desc:="")
	; Module author use this function to add varnames to Dbgvar's UI so that user knows they exist.

*/

; [[ Dbgwin ]]

global g_dbgwinHwnd

global gu_dbgwinBtnCopy
global gu_dbgwinHint
global gu_dbgwinBtnClear
global gu_dbgwinMLE

global g_dbgwinMsgCount := 0

; [[ Dbgvar ]]

global g_dbgvarHwnd

global gu_dbgvarCbxVarSelect
global gu_dbgvarMleDesc
global gu_dbgvarEdtNewValue
global gu_dbgvarTxtNewValue
global gu_dbgvarSetBtn


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; If you define any global variables, you MUST define them ABOVE this line.
;
;return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


class Dbgwin ; as global var container
{
	; We define Dbgwin class, in order to define these "global constant"
	; without the help of AUTOEXEC_debugwin label.
	;
	static IniFilename := "debugwin.ini"
	static IniSection  := "cfg"
}


Dbgwin_Output_fg(msg)
{
	Dbgwin_Output(msg, true)
}

Dbgwin_Output(msg, force_fgwin:=false)
{
	; This function will append msg to end of curent multiline-editbox,
	; adding time-stamp prefix and \r\n suffix .
	
	; Makes single \n become \r\n, bcz Win32 editbox recognized only \r\n as newline.
	msg := StrReplace(msg, "`r`n", "`n")
	msg := StrReplace(msg, "`n", "`r`n")
	
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

	Dbgwin_ShowGui(force_fgwin)
	
	; We we append msg to end of curent multiline-editbox. (AppendText)
	; Using WinAPI like this:
	;
    ; int pos = GetWindowTextLength (hedit);
    ;
    ; Edit_SetSel(hedit, pos, pos);
    ; Edit_ReplaceSel(hedit, text);
    
    hwndEdit := GuiControl_GetHwnd("Dbgwin", "gu_dbgwinMLE")

    pos := DllCall("GetWindowTextLength", "Ptr", hwndEdit)
    
    EM_SETSEL := 0x00B1
    EM_REPLACESEL := 0x00C2
    dev_SendMessage(hwndEdit, EM_SETSEL, pos, pos)
    dev_SendMessage(hwndEdit, EM_REPLACESEL, 0, &soutput)
    
   	g_dbgwinMsgCount += 1
	;
    GuiControl_SetText("Dbgwin", "gu_dbgwinHint"
    	, Format("{} Messages from Dbgwin_Output():", g_dbgwinMsgCount))

    s_prev_msec := now_tick
}	


Dbgwin_CreateGui()
{
	Gui, Dbgwin:New ; Destroy old window if any
	Gui_ChangeOpt("Dbgwin", "+Resize +MinSize300x150 +E0x0080 +E0x40000")
	; -- +E0x0080: WS_EX_TOOLWINDOW (thin title);  +E0x40000: WS_EX_APPWINDOW (want taskbar thumbnail)
	
	Gui_AssociateHwndVarname("Dbgwin", "g_dbgwinHwnd")
	Gui_Switch_Font("Dbgwin", 8, "Black", "Tahoma") 
	
	Gui_Add_Button("Dbgwin", "gu_dbgwinBtnCopy" , 40, "Section g" "Dbgwin_evtBtnCopy", "&Copy")
	Gui_Add_TxtLabel("Dbgwin", "gu_dbgwinHint", 200, "x+5 yp+4", "Message from Dbgwin_Output():")
	Gui_Add_Button("Dbgwin", "gu_dbgwinBtnClear", 40, "ys x+115 g" "Dbgwin_evtClear", "Clea&r")
	Gui_Add_Editbox("Dbgwin", "gu_dbgwinMLE", 400, "xm r10")

	g_dbgwinMsgCount := 0

	Gui_Show("Dbgwin")
	Dbgwin_LoadWindowPos()
}

Dbgwin_ShowGui(bring_to_front:=false)
{
	if(!g_dbgwinHwnd)
	{
		Dbgwin_CreateGui()
	}
	
	Gui_Show("Dbgwin", bring_to_front ? "" : "NoActivate", "AmHotkey Debugwin")
}

Dbgwin_HideGui()
{
	Dbgwin_SaveWindowPos()

	Gui_Hide("Dbgwin")
}

Dbgwin_SaveWindowPos()
{
	WinGetPos, x,y,w,h, ahk_id %g_dbgwinHwnd%

	if(w!=0 and h!=0)
	{
		xywh := Format("{},{},{},{}", x,y,w,h)
		succ := dev_IniWrite(Dbgwin.IniFilename, Dbgwin.IniSection, "WinposXYWH", xywh)
		if(!succ)
			dev_MsgBoxWarning(Format("Dbgwin_SaveWindowPos(): Fail to save ini file: {}", Dbgwin.IniFilename))
	}

;	Msgbox, % "Dbgwin.IniFilename=" Dbgwin.IniFilename
}

Dbgwin_LoadWindowPos()
{
	xywh := dev_IniRead(Dbgwin.IniFilename, Dbgwin.IniSection, "WinposXYWH")

	num := StrSplit(xywh, ",")
	x := num[1] , y := num[2] , w := num[3] , h := num[4]
	if(w>0 and h>0)
	{
		dev_WinMoveHwnd(g_dbgwinHwnd, x,y, w,h)
	}
}

DbgwinGuiClose()
{
	Dbgwin_HideGui()
}

DbgwinGuiEscape()
{
	; This enables ESC to close AHK window.
	Dbgwin_HideGui()
}


DbgwinGuiSize()
{
;	Dbgwin_Output(Format("In DbgwinGuiSize(), A_GuiWidth={}, A_GuiHeight={}", A_GuiWidth, A_GuiHeight))
	
	rsdict := {}
	rsdict.gu_dbgwinMLE := "0,0,100,100" ; Left/Top/Right/Bottom
	rsdict.gu_dbgwinBtnClear := "100,0,100,0"
	dev_GuiAutoResize("Dbgwin", rsdict, A_GuiWidth, A_GuiHeight)
}

Dbgwin_evtBtnCopy()
{
	text := GuiControl_GetText("Dbgwin", "gu_dbgwinMLE")
	
	if(text)
	{
		Clipboard := text
		slen := strlen(text)
		dev_TooltipAutoClear(Format("Copied to clipboard, {} chars", slen))
	}

	Dbgwin_SaveWindowPos()
}

Dbgwin_evtClear()
{
	GuiControl_SetText("Dbgwin", "gu_dbgwinMLE", "")

	Dbgwin_SaveWindowPos()
}


; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 

; Dbgvar : a GUI that allow user to change global vars on the fly.

class Dbgvar ; as global var container
{
	static GuiName := "Dbgvar"
	static GuiWidth := 400 ; px
	
	static dictVars := {}
}

Dbgvar_CreateGui()
{
	GuiName := Dbgvar.GuiName
	guiwidth := 400
	
	Gui_New(GuiName)
	Gui_AssociateHwndVarname(GuiName, "g_dbgvarHwnd")
	Gui_ChangeOpt(GuiName, "+Resize +MinSize")
	
	Gui_Switch_Font( GuiName, 9, "", "Tahoma")
	
	Gui_Add_TxtLabel(GuiName, "", -1, "xm", "Change global vars on the fly.")
	Gui_Add_TxtLabel(GuiName, "", -1, "xm", "Var name:")
	
	Gui_Add_Combobox(GuiName, "gu_dbgvarCbxVarSelect", 300, "xm g" "Dbgvar_SyncUI")
	Gui_Add_Editbox( GuiName, "gu_dbgvarMleDesc", Dbgvar.GuiWidth-20, "xm-2 readonly r3 -E0x200")
	
	Gui_Add_TxtLabel(GuiName, "gu_dbgvarTxtNewValue", -1, "xm", "New value:")
	Gui_Add_Editbox( GuiName, "gu_dbgvarEdtNewValue", Dbgvar.GuiWidth-20, "")

	Gui_Add_Button(  GuiName, "gu_dbgvarSetBtn", -1, "Default g" "Dbgvar_SetValueBtn", "&Set new value")
	
	varlist := []
	for varname,desc in Dbgvar.dictVars
	{
		varlist.Push(varname)
	}
	GuiControl_ComboboxAddItems(GuiName, "gu_dbgvarCbxVarSelect", varlist) ; already sorted by AHKGUI
}

Dbgvar_ShowGui()
{
	GuiName := Dbgvar.GuiName

	if(!g_dbgvarHwnd) {
		Dbgvar_CreateGui() ; destroy old and create new
	}
	
	Gui_Show(GuiName, Format("w{} center", Dbgvar.GuiWidth), "AHK change global var")
	
}

Dbgvar_HideGui()
{
	GuiName := Dbgvar.GuiName

	Gui_Hide(GuiName)
}

DbgvarGuiClose()
{
	Dbgvar_HideGui()
}

DbgvarGuiEscape()
{
	Dbgvar_HideGui()
}

Dbgvar_SetValue()
{
	GuiName := Dbgvar.GuiName

	uservar := GuiControl_GetText(GuiName, "gu_dbgvarCbxVarSelect")
	uservalue := GuiControl_GetText(GuiName, "gu_dbgvarEdtNewValue")
	
	GuiControl_SetText(GuiName, "gu_dbgvarMleDesc", Dbgvar.dictVars[uservar])
	
	%uservar% := uservalue
}

Dbgvar_SetValueBtn()
{
	Dbgvar_SetValue()
	
	Dbgvar_HideGui()
}

DbgvarGuiSize()
{
	rsdict := {}
    rsdict.gu_dbgvarMleDesc := "0,0,100,100" ; Left/Top/Right/Bottom pct
    rsdict.gu_dbgvarEdtNewValue := "0,100,100,100"
    rsdict.gu_dbgvarTxtNewValue := "0,100,0,100"
    rsdict.gu_dbgvarSetBtn := "0,100,0,100"
    dev_GuiAutoResize(Dbgvar.GuiName, rsdict, A_GuiWidth, A_GuiHeight, true)
}



;Dbgvar_evtCbxVarSelect()
;{
;	Dbgvar_SyncUI()
;}
;

Dbgvar_SyncUI()
{
	GuiName := Dbgvar.GuiName

	uservar := GuiControl_GetText(GuiName, "gu_dbgvarCbxVarSelect")
	
	GuiControl_SetText(GuiName, "gu_dbgvarMleDesc", Dbgvar.dictVars[uservar])
	
	uservalue := %uservar%
	GuiControl_SetText(GuiName, "gu_dbgvarEdtNewValue", uservalue)
}


Dbgvar_AddVarname(uservar, desc:="")
{
	Dbgvar.dictVars[uservar] := desc
}


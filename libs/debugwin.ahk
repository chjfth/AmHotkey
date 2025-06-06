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

Amdbg_ShowGui()
	; Pop up the dialog UI that allows user to change AHK global vars on the fly.

AmDbg_SetDesc(modu, desc)
	; [Optional] Associate a piece of description text to modu, which can be seen in 
	; Dbgwin GUI instantly, so the final user knows what the modu name stands for.

AmDbg_GetVerboseLv(modu)
	; Query modu's current debug-message limitLv

Amdbg_output(modu, newmsg, msglv)

Amdbg_Lv1(modu, newmsg)
Amdbg_Lv2(modu, newmsg)
Amdbg_Lv3(modu, newmsg)
	; Output a debug message in the name of modu(debug-module). 
	; By calling Amdbg_ShowGui(), final user can control which modu's messages 
	; appears in Dbgwin GUI instantly.

Amdbg_Lv0(modu, newmsg)
	; Lv0 message has the benefit over Dbgwin_Output() that it's content is buffered into RAM,
	; and can be later retrieved by Amdbg_ShowGui()'s [Copy to clipboard] button.

Amdbg_Lv0p(modu, newmsg) ; newmsg auto-prefixed with modu name.
...

Simpler message output (modu name "_default_"):
Amdbg0(newmsg)
Amdbg1(newmsg)
Amdbg2(newmsg)
Amdbg3(newmsg)

*/

; [[ Dbgwin ]]

global g_dbgwinHwnd

global gu_dbgwinBtnCopy
global gu_dbgwinHint
global gu_dbgwinBtnClear
global gu_dbgwinMLE

global g_dbgwinMsgCount := 0

; [[ Amdbg ]]

global g_amdbgHwnd

global gu_amdbgCbxDbgModu
global gu_amdbgBtnRefresh
global gu_amdbgTxtDbgBuffer
global gu_amdbgBtnCopyDbgBuffer
global gu_amdbgMleDesc
global gu_amdbgTxtNewValue
global gu_amdbgEdtNewValue
global gu_amdbgSetBtn
global gu_amdbgBtnOpenDbgwin


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; If you define any global variables, you MUST define them ABOVE this line.
;
;return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

class Amdbg ; as global var container
{
	static _default_modu := "_default_"

	static _GuiName := "Amdbg"
	static _GuiWidth := 470 ; px
	
	static _dictModules := {}
	; -- each dict-key represent a debug-module, and the module's content is described in
	; 	yet another dict which has the following keys:
	;	.desc     : description text of this debug-module.
	; 	.allmsg   : all debug messaged accumulated(as a circular buffer).
	;	.displaylimitlv : 
	;               debug-message display-limit level, 0,1,2... (sift-level)
	;               If 1, msg with level equal or less than 1 is is sent to Dbgwin_Output(), 
	;               msg with larger-levels are buffered to memory.
	;
	static _tmp_ := Amdbg.CreateDefaultModu()
	
	static _maxbuf := 2048000 ; allmsg buffer size, in bytes
	
	CreateDefaultModu()
	{
		desc := "Debug-messages without assigning an explicit module-name, belong to the _default_ module. `n"
			. "Amdbg0(), Amdbg1(), Amdbg2() outputs such messages."

		Amdbg_SetDesc(Amdbg._default_modu, desc)
	}
}




class Dbgwin ; as global var container
{
	; We define Dbgwin class, in order to define these "global constant"
	; without the help of AUTOEXEC_debugwin label.
	;
	static _IniFilename := "debugwin.ini"
	static _IniSection  := "cfg"
}


class CTimeGapTeller
{
	_gap_millisec := 0
	_msec_prev := 0
	
	__New(gap_millisec)
	{
		this._msec_prev := 0
		this._gap_millisec := gap_millisec
	}
	
	CheckGap()
	{
		; If _gap_millisec time-period has elapsed since previous CheckGap() call,
		; return positive value, otherwise, return 0. 
		; If the positive value is N, it means N times of _gap_millisec has elapsed.
		; First-run returns 0.
		
		ret := 0 ; assume false
		now_msec := dev_GetTickCount64()
		
		if(this._msec_prev>0)
		{
			elapsed_ms := now_msec - this._msec_prev
			if(elapsed_ms >= this._gap_millisec)
				ret := elapsed_ms // this._gap_millisec
		}

		this._msec_prev := now_msec
		return ret
	}
}

Dbgwin_Output_fg(msg)
{
	Dbgwin_Output(msg, true)
}

Dbgwin_Output(msg, force_fgwin:=false)
{
	linemsg := AmDbg_MakeLineMsg(Amdbg._default_modu, msg, 1, _unused_output)
	
	Dbgwin_AppendRaw(linemsg, force_fgwin)
}
	
Dbgwin_AppendRaw(linemsg, force_fgwin:=false)
{	
	static s_tgt := new CTimeGapTeller(1000)

	nsecs := s_tgt.CheckGap()
	if(nsecs>0)
	{
		if(nsecs>10)
			nsecs := 10
		
		linemsg := dev_StrRepeat(".", nsecs) "`r`n" linemsg
	}
	
	Dbgwin_ShowGui(force_fgwin)
	
	; We append msg to end of current multiline-editbox. (AppendText)
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
    dev_SendMessage(hwndEdit, EM_REPLACESEL, 0, &linemsg)
    
   	g_dbgwinMsgCount += 1
	;
    GuiControl_SetText("Dbgwin", "gu_dbgwinHint"
    	, Format("{} Messages from Dbgwin_Output():", g_dbgwinMsgCount))

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
		succ := dev_IniWrite(Dbgwin._IniFilename, Dbgwin._IniSection, "WinposXYWH", xywh)
		if(!succ)
			dev_MsgBoxWarning(Format("Dbgwin_SaveWindowPos(): Fail to save ini file: {}", Dbgwin._IniFilename))
	}

;	Msgbox, % "Dbgwin._IniFilename=" Dbgwin._IniFilename
}

Dbgwin_LoadWindowPos()
{
	xywh := dev_IniRead(Dbgwin._IniFilename, Dbgwin._IniSection, "WinposXYWH")

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

; Amdbg : a GUI that allows user to change global vars on the fly.

Amdbg_CreateGui()
{
	GuiName := Amdbg._GuiName
	gwidth := Amdbg._GuiWidth
	
	Gui_New(GuiName)
	Gui_AssociateHwndVarname(GuiName, "g_amdbgHwnd")
	Gui_ChangeOpt(GuiName, "+Resize +MinSize")
	
	Gui_Switch_Font( GuiName, 9, "", "Tahoma")
	
;	Gui_Add_TxtLabel(GuiName, "", -1, "xm", "Still contemplating good wording for this banner text.")
	Gui_Add_TxtLabel(GuiName, "", -1, "xm", "&Debug-module:")
	
	Gui_Add_Combobox(GuiName, "gu_amdbgCbxDbgModu", gwidth-80, "xm g" "Amdbg_SyncUI_nocopy")
	; -- Use Combobox instead of DropdownList, so that user can copy the module name.
	Gui_Add_Button(  GuiName, "gu_amdbgBtnRefresh", 60, "yp-1 x+5 g" "Amdbg_RefreshModules", "&Refresh")
	
	Gui_Add_TxtLabel(GuiName, "gu_amdbgTxtDbgBuffer", gwidth-120, "xm y+8", "")
	Gui_Add_Button(  GuiName, "gu_amdbgBtnCopyDbgBuffer", 100, "yp-4 x+5 g" "Amdbg_CopyDbgBuffer", "&Copy buffer")
	
	Gui_Add_TxtLabel(GuiName, "", 320, "xm", "Debug-module description:")
	Gui_Switch_Font( GuiName, 0, "666666") ; change text color to gray
	Gui_Add_Editbox( GuiName, "gu_amdbgMleDesc", gwidth-20, "xm-2 readonly r4 -E0x200")
	Gui_Switch_Font( GuiName, 0, "000000") ; revert text color to black
	
	Gui_Add_TxtLabel(GuiName, "gu_amdbgTxtNewValue", -1
		, "xm +0x100", "Dbgwin &verbose level for this module: (hover for tip)") ; +0x100 enable SS_NOTIFY so to have tooltip on it
	Gui_Add_Editbox( GuiName, "gu_amdbgEdtNewValue", 60, "")

	Gui_Add_Button(  GuiName, "gu_amdbgSetBtn", -1, "Default g" "Amdbg_SetValueBtn", "&Set new")
	Gui_Add_Button(  GuiName, "gu_amdbgBtnOpenDbgwin", 100
		, Format("x+{} g{}", gwidth-175, "Dbgwin_ShowGui")
		, "&Open Dbgwin")
	
	Amdbg_RefreshModules()
}

Amdbg_ShowGui()
{
	GuiName := Amdbg._GuiName

	if(!g_amdbgHwnd) {
		Amdbg_CreateGui() ; destroy old and create new
	}
	
	OnMessage(0x200, Func("Amdbg_WM_MOUSEMOVE")) ; add message hook
	
	Gui_Show(GuiName, Format("w{} center", Amdbg._GuiWidth), "AmHotkey AmDbg configurations")
	
	Amdbg_RefreshModules()
}

Amdbg_HideGui()
{
	GuiName := Amdbg._GuiName

	Gui_Hide(GuiName)
	
	OnMessage(0x200, Func("Amdbg_WM_MOUSEMOVE"), 0) ; remove message hook
	tooltip
}

AmdbgGuiClose()
{
	Amdbg_HideGui()
}

AmdbgGuiEscape()
{
	Amdbg_HideGui()
}

Amdbg_SetValue()
{
	GuiName := Amdbg._GuiName

	modu := GuiControl_GetText(GuiName, "gu_amdbgCbxDbgModu")
	displaylimitlv := GuiControl_GetText(GuiName, "gu_amdbgEdtNewValue")
	
	errtitle := "Error input"
	if(not modu)
	{
		dev_MsgBoxError("Debug-module input empty.", errtitle)
		return false
	}
	
	moduobj := Amdbg._dictModules[modu]
	if(not moduobj)
	{
		dev_MsgBoxError("No such debug-module exists: " modu, errtitle)
		return false
	}
	
	if(StrLen(displaylimitlv)==0)
	{
		dev_MsgBoxError("Verbose-level input empty.", errtitle)
		return false
	}
	
	moduobj.displaylimitlv := displaylimitlv
	
	return true
}

Amdbg_SetValueBtn()
{
	succ := Amdbg_SetValue()
	
	if(succ)
		dev_MsgBoxInfo("Set success.")
}

AmdbgGuiSize()
{
	rsdict := {}
	rsdict.gu_amdbgCbxDbgModu := "0,0,100,0"
	rsdict.gu_amdbgBtnRefresh  := "100,0,100,0"
	rsdict.gu_amdbgBtnCopyDbgBuffer := "100,0,100,0"
    rsdict.gu_amdbgMleDesc := "0,0,100,100" ; Left/Top/Right/Bottom pct
    rsdict.gu_amdbgSetBtn := "0,100,0,100"
    rsdict.gu_amdbgTxtNewValue := "0,100,0,100"
    rsdict.gu_amdbgEdtNewValue := "0,100,0,100"
    rsdict.gu_amdbgBtnOpenDbgwin := "100,100,100,100"
    dev_GuiAutoResize(Amdbg._GuiName, rsdict, A_GuiWidth, A_GuiHeight, true)
}


Amdbg_RefreshModules()
{
	; Amdbg modules can be dynamically created/deleted, so we need this operation
	; to list new modules.
	
	GuiName := Amdbg._GuiName
	vnCbx := "gu_amdbgCbxDbgModu"
	
	cbTextOrig := GuiControl_GetText(GuiName, vnCbx)
	
	hwndCombobox := GuiControl_GetHwnd(GuiName, vnCbx)
	dev_assert(hwndCombobox)
	dev_Combobox_Clear(hwndCombobox)

	varlist := []
	for modu in Amdbg._dictModules
	{
		varlist.Push(modu)
	}
	GuiControl_ComboboxAddItems(GuiName, vnCbx, varlist) ; already sorted by AHKGUI
	
	Combobox_SetText(GuiName, vnCbx, cbTextOrig)
	
	if(!cbTextOrig)
	{
		GuiControl_ChooseN(GuiName, vnCbx, 1)
	}
	
	Amdbg_SyncUI()
}

Amdbg_SyncUI(is_copybuffer:=false)
{
	GuiName := Amdbg._GuiName

	modu := GuiControl_GetText(GuiName, "gu_amdbgCbxDbgModu")
	moduobj := Amdbg._dictModules[modu]

	if(moduobj)
	{
		chars := StrLen(moduobj.allmsg)
		
		GuiControl_SetText(GuiName, "gu_amdbgTxtDbgBuffer"
			, Format("{} characters of debug message in buffer.", chars))
		
		if(is_copybuffer)
		{
			is_ok := dev_SetClipboardWithTimeout(moduobj.allmsg)
			if(is_ok)
				dev_MsgBoxInfo(Format("{} characters copied to clipboard.", chars))
		}
		
		GuiControl_SetText(GuiName, "gu_amdbgMleDesc", moduobj.desc)
		
		displaylimitlv := moduobj.displaylimitlv
		GuiControl_SetText(GuiName, "gu_amdbgEdtNewValue", displaylimitlv)
	}
	else
	{
		GuiControl_SetText(GuiName, "gu_amdbgMleDesc", "")
		
		GuiControl_SetText(GuiName, "gu_amdbgTxtDbgBuffer", "")
		
		GuiControl_SetText(GuiName, "gu_amdbgEdtNewValue", "")
	}
}

Amdbg_SyncUI_nocopy()
{
	Amdbg_SyncUI(false)
}

Amdbg_CopyDbgBuffer()
{
	Amdbg_SyncUI(true)
}

Amdbg_WM_MOUSEMOVE()
{
    static s_prev_tooltiping_uic := 0
    
	GuiName := Amdbg._GuiName

	is_from_tooltiping_uic := true ; assume message is from a GuiControl
	idCtrl := A_GuiControl

	modu := GuiControl_GetText(GuiName, "gu_amdbgCbxDbgModu")
	displaylimitlv := GuiControl_GetText(GuiName, "gu_amdbgEdtNewValue")
	
	if(idCtrl=="gu_amdbgTxtNewValue")
	{
		dev_Tooltip(Format("" 
			. "How verbose you want to see in Dbgwin window.`n"
			. "`n"
			. "If debug-module ""{1}"" outputs a message with message level higher than {2}, `n"
			. "that message is considered too noisy, and will not be visible in Dbgwin.`n"
			. "`n"
			. "On the other hand, if debug-module ""{1}"" outputs a message of level {2} or below, `n"
			. "that message is considered cozy, and will be immediately visible in Dbgwin. `n"
			. "`n"
			. "Noisy debug-messages are not lost, they can be retrieved by clicking `n"
			. "[Copy buffer] button."
			, modu, displaylimitlv))
	}
	else
	{
		is_from_tooltiping_uic := false
	}
	
	if(A_Gui==GuiName)
	{
		; According to my [20221215.R1]
        ; If mouse has *just* moved off a tooltiping UIC, we turn off the tooltip.
        ; We cannot blindly turn off tooltip here, bcz we would get constant WM_MOUSEMOVE 
        ; even if we do not move the mouse; turning off tooltip blindly would cause 
        ; other function''s dev_TooltipAutoClear() to vanish immediately.
        ;
        if(is_from_tooltiping_uic) {
            s_prev_tooltiping_uic := A_GuiControl
        }
        else if(s_prev_tooltiping_uic) {
            tooltip ; turn off tooltip
            s_prev_tooltiping_uic := 0
        }
	}
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Implement Amdbg_output()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AmDbg_MakeLineMsg(modu, msg, lv, byref is_same_modu_as_prev)
{
	; Makes single \n become \r\n, bcz Win32 editbox recognizes only \r\n as newline.
	msg := StrReplace(msg, "`r`n", "`n")
	msg := StrReplace(msg, "`n", "`r`n")
	
	; I will report millisecond fraction, so need some extra work.
	;
	static s_start_msec   := A_TickCount
	static s_start_ymdhms := A_Now
	static s_prev_msec    := s_start_msec
	
	static s_prev_modu := ""
	
	now_ymdhms_rtc := A_Now ; wall time reported by OS
	
	now_tick := A_TickCount
	msec_from_prev := now_tick - s_prev_msec

	; Dbgwin_AppendRaw(Format("s_prev_msec={} , now_tick={} ({})`r`n", s_prev_msec, now_tick, now_tick-s_prev_msec))
	; -- this is used to output dbg-info inside this very function(AmDbg_MakeLineMsg).
	
	sec_from_start := (now_tick - s_start_msec) // 1000
	msec_frac := Mod(now_tick - s_start_msec, 1000)
	
	now_ymdhms := dev_Ts14AddSeconds(s_start_ymdhms, sec_from_start)
	
	bias_seconds := dev_Ts14Diff(now_ymdhms_rtc, now_ymdhms)
	; -- If 2, it mean wall-time is 2 seconds ahead of deduced-time.
	;
	if(Abs(bias_seconds)>=2)
	{
		; OS User may have changed system time, or,
		; user has paused VM for 10 seconds then resume, and we will get bias_seconds=10.
		; So we need to adjust s_start_ymdhms to make our ymdhms match the wall-time.
		s_start_ymdhms := dev_Ts14AddSeconds(s_start_ymdhms, bias_seconds)
		now_ymdhms := dev_Ts14AddSeconds(now_ymdhms, bias_seconds)
	}

	; now_ymdhms is like "20221212115851"
;	year := substr(now_ymdhms, 1, 4)
;	mon  := substr(now_ymdhms, 5, 2)
;	day  := substr(now_ymdhms, 7, 2)
	ymd  := substr(now_ymdhms, 1, 8)
	hour := substr(now_ymdhms, 9, 2)
	minu := substr(now_ymdhms, 11, 2)
	sec  := substr(now_ymdhms, 13, 2)
	
	stimestamp := Format("{}_{}:{}:{}.{:03}", ymd, hour, minu, sec, msec_frac)
	stimeplus  := Format("+{}.{:03}s", msec_from_prev//1000, Mod(msec_from_prev,1000)) ; "+1.002s" etc
	
;	msg := now_ymdhms "  " msg . "`r`n"
	
	linemsg := Format("{1}*[{2}] ({3}) {4}`r`n"
		, lv, stimestamp, stimeplus, msg)
	
    s_prev_msec := now_tick

	if(modu==s_prev_modu) {
		is_same_modu_as_prev := true
	}
	else {
		is_same_modu_as_prev := false
		s_prev_modu := modu
	}
	
	return linemsg
}

_Amdbg_CreateDbgModule(modu) ; Create debug-module object if not-exist yet
{
	dev_assert(StrLen(modu)>1)
	
	if(not Amdbg._dictModules.HasKey(modu))
	{
		Amdbg._dictModules[modu] := {}
		Amdbg._dictModules[modu].desc := "(Unset yet)"
		Amdbg._dictModules[modu].allmsg := ""
		Amdbg._dictModules[modu].timegapteller := new CTimeGapTeller(1000)
		
		; Check for default Debug verbose level for this modu.
		; User can set those default values in custom_env.ahk.
		; For example, for modu="Clipmon", put this into custom_env.ahk :
		;
		; 	DbgwinInit.VerboseLv["Clipmon"] := 1
		;
		defaultlv := 0
		if( DbgwinInit )
		{
			defaultlv := DbgwinInit.VerboseLv[modu]
		}
		
		if(defaultlv>0)
			Amdbg._dictModules[modu].displaylimitlv := defaultlv
		else
			Amdbg._dictModules[modu].displaylimitlv := 0
	}

	return Amdbg._dictModules[modu]
}

_Amdbg_AppendLineMsg(moduobj, linemsg, is_same_modu_as_prev)
{
	; moduobj is the object returned by _Amdbg_CreateDbgModule()
	
	line_prefix := ""
	
	if(moduobj.timegapteller.CheckGap())
		line_prefix .= "." ; Use a dot to indicate a big time gap
	
	if(not is_same_modu_as_prev)
	{
		; Indicate that there are some intervening dbg-msgs from other dbg-modu 
		; before this one, so the time-diff, eg. (+0.333ms), is diff to that other msg.
		line_prefix .= "~" 
	}

	if(line_prefix)
		linemsg := line_prefix "`r`n" linemsg
	
	moduobj.allmsg .= linemsg
}

AmDbg_GetVerboseLv(modu)
{
	dev_assert(dev_IsOneWord(modu))
	
	return Amdbg._dictModules[modu].displaylimitlv
}

Amdbg_output(modu, newmsg, msglv:=1)
{
	; modu is a short string describing to which debug-module this newmsg belongs
	
	;dev_assert(modu) ; modu must NOT be empty
	if(!modu)
		modu := Amdbg._default_modu
	
	dev_assert(dev_IsOneWord(modu))
	dev_assert(StrLen(newmsg)>0)
	
	moduobj := _Amdbg_CreateDbgModule(modu)
	
	; Truncate buffer if full
	if(StrLen(moduobj.allmsg)>=Amdbg._maxbuf)
	{
		halfmax := Amdbg._maxbuf / 2
		
		moduobj.allmsg := SubStr(moduobj.allmsg, halfmax)
	}
	
	linemsg := AmDbg_MakeLineMsg(modu, newmsg, msglv, is_same_modu_as_prev)
	
	_Amdbg_AppendLineMsg(moduobj, linemsg, is_same_modu_as_prev)
	
	if(msglv <= moduobj.displaylimitlv)
	{
		Dbgwin_AppendRaw(linemsg)
	}
}

Amdbg_Lv0(modu, newmsg)
{
	Amdbg_output(modu, newmsg, 0)
}

Amdbg_Lv1(modu, newmsg)
{
	Amdbg_output(modu, newmsg, 1)
}

Amdbg_Lv2(modu, newmsg)
{
	Amdbg_output(modu, newmsg, 2)
}

Amdbg_Lv3(modu, newmsg)
{
	Amdbg_output(modu, newmsg, 3)
}

Amdbg_Lv0p(modu, newmsg)
{
	Amdbg_output(modu, modu ": " newmsg, 0)
}

Amdbg_Lv1p(modu, newmsg)
{
	Amdbg_output(modu, modu ": " newmsg, 1)
}

Amdbg_Lv2p(modu, newmsg)
{
	Amdbg_output(modu, modu ": " newmsg, 2)
}

Amdbg_Lv3p(modu, newmsg)
{
	Amdbg_output(modu, modu ": " newmsg, 3)
}


Amdbg_SetDesc(modu, desc)
{
	moduobj := _Amdbg_CreateDbgModule(modu)
	
	moduobj.desc := desc
}

Amdbg0(newmsg)
{
	Amdbg_Lv0("", newmsg)
}

Amdbg1(newmsg)
{
	Amdbg_Lv1("", newmsg)
}

Amdbg2(newmsg)
{
	Amdbg_Lv2("", newmsg)
}

Amdbg3(newmsg)
{
	Amdbg_Lv3("", newmsg)
}


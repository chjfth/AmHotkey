﻿
AUTOEXEC_winshell: ; Workaround for Autohotkey's ugly auto-exec feature. Must be first line.

global g_ctlmove_unit := 10 ; control move unit
global g_ctlmove_hwndtop
global g_ctlmove_classnn


global g_MoffCheckPeriod := 10 ; 10 seconds default
global g_isMoffPeriodic := false            ; Associate with Gui Checkbox
global g_isMoffPeriodicOnLockScreen = false ; Associate with Gui Checkbox
	; We need g_...Checked to remember user's choice after user press Cancel on the countdown dialog.
global g_isScreenLocked_byMoff := false
global g_PriorKeyBeforeLock := ""

global g_monitor_off_countdown_init := 5 ; const
global g_MoffCountdown ; variable

global g_MoffPause ; Associate with Gui Button
global g_isMoffPaused := false


; Calculate monitor PPI globals >>>

global g_idxMonitorChoice = 0
global g_cm_per_inch = 2.54 ; const

global g_HwndCalppi

global g_CalppiXPixels ; X direction physical pixels, e.g. 1920
global g_CalppiYPixels ; Y direction physical pixels, e.g. 1200
global g_CalppiInch ; Monitor size in inch, e.g. 24.0

global gar_models ; an array
global g_CalppiListlist
global g_CalppiDropboxSel = 0 ; 0 means un-selected
global g_cm_Diagonal, g_cm_Width, g_cm_Height
global g_mm_dotsize, g_monitor_ppi

global g_btnCalppiAdvanced ; Gui-assoc
global g_CalppiLogicalResX, g_CalppiLogicalResY ; Gui-assoc
global g_mm_dotsize_LogiX, g_mm_dotsize_LogiY ; Gui-assoc
global g_ppi_LogiX, g_ppi_LogiY ; Gui-assoc


CalPPI_Init() ; Call it
; Calculate monitor PPI globals <<<

; Systray menu-items
global winshell_menutext_WindowOp := "Daily window op"
	global winshell_menutext_CheckActiveWindowInfo := "Check active window info"
	global winshell_menutext_ActiveWindowDwmOff := "Active-window DWM rendering off"
	global winshell_menutext_ActiveWindowDwmOn  := "Active-window DWM rendering on"

winshell_WindowOp_Init()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

class winshell
{
	static UtilityMenu := "WinshellUtilityMenu"
}


AppsKey & w:: dev_MenuShow(winshell.UtilityMenu)

; Ctrl+Alt+[Numpad /], click in left-hand portion of a window.
; Ctrl+Alt+[Numpad *], click in right-hand portion of a window.
; [2021-12-02] Avoid Alt+*, bcz Visual Studio IDE use Alt+* as "Show Next Statement".
; [2021-12-03] Avoid Ctrl or Shift, bcz Ctrl+click or Shift+click can cause "multi/range selection" hehavior.
#NumpadDiv::  chj_ClickLeftSide()
chj_ClickLeftSide()
{
	ClickInActiveWindow(g_LeftsideClickPct, g_MiddleFloorClickPct)
	dev_TooltipAutoClear(Format("ClickInActiveWindow({1}, {2})", g_LeftsideClickPct, g_MiddleFloorClickPct))
}
;
#NumpadMult:: chj_ClickRightSide()
chj_ClickRightSide()
{
	ClickInActiveWindow(g_RightsideClickPct, g_MiddleFloorClickPct)
	dev_TooltipAutoClear(Format("ClickInActiveWindow({1}, {2})", g_RightsideClickPct, g_MiddleFloorClickPct))
}

dev_WinMove_with_backup_with_prompt(_newx, _newy, _new_width, _new_height, Awinid:=0, is_force:=false)
{
	static s_hint_timeout := 8000

	dev_WinMove_with_backup(_newx, _newy, _new_width, _new_height, Awinid, is_force)

	dev_TooltipAutoClear("Press Ctrl+Win+0 to undo window location/size change.", s_hint_timeout)
	s_hint_timeout := 1000
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 2023.01: Static hotkey definitions moved from AmHotkey.ahk .
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

$AppsKey:: Send {AppsKey} 
	; Need this because I somewhere else use AppsKey as a prefix key (in many modules).

CapsLock & Up:: Click WheelUp
CapsLock & Down:: Click WheelDown
;
AppsKey & UP:: Click WheelUp
AppsKey & DOWN:: Click WheelDown

; Win+N to minimize a window, replacing Alt+Space,n
#n:: WinMinimize, A
+#n:: WinRestore, A

!#Del:: dev_WinHideWithPrompt("", "You can use Alt+Win+Ins to unhide it.")

!#Ins:: dev_WinHide_Restore()


; Double-press Left Ctrl to move mouse cursor to the center of current active window. (memo: Press Ctrl twice)
; I need "up"; otherwise, holding down LCtrl will trigger the double press condition.
~LCtrl up::
;	tooltip, % "Left-Ctrl-up: A_ThisHotkey=" . A_ThisHotkey . " "
	if (A_PriorHotkey == "~LCtrl up" and A_TimeSincePriorHotkey < 300) {
	    ; This is a double-press.
		MouseMoveInActiveWindow(1/2, 1/2, 7)
	}
return


winshell_BringUpEnvvarEditor()
{
	if IsWin5x() ; A_OSVersion in WIN_2003, WIN_XP, WIN_2000
	{
		dlgbox_title := "System properties"
		Run rundll32 shell32.dll`,Control_RunDLL sysdm.cpl`,`,3
	}
	else 
	{
		dlgbox_title := "Environment Variables"
		Run rundll32 sysdm.cpl`,EditEnvironmentVariables
	}

	isok := dev_WinWaitActive_with_timeout(dlgbox_title, "", 2) ;WinWaitActive, % dlgbox_title,, 2
	if(!isok)
	{
		MsgBox, % "Error: Autohotkey cannot bring up Envvar-editing dialog box."
		return
	}
	
	if IsWin5x()
	{
		; We have just brought up the "System Properties" dialog box.
		; We need to further click [Environment Variables] button.
		SendInput n
	}
}


CalPPI_Init() ; Define it
{
	SetFormat, float, 0.8

	; Predefined monitor params array 
	gar_modelstr := [ "5120,2880,27.0" ; DELL UP2715K (2014)
		, "3840,2160,27.0"  ; DELL P2715Q 
		, "3200,1800,13.3"  ; Lenovo Yoga 900
		, "2560,1440,27.0"  ; DELL U2515H (2014)
		, "2560,1440,25.0"  ; DELL U2515H (2014)
		, "1920,1200,24.0"  ; DELL U2412M (2011)
		, "1920,1080,22.0" 
		, "1680,1050,20.0"  ; DELL 2007WFP (2006)
		, "1600,1200,20.1"  ; DELL 2007FP (2006)
		, "1600,900,19.0" 
		, "1366,768,15.6" 
		, "1280,1024,17.0" 
		, "1280,800,14.0" 
		, "1024,768,13.0" 
		, "800,600,12.8" 
		, "960,640,3.5" ] ; iPhone 4

	gar_models := Object()
	g_CalppiListlist := ""
	for index, str in gar_modelstr
	{
		num := StrSplit(str, ",") ; split comma delimited value
		w := num[1]
		h := num[2]
		inch := num[3]
		gar_models.Insert({"w":w, "h":h, "inch":inch})

		listitem := w . "x" h . " , " . inch . " inch"
		g_CalppiListlist .= listitem . "|"
		
		if(A_ScreenWidth==w and A_ScreenHeight==h)
		{
			g_CalppiDropboxSel := index
		}
	}
	
	dev_MenuAddItem("TRAY", "Power-saving my monitor", "mo_InitCountDown")
}



;==============================================================
; Windows Explorer
;==============================================================

#IfWinActive, ahk_class CabinetWClass

; Let Windows 7 explorer's Backspace work like Windows XP.
; Thanks to: http://www.howtogeek.com/howto/8955/make-backspace-in-windows-7-or-vista-explorer-go-up-like-xp-did/ (with some fix)
$Backspace:: ; I think it's better to have a $ prefix
	if IsWin5x() ; nothing to change for WinXP
	{
		Send {Backspace}
		return
	}
	; Win 7+
	ControlGet renamestatus,Visible,,Edit1,A
	ControlGetFocus focussed, A
	if(renamestatus!=1 && (focussed=="DirectUIHWND3"||focussed==SysTreeView321))
	{
		SendInput !{Up}
	}else{
		Send {Backspace}
	}
return

#IfWinActive


#If dev_IsWin7SaveAsDialog()

; For easy clicking [Save] button in the oftenly keyboard stuck Windows 7 "Save As" dialog box.
^Enter::  ClickInActiveWindow(-170, -40, false)

#If


;==============================================================
; 2015-02-07: Speed Commander 14/15
;==============================================================

IsSpeedCommanderActive()
{
	if(IsWinClassActive("SC14MainFrame") || IsWinClassActive("SpeedCommander_MainWnd")) 
	{
		; "SpeedCommander_MainWnd" is used since SpeedCommander v15
		return true
	}
	else 
		return false
}

Spc_FolderGoto_AppendBSlash(driveletter)
{
;	tooltip, Spc_FolderGoto_AppendBSlash: A_PriorHotKey=%A_PriorHotKey%
	if (A_PriorHotKey=="F12")
	{
		; Append :\ after the letter
		dev_WaitKeyRelease(driveletter)
		SendInput :\
	}	
}

Spc_FolderGoto_InitHotkeys()
{
	static init_done := false
	if init_done
		return
	init_done := true
	
	; Now do:
	; dev_DefineHotkeyWithCondition("~$a", "Spc_FolderGoto_AppendBSlash", "a")
	; dev_DefineHotkeyWithCondition("~$b", "Spc_FolderGoto_AppendBSlash", "b")
	; ...
	letters = abcdefghijklmnopqrstuvwxyz
	Loop, parse, letters
	{
;		Hotkey, If, IsSpeedCommanderActive()
		old_dev_DefineHotkeyWithCondition("~$" A_LoopField, "IsSpeedCommanderActive", "Spc_FolderGoto_AppendBSlash", A_LoopField)
	}
	
}

#If IsSpeedCommanderActive()

F8:: Send +^{Tab}
F9:: Send ^{Tab}

; Feature: Pressing F10 then c(or any letter) will append \: for you, saving two seconds type the 
; two hard-to-press ":" and "\" .
; This requires Ctrl+G(the default) to be configured to Folder.Goto.Goto .
F12:: 
	Spc_FolderGoto_InitHotkeys()
	Send {F5} ; Refresh first so that we can go back later(a freaking point of SpeedCommander)
	Send ^g
return


#If

mo_TurnMonitorOff()
{
	Sleep, 500
	SendMessage, 0x112, 0xF170,2 ,,Program Manager
}

mo_IsScreenLocked()
{
	apihr := DllCall("User32\OpenInputDesktop", "int", 0, "int", 0, "int", 0x0001L*1)
	if(apihr)
	{
		; PlaySoundLeftClick() ; debug
		succ := DllCall("User32\CloseDesktop", "ptr", apihr)
		return false
	}
	else
	{
		; PlaySoundRightClick(); debug
		return true
	}
}

mo_CreateMonitorOffDlg()
{
	g_isMoffPaused := false
	SetTimer, moTimer_CheckAgain, Off
	
	Gui, MonitorOff:New ; destroy old
	Gui, MonitorOff:+HwndHwndMonitorOff ; generate variable HwndMonitorOff
	Gui, MonitorOff:Font, s9 cBlack, Tahoma
	Gui, MonitorOff:Add, Text, , % "Computer screen turn off countdown"
	
	Gui, MonitorOff:Font, s24 cGreen
	Gui, MonitorOff:Add, Text, vg_MoffCountdown Center w440, % " " ; Text set later by timer
	
	Gui, MonitorOff:Font, s9 cBlack, Tahoma
	optchecked := g_isMoffPeriodic ? "Checked" : ""
	Gui, MonitorOff:Add, CheckBox, % "vg_isMoffPeriodic " optchecked, % "Periodically turn &off screen?"

;	optchecked := g_isMoffPeriodicOnLockScreen ? "Checked" : ""
;	Gui, MonitorOff:Add, CheckBox, % "vg_isMoffPeriodicOnLockScreen " optchecked
;		, % "P&eriodically turn off only when screen is locked(by [Lock Now] button)?"
	; [2016-02-19] This has very vague semantic and I actually never use it in the past year, so comment it out.
	
	Gui, MonitorOff:Add, Text, Section , % "Every ? &seconds"
	Gui, MonitorOff:Add, Edit, vg_MoffCheckPeriod ys x+m, % g_MoffCheckPeriod 
		; ys: let the editbox at the same row as the static text
	
	Gui, MonitorOff:Add, Button, default section, &Lock Now  
		; The label MonitorOffButtonLockNow (if it exists) will be run when the button is pressed.
	Gui, MonitorOff:Add, Button, ys x+m , Cancel  ; trigger MonitorOffButtonCancel
	Gui, MonitorOff:Add, Button, ys x+m vg_MoffPause, % " &Pause "   ; Pause the countdown

	Gui, MonitorOff:Show, , % "Power saving your monitor"
	WinSet, AlwaysOnTop, On, ahk_id %HwndMonitorOff%
}

MonitorOffGuiClose:
MonitorOffGuiEscape:
MonitorOffButtonCancel:
	; g_isScreenLocked_byMoff := false ; not neccessary
	mo_Cleanup()
	return


MonitorOffButtonLockNow:
	mo_OnPressLockNowButton()
	return

mo_OnPressLockNowButton()
{
	; Now reset the monitor-off countdown timer to 3 seconds so that 
	; the user can be sure(see) the screen has been locked before the monitor really turns off.
	g_MoffCountdown := 3
	mo_CountingDown()

	DllCall("user32.dll\LockWorkStation") 
		; This really locks the screen, like Win+L (but not turning off monitor immediately)

	g_isScreenLocked_byMoff := true
}

mo_InitCountDown() ; mo: monitor-off
{
	; pending: Clear resource? may be not necessary
	mo_CreateMonitorOffDlg()
	g_MoffCountdown := g_monitor_off_countdown_init
	
	mo_CountingDown()
	
}

moTimer_CountingDown:
	mo_CountingDown()
	return

mo_CountingDown() ; as mo_TimerCountdown callback
{
	if(g_isScreenLocked_byMoff and not mo_IsScreenLocked())
	{	
		; User has just unlock the screen from locked-state, 
		; so we should now stop the monitor-off timer.
		SetTimer, moTimer_CheckAgain, Off
		g_isScreenLocked_byMoff := false
		mo_Cleanup()
		return
	}

	if(g_MoffCountdown>0)
	{
		;PlaySoundRightClick() ;debug
		
		; Update dlg countdown text
		GuiControl, MonitorOff:, g_MoffCountdown, %g_MoffCountdown%
		g_MoffCountdown -= 1
		SetTimer, moTimer_CountingDown, -1000
		return
	}
	else
	{
		mo_CountdownDue()
	}
}

mo_Cleanup()
{
	; Note: Cleanup almost everything except g_isScreenLocked_byMoff 
	
	SetTimer, moTimer_CheckAgain, Off

	SetTimer, moTimer_CountingDown, Off
	g_MoffCountdown := 0
	Gui, MonitorOff:Destroy
;	s_isLaunched := false  ; not necessary, right?
}

mo_CountdownDue()
{
	Gui, MonitorOff:Submit ; update g_isMoffPeriodic etc
	mo_Cleanup()
	
	; Launch periodic-check timer if requested.
	if( g_isMoffPeriodic or (g_isMoffPeriodicOnLockScreen and g_isScreenLocked_byMoff) )
	{
		SetTimer, moTimer_CheckAgain, % -1000*g_MoffCheckPeriod
	}
	else 
	{
		SetTimer, moTimer_CheckAgain, Off
	}
	
	mo_TurnMonitorOff()
	; Now in idle state.	
}

mo_isMonitorOffAgain()
{
	isAgain := false ; assume false first
	if(g_isMoffPeriodic)
		return true
	
	if(g_isMoffPeriodicOnLockScreen and g_isScreenLocked_byMoff)
	{
		if(mo_IsScreenLocked())
			return true
		else
			g_isScreenLocked_byMoff := false
	}
	
	return false
}

moTimer_CheckAgain:
	mo_CheckAgain()
	return

mo_CheckAgain()
{
	; Determine whether we should init another countdown.
	isAgain := mo_isMonitorOffAgain()
	if(isAgain) {
		mo_InitCountDown()
	}
	else {
		SetTimer, moTimer_CheckAgain, Off
	}
}

MonitorOffButtonPause:
	mo_DoButtonPause()
	return

mo_DoButtonPause()
{
	if(not g_isMoffPaused)
	{
		; clicking the "pause" button the first time
		g_isMoffPaused := true
		GuiControl, MonitorOff:, g_MoffCountdown, % "Paused"
		SetTimer, moTimer_CountingDown, Off
		
		GuiControl, MonitorOff:, g_MoffPause, % "Cal &PPI"
			; Good the new hot-letter C (because of &C) is active as soon as you set button text.
	}
	else
	{
		; clicking the "pause" button a second time
		CalPPI_CreateGui()
		mo_Cleanup() ; Remove the monitor-off dialog
	}
	
}


; =======================================================================

CalPPI_CalPhysicalParams(w, h, inch)
{
	SetFormat, float, 0.8

	cm_diagonal := inch * g_cm_per_inch
	px_diagonal := sqrt(w*w+h*h) ; hypothetical
	w_fraction := w/px_diagonal
	h_fraction := h/px_diagonal
	cm_width := cm_diagonal*w_fraction
	cm_height := cm_diagonal*h_fraction
	
	mm_dotsize := cm_width*10 / w ;mm: millimeter
	retobj := {"cm_w":cm_width, "cm_h":cm_height, "cm_d":cm_diagonal, "mm_dot":mm_dotsize}
	return retobj
}

CalPPI_CreateGui()
{
	Gui, CalPPI:Destroy ; destroy old
	Gui, CalPPI:+Hwndg_HwndCalppi ; Gui hwnd generated in g_HwndCalppi
	Gui, CalPPI:Font, s9 cBlack, Tahoma

	Gui, CalPPI:Add, Text, Section, % "&Choose a predefined model:"
	default_sel := g_CalppiDropboxSel>0 ? ("Choose" g_CalppiDropboxSel) : ""
	Gui, CalPPI:Add, DropDownList
		, % "ys-2 w200 vg_idxMonitorChoice glb_CalPPI_OnChangeDropdownSelection AltSubmit " default_sel
		, % g_CalppiListlist
	;
	Gui, CalPPI:Add, Text, xm, % "My monitor has phys&ical parameters:"
	Gui, CalPPI:Add, Edit, Section vg_CalppiInch Center w50
	Gui, CalPPI:Add, Text, ys+3, % "inch,"
	Gui, CalPPI:Add, Edit, ys vg_CalppiXPixels Center w50
	Gui, CalPPI:Add, Text, ys+3, % "x"
	Gui, CalPPI:Add, Edit, ys vg_CalppiYPixels Center w50
	;
	Gui, CalPPI:Add, Button, ys-2 Default glb_CalPPIButtonUpdate , % "&Update" 

	Gui, CalPPI:Font, Bold
	Gui, CalPPI:Add, Text, xm w50 Section, % "Diagonal:"
	Gui, CalPPI:Add, Edit, ys-2 w64 ReadOnly vg_cm_Diagonal ; text fill later
	Gui, CalPPI:Add, Text, ys w40 Right, % "Width:"
	Gui, CalPPI:Add, Edit, ys-2 w64 ReadOnly vg_cm_Width ; text fill later
	Gui, CalPPI:Add, Text, ys w40 Right, % "Height:"
	Gui, CalPPI:Add, Edit, ys-2 w64 ReadOnly vg_cm_Height ; text fill later
	Gui, CalPPI:Font, Norm
	
	Gui, CalPPI:Add, Text, xm w50 Section, % "Dot size:"
	Gui, CalPPI:Add, Edit, ys-2 w64 ReadOnly vg_mm_dotsize ; text fill later
	Gui, CalPPI:Add, Text, ys w66 Right, % "Monitor PPI"
	Gui, CalPPI:Add, Edit, ys-2 w38 ReadOnly vg_monitor_ppi ; text fill later
	Gui, CalPPI:Add, Text, ys, % "(pixels per inch)"
	
	Gui, CalPPI:Add, Button, xm vg_btnCalppiAdvanced glb_CalPPIDoAdvanced, % "&Advanced >>>"
	
	Gui, CalPPI:Show, , % "Calculate Monitor PPI"

	model := gar_models[g_CalppiDropboxSel]
	GuiControl, CalPPI:, g_CalppiInch, % model.inch
	GuiControl, CalPPI:, g_CalppiXPixels, % model.w
	GuiControl, CalPPI:, g_CalppiYPixels, % model.h
	
	CalPPI_UpdateCustomInput()
}

lb_CalPPI_OnChangeDropdownSelection:
	CalPPI_OnChangeDropdownSelection()
	return

CalPPI_OnChangeDropdownSelection()
{
	GuiControlGet, g_idxMonitorChoice ; Know the current choice of the dropdown-list
	model := gar_models[g_idxMonitorChoice]
;	tooltip, hhhh %g_idxMonitorChoice% ; //ok
	CalPPI_RefreshMonitorParams(model)
}

CalPPI_RefreshMonitorParams(model)
{
	GuiControl, CalPPI:, g_CalppiXPixels, % model.w
	GuiControl, CalPPI:, g_CalppiYPixels, % model.h
	GuiControl, CalPPI:, g_CalppiInch, % model.inch

	physical := CalPPI_CalPhysicalParams(model.w, model.h, model.inch)
		; .cm_w .cm_h .mm_dot .cm_d
	
	; When displaying, use only 2 decimal precision
	SetFormat, float, 0.2
	cm_d := physical.cm_d + 0
	cm_w := physical.cm_w + 0
	cm_h := physical.cm_h + 0

	SetFormat, float, 0.3
	mm_dot := physical.mm_dot + 0

	; A note: calculating input should use 8-level precision value(i.e, use physical.cm_w instead of cm_w)
	mm_dotsize_logix := physical.cm_w*10/g_CalppiLogicalResX
	mm_dotsize_logiy := physical.cm_h*10/g_CalppiLogicalResY
	
	SetFormat, float, 0
	ppi := 25.4/physical.mm_dot ; pixel per inch
	ppi_logix := 25.4/(physical.cm_w*10/g_CalppiLogicalResX)
	ppi_logiy := 25.4/(physical.cm_h*10/g_CalppiLogicalResY)

	GuiControl, CalPPI:, g_cm_Diagonal, % cm_d "cm"
	GuiControl, CalPPI:, g_cm_Width, % cm_w "cm"
	GuiControl, CalPPI:, g_cm_Height, % cm_h "cm"
	GuiControl, CalPPI:, g_mm_dotsize, % mm_dot "mm"
	GuiControl, CalPPI:, g_monitor_ppi, % ppi
	;
	GuiControl, CalPPI:, g_mm_dotsize_LogiX, % mm_dotsize_logix "mm"
	GuiControl, CalPPI:, g_mm_dotsize_LogiY, % mm_dotsize_logiy "mm"
	GuiControl, CalPPI:, g_ppi_LogiX, % ppi_logix
	GuiControl, CalPPI:, g_ppi_LogiY, % ppi_logiy
}

lb_CalPPIButtonUpdate:
	CalPPI_UpdateCustomInput()
	return

CalPPI_UpdateCustomInput()
{
	; MEMO: To try: Can do it with Gui, Submit, NoHide
	GuiControlGet, g_CalppiInch, CalPPI:
	GuiControlGet, g_CalppiXPixels, CalPPI:
	GuiControlGet, g_CalppiYPixels, CalPPI:
	;
	GuiControlGet, g_CalppiLogicalResX, CalPPI:
	GuiControlGet, g_CalppiLogicalResY, CalPPI:
	
	model := {"w":g_CalppiXPixels, "h":g_CalppiYPixels, "inch":g_CalppiInch}
	CalPPI_RefreshMonitorParams(model)
}

CalPPIGuiEscape:
	Gui, CalPPI:Destroy
	return

lb_CalPPIDoAdvanced:
	CalPPI_DoAdvanced()
	return

CalPPI_DoAdvanced()
{
	GuiControl, Hide, g_btnCalppiAdvanced
	CalPPI_UpdateCustomInput() ; let g_CalppiXPixels, g_CalppiYPixels gets NEW user value

	; Add more custom fields ...
	
	Gui, CalPPI:Add, Text, xm Section, % "In case your logical screen &resolution is"
	Gui, CalPPI:Add, Edit, ys-2 w44 vg_CalppiLogicalResX Center, % g_CalppiXPixels
	Gui, CalPPI:Add, Text, ys, % "x"
	Gui, CalPPI:Add, Edit, ys-2 w44 vg_CalppiLogicalResY Center, % g_CalppiYPixels
	;
	Gui, CalPPI:Add, Button, xm Section glb_CalPPIButtonUpdate, % "&Re-calculate logical PPI (or just press Enter)"
	Gui, CalPPI:Add, Text, xm, % "Logical dot size and PPI:"
	;
	Gui, CalPPI:Add, Text, xm w60 Section, % "X dot size:"
	Gui, CalPPI:Add, Edit, ys-2 w64 ReadOnly vg_mm_dotsize_LogiX ; text fill later
	Gui, CalPPI:Add, Text, ys w46 Right, % "X PPI:"
	Gui, CalPPI:Add, Edit, ys-2 w38 ReadOnly vg_ppi_LogiX ; text fill later
	;
	Gui, CalPPI:Add, Text, xm w60 Section, % "Y dot size:"
	Gui, CalPPI:Add, Edit, ys-2 w64 ReadOnly vg_mm_dotsize_LogiY ; text fill later
	Gui, CalPPI:Add, Text, ys w46 Right, % "Y PPI:"
	Gui, CalPPI:Add, Edit, ys-2 w38 ReadOnly vg_ppi_LogiY ; text fill later
	
	GuiControl, Focus, g_CalppiLogicalResX
	Send ^a ; let the text in g_CalppiLogicalResX editbox select for easy user re-input.

	CalPPI_UpdateCustomInput()
	
	Gui, CalPPI:Show, xCenter yCenter AutoSize ; "AutoSize" make the dialog auto-extend to fit all new controls
}

; =======================================================================

winshell_GetListViewHeaderText(hwndListview)
{
	; Return an array, each element is one header text
	; Thanks to: https://www.autohotkey.com/board/topic/59420-solved-read-listview-column-header-text/
	; [2023-05-17] Chj updates it to support HWND from both x64 & x86 process.

	Headers := []
	LVM_GETHEADER := 0x101f
	hwndHeader := dev_SendMessage(hwndListview, LVM_GETHEADER, 0, 0)
	if(hwndHeader==0) {
    	Amdbg_Lv0p(A_ThisFunc, Format("LVM_GETHEADER for (0x{:08X}) error, probably invalid HWND value input.", hwndListview))
    	return ""
	}
	
	MaxName := 100     ; header text max length
	MaxName2x := MaxName*2
	Delimiter := "`n"  ; 

	PROCESS_VM_OPERATION := 0x8, PROCESS_VM_READ := 0x10
	PROCESS_VM_WRITE := 0x20,    PROCESS_QUERY_INFORMATION := 0x400
	MEM_COMMIT := 0x1000
	MEM_DECOMMIT := 0x4000,      PAGE_READWRITE = 0x4
	HDI_TEXT := 0x2,             HDM_GETITEMCOUNT := 0x1200
	HDM_GETITEMA := 0x1203
	HDM_GETITEMW := 0x120B
	
	threadid := DllCall("GetWindowThreadProcessId", "uint", hwndHeader
	                                  , "uint *", PID)
	if(threadid==0) {
    	Amdbg_Lv0p(A_ThisFunc, Format("For a header-control, GetWindowThreadProcessId(hwnd={}) error.", hwndHeader))
    	return
	}

	hProcess := DllCall("OpenProcess"
		, "uint", PROCESS_VM_READ | PROCESS_VM_WRITE | PROCESS_VM_OPERATION | PROCESS_QUERY_INFORMATION
	    , "int", FALSE
	    , "uint", PID)
	If (hProcess==0) {
    	Amdbg_Lv0p(A_ThisFunc, Format("OpenProcess(pid={}) error.", PID))
    	return
	}

	is32bit_tgt := dev_IsHe32bitProcess(hProcess)
	HDITEM_size :=       is32bit_tgt ? 48 : 72 ; sizeof(HDITEM)
	offset_cchTextMax := is32bit_tgt ? 16 : 24

	VarSetCapacity(Buf, MaxName2x, 0)  
	VarSetCapacity(hdi, HDITEM_size, 0)

	; Allocate HDITEM struct
	phdi := DllCall("VirtualAllocEx", "Ptr", hProcess
	                                , "Ptr", 0
	                                , "uint", HDITEM_size + MaxName2x
	                                , "uint", MEM_COMMIT
	                                , "uint", PAGE_READWRITE)
	if (phdi = 0) {
		Amdbg_Lv0p(A_ThisFunc, Format("VirtualAllocEx() error."))
		Goto, Close_20230517
	}

	NumPut(HDI_TEXT, hdi, 0, "uint")                 ; set hdi.mask=HDI_TEXT
	NumPut(phdi+HDITEM_size, hdi, 8, "Ptr")          ; set hdi.pszText 
	NumPut(MaxName, hdi, offset_cchTextMax, "uint")  ; set hdi.cchTextMax

	succ := dev_WriteRemoteBuffer(hProcess, phdi, hdi, HDITEM_size)
	If (not succ) {
		Amdbg_Lv0p(A_ThisFunc, Format("WriteProcessMemory() error."))
		Goto, Free_20230517
	}

	Count := dev_SendMessage(hwndHeader, HDM_GETITEMCOUNT, 0, 0)
	If (Count <= 0) {
		Amdbg_Lv0p(A_ThisFunc, Format("SendMessage() querying HDM_GETITEMCOUNT error. Return={}", Count))
		Goto, Free_20230517
	}

	Loop, % Count
	{
		dev_SendMessage(hwndHeader, HDM_GETITEMW, A_Index - 1, phdi)

		succ := dev_ReadRemoteBuffer(hProcess, phdi+HDITEM_size, Buf, MaxName2x)
		If (not succ) {
	  		Amdbg_Lv0p(A_ThisFunc, Format("ReadProcessMemory() error."))
	  		Goto, Free_20230517
		}

		VarSetCapacity(Buf, -1)  ; finish the string
		Headers.Push(Buf)
	}

Free_20230517:
	DllCall("VirtualFreeEx", "Ptr", hProcess
	                    , "Ptr", phdi
	                    , "uint", HDITEM_size + MaxName2x
	                    , "uint", MEM_DECOMMIT)

Close_20230517:
	DllCall("CloseHandle", "uint", hProcess)

  Return Headers
}

winshell_GrabControlTextUnderMouse(is_silent_return:=false)
{
	MouseGetPos, x, y, tophwnd, classnn
	ControlGetPos, x, y, w, h, %classnn%, ahk_id %tophwnd%
	ctlhwnd := dev_GetHwndFromClassNN(classnn, "ahk_id " tophwnd)

	if(not classnn) {
		MsgBox, % "Cannot get child window classnn under mouse."
		return
	}
	
	otext := winshell_GrabControlText(ctlhwnd)

	if(is_silent_return)
		return otext

	if(strlen(otext)>0)
	{
		textlen := strlen(otext)
		Clipboard := otext
		ClipWait, 1.0
		
		lines := StrCountLines(otext)
		if(lines>1) {
			color := "88eeff" ; cyan
			prompt_lines := " (" lines " lines)"
		}
		else
			color := "ffe088" ; orange
		
		DoHilightRectInTopwin("ahk_id " tophwnd, x,y,w,h, 500, color)
		
		MsgBox, % textlen " chars grabbed" prompt_lines ", in clipboard.`n`nClassnn=" classnn
	}
	else
	{
		DoHilightRectInTopwin("ahk_id " tophwnd, x,y,w,h, 500, "ff8888") ; red 
		
		if(warnmsg=="")
			warnmsg := "No text under mouse grabbed.`n`nClassnn=" classnn
		
		dev_MsgBoxWarning(warnmsg)
	}
}

winshell_GrabControlText(ctlhwnd)
{
	; ctlhwnd refers to the UIC that we want to grab its text.

	MaxItems := 99999
	PromptItems := 999
	warnmsg := ""
	otext := ""

	WinGetClass, classnn , % "ahk_id " ctlhwnd

	; For ListView, we first check its item-count.
	; (ListBox does nnot support 'List')
	if(StrIsStartsWith(classnn, "SysListView32"))
	{
		itemcount := dev_ControlGet_byHwnd(ctlhwnd, "List", "Count")
		if(itemcount==0)
		{
			; Meet an empty ListView etc.
			warnmsg := "Listview has zero item."
		}
		else if(itemcount>0 and itemcount<=MaxItems)
		{
			if(itemcount>PromptItems)
				dev_TooltipAutoClear(Format("Grabbing {} items...", itemcount), 99000)
			
			otext := dev_ControlGet_byHwnd(ctlhwnd, "List")

			if(itemcount>PromptItems)
				dev_TooltipAutoClear(Format("Grabbing {} items done.", itemcount))
			
			; For ListView, we add Header-text at first line(to otext).
			arhdrtext := winshell_GetListViewHeaderText(ctlhwnd)
			if(arhdrtext and arhdrtext.Length()>0)
			{
				otext := dev_JoinStrings(arhdrtext, "`t")  "`r`n" otext
			}
		}
		else if(itemcount>MaxItems)
		{
			warnmsg := Format("ListView items more than {}, I cannot grab that many.", MaxItems)
			
			; -- Partial items grabbing has not been implemented.
		}
	}
	else
	{
		; For Listbox, Combobox, DropDownList, call ControlGet directly
		
		otext := dev_ControlGet_byHwnd(ctlhwnd, "List")
	}

	if(otext=="")
	{
		; then consider it simple control types, Buttons, Static, Edit etc
		
		otext := dev_ControlGetText_hwnd(ctlhwnd)
	}
	
	return otext
}

AppsKey & g:: winshell_GrabControlTextUnderMouse()
#!g:: winshell_GrabControlTextUnderMouse()



#SC046:: ; SC046 is ScrollLock, but writing ``ScrollLock`` somehow does not take effect.
	mo_InitCountDown()
return


; #!e:: CalPPI_CreateGui() ; for easy debug launch


;============================================================================
; My control move initiative
; Some dialog boxes from some applications exhibit very small controls, 
; small editbox, small listbox etc, for example, the Windows env-var setting dialog.
; These control layouts are very unfriendly when you want to record a bit more 
; information from a screen-shot. So I'd like to have a way to enlarge those 
; dialog boxes and enlarge/re-position the contained controls to make them
; present more information. And these hotkeys come to help.
;
; Prerequisite: Use Ctrl+Win+arrow to enlarge the dialogbox(the frame) a bit,
;   so to make room for the to-be-enlarged controls.
; Now: assuming you want to resize/re-position a listbox.
; Step 1: Turn off your NumLock.
; Step 2: Move mouse pointer above the the listbox. Press Ctrl+Win+5 to confirm
;   aiming at the listbox. On pressing this hotkey, you see a purple mask feedback.
; Step 3: 
;   Use Ctrl+Win+NumpadArrow to enlarge that listbox.
;   Use Ctrl+Win+Shift+NumpadArrow to shrink that listbox(in case you make it too big).
;   Use Alt+Win+NumpadArrow to move the listbox.
; Repeat from step 2 to aim at and move another control.
;============================================================================

^#NumpadClear:: ctlmove_AimControlUnderMouse() ; the same physical key as Numpad5 
#!NumpadClear:: ctlmove_AimControlUnderMouse() ; just an aux hotkey

#!NumpadLeft::  ctlmove_Relative(-1, 0)
#!NumpadRight:: ctlmove_Relative(1, 0)
#!NumpadUp::    ctlmove_Relative(0, -1)
#!NumpadDown::  ctlmove_Relative(0, 1)

^#NumpadUp::    ctlmove_Border("T", -1)
^#NumpadDown::  ctlmove_Border("B", 1)
^#NumpadLeft::  ctlmove_Border("L", -1)
^#NumpadRight:: ctlmove_Border("R", 1)
;
+^#NumpadUp::    ctlmove_Border("B", -1)
+^#NumpadDown::  ctlmove_Border("T", 1)
+^#NumpadLeft::  ctlmove_Border("R", -1)
+^#NumpadRight:: ctlmove_Border("L", 1)


ctlmove_AimControlUnderMouse()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	wintitle := "ahk_id " Awinid

	CoordMode, Mouse, Window
	MouseGetPos, mxWindow, myWindow, mouse_at_htopwin, classnn
	
;	dev_TooltipAutoClear("classNN=" classnn " mouse_at_htopwin=" mouse_at_htopwin, 15000)
	
	if(mouse_at_htopwin!=Awinid) 
	{
		; [2022-11-13] Check for a special case: If the window under mouse pointer 
		; is a combobox-dropdown, we increase its width. This copes with the 
		; "combobox dropdown width often too narrow" baffle.
		if(StrIsStartsWith(classnn, "ComboLBox"))
		{
			; mouse_at_htopwin will always be 0x10010 for "ComboLBox"
			
			wintitle := "ahk_id " mouse_at_htopwin
			ControlGetPos, x,y, w,h, %classnn%, %WinTitle%
			newwidth := w + g_ctlmove_unit
			
			hwndctl := dev_GetHwndFromClassNN(classnn, wintitle)
			
			ControlMove, %classnn%, %x%, %y%, %newwidth%, %h%, %wintitle%
			
			dev_TooltipAutoClear(Format("ComboLBox(0x{:08x}) at X,Y={},{} W,H={},{}. Now width increased to {}."
				,hwndctl , x,y, w,h, newwidth), 5000)
			
			; Set the two g_ vars so that we can later press (Shift+)Ctrl+Win+NumpadArrows to try to further 
			; increase/decrease its width/height. But weird: I can only see its height decreased but not increased.
			g_ctlmove_hwndtop := wintitle
			g_ctlmove_classnn := classnn

			; Don't call DoHilightRectInTopwin(), which would cause the dropdown window to vanish immediately.
			return
		}
		else
		{
			dev_TooltipAutoClear(Format("ctlmove_AimControlUnderMouse(): `n`n"
				. "Your mouse is not above an active window. I will not work. htopwin={} , classnn={}`n`n"
				. "But if you are hovering on a comboxbox dropdown, this may be a misreport and please try again."
				, mouse_at_htopwin, clasnn)
				, 9900)
			return
		}
	}
	
	ControlGetPos, x,y, w,h, %classnn%, %wintitle%

	g_ctlmove_hwndtop := wintitle
	g_ctlmove_classnn := classnn

	DoHilightRectInTopwin(wintitle, x, y, w, h, 500, "f8e8ff")
}

ctlmove_Relative(rx, ry)
{
	; Move current control by a relative rx, ry value. rx, ry can be positive or negative
	scale := 1

	ControlGetPos, x,y, w,h, %g_ctlmove_classnn%, %g_ctlmove_hwndtop%

	newx := x + rx*g_ctlmove_unit*scale
	newy := y + ry*g_ctlmove_unit*scale

	ControlMove, %g_ctlmove_classnn%, %newx%, %newy%, , , %g_ctlmove_hwndtop%
}

ctlmove_Border(whichb, direction)
{
	; whichb can be "L", "T", "R", "B" for Left, Top, Right, Bottom respectively
	; direction should be -1 or 1.
	; -1 makes smaller x,y value.
	;  1 makes bigger x,y value.
	scale := 1

	value := direction * g_ctlmove_unit * scale
	ControlGetPos, x,y, w,h, %g_ctlmove_classnn%, %g_ctlmove_hwndtop%
	
	if(whichb=="L") {
		x += value
		w -= value
	}
	if(whichb=="T") {
		y += value
		h -= value
	}
	if(whichb=="R") {
		w += value
	}
	if(whichb=="B") {
		h += value
	}
	ControlMove, %g_ctlmove_classnn%, %x%, %y%, %w%, %h%, %g_ctlmove_hwndtop%
}



winshell_SetDwmNcRendering(winid, on_or_off)
{
	DWMWA_NCRENDERING_POLICY := 2
	
	; enum DWMNCRENDERINGPOLICY
	DWMNCRP_DISABLED := 1
	DWMNCRP_ENABLED := 2
	set_value := on_or_off ? DWMNCRP_ENABLED : DWMNCRP_DISABLED
	
	ret := DllCall("DwmApi.dll\DwmSetWindowAttribute"
		, "Ptr", winid
		, "Uint", DWMWA_NCRENDERING_POLICY
		, "Uint*", set_value
		, "Uint", 4)
	
	if(ret==0)
	{
		info := Format("DwmSetWindowAttribute({}, DWMWA_NCRENDERING_POLICY, ...) turned {}"
			, winid
			, on_or_off ? "ON" : "OFF")
		dev_TooltipAutoClear(info, 5000)
	}
	else
	{
		dev_MsgBoxError("DwmSetWindowAttribute() execution error.")
	}
}

winshell_SetDwmNcRendering_ActiveWindow(on_or_off)
{
	Awinid := dev_ActivateLastSeenWindow()
	
	if(Awinid)
		winshell_SetDwmNcRendering(Awinid, on_or_off)
	else
		dev_MsgBoxInfo( "No active window can be found. Nothing to do." )
}

;==============================================================
; Daily Window operations
;==============================================================

winshell_WindowOp_Init()
{
	;
	; Define a set of AHK systray menu items:
	;

	; Define submenu item list:
	dev_MenuAddItem("winshell_menutext_WindowOp", "Check active window info", "dev_CheckActiveWindowInfo")
	;
	fn := Func("winshell_SetDwmNcRendering_ActiveWindow").Bind(false)
	dev_MenuAddItem("winshell_menutext_WindowOp", "Active-window DWM rendering off", fn)
	;
	fn := Func("winshell_SetDwmNcRendering_ActiveWindow").Bind(true)
	dev_MenuAddItem("winshell_menutext_WindowOp", "Active-window DWM rendering on", fn)

	; Attach above submenu to main menu
	dev_MenuAddSubmenu("TRAY", winshell_menutext_WindowOp, "winshell_menutext_WindowOp")
	
	; ...
	
	winshell_DefineUtilitiesMenu()
}
winshell_popup_WindowOpMenu()
{
	Menu, winshell_menutext_WindowOp, Show
}

winshell_AddOneUtilitiesMenu(menuitem_text, cmd_and_params)
{
	fnobj := Func("dev_RunCmd").Bind(cmd_and_params)
	dev_MenuAddItem(winshell.UtilityMenu, menuitem_text, fnobj)
}

winshell_AddOneSendTextMenu(menuitem_text, textlines)
{
	; textlines: 
	; * may be a string, each line separated by `n 
	; * or an array of strings, then after sending each line, a `n will be appended.
	
	fnobj := Func("dev_PasteTextViaClipboard").Bind(textlines)
	
	dev_MenuAddItem("submenu_PasteText", menuitem_text, fnobj)
	
	dev_MenuAddSubmenu(winshell.UtilityMenu, "Paste text >>", "submenu_PasteText")
	
}

winshell_AddOneAhkFunctionMenuItem(menuitem_text, funcname)
{
	dev_assert(dev_IsOneWord(funcname), "winshell_AddOneAhkFunctionMenuItem() gets an empty funcname.")

	fnobj := Func(funcname)

	dev_assert(IsObject(fnobj)
		, Format("ERROR in winshell_AddOneAhkFunctionMenuItem(): ""{}"" is not an existing function name.", funcname))

	dev_MenuAddItem("submenu_AhkFuncs"
		, Format("{}`t{}( )", menuitem_text, funcname)
		, fnobj)
	
	dev_MenuAddSubmenu(winshell.UtilityMenu, "AHK Functions >>", "submenu_AhkFuncs")
}

winshell_DefineUtilitiesMenu()
{
	winshell_AddOneUtilitiesMenu("Network/WiFi Systray Panel"
		, dev_IsWin10() ? "explorer.exe ms-availablenetworks:" : "rundll32.exe van.dll`,RunVAN")

	winshell_AddOneUtilitiesMenu("Network interface list (ncpa.cpl)", "ncpa.cpl")
	
	winshell_AddOneUtilitiesMenu("Traditional System properties (sysdm.cpl)", "sysdm.cpl")
	
	dev_MenuAddItem(winshell.UtilityMenu, "Edit Env-vars dialogbox", "winshell_BringUpEnvvarEditor")
	
	winshell_AddOneUtilitiesMenu("Sound property", "control mmsys.cpl sounds")
	
	winshell_AddOneUtilitiesMenu("Eject hardware dialog", "rundll32.exe shell32.dll`,Control_RunDLL hotplug.dll")
}



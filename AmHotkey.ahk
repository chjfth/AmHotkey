; AmHotkey is the Modularized Autohotkey framework, created by Jimm Chen since 2010,
; based on the fantastic Autohotkey script engine.
;
; Tested with Autohotkey v1.1.32.00

#InstallKeybdHook

#Include *i custom_env.ahk ; optional 

global NOERROR_0 := 0

global g_winmove_unit := 50 ; window move unit small
global g_winmove_scale := 5 ; window move 5x larger step if you tap LCtrl just before doing win move

global g_saved_xMouseScreen := 0
global g_saved_yMouseScreen := 0

;g_NumpadKeyMouse = 1
	; Use Numpad keys as mouse navigator.
	; Win+NumLock will toggle this behavior.

global g_MouseNudgeUnit = 10
global g_MouseNudgeUnitAM = 10 ; AM: Application Match
global g_MouseNudgeTitleAM = "Non-existing title"
	; Write ``global`` so that these vars can be referenced in later functions' body.

global g_AmMute := false


global g_RCtrl_WinMoveScale_graceticks = 3000



global g_func_IsTypingZhongwen := "IsTypingZhongwen_PinyinJiaJia"
global g_func_IMEToggleZhonwen := "ToggleZhongwenStatus_PinyinJiaJia"
	; User can override these two function pointers to suit their own IME(Input MEthod).


;;;;;;;;;;;;;;;;;;;;;;;;;; ^^^ user configurable globals end ^^^ ;;;;;;;;;;;;;;;;;;;;;;;;;;


global g_UntitledNotpad := "Untitled - Notepad"

global gtc_last_RCtrl = 0 ; Last RCtrl release tickcount
global Eme_Fn_idle = true ; no need to configure

global g_clipboard_cache
global g_pathop_last_numop = 14

RegRead, g_CmdCompletionChar, HKEY_CURRENT_USER, Software\Microsoft\Command Processor, CompletionChar

global g_winx, g_winy, g_winwidth=-1, g_winheight
	; These four vars tells previous window position before a window-size change, 
	; so that user can undo the change(if inadvertently changed an undesired window)
	; g_winwidth = -1 means "these values are invalid now".

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Cope with auto-exec section in sub-ahk. Thanks to:
; http://www.autohotkey.com/board/topic/9890-multiple-auto-execute-sections/ with IsLabel() fix

global g_arAutoexecLabels := []
global g_dictAutoexecExistingFname := {} ; for checking duplicate
global g_customize_ahk := "customize.ahk"

; Constant used in dev_MsgBoxYesNo() etc.
global msgboxoption_Ok := 0
global msgboxoption_OkCancel := 1
global msgboxoption_YesNo := 4
global msgboxoption_YesNoCancel := 3
global msgboxoption_IconStop := 16
global msgboxoption_IconQuestion := 32
global msgboxoption_IconExclamation := 48
global msgboxoption_IconInfo := 64
global msgboxoption_2nddefault := 256
global msgboxoption_3rddefault := 512
global msgboxoption_SystemModal := 0x1000
global msgboxoption_TaskModal := 0x2000
global msgboxoption_Topmost := 0x40000

global g_devGuiAutoResizeDict := {}

global g_amstrMute := "AM: Mute clicking sound"

global g_DefineHotkeyLogfile := "DefineHotkeys.log"

global g_tmpMonitorsLayout := {}

;==========;==========;==========;==========;==========;==========;==========;==========;
; All global vars should be defined ABOVE this line, otherwise, they will be null.
;==========;==========;==========;==========;==========;==========;==========;==========;

AmDoInit()
dev_DefineHotkeyLogClear()

Amhotkey_LoadMoreIncludes()

return 

;################################################################################################ 
;################################### Global-exec section ENDS ################################### 
;################################################################################################ 

AmDoInit()
{
	; [2022-11-02] Move this to chjmisc.ahk, other people may not need it.
;	Menu, tray, add  ; Creates a separator line.
;	SystrayMenu_Add_MuteClicking()
}

; ########## Some debugging hotkeys first ##########

; 2010-03-13 Win+Alt+R to reload current script
#!r:: Reload

; Win+Alt+C : Check Window class
!#c:: dev_CheckActiveWindowInfo()
dev_CheckActiveWindowInfo()
{
	tooltip
	Awinid := dev_ActivateLastSeenWindow()
	if(!Awinid)
	{
		dev_MsgBoxInfo( "No active window can be found. Use hotkey Win+Alt+C instead." )
	}
	dev_CheckWindowInfo(Awinid)
}

dev_ActivateLastSeenWindow()
{
	; Usage scenario: 
	; When a Systray Autohotkey menu item wants to operate current active window, 
	; there may not be an active window(``WinGet, Awinid, ID, A`` reports Awinid==null),
	; so we can use this function to bring up the last seen active window.

	WinGet, Awinid, ID, A ; cache active window unique id
	
	if(!Awinid)
	{
		SendInput !{TAB} 
		
		Loop, 10
		{
			WinGet, Awinid, ID, A
			if(Awinid)
				break
			Sleep, 100
		}
	}
	
	return Awinid
}

dev_CheckWindowInfo(hwnd)
{
	WinGetClass, class, ahk_id %hwnd%
	WinGetTitle, title, ahk_id %hwnd%
	WinGetPos, x,y,w,h, ahk_id %hwnd%
	WinGet, pid, PID, ahk_id %hwnd%
	WinGet, exepath, ProcessPath, ahk_id %hwnd%
	ControlGetFocus, focusNN, ahk_id %hwnd%
	ControlGet, focus_hctrl, HWND, , %focusNN%, ahk_id %hwnd%
	
	x_end_ := x + w
	y_end_ := y + h
	
	caRect := dev_WinGetClientAreaPos(hwnd)
	; if (caRect==null) ...
	;	MsgBox, % "caRect==null"
	caLeft := caRect.Left
	caTop := caRect.top
	caRight := caRect.right
	caBottom := caRect.bottom
	caWidth := caRight - caLeft
	caHeight := caBottom - caTop
	
	CoordMode, Mouse, Screen
	MouseGetPos, mxScreen, myScreen
	
	CoordMode, Mouse, Window
	MouseGetPos, mxWindow, myWindow, tophwnd_undermouse, classnn
	if(classnn)
		ControlGet, hctrl_undermouse, HWND, , %classnn%, ahk_id %tophwnd_undermouse%
	else
		classnn := ""
	
	info =
	(
The Active window class is "%class%" (Hwnd=%hwnd%)
Title is "%title%"
Position  : X ( %x% ~ %x_end_% ), Y ( %y% ~ %y_end_% ), size ( %w% x %h% )

Client area: X ( %caLeft% ~ %caRight% ), Y ( %caTop% ~ %caBottom% ), size ( %caWidth% x %caHeight% )

Current focused classnn: %focusNN%
Current focused hctrl: ahk_id=%focus_hctrl%

Process ID: %pid%
Process path: %exepath%

Mouse position: In-window: (%mxWindow%,%myWindow%)  `; In-screen: (%mxScreen%,%myScreen%)

ClassNN under mouse is "%classnn%"
hwndCtrl under mouse is "%hctrl_undermouse%"
	)
	MsgBox, % msgboxoption_IconInfo, , %info%
}


dev_assert(torf)
{
	if(torf!=true)
	{
		dev_MsgBoxError(dev_getCallStack(), "AHK Assertion Fail! Stacktrace >>>")
	}
}

SystrayMenu_Add_MuteClicking()
{
	Menu, TRAY, add, %g_amstrMute%, dev_AmMute  ; Creates a new menu item.
}

dev_AmMute()
{
	g_AmMute := !g_AmMute
	if(g_AmMute) {
		Menu, TRAY, Check, %g_amstrMute%
	}
	else {
		Menu, TRAY, UnCheck, %g_amstrMute%
	}
}

GetFirstNoncommentLine(ahkfname)
{
	Loop, read, %ahkfname%
	{
		if(Trim(A_LoopReadLine)=="")
			continue ; this is a blank line
		else if( A_LoopReadLine ~= "^\s*(?=;);+" ) ; \s space or tab
		{	
			continue ; this is a comment line 
		}
		else
			return A_LoopReadLine
	}
	return ""
}

AddAutoExecAhk(ahkdir, filename)
{
	ahkfname := ahkdir . "\" . filename

	; check duplicate
	if(g_dictAutoexecExistingFname.HasKey(ahkfname)) {
		return
	}

	; Check whether the first non comment line is in pattern AUTOEXEC_xxx:
	chkline := GetFirstNoncommentLine(ahkfname)
	
	foundpos := RegExMatch(chkline, "^(AUTOEXEC_[a-zA-Z0-9_.]+)\:", subpat)
	if( foundpos>0 )
	{
		g_arAutoexecLabels.Insert( {"filename":filename , "label":subpat1} )
		g_dictAutoexecExistingFname[ahkfname] := "yes"
	}
}

Amhotkey_LoadMoreIncludes()
{
	; "Call" auto-exec sections collected(for those ahks with AUTOEXEC_xxx: label at start of file)
	ScanAhkFilesForAutoexecLabel()
	CallAutoexecLabels()
}

ScanAhkFilesForAutoexecLabel()
{
	; Scan all ahk files in the same folder as the master ahk file.

	; some stock ahk first
	AddAutoExecAhk(A_ScriptDir , "keymouse.ahk")
	AddAutoExecAhk(A_ScriptDir , "quick-switch-app.ahk")
	
	Loop, %A_ScriptDir%\*.ahk
	{
		; Loop, %A_ScriptDir%\*.ahk ; this matches XXX.ahkx , XXX.ahky etc (AHK bug?)
		; so I have to filter it once more.
		
		if(not A_LoopFileName ~= ".ahk$" )
			continue

		if(A_LoopFileName==A_ScriptName)
			continue ; skip self
		
		
		if(A_LoopFileName==g_customize_ahk)
			continue ; leave this at end
			
		if(InStr(A_LoopFileName, " "))
			continue ; reject those with spaces in filename
		
		AddAutoExecAhk(A_ScriptDir, A_LoopFileName)
	}
	
	AddAutoExecAhk(A_ScriptDir, g_customize_ahk)
		; Load this at the final stage, because it is intended to override some 
		; global vars defined by other modules.
	
;	msgbox, % "g_arAutoexecLabels maxindex=" . g_arAutoexecLabels.MaxIndex()
}

CallAutoexecLabels()
{
	module_count := 0
	msglistmodules := ""
	
	for index, autolabel in g_arAutoexecLabels 
	{
		label_varname := autolabel.label

		if(IsLabel(label_varname)) 
		{
			module_count++
			msglistmodules .=  module_count . ". " . autolabel.filename . " [" . label_varname . "]`n"
			GoSub, %label_varname%
		}
		else
		{
			; This label_varname is not found, probably because its containing XXX.ahk 
			; is not included in _more_includes_.ahk .
		}
	}
	
	if(module_count==0) ; no modules loaded, probably _more_includes_.ahk not generated yet
	{
		srcfile := A_ScriptDir . "\" . "_more_includes_.ahk.sample"
		dstfile := A_ScriptDir . "\" . "_more_includes_.ahk"

	;	MsgBox, % Format("filecopy {} -- {}", srcfile, dstfile)
		
		FileCopy, %srcfile%, %dstfile%
		
		if(ErrorLevel)
		{
			dev_MsgBoxError(Format("Cannot find or generate ""{}"" . The program will exit.", dstfile))
			ExitApp, 4
		}
		
		; Generate customize.ahk from customize.ahk.sample as well
		
		dst_customize_ahk := A_ScriptDir "\customize.ahk"
		FileCopy, % A_ScriptDir "\customize.ahk.sample" , % dst_customize_ahk , 0 ; no overwrite
		if(!FileExist(dst_customize_ahk))
		{
			dev_MsgBoxWarning("Cannot create file: " dst_customize_ahk)
		}
		
		MsgBox, % msgboxoption_IconInfo, % "AmHotkey.ahk starts", 
(
This is the first time you run this script. 

You can edit 

    %dstfile% 

to customize what AHK modules to load into this program.

Click OK to continue.
)
		Reload
	}
	;
	MsgBox, 0x40, Autohotkey script loading info, 
(
%A_ScriptDir%\%A_ScriptName% has loaded the following modules:`n
%msglistmodules%
)

}


#!s:: Launch_AU3Spy()
Launch_AU3Spy()
{
	tooltip
	if not A_AhkPath {
		MsgBox, A_AhkPath is blank, so I don't know where to find AU3_Spy.exe
	}
	
	spypath := RegExReplace(A_AhkPath, "(.+)\\[^\\]+$", "$1\AU3_Spy.exe")
	Run, %spypath%, , UseErrorLevel
	if ErrorLevel {
		MsgBox, "%spypath%" launch failed!
	}
	else {
		winspy_class := "ahk_class AutoHotkeyGUI"
		WinWait, %winspy_class%
		WinActivate, %winspy_class%
		WinWaitActive, %winspy_class%
	}
}

dev_WinWaitActive_with_timeout(wintitle, wintext:="", timeout_sec:=1)
{
	WinWaitActive, %wintitle%, %wintext%, %timeout_sec%
	if not ErrorLevel
	{
		return true
	}
	else
	{
		return false
	}
}

dev_WinGetClientAreaPos(WinId)
{
	; https://www.autohotkey.com/boards/viewtopic.php?p=257561&sid=d2327857875a0de35c9281ab43c6a868#p257561
	
	VarSetCapacity(RECT, 16, 0)
	if !DllCall("user32\GetClientRect", Ptr,WinId, Ptr,&RECT)
		return null
	if !DllCall("user32\ClientToScreen", Ptr,WinId, Ptr,&RECT)
		return null
	
	Win_Client_X := NumGet(&RECT, 0, "Int")
	Win_Client_Y := NumGet(&RECT, 4, "Int")
	Win_Client_W := NumGet(&RECT, 8, "Int")
	Win_Client_H := NumGet(&RECT, 12, "Int")

	r := {}
	r.left := Win_Client_X
	r.right := Win_Client_X + Win_Client_W
	r.top := Win_Client_Y
	r.bottom := Win_Client_Y + Win_Client_H
	
	return r
}

Get_HCtrlFromClassNN(classnn, wintitle)
{
	ControlGet, hctrl, HWND, , %classnn%, %wintitle%
	return hctrl
}


!#f:: ; Try to set focus to the control beneath current mouse pointer.
	MouseGetPos, _mx, _my, hwnd, target_classnn
	ControlFocus, %target_classnn%, A ; [2015-02-10] Strange, without explicity A param, it will not succeed.
	if not ErrorLevel {
		tooltip, % "New focus @ #" . hwnd . " classnn=" . target_classnn
	} else {
		MsgBox, % "ControlFocus reports ErrorLevel = " . ErrorLevel
	}
return

Get_DPIScale()
{
	return A_ScreenDPI/96
}


FlashRectInActiveWindow(x, y, width, height) ; old test code
{
	speed = 10, sleep = 100
	tooltip, ☆ , % x, % y
	mousemove, % x , % y , 1
	sleep, %sleep%
	mousemove, % x, % y+height , %speed%
	sleep, %sleep%
	mousemove, % x+width, % y+height , %speed%
	sleep, %sleep%
	mousemove, % x+width, % y , %speed%
	sleep, %sleep%
	mousemove, % x, % y , %speed%

	tooltip, ★ , % x+width, % y+height 
}

HighlightRectInScreen(screenx, screeny, width, height, rgb:="8000FF", duration_msec:=2000) ; "8000FF"=purple
{
	Gui, hilightScreen:New
	Gui, hilightScreen:-Caption +ToolWindow ; so that it can be transparent
	Gui, hilightScreen:+HwndHRwnd ; generate variable HRwnd
	Gui, hilightScreen:Color, % rgb
	Gui, hilightScreen:Font, s8 c888888, Tahoma
	Gui, hilightScreen:Add, Text, , AHK Highlight
	;
	showopt := "X" . screenx . " Y" . screeny . " W" . width . " H" . height
	Gui, hilightScreen:Show, %showopt%
	WinSet, AlwaysOnTop, On, ahk_id %HRwnd%
	WinSet, Transparent, 160, ahk_id %HRwnd%
	;
	SetTimer, hilightScreenGuiEscape, -%duration_msec%
	return 

hilightScreenGuiClose:
hilightScreenGuiEscape:
;	tooltip timer...END (A_Gui=%A_Gui% A_GuiControl=%A_GuiControl%)
	Gui, hilightScreen:Destroy 
	return

}

HighlightRectInActiveWindow(hx, hy, hwidth, hheight, duration_msec:=2000) ; old code, use DoHilightRectInTopwin instead
{
	; hx, hy relative to current active window
	
	WinGetPos, Ax, Ay, Awidth, Aheight, A 

	Gui, hilightwin:New
	Gui, hilightwin:-Caption +ToolWindow ; so that it can be transparent
	Gui, hilightwin:+HwndHRwnd ; generate variable HRwnd
	Gui, hilightwin:Color, FFFF00
	Gui, hilightwin:Font, s8 c888888, Tahoma
	Gui, hilightwin:Add, Text, , AHK Highlight
	;
	screenx := Ax + hx
	screeny := Ay + hy
	showopt := "X" . screenx . " Y" . screeny . " W" . hwidth . " H" . hheight
	Gui, hilightwin:Show, %showopt%
	WinSet, AlwaysOnTop, On, ahk_id %HRwnd%
	WinSet, Transparent, 200, ahk_id %HRwnd%
	;
	SetTimer, hilightwinGuiEscape, -%duration_msec%
	return 

hilightwinGuiClose:
hilightwinGuiEscape:
;	tooltip timer...END (A_Gui=%A_Gui% A_GuiControl=%A_GuiControl%)
	Gui, hilightwin:Destroy 
	return
	
}

DoHilightRectInTopwin(wintitle, x, y, w, h, duration_msec:=1000, rgb:="FFE0BE")
{
	arRects := [ { "x":x, "y":y, "w":w, "h":h, "rgb":rgb, "notext":true} ]
	DoHilightBlocksInTopwin(wintitle, arRects, duration_msec)
}

not_used___DoHilightBlocksInTopwin_rs(wintitle, arRectStrs, msec_step:=1000)
{
	; arRects sample:
	;
	; arRects := [ "100,100,100,100", "200,200,200,100" ]
	
	arRects := array()
	for index, rectstr in arRectStrs
	{
		inputvar := arRectStrs[index]
		num := StrSplit(inputvar, ",")
		arRects.Insert( { "x":num[1] , "y":num[2] , "w":num[3] , "h":num[4] } )
	}
	DoHilightBlocksInTopwin(wintitle, arRects, msec_step)

}

DoHilightBlocksInTopwin(wintitle, arRects, msec_step:=1000)
{
	; arRects is an array; array element is a dict with member .x .y .w .h 

	WinGet, hwndBase, ID, %wintitle%

	static ccyellow := "FFFF00" , ccred := "FF8888" , ccmagenta := "FF00FF" ; cc: color code

	static hilictl := {}
	static s_hili_running := false
	if (s_hili_running) {
		tooltip, Another instance of DoHilightBlocksInTopwin is running.
		return
	}
	s_hili_running := true

	static s_name := ""
	global HiliText 
		; must be global, otherwise, second timer's will GuiControl will not update control text
		; The manual explicitly states this in "Functions -> Using Subroutines Within a Function"

	hilictl := {}
	hilictl.wintitle := wintitle
 	; hilictl.name := "hiname" ; optional
	hilictl.msec_step := msec_step
	hilictl.nextstep := 1

	hilictl.arsteps := arRects

	; hx, hy relative to current active window
	WinGetPos, Ax, Ay, Awidth, Aheight, A 

	Gui, hiliblock:New
	Gui, hiliblock:-Caption +ToolWindow ; so that it can be transparent
	Gui, hiliblock:+HwndHIwnd ; generate variable HIwnd (global or local? seems global)
;	Gui, hiliblock:Color, %ccyellow% ; set later
	Gui, hiliblock:Font, s8 c333333, Tahoma
	Gui, hiliblock:Add, Text, vHiliText, "any" ; text modified later
	
	
	hilictl.HIwnd := HIwnd
	hilictl.hwndBase := hwndBase
	
	GoSub, HiliStepTimer ; Starting the highlight!
	; Wait until all hilight done
	while (s_hili_running)
		sleep 100
	return
	

hiliblockGuiClose:
hiliblockGuiEscape:
;	tooltip, % "close " . hilictl.nextstep
HiliStepTimer:

	arsteps := hilictl.arsteps ; each step is an object containing xywh(4 members)
	thisstep := hilictl.nextstep
	hilictl.nextstep += 1
	maxsteps := arsteps.MaxIndex()
	thisrect := arsteps[thisstep]

	if(thisstep>maxsteps)
	{
		; kill timer
		SetTimer, HiliStepTimer, Off
		Gui, hiliblock:Destroy
		s_hili_running := false
		return
	}

	WinGetPos, xbase, ybase, wbase, hbase, % "ahk_id " hilictl.hwndBase

	boxcolor := thisrect.rgb ? thisrect.rgb : ccyellow
	halfw := 200, halfh := 100

	; Check Rect validity:
	is_goodwnd := true ; assume true
	;
	if(xbase=="" || ybase=="")
	{
		is_goodwnd := false
		; Will display a RED box at center of the main monitor warning the user
		x := A_ScreenWidth/2 - halfw
		y := A_ScreenHeight/2 - halfh
		w := halfw * 2
		h := halfh * 2
		
		boxtext := "Can not get valid HWND by AHK wintitle:`n`n" . hilictl.wintitle
			. "`n`nPress cancel to dismiss."
	}
	else if(thisrect.x=="" || thisrect.y=="" || thisrect.w=="" || thisrect.h=="")
	{
		is_goodwnd := false
		x := xbase
		y := ybase
		w := halfw * 2
		h := halfh * 2
		boxtext := "Invalid xywh input.`n`n" 
			. "x=" . thisrect.x . " y=" . thisrect.y . " w=" . thisrect.w . " h=" . thisrect.h
			. "`n`nPress cancel to dismiss."
	}
	else 
	{
		if(thisrect.w>0 && thisrect.h>0)
		{
			x := thisrect.x + xbase
			y := thisrect.y + ybase
			w := thisrect.w
			h := thisrect.h
		
			boxtext := "x=" . thisrect.x . " y=" . thisrect.y . "`n[w=" . thisrect.w . " h=" . thisrect.h . "]"
				; display x,y relative to the topmost window
		}
		else 
		{
			x := thisrect.x + xbase
			y := thisrect.y + ybase
			w := 200
			h := 200
			boxcolor := thisrect.rgb ? thisrect.rgb : ccmagenta
			boxtext := "Invisible! w=" . thisrect.w . " h=" . thisrect.h
		}

		if(maxsteps>1)
			boxtext := thisstep . "/" . maxsteps . ": " . boxtext
	}
	
	if(not is_goodwnd)
		boxcolor := thisrect.rgb ? thisrect.rgb : ccred
	
	if(thisrect.notext)
		boxtext := ""
	
	Gui, hiliblock:Color, %boxcolor%
	GuiControl, hiliblock:, HiliText, %boxtext%
	GuiControl, hiliblock:Move, HiliText, X0 Y0 w%w% h%h% ; this is relative to HIwnd

	Gui, hiliblock:Show, X0 Y0 W20 H10 ; init arbitrary small window 
		; Don't use %screen_xywh% in Gui,Show (its W,H means client area), so use WinMove .
	HIwnd := hilictl.HIwnd ; optional, because HIwnd has been a global
	WinMove, % "ahk_id " . HIwnd, 
		, % xbase+thisrect.x , ybase+thisrect.y, % w, % h
	WinSet, AlwaysOnTop, On, ahk_id %HIwnd% 

	if(is_goodwnd)
	{
		WinSet, Transparent, 188, ahk_id %HIwnd% ; set-transparent must be AFTER Gui,Show , no effect otherwise
		SetTimer, HiliStepTimer, % 0-hilictl.msec_step
	}
	else
	{
		WinSet, Transparent, 244, ahk_id %HIwnd%
		hilictl.nextstep := maxsteps+1 ; so that next callback will destroy the Gui
		SetTimer, HiliStepTimer, Off ; so user have to explicitly close the box (keyboard cancel)
	}	
	return
}

;##############################################################################
; Something with global effects
;##############################################################################

~RCtrl up:: ; [2015-02-06] moveWinRelative() requires this
	gtc_last_RCtrl := A_TickCount
;	Send {Blind}{RCtrl up}
return




;##############################################################################
;#################### Environment checking functions ##########################
;##############################################################################

IsWin5x()
{
	if A_OSVersion in WIN_2003,WIN_XP,WIN_2000
	{
	    return true
	}
	else
	{
		return false
	}
}

GetMonitorWorkArea(monidx)
{
	; monidx 1 means first monitor, 2 means second ...
;	SysGet, wa, Monitor, %monidx%
	SysGet, wa, MonitorWorkArea, %monidx% ; this exlcudes taskbar region
	if(waLeft!=None) 
	{
		return {"left":waLeft, "right":waRight, "top":waTop, "bottom":waBottom
			, "width":waRight-waLeft, "height":waBottom-waTop }
	}
	else
		return None
}

IsWinidActive(winid) ; Check against active window
{
	IfWinActive, ahk_id %winid%
	{
	    return true
	}
	return false
}

IsWinClassActive(winclass, wintext="") ; Check against active window
{
	IfWinActive, ahk_class %winclass%, %wintext%
	{
	    return true
	}
	return false
}

IsWinClassExist(winclass, wintext="") ; Check existing window
{
	IfWinExist, ahk_class %winclass%, %wintext%
	{
	    return true
	}
	return false
}


IsWinClassMatchRegex(regex) ; Check against active window class
{
	WinGetClass, class, A
	foundpos := RegExMatch(class, regex)
	if (foundpos>0)
		return true
	else 
		return false
}

IsWinTitleMatchRegex(regex) ; Check against active window
{
	WinGetTitle, title, A
	foundpos := RegExMatch(title, regex)
	if (foundpos>0)
		return true
	else 
		return false
}

dev_IsWin7SaveAsDialog()
{
	if(not IsWinClassActive("#32770"))
		return false
	
	if(IsWinTitleMatchRegex("另存为")
		or IsWinTitleMatchRegex("Save As") )
	{
		return true
	}
	else
		return false
}

Is_XY_in_Rect(x,y, xrect, yrect, wrect, hrect)
{
	if(x>=xrect and x<=xrect+wrect and y>yrect and y<yrect+hrect)
		return true
	else
		return false
}

Is_RectA_in_RectB(Ax, Ay, Aw, Ah, Bx, By, Bw, Bh, tolerance:=0)
{
	t := tolerance
	if(Ax>=(Bx-t) and Ay>=(By-t) and (Ax+Aw)<=(Bx+Bw+t) and (Ay+Ah)<=(By+Bh+t))
		return true
	else
		return false
}

GetActiveClassnnFromXY(x, y)
{
	; Providing X,Y inside the active window, return control classnn from that position
	
	if(x==None)
	{
		MsgBox, % "Error: GetActiveClassnnFromXY() null x"
		return 
	}
	if(y==None)
	{
		MsgBox, % "Error: GetActiveClassnnFromXY() null y"
		return 
	}
	
	MouseMove, %x%, %y%
	MouseGetPos,,,, classnn
	return classnn
}

IsDictEmpty(dict)
{	
	; A dict(dictionary) is an associative array.
	empty := true
	for k, v in dict {
		empty := false
		break
	}
	return empty
}

dev_GetDateTimeStrNow()
{
	FormatTime, dt, , % "yyyy-MM-dd.HH:mm:ss"
	return dt
}

dev_GetDateTimeStrCompact(sep:="_")
{
	FormatTime, dt, , % "yyyyMMdd" . sep .  "HHmmss"
	return dt
}


; [2015-02-07] The great dynamically hotkey defining function. (tested on AHK 1.1.13.01)
; BIG Thanks to: http://stackoverflow.com/a/17932358
; ... above is historical comment.
; ... [2020-03-15] Now we have more advanced dev_DefineHotkey, dev_UnDefineHotkey, 
;                  dev_DefineHotkeyWithCondition, dev_UnDefineHotkeyWithCondition .

dev_DefineHotkeyLogClear() 
{
	; [2020-03-15] Autohotkey 1.1.32.00 
	; If you need this log, please define `global g_isDefineHotkeyLog:=true` in custom_env.ahk .
	; Default is no log, bcz dev_WriteLogFile seems quit time consuming.
	if(g_isDefineHotkeyLog) {
		dev_WriteLogFile(g_DefineHotkeyLogfile, "AmHotkey reload at: " . dev_GetDateTimeStrNow() . "`n", false)
	} else {
		FileDelete, % g_DefineHotkeyLogfile
	}
}

dev_DefineHotkeyLogAppend(prefix, hk, fn_name)
{
	if(g_isDefineHotkeyLog) {
		str := Format("[{1}] {2}： '{3}' => '{4}'`n",dev_GetDateTimeStrNow(), prefix, hk, fn_name)
		dev_WriteLogFile(g_DefineHotkeyLogfile, str)
	}
}

dev_UnDefineHotkey(hk, fn_name)
{
	dev_DefineHotkeyLogAppend("dev_UnDefineHotkey", hk, fn_name)
	in_dev_DefineHotkey(false, hk, fn_name, 0)
}

dev_DefineHotkey(hk, fn_name, args*) 
{
	dev_DefineHotkeyLogAppend("dev_DefineHotkey", hk, fn_name)
	in_dev_DefineHotkey(true, hk, fn_name, args)
}

in_dev_DefineHotkey(is_on, hk_userform, fn_name, args) ; will define global hotkey
{
	; Define or Undefine a hotkey, much more powerful than the `Hotkey` keyword.
	;
	; hk_userform : the hotkey name recognized by AutoHotkey.
	; fn_name     : the function name string, like "DoMyWork", DoMyWork() is defined somewhere else.
	;
	; Data structure example:
	; funs["F1"][fn_name]         => another object
	; funs["F1"][fn_name].fn_name => name of the function, a string
	; funs["F1"][fn_name].fn      => Function object for the hotkey
	; funs["F1"][fn_name].pr      => function parameters for the .fn function

	static funs := {}

;	dev_WriteLogFile("dev_DefineHotkey.txt", fn_name . "`n") ; debug
	
	if(!fn_name) {
		dev_MsgBoxError("Error: dev_DefineHotkey() pass in fn_name=null !")
		return
	}
	
	hk := hk_userform
	; 
	if(StrIsStartsWith(hk_userform, "~")) {
		; We need to strip off the "~" because later A_ThisHotkey *sometimes* does not contain that "~".
		hk := SubStr(hk_userform, 2)
	}
	
	if(is_on)
	{
		if(not funs[hk])
			funs[hk] := {}
		
		if(not funs[hk][fn_name])
			funs[hk][fn_name] := {}
		
		funs[hk][fn_name].fn_name := fn_name
		funs[hk][fn_name].fn := Func(fn_name)
		funs[hk][fn_name].pr := args

		Hotkey, If ; -- use the global context
		Hotkey, %hk_userform%, Hotkey_Handler_global, On
	}
	else 
	{
		funs[hk].Delete(fn_name)
		
		if( IsDictEmpty(funs[hk]) )
		{
			Hotkey, If ; -- use the global context
			Hotkey, %hk%, Off
		}
	}
	
	return

Hotkey_Handler_global:
;tooltip, % "Hotkey_Handler_global() [" . A_ThisHotkey . "] ........"

	ThisHotkey_fix := A_ThisHotkey
	;
	if(StrIsStartsWith(A_ThisHotkey, "~")) {
		; We need to strip off the "~" because later A_ThisHotkey *sometimes* does not contain that "~".
		ThisHotkey_fix := SubStr(A_ThisHotkey, 2)
	}

	dict_fnpr := funs[ThisHotkey_fix]
	if(dict_fnpr)
	{
		; Call each callbacks registered in dict_fnpr{}.
		for key, fnpr in dict_fnpr
		{
			fnpr.fn.(fnpr.pr*)
		}
	}
	else
	{
		tooltip, Bad! funs[%ThisHotkey_fix%] is null!!!!!
	}

	return
}


dev_UnDefineHotkeyWithCondition(hk, cond)
{
	dev_DefineHotkeyLogAppend(Format("dev_UnDefineHotkeyWithCondition({})",cond), hk, fn_name)
	dev_DefineHotkeyWithCondition(hk, cond, "")
}

dev_DefineHotkeyWithCondition(hk, cond, fn_name, args*)
{
	dev_DefineHotkeyLogAppend(Format("dev_DefineHotkeyWithCondition({})",cond), hk, fn_name)

	; fn_name  is a function name string, like "DoMyWork", DoMyWork() is defined somewhere else.
	; If fn_name=="", the previously registered hotkey *for the cond* is removed.
	;
	; cond is a function name string, like "Spc_IsActive".
	;
	; (Autohotkey 1.1.19.02 MEMO)
	; [[IMPORTANT]] User should already have an exact ``#If cond()`` block defined to use with dev_DefineHotkeyWithCondition().
	; Missing this step will *silently* fail the conditional-hotkey, OR, fail the global hotkey(random from the two).
	;
	; This step is easily ignored because there will be no ``Parameter #2 must match an existing #If expression``
	; error message on reloading the script. That error message can usually be seen when you write explicit 
	; ``Hotkey, If, somecond()`` instead of [ a variable-flavored ``Hotkey, If, %cond%()`` as in this function ].
	;
	; For example, if you call like this.
	;
	;	dev_DefineHotkeyWithCondition("F9", "IsNotepadActive", "mytooltip", "Hit", "notePad")
	;
	; then you must have an #If block with at least two lines(an empty block is enough)
	;
	;	#If IsNotepadActive()
	;	#If
	;
	;	IsNotepadActive()
	;	{
	;		IfWinActive, ahk_class Notepad
	;	    {
	;	         return true
	;		}
	;		return false
	;	}
	;
	;
	; Data structure example:
	; condfuns["F1"]                         => another object
	; condfuns["F1"]["Spc_IsActive"]         => yet another object
	; condfuns["F1"]["Spc_IsActive"].fn_name => yet another object
	; condfuns["F1"]["Spc_IsActive"].fn      => Function object for Spc_IsActive() true condition
	; condfuns["F1"]["Spc_IsActive"].pr      => function parameters for the .fn function
	
	if(cond=="")
	{
		dev_MsgBoxError("BUG! Call with null cond: `n`ndev_DefineHotkeyWithCondition(" . hk . "`, (null)`, " . fn_name . ")")
		return 
	}
	
	static condfuns := {}
	
	if(not condfuns[hk])
	{
		condfuns[hk] := {}
		condfuns[hk].count := 0
	}
		
	
	if(not condfuns[hk][cond])
		condfuns[hk][cond] := {}

	if(fn_name)
	{
		; To improve(maybe): cache cond's function in ``condfuns[hk][cond].condfn`` to improve speed

		condfuns[hk][cond].fn_name := fn_name
		condfuns[hk][cond].fn := Func(fn_name)
		condfuns[hk][cond].pr := args
		condfuns[hk][cond].cnt := 0
		
		Hotkey, If, %cond%()
		Hotkey, %hk%, Hotkey_Handler_conditional, On
	}
	else 
	{
		condfuns[hk].remove(cond)
		
		Hotkey, If, %cond%()
		Hotkey, %hk%, Off
	}
	
	Hotkey, If ; to be third-party code friendly, revert to global Hotkey context
	
	return

Hotkey_Handler_conditional:
	hk_dict := condfuns[A_ThisHotkey]
	hk_dict.count += 1
;tooltip, % "Hotkey_Handler_conditional() [" . A_ThisHotkey . "] ........(" . hk_dict.count . ")"
	
	for cond, fnpr in hk_dict
	{
		if(%cond%()) ; if the condition is true
		{
;			tooltip, % "Hotkey_Handler_conditional() [" . A_ThisHotkey . "@" . cond . "] => " . fnpr.fn_name . "()" ; debug ok
;			sleep, 500 ; debug

			fnpr.cnt += 1
			fnpr.fn.(fnpr.pr*)
		}
	}

	return
}

Get_ClientAreaPos(htopwin, byref x, byref y, byref w, byref h)
{
	if(not htopwin)
	{
		WinGet, htopwin, ID, A ; cache active window unique id
	}

	GetWindowInfo(htopwin, left, top, right, bottom, cleft, ctop, cright, cbottom)
	
	x := cleft-left
	y := ctop-top
	w := cright-cleft
	h := cbottom-ctop
}

GetWindowInfo(_hGui
				, ByRef _winLeft=0, ByRef _winTop=0, ByRef _winRight=0, ByRef _winBottom=0
				, ByRef _cliLeft=0, ByRef _cliTop=0, ByRef _cliRight=0, ByRef _cliBottom=0
				, ByRef _xWinBorder=0, ByRef _yWinBorder=0, ByRef _winStyle=0)
{
	; Thanks to http://www.autohotkey.com/board/topic/101025-wingetpos-bug/
	
;	if TraceLevel
;		SendTrace(A_ThisFunc, "START")
	
	;---------------------------------------------------------------------
	; DWORD + 2 RECT + 3 DWORD + 2 UINT + ATOM + WORD		(RECT = 4 LONG)
	;---------------------------------------------------------------------
	windowInfoSize := 56 + A_PtrSize + 2
	VarSetCapacity(windowInfo, windowInfoSize, 0)
	NumPut(windowInfoSize, windowInfo, 0, "UInt") 	; cbSize
	
	if !DllCall("User32.dll\GetWindowInfo", Ptr, _hGui, Ptr, &windowInfo)
		return false
	
	_winLeft   := NumGet(windowInfo, 4, "Int")	; RECT of the Window
	_winTop    := NumGet(windowInfo, 8, "Int")
	_winRight  := NumGet(windowInfo, 12, "Int")
	_winBottom := NumGet(windowInfo, 16, "Int")
	
;	if (TraceLevel >= 2)
;		SendTrace(A_ThisFunc, "Window", "Left:" _winLeft " Top:" _winTop . " Right:" _winRight " Bottom:" _winBottom)
	
	_cliLeft   := NumGet(windowInfo, 20, "Int")	; RECT of the Window Client Area
	_cliTop    := NumGet(windowInfo, 24, "Int")
	_cliRight  := NumGet(windowInfo, 28, "Int")
	_cliBottom := NumGet(windowInfo, 32, "Int")
	
;	if (TraceLevel >= 2)
;		SendTrace(A_ThisFunc, "Client", "Left:" _cliLeft " Top:" _cliTop . " Right:" _cliRight " Bottom:" _cliBottom)
	
	SetFormat, Integer, H
	_winStyle := NumGet(windowInfo, 36, "UInt") + 0
	SetFormat, IntegerFast, D
	
	_xWinBorder := NumGet(windowInfo, 48, "UInt")
	_yWinBorder := NumGet(windowInfo, 52, "UInt")
	
;	if (TraceLevel >= 2)
;		SendTrace(A_ThisFunc, "winStyle:" _winStyle, "xBorder:" _xWinBorder
;								  . " yBorder:" _yWinBorder)
;	
;	if TraceLevel
;		SendTrace(A_ThisFunc, "END")
	
	return true
}

dev_StrIsEqualI(s1, s2) ; case insensitive compare
{
	StringUpper, s1u, s1
	StringUpper, s2u, s2
	if(s1u==s2u)
		return true
	else
		return false
}

StrIsStartsWith(str, prefix, is_case_sensitive:=false)
{
	; Check if the string str starts with prefix
	pfxlen := strlen(prefix)
	if(pfxlen<=0)
		return false
	
	s1 := substr(str, 1, pfxlen)
	
	StringUpper, s1_u, s1
	StringUpper, s2_u, prefix
	
	if(s1_u==s2_u)
		return true
	else
		return false
}

StrIsEndsWith(str, suffix)
{
	suffix_len := strlen(suffix)
	if(suffix_len==0)
		return false
	if(substr(str, 1-suffix_len)==suffix)
		return true
	else
		return false
}

StrCountLines(str)
{
	if(!str)
		return 0
	
	strlfs := RegExReplace(str, "[^\n]", "")
	return strlen(strlfs)+1
}

CharIsAlphaNum(c)
{
	if(not c)
		return false
	
	ascii := Asc( substr(c, 1) )
	if(ascii>=Asc("A") and ascii<=Asc("Z") || ascii>=Asc("a") and ascii<=Asc("z") || ascii>=Asc("0") and ascii<=Asc("9"))
		return true
	else
		return false
	
}

dev_StripPrefix(str, prefix, is_case_sensitive:=false)
{
	if(StrIsStartsWith(str, prefix, is_case_sensitive))
		return SubStr(str, StrLen(prefix)+1)
	else
		return str
	
}

dev_str2num(str)
{
	; Convert "012" to 12, so that it can be used as array index.
	; Tip from Lexikos: https://www.autohotkey.com/board/topic/21271-converting-string-to-number/
	
	num := "0" . str
	num += 0
	return num
}

dev_TooltipAutoClear(text, keep_millisec:=2000)
{
	tooltip, %text%
	SetTimer, lb_TooltipAutoClear, % 0-keep_millisec
	return
	
lb_TooltipAutoClear:
	tooltip
	return
}

dev_TooltipDelayHide(keep_millisec:=2000)
{
	; Hide the tooltip after some millisec.
	SetTimer, lb_TooltipDelayHide, % 0-keep_millisec
	return 
	
lb_TooltipDelayHide:
	tooltip
	return
}

dev_WriteLogFile(filepath, text, is_append:=true)
{
	; memo: Use "`n" in text to represent a new line.
	;
	if(not filepath)
		return
	
	if(not is_append)
		FileDelete, %filepath%
	
	FileAppend, %text%, %filepath%
}

dev_RunWaitOne(command, is_hidewindow:=false, working_dir:="") 
{
	if(not is_hidewindow)
	{
		; // From Autohotkey chm doc
		; // Problem: if StdOut contains Unicode, they may be swallowed.
		;
		; WshShell object: http://msdn.microsoft.com/en-us/library/aew9yb99
		shell := ComObjCreate("WScript.Shell")
		; Execute a single command via cmd.exe
		exec := shell.Exec(ComSpec " /C " command)
		; Read and return the command's output
		return exec.StdOut.ReadAll()
	}
	else
	{
		; Redirect the new process's stdout to a file then retrieve it.
		; I have to do this because WScript.Shell.Exec does not support "hide window" param,
		; while Autohotkey's Run allows "hiding".
		dir_localapp := dev_EnvGet("LocalAppData")
		tempfile := dir_localapp . "\temp\dev_RunWaitOne.txt"
		run_string = %ComSpec% /c %command% > %tempfile%
		try {
			RunWait, %run_string%, %working_dir%, Hide
		} catch e {
			return "In dev_RunWaitOne(), the following command failed:`n" . run_string
		}
		FileRead, cmd_output, %tempfile%
		return cmd_output
	}
}

dev_EnvGet(varname)
{
	; Get environment variable value.
	EnvGet, val, %varname%
	return val
}

dev_MsgBoxInfo(text, wintitle:="") ; with a blue (i) icon
{
	if(!wintitle)
		wintitle := "AHK Info"

	MsgBox, 64, % wintitle, % text
}

dev_MsgBoxWarning(text, wintitle:="") ; with a yellow (!) icon
{
	if(!wintitle)
		wintitle := "AHK Warning"

	MsgBox, 48, % wintitle, % text
}

dev_MsgBoxError(text, wintitle:="") ; with a red (x) icon
{
	if(!wintitle)
		wintitle := "AHK Error"

	MsgBox, 16, % wintitle, % text
}

dev_MsgBoxYesNo(text, default_yes:=true, parent_winid:=0, icon:=64)
{
	; hope to display the message box at the center of parent_winid window...(pending)

	opt := icon + msgboxoption_YesNo + (default_yes ? 0 : msgboxoption_2nddefault)
	MsgBox, % opt, , %text%, 1000
		; [2016-02-09] I can't use ``%opt%`` for ``% opt`` here(dialogbox would display 260), don't know why.
	
	IfMsgBox, Yes
		return true
	Else
		return false
}

dev_MsgBoxYesNo_Warning(text, default_yes:=true, parent_winid:=0)
{
	return dev_MsgBoxYesNo(text, default_yes, parent_winid, 48)
}


dev_IsClassnnFocused_regex(regex)
{
	ControlGetFocus, focusNN, A
	if(focusNN ~= regex)
		return true
	else
		return false
}

dev_SetClipboardWithTimeout(text, timeout_milisec:=1000)
{
	is_ok := false
	msec_start := A_TickCount
	Loop
	{
		try {
			Clipboard := text
		} catch e {
			; e seems to be null
			Sleep, 10
			continue
		}
		
		is_ok := true
		break
		
	} until (A_TickCount-msec_start>timeout_milisec)
	
	return is_ok
}

;################### Windows GUI tweaking functions ###########################

dev_ReadRemoteBuffer(hpRemote, RemoteBuffer, ByRef LocalVar, bytes)
{
	result := DllCall( "ReadProcessMemory" 
	            , "Ptr", hpRemote 
	            , "Ptr", RemoteBuffer 
	            , "Ptr", &LocalVar 
	            , "uint", bytes 
	            , "uint", 0 ) 
}

EnumToolbarButtons(ctrlhwnd, is_apply_scale:=false)
{
	; Thanks to LabelControl code from 
	; https://www.donationcoder.com/Software/Skrommel/
	;
	; ctrlhwnd is the toolbar hwnd.
	; Return an array of objects, with element:
	; * .x .y .w .h (button position relative to the toolbar)
	; * .cmd  (command id of the button)
	; * .text  (text displayed on the button)
	;
	; is_apply_scale should keep false; true is only for testing purpose
	
	arbtn := []

	ControlGetPos, ctrlx, ctrly, ctrlw, ctrlh, , ahk_id %ctrlhwnd%
	
	WinGet, pid_target, PID, ahk_id %ctrlhwnd%
	hpRemote := DllCall( "OpenProcess" 
	                    , "uint", 0x18    ; PROCESS_VM_OPERATION|PROCESS_VM_READ 
	                    , "int", false 
	                    , "uint", pid_target ) 
    ; hpRemote: Remote process handle
	if(!hpRemote) {
		tooltip, % "Autohotkey: Cannot OpenProcess(pid=" . pid_target . ")"
		return
	}
	remote_buffer := DllCall( "VirtualAllocEx" 
                    , "uint", hpRemote 
                    , "Ptr", 0          ; LPVOID lpAddress ("uint" tolerable) 
                    , "uint", 0x1000    ; size to allocate, 4KB
                    , "uint", 0x1000         ; MEM_COMMIT 
                    , "uint", 0x4 )          ; PAGE_READWRITE 
	x1=
	x2=
	y1=
	WM_USER:=0x400
	TB_GETSTATE:=WM_USER+18
	TB_GETBITMAP     :=     (WM_USER + 44) ; only for test
	TB_GETBUTTONSIZE :=     (WM_USER + 58) ; only for test
	TB_GETBUTTON:=WM_USER+23
	TB_GETBUTTONTEXTW := WM_USER+75 ; I always get UTF-16 string from the toolbar // ANSI: WM_USER+45
	TB_GETITEMRECT:=WM_USER+29
	TB_BUTTONCOUNT:=WM_USER+24
	SendMessage, %TB_BUTTONCOUNT%,0,0, , ahk_id %ctrlhwnd%
	buttons := ErrorLevel
;tooltip, buttons=%buttons%	 ; OK
	
	VarSetCapacity( rect, 16, 0 ) 
	VarSetCapacity( BtnStruct, 32, 0 ) ; Winapi TBBUTTON struct(32 bytes on x64, 20 bytes on x86)
	/*
		typedef struct _TBBUTTON {
		    int       iBitmap; 
		    int       idCommand; 
		    BYTE      fsState; 
		    BYTE      fsStyle; 
		#ifdef _WIN64
		    BYTE      bReserved[6]     // padding for alignment
		#elif defined(_WIN32)
		    BYTE      bReserved[2]     // padding for alignment
		#endif
		    DWORD_PTR dwData; 
		    INT_PTR   iString; 
		} TBBUTTON, NEAR* PTBBUTTON, FAR* LPTBBUTTON; 
	*/

	Loop,%buttons%
	{
		; Try to get button text. Two steps: 
		; 1. get command-id from button-index,
		; 2. get button text from comand-id
		SendMessage, %TB_GETBUTTON%, % A_Index-1, remote_buffer, , ahk_id %ctrlhwnd%
		dev_ReadRemoteBuffer(hpRemote, remote_buffer, BtnStruct, 32)
		idButton := NumGet(BtnStruct, 4, "int")
		;
;		SendMessage, %TB_GETSTATE%, %idButton%, 0, , ahk_id %ctrlhwnd% ; hope that 4KB is enough ; just a test
		SendMessage, %TB_GETBUTTONTEXTW%, %idButton%, remote_buffer, , ahk_id %ctrlhwnd% ; hope that 4KB is enough
		btntextchars := ErrorLevel
		if(btntextchars>0){
			btntextbytes := A_IsUnicode ? btntextchars*2 : btntextchars
			VarSetCapacity(BtnTextBuf, btntextbytes+2, 0) ; +2 is for trailing-NUL
			dev_ReadRemoteBuffer(hpRemote, remote_buffer, BtnTextBuf, btntextbytes)
			BtnText := StrGet(&BtnTextBuf, "UTF-16")
		} else {
			BtnText := ""
		}
		;FileAppend, % A_Index . ":" . idButton . "(" . btntextchars . ")" . BtnText . "`n", _emeditor_toolbar_buttons.txt ; debug

		SendMessage,%TB_GETITEMRECT%,% A_Index-1, remote_buffer, , ahk_id %ctrlhwnd%

		dev_ReadRemoteBuffer(hpRemote, remote_buffer, rect, 16)
		oldx1:=x1
		oldx2:=x2
		oldy1:=y1
		x1 := NumGet(rect, 0, "int") 
		x2 := NumGet(rect, 8, "int") 
		y1 := NumGet(rect, 4, "int") 
		y2 := NumGet(rect, 12, "int")
		
		if(is_apply_scale) {
			scale := Get_DPIScale()
			x1 /= scale
			y1 /= scale
			x2 /= scale
			y2 /= scale
		}

		If (x1=oldx1 And y1=oldy1 And x2=oldx2)
			Continue
		If (x2-x1<10)
			Continue
		If (x1>ctrlw Or y1>ctrlh)
			Continue
	
		arbtn.Insert( {"x":x1, "y":y1, "w":x2-x1, "h":y2-y1, "cmd":idButton, "text":BtnText} )
		;line:=100000000+Floor((ctrly+y1)/same)*10000+(ctrlx+x1)
		;lines=%lines%%line%%A_Tab%%ctrlid%%A_Tab%%class%`n
	}
	result := DllCall( "VirtualFreeEx" 
	             , "uint", hpRemote 
	             , "uint", remote_buffer 
	             , "uint", 0 
	             , "uint", 0x8000 )     ; MEM_RELEASE 
	result := DllCall( "CloseHandle", "uint", hpRemote )
	return arbtn
}


;##############################################################################
;##################### General system-wide hotkeys. ###########################
;##############################################################################

Am_PlaySound(wavfile)
{
	if(!g_AmMute)
		SoundPlay, %wavfile%
}

PlaySoundLeftClick()
{
	Am_PlaySound("click.wav")
}

PlaySoundRightClick()
{
	Am_PlaySound("sel.wav")
}

LeftClickWithSound(sound:=true)
{
	MouseClick, Left
	if(sound)
		PlaySoundLeftClick()
}

RightClickAndPlaySound(sound:=true)
{
	MouseClick, Right
	if(sound)
		PlaySoundRightClick()
}


; Win+N to minimize a window, replacing Alt+Space,n
#n:: WinMinimize, A
+#n:: WinRestore, A

!#Del:: dev_WinHideWithPrompt()

dev_WinHideWithPrompt(Awinid:=0)
{
	if(Awinid==0)
		WinGet, Awinid, ID, A ; cache active window unique id

	WinGetTitle, title, ahk_id %Awinid%
	
	ans := dev_MsgBoxYesNo("Hide this window?`n`n" . title)
	if (ans) {
		WinHide, ahk_id %Awinid%
	}
}


AppsKey:: Send {AppsKey} 
	; Need this because I use AppsKey as a prefix key (in many modules).
	; Q: Why isn't a $ prefix required?


CapsLock & Up:: Click WheelUp
CapsLock & Down:: Click WheelDown
/*
; Define some AppsKey-combo hotkeys

CapsLock & LEFT:: Click WheelLeft
CapsLock & RIGHT:: Click WheelRight
*/
;
AppsKey & UP:: Click WheelUp
AppsKey & DOWN:: Click WheelDown


MouseNudge(dx, dy, pixels, speed=1)
{
	; dx, dy, should be [0, -1, 1], i.e. only direction indication
	WinGetTitle, title, A
	if(title==g_MouseNudgeTitleAM) {
		mult :=  g_MouseNudgeUnitAM 
	}
	else {
		mult := pixels
		g_MouseNudgeTitleAM := "Mouse-nudge title match not valid now!" ;
	}
	rx := dx*mult
	ry := dy*mult
	
	MouseMove, %rx%, %ry%, %speed%, R
}

ModifyMouseNudgeUnitAM(nudge_unit, wintitle="") ; nudge_unit in pixels
{
	g_MouseNudgeUnitAM := nudge_unit
	
	if (not wintitle)
		WinGetTitle, wintitle, A
	
	g_MouseNudgeTitleAM := wintitle
}


IsDirectionKey(key)
{
	if (key=="Up"||key=="Down"||key=="Left"||key=="Right")
		return true
	else {
		return false
		}
}

movewinGetScale()
{
	; Note: This function requires a prior RCtrl relative hotkey defnition, such as 
	;
	; RCtrl::RCtrl
	;
	; ~RCtrl:: ...
	;
	; -- any one is ok.
	
	static scale = 1
	matchpos := RegExMatch(A_PriorHotKey, "RCtrl")
;tooltip, A_PriorHotKeY=%A_PriorHotKey% . A_PriorKeY=%A_PriorKey%  . matchpos=%matchpos%
	if (matchpos>0 && A_TickCount-gtc_last_RCtrl<g_RCtrl_WinMoveScale_graceticks)
	{	; A pre RCtrl tap will scale the move step
		scale := g_winmove_scale
	}
	else if ( scale!=1 && not (IsDirectionKey(A_PriorKey)||A_PriorKey=="LShift") ) 
	{
		; That means user release Win+Alt and then press them again, so reset the scale.
		scale = 1
	}
	return scale
}

moveWinRelative(rx, ry)
{
	; Move current window by a relative rx, ry value. rx, ry can be positive or negative
	scale := movewinGetScale()
	WinGetPos, x, y, width, height, A
	absx := x + rx*g_winmove_unit*scale
	absy := y + ry*g_winmove_unit*scale
	WinMove, A, , %absx%, %absy%
}

moveWinBorder(whichb, direction)
{
	; whichb can be "L", "T", "R", "B" for Left, Top, Right, Bottom respectively
	
	scale := movewinGetScale()
	value := direction * g_winmove_unit*scale
	WinGetPos, x, y, width, height, A
	
	if(whichb=="L") {
		x := x + value
		width := width - value
	}
	if(whichb=="T") {
		y := y + value
		height := height - value
	}
	if(whichb=="R") {
		width := width + value
	}
	if(whichb=="B") {
		height := height + value
	}
	WinMove, A ,, %x%, %y%, %width%, %height%
}


; 2014-08-09
dev_WinMove_with_backup(_newx, _newy, _new_width, _new_height, Awinid:=0, is_force:=false)
{
	; Use "" for _newx, _newy, _new_width, _new_height if you don't want to change one of them.
	; Note: 0 is different with "" .

	if(Awinid==0)
		WinGet, Awinid, ID, A ; cache active window unique id

	WinGetPos old_winx, old_winy, old_winwidth, old_winheight, ahk_id %Awinid%
	; MsgBox New value is new_width, %new_height%
	
	if(_newx!="")
		newx := _newx
	if(_newy!="")
		newy := _newy
	if(_new_width!="")
		new_width := _new_width
	if(_new_height!="")
		new_height := _new_height
	
	if( !is_force && newx==old_winx && newy==old_winy && new_width==old_winwidth && new_height==old_winheight ) {
		return ; already at desired position, no need to move
	}
	
	WinMove, ahk_id %Awinid% ,, %newx%, %newy%, %new_width%, %new_height%
	WinGetPos winx, winy, winwidth, winheight, ahk_id %Awinid%
	If( winx==old_winx and winy==old_winy and winwidth==old_winwidth and winheight==old_winheight ){
		; oldpos==newpos, do nothing 
	}
	Else {
		; backup old position into g_xxx
		g_winx := old_winx
		g_winy := old_winy
		g_winwidth := old_winwidth
		g_winheight := old_winheight
	}
}

; 2014-08-09:
dev_UndoChangeWindowSize()
{
	WinGetPos winx, winy, winwidth, winheight, A
	If (g_winwidth>0) {
		WinMove, A, , g_winx, g_winy, g_winwidth, g_winheight
		g_winx := winx
		g_winy := winy
		g_winwidth := winwidth
		g_winheight := winheight
	}
}

dev_SortIntArray(ar)
{
	; https://www.autohotkey.com/boards/viewtopic.php?t=12054
	For i, v in ar
		list .=	v ","
	list :=	Trim(list,",")
	Sort, list, N D`,
	out :=	[]
	Loop, parse, list, `,
		out.Push(A_LoopField)
	Return	out
}

_Lineseg_IntersectLen(a0,b0_, a1,b1_)
{
	; Calculate intersect length of two line-segments [a0, b0_) and [a1, b1_)
	
	; First check whether the two lineseg are separated.
	if( b0_<=a1 || a0>=b1_ )
		return 0 ; two lineseg does not intersect
	
	; Find the middle two numbers of a0,b0_,a1,b1_ , those two constitute the intersecting lineseg.
	arout := dev_SortIntArray([a0, b0_, a1,b1_])
	return arout[3] - arout[2]
}

dev_SetWindowSize_StickCorner(hwnd, newwidth, newheight, escape_taskbar:=false)
{
	; "StickCorner" means: 
	; * If the window is near left/top corner of a specific monitor, it will extend/shrink its right/bottom.
	; * If the window is near right/bottom corner of a specific monitor, it will extend/shrink its left/top.
	; -- as if the window is stick to its original corner when changing size.
	;
	; If escape_taskbar==true, the adjusted window position will not overlap Windows taskbar.

	use_hwnd := "ahk_id " . hwnd
	
	WinGetPos, x,y,w,h, % use_hwnd
	
	mrect := {}
	
	; The monitor that totally accommodates the whole hwnd. To be set later. 0 is invalid value.
	idx_best_monitor := 0 
	
	; If the hwnd straddles across multiple monitors, we'll pick the monitor with the most occupied area
	; as the "good monitor"
	idx_good_monitor := 1
	area_goodr_monitor := 0
	
	;
	; Check whether the hwnd totally resides in a specific monitor(no straddle)
	;
	mlo := dev_EnumDisplayMonitors() ; mlo: monitor layout
	Loop, % mlo.count
	{
		mrect := escape_taskbar ? mlo.workarea_rects[A_Index] : mlo.monitor_rects[A_Index]
		
		if (x>=mrect.left && y>=mrect.top && x+w<mrect.right && y+h<mrect.bottom)
		{
			idx_best_monitor := A_Index
			break
		}
		
		; hwnd does not fit into a single monitor, so we need to resort to the good one
		interx := _Lineseg_IntersectLen(x, x+w, mrect.left, mrect.right)
		intery := _Lineseg_IntersectLen(y, y+h, mrect.top, mrect.bottom)
		intersect_area := interx * intery
		if(intersect_area>area_goodr_monitor)
		{
			area_goodr_monitor := intersect_area
			idx_good_monitor := A_Index
		}
	}
	
;	MsgBox, % "idx_best_monitor = " . idx_best_monitor ; debug

	mwidth := mrect.right - mrect.left
	mheight := mrect.bottom - mrect.top

	if(idx_best_monitor==0)
	{
		; fallback to the good one
		mrect := escape_taskbar ? mlo.workarea_rects[idx_good_monitor] : mlo.monitor_rects[idx_good_monitor]
		
		; new width & height must be shrunk to fit into the newly select monitor

		if(newwidth>mwidth) 
			newwidth := mwidth
		if(newheight>mheight) 
			newheight := mheight

		if(w>mwidth)
			w := mwidth
		if(h>mheight)
			h := mheight
		
		; adjust hwnd's Right border
		Rofs := x+w - mrect.right
		if(Rofs>0)
			x -= Rofs
		
		; adjust hwnd's Bottom border
		Bofs := y+h - mrect.bottom
		if(Bofs>0)
			y -= Bofs
		
		; adjust hwnd's Left border
		if(x < mrect.left)
			x := mrect.left
			
		; adjust hwnd's Top border
		if(y < mrect.top)
			y := mrect.top
		
		; Now, x,y,w,h is a rectangle that fits into mrect.
	}
	
	if(newwidth > mwidth) {
		MsgBox, % Format("BUG! New window width({1}) should not exceed its current monitor width({2}) .", newwidth, mwidth)
		return
	}
	if(newheight > mheight) {
		MsgBox, % Format("BUG! New window height({1}) should not exceed its current monitor height({2}) .", newheight, mheight)
		return
	}

	winleft := x
	winright := x+w
	wintop := y
	winbottom := y+h
	
	; Check whether we should adjust left border or right border.
	leftgap := winleft - mrect.left
	rightgap := mrect.right - winright
	if(leftgap < rightgap)
		winright := winleft + newwidth
	else
		winleft := winright - newwidth

	; Check whether we should adjust top border or bottom border.
	topgap := wintop - mrect.top
	bottomgap := mrect.bottom - winbottom
	if(topgap < bottomgap)
		winbottom := wintop + newheight
	else
		wintop := winbottom - newheight

	; Finally, move window and change window size
	WinMove, % use_hwnd, , % winleft , % wintop , % winright-winleft , % winbottom-wintop

	return true
}


; Alt+Win+(+/-)Make current window transparent ON/OFF
!#=:: Am_SetTransparentWithTip(-1) ; WinSet, Transparent, OFF, A
!#-:: Am_SetTransparentWithTip(144)
Am_SetTransparentWithTip(tranparent_level)
{
	static s_hint_timeout := 5000
	WinGet, Awinid, ID, A ; cache active window unique id
	
	if(tranparent_level>=0)
	{
		WinSet, Transparent, %tranparent_level%, ahk_id %Awinid%
		dev_TooltipAutoClear("Press Alt+Win+= to cancel transparent.", s_hint_timeout)
	}
	else
	{
		WinSet, Transparent, OFF, ahk_id %Awinid%

		; [2019-12-12] Autohotkey 1.1.24.05 Memo: If only execute 
		;   WinSet, Transparent, OFF, A
		; The previously Am_SetTransparentWithTip(0) window will not revert to normal, weird.
	}
	s_hint_timeout := 1000
}

!#End:: UnsetAlwaysOnTopWithTip()
UnsetAlwaysOnTopWithTip()
{
	WinSet, AlwaysOnTop, Off, A
	dev_TooltipAutoClear("Always-on-top off for active window.", 1000)
}
!#Home:: SetAlwaysOnTopWithTip()
SetAlwaysOnTopWithTip()
{
	static s_hint_timeout := 8000
	WinSet, AlwaysOnTop, On,  A
	dev_TooltipAutoClear("Press Alt+Win+End to cancel always-on-top (for active window).", s_hint_timeout)
	s_hint_timeout := 1000
}

;
!#Left::  moveWinRelative(-1, 0)
!#Right:: moveWinRelative(1, 0)
!#Up::    moveWinRelative(0, -1)
!#Down::  moveWinRelative(0, 1)

^#Up::    moveWinBorder("T", -1)
^#Down::  moveWinBorder("B", 1)
^#Left::  moveWinBorder("L", -1)
^#Right:: moveWinBorder("R", 1)
;
+^#Up::    moveWinBorder("B", -1)
+^#Down::  moveWinBorder("T", 1)
+^#Left::  moveWinBorder("R", -1)
+^#Right:: moveWinBorder("L", 1)


^#/:: devui_ChangeWindowPosition()
devui_ChangeWindowPosition()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetPos x, y, width, height, ahk_id %Awinid%
	x2 := x + width
	y2 := y + height
	textpreset := % "" . x . "," . y . "," . x2 . "," . y2
	
	WinGetClass, winclass, ahk_id %Awinid%
	InputBox, size_xy , % "Autohotkey move window", 
	(
Assign new position and size for current active window. For example, 

40,20,840,620
    Set window position to left=40, top=20, right=840, bottom=620.
    
40,20,,
    Set window position to left=40, top=20, not changing size.
    
,,840,620
    Set position to right=840, bottom=620, not changing left-top.
    
40,20,=800,=600
    Set window position to left=40, top=20, width=800, height=600.
    
,,=800,=600
    Set window width=800, height=600, not changing left-top.

Current window(%winclass%) at <%x%,%y%> , size [%width%,%height%]
	), , 600, 420, , , , , %textpreset%
	if ErrorLevel
		return
	
	n := StrSplit(size_xy, ",", " ")
	x1_ := n[1]
	y1_ := n[2]
	x2_ := n[3]
	y2_ := n[4]
	
	if (x1_ <> "")
		newx := x1_
	else
		newx := x
	
	if (y1_ <> "")
		newy := y1_
	else
		newy := y
	
	if (x2_ <> "") 
	{
		if(SubStr(x2_, 1, 1)=="=")
			newwidth := SubStr(x2_, 2)
		else
			newwidth := x2_ - newx
	}
	else
		newwidth := width
	
	if (y2_ <> "" )
	{
		if(SubStr(y2_, 1, 1)=="=")
			newheight := SubStr(y2_, 2)
		else
			newheight := y2_ - newy
	}
	else
		newheight := height
	
;	msgbox, zzz %newx%, %newy%, %newwidth%, %newheight% ; debug

	dev_WinMove_with_backup(newx, newy, newwidth, newheight, Awinid)
	;	WinMove, ahk_id %Awinid% ,, %newx%, %newy%, %newwidth%, %newheight%
	return
}

!#/:: ; Interactively change g_winmove_unit
	InputBox g_winmove_unit, Autohotkey move step, Input new window move unit in pixels, , , , , , , , %g_winmove_unit%
return



;

; Double-press Left Ctrl to move mouse cursor to the center of current active window. (memo: Press Ctrl twice)
; I need "up"; otherwise, holding down LCtrl will trigger the double press condition.
~LCtrl up::
;	tooltip, % "LLLLLLLLLLLLLLLLctrl-up: A_ThisHotkey=" . A_ThisHotkey . " "
	if (A_PriorHotkey == "~LCtrl up" and A_TimeSincePriorHotkey < 300) {
	    ; This is a double-press.
		MouseMoveInActiveWindow(1/2, 1/2, 7)
	}
return


NewCoordFromHint(x, width, xhint, omode:=false)
{
	; Although function parameters refer to 'x', it can be used by 'y' as well.
	; omode: outside-mode, the coordinate will be outside the range of [x, x+width]
	
	if(not omode)
	{	; inside-mode
		if(xhint>=1) ; xhint is offset from left border
		{
			if(xhint > width)
				xhint := width
			outputx := x + xhint
		}
		else if(xhint<=-1) ; xhint is offset from right border
		{
			if(xhint <= 0-width)
				xhint := 0-width
			outputx := x + width + xhint
		}
		else if(xhint>=0) ; xhint is percent from left border
		{
			outputx := x + width*xhint
		}
		else ; -1<xhint<0 , xhint is percent from right border
		{
			outputx := x + width*(1+xhint)
		}
	}
	else  
	{	; outside-mode
		if(xhint>=1) ; offset from right border and go further right
			outputx := x + width + xhint
		else if(xhint<=-1) ; offset from left border and go further left
			outputx := x + xhint
		else ; invalid xhint
			outputx := x
	}
	return outputx
}

dev_SaveMouseScreenPos()
{
	; Note: I use screen coord to save/restore mouse pos because active window
	; may have changed during the save and the restore.
	CoordMode, Mouse, Screen
	MouseGetPos, g_saved_xMouseScreen, g_saved_yMouseScreen
	CoordMode, Mouse, Window
}
dev_RestoreMouseScreenPos()
{
	CoordMode, Mouse, Screen
	MouseMove, %g_saved_xMouseScreen%, %g_saved_yMouseScreen%
	CoordMode, Mouse, Window
}

dev_ClickInScreen(xhint, yhint, is_movemouse:=true, is_clicksound:=true)
{
	CoordMode, Mouse, Screen    ;sets screen-based coordinates

	MouseGetPos origx, origy
	
	clickx := NewCoordFromHint(0, A_ScreenWidth, xhint)
	clicky := NewCoordFromHint(0, A_ScreenHeight, yhint)

	Click %clickx%, %clicky%
	
	if(is_clicksound)
		PlaySoundLeftClick()
	
	if(not is_movemouse)
		MouseMove %origx%, %origy%

	CoordMode, Mouse, Window  ;restore to active-window-based coordinates
}

dev_MouseMoveInScreen(newx, newy)
{
	CoordMode, Mouse, Screen    ;sets screen-based coordinates

	MouseMove %newx%, %newy%
	
	CoordMode, Mouse, Window  ;restore to active-window-based coordinates
}




MouseMoveInActiveWindow(ux, uy, speed:=3)
{
	MouseActInActiveWindow(ux,false, uy,false, true, false, speed)
}
MouseMoveInActiveWindowEx(ux,xomode, uy,yomode, speed:=3)
{
	MouseActInActiveWindow(ux,xomode, uy,yomode, true, false, speed)
}

ClickInActiveWindow(ux, uy, is_movemouse:=true, movespeed:=0)
{
	; Assume window position is left=100,top=100, right=600,bottom=400
	; If ux>=1, clickx will be 100+ux, but not go right-hand beyond 600.
	; If ux<=-1, clickx will be 600+ux, but not go left-hand beyond 100.
	; If 0<ux<1, clickx will be 100+500*ux .
	; If -1<ux<0, clickx will be 600+500*ux .
	;  --same rule for uy.
	; But if you want to click outside the window area, you should use ClickInActiveWindowEx().

	MouseActInActiveWindow(ux,false, uy,false, is_movemouse, true, movespeed)
}
ClickInActiveWindowEx(ux,xomode, uy,yomode, is_movemouse:=true)
{
	MouseActInActiveWindow(ux,xomode, uy,yomode, is_movemouse, true)
}

MouseActInActiveWindow(ux,xomode, uy,yomode, is_movemouse:=true, is_click:=false, movespeed:=0)
{
	; If ux>=1, x offset from left border; if ux<0, x offset from right border.
	; If uy>=1, y offset from top border; if uy<0,  offset from bottom border.
	; If using a fraction(0.5 etc) for ux or uy, it means x or y percent.

	if (not is_movemouse && not is_click)
		return

	dev_SaveMouseScreenPos()
	WinGetPos, _x, _y, width, height, A

	targetx := NewCoordFromHint(0, width, ux, xomode)
	targety := NewCoordFromHint(0, height, uy, yomode)
	
	MouseMove, %targetx%, %targety%, %movespeed%

	if (is_click)
		Click %targetx%, %targety%

	If (not is_movemouse)
		dev_RestoreMouseScreenPos()
	
	if is_click
		PlaySoundLeftClick()
}

ClickInActiveControl(classnn, ux, uy, is_movemouse:=false, is_warn:=true)
{
	; Note: ClickInActiveControl(classnn, 0.5, 0.5) can be used as a workaround for 
	; ControlClick's often losing functionality.
	; Note: This requires the classnn control be visible on the screen,
	; -- because I really drive the mouse their and do a real click.

	MouseActInActiveControl(classnn, ux,false, uy,false, is_movemouse, true, is_movemouse?3:0, is_warn)
}
ClickInActiveControlEx(classnn, ux,xomode, uy,yomode, is_movemouse:=false, is_warn:=true)
{
	MouseActInActiveControl(classnn, ux,xomode, uy,yomode, is_movemouse, true, is_movemouse?3:0, is_warn)
}

MouseActInActiveControl(classnn, ux,xomode, uy,yomode, is_movemouse:=true, is_click:=false, movespeed:=0, is_warn:=true)
{
	; This function does not really operate at the target control, but operate on 
	; the screen position of that control.

	; When calling, remember to pass quoted-string for classnn
	ControlGetPos, winx, winy, width, height, %classnn%, A
	if(!winx and is_warn) {
		
		errmsg = [AmHotkey]Unexpected in MouseActInActiveControl(): ControlGetPos returns blank for classnn %classnn%
		
		MsgBox, % errmsg . "`n`nCallstack below (most recent call last):`n`n" . dev_getCallStack()
		
		return
	}
	if (!is_movemouse && !is_click)
		return

	dev_SaveMouseScreenPos()

	targetx := NewCoordFromHint(winx, width,  ux, xomode)
	targety := NewCoordFromHint(winy, height, uy, yomode)

	MouseMove, %targetx%, %targety%, %movespeed%
	
	if (is_click)
		Click %targetx%, %targety%

	If (not is_movemouse)
		dev_RestoreMouseScreenPos()
}


dev_ListActiveWindowChildren()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGet, ControlList, ControlList, ahk_id %Awinid%

	filepath := "ChildrenList.txt"
	dev_WriteLogFile(filepath, "", false) ; clear the file

	Loop, parse, ControlList, `n
	{
		classnn := A_LoopField

		ControlGet, ctlid, Hwnd,, %classnn%, ahk_id %Awinid%
		ControlGetText, ctltext, %classnn%, ahk_id %Awinid%

		; msgbox, %classnn% - %ctlid%
		
		textline := classnn . A_Tab . ctlid . A_Tab . ctltext . "`n"
		
		dev_WriteLogFile(filepath, textline, true)
	}
	
	Run, %filepath%

}

RegexClassnnFindControl(Cregex, Tregex
	, byref oClassnn, byref ox=0, byref oy=0, byref owidth=0, byref oheight=0, byref Awinid=0)
{
	return RegexClassnnFindControlEx("A", Cregex, Tregex, oClassnn, ox,oy,owidth,oheight, Awinid)
}

RegexClassnnFindControlEx(wintitle, Cregex, Tregex
	, byref oClassnn, byref ox=0, byref oy=0, byref owidth=0, byref oheight=0, byref Awinid=0)
{
	; Cregex should match a classnn.
	; Example:
	; If classnn is Afx:400000:8 , you can use match is with "^Afx:"
	;
	; Tregex is the control title(window text) regex match condition; you can use this
	; to distinguish different same-Cregex windows.
	; If Tregex==false, control title is not considered, i.e. Cregex's match is enough to return ``true``.
	; To require an empty title match, pass Tregex=="^$" .
	;
	; Currently no check for multi-match, only return first match. For multi-match, use RegexClassnnFindControls()
	
	oClassnn := false
	WinGet, Awinid, ID, %wintitle% ; cache active window unique id
	WinGet, ControlList, ControlList, ahk_id %Awinid%
	Loop, parse, ControlList, `n
	{
		classnn := A_LoopField
		Cmatchpos := RegExMatch(classnn, Cregex)
		
		if (Cmatchpos>0)
		{
			if not Tregex {
				oClassnn := classnn
				break 
			}
			
			try {
				ControlGetText, text, %classnn%, ahk_id %Awinid%
			} catch e {
				; Without this catch, a too large child-control text will assert #MaxMem error.
				text := ""
			}
			if ( RegExMatch(text, Tregex)>0 ) {
				oClassnn := classnn
				break
			}
		}
	}
	
	if (oClassnn)
	{
		ControlGetPos, ox, oy, owidth, oheight, %oClassnn%, ahk_id %Awinid%
		return true
	}
	else
		return false
}

RegexClassnnFindControls(Cregex:=".+", wintitle:="A")
{
	; Return an array of dicts, with member .classnn .id .x .y .w .h  .text

	; Cregex should match a classnn.
	; Example:
	; If classnn is "Afx:400000:8" , you can use match pattern "^Afx:"
	;
	; Hint: Substring match is OK, so no need to always contain ^ for start-flag and $ for end-flag.
	
	arctrls := []
	WinGet, hwnd, ID, %wintitle%
	WinGet, ControlList, ControlList, ahk_id %hwnd%
	Loop, parse, ControlList, `n
	{
		classnn := A_LoopField
		if( classnn ~= Cregex )
		{
			obj := {}
			obj.classnn := classnn
			
			ControlGet, ctrl_id, HWND, , %classnn%, ahk_id %hwnd%
			obj.id := ctrl_id
			
			try {
				ControlGetText, text, , ahk_id %ctrl_id%
			} catch e {
				; Without this catch, a too large child-control text will assert #MaxMem error.
				; Example: a EmEditor v10+ "EmEditorView" child window with 300MB text.
				text := ""
			}
			obj.text := text

			ControlGetPos, x, y, w, h, , ahk_id %ctrl_id%
			obj.x := x
			obj.y := y
			obj.w := w
			obj.h := h
			
			arctrls.Insert(obj)
		}
	}

	if(arctrls.MaxIndex()>0)
		return arctrls
	else
		return None
}

ControlFocusViaRegexClassNNXY(Cregex, Tregex, xhint, yhint, is_click=true, is_movemouse=false
	, is_xomode=false, is_yomode=false)
{
/*
	Do the following operation in the active window:
	1. Find Cregex and Tregex matched child-window(cwin), 
	2. Get a screen position(target-pos) from xhint and yhint relative to cwin, 
	3. Set focus to the on-screen window at target-pos (target-window). 
	   Typically, target-window is another child window of current active window.
	
	NOTE: If is_click==false, in quite many cases, the target control cannot actually get focus.
	So, is_click==true is suggested most of the time, especially when you known the contol is visible.
*/	
	; 1.
	found := RegexClassnnFindControl(Cregex, Tregex, input_classnn, x, y, width, height, Awinid)
		; Awinid is the Active window's ID, not the control's.
	if not found
		return false
	;tooltip, coord: x/y %x% %y% . w/h %width% %height%
	; 2.
	targetx := NewCoordFromHint(x, width, xhint, is_xomode)
	targety := NewCoordFromHint(y, height, yhint, is_yomode)
	
	; 3.
	if (is_click) {
		;tooltip, targetx/y: %targetx% . %targety%
		ClickInActiveWindow(targetx, targety, is_movemouse)
			; hope that active window has not changed.
	}
	else {
		MouseGetPos, origx, origy
		MouseMove, %targetx%, %targety%
		MouseGetPos, _mx, _my, _winid, target_classnn
		ControlFocus, %target_classnn%, ahk_id %Awinid%
;		tooltip, % "ControlFocusViaRegexClassNNXY() target_classnn=" . target_classnn . " / hctrl=" . Get_HCtrlFromClassNN(target_classnn, "ahk_id " . Awinid)
		if (not is_movemouse)
			MouseMove, %xorig%, %yorig%
	}
	return true
}



; 2015-01-05
ControlClickClassNN_TitleRegex(classnn, titleregex, delay_millisec=0)
{
	; Find a window whose title matches titleregex, and click the control whose classNN is classnn.
	; If target window is not found, alert with a message box.
	SetTitleMatchMode, RegEx
	winfound := WinExist(titleregex) ; Note: must use := . If just = , winfound will always be true.
	if(winfound)
	{
;		WinActivate ahk_id %winfound% ; On my i7-4770K Win7, this is required
		if (delay_millisec>0)
			Sleep delay_millisec
		ControlClick, % classnn, % titleregex, , LEFT
	}
	
	SetTitleMatchMode, 3 ; restore to default exact match
	
	return winfound ? true : false
}


CheckControlBool(classnn, prop) 
{ 
	; classnn="Edit1" etc
	ControlGet, OutputVar, %prop%, , %classnn%, A
	return OutputVar ? true : false
}


WinMove_ClassTitleRegex(regex_cls, regex_title, absx:="", absy:="", width:="", height:="", notfound_msgbox:=false)
{
	; Find window(find first) by wndclass regex and wintitle regex, and move it.
	; * If regex_cls is "", wndclass is not checked. 
	; * If regex_title is "", window title is not checked. 
	; * If regex_cls and regex_title both present, they should both match.
	; Return:
	; * If target window found, return the moved windows winid.
	; * If target window not found, return 0
	
	WinGet, wnd, List
	isfound := false

	Loop, %wnd%
	{
		winid := wnd%A_Index%
		WinGetClass, class, ahk_id %winid%
		WinGetTitle, title, ahk_id %winid%
		WinGetPos, oldx, oldy, oldwidth, oldheight, ahk_id %winid%
		
		; msgbox, % "class=" . class . " , title=" . title ;// debug
		if( regex_cls && !(class ~= regex_cls) )
		{
			continue
		}
		
		if( regex_title && !(title ~= regex_title) )
		{
			continue
		}
		
		isfound := true
		break
	}
	
	;msgbox, % "Found: class=" . class . " , title=" . title . " , winid=" . winid ;// debug

	if(!isfound)
	{
		if(notfound_msgbox)
			MsgBox, Your regex ( "%regex_cls%" , "%regex_title%" )  does not match any existing window.
		return 0
	}

	if (absx == "") {
		absx := oldx
	}
	if (absy == "") {
		absy := oldy
	}
	if (width == "") {
		width := oldwidth
	}
	if (height == "") {
		height := oldheight
	}

	WinMove, ahk_id %winid% ,, absx, absy, width, height
	
	return winid
}

; Generic function: Move a regex-matched window to a given position, and bring it to front.
WinMove_MatchTitleRegex(regex, absx:="", absy:="", width:="", height:="")
{
	; this is old function. should be implemented with WinMove_ClassTitleRegex()

	SetTitleMatchMode, RegEx ;
	found_window := WinExist(regex)
	if found_window 
	{
		WinActivate, ahk_id %found_window%
		WinGetPos oldx, oldy, oldwidth, oldheight, A
		if (absx == "") {
			absx = %oldx%
		}
		if (absy == "") {
			absy = %oldy%
		}
		if (width == "") {
			; Note: oldwidth must be wrapped with %
			width = %oldwidth%
		}
		if (height == "") {
			height = %oldheight%
		}
		WinMove, A ,, absx, absy, width, height
	}
	else
	{
		MsgBox, Your regex "%regex%" does not match any existing window.
	}
	SetTitleMatchMode, 3 ; restore to default exact match
}


RegexBlindScrollAControl(sdir, wintitle, regexClassnn, regexControlText)
{
	; "Blind" means you don't have to activate or even don't have to see the to-be-scroll window.

	if(sdir!="up" and sdir!="down")
	{
		MsgBox, % msgboxoption_IconExclamation, , % "RegexBlindScrollAControl(): Invalid sdir value, sdir=" . sdir
		return false
	}
	
	isok := RegexClassnnFindControlEx(wintitle, regexClassnn, regexControlText, target_classnn)
	if(not isok)
	{
		return false
	}

	ControlClick, %target_classnn%, %wintitle%, , Wheel%sdir%, 1
	
	return true
}


dev_Hex2Num(HX)
{
	; https://autohotkey.com/boards/viewtopic.php?t=6434
    ; Assuming "0x" is always omitted (since in your script the "0x" will never occur anyway)
    
    ; Usage Example:
    ; integer_result := dev_Hex2Num("FF")+100 ;// integer_result will be 355
    
	SetFormat, integer, D
	Dec += "0x" HX
	return Dec
}

dev_GuiLabelSetText(GuiName, LabelName, text)
{
	GuiControl, %GuiName%:, %LabelName%, % text
}

dev_IsDictEmpty(dict)
{
	for key, value in dict {
		return false
	}
	return true
}


dev_GuiAutoResize(GuiName, rsdict, gui_nowwidth, gui_nowheight, force_redraw:=false, qmargin:="")
{
	; gui_nowwidth, gui_nowheight tells the GUI's client area size
	
	if(qmargin) ; q implies quad
	{
		; Example: qmargin:="10,20,10,20"
		token := StrSplit(qmargin, ",")
		x0m := token[1]
		y0m := token[2]
		x1m := token[3]
		y1m := token[4]

		nowwidth := gui_nowwidth - (x0m+x1m)
		nowheight := gui_nowheight - (y0m+y1m)
	}
	else 
	{
		x0m := 0
		y0m := 0
		x1m := 0
		y1m := 0
		nowwidth := gui_nowwidth
		nowheight := gui_nowheight
	}
	
;	MsgBox, % Format("nowwidth={} nowheight={} x0m={} y0m={}", nowwidth, nowheight, x0m, y0m)
	
	if( ! g_devGuiAutoResizeDict[GuiName] )
	{
		; It is the first time this GuiName is seen, which means this GUI is just created, 
		; so we initialize it. The ctrl's positions at this time are considered at their initial positions.
		
		gui_rsinfo := {}
		
		for ctrlvar, quad in rsdict
		{
			; Sample: ctrlvar="g_PvhtmlEdit" , qual="0,0,100,100"
			
			gui_rsinfo[ctrlvar] := {} ; a nested dict
			ctrl_rsinfo := gui_rsinfo[ctrlvar] ; define a label for easier reference
			
			token := StrSplit(quad, ",")
			ctrl_rsinfo.pct_left := token[1]/100
			ctrl_rsinfo.pct_top := token[2]/100
			ctrl_rsinfo.pct_right := token[3]/100
			ctrl_rsinfo.pct_bottom := token[4]/100
			
			GuiControlGet, rect, %GuiName%:Pos, %ctrlvar%
;			MsgBox, % Format("dev_GuiAutoResize({}.{}) Init:  rectX={}, rectY={}, rectW={}, rectH={}", GuiName, ctrlvar, rectX, rectY, rectW, rectH)
			
			ctrl_rsinfo.ofs_left := (rectX-x0m) - nowwidth * ctrl_rsinfo.pct_left
			ctrl_rsinfo.ofs_top  := (rectY-y0m) - nowheight * ctrl_rsinfo.pct_top
			ctrl_rsinfo.ofs_right := (rectX-x0m + rectW) - nowwidth * ctrl_rsinfo.pct_right
			ctrl_rsinfo.ofs_bottom := (rectY-y0m + rectH) - nowheight * ctrl_rsinfo.pct_bottom

;			MsgBox, % Format("dev_GuiAutoResize({}.{}) Init:  ofs:{},{},{},{}", GuiName, ctrlvar, ctrl_rsinfo.ofs_left, ctrl_rsinfo.ofs_top, ctrl_rsinfo.ofs_right, ctrl_rsinfo.ofs_bottom)
		}

		; Mark this GuiName "created".
		g_devGuiAutoResizeDict[GuiName] := gui_rsinfo ; to modify

	}
	else
	{
;		MsgBox, SecondTimeARS
		
		gui_rsinfo := g_devGuiAutoResizeDict[GuiName] ; define a label for easier reference
		
		for ctrlvar, ctrl_rsinfo in gui_rsinfo
		{
			; Calculate new positions for this ctrl
			newX := nowwidth * ctrl_rsinfo.pct_left + ctrl_rsinfo.ofs_left +x0m
			newY := nowheight * ctrl_rsinfo.pct_top + ctrl_rsinfo.ofs_top +y0m
			newW := nowwidth * ctrl_rsinfo.pct_right + ctrl_rsinfo.ofs_right - newX +x0m
			newH := nowheight * ctrl_rsinfo.pct_bottom + ctrl_rsinfo.ofs_bottom - newY +y0m

;			MsgBox, % Format("dev_GuiAutoResize Newpos({}:{}) is {},{} | {},{}", GuiName, ctrlvar, newX, newY, newW, newH)

			; Move this ctrl
			newpos := Format("x{} y{} w{} h{}", newX, newY, newW, newH)
			
			RedrawOp := force_redraw ? "MoveDraw" : "Move"
			
			GuiControl, %GuiName%:%RedrawOp%, %ctrlvar%, % newpos
		}
	}
}

dev_GuiAutoResizeRemove(GuiName)
{
	g_devGuiAutoResizeDict.Delete(GuiName)
}


;############### Zhongwen IME related ################
IsTypingZhongwen_PinyinJiaJia() 
{
	; 获知当前是否处于 拼音加加 中文输入状态。
	; 若是，意思是敲入的一个英文字母将被输入法浮动窗口吸收。
	; 若否，敲入的一个英文字母将直接被应用程序获得。
	
	; 本函数适用于 拼音加加 5.2 。
	
	if WinExist("ahk_class PYJJ_STATUS_WND")
	{
		; PYJJ_STATUS_WND 是拼音加加附着在应用程序标题上的状态条。
		; 接下来检查拼音加加状态条最右侧的那个小格是否是“全”字（全拼状态），
		; 检查“全”字尖顶的那个粉红像素(x78, y3)，有的话则表示中文输入状态。
		; 暂不处理双拼。
		
		WinGetPos, jjx, jjy, jjw, jjh, ahk_class PYJJ_STATUS_WND
		CoordMode, Pixel, Screen
		PixelGetColor, color, jjx+78, jjy+3, RGB
		CoordMode, Pixel, Window
		if(color==0xFF0099)
			return true
		else
			return false
	}
	else
	{
		return false
	}
}

ToggleZhongwenStatus_PinyinJiaJia(is_zhongwen_on)
{
	zs := IsTypingZhongwen_PinyinJiaJia()
	if( (zs && !is_zhongwen_on) || (is_zhongwen_on && !zs))
		SendInput {Shift down}{Shift up}{Ctrl down}{Ctrl up}
	return zs ; return original status
}


ClipboardGet_HTML( byref Data ) 
{ ; https://autohotkey.com/board/topic/59058-convert-clipboard-data-to-html/#entry373078
 If CBID := DllCall( "RegisterClipboardFormat", Str,"HTML Format", UInt )
  If DllCall( "IsClipboardFormatAvailable", UInt,CBID ) <> 0
   If DllCall( "OpenClipboard", UInt,0 ) <> 0
    If hData := DllCall( "GetClipboardData", UInt,CBID, UInt )
       DataL := DllCall( "GlobalSize", UInt,hData, UInt )
     , pData := DllCall( "GlobalLock", UInt,hData, UInt )
     , VarSetCapacity( data, dataL * ( A_IsUnicode ? 2 : 1 ) ), StrGet := "StrGet"
     , A_IsUnicode ? Data := %StrGet%( pData, dataL, 0 )
                   : DllCall( "lstrcpyn", Str,Data, UInt,pData, UInt,DataL )
     , DllCall( "GlobalUnlock", UInt,hData )
 DllCall( "CloseClipboard" )
Return dataL ? dataL : 0
}

dev_ClipboardSetHTML(html, is_paste_now:=false, wait_hwnd:=0)
{
	; [2022-04-28] Limitation: 
	; After calling WinClip.SetHTML(), the clipboard contains only
	; one format("HTML Format"), i.e. no "Text" format. So, subsequent 
	; `Clipboard` variable will return empty text.

	WinClip.Clear()
	WinClip.SetHTML(html)

	if(is_paste_now)
	{
		if(wait_hwnd)
		{
			dev_TooltipAutoClear(Format("Wait for paste-target window to be active. Hwnd={}", wait_hwnd))
			WinWaitActive, % "ahk_id " wait_hwnd, , 1.0

			if not ErrorLevel 
			{
				tooltip ; clear tooltip
			}
			else
			{
				dev_MsgBoxWarning(Format("Fail to wait for paste-target window to become active.`r`n`r`n"
						. "Hwnd={}`r`n`r`n"
						. "So I can not paste for you. You can manually paste it by typing Ctrl+V ."
						, wait_hwnd)
					, "AmHotkey - Everpic Wrinkle")
				return ; So not paste into wrong window.
			}
		}
		
		WinClip.Paste()
	}
}

dev_IsWinclassExist(classname)
{
	if WinExist("ahk_class " . classname) {
		return true
	} 
	else {
		return false
	}
}

dev_GetActiveEXE_PathName()
{
	WinGet, exepath, ProcessPath, A
	SplitPath, exepath, filename, dirpath
	return [dirpath, filename]
	; retarray[1] is dirpath, retarray[2] is filename .
}

dev_mapping_count(map)
{
	; Count how many keys are in a map(dict)
	count := 0
	for key, val in map
		count++
	return count
}

dev_GetHwndByExepath(exepath)
{
	WinGet topwnd, List
	Loop %topwnd%
	{
		hwnd := topwnd%A_Index%
		WinGet, tmppath, ProcessPath, ahk_id %hwnd%
		if(exepath==tmppath) 
		{
			return hwnd
		}
	}
	return None
}

dev_IsExeActive(exefile)
{
	; exefilename sample :
	; 	"notepad.exe"
	; or 
	;   "D:\portableapps\MPC-HC-Portable\App\MPC-HC\mpc-hc.exe"
	
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGet, exepath, ProcessPath, ahk_id %Awinid%

	if(InStr(exefile, "\"))
	{
		; consider exefile as fullpath, need exact match
		if(exepath==exefile)
			return true
		else
			return false
	}
	else
	{
		; consider exefile as filenam only, match only final component.
		if( StrIsEndsWith(exepath, "\" . exefile) )
			return true
		else
			return false
	}
}

dev_IsExePathMatchRegex(regex)
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGet, exepath, ProcessPath, ahk_id %Awinid%

	foundpos := RegExMatch(exepath, regex)
	if (foundpos>0)
		return true
	else 
		return false
}

dev_StrRepeat(string, times)
{
    loop % times
        output .= string
    return output
}

test_EnumDisplayMonitors()
{
	mlo := dev_EnumDisplayMonitors()
	MsgBox, % mlo.desctext
}

dev_EnumDisplayMonitors()
{
	mlo := g_tmpMonitorsLayout ; create a short-name reference to the global var 
		; this global var is required to communicate with the callback function devcb_EnumDisplayMonitors()
	mlo.count := 0
	mlo.monitor_rects := []
	mlo.workarea_rects := []
	mlo.desctext := ""

	hCB := RegisterCallback("devcb_EnumDisplayMonitors", "F", 4, 0)
	if DllCall("user32\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", hCB, "UInt", 0)
	{
		mlo.desctext := "Monitor layout (L,T , R,B):`n`n"
		Loop, % mlo.monitor_rects.Length()
		{
			rect := mlo.monitor_rects[A_Index]
			width := rect.right - rect.left
			height := rect.bottom - rect.top
			mlo.desctext .= Format("[{1}] {2},{3} , {4},{5}   ({6}x{7})`n", A_Index, rect.left, rect.top, rect.right, rect.bottom, width, height)
		}
		; MsgBox, % mlo.desctext ; debug
	}
	else 
	{
		MsgBox, % "Unexpected! Calling WinAPI EnumDisplayMonitors() failed!"
	}

	return mlo.Clone()
}

devcb_EnumDisplayMonitors(hMonitor, hDC, pRect, arg)
{
	if !hMonitor
	    return false

	static sizeof_GetMonitorInfo := 40
;	typedef struct tagMONITORINFO {
;	  DWORD  cbSize; 
;	  RECT   rcMonitor; 
;	  RECT   rcWork; 
;	  DWORD  dwFlags; 
;	} MONITORINFO, *LPMONITORINFO; 

	VarSetCapacity(mi, sizeof_GetMonitorInfo) ; mi: MonitorInfo
	NumPut(sizeof_GetMonitorInfo, mi, 0, Int) ; init cbSize with struct size

	DllCall("GetMonitorInfo", Ptr, hMonitor, Ptr, &mi)
;	MsgBox, % Format("Monitor L/T/R/B: {1},{2},{3},{4}", NumGet(mi, 4, Int), NumGet(mi, 8, Int), NumGet(mi, 12, Int), NumGet(mi, 16, Int))

	rect := {}
	rect.left := NumGet(mi, 4, Int)
	rect.top := NumGet(mi, 8, Int)
	rect.right := NumGet(mi, 12, Int)
	rect.bottom := NumGet(mi, 16, Int)
	;
	rect_workarea := {}
	rect_workarea.left := NumGet(mi, 20, Int)
	rect_workarea.top := NumGet(mi, 24, Int)
	rect_workarea.right := NumGet(mi, 28, Int)
	rect_workarea.bottom := NumGet(mi, 32, Int)

	mlo := g_tmpMonitorsLayout ; create a short-name reference to the global var
	mlo.monitor_rects.Push(rect)
	mlo.workarea_rects.Push(rect_workarea)
	mlo.count += 1

;	MsgBox, % Format("devcb_EnumDisplayMonitors [{1}]`nL={2} T={3} R={4} B={5} , W={6} H={7} `nL={8} T={9} R={10} B={11} , W={12} H={13}", mlo.count
;		, rect.left, rect.top, rect.right, rect.bottom, (rect.right-rect.left), (rect.bottom-rect.top)
;		, rect_workarea.left, rect_workarea.top, rect_workarea.right, rect_workarea.bottom, (rect_workarea.right-rect_workarea.left), (rect_workarea.bottom-rect_workarea.top)) ; debug
	return true
}

dev_XYinRect(x, y, rect_)
{
	if(x>=rect_.left && x<rect_.right && y>=rect_.top && y<rect_.bottom)
		return true
	else
		return false
}


dev_TooltipDisableCloseWindow(msg_prefix)
{
	; In many applications, Ctrl+W etc would close current window/tab, and I hate it. 
	; So call this function to hint that.
	; msg_prefix is some hotkey names like "Ctrl+W" or "Ctrl+Shift+W".
	dev_TooltipAutoClear(msg_prefix . " closing window/tab is disabled by AmHotkey.")
}


dev_getCallStack(deepness = 20, is_print_code = true)
{
	; Call this function to get current callstack.
	; Usage: If we want to report an error to user(MsgBox etc), showing a full callstack helps greatly.
	;
	; Thanks to: https://www.autohotkey.com/board/topic/76062-ahk-l-how-to-get-callstack-solution/
	
	lv_first_print := -1
	
	loop % deepness
	{
		lvl := -1 - deepness + A_Index
		oEx := Exception("", lvl)
		oExPrev := Exception("", lvl - 1)
		FileReadLine, line, % oEx.file, % oEx.line
		if(oEx.What = lvl)
			continue
			
		if(lv_first_print==-1) 
			lv_first_print := A_Index
		
		stack .= (stack ? "`n" : "") . Format("#{1}： ",A_Index-lv_first_print+1) . "File '" oEx.file "', Line " oEx.line (oExPrev.What = lvl-1 ? "" : ", in " oExPrev.What) (is_print_code ? ":`n" line : "") "`n"
	}
	return stack
}

dev_hasValue(haystack, needle) 
{
	; Check if needle is in the haystack array.
	; https://stackoverflow.com/a/33593563/151453
    
    if(!IsObject(haystack))
        return false
    if(haystack.Length()==0)
        return false
    for k,v in haystack
        if(v==needle)
            return true
    return false
}

dev_Menu_CreateEmpty(menuname)
{
	dev_Menu_DeleteAll(menuname)
	
	Menu, % menuname, Add, "===empty===", dev_Menu_DoNone
	Menu, % menuname, DeleteAll
}

dev_Menu_DeleteAll(menuname)
{
	try {
		Menu, % menuname, DeleteAll
	} catch {
	}
}

dev_Menu_DoNone()
{
}

dev_GetCurrentDatetime(format)
{
	FormatTime, outvar, , %format%
	return outvar
}

dev_SplitPath(input, byref Filename:="")
{
	SplitPath, input, Filename, OutDir
	return OutDir
}

dev_SplitExtname(input, byref dotext:="")
{
	SplitPath, input, Filename, OutDir, OutExt, OutNameNoExt
	dotext := "." OutExt
	return Format("{}\{}", OutDir, OutNameNoExt) ; the stempath
}

dev_FindVacantFilename(path_ptn, start_seq:=1, max_seq:=10000)
{
	; If path_ptn=="d:\test\foo{}.txt", we'll search for 
	;	d:\test\foo1.txt
	;	d:\test\foo2.txt
	;	d:\test\foo3.txt
	; until the first non-existing filename/dirname is found.

	if(!InStr(path_ptn, "{}"))
		return ""
	
	now_seq := start_seq
	Loop
	{
		if(now_seq>max_seq)
			return ""
	
		nowpath := Format(path_ptn, now_seq)
		if(!FileExist(nowpath))
			return nowpath

		now_seq += 1
	}
}

dev_EscapeHtmlChars(text)
{
	text := StrReplace(text, "&", "&amp;")
	text := StrReplace(text, "<", "&lt;")
	text := StrReplace(text, ">", "&gt;")
	return text
}

dev_IsSameFiletime(file1, file2)
{
	FileGetTime, time1, % file1
	FileGetTime, time2, % file2
	
	if(time1 && time1==time2)
		return true
	else
		return false
}

dev_IsBinaryFile(filepath, bytes_to_check:=8192)
{
	; Note: UTF-16 text files will be considered as binary.
	; We only check for byte-value >=0 and <9 , so, text files encoded in MBCS(GBK etc)
	; will still be considered text. For a GBK file, there will be byte-value >=128.
	; Also, UTF-8 file with BOM will not be considered binary.

	FileGetSize, filelen, % filepath
	if ErrorLevel
		return false

	if(filelen==0)
		return true

	isbin := false ; assume false

	if(filelen<bytes_to_check)
		bytes_to_check := filelen

;	dev_WriteLogFile("binlog.txt", "Byte dump of " filepath "`n", false) ; debug

	file := FileOpen(filepath, "r", "UTF-8-RAW")
	if(!IsObject(file))
		return false
	
	; Seek to file start explicitly.
	; Withouth this, Autohotkey will skip BOM bytes for us, which is not desired.
	file.Pos := 0
	
	file.RawRead(buffer, bytes_to_check)
	
	Loop, % bytes_to_check
	{
		byteval := NumGet(buffer, A_Index-1, "UChar")
		
;		dev_WriteLogFile("binlog.txt", Format("{1:02X}`n", byteval)) ; debug
		
		if(byteval>=0 && byteval<9)
		{
			isbin := true
		}
	}
	
	file.Close()
	return isbin
}


dev_IsExeRunning(exename)
{
	Process, Exist, % exename
	if ErrorLevel
	{
		; ErrorLevel is the pid.
		return true
	}
	else
	{
	    return false
	}
}

dev_LocalTimeZoneInMinutes()
{
	; For China, it returns 480 (8*60)
	
	VarSetCapacity(Tzinfo, 200, 0)
	DllCall("GetTimeZoneInformation", Ptr,&Tzinfo)
	
	tzminutes := NumGet(&Tzinfo, 0, "Int")
	return -tzminutes
}

dev_LocalTimeZoneMinutesStr()
{
	tzminutes := dev_LocalTimeZoneInMinutes()
	if(tzminutes>=0)
		return Format("+{:02X}{:02X}", tzminutes/60, Mod(tzminutes, 60))
	else
		return Format("-{:02X}{:02X}", (-tzminutes)/60, Mod(-tzminutes, 60))
}

dev_IsShiftKeyDown()
{
	GetKeyState, state, Shift
	if(state=="D")
	    return true
	else
	    return false

}

;==============================================================================
#Include *i _more_includes_.ahk ;This should be the final statement of this ahk
;==============================================================================

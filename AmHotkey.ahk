; AmHotkey is the Modularized Autohotkey framework, created by Jimm Chen since 2010,
; based on the fantastic Autohotkey script engine.
;
; Tested with Autohotkey v1.1.32.00

#InstallKeybdHook

; Switch #include base-dir to A_ScriptDir:
#Include %A_ScriptDir%

#Include *i custom_env.ahk ; optional 

global NOERROR_0 := 0

global g_winmove_unit := 50 ; window move unit small
global g_winmove_scale := 5 ; window move 5x larger step if you tap LCtrl just before doing win move

global g_saved_xMouseScreen := 0
global g_saved_yMouseScreen := 0


global g_MouseNudgeUnit = 10
global g_MouseNudgeUnitAM = 10 ; AM: Application Match
global g_MouseNudgeTitleAM = "Non-existing title"
	; Write ``global`` so that these vars can be referenced in later functions' body.

global g_AmMute := false


global g_RCtrl_WinMoveScale_graceticks = 3000

global gu_TxtLabelDefault := ""

global g_func_IsTypingZhongwen := "IsTypingZhongwen_PinyinJiaJia"
global g_func_IMEToggleZhonwen := "ToggleZhongwenStatus_PinyinJiaJia"
	; User can override these two function pointers to suit their own IME(Input MEthod).


;;;;;;;;;;;;;;;;;;;;;;;;;; ^^^ user configurable globals end ^^^ ;;;;;;;;;;;;;;;;;;;;;;;;;;


global g_UntitledNotpad := "Untitled - Notepad"

;global gc_AutoexecLabelsFilename := ""
global gc_AutoexecLabelsFilepath := A_ScriptDir "\autoexec-labels.autogen.ahk"
; #Include the very file right now, which is required by exerun.
#Include *i %A_ScriptDir%\autoexec-labels.autogen.ahk


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

global gc_customize_ahk := "customize.ahk"

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

global g_amstrMute := "AM: Mute clicking sound"

global g_DefineHotkeyLogfile := "DefineHotkeys.log"

global g_tmpMonitorsLayout := {}

global g_AmHotkeyFilepath := A_LineFile ; Record my real filepath at runtime.
global g_AmHotkeyDirpath  := dev_SplitPath(g_AmHotkeyFilepath)

global g_isdbg_DefineHotkeyLegacy := g_isdbg_DefineHotkeyLegacy_default
global g_isdbg_DefineHotkeyFlex   := g_isdbg_DefineHotkeyFlex_default
; -- User can override g_isdbg_DefineHotkeyFlex_default in custom_env.ahk .



;==========;==========;==========;==========;==========;==========;==========;==========;
; All global vars should be defined ABOVE this line, otherwise, they will be null.
;==========;==========;==========;==========;==========;==========;==========;==========;

AmHotkey_DoInit()

Amhotkey_ScanAndLoadAutoexecLabels()

return 

;################################################################################################ 
;################################### Global-exec section ENDS ################################### 
;################################################################################################ 


#Include %A_LineFile%\..\libs\debugwin.ahk
#Include %A_LineFile%\..\libs\WinClipAPI.ahk
#Include %A_LineFile%\..\libs\WinClip.ahk
#include %A_LineFile%\..\libs\Amhk-common.ahk
#include %A_LineFile%\..\libs\Amhk-gui.ahk
#include %A_LineFile%\..\libs\ClipboardMonitor.ahk

class AmHotkey ; Store global vars here
{
	static dbgid_HotkeyFlex := "HotkeyFlex"
	static dbgid_HotkeyLegacy := "HotkeyLegacy"
}


AmHotkey_DoInit()
{
	AmDbg_SetDesc(AmHotkey.dbgid_HotkeyFlex,   "Debug message for fxhk_DefineHotkey() functions.")
	AmDbg_SetDesc(AmHotkey.dbgid_HotkeyLegacy, "Debug message for dev_DefineHotkey() legacy functions.")
	
	dev_MenuAddSepLine("TRAY")
	dev_MenuAddItem("TRAY", Format("== {} ==", ts14short()), "dev_nop") ; so to distinguish different AmHotkey instance.
	dev_MenuAddItem("TRAY", "Show debug-message window", "Dbgwin_ShowGui")
	dev_MenuAddItem("TRAY", "Configure debug-modules", "Amdbg_ShowGui")

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
	; there may not be an active window(``Awinid := dev_GetActiveHwnd()`` reports Awinid==null),
	; so we can use this function to bring up the last seen active window.

	Awinid := dev_GetActiveHwnd() ; cache active window unique id
	
	if(!Awinid)
	{
		SendInput !{TAB} 
		
		Loop, 10
		{
			Awinid := dev_GetActiveHwnd()
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
	
	cliRel := dev_WinGetClientAreaPos(hwnd)
	caLeft := cliRel.x
	caTop := cliRel.y
	caRight := cliRel.x_
	caBottom := cliRel.y_
	caWidth := cliRel.w
	caHeight := cliRel.h
	
	CoordMode, Mouse, Screen
	MouseGetPos, mxScreen, myScreen
	
	CoordMode, Mouse, Window
	MouseGetPos, mxWindow, myWindow, tophwnd_undermouse, classnn
	if(classnn)
	{
		; Get child's relative position(relative to parent window's top-left corner).
		ControlGetPos, xr_child, yr_child, wr_child, hr_child, %classnn%, ahk_id %tophwnd_undermouse%
		xrend_child_ := xr_child + wr_child
		yrend_child_ := yr_child + hr_child

		; Get child's absolute position(screen coordinate).
		ControlGet, hctrl_undermouse, HWND, , %classnn%, ahk_id %tophwnd_undermouse%
		WinGetPos, x_child, y_child, w_child, h_child, ahk_id %hctrl_undermouse%
		xend_child_ := x_child + w_child
		yend_child_ := y_child + h_child
		
		isHCtrlUnicode := DllCall("IsWindowUnicode", "Ptr", hctrl_undermouse)
		ynHCtrlUnicode := isHCtrlUnicode ? "yes" : "no"
		
		info_child =
		(
ClassNN under mouse is "%classnn%"
hwndCtrl under mouse is "%hctrl_undermouse%"
RelaPos: X ( %xr_child% ~ %xrend_child_% ), Y ( %yr_child% ~ %yrend_child_% ), size ( %wr_child% x %hr_child% )
AbsPos: X ( %x_child% ~ %xend_child_% ), Y ( %y_child% ~ %yend_child_% ), size ( %w_child% x %h_child% )
IsWindowUnicode? [%ynHCtrlUnicode%]
		)
	}
	else
	{
		classnn := ""
		info_child := "No child-window under mouse cursor."
	}

	info =
	(
The Active window class is "%class%" (Hwnd=%hwnd%)
Title is "%title%"
Position  : X ( %x% ~ %x_end_% ), Y ( %y% ~ %y_end_% ), size ( %w% x %h% )

Client area: rX ( %caLeft% ~ %caRight% ), rY ( %caTop% ~ %caBottom% ), size ( %caWidth% x %caHeight% )

Current focused classnn: %focusNN%
Current focused hctrl: ahk_id=%focus_hctrl%

Process ID: %pid%
Process path: %exepath%

Mouse position: In-window: (%mxWindow%,%myWindow%)  `; In-screen: (%mxScreen%,%myScreen%)

%info_child%

Answer [Yes] to see more system info.
	)
	
	more := dev_MsgBoxYesNo(info, false)
	if(more)
	{
		Dbg_DumpSysInfo(true)
		Dbg_DumpChildWinsInfo(tophwnd_undermouse)
	}
}

dbgline_onevar(varname, showfmt:="")
{
	if(not showfmt)
		str := Format("{} = {}`n", varname, %varname%)
	else if(showfmt=="t/f")
		str := Format("{} = {}`n", varname, %varname% ? "true" : "false")
	else if(showfmt=="hex")
		str := Format("{} = 0x{:08X}`n", varname, %varname%)
	
	return str
}

Dbg_DumpSysInfo(force_fgwin:=false)
{
	info := "System info:`n"
	info .= dbgline_onevar("A_OSVersion")
	info .= dbgline_onevar("A_Is64bitOS", "t/f")
	info .= dbgline_onevar("A_PtrSize")
	info .= dbgline_onevar("A_IsAdmin", "t/f")
	info .= dbgline_onevar("A_AppData")
	info .= dbgline_onevar("A_ScreenDPI")
	info .= dbgline_onevar("A_AhkVersion")
	info .= dbgline_onevar("A_AhkPath")
	info .= dbgline_onevar("A_WorkingDir")
	info .= dbgline_onevar("A_ScriptDir")
	info .= dbgline_onevar("A_ScriptName")
	info .= dbgline_onevar("A_ScriptFullPath")
	info .= dbgline_onevar("A_FileEncoding")
	info .= dbgline_onevar("A_ScriptHwnd", "hex")
	info .= dbgline_onevar("A_IsUnicode", "t/f")
	info .= dbgline_onevar("A_IsCompiled", "t/f")
	
	Dbgwin_Output(info, force_fgwin)
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

GetFirstNoncommentLine(ahkfilepath)
{
	Loop, read, %ahkfilepath%
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

amhk_AddAutoExecAhk(arAutoexecLabels, ahkdir, filename)
{
	static s_dictAutoexecExistingFname := {} ; for checking duplicate
	static s_dictAutoexecExistingLabel := {} ; for checking duplicate

	ahkfilepath := ahkdir . "\" . filename

	; check and skip duplicate
	if(s_dictAutoexecExistingFname.HasKey(ahkfilepath)) {
		return
	}

	; Check whether the first non comment line is in pattern AUTOEXEC_xxx:
	chkline := GetFirstNoncommentLine(ahkfilepath)
	
	foundpos := RegExMatch(chkline, "^(AUTOEXEC_[a-zA-Z0-9_.]+)\:", subpat)
	if( foundpos>0 )
	{
		autoexec_label := subpat1

		if(s_dictAutoexecExistingLabel.HasKey(autoexec_label))
		{
			; [2023-04-20] As of Autohotkey 1.1.32, this code will not have a chance to execute,
			; bcz AHK engine will detect "Duplicate label" error and refuse to load the whole AHK.
			dev_MsgBoxError(Format("User AHK error detected! The same label '{}' is defined in two ahk files:`n`n"
				. "{}`n"
				. "{}`n"
				, autoexec_label, s_dictAutoexecExistingLabel[autoexec_label], ahkfilepath))
		}

		filename := dev_StripPrefix(ahkfilepath, A_ScriptDir "\")
		arAutoexecLabels.Insert( {"filename":filename , "label":autoexec_label} )
		s_dictAutoexecExistingFname[ahkfilepath] := autoexec_label
		
		s_dictAutoexecExistingLabel[autoexec_label] := ahkfilepath
;		Dbgwin_Output(autoexec_label " => " ahkfilepath)
	}
}

Amhotkey_ScanAndLoadAutoexecLabels()
{
	; "Call" auto-exec sections collected(for those ahks with AUTOEXEC_xxx: label at start of file)

	if(!A_IsCompiled)
	{
		arAutoexecLabels := []
		
		amhk_ScanAhkFilesForAutoexecLabels(arAutoexecLabels)
		amhk_CallAutoexecLabels(arAutoexecLabels)
	}
	else
	{
		; For Ahk2Exe-compiled AmHotkey.exe
		
		if(not AutoexecForExe.labels)
		{
			dev_MsgBoxError("The file 'autoexec-labels.autogen.ahk' did NOT exist or had wrong content "
				. "when compiling this AHK-exe. You have to re-compile this exe.")
			ExitApp
		}

		dict_DoneLabels := {}
		
		for i,label in AutoexecForExe.labels
		{
			if(!dict_DoneLabels.HasKey(label) && IsLabel(label))
			{
				dict_DoneLabels[label] := true
;				Dbgwin_Output("AHK-exe found existing label: " label) ; debug
				GoSub, %label%
			}
		}
	}

}

amhk_ScanAhkFilesForAutoexecLabels(arAutoexecLabels)
{
	; Scan all ahk files in the same folder as the master(startup) ahk file,
	; and store all found AUTOEXEC_xxx label info into arAutoexecLabels[] .

	Loop, Files, % g_AmHotkeyDirpath "\*.ahk", R
	{
		; Loop, %A_ScriptDir%\*.ahk ; this matches XXX.ahkx , XXX.ahky etc (AHK bug?)
		; so I have to filter it once more.
		
		if(InStr(A_LoopFileFullPath, ".no-ahk"))
		{
			; We deliberately skip those dir with ".no-ahk" suffix.
			continue
		}
		
		if(amhk_IsAutoGlobalFilename(A_LoopFileName))
		{
			amhk_AddAutoExecAhk(arAutoexecLabels, A_LoopFileDir, A_LoopFileName)
		}
	}
	
	; If user has his own startup Script(known via A_ScriptDir, instead of AmHotkey.ahk), 
	; we scan and load ahk modules there.
	;
	if(not dev_StrIsEqualI(A_ScriptDir, g_AmHotkeyDirpath))
	{
		Loop, Files, %A_ScriptDir%\*.ahk, R
		{
			if(amhk_IsAutoGlobalFilename(A_LoopFileName))
			{
				amhk_AddAutoExecAhk(arAutoexecLabels, A_LoopFileDir, A_LoopFileName)
			}
		}
	}

	amhk_AddAutoExecAhk(arAutoexecLabels, A_ScriptDir, gc_customize_ahk)
	; -- Load this at the final stage, because it is intended to override some 
	;    global vars defined by other modules.
	
	; [2022-12-28] Ahk2Exe support code:
	;
	autogen_content_fmt =
(
class AutoexecForExe
{
	static labels := [ "NullLabel_placeholder"
{}, "NullLabel_placeholder"]
}
) ; Look out. Above 5 lines are AHK strings, not AHK statements. Don't reformat it casually.
	strlabels := ""
	for i,label in arAutoexecLabels
	{
		; Prepare each line as an AutoexecForExe.labels[] element, as ahk array definition syntax.
		strlabels .= Format("`t`t, ""{}""`r`n", label.label)
	}
	
	autogen_content := Format(autogen_content_fmt, strlabels)
	
	dev_WriteWholeFile(gc_AutoexecLabelsFilepath, autogen_content)
}


amhk_IsAutoGlobalFilename(filenam)
{
	if(not filenam ~= ".ahk$" )
		return false

	if(filenam==A_ScriptName)
		return false ; skip self
	
	if(filenam==gc_customize_ahk)
		return false ; leave this at end
		
	if(InStr(filenam, " "))
		return false ; reject those with spaces in filename
	
	return true
}

amhk_CallAutoexecLabels(arAutoexecLabels)
{
	module_count := 0
	msglistmodules := ""
	
	for index, autolabel in arAutoexecLabels 
	{
		dict_DoneLabels := {}
	
		label_varname := autolabel.label

		if(!dict_DoneLabels.HasKey(label_varname) && IsLabel(label_varname)) 
		{
			dict_DoneLabels[label_varname] := true
		
			module_count++
			msglistmodules .=  module_count ". " autolabel.filename " [" label_varname "]`n"
			
			; Jump to one AUTOEXEC_xxx_ahk label:
			;
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
		srcfile := Format("{}\{}", A_ScriptDir, "_more_includes_.ahk.sample")
		dstfile := Format("{}\{}", A_ScriptDir, "_more_includes_.ahk")

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
	start_msgbox_info =
(
%A_ScriptDir%\%A_ScriptName% has loaded the following modules:`n
%msglistmodules%
)
	dev_MsgBoxInfo(start_msgbox_info, "AmHotkey script loading info")
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


; !#f:: devtest_TryFocusUicBeneathMouse() 
devtest_TryFocusUicBeneathMouse()
{
	; Try to set focus to the control beneath current mouse pointer.
	MouseGetPos, _mx, _my, hwnd, target_classnn
	ControlFocus, %target_classnn%, A ; [2015-02-10] Strange, without explicity A param, it will not succeed.
	if not ErrorLevel {
		tooltip, % "New focus @ #" . hwnd . " classnn=" . target_classnn
	} else {
		MsgBox, % "ControlFocus reports ErrorLevel = " . ErrorLevel
	}
}

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
;#################### Environment checking functions ##########################
;##############################################################################

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

; ===============================================================================================

dbgHotkeyFlex(msg)
{

	AmDbg_output(AmHotkey.dbgid_HotkeyFlex, msg)
}

dbgHotkeyLegacy(msg)
{
	AmDbg_output(AmHotkey.dbgid_HotkeyLegacy, msg)
}

_fxhk_KeynameStripPrefix(keyname)
{
	; Purpose: On Autohotkey 1.1.36 and many prior versions, I see that, when a Hotkey callback 
	; is called, the A_ThisHotkey is not exactly the same as when we formerly told `Hotkey` command.
	; For example "$NumpadDiv" becomes "NumpadDiv", but "$NumpadLeft" remains "$NumpadLeft".
	; So, we need to strip off "~" and "$", and use the stripped-off form as dict-key to 
	; Amhk.HotkeyFlexDispatcher .

	keyname := dev_StripPrefixChars(keyname, "~$")
	return keyname
}

_fxhk_KeynameAddHppPrefix(keyname)
{
	if(_fxhk_IsComboKeyname(keyname))
	{
		; User assigns a "Custom combination" keyname (CcHotkey) like "Esc & 1", 
		; then we need to add ~ prefix,
		; so that Esc key's native action is not blocked (=keepnative).
		return "~" keyname
	}
	else
	{
		; User assigns a keyname like "F1", and we need to add $ prefix,
		; so that we can delay-determine whether to passthru this hotkey.
		return "$" keyname
	}
}

_fxhk_IsComboKeyname(keyname, byref prefix_keyname="", byref suffix_keyname:="")
{
	if(InStr(keyname, " & "))
	{
		dual := StrSplit(keyname, " & ")
		prefix_keyname := dual[1]
		suffix_keyname := dual[2]
		return true
	}
	else
	{
		return false
	}
}


; [2023-01-06] Brandnew dynamic hotkey definition.
; User can attach multiple actions to the same [hotkey-and-condition pair].
; User parameter fn_cond and fn_act, can be any "callable" variable, which include:
; * a string representing a function name, or
; * a function object name, or 
; * a Bind("funcname")-returned object. // to fix: BoundFunc object?
;
; fn_cond: The condition to run fn_act. If fn_cond=="", then fn_act is always run.

_in_dev_DefineHotkeyFlex(user_keyname, purpose_name, comment, is_passthru, fn_cond, fn_act, act_args*)
{
	; user_keyname is the "KeyName" param that can be passed to `Hotkey` internal command.
	; e.g., "F1"
	
	; Check input param validity >>>
	
	if(StrLen(fn_cond)>0)
	{
		errmsg := Format("ERROR on 'fn_cond' param: ""{}"" is not a string representing a function name.", fn_cond)
		dev_assert(dev_IsExistingFuncName(fn_cond), errmsg)
	}
	
	if(comment!="_off_")
	{
		errmsg := Format("ERROR on 'fn_act' param: ""{}"" is not a string representing a function name.", fn_act)
		dev_assert(dev_IsExistingFuncName(fn_act), errmsg)
	}
	
	; Check input param validity <<<
	
	is_add := comment!="_off_" ? true : false
	
	dev_assert(user_keyname!="")
	if(is_add)
		dev_assert(fn_act!="")
	
	if(user_keyname=="" || (is_add && fn_act==""))
		return ""

	s_dp := Amhk.HotkeyFlexDispatcher ; the static global
	
	; Data structure example:
	;
	; s_dp["F1"]["purpose_auto1"].comment
	; s_dp["F1"]["purpose_auto1"].fn_cond
	; s_dp["F1"]["purpose_auto1"].fn_act
	; s_dp["F1"]["purpose_auto1"].act_args
	;
	; s_dp["F1"]["purpose_auto2"].comment
	; s_dp["F1"]["purpose_auto2"].fn_cond
	; s_dp["F1"]["purpose_auto2"].fn_act
	; s_dp["F1"]["purpose_auto2"].act_args
	
	
	; If purpose_name is null, a new purpose_name will be auto-generated.
	; If purpose_name is not null, old purpose_name will be replaced.
	;
	; If `comment` is "_off_", the hotkey by [keyname-purpose_name] is to be removed.
	
	; Note: $ and ~ keyname prefixes are ignored by _in_dev_DefineHotkeyFlex(),
	; bcz $ and ~ is incompatible with _in_dev_DefineHotkeyFlex() intrinsic logic.
	; Workaround: To make a Hotkey do it original work(the work when AHK is not run),
	;     user should set param is_passthru=true. If user registers multiple fn_act-s
	;     on the same Hotkey, any is_passthru=true makes it true.
	;
	keynamed := _fxhk_KeynameStripPrefix(user_keyname) ; keyname as dict-key
	hpp_keyname := _fxhk_KeynameAddHppPrefix(keynamed) ; hpp: hook($) or passthru(~) prefix
	
	dbgHotkeyFlex(Format("user_keyname=〖{}〗, keynamed=〖{}〗, hpp_keyname=〖{}〗", user_keyname, keynamed, hpp_keyname))
	
	if(is_add)
	{
		; create first-level object for keynamed
		if(not s_dp[keynamed])
		{
			dbgHotkeyFlex(Format("Create empty object s_dp[""{}""]", keynamed))
			s_dp[keynamed] := {}
		}
		
		if(purpose_name=="")
			purpose_name := _create_auto_purposename(s_dp[keynamed])
		
		is_new_purpose := not s_dp[KeyNamed].HasKey(purpose_name)
		
		dbgHotkeyFlex( Format("{} hotkey 〖{}〗 of purpose-name: ""{}""`r`n"
			. "    .is_passthru = {}`r`n"
			. "    .comment = {}`r`n"
			. "    .fn_cond = {}`r`n"
			. "    .fn_act  = {}`r`n"
			. "    .act_args (count) = {}"
			, (is_new_purpose?"Create":"Update"), keynamed, purpose_name
			, is_passthru ? "true" : "false"
			, comment
			, _tryget_funcobj_name(fn_cond)
			, _tryget_funcobj_name(fn_act)
			, act_args.Length() ))
		
		if(not s_dp[keynamed][purpose_name])
			s_dp[keynamed][purpose_name] := {}
		
		s_dp[keynamed][purpose_name].is_passthru  := is_passthru
		s_dp[keynamed][purpose_name].comment  := comment
		s_dp[keynamed][purpose_name].fn_cond  := fn_cond
		s_dp[keynamed][purpose_name].fn_act   := fn_act
		s_dp[keynamed][purpose_name].act_args := act_args
		
		Hotkey, If ; we always use global space
		Hotkey, % hpp_keyname, _dev_HotkeyFlex_callback, On UseErrorLevel
		if(ErrorLevel) 
		{
			; Improper hpp_keyname that would cause `Hotkey` command to err:
			; 	F44
			; 	$CapsLock
			Dbgwin_Output(Format("【Hotkey, {}】 execution fail. You probably passed in an improper keyname.", hpp_keyname))
			dev_assert(0) ; 
		}

		return purpose_name
		; -- Call should keep this purpose_name so that current registered-hotkey 
		;    can be removed later by calling with comment="_off_".
	}
	else ; remove this hotkey
	{
		dev_assert(purpose_name) ; To remove a hotkey, you must pass in an explicity purpose_name.
		
		if(not s_dp.HasKey(keynamed)) {
			dbgHotkeyFlex(Format("On delete, the keynamed does not exist yet: 〖{}〗", keynamed))
			return false
		}
		
		if(not s_dp[keynamed].HasKey(purpose_name)) {
			dbgHotkeyFlex(Format("On delete, the passed in purpose_name does not exist yet: 〖{}〗", purpose_name))
			return false
		}
		
		dbgHotkeyFlex(Format("Keynamed 〖{}〗 deletes purpose-name: ""{}"""
			, keynamed, purpose_name))
		
		s_dp[keynamed].Delete(purpose_name)
		
		if(dev_IsDictEmpty(s_dp[keynamed]))
		{
			dbgHotkeyFlex(Format("Remove empty object s_dp[""{}""]", keynamed))
			
			s_dp.Delete(keynamed)
		
			Hotkey, If ; we always use global space
			Hotkey, % hpp_keyname, Off
		}
		
		return true
	}
	
	dev_assert(0) ; BUG! Should not get here.
}

_dev_HotkeyFlex_callback()
{
	; Critical On
	; -- Using "Critical On" makes this BIG global callback NOT re-entrant,
	;    which defeats AHK's great design of AHK-threads.
	;
	;    BUT, Autohotkey 1.1.39.2 lacks built-in var A_ThreadID; this 
	;    makes user unable to store thread-specific data, which greatly
	;    compromise AHK-thread's usability here.

	s_dp := Amhk.HotkeyFlexDispatcher
	
	keynamed := _fxhk_KeynameStripPrefix(A_ThisHotkey)
	
	if(not s_dp.HasKey(keynamed))
	{
		errmsg := Format("[Unexpect!] In _dev_HotkeyFlex_callback(), A_ThisHotkey=〖{}〗 , keynamed=〖{}〗 , not found in s_dp{}."
			, A_ThisHotkey, keynamed)
		dbgHotkeyFlex(errmsg)
		dev_TooltipAutoClear(errmsg)
		return
	}

	dev_assert(Amhk.fxhk_seq >= Amhk.fxhk_seq_end)
	
	
	if(Amhk.fxhk_seq > Amhk.fxhk_seq_end) {
		
		; Set a flag to indicate that current AHK-thread is intruding(interrupting) another AHK-thread.
		
		is_reentrance := true
		; -- Yes, we delay the re-entrance dbginfo output after "[seq:{}] >>>" .
	}
	else {
		is_reentrance := false
	}

	Amhk.fxhk_seq++

	nowseq := Amhk.fxhk_seq
	; -- to get rid of influence of callback re-entrance, save it as a local var.

	Amhk.fxhkRcbStartTick := dev_GetTickCount64()
	dbgHotkeyFlex(Format("[seq:{}]〖{}〗>>> fxhkRcbStartTick = {}", nowseq, keynamed, Amhk.fxhkRcbStartTick))

	if(is_reentrance)
	{
		; Re-entrance can really happen, randomly, bcz more than one AHK-thread could 
		; possibly execute _dev_HotkeyFlex_callback() in parallel. 
		; Re-entrance is more likely to happen if the callback code calls Sleep, 
		; or GUI-related code, e.g, calling Dbgwin_Output().
		Amhk.fxhk_callback_reentrance_count++
		dbgHotkeyFlex(Format("[INFO] ### seq:{} _dev_HotkeyFlex_callback() re-entrance detected (count={})"
			, nowseq, Amhk.fxhk_callback_reentrance_count))
	}

	has_cond_match := false
	meet_passthru := false
	
	for purpose_name, actinfo in s_dp[keynamed]
	{
		is_global := actinfo.fn_cond ? false : true
		cond_ok := is_global ? true : actinfo.fn_cond.()
		
		if(cond_ok)
		{
			dbgHotkeyFlex(Format("[seq:{}]〖{}〗 firing: [{}] {}", nowseq, keynamed, purpose_name, actinfo.comment))
			
			Amhk.fxhk_context := actinfo
			; -- In user's hotkey callback, he can use fxhk_get_callback_context() to get this global,
			;    querying existing info or attaching new info to this context object.
			
			actinfo.fn_act.(actinfo.act_args*)
			
			has_cond_match := true
			
			if(actinfo.is_passthru)
				meet_passthru := true
		}
		else
		{
			dbgHotkeyFlex(Format("[seq:{}]〖{}〗 NOT-fired: [{}] {}", nowseq, keynamed, purpose_name, actinfo.comment))
		}
	}

	if(meet_passthru || !has_cond_match)
	{
		; EXPLAIN: 
		; If user explicitly wants current hotkey to passthrough(meet_passthru==true), we need to re-send the key.
		;   OR
		; If current hotkey does not match any triggering-condition(no matter user wants it passthru or not),
		; we need to re-send the key as well -- so that current suffix-key can retain its original behavior.
		;
		; But be aware, for combo-hotkey and non-combo-hotkey, the "re-send" method is different.
	
		if(not _fxhk_IsComboKeyname(keynamed, out_prefix_keyname, out_suffix_keyname))
		{
			; keynamed is like: F2 , ^1 , #!u , ...
			;                   __   __   ___
			
			sendcompat := _HotkeynameToSendCompat(keynamed) ; get a compatible string representing the key for `Send`
			
			dev_assert(sendcompat!="")
			
			dbgHotkeyFlex(Format("[seq:{}]〖{}〗 NCC-passthrough {} → Send {}"
				, nowseq
				, keynamed
				, meet_passthru?"(explicit)":"(implicit)"
				, sendcompat))
				
			Send % sendcompat
		}
		else
		{
			; keynamed is like: AppsKey & 1 , ESC & n , ...
			;                   ___________   _______
			;
			; Then we'll send {1} , {n} etc.
			
			send_suffix := "{" out_suffix_keyname "}"
			
			dbgHotkeyFlex(Format("[seq:{}]〖{}〗 CC-passthrough {} → Send {}"
				, nowseq
				, keynamed
				, meet_passthru?"(explicit)":"(implicit)"
				, send_suffix))
			
			Send % send_suffix
		}
	}
	
	; Sleep, 3000
	; -- If you Sleep here, you can very easily see re-entrance problem by pressing hotkeys quickly.
	
	Amhk.fxhkRcbEndTick := dev_GetTickCount64()
	dbgHotkeyFlex(Format("[seq:{}]〖{}〗<<< fxhkRcbEndTick = {} (+{})"
		, nowseq
		, keynamed
		, Amhk.fxhkRcbEndTick
		, Amhk.fxhkRcbEndTick-Amhk.fxhkRcbStartTick))

	Amhk.fxhk_context := ""
	Amhk.fxhk_seq_end++
	
	return
}

fxhk_RcbStartTick()
{
	return Amhk.fxhkRcbStartTick
}

fxhk_RcbEndTick()
{
	return Amhk.fxhkRcbEndTick
}

fxhk_get_seq()
{
	; [2023-01-13] Autohotkey 1.1.39.2: Due to lack of AHK-thread-specific storage,
	; this function is NOT reliable, bcz the global var can possibly be change 
	; by other interrupting AHK-thread.

	return Amhk.fxhk_seq
}

fxhk_get_callback_context()
{
	; This function is only meaningful from a fxhk hotkey callback funcion.

	; [2023-01-13] Autohotkey 1.1.39.2: Due to lack of AHK-thread-specific storage,
	; this function is NOT reliable, bcz the global var can possibly be change 
	; by other interrupting AHK-thread.

	return Amhk.fxhk_context
}

fxhk_get_hpcontext(user_keyname, purposename)
{
	; Use this function to get other-person's context, as long as the requesting user 
	; knows other-person's user_keyname and purposename.
	;
	; hp: Implies this context is indexed by a "Hotkey-name" and a "Purpose".
	
	s_dp := Amhk.HotkeyFlexDispatcher
	
	keynamed := _fxhk_KeynameStripPrefix(user_keyname)
	
	
;	Dbgwin_Output(Format("IsObject(s_dp[{}]) = {}", keynamed, IsObject(s_dp[keynamed])))
;	Dbgwin_Output(Format("IsObject(s_dp[{}][{}]) = {}", keynamed, purposename, IsObject(s_dp[keynamed][purposename])))
	
	context := s_dp[keynamed][purposename]
	if(not IsObject(context))
		return ""
	
	if(not context.fn_act)
		return ""
	
	return context
}


_HotkeynameToSendCompat(a__thishotkey)
{
	if(_fxhk_IsComboKeyname(a__thishotkey))
		return ""

	; My problem description:
	; https://www.autohotkey.com/boards/viewtopic.php?f=76&t=112401
	; according to mikeyww's suggestion, suitable for most cases.
	;
	; One failing case: >^a should translate to {RCtrl down}a{RCtrl up}
	
	sendcompat := RegExReplace(a__thishotkey, "\$?([#^!+]*)(.+)", "$1{$2}")
	return sendcompat
}

_create_auto_purposename(dict_of_purposename)
{
	Loop
	{
		newpurpose := "purpose_auto" A_Index
	} Until (not dict_of_purposename.HasKey(newpurpose))
	
	return newpurpose
}

_tryget_funcobj_name(func)
{
	if(IsObject(func)) {
		; a function object, cannot show it name, just show hint.
		return "(not funcname, maybe a funcobj)"
	}
	else if(StrLen(func)>0) {
		return func
	}
	else if(func=="") {
		return "(empty string)"
	}
	else {
		return "(weird, neither string nor funcobj)"
	}
}

fxhk_DefineHotkey(_keyname, is_passthru, fn_act, act_args*)
{
	; Memo: In order to define hotkey like "AppsKey & c", 
	;       User should better use fxhk_DefineComboHotkey().
	dev_assert(StrLen(_keyname)>0) ; _keyname must be a valid Autohotkey keyname

	purpose_name := _in_dev_DefineHotkeyFlex(_keyname
		, ""       ; purpose_name null, would auto-generate
		, ""       ; empty comment
		, is_passthru
		, ""       ; empty condition  
		, fn_act, act_args*)
	
	return purpose_name
}

fxhk_DefineHotkeyCond(_keyname, fn_cond, is_passthru, fn_act, act_args*)
{
	; Memo: In order to define hotkey like "AppsKey & c", 
	;       User should better use fxhk_DefineComboHotkeyCond().
	dev_assert(StrLen(_keyname)>0) ; _keyname must be a valid Autohotkey keyname

	purpose_name := _in_dev_DefineHotkeyFlex(_keyname
		, ""       ; purpose_name null, would auto-generate
		, ""       ; empty comment
		, is_passthru
		, fn_cond  ; condition
		, fn_act, act_args*)
	
	return purpose_name
}

fxhk_DefineHotkeyComment(_keyname, purpose_name, comment, is_passthru, fn_act, act_args*)
{
	; explicit `comment` parameter

	dev_assert(StrLen(_keyname)>0)     ; _keyname must be a valid Autohotkey keyname
;	dev_assert(StrLen(purpose_name)>0) ; Input purpose_name must be a non-empty string

	purpose_name := _in_dev_DefineHotkeyFlex(_keyname
		, purpose_name
		, comment
		, is_passthru
		, ""       ; empty condition  
		, fn_act, act_args*)
	
	return purpose_name
}

fxhk_DefineHotkeyCondComment(_keyname, purpose_name, comment, is_passthru, fn_cond, fn_act, act_args*)
{
	; explicit `comment` parameter

	dev_assert(StrLen(_keyname)>0)     ; _keyname must be a valid Autohotkey keyname
;	dev_assert(StrLen(purpose_name)>0) ; Input purpose_name must be a non-empty string

	purpose_name := _in_dev_DefineHotkeyFlex(_keyname
		, purpose_name
		, comment
		, is_passthru
		, fn_cond
		, fn_act, act_args*)
	
	return purpose_name
}

fxhk_UnDefineHotkey(_keyname, purpose_name)
{
	dev_assert(StrLen(_keyname)>0) ; _keyname must be a valid Autohotkey keyname
	dev_assert(StrLen(purpose_name)>0) ; purpose_name must be a string
	
	ret := _in_dev_DefineHotkeyFlex(_keyname, purpose_name, "_off_"
		, "", "", "")
	return ret
}

fxhk_IsHotkeyExist(_keyname, purpose_name)
{
	keyname := _fxhk_KeynameStripPrefix(_keyname) ; keyname as dict-key

	s_dp := Amhk.HotkeyFlexDispatcher

	if(IsObject(s_dp[keyname][purpose_name]))
		return true
	else
		return false
}

fxhk_DefineComboHotkeyCondComment(prefix_keyname, suffix_keyname, user_purpose, user_comment
	, fn_cond, fn_act, act_args*)
{
	; Combo hotkey: the chm-doc so-called "custom Combination hotkey", CcHotkey for short.

	dev_assert(StrLen(prefix_keyname)>0)
	dev_assert(StrLen(suffix_keyname)>0)

	ahk_keyname := prefix_keyname " & " suffix_keyname
	
	user_purpose := fxhk_DefineHotkeyCondComment(ahk_keyname, user_purpose, user_comment
		, false     ; is_passthru
		, fn_cond, fn_act, act_args*)
	
	;
	; Define implicity hotkeys for prefix_keyname's DOWN and UP action.
	;
	
	purpose_keydown := _fxhk_getComboKeyDownPurposeName(prefix_keyname)
	fxhk_DefineHotkeyCondComment(prefix_keyname ; note: Don't add " DOWN" suffix, which results in invalid `Hotkey` keyname.
		, purpose_keydown
		, Format("This holds back prefix-key-down action of {}", prefix_keyname) ; comment
		, false  ; is_passthru
		, ""     ; fn_cond
		, "_fxhk_callback_ComboPrefixHoldback" ; fn_act
		, prefix_keyname) ; parameters to fn_act
	
	purpose_keyup := _fxhk_getComboKeyUpPurposeName(prefix_keyname)
	fxhk_DefineHotkeyCondComment(prefix_keyname " UP"
		, purpose_keyup
		, Format("This will re-send prefix-key-up action of {} (only if clean-press)", prefix_keyname) ; comment
		, false  ; is_passthru
		, ""     ; fn_cond
		, "_fxhk_callback_ComboPrefixResend" ; fn_act
		, prefix_keyname) ; parameters to fn_act
	
	return user_purpose
}

_fxhk_getComboKeyDownPurposeName(prefix_keyname)
{
	return  "CcPrefixKeyDown-" prefix_keyname
}

_fxhk_getComboKeyUpPurposeName(prefix_keyname)
{
	return  "CcPrefixKeyUp-" prefix_keyname
}

_fxhk_callback_ComboPrefixHoldback(prefix_keyname)
{
	ctx := fxhk_get_callback_context()
	dev_assert(ctx)
	
	; attach a property(.cchk_keydown_seq) to the context
	nowseq := fxhk_get_seq()
	ctx.cchk_keydown_seq := nowseq
	
	dbgHotkeyFlex(Format("Holdback of combo-prefix 〖{}〗 at seq:{}", prefix_keyname, nowseq))
}

_fxhk_callback_ComboPrefixResend(prefix_keyname)
{
	purpose_keydown := _fxhk_getComboKeyDownPurposeName(prefix_keyname)
	ctx_keydown := fxhk_get_hpcontext(prefix_keyname, purpose_keydown)
	
;	Dbgwin_Output(Format("prefix_keyname={} , purpose_keydown={}", prefix_keyname, purpose_keydown))
	
	seq_keydown := ctx_keydown.cchk_keydown_seq
	seq_keyup := fxhk_get_seq()
	
	if(seq_keydown=="")
	{
		; [2023-01-20] This may happen on a Win10 Host machine, when:
		; * The Host machine has a VirtualBox 6.1.26 Win7 VM running,
		; * User in VM presses AppsKey and release.
		; In this case, the Host machine sees only {AppsKey UP} without {AppsKey} DOWN.
		; We just ignore such case.
		dbgHotkeyFlex(Format("[INFO] In _fxhk_callback_ComboPrefixResend(), seeing 〖{} UP〗 first without key DOWN.", prefix_keyname))
		return
	}
	
;	Dbgwin_Output(Format("seq_keydown={} , seq_keyup={}", seq_keydown, seq_keyup))
	
	seq_diff := seq_keyup - seq_keydown
	
	if(seq_diff == 1)
	{
		; This means no other key is pressed between a prefix-key(e.g. AppsKey)'s down and up,
		; so we should re-send this prefix-key to user-environment.
		
		dbgHotkeyFlex(Format("Prefix-key 〖{}〗 released cleanly, re-send it.", prefix_keyname))
		Send % "{" prefix_keyname "}"
	}
	else if(seq_diff>1)
	{
		dbgHotkeyFlex(Format("Prefix-key 〖{}〗 released with {} intervening fxhk hotkeys, so NO re-send.", prefix_keyname, seq_diff-1))
	}
	else
	{
		Dbgwin_Output("Unexpect: In _fxhk_callback_ComboPrefixResend(), seq_diff=" seq_diff)
		dev_assert(0) ; seq_diff should > 1
	}
}

fxhk_DefineComboHotkey(prefix_keyname, suffix_keyname, fn_act, act_args*)
{
	; Command prefix_keyname: "AppsKey", "Esc"

	purpose := fxhk_DefineComboHotkeyCondComment(prefix_keyname, suffix_keyname
		, "" ; user_purpose
		, "" ; user_comment
		, "" ; fn_cond
		, fn_act, act_args*)
	return purpose
}

fxhk_DefineComboHotkeyCond(prefix_keyname, suffix_keyname, fn_cond, fn_act, act_args*)
{
	purpose := fxhk_DefineComboHotkeyCondComment(prefix_keyname, suffix_keyname
		, "" ; user_purpose
		, "" ; user_comment
		, fn_cond, fn_act, act_args*)
	return purpose
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Encapsulation for 2015 old "Define hotkey functions".
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dev_DefineHotkey(hk, fn_name, args*) ; old 2015
{
	dev_assert(StrLen(hk)>0)
	dev_assert(StrLen(fn_name)>0) ; fn_name must be a string function name

	_in_dev_DefineHotkeyFlex(hk
		, fn_name  ; fn_name as purpose_name
		, ""       ; empty comment
		, false    ; is_passthru
		, ""       ; empty condition
		, fn_name, args*)
}

dev_UnDefineHotkey(hk, fn_name)  ; old 2015
{
	dev_assert(StrLen(fn_name)>0) ; fn_name must be a string function name

	_in_dev_DefineHotkeyFlex(hk, fn_name, "_off_"
		, "", "", "")
}

_purposename_old2015(fn_name, fn_cond)
{
	; fn_name+fn_cond as purpose_name
	return Format("{}.if.{}", fn_name, fn_cond)
}

dev_DefineHotkeyWithCondition(hk, fn_cond, fn_name, args*) ; old 2015
{
	dev_assert(StrLen(hk)>0)
	dev_assert(StrLen(fn_cond)>0) ; condition must be a string function name
	dev_assert(StrLen(fn_name)>0) ; fn_name must be a string function name
	
	purpose_name := _purposename_old2015(fn_name, fn_cond)

	_in_dev_DefineHotkeyFlex(hk
		, purpose_name
		, ""       ; empty comment
		, false    ; is_passthru
		, fn_cond
		, fn_name, args*)
}


dev_UnDefineHotkeyWithCondition(hk, fn_cond, fn_name) ; old 2015
{
	dev_assert(StrLen(hk)>0)
	dev_assert(StrLen(fn_cond)>0) ; condition must be a string function name
	dev_assert(StrLen(fn_name)>0) ; fn_name must be a string function name
	
	purpose_name := _purposename_old2015(fn_name, fn_cond)
	
	_in_dev_DefineHotkeyFlex(hk, purpose_name, "_off_"
		, "", "", "")
}


;
; [2015-02-07] The great dynamically hotkey defining function. (tested on AHK 1.1.13.01)
; BIG Thanks to: http://stackoverflow.com/a/17932358
;
; [2022-01-06] Updated and tested with AHK 1.1.36.2 .
; This function family includes (now with old_ prefix):
; * dev_DefineHotkey
; * dev_UnDefineHotkey
; * dev_DefineHotkeyWithCondition
; * dev_UnDefineHotkeyWithCondition
; This is considered my legacy enhancements to internal `Hotkey` command. 
; They are not so flexible as those new fxhk_xxx alternatives.
;
; BUT we should know, fxhk_xxx has its own limitation, due to not reliable 
; implementation of _HotkeynameToSendCompat().
; If such limitation is encountered, we have to use the old_ functions.
; And BE AWARE: For a specific hotkey, that hotkey can NOT be registered 
; with both fxhk_xxx and old_xxx; if you do that, only one will be effective.

old_dev_DefineHotkey(hk, fn_name, args*) 
{
	dbgHotkeyLegacy(Format("dev_DefineHotkey(), hk={}, fn_name={}", hk, fn_name))
	in_dev_DefineHotkey(true, hk, fn_name, args)
}

old_dev_UnDefineHotkey(hk, fn_name)
{
	dbgHotkeyLegacy(Format("dev_UnDefineHotkey(), hk={}, fn_name={}", hk, fn_name))
	in_dev_DefineHotkey(false, hk, fn_name, 0)
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
	
;	Dbgwin_Output(Format("In in_dev_DefineHotkey({}): hk_userform={}", is_on?"on":"off", hk_userform)) ; debug
	
	if(!fn_name) {
		dev_MsgBoxError("Error: dev_DefineHotkey() pass in fn_name=null! Be aware, function name should be passed in string form.")
		return
	}
	
	hk := _fxhk_KeynameStripPrefix(hk_userform)
	
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
		if(not funs.HasKey(hk))
		{
			; User calls dev_UnDefineHotkey() before dev_DefineHotkey(),
			; this should be allowed and ignore.
			return
		}
	
		funs[hk].Delete(fn_name)
		
		if( dev_IsDictEmpty(funs[hk]) )
		{
			Hotkey, If ; -- use the global context
			Hotkey, %hk%, Off
		}
	}
	
	return

Hotkey_Handler_global:

	hk_stripped := _fxhk_KeynameStripPrefix(A_ThisHotkey)

;	Dbgwin_Output(Format("Hotkey_Handler_global: A_ThisHotkey={} , fixed={}", A_ThisHotkey, hk_stripped)) ; debug
	
	dict_fnpr := funs[hk_stripped]
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
		tooltip, % Format("Bad! funs[{}] is null !!!!!", hk_stripped)
	}

	return
}


old_dev_UnDefineHotkeyWithCondition(hk, cond)
{
	dbgHotkeyLegacy(Format("dev_UnDefineHotkeyWithCondition(), hk={}, cond={}", hk, cond))
	dev_DefineHotkeyWithCondition(hk, cond, "")
}

old_dev_DefineHotkeyWithCondition(hk_userform, cond, fn_name, args*)
{
	dbgHotkeyLegacy(Format("dev_DefineHotkeyWithCondition(), hk={}, cond={}, fn_name={}", hk_userform, cond, fn_name))

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
	
	hk := _fxhk_KeynameStripPrefix(hk_userform) ; hk as dict-key
	
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
		Hotkey, %hk_userform%, Hotkey_Handler_conditional, On
	}
	else 
	{
		condfuns[hk].Delete(cond)
		
		Hotkey, If, %cond%()
		Hotkey, %hk_userform%, Off
	}
	
	Hotkey, If ; to be third-party code friendly, revert to global Hotkey context
	
	return

Hotkey_Handler_conditional:

	hk_stripped := _fxhk_KeynameStripPrefix(A_ThisHotkey)

	hk_dict := condfuns[hk_stripped]
	hk_dict.count += 1
;tooltip, % "Hotkey_Handler_conditional() [" . hk_stripped . "] ........(" . hk_dict.count . ")"
	
	for cond, fnpr in hk_dict
	{
		if(%cond%()) ; if the condition is true
		{
;			tooltip, % "Hotkey_Handler_conditional() [" . hk_stripped . "@" . cond . "] => " . fnpr.fn_name . "()" ; debug ok
;			sleep, 500 ; debug

			fnpr.cnt += 1
			fnpr.fn.(fnpr.pr*)
		}
	}

	return
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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


dev_IsClassnnFocused_regex(regex)
{
	ControlGetFocus, focusNN, A
	if(focusNN ~= regex)
		return true
	else
		return false
}

;################### Windows GUI tweaking functions ###########################

dev_WriteRemoteBuffer(hpRemote, RemoteBuffer, byref iVarBlock, bytes)
{
	succ := DllCall( "WriteProcessMemory"
				, "Ptr", hpRemote
				, "Ptr", RemoteBuffer
				, "Ptr", &iVarBlock
				, "uint", bytes
				, "Ptr", 0)
	return succ
}

dev_ReadRemoteBuffer(hpRemote, RemoteBuffer, byref oVarBlock, bytes)
{
	succ := DllCall( "ReadProcessMemory" 
	            , "Ptr", hpRemote 
	            , "Ptr", RemoteBuffer 
	            , "Ptr", &oVarBlock 
	            , "uint", bytes 
	            , "Ptr", 0 ) 
	return succ
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


dev_WinHideWithPrompt(Awinid:=0)
{
	if(Awinid==0)
		Awinid := dev_GetActiveHwnd() ; cache active window unique id

	WinGetTitle, title, ahk_id %Awinid%
	
	ans := dev_MsgBoxYesNo("Hide this window?`n`n" . title)
	if (ans) {
		WinHide, ahk_id %Awinid%
	}
}


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

_movewinGetScale()
{
	return 1
}

moveWinRelative(rx, ry)
{
	; Move current window by a relative rx, ry value. rx, ry can be positive or negative
	scale := _movewinGetScale()
	WinGetPos, x, y, width, height, A
	absx := x + rx*g_winmove_unit*scale
	absy := y + ry*g_winmove_unit*scale
	WinMove, A, , %absx%, %absy%
}

moveWinBorder(whichb, direction)
{
	; whichb can be "L", "T", "R", "B" for Left, Top, Right, Bottom respectively
	
	scale := _movewinGetScale()
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
		Awinid := dev_GetActiveHwnd() ; cache active window unique id

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
	Awinid := dev_GetActiveHwnd() ; cache active window unique id
	
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


; ^#/:: devui_ChangeWindowPosition()
devui_ChangeWindowPosition()
{
	Awinid := dev_GetActiveHwnd() ; cache active window unique id
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

dev_ClickInChildClassnn(hwnd, classnn, ux, uy, is_movemouse:=false, is_warn:=true)
{
	; When calling, remember to pass quoted-string for classnn
	ControlGet, output_hctrl, HWND, , %classnn%, ahk_id %hwnd%

	dev_MouseActInChildwnd(output_hctrl, ux,false, uy,false, is_movemouse, true, is_movemouse?3:0, is_warn)
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
	; When calling, remember to pass quoted-string for classnn
	ControlGet, output_hctrl, HWND, , %classnn%, A
	
	dev_MouseActInChildwnd(output_hctrl, ux,xomode, uy,yomode, is_movemouse, is_click, movespeed, is_warn)
}

dev_MouseActInChildwnd(hwnd, ux,xomode, uy,yomode, is_movemouse:=true, is_click:=false, movespeed:=0, is_warn:=true)
{
	; If is_click==true, this function does not really operate at the target control, 
	; but operate on the screen position of that control.

	; ControlGetPos, winx, winy, width, height, , ahk_id %hwnd%
	WinGetPos, winx, winy, width, height, ahk_id %hwnd% ; we need absolute screen pos

;	Dbgwin_Output(Format("chd_hwnd={:#x} winx={}, winy={}", hwnd, winx, winy)) ; debug
	if(!winx and is_warn) {
		
		errmsg := Format("[AmHotkey]Unexpected in dev_MouseActInChildwnd(): WinGetPos returns blank for hwnd={}", hwnd)
		
		MsgBox, % errmsg . "`n`nCallstack below (most recent call last):`n`n" . dev_getCallStack()
		
		return
	}
	if (!is_movemouse && !is_click)
		return

	dev_SaveMouseScreenPos()

	targetx := NewCoordFromHint(winx, width,  ux, xomode)
	targety := NewCoordFromHint(winy, height, uy, yomode)

	CoordMode, Mouse, Screen  ;sets screen-based coordinates

	MouseMove, %targetx%, %targety%, %movespeed%
	
	if (is_click)
		Click %targetx%, %targety%

	CoordMode, Mouse, Window  ;restore to active-window-based coordinates

	If (not is_movemouse)
		dev_RestoreMouseScreenPos()
}


dev_ListActiveWindowChildren()
{
	Awinid := dev_GetActiveHwnd() ; cache active window unique id
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

RegexFindToplevelWindowByTitle(tpw_regex, chd_regex:="")
{
	; tpw_regex : The top-level window's title should match this regex.
	; chd_regex : If present, the top-level window should have a child-window matching this regex title.
	
	if(!tpw_regex)
		return false
	
	WinGet, wnd, List ; wnd contains only top-level windows

	Loop, %wnd%
	{
		winid := wnd%A_Index%
		WinGetTitle, title, ahk_id %winid%
		
		if(chd_regex=="")
		{
			if(title ~= tpw_regex)
				return winid
			else
				continue
		}
		
		; Go on checking for child-windows
		
		WinGet, chdwinids, ControlListHwnd, ahk_id %winid%
		
		Loop, parse, chdwinids, `n
		{
			chd_winid := A_LoopField
			WinGetTitle, title, ahk_id %chd_winid%
;			Dbgwin_Output(Format("{:#x} ### {:#x}", winid, chd_winid)) ; debug

			if(title ~= chd_regex)
				return winid
		}
	}
	return false
	
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

dev_ControlFocusViaRegexClassNNXY(Cregex, Tregex, xymode, xhint, yhint, is_click=true, is_movemouse=false)
{
	; This is wrapper of ControlFocusViaRegexClassNNXY()
	; xymode param has more friendly representation.
	; xymode's substring determines innner is_xomode and is_yomode.
	; If xymode contains "xo", is_xomode=yes, if it contains "yo", is_yomode=yes .
	
	if xymode is number
		dev_assert(0, "dev_ControlFocusViaRegexClassNNXY()'s xymode parameter must NOT be a number.")
	
	if(xymode)
		dev_IsOneWord(xymode)
	
	is_xomode := InStr(xymode, "xo") ? true : false ; Suggestion: User pass in "xi" to indicate "x inside"
	is_yomode := InStr(xymode, "yo") ? true : false ; Suggestion: User pass in "yi" to indicate "y inside"
	
	ControlFocusViaRegexClassNNXY(Cregex, Tregex, xhint, yhint, is_click, is_movemouse, is_xomode, is_yomode)
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
;		tooltip, % "ControlFocusViaRegexClassNNXY() target_classnn=" . target_classnn . " / hctrl=" . dev_GetHwndFromClassNN(target_classnn, "ahk_id " . Awinid)
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



ClipboardGet_HTML( byref Data ) ; [2022-12-17] No one use it yet, just keep for reference.
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

	dbgm := A_ThisFunc
	AmDbg_SetDesc(dbgm, Format("Debug message for {}()", A_ThisFunc))

	WinClip.Clear()
	
	Amdbg_Lv1(dbgm, Format("dev_ClipboardSetHTML(), html length {} bytes", StrLen(html)))
	
	Loop, 10
	{
		WinClip.SetHTML(html)
		
		htmlret := WinClip.GetHTML()
		if(htmlret)
		{
			Amdbg_Lv1(dbgm, Format("dev_ClipboardSetHTML() done."))
			break
		}
		else 
		{
			Amdbg_Lv1(dbgm, Format("dev_ClipboardSetHTML() retrying {} ...", A_Index))
			dev_Sleep(100)
		}
	}

	if(is_paste_now)
	{
		if(wait_hwnd)
		{
			Amdbg_Lv1(dbgm, Format("Wait for paste-target window to be active. Hwnd={}", wait_hwnd))
			
			dev_WinActivateHwnd(wait_hwnd)
			
			if(not dev_WinWaitActiveHwnd(wait_hwnd, 1000))
			{
				errmsg := Format("Fail to wait for paste-target window to become active.`r`n`r`n"
					. "Hwnd={}`r`n`r`n"
					. "So I can not paste for you. You can manually paste it by typing Ctrl+V ."
					, wait_hwnd)
				
				Amdbg_Lv1(dbgm, errmsg)
				dev_MsgBoxWarning(errmsg, "AmHotkey - Everpic Wrinkle")
				return ; So not paste into wrong window.
			}
		}
		
		Amdbg_Lv1(dbgm, "Calling WinClip.Paste() >>>")
		WinClip.Paste()
		Amdbg_Lv1(dbgm, "Calling WinClip.Paste() <<<")
	}
}


;test_EnumDisplayMonitors()
;{
;	mlo := dev_EnumDisplayMonitors()
;	MsgBox, % mlo.desctext
;}

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


dev_SetClipboardEmpty(wait_millisec:=500)
{
	tick_end := A_TickCount + wait_millisec
	while(A_TickCount<tick_end)
	{
		if( WinClip.Clear() )
			return true
		
		dev_Sleep(10)
	}
	return false
}

dev_WaitForClipboardFill(wait_millisec:=500)
{
	tick_end := A_TickCount + wait_millisec
	while(A_TickCount<tick_end)
	{
		if(!WinClip.IsEmpty())
			return true
		
		dev_Sleep(10)
	}
	return false
}

dev_CutToClipboard(wait_millisec:=500, is_msgbox_warn:=true)
{
	; Send Ctrl+X to current active window, then wait for wait_millisec
	; for new text to appear in clipboard. If timeout, assert error.
	
	if(!dev_SetClipboardEmpty(wait_millisec))
	{
		if(is_msgbox_warn)
			dev_MsgBoxWarning("ERROR in dev_CutToClipboard(): Cannot clear Clipboard.")
		return false
	}
	
	dev_SendKeyToExeMainWindow("{Ctrl down}x{Ctrl up}")
	
	if(!dev_WaitForClipboardFill(wait_millisec))
	{
		if(is_msgbox_warn)
			dev_MsgBoxWarning(Format("ERROR in dev_CutToClipboard(): Clipboard remains empty after {}ms's wait.", wait_millisec))
		return false
	}
	
	return true
}

dev_CutToOrUseClipboard(cutwait_millisec:=100)
{
	; If we can cut something(via Ctrl+X) to clipboard, then use the cut content.
	; If there is nothing cut(after cutwait_millisec), we'll use(=restore) initial Clipboard text.
	
	backup_text := Clipboard
	
	if(dev_CutToClipboard(cutwait_millisec, false))
		return true ; Some text has put into Clipboard
	
	; We cut nothing, so restore initual clipboard text.
	
	Clipboard := backup_text
	
	if(backup_text=="")
		return false ; seeing empty clipboard
	
	if(WinClip.SetText(backup_text))
		return true
	else
		return false
}



;==============================================================================
#Include *i _more_includes_.ahk ;This should be the final statement of this ahk
;==============================================================================

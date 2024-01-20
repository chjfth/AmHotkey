
AUTOEXEC_cmdconsole: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.


global g_putty_isMousePressed := false
global g_putty_is_warned_termsize := false
global g_putty_is_esc_comboing := false

global g_putty_hwnd2termsize := {} 
	; element value is a string, like "9,15", cell is 9 pixels wide, 15 pixels high

global g_cmdc_text_cmdconsole := "CMD Console"
	global g_cmdc_text_Cmd100Prompt := "Cmd width 100 Prompt"
	global g_cmdc_text_Cmd120Prompt := "Cmd width 120 Prompt"

cmdconsole_InitHotkeys()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


cmdconsole_RightClickTheMainWindow(wait_ctrl_release:=false)
{
	; CMD and PuTTY user may need to call this function to simulate right-clicking into 
	; current application's main window. For CMD and PuTTY, this will provoke 
	; "paste text" action.
	;
	; Consider that this function is probably called for AHK hotkey Ctrl+V, 
	; caller may need to pass in wait_ctrl_release:=true, so that we *wait until* 
	; Ctrl key is released first, then do send a RightClick. 
	; If not this waiting, some application may act as if user does a Ctrl+RightClick, 
	; which behaves differently than a pure RightClick.
	; For example, in PuTTY, Ctrl+RightClick calls up a context menu.
	
	if(wait_ctrl_release)
		KeyWait, Ctrl 
	
	ControlClick , , A, , RIGHT
	
	dev_TooltipAutoClear("AmHotkey: Simulated Right-clicking into main window.", 1500)
	return
}


cc_IsCMDorConEmuActive()
{
	if IsWinClassActive("ConsoleWindowClass") or IsWinClassActive("VirtualConsoleClass")
		return true
	else
		return false
}


cmd_Backspace10()
{
	Send {Backspace 10}
	KeyWait, Backspace 
		; Do a keywait to avoid deleting too much after user has released the hotkey.
}

cmd_Del10()
{
	Send {Del 10}
	KeyWait, Del
		; Do a keywait to avoid deleting too much after user has released the hotkey.
}

;==============================================================
; CMD window
;==============================================================

SuggestCmdCompletionCharInRegistry()
{
	RegRead, theCompletionChar, HKEY_CURRENT_USER, Software\Microsoft\Command Processor, CompletionChar
	if theCompletionChar
	{
		hint = The CompletionChar currently has value %theCompletionChar%
	}
	else
	{
		hint = The CompletionChar currently does not exist.
	}
	MsgBox, % 3+32,, ; Yes/No/Canel + Question-icon
(
Would you like to set a registry item, so that Tab key can be used for filename completion?

[HKEY_CURRENT_USER\Software\Microsoft\Command Processor]
"CompletionChar"=dword:00000009

%hint%

Answering Yes to add, No to delete, Cancel to take no action.
)
	IfMsgBox Yes
	    RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Command Processor, CompletionChar, 9
	IfMsgBox No
	    RegDelete, HKEY_CURRENT_USER, Software\Microsoft\Command Processor, CompletionChar
	return
}



#If cc_IsCMDorConEmuActive()

; Alt+E , execute command to show %ERRORLEVEL% // Ctrl+E is saved for IPython(move caret to line end)
!E::
	SendInput echo `%ERRORLEVEL`%{enter}
	; note: 'Send'executes quite slow for a CMD window, and SendInput is fast.
	; But very strange! Send and SendInput often randomly loses one or two chars(on chji Win7 etc).
return

!Backspace:: cmd_Backspace10()

!Del:: cmd_Del10()

!m:: cc_LoadChjMacros()
cc_LoadChjMacros()
{
	exedir := dev_GetActiveEXE_PathName()[1]
	filename := "ChjMacro.txt"
	
	mpath := exedir . "\" . filename
	if FileExist(mpath) {
		SendInput doskey /macrofile=%mpath%{enter}
	} 
	else {
		Msgbox, % "Macro file not found: " . mpath
	}
	
}

!g:: cc_devGMUPATHfront()
cc_devGMUPATHfront()
{
	mpath := ":\w\GMU\gmupath-front.bat"
	drive_letters := "defgh"
	Loop, parse, drive_letters
	{
		path := A_LoopField . mpath
		if FileExist(path) {
			SendInput {enter}{enter}{enter}
			SendInput %path%{enter}
			break
		}
	}
	
}


#If ; cc_IsCMDorConEmuActive()


cc_IsPreWin10_CMD_Window()
{
	if IsWinClassActive("ConsoleWindowClass") and not StrIsStartsWith(A_OSVersion, "10.0")
		return true
	else
		return false
}


__notused__cc_IsWin10WSL_Window()
{
	if( IsWinClassActive("ConsoleWindowClass") and dev_IsExeActive("wsl.exe") )
		return true
	else
		return false
}

#If IsWinClassActive("ConsoleWindowClass")
; -- no matter it is Win7 CMD, Win10 CMD, or Win10 WSL.

^v:: cmdconsole_RightClickTheMainWindow() ; to paste clipboard text

cmdwin_ScrollOneLine(is_up)
{
	; WM_VSCROLL=0x115, SB_LINEUP=0, SB_LINEDOWN=1
	PostMessage, 0x115 , % is_up?0:1 , 0, , A
}

cmdwin_ScrollOnePage(is_up)
{
	; WM_VSCROLL=0x115, SB_PAGEUP=2, SB_PAGEDOWN=3
	PostMessage, 0x115 , % is_up?2:3 , 0, , A
}

; Ctrl+up/down to scroll command window back and forward; Paste in command window
^Up:: cmdwin_ScrollOneLine(true)
^Down:: cmdwin_ScrollOneLine(false)

;
^PGUP:: cmdwin_ScrollOnePage(true)
^PGDN:: cmdwin_ScrollOnePage(false)


#If ; IsWinClassActive("ConsoleWindowClass")



#If cc_IsPreWin10_CMD_Window

; Win+Alt+F to suggest writing CompletionChar=9 to registry
#!f:: SuggestCmdCompletionCharInRegistry()

#If



;==============================================================
; 2014-11-07 ConEmu Window
;==============================================================
#IfWinActive ahk_class VirtualConsoleClass

; use F8/F9 to switch to prev/next Tab
F8:: Send ^{F8} ; ConEmu should set Ctrl+F8 to be "Switch next console".
F9:: Send ^{F9} ; ConEmu should set Ctrl+F9 to be "Switch previous console".

#IfWinActive



;==============================================================
; PuTTY 
;==============================================================

putty_IsActive()
{
	IfWinActive, ahk_class PuTTY
	{
	    return true
	}
	return false
}

putty_SimuMouseHolddown()
{
	if(g_putty_isMousePressed)
		return

	Send {LButton down}
	g_putty_isMousePressed := true
	g_putty_is_esc_comboing := false
}

putty_SimuMouseRelease()
{
	Send {LButton up}
	
	if(not g_putty_is_esc_comboing)
		Send {Esc}
	
	g_putty_isMousePressed := false
}

putty_GetXYUnit(byRef xunit, byRef yunit)
{
	; I'm feeling very lucky to be able to implement this function.
	; On PuTTY 0.62, once you start dragging its window border, there will be a tiny window pop up
	; right above putty window title showing terminal size in character count, the text is like:
	;	100x48
	; which means there are 100 letters in x-direction and 48 letters in y- direction.
	; After you release your mouse, that tiny window is gone.

	; Because simulating mouse dragging for user costs quite some time, I decide to 
	; maintain a map between hwnd and the terminal-size(termsize)
	; 
	WinGet, hwnd, ID, A ; cache active window unique id
	Get_ClientAreaPos(hwnd, cx, cy, cw, ch)
	
	cellsize := g_putty_hwnd2termsize[hwnd] ; sample: cellsize="9,15"
	
	if(not cellsize)
	{
		; Fetch it now.
		
		MouseGetPos, origx, origy
		MouseMove, cw/2, 0

		Send {LButton down}
		MouseMove, 4, 0, , R 
		
		; wait for the tiny popup window
		SetTitleMatchMode, RegEx
		Loop, 5
		{
			tinywin := WinExist("^[0-9]+x[0-9]+$")
			if(tinywin)
			{
				WinGetTitle, xy_termsize, ahk_id %tinywin%
;				tooltip, % "Got putty termsize=" . xy_termsize ; debug
				break
			}
			else
				Sleep, 100
		}
		SetTitleMatchMode, 3 ; restore to default exact match
		
		Send {LButton up}
		MouseMove, %origx%, %origy%
		
		if(xy_termsize)
		{
			outvar := StrSplit(xy_termsize, "x")
			xunit := floor( cw/outvar[1] )
			yunit := floor( ch/outvar[2] )

			cellsize := xunit . "," . yunit
			g_putty_hwnd2termsize[hwnd] := cellsize
		}
	}
	
	if(cellsize)
	{
		outvar := StrSplit(cellsize, ",")
		
		xunit := outvar[1]
		yunit := outvar[2]
;		tooltip, % "xunit=" . xunit . " / yunit=" . yunit
		return true
	}
	else
	{
		xunit := 9   ; use a fixed value
		yunit := 15
		
		if(not g_putty_is_warned_termsize)
		{
			g_putty_is_warned_termsize := true
			MsgBox, % msgboxoption_IconExclamation, 
				, % "Cannot auto-detect PuTTY terminal size; mouse move will not be accurate. Perhaps your PuTTY version is too old(earlier than 0.62)."
		}
		return false
	}
	
}

putty_GetCaretHeight()
{
	return 8
}


putty_MouseAlignFontCell(cx,cy,cw,ch, xunit, yunit
	,byRef xcells, byRef ycells, byRef xCell, byRef yCell)
{
;	WinGet, hwnd, ID, A ; cache active window hwnd
;	WinGetPos, x,y, winwidth, winheight, ahk_id %hwnd%
	
	xcells := floor(cw/xunit)
	ycells := floor(ch/yunit)
;msgbox, %xcells% / %ycells% 
	PB := 1 ; it seems putty client area as a one-pixel non-drawing border
	
	MouseGetPos, mousex, mousey
		; mousex/mousey relative to putty window(active window)
;msgbox, %mousex% / %mousey% // %cx% / %cy% // %xunit% / %yunit%
	
	xCell := floor((mousex-cx-PB)/xunit) ; x-direction which cell?
	yCell := floor((mousey-cy-PB)/yunit) ; y-direction which cell?
;MsgBox, %xCell% / %yCell%	
	xAligned := cx+PB + xCell*xunit
	yAligned := cy+PB + yCell*yunit
;MsgBox, %xAligned% /// %yAligned%	
	
	MouseMoveInActiveWindow(xAligned, yAligned+putty_GetCaretHeight(), 0)
;tooltip, % "newy_offset_by_clientarea=" . yAligned+putty_GetCaretHeight()-cy
}
	
putty_SimuMouseMove(sdir, count:=1)
{
	static g_putty_is_warned_termsize := false

	WinGet, hwndPutty, ID, A ; cache active window unique id
	Get_ClientAreaPos(hwndPutty, cx, cy, cw, ch)
	
	MouseGetPos, mousex, mousey, hwndUnderMosue
	
	; If mouse pointer is not in the putty window, move it into putty first.
	if(hwndUnderMosue!=hwndPutty)
	{
		MouseMoveInActiveWindow(0.5, 0.5)
	}
	
	isok := putty_GetXYUnit(xunit, yunit) ; font width/height in pixels
	
	putty_MouseAlignFontCell(cx,cy,cw,ch, xunit, yunit, xcells,ycells, xcell,ycell) 
		; output: xcells/ycells/xcell/ycell

	if(sdir=="up" and ycell>0)
	{
		if(count>ycell)
			count := ycell
		MouseMove, 0, 0-yunit*count, , R
	}
	else if(sdir=="down" and ycell<ycells)
	{
		if(count>ycells-ycell)
			count := ycells-ycell
		MouseMove, 0, yunit*count, , R
		ycell += 1
	}
	else if(sdir=="left" and xcell>0)
	{
		if(count>xcell)
			count := xcell
		MouseMove, 0-xunit*count, 0, , R
		xcell -= 1
	}
	else if(sdir=="right" and xcell<xcells)
	{
		if(count>xcells-xcell)
			count := xcells-xcell
		MouseMove, xunit*count, 0, , R
		xcell += 1
	}
	
	g_putty_is_esc_comboing := true
}

cmdconsole_InitHotkeys()
{
	; PuTTY use
	;
	dev_DefineHotkeyWithCondition("CapsLock & Up", "putty_IsActive", "putty_SimuMouseMove", "up")
	dev_DefineHotkeyWithCondition("CapsLock & Down", "putty_IsActive", "putty_SimuMouseMove", "down")
	dev_DefineHotkeyWithCondition("CapsLock & Left", "putty_IsActive", "putty_SimuMouseMove", "left")
	dev_DefineHotkeyWithCondition("CapsLock & Right", "putty_IsActive", "putty_SimuMouseMove", "right")

;	dev_DefineHotkeyWithCondition("Esc & Up", "putty_IsActive", "putty_SimuMouseMove", "up")
;	dev_DefineHotkeyWithCondition("Esc & Down", "putty_IsActive", "putty_SimuMouseMove", "down")
;	dev_DefineHotkeyWithCondition("Esc & Left", "putty_IsActive", "putty_SimuMouseMove", "left")
;	dev_DefineHotkeyWithCondition("Esc & Right", "putty_IsActive", "putty_SimuMouseMove", "right")

	dev_DefineHotkeyWithCondition("!Up", "putty_IsActive", "putty_SimuMouseMove", "up", 5)
	dev_DefineHotkeyWithCondition("!Down", "putty_IsActive", "putty_SimuMouseMove", "down", 5)
	dev_DefineHotkeyWithCondition("!Left", "putty_IsActive", "putty_SimuMouseMove", "left", 5)
	dev_DefineHotkeyWithCondition("!Right", "putty_IsActive", "putty_SimuMouseMove", "right", 5)
		; [2015-03-28] Strange: Using "<!Up" here will invalidate emeditor.ahk's ``!UP:: Send {UP 10}``
		
	; cmdc_SetNewPrompt_AddTrayMenu()
}


cmdc_SetNewPrompt_AddTrayMenu() ; Legacy, not used now
{
	; Define submenu item list:
	Menu, CmdconsoleSubmenu, add, %g_cmdc_text_Cmd100Prompt%, cmdc_Prompt100
	Menu, CmdconsoleSubmenu, add, %g_cmdc_text_Cmd120Prompt%, cmdc_Prompt120
	
	; Attach submenu to main menu
	Menu, tray, add, %g_cmdc_text_cmdconsole%, :CmdconsoleSubmenu
}

cmdc_Prompt100()
{ 
	cmdc_SetNewPrompt(100)
}

cmdc_Prompt120() 
{ 
	cmdc_SetNewPrompt(120)
}

cmdc_SetNewPrompt(cmd_width)
{
	; Activate the most recent CMD window, and then send new `prompt` command to it.
	
	cmdwin := "ahk_class ConsoleWindowClass"
	WinActivate, % cmdwin

	isok := dev_WinWaitActive_with_timeout(cmdwin)
	if(!isok)
	{
	    MsgBox, % "No CMD windows can be activated, so nothing to do."
	    return
	}
	else
	{
		diamond_count := (cmd_width-14)/2
		cmd := Format("PROMPT {1}[$t] $p$g", dev_StrRepeat("◆", diamond_count))
		
		dev_TooltipAutoClear("Sending new PROMPT command to recent CMD window...")
		SendInput %cmd%{enter}
	}
}

#If putty_IsActive()

^v:: cmdconsole_RightClickTheMainWindow(true)

^!-:: ; Ctrl+Alt+-: Clear terminal and clear PuTTY window buffer
Send !{space}t
Send !{space}l
return

^!c:: ; Ctrl+Alt+c: Copy all to clipboard
Send !{space}o
return


; Ctrl+Up/Down: Scroll one line up/down
^Up:: PostMessage, 0x115 , 0, 0, , A
^Down:: PostMessage, 0x115 , 1, 0, , A
; Ctrl+PgUp/PgDn to scroll a page 
^PgUp:: PostMessage, 0x115 , 2, 0, , A
^PgDn:: PostMessage, 0x115 , 3, 0, , A

; Ctrl+E , try to show linux error value
^E::
Send echo $?{enter}
return

; Ctrl+Alt+E  Run my favorite command in a Bash env(e.g. VMware ESXi shell, FreeBSD Bash)
^!E::
SendInput PS1_ERRC='ERR:$?'{enter}
SendInput PS1="\n[\u @\h (\D{{}`%G-`%m-`%d{}} \t $PS1_ERRC) \[\033[1;31m\w\033[0m\]]\n\[\033[1;37;44m\]$\[\033[0m\] "{enter}
; After unescaping, you get:
; PS1="\n[\u @\h (\D{%G-%m-%d} \t) \[\033[1;31m\w\033[0m\]]\n\[\033[1;37;44m\]$\[\033[0m\] "
SendInput alias ll='ls -l' && alias la='ls -la'{enter}
SendInput {enter}
return



Esc::    putty_SimuMouseHolddown()
Esc up:: putty_SimuMouseRelease()




#If ; putty_IsActive()



;==============================================================
; SysProgs SmarTTY
;==============================================================

smartty_IsActive()
{
	WinGet, Awinid, ID, A ; cache active window unique id
;	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%

	if ( title ~= "^SmarTTY" ) ; regex match
	{
	    return true
	}
	return false
}

#If smartty_IsActive()

^v:: SmarttyPasteText()

SmarttyPasteText()
{
	; A context menu pops up on {AppsKey}, and the first item is Copy, the second is Paste.
	Send {AppsKey}{Down}{Down}{Enter}
}


#If ; smartty_IsActive()




AUTOEXEC_webbrowers: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

global Chrome_kbd_MoveTabLeft := "+^{pgup}"
global Chrome_kbd_MoveTabRight := "+^{pgdn}" ; This requires extension
	; https://chrome.google.com/webstore/detail/keyboard-shortcuts-to-reo/moigagbiaanpboaflikhdhgdfiifdodd
	; but quite often fails to act spontaneously.
global Chrome_kbd_MRUTab := ;"^Q"   
global Chrome_kbd_MRUTab_r := ;"+^Q"
	; [2015-02-09] Currently, no Extension seems to be able to provide the MRU switching reliably

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;==============================================================
; Chrome Main Window
;==============================================================

Is_Chrome_WidgetWin_1()
{
	return IsWinClassActive("Chrome_WidgetWin_1")
}

IsChromeHwnd(hwnd)
{
	WinGetClass, class, ahk_id %hwnd%
	WinGetTitle, title, ahk_id %hwnd%

	if( class=="Chrome_WidgetWin_1" 
		and (StrIsEndsWith(title, "Google Chrome") 
		  or StrIsEndsWith(title, "Comodo Dragon")
		  or StrIsEndsWith(title, "Microsoft​ Edge")) 
		and title!="Skype" )
	{
		return true
	}
	else
	{	
		return false
	}
}

IsChromeWindowActive()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	return IsChromeHwnd(Awinid)
}

#If IsChromeWindowActive() and (!dev_IsExeRunning("HprSnap8.exe") and !dev_IsExeRunning("HprSnap7.exe"))

; If Hypersnap 7/8 is running, then I must have configured Hypersnap to monitor global hotkey 
; Ctrl+Shift+W to start windows-capture, so user pressing Ctrl+Shift+W will not close Chrome window.
;
; But if If Hypersnap 7/8 is not running, I want AHK to intercept Ctrl+Shift+W to prevent accidentally closing Chrome window.

+^w:: dev_TooltipDisableCloseWindow("Ctrl+Shift+W")

#If

; ////

#If IsChromeWindowActive()

^w:: dev_TooltipDisableCloseWindow("Ctrl+W")

F8:: Send ^{PgUp}
F9:: Send ^{PgDn}

^F8:: Send %Chrome_kbd_MoveTabLeft%
^F9:: Send %Chrome_kbd_MoveTabRight%


$^Tab:: Send % Chrome_kbd_MRUTab ? Chrome_kbd_MRUTab : "^{Tab}"
$+^Tab:: Send, % Chrome_kbd_MRUTab_r ? Chrome_kbd_MRUTab_r : "+^{Tab}"

^!\:: ClickInActiveWindow(-30, -30, false) ; Close download bar

!End:: ClickInActiveWindow(0.5, -60, false) ; try to click into DevTool console so to input new command


; Define a hotkey to "fix" prettify.js generated CF_HTML clipboard content,
; so that colored-code pasting into Evernote 5.x have correct line breaks.
; The pasting line-break problem is described at
; http://www.evernote.com/l/ABXoualVqgJIOZhQNzyy5VB6sWrGpUXMSBw/
AppsKey & q:: CopyAndFix_Evernote_CF_HTML()
CopyAndFix_Evernote_CF_HTML()
{
	title := "CopyAndFix_Evernote_CF_HTML"
	Clipboard :=
	Send ^a ; Select all page text
	Sleep 500 ; Let user see the select-all visual effect

	Send ^c ; Copy to clipboard	
	ClipWait 0.5
	if(ErrorLevel)
	{
		MsgBox, 48, %title%, % "Nothing copied to clipboard. Nothing to do."
		return	
	}
	
	py := g_dirEverpic . "\fix_CF_HTML_for_Evernote.pyw" ; Use g_dirEverpic for convenience 
	IfNotExist, % py
	{
		tooltip, >>> %g_dirEverpic%
		MsgBox, 16, %title%, % py . " does not exist. `nCheck your g_dirEverpic value in customize.ahk ."
		return
	}
	
	RunWait, % py, , UseErrorLevel
	if(ErrorLevel==101)
	{
		MsgBox, 48, %title%, % "No CF_HTML content in clipboard, nothing to do."
		return
	}
	else if(ErrorLevel)
	{
		MsgBox, 16, %title%, % "Fail to run " . py . "`nExitcode=" . ErrorLevel
		return
	}
	
	info := "Copied web page content to clipboard with CF_HTML fix for Evernote. Now you can paste it into Evernote."
	MsgBox, 64, %title%, % info, 2
;	TrayTip, % "AHK info", % info, 3
}

; [2018-05-01] Chrome Console's caret cannot be fetched by A_CaretX and A_CaretY

NumpadMult:: ChromeConsole_click()
ChromeConsole_click()
{
	; in hope to click at left-lower corner of Chrome console window, 
	; for further manual mouse actions.
	ClickInActiveWindow(12, -77, true, 3)
}



#If # IsChromeWindowActive()

;==============================================================
; Firefox 31
;==============================================================

IsFirefoxWindowActive()
{
	; Memo: Active State Komodo IDE 7 also have ahk_class "MozillaWindowClass"
	WinGetTitle, title, A
	if( IsWinClassActive("MozillaWindowClass") 
		and (InStr(title, "Firefox") or InStr(title, "Waterfox")) )
		return true
	else
		return false
}


#If IsFirefoxWindowActive()

^Ins:: ClickInActiveWindow(500, 140) ; Bing English search box

^\:: dev_ClickInScreen(-10, 10, false) ; close bookdl.com , prefiles.com screen popup ad
^!\:: ClickInActiveWindow(-14, -14, false) ; Clear download status bar OR search bar

F8:: Send +^{Tab}
F9:: Send ^{Tab}


#If ;IsFirefoxWindowActive()


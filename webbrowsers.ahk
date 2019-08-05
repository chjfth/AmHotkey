
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

Is_ChromeBasedWebBrowser()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%

	if( class=="Chrome_WidgetWin_1" 
		and (StrIsEndsWith(title, "Google Chrome") or StrIsEndsWith(title, "Comodo Dragon")) 
		and title!="Skype" )
	{
		return true
	}
	else
	{	
		return false
	}
}

; 2013-12-29 [Ins] Chome click into Web site's search box
#If Is_ChromeBasedWebBrowser()
; Ins:: ClickInActiveWindow(500, 145) ; Google search box
^Ins:: ClickInActiveWindow(500, 110) ; Bing English search box

F8:: Send ^{PgUp}
F9:: Send ^{PgDn}

^F8:: Send %Chrome_kbd_MoveTabLeft%
^F9:: Send %Chrome_kbd_MoveTabRight%


$^Tab:: Send % Chrome_kbd_MRUTab ? Chrome_kbd_MRUTab : "^{Tab}"
$+^Tab:: Send, % Chrome_kbd_MRUTab_r ? Chrome_kbd_MRUTab_r : "+^{Tab}"

^!\:: ClickInActiveWindow(-30, -30, false) ; Close download bar

!End:: ClickInActiveWindow(0.5, -60, false) ; try to click into DevTool console so to input new command

; Confluence macros
:*:,,c:: 
	Hots_CF_InsertCodeSpan(100)
return
Hots_CF_InsertCodeSpan(keydelay_msec)
{
	; Type {{code}} into Confluence editor, the ``code`` will become monospaced,
	; then caret back to select ``code``. So further typing of words become monospaced too.
	; Tip: To paste text as monospaced, you have to type a space, then paste. 
	SendInput {{}{{}code{}}
	Sleep %keydelay_msec%
	SendInput {}}
	Sleep 10
	SendInput {Left}{Shift down}{Left 4}{Shift up}
}

CF_GetPrecedingChar()
{
	KeyWait Ctrl
	KeyWait Shift
	SendInput {Shift down}{Left}{Shift up}
	Clipboard := ""
	Send ^c
	ClipWait, 0.5
	SendInput {Right}
	return Clipboard
}

^`:: CF_PasteAsCodeSpan(true) ; paste clipboard text as {{code}}
CF_PasteAsCodeSpan(is_check_preceding_space:=false)
{
	usertext := Clipboard
	newtext := Trim(usertext, " `t`r`n") ; these will interfere with Confluence editor's {{...}} action
		; If the trailin char is space/tab, Confluence will not trigger {{code}} format conversion,
		; so I have to trim it.
	if not newtext {
		tooltip, Blank text in clipboard`, nothing to paste as code-format.
		Sleep 1000
		tooltip
		return
	}

	if is_check_preceding_space
	{
		; Check if there is a space/tab/LF preceding the caret; if not, add a space.
		; Without the space, Confluence editor's {{code}} format conversion will not be triggered, which is by design.
		prechar := CF_GetPrecedingChar()
		if not (prechar==A_Space || prechar==A_Tab || prechar=="`n")
			Send {Space}
	}

	; now restore clipboard. try several times because sometimes it is not restored reliably
	while(Clipboard!=usertext)
	{
		Clipboard := usertext ;restore clipboard
		Sleep 10
	}
	
	orig_zs := %g_func_IMEToggleZhonwen%(false)
	SendInput {{}{{}
	SendRaw %newtext%
	SendInput {}}
	Sleep 10
	SendInput {}}
	Sleep 10
	if (newtext!=usertext)
		Send {Space} ; Suppliment the stripped space, but only one for simplicity

	if(orig_zs)
		%g_func_IMEToggleZhonwen%(true) ; restore Zhongwen status
}

; F2 up:: CF_ConvertToCodeSpan(true)
CF_ConvertToCodeSpan(is_auto_convert_preceding_word:=true)
{
	origclipboard := Clipboard ; save original clipboard, restore later
	Clipboard := ""
	Send ^x
	
	if (not Clipboard) and is_auto_convert_preceding_word
	{
		prechar := CF_GetPrecedingChar()
		if (prechar=="`n" || prechar=="`r`n")
		{
			Clipboard := origclipboard
			tooltip, % "At line start, nothing to convert."
			Sleep 1000
			tooltip
			return
		}
		SendInput {Ctrl down}{Shift down}{Left}{Shift up}{Ctrl up}
		Sleep, 200
			; [2015-02-16] Note: without a sleep here , Chrome 40 may select only the right-most single char. ???? no use
		Send ^x
		ClipWait, 0.5 ;sleep 100 ; required on Chrome 40, 4770k
		CF_PasteAsCodeSpan(false)
	}
	else 
	{
		CF_PasteAsCodeSpan(true)
	}
	Clipboard := origclipboard
}


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



#If

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

; Confluence macros
:*:,,c:: Hots_CF_InsertCodeSpan(500)

^`:: CF_PasteAsCodeSpan(true) ; paste clipboard text as {{code}}

; F2 up:: CF_ConvertToCodeSpan(true)

#If ;IsFirefoxWindowActive()


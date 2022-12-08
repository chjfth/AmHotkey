
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
		dev_MsgBoxWarning("Nothing copied to clipboard. Nothing to do.", title)
		return	
	}
	
	Fix_prettyprint_html_pre_for_Evernote()
	
	info := "Copied web page content to clipboard with CF_HTML fix for Evernote. Now you can paste it into Evernote."
	dev_MsgBoxInfo(info, title)
}

Fix_prettyprint_html_pre_for_Evernote()
{
	htmlcc := WinClip.GetHtml() ; cc: clipboard content
	
	if(!htmlcc) {
		; maybe no "HTML Format" in clipboard
		dev_TooltipAutoClear("Fix_prettyprint_html_pre_for_Evernote(): WinClip.GetHtml() got empty string.")
		return false
	}
	
	; When a piece of code is prettyprinted into foo.html, and we open foo.html in Chrome/Firefox,
	; Ctrl+A, then Ctrl+C to copy the HTML content into Clipboard, we will get htmlcc like this:
/* 

Version:0.9
StartHTML:0000000181
EndHTML:0000001598
StartFragment:0000000217
EndFragment:0000001562
SourceURL:file:///C:/Users/win7evn/AppData/Local/Temp/prettify_output.html
<html>
<body>
<!--StartFragment--><pre class="prettyprint prettyprinted" style="font-family: consolas, monospace; font-size: 12px; background-color: rgb(238, 238, 238); padding: 0.5em; border: 1px solid rgb(221, 221, 221); color: rgb(0, 0, 0); font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: start; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><span class="kwd" style="color: rgb(0, 0, 204);">void</span><span class="pln" style="color: rgb(0, 0, 0);"> foo</span><span class="pun" style="color: rgb(136, 0, 0);">()</span><span class="pln" style="color: rgb(0, 0, 0);">
</span><span class="pun" style="color: rgb(136, 0, 0);">{</span><span class="pln" style="color: rgb(0, 0, 0);">
    printf</span><span class="pun" style="color: rgb(136, 0, 0);">(</span><span class="str" style="color: rgb(238, 0, 255);">"Hello.\n"</span><span class="pun" style="color: rgb(136, 0, 0);">);</span><span class="pln" style="color: rgb(0, 0, 0);"> </span><span class="com" style="color: rgb(0, 136, 0);">// do something</span><span class="pln" style="color: rgb(0, 0, 0);">
</span><span class="pun" style="color: rgb(136, 0, 0);">}</span></pre><!--EndFragment-->
</body>
</html> 

*/
	; [2015~2022] The problem(A) is: If we just paste current clipboard into Evernote,
	; some line breaks are lost... bcz there is "</span>" at start of some html line,
	; and Evernote do NOT like this, so the line break there is lost.
	; [Workaround] Swap \n and </span>, so that </span> is at tail of a line, and,
	; add an extra </br> after </span>. This makes Evernote happy.
	;
	; [2022-12-05] This was once implemented in fix_CF_HTML_for_Evernote.pyw, but
	; now we can do it in Autohotkey purely. BUT, there is limitation:
	; the .py function linenums_extra() cannot be achieved by AHK, so prettyprint's
	; line-number mode html cannot be copied to Evernote yet.
	
	; We need to strip the "format header" and only care for content from "<html>".

	foundpos := InStr(htmlcc, "<html>")
	if(foundpos==0) {
		dev_TooltipAutoClear("Fix_prettyprint_html_pre_for_Evernote(): no <html>")
		return false
	}
	
	htmlraw := SubStr(htmlcc, foundpos)
	
	; Cope with problem(A)
	;
	htmlraw := StrReplace(htmlraw, "`r`n", "`n")
	;
	; Move all "</span>" at start-of-line to previous-line tail, and add <br/> after the </span> .
	; We need to do it in a loop, bcz if </span>'s previous-line is a blank line, do it once is not enough.
	;
	Loop
	{
		htmlraw := StrReplace(htmlraw, "`n</span>", "</span><br/>`n", nReplaced)
		
	} Until (nReplaced==0)
	
	dev_ClipboardSetHTML(htmlraw)
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


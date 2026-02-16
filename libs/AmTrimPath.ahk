#Include %A_LineFile%\..\Amhk-common.ahk
#Include %A_LineFile%\..\Amhk-gui.ahk
#Include %A_LineFile%\..\ClipboardMonitor.ahk

; API: AmTrimPath_ShowGui()

global g_amtpHwnd
global gu_amtpCbdSum   ; Clipboard summary text: "Clipboard has ... chars" 
global gu_amtpCbdText  ; Current clipboard text
global gu_amtpUserInput
global gu_amtpPreviewText ; Preview of converted text
global gu_amtpBtnConvert
global gu_amtpCkbKeepWindow

class AmTrimPath
{
	static _GuiName := "AmTrimPath"
	static _isGuiVisible := false
	static _hClipmon
}

AmTrimPath_ShowGui()
{
	Amtp_ShowGui()
}

amtp_Gui_add_onehint(charhint, desctext)
{
	GuiName := AmTrimPath._GuiName

	Gui_Switch_Font( GuiName, 0, "", "Consolas")
	Gui_Add_TxtLabel(GuiName, "", 30, "xm+10 y+0", charhint)
	Gui_Switch_Font( GuiName, 0, "", "Tahoma")
	Gui_Add_TxtLabel(GuiName, "", -1, "x+5 yp", desctext)
}

_Amtp_CreateGui()
{
	GuiName := AmTrimPath._GuiName
	
	Gui_New(GuiName)
	Gui_AssociateHwndVarname(GuiName, "g_amtpHwnd")
	Gui_ChangeOpt(GuiName, "+Resize +MinSize")
	
	Gui_Switch_Font( GuiName, 9, "", "Tahoma")
	
	Gui_Add_TxtLabel(GuiName, "gu_amtpCbdSum", 500, "xm", "To be filled...")

	Gui_Switch_Font( GuiName, 0, "blue")
	Gui_Add_Editbox( GuiName, "gu_amtpCbdText", 502, "xm-2 readonly r3 -E0x200")

	Gui_Switch_Font( GuiName, 0, "666666")
	
	Gui_Add_TxtLabel(GuiName, "", -1, "xm", "Type some letter instructions to manipulate text above.")
	amtp_Gui_add_onehint("/",  "Convert back-slashes to forward-slashes")
	amtp_Gui_add_onehint("//", "WSL style: D:\some\path to /mnt/d/some/path")
	amtp_Gui_add_onehint("\",  "Convert forward-slashes to back-slashes")
	amtp_Gui_add_onehint("\\", "WSL style: /mnt/d/some/path to D:\some\path")
	amtp_Gui_add_onehint("""", "Wrap string with double-quotes")
	amtp_Gui_add_onehint("'",  "Wrap string with single-quotes")
	amtp_Gui_add_onehint("-",  "Remove all double- and single- quotes")
	amtp_Gui_add_onehint("[",  "Collapse consecutive blank-lines into one")
	amtp_Gui_add_onehint("w20","Wrap long lines at line-width 20")
	amtp_Gui_add_onehint("w0", "Remove all line breaks, concatenate all lines")
	amtp_Gui_add_onehint("ws", "Remove all line breaks, concat each with a space")
	Gui_Add_TxtLabel(GuiName, "", -1, "xm", "Hint: You can type ""/ to wrap quotes and convert to / at the same time.")
	
	Gui_Switch_Font( GuiName, 0, "black")
	Gui_Add_TxtLabel(GuiName, "", -1, "xm y+10", "&Instructions: ")
	Gui_Add_Editbox( GuiName, "gu_amtpUserInput", 50, "x+10 yp-2 g" . "Amtp_UserInputChange")

	Gui_Add_TxtLabel(GuiName, "", -1, "xm y+10", "Convert preview:")
	Gui_Add_Editbox( GuiName, "gu_amtpPreviewText", 502, "xm-2 r3")
	
	Gui_Add_Button(GuiName, "gu_amtpBtnConvert", -1, "Default g" . "Amtp_SendToClipboard", "&Send to Clipboard")
	Gui_Add_Checkbox(GuiName, "gu_amtpCkbKeepWindow", -1, "x+5 yp+5", "&Keep window")
}

Amtp_ShowGui()
{
	GuiName := AmTrimPath._GuiName

	if(!g_amtpHwnd) {
		_Amtp_CreateGui() ; destroy old and create new
	}
	
	Gui_Show_CenterOnParent(GuiName, "", "AHK Trim path utility")
	
	if(not AmTrimPath._isGuiVisible) 
	{
		AmTrimPath._isGuiVisible := true
		AmTrimPath._hClipmon := Clipmon_CreateMonitor("Amtp_SyncUIFromClipboard", "AmTrimPath:Amtp_ShowGui")

		OnMessage(0x200, Func("Amtp_WM_MOUSEMOVE")) ; add message hook
	}

	GuiControl_SetFocus(GuiName, "gu_amtpUserInput")
	
	Amtp_SyncUIFromClipboard()
}

Amtp_HideGui()
{
	GuiName := AmTrimPath._GuiName

	Gui_Hide(GuiName)

	if(AmTrimPath._isGuiVisible)
	{
		AmTrimPath._isGuiVisible := false
		Clipmon_DeleteMonitor(AmTrimPath._hClipmon)
	
		OnMessage(0x200, Func("Amtp_WM_MOUSEMOVE"), 0) ; remove message hook
		tooltip
	}
}

AmTrimPathGuiClose()
{
	Amtp_HideGui()
}

AmTrimPathGuiEscape()
{
	Amtp_HideGui()
}

AmTrimPathGuiSize()
{
	rsdict := {}
    rsdict.gu_amtpCbdText := "0,0,100,0" ; Left/Top/Right/Bottom pct
    rsdict.gu_amtpPreviewText := "0,0,100,100"
    rsdict.gu_amtpBtnConvert := "0,100,0,100"
    rsdict.gu_amtpCkbKeepWindow := "0,100,0,100"
    dev_GuiAutoResize(AmTrimPath._GuiName, rsdict, A_GuiWidth, A_GuiHeight)
}

Amtp_WM_MOUSEMOVE()
{
}

Amtp_UserInputChange()
{
	Amtp_SyncUIFromClipboard()
}

Amtp_SyncUIFromClipboard()
{
	GuiName := AmTrimPath._GuiName
	
	text := Clipboard
	GuiControl_SetText(GuiName, "gu_amtpCbdText", text)
	
	if(text=="")
	{
		GuiControl_SetText(GuiName, "gu_amtpCbdSum", "Clipboard has no text yet.")
		return
	}
	
	alltext := StrReplace(text, "`r`n", "`n")
	arlines_orig := StrSplit(alltext, "`n")
	nlines := arlines_orig.Length()
	
	nchars := 0
	arlines_noquotes := []
	for index,linetext in arlines_orig
	{
		nchars += StrLen(linetext)
		arlines_noquotes[index] := Trim(linetext, """'") ; trim off double-/single- quotes
	}
	
	if(nlines==1)
		sumtext := Format("Clipboard has {} characters", nchars)
	else
		sumtext := Format("Clipboard has {} lines, {} chars total (not counting CRLF)", nlines, nchars)
	
	GuiControl_SetText(GuiName, "gu_amtpCbdSum", sumtext)
	
	;
	; Start converting clipboard content
	;
	
	howto := GuiControl_GetText(GuiName, "gu_amtpUserInput")
	; -- howto may include chars of / \ " ' -
	
	if(InStr(howto, """")>1 or InStr(howto, "'") or InStr(howto, "-"))
	{
		; User assigns " or ', then we need to process from bare strings.
		arlines_output := arlines_noquotes
	}
	else 
	{
		arlines_output := arlines_orig
	}

	for index,linetext in arlines_output
	{
		if(InStr(howto, "/"))
		{
			if(InStr(howto, "//"))
			{
				; Special op for WSL: will convert D:\some\path to /mnt/d/some/path
				foundpos := RegExMatch(linetext, "^([A-Za-z]):\\", subpat)
				if(foundpos==1)
				{
					smallc := dev_StringLower(subpat1)
					linetext := "/mnt/" smallc SubStr(linetext, 3)
				}
			}

			; Regular op: convert each \ to /
			linetext := StrReplace(linetext, "\", "/")
		}
		else if(InStr(howto, "\"))
		{
			if(InStr(howto, "\\"))
			{
				; Special op for WSL: will convert /mnt/d/some/path to d:\some\path
				foundpos := RegExMatch(linetext, "^/mnt/([A-Za-z])/", subpat)
				if(foundpos==1)
				{
					smallc := subpat1
					linetext := smallc ":" SubStr(linetext, 7)
				}
			}
			
			; Regular op: convert each / to \
			linetext := StrReplace(linetext, "/", "\")
		}
		
		if(InStr(howto, """"))
			linetext := """" linetext """"
		else if(InStr(howto, "'"))
			linetext := "'" linetext "'"
		
		arlines_output[index] := linetext
	}
	
	; ====== Remaining : Processing the output string as a whole ======
	
	textfinal := dev_JoinStrings(arlines_output, "`n")
	
	; Collapse consecutive blank-lines into one blank-line.
	
	if(InStr(howto, "["))
	{
		textfinal := RegExReplace(textfinal, "\n{3,}", "`n`n")
	}
	
	; Split lines according to 'w40' etc.
	
	foundpos := RegExMatch(howto, "w([0-9s]+)", subpat)
	if(foundpos)
	{
		wn := subpat1
		if(wn=="s")
		{
			textfinal := StrReplace(textfinal, "`n", " ")
		}
		else if(wn==0)
		{
			textfinal := StrReplace(textfinal, "`n", "")
		}
		else if(wn>0)
		{
			textfinal := Amtp_WrapLines(textfinal, wn)
		}
	}
	
	GuiControl_SetText(GuiName, "gu_amtpPreviewText", textfinal)
}

Amtp_SendToClipboard()
{
	GuiName := AmTrimPath._GuiName
	text := GuiControl_GetText(GuiName, "gu_amtpPreviewText")
	Clipboard := text
	
	is_keepwindow := GuiControl_GetValue(GuiName, "gu_amtpCkbKeepWindow")
	
	if(is_keepwindow)
		dev_TooltipAutoClear("Sent to clipboard")
	else
		Amtp_HideGui()
}



Amtp_WrapLines(inputtext, colwidth)
{
	; Return a new text string with extra \n inserted.
	; If we want to break a very long string(shell command line for example)
	; into trivial lines so that they looks pretty, we can use this.
	;
	; 2023.05.11, modified on the basis of ChatGPT generated code.
	
	newtext := ""

	Loop, Parse, inputtext, `n ; Parse the text string into separate lines.
	{
	    line := A_LoopField ; Get the current line.
	    ;word_count := 0      ; Initialize word count to 0.
	    new_line := ""

	    loop
	    {
	        word := _amtp_GetFirstWord(line, remain_words) ; Get the next word in the line.
	        if (!word)  ; If there are no more words, break the loop.
	            break

	        if (StrLen(new_line) + StrLen(word) > colwidth) ; If adding the next word would exceed the maximum line length, break the line.
	        {
	        	if(new_line != "") {
	        		newtext .= new_line "`r`n"
		            ; MsgBox, % "[New line]" new_line  ; Display the new line.
		        }
	            
	            new_line := word                 ; Start a new line with the current word.
	        }
	        else ; Otherwise, add the next word to the current line.
	        {
	            if (new_line != "") ; If the current line is not empty, add a space before the next word.
	                new_line .= " "
	            new_line .= word
	        }

	        line := remain_words
	    }

	    if (new_line != "") ; If there is a current line when we exit the loop, display it.
	    {
	    	newtext .= new_line "`r`n"
	        ;MsgBox, % [New line] " new_line
	    }
	}

	return newtext
}

; Get a specific word from a string.
; Assumes that words are separated by whitespace (space, tab, or newline).
_amtp_GetFirstWord(str, byref remain_str) {
    str := Trim(str)
    index := InStr(str, " ")
    if(index>0) {
        remain_str := SubStr(str, index)
        return SubStr(str, 1, index-1)
    }
    else {
        remain_str := ""
        return str
    }
}

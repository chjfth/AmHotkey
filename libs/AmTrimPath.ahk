#Include %A_LineFile%\..\Amhk-common.ahk
#Include %A_LineFile%\..\Amhk-gui.ahk

; API: AmTrimPath_ShowGui()

global g_amtpHwnd
global g_amtpCbdSum   ; Clipboard summary text: "Clipboard has ... chars" 
global g_amtpCbdText  ; Current clipboard text
global g_amtpUserInput
global g_amtpPreviewText ; Preview of converted text
global g_amtpBtnConvert
global g_amtpCkbKeepWindow

class AmTrimPath
{
	static GuiName := "AmTrimPath"
	static hClipmon
}

AmTrimPath_ShowGui()
{
	Amtp_ShowGui()
}

Amtp_CreateGui()
{
	GuiName := AmTrimPath.GuiName
	
	Gui_New(GuiName)
	Gui_AssociateHwndVarname(GuiName, "g_amtpHwnd")
	Gui_ChangeOpt(GuiName, "+Resize +MinSize")
	
	Gui_Switch_Font( GuiName, 9, "", "Tahoma")
	
	Gui_Add_TxtLabel(GuiName, "g_amtpCbdSum", 500, "xm", "To be filled...")

	Gui_Switch_Font( GuiName, 0, "blue")
	Gui_Add_Editbox( GuiName, "g_amtpCbdText", 502, "xm-2 readonly r3 -E0x200")

	Gui_Switch_Font( GuiName, 0, "666666")
	helptext = 
(
Type some letter instructions to manipulate text above.

/   Convert back-slashes to forward-slashes
\   Convert forward-slashes to back-slashes
"   Wrap string with double-quotes
'   Wrap string with single-quotes
-   Remove all double- and single- quotes.

Hint: You can type "/ to wrap quotes and convert to / at the same time.
)
;--  Remove all double-/single- quotes and colons.
	Gui_Add_TxtLabel(GuiName, "", -1, "xm", helptext)
	
	Gui_Switch_Font( GuiName, 0, "black")
	Gui_Add_TxtLabel(GuiName, "", -1, "xm y+10", "&Instructions: ")
	Gui_Add_Editbox( GuiName, "g_amtpUserInput", 50, "x+10 yp-2 g" . "Amtp_UserInputChange")

	Gui_Add_TxtLabel(GuiName, "", -1, "xm y+10", "Convert preview:")
	Gui_Add_Editbox( GuiName, "g_amtpPreviewText", 502, "xm-2 r3")
	
	Gui_Add_Button(GuiName, "g_amtpBtnConvert", -1, "g" . "Amtp_SendToClipboard", "&Send to Clipboard")
	
	Gui_Add_Checkbox(GuiName, "g_amtpCkbKeepWindow", -1, "x+5 yp+5", "&Keep window")
}

Amtp_ShowGui()
{
	GuiName := AmTrimPath.GuiName

	if(!g_amtpHwnd) {
		Amtp_CreateGui() ; destroy old and create new
	}
	
	OnMessage(0x200, Func("Amtp_WM_MOUSEMOVE")) ; add message hook
	
	Gui_Show(GuiName, "", "AHK Trim path utility")

	GuiControl_SetFocus(GuiName, "g_amtpUserInput")
	
	Amtp_SyncUIFromClipboard()
	
	AmTrimPath.hClipmon := Clipmon_CreateMonitor("Amtp_SyncUIFromClipboard")
}

Amtp_HideGui()
{
	GuiName := AmTrimPath.GuiName

	Gui_Hide(GuiName)

	OnMessage(0x200, Func("Amtp_WM_MOUSEMOVE"), 0) ; remove message hook
	tooltip
	
	Clipmon_DeleteMonitor(AmTrimPath.hClipmon)
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
    rsdict.g_amtpCbdText := "0,0,100,0" ; Left/Top/Right/Bottom pct
    rsdict.g_amtpPreviewText := "0,0,100,0"
    dev_GuiAutoResize(AmTrimPath.GuiName, rsdict, A_GuiWidth, A_GuiHeight)
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
	GuiName := AmTrimPath.GuiName
	
	text := Clipboard
	GuiControl_SetText(GuiName, "g_amtpCbdText", text)
	
	if(text=="")
	{
		GuiControl_SetText(GuiName, "g_amtpCbdSum", "Clipboard has no text yet.")
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
	
	GuiControl_SetText(GuiName, "g_amtpCbdSum", sumtext)
	
	;
	; Start converting clipboard content
	;
	
	howto := GuiControl_GetText(GuiName, "g_amtpUserInput")
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
			linetext := StrReplace(linetext, "\", "/")
		else if(InStr(howto, "\"))
			linetext := StrReplace(linetext, "/", "\")
		
		if(InStr(howto, """"))
			linetext := """" linetext """"
		else if(InStr(howto, "'"))
			linetext := "'" linetext "'"
		
		arlines_output[index] := linetext
	}
	
	textfinal := dev_JoinStrings(arlines_output, "`r`n")
	
	GuiControl_SetText(GuiName, "g_amtpPreviewText", textfinal)
}

Amtp_SendToClipboard()
{
	GuiName := AmTrimPath.GuiName
	text := GuiControl_GetText(GuiName, "g_amtpPreviewText")
	Clipboard := text
	
	is_keepwindow := GuiControl_GetValue(GuiName, "g_amtpCkbKeepWindow")
	
	if(is_keepwindow)
		dev_TooltipAutoClear("Sent to clipboard")
	else
		Amtp_HideGui()
}


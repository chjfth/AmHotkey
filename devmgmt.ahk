
AUTOEXEC_devmgmt: ; Workaround for Autohotkey's ugly auto-exec feature. Must be first line.

global g_DevmpEditbox

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;==============================================================
; 2016-09-27: devmgmt.msc hotkeys
;==============================================================

Is_mmc_window()
{
	return dev_IsExeActive("mmc.exe")
}


devmgmt_IsViewingDetailTab(Awinid)
{
	; Surprise! This can succeed as long as the/a device property dialog is open 
	; and you have displayed the Details tab at least once.
	
	; Check Combobox1(device property list) exists and there is at least 10 entries.
	ControlGet, otext, List, , Combobox1, ahk_id %Awinid%
	if(!otext)
		return false

	lines := StrCountLines(otext)
	if(lines<10)
		return false

	ControlGet, otext, List, , SysListView321, ahk_id %Awinid%
	if(!otext)
		return false

	return true
}

#If Is_mmc_window()

F12:: devmgmt_DetailTabShowAllProperties()
devmgmt_DetailTabShowAllProperties()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetTitle, title, ahk_id %Awinid%

	if(!devmgmt_IsViewingDetailTab(Awinid))
	{
		Msgbox, % "devmgmt.ahk: You're not viewing a device property Details tab."
		return false
	}
	
	text_result := "== " . title . " ==`n`n"

	; Iterate each Combobox1(device property list) item, and grab each corresponding ListView321 text.

	ControlGet, all_props, List,, Combobox1, ahk_id %Awinid%
	count_props := StrCountLines(all_props)

	Loop, %count_props%
	{
		Control, Choose, %A_Index%, Combobox1, ahk_id %Awinid%

		ControlGetText, text_prop, Combobox1, ahk_id %Awinid%
		ControlGet, text_val, List, , SysListView321, ahk_id %Awinid%
		
		text_result .= A_Index . ".[" . text_prop . "]`n" . text_val . "`n`n"
	}

;	dev_WriteLogFile("_log1.txt", text_result, true)
;	dev_SetClipboardWithTimeout(text_result)
;	Msgbox, % title . " (" . count_props . " items) sent to clipboard." 

	Gui, Devmp:New
	Gui, Devmp:+Resize +MinSize
	Gui, Devmp:Add, Text,, %title%
	Gui, Devmp:Add, Edit, r20 vg_DevmpEditbox, %text_result%
;	Gui, Devmp:Add, Button, Default, OK
	Gui, Devmp:Show
}

; Q: How can I avoid using the *exclusive* GuiEscape label, and at the same time
; allow multiple popups of the my GUI window?
DevmpGuiClose:
DevmpGuiEscape:
	; This enables ESC to close AHK window.
	Gui, Devmp:Destroy
	return 

DevmpGuiSize()
{
	rsdict := {}
	rsdict.g_DevmpEditbox := "0,0,100,100" ; Left/Top/Right/Bottom
	dev_GuiAutoResize("Devmp", rsdict, A_GuiWidth, A_GuiHeight)
}


#If ;Is_mmc_window()
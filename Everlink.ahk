AUTOEXEC_Everlink: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

/* APIs:
Everlink_LoadData(csvfilepath)
Everlink_LaunchUI()

*/

;;;;;;;; Everlink global vars ;;;;;;;;;;

global g_HwndEVLGui

global gu_evlHeadLabel
global gu_evlSearchWord
global gu_evlListview
global gu_evlBtnOK

Everlink_InitHotkeys()


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include %A_LineFile%\..\evernote.ahk


class Everlink
{
	static isGuiVisible := false
	
	static csvfullpath := ""
	static dict := {} 
	; -- key is "URL|tag", value is description string.
	
	static hwndToPaste := ""
	
	dbg(msg, lv) {
		AmDbg_output("Everlink", msg, lv)
	}
	dbg0(msg) {
		this.dbg(msg, 0)
	}
	dbg1(msg) {
		this.dbg(msg, 1)
	}
	dbg2(msg) {
		this.dbg(msg, 2)
	}
}




Everlink_InitHotkeys()
{
	; App+k to call up the UI
	fxhk_DefineComboHotkey("AppsKey", "k", "Everlink_LaunchUI")
}

Everlink_InitData(csvfilepath)
{
	static s_inited := false
	if(!s_inited)
	{
		if(Everlink_LoadData(csvfilepath)==true)
		{
			s_inited := true
		}
		else
		{
			dev_MsgBoxError(Format("[ERROR] Everlink.ahk: Cannot read or create file:`n`n{}", csvfilepath))
			return
		}
	}
	
}

Evl_ShowGui()
{
	if(Everlink.isGuiVisible)
		return
	
	if(!g_HwndEVLGui) {
		Evl_CreateGui()
	}
	
	
	Gui_Show("EVL", "AutoSize", "Everlink")
	
	Everlink.isGuiVisible := true
}

Evl_HideUI()
{
	Gui_Hide("EVL")
	Everlink.isGuiVisible := false
}

EVLGuiClose()
{
	Evl_HideUI()
}

EVLGuiEscape()
{
	Evl_HideUI()
}

Evl_CreateGui()
{
	GuiName := "EVL" ; EVL: Short for Everlink
	
	Gui_New(GuiName)
	Gui_AssociateHwndVarname(GuiName, "g_HwndEVLGui")
	
	fullwidth := 500
	Gui_Add_TxtLabel(GuiName, "gu_evlHeadLabel", fullwidth, "", "Search for link: (?/?)")
	Gui_Add_Editbox( GuiName, "gu_evlSearchWord", fullwidth, gui_g("Evl_EditChange"), "")

	Gui_Add_Listview(GuiName, "gu_evlListview", fullwidth
		, "r12 -Multi"
		, "Tag|Description|URL")
	Gui_Add_Button(  GuiName, "gu_evlBtnOK", 80, gui_g("Evl_BtnOK") " default", "&Use This")

	Everlink_LoadUIFresh("", true)
	
}



Everlink_LoadData(csvpath)
{
	csvfullpath := win32_GetFullPathName(csvpath)
	Everlink.csvfullpath := csvfullpath
	
	if(not dev_IsDiskFile(csvfullpath))
	{
		; Create that empty file
		dev_WriteFile(csvfullpath, "", true)
	}
	
	Everlink.dbg1(Format("Everlink Loading {}", csvfullpath))
	
	lines := dev_ReadFileLines(csvfullpath)
	if(not lines) 
	{
		; Probably a bad/invalid filepath
		return false
	}
	
	for index,linetext in lines
	{
		fields := StrSplit(linetext, ",", " `t", 3)
		url := fields[1]
		tag := fields[2]
		desc := fields[3]
		
		if(url=="")
			continue ; an empty line
		
		if(tag=="") {
			Everlink.dbg1(Format("Missing tag at line #{} of {}", index, csvpath))
			continue
		}
		
		key := url "|" tag
		Everlink.dict[key] := desc
		
		Everlink.dbg2(Format("Everlink [""{}""]", key))
	}
	
	return true
}

Everlink_LoadUIFresh(ysift:="", is_adjust_column_width:=false)
{
	; Only those entries with ysift substring is populated into Listview
	
	GuiName := "EVL"

	Gui_Default(GuiName)
	LV_Delete()
	
	total := 0
	matches := 0
	for key, val in Everlink.dict
	{
		total++
		
		fields := StrSplit(key, "|")
		url := fields[1]
		tag := fields[2]
		desc := val
		
		if(InStr(tag, ysift) or InStr(desc, ysift))
		{
			LV_Add("", tag, desc, url)
			matches++
		}
	}
	
	AmDbg0("=====" gu_evlHeadLabel)
;	nn = gu_evlHeadLabel ; OK
;	AmDbg0(Format("{}'s varcap={}", nn, dev_VarGetCapacity(gu_evlHeadLabel)))
	
	
	GuiControl_SetText(GuiName, "gu_evlHeadLabel", Format("Search for link: ({}/{})", matches, total))
	
	if(is_adjust_column_width or matches>0)
		dev_LV_UnveilColumns(GuiName)
}


Evl_EditChange()
{
	if(A_GuiControl=="gu_evlSearchWord")
	{
		text := GuiControl_GetText("EVL", "gu_evlSearchWord")
		Everlink_LoadUIFresh(text)
	}
	
}

Everlink_LaunchUI()
{
	Everlink.hwndToPaste := dev_GetActiveHwnd()
	
	Evl_ShowGui()
}

Evl_BtnOK()
{
	GuiName := "EVL"
;	Gui_Default(GuiName)
	
	rowsel := dev_LV_GetNext(GuiName)
	
	if(rowsel>0)
	{
		tag := dev_LV_GetText(GuiName, rowsel, 1)
		url := dev_LV_GetText(GuiName, rowsel, 3)
;		AmDbg0(tag " | " url)
	}
	else
	{
		dev_MsgBoxInfo("No link is selected yet. Nothing to do.")
		return
	}
	
	html := Format("<span>[<a href='{1}'>{2}</a>]&nbsp;</span>", url, tag)
	dev_ClipboardSetHTML(html, true, Everlink.hwndToPaste)
	
	Evl_HideUI()
}






﻿AUTOEXEC_Everlink: ; Workaround for Autohotkey's ugly auto-exec feature. Must be first line.

/* APIs:
Everlink_Init("Everlink.csv.sample") ; User provides csv data to initialize Everlink object (e.g. Everlink.chj.csv)

Everlink_LaunchUI() ; Call this to bring up Everlink UI.

*/

;;;;;;;; Everlink global vars ;;;;;;;;;;

global g_everlink ; The single object responsible for the Everlink GUI

global Everlink_Id := Everlink.Id ; Note: This line is executed AFTER Everlink's static member assignments.

global g_HwndEVLGui

global gu_evlHeadLabel
global gu_evlCkbUseRecent
global gu_evlSearchWord
global gu_evlListview
global gu_evlBtnOK
global gu_evlBtnCopyTag
global gu_evlBtnChgDesc
global gu_evlEdrCsvpath ; Edr : editbox readonly

Everlink_InitHotkeys()


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include %A_LineFile%\..\evernote.ahk
#Include %A_LineFile%\..\libs\win32-const.ahk
#Include %A_LineFile%\..\libs\ClipboardMonitor.ahk


class Everlink
{
	; static vars as constant
	static Id := "Everlink"
	static linktag_allow_unicode := true
	static linktag_maxlen := 32
	static recent_max := 30     ; recently used items to keep in UI
	static _tmp_ := AmDbg_SetDesc(Everlink.Id
		, "Everlink collects links in a form called Linktag, and store them in a .csv file. "
		. "User can later call up Everlink UI to quickly pick up a Linktag and insert it into current Evclip.`n`n"
		. "A Linktag looks like [WinAPI], where the ""WinAPI"" part holds a link to another Evclip. "
		. "When a user copies the whole ""[WinAPI]"", it will be collected by Everlink.")

	isGuiVisible := false
	
	csvfullpath := ""
	dict := {} 
	; -- key is evkey(i.e. "tag|URL"), value is description string.
	
	recent_evkeys := []  ; recently used evkeys
	
	was_show_recent := false
	irow_alltags := 1
	irow_recent := 1
	
	hwndToPaste := ""
	
	hclipmon := 0 ; HANDLE from Clipmon_CreateMonitor()
	
	dbg(msg, lv) {
		AmDbg_output(Everlink_Id, msg, lv)
	}
	dbg0(msg) {
		Everlink.dbg(msg, 0)
	}
	dbg1(msg) {
		Everlink.dbg(msg, 1)
	}
	dbg2(msg) {
		Everlink.dbg(msg, 2)
	}
	ethrow(msg) {
		Everlink.dbg1(msg)
		throw Exception(msg, -1)
	}

	__New(csvfilepath)
	{
		this.dbg2("Everlink.__New(), singleton creating...")
		
		if(this.LoadData(csvfilepath))
			this.dbg2(Format("[OK] Everlink loads datafile: ""{}""", csvfilepath))
		else
			this.ethrow(Format("Everlink fails to load datafile: ""{}""", csvfilepath))
		
		this.hclipmon := Clipmon_CreateMonitor("Everlink_Clipmon", Everlink_Id)
		if(this.hclipmon)
			this.dbg2("[OK] Everlink registers clipboard monitor.")
		else
			this.ethrow(Format("Everlink fails to register clipboard monitor."))
	}
	
	__Delete()
	{
		this.dbg2("Everlink.__Delete(), singleton destroying.")
	}
	
	make_evkey(tag, url) ; static
	{
		return tag "|" url
	}
	
	linkurl_guid_tail(url) ; static
	{
		return SubStr(url, -35)
	}
	
	LoadData(csvpath)
	{
		this.csvfullpath := win32_GetFullPathName(csvpath)

		evl_array := Everlink.__LoadData_as_array(this.csvfullpath, this.dict)
		if(not evl_array)
			return false

		this.LoadRecentListFromDisk()
		
		return true
	}
	
	__LoadData_as_array(csvpath, evkey_dict_output:="") ; static
	{
		; Read csvpath's content and return it as an array,
		; each element is a dict of (.tag .url. .desc)
		; If fail, return "".
		
		csvfullpath := win32_GetFullPathName(csvpath)
		
		if(not dev_IsDiskFile(csvfullpath))
		{
			Everlink.dbg1(Format("[Error] Not a disk file: {}", csvfullpath))
			return ""
		}
		
		Everlink.dbg1(Format("Everlink Loading {}", csvfullpath))
		
		lines := dev_ReadFileLines(csvfullpath)
		
		evl_array := []
		dev_dictclear(evkey_dict_output)
		
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
			
			evl_array.Push({tag:tag, url:url, desc:desc})
			
			if(evkey_dict_output)
			{
				; Construct the output dict
				evkey := Everlink.make_evkey(tag, url)
				if(evkey_dict_output.HasKey(evkey))
				{
					Everlink.dbg1(Format("[NOTE] Ignore duplicate evkey(line #{}): [{}]", index, evkey))
				}
				else
				{
					evkey_dict_output[evkey] := desc
				}
			}
			
		}
		return evl_array
	}
	
	
	
	split_evkey(evkey, byref tag, byref url)
	{
		fields := StrSplit(evkey, "|")
		tag := fields[1]
		url := fields[2]
	}
	
	make_csv_linetext(evkey)
	{
		Everlink.split_evkey(evkey, tag, url) ; tag & url is output var
		desc := this.dict[evkey]
		return Format("{} , {} , {}", url, tag, desc)
	}
	
	SaveData()
	{
		csvcontent := ""
		for index,evkey in dev_objkeys(this.dict)
		{
			csvcontent .= this.make_csv_linetext(evkey) "`r`n"
		}
		dev_WriteWholeFile(this.csvfullpath, csvcontent, "UTF-8")
	}
	
	GetRecentListFilepath()
	{
		return this.csvfullpath . ".recent"
	}
	
	LoadRecentListFromDisk()
	{
		this.dbg2("LoadRecentListFromDisk()...")
	
		fp_recent := this.GetRecentListFilepath()
		evl_array := Everlink.__LoadData_as_array(fp_recent)
		
		this.recent_evkeys := []
		for index,e3 in evl_array
		{
			evkey := Everlink.make_evkey(e3.tag, e3.url)
			this.recent_evkeys.Push(evkey)
		}
	}
	
	SaveRecentListToDisk()
	{
		fp_recent := this.GetRecentListFilepath()
		csvcontent := ""
		for index,evkey in this.recent_evkeys
		{
			csvcontent .= this.make_csv_linetext(evkey) "`r`n"
		}
		dev_WriteWholeFile(fp_recent, csvcontent, "UTF-8")
	}
	
	CreateGui()
	{
		GuiName := "EVL" ; EVL: Short for Everlink
		
		Gui_New(GuiName)
		Gui_ChangeOpt(GuiName, "+Resize +MinSize")
		Gui_AssociateHwndVarname(GuiName, "g_HwndEVLGui")
		
		fullwidth := 500
		Gui_Add_TxtLabel(GuiName, "gu_evlHeadLabel", fullwidth, "", "Search for link: (?/?)")
		Gui_Add_Editbox( GuiName, "gu_evlSearchWord", fullwidth-125, "xm " gui_g("Evl_OnEditChange"), "")
		Gui_Add_Checkbox(GuiName, "gu_evlCkbUseRecent", 120, "x+5 yp+2 " gui_g("Evl_OnCkbRecent"), "Pick &recently used")

		Gui_Add_Listview(GuiName, "gu_evlListview", fullwidth
			, "xm r12 -Multi"
			, "LinkTag|Description|URL")
		Gui_Add_Button(  GuiName, "gu_evlBtnOK",      80, gui_g("Evl_OnBtnOK") " default", "&Use This")
		Gui_Add_Button(  GuiName, "gu_evlBtnCopyTag", 80, gui_g("Evl_OnBtnCopyTag") " x+10 yp", "&Copy Tag")
		Gui_Add_Button(  GuiName, "gu_evlBtnChgDesc", 80, gui_g("Evl_OnBtnChgDesc") " x+10 yp", "Change &Desc")
		Gui_Add_Editbox( GuiName, "gu_evlEdrCsvpath", fullwidth, "xm readonly -E0x200 -0x1000", this.csvfullpath)

		this.RefreshUI_AllTags("", true)
		
		dev_LV_Select1Row(GuiName, 1) ; so that first focusing the Listview can highlight item one immediately
	}
	
	ShowGui()
	{
		if(this.isGuiVisible)
		{
			dev_WinActivateHwnd(g_HwndEVLGui) ; bring it to front
			return ; already shown
		}
		
		if(!g_HwndEVLGui) {
			this.CreateGui()
		}
		
		Gui_Show("EVL", "AutoSize", "Everlink")
		
		dev_OnMessageRegister(win32c.WM_KEYDOWN, "Evl_WM_KEYDOWN")
		
		this.isGuiVisible := true
	}
	
	HideGui()
	{
		Gui_Hide("EVL")

		dev_OnMessageUnRegister(win32c.WM_KEYDOWN, "Evl_WM_KEYDOWN")

		this.isGuiVisible := false
	}

	CurRowIdx()
	{
		GuiName := "EVL"
		idx := dev_LV_GetSelectIdx(GuiName)
		if(idx==0 and LV_GetCount()==1)
		{	; if there is only one row in the list , just return it.
			idx := 1
		}
		return idx
	}

	RefreshUI()
	{
		Guiname := "EVL"
		is_show_recent := Checkbox_GetCheckState(GuiName, "gu_evlCkbUseRecent")

		if(not is_show_recent)
		{
			; Show all tags
			
			; (save idx for the other side)
			if(this.was_show_recent)
				this.irow_recent := this.CurRowIdx(GuiName)
			
			GuiControl_Enable(GuiName, "gu_evlSearchWord", true)
			text := GuiControl_GetText(GuiName, "gu_evlSearchWord")
			this.RefreshUI_AllTags(text)

			if(this.was_show_recent)
				dev_LV_Select1Row(GuiName, this.irow_alltags)
			
			this.was_show_recent := false
		}
		else
		{
			; (save idx for the other side)
			if(not this.was_show_recent)
			{
				this.irow_alltags := this.CurRowIdx(GuiName)
			}
				
			GuiControl_Enable(GuiName, "gu_evlSearchWord", false)
			this.RefreshUI_RecentTags()
			
			if(not this.was_show_recent)
				dev_LV_Select1Row(GuiName, this.irow_recent)
			
			this.was_show_recent := true
		}
	}

	RefreshUI_AllTags(ysift:="", is_adjust_column_width:=false)
	{
		; Only those entries containing ysift substring is populated into Listview
		GuiName := "EVL"
		Gui_Default(GuiName)
		LV_Delete()
		
		total := 0
		matches := 0
		for evkey, desc in this.dict
		{
			total++
			
			Everlink.split_evkey(evkey, tag, url) ; tag & url is output var

			if(InStr(tag, ysift) or InStr(desc, ysift))
			{
				LV_Add("", tag, desc, url)
				matches++
			}
		}

		GuiControl_SetText(GuiName, "gu_evlHeadLabel", Format("&Search for link: ({}/{})", matches, total))
		
		if(is_adjust_column_width or matches>0)
			dev_LV_UnveilColumns(GuiName)
	}
	
	RefreshUI_RecentTags()
	{
		GuiName := "EVL"
		Gui_Default(GuiName)
		LV_Delete()
		
		count := 0
		for index,evkey in this.recent_evkeys
		{
			Everlink.split_evkey(evkey, tag, url) ; tag & url is output var
			
			desc := this.dict[evkey]
			LV_Add("", tag, desc, url)
			
			count++
		}

		GuiControl_SetText(GuiName, "gu_evlHeadLabel", "Pick a recent link:")
		
		if(count>0)
			dev_LV_UnveilColumns(GuiName)
	}

	OnBtnOK()
	{
		GuiName := "EVL"
	;	Gui_Default(GuiName)
		
		rowsel := this.CurRowIdx(GuiName)
		
		if(rowsel>0)
		{
			tag := dev_LV_GetText(GuiName, rowsel, 1)
			url := dev_LV_GetText(GuiName, rowsel, 3)
;			AmDbg0(tag " | " url)
		}
		else
		{
			dev_MsgBoxInfo("No link is selected yet. Nothing to do.")
			return
		}
		
		html := Format("<span>[<a href='{1}'>{2}</a>]&nbsp;</span>", url, tag)
		dev_ClipboardSetHTML(html, true, this.hwndToPaste)
		
		evkey := Everlink.make_evkey(tag, url)

		this.SaveRecentListToDisk()

		this.HideGui()
	}

	OnEditChange()
	{
		if(A_GuiControl=="gu_evlSearchWord")
		{
			this.RefreshUI()
		}
		
	}
	
	OnCkbRecent()
	{
		this.RefreshUI()
		
		if(this.was_show_recent)
			GuiControl_SetFocus("EVL", "gu_evlListview")
		else
			GuiControl_SetFocus("EVL", "gu_evlSearchWord")
		
	}
	
	On_WM_KEYDOWN(wParam, lParam, msg, hwnd)
	{
		; {"vk":wParam, "fDown":true, "cRepeat":LOWORD(0xFFFF), "flags":HIWORD(lParam)}
		mx := msgx_WM_KEYDOWN(wParam, lParam)
		
		if(A_GuiControl=="gu_evlSearchWord")
		{
			if(mx.vk==win32c.VK_DOWN || mx.vk==win32c.VK_UP)
			{
				GuiControl_SetFocus("EVL", "gu_evlListview")
				dev_LV_Select1Row("EVL")
			}
		}
	}

	OnBtnCopyTag()
	{
		GuiName := "EVL"
		rowsel := this.CurRowIdx(GuiName)
;		AmDbg0("OnBtnCopyTag() rowsel=" rowsel)
		if(rowsel>0)
		{
			tag := dev_LV_GetText(GuiName, rowsel, 1)
			Clipboard := tag
			dev_TooltipAutoClear("Copied: " tag)
		}
		else
		{
			dev_MsgBoxInfo("Please select a LinkTag first.")
			return
		}
	}
	
	OnBtnChgDesc()
	{
		GuiName := "EVL"
		rowsel := this.CurRowIdx(GuiName)
		if(rowsel>0)
		{
			tag := dev_LV_GetText(GuiName, rowsel, 1)
			url := dev_LV_GetText(GuiName, rowsel, 3)
			desc := dev_LV_GetText(GuiName, rowsel, 2)
			evkey := Everlink.make_evkey(tag, url)
			
			isok := dev_InputBox_InitText("Everlink - Rename description"
				, Format("Input new description for [{}]", tag), desc) ; output desc
			
			if(isok)
			{
				this.dict[evkey] := desc
				LV_Modify(rowsel, "Col2", desc)
				dev_LV_UnveilColumns(GuiName)
			}
			
			this.SaveData()
		}
		else
		{
			dev_MsgBoxInfo("Please select a LinkTag first.")
			return
		}
	}

	ClipmonCallback()
	{
		; This acts as a Clipmon callback.
		; It checks if [Clipboard has CF_HTML content and has a piece of short text with 
		; Evernote internal-link(call it evlink) in it. If it has, then pick up
		; the evlink and add it to .dict .

		cfhtml := WinClip.GetHtml("UTF-8")
		if(not cfhtml)
		{
			this.dbg2("WinClip.GetHtml() returns empty.")
			return
		}

		preview_limit := 2000
		taildots := StrLen(cfhtml)>preview_limit ? "......" : ""
		this.dbg2("Got CF_HTML: " SubStr(cfhtml, 1, preview_limit) " " taildots)
		
		if(not Everlink.linktag_allow_unicode)
		{
			if(dev_IsUnicodeInString(cfhtml))
			{
				this.dbg2("Sees non-ASCII chars, ignore it. (due to NOT linktag_allow_unicode)")
				return
			}
		}
		
		; URL Sample:
		; https://www.evernote.com/shard/s21/nl/2425275/4586fb5e-4414-4e81-8ea8-75bf28d9d666
		;
		; a piece of text like [WinAPI] will be matched, on the premise that WinAPI is a href to https://...
		
		ptn := "<!--StartFragment-->`r`n<span><span>.{0,5}\[<a href=""(https://www.evernote.com/shard/s../nl/[0-9a-z-/]+)""[^>]*>([^<]+?)</a>\]"
		; -- allow only 5 (as in .{0,5}) chars before the link-text.
		; -- Meaning: For an Evlink like "[VMwks]. VMware Workstation 备忘收集" -- only VMWks in green color, "[" and "]" not in green,
		;    the "VMwks" here is considered a LinkTag.

		ptn_WRONG := "<!--StartFragment-->`r`n<span><span>.{0,5}<a href=""(https://www.evernote.com/shard/s../nl/[0-9a-z-/]+)""[^>]*>\[([^<]+?)\].*</a>"
		; -- If we see a Evlink "[VMwks] 制备 Win10 虚拟机, 节省宿主机空间的最佳实践" -- all text in green-color,
		;    This link is (probably) NOT what [VMwks] refers to, it is another Evclip that is categorized under [VMwks] topic.
		;    So I don't extract Linktag for this.

		foundpos := RegExMatch(cfhtml, ptn, outfound)
		if( foundpos==0 )
		{
			this.dbg2("Everlink-RegEx not match")
			return
		}
		
		linkurl := outfound1 ; https://www.evernote.com/shard/s21/nl/2425275/...
		linktag := outfound2 ; chja20 (for example)
		
		linktag := Trim(linktag, "[()]")
		
		this.dbg2(Format("Everlink-RegEx match: [{}] {}", linktag, linkurl))
		
		if(strlen(linktag)>Everlink.linktag_maxlen)
		{
			this.dbg1(Format("Linktag '{}' exceeds {} chars, ignore it.", linktag, Everlink.linktag_maxlen))
			return
		}
		
		evkey := Everlink.make_evkey(linktag, linkurl)

		if(this.dict.HasKey(evkey))
		{
			this.InsertRecentEvkey(evkey)
			return
		}
		
		this.dbg1(Format("Got a new evkey: {}|{}", linktag, Everlink.linkurl_guid_tail(linkurl)))
		; -- use a shorter form
		
		desc := ""
		isok := dev_InputBox_InitText("Everlink - New linktag detected"
			, Format("Input a description for [{}]", linktag), desc) ; output desc
		if(isok)
		{
			this.dict[evkey] := desc

			this.InsertRecentEvkey(evkey)
			this.RefreshUI()
			this.SaveData()
		}
	}
	
	InsertRecentEvkey(evkey1)
	{
		; Insert evkey1 at head of .recent_evkeys[]

		; first, remove old dup evkey 
		for index,evkey in this.recent_evkeys
		{
			if(evkey1==evkey)
			{
				this.recent_evkeys.RemoveAt(index)
				break
			}
		}
		
		; insert at head
		this.recent_evkeys.InsertAt(1, evkey1)
		
		; Delete beyond max
		dev_ArrayTruncateAt_(this.recent_evkeys, Everlink.recent_max)
		
		if(this.was_show_recent)
			this.RefreshUI()
	}
	
} ; class Everlink


Everlink_InitHotkeys()
{
	; App+k to call up the UI
	fxhk_DefineComboHotkeyCond("AppsKey", "k", "Evernote_IsMainFrameOrSingleActive", "Everlink_LaunchUI")
	
	; Caller code suggestion
	; dev_DefineHotkeyWithCondition("!k", "Evernote_IsMainFrameOrSingleActive", "Everlink_LaunchUI")
}

Everlink_Init(csvfilepath, is_pop_errmsg:=true)
{
	try {
		
		g_everlink := new Everlink(csvfilepath)
		varcap := dev_VarGetCapacity(g_everlink)
		Everlink.dbg2(Format("[OK] Everlink singleton object created. (addr=0x{} , varcap={})", &g_everlink, varcap))
		return true
	
	} catch e {
	
		errmsg := "Everlink_Init() fail. Reason:`n`n" e.message ; Double `n to make MsgBox text friendlier.
		
		Everlink.dbg1(errmsg)
	
		if(is_pop_errmsg)
		{
			dev_MsgBoxWarning(errmsg)
		}
		
		g_everlink := "" ; delete the object if sth goes wrong after object-construction
		return false
	}
}

Everlink_LaunchUI()
{
	if(!g_everlink)
	{
		dev_MsgBoxError("Everlink has not been initialized.`n`n"
			. "You have to first call Everlink_Init(csvfilepath) .")
		return
	}

	g_everlink.hwndToPaste := dev_GetActiveHwnd()
	
	g_everlink.ShowGui()
	
	dev_WinActivateHwnd(g_HwndEVLGui)
}


EVLGuiSize()
{
	rsdict := {}
	rsdict.gu_evlSearchWord := JUL.FillWidth_AtTop
	rsdict.gu_evlCkbUseRecent := JUL.PinToRightTop
	rsdict.gu_evlListview := JUL.FillArea
	
	rsdict.gu_evlBtnOK := JUL.PinToLeftBottom
	rsdict.gu_evlBtnCopyTag := JUL.PinToLeftBottom
	rsdict.gu_evlBtnChgDesc := JUL.PinToLeftBottom
	rsdict.gu_evlEdrCsvpath := JUL.FillWidth_AtBottom
	
	dev_GuiAutoResize("EVL", rsdict, A_GuiWidth, A_GuiHeight)
}

EVLGuiClose()
{
	g_everlink.HideGui()
}

EVLGuiEscape()
{
	g_everlink.HideGui()
}



Evl_OnEditChange()
{
	g_everlink.OnEditChange()
}

Evl_OnBtnOK()
{
	g_everlink.OnBtnOK()
}


Evl_WM_KEYDOWN(wParam, lParam, msg, hwnd)
{
	g_everlink.On_WM_KEYDOWN(wParam, lParam, msg, hwnd)
}

Evl_OnCkbRecent()
{
	g_everlink.OnCkbRecent()
}

Evl_OnBtnCopyTag()
{
	g_everlink.OnBtnCopyTag()
}

Evl_OnBtnChgDesc()
{
	g_everlink.OnBtnChgDesc()
}


Everlink_Clipmon()
{
	g_everlink.ClipmonCallback()
}



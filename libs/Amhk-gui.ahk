;===================================
;====== AHK Gui & GuiControl =======
;===================================

class AmhkGui ; To store global vars
{ 
	static dictGuiAutoResize := {}
}


gui_g(label_or_funcname)
{
	dev_assert(strlen(label_or_funcname)>=2)
	return "g" label_or_funcname
}

gui_v(varname)
{
	dev_assert(strlen(label_or_funcname)>=2)
	return "v" varname
}


Gui_IsValidVar(varname)
{
	
	if(StrIsStartsWith(varname, "gu_"))
		return true
	else
		return false
}

Assert_UicVarname(CtrlVarname)
{
	if(StrLen(CtrlVarname)==0)
	{
		dev_assert(0, "You pass in an empty GUI-control varname. It must be in string form ""gu_XXX"" .")
	}
	
	if(CtrlVarname=="-")
		return ; "-" means user explicitly do NOT want to associate a varname
	
	dev_assert(Gui_IsValidVar(CtrlVarname)
		, Format("'{}' is not valid GUI-control varname, it must starts with ""gu_"" .", CtrlVarname))
}

Gui_New(GuiName)
{
	Gui, % (GuiName ? GuiName ":" : "") . "New"
}

Gui_Default(GuiName)
{
	Gui, % (GuiName ? GuiName ":" : "") . "Default"
}

Gui_Hide(GuiName)
{
	Gui, % (GuiName ? GuiName ":" : "") . "Hide"
}

Gui_Destroy(GuiName)
{
	Gui, % (GuiName ? GuiName ":" : "") . "Destroy"
}

Gui_Show(GuiName, options="", title:="AHKGUI")
{
	; options:
	; W400 H300 Center

	cmd := "Show"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	Gui, % cmd, % options, % title
}

Gui_Submit(GuiName, is_keep_gui:=false)
{
	Gui, % (GuiName ? GuiName ":" : "") "Submit", % is_keep_gui ? "NoHide" : ""
}

Gui_AssociateHwndVarname(GuiName, HwndVarname)
{
	dev_assert(GuiName)

	Gui, % Format("{}:+Hwnd{}", GuiName, HwndVarname)
}

Gui_ChangeOpt(GuiName, optstr)
{
	Gui, % (GuiName ? GuiName ":" : "") . optstr
}

Gui_SetXYMargin(GuiName, xmargin, ymargin)
{
	cmd := "Margin"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	Gui, % cmd , % xmargin, % ymargin
}

Gui_Switch_Font(GuiName, sizept:=0, rgbhex:="", fontface:="", weight:=400)
{
	; Set new font for next control, influencing Button, TxtLabel, Editbox etc.
	;	Gui, EVTBL:Font, s9 cBlack, Tahoma

	; rgbhex: "FF9977" or "Blue" , fontface: "Tahoma"
	
	cmd := "Font"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	opt_sizept := sizept ? ("s" sizept) : ""
	opt_rgbhex := StrLen(rgbhex)!=0 ? ("c" rgbhex) : "" 
	; -- should not check rgbhex as bool, bcz "000000" is considered false
	opt_weight := weight ? ("w" weight) : ""
	
	optall := opt_sizept " " opt_rgbhex " " opt_weight

	Gui, % cmd, % optall, % fontface
}

GuiControl_ChangeOpt(GuiName, CtrlVarname, opt, value:="")
{
	; Change a GUI-control's option dynamically.
	; Example:
	;	GuiControl_ChangeOpt("EVP", gu_xxx, "+AltSubmit")
	
	Assert_UicVarname(CtrlVarname)
	cmd := (GuiName ? GuiName ":" : "") . opt
	GuiControl, % cmd, % CtrlVarname, % value
}

GuiControl_SetCallback(GuiName, CtrlVarname, fni)
{
	fnobj := dev_make_fnobj(fni)
	GuiControl_ChangeOpt(GuiName, CtrlVarname, "+g", fnobj)
}

Gui_Add_TxtLabel(GuiName, CtrlVarname:="", width:=-1, format:="", text:="")
{
	; format: 
	; +0x8000 (SS_PATHELLIPSIS)
	; +0xC000 (SS_WORDELLIPSIS)
	
	if(CtrlVarname=="")
		CtrlVarname := "-"

	Assert_UicVarname(CtrlVarname)
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	vCtrlVarname := StrLen(CtrlVarname)>1 ? "v" CtrlVarname : ""
	wWidth := width>0 ? "w" width : "" ; so width==-1 will make it auto-width by text length
	
	Gui, % cmdadd, Text, % Format("{} {} {}", vCtrlVarname, wWidth, format), % text
}

Gui_Add_StaticLabel(GuiName, text)
{
	Gui_Add_TxtLabel(GuiName, "", -1, "", text)
}

GuiControl_SetColor(GuiName, CtrlVarname, fgcolor:="", bgcolor:="")
{
	; color value in RRGGBB string format, "FF9977", "Blue", "Red" or "default".
	; If empty string, that means no change to current value.
	;
	; Note: bgcolor is only effective on a small number of controls, such as Progress-bar.
	
	Assert_UicVarname(CtrlVarname)
	optfg := fgcolor ? ("+c" fgcolor) : ""
	optbg := bgcolor ? ("+Background" bgcolor) : ""
	
	if(optfg || optbg)
	{
		GuiControl_ChangeOpt(GuiName, CtrlVarname, optfg " " optbg)
	}
}

Gui_Add_Button(GuiName, CtrlVarname, width, format, btntext)
{
	Assert_UicVarname(CtrlVarname)
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	vCtrlVarname := StrLen(CtrlVarname)>1 ? "v" CtrlVarname : ""
	wWidth := width>0 ? "w" width : "" ; so width==-1 will make it auto-width by text length

	Gui, % cmdadd, Button, % Format("{} {} {}", vCtrlVarname, wWidth, format), % btntext
}

Gui_Add_Picture(GuiName, CtrlVarname, width, format, imgfilepath:="")
{
	Assert_UicVarname(CtrlVarname)
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	vCtrlVarname := StrLen(CtrlVarname)>1 ? "v" CtrlVarname : ""
	wWidth := width>0 ? "w" width : "" ; so width==-1 will make it auto-width by text length

	Gui, % cmdadd, Picture, % Format("{} {} {}", vCtrlVarname, wWidth, format), % imgfilepath
}

Gui_Picture_SetIconFromDll(GuiName, CtrlVarname, dllpath, icon_group_idx)
{
	iconpath := Format("*icon{} {}", icon_group_idx, dllpath)
	GuiControl_SetText(GuiName, CtrlVarname, iconpath)
}

Gui_Add_Checkbox(GuiName, CtrlVarname, width, format, btntext)
{
	; format: "Checked"

	Assert_UicVarname(CtrlVarname)
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	vCtrlVarname := StrLen(CtrlVarname)>1 ? "v" CtrlVarname : ""
	wWidth := width>0 ? "w" width : "" ; so width==-1 will make it auto-width by text length
	
	Gui, % cmdadd, Checkbox, % Format("{} {} {}", vCtrlVarname, wWidth, format), % btntext
}

Gui_Add_Radiobox(GuiName, CtrlVarname, width, format, btntext)
{
	; format: "Group Checked"
	Assert_UicVarname(CtrlVarname)
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	vCtrlVarname := StrLen(CtrlVarname)>1 ? "v" CtrlVarname : ""
	wWidth := width>0 ? "w" width : "" ; so width==-1 will make it auto-width by text length
	
	Gui, % cmdadd, Radio, % Format("{} {} {}", vCtrlVarname, wWidth, format), % btntext
}

Gui_Add_Editbox(GuiName, CtrlVarname, width, format, init_text:="")
{
	; format: 
	; r10
	; Readonly
	; -E0x200 (turn off WS_EX_CLIENTEDGE, remove editbox border thin line)

	Assert_UicVarname(CtrlVarname)
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	vCtrlVarname := StrLen(CtrlVarname)>1 ? "v" CtrlVarname : ""
	wWidth := width>0 ? "w" width : "" ; so width==-1 will make it auto-width by text length

	Gui, % cmdadd, Edit, % Format("{} {} {}", vCtrlVarname, wWidth, format), % init_text
}

Gui_Add_Listbox(GuiName, CtrlVarname, width, format, itemlist_pipes:="")
{
	; format: AltSumbit r12

	Assert_UicVarname(CtrlVarname)
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	vCtrlVarname := StrLen(CtrlVarname)>1 ? "v" CtrlVarname : ""
	wWidth := width>0 ? "w" width : "" ; so width==-1 will make it auto-width by text length

	Gui, % cmdadd, ListBox, % Format("{} {} {}", vCtrlVarname, wWidth, format), % itemlist_pipes
}

Gui_Add_Combobox(GuiName, CtrlVarname, width, format, itemlist_pipes:="")
{
	; format: AltSumbit

	Assert_UicVarname(CtrlVarname)
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	vCtrlVarname := StrLen(CtrlVarname)>1 ? "v" CtrlVarname : ""
	wWidth := width>0 ? "w" width : "" ; so width==-1 will make it auto-width by text length

	Gui, % cmdadd, ComboBox, % Format("{} {} {}", vCtrlVarname, wWidth, format), % itemlist_pipes
}

Gui_Add_Listview(GuiName, CtrlVarname, width, format, columnlist_pipes)
{
	Assert_UicVarname(CtrlVarname)
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	vCtrlVarname := StrLen(CtrlVarname)>1 ? "v" CtrlVarname : ""
	wWidth := width>0 ? "w" width : "" ; so width==-1 will make it auto-width by text length
	
	Gui, % cmdadd, ListView, % Format("{} {} {}", vCtrlVarname, wWidth, format), % columnlist_pipes
}


GuiControl_Enable(GuiName, CtrlVarname, is_enable)
{
	Assert_UicVarname(CtrlVarname)
	cmd := is_enable ? "Enable" : "Disable"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	GuiControl, % cmd, % CtrlVarname
}

GuiControl_ButtonCheck(GuiName, CtrlVarname, is_check)
{
	Assert_UicVarname(CtrlVarname)
	cmd := GuiName ? (GuiName ":") : ""

	GuiControl, % cmd, % CtrlVarname, % is_check ? "1" : "0"
}

GuiControl_Show(GuiName, CtrlVarname, is_show)
{
	Assert_UicVarname(CtrlVarname)
	cmd := is_show ? "Show" : "Hide"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	GuiControl, % cmd, % CtrlVarname
}

GuiControl_GetHwnd(GuiName, CtrlVarname)
{
	Assert_UicVarname(CtrlVarname)
	cmd := "Hwnd"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	GuiControlGet, outputHwnd, % cmd, % CtrlVarname
	return outputHwnd
}

GuiControl_GetText(GuiName, CtrlVarname)
{
	Assert_UicVarname(CtrlVarname)
	cmd := GuiName ? GuiName ":" : ""
	GuiControlGet, outvar, % cmd, % CtrlVarname
	return outvar
}

GuiControl_GetValue(GuiName, CtrlVarname)
{
	text := GuiControl_GetText(GuiName, CtrlVarname)
	return dev_str2num(text)
}


GuiControl_SetText(GuiName, CtrlVarname, text)
{
	; CtrlVarname can also be an HWND value.
	; If it is an HWND, GuiName can be empty string.
	;
	; For Combobox, we should use Combobox_SetText()

	Assert_UicVarname(CtrlVarname)
	cmd := GuiName ? GuiName ":" : ""
	GuiControl, % cmd, % CtrlVarname, % text
}
; -- Memo: GuiControl can be called to set a Uic's text without knowing its containing GuiName,
;    as long as we know the Uic's HWND. This has not been encapsulated yet.
;    ClipboardMonitor.ahk's pre-20220422 code demonstrates this.

GuiControl_SetValue(GuiName, CtrlVarname, text)
{
	GuiControl_SetText(GuiName, CtrlVarname, text)
}

Combobox_SetText(GuiName, CtrlVarname, text)
{
	Assert_UicVarname(CtrlVarname)
	cmd := (GuiName ? GuiName ":" : "") . "Text"
	GuiControl, % cmd, % CtrlVarname, % text
}


GuiControl_GetPos(GuiName, CtrlVarname)
{
	Assert_UicVarname(CtrlVarname)
	cmd := "Pos"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	GuiControlGet, outvar, % cmd, % CtrlVarname
	
	return {"x":outvarX, "y":outvarY, "w":outvarW, "h":outvarH}
}

GuiControl_SetPos(GuiName, CtrlVarname, x:=-1, y:=-1, w:=-1, h:=-1, force_redraw:=true)
{
	; -1 : Don't change current value
	
	Assert_UicVarname(CtrlVarname)
	cmd := force_redraw ? "MoveDraw" : "Move"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	r := GuiControl_GetPos(GuiName, CtrlVarname)

	GuiControl, % cmd, % CtrlVarname, % Format("x{} y{} w{} h{}"
		, x==-1 ? r.x : x
		, y==-1 ? r.y : y
		, w==-1 ? r.w : w
		, h==-1 ? r.h : h)
}

Checkbox_GetCheckState(GuiName, CtrlVarname)
{
	Assert_UicVarname(CtrlVarname)
	cmd := ""
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	GuiControlGet, outvar, % cmd, % CtrlVarname
	
	return outvar ; Can be 1, 0, -1
}

GuiControl_ComboboxAddItems(GuiName, CtrlVarname, ar_strings)
{
	if(StrLen(ar_strings)>0)
	{
		; ar_string should be | separated string
		value := ar_strings 
	}
	else
	{
		; ar_string should be an array of strings
		value := dev_JoinStrings(ar_strings, "|")
	}
	
	GuiControl_SetText(GuiName, CtrlVarname, value)
}

GuiControl_ComboboxGetText(GuiName, CtrlVarname)
{
	;pending, need to query whether it has 'AltSubmit' option .
}

GuiControl_SetFocus(GuiName, CtrlVarname)
{
	Assert_UicVarname(CtrlVarname)
	cmd := "Focus"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	GuiControl, % cmd, % CtrlVarname
}

GuiControl_ChooseN(GuiName, CtrlVarname, item_index)
{
	Assert_UicVarname(CtrlVarname)
	cmd := (GuiName ? GuiName ":" : "") . "Choose"
	
	GuiControl, % cmd, % CtrlVarname, % item_index
}

; =================================

dev_GuiAutoResize(GuiName, rsdict, gui_nowwidth, gui_nowheight, force_redraw:=false, qmargin:="")
{
	; gui_nowwidth, gui_nowheight tells the GUI's client area size
	
	if(qmargin) ; q implies quad
	{
		; Example: qmargin:="10,20,10,20"
		token := StrSplit(qmargin, ",")
		x0m := token[1]
		y0m := token[2]
		x1m := token[3]
		y1m := token[4]

		nowwidth := gui_nowwidth - (x0m+x1m)
		nowheight := gui_nowheight - (y0m+y1m)
	}
	else 
	{
		x0m := 0
		y0m := 0
		x1m := 0
		y1m := 0
		nowwidth := gui_nowwidth
		nowheight := gui_nowheight
	}
	
	
;	MsgBox, % Format("nowwidth={} nowheight={} x0m={} y0m={}", nowwidth, nowheight, x0m, y0m)
	
	if( ! AmhkGui.dictGuiAutoResize[GuiName] )
	{
;		Dbgwin_Output("dev_GuiAutoResize() see newly created: " GuiName) ; debug
		
		; It is the first time this GuiName is seen, which means this GUI is just created, 
		; so we initialize it. The ctrl's positions at this time are considered at their initial positions.
		
		gui_rsinfo := {}
		
		for ctrlvar, quad in rsdict
		{
			; Sample: ctrlvar="g_PvhtmlEdit" , qual="0,0,100,100"
			
			gui_rsinfo[ctrlvar] := {} ; a nested dict
			ctrl_rsinfo := gui_rsinfo[ctrlvar] ; define a label for easier reference
			
			token := StrSplit(quad, ",")
			ctrl_rsinfo.pct_left := token[1]/100
			ctrl_rsinfo.pct_top := token[2]/100
			ctrl_rsinfo.pct_right := token[3]/100
			ctrl_rsinfo.pct_bottom := token[4]/100
			
			GuiControlGet, rect, %GuiName%:Pos, %ctrlvar%
;			Dbgwin_Output(Format("dev_GuiAutoResize({}.{}) Init: X={}, Y={}, W={}, H={}", GuiName, ctrlvar, rectX, rectY, rectW, rectH)) ; debug
			
			ctrl_rsinfo.ofs_left := round( (rectX-x0m) - nowwidth * ctrl_rsinfo.pct_left )
			ctrl_rsinfo.ofs_top  := round( (rectY-y0m) - nowheight * ctrl_rsinfo.pct_top )
			ctrl_rsinfo.ofs_right := round( (rectX-x0m + rectW) - nowwidth * ctrl_rsinfo.pct_right )
			ctrl_rsinfo.ofs_bottom := round( (rectY-y0m + rectH) - nowheight * ctrl_rsinfo.pct_bottom )

;			Dbgwin_Output(Format("dev_GuiAutoResize({}.{}) Init: ofs: L={}, T={}, R={}, B={}", GuiName, ctrlvar, ctrl_rsinfo.ofs_left, ctrl_rsinfo.ofs_top, ctrl_rsinfo.ofs_right, ctrl_rsinfo.ofs_bottom)) ; debug
		}

		; Mark this GuiName "created".
		AmhkGui.dictGuiAutoResize[GuiName] := gui_rsinfo

	}
	else
	{
;		Dbgwin_Output("dev_GuiAutoResize() see existing: " GuiName) ; debug
		
		gui_rsinfo := AmhkGui.dictGuiAutoResize[GuiName] ; define a label for easier reference
		
		for ctrlvar, ctrl_rsinfo in gui_rsinfo
		{
			; Calculate new positions for this ctrl
			newX := round( nowwidth * ctrl_rsinfo.pct_left + ctrl_rsinfo.ofs_left +x0m )
			newY := round( nowheight * ctrl_rsinfo.pct_top + ctrl_rsinfo.ofs_top +y0m )
			newW := round( nowwidth * ctrl_rsinfo.pct_right + ctrl_rsinfo.ofs_right - newX +x0m )
			newH := round( nowheight * ctrl_rsinfo.pct_bottom + ctrl_rsinfo.ofs_bottom - newY +y0m )

;			Dbgwin_Output(Format("dev_GuiAutoResize Newpos({}.{}) is {},{} | {},{}", GuiName, ctrlvar, newX, newY, newW, newH)) ; debug

			; Move this ctrl
			newpos := Format("x{} y{} w{} h{}", newX, newY, newW, newH)
			
			RedrawOp := force_redraw ? "MoveDraw" : "Move"
			
			GuiControl, %GuiName%:%RedrawOp%, %ctrlvar%, % newpos
		}
	}
}

dev_GuiAutoResizeRemove(GuiName)
{
;	Dbgwin_Output("dev_GuiAutoResizeRemove(): " GuiName) ; debug

	AmhkGui.dictGuiAutoResize.Delete(GuiName)
}


GuiButton_SetIconFromDll(GuiName, CtrlVarName, dllname, icon_idx, icon_width, is_icon_only:=false)
{
	hctl := GuiControl_GetHwnd(GuiName, CtrlVarName)
	
;	Dbgwin_Output("hctl = " hctl)
	if(not hctl)
		return false

	null := ""
	IMAGE_ICON := 1
	LR_SHARED := 0x8000
	
	hDll := DllCall("GetModuleHandle", "Str", dllname)
;	Dbgwin_Output("hDll = " hDll)
	if(hDll==0)
		return false
	
	hIcon := DllCall("LoadImage"
		, "Ptr", hDll ; HMODULE 
		, "Ptr", icon_idx ; LPCTSTR lpszName or Resource-ID
		, "Int", IMAGE_ICON ; UINT uType
		, "Int", icon_width ; int cxDesired
		, "Int", icon_width ; int cyDesired
		, "Int", LR_SHARED) ; UINT fuLoad
;	Dbgwin_Output("hIcon = " hIcon)
	if(hIcon==0)
		return false

	BM_SETIMAGE := 247
	DllCall("SendMessage"
		, "Ptr", hctl
		, "Int", BM_SETIMAGE
		, "Ptr", IMAGE_ICON
		, "Ptr", hIcon)
	
	opt_BS_ICON := is_icon_only ? "+0x40" : "-0x40"
	GuiControl_ChangeOpt(GuiName, CtrlVarname, opt_BS_ICON)
	
	return true
}

dev_Listbox_Clear(hwndListbox)
{
	LB_RESETCONTENT := 0x0184
	dev_SendMessage(hwndListbox, LB_RESETCONTENT, 0, 0)
}

dev_Combobox_Clear(hwndCombobox)
{
	CB_RESETCONTENT := 0x014B
	dev_SendMessage(hwndCombobox, CB_RESETCONTENT, 0, 0)
}


dev_LV_UnveilColumns(GuiName:="")
{
	if(GuiName)
		Gui_Default(GuiName)
	
	LV_ModifyCol()
}

dev_LV_GetSelectIdx(GuiName)
{
	return dev_LV_GetNext(GuiName, 0)
}

dev_LV_GetNext(GuiName, StartRow:=0, RowType:="")
{
	; Return which row is selected/highlighted.
	
	Gui_Default(GuiName)

	return LV_GetNext(Start, RowType)
}

dev_LV_GetText(GuiName, iRow, iCol:=1)
{
	Gui_Default(GuiName)
	
	LV_GetText(ret, iRow, iCol)
	return ret
}

dev_LV_Select1Row(GuiName, iRow:=0, is_on:=true)
{
	if(GuiName)
		Gui_Default(GuiName)
	
	neg := is_on ? "" : "-"
	
	if(iRow<=0)
	{
		; Focus currently "select" row.
		; Yes, "select" and "focus" are different things in Listview UI
		
		iRow := dev_LV_GetSelectIdx(GuiName)
		; AmDbg0(Format("iRow -1 => {}", iRow))
		
		if(iRow==0)
		{
			; None was selected, so we select 1st item.
			iRow := 1
		}
	}
	
	LV_Modify(iRow, Format("{1}Select {1}Focus", neg))
}

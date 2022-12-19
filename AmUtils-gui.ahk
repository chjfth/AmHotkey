

;===================================
;====== AHK Gui & GuiControl =======
;===================================



Gui_AssociateHwndVarname(GuiName, HwndVarname)
{
	dev_assert(GuiName)

	Gui, % Format("{}:+Hwnd{}", GuiName, HwndVarname)
}

Gui_IsValidVar(varname)
{
	; [2022-12-16] This is a fake function that always succeeds.
	; Currently, no solution for this semantic yet.

	; Wrong comment >>>
			; If varname is not defined, return false.
			; User note: When passed in, your varname should be surround by double-quotes.
			; Example:
			;	Gui_IsValidVar("g_count")    ; may get true
			;	Gui_IsValidVar("NoSuchVar")  ; will get false
			;
			; In order for a `global` var to pass this test, please initialize 
			; your global var with a explicit value, like this:
			; 	global g_count := 0
			; 	global g_errmsg := ""
	; Wrong comment <<<

	if(%varname%)
		return true
	else if(%varname%==0)
		return true
	else if(%varname%=="") ; [2022-12-16] This will be true even if varname is not defined.
		return true
	else
		return false
}

Gui_Show(GuiName, options="", title:="AHKGUI")
{
	cmd := "Show"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	Gui, % cmd, % options, % title
}

Gui_Hide(GuiName)
{
	cmd := "Hide"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	Gui, % cmd
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

Gui_Switch_Font(GuiName, sizept=0, rgbhex="", fontface:="", weight:=400)
{
	; Set new font for next control, influencing Button, TxtLabel, Editbox etc.
	;	Gui, EVTBL:Font, s9 cBlack, Tahoma

	; rgbhex: "FF9977" or "Blue" , fontface: "Tahoma"
	
	cmd := "Font"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	opt_sizept := sizept ? ("s" sizept) : ""
	opt_rgbhex := rgbhex ? ("c" rgbhex) : ""
	opt_weight := weight ? ("w" weight) : ""
	
	optall := opt_sizept " " opt_rgbhex " " opt_weight

	Gui, % cmd, % optall, % fontface
}

GuiControl_ChangeOpt(GuiName, CtrlVarname, opt)
{
	; Example:
	;	GuiControl_ChangeOpt("EVP", gu_xxx, "+AltSubmit")
	
	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmd := (GuiName ? GuiName ":" : "") . opt
	GuiControl, % cmd, % CtrlVarname, % opt
}

Gui_Add_TxtLabel(GuiName, CtrlVarname:="", width:=-1, format="", text:="")
{
	; format: 
	; +0x8000 (SS_PATHELLIPSIS)
	; +0xC000 (SS_WORDELLIPSIS)
	
	if(!CtrlVarname)
		CtrlVarname := "gu_TxtLabelDefault"

	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	
	w_width := width>=0 ? "w" width : "" ; so width==-1 will make it auto-width by text length
	
	Gui, % cmdadd, Text, % Format("v{} {} {}", CtrlVarname, w_width, format), % text
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
	
	dev_assert(Gui_IsValidVar(CtrlVarname))
	optfg := fgcolor ? ("+c" fgcolor) : ""
	optbg := bgcolor ? ("+Background" bgcolor) : ""
	
	if(optfg || optbg)
	{
		GuiControl_ChangeOpt(GuiName, CtrlVarname, optfg " " optbg)
	}
}

Gui_Add_Button(GuiName, CtrlVarname, width, format, btntext)
{
	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	Gui, % cmdadd, Button, % Format("v{} w{} {}", CtrlVarname, width, format), % btntext
}

Gui_Add_Picture(GuiName, CtrlVarname, width, format, imgfilepath:="")
{
	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	Gui, % cmdadd, Picture, % Format("v{} w{} {}", CtrlVarname, width, format), % imgfilepath
}

Gui_Picture_SetIconFromDll(GuiName, CtrlVarname, dllpath, icon_group_idx)
{
	iconpath := Format("*icon{} {}", icon_group_idx, dllpath)
	GuiControl_SetText(GuiName, CtrlVarname, iconpath)
}

Gui_Add_Checkbox(GuiName, CtrlVarname, width, format, btntext)
{
	; format: "Checked"

	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmdadd := GuiName ? (GuiName ":Add") : "Add"

	w_width := width>=0 ? "w" width : ""
	
	Gui, % cmdadd, Checkbox, % Format("v{} {} {}", CtrlVarname, w_width, format), % btntext
}

Gui_Add_Editbox(GuiName, CtrlVarname, width, format, init_text:="")
{
	; format: 
	; r10
	; Readonly
	; -E0x200 (turn off WS_EX_CLIENTEDGE, remove editbox border thin line)

	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	Gui, % cmdadd, Edit, % Format("v{} w{} {}", CtrlVarname, width, format), % init_text
}

Gui_Add_Listbox(GuiName, CtrlVarname, width, format, itemlist_pipes:="")
{
	; format: AltSumbit r12

	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	Gui, % cmdadd, ListBox, % Format("v{} w{} {}", CtrlVarname, width, format), % itemlist_pipes
}

Gui_Add_Combobox(GuiName, CtrlVarname, width, format, itemlist_pipes:="")
{
	; format: AltSumbit

	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmdadd := GuiName ? (GuiName ":Add") : "Add"
	Gui, % cmdadd, ComboBox, % Format("v{} w{} {}", CtrlVarname, width, format), % itemlist_pipes
}

GuiControl_Enable(GuiName, CtrlVarname, is_enable)
{
	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmd := is_enable ? "Enable" : "Disable"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	GuiControl, % cmd, % CtrlVarname
}

GuiControl_Show(GuiName, CtrlVarname, is_show)
{
	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmd := is_show ? "Show" : "Hide"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	GuiControl, % cmd, % CtrlVarname
}

GuiControl_GetHwnd(GuiName, CtrlVarname)
{
	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmd := "Hwnd"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	GuiControlGet, outputHwnd, % cmd, % CtrlVarname
	return outputHwnd
}

GuiControl_GetText(GuiName, CtrlVarname)
{
	dev_assert(Gui_IsValidVar(CtrlVarname))
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

	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmd := GuiName ? GuiName ":" : ""
	GuiControl, % cmd, % CtrlVarname, % text
}

GuiControl_SetValue(GuiName, CtrlVarname, text)
{
	GuiControl_SetText(GuiName, CtrlVarname, text)
}

GuiControl_GetPos(GuiName, CtrlVarname)
{
	dev_assert(Gui_IsValidVar(CtrlVarname))
	cmd := "Pos"
	if(GuiName)
		cmd := Format("{}:{}", GuiName, cmd)

	GuiControlGet, outvar, % cmd, % CtrlVarname
	
	return {"x":outvarX, "y":outvarY, "w":outvarW, "h":outvarH}
}

GuiControl_SetPos(GuiName, CtrlVarname, x:=-1, y:=-1, w:=-1, h:=-1, force_redraw:=true)
{
	; -1 : Don't change current value
	
	dev_assert(Gui_IsValidVar(CtrlVarname))
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


GuiControl_ComboboxGetText(GuiName, CtrlVarname)
{
	;pending, need to query whether it has 'AltSubmit' option .
}



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
	
	if( ! g_devGuiAutoResizeDict[GuiName] )
	{
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
;			MsgBox, % Format("dev_GuiAutoResize({}.{}) Init:  rectX={}, rectY={}, rectW={}, rectH={}", GuiName, ctrlvar, rectX, rectY, rectW, rectH)
			
			ctrl_rsinfo.ofs_left := (rectX-x0m) - nowwidth * ctrl_rsinfo.pct_left
			ctrl_rsinfo.ofs_top  := (rectY-y0m) - nowheight * ctrl_rsinfo.pct_top
			ctrl_rsinfo.ofs_right := (rectX-x0m + rectW) - nowwidth * ctrl_rsinfo.pct_right
			ctrl_rsinfo.ofs_bottom := (rectY-y0m + rectH) - nowheight * ctrl_rsinfo.pct_bottom

;			MsgBox, % Format("dev_GuiAutoResize({}.{}) Init:  ofs:{},{},{},{}", GuiName, ctrlvar, ctrl_rsinfo.ofs_left, ctrl_rsinfo.ofs_top, ctrl_rsinfo.ofs_right, ctrl_rsinfo.ofs_bottom)
		}

		; Mark this GuiName "created".
		g_devGuiAutoResizeDict[GuiName] := gui_rsinfo ; to modify

	}
	else
	{
;		MsgBox, SecondTimeARS
		
		gui_rsinfo := g_devGuiAutoResizeDict[GuiName] ; define a label for easier reference
		
		for ctrlvar, ctrl_rsinfo in gui_rsinfo
		{
			; Calculate new positions for this ctrl
			newX := nowwidth * ctrl_rsinfo.pct_left + ctrl_rsinfo.ofs_left +x0m
			newY := nowheight * ctrl_rsinfo.pct_top + ctrl_rsinfo.ofs_top +y0m
			newW := nowwidth * ctrl_rsinfo.pct_right + ctrl_rsinfo.ofs_right - newX +x0m
			newH := nowheight * ctrl_rsinfo.pct_bottom + ctrl_rsinfo.ofs_bottom - newY +y0m

;			MsgBox, % Format("dev_GuiAutoResize Newpos({}:{}) is {},{} | {},{}", GuiName, ctrlvar, newX, newY, newW, newH)

			; Move this ctrl
			newpos := Format("x{} y{} w{} h{}", newX, newY, newW, newH)
			
			RedrawOp := force_redraw ? "MoveDraw" : "Move"
			
			GuiControl, %GuiName%:%RedrawOp%, %ctrlvar%, % newpos
		}
	}
}

dev_GuiAutoResizeRemove(GuiName)
{
	g_devGuiAutoResizeDict.Delete(GuiName)
}


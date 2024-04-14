; This module provides a UI that facilitates expanding(copy files and replace words) 
; a user selected template folder into an actual new folder.
; * User assigns template searching folders in g_dirsAmTemplates[].
; * A file named "AmTemplate.cfg.ini" marks the existence of a template folder.
; * Once user selects a template folder, a dialogbox pops out asking for substitution parameters.

; All GUIDs in AmTemplate.cfg.ini must conform to AmtGuidFormat, this requirement 
; enables me to check for GUID-mismatch situation between AmTemplate.cfg.ini and Template file sources.

AUTOEXEC_AmTemplates: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

/* APIs:
Amt_LaunchMenu()
Amt_ShowPreviousGui()
*/

global g_dirsAmTemplates := [ A_ScriptDir "\AmTemplates" ]
	; Templates will be searched inside these dirs. User can override or append to this array.
	; g_dirsAmTemplates.Push("D:\test\AmTemplates")

; global constant use by this module
global g_amtIniCfgFilename := "AmTemplate.cfg.ini"
global g_amtIniResultFileName := "AmTemplate.result.ini" ; looks useless
global g_amtRootMenu := "AmtMenu"

global g_amtGuidFormatRegex := "\{CCCCCCCC-0000-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}"
global g_amtGuidFormatFriendly := "{CCCCCCCC-0000-....-....-............}"
; -- that is, AmtGuidFormat {CCCCCC-0000-0000-...}

global AMT_FOUND_IMMEDIATE_TEMPLATE := -1

; global variable used by this module
												;global g_countAmTemplates := 0
global g_HwndAmt ; HWND for AMT dialog.
global g_amtTemplateSrcDir ; the Dir with file AmTemplate.cfg.ini

global g_amtWordEdtWidth := 220

global g_OldwordHeader, g_NewwordHeader
;
; Max 9 words supported.
global g_amteditOldword1, g_amteditNewword1
global g_amteditOldword2, g_amteditNewword2
global g_amteditOldword3, g_amteditNewword3
global g_amteditOldword4, g_amteditNewword4
global g_amteditOldword5, g_amteditNewword5
global g_amteditOldword6, g_amteditNewword6
global g_amteditOldword7, g_amteditNewword7
global g_amteditOldword8, g_amteditNewword8
global g_amteditOldword9, g_amteditNewword9
;
global g_amt_arTemplateWords := [] ; an array of object(.oldword .desc .newword)

global g_OldguidHeader, g_NewguidHeader

global g_amteditOldguid1, g_amteditNewguid1
global g_amteditOldguid2, g_amteditNewguid2
global g_amteditOldguid3, g_amteditNewguid3
global g_amteditOldguid4, g_amteditNewguid4
global g_amteditOldguid5, g_amteditNewguid5
global g_amteditOldguid6, g_amteditNewguid6
global g_amteditOldguid7, g_amteditNewguid7
global g_amteditOldguid8, g_amteditNewguid8
global g_amteditOldguid9, g_amteditNewguid9

global g_amt_arTemplateGuids := [] ; an array of object(.oldword .desc .newword)

global CREATE_SUBDIR_WITH_NEW_WORD := "Create a subdir with first new word"

global g_amtIsAutoGuid := true

global g_amtRadioCRLF
global g_amtRadioLF

global g_amtEdtOutdirUser

global g_amtIsCreateDirForFirstWord := true
global g_amtTxtApplyDirFinal
global g_amtIconWarnOverwrite

global g_amtPrevInipath := ""
global g_amtPrevIniTime := ""
global g_amtApplyFolderHint := ""

global g_amtDefaultOutdirUser := A_AppData "\" "AmTemplatesApply" 
	; Example: C:\Users\win7evn\AppData\Roaming\AmTemplatesApply
	; This can be overridden in customize.ahk

global g_amtApplyBtn := ""

global g_amtDefaultOutdirUser0 := g_amtDefaultOutdirUser

; AmTemplates_InitHotkeys()

;Dbgwin_Output("AmTemplate............AUTOEXEC")
;Dbgwin_Output("gu_dbgwinTEST4 ? " . Gui_IsValidVar("gu_dbgwinTEST4") ". =" gu_dbgwinTEST4)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Amt_GetIniFilepath(dirtmpl)
{
	return dirtmpl "\" g_amtIniCfgFilename
}

Amt_IsAmtGuidFormat(guid)
{
	if(guid ~= "i)" g_amtGuidFormatRegex) ; case-insensitive match
		return true
	else 
		return false
}

Amt_PrepareDir(basemenu, basedirpath)
{
	; basemenu: The basemenu name that is potentailly to be created.
	; Hint: Think of the "menu-name"(not menuitem-name) as the "frame-name".
	;       The caller refers to this "frame-name" as one of its(caller's) submenu. 
	;
	; basemenu example:
	;	AmtMenu.1
	;	AmtMenu.2
	;	AmtMenu.1.2
	;
	; Three cases:
	;
	; (1) If there is an immediate g_amtIniCfgFilename found, we'll NOT create 
	; this basemenu and return AMT_FOUND_IMMEDIATE_TEMPLATE(-1).
	;
	; (2) If there is any g_amtIniCfgFilename found in deeper subdirs, we'll 
	; actually create this basemenu and return a positive number indicating 
	; templates inside.
	;
	; (3) If there is no g_amtIniCfgFilename found, basemenu is NOT created 
	; and we will return 0.
	;
	; Yes, the caller suggests the basemenu name(string) for us to create.

	dev_Menu_DeleteAll(basemenu) ; clear old menu with the "same" name

	if FileExist(Amt_GetIniFilepath(basedirpath))
	{
		return AMT_FOUND_IMMEDIATE_TEMPLATE
	}
	
	; Now recurse into subdirs to find other potential g_amtIniCfgFilename files.
	
	total_found := 0
	
	Loop, Files, % basedirpath "\*", D
	{
		; *Create* a new submenu for this found subdir, with menu's internal-name like:
		; AmtMenu.1.1
		; AmtMenu.2.1
		; AmtMenu.2.1.3
		
		submenu := basemenu "." A_Index
		
		amtfound := Amt_PrepareDir(submenu, A_LoopFileFullPath) ; Recursive call

		if(amtfound==AMT_FOUND_IMMEDIATE_TEMPLATE)
		{
			; append menuitem to basemenu
			fn := Func("Amt_ExpandTemplateUI").Bind(A_LoopFileFullPath)
			Menu, % basemenu, Add, % A_LoopFileName, %fn%
			total_found += 1
		}
		else if(amtfound>0)
		{
			; append submenu to basemenu
			menutext := Format("{1} ({2})", A_LoopFileName, amtfound)
			Menu, % basemenu, Add, % menutext, :%submenu%
			total_found += amtfound
		}
		else 
		{
			; AMT_FOUND_NONE, do nothing
		}
	}

	return total_found
}

AppsKey & m:: Amt_LaunchMenu()

Amt_LaunchMenu(scanrootdir:="")
{
;	g_countAmTemplates := 0 
	
	dev_Menu_DeleteAll(g_amtRootMenu)
	
	dev_MenuAddItem(g_amtRootMenu, "==== AmTemplates ====", "dev_nop")
	
	if(StrLen(scanrootdir)>0)
	{
		Amt_attach_scandir_to_LaunchMenu("AmtCustomScandir", scanrootdir)
	}
	else
	{
		if(g_amtPrevInipath)
		{
			dev_MenuAddItem(g_amtRootMenu, "Show previous dialog", "Amt_ShowPreviousGui")
		}

		; Load AmTemplates from g_dirsAmTemplates[]

		Loop, % g_dirsAmTemplates.Length()
		{
			submenu_name := g_amtRootMenu "." A_Index

			scandir := g_dirsAmTemplates[A_Index]

			Amt_attach_scandir_to_LaunchMenu(submenu_name, scandir)
		}
	}
	
	dev_MenuAddItem(g_amtRootMenu, "Custom scandir ...", "Amt_InputCustomScandir")

	dev_MenuShow(g_amtRootMenu)
}

Amt_attach_scandir_to_LaunchMenu(submenu_name, scandir)
{
	dev_TooltipAutoClear("AmTemplate scanning " scandir " ...", -1)

	amtfound := Amt_PrepareDir(submenu_name, scandir)
	
	dev_TooltipClear()
	
	if(amtfound==AMT_FOUND_IMMEDIATE_TEMPLATE)
	{
		; append menuitem to basemenu
		fn := Func("Amt_ExpandTemplateUI").Bind(scandir)
		dev_MenuAddItem(g_amtRootMenu, scandir, fn)
	}
	else
	{
		menutext := Format("{1} ({2})", scandir, amtfound)
		
		if(amtfound==0)
		{
			dev_MenuAddItem(g_amtRootMenu, menutext, "dev_nop")
		}
		else
		{
			dev_MenuAddItem(g_amtRootMenu, menutext, ":" submenu_name)
		}
	}
}

Amt_InputCustomScandir()
{
	static s_scandir := ""
	isok := dev_InputBox_InitText("AmTemplate"
		, "Input a directory to scan for " g_amtIniCfgFilename
		, s_scandir)
	
	if(not isok || not s_scandir)
		return
	
	Amt_LaunchMenu(s_scandir)
}


Amt_ExpandTemplateUI(dirtmpl)
{
	Amt_ShowGui(Amt_GetIniFilepath(dirtmpl))
}

Amt_CreateGui(inipath)
{
	GuiName := "AMT"
	g_amt_arTemplateWords := []
	g_amt_arTemplateGuids := []
	;
	dev_GuiAutoResizeRemove(GuiName)

	inidir := dev_SplitPath(inipath, inifilename)

	Gui, AMT:New ; Destroy old window if any
	Gui, AMT:+Hwndg_HwndAmt
	Gui, AMT:+Resize +MinSize

	Gui_Switch_Font( GuiName, 9, "", "Tahoma")
	Gui_Add_TxtLabel(GuiName, "", 580, "xm", Format("Template folder found: (with {})", inifilename))
	Gui_Add_Editbox( GuiName, "g_amtTemplateSrcDir", 580, "xm ReadOnly -E0x200", inidir)
	Gui_Add_TxtLabel(GuiName, "g_OldwordHeader", g_amtWordEdtWidth, "xm y+16", "Old words from template:")
	Gui_Add_TxtLabel(GuiName, "g_NewwordHeader", -1, "x+10 yp", "New words to apply:")

	;
	; Get all items from [WordToReplace]
	;
	
	arlinetext := dev_IniReadSection(inipath, "WordToReplace")
	
	for index,itemline in arlinetext
	{
		if(index>9)
		{
			MsgBox, % "Sorry, only first 9 template words are supported."
			break
		}
	
		key_value := StrSplit(itemline, "=")
		key := key_value[1]
		value := key_value[2]
		
		varname_oldword := "g_amteditOldword" index
		varname_newword := "g_amteditNewword" index
		
		Gui_Add_Editbox(GuiName, varname_oldword, g_amtWordEdtWidth, "xm ReadOnly -Tabstop", key)
		Gui_Add_Editbox(GuiName, varname_newword, g_amtWordEdtWidth, "yp x+10 g" . "Amt_OnNewWordChange", key)
		
		g_amt_arTemplateWords[index] := {"oldword":key, "newword":key, "desc":value}
	}
	
	;
	; Get all items from [GUID]
	;
	
	arlinetext := dev_IniReadSection(inipath, "GUID")

	if(arlinetext.Length()>0)
	{
		Gui_Add_TxtLabel(GuiName, "g_OldguidHeader", 280, "xm y+16", "Old GUIDs from template:")
		Gui_Add_TxtLabel(GuiName, "g_NewguidHeader", -1, "x+10 yp", "New GUIDs to apply:")
		Gui_Add_Checkbox(GuiName, "g_amtIsAutoGuid", -1, "x+45 yp Checked g" . "Amt_ckbToggledAutoGenGuid", "Auto &generate")
	}
	
	for index,itemline in arlinetext
	{
		if(index>9)
		{
			MsgBox, % "Sorry, only first 9 template GUIDs are supported."
			break
		}
		
		key_value := StrSplit(itemline, "=")
		key := key_value[1]
		value := key_value[2]
		
		varname_oldword := "g_amteditOldguid" + index
		varname_newword := "g_amteditNewguid" + index
		
		guidnew := Amt_GenerateGuidByTime(index)
		
		Gui_Add_Editbox(GuiName, varname_oldword, 280, "xm ReadOnly -Tabstop", key)
		Gui_Add_Editbox(GuiName, varname_newword, 280, "yp x+10 g" . "Amt_OnNewGuidChange", guidnew) 
		
		g_amt_arTemplateGuids[index] := {"oldword":key, "newword":guidnew, "desc":value}
	}
	
	; CRLF/LF radio boxes
	
	Gui_Add_TxtLabel(GuiName, "", -1, "xm y+10", "&New-line style:")
	Gui_Add_Radiobox(GuiName, "g_amtRadioCRLF", -1, "Group Checked yp x+10", "CRLF")
	Gui_Add_Radiobox(GuiName, "g_amtRadioLF", -1, "yp x+5", "LF")
	;
	newline_style := dev_IniRead(inipath, "global", "TextFileNewLineStyle", "CRLF")
	if(dev_StrIsEqualI(newline_style, "LF"))
		GuiControl_ButtonCheck(GuiName, "g_amtRadioLF", true)
	
	Gui_Add_TxtLabel(GuiName, "", -1, "y+16 xm", "Apply &to:")
	Gui_Add_Editbox( GuiName, "g_amtEdtOutdirUser", 565, "xm+15 g" . "Amt_ResyncUI") ; text fill later in Amt_ShowGui()
	
	initcheck := g_amtIsCreateDirForFirstWord ? "Checked" : ""
	
	Gui_Add_Checkbox(GuiName, "g_amtIsCreateDirForFirstWord", 500, initcheck " xm g" . "Amt_ResyncUI", CREATE_SUBDIR_WITH_NEW_WORD)

	Gui_Add_TxtLabel(GuiName, "", -1, "xm", "Final apply folder:")
	
	; Now, a readonly text line that shows final apply folder, with a prefix icon showing final-folder state.
	Gui_Add_Picture(GuiName, "g_amtIconWarnOverwrite", 16, "xm h16 +0x100") ; 0x100: SS_NOTIFY, for hovering tooltip
	Gui_Add_Editbox(GuiName, "g_amtTxtApplyDirFinal", 562, "yp x+3 ReadOnly -E0x200") ; -E0x200: turn off WS_EX_CLIENTEDGE, no so editbox border
	Gui_Add_Button( GuiName, "", -1, "y+10 xm Default g" . "AMT_BtnOK", " &Apply ")
}


Amt_ShowPreviousGui()
{
	if(not g_amtPrevInipath)
	{
		dev_MsgBoxWarning("No existing AmTemplates selected yet.")
		return
	}

	Amt_ShowGui(g_amtPrevInipath)
}

Amt_ShowGui(inipath)
{
	FileGetTime, NowIniTime, % inipath

	if(!g_HwndAmt || inipath!=g_amtPrevInipath || NowIniTime!=g_amtPrevIniTime) {
		
		; Comes a different ini, so destroy old and create new
		Amt_CreateGui(inipath) 
		
		g_amtPrevInipath := inipath
		g_amtPrevIniTime := NowIniTime
	}
	
	OnMessage(0x200, Func("Amt_WM_MOUSEMOVE")) ; add message hook
	
	Gui, AMT:Show, , % "Expand your AmTemplate"

	if(g_amtEdtOutdirUser=="")
	{
		; Fill a preset apply path for user
		g_amtEdtOutdirUser := g_amtDefaultOutdirUser
	}
	GuiControl, AMT:, g_amtEdtOutdirUser, % g_amtEdtOutdirUser
	
;	applydir := dev_FindVacantFilename(inidir "-Apply{}")
	
	Amt_RegenGuidsByCheckbox()
	; -- to avoid using stale auto-GUIDs from maybe several hours/days agao.

	Amt_ResyncUI()
	
	dev_StartTimerPeriodic("Amt_RegenGuidsByCheckbox", 1000)
}

Amt_HideGui()
{
	Gui, AMT:Hide

	OnMessage(0x200, Func("Amt_WM_MOUSEMOVE"), 0) ; remove message hook
	tooltip
	
	dev_StopTimer("Amt_RegenGuidsByCheckbox")
}

AMTGuiSize()
{
	Gui, AMT:+MaxSizex%A_GuiHeight% ; Effect: only allow changing window width, not height

	rsdict := {}
	rsdict.g_amtTemplateSrcDir := "0,0,100,0"
	
	rsdict.g_OldwordHeader := "0,0,44,0"
	rsdict.g_NewwordHeader := "44,0,88,0"
	;
	nwords := g_amt_arTemplateWords.Length()
	Loop, %nwords%
	{
		rsdict["g_amteditOldword" A_index] := rsdict.g_OldwordHeader
		rsdict["g_amteditNewword" A_Index] := rsdict.g_NewwordHeader
	}

;	// No need to change GUID editbox width.
;	rsdict.g_OldguidHeader := "0,0,50,0"
;	rsdict.g_NewguidHeader := "50,0,100,0"
;	;
;	nguids := g_amt_arTemplateGuids.Length()
;	Loop, %nguids%
;	{
;		rsdict["g_amteditOldguid" A_Index] := rsdict.g_OldguidHeader
;		rsdict["g_amteditNewguid" A_Index] := rsdict.g_NewguidHeader
;	}
	
	rsdict.g_amtEdtOutdirUser := "0,100,100,100"
	rsdict.g_amtTxtApplyDirFinal := "0,100,100,100"
	rsdict.g_amtApplyBtn := "0,100,0,100"
	
	dev_GuiAutoResize("AMT", rsdict, A_GuiWidth, A_GuiHeight)
}

AMTGuiClose()
{
	Amt_HideGui()
}

AMTGuiEscape()
{
	Amt_HideGui()
}

AMT_BtnOK()
{
	Gui, AMT:Submit, NoHide
	Gui, AMT:+OwnDialogs ; So that child dialogboxes are Modal.
	
	finalApplyDir := g_amtTxtApplyDirFinal
	
	if(FileExist(finalApplyDir))
	{
		dev_MsgBoxWarning("Applying target folder already exists. Please choose a different one.")
		return
	}

	; Check that editbox contents has changed.
	stales := ""
	for index,obj in g_amt_arTemplateWords
	{
		if(obj.oldword==obj.newword)
			stales .= obj.oldword "`n"
	}
	;
	if(stales)
	{
		isgo := dev_MsgBoxYesNo_Warning(Format("The following word(s) remain the same:`n`n{}`n`nAre you sure?", stales), false)
		if(!isgo)
			return
	}

	isok := Amt_DoExpandTemplate(g_amtTemplateSrcDir, finalApplyDir)
	; -- implicit input: g_amt_arTemplateGuids[], g_amt_arTemplateWords

	if(isok)
	{
		msg := "Expand template success.`n`n" finalApplyDir 
		
		if(g_amtDefaultOutdirUser==g_amtDefaultOutdirUser0)
		{	
			; If user is using the raw default, give him a hint about using user default.
			msg .= "`n`nHint: Default output folder can be set in global var g_amtDefaultOutdirUser."
		}
		
		dev_MsgBoxInfo(msg)
	}
	else
	{
		if(dev_IsDiskFolder(finalApplyDir))
		{
			is_yes := dev_MsgBoxYesNo_Warning(Format("Template expansion failed. Do you want to remove target folder?`n`n"
				. "{}", finalApplyDir))
			if(is_yes) {
				dev_rmdir(finalApplyDir)
			}
		}
	}
	
	Amt_RegenGuidsByCheckbox()
	
	Amt_ResyncUI() ; Purpose: show "folder exists" warning icon at bottom-right
	
;	Amt_HideGui()
}

Amt_GenerateGuidByTime(suffix_num)
{
	; Generate a set of GUIDs by current timestamp, like 
	; {20220119-0000-0000-0000-134742000001}
	; {20220119-0000-0000-0000-134742000002}
	
	if(suffix_num>=0 && suffix_num<=9)
		guidfmt := Format("{yyyyMMdd-0000-0000-0000-HHmmss00000{1}}", suffix_num)
	else if(suffix_num>=10 && suffix_num<=99)
		guidfmt := Format("{yyyyMMdd-0000-0000-0000-HHmmss0000{1}}", suffix_num)
	else {
		guidfmt := "{yyyyMMdd-0000-0000-0000-HHmmss000000}"
		dev_MsgBoxError("Amt_GenerateGuidByTime input parameter error, suffix_num should be 0~99.")
	}
	
	guidnew := dev_GetCurrentDatetime(guidfmt)
	return guidnew
}

Amt_GenerateAllGuidsByTime()
{
	for index,obj in g_amt_arTemplateGuids
	{
		obj.newword := Amt_GenerateGuidByTime(index)
	
		GuiControl, AMT:, % Format("g_amteditNewguid{1}", index), % obj.newword
	}
}


Amt_OnNewWordChange()
{
	idCtrl := A_GuiControl
	
	if(!StrIsStartsWith(idCtrl, "g_amteditNewword"))
	{
		MsgBox, % "Assert Error: Amt_OnNewWordChange()."
	}

	index := dev_str2num(dev_StripPrefix(idCtrl, "g_amteditNewword"))
	
	GuiControlGet, %idCtrl%, AMT:
	newtext := %idCtrl%
	g_amt_arTemplateWords[index].newword := newtext
	
;	dev_TooltipAutoClear("text changed to: " newtext)

	if(idCtrl=="g_amteditNewword1")
	{
		Amt_ResyncUI()
	}
}

Amt_OnNewGuidChange()
{
	idCtrl := A_GuiControl
	
	if(!StrIsStartsWith(idCtrl, "g_amteditNewguid"))
	{
		MsgBox, % "Assert Error: Amt_OnNewGuidChange()."
	}
	
	GuiControlGet, %idCtrl%, AMT:
	newtext := %idCtrl%

	index := dev_str2num(dev_StripPrefix(idCtrl, "g_amteditNewguid"))
	g_amt_arTemplateGUIDs[index].newword := newtext

;	dev_TooltipAutoClear(Format("g_amt_arTemplateGUIDs[{1}].newword changed to: {2}", index, newtext)) ; debug
}

Amt_WM_MOUSEMOVE()
{
    static s_prev_tooltiping_uic := 0

	is_from_tooltiping_uic := true ; assume message is from a GuiControl
	idCtrl := A_GuiControl
	
	if(StrIsStartsWith(idCtrl, "g_amteditOldword"))
	{
		; Show desc text of this template word.
	
		index := dev_str2num(dev_StripPrefix(idCtrl, "g_amteditOldword"))
		
		dev_TooltipAutoClear( amt_AdjustTooltipText(g_amt_arTemplateWords[index].desc) )
		
;		MsgBox, % Format("Amt_WM_MOUSEMOVE on Oldword #{1} : {2} , {3} , {4}", index, g_amt_arTemplateWords[index].oldword, g_amt_arTemplateWords[index].newword, g_amt_arTemplateWords[index].desc)
	}
	else if(StrIsStartsWith(idCtrl, "g_amteditOldguid"))
	{
		; show tooltip on old-GUID, that is text description of this GUID's meaning.
	
		index := dev_str2num(dev_StripPrefix(idCtrl, "g_amteditOldguid"))
		
		dev_TooltipAutoClear( amt_AdjustTooltipText(g_amt_arTemplateGuids[index].desc) )
	}
	else if(idCtrl=="g_amtIconWarnOverwrite")
	{
		dev_TooltipAutoClear(g_amtApplyFolderHint)
	}
	else
		is_from_tooltiping_uic := false
	
	if(A_Gui=="AMT")
	{
		; According to my [20221215.R1]
        ; If mouse has *just* moved off a tooltiping UIC, we turn off the tooltip.
        ; We cannot blindly turn off tooltip here, bcz we would get constant WM_MOUSEMOVE 
        ; even if we do not move the mouse; turning off tooltip blindly would cause 
        ; other function''s dev_TooltipAutoClear() to vanish immediately.
        ;
        if(is_from_tooltiping_uic) {
            s_prev_tooltiping_uic := A_GuiControl
        }
        else if(s_prev_tooltiping_uic) {
            tooltip ; turn off tooltip
            s_prev_tooltiping_uic := 0
        }
	}
}

Amt_ckbToggledAutoGenGuid()
{
	Amt_RegenGuidsByCheckbox()
	
	Amt_ResyncUI()
}

Amt_RegenGuidsByCheckbox()
{
	GuiControlGet, ischecked, AMT:, g_amtIsAutoGuid
	
	if(ischecked)
	{
		Amt_GenerateAllGuidsByTime()
	}
}

Amt_ResyncUI()
{
	; ==== Auto-generate GUID checkbox ====

	GuiControlGet, ischecked, AMT:, g_amtIsAutoGuid

	cmdEnable := ischecked ? "Disable" : "Enable"
	
	for index,obj in g_amt_arTemplateGuids
	{
		varname := "g_amteditNewguid" . index
	
		GuiControl, AMT:%cmdEnable%, %varname%
	}
	
	; ==== Create subdir checkbox ====
	
	Gui, AMT:Submit, NoHide
	
	if(g_amtIsCreateDirForFirstWord)
	{
		ckbText := Format("Create a subdir named ""{1}"" .", g_amteditNewword1)
		GuiControl, AMT:, g_amtIsCreateDirForFirstWord, % ckbText
		
		finalApplyDir := g_amtEdtOutdirUser "\" g_amteditNewword1
	}
	else
	{
		GuiControl, AMT:, g_amtIsCreateDirForFirstWord, % CREATE_SUBDIR_WITH_NEW_WORD
		
		finalApplyDir := g_amtEdtOutdirUser
	}

	;  Update text in g_amtTxtApplyDirFinal
	GuiControl, AMT:, g_amtTxtApplyDirFinal, % finalApplyDir

	if(FileExist(finalApplyDir)) {
		icongroup := 2 ; yellow exclamation triangle
		g_amtApplyFolderHint := "This folder already exists. You need to choose another."
	}
	else {
		icongroup := 5 ; blue info circle
		g_amtApplyFolderHint := "This folder will be created."
	}
	iconparams := Format("*icon{1} USER32.DLL", icongroup)
	GuiControl, AMT:, g_amtIconWarnOverwrite, % iconparams
}

Amt_DoExpandTemplate(srcdir, dstdir)
{
	GuiName := "AMT"
	logfile := "AmTemplates.log"
;	dev_WriteLogFile(logfile, "", false) ; create logfile

	arPairs := []
	
	cfgini := Amt_GetIniFilepath(srcdir)
	
	; Walk source dir and find files matching IncludePatterns.

	IncludePatterns := dev_IniRead(cfgini, "global", "IncludePatterns","*")
	ptns := StrSplit(IncludePatterns, "|")
	
	isStrictGuid := dev_IniReadVal(cfgini, "global", "IsStrictGuid", 0)
	
	Gui_Submit(GuiName, true)

	; ========== Gather src -> dst file pairs in a dict.

	Loop, Files, % srcdir "\*", FR
	{
		srcRela := dev_StripPrefix(A_LoopFileFullPath, srcdir) ; srcRela will have \ prefix
		
		dev_SplitPath(srcRela, filename)
		
		if(!amt_IsWildcardsMatch(ptns, filename))
		{
			continue
		}

		dstRela := srcRela
		for idx,wordmap in g_amt_arTemplateWords
		{
			dstRela := StrReplace(dstRela, wordmap.oldword, wordmap.newword)
		}

;		dev_WriteLogFile(logfile, Format("[{1}] -> [{2}]`n", srcRela, dstRela)) ; debug
		arPairs.Push({"srcrela":srcRela , "dstrela":dstRela}) 
	}

	dictGuidReplaceCount := {}
	dictNewGuid := {} ; for dup-check
	
	; ========== For each GUID, check format correctness
	
	for index,obj in g_amt_arTemplateGuids
	{
		oldguid := obj.oldword
		newguid := obj.newword
	
		; Check that template(old) GUIDs do not duplicate.
		if(dictGuidReplaceCount.HasKey(oldguid)) {
			dev_MsgBoxError(Format("[ERROR] {} has duplicate GUID in it: {}", g_amtIniCfgFilename, oldguid))
			return false
		}
		
		; This count is used to check GUID stray-away Template bug.
		dictGuidReplaceCount[oldguid] := 0
		
		; Check that old GUIDs conform to AmtGuidFormat.
		if(isStrictGuid and not Amt_IsAmtGuidFormat(oldguid))
		{
			info := Format("[ERROR] The GUID ""{}"" does NOT meet AMT-GUID-format.`n`n"
				. "With IsStrictGuid=1, the GUID should have this format:"
				. "`n`n{}"
				, oldguid, g_amtGuidFormatFriendly)
			dev_MsgBoxError(info)
			return false
		}

		; Check that target(new) GUIDs do not duplicate.
		if(dictNewGuid.HasKey(newguid)) {
			dev_MsgBoxError(Format("[ERROR] Your input new GUIDs has duplication: {}", newguid))
			return false
		}
		
		dictNewGuid[newguid] := 1
		
		if(not dev_IsValidGuid(newguid)) {
			dev_MsgBoxError(Format("[ERROR] Your input GUID is in wrong format:`n`n{}", newguid))
			return false
		}

		if(isStrictGuid)
		{
			; Check that target(new) GUIDs is NOT in AMT-GUID-format.
			if(Amt_IsAmtGuidFormat(newguid))
			{
				dev_MsgBoxError(Format("[ERROR] One of your manually typed new GUIDs has AMT-GUID-format:`n`n"
					. "{}`n`n"
					. "This is not allowed when {} says IsStrictGuid=1 ."
					, newguid, g_amtIniCfgFilename))
				return false
			}
		}
	}
	
	; ========== Actually copy/expand each file.
	
	for index,pair in arPairs
	{
		srcpath := srcdir . pair.srcrela
		dstpath := dstdir . pair.dstrela

		dstdir_tip := dev_SplitPath(dstpath)

		if(FileExist(dstpath))
		{
			dev_MsgBoxError(Format("Unexpected: Target file should not have exsited: {}", dstpath))
			return false
		}
		
		FileCreateDir, %dstdir_tip%
		if ErrorLevel {
			dev_MsgBoxError("ERROR: Cannot create folder: " dstdir_tip)
			return false
		}
		
		if(dev_IsBinaryFile(srcpath))
		{
			; For binary file, do raw file copy.
			FileCopy, %srcpath%, %dstpath%
			if(ErrorLevel)
			{
				dev_MsgBoxError(Format("ERROR: Fail to create new binary file: {}", dstpath))
				return false
			}
		}
		else
		{
			; For text file, we need to replace text.
			
			filetext := dev_ReadFile(srcpath)
			if(ErrorLevel)
			{
				dev_MsgBoxError(Format("ERROR: Fail to read source file: {}", srcpath))
				return false
			}
			
			for index,obj in g_amt_arTemplateWords
			{
				filetext := StrReplace(filetext, obj.oldword, obj.newword)
			}
			
			for index,obj in g_amt_arTemplateGuids
			{
				filetext := StrReplace(filetext, obj.oldword, obj.newword, outCount)
				dictGuidReplaceCount[obj.oldword] += outCount
			}

			if(IsStrictGuid)
			{
				; Ensure that all AmtGuidFormat GUIDs are all gone, otherwise, assert error.
				;
				badpos := RegExMatch(filetext, "i)" g_amtGuidFormatRegex, matchedstr)
				if(badpos>0)
				{
					badguid := matchedstr
					dev_MsgBoxError(Format("[ERROR] Template source file`n`n"
						. "{}`n`n"
						. "has un-replaced AMT-GUID-format GUID: `n`n"
						. "{}`n`n"
						. "The author of {} probably forgot to refer to this GUID to have it replaced, which is an error."
						, srcpath, badguid, g_amtIniCfgFilename))
					return false
				}
			}
			
			if(g_amtRadioLF)
			{
				; Force LF textfile output(for Unix/Linux)
				
				text_lf := dev_StrReplace_CRLF_to_LF(filetext)
				
				nwr := dev_WriteWholeFile_rawstring(dstpath, text_lf)
				if(nwr==0)
				{
					dev_MsgBoxError(Format("ERROR: dev_WriteWholeFile_rawstring() fails to create new text file: {}", dstpath))
					return false
				}
			}
			else
			{
				dev_WriteWholeFile(dstpath, filetext)
				if(ErrorLevel)
				{
					dev_MsgBoxError(Format("ERROR: Fail to create new text file: {}", dstpath))
					return false
				}
			}
		}
	}
	
	; Check that all source GUIDs are "used" at least once.
	
	arBadGuids := []
	for index,obj in g_amt_arTemplateGuids
	{
		if(dictGuidReplaceCount[obj.oldword] == 0)
			arBadGuids.Push(obj.oldword)
	}
	if(arBadGuids.Length() > 0)
	{
		bads := dev_JoinStrings(arBadGuids, "`n")
		dev_MsgBoxError(Format("[ERROR] Some GUID(s) from {} does not appear even once in source files. Template BUG!`n`n{}"
			,g_amtIniCfgFilename, bads))
		return false
	}

	Amt_GenerateNextLevelCfgIni(srcdir, dstdir)

;	Amt_GenerateResultIni(cfgini, dstdir "\" g_amtIniResultFileName)
	
	return true
}

Amt_GenerateNextLevelCfgIni(srcdir, dstdir)
{
	; We generate in dstdir a new AmTemplate.cfg.ini, so that this new one
	; can mark a valid AmTemplate folder to carry out further expansion(if user wishes).
	;
	; The facilitates the work flow of:
	;   Apply Template -> Customize the new project -> Clone the customized-project with a new project-name.
	
	srcinipath := srcdir "\" g_amtIniCfgFilename
	dstinipath := dstdir "\" g_amtIniCfgFilename
	
	IncludePatterns := dev_IniRead(srcinipath, "global", "IncludePatterns","*")
	dev_IniWrite(dstinipath, "global", "IncludePatterns", IncludePatterns)
	
	isGuidAllAmt := true ; assume true
	
	for index,obj in g_amt_arTemplateWords
	{
		dev_IniWrite(dstinipath, "WordToReplace", obj.newword, obj.desc)
	}
	
	for index,obj in g_amt_arTemplateGuids
	{
		dev_IniWrite(dstinipath, "GUID", obj.newword, obj.desc)
		
		if(not Amt_IsAmtGuidFormat(obj.newword))
			isGuidAllAmt := false
	}
	
	dev_IniWrite(dstinipath, "global", "IsStrictGuid", isGuidAllAmt ? 1 : 0)
}

Amt_GenerateResultIni(srcini, dstini)
{
	; First make a verbatim copy to new filename

	FileCreateDir, % dev_SplitPath(dstini)
	FileCopy, %srcini%, %dstini%, 1 ; overwrite
	
	; Then append actual expansion parameters into dstini.
	;
	; [Replaced]
	; OldWord1=NewWord1
	; OldWord2=NewWord2
	; {A33FD2BA-B4AE-4C44-A512-FCF87D0F9976}={20220119-0000-0000-0000-213712000001}
	
	inisect := "Replaced"
	
	for index,obj in g_amt_arTemplateWords
	{
		IniWrite, % obj.newword, % dstini, % inisect, % obj.oldword
	}
	
	for index,obj in g_amt_arTemplateGuids
	{
		IniWrite, % obj.newword, % dstini, % inisect, % obj.oldword
	}
}

amt_IsWildcardMatch(ptn, filename)
{
	; ptn: the pattern, like: "*.cpp" 
	
	; Currently, I do rough processing, hoping no wacky chars in ptn
	; I change ptn to a regex pattern so that I can use regex match.
	
	reptn := ptn
	reptn := StrReplace(reptn, ".", "\.")
	reptn := StrReplace(reptn, "*", ".*")
	
	if(filename ~= "^" reptn "$")
		return true
	else
		return false
}

amt_IsWildcardsMatch(ptns, filename)
{
	for index,ptn in ptns
	{
		if(amt_IsWildcardMatch(ptn, filename))
			return true
	}
	
	return false
}

amt_AdjustTooltipText(ini_text)
{
	otext := StrReplace(ini_text, "\n", "`n")
	return otext
}


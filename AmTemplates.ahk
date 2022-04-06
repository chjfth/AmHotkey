; This module provides a UI that facilitates expanding(copy files and replace words) 
; a user selected template folder into an actual new folder.
; * User assigns template searching folders in g_dirsAmTemplates[].
; * A file named "AmTemplate.cfg.ini" marks the existence of a template folder.
; * Once user selects a template folder, a dialogbox pops out asking for substitution parameters.

AUTOEXEC_AmTemplates_ahk: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

/* APIs:
Amt_LaunchMenu()
*/

global g_dirsAmTemplates := [ A_ScriptDir "\AmTemplates" ]
	; Templates will be searched inside these dirs. User can override or append to this array.
	; g_dirsAmTemplates.Push("D:\test\AmTemplates")

; global constant use by this module
global g_amtIniCfgFilename := "AmTemplate.cfg.ini"
global g_amtIniResultFileName := "AmTemplate.result.ini"
global g_amtRootMenu := "AmtMenu"

global AMT_FOUND_IMMEDIATE_TEMPLATE := -1

; global variable used by this module
												;global g_countAmTemplates := 0
global g_HwndAmt ; HWND for AMT dialog.
global g_amtTemplateSrcDir ; the Dir with file AmTemplate.cfg.ini

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

global g_amtEdtOutdirUser

global g_amtIsCreateDirForFirstWord := false
global g_amtTxtApplyDirFinal
global g_amtIconWarnOverwrite

; AmTemplates_InitHotkeys()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Amt_GetIniFilepath(dirtmpl)
{
	return dirtmpl "\" g_amtIniCfgFilename
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
Amt_LaunchMenu()
{
;	g_countAmTemplates := 0 
	
	dev_Menu_DeleteAll(g_amtRootMenu)
	
	menuheadtext := "==== AmTemplates ===="
	Menu, % g_amtRootMenu, Add, % menuheadtext, Amt_none
	
	Loop, % g_dirsAmTemplates.Length()
	{
		submenu := g_amtRootMenu "." A_Index

		searchdir := g_dirsAmTemplates[A_Index]

		amtfound := Amt_PrepareDir(submenu, searchdir)
		
		if(amtfound==AMT_FOUND_IMMEDIATE_TEMPLATE)
		{
			; append menuitem to basemenu
			fn := Func("Amt_ExpandTemplateUI").Bind(searchdir)
			Menu, % g_amtRootMenu, Add, % searchdir, %fn%
		}
		else
		{
			menutext := Format("{1} ({2})", searchdir, amtfound)
			
			if(amtfound==0)
			{
				Menu, % g_amtRootMenu, Add, % menutext, Amt_none
			}
			else
			{
				Menu, % g_amtRootMenu, Add, % menutext, :%submenu%
			}
		}
	}

	Menu, % g_amtRootMenu, Show
}

Amt_ExpandTemplateUI(dirtmpl)
{
;	MsgBox, % "TODO: " dirtmpl
	Amt_ShowGui(Amt_GetIniFilepath(dirtmpl))
}

Amt_CreateGui(inipath)
{
	g_amt_arTemplateWords := []
	g_amt_arTemplateGuids := []
	;
	dev_GuiAutoResizeRemove("AMT")

	inidir := dev_SplitPath(inipath, inifilename)

	Gui, AMT:New ; Destroy old window if any
	Gui, AMT:+Hwndg_HwndAmt
	Gui, AMT:+Resize +MinSize

	Gui, AMT:Font, s9, Tahoma
	Gui, AMT:Add, Text, xm w580, % Format("Template folder found: (with {})", inifilename)
	Gui, AMT:Add, Edit, xm w580 ReadOnly -E0x200 vg_amtTemplateSrcDir, % inidir ; -E0x200: turn off WS_EX_CLIENTEDGE

	Gui, AMT:Add, Text, xm y+16 w180  vg_OldwordHeader, % "Old words from template:"
	Gui, AMT:Add, Text, x+10 yp       vg_NewwordHeader, % "New words to apply:"

	;
	; Get all items from [WordToReplace]
	;
	
	IniRead, sectlines, % inipath, % "WordToReplace"
;	MsgBox, % ">>> " inipath " ### " sectlines
	
	arlinetext := StrSplit(sectlines, "`n")
;	nlines := arlinetext.Length
	
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
		
		varname_oldword := "g_amteditOldword" + index
		varname_newword := "g_amteditNewword" + index
		
		Gui, AMT:Add, Edit,    xm   w180 ReadOnly -Tabstop           v%varname_oldword% , % key
		Gui, AMT:Add, Edit, yp x+10 w180        gAmt_OnNewWordChange v%varname_newword% , % key
		
		g_amt_arTemplateWords[index] := {"oldword":key, "newword":key, "desc":value}
	}
	
	
	Gui, AMT:Add, Text, xm y+16 w280 vg_OldguidHeader, % "Old GUIDs from template:"
	Gui, AMT:Add, Text, x+10 yp      vg_NewguidHeader, % "New GUIDs to apply:"
	Gui, AMT:Add, Checkbox, x+45 yp Checked vg_amtIsAutoGuid gAmt_ckbToggleAutoGenGuid, % "Auto &generate"
	
	;
	; Get all items from [GUID]
	;
	
	IniRead, sectlines, % inipath, % "GUID"
	
	arlinetext := StrSplit(sectlines, "`n")
	
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
		
		Gui, AMT:Add, Edit,    xm   w280 ReadOnly -Tabstop         v%varname_oldword% , % key
		Gui, AMT:Add, Edit, yp x+10 w280      gAmt_OnNewGuidChange v%varname_newword% , % guidnew
		
		g_amt_arTemplateGuids[index] := {"oldword":key, "newword":guidnew, "desc":value}
	}
	
	Gui, AMT:Add, Text, y+16 xm, % "Apply &to:"
	Gui, AMT:Add, Edit, xm w580 vg_amtEdtOutdirUser gAmt_ResyncUI, % ""
	
	Gui, AMT:Add, Checkbox, xm w500 Checked vg_amtIsCreateDirForFirstWord gAmt_ResyncUI, % CREATE_SUBDIR_WITH_NEW_WORD
	Gui, AMT:Add, Edit, xm+1 w560  ReadOnly -E0x200   vg_amtTxtApplyDirFinal, % "" ; -E0x200: turn off WS_EX_CLIENTEDGE, no so editbox border
	;
	; An exclamation icon at right end, to indicate output folder already exists
	Gui, Add, Picture, x+3 yp Icon2 Hidden w16 h16 +0x100 vg_amtIconWarnOverwrite, % "USER32.DLL" 
	
	Gui, AMT:Add, Button, y+16 xm Default gAMT_BtnOK, % " &Apply "
}


Amt_ShowGui(inipath)
{

	if(!g_HwndAmt) {
		Amt_CreateGui(inipath)
	}
	
	OnMessage(0x200, Func("Amt_WM_MOUSEMOVE")) ; add message hook
	
	Gui, AMT:Show, , % "Expand your AmTemplate"

	GuiControlGet, g_amtEdtOutdirUser, AMT:

	if(g_amtEdtOutdirUser=="")
	{
		; Fill a preset apply path for user
		useroutdir := A_AppData "\" "AmTemplatesApply" ; Example: C:\Users\win7evn\AppData\Roaming\AmTemplatesApply

		GuiControl, AMT:, g_amtEdtOutdirUser, % useroutdir
	}
	
;	applydir := dev_FindVacantFilename(inidir "-Apply{}")

	Amt_ResyncUI()
}

Amt_HideGui()
{
	Gui, AMT:Hide

	OnMessage(0x200, Func("Amt_WM_MOUSEMOVE"), 0) ; remove message hook
	tooltip
}

AMTGuiSize()
{
	Gui, AMT:+MaxSizex%A_GuiHeight% ; Effect: only allow changing window width, not height

	rsdict := {}
	rsdict.g_amtTemplateSrcDir := "0,0,100,0"
	
	rsdict.g_OldwordHeader := "0,0,33,0"
	rsdict.g_NewwordHeader := "33,0,66,0"
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
	
	rsdict.g_amtEdtOutdirUser := "0,0,100,0"
	rsdict.g_amtTxtApplyDirFinal := "0,0,100,0"
	
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
		dev_MsgBoxWarning("Apply folder already exists. Please choose a different one.")
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
		dev_MsgBoxInfo("Expand template success.`n`n" finalApplyDir)
	}
	
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
	idCtrl := A_GuiControl
	
	if(StrIsStartsWith(idCtrl, "g_amteditOldword"))
	{
		; Show desc text of this template word.
	
		index := dev_str2num(dev_StripPrefix(idCtrl, "g_amteditOldword"))
		
		dev_TooltipAutoClear(g_amt_arTemplateWords[index].desc)
		
;		MsgBox, % Format("Amt_WM_MOUSEMOVE on Oldword #{1} : {2} , {3} , {4}", index, g_amt_arTemplateWords[index].oldword, g_amt_arTemplateWords[index].newword, g_amt_arTemplateWords[index].desc)
	}
	else if(StrIsStartsWith(idCtrl, "g_amteditOldguid"))
	{
		; show tooltip on old-GUID, that is text description of this GUID's meaning.
	
		index := dev_str2num(dev_StripPrefix(idCtrl, "g_amteditOldguid"))
		
		dev_TooltipAutoClear(g_amt_arTemplateGuids[index].desc)
	}
	else if(idCtrl=="g_amtIconWarnOverwrite")
	{
		dev_TooltipAutoClear("This folder already exists.")
	}
	else if(A_Gui=="AMT")
	{
		; Note: We use delay-hide here.
		; If execute `tooltip` immediately, the dev_TooltipAutoClear() call from 
		; Amt_OnNewWordChange() and Amt_OnNewGuidChange() will vanish immediately, with a mere flash.
		dev_TooltipDelayHide()
	}
}

Amt_ckbToggleAutoGenGuid()
{
	GuiControlGet, ischecked, AMT:, g_amtIsAutoGuid
	
	if(ischecked)
	{
		Amt_GenerateAllGuidsByTime()
	}

	Amt_ResyncUI()
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
	
	GuiControlGet, g_amtEdtOutdirUser, AMT:
	GuiControlGet, g_amteditNewword1, AMT:
	GuiControlGet, ischecked, AMT:, g_amtIsCreateDirForFirstWord
	
	if(ischecked)
	{
		ckbText := Format("Create a subdir named ""{1}"", so we will create folder:", g_amteditNewword1)
		GuiControl, AMT:, g_amtIsCreateDirForFirstWord, % ckbText
		
		finalApplyDir := g_amtEdtOutdirUser "\" g_amteditNewword1
		GuiControl, AMT:Show, g_amtTxtApplyDirFinal
	}
	else
	{
		GuiControl, AMT:, g_amtIsCreateDirForFirstWord, % CREATE_SUBDIR_WITH_NEW_WORD
		
		finalApplyDir := g_amtEdtOutdirUser
		GuiControl, AMT:Hide, g_amtTxtApplyDirFinal
	}

	;  Update text in g_amtTxtApplyDirFinal
	GuiControl, AMT:, g_amtTxtApplyDirFinal, % finalApplyDir
	
	showOverwriteWarning := FileExist(finalApplyDir) ? "Show" : "Hide"
	GuiControl, AMT:%showOverwriteWarning%, g_amtIconWarnOverwrite
}

Amt_DoExpandTemplate(srcdir, dstdir)
{
	logfile := "AmTemplates.log"
;	dev_WriteLogFile(logfile, "", false) ; create logfile

	arPairs := []
	
	cfgini := Amt_GetIniFilepath(srcdir)
	
	; Walk source dir and find files matching IncludePatterns.

	IniRead, IncludePatterns, % cfgini, % "global", % "IncludePatterns", % "*"
	ptns := StrSplit(IncludePatterns, "|")

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

	Amt_WriteResultIni(cfgini, dstdir "\" g_amtIniResultFileName)
	
	; Actually copy these files.
	
	for index,pair in arPairs
	{
		srcpath := srcdir . pair.srcrela
		dstpath := dstdir . pair.dstrela

		dstdir_tip := dev_SplitPath(dstpath)
		
		FileCreateDir, %dstdir_tip%
		if ErrorLevel {
			dev_MsgBoxError("ERROR: Cannot create folder: " dstdir_tip)
			return false
		}
		
		FileRead, filetext, %srcpath%
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
			filetext := StrReplace(filetext, obj.oldword, obj.newword)
		}
		
		if(FileExist(dstpath))
		{
			dev_MsgBoxError(Format("Unexpected: Target file should not have exsited: {}", dstpath))
			return false
		}
		
		FileAppend, %filetext%, %dstpath%
		if(ErrorLevel)
		{
			dev_MsgBoxError(Format("ERROR: Fail to create new file: {}", dstpath))
			return false
		}
	}
	
	return true
}

Amt_WriteResultIni(srcini, dstini)
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


Amt_none()
{
}

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
; -- Templates will be searched inside these dirs. User can override or append to this array.

; global constant use by this module
global g_amtIniFilename := "AmTemplate.cfg.ini"
global g_amtRootMenu := "AmtMenu"

global AMT_FOUND_IMMEDIATE_TEMPLATE := -1

; global variable used by this module
												;global g_countAmTemplates := 0
global g_HwndAmt ; HWND for AMT dialog.

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


; AmTemplates_InitHotkeys()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Amt_GetIniFilepath(dirtmpl)
{
	return dirtmpl "\" g_amtIniFilename
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
	; (1) If there is an immediate g_amtIniFilename found, we'll NOT create 
	; this basemenu and return AMT_FOUND_IMMEDIATE_TEMPLATE(-1).
	;
	; (2) If there is any g_amtIniFilename found in deeper subdirs, we'll 
	; actually create this basemenu and return a positive number indicating 
	; templates inside.
	;
	; (3) If there is no g_amtIniFilename found, basemenu is NOT created 
	; and we will return 0.
	;
	; Yes, the caller suggests the basemenu name(string) for us to create.

	if FileExist(Amt_GetIniFilepath(basedirpath))
	{
		return AMT_FOUND_IMMEDIATE_TEMPLATE
	}
	
	; Now recurse into subdirs to find other potential g_amtIniFilename files.
	
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
	Gui, AMT:New ; Destroy old window if any
	Gui, AMT:+Hwndg_HwndAmt

	Gui, AMT:Font, s9, Tahoma
	Gui, AMT:Add, Text, xm w500, % inipath

	Gui, AMT:Add, Text, xm y+16 w160, % "Old words from template:"
	Gui, AMT:Add, Text, x+10 yp, % "New words to apply:"

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
		
		Gui, AMT:Add, Edit,    xm   w160 ReadOnly  v%varname_oldword%                     , % key
		Gui, AMT:Add, Edit, yp x+10 w160           v%varname_newword% gAmt_OnNewWordChange, % key
		
		g_amt_arTemplateWords[index] := {"oldword":key, "newword":key, "desc":value}
	}
	
	
	
	Gui, AMT:Add, Text, xm y+16 w280, % "Old GUIDs from template:"
	Gui, AMT:Add, Text, x+10 yp , % "New GUIDs to apply:"
	
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
		
		Gui, AMT:Add, Edit,    xm   w280 ReadOnly v%varname_oldword%                      , % key
		Gui, AMT:Add, Edit, yp x+10 w280          v%varname_newword% gAmt_OnNewGuidChange , % key
		
		g_amt_arTemplateGuids[index] := {"oldword":key, "newword":key, "desc":value}
	}
}

Amt_ShowGui(inipath)
{
	Amt_CreateGui(inipath)
	
	OnMessage(0x200, Func("Amt_WM_MOUSEMOVE")) ; add message hook
	
	Gui, AMT:Show, , % "Expand your AmTemplate"
}

Amt_HideGui()
{
	Gui, AMT:Hide

	OnMessage(0x200, Func("Amt_WM_MOUSEMOVE"), 0) ; remove message hook
	tooltip
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
	Amt_HideGui()
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
	g_amt_arTemplateGUIDs[index].newword := newtext

;	dev_TooltipAutoClear("text changed to: " newtext)
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
	else if(A_Gui=="AMT")
	{
		; Note: We use delay-hide here.
		; If execute `tooltip` immediately, the dev_TooltipAutoClear() call from 
		; Amt_OnNewWordChange() and Amt_OnNewGuidChange() will vanish immediately, with a mere flash.
		dev_TooltipDelayHide()
	}
}

Amt_none()
{
}
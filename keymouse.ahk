
AUTOEXEC_keymouse: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

global km_PinnedMousePos := {} ; .x .y

global km_T3recnames := ["PrnScrn", "ScroLock", "Brk"]
	; recname: RECorded name in the ini as INI-key.
	; The INI file has something like:
	;
	; [T3keymouse]
	; PrnScrn=Left
	; ScroLock=Right

global km_radiosel_PrnScrn
global km_radiosel_ScroLock
global km_radiosel_Brk
	; cannot make these 3 lines into a for-cycle, because concatenating GLOBAL-varname is not allowed(at least in 1.1.19.02)

global km_dict_T3obj := {}

km_init_arT3obj() ; call the function
km_init_arT3obj() ; define the function
{
	km_dict_T3obj.PrnScrn := {}
	o := km_dict_T3obj.PrnScrn ; o is just a reference to km_dict_T3obj.PrnScrn, not a copy
	o.friendlyname := "PrintScreen" ; (const)
	o.ahkname := "SC137" ; use "PrintScreen" sometimes cause weired problem, so SC-code (const)
	o.action := "Left" ; default as left click (variable)

	km_dict_T3obj.ScroLock := {}
	o := km_dict_T3obj.ScroLock
	o.friendlyname := "ScrollLock"
	o.ahkname := "SC046" ; use "ScrollLock" sometimes cause weired problem
	o.action := "Right" ; default as right click

	km_dict_T3obj.Brk := {}
	o := km_dict_T3obj.Brk
	o.friendlyname := "Pause"
	o.ahkname := "Pause"
	o.action := ""
	
;	MsgBox, % km_dict_T3obj.PrnScrn.ahkname . " // " . km_dict_T3obj.ScroLock.ahkname
}


;;; internal globals:
global kmc_indents := "  " ; c implies constant
global kmc_ybiggap := "y+14 "
global km_cfgfile := "keymouse.ini"
global km_isIniLoaded := false


global km_isRShiftArrowNudge := false
global km_RShiftNudgeUnit := "10"

global km_isKeypadNudge := false
global km_KeypadNudgeUnit := "10"
global km_isNumpadSpecial := false
global km_isAppsEasyMouse := false

global kmc_EasymouseLiteHint := "easymouse0"
global kmc_EasymouseLiteHintW, kmc_EasymouseLiteHintE, kmc_EasymouseLiteHintN, kmc_EasymouseLiteHintS ; west/east/north/south
global kmc_EasymouseLiteHint_q


global km_EasymouseWestKey := "SC137" ; (SC137 is PrintScreen) will write ``SC137`` into INI and must be true-and-valid AHK keyname
global km_EasymouseWest_radiosel
global km_EasymouseWest_fraction := "0.15"
;
global km_EasymouseEastKey := "SC046" ; SC046 is ScrollLock
global km_EasymouseEast_radiosel
global km_EasymouseEast_fraction := "0.85"
;
global km_EasymouseNorthKey := "Home"
global km_EasymouseNorth_radiosel
global km_EasymouseNorth_fraction := "0.3"
;
global km_EasymouseSouthKey := "End"
global km_EasymouseSouth_radiosel
global km_EasymouseSouth_fraction := "0.7"

km_AddSystryMenuItem()

km_LoadIni()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; 2010-01-04 http://www.autohotkey.com/forum/viewtopic.php?p=321498
;MButton:: Send ^c

; 2011-12-28 http://www.autohotkey.com/forum/viewtopic.php?p=500772
; right click while holding left mouse down
;~LButton & RButton::Send ^v
/*
km_IsIniExist()
{
	if(FileExist(km_cfgfile))
		return true
	else
		return false
}
*/
km_T3QueryChecked(recname, button)
{
	if(km_dict_T3obj[recname].action==button)
		return " Checked" ; deliberate add a space ahead
	else
		return " "
}

km_EasymouseLiteChecked(direction, ahkname)
{
	varname = km_Easymouse%direction%Key
	if(%varname%==ahkname)
		return " Checked"
	else
		return " "
}

km_EasymouseLite_sel2keyname(dxn, is_updatevar:=true)
{
	; The mapping should sync with Gui: ``vkm_EasymouseWest_radiosel Group``
	dxnsel_varname = km_Easymouse%dxn%_radiosel
	dxnkey_varname = km_Easymouse%dxn%Key
	sel := %dxnsel_varname%
	if(sel==1)
		hotname := "SC137"
	else if(sel==2)
		hotname := "SC046"
	else if(sel==3)
		hotname := "Pause"
	else if(sel==4)
		hotname := (dxn=="West" or dxn=="North") ? "PgUp" : "PgDn"
	else if(sel==5)
		hotname := (dxn=="West" or dxn=="North") ? "Home" : "End"
	else
		hotname := ""
	
	%dxnkey_varname% := hotname
	return hotname
}

km_EasyMouseLite(fractionx, fractiony)
{
	; just a wrapper for easy debugging
	; tooltip, % "km_EasyMouseLite x=" . fractionx . " y=" . fractiony
	km_Easymouse(fractionx, fractiony)
}

km_DefineEasymouseLiteHotkeys(is_save_ini:=false, is_disable_old_hotkey:=false) 
{
	; "Lite" means West,East,North,South only, instead of eight directions.

/*	Don't need this now, because I enforce ahk Reload to flush old hotkeys.
	if(is_disable_old_hotkey)
	{	
		; Remove all "relating" AHK hotkeys first.
		; Note a side effect here: User's already effective "conflicting" hotkeys will be removed as well.
		; Workaround: Reload the whole AmHotkey.ahk, then is_disable_old_hotkey will be false and the remove actions
		; will be bypassed.
		apphots := ["SC137", "SC046", "Pause", "Home", "End", "PgUp", "PgDn"] ; this is hard-coded, should manually sync
		for index, hot in apphots
		{
			try {
				DefineHotkey("AppsKey & " . hot, "")
			}
			catch {
				;If, for example "AppsKey & Home" is not defined as hotkey yet, executing
				;
				;	Hotkey, AppsKey & Home, , Off 
				;
				;will assert runtime error, but not a true error by our purpose. 
				;So I use catch to bypass this error.
			}
		}
	}
*/

	ardxn := ["West", "East", "North", "South"]
	for index, dxn in ardxn
	{
		vHotname  = km_Easymouse%dxn%Key
		vFraction = km_Easymouse%dxn%_fraction

		if(%vFraction%<0) {
			MsgBox, % dxn . " bad(<0) " . %vFraction%
			%vFraction% := "0.01"
		}
		else if(%vFraction%>1) {
			MsgBox, % dxn . " bad(>1) " . %vFraction%
			%vFraction% := "0.99"
		}
		
		; Define dynamic hotkeys for Easymouse lite.
		if(%vHotname%) 
		{
;XX MsgBox, % "3333 vHotname=" . vHotname . " / " . %vHotname% . " / " . %vFraction%
			if(dxn=="West" or dxn=="East")
				DefineHotkey("AppsKey & " . %vHotname%, "km_EasyMouseLite", %vFraction%, 1/2)
			else ; North or South
				DefineHotkey("AppsKey & " . %vHotname%, "km_EasyMouseLite", 1/2, %vFraction%)
;XX MsgBox, 4444 vHotname=%vHotname% (%dxn%)
		}
		
		if(is_save_ini)
			km_IniWrite("EasyMouse", dxn . "Fraction", %vFraction%)
	}

}

km_IniRead(section, key, default)
{
	if(default=="") {
		default := A_Space
		; This is the official way to pass a null-string as default value.
		; If you use the "regular" way(use %default%), outputvar will be "ERROR" .
	}
	
	IniRead, outputvar, %km_cfgfile%, %section%, %key%, %default%
	return outputvar
}

km_LoadIni()
{
	if(not FileExist(km_cfgfile))
	{
		return
	}

	;;;;

	for index, recname in km_T3recnames
	{
		o := km_dict_T3obj[recname]
		strAction := km_IniRead("T3keymouse", recname, "")
		o.action := strAction
	
		if(strAction) ; if not ""
			DefineHotkey("$" . o.ahkname, "Km_T3key_do_action", o.ahkname, strAction)
		
		; For the key(s) that acts as left mouse click, we define Shift+Ctrl+<key> and Shift+<key>
		; as [save current mouse position] and [restore mouse to the saved position]
		if(strAction=="Left")
		{
			DefineHotkey("+^" . o.ahkname, "km_RememberPinPos")
			DefineHotkey("+" . o.ahkname, "km_RestorePinPos")
		}
	}

	;;;;
	
	km_isRShiftArrowNudge := km_IniRead("MouseNudge", "isRShiftArrowNudge", 0) ; 0=false
	km_RShiftNudgeUnit := km_IniRead("MouseNudge", "RShiftNudgeUnit", 10)
	if(km_isRShiftArrowNudge)
	{
		DefineHotkey("$>+Up", "km_RShiftNudge_do", "Up", 0, -1)
		DefineHotkey("$>+Down", "km_RShiftNudge_do", "Down", 0, 1)
		DefineHotkey("$>+Left", "km_RShiftNudge_do", "Left", -1, 0)
		DefineHotkey("$>+Right", "km_RShiftNudge_do", "Right", 1, 0)
	}
	
	;;;;
	
	km_isKeypadNudge := km_IniRead("MouseNudge", "isKeypadNudge", 0) ; 0=false
	km_KeypadNudgeUnit := km_IniRead("MouseNudge", "KeypadNudgeUnit", 10)
	if(km_isKeypadNudge)
	{
		DefineHotkey("$NumpadHome", "km_KeypadNudge_do", "NumpadHome", -1, -1)
		DefineHotkey("$NumpadUp", "km_KeypadNudge_do", "NumpadUp", 0, -1)
		DefineHotkey("$NumpadPgUp", "km_KeypadNudge_do", "NumpadPgUp", 1, -1)
		DefineHotkey("$NumpadLeft", "km_KeypadNudge_do", "NumpadLeft", -1, 0)
		DefineHotkey("$NumpadRight", "km_KeypadNudge_do", "NumpadRight", 1, 0)
		DefineHotkey("$NumpadEnd", "km_KeypadNudge_do", "NumpadEnd", -1, 1)
		DefineHotkey("$NumpadDown", "km_KeypadNudge_do", "NumpadDown", 0, 1)
		DefineHotkey("$NumpadPgDn", "km_KeypadNudge_do", "NumpadPgDn", 1, 1)
	}

	;;;;
	
	km_isNumpadSpecial := km_IniRead("NumpadSpecial", "isNumpadSpecial", 0) ; 0=false
	if(km_isNumpadSpecial)
	{
		DefineHotkey("$NumpadDiv", "km_NumpadSpecial_do", "NumpadDiv")
		DefineHotkey("$NumpadMult", "km_NumpadSpecial_do", "NumpadMult")
		DefineHotkey("$NumpadSub", "km_NumpadSpecial_do", "NumpadSub")
		DefineHotkey("$NumpadAdd", "km_NumpadSpecial_do", "NumpadAdd")
		DefineHotkey("$NumpadIns", "km_NumpadSpecial_do", "NumpadIns")
	}
	
	;;;;

	km_isAppsEasyMouse := km_IniRead("EasyMouse", "isAppsEasyMouse", 0) ; 0=false
	if(km_isAppsEasyMouse)
	{
		DefineHotkey("AppsKey & NumpadHome" , "km_EasyMouseNumpad", 1/6, 1/4)
		DefineHotkey("AppsKey & NumpadUp"   , "km_EasyMouseNumpad", 1/2, 1/4)
		DefineHotkey("AppsKey & NumpadPgUp" , "km_EasyMouseNumpad", 5/6, 1/4)
		DefineHotkey("AppsKey & NumpadLeft" , "km_EasyMouseNumpad", 1/6, 1/2)
		DefineHotkey("AppsKey & NumpadClear" , "km_EasyMouseNumpad", 1/2, 1/2)
		DefineHotkey("AppsKey & NumpadRight" , "km_EasyMouseNumpad", 5/6, 1/2)
		DefineHotkey("AppsKey & NumpadEnd"  , "km_EasyMouseNumpad", 1/6, 3/4)
		DefineHotkey("AppsKey & NumpadDown" , "km_EasyMouseNumpad", 1/2, 3/4)
		DefineHotkey("AppsKey & NumpadPgDn" , "km_EasyMouseNumpad", 5/6, 3/4)
	}

	km_EasymouseWestKey := km_IniRead("EasyMouse", "EasymouseWestKey", "")
;msgbox, 444444444[%km_EasymouseWestKey%]
	km_EasymouseEastKey := km_IniRead("EasyMouse", "EasymouseEastKey", "")
	km_EasymouseNorthKey := km_IniRead("EasyMouse", "EasymouseNorthKey", "")
	km_EasymouseSouthKey := km_IniRead("EasyMouse", "EasymouseSouthKey", "")

	km_EasymouseWest_fraction := km_IniRead("EasyMouse", "WestFraction", "0.15")
	km_EasymouseEast_fraction := km_IniRead("EasyMouse", "EastFraction", "0.85")
	km_EasymouseNorth_fraction := km_IniRead("EasyMouse", "NorthFraction", "0.3")
	km_EasymouseSouth_fraction := km_IniRead("EasyMouse", "SouthFraction", "0.7")

	km_DefineEasymouseLiteHotkeys()
	
	km_isIniLoaded := true
}

km_IniWrite(section, key, value)
{
	IniWrite, %value%, %km_cfgfile%, %section%, %key%
	if ErrorLevel {
;		dev_TooltipAutoClear("km_IniWrite() fail!")
		return -1
	}
	else {
;		dev_TooltipAutoClear("km_IniWrite() ok.")
		return 0
	}
}

km_SaveIni()
{
	err = 0
	ar_map := ["Left", "Right", "Middle", ""] ; Map radiosel to .action
	for index, recname in km_T3recnames
	{
		radiosel_varname := "km_radiosel_" . recname
		strAction := ar_map[%radiosel_varname%]
		km_dict_T3obj[recname].action := strAction
		err += km_IniWrite("T3keymouse", recname, strAction)
	}
	
	err += km_IniWrite("MouseNudge", "isRShiftArrowNudge", km_isRShiftArrowNudge)
	err += km_IniWrite("MouseNudge", "RShiftNudgeUnit", km_RShiftNudgeUnit)
	
	err += km_IniWrite("MouseNudge", "isKeypadNudge", km_isKeypadNudge)
	err += km_IniWrite("MouseNudge", "KeypadNudgeUnit", km_KeypadNudgeUnit)
	
	err += km_IniWrite("NumpadSpecial", "isNumpadSpecial", km_isNumpadSpecial)
	
	err += km_IniWrite("EasyMouse", "isAppsEasyMouse", km_isAppsEasyMouse)

	err += km_IniWrite("EasyMouse", "EasymouseWestKey", km_EasymouseLite_sel2keyname("West"))
	err += km_IniWrite("EasyMouse", "EasymouseEastKey", km_EasymouseLite_sel2keyname("East"))
	err += km_IniWrite("EasyMouse", "EasymouseNorthKey", km_EasymouseLite_sel2keyname("North"))
	err += km_IniWrite("EasyMouse", "EasymouseSouthKey", km_EasymouseLite_sel2keyname("South"))
	
	if(err!=0) {
		MsgBox, % msgboxoption_IconExclamation, , % "Unexpected: km_IniWrite() fail on " . km_cfgfile
	}
	
	km_DefineEasymouseLiteHotkeys(true, true)

	km_isIniLoaded := true
}

km_PromptMissingIni()
{
	if(not km_isIniLoaded)
	{
		km_DoGuiConfig()
			; This Gui, on OK Button, will generate the Ini.
	}
}


; 2013-08-10 EasyMouse() to position mouse cursor at some proportional position of current active window
; Ref: http://superuser.com/a/14872 (WinGetPos, 'A' on WinGetPos line mean "active window")
; Ref: http://www.autohotkey.com/board/topic/49872-time-precision/ (A_TickCount)

km_EasyMouse(fractionx, fractiony, button="L")
{
	WinGetPos, x, y, width, height, A
	static mylastx, mylasty, last_tickcount
;	MsgBox, get last %mylastx% %mylasty%
	mynowx := width*fractionx
	mynowy := height*fractiony
	If (mynowx==mylastx and mynowy==mylasty and A_TickCount-last_tickcount<1900) {
	  If (button=="L")
	    SendInput {Click,Left}	
	  Else 
	    SendInput {Click,Right}	 
	  PlaySoundLeftClick()
	} else { 
	  MouseMove, mynowx, mynowy
	  mylastx := mynowx
	  mylasty := mynowy
	  last_tickcount := A_TickCount
;	  MsgBox, Set last %mylastx% %mylasty%
	}
}

km_DoGuiConfig()
{
	Gui, kmcfg:Destroy ; destroy old
	Gui, kmcfg:+HwndKmcfgHwnd ; generate (global?) variable KmcfgHwnd
	Gui, kmcfg:Font, s9 cBlack, Tahoma
	Gui, kmcfg:Add, Text, , % "Configure Autohotkey keymouse module parameters. Call this dialog again with Ctrl+PrintScreen."

;	Gui, kmcfg:Add, Text, , % "" ; make a blank line
	Gui, kmcfg:Add, Text, , % "Use the following keys for mouse click:"
	for index, recname in km_T3recnames
	{
		o := km_dict_T3obj[recname]
		Gui, kmcfg:Add, Text , xm w120 Section, % kmc_indents . o.friendlyname . " action:"
		Gui, kmcfg:Add, Radio, % "ys x+m Group vkm_radiosel_" . recname . km_T3QueryChecked(recname, "Left"), % "Left click"
		Gui, kmcfg:Add, Radio, % "ys x+m " . km_T3QueryChecked(recname, "Right"), % "Right click"
		Gui, kmcfg:Add, Radio, % "ys x+m " . km_T3QueryChecked(recname, "Middle"), % "Middle click"
		Gui, kmcfg:Add, Radio, % "ys x+m " . km_T3QueryChecked(recname, ""), % "None"	
	}
	
;	Gui, kmcfg:Add, Text, xm , % "" ; blank line, x return to left margin
	optchecked := km_isRShiftArrowNudge ? "Checked" : ""
	Gui, kmcfg:Add, Checkbox, % kmc_ybiggap . " xm vkm_isRShiftArrowNudge Section " . optchecked
		, % "Use &Right-Shift + arrow keys to nudge mouse,"
	Gui, kmcfg:Add, Edit, vkm_RShiftNudgeUnit ys-2, %km_RShiftNudgeUnit% ; -2 is arbitrary, just visually better
	Gui, kmcfg:Add, Text, ys, % "pixels each time."
	;
	optchecked := km_isKeypadNudge ? "Checked" : ""
	Gui, kmcfg:Add, Checkbox, % "xm vkm_isKeypadNudge Section " . optchecked
		, % "Use Numpad keys(when NumLock off) to nudge mouse and do click,"
	Gui, kmcfg:Add, Edit, vkm_KeypadNudgeUnit ys-2, %km_KeypadNudgeUnit%
	Gui, kmcfg:Add, Text, ys, % "pixels each time."
	;
	Gui, kmcfg:Add, Checkbox, % "xm vkm_isNumpadSpecial " . (km_isNumpadSpecial ? "Checked" : "")
		, % "Us&e Numpad / * - + specially." 

;	Gui, kmcfg:Add, Text, xm , % "" ; blank line, x return to left margin
	optchecked := km_isAppsEasyMouse ? "Checked" : ""
	Gui, kmcfg:Add, Checkbox, % "xm vkm_isAppsEasyMouse Section " . kmc_ybiggap  . optchecked
		, % "Use AppsKey + Numpad(when NumLock off) to do &EasyMouse move && click."

;	Gui, kmcfg:Add, Text, xm , % "" ; blank line, x return to left margin
	Gui, kmcfg:Add, Text, % "xm " . kmc_ybiggap . " vkmc_EasymouseLiteHint Section" ; Pending! Static Text does not report non-null A_GuiControl in km_WM_MOUSEMOVE()
		, % "AppsKey+<key> to do EasyMouse move without Numpad:" ; blank line, x return to left margin
	Gui, kmcfg:Add, Edit, % "ys-2 x+m ReadOnly vkmc_EasymouseLiteHint_q", % " (?) " ; use a small editbox as workaround
	;
	Gui, kmcfg:Add, Text, xm w120 Section vkmc_EasymouseLiteHintW, % kmc_indents . "EasyMouse WEST:"
	Gui, kmcfg:Add, Radio, % "ys x+m vkm_EasymouseWest_radiosel Group " . km_EasymouseLiteChecked("West", "SC137"), % "PrintScreen" ;1
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("West", "SC046"), % "ScrollLock" ;2
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("West", "Pause"), % "Pause" ;3
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("West", "PgUp"), % "PageUp   " ;4
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("West", "Home"), % "Home" ;5
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("West", ""), % "None" ;6
	Gui, kmcfg:Add, Edit, % "ys-2 x+m vkm_EasymouseWest_fraction ", % km_EasymouseWest_fraction
	;
	Gui, kmcfg:Add, Text, xm w120 Section vkmc_EasymouseLiteHintE, % kmc_indents . "EasyMouse EAST:"
	Gui, kmcfg:Add, Radio, % "ys x+m vkm_EasymouseEast_radiosel Group " . km_EasymouseLiteChecked("East", "SC137"), % "PrintScreen" 
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("East", "SC046"), % "ScrollLock" 
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("East", "Pause"), % "Pause" 
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("East", "PgDn"), % "PageDown" 
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("East", "End"), % "End" 
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("East", ""), % "None"
	Gui, kmcfg:Add, Edit, % "ys-2 x+m vkm_EasymouseEast_fraction", % km_EasymouseEast_fraction
	;
	Gui, kmcfg:Add, Text, xm w120 Section vkmc_EasymouseLiteHintN, % kmc_indents . "EasyMouse NORTH:"
	Gui, kmcfg:Add, Radio, % "ys x+m vkm_EasymouseNorth_radiosel Group " . km_EasymouseLiteChecked("North", "SC137"), % "PrintScreen"
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("North", "SC046"), % "ScrollLock"
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("North", "Pause"), % "Pause"
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("North", "PgUp"), % "PageUp   "
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("North", "Home"), % "Home"
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("North", ""), % "None"
	Gui, kmcfg:Add, Edit, % "ys-2 x+m vkm_EasymouseNorth_fraction ", % km_EasymouseNorth_fraction
	;
	Gui, kmcfg:Add, Text, xm w120 Section vkmc_EasymouseLiteHintS, % kmc_indents . "EasyMouse SOUTH:"
	Gui, kmcfg:Add, Radio, % "ys x+m vkm_EasymouseSouth_radiosel Group " . km_EasymouseLiteChecked("South", "SC137"), % "PrintScreen"
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("South", "SC046"), % "ScrollLock"
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("South", "Pause"), % "Pause"
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("South", "PgDn"), % "PageDown"
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("South", "End"), % "End"
	Gui, kmcfg:Add, Radio, % "ys x+m " . km_EasymouseLiteChecked("South", ""), % "None"
	Gui, kmcfg:Add, Edit, % "ys-2 x+m vkm_EasymouseSouth_fraction ", % km_EasymouseSouth_fraction

	Gui, kmcfg:Font, s9 cBlue, Tahoma
	Gui, kmcfg:Add, Text, xm, % "NOTE: Answering OK will reload the whole AHK script. (normally nothing harmful)"
	Gui, kmcfg:Add, Button, Default Section, OK  ; The label ButtonOK (if it exists) will be run when the button is pressed.
	Gui, kmcfg:Add, Button, ys x+m , Cancel
	
	Gui, kmcfg:Show
	WinSet, AlwaysOnTop, On, ahk_id %KmcfgHwnd%
	
	fn := Func("km_WM_MOUSEMOVE")
	OnMessage(0x200, fn) ; new-style, turn a function-name into a function object
	; // OnMessage(0x200, "km_WM_MOUSEMOVE") // this is old-style and will not co-exist with other GUI's WM_MOUSEMOVE hook
	
	return

kmcfgButtonOK:
	Gui, kmcfg:Submit
	km_SaveIni()
	Reload

kmcfgGuiClose:
kmcfgGuiEscape:
kmcfgButtonCancel:
	OnMessage(0x200, Func("km_WM_MOUSEMOVE"), 0) ; remove our message hook
	Gui, kmcfg:Destroy

kmcfgCleanup:
	tooltip
	return
}


km_DoClick(button)
{
	if(not km_isIniLoaded)
		return

	; button is "Left", "Right" or "Middle"
	if(button=="Left") {
		SendInput {Click,Left}
		PlaySoundLeftClick()
	} 
	else if(button=="Right") {
		SendInput {Click,Right}
		PlaySoundRightClick()
	}
	else if(button=="Middle") {
		SendInput {Click,Middle}
	}
	else {
		MsgBox, Bad param for km_DoClick(%button%), possibly a bug in %A_ScriptName%
	}
}


km_WM_MOUSEMOVE()
{
;	dev_TooltipAutoClear("~~~~~~km_WM_MOUSEMOVE() called")
	
	if(A_GuiControl=="km_isKeypadNudge")
	{
		tooltip, % "When NumLock is off, press Numpad area arrow keys to nudge mouse."
	}
	else if(A_GuiControl=="km_isNumpadSpecial")
	{
		tooltip, 
(
Use Numpad area keys specially:.
 / to left-click
 * to right-click
 - to simulate Ctrl+X (cut)
 + to simulate Ctrl+C (copy)
 Enter to simulate Ctrl+V (paste)
)
	}
	else if(A_GuiControl=="km_isAppsEasyMouse")
	{
		tooltip, 
(
When NumLock is off: 
Press [App + one of the nine numpad arrow keys] to move mouse pointer at some proportional position of current active window.
First press of the hotkey moves the mouse, a second press of the same hotkey will left-click on that position.
-- This behavior is called EasyMouse.
)
	}
	else if(StrIsStartsWith(A_GuiControl, "kmc_EasymouseLiteHint"))
	{
		tooltip, 
(
Assign alternate EasyMouse hotkeys, especially when you do not have Numpad(e.g. on many laptop computers).
These hotkeys let you place your mouse pointer at four positions(East/West/North/South) quickly.
What's more, you can customized the four positions' fraction.
)
	}
	else if(A_Gui=="kmcfg")
	{
		tooltip
		;tooltip , % "A_GuiControl=" . A_GuiControl ; debug
	}
}

Km_T3key_do_action(keyname, action)
{
	km_PromptMissingIni()

;tooltip, >>>>>>>>>%keyname% do click of %action%
	if(action)
		km_DoClick(action)
	else
		Send {%keyname%}
}



km_RShiftNudge_do(arrowname, dx, dy)
{
	if(km_isRShiftArrowNudge) {
		MouseNudge(dx, dy, km_RShiftNudgeUnit)
	}
	else {
		MsgBox, % "In " . A_ThisFunc . "(), this should not be seen, probably a bug! (ahkname=" . ahkname . ")"
;		Send +{%arrowname%}
	}
}

km_KeypadNudge_do(ahkname, dx, dy)
{
	if(km_isKeypadNudge) {
		MouseNudge(dx, dy, km_KeypadNudgeUnit)
	}
	else {
		MsgBox, % "In " . A_ThisFunc . "(), this should not be seen, probably a bug! (ahkname=" . ahkname . ")"
;		Send {%ahkname%}
	}
}

km_NumpadSpecial_do(ahkname)
{
	if(ahkname=="NumpadDiv")
		LeftClickWithSound()
	else if(ahkname=="NumpadMult")
		RightClickAndPlaySound()
	else if(ahkname=="NumpadSub")
		Send ^x
	else if(ahkname=="NumpadAdd")
		Send ^c
	else if(ahkname=="NumpadIns")
		Send ^v
	else {
		MsgBox, % "In " . A_ThisFunc . "(), this should not be seen, probably a bug! (ahkname=" . ahkname . ")"
	}
}


km_EasyMouseNumpad(fractionx, fractiony, button="L")
{
	if(km_isAppsEasyMouse)
		km_EasyMouse(fractionx, fractiony, button)
}

km_TooltipOff:
	tooltip
	return

km_RememberPinPos()
{
	CoordMode, Mouse, Screen    ;sets coordinates based upon screen resolution
	MouseGetPos, pinx, piny
	CoordMode, Mouse, Relative  ;restore coordinates based upon active window

	km_PinnedMousePos.x := pinx
	km_PinnedMousePos.y := piny
	
	tooltip, % "Mouse position remembered (" . pinx . "," . piny . ")"
	SetTimer, km_TooltipOff, -2000
	return
}

km_RestorePinPos(speed:=3)
{
;	tooltip, 2222222222
	CoordMode, Mouse, Screen    ;sets coordinates based upon screen resolution
	MouseMove, % km_PinnedMousePos.x, % km_PinnedMousePos.y, %speed%
	CoordMode, Mouse, Relative  ;restore coordinates based upon active window
}


;^SC137:: km_DoGuiConfig() ; Ctrl+PrintScreen
;!#\:: km_DoGuiConfig()

; ^NumLock::  km_RestorePinPos() ; strange! ^NumLock does not response, but +NumLock is ok.

km_AddSystryMenuItem()
{
	Menu, tray, add  ; Creates a separator line.
	Menu, tray, add, Configure Keymouse, km_DoGuiConfig  ; Creates a new menu item.
}

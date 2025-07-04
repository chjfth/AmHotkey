
AUTOEXEC_quick_switch_app: ; Workaround for Autohotkey's ugly auto-exec feature. Must be first line.

global gtc_last_letter := 0 ; Last letter GetTickCount()
global g_last_letter := "" 
global g_qsa_grace_ticks := 500 ; millisec

global g_msec_dither_threshold := 90

; global PREFIX_REGEX = REGEX_ ; memo: This is wrong, function body will not see this global
global PREFIX_REGEX := "REGEX_" ; const // No longer needed.

global QSA_NO_SUFFIXKEY := ""
global QSA_NO_WNDCLASS := ""
global QSA_NO_WNDCLS := ""
global QSA_NO_WNDCLS_REGEX := ""
global qsa_dbgfile := "qsa_dbgfile.txt"

QSA_ModuleInit()

; sample_DefineQuickSwitchApps() ; This is too personal, so don't do it here.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QSA_ModuleInit()
{

; Temp disable this
;	QSA_MonitorLiteralKeyTick()
}


QSA_RecordLastLiteralTick(now_key)
{
	; now_key is not used yet, just for debugging
	g_last_letter := now_key

	gtc_last_letter := A_TickCount
}

QSA_MonitorLiteralKeyTick()
{
	static init_done := false
	if init_done
		return
	init_done := true

	literal_keys = abcdefghijklmnopqrstuvwxyz1234567890
	Loop, parse, literal_keys
	{
		dev_DefineHotkey("~$" . A_LoopField , "QSA_RecordLastLiteralTick", A_LoopField)
	}
}

QSA_IsFastTyping(suffixkey)
{
	;
	; Note: I just can't implement it with A_TimeIdlePhysical, because it will always be 0
	; when QSA_IsFastTyping() is executing. That's true because user did really just pressed a key
	; to trigger this.

	if(StrLen(suffixkey)!=1) ; suffixkey=="F1" etc
	{
		return false
	}

	timegap := A_TickCount - gtc_last_letter
	;tooltip, prior=%A_PriorKey% / prioHot=%A_PriorHotKey% / timegap=%timegap%
	if (timegap < g_qsa_grace_ticks)
	{
		Send %suffixkey% ;seem no need of {Blind}
		gtc_last_letter := A_TickCount

;		dev_TooltipAutoClear("Fast typing!")

		return true
		; Side effect here: If you press a second key while CapsLock is still holding down,
		; that second key may (sometimes) not be in desired case. 
	}
	else {
;		dev_TooltipAutoClear("Not Fast typing.")
		return false
	}
}

ArrayHasValue(ar, chkval)
{
	for index, value in ar 
	{
		
		if (chkval==value) {
;			msgbox, [%chkval%] [%value%]
			return true
		}
	}
	return false
}

AddHwndToWingroup(hwnd, groupname)
{
	; This functions remembers which hwnd(s) are in which groupname to avoid add it twice,
	; duplicate adding causes AHK's internal hwnd Z order to change, which causes 
	; `GroupActivate, groupname, R`'s R feature to lose.
	
	static s_groupdict := {} ; associative array, groupname as key, python idiom
	static s_actcount := 0
	s_actcount += 1
	
	is_do_add := false
	if not s_groupdict.haskey(groupname)
		s_groupdict[groupname] := array() ; create a new key assigning an array
	
	; check if hwnd has been in the array
	if not ArrayHasValue(s_groupdict[groupname], hwnd)
		is_do_add := true
	
	
	if is_do_add
	{
		s_groupdict[groupname].Insert(hwnd)
		; tooltip, % "grpname=" . groupname
		GroupAdd, %groupname%, ahk_id %hwnd%
	}
	
	; clear stale hwnd periodically
	if mod(s_actcount, 100)==0 ; s_actcount is increased by caller
	{
		for index, hwnd in s_groupdict[groupname] {
			if not WinExist("ahk_id " . hwnd) {
;				msgbox, AddHwndToWingroup() will clear hwnd %hwnd% ; // debug
				s_groupdict[groupname].remove(index)
			}
		}
	}
}

MyActivateSingleWindow(suffixkey, winclass, appdesc)
{
	; This function can be used by user standalone, for example:
	; 
	;	CapsLock & 0:: MyActivateSingleWindow("0", "CalcFrame", "Windows Calculator")
	;
	;	CapsLock & F10:: MyActivateSingleWindow("F10", "CalcFrame", "Windows Calculator")
	;
	; If you have multiple windows of "ahk_class CalcFrame", MyActivateSingleWindow can only switch to
	; the most recently used one; in order to switch between two or more of such windows, 
	; use MyActivateWindowClasses instead. Of course, MyActivateSingleWindow and MyActivateWindowClasses
	; can be used at the same time for the same winclass.

	if QSA_IsFastTyping(suffixkey)
		return

	WinActivate, ahk_class %winclass%
	isok := dev_WinWaitActive_with_timeout("ahk_class " . winclass, "", 1)
	If(!isok)
	{
		MsgBox, Cannot find a window of %appdesc%
		return
	}
	MouseMoveInActiveWindow(0.5, 0.5)
}

MyActivateGroup(suffixkey, groupname, winclass, wincls_regex, title_regex, appdesc)
{
	; All winclass, wincls_regex and title_regex should be matched(unless empty) to make activation.
	
	if(title_regex=="") 
	{
		; Without this: when winclass and title_regex are both null, and there is only one matched window
		; (e.g. Hypersnap 8), pressing CapsLock+j twice would cause "Cannot find any window of Hypersnap 7 or 8"
		; message box pop out.
		title_regex := ".*" ; match any
	}
	
	if QSA_IsFastTyping(suffixkey)
		return
	
;	tooltip, [%groupname%] %winclass% -- %wincls_regex% == %title_regex% ; debug
;	FileDelete, %qsa_dbgfile% ; debug
	
	if(wincls_regex || title_regex)
	{
		WinGet, hwnds, LIST
		Loop, %hwnds% 
		{
			hwnd := hwnds%A_Index%

			match_winclass := true ; assume match
			match_winclsregex := true
			match_titleregex := true

			WinGetClass, class, ahk_id %hwnd%
			WinGetTitle, title, ahk_id %hwnd%
			
			; debug >>>
;			dbgline := hwnd . " ## " . class . " %% " . title . "`n"
;			FileAppend, %dbgline%, %qsa_dbgfile%
			; debug <<<

			if(winclass)
			{
				; WinGetTitle, title, ahk_id %Awinid% ; debug
				; msgbox, % "class=" . class . "  title=" .title ; debug
				if(class==winclass)
					match_winclass := true
				else
					match_winclass := false
			}
			if(wincls_regex)
			{
				if(class ~= wincls_regex)
					match_winclsregex := true
				else
					match_winclsregex := false
			}
			if(title_regex)
			{
				if(title ~= title_regex)
					match_titleregex := true
				else
					match_titleregex := false
			}
			
;			FileAppend, [%match_winclass%][%match_winclsregex%][%match_titleregex%]`n, %qsa_dbgfile% ; debug

			if(match_winclass && match_winclsregex && match_titleregex)
			{
				AddHwndToWingroup(hwnd, groupname) ; inside: calls GroupAdd
			}
		}
	}
	else 
	{
		GroupAdd, %groupname%, ahk_class %winclass%
	}
	
	GroupActivate, %groupname%, R
	; -- Note: If only one target window exists and already in foreground, ErrorLevel will assert.

	if(ErrorLevel) ; check for false ErrorLevel
	{
		ok := false
		if(title_regex)
		{
			WinGetActiveTitle, title
			if (title ~= title_regex) ; regex compare
				ok := true
		}
		else
		{
			WinGetClass, class, A
;			msgbox, % "[ahk_class " . class . "] [" . wincriteria . "]" //xxx
			if(class==winclass)
				ok := true
		}

		if not ok
		{
			dev_MsgBoxWarning("Cannot find any window of: " . appdesc)
			return
		}
	}
	MouseMoveInActiveWindow(0.5, 0.5)
}


dev_MyActivateGroupByBooleanFunc(funcname, suffixkey="")
{
	; 2022.08.08 : Check all HWNDs on current system, If funcname(hwnd) returns true, then this hwnd
	; is considered in the group (the group is identified by funcname), then one of the hwnds in 
	; this group is activated.
	; Flexibility: A specific hwnd can be matched against different funcname-s, at the same time.
	
	if QSA_IsFastTyping(suffixkey)
		return
	
	if(not funcname)
	{
		errmsg := "Error: Input parameter funcname is null!" . "`n`nCallstack below:`n`n" . dev_getCallStackEx()
		dev_MsgBoxError(errmsg)
		return
	}
	
	groupname := "groupbbf_" . funcname
	
	WinGet, hwnds, LIST
	Loop, %hwnds% 
	{
		hwnd := hwnds%A_Index%

		if(%funcname%(hwnd))
		{
			AddHwndToWingroup(hwnd, groupname) ; inside: calls GroupAdd
		}
	}
	
	GroupActivate, %groupname%, R
	; -- Note: If only one target window exists and already in foreground, ErrorLevel will assert.

	if(ErrorLevel) ; check for false ErrorLevel
	{
		; Cope with a weird behavior of Autohotkey: If [there is only one HWND in current group and 
		; it had been in activated state], ErrorLevel will be asserted here. 
		; We sure should consider this success.
		;
		WinGet, Awinid, ID, A
		if(%funcname%(Awinid))
		{
			dev_TooltipAutoClear(Format("The only window matching ""{1}()"" had already been activated.", funcname), 1000)
		}
		else
		{
			; Really no matched window is found.
			dev_MsgBoxInfo("dev_MyActivateGroupByBooleanFunc(): Cannot find any window matching the function: `n`n" . funcname . "()")
			return
		}
	}
	
	; Move mouse point to center of the activated window, so we have an additional visual clue of the activated window.
	MouseMoveInActiveWindow(0.5, 0.5)
}


QSA_make_group_name(iname)
{
	; Strip illegal characters from iname to make a legal groupname.
	; If illegal chars in groupname found, GroupAdd will assert error("Illegal group name").
	; For example "+" is an illegal one, at least in AHK_L 1.19 .
	return RegExReplace(iname, "[^A-Za-z0-9_]", "_")
}

QSA_DefineActivateSingle_Caps(suffixkey, winclass, appdesc)
{
	dev_DefineHotkey("CapsLock & " . suffixkey, "MyActivateSingleWindow", suffixkey, winclass, appdesc)
}

QSA_DefineActivateGroup_Caps(suffixkey, winclass, appdesc)
{
	; Auto generate a group-name for GroupActivate (just prepend "group_"). 
	; Same winclass strings will result in same group-name.
	
	groupname := "groupWINCLASS_" . QSA_make_group_name(winclass)
	; GroupAdd, %groupname%, ahk_class %winclass%
	; -- Note: GroupAdd is postponed to MyActivateGroup.
	
	dev_DefineHotkey("CapsLock & " . suffixkey, "MyActivateGroup", suffixkey, groupname, winclass, QSA_NO_WNDCLS_REGEX, "", appdesc)
}

QSA_DefineActivateGroupFlex(hotkey, suffixkey, winclass, wincls_regex, title_regex, appdesc)
{
	; winclass can be "", to only match against title_regex
	;
	; suffixkey is not important; it will be passed to QSA_IsFastTyping() finally. You can just pass QSA_NO_SUFFIXKEY.
	
	if(!winclass and !wincls_regex and !title_regex)
	{
		MsgBox, % "Error calling QSA_DefineActivateGroupFlex: winclass, wincls_regex and title_regex are all empty!"
		return 
	}
	
	if(winclass and wincls_regex)
	{
		MsgBox, % "Error calling QSA_DefineActivateGroupFlex: You cannot assign both winclass and wincls_regex!"
		return
	}
	
	if(!appdesc)
	{
		MsgBox, % "Error calling QSA_DefineActivateGroupFlex: appdesc must not be empty!"
		return 
	}
	
	; Auto generate a group-name from appdesc (not using winclass, title_regex because they can be empty)
	groupname := "groupREGEX_" . QSA_make_group_name(winclass . appdesc)
	; -- Note: GroupAdd is postponed to the moment the hotkey is pressed,
	; because we intend the regex title-match behavior to take effect just at the time we fire the hotkey.
	
	dev_DefineHotkey(hotkey, "MyActivateGroup", suffixkey, groupname, winclass, wincls_regex, title_regex, appdesc)
}

QSA_DefineActivateGroupFlex_Caps(suffixkey, winclass, wincls_regex, title_regex, appdesc)
{
	QSA_DefineActivateGroupFlex("CapsLock & " . suffixkey, suffixkey, winclass, wincls_regex, title_regex, appdesc)
}

MyActivateWindowGroupFlex(winclass, wincls_regex, title_regex, appdesc) ; Flex: flexible
{
	; This function can be used by user standalone,to activate windows matching winclass and title_regex.
	; Exampe:
	;
	;	+^8:: MyActivateWindowGroupFlex("wndclass_desked_gsk", QSA_NO_WNDCLS_REGEX, "Microsoft Document Explorer", "VS2008 MSDN Documents")
	;
	
	; Auto generate a group-name for GroupActivate
	wincls_part := winclass ? winclass : wincls_regex
	groupname := QSA_make_group_name(Format("groupFlex__{}__{}__{}", wincls_part, title_regex, appdesc))

	MyActivateGroup("", groupname, winclass, wincls_regex, title_regex, appdesc)
}


sample_DefineQuickSwitchApps() ; as template for actual users
{
	QSA_DefineActivateGroup_Caps("/", "Notepad", "Notepad")
	QSA_DefineActivateGroupFlex_Caps("1", "Chrome_WidgetWin_1", QSA_NO_WNDCLS_REGEX, "(Google Chrome|Comodo Dragon)$", "Google Chrome")
	
	QSA_DefineActivateGroup_Caps("d", "ConsoleWindowClass", "CMD")

	QSA_DefineActivateGroup_Caps("w", "CabinetWClass", "Windows Explorer")

	QSA_DefineActivateGroupFlex_Caps("j", QSA_NO_WNDCLASS, "HyperSnap (7|8) Window Class",  "", "Hypersnap 7 or 8")

	QSA_DefineActivateGroupFlex_Caps("6", QSA_NO_WNDCLASS, "^Afx", "Microsoft Visual C\+\+", "The Visual C++ 6 IDE")
		; VC6 winclass is like Afx:400000:8:10009:0:3ab31345
		; Sigh, with 1.1.19.02, MRU behavior is broken with this regex mode
		; http://superuser.com/questions/876491/autohotkey-groupactivate-mru-behavior-discrepancy-any-way-to-fix

	; Visual Studio VS2010+
	QSA_DefineActivateGroupFlex_Caps("0", QSA_NO_WNDCLASS, "^HwndWrapper", "Microsoft Visual Studio( \(Administrator\))*$", "VS2010_or_above")
}


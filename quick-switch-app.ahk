
AUTOEXEC_quick_switch_app: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

global gtc_last_letter := 0 ; Last letter GetTickCount()
global g_last_letter := "" 
global g_qsa_grace_ticks := 500 ; millisec

global g_msec_dither_threshold := 90

; global PREFIX_REGEX = REGEX_ ; memo: This is wrong, function body will not see this global
global PREFIX_REGEX := "REGEX_" ; const // No longer needed.

global QSA_NO_SUFFIXKEY := ""
global QSA_NO_WNDCLASS := ""
global QSA_NO_WNDCLS_REGEX := ""
global qsa_dbgfile := "qsa_dbgfile.txt"

QSA_InitHotkeys()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Hook "common" keys to get their last press tick(in gtc_last_letter)
QSA_RecordLastLetterTick(now_key)
{
	now_tick := A_TickCount

;	dev_TooltipAutoClear("now:" . now_key . " // last: " . g_last_letter )
	if(now_key==g_last_letter)
	{
		msec_diff := now_tick-gtc_last_letter
;		if(msec_diff <= g_msec_dither_threshold)
;		{
;			dev_TooltipAutoClear("AHK: Dither key detected: " . now_key . " (" . msec_diff  . "ms)", 5300)
;			Am_PlaySound("ding.wav")
;		}
	}

	gtc_last_letter := now_tick
	g_last_letter := now_key
	
;	Send {Blind}%now_key%
}
QSA_RecordTick_InitHotkeys()
{
	static init_done := false
	if init_done
		return
	init_done := true

	commonkeys = abcdefghijklmnopqrstuvwxyz%A_Space%1234567890
	Loop, parse, commonkeys
	{
		DefineHotkey("~$" . A_LoopField , "QSA_RecordLastLetterTick", A_LoopField)
			; This comon-key hooking looks something brutal and exclusive. 
			; Hope others don't do the same thing.
	}
}

QSA_IsFastTyping(suffixkey)
{
	; Note: I just can't implement it with A_TimeIdlePhysical, because it will always be 0
	; when QSA_IsFastTyping() is executing. That's true because user did really just pressed a key
	; to trigger this.

	if(StrLen(suffixkey)!=1) ; suffixkey=="F1" etc
	{
		return false
	}

	timegap := A_TickCount - gtc_last_letter
	;tooltip, prior=%A_PriorKey% / prioHot=%A_PriorHotKey% / timegap=%timegap%
	if (timegap<g_qsa_grace_ticks)
	{
		Send %suffixkey% ;seem no need of {Blind}
		gtc_last_letter := A_TickCount
		return true
		; Side effect here: If you press a second key while CapsLock is still holding down,
		; that second key may (sometimes) not be in desired case. 
	}
	else 
		return false
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

AddHwndToWingroup(hwnd, groupname, actcount)
{
	; This functions remembers which hwnd(s) are in which groupname to avoid add it twice,
	; duplicate adding causes AHK's internal hwnd Z order to change, which causes 
	; ``GroupActivate, groupname, R``'s R feature to lose.
	
	static s_groupdict := {} ; associative array, groupname as key, python idiom
	
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
	if mod(actcount, 100)==0 ; actcount is increased by caller
	{
		for index, hwnd in s_groupdict[groupname] {
			if not WinExist("ahk_id " . hwnd) {
;				msgbox, AddHwndToWingroup() will clear hwnd %hwnd%
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
	; the most recently used one; in order to swtich between two or more of such windows, 
	; use MyActivateWindowClasses instead. Of course, MyActivateSingleWindow and MyActivateWindowClasses
	; can be used at the same time for the same winclass.

	if QSA_IsFastTyping(suffixkey)
		return

	WinActivate, ahk_class %winclass%
	WinWaitActive, ahk_class %winclass%, , 0.5
	If ErrorLevel 
	{
		MsgBox, Cannot find a window of %appdesc%
		return
	}
	MouseMoveInActiveWindow(0.5, 0.5)
}

MyActivateGroup(suffixkey, groupname, winclass, wincls_regex, title_regex, appdesc)
{
	; All winclass, wincls_regex and title_regex should be matched(unless empty) to make activation.
	
	static s_actcount := 0
	s_actcount += 1
	
	if(title_regex=="") 
	{
		; Withouth this: when winclass and title_regex are both null, and there is only one matched window
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
				AddHwndToWingroup(hwnd, groupname, s_actcount)
		}
	}
	else 
	{
		GroupAdd, %groupname%, ahk_class %winclass%
	}
	
	GroupActivate, %groupname%, R
		; Note: If only one target window exists and already in foreground, ErrorLevel will assert.

	if(ErrorLevel) ; check for false ErrorLevel
	{
		ok := false
		if(title_regex)
		{
			WinGetActiveTitle, title
			if (title ~= title_regex) ; regex comapre
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
			MsgBox, 0x30, , Cannot find any window of %appdesc% 
			return
		}
	}
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
	DefineHotkey("CapsLock & " . suffixkey, "MyActivateSingleWindow", suffixkey, winclass, appdesc)
}

QSA_DefineActivateGroup_Caps(suffixkey, winclass, appdesc)
{
	; Auto generate a group-name for GroupActivate (just prepend "group_"). 
	; Same winclass strings will result in same group-name.
	
	groupname := "groupWINCLASS_" . QSA_make_group_name(winclass)
	; GroupAdd, %groupname%, ahk_class %winclass%
		; Note: GroupAdd is postponed to MyActivateGroup.
	
	DefineHotkey("CapsLock & " . suffixkey, "MyActivateGroup", suffixkey, groupname, winclass, QSA_NO_WNDCLS_REGEX, "", appdesc)
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
		; Note: GroupAdd is postponed to the moment the hot key is pressed,
		; because we intend the regex title-match behavior to take effect just at the time we fire the hotkey.
	DefineHotkey(hotkey, "MyActivateGroup", suffixkey, groupname, winclass, wincls_regex, title_regex, appdesc)
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


QSA_InitHotkeys()
{
	QSA_RecordTick_InitHotkeys()
	
	QSA_DefineActivateGroup_Caps("/", "Notepad", "Notepad")
;	QSA_DefineActivateGroup_Caps("1", "Chrome_WidgetWin_1", "Chrome")
;	[2018-07-25] I have to use this bcz Skype 8.x UI is using the Chromium framework.
	;QSA_DefineActivateGroupFlex_Caps("1", "Chrome_WidgetWin_1", QSA_NO_WNDCLS_REGEX, "^(?!Skype).*", "Chrome")
	QSA_DefineActivateGroupFlex_Caps("1", "Chrome_WidgetWin_1", QSA_NO_WNDCLS_REGEX, "(Google Chrome|Comodo Dragon)$", "Google Chrome")
	
	QSA_DefineActivateGroupFlex_Caps("2", "MozillaWindowClass", QSA_NO_WNDCLS_REGEX, "(Firefox|Waterfox)", "Firefox or Waterfox")
	;QSA_DefineActivateGroup_Caps("2", "MozillaWindowClass", "Firefox") // would share with Active-state Komodo 7
	
	QSA_DefineActivateGroup_Caps("d", "ConsoleWindowClass", "CMD")
	QSA_DefineActivateGroup_Caps("q", "TXGuiFoundation", "QQ")
	QSA_DefineActivateGroup_Caps("h", "HH Parent", "CHM viewer")

;	QSA_DefineActivateSingle_Caps("m", "ENMainFrame", "Evernote") ; // [2017-11-18] moved to evrnote.ahk
;	QSA_DefineActivateGroup_Caps("n", "ENSingleNoteView", "Evernote Single-note")
	
	QSA_DefineActivateGroup_Caps("v", "VMUIFrame", "VMware Workstation")
		; Note: On activated, the VM may or may not grabs input immediately, which depends on 
		; whether you have used Ctrl+Alt to release control from the VM.
	QSA_DefineActivateGroupFlex_Caps("b", QSA_NO_WNDCLASS, QSA_NO_WNDCLS_REGEX, "VirtualBox Manager$", "VirtualBox Manager") ; virtualbox 6

	QSA_DefineActivateGroup_Caps("w", "CabinetWClass", "Windows Explorer")
	QSA_DefineActivateGroup_Caps("e", "EmEditorMainFrame3", "EmEditor")
	QSA_DefineActivateGroup_Caps("f", "classFoxitReader", "Foxit Reader")
	QSA_DefineActivateGroup_Caps("c", "VirtualConsoleClass", "ConEmu")
	QSA_DefineActivateGroup_Caps("p", "PuTTY", "PuTTY")

	QSA_DefineActivateGroupFlex_Caps("j", QSA_NO_WNDCLASS, "HyperSnap (7|8) Window Class",  "", "Hypersnap 7 or 8")

	QSA_DefineActivateGroupFlex_Caps("6", QSA_NO_WNDCLASS, "^Afx", "Microsoft Visual C\+\+", "The Visual C++ 6 IDE")
		; VC6 winclass is like Afx:400000:8:10009:0:3ab31345
		; Sigh, with 1.1.19.02, MRU behavior is broken with this regex mode
		; http://superuser.com/questions/876491/autohotkey-groupactivate-mru-behavior-discrepancy-any-way-to-fix

     ; Visual Studio 2008:
     ;QSA_DefineActivateGroupFlex("AppsKey & 8", QSA_NO_SUFFIXKEY, "wndclass_desked_gsk", QSA_NO_WNDCLS_REGEX, "^Microsoft Visual Studio", "VS2008 IDE")
     ; -- AppsKey & 8
     ; or
     ;QSA_DefineActivateGroupFlex_Caps("8", "wndclass_desked_gsk", QSA_NO_WNDCLS_REGEX, "^Microsoft Visual Studio", "VS2008 IDE")
     ; -- CapsLock & 8

	; Visual Studio VS2010+
	QSA_DefineActivateGroupFlex_Caps("0", QSA_NO_WNDCLASS, "^HwndWrapper", "Microsoft Visual Studio( \(Administrator\))*$", "VS2010_or_above")

	; MS Help Viewer 2.x
	QSA_DefineActivateGroupFlex_Caps("-", QSA_NO_WNDCLASS, "^HwndWrapper\[HlpViewer", "", "MS Help Viewer 2.x")
	
	; Visual Studio Code (2018)
	QSA_DefineActivateGroupFlex_Caps("9", "Chrome_WidgetWin_1", QSA_NO_WNDCLS_REGEX, "Visual Studio Code$", "Visual Studio Code")
	
	; Python IDLE shell
	QSA_DefineActivateGroupFlex_Caps("y", "TkTopLevel", QSA_NO_WNDCLS_REGEX, "^\*?Python.+Shell", "Python IDLE shell window")
	
	; Navicat
	QSA_DefineActivateGroup_Caps("i", "TNavicatMainForm", "Navicat database manager")
	
	;QSA_DefineActivateGroupFlex_Caps("-", QSA_NO_WNDCLASS, "^HwndWrapper", "Microsoft Help Viewer", "MS Help Viewer 1.x/2.x") //VS2010 hlpviewer 1.x
}


; Bind Win+1, Win+2 ... for WinXP, 2003 (example)
#If IsWin5x()

#1:: WinActivate, ahk_class CalcFrame
;#2:: WinActivate, ahk_class CalcFrame
;#3:: WinActivate, ahk_class CalcFrame

#If ; IsWin5x()

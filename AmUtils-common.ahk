; AmUtils-common.ahk, part of AmHotkey suite.
;
; This ahk is not to be run standalone, it is to be #include-d as AHK function library.
;


#Include %A_LineFile%\..\AmUtils-const.ahk


dev_assert(torf)
{
	if(!torf)
	{
		dev_MsgBoxError(dev_getCallStack(), "AHK Assertion Fail! Stacktrace >>>")
	}
}

dev_getCallStack(deepness = 20, is_print_code = true)
{
	; Call this function to get current callstack.
	; Usage: If we want to report an error to user(MsgBox etc), showing a full callstack helps greatly.
	;
	; Thanks to: https://www.autohotkey.com/board/topic/76062-ahk-l-how-to-get-callstack-solution/
	
	lv_first_print := -1
	
	loop % deepness
	{
		lvl := -1 - deepness + A_Index
		oEx := Exception("", lvl)
		oExPrev := Exception("", lvl - 1)
		FileReadLine, line, % oEx.file, % oEx.line
		if(oEx.What = lvl)
			continue
			
		if(lv_first_print==-1) 
			lv_first_print := A_Index
		
		stack .= (stack ? "`n" : "") . Format("#{1}£º ",A_Index-lv_first_print+1) . "File '" oEx.file "', Line " oEx.line (oExPrev.What = lvl-1 ? "" : ", in " oExPrev.What) (is_print_code ? ":`n" line : "") "`n"
	}
	return stack
}


dev_EnvGet(varname)
{
	; Get environment variable value.
	EnvGet, val, %varname%
	return val
}

dev_str2num(str)
{
	; Convert "012" to 12, so that it can be used as array index.
	; Tip from Lexikos: https://www.autohotkey.com/board/topic/21271-converting-string-to-number/
	;
	; [2022-12-07] Memo: Convert "90%" to 90 .
	
	num := "0" . str
	num += 0
	return num
}

;dev_Str2Num(str) // chj
;{
;	; like ANSI C atoi(str),  str="90%", will return 90. 
;	foundpos := RegExMatch(str, "^([0-9]+)", subpat)
;	if(foundpos==1)
;		return subpat1
;	else
;		return 0
;}
;


dev_MsgBoxInfo(text, wintitle:="") ; with a blue (i) icon
{
	if(!wintitle)
		wintitle := "AHK Info"

	MsgBox, 64, % wintitle, % text
}

dev_MsgBoxWarning(text, wintitle:="") ; with a yellow (!) icon
{
	if(!wintitle)
		wintitle := "AHK Warning"

	MsgBox, 48, % wintitle, % text
}

dev_MsgBoxError(text, wintitle:="") ; with a red (x) icon
{
	if(!wintitle)
		wintitle := "AHK Error"

	MsgBox, 16, % wintitle, % text
}

dev_MsgBoxYesNo(text, default_yes:=true, icon:=64)
{
	; hope to display the message box at the center of parent_winid window...(pending)

	opt := icon + Amhk.mbopt_YesNo + (default_yes ? 0 : Amhk.mbopt_2nddefault)
	MsgBox, % opt, , %text%
		; [2016-02-09] I can't use ``%opt%`` for ``% opt`` here(dialogbox would display 260), don't know why.
	
	IfMsgBox, Yes
		return true
	Else
		return false
}

dev_MsgBoxYesNo_Warning(text, default_yes:=true)
{
	return dev_MsgBoxYesNo(text, default_yes, Amhk.mbopt_IconExclamation)
}


dev_SendMessage(hwnd, wm_xxx, wparam, lparam)
{
    SendMessage, % wm_xxx, % wparam, % lparam, , ahk_id %hwnd%
}

dev_PostMessage(hwnd, wm_xxx, wparam, lparam)
{
    PostMessage, % wm_xxx, % wparam, % lparam, , ahk_id %hwnd%
}


dev_IniRead(inifilepath, section, key, default_val:="")
{
	IniRead, outvar, % inifilepath, % section, % key, % default_val
	return outvar
}

dev_IniWrite(inifilepath, section, key, val)
{
	IniWrite, % val, % inifilepath, % section, % key
	return ErrorLevel ? false : true
}


dev_CreateDirIfNotExist(dirpath)
{
	; If dirpath already exists and is a directory or a junction (not file),
	; it will return true(=succ).
	try {
		FileCreateDir, % dirpath
	} catch e {
		return false
	}
	return true
}

dev_OnMessage_Register(wm_xxx, str_funcname)
{
	s := str_funcname
	dev_assert(s) ; If user pass in function name without double-quotes, this will fail
	
	OnMessage(wm_xxx, Func(str_funcname))
}

dev_OnMessage_Unregister(wm_xxx, str_funcname)
{
	s := str_funcname
	dev_assert(s) ; If user pass in function name without double-quotes, this will fail

	OnMessage(wm_xxx, Func(str_funcname), 0)
}

dev_WinMoveHwnd(hwnd, x:="", y:="", w:="", h="")
{
	wold := "bad"

	WinGetPos, xold,yold,wold,hold, ahk_id %hwnd%
	
	if(wold=="bad")
		return

	if(x=="")
		x := xold
	if(y=="")
		y := yold
	if(w=="")
		w := wold
	if(h=="")
		h := hold
	
	WinMove, ahk_id %hwnd%, , % x, % y, % w, % h
}

dev_TooltipAutoClear(text, keep_millisec:=2000)
{
	tooltip, %text%
	SetTimer, lb_TooltipAutoClear, % 0-keep_millisec
	return
	
lb_TooltipAutoClear:
	tooltip
	return
}

dev_TooltipDelayHide(keep_millisec:=2000)
{
	; Hide the tooltip after some millisec.
	SetTimer, lb_TooltipDelayHide, % 0-keep_millisec
	return 
	
lb_TooltipDelayHide:
	tooltip
	return
}

dev_WriteFile(filepath, text, is_append)
{
	; memo: Use "`n" in text to represent a new line.
	;
	if(not filepath)
		return
	
	if(not is_append)
		FileDelete, %filepath%
	
	FileAppend, %text%, %filepath%
}

dev_WriteLogFile(filepath, text, is_append:=true)
{
	dev_WriteFile(filepath, text, is_append)
}

dev_WriteWholeFile(filepath, text)
{
	dev_WriteFile(filepath, text, false)
}


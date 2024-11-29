; Amhk-common.ahk, part of AmHotkey suite.
;
; This ahk is not to be run standalone, it is to be #include-d as AHK function library.
;

#Include %A_LineFile%\..\Amhk-globals.ahk
#Include %A_LineFile%\..\win32-const.ahk

dev_nop()
{
	; No operation
}

dev_true()
{
	return true
}

dev_false()
{
	return false
}

dev_assert(success_condition, msg_on_error:="", is_attach_code:=true)
{
	; msg_on_error is the text message you want to say to user, in case success_condition is not met.

	if(success_condition)
		return
	
	fullmsg := ""
	
	if(msg_on_error)
	{
		fullmsg := msg_on_error "`r`n`r`n"
			. "Stacktrace below: `r`n`r`n"
	}
	
	fullmsg .= dev_getCallStack(20, is_attach_code)
	
	dev_MsgBoxError(fullmsg, "AHK Assertion Fail!")
	
	throw Exception(fullmsg, -1) ; Chj 2024.04.17
}

dev_getCallStack(deepness:=20, is_print_code:=true)
{
	; Call this function to get current callstack.
	; Usage: If we want to report an error to user(MsgBox etc), showing a full callstack helps greatly.
	;
	; Thanks to: https://www.autohotkey.com/board/topic/76062-ahk-l-how-to-get-callstack-solution/
	
	lv_first_print := -1
	stack := ""
	stack_prev := ""
	
	loop % deepness
	{
		lvl := -1 - deepness + A_Index
		oEx := Exception("", lvl)
		oExPrev := Exception("", lvl - 1)
		
		if(is_print_code)
			FileReadLine, linetext, % oEx.file, % oEx.line
		
		if(oEx.What = lvl)
			continue
			
		if(lv_first_print==-1) 
			lv_first_print := A_Index
		
		stack_prev := stack
		stack .= (stack ? "`n" : "") . Format("[#{1}] ", A_Index-lv_first_print+1) . "File '" oEx.file "', Line " oEx.line (oExPrev.What = lvl-1 ? "" : ", in " oExPrev.What "()") (is_print_code ? ":`n" linetext : "") "`n"
	}
	
	return stack_prev
}

dev_FileRead_NthLine(file, line)
{
	; Read n-th line of a file
	FileReadLine, linetext, % file, % line
	return linetext
}

dev_fileline_syse(sys_e)
{
	; sys_e should be a AHK engine generated Exception object.
	; For example:
	;
;	try {
;		GuiControl, , % "ahk_id0123456", "user-text"
;	}
;	catch e {
;		dev_MsgBoxWarning( dev_fileline_syse(e) )
;	}
	
	; produces message box test:
	
;	Message: 1
;	File 'D:\gitw\AmHotkey\customize.ahk', Line 766: 
;			GuiControl, , % "ahk_id0123456", "user-text"
;
; [2024-06-06] Error case 2: Pass an invalid function to SetTimer .

	msg := Format("Message: {}`nFile '{}', Line {}: `n{}"
		, sys_e.Message
		, sys_e.File, sys_e.Line
		, dev_FileRead_NthLine(sys_e.File, sys_e.Line))
	return msg
}

dev_rethrow_syse(sys_e, new_msg)
{
	new_e := Exception(new_msg)
	new_e.Line := sys_e.Line
	
	supp := Format("[##] File '{}', Line {}: `n{}"
		, sys_e.File, sys_e.Line, dev_FileRead_NthLine(sys_e.File, sys_e.Line))
	
	AmDbg0("Got system exception:`n" dev_getCallStack() "`n" supp)
	
	throw new_e
}

dev_throw(errmsg)
{
	; throw with stacktrace info
	; better than `throw Exception(errmsg)`
	
	throw Exception(errmsg "`n`n" dev_getCallStack())
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

dev_which_functype(funcware)
{
	; [2024-04-17] A gross triage of three different function(callable) types.
	; If the input funcware is really a legal callable of one of the three type,
	; dev_which_functype() should give correct result. 
	; But if user passes in a casual object, this function may return 
	; false positive. For example, a dict or array object will produce "fbobj".
	;
	; Test this function with test_which_functype()

	if(dev_IsFuncWord(funcware))
	{	
		; funcware can be "myfunc" or "MyClass.myfunc" .
		; but we cannot tell whether the function by that name really exist
		return "fnname" 
	}
	else if(funcware.name)
	{
		return "fnobj"
	}
	else if(funcware)
	{
		; Consider it a BoundFunc object
		return "fbobj"
	}
	else
		return ""
}
/*
test_which_functype()
{
    fnstr := "fnhello"
    fnobjA := Func("fnhello")
    fnobjB := fnobjA.bind("0th")
    fnobjC := fnobjB
    
    s := dev_which_functype(fnstr)
    a := dev_which_functype(fnobjA)
    b := dev_which_functype(fnobjB)
    c := dev_which_functype(fnobjC)
    n := dev_which_functype(Func(fnobjA))
    nil := ""
    
    AmDbg0(Format("{} | {} | {} | {} | [{},{}]", s, a, b, c, n, nil))
    ; Answer: fnname | fnobj | fbobj | fbobj | [,]
}
}
*/

dev_make_fnobj(fni, args*) ; old name
{
	return make_solo_callable(fni, args*)
}

make_solo_callable(funcware, args*)
{
	; funcware can be any of three types of callable in AHK.
	; This function binds args* into funcware to make(return) a new 
	; callable object, so that you can use that callable in 
	; SetTimer, Menu, etc.
	;
	; One exception: if funcware is already a BoundFunc-object, `args` cannot be further bounded.

	fnout := funcware
	
	ft := dev_which_functype(funcware)

	if(ft=="fnname")
	{
		fnout := Func(fnout)
		
		if(args.Length()>0)
		{
			fnout := fnout.Bind(args*) 
			; -- now fnout becomes a BoundFunc, user cannot apply further .Bind() on it.
		}
		else 
		{
			; Do not apply .Bind(), so that fnout still has a future chance to .Bind().
		}
	}
	else if(ft=="fnobj")
	{
		if(args.Length()>0)
			fnout := fnout.Bind(args*)
	}
	else if(ft=="fbobj")
	{
		if(args.Length()>0)
		{
			dev_assert(0, "When funcware is already a BoundFunc-object, you MUST NOT pass args* params.")
			fnout := ""
		}
	}
	else
	{
		dev_assert(0, "funcware parameter() invalid, not a function or callable. Your funcware's value:`n`n" funcware)
		fnout := ""
	}

	return fnout ; User can then write %fnout%(...) to call the function.
}


dev_GetActiveHwnd()
{
	WinGet, Awinid, ID, A
	return Awinid
}

dev_WinGet_Hwnd(wintitle, wintext:="")
{
	WinGet, winid, ID, % wintitle, % wintext
	return winid
}

dev_WinClose(wintitle, timeout_millisec:=0)
{
	WinClose, % wintitle
	
	if(timeout_millisec==0)
		return true
	
	return dev_WinWaitClose(wintitle, timeout_millisec)
}

dev_WinWaitClose(wintitle, timeout_millisec:=-1)
{
	; wintitle can be "ahk_id 0xC5134C" etc
	
	if(timeout_millisec<0)
		timeout_sec := "" ; to wait indefinitely
	else if(timeout_millisec==0)
		return true
	else
		timeout_sec := timeout_millisec/1000

	WinWaitClose, % wintitle, , % timeout_sec
	return ErrorLevel==0 ? true : false
}

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

dev_MsgBoxYesNo_title(title, text, default_yes:=true, icon:=64)
{
	; hope to display the message box at the center of parent_winid window...(pending)

	opt := icon + Amhk.mbopt_YesNo + (default_yes ? 0 : Amhk.mbopt_2nddefault)
	MsgBox, % opt, % title, %text%
		; [2016-02-09] I can't use ``%opt%`` for ``% opt`` here(dialogbox would display 260), don't know why.
	
	IfMsgBox, Yes
		return true
	Else
		return false
}

dev_MsgBoxYesNo(text, default_yes:=true, icon:=64)
{
	return dev_MsgBoxYesNo_title("", text, default_yes, icon)
}

dev_MsgBoxYesNo_Warning(text, default_yes:=true)
{
	return dev_MsgBoxYesNo(text, default_yes, Amhk.mbopt_IconExclamation)
}


dev_SendMessage(hwnd, wm_xxx, wparam, lparam)
{
    SendMessage, % wm_xxx, % wparam, % lparam, , ahk_id %hwnd%
    
    if(ErrorLevel=="FAIL")
    	return ""
    else
    	return ErrorLevel
}

dev_PostMessage(hwnd, wm_xxx, wparam, lparam)
{
    PostMessage, % wm_xxx, % wparam, % lparam, , ahk_id %hwnd%
}

dev_IniReadSection(inifilepath, section)
{
	IniRead, outvar, % inifilepath, % section
	lines := StrSplit(outvar, "`n")
	return lines ; an array of text, each element is one line 
}

dev_IniReadSectionIntoDict(inifilepath, section)
{
	dict := {}
	arlinetext := dev_IniReadSection(inifilepath, section)
	
	for index,itemline in arlinetext
	{
		key_value := StrSplit(itemline, "=")
		key := key_value[1]
		value := key_value[2]
		
		dict[key] := value
	}
	return dict
}

dev_IniRead(inifilepath, section, key:="", default_val:="")
{
	; key=="" to return whole section content as a single string(separated by \n)

	default_magic := "20221219.dev_IniRead.default"
	if(default_val=="")
		default_val := default_magic

	IniRead, outvar, % inifilepath, % section, % key, % default_val
	
	if(outvar==default_magic)
		return "" ; User just want a empty string as default
	else
		return outvar
	
}

dev_IniReadVal(inifilepath, section, key:="", default_val:=0)
{
	str := dev_IniRead(inifilepath, section, key, default_val)
	return dev_str2num(str)
}

dev_IniWrite(inifilepath, section, key, val)
{
	try {
		IniWrite, % val, % inifilepath, % section, % key
	}
	catch e {
		dev_rethrow_syse(e, Format("Error writing file: ""{}""", inifilepath))
	}
	return true
}

dev_IniWriteSection(inifilepath, section, items)
{
	; note: would overwrite whole section.
	try {
		IniWrite, % items, % inifilepath, % section
	}
	catch e {
		dev_rethrow_syse(e, Format("Error writing file: ""{}""", inifilepath))
	}
	return true
}

dev_IniWriteSectionVA(inifilepath, section, items*)
{
	; Usage example:
	; dev_IniWriteSectionVA("test1.ini", "section1", "key1=val1", "key2=val2")
	
	linestext := ""
	for index,item in items
	{
		linestext .= item "`n" ; should not use "`r`n", AHK does it for us.
	}
	return dev_IniWriteSection(inifilepath, section, linestext)
}

dev_OnMessage_Register(wm_xxx, str_funcname)
{
	s := str_funcname
	dev_assert(s) ; If user pass in function name without double-quotes, this will fail
	
	OnMessage(wm_xxx, Func(str_funcname)) ; todo: better use dev_make_fnobj()
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
	
	if(x!=xold || y!=yold || w!=wold || h!=hold)
	{
		; [2024-05-02] A redundant WinMove may cost 100ms or more.
		WinMove, ahk_id %hwnd%, , % x, % y, % w, % h
	}
}

dev_WinGetPos(wintitle)
{
	WinGet, hwnd, ID, % wintitle
	
	if(!hwnd)
		return ""
	
	return dev_WinGetPos_byHwnd(hwnd)
}

dev_WinGetPos_byHwnd(hwnd)
{
	; Note the difference to Autohotkey's WinGet command.
	;
	; If hwnd does NOT exist, return null.
	; If hwnd is a hidden window, return a dict of {hidden:true} .
	; If hwnd is not-hidden, return a dict of {.x .y .x_ .y_ .w .h} .

	isok := DllCall("IsWindow", "Ptr", hwnd)
	if(!isok)
		return ""

	WinGetPos, x,y,w,h, % "ahk_id " hwnd

	pos := {x:x, y:y, w:w, h:h, x_:x+w, y_:y+h} 
	
	WinGet, outvar, MinMax, % "ahk_id " hwnd

	if(outvar==1)
		pos.maximized := true
	if(outvar==-1)
		pos.minimized := true

	; Check visible at last, so that if the caller turns on DetectHiddenWindows, x/y will be returned.
	; If `DetectHiddenWindows Off`(the default behavior), AHK engine will not tell us x/y info.
	
	visible := DllCall("IsWindowVisible", "Ptr", hwnd)
	if(!visible)
	{
		; .x .y .w .h are probably empty value
		pos.hidden := true
	}
	
	return pos
}

dev_Tooltip(text)
{
	tooltip, % text
}

dev_TooltipAutoClear(text, keep_millisec:=2000, x:="", y:="", which:="")
{
	tooltip, % text, % x, % y, % which
	
	if(keep_millisec>0) {
		dev_StartTimerOnce("dev_TooltipClear", keep_millisec)
	}
}

dev_TooltipClear()
{
	tooltip
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


dev_TooltipDisableCloseWindow(msg_prefix)
{
	; In many applications, Ctrl+W etc would close current window/tab, and I hate it. 
	; So call this function to hint that.
	; msg_prefix is some hotkey names like "Ctrl+W" or "Ctrl+Shift+W".
	dev_TooltipAutoClear(msg_prefix . " closing window/tab is disabled by AmHotkey.")
}



dev_FileDelete(filepath)
{
	if(!FileExist(filepath))
		return true

	FileDelete, % filepath
	return ErrorLevel ? false : true
}

dev_FileRemoveDir(dirpath, is_recurse)
{
	FileRemoveDir, % dirpath, % (is_recurse?1:0)
	if(ErrorLevel)
		return false
	else
		return true
}

dev_MoveFile(oldpath, newpath, is_overwrite:=false) ; rename
{
	FileMove, % oldpath, % newpath, % is_overwrite
}

dev_CopyFile(oldpath, newpath, is_overwrite:=false)
{
	FileCopy, % oldpath, % newpath, % is_overwrite
}


dev_FileRead(filepath)
{
	FileRead, outvar, % filepath
	return outvar
}

dev_ReadFile(filepath)
{
	return dev_FileRead(filepath)
}

dev_FileReadLine(filepath, idxline)
{
	FileReadLine, linetext, % filepath, % idxline
	return linetext
}


dev_WriteFile(filepath, text, is_append, encoding:="")
{
	; memo: Use "`n" in text to represent a new line.
	;
	; [2024-04-14] Comment on Autohotkey 1.1.32,
	; FileAppend can throw exception when writing file fail, e.g.,
	; when filepath is a directory.
	; But AHK engine has wacky behavior:
	; - If User has set up try/catch outward, user's code will catch that exception.
	; - If User has not set up try/catch, then the exception is silently discarded.
	; So, I need to rethrow exception here. With this rethrow code, even if user 
	; has not set up try/catch, AHK engine will still pop up an error dialogbox
	; telling user an exception has occurred -- that's the behavior I want.
	
	; encoding: "UTF-8", "UTF8-RAW", "UTF-16", "UTF-16-RAW", "CP936" etc
	
	if(encoding=="utf8" or encoding="UTF8")
		encoding := "UTF-8"
	else if(encoding=="utf8raw" or encoding="UTF8RAW")
		encoding := "UTF-8-RAW"
	
	if(not filepath)
		return
	
	try {
		if((not is_append) and FileExist(filepath))
			FileDelete, %filepath%

		FileAppend, %text%, %filepath%, %encoding%
	}
	catch e {
		emsg := Format("Error {} file: ""{}"""
			, e.What=="FileDelete" ? "deleting" : "writing"
			, filepath)
		dev_rethrow_syse(e, emsg)
	}
}

dev_WriteLogFile(filepath, text, is_append:=true, encoding:="")
{
	dev_WriteFile(filepath, text, is_append, encoding)
}

dev_WriteWholeFile(filepath, text, encoding:="")
{
	dev_WriteFile(filepath, text, false, encoding)
}


dev_WriteWholeFile_rawstring(filepath, text, codepage:=65001) ; 65001 is CP_UTF8
{
	; raw means `n will not be replaced with `r`n 
	
	slen := StrLen(text)
	slen_3x := slen * 3
	VarSetCapacity(astr_out, slen_3x)
	
	obytes := DllCall("WideCharToMultiByte"
		, "uint", codepage
		, "uint", 0 ; dwFlags
		, "str", text ; lpWideCharStr :input unicode string
		, "int", -1   ; cchWideChar: unicode string is NUL-terminated
		, "Ptr", &astr_out
		, "int", slen_3x
		, "Ptr", 0
		, "Ptr", 0)
	
;	AmDbg0(Format("WideCharToMultiByte() input chars {}, output bytes {}", slen, obytes))
	if(obytes>=1)
		obytes -= 1 ; remove trailing NUL
	
	file := FileOpen(filepath, "w")
	if(file)
	{
		nwr := file.RawWrite(&astr_out, obytes)
		file.Close()
		
;		AmDbg0(Format("file.RawWrite({}, {}) returns {}", text, slen, nwr))

		return nwr
	}
	else
	{
		return 0
	}
}

dev_Copy1File(srcfilepath, dstfilepath, is_overwrite:=false)
{
	dev_assert(InStr(srcfilepath, "*")==0)
	
	srcfileattr := FileExist(srcfilepath)

	if(srcfileattr=="")
		return false ; srcfile not exist
	
	if(InStr(srcfileattr, "D")>0)
		return false ; src must not be a folder
	
	if(InStr(FileExist(dstfilepath), "D")>0) 
		return false ; dst must not be a folder
	
	dstdir := dev_SplitPath(dstfilepath)
	dev_CreateDirIfNotExist(dstdir)
	
	FileCopy, % srcfilepath, % dstfilepath, % (is_overwrite?"1":"")
	
	if(ErrorLevel)
		return false
	else
		return true
}

dev_ReadFileLines(filepath, maxlines:=-1)
{
	; Read all lines from filepath, return a string array.
	lines := []
	count := 0
	
	if(not dev_IsDiskFile(filepath))
		return ""
	
	Loop, read, % filepath
	{
		if(maxlines:=-1 or count<maxlines)
		{
			lines.Push(A_LoopReadLine)
		}
		count++
	}
	
	; If the file is 0 byte, lines will be an empty array, which is still a true condition.
	return lines
}



dev_GetParentDir(path)
{
	dev_assert(InStr(path, "\")>0)
	
	foundpos := RegExMatch(path, "^(.+)\\.+$", subpat)
	
	return subpat1
}

dev_IsDiskFile(filepath)
{
	attr := FileExist(filepath)
	if( InStr(attr, "A") || InStr(attr, "N") ) ; but never see "N" yet
		return true
	else
		return false
}

dev_IsDiskFolder(dirpath)
{
	attr := FileExist(dirpath)
	if( InStr(attr, "D") )
		return true
	else
		return false
}

dev_CreateDirIfNotExist(dirpath) ; makedir, mkdir
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


dev_rmdir(dirpath)
{
	FileRemoveDir, % dirpath, 1
	
	if(FileExist(dirpath))
		return false
	else
		return true
}

dev_InterpretHotkeySpec(spec)
{
	; spec is like "^#c", will return "Ctrl+Win+c"
	

	if(InStr(spec,"^") || InStr(spec,"#") || InStr(spec,"!"))
	{
		desc := ""
		if(InStr(spec,"^"))
			desc .= "Ctrl+"
		if(InStr(spec,"#"))
			desc .= "Win+"
		if(InStr(spec,"!"))
			desc .= "Alt+"
		
		desc .= LTrim(spec, "^#!")
		return desc
	}
	else
	{
		return spec
	}
}

dev_SplitPath(input, byref Filename:="")
{
	SplitPath, input, Filename, OutDir
	return OutDir
}

dev_SplitExtname(input, byref dot_ext:="")
{
	SplitPath, input, outname_nouse, OutDir, OutExt, OutNameNoExt
	dot_ext := "." OutExt
	if(OutDir)
		return Format("{}\{}", OutDir, OutNameNoExt) ; the stempath(no extname)
	else
		return OutNameNoExt
}

dev_AppendToStemname(input, stemname_suffix)
{
	stem := dev_SplitExtname(input, dot_ext)
	return stem . stemname_suffix . dot_ext
}

dev_StringUpper(s)
{
	StringUpper, s, s
	return s
}

dev_StringLower(s)
{
	StringLower, s, s
	return s
}

dev_StrIsEqualI(s1, s2) ; case insensitive compare (strcmpi)
{
	StringUpper, s1u, s1
	StringUpper, s2u, s2
	if(s1u==s2u)
		return true
	else
		return false
}

dev_stricmp(s1, s2)
{
	us1 := dev_StringUpper(s1)
	us2 := dev_StringUpper(s2)
	if(us1==us2)
		return 0
	else if(us1<us2)
		return -1
	else
		return 1
}

dev_IsSubStr(Haystack, Needle)
{
	foundpos := InStr(Haystack, Needle)
	return foundpos>0 ? true : false
}

StrIsStartsWith(str, prefix, anycase:=false)
{
	; Check if the string str starts with prefix
	
	if(anycase)
	{
		StringLower, str, str
		StringLower, prefix, prefix
	}
	
	pfxlen := strlen(prefix)
	if(pfxlen<=0)
		return false
	
	s1 := substr(str, 1, pfxlen)
	
	StringUpper, s1_u, s1
	StringUpper, s2_u, prefix
	
	if(s1_u==s2_u)
		return true
	else
		return false
}

StrIsEndsWith(str, suffix, anycase:=false)
{
	if(anycase)
	{
		StringLower, str, str
		StringLower, prefix, prefix
	}
	
	suffix_len := strlen(suffix)
	if(suffix_len==0)
		return false
	if(substr(str, 1-suffix_len)==suffix)
		return true
	else
		return false
}

dev_StripPrefix(str, prefix, is_case_sensitive:=false)
{
	if(StrIsStartsWith(str, prefix, is_case_sensitive))
		return SubStr(str, StrLen(prefix)+1)
	else
		return str
}

dev_StripSuffix(str, suffix, is_case_sensitive:=false)
{
	if(StrIsEndsWith(str, suffix, is_case_sensitive))
		return SubStr(str, 1, StrLen(str)-StrLen(suffix))
	else
		return str
}

dev_StripPrefixChars(str, pfxchars, is_case_sensitive:=false)
{
	; Alternative: stock function LTrim()

	Loop, % StrLen(str)
	{
		c := SubStr(str, 1, 1)
		if(InStr(pfxchars, c, is_case_sensitive))
			str := SubStr(str, 2)
		else
			break
	}
	return str
}

dev_StripSuffixChars(str, sfxchars, is_case_sensitive:=false)
{
	; Alternative: stock function RTrim()

	Loop, % StrLen(str)
	{
		c := SubStr(str, 0)
		if(InStr(sfxchars, c, is_case_sensitive))
			str := SubStr(str, 1, -1)
		else
			break
	}
	return str
}

dev_EscapeHtmlChars(text)
{
	text := StrReplace(text, "&", "&amp;")
	text := StrReplace(text, "<", "&lt;")
	text := StrReplace(text, ">", "&gt;")
	return text
}

dev_IsSameFiletime(file1, file2)
{
	FileGetTime, time1, % file1
	FileGetTime, time2, % file2
	
	if(time1 && time1==time2)
		return true
	else
		return false
}

dev_FileGetTime(filepath, whichtime:="M")
{
	; Note: AHK's FileGetTime may return a lagged timestamp, when the file is in use 
	; by another process. To workaround this, use win32_GetFileTime() .

	FileGetTime, outvar, % filepath, % whichtime
	return outvar ; return TS14 format
}

win32_ResetLastError()
{
	DllCall("SetLastError", "UInt", 0, "UInt")
}

win32_GetLastError()
{
	winerr := DllCall("GetLastError", "UInt")
	return winerr
}

win32_CreateFile_QueryOnly(filepath)
{
	dwDesiredAccess := 0 ; query only
	dwShareMode := 3 ; FILE_SHARE_READ(1), FILE_SHARE_WRITE(2)
	dwCreateFlag := 3 ; OPEN_EXISTING

	fh := DllCall("CreateFile"
		, "Str", filepath
		, "Int", dwDesiredAccess
		, "Int", dwShareMode
		, "Ptr", 0  ; no security attributes
		, "Int", dwCreateFlag
		, "Int", 0 ; overlapped flag
		, "Ptr", 0
		, "Ptr")
;	dev_MsgBoxInfo("fh = " fh)
	
	return fh
}

win32_CloseHandle(handle)
{
	DllCall("CloseHandle", "Ptr", handle)
}

win32_GetFileTime(filepath)
{
	; This function uses Win32 API GetFileTime() to retrieve real file-modification-time.
	; AHK's FileGetTime will probably report a lagged time, in case a file is opened by 
	; another process. For example, a running VM's .vmdk will be this case.
	
	fh := win32_CreateFile_QueryOnly(filepath)
	if((not fh) or fh==-1)
		return ""
	
	VarSetCapacity( ft_utc, 8, 0 )
	VarSetCapacity( ft_local, 8, 0 )
	succ := DllCall("GetFileTime"
		, "Ptr", fh
		, "Ptr", 0
		, "Ptr", 0
		, "Ptr", &ft_utc)
	
	win32_CloseHandle(fh)
	
	if(!succ)
		return ""
	
	DllCall("FileTimeToLocalFileTime"
		, "Ptr", &ft_utc
		, "Ptr", &ft_local)
	
	VarSetCapacity( st, 16, 0 )
	DllCall("FileTimeToSystemTime"
		, "Ptr", &ft_local
		, "Ptr", &st)
	
	year  := NumGet(st, 0, "UShort")
	month := NumGet(st, 2, "UShort")
	mday  := NumGet(st, 6, "UShort")
	hour  := NumGet(st, 8, "UShort")
	minute:= NumGet(st, 10, "UShort")
	second:= NumGet(st, 12, "UShort")
	
;	dev_MsgBoxInfo(Format("{}-{}-{} {}:{}:{}", year, month, mday, hour, minute, second))
	ts14 := Format("{:04d}{:02d}{:02d}{:02d}{:02d}{:02d}", year, month, mday, hour, minute, second)
	
	return ts14
}

dev_FileGetSize(filepath)
{
	FileGetSize, outlen, % filepath
	return outlen
}

dev_IsBinaryFile(filepath, bytes_to_check:=8192)
{
	; Note: UTF-16 text files will be considered as binary.
	; We only check for byte-value >=0 and <9 , so, text files encoded in MBCS(GBK etc)
	; will still be considered text. For a GBK file, there will be byte-value >=128.
	; Also, UTF-8 file with BOM will not be considered binary.

	FileGetSize, filelen, % filepath
	if ErrorLevel
		return false

	if(filelen==0)
		return true

	isbin := false ; assume false

	if(filelen<bytes_to_check)
		bytes_to_check := filelen

;	dev_WriteLogFile("binlog.txt", "Byte dump of " filepath "`n", false) ; debug

	file := FileOpen(filepath, "r", "UTF-8-RAW")
	if(!IsObject(file))
		return false
	
	; Seek to file start explicitly.
	; Withouth this, Autohotkey will skip BOM bytes for us, which is not desired.
	file.Pos := 0
	
	file.RawRead(buffer, bytes_to_check)
	
	Loop, % bytes_to_check
	{
		byteval := NumGet(buffer, A_Index-1, "UChar")
		
;		dev_WriteLogFile("binlog.txt", Format("{1:02X}`n", byteval)) ; debug
		
		if(byteval>=0 && byteval<9)
		{
			isbin := true
		}
	}
	
	file.Close()
	return isbin
}

dev_mino(args*)
{
	nargs := args.Length()
	
	dev_assert(nargs>1)
	
	valmin := args[1]
	posmin := 1
	
	for i,n in args
	{
		if(n < valmin) {
			valmin := n
			posmin := i
		}
	}
	
	return {idx:posmin, val:valmin}
}

dev_min(args*)
{
	ret := dev_mino(args*)
	return ret.val
}

dev_maxo(args*)
{
	nargs := args.Length()
	
	dev_assert(nargs>1)
	
	valmax := args[1]
	posmax := 1
	
	for i,n in args
	{
		if(n > valmax) {
			valmax := n
			posmax := i
		}
	}
	
	return {idx:posmax, val:valmax}
}

dev_max(args*)
{
	ret := dev_maxo(args*)
	return ret.val
}

dev_JoinStrings(ar_strings, join_with:="`n")
{
	; ar_strings is an array containing strings
	if(!IsObject(ar_strings))
		return ""
	
	ret := ""
	for index,value in ar_strings 
	{
		if(index==1)
			ret := value
		else
			ret := ret . join_with . value
	}
	return ret
}

dev_SplitStrings(bigstring, sep:="`n")
{
	if(sep=="`n")
		bigstring := dev_StrReplace_CRLF_to_LF(bigstring)

	ar_strings := []

	Loop, PARSE, % bigstring, % sep
	{
		ar_strings.Push(A_LoopField)
	}
	
	return ar_strings
}

dev_ParseLinesToArray(bigstring, sep:="`n") ; old name
{
	return dev_SplitStrings(bigstring, sep)
}


IsWinXP()
{
	return IsWin5x()
}

IsWin5x()
{
	if A_OSVersion in WIN_2003,WIN_XP,WIN_2000
	{
	    return true
	}
	else
	{
		return false
	}
}


dev_WaitUntilProcessExit(pid, timeout_millisec:=-1)
{
	waitmsec_start := A_TickCount
	Loop
	{
		if(!dev_IsProcessAlive(pid))
			return true
		
		if(timeout_millisec>0 && (A_TickCount-waitmsec_start)>timeout_millisec)
			return false ; timeout
		
		Sleep, 100
	}
}

dev_KillProcessByPid(pid, byref winerr:=0)
{
	hProcess := DllCall( "OpenProcess" 
	                    , "uint", 0x1    ; PROCESS_TERMINATE
	                    , "int", false 
	                    , "uint", pid ) 

	if(!hProcess) {
		winerr := DllCall("GetLastError")
;		Dbgwin_Output(Format("OpenProcess(pid={}) fail. WinErr={}", pid, winerr))
		return false
	}
	
	is_succ := DllCall("TerminateProcess", "Ptr",hProcess, "uint",444)
	if(!is_succ){
		winerr := DllCall("GetLastError")
;		Dbgwin_Output(Format("TerminateProcess(pid={}) fail. WinErr={}", pid, winerr))
	}
	
	DllCall("CloseHandle", "Ptr", hProcess)
	
	return is_succ
}

dev_GetParentHwnd(hwnd)
{
	hwndparent := DllCall("GetParent", "Ptr",hwnd)
	return hwndparent
}

dev_GetRootWindow(hwnd)
{
	GA_ROOT := 2
	hwndRoot := DllCall("GetAncestor", "Ptr",hwnd, "int", GA_ROOT)
	return hwndRoot
}

dev_IsToplevelWindow(hwnd)
{
	hwndRoot := dev_GetRootWindow(hwnd)
	return hwndRoot==hwnd ? true : false
}

dev_IsOneWord(s) ; old name, to deprecate
{
	return dev_IsFuncWord(s)
}

dev_IsFuncWord(s)
{
	; s should be a single word, but can not be pure-digits.
	; It is used when I check if a word can be used as AHK functionn name.
	
	if(not s)
		return false

	if s is number       ; [2024-01-26] Note: Cannot add round brackets to `s is number`
	{
		; [2024-03-09] But This check is useless, bcz AHK 1.1 does not distingush 
		; between 123 and "123". I mean, the following two produce the same result:
		; 
		;	if 123 is number
		;
		;	if "123" is number
		
		return false
	}
	
	if(InStr(s, " "))
		return false

	if(InStr(s, "`n"))
		return false
	
	if(IsObject(s))
		return false
	
	return true
}

dev_IsString(s, least:=2)
{
	dev_assert(0, "dev_IsString() is bad function, should not be used.")
	; -- bcz Autohotkey 1.1 does not distinguish between 0 and "0".

	; Limitation:
	; `strlen(456)` will report 3, which is wrong result.
	; `strlen(true)` will report 1, which is wrong again.

	slen := strlen(s)

	if(slen>=least)
		return true
	else
		return false
}

dev_IsExistingFuncName(s)
{
	; Check if a string is an existing(already defined) AHK function name.
	fnobj := Func(s)
	if(fnobj)
		return true
	else
		return false
}

indev_OnMessage(wm_xxx, user_callback, maxthreads)
{
	dev_assert(user_callback)

	if(dev_IsOneWord(user_callback))
	{
		; So, user don't have to wrap `Func("function_name")` himself.
		fnobj := Func(user_callback)
		
		dev_assert(IsObject(fnobj)) ; fails if `user_callback` is NOT a function name
	}
	else
	{	
		dev_assert(IsObject(user_callback))
		fnobj := user_callback
	}
	
	return OnMessage(wm_xxx, fnobj, maxthreads)
}

dev_OnMessageRegister(wm_xxx, user_callback)
{
	return indev_OnMessage(wm_xxx, user_callback, 1)
}

dev_OnMessageUnRegister(wm_xxx, user_callback)
{
	return indev_OnMessage(wm_xxx, user_callback, 0)
}

dev_IsDictEmpty(dict)
{
	for key, value in dict {
		return false
	}
	return true
}


dev_GetCurrentDatetime(format)
{
	FormatTime, outvar, , %format%
	return outvar
}

dev_GetDateTimeStr(sep:="_", ts14:="now")
{
	if(ts14=="now")
		ts14 := A_Now
	
	FormatTime, dt, % ts14 , % "yyyy-MM-dd" sep "HH:mm:ss"
	return dt
}

dev_GetDateTimeStrNow(sep:="_")
{
;	FormatTime, dt, , % "yyyy-MM-dd.HH:mm:ss"
;	return dt
	return dev_GetDateTimeStr(sep, A_Now)
}

ts14short(ts14:="now", sep:=".")
{
	return dev_GetDateTimeStrCompact(sep, ts14)
}

dev_GetDateTimeStrCompact(sep:="_", ts14:="now")
{
	; I use "now" as default 2nd-param(instead of using empty-string), because:
	; If user wants to pass-in an explicit ts14 but accidentally pass-in
	; an empty string, I want it to error out loudly, instead of returning 
	; a false "now" timestamp.

	if(ts14=="now")
	{
		; return current time
		FormatTime, dt, , % "yyyyMMdd" . sep .  "HHmmss"
		return dt
	}
	else 
	{
		dev_assert(StrLen(ts14)==14)
		return SubStr(ts14, 1, 8) . sep . SubStr(ts14, 9, 6)
	}
}

dev_Ts14AddSeconds(tsinput, seconds)
{
	; Add seconds to AHK 14-char timestamp (YYYYMMDDhhmmss).
	; A_Now has this format.
	;
	; seconds can be positive or negative
	
	dev_assert(StrLen(tsinput)==14)
	
	tsoutput := tsinput
	EnvAdd, tsoutput, % seconds, Seconds

	return tsoutput
}

dev_Ts14Diff(ts1, ts2)
{
	diff := ts1
	EnvSub, diff, % ts2, Seconds
	return diff
}



dev_LocalTimeZoneInMinutes()
{
	; For China, it returns 480 (8*60)
	
	VarSetCapacity(Tzinfo, 200, 0)
	DllCall("GetTimeZoneInformation", Ptr,&Tzinfo)
	
	tzminutes := NumGet(&Tzinfo, 0, "Int")
	return -tzminutes
}

dev_LocalTimeZoneMinutesStr()
{
	tzminutes := dev_LocalTimeZoneInMinutes()
	if(tzminutes>=0)
		return Format("+{:02X}{:02X}", tzminutes/60, Mod(tzminutes, 60))
	else
		return Format("-{:02X}{:02X}", (-tzminutes)/60, Mod(-tzminutes, 60))
}

dev_SetEnvVar(varname, varvalue)
{
	EnvSet, % varname, % varvalue
}

win32_GetCurrentThreadId()
{
	threadid := DllCall("kernel32.dll\GetCurrentThreadId")
	return threadid
}

dev_RunCmd(cmd_and_params)
{
	Run % cmd_and_params
}

dev_RunWaitOne(command, is_hidewindow:=false, working_dir:="") 
{
	; This simplified function returns only output-text from stdin/stderr.
	; Use dev_RunWaitOneEx() to get sub-process exitcode.

	dret := dev_RunWaitOneEx(command, is_hidewindow, working_dir)
	if(dret.exitcode==0) {
		return dret.output
	}
	else {
			return Format("In dev_RunWaitOne(), the following shell command failed:`n`n"
			. "{}`n`n"
			. "Console output is:`n`n"
			. "{}"
		 	, command, dret.output)
	}
}

dev_RunWaitOneEx(command, is_hidewindow:=false, working_dir:="") 
{
	; Return a dict like: { "exitcode" : 0, "output" : "stdout+stderr" }

	if(not is_hidewindow)
	{
		; // From Autohotkey chm doc
		; // Problem: if StdOut contains Unicode, they may be swallowed.
		;
		; WshShell object: http://msdn.microsoft.com/en-us/library/aew9yb99
		shell := ComObjCreate("WScript.Shell")
		; Execute a single command via cmd.exe
		exec := shell.Exec(ComSpec " /C " command)
		
		; Read and return the command's output
		stdout := exec.StdOut.ReadAll()
		stderr := exec.StdErr.ReadAll()

		return { "exitcode" : exec.ExitCode , "output" : stdout . stderr }
		
		; [2023-04-20] Seems that we can never see stdout,stderr text on the popped out
		; CMD console, even if we do not call exec.StdOut.ReadAll() and exec.StdErr.ReadAll().
		
		; [2023-06-08] Using ComObjCreate() method is NOT recommended, bcz it freezes 
		; current AHK-thread.
	}
	else
	{
		; Redirect the new process's stdout to a file then retrieve it.
		; I have to do this because WScript.Shell.Exec does not support "hide window" param,
		; while Autohotkey's Run allows "hiding".
		
		threadid := win32_GetCurrentThreadId()
		
		dir_localapp := dev_EnvGet("LocalAppData")
		tempfile := Format(dir_localapp . "\temp\AHK-dev_RunWaitOne-tid{}.txt", threadid)
		run_string = %ComSpec% /c @%command% > %tempfile% 2>&1
		; -- We need an @, to avoid 'CMD /C' stripping user command's starting-ending-double-quote-pair

		try {
			RunWait, %run_string%, %working_dir%, Hide UseErrorLevel
			if(ErrorLevel=="ERROR")
				exitcode := 1
			else
				exitcode := ErrorLevel
		} catch e {
			Dbgwin_Output("dev_RunWaitOneEx() catch RunWait error!") ; debug
			exitcode := 1
		}
		
		cmd_output := dev_FileRead(tempfile)
		
		return { "exitcode" : exitcode , "output" : cmd_output }
	}
}

dev_PasteTextViaClipboard(usertext)
{
	if(StrLen(usertext)==0)
	{
		; Consider usertext as a string *array* .
		usertext := dev_JoinStrings(usertext, "`r`n") . "`r`n"
	}
	
	if(not dev_SetClipboardWithTimeout(usertext, 500))
	{
		dev_MsgBoxWarning("Unexpect: dev_PasteTextViaClipboard() cannot open Clipboard.")
		return
	}
	
	WinClip.Paste()
}

dev_Send(send_keys)
{
	Send % send_keys
}

dev_SendInput(send_keys)
{
	SendInput % send_keys
}

dev_SendRaw(rawstr)
{
	; `n represent Line-feed
	SendInput % "{Raw}" rawstr
}

dev_SendTextLines(arlines)
{
	if(!arlines)
		return

    for index,oneline in arlines
    {
    	SendInput % "{Raw}" oneline
        Send {Enter}
    }
}

dev_SendKeyToExeMainWindow(keyspec, wintitle:="A")
{
	; wintitle can be:
	;	"A"
	;	"ahk_id XXXXXXXX"
	;	"ahk_class Notepad"
	; etc

	; [2023-04-26] This function use ControlSend to send keys. 
	; You should know the caveat: If you want to send Ctrl+Shift+n , keyspec cannot be:
	;	"^+n"
	; instead, you should pass:
	;	"{Ctrl down}{Shift down}n{Shift up}{Ctrl up}"
	;
	; -- yes, as for Autohotkey 1.1.32, the keyspec meaning is different from that of `SendRaw` command.
	;
	; [2024-04-19] One more note: When defining a hotkey action that calls dev_SendKeyToExeMainWindow(),
	; you should add `Sleep, 500`, bcz your triggering hotkey may probably interfere with target 
	; application's interpretation of your sending hotkeys.

	WinGet, winid, ID, % wintitle
	ControlSend , , % keyspec, % "ahk_id " winid
}

dev_SendRawToExeMainWindow(keyspec, wintitle:="A")
{
	; Similar to dev_SendKeyToExeMainWindow, but use ControlSendRaw instead.
	WinGet, winid, ID, % wintitle
	ControlSendRaw , , % keyspec, % "ahk_id " winid
}

dev_SendKeyToExeMainWindow_ap(keyspec, wintitle:="A")
{
	; [2023-11-03] Usage Note: 
	; If keyspec=="{F5}", it triggers Notepad's F5 hotkey(insert current datetime).
	;
	; If keyspec=="F5", Notepad does not get "F5" into editing area, that's bcz 
	; the window messages for "F" and "5" have MSG.hwnd==hMainWindowOfNotepad,
	; so they will not be dispatched to the "Edit" control, so the editbox in Notepad 
	; will not get the two characters "F" and "5".
	;
	; 
	ControlSend ahk_parent, % keyspec, % wintitle
}
dev_SendRawToExeMainWindow_ap(keyspec, wintitle:="A")
{
	ControlSendRaw ahk_parent, % keyspec, % wintitle
}

dev_ControlSend_hwnd(hwnd, keys)
{
	ControlSend, , % keys, ahk_id %hwnd%
}

dev_ControlSend(wintitle, classnn, keys)
{
	ControlSend, % classnn, % keys, % wintitle
}


dev_MenuAddSepLine(menuname)
{
	Menu, % menuname, add
}

dev_MenuAddItem(menuname, itemtext, target)
{
	; To add a menu-item to AHK's systray popup, use menuname="TRAY"
	; If `target` is a function, caller should write "some_function" as target, i.e. with double-quotes.
	; The `target` can be a function-object resulting from Func("some_function").Bind() .

	dev_assert(target, "ERROR: dev_MenuAddItem() gets empty 'target' parameter.")

	if(dev_IsOneWord(target) && !StrIsStartsWith(target, ":")) ; ":" means a submenu name
	{
		dev_assert(IsObject(Func(target))
			, Format("ERROR in dev_MenuAddItem(): ""{}"" is not an existing function name.", target))
	}

	Menu, % menuname, add, % itemtext, % target
}

dev_MenuAddSubmenu(parent_menuname, parent_itemtext, child_menuname)
{
	; If child_menuname is "g_more_operations", the child menu should have been 
	; created with:
	; 	dev_MenuAddItem("g_more_operations", "more info one", "MoreTargetOne")
	; 	dev_MenuAddItem("g_more_operations", "more info two", "MoreTargetTwo")
	;	...
	
	Menu, % parent_menuname, add, % parent_itemtext, % ":" child_menuname
}

dev_MenuShow(menuname, x:="", y:="")
{
	Menu, % menuname, show, % x, % y
}

dev_MenuRenameItem(menuname, itemtext_old, itemtext_new)
{
	Menu, % menuname, rename, % itemtext_old, % itemtext_new
}

dev_MenuTickItem(menuname, whichitem, is_tick)
{
	Menu, % menuname, % is_tick ? "Check" : "Uncheck", % whichitem
}

dev_Menu_CreateEmpty(menuname)
{
	dev_Menu_DeleteAll(menuname)
	
	Menu, % menuname, Add, "===empty===", dev_nop
	Menu, % menuname, DeleteAll
}

dev_Menu_DeleteAll(menuname)
{
	try {
		Menu, % menuname, DeleteAll
	} catch {
	}
}


dev_YMDHMS_AddSeconds(ymdhms, seconds)
{
	outvar := ymdhms
	EnvAdd, outvar, seconds, Seconds
	return outvar
}


dev_isValidWalltime(wt)
{
	; I just add a underscore between date and time to make the whole timestamp
	; more readable.

	if(!wt)
		return true ; consider empty value valid, as in Unix-epoch

	return (wt ~= "^[0-9]{8}_[0-9]{6}$") ? true : false
}

dev_walltime_strip(wt)
{
	if(!wt)
		return ""

	; Return AHK native timestamp, so to call EnvAdd, EnvSub
	return StrReplace(wt, "_" , "")
}

dev_walltime_make(ahkts)
{
	if(!ahkts)
		return ""

	return SubStr(ahkts, 1, 8) "_" SubStr(ahkts, 9, 6)
}

dev_walltime_origin()
{
	east_seconds := 60 * dev_LocalTimeZoneInMinutes()
	return dev_walltime_AddSeconds("19700101_000000", east_seconds) ; count from Unix-epoch
}

dev_walltime_AddSeconds(wt, add_seconds)
{
	if(!wt)
		wt := dev_walltime_origin()

	dev_assert( dev_isValidWalltime(wt), Format("'{}' is NOT valid walltime format.", wt))
	dev_assert(!dev_isValidWalltime(add_seconds), Format("'{}' is in walltime format, which is wrong.", add_seconds))

	outvar := dev_walltime_strip(wt)
	EnvAdd, outvar, %add_seconds%, Seconds
	; -- surprise, `%add_seconds%` above can be written as `add_seconds`
	
	return dev_walltime_make(outvar)
}

no_use__dev_walltime_friendly(wt, sepchar:="_")
{
	; Add a _ between date and time.

	dev_assert(dev_isValidWalltime(wt))
	
	if(!wt or wt==dev_walltime_origin())
		return "(walltime-nil)"
	
	return SubStr(wt, 1, 8) . sepchar . SubStr(wt, 9, 6)
}

dev_walltime_now()
{
	return dev_walltime_make(A_Now)
}

dev_walltime_elapsec(wt_from, wt_to)
{
	; Calculate wt_to - wt_from
	; wt_from and wt_to must be seconds-precision.

	dev_assert(dev_isValidWalltime(wt_from), Format("'{}' is NOT in AHK timestamp format.", wt_from))
	dev_assert(dev_isValidWalltime(wt_to),   Format("'{}' is NOT in AHK timestamp format.", wt_to))

	if(!wt_from)
		wt_from := dev_walltime_origin()

	if(!wt_to)
		wt_to := dev_walltime_origin()

	ahkts_from := dev_walltime_strip(wt_from)
	ahkts_to   := dev_walltime_strip(wt_to)

	outvar := ahkts_to
	EnvSub, outvar, %ahkts_from%, Seconds
	return outvar
}


dev_Hex2Num(HX)
{
	; https://autohotkey.com/boards/viewtopic.php?t=6434
    ; Assuming "0x" is always omitted (since in your script the "0x" will never occur anyway)
    
    ; Usage Example:
    ; integer_result := dev_Hex2Num("FF")+100 ;// integer_result will be 355
    
	SetFormat, integer, D
	Dec += "0x" HX
	return Dec
}

dev_IsProcessAlive(pid)
{
	; Dup with dev_IsExeRunning() ?

	access := 0x1000 ; PROCESS_QUERY_LIMITED_INFORMATION
	if(IsWinXP())
		access := PROCESS_QUERY_INFORMATION

	hProcess := DllCall( "OpenProcess" 
	                    , "uint", access
	                    , "int", false 
	                    , "uint", pid ) 
	if(hProcess)
	{
		DllCall("CloseHandle", "Ptr",hProcess)
		return true
	}
	else
		return false
}


dev_IsExeRunning(exename)
{
	Process, Exist, % exename
	if ErrorLevel
	{
		; ErrorLevel is the pid.
		return true
	}
	else
	{
	    return false
	}
}

dev_IsExeActive(exefile)
{
	; exefilename sample :
	; 	"notepad.exe"
	; or 
	;   "D:\portableapps\MPC-HC-Portable\App\MPC-HC\mpc-hc.exe"
	
	Awinid := dev_GetActiveHwnd() ; cache active window unique id
	WinGet, exepath, ProcessPath, ahk_id %Awinid%

	if(InStr(exefile, "\"))
	{
		; consider exefile as fullpath, need exact match
		if(exepath==exefile)
			return true
		else
			return false
	}
	else
	{
		; consider exefile as filenam only, match only final component.
		if( StrIsEndsWith(exepath, "\" . exefile) )
			return true
		else
			return false
	}
}

dev_WinGetTitle_byHwnd(winid)
{
	WinGetTitle, title, % "ahk_id " winid
	return title
}

dev_IsWintitleRegexActive(regex)
{
	WinGetTitle, title, A
	
	if(title ~= regex)
		return true
	else
		return false
}

IsWinidActive(winid) ; Check against active window
{
	IfWinActive, ahk_id %winid%
	{
	    return true
	}
	return false
}

IsWinClassActive(winclass, wintext="") ; Check against active window
{
	IfWinActive, ahk_class %winclass%, %wintext%
	{
	    return true
	}
	return false
}


IsWinClassExist(winclass, wintext="") ; Check existing window
{
	IfWinExist, ahk_class %winclass%, %wintext%
	{
	    return true
	}
	return false
}

dev_IsWinclassExist(classname)
{
	if WinExist("ahk_class " classname) {
		return true
	} 
	else {
		return false
	}
}

dev_GetHwndByWintitle(wintitle:="A")
{
	WinGet, Awinid, ID, % wintitle
	return Awinid ; will return null if no window found
}

dev_GetHwndByClass(classname)
{
	return dev_GetHwndByWintitle("ahk_class " classname)
}

dev_WinActivateHwnd(hwnd, timeout_millisec:=0)
{
	WinActivate, ahk_id %hwnd%
	
	if(timeout_millisec==0)
		return true
	
	return dev_WinWaitActiveHwnd(hwnd, timeout_millisec)
}

dev_WinWaitActiveHwnd(hwnd, timeout_millisec:=2000)
{
	WinWaitActive, ahk_id %hwnd%, , % timeout_millisec/1000
	if not ErrorLevel
	{
		return true
	}
	else
	{
		return false
	}
}

dev_WinWaitActive_with_timeout(wintitle, wintext:="", timeout_sec:=1)
{
	WinWaitActive, %wintitle%, %wintext%, %timeout_sec%
	if not ErrorLevel
	{
		return true
	}
	else
	{
		return false
	}
}

dev_WinShow_byHwnd(hwnd)
{
	dev_WinShow("ahk_id " hwnd)
}

dev_WinShow(wintitle)
{
	WinShow, % wintitle
}

dev_WinHide_byHwnd(hwnd)
{
	dev_WinHide("ahk_id " hwnd)
}

dev_WinHide(wintitle)
{
	WinHide, % wintitle
}

dev_ControlFocus(wintitle, classnn)
{
	ControlFocus, %classnn%, %wintitle%
}


dev_GetHwndByExepath(exepath)
{
	WinGet topwnd, List
	Loop %topwnd%
	{
		hwnd := topwnd%A_Index%
		WinGet, tmppath, ProcessPath, ahk_id %hwnd%
		if(exepath==tmppath) 
		{
			return hwnd
		}
	}
	return None
}

dev_GetExeFilepath(wintitle:="A")
{
	WinGet, exepath, ProcessPath, % wintitle
	return exepath
}

dev_GetActiveEXE_PathName()
{
	WinGet, exepath, ProcessPath, A
	SplitPath, exepath, filename, dirpath
	return [dirpath, filename]
	; retarray[1] is dirpath, retarray[2] is filename .
}


dev_mapping_count(map)
{
	; Count how many keys are in a map(dict)
	; Since AutoHotkey 1.1.29, equals map.Count() .
	
	count := 0
	for key, val in map
		count++
	return count
}


dev_IsShiftKeyDown()
{
	if(GetKeyState("Shift", "P"))
	    return true
	else
	    return false
}

dev_IsCtrlKeyDown()
{
	if(GetKeyState("Ctrl", "P"))
	    return true
	else
	    return false
}


dev_GetHwndFromClassNN(classnn, wintitle)
{
	ControlGet, hctrl, HWND, , %classnn%, %wintitle%
	return hctrl
}

dev_GetClassNameFromHwnd(hwnd)
{
	nbuf := 100
	VarSetCapacity(classname, A_IsUnicode ? nbuf * 2 : nbuf)
	nret := DllCall("GetClassName"
		, "Ptr", hwnd
		, "Str", classname
		, "Int", nbuf)
	if(nret==0)
		return ""
	else
		return classname
}

GetActiveClassnnFromXY(x, y)
{
	; Providing X,Y inside the active window, return control classnn from that position
	
	if(x==None)
	{
		MsgBox, % "Error: GetActiveClassnnFromXY() null x"
		return 
	}
	if(y==None)
	{
		MsgBox, % "Error: GetActiveClassnnFromXY() null y"
		return 
	}
	
	MouseMove, %x%, %y%
	MouseGetPos,,,, classnn
	return classnn
}

dev_GetHwndUnderMouse()
{
	rdict := {} ; will return this dict

	MouseGetPos, mxWindow, myWindow, tophwnd_undermouse, classnn
	
	rdict.hwndtop := tophwnd_undermouse
	rdict.classnn := classnn

	if(classnn)
	{
		rdict.hwndctl := dev_GetHwndFromClassNN(classnn, "ahk_id " tophwnd_undermouse)
	}
	
	return rdict
}

dev_GetMouseScreenXY()
{
	CoordMode, Mouse, Screen
	
	MouseGetPos, outx, outy
	
	CoordMode, Mouse, Window
	
	return {x:outx, y:outy}
}

dev_MouseMove(x, y, mode, movespeed:=3)
{
	; mode:
	; "S" screen coordinate
	; "A" relative to active window
	; "R" relative to current mouse pointer location

	dev_assert(mode=="S" or mode="A" or mode=="R")
	
	if(mode=="S" or mode=="A")
	{
		if(mode=="S")
			CoordMode, Mouse, Screen
		else
			CoordMode, Mouse, Window
	
		MouseMove, % x, % y, % movespeed

		CoordMode, Mouse, Window
	}
	else
	{
		MouseMove, % x, % y, % movespeed, R
	}
}

dev_GetTopHwndAtScreenXY(screenx, screeny)
{
	hwnd := win32_WindowFromPoint(screenx, screeny)
	
	tophwnd := dev_GetRootWindow(hwnd)
	return tophwnd
}

win32_WindowFromPoint(screenx, screeny)
{
	hwnd := DllCall("WindowFromPoint", "Int", screenx, "Int", screeny)
	return hwnd
}


IsWinClassMatchRegex(regex) ; Check against active window class
{
	WinGetClass, class, A
	foundpos := RegExMatch(class, regex)
	if (foundpos>0)
		return true
	else 
		return false
}

IsWinTitleMatchRegex(regex) ; Check against active window
{
	WinGetTitle, title, A
	foundpos := RegExMatch(title, regex)
	if (foundpos>0)
		return true
	else 
		return false
}

dev_IsWin7SaveAsDialog()
{
	if(not IsWinClassActive("#32770"))
		return false
	
	if(IsWinTitleMatchRegex("另存为")
		or IsWinTitleMatchRegex("Save As") )
	{
		return true
	}
	else
		return false
}

dev_WinGetClientAreaPos(WinId, isScreenCoord:=false)
{
	; https://www.autohotkey.com/boards/viewtopic.php?p=257561&sid=d2327857875a0de35c9281ab43c6a868#p257561
	
	VarSetCapacity(RECT, 16, 0)
	if !DllCall("user32\GetClientRect", Ptr,WinId, Ptr,&RECT)
		return null
	if !DllCall("user32\ClientToScreen", Ptr,WinId, Ptr,&RECT)
		return null

	cliAbs := {}	
	cliAbs.x := NumGet(&RECT, 0, "Int")
	cliAbs.y := NumGet(&RECT, 4, "Int")
	cliAbs.w := NumGet(&RECT, 8, "Int")
	cliAbs.h := NumGet(&RECT, 12, "Int")
	cliAbs.x_ := cliAbs.x + cliAbs.w
	cliAbs.y_ := cliAbs.y + cliAbs.h

	if(isScreenCoord)
	{
		; Return the client-area's absolute(screen) coordinate.
		return cliAbs
	}
	else
	{
		; Return the client-area's relative coordinate, relative to its host-window.
	
		WinGetPos, hostx, hosty, _, _, ahk_id %winid%
		
		cliRel := {}
		cliRel.x := cliAbs.x - hostx
		cliRel.y := cliAbs.y - hosty
		cliRel.w := CliAbs.w
		cliRel.h := CliAbs.h
		cliRel.x_ := cliRel.x + cliRel.w
		cliRel.y_ := cliRel.y + cliRel.h
		
		return cliRel
	}
}


Is_XY_in_Rect(x,y, xrect, yrect, wrect, hrect)
{
	if(x>=xrect and x<=xrect+wrect and y>yrect and y<yrect+hrect)
		return true
	else
		return false
}

dev_XYinRect(x, y, rect_)
{
	if(x>=rect_.left && x<rect_.right && y>=rect_.top && y<rect_.bottom)
		return true
	else
		return false
}


Is_RectA_in_RectB(Ax, Ay, Aw, Ah, Bx, By, Bw, Bh, tolerance:=0)
{
	t := tolerance
	if(Ax>=(Bx-t) and Ay>=(By-t) and (Ax+Aw)<=(Bx+Bw+t) and (Ay+Ah)<=(By+Bh+t))
		return true
	else
		return false
}


dev_hasValue(haystack, needle) 
{
	; Check if needle is in the haystack array.
	; https://stackoverflow.com/a/33593563/151453
    
    if(!IsObject(haystack))
        return false
    if(haystack.Length()==0)
        return false
    for k,v in haystack
        if(v==needle)
            return true
    return false
}

dev_FindVacantFilename(path_ptn, start_seq:=1, max_seq:=10000)
{
	; If path_ptn=="d:\test\foo{}.txt", we'll search for 
	;	d:\test\foo1.txt
	;	d:\test\foo2.txt
	;	d:\test\foo3.txt
	; until the first non-existing filename/dirname is found.

	if(!InStr(path_ptn, "{}"))
		return ""
	
	now_seq := start_seq
	Loop
	{
		if(now_seq>max_seq)
			return ""
	
		nowpath := Format(path_ptn, now_seq)
		if(!FileExist(nowpath))
			return nowpath

		now_seq += 1
	}
}


dev_IsExePathMatchRegex(regex)
{
	Awinid := dev_GetActiveHwnd() ; cache active window unique id
	WinGet, exepath, ProcessPath, ahk_id %Awinid%

	foundpos := RegExMatch(exepath, regex)
	if (foundpos>0)
		return true
	else 
		return false
}

dev_StrRepeat(string, times)
{
	; times<=0 will get empty string
	output := ""
    loop % times
        output .= string
    return output
}


dev_GetTickCount64()
{
	; As of Autohotkey 1.1.36.2, A_TickCount only returns a 32bit DWORD.
	; Here I provide an encapsulation to make it 64-bit.

	static s_prev_dword := 0
	static s_highquad := 0 ; the 32-bit ~ 64-bit part
	
	now_dword := A_TickCount
	
	if(now_dword < s_prev_dword)
	{
		; DWORD wrap around happened
		s_highquad += 1
	}
	
	s_prev_dword := now_dword

	return s_highquad * 0x100000000 + now_dword
}

dev_IsHe32bitProcess(hProcess)
{
	; hProcess is a handle returned by WinAPI OpenProcess(PROCESS_QUERY_INFORMATION)
	
	if(not A_Is64bitOS)
		return true
	
	is32Bit := false
	succ := DllCall("Kernel32.dll\IsWow64Process", "Ptr", hProcess
							, "int*", is32Bit)
	return is32Bit
}

dev_ArrayTruncateAt_(ar, nkeeps)
{
	nDel := ar.Length() - nkeeps
	if(nDel>0)
	{
	    Loop, % nDel
	    {
	    	ar.Pop()
		}
	}
}

dev_IsEleInArray(ele, array)
{
	for index,value in array
    {
        if(value==ele)
        	return true
    }
	return false
}


dev_SetClipboardWithTimeout(text, timeout_millisec:=1000)
{
	is_ok := false
	msec_start := A_TickCount
	Loop
	{
		try {
			Clipboard := text
		} catch e {
			; e seems to be null

;			Dbgwin_Output("dev_SetClipboardWithTimeout() needs wait...")
			Sleep, 10
			continue
		}
		
		is_ok := true
		break
		
	} until (A_TickCount-msec_start>timeout_millisec)
	
	return is_ok
}


dev_IsWin10()
{
	verstr := A_OSVersion ; may be "10.0.19044"
	
	if(StrIsStartsWith(verstr, "10.0."))
	{
		return true
	}
	else
	{
		return false
	}
}

dev_InputBox_InitText(title, prompt, byref usertext:="", on_active_window:=true)
{
	; Input param usertext is also the output param.

	scrx := "" ; to position the Inputbox
	scry := ""
	
	if(on_active_window)
	{
		; We make that Inputbox appear at center of current active window, 
		; which is much more friendly to human user.
		pos := dev_WinGetPos("A")
		if(pos)
		{
			boxw := 375
			boxh := 189 ; hard value according to AHK chm
			
			scrx := pos.x + (pos.w - boxw) / 2
			scry := pos.y + (pos.h - boxh) / 2
		}
	}

	if(title=="")
		title := "AHK InputBox"
	
	InputBox, answer, % title, % prompt, , , , % scrx , % scry , , 0, % usertext
	
	usertext := answer

	if(ErrorLevel) 
	{
		; User pressed Cancel. 
    	return false
    }
	else
	{
    	return true
    }
}

dev_StartTimerOnce(str_callable, millisec)
{
	; str_callable can be 
	;	a function name in string format, like "DoSomeWork"
	; or
	;	a function object(use it to carry function parameters), like this:
	;	
	;	fn := Func("evernote_RestoreClipboardText").Bind(codetext)
	;	dev_StartTimerOnce(fn, 500)

	dev_assert(millisec>0, "dev_StartTimerPeriodic() `millisec` must be >0")

	SetTimer, % str_callable, % 0-millisec
}

dev_StartTimerPeriodic(str_callable, millisec, is_exec_now:=false)
{
	dev_assert(millisec>0, "dev_StartTimerPeriodic() `millisec` must be >0")

	if(is_exec_now)
		%str_callable%()

	SetTimer, % str_callable, % millisec
}

dev_StopTimer(str_callable:="")
{
	if(str_callable)
		SetTimer, % str_callable, Off
	else
		SetTimer, , Off
}

dev_StartTimerPeriodicEx(millisec, is_exec_now, funcware, callback_args*)
{
	if millisec is not number 
	{
		dev_assert(0, Format("millisec parameter MUST be a number, not '{}'.", millisec))
	}
	
	fn := make_solo_callable(funcware, callback_args*)
	if(is_exec_now)
		%fn%()
	
	SetTimer, % fn, % millisec
	; -- To stop the timer, you should call dev_StopTimer() from *within* your timer callback.
	;    instead of calling dev_StopTimer().
	;
	;    -- because, most of the time, even if you pass the same funcware object to 
	;    dev_StartTimerPeriodicEx() and to dev_StopTimer(), the resulting `fn` 
	;    may NOT be the same, so dev_StopTimer() does not take effect.
}

dev_StopTimerPeriodicEx(args*)
{
	dev_assert(0, "You should NOT call dev_StopTimerPeriodicEx(). You HAVE to stop the timer within the timer callback.")
}

dev_IsValidGuid(input)
{
	ptn := "^\{[0-9A-Za-z]{8}-[0-9A-Za-z]{4}-[0-9A-Za-z]{4}-[0-9A-Za-z]{4}-[0-9A-Za-z]{12}\}$"
	if(input ~= ptn)
		return true
	else
		return false
}

dev_IsValidHwnd(hwnd)
{
	succ := DllCall("IsWindow", "Ptr", hwnd)
	return succ
}

dev_Sleep(millisec)
{
	Sleep % millisec
}

dev_WaitKeyRelease(keyname, options:="")
{
	; Example:
	; dev_WaitKeyRelease("Shift")

	KeyWait % keyname, % options
}

dev_IsUnicodeInString(s)
{
	slen := StrLen(s)
	
	Loop, % slen
	{
		c := SubStr(s, A_Index, 1)
		if(Ord(c)>255)
			return true
	}
	
	return false
}

dev_StrReplace_CRLF_to_LF(s)
{
	return StrReplace(s, "`r`n", "`n"`)
}

dev_StrReplace_LF_to_CRLF(s)
{
	return StrReplace(s, "`n", "`r`n"`)
}

dev_StringCountLines(multiline_string)
{
	lines := StrSplit(multiline_string, "`n")
	return lines.Length()
}


Dbg_DumpChildWinsInfo(hwndtop)
{
	if(!dev_IsValidHwnd(hwndtop))
	{
		Dbgwin_Output(Format("Dbg_DumpChildWinsInfo(): 0x{:08X} is not a valid HWND."))
		return false
	}

	WinGet, ControlList, ControlList, ahk_id %hwndtop%
	
	info := Format("Top-wnd 0x{:08X} has total {} child windows:`n", hwndtop, dev_StringCountLines(ControlList))
	
	Loop, parse, ControlList, `n
	{
		classnn := A_LoopField
		
		hctrl := dev_GetHwndFromClassNN(classnn, "ahk_id " hwndtop)

		pos := dev_ControlGetPos_hc(hwndtop, classnn)

		wintext := dev_ControlGetText_hc(hwndtop, classnn)
		wintext := Substr(wintext, 1, 100) ; Limit length to 100
		
		childinfo := Format("#{} [{} , 0x{:08X}] @({},{}) {}", A_Index, classnn, hctrl, pos.x, pos.y, wintext)
		
		info .= childinfo . "`n"
	}
	
	Dbgwin_Output(info)
	
	return true
}

dev_WinGet_ControlList(wintitle)
{
	; Return an array of classnn-s
	
	WinGet, xClassnn, ControlList, %wintitle%
	return dev_SplitStrings(xClassnn, "`n")
}

dev_ControlGetText_hwnd(hwnd)
{
	try {
		ControlGetText, outtext, , ahk_id %hwnd%
	} catch e {
		; Without this catch, a too large child-control text will assert #MaxMem error.
		outtext := "(wintext too large?)"
	}
	return outtext
}

dev_ControlGetText_hc(hwndtop, classnn) ; hc: hwnd+classnn
{
	hctl := dev_GetHwndFromClassNN(classnn, "ahk_id " hwndtop)
	return dev_ControlGetText_hwnd(hctl)
}

dev_ControlSetText_hwnd(hwnd, newtext)
{
	ControlSetText, , %newtext%, ahk_id %hwnd%
}

dev_ControlSetText_hc(hwndtop, classnn, newtext) ; hc: hwnd+classnn
{
	ControlSetText, %classnn%, %newtext%, ahk_id %hwndtop%
}


dev_ControlGetPos_hc(hwndtop, classnn)
{
	; Get specific child-window's position, relative to its parent.
	; hc: Hwnd and Classnn
	
	ControlGetPos, rx, ry, rw, rh, %classnn%, ahk_id %hwndtop%
	pos := { "x":rx, "y":ry, "w":rw, "h":rh, "x_":rx+rw, "y_":ry+rh }
	return pos
}

dev_ControlGet_byHwnd(hwnd, SubCommand, Options:="")
{
	; hwnd can be top-level hwnd or a UIC's hwnd
	
	ControlGet, OutputVar, % SubCommand , % Options, , % "ahk_id " hwnd
	return OutputVar
}


dev_ControlMove(hwndtop, classnn, x, y, w, h)
{
	ControlMove, % classnn, % x, % y, % w, % h, ahk_id %hwndtop% 
}


dev_PixelGetColor(x, y, coordmode:="Relative")
{
	CoordMode, Pixel, % coordmode
	
	PixelGetColor, rgb, % x, % y, RGB
	return rgb
}

dev_IsGreyPixel(rgb)
{
	; rgb example: 
	; 	0xFFFFFF
	; 	0x3399CC

	if(SubStr(rgb,3,2)==SubStr(rgb,5,2) and SubStr(rgb,5,2)==SubStr(rgb,7,2))
		return true
	else
		return false
}

win32_GetFullPathName(sPath) 
{
	; The input sPath does not have to actually exist on disk.
	; GetFullPathName() can do pure string operation.
	
	n := DllCall("GetFullPathName"
		, "Ptr", &sPath
		, "UInt", 0
		, "UInt", 0
		, "Int", 0)
	
	VarSetCapacity(sAbs, A_IsUnicode ? n * 2 : n)
	
	DllCall("GetFullPathName"
		, "Ptr", &sPath
		, "UInt", n
		, "Str", sAbs
		, "Ptr*", 0)
	Return sAbs
}

ahk_Sort(ByRef varname, option:="")
{
	Sort, varname, % option
}

ahk_SortArrayReturnNew(array_varname, option:="")
{
	s := dev_JoinStrings(array_varname, "`n")
	
	Sort, s, % option
	
	return StrSplit(s, "`n")
}


dev_objkeys(obj)
{
	keys := []
	for key,val in obj
		keys.Push(key)
	return keys
}

dev_dictkeys(dict)
{
	return dev_objkeys(dict)
}

dev_dictclear(dict)
{
	keys := dev_dictkeys(dict)
	for index,key in keys
		dict.Delete(key)
		
	; Note: The following code is wrong, the dict cannot be thoroughly cleared.
	;
	;for key,val in dict
	;	dict.Delete(key)
	
	
}

dev_poke_byte(addr, byte_value)
{
	; write a byte_value to own-process's address `addr`
	NumPut(byte_value, addr+0, 0, "UChar")
}

dev_VarGetCapacity(byref varname) ; this is Get()
{
	return VarSetCapacity(varname)
}


dev_OpenSelectFileDialog(path_hint, dlg_title:="", filter:="")
{
	opt_FilemustExist := 1
	
	try {
		FileSelectFile, outpath_selected, % opt_FilemustExist, % path_hint , % dlg_title, % filter
	}
	catch e {
		; If path_hint is "Caution: danger", we get this. (due to the bad colon char)
		; More bad chars like: <|>/
		dev_MsgBoxError("Unexpected! FileSelectFile execution fail!`n`n" dev_getCallStack())
	}
	return outpath_selected
}

dev_ReplaceBadChars(inputstr, badchars, safestr:="")
{
	; Each char in badchars[] will be replaced with safestr
	
	outputstr := inputstr
	
	badlen := StrLen(badchars)
	Loop, % badlen
	{
		outputstr := StrReplace(outputstr, SubStr(badchars, A_Index, 1), safestr)
	}
	return outputstr
}

WinSet_AlwaysOnTop(on_or_off, wintitle:="")
{
	op := on_or_off
	if(!on_or_off)
		op := "off"
	if(on_or_off==1 or on_or_off==true)
		op := "on"

	WinSet, AlwaysOnTop, % op, % wintitle
}

WinSet_TopNoActivate(wintitle:="")
{
	WinSet, Top, , % wintitle
}

WinSet_Transparent(n0_255, wintitle:="")
{
	; n=1   : almost invisible 
	; n=250 : almost solid 
	; "Off" : turn off transparency
	
	WinSet, Transparent, % n0_255, % wintitle
}

dev_IsWin7()
{
	return A_OSVersion=="WIN_7" ? true : false
}

dev_IsWinXP()
{
	return A_OSVersion=="WIN_XP" ? true : false
}


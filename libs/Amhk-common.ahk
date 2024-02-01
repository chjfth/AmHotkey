; Amhk-common.ahk, part of AmHotkey suite.
;
; This ahk is not to be run standalone, it is to be #include-d as AHK function library.
;

#Include %A_LineFile%\..\Amhk-globals.ahk

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

dev_assert(success_condition, msg_on_error:="")
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
	
	fullmsg .= dev_getCallStack()
	
	dev_MsgBoxError(fullmsg, "AHK Assertion Fail!")
}

dev_getCallStack(deepness = 20, is_print_code = true)
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
		FileReadLine, line, % oEx.file, % oEx.line
		if(oEx.What = lvl)
			continue
			
		if(lv_first_print==-1) 
			lv_first_print := A_Index
		
		stack_prev := stack
		stack .= (stack ? "`n" : "") . Format("[#{1}] ", A_Index-lv_first_print+1) . "File '" oEx.file "', Line " oEx.line (oExPrev.What = lvl-1 ? "" : ", in " oExPrev.What "()") (is_print_code ? ":`n" line : "") "`n"
	}
	
	return stack_prev
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

dev_StrIsEqualI(s1, s2) ; case insensitive compare
{
	StringUpper, s1u, s1
	StringUpper, s2u, s2
	if(s1u==s2u)
		return true
	else
		return false
}

dev_IsStrEqualI(s1, s2)
{
	return dev_StrIsEqualI(s1, s2)
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

dev_JoinStrings(ar_strings, join_with:=",")
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

dev_IsOneWord(s)
{
	; s should be a single word, but can not be pure-digits.
	; It is used when I check if a word can be used as AHK functionn name.
	
	if(not s)
		return false

	if s is number       ; [2024-01-26] Note: Cannot add round brackets to `s is number`
		return false
	
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

dev_GetDateTimeStrNow()
{
	FormatTime, dt, , % "yyyy-MM-dd.HH:mm:ss"
	return dt
}

ts14short(ts14:="now", sep:=".")
{
	return dev_GetDateTimeStrCompact(sep, ts14)
}

dev_GetDateTimeStrCompact(sep:="_", ts14:="now")
{
	; I use "now" as default 2nd-param(instead of using empty-string), because:
	; If user wants to pass-in an explicit ts14 but accidentally the passed argument
	; is an empty string, I want it to error out loudly, instead of returning 
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


dev_Send(send_keys)
{
	Send % send_keys
}

dev_YMDHMS_AddSeconds(ymdhms, seconds)
{
	outvar := ymdhms
	EnvAdd, outvar, seconds, Seconds
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

dev_IsWintitleRegexActive(regex)
{
	WinGetTitle, title, A
	
	if(title ~= regex)
		return true
	else
		return false
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
	return Awinid
}

dev_WinActivateHwnd(hwnd)
{
	WinActivate, ahk_id %hwnd%
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

dev_GetHwndFromClassNN(classnn, wintitle)
{
	ControlGet, hctrl, HWND, , %classnn%, %wintitle%
	return hctrl
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

dev_InputBox_InitText(title, prompt, byref usertext:="")
{
	; Input param usertext is also the output param.

	if(title=="")
		title := "AHK InputBox"
	
	InputBox, answer, % title, % prompt, , , , , , , 0, % usertext
	
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

dev_StopTimer(str_callable)
{
	SetTimer, % str_callable, Off
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

dev_ParseLinesToArray(bigstring, sep:="`n")
{
	if(sep=="`n")
		bigstring := dev_StrReplace_CRLF_to_LF(bigstring)

	ar := []

	Loop, PARSE, % bigstring, % sep
	{
		ar.Push(A_LoopField)
	}
	
	return ar
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

		pos := dev_ControlGetPos(hwndtop, classnn)

		wintext := dev_ControlGetText(hwndtop, classnn)
		wintext := Substr(wintext, 1, 100)
		
		childinfo := Format("#{} [{} , 0x{:08X}] @({},{}) {}", A_Index, classnn, hctrl, pos.x, pos.y, wintext)
		
		info .= childinfo . "`n"
	}
	
	Dbgwin_Output(info)
	
	return true
}


dev_ControlGetText(hwndtop, classnn)
{
	try {
		ControlGetText, outtext, %classnn%, ahk_id %hwndtop%
	} catch e {
		; Without this catch, a too large child-control text will assert #MaxMem error.
		outtext := "(wintext too large?)"
	}

	return outtext
}


dev_ControlGetPos(hwndtop, classnn)
{
	; Get specific child-window's position, relative to its parent.
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

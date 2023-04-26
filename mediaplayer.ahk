; Note: This file is saved with UTF8 with BOM, which is the best encoding choice to write Unicode chars here.

AUTOEXEC_mediaplayer: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

global g_mpc_seekbar_xborder := 10 ; const, eye-estimated

global g_mpc_was_active := false
	; Was it active on previous timer tick?
global g_mpc_is_tooltip_hidden := false
	
global g_mpc_txc_string := ""
	; txc: "transcode"

global g_mpc_hwndWebcam ; The MPC window showing live webcam

global g_mpcaot_exepath := "D:\portableapps\MPC-HC-Portable\App\MPC-HC\mpc-hc.exe"
	; // User should customize this exepath to match their own environment.
global g_mpcaot_isNowAlwaysOnTop := false
global g_mpcaot_text_LaunchExe := "Launch MPC-HC (AOT-able)"
global g_mpcaot_text_AlwaysOnTop := "MPC-AOT always on top"
global g_mpcaot_text_SetWindowSize := "MPC-AOT set window size"
; global g_mpcaot_subtext_CustomSize := "200 x 150 (Ctrl+click to customize)" ; change later
global g_mpcaot_custwndsize := { w:160 , h:120 }
	; // User can override this in customize.ahk .

MPC_InitHotkeys()
MpcAot_InitTrayicon()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;==============================================================
;Media Player Classic (MPC) 1.7 
;==============================================================

MPC_IsRunning()
{
	winfound := WinExist("ahk_class MediaPlayerClassicW")
	if(winfound)
		return true
	else
		return false
}

MPC_IsActive()
{
	if(IsWinClassActive("MediaPlayerClassicW"))
		return true
	else
		return false
}

MPC_IsActiveWebcam()
{
	; This function outputs g_mpc_hwndWebcam
	
	WinGet, mpc_hwndcount, COUNT, ahk_class MediaPlayerClassicW
	if(mpc_hwndcount==0)
	{
		g_mpc_hwndWebcam := 
		return false
	}
	
	WinGet, mpc_hwnds, LIST, ahk_class MediaPlayerClassicW
	Loop, % mpc_hwndcount
	{
		hwnd := mpc_hwnds%A_Index%
		WinGetTitle, title, % "ahk_id " hwnd
		if(StrIsStartsWith(title, "Live"))
		{
			g_mpc_hwndWebcam := hwnd
			return true
		}
	}
	g_mpc_hwndWebcam := 
	return false
}


MPC_GetVideoFullpath()
{
	Send ^o ; Open "open file" dialog
	WinWaitActive, % "Open", % "Dub:", 2.0
	if (ErrorLevel)
	{
		MsgBox, % msgboxoption_IconExclamation, 
			,% "Ooops! I can't grab MPC-HC media file's fullpath, the ""Open"" dialog fails to come up."
		return None
	}

	ControlGetText, fullpath, Edit1, A
	Send {Esc} ; Close the dialog
;	WinWaitClose, % "Open", % "Dub:", 2
	WinWaitClose, % "Open", % "Dub" , 1.0
		; Using WinText="Dub:" reduces the chance to match another window whose title starts with "Open".
		; Of course it is not 100% safe-proof, but almost OK.
	
	if (ErrorLevel)
	{
		MsgBox, % msgboxoption_IconExclamation, 
			,% "Ooops! I can't grab MPC-HC media file's fullpath, because there are other window(s) with title ""Open..."", please close those window(s) and try again."
	}

	return fullpath
}

lb_MPC_tooltip_timer:
	MPC_tooltip_timer()
	return
	
MPC_tooltip_timer()
{
	if(g_mpc_txc_string=="")
	{
		SetTimer, lb_MPC_tooltip_timer, Off
		return
	}

	if(MPC_IsActive())
	{
		WinGetTitle, title, A
		if(not InStr(g_mpc_txc_string, title))
		{	; probably  user has opened a new video file
			g_mpc_txc_string := ""
			SetTimer, lb_MPC_tooltip_timer, Off
		}
	}

	MPC_txc_tooltip_display(g_mpc_txc_string)
		; This may hide the tooltip in case MPC is in background.

	g_mpc_was_active := MPC_IsActive() ? true : false
}

MPC_IsRefreshTooltip(newtext)
{
	static s_oldtext
	
	is_active := MPC_IsActive()
	
	if(not is_active) {
		; Don't do extra tooltip turning-off because that has global effect.
		if(not g_mpc_is_tooltip_hidden) {
			tooltip ; turn off the tooltip
			g_mpc_is_tooltip_hidden := true
		}
		return
	}
	
	if( (not g_mpc_was_active and is_active) 
		or (newtext!=s_oldtext) )
	{
		s_oldtext := newtext
		g_mpc_is_tooltip_hidden := false
		return true
	}
	else 
	{
		return false
	}
}

MPC_txc_tooltip_display(text)
{
	; [NOTE A problem]: Everytime tooltip is displayed, the tooltip window flashes,
	; so I just can't call it on every timer tick(eye-distracting).
	if(not MPC_IsRefreshTooltip(text))
		return
	
	ySeekbar := MPC_GetSeekbarY()
	if(ySeekbar>0)
		yShow := ySeekbar-(40*Get_DPIScale())
	else
	{
		WinGetPos, x,y,w,h, A
		yShow := h-30
	}
	tooltip, % text, 10, % yShow
	; PlaySoundRightClick() ; debug
	Clipboard := g_mpc_txc_string
	
	SetTimer, lb_MPC_tooltip_timer, 1000
}

MPC_CalAllSeconds(h, m, s)
{
	return (h*60+m)*60+s
}

MPC_txc_GetPlaytime(wintitle="")
{
	; Return an array:
	; ret[1].hour , ret[1].minute , ret[1].second, ret[1].AllSeconds // this is for total time
	; ret[2].hour , ret[2].minute , ret[2].second, ret[2].AllSeconds // this is for current play time
	; Returning a empty string on failure.
	;

	if(not wintitle)
	{
		; Deduce MPC-HC window title to operate
		WinGet, winid, ID, A ; cache active window unique id
		WinGetClass, class, ahk_id %winid%
		if(class!="MediaPlayerClassicW")
		{
			WinGet, winid, ID, ahk_class MediaPlayerClassicW
		}
		wintitle := "ahk_id " winid
	}

	ControlGetText, mpc_timetext, Static2, %wintitle%
		; Note: On MPC-HC 1.7.8, even if the status bar is hidden, Static2 content is still available.
	
	; mpc_timetext may have two forms
	; First, played time:
	;	02:06 / 24:55
	;	00:02:06 / 01:24:55
	; Second, remaining time:
	;	- 17:19 / 24:55
	;	- 01:17:19 / 01:24:55
	;
	; We have to cope with these four cases.
	
	if(StrIsStartsWith(mpc_timetext, "-"))
	{
		if(RegExMatch(mpc_timetext, "- ([0-9]{2}):([0-9]{2}):([0-9]{2}) / ([0-9]{2}):([0-9]{2}):([0-9]{2})", r)>0)
		{
			remHour := r1 ; rem: remain
			remMinute := r2
			remSecond := r3
			totHour := r4
			totMinute := r5
			totSecond := r6
		}
		else if(RegExMatch(mpc_timetext, "- ([0-9]{2}):([0-9]{2}) / ([0-9]{2}):([0-9]{2})", r)>0)
		{
			remHour := 0
			remMinute := r1
			remSecond := r2
			totHour := 0
			totMinute := r3
			totSecond := r4
		}
		else 
		{
			MsgBox, % msgboxoption_IconExclamation , , % "Unexpected MPC timetext: " mpc_timetext
			return ""
		}
		
		TotSeconds := MPC_CalAllSeconds(totHour, totMinute, totSecond)
		RemSeconds := MPC_CalAllSeconds(remHour, remMinute, remSecond)
		CurSeconds := TotSeconds - RemSeconds
		;
		curSecond := mod(CurSeconds, 60)
		tmp := floor(CurSeconds/60)
		curMinute := mod(tmp, 60)
		curHour := floor(tmp/60)
	}
	else
	{
		
		if(RegExMatch(mpc_timetext, "([0-9]{2}):([0-9]{2}):([0-9]{2}) / ([0-9]{2}):([0-9]{2}):([0-9]{2})", r)>0)
		{
			curHour := r1
			curMinute := r2
			curSecond := r3
			totHour := r4
			totMinute := r5
			totSecond := r6
		}
		else if(RegExMatch(mpc_timetext, "([0-9]{2}):([0-9]{2}) / ([0-9]{2}):([0-9]{2})", r)>0)
		{
			curHour := 0
			curMinute := r1
			curSecond := r2
			totHour := 0
			totMinute := r3
			totSecond := r4
		}
		else 
		{
			MsgBox, % msgboxoption_IconExclamation , , % "Unexpected MPC timetext: " mpc_timetext
			return ""
		}
		TotSeconds := MPC_CalAllSeconds(totHour, totMinute, totSecond)
	}
	;MsgBox, %curHour% / %curMinute% / %curSecond% // %totHour% / %totMinute% / %totSecond% ; debug
	
	CurSeconds := MPC_CalAllSeconds(curHour, curMinute, curSecond)
	
	ret := Object()
	ret.Insert({"hour":totHour, "minute":totMinute, "second":totSecond, "AllSeconds":TotSeconds})
	ret.Insert({"hour":curHour, "minute":curMinute, "second":curSecond, "AllSeconds":CurSeconds})
	return ret
}

MPC_txc_GetCurrentPlaytimeTxc()
{
	; Txc means "in chjtranscode foramt" 
	; Example:
	;	0233	// means 02:33
	;   010233	// means 01:02:33
	times := MPC_txc_GetPlaytime()
	if(not times)
		return ""
		
	if(times[2].hour==0)
		return Format("{1:02d}{2:02d}", times[2].minute, times[2].second)
	else
		return Format("{1:02d}{2:02d}{3:02d}", times[2].hour, times[2].minute, times[2].second)
}

MPC_txc_append_left()
{
	WinGetTitle, video_filename, A ; MPC's title is the playing filename (without path prefix)
	
	if(not InStr(g_mpc_txc_string, video_filename))
	{
		; set g_mpc_txc_string to a the new video fullpath
		g_mpc_txc_string := MPC_GetVideoFullpath()
	}
	
	if(g_mpc_txc_string ~= "-]$") ; already ends with "-]" (already has a left part)
	{
		; Example:
		;	P:\rec\20150313xxx.mpg[0010-0022][0045-]
		;
		; So remove the old left-part first, resulting in 
		;	P:\rec\20150313xxx.mpg[0010-0022]
		g_mpc_txc_string := RegExReplace(g_mpc_txc_string, "\[[^\[]+-]$", "")
	}
	
	; now append the new left-part
	txc_playtime := MPC_txc_GetCurrentPlaytimeTxc()
	g_mpc_txc_string .= "[" txc_playtime "-]"
	MPC_txc_tooltip_display(g_mpc_txc_string)
}

MPC_txc_append_right()
{
	WinGetTitle, video_filename, A ; MPC's title is the playing filename (without path prefix)
	
	if(not InStr(g_mpc_txc_string, video_filename))
	{
		; set g_mpc_txc_string to a the new video fullpath
		g_mpc_txc_string := MPC_GetVideoFullpath()
	}

	if(StrIsEndsWith(g_mpc_txc_string, video_filename)) ; no starting time(left-part) assigned yet
	{
		; Make it something like:
		;	P:\rec\20150313xxx.mpg[-0011]
		g_mpc_txc_string := g_mpc_txc_string "[-]" ; 
	}
	else if(g_mpc_txc_string ~= "[0-9]]$") ; (already has a right part)
	{
		; Example:
		;	P:\rec\20150313xxx.mpg[0010-0022]
		;
		; So remove the old right-part first, resulting in 
		;	P:\rec\20150313xxx.mpg[0010-]
		g_mpc_txc_string := RegExReplace(g_mpc_txc_string, "-[0-9]+]$", "-]")
	}
	
	; now append the new right-part
	txc_playtime := MPC_txc_GetCurrentPlaytimeTxc()
	g_mpc_txc_string := RegExReplace(g_mpc_txc_string, "]$", txc_playtime "]")
	MPC_txc_tooltip_display(g_mpc_txc_string)
}

MPC_txc_remove_finalpart()
{
	; Example input(g_mpc_txc_string):
	;	P:\rec\20150313xxx.mpg[0010-0022][0045-3030]
	; Example output(g_mpc_txc_string):
	;	P:\rec\20150313xxx.mpg[0010-0022]

	g_mpc_txc_string := RegExReplace(g_mpc_txc_string, "\[[^\[\]]+]$", "")
	MPC_txc_tooltip_display(g_mpc_txc_string)
}


MPC_GetSeekbarY()
{
	pos := MPC_GetSeekbarPos()
	if(pos)
		return pos.y + pos.h - 2
	else
		return None
}

MPC_GetSeekbarPos(xhint:=0)
{
	WinGet, mpc_winid, ID, A ; cache active window unique id
	mpc_title := "ahk_id " mpc_winid

	WinGetPos, winx,winy,winw,winh, % mpc_title
	if(xhint==0) 
	{
		; If current mouse X in active window, use that X(use relative)
		; else, use middle position.
		MouseGetPos, xRela,,, classnn
		if(xRela>=0 and xRela<winw)
			xhint := xRela
		else
			xhint := winw/2

;		tooltip, xhint=%xhint% / xRela=%xRela%
	}

	; Find the seek bar automatically, assuming it to be exactly above the control bar.
	; Video viewport classnn is "Afx:XXXXXX" (dynamic)
	; Seekbar classnn is something like "#327704" (dynamic)
	; Control bar(the one with Play/Stop button) classnn is "ToolbarWindow321"
	ControlGetPos, x, yControlbar, width, height, ToolbarWindow321, % mpc_title
	if(yControlbar>5)
	{
		ySeekbar := yControlbar-5
		classnnSeekbar := GetActiveClassnnFromXY(xhint, ySeekbar)
			; Use xhint so that mouse pointer can avoid unnecessary moves inside GetActiveClassnnFromXY().
		if ( not classnnSeekbar ~= "^Afx:" )
		{
			ControlGetPos, seekx,seeky,seekw,seekh, %classnnSeekbar%, %mpc_title%
			return {"x":seekx, "y":seeky, "w":seekw, "h":seekh}
		}
		else
			return None
	}
	else 
	{
		return None ; indicate failure
	}
}

MPC_ClickToSeek(xpct, uy=0)
{
	MPC_ClickToSeek_condition(xpct, uy, "")
}

MPC_ClickToSeek_condition(xpct, uy, proc_condition)
{
	; xpct: x percent, 0 ~ 100

	if(proc_condition)
	{
		if not %proc_condition%()
			return
	}

	; Check if right-Ctrl or left-Ctrl is pressed.
	; Only right-Ctrl will fire the click-to-seek behavior.
	isLCtrl := GetKeyState("LCtrl") 
	isRCtrl := GetKeyState("RCtrl") 
	
	if(isLCtrl) {
		; left-Ctrl pressed, just fire the default Ctrl+[?] function and return
		Send %A_ThisHotkey%
		return 
		; [2016-02-08] Implementation note:
		; I do not use > prefix to indicate "right-side" ctrl because 
		; there is a problem I cannot solve yet. See 
		; http://superuser.com/questions/1035609/autohotkey-right-side-prefix-out-of-bound-effect-correct-behavior
	}

	if(xpct<0 or xpct>100)
	{
;		MsgBox, % "MPC_ClickToSeek(): Wrong xpct=" xpct " (should be 0 ~ 100)."
		return
	}
	xpct := xpct/100 ; convert 1~100 to 0.01~0.99 // As of 1.1.19.02, I cannot write ``xpct /= 100``, which is floor division
	
	; If uy>=0, x offset from top border; if uy<0, x offset from bottom border.
	WinGetPos, x, y, width, height, A
	If (uy>0)
	  clicky := uy
	Else If (uy<0)
	  clicky := height+uy
	Else {
;		clicky := MPC_GetSeekbarY()
		seekbarPos := MPC_GetSeekbarPos()
		if(not seekbarPos) {
			MsgBox, To click onto MPC seek-bar, please enable "View → Seek bar" and "View → Controls"
			return
		}
		x := seekbarPos.x
		width := seekbarPos.w
		clicky := seekbarPos.y + seekbarPos.h - 5
	}

	clickx := x + width * xpct
	MouseMove, %clickx%, %clicky%
	Click %clickx%, %clicky%
	PlaySoundLeftClick()
}


MPC_InitHotkeys()
{
	MPC_DefineHotkeysSeekPercents()
	
	dev_DefineHotkeyWithCondition("~^LButton", "MpcAot_IsActive", "MpcAot_ShowSizingMenu_LButton")
}

MPC_cond_F1toF9Seek()
{
	is_on := GetKeyState("NumLock", "T")
	if(is_on) {
		dev_TooltipAutoClear("Doing F1...F9 seeking when NumLock is on.")
		return true
	} else {
		dev_TooltipAutoClear("F1...F9 seeking is disabled when NumLock is off.")
		return false
	}
}

MPC_DefineHotkeysSeekPercents()
{
	; Effect: Right CTRL + 0-9 to quick seek to predefined percent.
	; So, to execute normal Ctrl+<key>, use left Ctrl instead.
	hotchars := "123456789"
	Loop, parse, hotchars
	{
		dev_DefineHotkeyWithCondition("^" A_LoopField, "MPC_IsActive", "MPC_ClickToSeek", A_LoopField*10)
		
		; And F1~F9 to be 10% ~ 90%
		dev_DefineHotkeyWithCondition("F" A_LoopField, "MPC_IsActive", "MPC_ClickToSeek_condition", A_LoopField*10, 0, "MPC_cond_F1toF9Seek")
	}
	dev_DefineHotkeyWithCondition("^``", "MPC_IsActive", "MPC_ClickToSeek", "2.5") ; ` is escaped, double typing it
	dev_DefineHotkeyWithCondition("^0", "MPC_IsActive", "MPC_ClickToSeek", "97.5")

/*
	; For English keyboard, quick seek to 5pct, 15pct, 25pct, 95pct etc.
	dev_DefineHotkeyWithCondition("^Tab", "MPC_IsActive", "MPC_ClickToSeek", "5")
	dev_DefineHotkeyWithCondition("^q", "MPC_IsActive", "MPC_ClickToSeek", "15")
	dev_DefineHotkeyWithCondition("^w", "MPC_IsActive", "MPC_ClickToSeek", "25")
	dev_DefineHotkeyWithCondition("^e", "MPC_IsActive", "MPC_ClickToSeek", "35")
	dev_DefineHotkeyWithCondition("^r", "MPC_IsActive", "MPC_ClickToSeek", "45")
	dev_DefineHotkeyWithCondition("^t", "MPC_IsActive", "MPC_ClickToSeek", "55")
	dev_DefineHotkeyWithCondition("^y", "MPC_IsActive", "MPC_ClickToSeek", "65")
	dev_DefineHotkeyWithCondition("^u", "MPC_IsActive", "MPC_ClickToSeek", "75")
	dev_DefineHotkeyWithCondition("^i", "MPC_IsActive", "MPC_ClickToSeek", "85")
	dev_DefineHotkeyWithCondition("^o", "MPC_IsActive", "MPC_ClickToSeek", "95")
*/
}


MPC_MoveWebcamWindow(idmonitor, xhint:=0, yhint:=0, width:=0, height:=0, isAlwaysOnTop:=false)
{
	/*
	Usage example: 
		
	MPC_MoveWebcamWindow(1, -320, -240, 320, 240, true) 
		; Move Webcam window to down-right corner of your main monitor and make it always on top.
		; The new window size is 320x240
		
	MPC_MoveWebcamWindow(2, -320, 0, 320, 240)
		; Move Webcam window to up-right corner of your second monitor.

	MPC_MoveWebcamWindow(0)
		; Send Webcam window Z-order bottom, but remain its position.
	*/
	
	if(not MPC_IsActiveWebcam())
	{
		MsgBox, % msgboxoption_IconExclamation, , % "MPC_MoveWebcamWindow(): No MPC Webcam window exists"
		return None
	}
	mpc_hwnd := g_mpc_hwndWebcam
	
	if(idmonitor==0)
	{
		Winset, Bottom, , ahk_id %mpc_hwnd%
		;Winset, AlwaysOnTop, Off, ahk_id %mpc_hwnd%
		return mpc_hwnd
	}
	
	if(width>0 and height>0)
	{
		wa := GetMonitorWorkArea(idmonitor)
		if(not wa)
		{
			MsgBox, % msgboxoption_IconExclamation, , % "MPC_MoveWebcamWindow(): invalid idmonitor=" idmonitor
			return None
		}
		
		xpos := NewCoordFromHint(wa.left, wa.width, xhint)
		ypos := NewCoordFromHint(wa.top, wa.height, yhint)
		
;		msgbox, %xpos% / %ypos% / %width% / %height%
		WinMove, ahk_id %mpc_hwnd%,, %xpos%, %ypos%, %width%, %height%
	}
	
	WinActivate, ahk_id %mpc_hwnd%
	
	if(isAlwaysOnTop)
		Winset, AlwaysOnTop, On, ahk_id %mpc_hwnd%
	else
		Winset, AlwaysOnTop, Off, ahk_id %mpc_hwnd%
	
	return mpc_hwnd
}



#If MPC_IsActive()

/* These are replaced by MPC_DefineHotkeysSeekPercents()
^`:: MPC_ClickToSeek(0.5/10)
^1:: MPC_ClickToSeek(1/10)
^2:: MPC_ClickToSeek(2/10)c
^3:: MPC_ClickToSeek(3/10)
^4:: MPC_ClickToSeek(4/10)
^5:: MPC_ClickToSeek(5/10)
^6:: MPC_ClickToSeek(6/10)
^7:: MPC_ClickToSeek(7/10)
^8:: MPC_ClickToSeek(8/10)
^9:: MPC_ClickToSeek(9/10)
^0:: MPC_ClickToSeek(9.5/10)
^-:: MPC_ClickToSeek(9.75/10)
*/

^!0:: Send ^0 ; hide MPC window menu/title/border
^!1:: Send ^1 ; toggle seek bar # #32770
^!2:: Send ^2 ; toggle play/pause/stop control # ToolbarWindow32
^!3:: Send ^3 ; toggle information
^!4:: Send ^4 ; toggle statistics # #32770
^!5:: Send ^5 ; toggle status bar # #32770
^!6:: Send ^6 ; Sub resync
^!7:: Send ^7 ; toggle  playlist
^!8:: Send ^8 ; toggle capture-device control
^!9:: Send ^9 ; toggle navigation


; Ctrl+, go back 2%, Ctrl+. go forward 2%
; Prerequisite: mouse should have been on the seek bar
MPC_ClickShift_Xpct(add_pct)
{
	; add_pct can be positive or negative
	WinGetPos, x, y, winwidth, height, A
													;MouseGetPos origx, origy
	times := MPC_txc_GetPlaytime()
	if(not times)
	{
		MsgBox, % "Unexpected! Cannot get current playtime from status bar."
		return
	}
	
	orig_pct := 100 * times[2].AllSeconds / times[1].AllSeconds
	
	MPC_ClickToSeek(orig_pct+add_pct)
}


MPC_PasteCurrentPlaytime(wintitle="")
{
	str := MPC_GetCurrentPlaytimeStr(wintitle)
	if(str)
	{
		; memo: WinClip.Paste will not destroy original clipboard content
		; But strange, I have to use two trailing spaces to get one.
		WinClip.Paste(Format("[{}]  ", str)) 
	}
}

MPC_CurrentPlaytimeToClipboard(wintitle="")
{
	str := MPC_GetCurrentPlaytimeStr(wintitle)
	if(str) {
		is_ok := dev_SetClipboardWithTimeout(str, 2000)
		if(is_ok)
			return str
	}
	return ""
}
MPC_GetFriendlyCurrentPlayTime(wintitle="")
{
	return MPC_GetCurrentPlaytimeStr(wintitle)
}
MPC_GetCurrentPlaytimeStr(wintitle="")
{
	ret := MPC_txc_GetPlaytime(wintitle)
	if(not ret)
		return "" ; fail
	
	hour := ret[2].hour
	minute := ret[2].minute
	second := ret[2].second
	
	if(hour==0)
		retstr := Format("{1:02d}:{2:02d}", minute, second)
	else
		retstr := Format("{1:02d}:{2:02d}:{3:02d}", hour, minute, second)

	return retstr
}

MPC_CopyToClipboardFriendlyCurrentPlayTime()
{
	timestr := MPC_GetFriendlyCurrentPlayTime()
	if(timestr)
		prompt := timestr " - current playtime copied to clipboard."
	else
	{
		prompt := "Error fetching current playtime. You may try again."
		dev_TooltipAutoClear(prompt, 2000)
		return
	}

	is_ok := dev_SetClipboardWithTimeout(timestr)
	if(not is_ok) {
		prompt := "Unexpected: Error put clipboard. You may try again."
	}
	dev_TooltipAutoClear(prompt, 2000)
}


F1:: MPC_CopyToClipboardFriendlyCurrentPlayTime()

; Ctrl+, seek backward %2 , Ctrl+. seek forward %2
^,:: MPC_ClickShift_Xpct(-2)
^.:: MPC_ClickShift_Xpct(2)
NumpadDiv::  MPC_ClickShift_Xpct(-2)
NumpadMult:: MPC_ClickShift_Xpct(2)
; Alt+, seek backward %1 ,  Alt+. seek forward %1
!,:: MPC_ClickShift_Xpct(-1)
!.:: MPC_ClickShift_Xpct(1)
; , . backward/forward 5 seconds
,:: Send {Left} 
.:: Send {Right} ; override MPC-HC's default(stop playing)



[:: MPC_txc_append_left()
]:: MPC_txc_append_right()
Backspace:: MPC_txc_remove_finalpart()

Pgup:: MPC_PromptDisablePgupPgdn()
Pgdn:: MPC_PromptDisablePgupPgdn()

MPC_PromptDisablePgupPgdn()
{
	dev_TooltipAutoClear("PgUp/Dn key is disabled by Chj to avoid accidentally jump to Prev/Next audio/video.")
}

#If


MPC_Bg_Back5sec(showtip:=false)
{
	WinGet, winid, ID, ahk_class MediaPlayerClassicW ; cache MPC window unique id
	dev_SendKeyToExeMainWindow("{Left}", "ahk_id " winid)
	if(showtip)
		dev_TooltipAutoClear("MPC back 5 sec [" MPC_GetCurrentPlaytimeStr("ahk_id " winid) "]")
}
MPC_Bg_Forward5sec(showtip:=false)
{
	WinGet, winid, ID, ahk_class MediaPlayerClassicW ; cache MPC window unique id
	dev_SendKeyToExeMainWindow("{Right}", "ahk_id " winid)
	if(showtip)
		dev_TooltipAutoClear("MPC forward 5 sec [" MPC_GetCurrentPlaytimeStr("ahk_id " winid) "]")
}
MPC_Bg_PausePlay(showtip:=false, bringfront:=false)
{
	if(showtip)
		dev_TooltipAutoClear("MPC Pause/Play")

	WinGet, winid, ID, ahk_class MediaPlayerClassicW ; cache MPC window unique id
	dev_SendKeyToExeMainWindow("{Space}", "ahk_id " winid)
	
	if(bringfront)
	{
		WinGet, Awinid, ID, A ; cache active window unique id
		WinActivate, ahk_class MediaPlayerClassicW
		Sleep, 0.2
		WinActivate, ahk_id %Awinid%
	}
}

MPC_Bg_PausePlay_front(showtip:=false)
{
	MPC_Bg_PausePlay(showtip, true)
}


;==================================================================
; 2020-06-10
; Add AHK tray icon menu to Enable/Disable MPC-HC always on top. 
; We start a timer to ensure its always-on-top(AOT), for example,
;  on top of a full-screen VMware Workstation VM window.
;==================================================================

MpcAot_GetHwnd(is_offer_launch:=false)
{
	; Would return (first-matching) MPC-HC's hwnd
	hwnd_mpc := dev_GetHwndByExepath(g_mpcaot_exepath)
	
	if (hwnd_mpc) 
	{
		return hwnd_mpc
	}
	else 
	{
		if(is_offer_launch) 
		{
			Run, % g_mpcaot_exepath, , UseErrorLevel
			if not ErrorLevel
			{
				Loop, 10
				{
					hwnd_mpc := MpcAot_GetHwnd(false)
					if (hwnd_mpc)
						return hwnd_mpc
					else
						Sleep, 500
				}
				MsgBox, % Format("Unexpected! Tried to launch  MPC-HC exe at path {} , but failed to see its window.", g_mpcaot_exepath)
				return None
			}
			else 
			{
				MsgBox, % Format("Cannot launch MPC-HC exe at path {}.", g_mpcaot_exepath)
				return None
			}
		}
		else 
		{
			return None
		}
	}
	return None
}

MpcAot_GetRect()
{
	hwnd := MpcAot_GetHwnd()
	if(!hwnd)
		return false
	
	WinGetPos, x, y, width, height, ahk_id %hwnd%
	
	mpcrect := { left:x, top:y, right:x+width, bottom:y+height }
	return mpcrect
}

MpcAot_CustomMenuSize_MakeText(width, height)
{
	return Format("{} x {} (Ctrl+click to customize)", width, height)
}

MpcAot_InitTrayicon()
{
	Menu, TRAY, add  ; Creates a separator line.
	Menu, TRAY, add, %g_mpcaot_text_LaunchExe%, MpcAot_LaunchExe  ; Creates a new menu item.
	Menu, TRAY, add, %g_mpcaot_text_AlwaysOnTop%, MpcAot_ToggleAlwaysOnTop

	;
	; Set window size menu/submenu items
	;
	; Define submenu item list:
	custtext := MpcAot_CustomMenuSize_MakeText(g_mpcaot_custwndsize.w, g_mpcaot_custwndsize.h)
	Menu, mpcpop_SetWindowSize, add, % custtext, MpcAot_SetCustomWindowSize
	Menu, mpcpop_SetWindowSize, add, % "200 x 150", MpcAot_Set200x150
	Menu, mpcpop_SetWindowSize, add, % "320 x 240", MpcAot_Set320x240
	Menu, mpcpop_SetWindowSize, add, % "640 x 480", MpcAot_Set640x480
	; Attach submenu to main menu
	Menu, tray, add, % g_mpcaot_text_SetWindowSize, :mpcpop_SetWindowSize
}
	

MpcAot_LaunchExe()
{
	hwnd_mpc := MpcAot_GetHwnd(true)

	WinActivate, % "ahk_id " hwnd_mpc
	
	MpcAot_SetAlwaysOnTop(true)
}

MpcAot_SetAlwaysOnTop(isset)
{
	hwnd := MpcAot_GetHwnd()

	if(isset)
	{
;		g_mpcaot_isNowAlwaysOnTop := true
		WinSet, AlwaysOnTop, On, % "ahk_id " hwnd
		
		Menu, TRAY, Check, %g_mpcaot_text_AlwaysOnTop%
		SetTimer, _MPC_timer_EnableAOT, 500
	}
	else
	{
;		g_mpcaot_isNowAlwaysOnTop := false
		WinSet, AlwaysOnTop, Off, % "ahk_id " hwnd
		
		Menu, TRAY, UnCheck, %g_mpcaot_text_AlwaysOnTop%
		SetTimer, _MPC_timer_EnableAOT, Off
	}
}

MpcAot_PromptNotLaunched()
{
	MsgBox, % Format("MPC-HC at {} has not launched yet.", g_mpcaot_exepath)
}

MpcAot_ToggleAlwaysOnTop()
{
	g_mpcaot_isNowAlwaysOnTop := !g_mpcaot_isNowAlwaysOnTop
	
	if(!MpcAot_GetHwnd()) {
		g_mpcaot_isNowAlwaysOnTop := false
		MpcAot_PromptNotLaunched()
	}
	
	MpcAot_SetAlwaysOnTop(g_mpcaot_isNowAlwaysOnTop)
	
}

_MPC_timer_EnableAOT()
{
	hwnd_mpc := dev_GetHwndByExepath(g_mpcaot_exepath)
	if(hwnd_mpc)
	{
		WinSet, AlwaysOnTop, On, % "ahk_id " hwnd_mpc
	}
}

MpcAot_IsActive()
{
	return dev_IsExeActive(g_mpcaot_exepath)

;	WinGet, Awinid, ID, A ; cache active window unique id
;	WinGet, exepath, ProcessPath, ahk_id %Awinid%
;	
;	if(exepath==g_mpcaot_exepath)
;		return true
;	else
;		return false
}

#If MpcAot_IsActive()

ESC:: MPC_BlockEscIfAOT()
MPC_BlockEscIfAOT()
{
	; Do nothing. (=Disable ESC key)
	; Reason: When MPC-HC is in borderless mode(press Ctrl+0 several times), ESC will bring back the border.
	; When AOT displaying a webcam content in borderless mode, we probably don't want to see the border.
	dev_TooltipAutoClear("AHK: ESC key is blocked for this MPC-HC window.")
}

#If

MpcAot_Set200x150()
{
	MpcAot_SetWindowSize(200, 150)
}
MpcAot_Set320x240()
{
	MpcAot_SetWindowSize(320, 240)
}
MpcAot_Set640x480()
{
	MpcAot_SetWindowSize(640, 480)
}

MpcAot_SetWindowSize(width, height)
{
	hwnd_mpc := dev_GetHwndByExepath(g_mpcaot_exepath)
	if(!hwnd_mpc)
	{
		MpcAot_PromptNotLaunched()
		return
	}
	
	dev_TooltipAutoClear(Format("Set MPC-AOT window size to {},{}", width, height))
	
	dev_SetWindowSize_StickCorner(hwnd_mpc, width, height)
}

MpcAot_SetCustomWindowSize()
{
	hwnd_mpc := dev_GetHwndByExepath(g_mpcaot_exepath)
	if(!hwnd_mpc)
	{
		MpcAot_PromptNotLaunched()
		return
	}

	cs := g_mpcaot_custwndsize ; create a short-name reference to the global var
	cs_oldmenutext := MpcAot_CustomMenuSize_MakeText(cs.w, cs.h)

	s2 := Format("{},{}", cs.w, cs.h)

	isshift := GetKeyState("Shift")
	isctrl := GetKeyState("Ctrl")
;	msgbox, % Format("shift: {} , ctrl: {}", isshift, isctrl)

	if(isctrl)
	{
		; Pop-up a message box for new width,height value
		InputBox, s2, % "mediaplayer.ahk", % "Input new width,height for MPC-HC window", , 300, 150, , , , , % s2
		If ErrorLevel
			return
		
		n := StrSplit(s2, ",")
		w := n[1]
		h := n[2]
		if(! (w>=100 and h>=100) ) {
			MsgBox, % "Invalid input! Two values should both >= 100"
			return
		}
		cs.w := w
		cs.h := h
	}
	
	cs_newtext := MpcAot_CustomMenuSize_MakeText(cs.w, cs.h)
	
	Menu, mpcpop_SetWindowSize, Rename, % cs_oldmenutext, % cs_newtext
	
;	WinGet, winid, ID, % "ahk_id " hwnd_mpc
;	dev_WinMove_with_backup("", "", cs.w, cs.h, winid)
	MpcAot_SetWindowSize(cs.w, cs.h)
}


MpcAot_ShowSizingMenu_LButton()
{
	isok := MpcAot_ShowSizingMenu()
	
;	if(!isok) {
;		[2020-07-30] Well, I just don't know how to relay Ctrl+click to non-MPC-AOT programs transparently.
;		So I just used "~^LButton" when calling dev_DefineHotkey()
;	
;		dev_TooltipAutoClear("Sendddd.... Click")
;		Send ^Click
;	}
}

MpcAot_ShowSizingMenu()
{
	CoordMode, Mouse, Screen
	MouseGetPos, mx, my

	mpcrect := MpcAot_GetRect()
	if(!mpcrect)
		return false

	if( dev_XYinRect(mx, my, mpcrect) )
	{
		Menu, mpcpop_SetWindowSize, show
		
		return true
	}
	else
	{
		; [2020-07-30] AHK 1.1.32 on Win10.1909: 
		; Memo: If we right-click MPC to bring up its context menu and trigger this function, 
		; the mpcrect will be the Rect of the popped-up context menu, not the MPC's real window.
		; That is not a problem.

;		dev_TooltipAutoClear(Format("Ctrl+click not in MPC-AOT window. mx={} , my={} , rect={}/{}/{}/{}"
;			, mx, my, mpcrect.left, mpcrect.top, mpcrect.right, mpcrect.bottom)) ; debug

		return false
	}
}


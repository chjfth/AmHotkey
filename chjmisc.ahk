; Note: This file is saved with UTF8 with BOM, which is the best encoding choice to write Unicode chars here.

AUTOEXEC_chjmisc_ahk: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

; Something to place here.
; * Customize these global vars according to your running machine:
; * Call the run-once functions.

; Example
;g_dirEverpic = D:\chj\scripts\everpic

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;==============================================================================
; Some hotstring auto-replace
;==============================================================================

; Auto-replace `1 to be 192.168. -- easy typing those IP addresses.
; Note: You have to double ` here. ``1 means triggering chars `1 
; memo: [*] no need to post-type a space to trigger, 
;       [?] no need to prefix a wordchar to trigger
:*:``1::192.168.
:*:``2::172.27.
:*:``q::Q:{space}
:?*:;;::`:{space}

; Type ``t to get _T("") , or ``y to get _T(''),, then move the caret back inside the quotes
:*:````t::_T(""){left}{left}
:*:````y::_T(''){left}{left}

; Type ``pp to get pprint.pprint (python)
:*:````pp::from pprint import pprint as pp

; Type:
;	 ``!
; Get HTML comment block.
;	<!-- -->
:?*:````!::<{!}--  -->{left}{left}{left}{left}


; <<>> makes Chinese ShuMingHao
:?*:<<>>::《》{space}
:?*:``ss::《》{space}

; Type #! to insert a shebang line in .py script.
; b0 means no erase already typed #! // [2018-11-25] I forgot this shortcut bcz it is not led by my accustomed ``
;           :*Rb0:#!::/usr/bin/env python3 #-*- coding: utf-8 -*-

; Type ``# to insert a shebang line in .py script (AHK 1.1.24.05 ok).
; Thanks to https://superuser.com/a/1378252/74107
:*:`````#:: ; Yes, function calling should be on a separate line.
type_python_shebang()
type_python_shebang()
{
	SendInput {Raw}
	(
#!/usr/bin/env python3
#coding: utf-8

	)
}
; A more verbose way is:
;	:*:`````#::`{#`}`{!`}/usr/bin/env python3{enter}`{#`}coding: utf-8{enter}
;


; Type ``u to insert Python utf-8 heading
; R means raw, no re-interpreting # : etc, otherwise, a # causes Win key to be sent.
:*R:````u::#-*- coding: utf-8 -*-


;==============================================================================
; Clipcache 3.4
;==============================================================================
#If IsWinClassActive("ClipCacheWindowClass")

CapsLock & Left:: ControlFocus, SysTreeView321, A

CapsLock & Up:: ControlFocus, SysListView321, A
CapsLock & Right:: ControlFocus, SysListView321, A

CapsLock & Down:: ControlFocus, RichEdit20W1, A


#If




;==============================================================
; Dreamweaver CS5
;==============================================================
; 2013-09-25 F12: Click into select CSS style combobox
#IfWinActive ahk_class _macr_dreamweaver_frame_window_
F12:: 
MouseGetPos origx, origy
ClickInActiveWindow(340, -133)
MouseMove origx, origy
return
#IfWinActive
; Historical note: 
; In case you use Ctrl+Win+0, you probably should add:
;#^0:: return ; otherwise, Ctrl+Win+0 will act as Win+0 (This workaround is great)




;==============================================================
; VLC Media Player 
; Note: Many apps use "QWidget" class, so check IsWinTitleMatchRegex() is required.
;==============================================================

; 2013-11-11, VLC 2.0 Loop A-B button hotkey
#If IsWinClassActive("QWidget") && IsWinTitleMatchRegex("VLC")
PrintScreen:: ClickInActiveWindow(90, -50)
#If




;==============================================================
; Skype 6.x/7.x , Swap Enter & Ctrl+Enter, so Ctrl+Enter to send message.
; Note: Skype 8.x start using Chromium framework UI.
;==============================================================
skype_IsChsIMEActive()
{
	if WinExist("ahk_class PYJJ_COMPUI_WND") ; Pinyin JiaJia 
		return true
	else
		return false
}

Is_Skype8Active()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%

	if( class=="Chrome_WidgetWin_1" and title=="Skype" )
	{
		return true
	}
	else
	{	
		return false
	}
}

#If WinActive("ahk_class tSkMainForm") or Is_Skype8Active()

Enter::
	if(skype_IsChsIMEActive()) 
	{
		; If doing Pinyin JiaJia input(IME floating window on screen), don't change Enter
		; dev_TooltipAutoClear("[Enter] PYJJ_COMPUI_WND active", 1000)
		SendInput {Enter}
	}
	else 
	{
		SendInput ^{Enter}
	}
return

^Enter:: 
	KeyWait, Ctrl ; Wait until Ctrl is released
	SendInput {enter}
return

#IfWinActive 


;==============================================================
;2014-05-09 VMware Workstation 10
;==============================================================
#IfWinActive ahk_class VMUIFrame

; Ctrl+F9 click into "Library" search box
^F9::
	ClickInActiveControl("Edit1", -2, -2)
return

^/:: 
	; Move mouse to right-bottom corner(device connect/disconnect controls there)
	; so easy to use keybad mouse there.
	MouseMoveInActiveWindow(-68, -14)
	ModifyMouseNudgeUnitAM(21)
return 

#IfWinActive


#IfWinActive ahk_class VMPlayerFrame

F1:: vmrc_ClickRemoteConsoleMenu()
vmrc_ClickRemoteConsoleMenu()
{
	; Click the button written as VMRC
	ClickInActiveControl("xui::TForm3", 0.5, 0.5)
}

#IfWinActive



;==============================================================
;2016-03-03 Everything 1.3.4
;==============================================================
#IfWinActive ahk_class EVERYTHING

Up::   Everything_SmartUpDown("Up")
Down:: Everything_SmartUpDown("Down")
PgUp:: Everything_SmartUpDown("PgUp")
PgDn:: Everything_SmartUpDown("PgDn")
Everything_SmartUpDown(keyname)
{
	ControlGetFocus, focusNN, A
	if(focusNN=="Edit1")
	{
		SendInput {Tab}
	}
	SendInput {%keyname%}
}

#IfWinActive ; ahk_class EVERYTHING




;;;;;;;;; Some commonly used path string operation ;;;;;;;;;;
+^':: DlgManipulatePathString() ; Ctrl+Shift+'
DlgManipulatePathString()
{
	g_clipboard_cache := Clipboard
	If not g_clipboard_cache {
		MsgBox, No text in clipboard, nothing to do.
		return
	}
	
	; Trim the extra long(if so) clipboard content within around 1024 chars, and 10 lines.
	; because I will prompt them on an input dialog, so avoiding a giant dialog.
	max_preview_len = 1024
	if StrLen(g_clipboard_cache)<=max_preview_len
		clip_preview := g_clipboard_cache
	else 
	{
		clip_preview := RegExReplace(g_clipboard_cache, "s)^(.{1," . max_preview_len . "})(.*)", "$1")
			; ``s)`` options means DOTALL, dot matches \n
		clip_preview := RegExReplace(clip_preview, "s)(([^\n]*\n){1,10})(.*)", "$1")
		if (clip_preview!=g_clipboard_cache)
			clip_preview .= "..."
	}
	
	static OpNums
	static ClipboardPreview
	Gui, pathop:New ; This New is required, otherwise, a second call of this will assert error
	Gui, pathop:Font, s9 cBlack, Tahoma
	Gui, pathop:Add, Text, , % "剪贴板中的文字共 " . StrLen(g_clipboard_cache) . " 个字符 :"
	Gui, pathop:Font, cBlue
	Gui, pathop:Add, Text, , %clip_preview%
	Gui, pathop:Font, s8 cBlack
	Gui, pathop:Add, Text, ,
(
选择如何转换剪贴板中的文字:

1. 两侧添加双引号 "..."
2. 去除两侧双引号

3. 使用正斜杠 / 作为路径分隔符
4. 使用反斜杠 \ 作为路径分隔符
5. 使用双反斜杠 \\ 作为路径分隔符

n. 使用单个 \n 作为换行符

输入范例 "1" "2" "3" "14" "15" "23n"
)
	Gui, pathop:Add, Edit, w50 vOpNums, %g_pathop_last_numop%
	Gui, pathop:Add, Button, default, OK  ; The label ButtonOK (if it exists) will be run when the button is pressed.
	Gui, pathop:Show, , Autohotkey prompt
	return

pathopButtonOK:
	Gui, pathop:Submit ; OpNums updated
	
	LFonly := InStr(OpNums, "n") ? true : false
	
	rtest12 := RegExReplace(OpNums, "[^12]", "")
	if StrLen(rtest12)>1 {
		MsgBox, % "输入错误！只能指定 1 2 其中之一。"
		return
	}
	rtest345 := RegExReplace(OpNums, "[^345]", "")
	if StrLen(rtest345)>1 {
		MsgBox, % "输入错误！只能指定 3 4 5 其中之一。"
		return
	}
	
	if (rtest12=="" && rtest345=="") { ; need brackets here
		MsgBox, % "没有提供有效输入。"
		return
	}
	
	g_pathop_last_numop := OpNums
	g_clipboard_cache := RTrim(g_clipboard_cache, "`n") 
		; I need this trick here: trim trailing \n , so that a clipboard content like "abc\n" will loop only once.
	new_clipboard := ""
	Loop, parse, g_clipboard_cache, `n , `r
	{
		newline := A_LoopField
		ahk_dbquote = "
		ptn_quoted := "^" . ahk_dbquote . "(.*)" . ahk_dbquote . "$"
		;MsgBox, ptn_quoted=%ptn_quoted%
		if (rtest12=="1") {
			if RegExMatch(newline, ptn_quoted)==0 ; if not already quoted
				newline := ahk_dbquote . newline . ahk_dbquote
		}
		else if (rtest12=="2") {
			newline := RegExReplace(newline, ptn_quoted, "$1")
		}
		
		; Sample input:
		; X:\a\\b/c//d\\\e///f.txt
		if (rtest345=="3") { ; to /
			StringReplace, newline, newline, \ , / , All
			newline := RegExReplace(newline, "/+", "/") ; remove duplicate
		}
		else if (rtest345=="4"||rtest345=="5") { ; to \
			StringReplace, newline, newline, / , \ , All
			newline := RegExReplace(newline, "\\+", "\") ; remove duplicate
			if (rtest345=="5") {
				StringReplace, newline, newline, \ , \\ , All ; doubles \
			}
		}
		
		new_clipboard .= newline . (LFonly ? "`n" : "`r`n")
	}
	
	Clipboard := new_clipboard
	
	; fall down to Gui,Destroy
pathopGuiClose:
pathopGuiEscape:
	Gui, pathop:Destroy
	return
}


;==============================================================================
; MSDN 2008
;==============================================================================

; Virtual key-code 226(0xE2) is the Central Europe extra \ key at the left-side of 'Z', which is not used on a US keyboard layout.
; I happen to have this key on my B.FriendIt(type1) keyboard, so enjoy this.

vkE2 & 8:: MSDN2008_Activate__Focus_IndexPane()
vkE2 & F8:: MSDN2008_Activate__Focus_IndexPane()
; B.FriendIt(type2) keyboard does not have the Europe \ key, but instead a Fn, so I have to turn to Fn+F8 for MSDN2008.
vKB2:: MSDN2008_Activate__Focus_IndexPane()

MSDN2008_Activate__Focus_IndexPane()
{
	if(MSDN2008_IsActive())
		MSDN2008_Focus_IndexPane()
	else
		MSDN2008_ActivateGroup()
}


;===== iPad Reflector recording on my Chji Win7 =====

chji_CheckiPadRecordingReady(request_fps 
	, airplay_window_offset_x:=0, airplay_window_offset_y:=0
	, record_width:=600, record_height:=800)
{
	; Run this function so that Reflector2 window and Bandicam target-window rest in the "same" position.
	; Then bandicam screen recording will record the very iPad AirPlay casting screen content.
	;
	; Limitation: Sometimes, I have to run this function *twice*, to make the two windows rest in the same position.

	; Check if "Reflector 2" is running.
	; If so, move "Reflector 2" window to my designated position.
	
	; Its window class is sth like:
	;	HwndWrapper[Reflector2.exe;;534cdb1d-82b1-462a-8391-0c90eeaaf301]
	;
	; Title is exactly "Reflector 2"
	; Process path: C:\Program Files\Reflector 2\Reflector2.exe

	
;	SetTitleMatchMode, 2 ; set partial title match mode
	hwndReflector := WinExist("Reflector 2")
;	SetTitleMatchMode, 3 ; restore to default exact match
	
	if(!hwndReflector) {
		dev_MsgBoxError("Cannot detect ""Reflector 2"" mirroring window.")
		return
	}
	
	WinGetPos, x,y,w,h, ahk_id %hwndReflector%
	if(w==325 && h==275) {
		dev_MsgBoxError("Reflector 2 small window is opened, you should close it first.")
		return
	}
	
	preset_x := 20
	preset_y := 20
	ofx := airplay_window_offset_x
	ofy := airplay_window_offset_y
	
	dev_WinMove_with_backup(preset_x+4+ofx, preset_y+ofy ,record_width, record_height+80, hwndReflector) ; (1204, -1002, 600, 880, hwndReflector)
	
	; Check whether Bandicam is running, if so, move it to the same location of Reflector2.
	; For Bandicam 3.4.2 .
	
	hwndBandicamRec := WinExist("ahk_class TARGETRECT")
	if(!hwndBandicamRec) {
		dev_MsgBoxError("Bandicam is not running yet, or, Bandicam's TARGETRECT is not visible now.")
		return
	}
	
	dev_WinMove_with_backup(preset_x+ofx, preset_y+38+ofy, record_width+8, record_height+30, hwndBandicamRec, false) ; (1200, -964, 608, 830, hwndBandicamRec)
		; [2019-05-28] Use is_force:=false in hope to workaround a Bandicam 3.4.2 crashing bug(when start REC).

	;
	; Check whether Bandicam's current recording cfg is the desired one. If not, MsgBox warn.
	;
	
	hwndBandicamMain := WinExist("ahk_class Bandicam2.x")
	if(!hwndBandicamMain) {
		dev_MsgBoxError("Unexpect: Bandicam main-window does NOT exist.")
		return
	}
	
	WinActivate, ahk_id %hwndBandicamMain%
	WinWaitActive, ahk_id %hwndBandicamMain%
	
	if ErrorLevel {
		dev_MsgBoxError("Unexpect: Bandicam main-window can not be activated.")
		return
	}
	
	; Click two buttons of Bandicam main window to force writing in-memory cfg to registry
	ClickInActiveWindow( 30, 94, false, 3)
	Sleep, 200
	ClickInActiveWindow(130, 94, false, 3)
	
	RegRead, now_fpms, HKEY_CURRENT_USER, Software\BANDISOFT\BANDICAM\OPTION, VideoFormat.VideoFrameRate
	; -- 12000 fpms means 12 fps
	
	if(now_fpms!=request_fps*1000) {
		dev_MsgBoxError("Cfg Error: Current recording FPS is not set to " . request_fps . " " . zz)
		return
	}
	
	dev_TooltipAutoClear(Format("chji_CheckiPadRecordingReady OK."))

}


class CDuraState
{
	__New(funcGetstate, context:=0)
	{
		; note: funcGetstate is a function name represented as a string
	
		this._funcGetState := funcGetstate
		this._context := context

		this._prevState := %funcGetstate%(context)
		this._timeSince := A_TickCount
		
;		tooltip, % "CDuraState __New()..." ; debug
	}
	
	GetState()
	{
		ucallback := this._funcGetState
		nowState := %ucallback%(this._context)
		
		if(nowState==this._prevState)
		{
			ret := {}
			ret.state := nowState
			ret.dura_millisec := A_TickCount - this._timeSince
		}
		else 
		{
			this._prevState := nowState
			this._timeSince := A_TickCount
			
			ret := { state: nowState , dura_millisec: 0 }
		}
		
		return ret
	}

	ResetTime()
	{
		this._timeSince := A_TickCount
	}
}


Check_Reflector2_Idle(context:=0)
{
	Process, Exist, Reflector2.exe
	if (ErrorLevel) {
		; Reflector2.exe process running 

		hwndReflector := WinExist("Reflector 2")
		if(hwndReflector) {
			; dev_MsgBoxError(" 'Reflector 2' mirroring window exists.")
			return "Mirroring"
		}
		else {
			return "Idle"
		}
	} 
	else {
		return "NotRun"
	}
}

chji_CheckSystemHealth()
{
	static Reflector2Idle := new CDuraState("Check_Reflector2_Idle")
		; [2018-12-01] Memo: This static object's __New is called as early as on script loading,
		; not when chji_CheckSystemHealth() is first called.
	
	
	ret := Reflector2Idle.GetState()
	durasec := ret.dura_millisec//1000
	durasec_warn := 60
	msgbox_timeout_sec := 30
;	MsgBox, % Format("Reflector2.exe state={} for {} seconds", ret.state, durasec) ; debug
	
	if(ret.state=="Idle" and durasec>durasec_warn)
	{
		MsgBox, % msgboxoption_IconExclamation, , % Format("Reflector2.exe has been idle for {} seconds. You should quit it for system safety.", durasec_warn), % msgbox_timeout_sec
		
		Reflector2Idle.ResetTime()
	}
}



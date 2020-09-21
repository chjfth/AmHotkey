
AUTOEXEC_windev: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

global g_VSDlg_sleep_bfr_close := 100

global g_isNavibackTriggered := false

MSHV22_DefineHotkeys()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


windev_HideTooltip:
	tooltip
	return

;==============================================================
; Visual Studio 6 (VC6) with VAX
;==============================================================
#If IsWinTitleMatchRegex("Microsoft Visual C++")
	; Not to match ahk_class, because VC6's class name is Afx:....

^`:: ; in hope clicking on FileView pane
	ClickInActiveControl("SysTabControl321", 0.4, 0.5)
return


;^!4:: ; click on VA Outline tab
;	ClickInActiveControl("SysTabControl321", 0.9, 0.5)
;return

CapsLock & Right UP:: VC6_FocusCodeArea()
VC6_FocusCodeArea()
{
	static s_flip = 0 ; consider that VC6 code area may be splitted into two panes
	arpos := [ "0.8,0.2" , "0.8,0.8" ]
	s_flip := not s_flip
	
	; "MDIClient" is the VC6 code area(the big pane on the right side).
	; This area may be splitted into four panes, so we will cycle through
	; each of them on every call of this function. 

	nowpos := arpos[s_flip+1] ; Ahk array index is 1-based
	StringSplit, p, nowpos, `,
	ControlFocusViaRegexClassNNXY("^MDIClient[0-9]+$", false, p1, p2, true, true)
}

CapsLock & Left UP:: VC6_FocusLeftPane()
VC6_FocusLeftPane() ; Here, Left-pane mean the workspace pane area
{
	ControlGetPos, x, y, width, height, SysTabControl321, A ; find the gang-tabs
	if not x
		return 
	; Now focus(click) the control right above the gang-tabs
	MouseMove, % x+8 , % y-8
/*
	MouseGetPos, _mx, _my, , leftpane_classnn
	ControlGetPos, x, y, width, height, %leftpane_classnn%, A
	tooltip, leftpane=%leftpane_classnn% (%x% . %y%) / (%width% . %height%)
		; [2015-02-10]
		; VERY Strange! The above ControlGetPos always return blank for x, y, width, height 
		; although leftpane_classnn contains a (看上去) utterly valid value, something like:
		; Afx:400000:8:19990:0:01
	ClickInActiveControl(leftpane_classnn, -2, 2, true)
*/
	; The workaround is, just Click inside the pane.
	Click
}

#If



;==============================================================
; Visual Studio 2008+ & its counterpart Document Explorer
;==============================================================

VS2008_IsActive()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%
	
	if( class=="wndclass_desked_gsk" and title~="Microsoft Visual Studio" ) ; ~= means regex match(substring match)
		return true
	else
		return false
}

VS2010_IsActive()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%
	WinGet, exepath, ProcessPath, ahk_id %Awinid%
	
	; ~= means regex match(can be used as substring match)
	if( class~="^HwndWrapper" and title~="Microsoft Visual Studio" and exepath~="devenv.exe$")
		return true
	else
		return false
}


MSDN2008_IsActive() ; Is "MSDN Library - Visual Studio 008 - Microsoft Document Explorer" window active
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%
	
	if( class=="wndclass_desked_gsk" and title~="Microsoft Document Explorer" ) ; ~= means regex match(substring match)
		return true
	else
		return false
}

MSDN2008_ActivateGroup()
{
	; Call this to activate MSDN2008 window
	MyActivateWindowGroupFlex("wndclass_desked_gsk", "", "Microsoft Document Explorer", "VS2008 MSDN Documents")
}


#If VS2008_IsActive()
; Most operation's shortcut can be defined with Tools -> Options -> Keyboard

; CapsLock & F8:: Send +^!{F8} ; TabsStudio previous tab (?)

; CapsLock & F9:: Send +^!{F9} ; TabsStudio next tab


#If ; #If VS2008_IsActive()


#If MSDN2008_IsActive()

;F10:: MSDN2008_Focus_IndexPane() ; This is configurable @ Help.Index

F12:: MSDN2008_Focus_MainPane()
CapsLock & Right:: MSDN2008_Focus_MainPane()
CapsLock & Up:: MSDN2008_Focus_MainPane()
CapsLock & Down:: MSDN2008_Focus_IndexResult()

; === Sample usage ===
;	; Pressing WinApp+8 *twice* will bring up MSDN2008 window and focus the Index editbox
;	AppsKey & 8:: 
;		if(MSDN2008_IsActive())
;			MSDN2008_Focus_IndexPane()
;		else
;			MSDN2008_ActivateGroup()
;	return


MSDN2008_Focus_MainPane()
{
	; ControlFocus, % "Internet Explorer_Server1" ; [2015-11-05] Don't know why this results in vain.
	ClickInActiveControl("Internet Explorer_Server1", 8, -2)
		; Note: Clicking left-bottom instead of left-top, because some docpage(CWnd::BeginPaint etc)
		; is HTML-framed who has a fixed banner. Clicking that fixed banner will not transfer focus
		; to the scrollable "main" area.
}

MSDN2008_Focus_IndexResult()
{
	; ControlFocus, % "SysListView321" 
	ClickInActiveControl("SysListView321", -2,-2)
}

MSDN2008_Focus_IndexPane()
{
	Send !i
	Send !l
		; Flaw: When Help.Contents has focus, this key seq does not work.
}

#If ; #If MSDN2008_IsActive()

;===========================================================================
; MS Help Viewer 1.x /2.x(VS2015Doc)
;===========================================================================

; It's weird that MSHV 2.x's "left pane" is not a control, which causes lots of AHK automation trouble.

MSHV_IsActive() ; MSHV: MS Help Viewer 1.x/2.x for VS2010/VS2013/(VS2015)
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%
	
	if( class~="^HwndWrapper\[HlpViewer.exe" and title~="^Microsoft Help Viewer" ) ; ~= means regex match(substring match)
		return true
	else
		return false
}


#If MSHV_IsActive()

F9:: MSHV_Focus_ContentPane()
F10:: MSHV_Focus_IndexPane()
F12:: MSHV_Focus_MainPane() ; no effect on VS2015
^Right:: MSHV_Focus_MainPane()
CapsLock & Right:: MSHV_Focus_MainPane()
CapsLock & Up:: MSHV_MainPane_Scroll("Up")
CapsLock & Down:: MSHV_MainPane_Scroll("Down")

CapsLock & Left::
	Send !i
	Send {Tab} ; not reliable
return

^LButton:: Send !{Left}
^RButton:: Send !{Right}

; While pressing down mouse right-button, left click do Navigate Back.
; Hint(when you delete the two MouseMove line): To avoid right-click context memu pop-up, you have to manually.
~RButton & LButton:: MSHV_mousekey_naviback() 
MSHV_mousekey_naviback()
{
	Send !{Left}
;	g_isNavibackTriggered := true

	; The following two MouseMove have a tricky but desired effect: right-click context memu WON'T pop-up.
	; and an undesired side-effect: You have to release the right-button and press it down before triggering a second this hotkey.
	MouseMove, -20, 0, , R
	MouseMove, 20, 0, , R
		
}

;~RButton up:: MSHV_RButton_up_tweak()
;MSHV_RButton_up_tweak()
;{
;	if(g_isNavibackTriggered) {
;		MouseMove, 20, 0, 1, R
;	}
;}

; While pressing down mouse left-button, right click do Navigate Forward.
~LButton & RButton:: Send !{Right}


MSHV_Focus_MainPane(movemouse:=true)
{
	ClickInActiveControl("Internet Explorer_Server1", 2, 0.5, movemouse, false)
}

MSHV_Focus_ContentPane()
{
	Send !c
}

MSHV_Focus_IndexResult()
{
	;ClickInActiveControl("SysListView321", -2,-2)
}

MSHV_Focus_IndexPane()
{
	Send !i
}

MSHV_MainPane_Scroll(dir)
{
	ControlClick, % "Internet Explorer_Server1", A, , Wheel%dir%, 1
}

#If ; MSHV_IsActive() 



;===========================================================================
; MS Help Viewer 2.2 (VS2015 Doc)
;===========================================================================


#If MSHV22_IsActive() ; [2016-06-15] Note: If this line is deleted, F1~F9 will not work in other programs.
;#If ;MSHV22_IsActive()

NumpadDiv:: Send !{Left}
NumpadMult:: Send !{Right}

MSHV22_IsActive()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%
	
	if( class~="HwndWrapper" and title~="Microsoft Help Viewer 2.2" ) ; ~= means regex match(substring match)
		return true
	else
		return false
}


MSHV22_FN_send_CtrlN(num)
{
	static s_prevnum := 0
	if(num==s_prevnum) {
		MSHV_Focus_MainPane(false) ; Workaround the quick switch freeze bug of HV22 viewer
	}

	sendkey := "^" . num
	Send %sendkey%

	s_prevnum := num
}

MSHV22_DefineHotkeys()
{
	; F1~F9 to send Ctr+1 ~ Ctrl+9 (switch doc tabs)
	hotchars := "123456789"
	Loop, parse, hotchars
	{
		dev_DefineHotkeyWithCondition("F" . A_LoopField, "MSHV22_IsActive", "MSHV22_FN_send_CtrlN", A_LoopField)
	}

}

MSHV22_ActivateGroup()
{
	MyActivateWindowGroupFlex(QSA_NO_WNDCLASS, "^HwndWrapper", "^Microsoft Help Viewer 2.2", "MS Help Viewer 2.2 (VS2015Doc)")
}

MSHV22_Focus_IndexPane()
{
	Send !i
}


#If VS2008_IsActive() || VS2010_IsActive()

; Chj: Numpad  / *  switch to previous or next tab. (Requires TabsStudio)
NumpadDiv:: Send ^!{Left}     ; TabsStudio.Connect.NavigateToPreviousTab
NumpadMult:: Send ^!{Right}   ; TabsStudio.Connect.NavigateToNextTab

NumpadSub:: Send ^!{Pgup}     ; TabsStudio.Connect.NextTabExtension [global]
NumpadAdd:: Send ^!{Pgdn}     ; TabsStudio.Connect.MarkerNextTabHighlightingColor

^NumpadDiv::  Send ^1         ; TabsStudio.Connect.NavigateToTab1
^NumpadMult:: Send ^!{End}    ; TabsStudio.Connect.NavigateToLastTab (Last=Rightmost)

;!NumpadDiv::  Send ^![    ; TabsStudio.Connect.MoveTabLeft
;!NumpadMult:: Send ^!]    ; TabsStudio.Connect.MoveTabRight // this is defaultly used as Debug.ShowNextStatement


!Up:: Send {Up 10}
!Down:: Send {Down 10}

:*?:irpc``::Irp->CurrentLocation
:*?:irps``::Irp->Tail.Overlay.CurrentStackLocation
:*?:irps1``::((IO_STACK_LOCATION*)(Irp+1))[0]
:*?:irps2``::((IO_STACK_LOCATION*)(Irp+1))[1]
:*?:irps3``::((IO_STACK_LOCATION*)(Irp+1))[2]


CapsLock & Left:: ClickInActiveWindow(14, 0.5, false)

CapsLock & Right:: VS2010_FocusCodeArea()
VS2010_FocusCodeArea()
{
	static s_flip = 0 ; consider that VC6 code area may be splitted into two panes
	arpos := [ "0.6,0.3" , "0.6,0.7" ]
	s_flip := not s_flip
	nowpos := arpos[s_flip+1] ; Ahk array index is 1-based
	StringSplit, p, nowpos, `,
	;ControlFocusViaRegexClassNNXY("^MDIClient[0-9]+$", false, p1, p2, true, true)
	ClickInActiveWindow(p1, p2, false) ; false=not moving mouse
}


#If


;==============================================================
; Visual Studio 2010+ Property Pages
;==============================================================

VSIDE_IsPropertyPageActive() ; Is "MSDN Library - Visual Studio 008 - Microsoft Document Explorer" window active
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%
	
	if( class=="#32770" and title~="Property Pages$" ) ; ~= means regex match(substring match)
		return true
	else
		return false
}


#If VSIDE_IsPropertyPageActive()

; Override [Enter] to avoid accidentally close the Property-page dialog
Enter:: VSIDEPP_PressEnter()
VSIDEPP_PressEnter()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	
	if(dev_IsClassnnFocused_regex("SysTreeView321"))
	{	; Set focus to right-side pane instead of close the dialog
		VSIDEPP_FocusRightPane()
		return
	}
	
	is_close := dev_MsgBoxYesNo("Save and close the Property Page dialog box?", false)
	if(!is_close)
		return
	
	WinWaitActive, ahk_id %Awinid%, , 1.0
	VSIDEPP_OK_CloseDialog()
}

VSIDEPP_OK_CloseDialog()
{
	; ControlClick, Button1, A ; this often lost in vain
	; so use ClickInActiveControl() instead.
	Sleep, %g_VSDlg_sleep_bfr_close% ; If no sleep, sometimes "Button2" is missed. Don't know why.
	ClickInActiveControl("Button1", 0.5, 0.5) ; Button1 is OK
}

^Enter:: VSIDEPP_OK_CloseDialog()

/* [2016-07-27] Find this Esc dialog boring, just set it aside.
Esc:: VSIDEPP_PressEsc()
VSIDEPP_PressEsc()
{
;	static last_EscTick := 0
;	now_tick := A_TickCount
;	diff_tick := now_tick - last_EscTick
;	last_EscTick := now_tick
;dev_TooltipAutoClear(diff_tick)
;	if(diff_tick>1000) {
;		VSIDEPP_Esc_CloseDialog()
;		return
;	}
; -- sigh, wish I could have the A_LastKey global...

	WinGet, Awinid, ID, A ; cache active window unique id

	is_close := dev_MsgBoxYesNo("Close the Property Page dialog box?", true, Awinid)
	if(!is_close)
		return

	WinWaitActive, ahk_id %Awinid%, , 2.0
	VSIDEPP_Esc_CloseDialog(Awinid)
}
*/

VSIDEPP_Esc_CloseDialog(dlg_winid:=0)
{
	count := 0
	while(1)
	{
		Sleep, %g_VSDlg_sleep_bfr_close% ; If no sleep, sometimes "Button2" is missed. Don't know why.
		ClickInActiveControl("Button2", 0.5, 0.5) ; Button2 is Cancel
			; Quite often, that click misses, so try it again.
		
		if(dlg_winid==0)
			break
		
		if( (not IsWinidActive(dlg_winid)) or count>=3 )
			break
		
		Sleep, 500
		count+=1
	}
}

^Esc:: VSIDEPP_Esc_CloseDialog() ; somehow this does not always work


CapsLock & Left:: VSIDEPP_FocusLeftPane()
VSIDEPP_FocusLeftPane()
{
	ControlFocus, SysTreeView321, A
}

CapsLock & Right:: VSIDEPP_FocusRightPane()
VSIDEPP_FocusRightPane()
{
	ClickInActiveControlEx("SysTreeView321", 12,true, 0.2,false, true)
		; Click 12 pixels beyond left-pane's right-side border.
	
	; MEMO: When focus has been in right-side pane, Alt+Down can drop down the combobox
	; for current item.
}



#If ; VSIDE_IsPropertyPageActive()





;==============================================================
; WinDbg 6.3
;==============================================================

windbg_IsActive()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%

	if(class=="WinDbgFrameClass")
		return true
	
	if(class=="WinBaseClass" && title~="WinDbg:") ; floating inner Command window, WinDbg 10.10240
		return true
	

	if(InStr(title, "- WinDbg:6"))
		return true
	
	return false
}

#If windbg_IsActive()

F12:: windbg_SendCommentLine()
windbg_SendCommentLine()
{
	FormatTime, dtstr, , yyyy-MM-dd HH:mm:ss
;	SendInput **★★★★★★★★ %dtstr% ★★★★★★★★**{enter} ; ★ is too small in Win8+ fonts(Consolas etc), damn you M$
	SendInput **■■■■■■■■■■■■■■■■■■■■ %dtstr% ■■■■■■■■■■■■■■■■■■■■**{enter}
		; memo: * leads a comment line for windbg/kd command
}

^!F12:: windbg_SendQuickCommands()
windbg_SendQuickCommands()
{
	SendRaw !sym noisy
	Send {Enter}
}

windbg_CommandInput_hctrl(Awinid:=0)
{
	if(!Awinid)
		WinGet, Awinid, ID, A ; cache active window unique id

	; Note: This is rough. 
	; Only when input focus is on command-input or command-output, command-input is RICHEDIT50W2 ;
	; when focus is on some other pane(source window etc), RICHEDIT50W2 is command-output.
	; This is tricky, but happend to work most of the time, at least on WinDBG 10.0.10240.

	ControlGet, hctrl, HWND, , % "RICHEDIT50W2", ahk_id %Awinid%
	return hctrl
}

windbg_CommandOutput_hctrl(Awinid:=0)
{
	if(!Awinid)
		WinGet, Awinid, ID, A ; cache active window unique id

	ControlGet, hctrl, HWND, , % "RICHEDIT50W1", ahk_id %Awinid%
	return hctrl
}

windbg_IsCommandInputFocused(Awinid:=0)
{
	if(!Awinid)
		WinGet, Awinid, ID, A ; cache active window unique id

	hCommandInput := windbg_CommandInput_hctrl(Awinid)
	
	ControlGetFocus, classnn_focus, ahk_id %Awinid%
	ControlGet, hFocus, HWND, , %classnn_focus% , ahk_id %Awinid%
	if(hFocus==hCommandInput)
		return true
	else
		return false

}

Enter:: windbg_SendCommandAppendTimestamp()
windbg_SendCommandAppendTimestamp()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	hCommandInput := windbg_CommandInput_hctrl(Awinid)
	
	ControlGetFocus, classnn_focus, ahk_id %Awinid%
	ControlGet, hFocus, HWND, , %classnn_focus% , ahk_id %Awinid%
	if(!windbg_IsCommandInputFocused(Awinid))
	{
		send {enter}
		return
	}
	
	; User just pressed enter from the windbg command prompt.
	
;	clipboard_saved := ClipboardAll ; seems not stable
;	tooltip, focus=%classnn_focus%

	ControlGetText, existing_cmd, , ahk_id %hCommandInput%
	if(not existing_cmd) ; command input box is empty
	{
		send {enter} ; relay enter key(windbg will repeat last command)
		return
	}
	; User pressed enter with some command typed in.
	Send ^{Home}^+{End}{Del} 
		; using Ctrl+Home, Ctrl+Shift+End so that we can select multiple lines
;	dev_TooltipAutoClear(">>>" . existing_cmd)
	
	windbg_SendCommentLine()
	; ControlSetText, ahk_id %hCommandInput%, % existing_cmd ; // ControlSetText does not work with a RichEdit control, sigh
	if(WinClip.Paste) {
		WinClip.Paste(existing_cmd)
		SendInput {enter}
	} else {
		MsgBox, % "windbg_SendCommandAppendTimestamp Error: You need to #Include WinClipAPI.ahk and WinClip.ahk for this to work."
	}
}

windbg_ScrollCommandOutputOnePage(is_up)
{
	hCommandOutput := windbg_CommandOutput_hctrl()

	; WM_VSCROLL=0x115, SB_PAGEUP=2, SB_PAGEDOWN=3
	PostMessage, 0x115 , % is_up?2:3 , 0, , ahk_id %hCommandOutput%
}

PGUP:: windbg_CommandOutput_pgup()
windbg_CommandOutput_pgup()
{
	if(windbg_IsCommandInputFocused())
		windbg_ScrollCommandOutputOnePage(true)
	else
		send {pgup}
}

PGDN:: windbg_CommandOutput_pgdn()
windbg_CommandOutput_pgdn()
{
	if(windbg_IsCommandInputFocused())
		windbg_ScrollCommandOutputOnePage(false)
	else
		send {pgdn}
}

Ins:: windbg_FocusCommandInput()
windbg_FocusCommandInput()
{
	hcmd := windbg_CommandInput_hctrl()
	if(hcmd)
		ControlFocus, ,ahk_id %hcmd%
}



^d:: windbg_SeeGlobalFlag()
windbg_SeeGlobalFlag()
{
     windbg_SendCommentLine()
     SendInput, dt ntdll{!}_PEB @$peb NtGlobalFlag{enter}
}

^!1:: send {!}sym noisy



#If ; #If windbg_IsActive()


; ################### VisualGDB ##################

VisualGDBPropertyWindow_IsActive() 
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%
	
	if( title~="^VisualGDB Project Properties" ) ; ~= means regex match(substring match)
		return true
	else
		return false
}

#If VisualGDBPropertyWindow_IsActive()

^Enter:: ClickInActiveWindow(-204, -32, true) ; Click the OK button

#If ; VisualGDBPropertyWindow_IsActive()


Is_VisualStudioCode()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%

	if( class=="Chrome_WidgetWin_1" 
		and StrIsEndsWith(title, "Visual Studio Code") )
	{
		return true
	}
	else
	{	
		return false
	}
}

#If Is_VisualStudioCode()

NumpadDiv:: Send ^{PgUp}     ; TabsStudio.Connect.NavigateToPreviousTab
NumpadMult:: Send ^{PgDn}   ; TabsStudio.Connect.NavigateToNextTab

#If

; ################ JetBrains IDE #################

JetBrainsIDE_IsActive() 
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGet, exepath, ProcessPath, ahk_id %Awinid%

	if( StrIsEndsWith(exepath, "pycharm64.exe") )
		return true
	else
		return false
}

#If JetBrainsIDE_IsActive()

NumpadDiv::  Send ^![   ; Select previous tab
NumpadMult:: Send ^!]   ; Select next tab


#If ;JetBrainsIDE_IsActive


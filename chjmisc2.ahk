; Note: This file is saved with UTF8 with BOM, which is the best encoding choice to write Unicode chars here.

AUTOEXEC_chjmisc2: ; Workaround for Autohotkey's ugly auto-exec feature. Must be first line.

; This file contains some chj-specific actions that relies on other .ahk-s,
; such as evernote.ahk and mediaplayer.ahk

Init_chjmisc2()


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include %A_LineFile%\..\evernote.ahk
#Include %A_LineFile%\..\mediaplayer.ahk
#Include %A_LineFile%\..\evernote.ahk

;==============================================================================
; Some hotstring auto-replace
;==============================================================================

; Auto-replace `1 to be 192.168. -- easy typing those IP addresses.
; Note: You have to double ` here. ``1 means triggering chars `1 
; memo: [*] no need to post-type a space to trigger, 
;       [?] no need to prefix a wordchar to trigger
:*:``1::192.168.
:*:``2::172.24.0.
:*:``q::Q:{space}

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


; <<>> → Chinese ShuMingHao
:?*:<<>>::《》{Left}

; Four single-quotes → full-width Chinese double-quotes
:?*:''''::“”{Left}

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


^#/:: devui_ChangeWindowPosition()

Init_chjmisc2()
{
	dev_MenuAddItem(winshell.UtilityMenu, "Mouse goto screen x,y", "InputBox_MouseGoto")
	
	if(dev_IsWin7() or dev_IsWinXP())
	{
		pN_Tweak_for_PYJJ_pageN_keystroke()
	}

;	HalfwidthChar_Tweak_for_PYJJ() ; not using it due to big side-effect.
}

;==============================================================================
; Windows generic
;==============================================================================

InputBox_MouseGoto()
{
	static coordxy := "S200,100"
	
	hint = 
	(
Where to place the mouse pointer?

S200,100
    At screen coordinate (200,100)
A200,100
    The coordinate relative to active window.
R200,100
    Relative to current mouse pointer.
	)
	
	isok := dev_InputBox_InitText("AHK move mouse", hint, coordxy)
	if(!isok)
		return
	
	arnum := StrSplit(coordxy, ",")

	word1 := arnum[1]
	prefix := SubStr(word1, 1, 1)
	mx := SubStr(word1, 2)
	my := arnum[2]
	
	if(prefix!="S" and prefix!="A" and prefix!="R")
	{
		dev_MsgBoxError("Input format error!")
		return
	}
	
	dev_MouseMove(mx, my, prefix)
}


; ====== Quick construct `net use \\10.22.x.x\d$' command. ======

#If cc_IsCMDorConEmuActive()

^n:: chj_PasteNetUseSambaCommand()
chj_PasteNetUseSambaCommand()
{
	static s_prev_smbpath := "\\10.22.3.4\d$"
	
	smbpath := s_prev_smbpath
	
	isok := dev_InputBox_InitText("AHK: net use command"
		, "Input a Samba share path, and a ``net use \\server\share`` command will be constructed for you."
		,  smbpath)
	if(not isok)
		return
	
	s_prev_smbpath := smbpath
	
	isAdmin := dev_IsSubStr(smbpath, "$")
	netusecmd := Format("net use {1} /user:{2} {3}"
		, smbpath
		, isAdmin ? "Admin" : "chj"
		, isAdmin ? "Adm0000" : "123456" )
	
	if(not cc_PasteTextToCMDWindow(netusecmd))
		return
	
	; Then place smbpath into Clipboard, bcz user probably want Explorer to go to that smbpath.
	;
	dev_Sleep(200)
	dev_SetClipboardWithTimeout(smbpath, 100)
	dev_TooltipAutoClear("Place to Clipboard: " smbpath)
}

#If

;==============================================================================
; Evernote 6.5.4 specific
;==============================================================================

#If Evernote_IsMainFrameOrSingleActive()

; Double semicolon, to make one colon (deprecated)
:?*:;;::`:{space}

#If


;==============================================================================
; Evernote 6.5.4 and MPC-HC interaction.
;==============================================================================

#If Evernote_IsSingleNoteActive() and WinExist("ahk_class MediaPlayerClassicW") 
F3::        MPC_Bg_PausePlay(true)
F1::        MPC_Bg_PausePlay_front(true)
; NumpadSub:: MPC_Bg_PausePlay_front(true)
F2::         Evernote_MPC_PasteCurrentPlaytime("{F2}") ; F2 defaults to Evernote clip rename
; NumpadAdd::  Evernote_MPC_PasteCurrentPlaytime()
F4::        MPC_Bg_Back5sec(true)
NumpadDiv:: MPC_Bg_Back5sec(true)
F5::         MPC_Bg_Forward5sec(true)
NumpadMult:: MPC_Bg_Forward5sec(true)

Evernote_MPC_PasteCurrentPlaytime(bypass_hotkey="")
{
	if(MPC_IsRunning()) 
		MPC_PasteCurrentPlaytime()
	else if(bypass_hotkey) {
;		dev_TooltipAutoClear("bypass_hotkey=" . bypass_hotkey) ; debug
		Send % bypass_hotkey
	}
}
#If


#If Evernote_IsSingleNoteActive()
NumpadSub:: Evernote_MoveYClick(-24) ; in hope to click onto prev table Row
NumpadAdd:: Evernote_MoveYClick(24)  ; in hope to click onto next table Row
Evernote_MoveYClick(movey)
{
	WinGet, Awinid, ID, A ; cache active window unique id
	MouseGetPos, mx, my, mwin

	if (Awinid != mwin)
	{	; move the mouse into Evernote window, so that we won't `Click` to activate other window
		MouseMoveInActiveWindow(A_CaretX, A_CaretY)
	}
	
	MouseMove, 0, %movey%, , R
	Click
}

^\:: 
	; close the "Find Text" bottom bar.
	; I have to use this bcz ESC has been disabled by me for ENSingleNoteView.
	ClickInActiveWindow(18, -48, false) 
return

#If


;==============================================================================
; PYJJ
;==============================================================================

pN_Tweak_for_PYJJ_pageN_keystroke()
{
	; [2024-07-24] This solves a long-existing boring system behavior when using PYJJ.
	;
	; Before this tweak:
	; When PYJJ is in ZH input state, and I want to type "p123" (meaning page 123)
	; into text editor, I just can not type 『p123』directly, bcz:
	;	the leading 『p』 provokes PJYY ZH-character candidates floatbar, 
	;	then 『1』 will select the first ZH-character.
	; So, to type in p123, I have to delete the already typed 『p』, then press 
	; Shift once to switch from ZH to EN, type my p123, then press Shift once again 
	; to go back to ZH state, -- quite stuttering typing experience.
	;
	; Now with this tweak:
	; On PJYY's initial ZH state, I can really type p123 smoothly interspersed with 
	; Chinese characters. Great!
	

	Loop, 9
	{
		; We want 'p1' to trigger AHK action, 'p2', 'p3'... as well.
	
		digit := A_Index
		fnobj := Func("PYJJ_pageN_Hotstring_Action").Bind(digit)
		Hotstring(":*:p" digit, fnobj, "On")
	}
}

PYJJ_pageN_Hotstring_Action(digit)
{
	; digit can be 0 ~ 9.

	is_pjyy := Is_PinyinJiaJia_Floatbar_Visible()

	if(is_pjyy)
	{
		dev_TooltipAutoClear(Format("AHK: p{} triggers smooth pNNN input for PYJJ.", digit))
		
		; Note: On triggering this, the digit has been intercepted by Autohotkey engine,
		; and the digit has not reach current text editor process. Autohotkey engine then
		; sends one backspace to the text editor process, so the PYJJ(inside that process) 
		; revokes the 'p' char on PYJJ float bar and the float bar vanishes from the screen.
		
		; Now, type Shift to place PYJJ into EN input-state (assume PYJJ configured as such),
		; so that user from now on types digits(1~9) directly into text editor.
		dev_Send("{Shift down}{Shift up}")
	}

	; Resend the two keystrokes of pN (p1, p2, ... or p9), so that our text editor gets them.
	dev_SendRaw("p" digit) 
	
	if(is_pjyy)
	{
		; Send Shift again to bring PYJJ back into ZH input-state.
		dev_Send("{Shift down}{Shift up}")
	}
} 

HalfwidthChar_Tweak_for_PYJJ()
{
	; [2024-07-24] Purpose: When typing a Chinese article with PYJJ-IME, full-width "mode", 
	; if a digit(0..9) is followed by a dot/comma/plus etc, I will make the dot/comma/plus 
	; **half-width** .
	;
	; [2024-07-25] This code works, but with serious side-effect:
	; Imagine: User brings up PYJJ floatbar then type '2' to select the second ZH candidate,
	; now keyboard caret goes back to text editor and PYJJ floatbar disappears(the normal 
	; behavior), then user type dot, hoping to type-in a Chinese full-width period symbol. 
	; However, AHK code here will substitute that full-width period with a half-width dot.
	; This is weird.

	halfwidth_chars := ".,+-*/"
	nchars := StrLen(halfwidth_chars)
	
	Loop, % nchars
	{
		hwchar := SubStr(halfwidth_chars, A_Index, 1)
		fnobj := Func("PYJJ_HalfwidthChar_Tweak_Action").Bind(hwchar)
		Loop, 10
		{
			digit := A_Index-1
			Hotstring(":?*B0:" digit hwchar, fnobj, "On")
			;  ?  Hotstring matching is not required at word starting boundary.
			;  *  Hotstring does not need to be trigger by a End-char(space char etc).
			;  B0 When hotstring is triggered, tell AHK engine not to backspace-delete 
			;     the already landing hotstring.
		}
	}
}

PYJJ_HalfwidthChar_Tweak_Action(hwchar)
{
	; hwchar can be . , + - * / etc

	if(Is_PinyinJiaJia_Floatbar_Visible())
	{
		; The user are in the process of selecting ZH-char candidates for a long ZH-word.
		; During that time, user may be 
		; * typing 1..9 to select one ZH-char,
		; * typing dot(.) or comma(.) to page next/prev,
		; So, A digit followed by a dot will trigger this hotstring,
		; and we should not apply tweaking in this situation, so return.
		return
	}

	is_zh := IsTypingZhongwen_PinyinJiaJia() ; the may cost 100ms

	if(is_zh)
	{
		dev_Send("{Shift down}{Shift up}") ; switch EN state
	}

	; Remove the full-width char(。，＋－×／ etc) and send the half-width counterpart.
	dev_Send("{BS}" "{" hwchar "}")
	; -- We need to enclose hwchar into "{ }", bcz some char(like "+") is considered as AHK modifier.
	;    A pure "+" in `Send/SendInput` command will do nothing.

	if(is_zh)
	{
		dev_Send("{Shift down}{Shift up}") ; switch back to ZH state
	}
}

; 『Enter Dot』 as a hotstring ? Seems not allowed.
;
;	:*:{Enter}.::
;	dev_TooltipAutoClear("enterrrrrrrrr")
;	return


;==============================================================================
; Livecast in Chrome
;==============================================================================

appw_Zhihu_LiveCast_BigViewWithCommentSidebar()
{
	; Available since 2024.06, for https://www.zhihu.com/education/
	
	text =
	(
// Autohotkey move window: =1900,=1400
document.querySelectorAll('.PcLive-player-bB4as').forEach(element => {
  element.style.width = '1560px'; // 此项调宽度
});

document.querySelectorAll('.PcPlayer-playerWrapper-2Wq7D').forEach(element => {
  element.style.height = '900px'; // 此项调高度
});

document.querySelectorAll('.PcLive-rightWrapper-7SavL').forEach(element => {
  element.style.width = '320px'; // 这是右侧网友发言区宽度
});
	)
	winshell_AddOneSendTextMenu("F12 console - ZhihuLLM big webcast pane", text)

}

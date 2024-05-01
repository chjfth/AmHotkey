; Note: This file is saved with UTF8 with BOM, which is the best encoding choice to write Unicode chars here.

AUTOEXEC_chjmisc2: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

; This file contains some chj-specific actions that relies on other .ahk-s,
; such as evernote.ahk and mediaplayer.ahk


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

;==============================================================================
; Windows generic
;==============================================================================

InputBox_MouseGoto()
{
	static coordxy := "200,100"
	
	isok := dev_InputBox_InitText("AHK", "Where to place the mouse pointer?", coordxy)
	if(!isok)
		return
	
	arnum := StrSplit(coordxy, ",")
	mx := arnum[1]
	my := arnum[2]
	
	dev_MouseMove(mx, my, "S")
}



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


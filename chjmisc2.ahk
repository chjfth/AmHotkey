; Note: This file is saved with UTF8 with BOM, which is the best encoding choice to write Unicode chars here.

AUTOEXEC_chjmisc2: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

; This file contains some chj-specific actions that relies on other .ahk-s,
; such as evernote.ahk and mediaplayer.ahk


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include %A_LineFile%\..\evernote.ahk
#Include %A_LineFile%\..\mediaplayer.ahk


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



AUTOEXEC_Teclast_X98: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;==============================================================
; For easy using of Teclast X98 tablet
;==============================================================


; For Teclast X98 bluetooth keyboard >>>
SC132:: AppsKey ; SC132: Browser_Home(open IE), useless, so make it AppsKey

RAlt::RCtrl
	; So we're easier to press Ctrl+C, Ctrl+V 

#SC132:: ; Win+IE, 
	mo_InitCountDown()
return
; For Teclast X98 bluetooth keyboard <<<


X98_corner_tooltip(tipstr, duration_msec:=2000, is_sync:=false)
{
	CoordMode, ToolTip, Screen
	tooltip, % tipstr, 0, 0
	CoordMode, ToolTip, Window
	
	if(is_sync) {
		Sleep, % duration_msec
		tooltip
	}
	else {
		SetTimer, lbl_X98_corner_tooltip, % -duration_msec
	}
	return 

lbl_X98_corner_tooltip:
	tooltip
	return
}


; [[ Use Volumn_down/Volumn_up creatively ]]
;
; Volumn_down vkAE , sc12E
; Volumn_up vkAF , sc130


X98_IsAcitveWindowVolumeAsArrow()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%

	if(class=="ConsoleWindowClass" ; CMD window
	  or class=="VirtualConsoleClass" ; ConEmu
	  or Evernote_IsMainFrameOrSingleActive())
	{
		return true
	}
	else
		return false
}

#If not X98_IsAcitveWindowVolumeAsArrow()

; Press Volumn_down+Volumn_up to capture screen
vkAE & vkAF:: X98_PrintScreen()
X98_PrintScreen()
{
	X98_corner_tooltip("AHK doing PrintScreen", 500, true)
	Send {PrintScreen}
}
vkAE up:: Send {vkAEsc12E}

#If ; not X98_IsAcitveWindowVolumeAsArrow()
;---
#If X98_IsAcitveWindowVolumeAsArrow()

vkAE:: Send {Down}
vkAF:: Send {Up}

; F1:: MSGBOX, hhhhhhhhhh333333 ; // weird, F1 behaves incorrectly

#If ; X98_IsAcitveWindowVolumeAsArrow()


#IfWinActive ahk_class HyperSnap 7 Window Class

; Volumn_down close current image
vkAE:: HS7_close_image()
HS7_close_image()
{
	X98_corner_tooltip("AHK close image (Ctrl+F4)", 1000)
	Send ^{F4}
}

vkAE up:: return

#IfWinActive 




; Note: 
;	A Line starting with semicolon is a comment line.
;	*i means "ignore if that .ahk does not exist"

#Include libs\debugwin.ahk
#Include libs\WinClipAPI.ahk
#Include libs\WinClip.ahk
#Include libs\CtlColorStatic.ahk
#Include libs\Gdip_All.ahk ; need by evernote.ahk

#Include *i quick-switch-app.ahk

#Include *i keymouse.ahk

#Include *i evernote.ahk

;#Include *i hotstrings.ahk

;#Include *i winshell.ahk

;#Include *i cmdconsole.ahk

;#Include *i webbrowsers.ahk

;#Include *i windev.ahk

;#Include *i chmviewer.ahk

;#Include *i emeditor.ahk

;#Include *i mediaplayer.ahk

;#Include *i hypersnap.ahk

;#Include *i pdfreader.ahk

;#Include *i devmgmt.ahk

;#Include *i chjmisc.ahk
;#Include *i AmTemplates.ahk

; #Include *i zjb-helper.ahk

; #Include *i menus.ahk
; #Include *i mstsc.ahk ; Microsoft terminal service client
; #Include *i Teclast_X98.ahk
; #Include *i numpad_tweak_as_R7.ahk

#Include *i customize.ahk

; [2015-11-05] To fix: If some foobar.ahk with unique AUTOEXEC_foobar exists but not gets #Included here,
; reloading DEV.ahk will tell that foobar.ahk is loaded, but actually foobar's statements does not take effect.
; (1.1.19.02)

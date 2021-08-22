AUTOEXEC_numpad_tweak_as_R7: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Use my accustomed Acer R7 Home/Up/Down/End position on Gigabyte P35W V2(with a numpad)
; -- when NumLock is off.

; On P35W, let physical key becomes(remaps to) userkey:
; NumLock becomes Home 
; Numpad 7(Home) becomes PgUp
; Numpad Left becomes PgDn
; Numpad 1(End) keep its meaning
;
; Numpad [Del and .] becomes NumLock
; [==don't do this now==]Home(above NumLock) becomes Del
; 
; Feature:
; Ctrl,Shift,Alt,Win combo work correctly with userkey, but NOT with other ahk's prefix-key feature.
; For example: "Apps & Home" definition will not be fired when you press physical key "Apps & NumLock".
;
; BE AWARE, if those tweaked physical keys are defined elsewhere, in other module ahk for example,
; they may probably silently lose the intended functionality expected here.
; For example, with keymouse.ahk, you must disable "Use Numpad keys to nudge mouse and do click".


;======== Implementation according to Autohotkey chm "Remapping keys and buttons"

NumLock::Home

NumpadHome::PgUp

NumpadLeft::PgDn

NumpadDel::NumLock
NumpadDot::NumLock




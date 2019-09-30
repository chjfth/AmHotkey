
AUTOEXEC_mstsc: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;==============================================================
; mstsc (Remote Desktop Client)
;==============================================================
#IfWinActive ahk_class TscShellContainerClass

; Let Alt+PrnSc do the Alt+PrnScr inside the server session and copy the image to client keyboard. 
!PrintScreen:: 
	Send ^!{NumpadSub}
	Am_PlaySound("sel.wav")
return 

#IfWinActive




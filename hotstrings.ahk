
AUTOEXEC_hotstrings: ; Workaround for Autohotkey's ugly auto-exec feature. Must be first line.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;###################### Some hot strings ####################
:*:,,/:: ; Insert C style comment /* ... */
	Send /*{Space}{Space}*/{Left 3}
return


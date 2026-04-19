
AUTOEXEC_hotstrings: ; Workaround for Autohotkey's ugly auto-exec feature. Must be first line.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



:*:,,c:: ; Insert C style comment /* ... */
	Send /*{Space}{Space}*/{Left 3}
return

;==============================================================================
; Some hotstring auto-replace
;==============================================================================

; Auto-replace `1 to be 192.168. -- easy typing those IP addresses.
; Note: You have to double ` here. ``1 means triggering chars `1 
; memo: [*] no need to post-type a space to trigger, 
;       [?] no need to prefix a wordchar to trigger
:*:``1::192.168.
:*:``q::Q:{space}

; Type ``t to get _T("") , or ``y to get _T(''),, then move the caret back inside the quotes
:*:````t::_T(""){left}{left}
:*:````y::_T(''){left}{left}

; Type ``pp to get pprint.pprint (python)
:*:````pp::from pprint import pprint as pp

; Type ``/ to get a full-width forward-slash so to use in filename
:*:````/::／
:*:````\::＼


;============================================================
; Type ``? to get superscript/subscript digits or letters
;============================================================
:*:````0::⁰¹₀₁
:*:````2::²₂
:*:````3::³₃
:*:````4::⁴₄
:*:````5::⁵₅
:*:````6::⁶₆
:*:````7::⁷₇
:*:````8::⁸₈
:*:````9::⁹₉
:*:````-::⁻₋
:*:````=::₊₋₌
:*:````[::⁽⁾₍₎

:*:````a::ᵃₐ
:*:````e::ᵉₑ
:*:````h::ʰ
:*:````i::ⁱᵢ
:*:````j::ʲⱼ
:*:````n::ⁿₙ
:*:````u::ᵘᵤ
:*:````v::ᵛᵥ
:*:````w::ʷ
:*:````x::ˣₓ
:*:````y::ʸᵧ

; =ᴬᴮᴰᴱᴳᴴᴵᴶᴷᴸᴹᴺᴼᴾᴿᵀᵁᵂ ᵃᵇᵉᵍᵏᵐᵒᵖᵗᵘᵛ
; =ₐₑᵢₕₗₗₙₒᵣₚₛₛᵤᵥₓ / ₔ

;⁻₋·₊₋₌`₊₋₌   `³₃ `⁰¹₀₁ 192.168.  Q: Q: 
; 上角标: ⁰ ¹ ² ³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ ´ ″ // More
; 下角标: ₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎


; Type ``; to get current date like [2026-04-19]
:*:````;:: 
dev_SendInput(dev_FormatTimeNow("[yyyy-MM-dd]"))
return

; Type ``' to get current date like 20260419
:*:````':: 
dev_SendInput(dev_FormatTimeNow("yyyyMMdd"))
return


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



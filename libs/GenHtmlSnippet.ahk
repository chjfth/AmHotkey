#Include %A_LineFile%\..\..\AmUtils-common.ahk

genhtml_simple_code2pre(codetext, comment_start:="//", tab_spaces:=4)
{
	if(codetext==""){
		dev_MsgBoxWarning("No text in Clipboard.")
		return
	}

	html := dev_EscapeHtmlChars(codetext)

	; Tab -> spaces
	spaces := "        "
	html := StrReplace(html, "`t", SubStr(spaces, 1, tab_spaces))

	; Split into lines
	html := StrReplace(html, "`r`n", "`n")
	lines := StrSplit(html, "`n")

	; Process each line
	outlines := []

	for i,linetext in lines
	{
		outline := genhtml_pre_colorize(linetext, comment_start)
		outlines.Push(outline)
	}

	; Join each result line
	html := dev_JoinStrings(outlines, "`r`n")

	;
	; Wrap whole content in <pre> tag
	;
	prestyle := "white-space:pre-wrap; border:1px solid #ddd; background-color:#f6f6f6; font-family:consolas,monospace; padding:0.4em; margin:0.2em 0;"
	html := Format("-<pre style='{}'>{}</pre>-"
		, prestyle, html)


	return html
}

genhtml_pre_colorize(linetext, comment_start)
{
	; Find each piece, decorate each piece.
	; For example, the linetext
	;	PFX "QUOT" // CMNT
	; contains 4 pieces:
	;	PFX                      "NORM"
	;	"QUOT"                   "QSTR"
	;	(just a space char)      "NORM"
	;	// CMNT                  "CMMT"

	otext := ""

	Loop
	{
		type := genhtml_Get1Piece(linetext, comment_start, piecelen)

		piecetext := SubStr(linetext, 1, piecelen)

		if(type=="NORM") {
			otext .= piecetext
		}
		else if(type=="QSTR") {
			c := SubStr(linetext, 1, 1)
			otext .= Format("<span style='color:{}'>", c=="'" ? "#d0e" : "#b0b")
				. piecetext
				. "</span>"
		}
		else if(type=="CMMT") {
			otext .= "<span style='color:#393'>"
				. piecetext
				. "</span>"
		}
		else {
			dev_assert(0) ; Buggy! None of "NORM", "QSTR", "CMMT"
		}

		linetext := SubStr(linetext, piecelen+1)

	} until linetext==""
	
	return otext
}

genhtml_Get1Piece(istr, comment_start, byref piecelen)
{
	ilen := strlen(istr)

	sqpos := InStr(istr, "'")
	dqpos := InStr(istr, """")
	cmpos := InStr(istr, comment_start)

	mino := dev_mino(sqpos?sqpos:99999, dqpos?dqpos:99999, cmpos?cmpos:99999)

	if(mino.val==1)
	{
		; istr starts with a non-normal piece

		if(mino.idx==1 || mino.idx==2) {
			piecelen := InStr(istr, mino.idx==1?"'":"""", true, 2)
			if(piecelen==0) ; no closing quote, fix it
				 piecelen := ilen
			return "QSTR"
		}
		else if(mino.idx==3) {
			piecelen := ilen
			return "CMMT"
		}
	}
	else
	{
		; istr starts with a normal piece
		piecelen := dev_min(mino.val-1, ilen)
		return "NORM"
	}
	
}

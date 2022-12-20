#Include %A_LineFile%\..\..\AmUtils-common.ahk

genhtml_simple_code2pre(codetext, line_comment:="//", block_comment:="", tab_spaces:=4)
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
		outline := genhtml_pre_colorize_1line(linetext, line_comment)
		outlines.Push(outline)
	}

	; Join each result line
	html := dev_JoinStrings(outlines, "`r`n")

	; Cope with block_comment(multi-line comment), like C++ /* ... */
	html := genhtml_pre_colorize_block(html, block_comment)
	;
	; Wrap whole content in <pre> tag
	;
	prestyle := "white-space:pre-wrap; border:1px solid #ddd; background-color:#f6f6f6; font-family:consolas,monospace; padding:0.4em; margin:0.2em 0;"
	html := Format("-<pre style='{}'>{}</pre>-"
		, prestyle, html)


	return html
}

genhtml_pre_colorize_1line(linetext, line_comment)
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
		type := genhtml_Get1Piece(linetext, line_comment, piecelen)

		piecetext := SubStr(linetext, 1, piecelen)

		if(type=="NORM") {
			otext .= piecetext
		}
		else if(type=="QSTR") {
			
			; If the string is short, I give it brighter color to make it stand out.
			qstrlen := strlen(piecetext) 
			if(qstrlen<=8)
				color := "#e0f"
			else if(qstrlen<=16)
				color := "#d0e"
			else if(qstrlen<=64)
				color := "#b0c"
			else
				color := "#80a"
			
			otext .= Format("<span style='color:{}'>", color)
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

genhtml_Get1Piece(istr, line_comment, byref piecelen)
{
	ilen := strlen(istr)

	sqpos := InStr(istr, "'")
	dqpos := InStr(istr, """")
	cmpos := InStr(istr, line_comment)

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

genhtml_pre_colorize_block(mltext, block_comment)
{
	otext := ""
	Loop 
	{
		type := genhtml_GetML1Piece(mltext, block_comment, piecelen)
		
		piecetext := SubStr(mltext, 1, piecelen)
		
		if(type=="NORM") {
			otext .= piecetext
		}
		else if(type=="CMMT") {
		
			; For piecetext, we need to find all child <span> element inside, and remove them,
			; bcz, we don't want the childs to <span>-set their own text color.
			
			piecetext := RegExReplace(piecetext, "<span.*?>", "")
			piecetext := RegExReplace(piecetext, "</span>", "")
		
			otext .= "<span style='color:#393;'>"
				. piecetext
				. "</span>"
		}
		else {
			dev_assert(0) ; Buggy! None of "NORM", "CMMT"
		}
		
		mltext := SubStr(mltext, piecelen+1)
	} until mltext==""
	
	return otext
}

genhtml_GetML1Piece(istr, block_comment, byref piecelen)
{
	; Similar to genhtml_Get1Piece(), difference with block_comment param
	
	; ML: multiline
	ilen := strlen(istr)
	
	bc_start := block_comment[1]
	bc_end   := block_comment[2]
	
	bcstart_pos := InStr(istr, bc_start) 
	if(bcstart_pos==0) ; not found
	{
		piecelen := ilen
		return "NORM"
	}
	else if(bcstart_pos==1) 
	{
		bcend_pos := InStr(istr, bc_end, strlen(bc_start))
		piecelen := bcend_pos + strlen(bc_end) - 1
		return "CMMT"
	}
	else
	{
		dev_assert(bcstart_pos>1)
		piecelen := bcstart_pos - 1
		return "NORM"
	}
}

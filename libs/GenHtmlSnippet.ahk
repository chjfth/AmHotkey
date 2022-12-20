#Include %A_LineFile%\..\..\AmUtils-common.ahk

/* API:

genhtml_simple_code2pre()

*/

genhtml_simple_code2pre(codetext, line_comment:="//", block_comment:="", tab_spaces:=4, workaround_evernote_bug:=true)
{
	; block_comment sample: ["/*", "*/"]

	if(codetext==""){
		dev_MsgBoxWarning("No text in Clipboard.")
		return ""
	}

	if(block_comment and block_comment.Length()!=2)
	{
		dev_MsgBoxError("In genhtml_simple_code2pre(), Error: block_comment[] array length is not 2 !")
		return ""
	}

	html := dev_EscapeHtmlChars(codetext)

	; Tab -> spaces
	spaces := "        "
	html := StrReplace(html, "`t", SubStr(spaces, 1, tab_spaces))

	; Want pure \n as separator
	html := StrReplace(html, "`r`n", "`n")

	if(!block_comment)
	{
		html := genhtml_pre_colorize_eachline(html, line_comment)
	}
	else if(InStr(block_comment[1], "'")>0 || InStr(block_comment[1], """")>0 
		|| InStr(block_comment[2], "'")>0 || InStr(block_comment[2], """")>0 )
	{
		; The Python case: whose block comment """...""" contains single-quotes or double-quotes.
		; I need to process block-comment first, then process each line, a bit complex. 
		
		html := genhtml_pre_colorize_block(html, block_comment, true)

		html := genhtml_pre_colorize_eachline(html, line_comment)
	}
	else 
	{
		; The C++ case, simpler.

		html := genhtml_pre_colorize_eachline(html, line_comment)

		; Cope with block_comment(multi-line comment), like C++ /* ... */
		html := genhtml_pre_colorize_block(html, block_comment, false)
	}
	
	;
	; Wrap whole content in <pre> tag
	;
	prestyle := "white-space:pre-wrap; border:1px solid #ddd; background-color:#f6f6f6; font-family:consolas,monospace; padding:0.3em; margin:0.3em 0;"
	html := Format("-<pre style='{}'>{}</pre>-"
		, prestyle, html)

	; Fix for Evernote 6.5.4 bug:
	; If line N ends with </span> and line N+1 starts with <span ...>, the line-break between 
	; is LOST on rendering. Workaround: add extra <br/> at end of line N.
	;
	if(workaround_evernote_bug)
	{
		lines := StrSplit(html, "`n")
		Loop, % lines.Length()-1
		{
			if(StrIsEndsWith(lines[A_Index], "</span>") 
				&& StrIsStartsWith(lines[A_Index+1], "<span"))
			{
				lines[A_Index] .= "<br/>"
			}
		}
		
		html := dev_JoinStrings(lines, "`n")
	}

;	dev_WriteWholeFile("stage3.html", html) ; debug

	return html
}

genhtml_pre_colorize_eachline(html, line_comment)
{
	lines := StrSplit(html, "`n")
	
	; Process each line
	outlines := []
	for i,linetext in lines
	{
		outline := genhtml_pre_colorize_1line(linetext, line_comment)
		outlines.Push(outline)
	}

	; Join each result line
	html := dev_JoinStrings(outlines, "`n")

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
		else if(type=="HTAG") {
			; Do not touch the HTAG piece, bcz the html-tag can have tag attributes, 
			; which many contain quotes, and these quotes must be preserved as is.
			; e.g. <span style='color:#393'>&quot;&quot;&quot; ... &quot;&quot;&quot;</span>
			otext .= piecetext
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
	tagopen_pos := InStr(istr, "<")

	mino := dev_mino(sqpos?sqpos:99999, dqpos?dqpos:99999, cmpos?cmpos:99999, tagopen_pos?tagopen_pos:99999)

	if(mino.val==1)
	{
		; istr starts with a non-normal piece

		if(mino.idx==1 || mino.idx==2) {
			; find closing quote
			piecelen := InStr(istr, mino.idx==1?"'":"""", true, 2)
			if(piecelen==0) ; no closing quote, fix it
				 piecelen := ilen
			return "QSTR"
		}
		else if(mino.idx==3) {
			piecelen := ilen
			return "CMMT"
		}
		else if(mino.idx==4) {
			; find html-tag's closing bracket
			piecelen := InStr(istr, ">", true, 2)
			dev_assert(piecelen>0) ; Buggy! Html-tag closing braket lost.
			return "HTAG"
		}
	}
	else
	{
		; istr starts with a normal piece
		piecelen := dev_min(mino.val-1, ilen)
		return "NORM"
	}
	
}

genhtml_pre_colorize_block(mltext, block_comment, is_smash_quotes)
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
		
			if(is_smash_quotes)
			{
				piecetext := StrReplace(piecetext, "'", "&apos;")
				piecetext := StrReplace(piecetext, """", "&quot;")
			}
			else
			{
				; For piecetext, we need to find all child <span> element inside, and remove them,
				; bcz, we don't want the childs to <span>-set their own text color.
				
				piecetext := RegExReplace(piecetext, "<span.*?>", "")
				piecetext := RegExReplace(piecetext, "</span>", "")
			}
			
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
		bcend_pos := InStr(istr, bc_end, true, strlen(bc_start))
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

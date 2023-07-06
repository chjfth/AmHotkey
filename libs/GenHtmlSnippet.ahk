#Include %A_LineFile%\..\Amhk-common.ahk

/* API:

genhtml_code2pre_pure() ; no color highlight, just wrap in <pre>

genhtml_code2pre_2022() ; wrap in <pre> and colorize.


Use the following text-block to verify whether continuous spaces are rendered correctly.

1234567890 "string"1234567890
 234567890 "string" 234567890
  34567890 "string"  34567890
   4567890 "string"   4567890
    567890 "string"    567890
     67890 "string"     67890
      7890 "string"      7890
       890 "string"       890
        90 "string"        90
         0 "string"         0

*/

genhtml_code2pre_pure(codetext, lnprefix_start:=0, tab_spaces:=4, workaround_evernote_bug:=false)
{
	return in_genhtml_code2pre_2022(codetext, lnprefix_start, false, "", "", tab_spaces, workaround_evernote_bug)
}

genhtml_code2pre_2022(codetext, lnprefix_start:=0, line_comment:="//", block_comment:=""
	, tab_spaces:=4, workaround_evernote_bug:=true)
{
;	Dbgwin_Output("lnprefix_start=" lnprefix_start)
	
	lnprefix_start := dev_str2num(lnprefix_start) ; dev_assert(!dev_IsString(lnprefix_start))

	return in_genhtml_code2pre_2022(codetext, lnprefix_start, true, line_comment, block_comment
		, tab_spaces, workaround_evernote_bug)
}

in_genhtml_code2pre_2022(codetext, lnprefix_start:=0
	, is_color:=false, line_comment:="//", block_comment:=""
	, tab_spaces:=4, workaround_evernote_bug:=true)
{
	; lnprefix_start: If >0, each code line has a line-number prefix from this value.
	; block_comment sample: ["/*", "*/"]

	if(lnprefix_start>0)
		workaround_evernote_bug := true

	if(codetext==""){
		dev_MsgBoxWarning("No text in Clipboard yet.", A_LineFile)
		return ""
	}

	if(block_comment and block_comment.Length()!=2)
	{
		dev_MsgBoxError("In genhtml_code2pre_2022(), Error: block_comment[] array length is not 2 !")
		return ""
	}

	; Want pure \n as separator, for easier later processing
	codetext := StrReplace(codetext, "`r`n", "`n")

	html := dev_EscapeHtmlChars(codetext)

	; Tab -> spaces
	spaces := "        "
	html := StrReplace(html, "`t", SubStr(spaces, 1, tab_spaces))
	
	if(workaround_evernote_bug)
	{
		; To workaround for Evernote, we need to use &nbsp; here, to avoid 
		; multiple white-spaces collapsing, 
		; bcz we'll use <div> instead of <pre> to represent a code block.
		html := StrReplace(html, "  ", "&nbsp; ")
		
		; -- note: StrReplace(html, "  ", " &nbsp;") is problematic,
		;    bcz " &nbsp" at START of a text line will be rendered as only ONE space.
		
		; Now we need to replace it a second time, otherwise(for example),
		; "   " would result in "&nbsp;  " that would be ONLY TWO space.
		html := StrReplace(html, "  ", " &nbsp;")
	}
	
	if(is_color)
	{
		if(block_comment)
		{
			html := genhtml_pre_colorize_block(html, block_comment)
		}
		
		html := genhtml_pre_colorize_eachline(html, line_comment)
	}
	
	;
	; Wrap whole content in <pre> tag
	;
	prestyle := workaround_evernote_bug ? "" : "white-space:pre-wrap; "
	prestyle .= "border:1px solid #ddd; background-color:#f6f6f6; font-family:consolas,monospace; padding:0.3em; margin:0.3em 0; border-radius:3px"
	; -- It's a big pitty that we cannot use CSS `line-height:1.0` here, Evernote 6.5.4 seems to 
	;    force strip off the `line-height` property.
	
	if(!workaround_evernote_bug)
	{
		; The normal <pre> code-blocking process, plain and simple.
		
		html := Format("-<pre style='{}'>{}</pre>-"
			, prestyle, html)
	}
	else
	{
		; Now fix for Evernote 6.5.4 html-editing buggy behavior.
		; To see the un-fixed behavior, just call genhtml_code2pre_pure() or genhtml_code2pre_2022() with workaround_evernote_bug=false.
		;
		; [CASE 1] prefix line number not needed.
		; We WILL to use <div> block instead of <pre> block, bcz Evernote exhibits quite a few 
		; weird behavior inside <pre> block. Historical observiation reveals:
		;   (#1) If line N ends with </span> and line N+1 starts with <span ...>, the line-break between 
		;        is LOST on rendering. Workaround: add extra <br/> at end of line N.
		;   (#2) Even if fix(1) makes the pasted text look correct, user copies several lines from the 
		;        <pre> block from Evernote will see that line-breaking is still lost. 
		;        User self-assisted workaround: type an Enter inside the <pre> block, and try to copy again.
		; With <div> block, line-break should be represented as <br/>, instead of normal \n .
		;
		; [CASE 2] prefix line numbers needed.
		; We WILL use <ol><li>...<li></ol> to represent the lines.
		; In this case, a pair of <li>...</li> produces the line-break, so <br/> is not used.
	
		lines := StrSplit(html, "`n")

		if(lnprefix_start<=0 or lnprefix_start=="")
		{
			; separate each line with <br/>
			html := dev_JoinStrings(lines, "<br/>`n") ; '\n" is for easier observiation in Free Clipboard Viewer
			
			html := Format("-<div style='{}'>{}</div>-", prestyle, html)

			; Fix Evernote problem: "<br/> " at start of the line would swallow the space-char inside.
			html := StrReplace(html, "<br/> ", "<br/>&nbsp;")
		}
		else
		{
			nlines := lines.Length()
			
			if(lines[nlines]=="")
				nlines--
		
			; wrap each line in <li> tag 
			
			Loop, % nlines
			{
				if(lines[A_Index]=="")
				{
					; For empty line, we need to add an extra nbsp, otherwise, Evernote
					; swallows this empty line. i.e. user will see this line missing.
					lines[A_Index] := "&nbsp;"
				}
			
				lines[A_Index] := "<li><span style=""color:#333;"">" lines[A_Index] "</span></li>"
			}

			; We add an almost-invisible end-line mark(e.g. "//END@12" or "#END@12") to the final line,
			; so that the user can easily check whether he has once manually added/deleted some lines.
			;
			markstr := Format("<span style=""color:#ededed""> {}END@{}</span>", line_comment, lnprefix_start+nlines-1)
			lines[nlines] := StrReplace(lines[nlines], "</span></li>", markstr "</span></li>")
			
			html := dev_JoinStrings(lines, "`n") 
			
			; #b6b6b6: make the number-prefix in grey
			html := Format("-<div style='{}'><ol start=""{}"" style=""color:#b6b6b6;"">{}</ol></div>-"
				, prestyle, lnprefix_start, html)
		}
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
				color := "#c4d"
			else
				color := "#b6c"
			
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
	; Performance can be improved by eliminating redundant search. Pending.

	ilen := strlen(istr)

	sqpos := InStr(istr, "'")
	dqpos := InStr(istr, """")
	cmpos := InStr(istr, line_comment)
	tagopen_pos := InStr(istr, "<") ; html tag open bracket
	hntopen_pos := InStr(istr, "&") ; html entity charref like &amp;

	mino := dev_mino(sqpos?sqpos:99999, dqpos?dqpos:99999, cmpos?cmpos:99999
		, tagopen_pos?tagopen_pos:99999, hntopen_pos?hntopen_pos:99999)

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
		else if(mino.idx==5) {
			; find html-entity's closing bracket
			piecelen := InStr(istr, ";", true, 2)
			dev_assert(piecelen>0) ; Buggy! Html-entity charref closing semicolon lost.
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
		
			piecetext := StrReplace(piecetext, "'", "&apos;")
			piecetext := StrReplace(piecetext, """", "&quot;")
			
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


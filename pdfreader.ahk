; Note: This file is saved with UTF8 with BOM, which is the best encoding choice to write Unicode chars here.

AUTOEXEC_pdfreader: ; Workaround for Autohotkey's ugly auto-exec feature. Must be first line.

; Something to place here.
; * Customize these global vars according to your running machine:
; * Call the run-once functions.

; Example
;g_dirEverpic = D:\chj\scripts\everpic

global FOXIT_TOOL_Hand := "Hand"
global FOXIT_TOOL_SelectAnnotation := "SelectAnnotation"
global FOXIT_TOOL_SelectText := "SelectText"

global g_foxit_last_tool := "none" ; compare it with FOXIT_TOOL_Hand, FOXIT_TOOL_SelectText or FOXIT_TOOL_SelectAnnotation

; Init_MyCustomizedEnv() ; Function can be defined later.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include %A_LineFile%\..\libs\chjfuncs.ahk


; Define hotkeys below


;==============================================================
; 2015-01-05: Foxit Reader 7, 9 shortcuts
;==============================================================

foxit_ScrollReader(sdir)
{
	; sdir should be "up" or "down"
	isok := RegexClassnnFindControlEx("ahk_class classFoxitReader", "^AfxWnd100su", "^Reader$", reader_classnn)
	if(not isok)
	{
		return
	}

	ControlClick, % reader_classnn, ahk_class classFoxitReader, , Wheel%sdir%, 1
}

foxit2_GetMainWindow()
{
	; `2` implies: both Foxit Reader and Editor.
	
	hwnd := dev_GetHwndByClass("classFoxitReader")
	if(hwnd)
		return hwnd
	
	hwnd := dev_GetHwndByClass("classFoxitPhantom")
	if(hwnd)
		return hwnd

	return ""
}

foxit_IsWinExist()
{
	hwnd := foxit2_GetMainWindow()
	if(WinExist("ahk_id " hwnd)) ; call WinExist() so to update Last Found Window
		return true
	else
		return false
}

foxit_IsWinActive()
{
	hwnd := foxit2_GetMainWindow()
	if(WinActive("ahk_id " hwnd)) ; call WinActive() so to update Last Found Window
		return true
	else
		return false
}

foxit_IsEditor11Active()
{
	if(dev_IsExeActive("FoxitPDFEditor.exe"))
		return true
	else
		return false
}

foxit_IsFoxit7_ForegroundProcess()
{
	WinGet, Awinid, ID, A ; cache active window unique id
	WinGet, exepath, ProcessPath, ahk_id %Awinid%

	if(StrIsEndsWith(exepath, "FoxitReader.exe"))
		return true
	if(StrIsEndsWith(exepath, "FoxitPhantomPDF.exe"))
		return true
	
	return false
}

foxit_IsAnnoationPropertyWindowActive()
{
	; Note: Foxit 9+, which is Ribbon-only, no longer has this floating Property window.

	if(! foxit_IsFoxit7_ForegroundProcess())
		return false

	WinGet, Awinid, ID, A ; cache active window unique id
;	WinGetClass, class, ahk_id %Awinid%
	WinGetTitle, title, ahk_id %Awinid%
	
	if( title ~= ".+ Properties$" || title ~= ".+ 属性$" )
		return true
	else
		return false
}

foxit_IsVersion7(wintitle="A")
{
	isfound := RegexClassnnFindControlEx(wintitle, "^AfxWnd100su", "", target_classnn)
	if(isfound)
		return true
	else
		return false
}

foxit_copynow(is_wait_until_mainwnd_foreground:=false)
{
	Send ^c
	
	if(is_wait_until_mainwnd_foreground)
	{
		; After user press Ctrl+c, Foxit reader may popup a progress-bar at right-bottom corner
		; which lasts for about 10~100ms(more text, longer wait). During this time, hotkeys 
		; for marking underline, Squiggly is not effective. 
		; So, we wait until the main-window re-gains input-focus is required.
		;
		hwnd := foxitR_GetMainWindow()
		dev_WinWaitActiveHwnd(hwnd, 500)
	}
}

foxitR_GetMainWindow()
{
	hwnd := dev_GetHwndByWintitle("ahk_class classFoxitReader")
	if(!hwnd) {
		dev_MsgBoxInfo("foxitR_ActivateMainWindow() Not found: ""ahk_class classFoxitReader"".")
		return false
	}
	
	return hwnd
}

foxitR_ActivateMainWindow()
{
	hwnd := foxitR_GetMainWindow()
	if(!hwnd)
		return
	
	dev_WinActivateHwnd(hwnd)

	return dev_WinWaitActiveHwnd(hwnd, 500)
}

#If foxit_IsAnnoationPropertyWindowActive()

ESC:: foxit_NoEscClosePropertiesDlgbox()
foxit_NoEscClosePropertiesDlgbox()
{
	; [2023-04-07] Great job! From today on, I will NOT be afraid that
	; striking ESC key(one or multi times) will close Foxit reader 7.1.5's 
	; comment-Property dialog. Instead, ESC brings me back to Foxit main window.
	
	dev_TooltipAutoClear("ESC key no closing Foxit comment Properties Dlgbox")
	
	; But activate Foxit Reader main-window.
	if(not foxitR_ActivateMainWindow()) {
		dev_TooltipAutoClear("foxitR_ActivateMainWindow() failed.")
		return
	}
	
	foxit_MakeMainWindowFreeScrolling()
}

Enter:: foxit_EnterNoCloseCommentProperties()
foxit_EnterNoCloseCommentProperties()
{
	dev_TooltipAutoClear("ENTER key no closing Foxit comment Properties Dlgbox")
}

#If



#If foxit_IsWinActive()

ESC:: foxit_MakeMainWindowFreeScrolling()
foxit_MakeMainWindowFreeScrolling()
{
	; [2023-04-07] Great job! After user press ESC key, user can then
	; press UP/DOWN key to scroll the page. Tested on Foxit Reader 7.1.5 .
	;
	; I have to simulate SelectTextMode then SelectHandMode, bcz:
	; If currently I have a comment object(e.g. Squiggly line) selected(=highlight)
	; UP/DOWN will not take effect. "SelectTextMode then SelectHandMode" unlocks it.

	if(Is_PinyinJiaJia_Floatbar_Visible())
	{
		Send, {Esc}
		return
	}

	foxitHotkey_SelectTextMode()
	Sleep, 50
	foxitHotkey_SelectHandMode()
}

F1:: Foxit_F1_Paste()
Foxit_F1_Paste()
{
	dev_TooltipAutoClear("Foxit reader: F1 paste text.")
	SendInput ^v
}

F8:: SendInput +^{Tab}
F9:: SendInput ^{Tab}

$F5:: Foxit_HkToggleBookmarkSidebar()
Foxit_HkToggleBookmarkSidebar()
{
	if(foxit_IsVersion7())
	{
		SendInput {F5} ; Relay F5, which is [Navigation Panels -> Bookmarks]
	}
	else
	{
		; On Foxit 9+, (buggy) Configuring F5 to [Navigation Panels -> Bookmarks]
		; takes no effect, so I have to choose Ctrl+F5 as its shortcut.
		SendInput ^{F5} 
	}
}

foxitHotkey_SelectTextMode(){
	g_foxit_last_tool := FOXIT_TOOL_SelectText
	Send !1 ; Alt+1 
}
foxitHotkey_SelectAnnotationMode()
{
	g_foxit_last_tool := FOXIT_TOOL_SelectAnnotation
	Send !2 ; Alt+2 
}
foxitHotkey_SelectHandMode()
{
	g_foxit_last_tool := FOXIT_TOOL_Hand
	Send !3 ; Alt+3
}
foxitHotkey_UnderlineText()
{
	foxit_copynow(true)
	
	Send ^- 
}
foxitHotkey_SquiggleText() 
{
	foxit_copynow(true)

	Send ^{=} 
		; Writing ^= does not take effect, adding the curly brackets makes it ok,
		; just don't know the reason. Autohotkey 1.1.19.02
}
foxitHotkey_HighlightText()
{
	foxit_copynow(true)
	
	Send ^' 
}

foxitHotkey_TypeWriterReady()
{
	Send ^]
}


CapsLock & Left:: foxit_FocusBookmarkPane()
foxit_FocusBookmarkPane()
{
	fnobj := Func("foxit_ClickAroundClassnn").Bind("xi,yi", 0.5, 0.5)
	foxit_FindBookmarkPane(fnobj)
	
	dev_TooltipAutoClear("Clicked Foxit Reader 7 Bookmarks pane.")
}

^`:: foxit7_TocSync()
foxit7_TocSync()
{
	; This action is only effective when Foxit Reader 7's "Bookmarks" pane and Status-bar is visible.

	rgbobj := { }
	fnobj := Func("foxit_GetPixelColorAroundClassnn").Bind("xi,yo", 85, -15, rgbobj)
	isok := foxit_FindBookmarkPane(fnobj)
	if(!isok)
		return

	; Workaround a Foxit Reader 7.1.5 bug: On first open of a pdf, the [Expand Current Bookmark](tocsync) button
	; keeps greyed out, until we click a bookmark. So, to activate the tocsync-button, we have to enforce 
	; a click into the TOC pane at (75, 8), in hope that we click some bookmark there.

;AmDbg0("foxit7_TocSync() see rgb=" rgbobj.rgb)

	if(dev_IsGreyPixel(rgbobj.rgb))
	{
		rx := 75
		ry := 8
		dev_TooltipAutoClear(Format("Foxit7 TOC sync bug workaround: jump to some TOC entry then jump back... R({},{})", rx, ry))
		
		; [1] Click first top-visible bookmark.
		fnobj := Func("foxit_ClickAroundClassnn").Bind("xi,yi", rx, ry)
		foxit_FindBookmarkPane(fnobj)
		
		; Sigh, we need to pause a second. Without a pause, clicking on a bookmark(e.g. [TLPI] COVER)
		; may not light up the tocsync-button.
		Sleep, 900

		; [2] Click the Navigate-back small button on the bottom status bar.
		foxit7_Click_StatusbarNaviBack()
	}

	; [3] Click [Expand Current Bookmark](tocsync) button, which is at top of the Bookmarks pane.
	fnobj := Func("foxit_ClickAroundClassnn").Bind("xi,yo", 85, -15)
	foxit_FindBookmarkPane(fnobj)
}

foxit_GetPixelColorAroundClassnn(xymode, xspec, yspec, rgbobj, classnn) ; Can be a generic func?
{
	Awinid := dev_GetActiveHwnd()
	r := dev_ControlGetPos_hc(Awinid, classnn)

	is_xomode := InStr(xymode, "xo") ? true : false
	is_yomode := InStr(xymode, "yo") ? true : false
	offsetx := NewCoordFromHint(r.x, r.w, xspec, is_xomode)
	offsety := NewCoordFromHint(r.y, r.h, yspec, is_yomode)
	
;AmDbg0(Format("{},{}  {},{}  // offsetx={} , offsety={}", r.x,r.y, r.w,r.h, offsetx, offsety))
	rgbobj.rgb := dev_PixelGetColor(offsetx, offsety)
}

foxit_ClickAroundClassnn(xymode, xspec, yspec, classnn)
{
;	is_click := false ;xxxx true
;	is_movemouse := true ;xxxx false
	is_click := true
	is_movemouse := false
	dev_ControlFocusViaRegexClassNNXY(classnn, "", xymode, xspec, yspec, is_click, is_movemouse)
}

foxit_FindBookmarkPane(fnobj)
{
	bookmark_ok := RegexClassnnFindControl("^ControlBar:", "^Bookmarks$", classnn_bookmark, x,y,w,h)
	if(not bookmark_ok)
	{
		dev_MsgBoxWarning("Cannot find Foxit Bookmarks pane.")
		return false
	}
	
	if(bookmark_ok)
	{
		treeviews := RegexClassnnFindControls("^SysTreeView32", "")
;		tooltip, %x% / %y% / %w% / %h%
;		tooltip, % "treeviews " . treeviews.MaxIndex()
		for index, ctrl in treeviews
		{
;			MsgBox, % ctrl.x . "/" . ctrl.y . "/" . ctrl.w . "/" . ctrl.h ; debug
			if(Is_RectA_in_RectB(ctrl.x,ctrl.y,ctrl.w,ctrl.h , x,y,w,h, 2))
			{
				fnobj.call(ctrl.classnn)
				return true
			}
		}
	}
	
	dev_MsgBoxWarning("Cannot find Foxit Bookmarks treeview.")
	return false
}

; ^\:: foxit7_Click_StatusbarNaviBack() ; just test
foxit7_Click_StatusbarNaviBack()
{
	fnobj := Func("foxit_ClickAroundClassnn").Bind("xo,yi", 84, 14)
	foxit7_FindStatusbarPagenumEditbox(fnobj)
}

foxit7_FindStatusbarPagenumEditbox(fnobj)
{
	statusbar_ok := RegexClassnnFindControl("^BCGPRibbonStatusBar:", "", classnn_statusbar, x,y,w,h)
	if(statusbar_ok)
	{
		edits := RegexClassnnFindControls("^Edit", "")
		for index, ctrl in edits
		{
			if(Is_RectA_in_RectB(ctrl.x,ctrl.y,ctrl.w,ctrl.h , x,y,w,h, 2))
			{
				fnobj.call(ctrl.classnn)
				isok := true
				break
			}
		}
	}
	
	if(not isok)
	{
		MsgBox, % msgboxoption_IconExclamation, 
			, % "Cannot find Foxit Statusbar -> Pagenumber Editbox."
	}
}



CapsLock & Right:: foxit_FocusReaderPane()
foxit_FocusReaderPane()
{
	if(foxit_IsVersion7())
	{
		ControlFocusViaRegexClassNNXY("^AfxWnd100su", "^Reader$", 24, 0.5, true, true) 
			; true, true: will move mouse and click into the pane
	}
	else
	{
		ControlFocusViaRegexClassNNXY("^AfxMDIFrame140su", "", 24, 0.5, true, true) 
	}
}


NumpadMult:: foxitHotkey_HighlightText()

NumpadSub:: foxitHotkey_UnderlineText()
NumpadAdd:: foxitHotkey_SquiggleText()

NumLock:: foxitHotkey_SelectHandMode()

^w:: dev_TooltipDisableCloseWindow("Ctrl+W")
^q:: dev_TooltipDisableCloseWindow("Ctrl+Q")


vkE2:: foxit_AltW() ; vkE2 is the Central Europe extra \ key at the left-side of 'Z'.
;!w::   foxit_AltW()
; -- [2024-01-27] Weird, Alt+W hotkey high-probably causes FoxitReader 7 to loose 
;    PYJJ visual bar on FoxitReader App window title, so I trend to use vkE2 today.
foxit_AltW()
{
;	dev_TooltipAutoClear("Alt+W")
	dev_WaitKeyRelease("Alt")
	foxitHotkey_TypeWriterReady()
}

#If ; #If foxit_IsWinActive() 



#If foxit_IsAnnoationPropertyWindowActive() or (foxit_IsWinActive() and !foxit_IsEditor11Active())

NumpadDiv:: foxit_SwitchTo_SelectText_mode()
foxit_SwitchTo_SelectText_mode()
{
	if(not foxitR_ActivateMainWindow()) {
		dev_TooltipAutoClear("foxitR_ActivateMainWindow() failed.")
		return
	}

	foxitHotkey_SelectTextMode()
}

^F12:: foxit7_ClickTextColorSelection()

F12:: foxit_ClickColorProperty() ; The hotkey I have used since 2015
!q::  foxit_ClickColorProperty() ; for left-hand ease (2023.04)
; -- Note: This foxit_ClickColorProperty(), not Ex, is used when:
;    the comment object is selected, but the mouse is not hovering on it.

NumpadEnter:: foxit_ClickColorPropertyEx() ; for easier human right-hand hotkey activating (2023.04)

foxit_ClickColorPropertyEx()
{
	; [2023-04-07] New: User only has to hover mouse pointer on a comment object
	; (Underline, Squiggly, Strikeout etc), then call this function to popup 
	; color selection box. Yes, no longer need to manally click on the comment object.

	if(not foxitR_ActivateMainWindow()) {
		dev_TooltipAutoClear("foxitR_ActivateMainWindow() failed.")
		return
	}
	
	foxitHotkey_SelectAnnotationMode()
	
	Click 
	; -- This "Click" makes the commented area "selected"(display in inverted color), 
	; only then, can foxit_ClickColorProperty() be effective.
	; Memo: Before calling foxit_ClickColorPropertyEx(), user should have placed
	; mouse cursor onto the commented area and the comment(underline, squiggles etc)
	; has benn applied, otherwise, in vain.
	; Tested in Foxit Reader 7.1.5 on Win7.
	
	foxit_ClickColorProperty() 
}

foxit7_ClickTextColorSelection()
{
	; This click the Text color selection "button" on the []Format toolbar.
	; I have to put this toolbar on a pre-defined location.
	;
	; When I'm editing the text in a comment text-block, it changes the text color.
	
	ClickInActiveWindow(380, 105)
}


foxit_ClickColorProperty()
{
	; This clicks the color-selection "button" inside the Comment-property floating-window.
	; This floating window may have title like "Underline Properties", "Squiggly Properties" etc.

	is_retried := false

RETRY:
	; Click in Color Property button(Property-window pre-open required), so to select a color by keyboard.
	; But sometimes the color box does not popup, the workaround is to press space after F12 .
	;
	; Small flaw: In order for this to work, we should NOT have any opened File property dialogs(from Explorer),
	; bcz those dialogs also have title text like "XXX Properties".
	
	titleregex := ".+ (Properties|属性)$"
	found := ControlClickClassNN_TitleRegex("Button3", titleregex, 100)
	if(found)
	{
		; wait for the "Properties" dialog to appear
		WinWaitActive, % "ahk_class #32770", , 0.2
		
		WinGetTitle, popup_title, A
		if(popup_title ~= titleregex) 
		{
			; If current active window title is still "xxx Properties", it means Foxit's color palette
			;  has not popped up, so we press {space} to have it popup.
			Send {space} 
		} 
	}
	else
	{
		if(is_retried) {
			MsgBox, No window found with regex title:`n`n %titleregex%`n`nYou should have opened Foxit Property Comment Property-window manually.
		}
		else {
			; Try to bring up the "Properties" dialog 
			is_retried := true
			movespeed := 5
			MouseGetPos, origx, origy
			MouseClick, Right
			Sleep, 200
			
			;MouseMove, 10, 10, %movespeed% , R
			;Click ; Properties is the first popup menu item (but cannot use hot char there in Foxit 7.1.5)
				; Using mouse will fail if the menu is popping out upward(when mouse cursor is near screen bottom).
			Send {Down} ;
			Sleep, 500
			Send {Enter}
			
			Sleep, 200
			goto RETRY
		}
	}
}


foxit_PixelGetColor_greyscale(x, y)
{
	PixelGetColor, rgb, %x%, %y%
		; For a red pixel, rgb will be a string: 0x0000FF
	
	r := "0x" . SubStr(rgb, 7, 2)
	r += 0 ; note: cannot combine to one line.
	g := "0x" . SubStr(rgb, 5, 2)
	g += 0
	b := "0x" . SubStr(rgb, 3, 2)
	b += 0
	
;	MsgBox The color at %x% , %y% position is %rgb% , r=%r%, g=%g%, b=%b% ; debug
	; some ref: http://www.joellipman.com/articles/automation/autohotkey/functions-to-convert-hex-2-rgb-and-vice-versa.html
	
	return (r+g+b)/3
}


#If 


#If foxit_IsAnnoationPropertyWindowActive()

; [ and ] adjust the Opacity slider .
[:: ClickInActiveControl("msctls_trackbar321", 0.1, 0.5)
]:: ClickInActiveControl("msctls_trackbar321", 0.9, 0.5)
; or using Ctrl+← , Ctrl+→
^Left:: ClickInActiveControl("msctls_trackbar321", 0.1, 0.5)
^Right:: ClickInActiveControl("msctls_trackbar321", 0.9, 0.5)
; or Numpad Home/PgUp
NumpadHome:: ClickInActiveControl("msctls_trackbar321", 0.1, 0.5)
NumpadPgUp:: ClickInActiveControl("msctls_trackbar321", 0.9, 0.5)

#If ; foxit_IsAnnoationPropertyWindowActive()


foxit_GetCommentPropertiesDlgBox()
{
	return RegexFindToplevelWindowByTitle(".+ Properties$", "Current Properties as Default")
}

#If foxit_IsWinActive()

foxit_PropertiesClickSlidebar(left_or_right)
{
;	Dbgwin_Output(Format("foxit_PropertiesClickSlidebar({})", left_or_right)) ; debug

	hwnd := foxit_GetCommentPropertiesDlgBox()
	if(hwnd)
	{
		awinid := dev_GetActiveHwnd() ; this is Foxit main window
		
		dev_ClickInChildClassnn(hwnd, "msctls_trackbar321", left_or_right=="left"?0.1:0.9, 0.5)
		
/*
		dev_WinActivateHwnd(hwnd) ; no use, bcz Comment Properties Dlgbox is *owned* by Foxit main-window.
		waitok := dev_WinWaitActiveHwnd(awinid, 500)
		if(!waitok)
		{
			dev_TooltipAutoClear("[Unexpect]Foxit main window is not re-activated.")
		}
*/		
		;Sleep, 1000
		Click ; use Click instead
	}
}

NumpadHome:: foxit_PropertiesClickSlidebar("left")
NumpadPgUp:: foxit_PropertiesClickSlidebar("right")


#If ; foxit_IsWinActive()



#If foxit_IsWinExist()

; NumpadUp:: foxit_ScrollView("up")
; NumpadDown:: foxit_ScrollView("down")

CapsLock & [:: foxit_ScrollView("up")
CapsLock & ]:: foxit_ScrollView("down")

foxit_ScrollView(sdir)
{
	WinGetClass, class, A
	if(class=="classFoxitReader")
	{
		; [2018-01-20] A workaround for a weird symptom:
		; If FoxitReader itself is the active windows, RegexBlindScrollAControl will scroll *EmEditor* windows.
		; So, for this case, I simply send 
		Send {%sdir%}
	}
	else
	{
		isFoxit7 := RegexBlindScrollAControl(sdir, "ahk_class classFoxitReader", "^AfxWnd100su", "^Reader$")

		if(not isFoxit7) {
			; tested on Foxit9
			RegexBlindScrollAControl(sdir, "ahk_class classFoxitReader", "^FoxitDocWnd1$", "")
		}
	}
}

#If


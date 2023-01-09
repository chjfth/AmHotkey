
AUTOEXEC_EmEditor: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

global Eme_isOverlayExist := false 
global Eme_arbtn := []
global g_emeLockChar := ""
global g_emeLockCharAdv := 0 ; valid value: 1,2,3,...
global g_emeLockCharSlots := [] 
	; g_emeLockCharSlots[1]=3 means: (assume lockchar is 'X') the first tab with filename X...
	; is the third doctab on the toolbar. (first and third are both one-based, AHK custom)

global g_emeOvLabelWidth := 0

global g_emeOverlayMsg := ""

; Aux vars: (not important)
  global g_emeMode2LaunchCount := 0

global Eme_HotcharDot := "." ; const
global Eme_HotcharDot_display := "*" ; this is more visually legible than a dot


Eme_QuickTabSelect_InitHotkeys()


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;==============================================================
; EmEditor v10+
;==============================================================

Eme_ClearLockChar()
{
	g_emeLockChar := ""
	g_emeLockCharAdv := 0
	g_emeLockCharSlots := [] 
}

Eme_IsActive()
{
	IfWinActive, ahk_class EmEditorMainFrame3
	{
	    return true
	}
	return false
}

Eme_FindUpperEditAreaY(wintitle)
{
	; EmEditor may have up to four "EmEditorView" child windows(when you do split editing).
	; This function finds the Y coordinate of the upper pane(s).
	editareas := RegexClassnnFindControls("^EmEditorView[0-9]$", wintitle?wintitle:"A")
	if(not editareas) {
		return -1
	}

	miny := editareas[1].y
	for index, area in editareas
	{
		if(area.y<miny)
			miny := area.y
	}
	return miny
}

Eme_GetDocTabClassNN(wintitle)
{
	; We have to update classnn_DocTab everytime our ``Esc & x`` fires,
	; because when you open 2+ EmEditor window, their classnn_DocTab may be different.
	; So don' t use static classnn_DocTab.

	; Now find out the actual ToolbarWindow32N for Docs-Tab pane.
	
	yEditArea := Eme_FindUpperEditAreaY(wintitle)
	if(yEditArea<0) {
		MsgBox, 0x30, , % "Cannot detect ""EmEditorView"" edit area. Esc+<hotkey> pane switching cannot execute."
		return
	}
	
	toolbars := RegexClassnnFindControls("^ToolbarWindow32[0-9]+$", wintitle)
	; tooltip, % "tbs=" . toolbars.MaxIndex()
	
	for index, toolbar in toolbars
	{
	 ; DoHilightBlocksInTopwin("A", [{"x":toolbar.x,"y":toolbar.y,"w":toolbar.w,"h":toolbar.h}], 2000) ;debug
	 ; msgbox , % toolbar.classnn . ": " toolbar.y+toolbar.h+1 . " / " . yEditArea ; debug
	 if( (toolbar.y+toolbar.h+2 >= yEditArea) and (toolbar.w>100)) {
		 	classnn_DocTab := toolbar.classnn
		 	break
		 }
	}
	
	if(not classnn_DocTab) {
		MsgBox, 0x30, , 
		(
Cannot detect EmEditor Docs-Tab pane. Esc+<hotkey> document switching cannot execute.

To enable Esc+<hotkey> document switching, do the following for EmEditor(v15 for example):
Tools -> Customize -> Tab -> Style(dropdown list) -> Button(instead of Tab).
		)
	}

	return classnn_DocTab
}


Eme_BlindSendFn(n) ; maybe useless
{
	keyseq := "{Blind}{F" . n . " down}{F" . n . " up}"
	Send %keyseq% 
		; Use {Blind} because of my exp: http://superuser.com/q/873460/74107
}

Eme_SelectDoctab_Mode1(hotchar)
{
	index := Eme_CharToIndex(hotchar) ; note: hotchar is in lower case
	Eme_SelectDoctabByBtnIndex(index)

	KeyWait, %hotchar% ; avoid causing double click by user deliberately holding down the hotchar
}

Eme_SelectDoctabByBtnIndex(index)
{
	tabs := Eme_arbtn.MaxIndex()
	if(!tabs)
		return

	if(index<=0 || index>tabs)
		return ; not a valid/existing index

	WinGet, emhwnd, ID, A
	classnn_DocTab := Eme_GetDocTabClassNN("ahk_id " . emhwnd)
	WinGetPos, xwin, ywin, , , ahk_id %emhwnd% ; get EmEditor window position
	ControlGetPos, xtb, ytb, wtb, htb, %classnn_DocTab%, ahk_id %emhwnd% ; get toolbar(tb) position

	clickx := xtb + Eme_arbtn[index].x + 4 + g_emeOvLabelWidth
		; Add g_emeOvLabelWidth so that the mouse will click on the transparent area of the overlay window,
		; and the click will hit through onto EmEditor DocTab region.
	clicky := ytb + Eme_arbtn[index].y + 4
	
	; MouseMoveInActiveWindow(clickx, clicky, false) ; debug
	ClickInActiveWindow(clickx, clicky, false)
}

Eme_ShowOverlayMsg(text)
{
	if(text) {
		GuiControl, EmeDocTabOverlay:, g_emeOverlayMsg, %text%
		GuiControl, EmeDocTabOverlay:Show, g_emeOverlayMsg
	} else {
		GuiControl, EmeDocTabOverlay:Hide, g_emeOverlayMsg
	}
}

Eme_HideAllLabels()
{
	; AHK 1.1.19.02 does not support remove control yet, so I have to resort to Hide
	for index, btn in Eme_arbtn
	{
		if(btn.hctrl)
		{
			GuiControl, EmeDocTabOverlay:Hide, % btn.hctrl
		}
	}
}

Eme_CycleDoctabByChar(_hotchar)
{
	StringUpper, hotchar, _hotchar ; let hotchar in upper-case

	if(g_emeLockChar!=hotchar)
	{
		; user press this hot char the "first" time
		Eme_HideAllLabels()
		Eme_ClearLockChar()

		; Create a new g_emeLockCharSlots[] with matching hotchar
		if(hotchar==Eme_HotcharDot)
		{
			for index, btn in Eme_arbtn
			{
				if(not CharIsAlphaNum(btn.text))
					g_emeLockCharSlots.Insert(index)
			}
		}
		else
		{
			for index, btn in Eme_arbtn
			{
				if(StrIsStartsWith(btn.text, hotchar))
					g_emeLockCharSlots.Insert(index)
			}
		}

		if(not g_emeLockCharSlots.MaxIndex()) ; note: for empty array, MaxIndex() return empty string, not 0
		{
			if(hotchar!=Eme_HotcharDot)
				Eme_ShowOverlayMsg("You don't have any DocTab that starts with letter " . hotchar . " .")
			return
		}
		else 
		{
			Eme_ShowOverlayMsg("")
			
			; Draw the hotchar on each matching Tab.
			for imatch, tabindex in g_emeLockCharSlots
			{
				Eme_DrawOverlayLabel(tabindex, hotchar, imatch==1?false:true)
			}
			
			g_emeLockChar := hotchar
			g_emeLockCharAdv := 1
		}
	}
	else 
	{
		; user press this hot char a second time, so cycle to the next matching tab
		prev := g_emeLockCharAdv
		g_emeLockCharAdv += 1
		if(g_emeLockCharAdv>g_emeLockCharSlots.MaxIndex())
			g_emeLockCharAdv := 1
		
;tooltip, % ">>>>>>>>>>>>" . %hotchar% . " / " . g_emeLockCharSlots[prev] . " / " . g_emeLockCharSlots[g_emeLockCharAdv]
		Eme_DrawOverlayLabel(g_emeLockCharSlots[prev], hotchar, true) ; dark
		Eme_DrawOverlayLabel(g_emeLockCharSlots[g_emeLockCharAdv], hotchar, false) ; bright
	}
}

Eme_CycleDoctabCancel()
{
	Eme_HideAllLabels()
	Eme_DestroyDocTabOverlay()
}

Eme_QuickTabSelect_InitHotkeys()
{
	; Special Note: Calling this function causes some global side-effect:
	; In other app window, F1's keyboard event will not be detected by the app until F1 is released.
	static init_done := false
	if init_done
		return
	init_done := true

	; Define dynamic hotkeys like:
	; Esc & 1:: Eme_SelectDoctab_Mode1("1")
	; ... 
	; Esc & a:: Eme_SelectDoctab_Mode1("a")
	hotchars := "123456789abcdefghijklmnopqrstuvwxyz"
	Loop, parse, hotchars
	{
		dev_DefineHotkeyWithCondition("Esc & " A_LoopField, "Eme_IsActive", "Eme_SelectDoctab_Mode1", A_LoopField)
		
		dev_DefineHotkeyWithCondition("F1 & " A_LoopField, "Eme_IsActive", "Eme_CycleDoctabByChar", A_LoopField)
		dev_DefineHotkeyWithCondition("F1 & " Eme_HotcharDot, "Eme_IsActive", "Eme_CycleDoctabByChar", Eme_HotcharDot)
			; Use dot(.) to match any non alphanumeric filenames.

		dev_DefineHotkeyWithCondition("F1 & Esc", "Eme_IsActive", "Eme_CycleDoctabCancel", A_LoopField)
	}

}

Eme_IndexToChar(index)
{
	; Index=1, Char=1
	; Index=2, Char=2
	; ...
	; Index=10, Char='A'
	; Index=11, Char='B'
	; ...
	; Index=35, Char='Z'
	
	if(Index>=1 && Index<=9)
		return Index
	else if(Index<=35) {
		Char := Chr((Index-10)+Asc("A"))
		return Char
	}
	else
		return false
}

Eme_CharToIndex(hotchar) ; note: hotchar is lower case
{
	if(hotchar>=1 && hotchar<=9)
		return hotchar
	else if(Asc(hotchar)>=Asc("a") && Asc(hotchar)<="z") {
		index := Asc(hotchar)-Asc("a") + 10
		return index
	}
	else 
		return 0 ; invalid value
}

Eme_CreateOverlayFrame(label_color:="")
{
	; Thanks to LabelControl code from 
	; https://www.donationcoder.com/Software/Skrommel/
	;
	; This function creates the overlay window and collect data in Eme_arbtn[] .
	; Overlay label drawing is postpone until Eme_DrawOverlayLabel is called.

	; Reset some globals first 
	Eme_arbtn := []
	g_emeOvLabelWidth := 0
	Eme_ClearLockChar()
	

	WinGet, emhwnd, ID, A
	wintitle := "ahk_id " . emhwnd
	classnn_DocTab := Eme_GetDocTabClassNN(wintitle) ; Find out which toolbar is the DocTab toolbar(DTTB)
	WinGetPos, xwin, ywin, , , %wintitle% ; get EmEditor window position
	ControlGetPos, xtb, ytb, wtb, htb, %classnn_DocTab%, %wintitle% ; get the toolbar(tb) position

	static s_overlay_bgcolor := "EFEFEF" ; any color is ok, which will become transparnet
		; [2015-03-21] Very Strange! s_overlay_bgcolor must meet condition R=G=B, otherwise(e.g "0xFF0000"),
		; The overlay shows normally, but Esc+<letter> click will cause the first label enter edited state.
		; --just can't explain! (tested on chji Windows 7, AHK_L 1.1.19.02)
	static s_guiid
	
	Gui, EmeDocTabOverlay:Destroy
	Gui, EmeDocTabOverlay:-Caption +Border +ToolWindow +AlwaysOnTop ; +Border to debug
	Gui, EmeDocTabOverlay:Color, %s_overlay_bgcolor%, %label_color%
	Gui, EmeDocTabOverlay:Margin, 0, 0
	Gui, EmeDocTabOverlay:Show,x0 y0 w1 h1 NoActivate,EmeDocTabOverlay_Gui
		; NoActivate is important, so that later hotkeys like ``Esc & 1`` can be captured by EmEditor 
		; instead of the overlay window.
	WinGet, s_guiid, ID, EmeDocTabOverlay_Gui
	WinSet, TransColor, %s_overlay_bgcolor% 214, ahk_id %s_guiid%
		; 214 is the transparency level for visible parts(the one-letter labels)
	overlay_scrx := xwin+xtb
	overlay_scry := ywin+ytb
	WinMove, ahk_id %s_guiid%, , %overlay_scrx%, %overlay_scry%, %wtb%, %htb%
	
	ControlGet, hctrlDocTab, HWND, , %classnn_DocTab%, ahk_id %emhwnd%
	Eme_arbtn := EnumToolbarButtons(hctrlDocTab)
;	msgbox, % "Eme_arbtn-size:" . Eme_arbtn.MaxIndex()

	Eme_isOverlayExist := true
}

Eme_WarnArbtnNull(funcname)
{
;	MsgBox, % "BUG! Calling " . funcname . " with empty Eme_arbtn[]"
		; It arises sometimes, but no harm, so not displaying this to average user.
}

Eme_DisplayOverlayLabels_Mode1() ; Mode 1 is the Esc+<letter> mode
{
	if(not Eme_arbtn or Eme_arbtn.MaxIndex()==0)
	{
		Eme_WarnArbtnNull(A_ThisFunc)
		return ; Should not happen
	}

	for index, btn in Eme_arbtn ; Eme_arbtn[] has been set by Eme_CreateOverlayFrame()
	{	
		letter := Eme_IndexToChar(index)
		Eme_DrawOverlayLabel(index, letter, false)
	}
}

Eme_DisplayPrompt_Mode2() ; Mode 2 is the F1+<one-letter-cycle> mode
{
	if(not Eme_arbtn or Eme_arbtn.MaxIndex()==0)
	{
		Eme_WarnArbtnNull(A_ThisFunc)
		return ; Should not happen
	}

	if(not g_emeOverlayMsg)
	{
		is_chance_prompt_dot := false
		if(g_emeMode2LaunchCount>=3 and g_emeMode2LaunchCount<=4)
		{
			for index, btn in Eme_arbtn
			{
				if(not CharIsAlphaNum(btn.text))
				{
					is_chance_prompt_dot := true
					break
				}
			}
		}
		
		if(not is_chance_prompt_dot)
		{
			Gui, EmeDocTabOverlay:Font, s8 wBold, Tahoma
			Gui, EmeDocTabOverlay:Add, Edit, % "vg_emeOverlayMsg X0 Y0 w400"
				, % "Press filename first character, one or more times, until you reach it."
		}
		else
		{
			Gui, EmeDocTabOverlay:Font, s8 wNorm, Tahoma
			Gui, EmeDocTabOverlay:Add, Edit, % "vg_emeOverlayMsg X0 Y0 w400"
				, % "or press dot(.) for non-digit and non-letter filenames."
		}
	}
}

Eme_DrawOverlayLabel(which, letter, is_dark)
{
	; which: 
	;	array index into Eme_arbtn[]
	; letter:
	;	the letter(single char) to display on the label
	; is_dark:
	; 	Display the letter something vague, so that the non-dark one stands out.
	;	Today, I just use blank-text for "dark effect".
	
	if(not Eme_arbtn or Eme_arbtn.MaxIndex()==0)
	{
		Eme_WarnArbtnNull(A_ThisFunc)
		return ; Should not happen
	}
	if(which>Eme_arbtn.MaxIndex())
	{
		Eme_WarnArbtnNull(A_ThisFunc)
		return ; Should not happen
	}
	
	if(letter==Eme_HotcharDot)
		letter:=Eme_HotcharDot_display
	
	gui_x := Eme_arbtn[which].x / Get_DPIScale() ; Label's x pos in Gui-unit
	gui_y := Eme_arbtn[which].y / Get_DPIScale() ; Label's y pos in Gui-unit
		; We need to do the scaling because AHK's dialog-box unit is based on 96 DPI monitor-setting,
		; while child-window x,y is in real screen pixels. So we need this on non-96(e.g.120) dpi monitor.

	; Create the Label(edit control) if not already exist yet
	HCtrl := Eme_arbtn[which].hctrl
	if(not HCtrl)
	{
		Gui, EmeDocTabOverlay:Font, s9 wBold, Consolas ;Use a fixed-width font
		Gui, EmeDocTabOverlay:Add, Edit, % "hwndHCtrl X" . gui_x " Y" . gui_y , % letter ; generate hctrl (local var)
		Eme_arbtn[which].hctrl := HCtrl
	}
	else
	{
		GuiControl, EmeDocTabOverlay:Show, %HCtrl% ; it may have been Hide
	}
/*
	Not using this, because +/-Background often do not work well, may be the redraw is delayed.
	if(is_dark) 
	{
		GuiControl, EmeDocTabOverlay:-Background, %HCtrl%
		Sleep, 1 ; Strange! Without this Sleep, some label may not receive -Backgound option, randomly.
	}
	else 
	{
		GuiControl, EmeDocTabOverlay:+Background, %HCtrl%
	}
*/
	if(is_dark)
	{
		GuiControl, EmeDocTabOverlay:, %HCtrl%, % " "
;		Sleep, 1 ; Strange! Without this Sleep, some label may not receive -Backgound option, randomly.
	}
	else 
	{
		GuiControl, EmeDocTabOverlay:, %HCtrl%, % letter
	}

	
	if(g_emeOvLabelWidth==0)
	{
		ControlGetPos, x,y, g_emeOvLabelWidth, h, , ahk_id %HCtrl%
			; typically, We get g_emeOvLabelWidth=18
;		tooltip, g_emeOvLabelWidth=%g_emeOvLabelWidth% ;debug
	}
}

;!#e:: tooltip, % Eme_arbtn[1].hctrl . " / " . Eme_arbtn[2].hctrl


Eme_DestroyDocTabOverlay()
{
	Gui, EmeDocTabOverlay:Destroy
	Eme_arbtn := []
	Eme_isOverlayExist := false

	Eme_ClearLockChar()
}



Eme_SwitchingStart_Mode1()
{
	if(not Eme_isOverlayExist)
	{
		Eme_CreateOverlayFrame("0xFFFF88")
		Eme_DisplayOverlayLabels_Mode1()
	}
}

Eme_SwitchingStart_Mode2()
{
	if(not Eme_isOverlayExist)
	{
		Eme_CreateOverlayFrame("0x88FFFF") ; "0xFFAA33"
		
		g_emeMode2LaunchCount += 1
		Eme_DisplayPrompt_Mode2()
	}
}


#If Eme_IsActive()

!UP:: Send {UP 10}
!DOWN:: Send {DOWN 10}

~Esc:: Eme_SwitchingStart_Mode1()
~Esc UP::
	Eme_DestroyDocTabOverlay()
return


F1:: Eme_SwitchingStart_Mode2()
~F1 UP::
	Eme_SelectDoctabByBtnIndex(g_emeLockCharSlots[g_emeLockCharAdv])
	Eme_DestroyDocTabOverlay()
return


^\:: Eme_CloseSidebar()
Eme_CloseSidebar()
{
	; Sidebar is the side pane of: Word Count, Large-file Control etc.
	ClickInActiveControl("EEPaneContainer1", -5, 5)
}


#If ; EmEditor

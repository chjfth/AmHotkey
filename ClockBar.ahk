/* API:
ClockBar_Show()
ClockBar_Hide()
*/

AUTOEXEC_FloatingClock: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

global g_ClockBar ; the single instance of ClockBar
global g_hwndClockBar
global gu_ClockText

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


class ClockBar
{
	static Id := "ClockBar"
	static _tmp_ := AmDbg_SetDesc(ClockBar.Id, "Debug messages from ClockBar module.")
	
	isGuiVisible := false
	timerobj := ""
	
	followingHwnd := "" ; ClockBar is following which HWND?
	tempsave_hwnd := ""
	
	ctxmenu := "ClockBar.CtxMenu" ; its only menuname
	menutarget := "" ; set in __New()
	
	dbg(msg, lv) {
		AmDbg_output(ClockBar.Id, msg, lv)
	}
	dbg0(msg) {
		ClockBar.dbg(msg, 0)
	}
	dbg1(msg) {
		ClockBar.dbg(msg, 1)
	}
	dbg2(msg) {
		ClockBar.dbg(msg, 2)
	}
	ethrow(msg) {
		ClockBar.dbg1(msg)
		throw Exception(msg, -1)
	}
	
	__New()
	{
		this.timerobj := Func("ClockBar.TimerUpdateClock").Bind(this)
	
		this.menutarget := Func("ClockBar.MenuExec_ToggleFollow").Bind(this)
		dev_MenuAddItem(this.ctxmenu, "(menu text to change)", this.menutarget)
	
		this.CreateGui()
	}

	CreateGui()
	{
		GuiName := ClockBar.Id
		
		Gui_New(GuiName)
		Gui_AssociateHwndVarname(GuiName, "g_hwndClockBar")

		Gui_ChangeOpt(GuiName, "-Caption +ToolWindow")
		Gui_SetXYMargin(GuiName, 3, 3)
		
		Gui_Switch_Font(GuiName, 16, "0x606060", "Arial")
		Gui_WindowColor(GuiName, "FEFECC")
		
		Gui_Add_TxtLabel(GuiName, "gu_ClockText", 0, "", this.NowTimeStr())
		
		Gui_As_LastFoundWindow(GuiName)
		WinSet_Transparent(128)
		WinSet_AlwaysOnTop(true)

		dev_OnMessageRegister(win32c.WM_LBUTTONDOWN, "Clockbar_WM_LBUTTONDOWN")
	}
	
	ShowGui()
	{
		if(this.isGuiVisible)
		{
			dev_WinActivateHwnd(g_hwndClockBar) ; bring it to front
			return ; already shown
		}
		
		dev_StartTimerPeriodicEx(1000, true, this.timerobj)
		
		; Note: using NoActivate, bcz we do not intend to get user input from the ClockBar.
		Gui_Show(ClockBar.Id, "AutoSize NoActivate", ClockBar.Id " title")
		this.isGuiVisible := true
	}
	
	HideGui()
	{
		dev_StopTimer(this.timerobj)
		
		Gui_Hide(ClockBar.Id)
		this.SetClockText("(ClockBar hidden)")
		
		this.isGuiVisible := false
	}
	
	NowTimeStr()
	{
		FormatTime, outvar, , % "yyyy-MM-dd HH:mm:ss"
		return outvar
	}
	
	SetClockText(text)
	{
		GuiControl_SetText(ClockBar.Id, "gu_ClockText", text)
	}
	
	TimerUpdateClock()
	{
		this.SetClockText(this.NowTimeStr())
		
		mehwnd := g_hwndClockBar
		hehwnd := this.followingHwnd
		;
		if(this.followingHwnd)
		{
			
			mepos := dev_WinGetPos("ahk_id " mehwnd)
			hepos := dev_WinGetPos("ahk_id " hehwnd)
			
			if(hepos.minimized)
			{
				this.dbg2(Format("HE is minimized. X[{}~{}] Y[{}~{}]", hepos.x, hepos.x_, hepos.y, hepos.y_))
			}
			if(hepos.hidden)
			{
				this.dbg2(Format("HE is hidden. X[{}~{}] Y[{}~{}]", hepos.x, hepos.x_, hepos.y, hepos.y_))
			}
			
			if(hepos.minimized or hepos.hidden)
			{
				; todo: hide myself
				return
			}
			
			this.dbg2(Format("ME x[{}~{}] y[{}~{}] following 0x{:X}, X[{}~{}] Y[{}~{}]"
				, mepos.x, mepos.x_, mepos.y, mepos.y_
				, hehwnd
				, hepos.x, hepos.x_, hepos.y, hepos.y_))
			
			newpos := ClockBar.AdjustMyRect(mepos, hepos)
			if(newpos)
			{
				this.dbg2(Format("Move ME to ({},{})", newpos.x, newpos.y))
				dev_WinMoveHwnd(mehwnd, newpos.x, newpos.y)
			}
			else
			{
				this.dbg2("No move needed.")
			}
		}
	}
	
	AdjustMyRect(mepos, hepos) ; static
	{
		; Check if mepos is within range of hepos.
		; If yes, return null; if not, return a new pos(.x .y) telling ME's new position that is within hepos.
		
		movex := ClockBar.Adjust1D(mepos.x, mepos.x_, hepos.x, hepos.x_)
		movey := ClockBar.Adjust1D(mepos.y, mepos.y_, hepos.y, hepos.y_)
		
		if(movex==0 and movey==0)
			return ""
		else
			return { x : mepos.x+movex , y : mepos.y+movey }
	}
	
	Adjust1D(me1, me2, he1, he2) ;static
	{
		; Try to make [me1,me2] fall into [he1,he2]
		move2 := me2<=he2 ? 0 : he2-me2
		dev_assert(move2<=0)
		
		newme1 := me1 + move2
		move1 := newme1>he1 ? 0 : he1-newme1
		dev_assert(move1>=0)
		
		return move2 + move1
	}
	
	GuiContextMenu(GuiHwnd, CtlHwnd, EventInfo, IsRightClick, X, Y)
	{
		this.dbg2(Format("{}: GuiHwnd=0x{:X} , CtlHwnd=0x{:X} , IsRightClick={}"
			, this.ctxmenu, GuiHwnd, CtlHwnd, IsRightClick))
		this.dbg2("EventInfo: " EventInfo) ; seems always 0
		
		GuiName := ClockBar.Id
		
		if(not this.followingHwnd)
		{
			; We are not following any HWND yet.
			; Detect the HWND under mouse and suggest user to follow it.
			
			dev_WinHide_byHwnd(g_hwndClockBar)
			
			dict := dev_GetHwndUnderMouse()
			
			dev_WinShow_byHwnd(g_hwndClockBar)
			short_title := ClockBar.GetShortWinTitle(dict.hwndtop)
			
			this.tempsave_hwnd := dict.hwndtop
			
			menutext := Format("Click to follow HWND 0x{:X} ({})", dict.hwndtop, short_title)
			
			dev_MenuRenameItem(this.ctxmenu, "1&", menutext)
			dev_MenuTickItem(this.ctxmenu, "1&", false)
		}
		else
		{
;			GuiControl_SetFont(GuiName, "gu_ClockText", "", "Underline")

			short_title := ClockBar.GetShortWinTitle(this.followingHwnd)
			menutext := Format("Following HWND 0x{:X} ({})", this.followingHwnd, short_title)
			
			dev_MenuRenameItem(this.ctxmenu, "1&", menutext)
			dev_MenuTickItem(this.ctxmenu, "1&", true)
		}
		
		dev_MenuShow(this.ctxmenu) ; AHK-thread blocks inside

		this.tempsave_hwnd := "" ; must be AFTER dev_MenuShow()
	}
	
	GetShortWinTitle(hwnd) ; static
	{
		wintitle := dev_WinGetTitle_byHwnd(hwnd)
		short_title := SubStr(wintitle, 1, 20)
		if(wintitle != short_title)
			short_title .= "..."
		return short_title
	}
	
	MenuExec_ToggleFollow()
	{
		GuiName := ClockBar.Id
;		AmDbg0("ToggleFollow()..... clicked")

		if(not this.followingHwnd)
		{
			this.followingHwnd := this.tempsave_hwnd

			GuiControl_SetFont(GuiName, "gu_ClockText", "", "Underline")
		}
		else
		{
			this.followingHwnd := ""

			GuiControl_SetFont(GuiName, "gu_ClockText", "", "Normal")
		}
	}
}


Clockbar_WM_LBUTTONDOWN()
{
	if(A_Gui==ClockBar.Id)
	{
		HTCAPTION := 2
		PostMessage, % win32c.WM_NCLBUTTONDOWN, % HTCAPTION
	}
}


ClockBar_Show()
{
	if(not g_ClockBar)
		g_ClockBar := new ClockBar()
	
	g_ClockBar.ShowGui()
}

ClockBar_Hide()
{
	g_ClockBar.HideGui()
}


ClockBarGuiContextMenu(args*)
{
	; XXXGuiContextMenu() intrinsic function.
	; This is executed automatically when user right clicks on the clockbar.

	g_ClockBar.GuiContextMenu(args*)
}


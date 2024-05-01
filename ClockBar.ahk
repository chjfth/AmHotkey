AUTOEXEC_ClockBar: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

/* API:
ClockBar_Enable()
ClockBar_Disable()
ClockBar_IsEnabled()
*/


global g_ClockBar ; the single instance of ClockBar
global g_hwndClockBar
global gu_ClockText

global g_menutext_clockbar := "Enable ClockBar"

ClockBar_Init()


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


class ClockBar
{
	static Id := "ClockBar"
	static _tmp_ := AmDbg_SetDesc(ClockBar.Id, "Debug messages from ClockBar module.")

	static TimerIntervalMs := 1000 ; 1 second
		
	static EXBOUND := 5 ; const adjustable
	static OFF1 := 1
	
	isGuiVisible := false
	timerobj := ""

	dragpoint_offx := 0
	dragpoint_offy := 0
	is_dragging := false
	
	followingHwnd := "" ; ClockBar is following which HWND?
	tempsave_hwnd := ""
	snap_corner := "" ; LT, RT, LB, RB
	offx_to_corner := 0
	offy_to_corner := 0
	
	pos_cache := {} ; as returned by dev_WinGetPos()
	
	ctxmenu := "ClockBar.CtxMenu" ; its only menuname
	menutarget := "" ; set in __New()
	
	dbg(msg, lv) {
		AmDbg_output(ClockBar.Id, Format("[{}] ", ClockBar.Id) msg, lv)
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

		dev_OnMessageRegister(win32c.WM_LBUTTONDOWN, Func("Clockbar_WM_LBUTTONDOWN"))
		dev_OnMessageRegister(win32c.WM_MOUSEMOVE, "Clockbar_WM_MOUSEMOVE")
		dev_OnMessageRegister(win32c.WM_LBUTTONUP, "Clockbar_WM_LBUTTONUP")
	}
	
	ShowGui()
	{
		if(this.isGuiVisible)
		{
			dev_WinActivateHwnd(g_hwndClockBar) ; bring it to front
			return ; already shown
		}
		
		this.dbg1("ShowGui(). Start timer.")
		
		dev_StartTimerPeriodicEx(ClockBar.TimerIntervalMs, true, this.timerobj)
		
		; Note: using NoActivate, bcz we do not intend to get user input from the ClockBar.
		Gui_Show(ClockBar.Id, "AutoSize NoActivate", ClockBar.Id " title")
		this.isGuiVisible := true
	}
	
	HideGui()
	{
		this.dbg1("HideGui(). Stop timer.")

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
		
		if(this.is_dragging)
			return
		
		this.DoFollowTarget()
	}
	
	DoFollowTarget()
	{
		mehwnd := g_hwndClockBar
		hehwnd := this.followingHwnd

		mepos := dev_WinGetPos("ahk_id " mehwnd)
		hepos := dev_WinGetPos("ahk_id " hehwnd)
		
		if(not mepos.hidden)
		{
			; Make it Always-on-Top again, so that ClockBar can again be shown above other top-most window.
			WinSet_AlwaysOnTop(true, "ahk_id " mehwnd)
		}

		;
		if(this.followingHwnd)
		{
			; Determine whether we should:
			; [1] Hide or show ClockBar according to whether the target-hwnd is hidden.
			; [2] Adjust ClockBar's position to follow the target.
			; [3] Hide or show ClockBar according to whether the ClockBar is fully "covered" by non-target window.
			
			
			; Phase [1]
			
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
				dev_WinHide_byHwnd(g_hwndClockBar)
				return
			}
			
			if(mepos.hidden)
			{
;				AmDbg0(Format("??? mepos: X[{}~{}] Y[{}~{}] ", mepos.x, mepos.x_, mepos.y, mepos.y_))
				; mepos.x, mepos.y is probably empty, so load from cache
				mepos := this.pos_cache
			}
			else
			{
				this.pos_cache := mepos.clone()
			}

			dev_assert(mepos.x || mepos.y || mepos.x_ || mepos.y_)
			
			; Phase [2]
			
			this.dbg2(Format("ME x[{}~{}] y[{}~{}] following 0x{:X}, X[{}~{}] Y[{}~{}]"
				, mepos.x, mepos.x_, mepos.y, mepos.y_
				, hehwnd
				, hepos.x, hepos.x_, hepos.y, hepos.y_))
			
			newpos := this.AdjustMyRect(mepos.w, mepos.h, hepos)
			newpos.x_ := newpos.x + mepos.w
			newpos.y_ := newpos.y + mepos.h
			
			if(newpos.x==mepos.x and newpos.y==mepos.y)
			{
				this.dbg2("No move needed.")
			}
			else
			{
				this.dbg1(Format("Move ME from ({},{}) to ({},{})", mepos.x, mepos.y, newpos.x, newpos.y))
				dev_WinMoveHwnd(mehwnd, newpos.x, newpos.y)
			}
			
			; Phase [3]
			
			if(this.IsWholyCoveredbyOthers(newpos))
				dev_WinHide_byHwnd(mehwnd)
			else
			{
				dev_WinShow_byHwnd(mehwnd)
				
				; Move again, bcz previous WinMove may not have taken effect when mehwnd was hidden.
				dev_WinMoveHwnd(mehwnd, newpos.x, newpos.y)
			}
		}
	}
	
	AdjustMyRect(me_width, me_height, hepos)
	{
		mepos := {}
	
		; Step 1: Adjust according to .snap_corner .
		
		dev_assert(strlen(this.snap_corner)==2)
		
		if(this.snap_corner=="LT") {
			mepos.x := hepos.x + this.offx_to_corner
			mepos.y := hepos.y + this.offy_to_corner
		}
		else if(this.snap_corner=="RT") {
			mepos.x := hepos.x_ + this.offx_to_corner
			mepos.y := hepos.y  + this.offy_to_corner
		}
		else if(this.snap_corner=="LB") {
			mepos.x := hepos.x  + this.offx_to_corner
			mepos.y := hepos.y_ + this.offy_to_corner
		}
		else if(this.snap_corner=="RB") {
			mepos.x := hepos.x_ + this.offx_to_corner
			mepos.y := hepos.y_ + this.offy_to_corner
		}
	
		; Step 2: Check if mepos is within the rect-area of hepos.
		; If not, move mepos to reside in hepos. 
		
		movex := ClockBar.Adjust1D(mepos.x, mepos.x+me_width,  hepos.x, hepos.x_)
		movey := ClockBar.Adjust1D(mepos.y, mepos.y+me_height, hepos.y, hepos.y_)
		
		mepos.x += movex
		mepos.y += movey
		return mepos
	}
	
	Adjust1D(me1, me2, he1, he2) ;static
	{
		; Try to make [me1,me2] fall into [he1,he2], with EXBOUND constraint
		eb := ClockBar.EXBOUND
		
		move2 := (me2+eb)<=he2 ? 0 : he2-(me2+eb)
		dev_assert(move2<=0)
		
		newme1 := me1 + move2
		move1 := newme1>=(he1+eb) ? 0 : (he1+eb)-newme1
		dev_assert(move1>=0)
		
		return move2 + move1
	}
	
	GuiContextMenu(GuiHwnd, CtlHwnd, EventInfo, IsRightClick, X, Y)
	{
		this.dbg1(Format("{}: GuiHwnd=0x{:X} , CtlHwnd=0x{:X} , IsRightClick={}"
			, this.ctxmenu, GuiHwnd, CtlHwnd, IsRightClick))
		this.dbg1("EventInfo: " EventInfo) ; seems always 0
		
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
			
			this.PrepareSnapCornerInfo()

			GuiControl_SetFont(GuiName, "gu_ClockText", "", "Underline")
			
			this.DoFollowTarget()
		}
		else
		{
			this.followingHwnd := ""

			GuiControl_SetFont(GuiName, "gu_ClockText", "", "Normal")
		}
	}
	
	WM_LBUTTONDOWN()
	{
		CoordMode, Mouse, Screen
		MouseGetPos, mxScreen, myScreen
		CoordMode, Mouse, Window
		
		pos := dev_WinGetPos("ahk_id " g_hwndClockBar)
		
		this.dragpoint_offx := mxScreen - pos.x
		this.dragpoint_offy := myScreen - pos.y
		this.dbg1(Format("SetCapture. Drag-point offset to self-hwnd: ({},{})", this.dragpoint_offx, this.dragpoint_offy))
		
		DllCall("SetCapture", "Ptr", g_hwndClockBar)
		this.is_dragging := true
	}
	
	WM_MOUSEMOVE()
	{
		if(not this.is_dragging)
			return
		
		CoordMode, Mouse, Screen
		MouseGetPos, mxScreen, myScreen
		CoordMode, Mouse, Window
		
		newx := mxScreen - this.dragpoint_offx
		newy := myScreen - this.dragpoint_offy
		
		this.dbg2(Format("Dragging... new window position: ({},{})", newx, newy))
		
		dev_WinMoveHwnd(g_hwndClockBar, newx, newy)
	}
	
	WM_LBUTTONUP()
	{
		this.dbg1("ReleaseCapture.")
		
		DllCall("ReleaseCapture")
		this.is_dragging := false
		
		this.dragpoint_offx := 0
		this.dragpoint_offy := 0
		
		if(not this.followingHwnd)
			return
		
		this.PrepareSnapCornerInfo()
	}
	
	MyDistanceTo(targx, targy)
	{
		mepos := dev_WinGetPos("ahk_id " g_hwndClockBar)
		
		; just take ClockBar's center point as my position
		mex := (mepos.x + mepos.x_)/2
		mey := (mepos.y + mepos.y_)/2
		
		distance := Sqrt( (mex-targx)*(mex-targx) + (mey-targy)*(mey-targy) )
		return distance
	}
	
	PrepareSnapCornerInfo()
	{
		dev_assert(this.followingHwnd)
	
		; Now check which corner of followingHwnd is most adjacent to the ClockBar.
		; We will have the ClockBar snap to that corner.
		
		me := dev_WinGetPos("ahk_id " g_hwndClockBar)
		tg := dev_WinGetPos("ahk_id " this.followingHwnd)
		
		toLT := this.MyDistanceTo(tg.x , tg.y) ; LT: left-top
		toRT := this.MyDistanceTo(tg.x_, tg.y)
		toLB := this.MyDistanceTo(tg.x , tg.y_)
		toRB := this.MyDistanceTo(tg.x_, tg.y_)
		
		min_dist := Min(toLT, toRT, toLB, toRB)
		if(min_dist==toLT) {
			this.snap_corner := "LT"
			this.offx_to_corner := me.x - tg.x
			this.offy_to_corner := me.y - tg.y
		}
		else if(min_dist==toRT) {
			this.snap_corner := "RT"
			this.offx_to_corner := me.x - tg.x_ ; rela to target's right border
			this.offy_to_corner := me.y - tg.y
		}
		else if(min_dist==toLB) {
			this.snap_corner := "LB"
			this.offx_to_corner := me.x - tg.x
			this.offy_to_corner := me.y - tg.y_
		}
		else if(min_dist==toRB) {
			this.snap_corner := "RB"
			this.offx_to_corner := me.x - tg.x_
			this.offy_to_corner := me.y - tg.y_
		}
	}
	
	IsWholyCoveredbyOthers(mepos)
	{
		; Check four corner(outbounded by OFF1) pixels of ClockBar.
		; If they all "belong" to other top-level window, I consider it wholy covered.
		; We need to use OFF1, bcz checking OFF0 always get g_hwndClockBar itself.
		
		hwndLT := dev_GetTopHwndAtScreenXY(mepos.x-1,  mepos.y-1)
		hwndRT := dev_GetTopHwndAtScreenXY(mepos.x_+1, mepos.y-1)
		hwndLB := dev_GetTopHwndAtScreenXY(mepos.x-1,  mepos.y_+1)
		hwndrB := dev_GetTopHwndAtScreenXY(mepos.x_+1,  mepos.y_+1)
		
		dev_assert(this.followingHwnd)
		tgh := this.followingHwnd
		if(hwndLT!=tgh and hwndRT!=tgh and hwndLB!=tgh and hwndRB!=tgh)
		{
			this.dbg1("ClockBar wholy covered by no-target-window, so hide it now.")
			return true
		}
		else
			return false
	}
}


Clockbar_WM_LBUTTONDOWN()
{
	if( A_Gui != ClockBar.Id )
		return

	g_ClockBar.WM_LBUTTONDOWN()
}

Clockbar_WM_MOUSEMOVE()
{
	if( A_Gui != ClockBar.Id )
		return

	g_ClockBar.WM_MOUSEMOVE()
}

Clockbar_WM_LBUTTONUP()
{
	if( A_Gui != ClockBar.Id )
		return

	g_ClockBar.WM_LBUTTONUP()
}

Clockbar_WM_NCLBUTTONUP() ; xxx
{
	if( A_Gui != ClockBar.Id )
		return

	AmDbg0("NC mouse up....")
}

ClockBar_Enable()
{
	if(not g_ClockBar)
		g_ClockBar := new ClockBar()
	
	g_ClockBar.ShowGui()
}

ClockBar_Disable()
{
	g_ClockBar.HideGui()
}

ClockBar_IsEnabled()
{
	if(!g_ClockBar)
		return false

	return g_ClockBar.isGuiVisible
}


ClockBarGuiContextMenu(args*)
{
	; XXXGuiContextMenu() intrinsic function.
	; This is executed automatically when user right clicks on the clockbar.

	g_ClockBar.GuiContextMenu(args*)
}


ClockBar_Init()
{
	dev_MenuAddItem("TRAY", g_menutext_clockbar, "ClockBar_Systray_DoMenu")
}

ClockBar_Systray_DoMenu()
{
	if(not ClockBar_IsEnabled())
	{
		ClockBar_Enable()
		
		dev_MenuTickItem("TRAY", g_menutext_clockbar, true)
	}
	else
	{
		ClockBar_Disable()
		
		dev_MenuTickItem("TRAY", g_menutext_clockbar, false)
	}
}


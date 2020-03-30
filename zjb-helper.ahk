; Note: This file is saved with UTF8 with BOM, which is the best encoding choice to write Unicode chars here.

; API:
; zjb_DelaySendInput(delay_sec, input_chars, is_fast_send:=true)
; Dsi_ShowGui()

AUTOEXEC_zjbhelper_ahk: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.
	; MUST DO: Change the above ahk label to a specific one, such as AUTOEXEC_foobar_ahk

; Something to place here.
; * Customize these global vars according to your running machine:
; * Call the run-once functions.

; Example
;g_dirEverpic = D:\chj\scripts\everpic


global g_HwndDsi ; Dsi: Delay Send Input
global g_dsiDelaySec
global g_dsiDelayText
global g_dsiIsFastSend

global g_amstr_zjbMonitorKey := "ZJB: Monitor my keys"

global _g_zjb_UsrPwdMap := {} ; internal use

; User can override this mapping in customize.ahk
global g_zjb_UsrPwdMap_input := { "13800012345" : "123" 
	, "13800054321" : "123456"
	, "g_zjb_UsrPwdMap_input := { usr : pwd }" : "123456789" } 


zjb_InitMonitorCommonKeys()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



zjb_DelaySendInput(delay_sec, input_chars, is_fast_send:=true)
{
	static counter := new CDelayedSendInput 
		; Using `static` to ensure there is only one CDelayedSendInput object,
		; so that there will be only one pending delayed input at any given time.
	
	counter.Start(delay_sec, input_chars, is_fast_send)
}
;
; A class working with SetTimer... modified from an example from AHK chm `SecondCounter`
class CDelayedSendInput {
    __New() {
        this.count_down := 0
        this.timer := ObjBindMethod(this, "Tick")
    }
    Start(delay_sec, input_chars, is_fast_send:=true) {

		if(delay_sec<1) {
			MsgBox, % Format("Wrong parameter: delay_sec={}", delay_sec)
			return
		}
		
		if(!input_chars) {
			MsgBox, % "input_chars is empty"
			return
		}

		this.count_down := delay_sec
		this.input_chars := input_chars
		this.is_fast_send := is_fast_send

		; Known limitation: SetTimer requires a plain variable reference.
		timer := this.timer
		SetTimer, % timer, 1000

		dev_TooltipAutoClear(Format("zjb_DelaySendInput() counting down {} seconds.", this.count_down), 1000)
    }
    Stop() {
        ; To turn off the timer, we must pass the same object as before:
        timer := this.timer
        SetTimer, % timer, Off
    }
    ; In this example, the timer calls this method:
    Tick() {
        --this.count_down
        
        if(this.count_down>0) {
			dev_TooltipAutoClear(Format("counting down: {}", this.count_down))
		}
		else {
			
			if(this.is_fast_send) {
;				dev_TooltipAutoClear("counting DONE")
				SendInput, % "{Raw}" . this.input_chars
			}
			else {
				Send, % "{Raw}" . this.input_chars
			}
			this.Stop()
		}
    }
}

;
; AHK GUI for launching zjb_DelaySendInput()
;

Dsi_ShowGui()
{
	if(!g_HwndDsi) {
		Dsi_CreateGui()
	}

	Gui, Dsi:Show, , % "zjb - Delay Send Input"
}

Dsi_HideGui()
{
	Gui, Dsi:Hide
	tooltip ; turn off possible dangling tooltip
}

Dsi_CreateGui()
{
	Gui, Dsi:New ;Destroy old window if any
	Gui, Dsi:+Hwndg_HwndDsi
	
	Gui, Dsi:Font, s9 cBlack, Tahoma
	
	Gui, Dsi:Add, Text, xm, % "&Delay seconds:"
	Gui, Dsi:Add, Edit, x120 w160 yp vg_dsiDelaySec, % "3"

	Gui, Dsi:Add, Text, xm, % "&Text to send:"
	Gui, Dsi:Add, Edit, x120 w160 yp vg_dsiDelayText, % "abc"

	Gui, Dsi:Add, Text, xm, % "Is fast-send:"
	Gui, Dsi:Add, Radio, x120 yp Group Checked vg_dsiIsFastSend , % "&Yes (SendInput)"
	Gui, Dsi:Add, Radio, x+10 yp                                , % "&No"

	Gui, Dsi:Add, Button, xm y+10 w40 Default gDsi_BtnOK, % "OK"
}

Dsi_BtnOK()
{
;	dev_TooltipAutoClear("Dsi_BtnOK", 1000)
	Gui, Dsi:Submit

;	MsgBox, % Format("Delay sec: {} | Text: {} | isFastSend: {}" , g_dsiDelaySec, g_dsiDelayText, g_dsiIsFastSend)

	zjb_DelaySendInput(g_dsiDelaySec, g_dsiDelayText, g_dsiIsFastSend)
	
	Dsi_HideGui()
}

DsiGuiEscape()
{
	Dsi_HideGui()
}


;=========================================================================================

zjb_InitMonitorCommonKeys()
{
	Menu, tray, add  ; Creates a separator line.
	Menu, TRAY, add, %g_amstr_zjbMonitorKey%, zjb_ToggleMonitorKey  ; Creates a new menu item.
	Menu, TRAY, add, % "ZJB: Show Delay-send-input GUI", Dsi_ShowGui
	
	zjb_ToggleMonitorKey()
}

zjb_HookCommonKeys(is_hook)
{
	commonkeys = abcdefghijklmnopqrstuvwxyz1234567890
	Loop, parse, commonkeys
	{
		if(is_hook)
		{
			dev_DefineHotkey("~$" . A_LoopField , "zjb_HintMyKey", A_LoopField)
				; This comon-key hooking looks something brutal and exclusive. 
				; Hope others don't do the same thing.
		}
		else
		{
			dev_UnDefineHotkey("~$" . A_LoopField , "zjb_HintMyKey")
		}
	}
}

zjb_HintMyKey(now_key)
{
	dev_TooltipAutoClear(" " . now_key . " ")
	Am_PlaySound("ding.wav")
}

zjb_ToggleMonitorKey()
{
	static is_monitor := true
	is_monitor := !is_monitor ; so the first time it is false
	
	if(is_monitor) {
		Menu, TRAY, Check, %g_amstr_zjbMonitorKey%
		
		zjb_HookCommonKeys(true)
	}
	else {
		Menu, TRAY, Uncheck, %g_amstr_zjbMonitorKey%
		
		zjb_HookCommonKeys(false)
	}
}

#If IsWinTitleMatchRegex("资金保登录")

zjb_mapping_count(map)
{
	count := 0
	for key, val in map
		count++
	return count
}

_zjb_LoginFillerInit()
{
	menu_title := "== 资金保登录自动填充 =="
	Menu, ZJB_LoginFiller, Add, % menu_title, zjb_menu_null ; this acts as menu title
	Menu, ZJB_LoginFiller, Disable, % menu_title
	Menu, ZJB_LoginFiller, Add ; separator
	
	for usr, pwd in g_zjb_UsrPwdMap_input
	{
		_g_zjb_UsrPwdMap[usr] := pwd
		
		Menu, ZJB_LoginFiller, Add, % usr, zjb_FillLoginNamePwd
		
;		MsgBox, % usr . " | " . pwd
;		MsgBox, % usr . " | " . _g_zjb_UsrPwdMap[usr]
	}
	
}

zjb_menu_null()
{
}

F1:: zjb_LoginFiller_Launch()
zjb_LoginFiller_Launch()
{
	static is_init_done := false
	if(!is_init_done) {
		_zjb_LoginFillerInit() ; Late init so that customize.ahk can override g_zjb_UsrPwdMap_input 
		is_init_done := true
	}

	; If only one user is present, just fill it.
	; If 2+ users are present, pop up a menu to have user select one.

	first_usr := ""
	count := 0
	for usr, pwd in g_zjb_UsrPwdMap_input ; [2020-03-30] Weird, using _g_zjb_UsrPwdMap will result wrong
	{
		if(not first_usr) {
			first_usr := usr
		}
		count++
	}

	if(count==0) {
		MsgBox, % "g_zjb_UsrPwdMap_input is empty. Nothing to fill for you."
	}
	else if(count==1) {
		zjb_FillLoginNamePwd(first_usr, 0, 0)
	}
	else {
		Menu, ZJB_LoginFiller, Show
	}
}


zjb_FillLoginNamePwd(ItemName, ItemPos, MenuName)
{
	username := ItemName
	password := _g_zjb_UsrPwdMap[username]
	
;	MsgBox, % username . " | " . password 
	
;	dev_TooltipAutoClear("hhhhhhhhh")
	classnn_usr := "WindowsForms10.EDIT.app.0.202c6663"
	classnn_pwd := "WindowsForms10.EDIT.app.0.202c6662"
	classnn_humancode := "WindowsForms10.EDIT.app.0.202c6661"
	
	ControlFocus, % classnn_usr, A
	ControlSetText, % classnn_usr, % username, A
	
	ControlFocus, % classnn_pwd, A
	ControlSetText, % classnn_pwd, % password,  A

	ControlFocus, % classnn_humancode, A
}

#If

^!F1:: testF1()
testF1() 
{
	dev_TooltipAutoClear("testF1()")
;	ControlSend, Edit1, 200, A
	ControlSetText, Edit1, 300, A
}


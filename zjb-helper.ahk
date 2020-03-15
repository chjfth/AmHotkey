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

; Init_MyCustomizedEnv() ; Function can be defined later.

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
	commonkeys = abcdefghijklmnopqrstuvwxyz%A_Space%1234567890
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


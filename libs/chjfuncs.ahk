
;############### Zhongwen IME related ################
; [2024-04-09] Moved here from chjmisc.ahk .

Is_PinyinJiaJia_Floatbar_Visible()
{
	; If PYJJ's floatbar is visible, user is typing Chinese chars, character picking pending.
	return dev_IsWinclassExist("PYJJ_COMPUI_WND")
}

IsTypingZhongwen_PinyinJiaJia() 
{
	; 获知当前是否处于 拼音加加 中文输入状态。
	; 若是，意思是敲入的一个英文字母将被输入法浮动窗口吸收。
	; 若否，敲入的一个英文字母将直接被应用程序获得。
	
	; 本函数适用于 拼音加加 5.2 。
	
	if WinExist("ahk_class PYJJ_STATUS_WND")
	{
		; PYJJ_STATUS_WND 是拼音加加附着在应用程序标题上的状态条。
		; 接下来检查拼音加加状态条最右侧的那个小格是否是“全”字（全拼状态），
		; 检查“全”字尖顶的那个粉红像素(x78, y3)，有的话则表示中文输入状态。
		; 暂不处理双拼。
		
		WinGetPos, jjx, jjy, jjw, jjh, ahk_class PYJJ_STATUS_WND
		CoordMode, Pixel, Screen

		msec1 := dev_GetTickCount64()
		PixelGetColor, color, jjx+78, jjy+3, RGB
		msec2 := dev_GetTickCount64()
		
		;AmDbg0(Format("AHK: PixelGetColor costs {} millisec.", msec2-msec1))
		; -- On my Win7Evernote VM(on VirtualBox 6.1), it costs 60~180 millisec, quite slow.
		
		CoordMode, Pixel, Window
		if(color==0xFF0099)
			return true
		else
			return false
	}
	else
	{
		return false
	}
}

ToggleZhongwenStatus_PinyinJiaJia(is_zhongwen_on)
{
	zs := IsTypingZhongwen_PinyinJiaJia()
	
	if( (zs && !is_zhongwen_on) || (is_zhongwen_on && !zs))
		SendInput {Shift down}{Shift up}{Ctrl down}{Ctrl up}
	
	return zs ; return original status
}



;############### Zhongwen IME related ################
; [2024-04-09] Moved here from chjmisc.ahk .

Is_PinyinJiaJia_Floatbar_Visible()
{
	; If PYJJ's floatbar is visible, user is typing Chinese chars, character picking pending.
	return dev_IsWinclassExist("PYJJ_COMPUI_WND")
}

IsTypingZhongwen_PinyinJiaJia() 
{
	; ��֪��ǰ�Ƿ��� ƴ���Ӽ� ��������״̬��
	; ���ǣ���˼�������һ��Ӣ����ĸ�������뷨�����������ա�
	; ���������һ��Ӣ����ĸ��ֱ�ӱ�Ӧ�ó����á�
	
	; ������������ ƴ���Ӽ� 5.2 ��
	
	if WinExist("ahk_class PYJJ_STATUS_WND")
	{
		; PYJJ_STATUS_WND ��ƴ���ӼӸ�����Ӧ�ó�������ϵ�״̬����
		; ���������ƴ���Ӽ�״̬�����Ҳ���Ǹ�С���Ƿ��ǡ�ȫ���֣�ȫƴ״̬����
		; ��顰ȫ���ּⶥ���Ǹ��ۺ�����(x78, y3)���еĻ����ʾ��������״̬��
		; �ݲ�����˫ƴ��
		
		WinGetPos, jjx, jjy, jjw, jjh, ahk_class PYJJ_STATUS_WND
		CoordMode, Pixel, Screen
		PixelGetColor, color, jjx+78, jjy+3, RGB
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


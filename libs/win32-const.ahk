
class win32c
{

	static WM_CREATE := 0x0001
	static WM_DESTROY := 0x0002
	static WM_MOVE := 0x0003
	static WM_SIZE := 0x0005
	
	static WM_ACTIVATE := 0x0006
	
	static WM_SETFOCUS := 0x0007
	static WM_KILLFOCUS := 0x0008
	static WM_ENABLE := 0x000A
	static WM_SETREDRAW := 0x000B
	static WM_SETTEXT := 0x000C
	static WM_GETTEXT := 0x000D
	static WM_GETTEXTLENGTH := 0x000E
	static WM_PAINT := 0x000F
	static WM_CLOSE := 0x0010
	
	static WM_QUERYENDSESSION := 0x0011
	static WM_QUERYOPEN := 0x0013
	static WM_ENDSESSION := 0x0016
	
	static WM_QUIT := 0x0012
	static WM_ERASEBKGND := 0x0014
	static WM_SYSCOLORCHANGE := 0x0015
	static WM_SHOWWINDOW := 0x0018
	static WM_SETTINGCHANGE := 0x001A
	
	static WM_DEVMODECHANGE := 0x001B
	static WM_ACTIVATEAPP := 0x001C
	static WM_FONTCHANGE := 0x001D
	static WM_TIMECHANGE := 0x001E
	static WM_CANCELMODE := 0x001F
	static WM_SETCURSOR := 0x0020
	static WM_MOUSEACTIVATE := 0x0021
	static WM_CHILDACTIVATE := 0x0022
	static WM_QUEUESYNC := 0x0023
	
	static WM_GETMINMAXINFO := 0x0024
	static WM_PAINTICON := 0x0026
	static WM_ICONERASEBKGND := 0x0027
	static WM_NEXTDLGCTL := 0x0028
	static WM_SPOOLERSTATUS := 0x002A
	static WM_DRAWITEM := 0x002B
	static WM_MEASUREITEM := 0x002C
	static WM_DELETEITEM := 0x002D
	static WM_VKEYTOITEM := 0x002E
	static WM_CHARTOITEM := 0x002F
	static WM_SETFONT := 0x0030
	static WM_GETFONT := 0x0031
	static WM_SETHOTKEY := 0x0032
	static WM_GETHOTKEY := 0x0033
	static WM_QUERYDRAGICON := 0x0037
	static WM_COMPAREITEM := 0x0039
	
	static WM_GETOBJECT := 0x003D
	
	static WM_COMPACTING := 0x0041
	static WM_WINDOWPOSCHANGING := 0x0046
	static WM_WINDOWPOSCHANGED := 0x0047
	
	static WM_POWER := 0x0048
	
	static WM_COPYDATA := 0x004A
	static WM_CANCELJOURNAL := 0x004B
	
	static WM_NOTIFY := 0x004E
	static WM_INPUTLANGCHANGEREQUEST := 0x0050
	static WM_INPUTLANGCHANGE := 0x0051
	static WM_TCARD := 0x0052
	static WM_HELP := 0x0053
	static WM_USERCHANGED := 0x0054
	static WM_NOTIFYFORMAT := 0x0055
	
	static NFR_ANSI := 1
	static NFR_UNICODE := 2
	static NF_QUERY := 3
	static NF_REQUERY := 4
	
	static WM_CONTEXTMENU := 0x007B
	static WM_STYLECHANGING := 0x007C
	static WM_STYLECHANGED := 0x007D
	static WM_DISPLAYCHANGE := 0x007E
	static WM_GETICON := 0x007F
	static WM_SETICON := 0x0080
	
	static WM_NCCREATE := 0x0081
	static WM_NCDESTROY := 0x0082
	static WM_NCCALCSIZE := 0x0083
	static WM_NCHITTEST := 0x0084
	static WM_NCPAINT := 0x0085
	static WM_NCACTIVATE := 0x0086
	static WM_GETDLGCODE := 0x0087
	
	static WM_SYNCPAINT := 0x0088
	
	static WM_NCMOUSEMOVE := 0x00A0
	static WM_NCLBUTTONDOWN := 0x00A1
	static WM_NCLBUTTONUP := 0x00A2
	static WM_NCLBUTTONDBLCLK := 0x00A3
	static WM_NCRBUTTONDOWN := 0x00A4
	static WM_NCRBUTTONUP := 0x00A5
	static WM_NCRBUTTONDBLCLK := 0x00A6
	static WM_NCMBUTTONDOWN := 0x00A7
	static WM_NCMBUTTONUP := 0x00A8
	static WM_NCMBUTTONDBLCLK := 0x00A9
	
	static WM_NCXBUTTONDOWN := 0x00AB
	static WM_NCXBUTTONUP := 0x00AC
	static WM_NCXBUTTONDBLCLK := 0x00AD
	
	static WM_INPUT_DEVICE_CHANGE := 0x00FE
	
	static WM_INPUT := 0x00FF
	
	static WM_KEYDOWN := 0x0100
	static WM_KEYUP := 0x0101
	static WM_CHAR := 0x0102
	static WM_DEADCHAR := 0x0103
	static WM_SYSKEYDOWN := 0x0104
	static WM_SYSKEYUP := 0x0105
	static WM_SYSCHAR := 0x0106
	static WM_SYSDEADCHAR := 0x0107
	
	static WM_UNICHAR := 0x0109
	
	static WM_IME_STARTCOMPOSITION := 0x010D
	static WM_IME_ENDCOMPOSITION := 0x010E
	static WM_IME_COMPOSITION := 0x010F
	static WM_IME_KEYLAST := 0x010F
	
	static WM_INITDIALOG := 0x0110
	static WM_COMMAND := 0x0111
	static WM_SYSCOMMAND := 0x0112
	static WM_TIMER := 0x0113
	static WM_HSCROLL := 0x0114
	static WM_VSCROLL := 0x0115
	static WM_INITMENU := 0x0116
	static WM_INITMENUPOPUP := 0x0117
	
	static WM_GESTURE := 0x0119
	static WM_GESTURENOTIFY := 0x011A
	
	static WM_MENUSELECT := 0x011F
	static WM_MENUCHAR := 0x0120
	static WM_ENTERIDLE := 0x0121
	
	static WM_MENURBUTTONUP := 0x0122
	static WM_MENUDRAG := 0x0123
	static WM_MENUGETOBJECT := 0x0124
	static WM_UNINITMENUPOPUP := 0x0125
	static WM_MENUCOMMAND := 0x0126
	
	static WM_CHANGEUISTATE := 0x0127
	static WM_UPDATEUISTATE := 0x0128
	static WM_QUERYUISTATE := 0x0129
	
	static WM_CTLCOLORMSGBOX := 0x0132
	static WM_CTLCOLOREDIT := 0x0133
	static WM_CTLCOLORLISTBOX := 0x0134
	static WM_CTLCOLORBTN := 0x0135
	static WM_CTLCOLORDLG := 0x0136
	static WM_CTLCOLORSCROLLBAR := 0x0137
	static WM_CTLCOLORSTATIC := 0x0138
	static MN_GETHMENU := 0x01E1
	
	static WM_MOUSEFIRST := 0x0200
	static WM_MOUSEMOVE := 0x0200
	static WM_LBUTTONDOWN := 0x0201
	static WM_LBUTTONUP := 0x0202
	static WM_LBUTTONDBLCLK := 0x0203
	static WM_RBUTTONDOWN := 0x0204
	static WM_RBUTTONUP := 0x0205
	static WM_RBUTTONDBLCLK := 0x0206
	static WM_MBUTTONDOWN := 0x0207
	static WM_MBUTTONUP := 0x0208
	static WM_MBUTTONDBLCLK := 0x0209
	
	static WM_MOUSEWHEEL := 0x020A
	
	static WM_XBUTTONDOWN := 0x020B
	static WM_XBUTTONUP := 0x020C
	static WM_XBUTTONDBLCLK := 0x020D
	
	static WM_MOUSEHWHEEL := 0x020E
	
	static WM_PARENTNOTIFY := 0x0210
	static WM_ENTERMENULOOP := 0x0211
	static WM_EXITMENULOOP := 0x0212
	
	static WM_NEXTMENU := 0x0213
	static WM_SIZING := 0x0214
	static WM_CAPTURECHANGED := 0x0215
	static WM_MOVING := 0x0216
	
	static WM_DEVICECHANGE := 0x0219
	
	static WM_MDICREATE := 0x0220
	static WM_MDIDESTROY := 0x0221
	static WM_MDIACTIVATE := 0x0222
	static WM_MDIRESTORE := 0x0223
	static WM_MDINEXT := 0x0224
	static WM_MDIMAXIMIZE := 0x0225
	static WM_MDITILE := 0x0226
	static WM_MDICASCADE := 0x0227
	static WM_MDIICONARRANGE := 0x0228
	static WM_MDIGETACTIVE := 0x0229
	
	
	static WM_MDISETMENU := 0x0230
	static WM_ENTERSIZEMOVE := 0x0231
	static WM_EXITSIZEMOVE := 0x0232
	static WM_DROPFILES := 0x0233
	static WM_MDIREFRESHMENU := 0x0234
	
	static WM_TOUCH := 0x0240
	
	static WM_IME_SETCONTEXT := 0x0281
	static WM_IME_NOTIFY := 0x0282
	static WM_IME_CONTROL := 0x0283
	static WM_IME_COMPOSITIONFULL := 0x0284
	static WM_IME_SELECT := 0x0285
	static WM_IME_CHAR := 0x0286
	
	static WM_IME_REQUEST := 0x0288
	
	static WM_IME_KEYDOWN := 0x0290
	static WM_IME_KEYUP := 0x0291
	
	static WM_MOUSEHOVER := 0x02A1
	static WM_MOUSELEAVE := 0x02A3
	
	static WM_NCMOUSEHOVER := 0x02A0
	static WM_NCMOUSELEAVE := 0x02A2
	
	static WM_WTSSESSION_CHANGE := 0x02B1
	
	static WM_TABLET_FIRST := 0x02c0
	static WM_TABLET_LAST := 0x02df
	
	static WM_CUT := 0x0300
	static WM_COPY := 0x0301
	static WM_PASTE := 0x0302
	static WM_CLEAR := 0x0303
	static WM_UNDO := 0x0304
	static WM_RENDERFORMAT := 0x0305
	static WM_RENDERALLFORMATS := 0x0306
	static WM_DESTROYCLIPBOARD := 0x0307
	static WM_DRAWCLIPBOARD := 0x0308
	static WM_PAINTCLIPBOARD := 0x0309
	static WM_VSCROLLCLIPBOARD := 0x030A
	static WM_SIZECLIPBOARD := 0x030B
	static WM_ASKCBFORMATNAME := 0x030C
	static WM_CHANGECBCHAIN := 0x030D
	static WM_HSCROLLCLIPBOARD := 0x030E
	static WM_QUERYNEWPALETTE := 0x030F
	static WM_PALETTEISCHANGING := 0x0310
	static WM_PALETTECHANGED := 0x0311
	static WM_HOTKEY := 0x0312
	
	static WM_PRINT := 0x0317
	static WM_PRINTCLIENT := 0x0318
	
	static WM_APPCOMMAND := 0x0319
	
	static WM_THEMECHANGED := 0x031A
	
	static WM_CLIPBOARDUPDATE := 0x031D
	
	static WM_DWMCOMPOSITIONCHANGED := 0x031E
	static WM_DWMNCRENDERINGCHANGED := 0x031F
	static WM_DWMCOLORIZATIONCOLORCHANGED := 0x0320
	static WM_DWMWINDOWMAXIMIZEDCHANGE := 0x0321
	
	static WM_DWMSENDICONICTHUMBNAIL := 0x0323
	static WM_DWMSENDICONICLIVEPREVIEWBITMAP := 0x0326
	
	
	static WM_GETTITLEBARINFOEX := 0x033F
	
	static WM_HANDHELDFIRST := 0x0358
	static WM_HANDHELDLAST := 0x035F
	
	static WM_AFXFIRST := 0x0360
	static WM_AFXLAST := 0x037F
	
	static WM_PENWINFIRST := 0x0380
	static WM_PENWINLAST := 0x038F
	
	; Virtual Key codes

	static VK_LBUTTON := 0x01
	static VK_RBUTTON := 0x02
	static VK_CANCEL := 0x03
	static VK_MBUTTON := 0x04

	static VK_XBUTTON1 := 0x05
	static VK_XBUTTON2 := 0x06

	static VK_BACK := 0x08
	static VK_TAB := 0x09

	static VK_CLEAR := 0x0C
	static VK_RETURN := 0x0D

	static VK_SHIFT := 0x10
	static VK_CONTROL := 0x11
	static VK_MENU := 0x12
	static VK_PAUSE := 0x13
	static VK_CAPITAL := 0x14

	static VK_KANA := 0x15
	static VK_HANGUL := 0x15
	static VK_JUNJA := 0x17
	static VK_FINAL := 0x18
	static VK_HANJA := 0x19
	static VK_KANJI := 0x19

	static VK_ESCAPE := 0x1B

	static VK_CONVERT := 0x1C
	static VK_NONCONVERT := 0x1D
	static VK_ACCEPT := 0x1E
	static VK_MODECHANGE := 0x1F

	static VK_SPACE := 0x20
	static VK_PRIOR := 0x21
	static VK_NEXT := 0x22
	static VK_END := 0x23
	static VK_HOME := 0x24
	static VK_LEFT := 0x25
	static VK_UP := 0x26
	static VK_RIGHT := 0x27
	static VK_DOWN := 0x28
	static VK_SELECT := 0x29
	static VK_PRINT := 0x2A
	static VK_EXECUTE := 0x2B
	static VK_SNAPSHOT := 0x2C
	static VK_INSERT := 0x2D
	static VK_DELETE := 0x2E
	static VK_HELP := 0x2F

	static VK_0 := 0x30
	static VK_1 := 0x31
	static VK_2 := 0x32
	static VK_3 := 0x33
	static VK_4 := 0x34
	static VK_5 := 0x35
	static VK_6 := 0x36
	static VK_7 := 0x37
	static VK_8 := 0x38
	static VK_9 := 0x39

	static VK_A := Asc("A")
	static VK_B := Asc("B")
	static VK_C := Asc("C")
	static VK_D := Asc("D")
	static VK_E := Asc("E")
	static VK_F := Asc("F")
	static VK_G := Asc("G")
	static VK_H := Asc("H")
	static VK_I := Asc("I")
	static VK_J := Asc("J")
	static VK_K := Asc("K")
	static VK_L := Asc("L")
	static VK_M := Asc("M")
	static VK_N := Asc("N")
	static VK_O := Asc("O")
	static VK_P := Asc("P")
	static VK_Q := Asc("Q")
	static VK_R := Asc("R")
	static VK_S := Asc("S")
	static VK_T := Asc("T")
	static VK_U := Asc("U")
	static VK_V := Asc("V")
	static VK_W := Asc("W")
	static VK_X := Asc("X")
	static VK_Y := Asc("Y")
	static VK_Z := Asc("Z")

	static VK_LWIN := 0x5B
	static VK_RWIN := 0x5C
	static VK_APPS := 0x5D

	static VK_SLEEP := 0x5F

	static VK_NUMPAD0 := 0x60
	static VK_NUMPAD1 := 0x61
	static VK_NUMPAD2 := 0x62
	static VK_NUMPAD3 := 0x63
	static VK_NUMPAD4 := 0x64
	static VK_NUMPAD5 := 0x65
	static VK_NUMPAD6 := 0x66
	static VK_NUMPAD7 := 0x67
	static VK_NUMPAD8 := 0x68
	static VK_NUMPAD9 := 0x69
	static VK_MULTIPLY := 0x6A
	static VK_ADD := 0x6B
	static VK_SEPARATOR := 0x6C
	static VK_SUBTRACT := 0x6D
	static VK_DECIMAL := 0x6E
	static VK_DIVIDE := 0x6F
	static VK_F1 := 0x70
	static VK_F2 := 0x71
	static VK_F3 := 0x72
	static VK_F4 := 0x73
	static VK_F5 := 0x74
	static VK_F6 := 0x75
	static VK_F7 := 0x76
	static VK_F8 := 0x77
	static VK_F9 := 0x78
	static VK_F10 := 0x79
	static VK_F11 := 0x7A
	static VK_F12 := 0x7B
	static VK_F13 := 0x7C
	static VK_F14 := 0x7D
	static VK_F15 := 0x7E
	static VK_F16 := 0x7F
	static VK_F17 := 0x80
	static VK_F18 := 0x81
	static VK_F19 := 0x82
	static VK_F20 := 0x83
	static VK_F21 := 0x84
	static VK_F22 := 0x85
	static VK_F23 := 0x86
	static VK_F24 := 0x87

 	static VK_NUMLOCK := 0x90
	static VK_SCROLL := 0x91

	static VK_LSHIFT := 0xA0
	static VK_RSHIFT := 0xA1
	static VK_LCONTROL := 0xA2
	static VK_RCONTROL := 0xA3
	static VK_LMENU := 0xA4
	static VK_RMENU := 0xA5

	static VK_BROWSER_BACK := 0xA6
	static VK_BROWSER_FORWARD := 0xA7
	static VK_BROWSER_REFRESH := 0xA8
	static VK_BROWSER_STOP := 0xA9
	static VK_BROWSER_SEARCH := 0xAA
	static VK_BROWSER_FAVORITES := 0xAB
	static VK_BROWSER_HOME := 0xAC

	static VK_VOLUME_MUTE := 0xAD
	static VK_VOLUME_DOWN := 0xAE
	static VK_VOLUME_UP := 0xAF
	static VK_MEDIA_NEXT_TRACK := 0xB0
	static VK_MEDIA_PREV_TRACK := 0xB1
	static VK_MEDIA_STOP := 0xB2
	static VK_MEDIA_PLAY_PAUSE := 0xB3
	static VK_LAUNCH_MAIL := 0xB4
	static VK_LAUNCH_MEDIA_SELECT := 0xB5
	static VK_LAUNCH_APP1 := 0xB6
	static VK_LAUNCH_APP2 := 0xB7
	
}

LOWORD(n)
{
	return n & 0xFFFF
}

HIWORD(n)
{
	return (n >> 16) & 0xFFFF
}

msgx_WM_KEYDOWN(wParam, lParam)
{
	return {"vk":wParam, "fDown":true, "cRepeat":LOWORD(0xFFFF), "flags":HIWORD(lParam)}
}


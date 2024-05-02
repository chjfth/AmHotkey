
AUTOEXEC_menus_ahk: ; Workaround for Autohotkey's ugly auto-exec feature. Must be first line.

; Create the popup menu by adding some items to it.
Menu, MyMenu, Add, WinTV Toggle Mute(ctrl+m), WinTVToggleMute
Menu, MyMenu, Add, °ÔWinTV Toggle Start/Stop Recording (alt+r), WinTVToggleRecording
Menu, MyMenu, Add  ; Add a separator line.
Menu, MyMenu, Add, Aver PVR Toggle Mute (F8), AverPvrToggleMute
Menu, MyMenu, Add, °ÔAver PVR Start Recording (ctrl+r), AverStartRecording
Menu, MyMenu, Add, °ÓAver PVR Stop Recording (ctrl+s), AverStopRecording
;Menu, MyMenu, Add  ; Add a separator line.
;Menu, MyMenu, Add, UPMOST PVR Toggle Mute (m), UpmostPvrToggleMute
;Menu, MyMenu, Add, °ÔUPMOST PVR Start Recording, UpmostStartRecording
;Menu, MyMenu, Add, °ÓUPMOST PVR Stop Recording, UpmostStopRecording
Menu, MyMenu, Add  ; Add a separator line.

; Create another menu destined to become a submenu of the above menu.
Menu, Submenu1, Add, Item1, MenuHandler
Menu, Submenu1, Add, Item2, MenuHandler

; Create a submenu in the first menu (a right-arrow indicator). When the user selects it, the second menu is displayed.
Menu, MyMenu, Add, My Submenu, :Submenu1

Menu, MyMenu, Add  ; Add a separator line below the submenu.
Menu, MyMenu, Add, Item3, MenuHandler  ; Add another menu item beneath the submenu.

return  ; End of auto-execute section.


MenuHandler:
MsgBox You selected %A_ThisMenuItem% from the menu %A_ThisMenu%.
return

WinTVToggleMute:
	SetTitleMatchMode, RegEx
	ControlSend, , ^m, ^WinTV7$
	SetTitleMatchMode, 3 ; restore to default exact match
return

WinTVToggleRecording:
	SetTitleMatchMode, RegEx
	ControlSend, , !r, ^WinTV7$
	SetTitleMatchMode, 3 ; restore to default exact match
return

;======================

AverPvrToggleMute:
	SetTitleMatchMode, RegEx
	ControlSend, , {F8}, ^AVer MediaCenter$
	SetTitleMatchMode, 3 ; restore to default exact match
return

AverStartRecording:
	SetTitleMatchMode, RegEx
	ControlSend, , ^r, ^AVer MediaCenter$
	SetTitleMatchMode, 3 ; restore to default exact match
return

AverStopRecording:
	SetTitleMatchMode, RegEx
	ControlSend, , ^s, ^AVer MediaCenter$
	SetTitleMatchMode, 3 ; restore to default exact match
return

;======================

UpmostPvrToggleMute:
	SetTitleMatchMode, RegEx
	ControlSend, , m, ^UPMOST PVR$
	SetTitleMatchMode, 3 ; restore to default exact match
return

UpmostStartRecording:
	SetTitleMatchMode, RegEx
	ControlSend, , ^r, ^UPMOST PVR$
	SetTitleMatchMode, 3 ; restore to default exact match
return

UpmostStopRecording:
	SetTitleMatchMode, RegEx
	ControlSend, , {ESC}, ^UPMOST PVR$
	SetTitleMatchMode, 3 ; restore to default exact match
return



#z::Menu, MyMenu, Show  ; i.e. press the Win-Z hotkey to show the menu.

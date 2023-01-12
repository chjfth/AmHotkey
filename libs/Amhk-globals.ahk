
class Amhk
{
	; Use Amhk class to define contants with non-zero value.

	static mbopt_Ok := 0
	static mbopt_OkCancel := 1
	static mbopt_YesNo := 4
	static mbopt_YesNoCancel := 3
	static mbopt_IconStop := 16
	static mbopt_IconQuestion := 32
	static mbopt_IconExclamation := 48
	static mbopt_IconInfo := 64
	static mbopt_2nddefault := 256
	static mbopt_3rddefault := 512
	static mbopt_SystemModal := 0x1000
	static mbopt_TaskModal := 0x2000
	static mbopt_Topmost := 0x40000


	; fxhk... related:
	;
	static HotkeyFlexDispatcher := {}
	;
	static fxhk_seq     := 0 ; current processing fx-hotkey sequence
	static fxhk_seq_end := 0 ; to detect recursive calling into _dev_HotkeyFlex_callback()
	static fxhk_callback_reentrance_count := 0
	;
	; Rcb : recent callback . Tick value is 64-bit.
	static fxhkRcbStartTick := 0
	static fxhkRcbEndTick   := 0
	;
;	static fxhkCtx_keynamed    := ""
;	static fxhkCtx_purposename := ""
	static fxhk_context := {} ; hotkey-purpose context
}

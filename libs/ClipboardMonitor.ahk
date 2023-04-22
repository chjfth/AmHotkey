/*
2022.12.14 Created by Jimm Chen. AHK API to monitor Windows Clipboard change.
    Implementation: via Windows API SetClipboardViewer, ChangeClipboardChain.
    Usage: You register a callback function to this API, and it will be 
    called back when Clipboard change is detected.

APIs:
* clientid := Clipmon_CreateMonitor(fnobj)
* Clipmon_DeleteMonitor(clientid)

*/

global g_clipmonHwndTmp
global g_clipmon ; the only clipmon instance, dynamically created/destroyed


class CClipboardMonitor
{
	static FeatureId := "Clipmon"

	_GuiHwnd := 0
	_hwndNextClipViewer := 0 ; the Win32 detail from WM_CHANGECBCHAIN
	_testmember := 7
	
	_hctlTxtClients := 0
	_hctlTxtChanges := 0 ; clipboard changes detected.
	
	_nChanges := -1 ; instance member
	
	_clients := {} ; Each client is identified by a random key.
	
	static _dbghelp := "Debug-message levels from ClipboardMonitor.ahk has the following meaning:`n"
		. "* Lv0 : Unexpect errors. Will always display on Dbgwin.`n"
		. "* Lv1 : Mild working state changes, such as new clients arrive/leave.`n"
		. "* Lv2 : Verbose working state changes."
	
	__New()
	{
		this.dbg2("CClipboardMonitor.__New(), singleton creating.")
		
		if(this.CreateGui())
			return this
		else
			return ""
	}

	__Delete()
	{
		if(CClipboardMonitor.FeatureId)
		{
			; AHK 1.1.32 buggy! If user exits current Autohotkey.exe process, or,
			; user executes a Reload command, CClipboardMonitor.FeatureId becomes empty
			; when this __Delete() is executed. So, if it is empty, do not call .dbg() .
			this.dbg2("CClipboardMonitor.__Delete(), singleton destroying.")
		}
		
		bSucc := DllCall("ChangeClipboardChain"
			, "Ptr", this._GuiHwnd
			, "Ptr", this._hwndNextClipViewer)
			
		
		if(!bSucc) {
			this.dbg0("[UNEXPECT] win32 ChangeClipboardChain() fails.")
		}
		
		this.DestroyGui()
	}

	dbg(msg, lv)
	{
		static s_prepared := false
		if(!s_prepared) {
			AmDbg_SetDesc(CClipboardMonitor.FeatureId, CClipboardMonitor._dbghelp)
			s_prepared := true
		}
	
		AmDbg_output(CClipboardMonitor.FeatureId, msg, lv)
	}
	dbg0(msg)
	{
		this.dbg(msg, 0)
	}
	dbg1(msg)
	{
		this.dbg(msg, 1)
	}
	dbg2(msg)
	{
		this.dbg(msg, 2)
	}

	DestroyGui()
	{
		GuiName := CClipboardMonitor.FeatureId
		
		Gui_Destroy(GuiName)
	}

	CreateGui()
	{
		GuiName := CClipboardMonitor.FeatureId
		
		Gui_New(GuiName)
		; -- Would destroy old window with the same GuiName.

		Gui_ChangeOpt(GuiName, "+E0x0080 +E0x40000")
		; -- +E0x0080: WS_EX_TOOLWINDOW (thin title);  +E0x40000: WS_EX_APPWINDOW (want taskbar thumbnail)

		Gui, % GuiName ":+Hwndg_clipmonHwndTmp"
		
		this.dbg1("Whole GUI hwnd = " g_clipmonHwndTmp)
		
		if(!g_clipmonHwndTmp)
			return false

		this._GuiHwnd := g_clipmonHwndTmp
		this._GuiName := GuiName
		
		Gui, % GuiName ":Add", Text, % Format("w200 hwnd{}", "g_clipmonHwndTmp")
		this._hctlTxtClients := g_clipmonHwndTmp

		Gui, % GuiName ":Add", Text, % Format("w200 hwnd{}", "g_clipmonHwndTmp")
		this._hctlTxtChanges := g_clipmonHwndTmp
		
		if(g_DefaultDbgLv_Clipmon>0)
		{
			Gui_Show(GuiName, "", "ClipboardMonitor.ahk") ; Show it only for debugging purpose
		}

		GuiControl_SetText(GuiName, this._hctlTxtClients, "Clients: 0")
		GuiControl_SetText(GuiName, this._hctlTxtChanges, "WM_DRAWCLIPBOARD received: 0")

		g_clipmon := this 
		; -- We need to set this now, bcz next-on dev_OnMessage_Register() will cause 
		; Clipmon_WM_DRAWCLIPBOARD() to be called inside, *before* this CreateGui() returns.
		
		; Clipboard WinAPI related:
		
		dev_OnMessage_Register(0x030D, "Clipmon_WM_CHANGECBCHAIN")
		dev_OnMessage_Register(0x0308, "Clipmon_WM_DRAWCLIPBOARD")
		
		this._hwndNextClipViewer := DllCall("SetClipboardViewer", "Ptr", this._GuiHwnd)
		
		if(this._hwndNextClipViewer) {
			return true
		}
		else  {
			this.dbg0("[UNEXPECT] win32 SetClipboardViewer() fails.") ; TODO: try this
			return false
		}
	}
	
	GenRandom_test()
	{
		; May return duplicate values, so to test AddClient() skips duplicates.
		static s_array := [11, 11, 22, 22, 33, 44]
		static s_i := 0
		
		s_i++
		if(s_i>s_array.Length())
			s_i := 1
			
		return s_array[s_i]
	}
	
	GenRandom()
	{
		Random, outvar, 1000, 9999
		return outvar
	}
	
	AddClient(fnobj, client_name)
	{
		Loop 
		{
			clientid := this.GenRandom()
		} Until not this._clients.haskey(clientid)
		
		this._clients[clientid] := { "fnobj":fnobj, "datetime":dev_GetDateTimeStrNow(), "client_name":client_name }

		this.dbg1(Format("CClipboardMonitor.AddClient(""{}"") returns clientid: {}", client_name, clientid))

		this.UIRefreshClients()
		
		return clientid
	}
	
	DelClient(clientid)
	{
		if(not this._clients.haskey(clientid))
			return false

		this.dbg1(Format("CClipboardMonitor.DelClient({}).", clientid))
		
		this._clients.Delete(clientid)
		
		this.UIRefreshClients()
		
		if(dev_mapping_count(this._clients)==0)
		{
			g_clipmon := "" 
			; -- destroy the CClipboardMonitor instance, 
			; __Delete() gets called internally, `this` vanishes.
		}
	}
	
	UIRefreshClients()
	{
		GuiControl_SetText("", this._hctlTxtClients
			, "Clients: " dev_mapping_count(this._clients)) ; GuiName="" is ok, bcz we use explicit hwnd
	}
	
	Do_WM_CHANGECBCHAIN(wParam, lParam, msg, hwnd)
	{
		this.dbg1(Format("Do_WM_CHANGECBCHAIN(): wParam=0x{:08X} lParam=0x{:08X} hwnd=0x{:08X}."
			,wParam, lParam, hwnd))

		if(wParam == this._hwndNextClipViewer)
			this._hwndNextClipViewer := lParam
		else if(this._hwndNextClipViewer)
			dev_SendMessage(this._hwndNextClipViewer, msg, wParam, lParam)
		
	}
	
	Do_WM_DRAWCLIPBOARD(wParam, lParam, msg, hwnd)
	{
		this.dbg1(Format("Do_WM_DRAWCLIPBOARD(), hwnd=0x{:08X}", this._GuiHwnd))

		this._nChanges++
		
		GuiControl_SetText("", this._hctlTxtChanges
			, "WM_DRAWCLIPBOARD received: " this._nChanges) ; GuiName="" is ok, bcz we use explicit hwnd

		for key,client in this._clients
		{
			this.dbg1(Format("Do_WM_DRAWCLIPBOARD() clientid={} , since={}", key, client.datetime))
			client.fnobj()
		}

		this.dbg2(Format("Clipmon: Relay WM_DRAWCLIPBOARD from hwnd=0x{:08X} to hwnd=0x{:08X}", hwnd, this._hwndNextClipViewer))
		dev_SendMessage(this._hwndNextClipViewer, msg, wParam, lParam)
	}
}

CLIPMONEscape()
{
	; Don't ESC Close
	return
}

CLIPMONClose()
{
	Gui_Hide(CClipboardMonitor.FeatureId)
}

Clipmon_WM_CHANGECBCHAIN(wParam, lParam, msg, hwnd)
{
	dev_assert(g_clipmon)
	g_clipmon.Do_WM_CHANGECBCHAIN(wParam, lParam, msg, hwnd)
}

Clipmon_WM_DRAWCLIPBOARD(wParam, lParam, msg, hwnd)
{
	dev_assert(g_clipmon)
	g_clipmon.Do_WM_DRAWCLIPBOARD(wParam, lParam, msg, hwnd)
}

Clipmon_CreateMonitor(fnobj, client_name:="default-client-name")
{
	; fnobj can be either a function-object or just a function-name string.

	dev_assert(fnobj) ; fnobj must not be null
	if(!fnobj)
		return 0

	if(dev_IsString(fnobj))
	{
		; Convert fnobj into a function-object if it is only a function-name.
		fnobj := Func(fnobj)
	}

	; Check for bad parameter format:
	if(!IsObject(fnobj)) 
	{
		; If fnobj is string of not-existing function, it gets here.
	
		fnname := fnobj . ""
		
		fnname := strlen(fnname)>0 ? fnname : "MyCallbackFunction"
	
		callstack := dev_getCallStack()
	
		errmsg := Format("In {}(), fnobj parameter invalid! You should pass in a function-object, like this:`r`n`r`n"
			. "Func(""{}"") `r`n`r`n"
			. "Callstack below:`r`n{}"
			, A_ThisFunc, fnname, callstack)
		this.dbg0(errmsg)
		dev_MsgBoxError(errmsg)
		
		return ""
	}

	if(!g_clipmon)
		new CClipboardMonitor()
	
	dev_assert(g_clipmon) ; should have been assigned inside CClipboardMonitor's __New()
	
	clientid := g_clipmon.AddClient(fnobj, client_name)
	
	return clientid
}

Clipmon_DeleteMonitor(clientid)
{
	if(!g_clipmon)
		return false

	return g_clipmon.DelClient(clientid)
}

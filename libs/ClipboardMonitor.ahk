/*
2022.12.14 Created by Jimm Chen. AHK API to monitor Windows Clipboard change.
    Implementation: via Windows API SetClipboardViewer, ChangeClipboardChain.
    Usage: You register a callback function to this API, and it will be 
    called back when Clipboard change is detected.

APIs:
* clientid := Clipmon_CreateMonitor(fnobj)
* Clipmon_DeleteMonitor(clientid)

*/

global g_clipmonStatusHwnd
global g_clipmon ; the only clipmon instance, dynamically created/destroyed

global gu_clipmonLblClients
global gu_clipmonLblMsgCounts

class CClipboardMonitor
{
	static _FeatureId := "Clipmon"

	_GuiHwnd := 0
	_hwndNextClipViewer := 0 ; the Win32 detail from WM_CHANGECBCHAIN
	
	_hctlTxtClients := 0
	_hctlTxtChanges := 0 ; clipboard changes detected.
	
	_nChanges := -1 ; instance member
	
	_clients := {} ; Each client is identified by a random key.
	
	static _dbghelp := "Debug-message levels from ClipboardMonitor.ahk has the following meaning:`n"
		. "* Lv0 : Unexpected errors. Will always display on Dbgwin.`n"
		. "* Lv1 : Mild working state changes, such as new clients arrive/leave.`n"
		. "* Lv2 : Verbose working diagnostic message."
	
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
		this.dbg2("CClipboardMonitor.__Delete(), singleton destroying.")
		
		if(this._hwndNextClipViewer)
		{
			bSucc := DllCall("ChangeClipboardChain"
				, "Ptr", this._GuiHwnd
				, "Ptr", this._hwndNextClipViewer)
				
			
			if(!bSucc) 
				this.dbg0("[UNEXPECT] win32 ChangeClipboardChain() fails.")
		}
		
		this.DestroyGui()
	}

	dbg(msg, lv)
	{
		static s_prepared := false
		if(!s_prepared) {
			AmDbg_SetDesc(CClipboardMonitor._FeatureId, CClipboardMonitor._dbghelp)
			s_prepared := true
		}
		
		if(CClipboardMonitor._FeatureId)
		{
			; AHK 1.1.32 buggy! If user exits current Autohotkey.exe process, or,
			; user executes a Reload command, CClipboardMonitor._FeatureId becomes empty
			; when this __Delete() is executed. So, if it is empty, do not call .dbg() .
		
			AmDbg_output(CClipboardMonitor._FeatureId, msg, lv)
		}
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
		GuiName := CClipboardMonitor._FeatureId
		
		Gui_Destroy(GuiName)
	}

	CreateGui()
	{
		GuiName := CClipboardMonitor._FeatureId
		mywintitle := "AmHotkey Clipmon Status"
		
		Gui_New(GuiName)
		; -- Would destroy old window with the same GuiName.

		Gui_ChangeOpt(GuiName, "+E0x0080 +E0x40000")
		; -- +E0x0080: WS_EX_TOOLWINDOW (thin title);  +E0x40000: WS_EX_APPWINDOW (want taskbar thumbnail)
		
		Gui_AssociateHwndVarname(GuiName, "g_clipmonStatusHwnd")
		
		this.dbg1(Format("{}, HWND = {}", mywintitle, g_clipmonStatusHwnd))
		
		if(!g_clipmonStatusHwnd)
			return false

		this._GuiHwnd := g_clipmonStatusHwnd
		this._GuiName := GuiName
		
		Gui_Add_TxtLabel(GuiName, "gu_clipmonLblClients",   -1, "w210", "Clients: 0")
		Gui_Add_TxtLabel(GuiName, "gu_clipmonLblMsgCounts", -1, "w210", "WM_DRAWCLIPBOARD received: 0")
		
		if(g_DefaultDbgLv_Clipmon>0)
		{
			Gui_Show(GuiName, "", mywintitle) ; Show it only for debugging purpose
		}

		g_clipmon := this 
		; -- We need to set this now, bcz next-on dev_OnMessage_Register() will cause 
		; Clipmon_WM_DRAWCLIPBOARD() to be called inside, *before* this CreateGui() returns.
		
		; Clipboard WinAPI related:
		
		dev_OnMessage_Register(0x030D, "Clipmon_WM_CHANGECBCHAIN")
		dev_OnMessage_Register(0x0308, "Clipmon_WM_DRAWCLIPBOARD")
		
		prevhwnd := DllCall("SetClipboardViewer", "Ptr", this._GuiHwnd)
		; -- return previous Clipboard viewer's hwnd
		this._hwndNextClipViewer := prevhwnd
		
		this.dbg2(Format("win32 SetClipboardViewer() returns previous clipboard viewer HWND={:08X}", prevhwnd))
		
		if(not this._hwndNextClipViewer) 
		{
			winerr := win32_GetLastError()
			this.dbg2("win32 GetLastError() returns " winerr)
			this.dbg2("Since prevhwnd is NULL, and AHK engine probably overwrites WinErr code internally, "
				. "so we can not know exactly whether SetClipboardViewer succeeded or failed."
				. "You need to actually copy some text to Clipboard and see whether more Clipmon "
				. "debug messages emerge. If they emerge, we can conclude success." )
			
			; [2023-04-22] Verified. If we run two AmHotkey instances on the same machine, both
			; calling Clipmon_CreateMonitor(), we can see that: 
			; * The first instance reports prevhwnd==NULL 
			; * The second instance report prevhwnd of first instance's "AmHotkey Clipmon Status" HWND.
		}
		
		return true
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
		GuiName := CClipboardMonitor._FeatureId
		GuiControl_SetText(GuiName, "gu_clipmonLblClients", "Clients: " dev_mapping_count(this._clients))
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
		GuiName := CClipboardMonitor._FeatureId
	
		this.dbg1(Format("Do_WM_DRAWCLIPBOARD(), hwnd=0x{:08X}", this._GuiHwnd))

		this._nChanges++
		
		GuiControl_SetText(GuiName, "gu_clipmonLblMsgCounts", "WM_DRAWCLIPBOARD received: " this._nChanges)
		for key,client in this._clients
		{
			this.dbg1(Format("Do_WM_DRAWCLIPBOARD() clientid={} , since={}", key, client.datetime))
			client.fnobj()
		}

		if(this._hwndNextClipViewer)
		{
			this.dbg2(Format("Clipmon: Relay WM_DRAWCLIPBOARD from hwnd=0x{:08X} to hwnd=0x{:08X}", hwnd, this._hwndNextClipViewer))
			dev_SendMessage(this._hwndNextClipViewer, msg, wParam, lParam)
		}
	}
}

CLIPMONEscape()
{
	; Don't ESC Close
	return
}

CLIPMONClose()
{
	Gui_Hide(CClipboardMonitor._FeatureId)
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

	if(dev_IsOneWord(fnobj))
	{
		; Convert fnobj(func-name) into a function-object if it is only a function-name.
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

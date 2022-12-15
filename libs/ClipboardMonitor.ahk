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

global g_clipmonSeeDebugMsg
; -- If override to true(e.g. in customize.ahk), it will show debug-messsage and small debug window.


class CClipboardMonitor
{
	_GuiHwnd := 0
	_hwndNextClipViewer := 0 ; the Win32 detail from WM_CHANGECBCHAIN
	_testmember := 7
	
	_hctlTxtClients := 0
	_hctlTxtChanges := 0 ; clipboard changes detected.
	
	_nChanges := -1 ; instance member
	
	_clients := {} ; Each client is identified by a random key.
	
	__New()
	{
		this.dbg("CClipboardMonitor.__New().")
		
		if(this.CreateGui())
			return this
		else
			return ""
	}

	__Delete()
	{
		this.dbg("CClipboardMonitor.__Delete().")
		
		DllCall("ChangeClipboardChain"
			, "Ptr", this._GuiHwnd
			, "Ptr", this._hwndNextClipViewer)
			
		this.DestroyGui()
	}

	dbg(msg)
	{
		if(g_clipmonSeeDebugMsg)
			Dbgwin_Output(msg)
	}

	DestroyGui()
	{
		GuiName := "CLIPMON"
		
		Gui, % GuiName ":Destroy" 
	}

	CreateGui()
	{
		GuiName := "CLIPMON"
		
		Gui, % GuiName ":New" 
		; -- Would destroy old window with the same GuiName.
		;    Solution pending.

		Gui_ChangeOpt(GuiName, "+E0x0080 +E0x40000")
		; -- +E0x0080: WS_EX_TOOLWINDOW (thin title);  +E0x40000: WS_EX_APPWINDOW (want taskbar thumbnail)

		Gui, % GuiName ":+Hwndg_clipmonHwndTmp"
		
		this.dbg("Whole GUI hwnd = " g_clipmonHwndTmp)
		
		if(!g_clipmonHwndTmp)
			return false

		this._GuiHwnd := g_clipmonHwndTmp
		this._GuiName := GuiName
		
		Gui, % GuiName ":Add", Text, % Format("w200 hwnd{}", "g_clipmonHwndTmp")
		this._hctlTxtClients := g_clipmonHwndTmp

		Gui, % GuiName ":Add", Text, % Format("w200 hwnd{}", "g_clipmonHwndTmp")
		this._hctlTxtChanges := g_clipmonHwndTmp
		
		if(g_clipmonSeeDebugMsg)
		{
			Gui, % GuiName ":Show", , % "ClipboardMonitor.ahk" ; Show it only for debugging purpose
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
	
	AddClient(fnobj)
	{
		Loop 
		{
			clientid := this.GenRandom()
		} Until not this._clients.haskey(clientid)

		
		this._clients[clientid] := { "fnobj":fnobj, "datetime":dev_GetDateTimeStrNow() }

		this.dbg(Format("CClipboardMonitor.AddClient() returns clientid: {}", clientid))

		this.UIRefreshClients()
		
		return clientid
	}
	
	DelClient(clientid)
	{
		if(not this._clients.haskey(clientid))
			return false

		this.dbg(Format("CClipboardMonitor.DelClient({}).", clientid))
		
		this._clients.Delete(clientid)
		
		this.UIRefreshClients()
		
		if(dev_mapping_count(this._clients)==0)
		{
			g_clipmon := "" ; destroy the CClipboardMonitor instance, __Delete() gets called, `this` vanishes.
		}
	}
	
	UIRefreshClients()
	{
		GuiControl_SetText("", this._hctlTxtClients
			, "Clients: " dev_mapping_count(this._clients)) ; GuiName="" is ok, bcz we use explicit hwnd
	}
	
	Do_WM_CHANGECBCHAIN(wParam, lParam, msg, hwnd)
	{
		this.dbg(Format("In WM_CHANGECBCHAIN(): wParam=0x{:08X} lParam=0x{:08X} hwnd=0x{:08X}."
			,wParam, lParam, hwnd))

		if(wParam == this._hwndNextClipViewer)
			this._hwndNextClipViewer := lParam
		else if(this._hwndNextClipViewer)
			dev_SendMessage(this._hwndNextClipViewer, msg, wParam, lParam)
		
	}
	
	Do_WM_DRAWCLIPBOARD(wParam, lParam, msg, hwnd)
	{
		this.dbg(Format("In WM_DRAWCLIPBOARD(), hwnd=0x{:08X}", this._GuiHwnd))

		this._nChanges++
		
		GuiControl_SetText("", this._hctlTxtChanges
			, "WM_DRAWCLIPBOARD received: " this._nChanges) ; GuiName="" is ok, bcz we use explicit hwnd

		for key,client in this._clients
		{
			this.dbg(Format("Do_WM_DRAWCLIPBOARD clientid={} , since={}", key, client.datetime))
			client.fnobj()
		}

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
	Gui_Hide("CLIPMON")
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

Clipmon_CreateMonitor(fnobj)
{
	; Check for bad parameter format:
	if(!IsObject(fnobj)) 
	{
		fnname := fnobj . ""
		
		fnname := strlen(fnname)>0 ? fnname : "MyCallbackFunction"
	
		callstack := dev_getCallStack()
	
		dev_MsgBoxError(Format("In {}(), fnobj parameter invalid! You should pass in a function-object, like this:`r`n`r`n"
			. "Func(""{}"") `r`n`r`n"
			. "Callstack below:`r`n{}"
			, A_ThisFunc, fnname, callstack))
		return ""
	}

	if(!g_clipmon)
		new CClipboardMonitor()
	
	dev_assert(g_clipmon) ; should have been assigned inside CClipboardMonitor's __New()
	
	clientid := g_clipmon.AddClient(fnobj)

	return clientid
}

Clipmon_DeleteMonitor(clientid)
{
	if(!g_clipmon)
		return false

	return g_clipmon.DelClient(clientid)
}

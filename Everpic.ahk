AUTOEXEC_Everpic: ; Workaround for Autohotkey's ugly auto-exec feature. Must be first line.

/* APIs:
Evp_LaunchUI(http_server_baseurl:="")

Everpic_InitHotkeys(http_server_baseurl:="") ; optional

Evp_FixInternalHttpServer() 
; -- If HTTP server chokes(not respond to client), need to call this to recover. (testing)

[Scenario 1] If user feels OK with the default hotkey of App+C, then, none of the above API is needed.
When user press App+C, Evp_LaunchUI() is triggered and the Everpic UI pops up converting the clipboard image.

[Scenario 2a] If user feels OK with the default hotkey of App+C and want to have HTTP server activated
(so that the image-carrying CF_HTML can be pasted into Evclip), user should call

	Everpic_InitHotkeys("*") 

once in customize.ahk .

[Scenario 2b] If user wants to work with customized HTTP server, then in customize.ahk, he calls once:

	Everpic_InitHotkeys("http://localhost:2017") 

[Scenario 3] If user wants to have another hotkey(^#c for example) to activate Everpic UI, then
he should call one of below once in customize.ahk :

	fxhk_DefineHotkey("^#c", false, "Evp_LaunchUI")
	fxhk_DefineHotkey("^#c", false, "Evp_LaunchUI", "*")
	fxhk_DefineHotkey("^#c", false, "Evp_LaunchUI", "http://localhost:2017")
*/

;;;;;;;; Everpic global vars ;;;;;;;;;;

; global g_evpTempDir := A_Temp "\Everpic" ; [2025-01-13] Now use Everpic.dirTempImg .

global gc_evpBatchConvertExecpath := A_ScriptDir "\exe\everpic-batch-prepare.bat"

global g_evpBaseImageFilepath_100pct
	; If user choose a new scale, we use g_evpBaseImageFilepath_100pct to re-generate
	; new scaled images, instead of re-generate from clipboard.
	; Note: The so-called "BaseImage", is always in Everpic.dirTempImg.
;global g_evpBaseImageFilepath_scaled ; no use

global g_evpImageWidth
global g_evpImageHeight

global g_evpImglistTxtPath
global g_evpBatchProgressFilepath
global g_evpImageSig := ""
	; need it as "signature" in Evernote image footnote. by Evp_GenImageSigByTimestamp().
	; Example: "everpic-20221205_150413"

global g_evpTempPreserveMinutes := 60*24 ; default to one day

global g_evpHwndToPaste

global gc_evpImgpaneDefWidth  := 400 ; image-pane default width
global gc_evpImgpaneDefHeight := 300
global g_evpImgpaneWidth      := gc_evpImgpaneDefWidth  ; To be filled in Evp_ShowGui()
global g_evpImgpaneHeight     := gc_evpImgpaneDefHeight ; To be filled in Evp_ShowGui()
global gc_evpCol1Width     := 160 ; EVP GUI Column 1 width in pixels
global gc_evpGapX := 10 ; const, gap between listbox and pic-control
global gc_evpGapY := 10 ; const, gap between listbox and pic-control
global gc_evp_GUIDefWidth := gc_evpGapX*2 + gc_evpCol1Width + gc_evpImgpaneDefWidth ; GUI default width

global gar_evpScalePcts := [ 100, 75, 50, 40, 30, 20 ]

global gc_evpMarginX := 10 ; const
global gc_evpMarginY := 10 ; const
global g_evpWindowBorder := 14 ; assume, may not be accurate yes
global g_evpBottomLineHeight := 16 ; for Button OK/Dismiss/Use_This

global g_HwndEVPGui

global gc_evp_CF_BITMAP := 2

; First column controls:
;
global gu_evpBtnCvtFromClipbrd := ""  ; The top-left corner "Convert from Clipboard" button
global gu_evpCkbAutoConvert    := 0
global gu_evpTxtScale   := ""  ; the small "Scale:" text label
global gu_evpCbxScalePct := 0  ; The image-scale percent combobox
global gu_evpBtnCvtFromBaseImg := ""  ; The Refresh button that converts from existing Base-image
global g_evpCurrentScalePct := 100
global gu_evpLbxImages   := 0  ; Image-candidates list listbox 
global gu_evpEdrLoadStat := "" ; Small text label, result statistics, e.g, "640*480, 0.2s"
;
; Second column controls:
;
global gu_evpTxtClipbState := "" ; Text label showing clipboard state.
global gu_evpIcnWarnNoTranspixel := "" ; Icon warning "no transparent pixel in png"
global gu_evpCkbKeepPngTrans := ""

global gu_evpEdrBaseImgFilepath := "" ; Currently previewing image filepath (readonly editbox)
global gu_evpPicPreview ; gui-assoc, Picture control
global g_evpCurPngHasTranspx := false ; Current png has transparent pixel? Detected by Evp_TimerProcCheckPngfileTranspixel()
;
global gu_evpBtnOK := "" ; Left-bottom "Use This" button
global gu_evpCkbAutoPaste  := ""
global gu_evpCkbKeepWindow := ""

global gu_evpEdrFootline   := "" ; current select image filepath
global gu_evpBtnCopyFile   := "" ; the button at right edge of gu_evpEdrFootline

global gc_evpIconBtnWidth := 25

global g_evpIsGuiVisible := false
global g_evpConvertStartCount := 0 ; increase one each time Launch convert.
global g_evpConvertSuccCount := 0

global gc_evpConvertBtnText := "&Convert from Clipboard"
global g_evpTimerStage := "Monitoring" 
	; "Monitoring" : Periodically check(monitor) the clipboard for image or CF_BITMAP or image-filepath.
	; "ConvertStarting" : External everpic-batch-prepare.bat launched, waiting for <basename>.progress.done.txt .
	; "ConvertStarted"  : <basename>.progress.done.txt detected, checking its content for progress.
global g_evpTickConvertStart := 0
global g_evpIsCancelling := false

global gc_evpFileSuffix_progressdone := ".progress.done.txt"
global gc_evpFileSuffix_imagelist    := ".imagelist.txt"

global gc_evpStartingTimeoutSec := 3
global g_evpBgCvtProcessId := 0

global g_evp_arImageStore := [] ; g_evp_arImageStore[1] refers to the first previewed image.
	; members: .hint .filelen_desc .path
global g_evpImageZoom := 1

global gut_progressbar := ""

global g_isKeepPngTransparent
global gc_KeepPngTransparent := true ; as synonym for true

global g_evpIsFullUIExpaned := -1 ; -1 means unset

global g_evp_hClipmon ; Clipboard monitor handle
global g_evp_ClipmonSeqNow := 0 ; Clipboard change sequence-number
global g_evp_ClipmonSeqAct := 0 ; The sequence-number on which we have done image-conversion.

global g_evpDbgCfg := {"showdbginfo":false, "showdbgcleanup":false, "showbgcmd":false, "slowbgcmd":0}

global g_evpSuppressUicTooltipBfrThis := A_Now ; will store A_Now format string


Everpic_InitHotkeys()

#Include %A_LineFile%\..\libs\Gdip_All.ahk


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


class Everpic
{
	static dirTempImg := A_Temp "\Everpic"
	static dirSaveImg := A_AppData "\Everpic-save"
	; -- User can override the above two dirs in customize.ahk .

	static listen_port_base := 2024
	static baseurl := "(not-set)" ; http://localhost:2024
	
	static httpserver := "" ; points to internal HttpServer() object
}


Everpic_InitHotkeys(http_server_baseurl:="")
{
	; App+c to callup Everpic UI, we make it global hotkey.
	; This converts in-clipboard image to your preferred format(png/jpg) and put CF_HTML content into clipboard,
	; so Ctrl+v pasting it into Evernote saves quite much space (Evernote defaultly gives you very big PNG-32).
	;
	; Note: Before Evp_LaunchUI() is actually called, user can call Everpic_InitHotkeys() a second time
	; with another http_server_baseurl value to overide the to-be-used BaseURL.
	; After Evp_LaunchUI() is called the first time, the BaseURL is solidified and can not be changed any more.
	;
	; Example:
	;	Everpic_InitHotkeys("http://localhost:2017")
	
	hotkey_purpose := "Purpose-Evp_LaunchUI"
	
	ret_purpose := fxhk_DefineComboHotkeyCondComment("AppsKey", "c"
		, hotkey_purpose ; must be explicit, so that a second call can override it.
		, "" ; user_comment
		, "" ; fn_cond
		, "Evp_LaunchUI", http_server_baseurl)
	
	dev_assert(hotkey_purpose==ret_purpose)
}

evp_HttpServing(ByRef request, ByRef response, ByRef server) {

	parts := StrSplit(request.path, "/")
	filenam := parts[parts.length()]

	dir_everpic_save := Everpic.dirSaveImg
	imgpath := Format("{}\{}", dir_everpic_save, filenam)
;	Amdbg0("Want: " imgpath)

	retlen := server.ServeFile(response, imgpath)
	if(retlen>0)
		response.status := 200
}

evp_LaunchHttpServer(listen_port)
{
	paths := {}
	paths["/Everpic-save"] := Func("evp_HttpServing")

	serv := new HttpServer()
	serv.LoadMimes("libs\mime.types")
	serv.SetPaths(paths)
	
	; Try 10 listen_port until success.
	listen_port_end_ := listen_port + 10
	
	Loop
	{
		; Amdbg0("Trying... " listen_port)
		err := serv.Serve(listen_port)
		if(!err)
			break
		
		listen_port++
		Sleep, 10
	}
	
	if(listen_port==listen_port_end_) {
		dev_MsgBoxError(Format("In evernote.ahk: Error starting HTTP server, tried port range {} ~ {}, Last WinError={}"
			, listen_port, listen_port_end_, ErrorLevel))
		return false
	}
	
	Everpic.baseurl := Format("http://localhost:{}", listen_port)
	
	Everpic.httpserver := serv
	return true
}

evp_StopHttpServer()
{
	Everpic.httpserver.StopServe()
}

Evp_FixInternalHttpServer()
{
	if(not Everpic.httpserver)
	{
		dev_MsgBoxInfo("You are not using Everpic's internal HTTP server, nothing to fix.")
		return
	}

	evp_StopHttpServer()
	
	is_ok := evp_LaunchHttpServer(Everpic.listen_port_base)
	if(is_ok)
		dev_MsgBoxInfo("Everpic internal HTTP server restart success.")
	else
		dev_MsgBoxWarning("Everpic internal HTTP server restart failed. You may try again.")
}


Evp_WinTitle()
{
	return "Everpic v2024.04"
}

evpdbg(msg)
{
	if(g_evpDbgCfg.showdbginfo)
		Dbgwin_Output(msg)
}

Evp_LaunchUI(http_server_baseurl:="")
{
	static s_inited := false
	if(!s_inited)
	{
		if(http_server_baseurl=="")
		{
			; No HTTP server involved. User will not be able to paste CF_HTML into Evclip,
			; only to copy generated image filepath, or, "List of files" for pasting into Explorer.
		}
		if(http_server_baseurl=="*")
		{
			; Use AHKHttp as (internal) HTTP server
			evp_LaunchHttpServer(Everpic.listen_port_base)
		}
		else if(http_server_baseurl!="")
		{
			; User may set-up his own HTTP server for this purpose. For example:
			; "http://localhost:2017"
			Everpic.baseurl := http_server_baseurl
		}

		s_inited := true ; Even if HTTP server start-up fail.
	}

	if(!dev_CreateDirIfNotExist(Everpic.dirTempImg))
	{
		dev_MsgBoxError("Error. Cannot create folder: " Everpic.dirTempImg)
		return
	}
	
	; Remember current active window, it becomes paste target later
	g_evpHwndToPaste := dev_GetActiveHwnd()
	
	was_gui_visible := g_evpIsGuiVisible

	Evp_ShowGui()

	Gui_Show("EVP", "", Evp_WinTitle()) ; This ensures EVP is brought to front(not passing "NoActive" option)

	; If the EVP GUI has been on screen, and user calls up Evp_LaunchUI(), and there is currently
	; no bitmap in the clipboard, our UI will keep *silent* (=not popping a msgbox saying clipboard is empty).
	; This decision matches such a usage scenario: 
	; * User ticks [Keep window], wanting to keep EVP GUI on the screen (perhaps on his secondary monitor);
	; * Then user picks "png (8 colors)" to paste into Evernote, leaving EVP GUI on screen;
	;   (Now, clipboard has CF_HTML, not a bitmap or bitmap-filepath.)
	; * After some Evernote editing, user calls up Evp_LaunchUI( AppsKey&c ), this time, he probably wants 
	;   to pick another image vairant to use, "jpg (60%)" for example. 
	; -- At this point, we'd better not telling the user "No bitmap in clipboard", instead we'd better 
	;    keep the EVP UI silent so the user can pick "jpg (60%") from last time.
	
	if(was_gui_visible)
	{
		hasbm := Evp_IsBitmapInClipboard(bitmap_filepath)
		if(!hasbm and !bitmap_filepath)
			return ; keep EVP UI silent
	}

	Evp_LaunchConvert_fromClipboard()
}

Evp_ShowGui()
{
	if(g_evpIsGuiVisible)
		return

	if(!g_HwndEVPGui) {
		
		Evp_CreateGui()
		
	} else {
;		MsgBox, % "Skip Evp_CreateGui()"
	}

	Evp_AutosizeNowUI() ; Gui, EVP:Show inside

	g_evpIsGuiVisible := true
	
	dev_OnMessageRegister(0x200, "Evp_WM_MOUSEMOVE")
	dev_OnMessageRegister(0x111, "Evp_WM_COMMAND")
	dev_OnMessageRegister(0x205, "Evp_WM_RBUTTONUP")

	g_evp_hClipmon := Clipmon_CreateMonitor(Func("Evp_ClipmonCallback"), "Evp_ShowGui")
	g_evp_ClipmonSeqNow := 0
	g_evp_ClipmonSeqAct := 0
	
	Evp_TimerOn()
}

Evp_CleanupUI() ; [2024-04-12] Better named (traditional) Evp_HideGui(), so it pairs with Evp_ShowGui()
{
	Evp_TimerOff()
	
	Clipmon_DeleteMonitor(g_evp_hClipmon)
	
	dev_OnMessageUnRegister(0x200, "Evp_WM_MOUSEMOVE")
	dev_OnMessageUnRegister(0x111, "Evp_WM_COMMAND")
	dev_OnMessageUnRegister(0x205, "Evp_WM_RBUTTONUP")
	
	Gui, EVP:Hide	; I will not do EVP:Destroy. If really want, just Reload the AHK script.
	g_evpIsGuiVisible := false
}

EVPGuiEscape(hwndGui)
{
;	dev_TooltipAutoClear("EVPGuiEscape() called")
	Evp_CleanupUI()
}

EVPGuiClose(hwndGui)
{
;	dev_TooltipAutoClear("EVPGuiClose() called")
	Evp_CleanupUI()
}



Evp_CreateGui()
{
	; Evp: short for "Everpic"
	; This UI will generate a series of image previews with different quality,
	; then user can pick the "best" one to use(paste it into Evernote).

	Gui, EVP:New ; Destroy old window if any
	Gui_AssociateHwndVarname("EVP", "g_HwndEVPGui") ; Gui hwnd generated in g_HwndEVPGui
	Gui_SetXYMargin("EVP", gc_evpMarginX, gc_evpMarginY)
	Gui_Switch_Font("EVP", 9, "Black", "Tahoma") ; Gui, EVP:Font, s9 cBlack, Tahoma

	fullwidth := Evp_CalCtrlFullWidth()
	
	; ==== Create Column1 controls. ====
	;
	col1w := gc_evpCol1Width
	Gui_Add_Button(  "EVP", "gu_evpBtnCvtFromClipbrd", col1w, "Section xm ym g" . "Evp_evtCvtFromClipboard" , gc_evpConvertBtnText)
	Gui_Add_Checkbox("EVP", "gu_evpCkbAutoConvert",    col1w, "xm+16 y+5 Hidden", "&Auto Convert")
	Gui_Add_Editbox( "EVP", "gu_evpEdrBaseImgFilepath", fullwidth, "xm y+34 Readonly -E0x200", "Base-image file path (to fill)")
	;
	lwScale := 42 ; label-width
	lwRefresh := 30
	Gui_Add_TxtLabel("EVP", "gu_evpTxtScale", lwScale, "xm+2 y+4", "&Scale:")
	Gui_Add_Combobox("EVP", "gu_evpCbxScalePct", col1w-lwScale-lwRefresh-gc_evpGapX
		, Format("x+{} yp-2 AltSubmit g{}", 0, "Evp_evtCbxScalepctChanged"))
	Gui_Add_Button(  "EVP", "gu_evpBtnCvtFromBaseImg", lwRefresh
		, Format("x+{} yp-1 g{}", gc_evpGapX, "Evp_evtCvtFromBaseImg"), "→") ; "↻" (the Refresh Unicode char) is rendered ugly, so use right-arrow instead
	;
	Gui_Add_Listbox( "EVP", "gu_evpLbxImages",   col1w, Format("xs r12 AltSubmit g{}", "Evp_RefreshImgpane"))
	Gui_Add_Editbox( "EVP", "gu_evpEdrLoadStat",  col1w, "Readonly -E0x200", "")

	; FootLine (The output filepath/[Copy] as in Explorer button)
	Gui_Add_Editbox( "EVP", "gu_evpEdrFootline", fullwidth-gc_evpIconBtnWidth, "xm Readonly", "...")
	Gui_Add_Button(  "EVP", "gu_evpBtnCopyFile", gc_evpIconBtnWidth, "x+2 g" . "Evp_CopyConvertedImageFileToClipboard", "")
	GuiButton_SetIconFromDll("EVP", "gu_evpBtnCopyFile", "shell32.dll", 243, 16, true) ; #243 is the [Copy] icon, 16 is icon size
	
	; OK button
	Gui_Add_Button(  "EVP", "gu_evpBtnOK", col1w, "default xm " gui_g("Evp_BtnOK"), "&Use This (or press Enter)")
	;
	; Two checkboxes beside BtnOK
	Gui_Add_Checkbox("EVP", "gu_evpCkbAutoPaste", -1, "x+5 yp+5 Checked", "Auto &paste") ; Auto paste
	Gui_Add_Checkbox("EVP", "gu_evpCkbKeepWindow",-1, "x+5 yp", "Keep &window") ; Keep window

	; ==== Create Column2 controls. ====
	;
	col2w := gc_evpImgpaneDefWidth
	Gui_Add_TxtLabel("EVP", "gu_evpTxtClipbState",  col2w, Format("xs+{} ys+5 section +0x8000", col1w+gc_evpGapX), "Clipboard state")
	;
	Gui_Add_Picture( "EVP", "gu_evpIcnWarnNoTranspixel", 16, "h16 hidden +0x100") ; 0x100: SS_NOTIFY, for hovering tooltip
		Gui_Picture_SetIconFromDll("EVP", "gu_evpIcnWarnNoTranspixel", "user32.dll", 2) ; 2: yellow exclamation triangle
	Gui_Add_Checkbox("EVP", "gu_evpCkbKeepPngTrans", -1, "x+4 yp+1 c666666 Hidden g" . "Evp_ToggleKeepPngTransparent"
		, "&Keep transparent pixels when converting png file.")
	;
	Gui_Add_Picture( "EVP", "gu_evpPicPreview",     col2w, "h" g_evpImgpaneHeight) 
	
	; The above GUI control layout will later be updated by Evp_SyncGuiByBaseImage()
	
	; Fill gu_evpCbxScalePct combobox
	for index,value in gar_evpScalePcts
	{
		if(index==1)
			jstr := value . "%|" ; extra "|" means default selection
		else
			jstr := jstr "|" value "%"
	}
	GuiControl_SetText("EVP", "gu_evpCbxScalePct", jstr)
	
	; Set default states of the controls:
	;
	evpdbg("UIC Disable: gu_evpBtnCvtFromClipbrd")
	GuiControl_Enable("EVP","gu_evpBtnCvtFromClipbrd", false) ; Not enabled until image in clipboard
	GuiControl_Enable("EVP","gu_evpBtnOK", false) ; Not enabled until image previews all generated
	;
	Evp_ShowAllControls(false)
	
	Gui_Show("EVP", "xCenter yCenter", Evp_WinTitle()) ; only center it when first created
	
	g_evpConvertStartCount := 0
	g_evpConvertSuccCount := 0	
}

Evp_ShowAllControls(is_show:=true)
{
	if(is_show==g_evpIsFullUIExpaned)
		return

	g_evpIsFullUIExpaned := is_show

	ctls := [ "gu_evpCkbAutoConvert"
		, "gu_evpTxtScale", "gu_evpCbxScalePct", "gu_evpBtnCvtFromBaseImg"
		, "gu_evpLbxImages", "gu_evpEdrLoadStat"
		, "gu_evpBtnOK", "gu_evpCkbAutoPaste", "gu_evpCkbKeepWindow"
		, "gu_evpEdrBaseImgFilepath"
;		, "gu_evpCkbKeepPngTrans"
		, "gu_evpPicPreview", "gu_evpEdrFootline", "gu_evpBtnCopyFile" ] 
	
	for index,value in ctls
	{
		GuiControl_Show("EVP", value, is_show)
	}
	
	Evp_AutosizeNowUI()
}

Evp_AutosizeNowUI()
{
	is_auto := GuiControl_GetValue("EVP", "gu_evpCkbAutoConvert")

	showopt := "AutoSize" . (is_auto ? " NoActivate" : "")

	Gui_Show("EVP", showopt, Evp_WinTitle())
}


Evp_CalCtrlFullWidth()
{
	; Calculate from g_evpImgpaneWidth
	;
	return gc_evpCol1Width + gc_evpGapX + g_evpImgpaneWidth
}

Evp_CalGuiFullWidth()
{
	return 2 * gc_evpMarginX + Evp_CalCtrlFullWidth()
}

Evp_GenImageSigByTimestamp()
{
	; Example: everpic-20221205_150413
	
	FormatTime, dt, , % "yyyyMMdd_HHmmss"
	return "everpic-" dt
}

Evp_BaseImageFilepathPrefix(imgsig)
{
	return Format("{}\{}", Everpic.dirTempImg, imgsig)
}

Evp_ScaleDownImage(scale_pct, srcimgpath, dstimgpath, isKeepPngTransparent)
{
	; 2022.12.09 https://www.autohotkey.com/board/topic/52033-convertresize-image-with-gdip-solved/

	If !pToken := Gdip_Startup()
		return false

	is_succ := false

	sBitmap := Gdip_CreateBitmapFromFile(srcimgpath)
	if(sBitmap<=0)
		goto Evp_ScaleDownImage_END
	
	sWidth  := Gdip_GetImageWidth(sBitmap)
	sHeight := Gdip_GetImageHeight(sBitmap)
	
	dWidth  := sWidth  * scale_pct // 100
	dHeight := sHeight * scale_pct // 100

	dBitmap := Gdip_CreateBitmap(dWidth, dHeight)
	G := Gdip_GraphicsFromImage(dBitmap)
	
	if(!isKeepPngTransparent)
	{
		; If not isKeepPngTransparent, we set white background for it.
;pBrush2 := Gdip_BrushCreateSolid(0x80FF2000)
	
		pBrushClear := Gdip_BrushCreateSolid(0xFFffffff) 
		; -- Fill ARGB(255,255,255,255), alpha-value=255 is required.
		;    Otherwise, the default ARGB is (0,0,0,0), which will result in black bg onto jpg.
		Gdip_FillRectangle(G, pBrushClear, 0, 0, dWidth, dHeight)
;Gdip_FillRectangle(G, pBrush2, 0, 0, dWidth, dHeight)

		Gdip_DeleteBrush(pBrushClear)
;Gdip_DeleteBrush(pBrush2)
	}
	
	
	Gdip_DrawImage(G, sBitmap, 0, 0, dWidth, dHeight, 0, 0, sWidth, sHeight)
	
	err := Gdip_SaveBitmapToFile(dBitmap, dstimgpath)
	if(err)
		goto Evp_ScaleDownImage_END
		
	is_succ := true

Evp_ScaleDownImage_END:
	Gdip_DisposeImage(sBitmap)
	Gdip_DisposeImage(dBitmap)
	Gdip_DeleteGraphics(G)
	Gdip_Shutdown(pToken)
	
	return is_succ
}


Evp_evtCvtFromClipboard(CtrlHwnd, GuiEvent, EventInfo, ErrLevel:="")
{
	evpdbg(Format("In Evp_evtCvtFromClipboard().")) ; debug

	Evp_LaunchConvert_fromClipboard()
}

Evp_evtCvtFromBaseImg(CtrlHwnd, GuiEvent, EventInfo, ErrLevel:="")
{
	dev_assert(g_evpBaseImageFilepath_100pct)

	Evp_LaunchConvert_fromBaseImage(g_evpBaseImageFilepath_100pct)
}

Evp_GetUIScalePct()
{
	GuiControl_ChangeOpt("EVP", "gu_evpCbxScalePct", "-AltSubmit")
	text := GuiControl_GetText("EVP", "gu_evpCbxScalePct")
	GuiControl_ChangeOpt("EVP", "gu_evpCbxScalePct", "+AltSubmit")
	
	scale_pct := dev_str2num(text)
	return scale_pct
}

Evp_ToggleKeepPngTransparent()
{
	is_checked := GuiControl_GetValue("EVP", "gu_evpCkbKeepPngTrans")
	g_isKeepPngTransparent := is_checked ? true : false
}

Evp_CheckAndWarnConvertBusy()
{
	if(g_evpTimerStage!="Monitoring") 
	{
		is_yes := dev_MsgBoxYesNo("Previous converting is in progress. Really cancel?")
		
		if(g_evpTimerStage=="Monitoring")
		{
			; During above dialog displaying period, the conversion have been completed.
			return true ; true means "was busy"
		}

		if(is_yes)
		{
			g_evpIsCancelling := true
			
			GuiControl_Enable("EVP", "gu_evpBtnCvtFromClipbrd", false)
			; -- so to avoid "repetitive" user-cancel.
	
			is_succ := dev_KillProcessByPid(g_evpBgCvtProcessId, winerr)
			if(!is_succ)
			{
				dev_MsgBoxWarning(Format("dev_KillProcessByPid(pid={}) fails with winerr={}", g_evpBgCvtProcessId, winerr))
			}
		}
		
		return true ; true means "was busy"
	}
	else
		return false
}

Evp_LaunchConvert_fromClipboard()
{
;	evpdbg("In Evp_LaunchConvert_fromClipboard().")

	Gui_ChangeOpt(  "EVP", "+OwnDialogs")

	if(Evp_CheckAndWarnConvertBusy())
		return ""

	; make it show blank
	GuiControl_Show("EVP", "gu_evpIcnWarnNoTranspixel", false)
	; -- Memo: Using 
	;		GuiControl_SetText("EVP", "gu_evpIcnWarnNoTranspixel" , "") 
	; is problematic, bcz it will make the control-window become 0-width,
	; so when we next do Gui_Picture_SetIconFromDll(), its width *changes* to 
	; icon's actual width(no longer 16).
	
	g_evpCurPngHasTranspx := false
	
	Evp_LaunchBatchConvert()
}

Evp_LaunchConvert_fromBaseImage(fpBaseImage)
{
	Gui_ChangeOpt(  "EVP", "+OwnDialogs")

	if(Evp_CheckAndWarnConvertBusy())
		return ""

	Evp_LaunchBatchConvert(fpBaseImage)
}

Evp_LaunchConvertResetUI()
{
	g_evpConvertStartCount++

	; Clear listbox
	hwndListbox := GuiControl_GetHwnd("EVP", "gu_evpLbxImages")
	dev_assert(hwndListbox)
	dev_Listbox_Clear(hwndListbox)

	GuiControl_Enable("EVP", "gu_evpLbxImages", true)
}

Evp_LaunchBatchConvert(fpFromImage:="", scale_pct:=0)
{
	; Return BaseImage filepath, empty string if launching fail.
	
	if(scale_pct==0) {
		scale_pct := Evp_GetUIScalePct()
	}

	if(scale_pct<=1 || scale_pct>100) {
		dev_MsgBoxError("Bad Scale percent value(should be 2 ~ 100): " scale_pct)
		return ""
	}
	
	if(Evp_CheckAndWarnConvertBusy())
		return ""

	evpdbg(Format("In Evp_LaunchBatchConvert(). `r`n"
		. "    fpFromImage = {}`r`n"
		. "    scale_pct = {}"
		, fpFromImage, scale_pct))
	
	g_evp_ClipmonSeqAct := g_evp_ClipmonSeqNow ; even if fpimg100pct fails

	imgsig := Evp_GenImageSigByTimestamp()

	fpimg100pct := Evp_GenerateBaseImage(fpFromImage, scale_pct, imgsig, g_isKeepPngTransparent
		, imgw, imgh, fpimgScaled) ; these three are output-vars
		; -- filepath of the base-image, example:
		; C:\Users\win7evn\AppData\Local\Temp\Everpic\everpic-20221204_150000.png

	if(!fpimg100pct)
		return "" ; Error should have been pop-up-ed in Evp_GenerateBaseImage()

	Evp_LaunchConvertResetUI()

	dev_assert(FileExist(fpimgScaled))

	; Note: fpimgScaled has wide meaning including 100% or less-than-100% scaling.
	; We will pass this fpimgScaled image to .bat .
		
	fpImageStem := dev_SplitExtname(fpimgScaled)
		
	fpImageList := fpImageStem . gc_evpFileSuffix_imagelist
	
	stageline_png32b := Format("PNG (32-bit)*{}`r`n", fpimgScaled)

	FileDelete, % fpImageList
	FileAppend, % stageline_png32b, % fpImageList

	fpbat := gc_evpBatchConvertExecpath
	fpbatlog := fpbat ".log"
	
	stdout_to_log := Format("1>""{}"" 2>&1", fpbatlog)
	batchcmd := Format("cmd /c @""{}"" ""{}"" {}"
		, fpbat
		, fpimgScaled
		, g_evpDbgCfg.showbgcmd ? "" : stdout_to_log)

	; We use `Run`, not `RunWait`, to avoid blocking ourselves. 
	; `Run` reports success as long as CreateProcess() succeeds. That means,
	; only when the target exe/bat(cmd.exe in this case) does not exists will we get ErrorLevel.
	; In turn, for `cmd /c foo.bat`, even if foo.bat does not exist, `Run` still report success.
	;
	; So, we'd better explictly check for .bat existence here.
	;
	if(!FileExist(fpbat))
	{
		dev_MsgBoxError(Format("Everpic missing required file: ""{}""", fpbat))
		return false
	}
	;
	opt_hidewindow := g_evpDbgCfg.showbgcmd ? "" : "Hide"
	dev_SetEnvVar("EverpicSimulateSlowCmd", g_evpDbgCfg.slowbgcmd>0 ? g_evpDbgCfg.slowbgcmd : "") ; .bat code will check this env-var
	;
	Run, % batchcmd, , UseErrorLevel %opt_hidewindow%, g_evpBgCvtProcessId
	if(ErrorLevel)
	{	; Not likely to get this.
		dev_MsgBoxError(Format("{} launch error.`n`nSee log file for reason:`n`n{}", fpbat, fpbatlog))
		return false
	}
	
	evpdbg("Everpic has launched bg-process with pid=" g_evpBgCvtProcessId)
	
	g_evpImageSig := imgsig
	g_evpBaseImageFilepath_100pct := fpimg100pct
;	g_evpBaseImageFilepath_scaled := fpimgScaled
	g_evpCurrentScalePct := scale_pct
	g_evpImageWidth  := imgw
	g_evpImageHeight := imgh
	g_evpImglistTxtPath := fpImageList
	
	g_evpBatchProgressFilepath := fpImageStem . gc_evpFileSuffix_progressdone
	if(FileExist(g_evpBatchProgressFilepath))
		FileDelete, % g_evpBatchProgressFilepath
	
	g_evpTimerStage := "ConvertStarting"
	g_evpTickConvertStart := A_TickCount

	evpdbg("UIC Enable: gu_evpBtnCvtFromClipbrd")
	GuiControl_Enable ("EVP", "gu_evpBtnCvtFromClipbrd", true)
	GuiControl_SetText("EVP", "gu_evpBtnCvtFromClipbrd", "Cancel converting")
	
	GuiControl_SetText("EVP", "gu_evpTxtClipbState", "Convert starting...")
	
	Evp_SyncGuiByBaseImage(fpimgScaled, imgw*scale_pct//100, imgh*scale_pct//100)
	
	Evp_ShowAllControls(true)
	
	if(g_evpConvertStartCount==1)
	{	; Center the UI only at the first run.
		Gui_Show("EVP", "xCenter yCenter", Evp_WinTitle())
	}
	
	return true
}

Evp_GenerateBaseImage(fpFromImage, scale_pct, imgsig, is_keeppngtrans
	, byref imgw, byref imgh, byref ofpScaled)
{
	; If fpFromImage is empty, generate the base .png image from clipboard.
	; Else, fpFromImage is the existing image file to use.
	; Return that 100pct .png filepath, empty string if fail.
	;
	; Return in `ofpScaled` the scaled 32-bit png filepath. 'o' implied output var.
	;
	; Memo: Whether scale_pct is 100, we always generate 100pct image, so that when 
	; user changes scale,we can use that 100pct image instead of re-generate from clipboard.
	;
	; This function does NOT change global vars.
	
	ofpprefix := Evp_BaseImageFilepathPrefix(imgsig)
	ptp_suffix := "-ptp"
	fp_100pctimg := ofpprefix . (is_keeppngtrans ? ptp_suffix  : "") ".png"
	fp_scaledimg := dev_AppendToStemname(fp_100pctimg, "-s" scale_pct)  ;fp_scaledimg := Format("{}-z{}.png", ofpprefix, scale_pct)

	ofpScaled := scale_pct==100 ? fp_100pctimg : fp_scaledimg

	if(FileExist(fp_100pctimg) && FileExist(ofpScaled))
	{
		dev_TooltipAutoClear("BaseImage already exists: " ofpScaled)
		return fp_100pctimg
	}

	is_100pct_succ := false ; assume fail
	
	if(!FileExist(fp_100pctimg))
	{
		If !pToken := Gdip_Startup()
		{
			dev_MsgBoxError("Gdip_Startup() failed. GDI+ problem!")
			return ""
		}

		Evp_IsBitmapInClipboard(bitmap_filepath)
		
		if(!fpFromImage && bitmap_filepath)
			fpFromImage := bitmap_filepath

		if(fpFromImage)
		{
			if(!FileExist(fpFromImage))	{
				dev_MsgBoxError("Image file does not exist:`n`n" fpFromImage)
				goto EVP_CLEANUP_20221204
			}
			
			; fpFromImage can be any format(bmp, jpg, gif, png etc)
			; We need to first save it as 32-bit png, via Gdip libray.

			bitmap := Gdip_CreateBitmapFromFile(fpFromImage)
			if(bitmap<=0) {
				dev_MsgBoxError(Format("Gdip_CreateBitmapFromFile(""{}"") fail, errcode={}.", fp_100pctimg, bitmap))
				goto EVP_CLEANUP_20221204
			}

			Gdip_GetImageDimensions(bitmap, imgw, imgh)

			dev_assert(StrIsEndsWith(fp_100pctimg, ".png", true))
			
			if(is_keeppngtrans)
			{
				err := Gdip_SaveBitmapToFile(bitmap, fp_100pctimg) ; this does not destroy png transparent pixels.
				if(err) {
					dev_MsgBoxError(Format("Gdip_SaveBitmapToFile(""{}"") fail, errcode={}.", fp_100pctimg, err))
					goto EVP_CLEANUP_20221204
				}
			}
			else 
			{
				; Inside Evp_ScaleDownImage, we call Gdip_DrawImage(), which will remove all png transparent pixels.
				; so fp_100pctimg will be non-transparent.
				succ := Evp_ScaleDownImage(100, fpFromImage, fp_100pctimg, !gc_KeepPngTransparent)
				if(!succ) {
					goto EVP_CLEANUP_20221204 ; error reported in Evp_ScaleDownImage()
				}
			}
			
			is_100pct_succ := true
		}
		else ; will get CF_BITMAP from Clipboard
		{
			bitmap := Gdip_CreateBitmapFromClipboard()
			if(bitmap<=0)
			{
				if(g_evpConvertStartCount>0)
				{
					dev_MsgBoxWarning("No bitmap in clipboard yet. Nothing to convert by Everpic.")
				}
				goto EVP_CLEANUP_20221204
			}

			Gdip_GetImageDimensions(bitmap, imgw, imgh)
			
			err := Gdip_SaveBitmapToFile(bitmap, fp_100pctimg)
			if(err) {
				dev_MsgBoxError(Format("Gdip_SaveBitmapToFile(""{}"") fail, errcode={}.", fp_100pctimg, err))
				goto EVP_CLEANUP_20221204
			}
			
			is_100pct_succ := true
		}

	EVP_CLEANUP_20221204:
	
		Gdip_DisposeImage(bitmap)
		Gdip_Shutdown(pToken)
		
	} ; if(!FileExist(fp_100pctimg))

	is_succ := false ; Re-assume faile
	
	;;; Do scale_pct if required to
	;
	if(is_100pct_succ)
	{
		if(scale_pct!=100 && !FileExist(fp_scaledimg))
		{
			succ := Evp_ScaleDownImage(scale_pct, fp_100pctimg, fp_scaledimg, is_keeppngtrans)
			if(!succ)
				return "" ; Error should have been reported inside Evp_ScaleDownImage()
		}

		is_succ := true
	}
	
	;;; Launch timer to check for png-transparent.
	; This checking is very slow, and we do NOT want to block here, so use a timer.
	;
	if(is_succ && StrIsEndsWith(fpFromImage, ".png", true) && is_keeppngtrans)
	{
		fn := Func("Evp_TimerProcCheckPngfileTranspixel").Bind(fpFromImage, g_evpConvertStartCount)
		SetTimer, % fn, -99 ; one-time timer, start after(99 ms)
	}
	
	return is_succ ?  fp_100pctimg : ""
}


Evp_WM_MOUSEMOVE(wParam, lParam, msg, hwnd)
{
	if(A_Now >= g_evpSuppressUicTooltipBfrThis)
	{
		evp_ShowUicTooltips(wParam, lParam, msg, hwnd)
	}
}

evp_ShowUicTooltips(wParam, lParam, msg, hwnd)
{
	static s_prev_tooltiping_uic := 0

	is_from_tooltiping_uic := true ; assume message is from a GuiControl

	if(A_GuiControl=="gu_evpCkbAutoPaste")
	{
		dev_TooltipAutoClear("If ticked, ""Use this"" button will paste the selected image into where you have come from(e.g. Evernote window).`r`n"
			. "If not ticked, you have to strike Ctrl+V to paste into your target application.")
	}
	else if(A_GuiControl=="gu_evpCkbKeepWindow")
	{
		dev_TooltipAutoClear("If ticked, after clicking ""Use this"" button, this Everpic window will remain visible instead of close itself.")
	}
	else if(A_GuiControl=="gu_evpCkbAutoConvert")
	{
		dev_TooltipAutoClear("Auto convert when new content in clipboard is detected.")
	}
	else if(A_GuiControl=="gu_evpBtnCvtFromBaseImg")
	{
		dev_TooltipAutoClear("Convert from current Base-image using new Scale value.")
	}
	else if(A_GuiControl=="gu_evpCkbKeepPngTrans")
	{
		dev_TooltipAutoClear("If ticked, an input png file's transparent pixels remains transparent in output pngs.`n"
			. "If not ticked, input transparent pixels becomes white pixels in output pngs.`n`n"
			. "This takes effect next time you Convert from Clipboard.")
	}
	else if(A_GuiControl=="gu_evpIcnWarnNoTranspixel")
	{
		dev_TooltipAutoClear("This input png file does NOT seem to have transparent pixels.")
	}
	else if(A_GuiControl=="gu_evpBtnCopyFile")
	{
		dev_TooltipAutoClear("Copy this file to Clipboard, so that you can paste the file to another folder.")
	}
	else
		is_from_tooltiping_uic := false
	
	if(A_Gui=="EVP")
	{
		; If mouse has *just* moved off a tooltiping UIC, we turn off the tooltip.
		; But,
		; we cannot blindly turn off tooltip here, bcz we would get constant WM_MOUSEMOVE 
		; even if we do not move the mouse; turning off tooltip blindly would cause 
		; other function's dev_TooltipAutoClear() to vanish immediately.
		;
		if(is_from_tooltiping_uic)
			s_prev_tooltiping_uic := A_GuiControl
		else if(s_prev_tooltiping_uic) {
			tooltip ; turn off tooltip
			s_prev_tooltiping_uic := 0
		}

;		xmouse := lParam & 0xFFFF , ymouse := (lParam >> 16) & 0xFFFF 
;		Dbgwin_Output(Format("In Evp_WM_MOUSEMOVE(), A_Gui==EVP, A_GuiControl={}, xmouse={}, ymouse={}. (sPrev={})"
;			, A_GuiControl, xmouse, ymouse, s_prev_tooltiping_uic))
	}
}

Evp_WM_COMMAND(wParam, lParam, msg, hwnd)
{
	hctrl := lParam
	notify_code := wParam >> 16

;	Dbgwin_Output(Format("Evp_WM_COMMAND: hwndctrl=0x{:08X} , notify_code={}", hctrl, notify_code)) ; debug
	; -- Yes, we will see lots of WM_COMMAND activity.

;	if(hctrl==g_evtblHwndComboColor && notify_code==4) ; CBN_KILLFOCUS=4
;	{
;	    Evtbl_ColorComboSetColorDualFormat()
;	}   
}

Evp_WM_RBUTTONUP(wParam, lParam, msg, hwnd)
{
	menuname := "Everpic Right-click Menu object"
	
	Evp_CreateContextMenu(menuname)
	dev_MenuShow(menuname)
}

Evp_CopyConvertedImageFileToClipboard()
{
	select_filepath := GuiControl_GetText("EVP", "gu_evpEdrFootline")
	
	Clipboard := ""
	WinClip.SetFiles(select_filepath)
	if(Clipboard==select_filepath)
	{
		g_evpSuppressUicTooltipBfrThis := dev_YMDHMS_AddSeconds(A_Now, 2)
		; -- increase g_evpSuppressUicTooltipBfrThis so that the button's stock(static) 
		; tooltip is temporarily turned off, otherwise, we would not be able to see the 
		; following new tooltip
		
		dev_TooltipAutoClear("File copied to Clipboard.")
	}
	else
	{
		dev_MsgBoxWarning("Unexpect! Copy file to Clipboard failed.")
	}
}

Evp_CreateContextMenu(menuname)
{
	menuitem := "Show Debug info"
	fnobj := Func("Evp_ToggleOnOff").Bind("g_evpDbgCfg", "showdbginfo")
	dev_MenuAddItem(menuname, menuitem, fnobj)
	dev_MenuTickItem(menuname, menuitem, g_evpDbgCfg.showdbginfo ? true : false)

	menuitem := "Show TempDir cleanup debug info"
	fnobj := Func("Evp_ToggleOnOff").Bind("g_evpDbgCfg", "showdbgcleanup")
	dev_MenuAddItem(menuname, menuitem, fnobj)
	dev_MenuTickItem(menuname, menuitem, g_evpDbgCfg.showdbgcleanup ? true : false)

	menuitem := "Show background converting CMD window"
	fnobj := Func("Evp_ToggleOnOff").Bind("g_evpDbgCfg", "showbgcmd")
	dev_MenuAddItem(menuname, menuitem, fnobj)
	dev_MenuTickItem(menuname, menuitem, g_evpDbgCfg.showbgcmd ? true : false)

	menuitem := "Simulate slow background converting"
	fnobj := Func("Evp_ToggleOnOff").Bind("g_evpDbgCfg", "slowbgcmd")
	dev_MenuAddItem(menuname, menuitem, fnobj)
	dev_MenuTickItem(menuname, menuitem, g_evpDbgCfg.slowbgcmd ? true : false)
}

Evp_ToggleOnOff(sobj, smember)
{
	; sobj and smember are both in string.

	obj := %sobj%
	obj[smember] := not obj[smember]
}

Evp_TimerOn()
{
	SetTimer, Evp_TimerProc, 500
}

Evp_TimerOff()
{
	SetTimer, Evp_TimerProc, Off
}

Evp_TimerProc()
{
	Gui_ChangeOpt(  "EVP", "+OwnDialogs")

	if(g_evpTimerStage=="Monitoring")
	{
		Evp_CheckClipboardStateUpdateUI()
		
		; ==== Check whether do Auto-convert. ====
		
		is_auto := GuiControl_GetValue("EVP", "gu_evpCkbAutoConvert")

		isnewclip := g_evp_ClipmonSeqNow > g_evp_ClipmonSeqAct ? true : false
		
		if(is_auto && isnewclip)
		{
			hasbm := Evp_IsBitmapInClipboard(bitmap_filepath)

			if(hasbm || bitmap_filepath)
			{
;				Dbgwin_Output(Format("Auto-convert again, act={} seq={} ...", g_evp_ClipmonSeqAct, g_evp_ClipmonSeqNow)) ; debug
				Evp_LaunchBatchConvert()
			}
		}
	}
	else if(g_evpTimerStage=="ConvertStarting" || g_evpTimerStage=="ConvertStarted")
	{
		Evp_CheckConvertingProgressUpdateUI()
	}
	else 
	{
		dev_MsgBoxError("Bad value of g_evpTimerStage: " g_evpTimerStage)
		dev_assert(("Bad value of g_evpTimerStage") ?0:0)
	}
	
	Evp_CleanupTempDir_withInterval()
	
}

Evp_ClipmonCallback()
{
	g_evp_ClipmonSeqNow++
}

Evp_IsImagefileSuffix(filepath)
{
	arsuffix := ["bmp", "png", "jpg", "gif"]

	if(StrLen(filepath)<8)
		return ""
   	
   	if(SubStr(filepath, 2, 1)!=":")
   		return "" ; No drive letter prefix
	
	for index,extname in arsuffix
    {
    	if(StrIsEndsWith(filepath, "." extname, true))
    		return extname
    }
    return ""
}


Evp_IsBitmapInClipboard(byref filepath_bitmap)
{
	; Two output values:
	; Return value: whether CF_BITMAP in clipboard.
	; [out] filepath_bitmap: will be a image filepath if there is one in clipboard text.
	
	filepath_bitmap := ""
	if( WinClipAPI.IsClipboardFormatAvailable(gc_evp_CF_BITMAP) )
	{
		return true
	}
	else
	{
		filepath := Clipboard ; assume filepath and check
		if(filepath && StrLen(filepath)<260 && Evp_IsImagefileSuffix(filepath))
		{
			filepath_bitmap := filepath
		}
		return false
	}
}

gdip_BitmapFindTransparentPixel(bitmap, xstart, ystart, xend_, yend_, xskip, yskip, msec_limit)
{
	; x/y param is 0-based, Gdip-style.
	; return an object(.is_found .x .y) telling the position of the first-found transparent pixel
	
	msec_start := A_TickCount
	
	y := ystart
	Loop ; y-loop
	{
		x := xstart
		Loop ; x-loop 
		{
			
			ARGB := Gdip_GetPixel(bitmap, x, y) ; Gdip
			if( (ARGB & 0xFF000000) != 0xFF000000 ) 
				return {"is_found":true, "x":x , "y":y}
			
			x += xskip
			if(x>=xend_)
				break
		}
		
		y += yskip
		if(y>=yend_)
			break
	
		if(A_TickCount-msec_start >= msec_limit)
			break
	}
	
	return {"is_found":false, "x":0, "y":y} ; y tells "next"-y to continue search
}

Evp_HasTransparentPixel(fpimg)
{
	; Baffle: This function runs very slow, but I don't know why.
	; Weird: The CPU usage during the run is far less from a whole core.
	; Due to its slowness, I have to limit the time-cost, so not every pixel is checked.
	scan1_msec_limit := 500
	scan2_msec_limit := 300

	If !pToken := Gdip_Startup()
	{
		dev_MsgBoxWarning("Evp_HasTransparentPixel(): Gdip_Startup FAIL.")
		return false
	}

	bitmap := Gdip_CreateBitmapFromFile(fpimg)
	if(bitmap<=0) {
		dev_MsgBoxError(Format("Gdip_CreateBitmapFromFile(""{}"") fail, errcode={}.", fpimg, bitmap))
		return false
	}

	imgw := 0 , imgh := 0
	Gdip_GetImageDimensions(bitmap, imgw, imgh)
	if(imgw==0 || imgh==0)
		dev_MsgBoxError("In Evp_HasTransparentPixel(), Gdip_GetImageDimensions() fails!")

	skip := 2
	scan_result := gdip_BitmapFindTransparentPixel(bitmap, 0,0, imgw, imgh, skip, skip, scan1_msec_limit)

	if(scan_result.is_found==false and scan_result.y<imgh)
	{
		dev_assert(scan_result.y>0)
		
;		if(scan_result.y>=imgh) { ; test
;			dev_assert(scan_result.y<imgh)
;		}
		
;		dev_TooltipAutoClear("Phase-two scan from image-y (0-based): " scan_result.y, 5000) ; debug
		
		; Now we search "image left-side"(100-pixel column)
		scan_width := 100
		scan_result := gdip_BitmapFindTransparentPixel(bitmap
			, 0,           scan_result.y
			, scan_width,  imgh
			, skip,        skip
			, scan2_msec_limit)
	}
	
	Gdip_DisposeImage(bitmap)
	Gdip_Shutdown(pToken)

	if(scan_result.is_found)
	{
;		Dbgwin_Output(Format("{}: transpx at {},{}", fpimg, scan_result.x, scan_result.y)) ; debug
	}

	return scan_result.is_found
}

Evp_TimerProcCheckPngfileTranspixel(pngfilepath, from_startcount)
{
	if(from_startcount!=g_evpConvertStartCount)
	{
		; We have been lagged, input pngfilepath no longer match "latest", so nothing to do here.
;		Dbgwin_Output(Format("### from_startcount={} , g_evpConvertStartCount={}", from_startcount, g_evpConvertStartCount)) ; debug
		return
	}

	Gui_ChangeOpt(  "EVP", "+OwnDialogs")

;	Dbgwin_Output("Evp_TimerProcCheckPngfileTranspixel(), " pngfilepath) ; debug
	
	hastranspx := Evp_HasTransparentPixel(pngfilepath)

;	Dbgwin_Output("Evp_TimerProcCheckPngfileTranspixel() = " (hastranspx?"Yes":"No")) ; debug
	
	; show warning icon if not hastranspx.
	GuiControl_Show("EVP", "gu_evpIcnWarnNoTranspixel", !hastranspx?true:false)
	
	if(hastranspx)
		g_evpCurPngHasTranspx := true
}


Evp_CheckClipboardStateUpdateUI()
{
	hint := ""
	is_pngpath := false
	
	if( Evp_IsBitmapInClipboard(bitmap_filepath) )
	{
		hint := "Bitmap in Clipboard. You can now [Convert from Clipboard]."
	}
	else if(bitmap_filepath)
	{
		hint := "Clipboard has filepath: " bitmap_filepath
		
		if(StrIsEndsWith(bitmap_filepath, ".png", true))
			is_pngpath := true
	}

	if(hint)
	{
		GuiControl_Enable("EVP","gu_evpBtnCvtFromClipbrd", true)
		fgcolor := "8888cc"
;		Evp_ShowAllControls(true) ; not so fast
	}
	else 
	{
		GuiControl_Enable("EVP","gu_evpBtnCvtFromClipbrd", false)
		hint := "Copy an image, or a filepath into system Clipboard so to convert it."
		fgcolor := "CC8888"
	}
	
	GuiControl_SetColor("EVP", "gu_evpTxtClipbState", fgcolor)
	GuiControl_SetText( "EVP", "gu_evpTxtClipbState", hint)
	
	uivis_pngtrans := (is_pngpath && g_evpIsFullUIExpaned) ? true : false
	GuiControl_Show("EVP", "gu_evpCkbKeepPngTrans", uivis_pngtrans)
	
	if(not uivis_pngtrans)
		GuiControl_Show("EVP", "gu_evpIcnWarnNoTranspixel", false)
}

Evp_CheckConvertingProgressUpdateUI()
{
	fpProgress := g_evpBatchProgressFilepath ; was set in Evp_LaunchBatchConvert()
	; 	C:\Users\win7evn\AppData\Local\Temp\Everpic\everpic-20221204_165806.progress.done.txt
	dev_assert(fpProgress) 

	progtext := dev_FileReadLine(fpProgress, 1)
	
	if(g_evpTimerStage=="ConvertStarting"
		&& A_TickCount-g_evpTickConvertStart > gc_evpStartingTimeoutSec*1000)
	{
		is_yes := dev_MsgBoxYesNo(Format("Unexpect! Background conversion process fails to start in {} seconds.`r`n`r`n"
			. "Do you want to cancel conversion now?", gc_evpStartingTimeoutSec)
			, true, Amhk.mbopt_IconExclamation)
		if(is_yes)
		{
			dev_assert(g_evpBgCvtProcessId)
			dev_KillProcessByPid(g_evpBgCvtProcessId)
			
			Evp_BatchConvertDone(false)
		}
	}

	if(!progtext)
	{
		; Possible situation: Above dev_FileReadLine() failed, due to file being written(file locked)
		; by background converting process. So we just neglect this case, and retry on next timer tick.
		return
	}
	

	if(g_evpTimerStage=="ConvertStarting")
	{
		; Check file content of fpProgress to see whether it has "0/9", "0/10" etc. 
		; If so, we move to next timer-stage; If not after some timeout, we claim it error.

		if(progtext ~= "^[0-9]+/[0-9]+$")
		{
			g_evpTimerStage := "ConvertStarted"
			
			GuiControl_SetText("EVP", "gu_evpTxtClipbState", "Converting " progtext " ...")
		}
	}
	
	; Check file content in fpProgress to see whether the background
	; image-list generation has completed. Sample file:
	; 	C:\Users\win7evn\AppData\Local\Temp\Everpic\everpic-20221204_165806.progress.done.txt
	; File content, just one line, can be:
	; 1/9
	; 2/9
	; ...
	; 9/9
	;
	; If 9/9 is reached, it means completed.

	nums := StrSplit(progtext, "/")
	nDone := nums[1]
	nTotal := nums[2]

	if(!nTotal)
	{
		dev_MsgBoxError(Format("Bad content in progress file: {}`r`n`r`n{}", fpProgress, progtext)
			, "Something Wrong!")
		Evp_BatchConvertDone(false)
		return
	}
	
	msecs := A_TickCount - g_evpTickConvertStart
	
	if(nDone<nTotal)
	{
		GuiControl_SetText("EVP", "gu_evpBtnCvtFromClipbrd", Format("Cancel converting (+{}s)", msecs//1000))
	
		GuiControl_SetText("EVP", "gu_evpTxtClipbState"
			, Format("Converting {}/{} ...", nDone, nTotal))
	}
	else if(nDone==nTotal)
	{
		; All (background) image conversion done successfully.

		zoomhint := ""
		if(g_evpImageZoom!=1)
			zoomhint := Format("({}% zoom)",floor(g_evpImageZoom*100)) ; note Zoom-pct is not Scale-pct
		
		GuiControl_SetText("EVP", "gu_evpEdrLoadStat"
			, Format("{}*{} , {}.{:03}s {}"
				, Evp_ImgScaledWidth(), Evp_ImgScaledHeight()
				, floor(msecs/1000), Mod(msecs,1000)
				, zoomhint))
		
		Evp_RefreshPreviewAllGui()
		
		Evp_BatchConvertDone(true)
		
		return
	}
	
	; Note: We have to check process-alive AFTER `if(nDone==nTotal)`, bcz `nDone==nTotal` signify success.
	;
	if(!dev_IsProcessAlive(g_evpBgCvtProcessId))
	{
		if(!g_evpIsCancelling)
		{
			dev_MsgBoxError(Format("Unexpect! Background process has terminated, but image conversion is not finished.`r`n`r`n"
				. "Error reason may be revealed from everpic-batch-prepare.bat.log ."))
		}
		
		Evp_BatchConvertDone(false)
	}
}

Evp_ImgScaledWidth()
{
	return g_evpImageWidth*g_evpCurrentScalePct//100
}

Evp_ImgScaledHeight()
{
	return g_evpImageHeight * g_evpCurrentScalePct // 100
}

Evp_BatchConvertDone(is_succ)
{
	; Set some shared-status after convert is done.
	
	evpdbg("Evp_BatchConvertDone(), " (is_succ ? "success." : "fail!"))

	dev_assert(g_evpBgCvtProcessId!=0)
	dev_WaitUntilProcessExit(g_evpBgCvtProcessId)
	; -- This is important, bcz everpic-batch-prepare.bat process's exist ensures that 
	;    everpic-batch-prepare.bat.log' file handle is closed by CMD shell's '>' operator,
	;    so that the next run of everpic-batch-prepare.bat can be sure to success.
	g_evpBgCvtProcessId := 0

	g_evpTimerStage := "Monitoring"
	g_evpTickConvertStart := 0
	g_evpIsCancelling := false

	GuiControl_Enable ("EVP", "gu_evpBtnCvtFromClipbrd", true)
	GuiControl_SetText("EVP", "gu_evpBtnCvtFromClipbrd", gc_evpConvertBtnText)

	if(is_succ)
	{
		g_evpConvertSuccCount++

		GuiControl_SetText("EVP", "gu_evpEdrBaseImgFilepath", "Base-image: " g_evpBaseImageFilepath_100pct)

		Evp_RefreshImgpane()
	}
}

Evp_SyncGuiByBaseImage(imgfilepath, imgw_scaled, imgh_scaled)
{
	; This function adjusts(Increase or decrease)  EVP GUI's window size 
	; so that the image can be display at 100% Zoom level. 
	; But if the image is larger than monitor area, I have to shrink it. 
	;
	; imgfilepath can be empty, this will change the UI to its default(blank) size.
	;
	; This function changes global vars: g_evpImgpaneWidth, g_evpImgpaneWidth
	
	
	; //// Set new content into controls according to imgfilepath ////
	
	if(imgfilepath)
	{
		wa := GetMonitorWorkArea(1)
		
		max_gui_width := wa.width - 2*g_evpWindowBorder
		
		imgw_gui_units := imgw_scaled / Get_DPIScale()
		imgh_gui_units := imgh_scaled / Get_DPIScale()
			; For example, on an 120-dpi monitor setting Windows(125% scale), for a 125-pixel width image,
			; you need to only pass w100 for the picture control to show it perfectly.
		
		stock_width := 2*gc_evpMarginX + gc_evpCol1Width + gc_evpGapX
		gui_wreq := stock_width + imgw_gui_units
		if(gui_wreq > max_gui_width)
			gui_wreq := max_gui_width ; not execeed primary monitor workarea width

		wimgpane := imgw_gui_units

		himgpane := imgh_gui_units
		if(wimgpane > gui_wreq-stock_width)
		{	
		; shrink wimgpane to fit in monitor
			wimgpane := round(gui_wreq - stock_width) ; preview(pic control) width
			himgpane := round(wimgpane * imgh_scaled/imgw_scaled) ; preview height
			
			g_evpImageZoom := wimgpane / imgw_gui_units
		}
		else 
		{
			g_evpImageZoom := 1
		}
		
		; todo optimize: adjust y position ,
		; todo optimize: deal with long portrait image scaling
	}
	else ; imgfilepath is empty, reset UI to default
	{
;		dev_assert(0) ; dead code? No, use at init stage
		wimgpane := gc_evpImgpaneDefWidth
		himgpane := gc_evpImgpaneDefHeight
	}
	
	ximgpane := gc_evpMarginX + gc_evpCol1Width + gc_evpGapX

	rScaleLabel := GuiControl_GetPos("EVP", "gu_evpTxtScale")
	yRef := rScaleLabel.y
	
	GuiControl_SetPos("EVP", "gu_evpPicPreview", ximgpane, yRef, wimgpane, himgpane) ; same vertical pos

	g_evpImgpaneWidth := round(wimgpane) 
	g_evpImgpaneHeight := round(himgpane)

	col2w := dev_max(wimgpane, gc_evpImgpaneDefWidth)
	gui_fullwidth := dev_max(Evp_CalCtrlFullWidth(), gc_evp_GUIDefWidth)
	
	GuiControl_SetPos("EVP", "gu_evpTxtClipbState", -1, -1, col2w, -1)
	GuiControl_SetPos("EVP", "gu_evpEdrBaseImgFilepath", -1, -1, gui_fullwidth, -1)
	
	GuiControl_SetText("EVP", "gu_evpPicPreview", imgfilepath) ; this actually changes Pic control's picture appearance

	footy := yRef + dev_max(gc_evpImgpaneDefHeight, himgpane) + gc_evpGapY
	GuiControl_SetPos("EVP", "gu_evpEdrFootline"
		, -1, footy
		, gui_fullwidth-gc_evpIconBtnWidth-9, -1)
	;
	rFootline := GuiControl_GetPos("EVP", "gu_evpEdrFootline")
	;
	GuiControl_SetPos("EVP", "gu_evpBtnCopyFile"
		, rFootline.x + rFootline.w + 2, footy - 1
		, -1, -1)

	yBtnOK := rFootline.y + rFootline.h + gc_evpGapY
	GuiControl_SetPos("EVP", "gu_evpBtnOK"
		, -1, yBtnOK
		, -1, -1)
	GuiControl_SetPos("EVP", "gu_evpCkbAutoPaste" , -1, yBtnOK+5, -1, -1)
	GuiControl_SetPos("EVP", "gu_evpCkbKeepWindow", -1, yBtnOK+5, -1, -1)
	
	Evp_AutosizeNowUI()

	if(imgfilepath)
	{
		; Some quick tweak: If the window is too tall, we move down the window to y=0, 
		; so that its title bar can be seen on primary monitor.
		WinGetPos, x,y,w,h, ahk_id %g_HwndEVPGui%
		if(h>wa.height)
			WinMove, ahk_id %g_HwndEVPGui%, , %x%, 0
	}
}

Evp_RefreshPreviewAllGui()
{
	if(not g_evpImglistTxtPath)
	{
		MsgBox, % "BUG found in Evp_RefreshPreviewAllGui()."
		return
	}
	
	g_evp_arImageStore := []
	
	Loop, Read, % g_evpImglistTxtPath
	{
		field := StrSplit(A_LoopReadLine, "*")
		desc := field[1]	; Example: "PNG (32-bit), 80KB"
		imgfile := field[2]
		
		filelen := dev_FileGetSize(imgfile)
		if(filelen>=1024)
			filelen_desc := Format("{} KB", filelen//1024)
		else 
			filelen_desc := Format("{} B", filelen)
		
		; Add desc(image variant description) to listbox
		GuiControl, EVP:, gu_evpLbxImages, % Format("{}, {}", desc, filelen_desc)
		
		g_evp_arImageStore[A_Index] := {"hint":desc, "filelen_desc":filelen_desc, "path":imgfile}
		; -- hint will be displayed as small-font footnote beneath each image in Evernote clip.
	}
	
	; Choose and display PNG-32bit by default
	GuiControl, EVP:Choose, gu_evpLbxImages, 1
	GuiControl, EVP:, gu_evpPicPreview, % g_evp_arImageStore[1].path
	GuiControl, EVP:Focus, gu_evpLbxImages
	
	GuiControl_Enable("EVP","gu_evpBtnOK", true)
}

Evp_evtCbxScalepctChanged()
{
	scale_pct := Evp_GetUIScalePct()
	
	if(scale_pct==g_evpCurrentScalePct)
		GuiControl_Enable("EVP", "gu_evpLbxImages", true)
	else
		GuiControl_Enable("EVP", "gu_evpLbxImages", false)
}

Evp_RefreshImgpane()
{
	idx := GuiControl_GetText("EVP", "gu_evpLbxImages")
	
	cur_imagefile := g_evp_arImageStore[idx].path
	
	GuiControl_SetText("EVP", "gu_evpPicPreview",  cur_imagefile)
	
	GuiControl_SetText("EVP", "gu_evpEdrFootline", cur_imagefile)
}

Evp_BtnOK()
{
	GuiControlGet, gu_evpLbxImages
	imgfilepath := g_evp_arImageStore[gu_evpLbxImages].path
	dev_SplitPath(imgfilepath, imgfilename)
	imghint := g_evp_arImageStore[gu_evpLbxImages].hint ; "PNG(32-bit)" etc
	filelen_desc := g_evp_arImageStore[gu_evpLbxImages].filelen_desc

	dev_assert(StrIsStartsWith(imgfilename, g_evpImageSig))
	
	if(StrIsEndsWith(imgfilename, ".png", true) && g_evpCurPngHasTranspx==true)
		imghint .= "(PTP)" ; =Preserve Transparent Pixels

	html_fmt = 
(
<div><img src="{8}/Everpic-save/{1}" alt="max-width:{2}px" /><br>
<span style="font-size: 10px; color: rgb(144,144,144)">
{4}, {2}*{3}, {5}, {6} ({7})
</span></div>~
)
	html := Format(html_fmt
		, imgfilename ; {1}
		, Evp_ImgScaledWidth(), Evp_ImgScaledHeight() ; {2}, {3} width and height
		, filelen_desc ; {4} "33 KB" etc
		, imghint ; {5} 
		, g_evpImageSig ; {6}
		, dev_LocalTimeZoneMinutesStr() ; {7} timezone 
		, Everpic.baseurl)

	; Save the used picture to a permanent directory, so that we can get it back 
	; in case Evernote fail to actually store my picture in the note.
	dir_everpic_save := Everpic.dirSaveImg
	FileCreateDir, %dir_everpic_save%
	FileCopy, %imgfilepath%, %dir_everpic_save%, 1 ; 1=overwrite
	if(ErrorLevel) {
		; Note: We did a non-overwrite copy, if destination file exist, we get ErrorLevel.
		dev_MsgBoxInfo("Unexpect: Fail to copy your image file to " dir_everpic_save)
		return
	}
	
	is_autopaste  := GuiControl_GetValue("EVP", "gu_evpCkbAutoPaste")
	is_keepwindow := GuiControl_GetValue("EVP", "gu_evpCkbKeepWindow")
	
	dev_ClipboardSetHTML(html
		, is_autopaste ? true : false
		, g_evpHwndToPaste)
	
	if(!is_autopaste && is_keepwindow)
	{
		dev_TooltipAutoClear("HTML content with this image has been placed into Clipboard.", 3000)
	}

	if(!is_keepwindow)
	{
		Evp_CleanupUI()
	}

	Evp_CleanupTempDir()
}

Evp_CleanupTempDir_withInterval()
{
	static s_msecPrevCleanup := 0
	
	; To reduce disk access, we do a cleanup only after one minute has elapsed since last cleanup.
	
	msec_now := A_TickCount
	msec_since_prev_cleanup := msec_now - s_msecPrevCleanup
	
	Evp_DbgCleanup(Format("EVP-cleantemp(every {} seconds): prev={}, now={}, diff={}", g_evpTempPreserveMinutes*60, msec_now//1000, s_msecPrevCleanup//1000, msec_since_prev_cleanup//1000)) ; debug
	
	one := 1
	if(msec_since_prev_cleanup >= one*60*1000)
	{
		Evp_CleanupTempDir()
	
		s_msecPrevCleanup := msec_now
	}
}

Evp_CleanupTempDir()
{
	; Cleanup stale everpic-... files in C:\Users\win7evn\AppData\Local\Temp\Everpic

	Loop, Files, % Everpic.dirTempImg "\*"
	{
		filename := A_LoopFileName ; example: "everpic-20221204_220000.q40.jpg"
		
		foundpos := RegExMatch(filename, "^everpic-([0-9]+)_([0-9]+)", subpat)
		if(foundpos>0)
		{
			file_datetime := subpat1 . subpat2
			
			diff_seconds := A_Now
			EnvSub diff_seconds, file_datetime, Seconds
			
			N := g_evpTempPreserveMinutes

			if(diff_seconds >= N*60)
			{
				pathdel := Everpic.dirTempImg "\" filename
			
				Evp_DbgCleanup("Evp_CleanupTempDir(), FileDelete: " pathdel) ; debug
				
				FileDelete, % pathdel
			}
		}

	}
}

Evp_DbgCleanup(msg)
{
	if(g_evpDbgCfg.showdbgcleanup)
		Dbgwin_Output(msg)
}



AUTOEXEC_FoxitCoedit: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.
; -- naming: Foxit PDF reader/editor from two machines, co-operatively edit the same PDF file

/* APIs:

*/

;;;;;;;; Foco global vars ;;;;;;;;;;

global g_foco ; The single object responsible for the Foco GUI
global FoxitCoedit_Id := "FoxitCoedit"

global g_HwndFOCOGui

global gu_focoBtnSavePdf
global gu_focoMleInfo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include %A_LineFile%\..\pdfreader.ahk


class FoxitCoedit
{
	; static vars as constant
	
	mineside := -1
	peerside := -1
	
	cofile := ""
	
	sides_info := [] ; only two elements [0] for sideA , [1] for sideB
	
	
	
	dbg(msg, lv) {
		AmDbg_output(FoxitCoedit_Id, msg, lv)
	}
	dbg0(msg) {
		FoxitCoedit.dbg(msg, 0)
	}
	dbg1(msg) {
		FoxitCoedit.dbg(msg, 1)
	}
	dbg2(msg) {
		FoxitCoedit.dbg(msg, 2)
	}

	CreateGui()
	{
		GuiName := "FOCO"
		
		Gui_New(GuiName)
		Gui_ChangeOpt(GuiName, "+Resize +MinSize")
		Gui_AssociateHwndVarname(GuiName, "g_HwndFOCOGui")
		
		fullwidth := 600
		Gui_Add_Button(  GuiName, "gu_focoBtnSavePdf",  120, "xm " gui_g("Evl_OnBtnSavePdf"), "&Save pdf")
		Gui_Add_Editbox( GuiName, "gu_focoMleInfo", fullwidth, "xm r20" , "...")
	}
	
	OnBtnSavePdf()
	{
	
	}

} ; class FoxitCoedit




Foco_LaunchUI()
{
	if(!g_foco)
	{
		dev_MsgBoxError("Foco UI has not been initialized.")
		return
	}

;	g_foco.ShowGui()
	
}

Evl_OnBtnSavePdf()
{

}


/*
FOCOGuiSize()
{
	rsdict := {}
	
	dev_GuiAutoResize("FOCO", rsdict, A_GuiWidth, A_GuiHeight)
}

FOCOGuiClose()
{
	g_foco.HideGui()
}

FOCOGuiEscape()
{
	g_foco.HideGui()
}



FOCO_OnEditChange()
{
	g_foco.OnEditChange()
}

FOCO_OnBtnOK()
{
	g_foco.OnBtnOK()
}


FOCO_WM_KEYDOWN(wParam, lParam, msg, hwnd)
{
	g_foco.On_WM_KEYDOWN(wParam, lParam, msg, hwnd)
}

FOCO_OnCkbRecent()
{
	g_foco.OnCkbRecent()
}

FOCO_OnBtnCopyTag()
{
	g_foco.OnBtnCopyTag()
}

FOCO_OnBtnChgDesc()
{
	g_foco.OnBtnChgDesc()
}


Everlink_Clipmon()
{
	g_foco.ClipmonCallback()
}

*/

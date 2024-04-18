AUTOEXEC_FoxitCoedit: ; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.
; -- naming: Foxit PDF reader/editor from two machines, co-operatively edit the same PDF file

/* APIs:

*/

;;;;;;;; Foco global vars ;;;;;;;;;;

global g_foco ; The single object responsible for the Foco GUI
global FoxitCoedit_Id := "FoxitCoedit"

global gu_focoLblDetecting
global g_HwndFOCOGui

global gu_focoBtnSavePdf
global gu_focoBtnSync
global gu_focoBtnTest
global gu_focoMleInfo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include %A_LineFile%\..\pdfreader.ahk
#Include %A_LineFile%\..\libs\class.PeersCoedit.ahk

class FoxitCoedit
{
	; static vars as constant
	
	isGuiVisible := false
	
	testmember := "testmember"
	
	coedit := "" ; the PeersCoedit class instance
	
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

	__New()
	{
		this.coedit := new PeersCoedit()
	}
	
	pdfpath[]
	{
		get {
			return this.coedit.docpath
		}
	}

	Activate(which_side, pdfpath)
	{
		fndoc := { "savedoc" : Func("FoxitCoedit.fndocSavePdf").Bind(this)
			, "closedoc" : Func("FoxitCoedit.fndocClosePdf").Bind(this)
			, "opendoc" : Func("FoxitCoedit.fndocOpenPdf").Bind(this) }
		
		this.coedit.Activate(which_side, pdfpath, fndoc)
	}
	
	Deactivate()
	{
;		dev_assert(this.coedit)
		this.coedit.Deactivate()
	}

	CreateGui()
	{
		GuiName := "FOCO"
		
		Gui_New(GuiName)
		Gui_ChangeOpt(GuiName, "+Resize +MinSize")
		Gui_AssociateHwndVarname(GuiName, "g_HwndFOCOGui")
		
		fullwidth := 500
		
		Gui_Add_TxtLabel(GuiName, "gu_focoLblDetecting", fullwidth, "", "Detecting Foxit Reader/Editor")
		
		Gui_Add_Button(  GuiName, "gu_focoBtnSavePdf",  120, "xm " gui_g("Foco_OnBtnSavePdf"), "Save &pdf")
		Gui_Add_Button(  GuiName, "gu_focoBtnSync",  50, "x+10 " gui_g("Foco_OnBtnSync"), "&Sync")
		Gui_Add_Editbox( GuiName, "gu_focoMleInfo", fullwidth, "xm r10" , "...")
	}

	ShowGui()
	{
		GuiName := "FOCO"
		if(this.isGuiVisible)
			return ; already shown
		
		if(!g_HwndFOCOGui) {
			this.CreateGui()
		}
		
		Gui_Show(GuiName, "AutoSize", "FOCO")
		
		this.isGuiVisible := true
	}
	
	HideGui()
	{
		Gui_Hide("FOCO")
		this.isGuiVisible := false
	}


	OnBtnSync()
	{
		this.coedit.ResetSyncState()
	}
	
	OnBtnSavePdf()
	{
		GuiName := "FOCO"
;		GuiControl_Disable(GuiName, "gu_focoBtnSavePdf")

		is_succ := this.coedit.LaunchSaveDocSession()
		
		if(is_succ)
		{
			; todo : UI update
		}
		else
		{
			this.coedit.ResetSyncState()
			dev_MsgBoxWarning("Peer connection lost. Now resyncing.")
			
		}
	}
	
	fndocSavePdf()
	{
		AmDbg0("##### " this.testmember " SavePdf" )
	}
	
	fndocClosePdf()
	{
		AmDbg0("##### " this.testmember " ClosePdf" )
	}

	fndocOpenPdf()
	{
		AmDbg0("##### " this.testmember " OpenPdf" )
	}

} ; class FoxitCoedit


FoxitCoedit_Init(which_side, docpath)
{
	g_foco := new FoxitCoedit()
	g_foco.Activate(which_side, docpath)
}

FoxitCoedit_Deactivate()
{
	AmDbg0("FoxitCoedit_Deactivate()")
	g_foco.Deactivate()
}

#!y:: FoxitCoedit_Deactivate()


FoxitCoedit_LaunchUI()
{
	if(!g_foco)
	{
		dev_MsgBoxError("FoxitCoedit_Init() not called yet!")
		;dev_assert(g_foco, "FoxitCoedit class instance creation fail!")
	}

	g_foco.ShowGui()
}

Foco_OnBtnSavePdf()
{
	g_foco.OnBtnSavePdf()
}

Foco_OnBtnSync()
{
	g_foco.OnBtnSync()
}

foco_SyncTimerCallback()
{
	g_foco.SyncTimerCallback()
}


Foco_OnBtnTest()
{
	g_foco.OnBtnTest()
}

FOCOGuiSize()
{
	rsdict := {}
	rsdict.gu_focoMleInfo := JUL.LeftTop_DynWidthHeight
	
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



/*
FOCO_OnBtnOK()
{
	g_foco.OnBtnOK()
}

*/

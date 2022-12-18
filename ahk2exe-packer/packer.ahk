
#include ..\AmUtils-common.ahk
#include ..\AmUtils-gui.ahk
#include ..\libs\debugwin.ahk

Do_Packer()

Do_Packer()
{

	dev_MsgBoxInfo("Do_Packer.")

	if(A_Args.Length()==0)
	{
		dev_MsgBoxError("You must pass-in a project dirname(e.g. ""Everpic"") as parameter.")
		ExitApp
	}

	dbg("ok...............")
	
	dev_MsgBoxInfo("Finished.")
	
	ExitApp
}


dbg(s)
{
	Dbgwin_Output(s)
}



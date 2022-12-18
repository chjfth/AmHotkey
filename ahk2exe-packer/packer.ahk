
#include ..\AmUtils-common.ahk
#include ..\AmUtils-gui.ahk
#include ..\libs\debugwin.ahk

;global gar_customize_filenames 
; -- typical value: ["_more_includes_.ahk", "customize.ahk"]

Do_Packer()

Do_Packer()
{
	SetWorkingDir %A_ScriptDir%

	if(A_Args.Length()==0)
	{
		dbgfail("You must pass-in a project dirname(e.g. ""Everpic"") as parameter.")
	}

	project := A_Args[1]

	dirProject := Format("{}\{}", A_ScriptDir, project)
	dirAmroot  := dev_GetParentDir(A_ScriptDir)
	
	dbg("dirProject = " project)

	if( Instr(FileExist(dirProject), "D")==0 )
	{
		dbgfail("The given project dir does NOT exist: " dirProject)
	}
	
	custfilenames := GetCustFilenames(dirProject)
	
	CopyCustToAmroot(custfilenames, dirProject, dirAmroot)
	
	exeout_dir := Format("{1}\{1}-ahk2exe", project) ; relative to packer.ahk's dir
	dev_CreateDirIfNotExist(exeout_dir)
	exeout_filepath := Format("{}\{}", exeout_dir, project ".exe")
	
	if(not dev_FileDelete(exeout_filepath))
		dbgfail("Cannot delete old output exe: " exeout_filepath)
	
	ahk2exe_cmd := Format("..\Compiler\Ahk2Exe.exe "
		. "/in   ..\AmHotkey.ahk "
		. "/out  {2} "
		. "/icon {1}\{1}.ico "
		. "/base ""..\Compiler\Unicode 32-bit.bin"""
		, project, exeout_filepath)
	
	dbg("Run cmd: " ahk2exe_cmd)
	
	RunWait, % ahk2exe_cmd
	if(ErrorLevel)
	{
		dbgfail("ahk2exe execution fail, with exitcode=" ErrorLevel)
	}
	
	if(not FileExist(exeout_filepath))
	{
		dbgfail("Unexpect! ahk2exe reports success, but output file does not exist: " exeout_filepath)
	}
	
	dbg("EXE generated successfully: " exeout_filepath)
	dev_MsgBoxInfo("EXE generated successfully: `r`n`r`n" exeout_filepath)
	
	RestoreCustAtAmRoot(custfilenames, dirAmroot)
	
	ExitApp 0
}


GetCustFilenames(dir)
{
	checkfns := ["_more_includes_.ahk", "customize.ahk"]
	foundfns := []
	
	for i,chkfn in checkfns
	{
		filepath := Format("{}\{}", dir, chkfn)
		if( dev_IsDiskFile(filepath) )
		{
			foundfns.Push(chkfn)
		}
	}
	
	return foundfns
}

CopyCustToAmroot(arfilenames, srcdir, dstdir)
{
	for i,filename in arfilenames
	{
		srcfilepath := srcdir "\" filename
		dstfilepath := dstdir "\" filename
	
		Dbgwin_Output("Preparing custfile: " dstfilepath)
	
		; Make a backup of dst-file first.
		;
		dstbackup := dstfilepath ".bak"
		succ := dev_Copy1File(dstfilepath, dstbackup, true)
		if(!succ) 
			dbgfail("Cannot generate backup file: " dstbackup)
		
		succ := dev_Copy1File(srcfilepath, dstfilepath, true)
		if(!succ)
			dbgfail("Cannot generate customization file: " dstfilepath)
	}
}

RestoreCustAtAmRoot(arfilenames, dstdir)
{
	; Copy XXX.ahk.bak to XXX.ahk
	
	for i,filename in arfilenames
	{
		orgfilepath := dstdir "\" filename
		bakfilepath := orgfilepath ".bak"
	
		Dbgwin_Output("Restoring: " orgfilepath)
	
		succ := dev_Copy1File(bakfilepath, orgfilepath, true)
		if(!succ) 
			dbgfail("Cannot restore: " orgfilepath)
	}
}


dbg(s)
{
	Dbgwin_Output(s)
}

dbgfail(s)
{
	Dbgwin_Output(s)
	dev_MsgBoxError(s, A_ScriptName " Error")
	ExitApp 4
}


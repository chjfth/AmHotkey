#include %A_LineFile%\..\..\libs
#include Amhk-common.ahk
#include Amhk-gui.ahk
#include debugwin.ahk

#include *i #Include %A_LineFile%\..\other.ahk.

global g_packer_BakFiles := [] ; These files will be restored on premature ExitApp

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

	exeout_dirname := get_exeout_dirname(project)
	exeout_dir := Format("{}\{}", project, exeout_dirname) ; relative to packer.ahk's dir
	exeout_filepath := dev_GetFullPathName( Format("{}\{}", exeout_dir, project ".exe") )

	; Remove old output dir first.
	if(FileExist(exeout_dir))
	{
		if(not dev_FileRemoveDir(exeout_dir, true))
			dbgfail(Format("Cannot delete old output dir: {}\{}", dirProject, exeout_dir))
	}

	dev_CreateDirIfNotExist(exeout_dir)
	
	PackerCopyFilesByIni(dirAmroot, dirProject)

	custfilenames := GetCustFilenames(dirProject)
	CopyCustToAmroot(custfilenames, dirProject, dirAmroot)
	; -- This temporarily modify customize.ahk and _more_includes_.ahk in 
	;    Amroot dir, with project-specific files of the same names.
	;    The two files will be restored on exit.
	
	fpAhk2Exe := dev_GetFullPathName("..\Compiler\Ahk2Exe.exe")
	fpBootBin := dev_GetFullPathName("..\Compiler\Unicode 32-bit.bin")
	
	if(not FileExist(fpAhk2Exe)) {
		dev_MsgBoxError(Format("Missing required file:`n`n{}", fpAhk2Exe))
		ExitApp 4
	}
	if(not FileExist(fpBootBin)) {
		dev_MsgBoxError(Format("Missing required file:`n`n{}", fpBootBin))
		ExitApp 4
	}
	
	ahk2exe_cmd := Format("""{1}"" "
		. "/in ..\AmHotkey.ahk "
		. "/out  {2} "
		. "/icon {3}\{3}.ico "
		. "/base ""{4}"""
		, fpAhk2Exe
		, exeout_filepath
		, project
		, fpBootBin)

	dbg("Run cmd: " ahk2exe_cmd)

	RunWait, % ahk2exe_cmd
	if(ErrorLevel)
	{
		dbgfail("ahk2exe execution fail, with exitcode=" ErrorLevel)
	}

	if(not FileExist(exeout_filepath))
	{
		dbgfail("Somthing Wrong! ahk2exe reports success, but output file does not exist:`n`n" exeout_filepath)
	}

	dbg("EXE generated successfully: " exeout_filepath)

	dev_MsgBoxInfo("EXE generated successfully: `n`n" exeout_filepath)

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
	; Clear all old .bak files first
	for i,filename in arfilenames
	{
		bakfilepath := dstdir "\" filename ".bak"
		if(!dev_FileDelete(bakfilepath))
			dbgfail("Cannot remove old file: " bakfilepath)
	}

	OnExit("RestoreCustAtAmRoot")

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
			
		g_packer_BakFiles.Push(dstbackup)

		succ := dev_Copy1File(srcfilepath, dstfilepath, true)
		if(!succ)
			dbgfail("Cannot generate customization file: " dstfilepath)
	}
}

RestoreCustAtAmRoot()
{
	; For files in g_packer_BakFiles[], copy XXX.ahk.bak to XXX.ahk

	for i,bakfilepath in g_packer_BakFiles
	{
		orgfilepath := dev_StripSuffix(bakfilepath, ".bak")
		dev_assert(orgfilepath!=bakfilepath)

		Dbgwin_Output("Restoring: " orgfilepath)

		succ := dev_Copy1File(bakfilepath, orgfilepath, true)
		if(!succ)
		{
			dev_MsgBoxWarning("[PANIC!] Cannot restore: " orgfilepath)
			; -- Don't quit, try to restore next file
		}
	}
}

PackerCopyFilesByIni(amroot, prjdir)
{
	; Copy files according to %prjdir%\packer.ini

	inifile := prjdir . "\packer.ini"

	CopyFiles := dev_IniRead(inifile, "CopyFiles")
	copylines := StrSplit(CopyFiles, "`n")

	for i,linetext in copylines
	{
		pair := StrSplit(linetext, "=")
		srcpath := pair[1]
		dstpath := pair[2]

		srcpath := Packer_ReplaceDirPrefix(srcpath, amroot, prjdir)
		dstpath := Packer_ReplaceDirPrefix(dstpath, amroot, prjdir)

		; If dstpath from .ini ends with \ , then we append source filename to it.
		if(StrIsEndsWith(dstpath, "\"))
		{
			dev_SplitPath(srcpath, srcfilename)
			dstpath .= srcfilename
		}

		dbg("Copy file: `r`n"
			. "  SRC: " srcpath "`r`n"
			. "  DST: " dstpath)
		
		if(not FileExist(srcpath))
			dbgfail(Format("From {}, `r`n`r`nSRC file does not exist: {}", inifile, srcpath))
		
		if(not dev_IsDiskFile(srcpath))
			dbgfail(Format("From {}, `r`n`r`nSRC is not a file: {}", inifile, srcpath))
		
		succ := dev_Copy1File(srcpath, dstpath, true)
		if(!succ)
			dbgfail("Cannot create file: " dstpath)
	}
}

Packer_ReplaceDirPrefix(path1, amroot, prjdir)
{
	; $R : AmHotkey Root dir
	; $P : Project dir
	; $E : Exe output dir

	path1 := RegExReplace(path1, "^\$R\\", amroot "\")

	path1 := RegExReplace(path1, "^\$P\\", prjdir "\")

	dev_SplitPath(prjdir, prjname)

	path1 := RegExReplace(path1, "^\$E\\"
		, Format("{}\{}\", prjdir, get_exeout_dirname(prjname)))

	return path1
}

get_exeout_dirname(prjname)
{
	return prjname "-ahk2exe"
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


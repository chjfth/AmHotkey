
; For input file: D:\mydoc\test.pdf
; I will create backup files:
;	D:\mydoc\test.pdf.backup\recent1.test.pdf
;	D:\mydoc\test.pdf.backup\recent2.test.pdf
;	D:\mydoc\test.pdf.backup\recent3.test.pdf
;	...
;
; The recent1 is the newest, and recent3 is the oldest
;
; API:
;	PiledBackup_DoOnce(filepath, nkeep)
; 

class PiledBackup
{
	static DoMove := 0
	static DoCopy := 1

	master_filepath := ""
	versions_tokeep := 3
	
	filenam := ""
	dirbackup := ""
	
	doCopyOrMove :=
	
	__New(inputfile, dirbackup, nkeep:=3, doCopyOrMove:=1)
	{
		; [2025-03-23] Note: I cannot write `doCopyOrMove:=PiledBackup.DoCopy`,
		; bcz AHK 1.1.32 would report error on loading: Unsupported parameter default.
	
		if(not dev_IsDiskFile(inputfile))
			dev_throw("Not a diskfile: " inputfile)
		
		if(InStr(inputfile, "*") or InStr(inputfile, "?"))
			dev_throw("Wildcard * or ? not allowed in you input file: " inputfile)
		
		if(nkeep<1)
			dev_throw("Invalid nkeep parameter: " versions_tokeep)
			
		this.master_filepath := inputfile
		this.versions_tokeep := nkeep
		
		_tmp := dev_SplitPath(this.master_filepath, filenam)
		this.filenam := filenam
		
		this.dirbackup := dirbackup
		
		this.doCopyOrMove := doCopyOrMove
	}
	
	filepath_by_seq(seq)
	{
		return Format("{}\recent{}.{}", this.dirbackup, seq, this.filenam)
	}
	
	; Public API
	SaveOneBackup()
	{
		; Will throw exception on disk/file operation error.
	
		dev_CreateDirIfNotExist(this.dirbackup)
		if(not dev_IsDiskFolder(this.dirbackup))
			dev_throw(Format("I need to create disk folder ""{}"", but fails. Please check the reason yourself.", this.dirbackup))
		
		nkeep := this.versions_tokeep
		
		; Delete oldest 
		dev_FileDelete(this.filepath_by_seq(nkeep))
		
		Loop, % this.versions_tokeep-1
		{
			oldseq := nkeep - A_Index
			newseq := oldseq + 1
			
			oldpath := this.filepath_by_seq(oldseq)
			newpath := this.filepath_by_seq(newseq)
			
			if(FileExist(oldpath))
				dev_MoveFile(oldpath, newpath, true, "throw")
		}
		
		; Save the latest 
		newpath := this.filepath_by_seq(1)
		if(this.doCopyOrMove==PiledBackup.DoCopy)
		{
			dev_CopyFile(this.master_filepath, newpath, true, "throw")
		}
		else
		{
			dev_MoveFile(this.master_filepath, newpath, true, "throw")
		}
		
		return true
	}
}

PiledBackup_DoOnce(filepath, nkeep)
{
	pb := new PiledBackup(filepath, nkeep)
	pb.SaveOneBackup()
}


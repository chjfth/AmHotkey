
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
	master_filepath := ""
	versions_tokeep := 3
	
	filenam := ""
	dirbackup := ""
	
	__New(inputfile, dirbackup, nkeep:=3)
	{
		if(not dev_IsDiskFile(inputfile))
			dev_throw("Not a diskfile: " inputfile)
		
		dev_CreateDirIfNotExist(dirbackup)
		if(not dev_IsDiskFolder(dirbackup))
			throw Exception(Format("I need to create disk folder ""{}"", but fails. Please check the reason yourself.", dirbackup))
		
		if(InStr(inputfile, "*") or InStr(inputfile, "?"))
			dev_throw("Wildcard * or ? not allowed in you input file: " inputfile)
		
		if(nkeep<1)
			dev_throw("Invalid nkeep parameter: " versions_tokeep)
			
		this.master_filepath := inputfile
		this.versions_tokeep := nkeep
		
		_tmp := dev_SplitPath(this.master_filepath, filenam)
		this.filenam := filenam
		
		this.dirbackup := dirbackup
	}
	
	filepath_by_seq(seq)
	{
		return Format("{}\recent{}.{}", this.dirbackup, seq, this.filenam)
	}
	
	; Public API
	SaveOneBackup()
	{
		; Should throw exception on disk/file operation error.
	
		dev_CreateDirIfNotExist(this.dirbackup)
		if(not dev_IsDiskFolder(this.dirbackup))
			throw Exception(Format("I need to create disk folder ""{}"", but fails. Please check the reason yourself.", this.dirbackup))
		
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
				dev_MoveFile(oldpath, newpath)
		}
		
		; Save the latest 
		newpath := this.filepath_by_seq(1)
		dev_CopyFile(this.master_filepath, newpath)
		
		return true
	}
}

PiledBackup_DoOnce(filepath, nkeep)
{
	pb := new PiledBackup(filepath, nkeep)
	pb.SaveOneBackup()
}


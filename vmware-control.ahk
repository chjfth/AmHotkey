; Note: If this file contains non-ASCII characters, you must save it in UTF8 with BOM,
; in order for the Unicode characters to be recognized by Autohotkey engine.
;
AUTOEXEC_vmware_control: 
	; Workaround for Autohotkey's ugly auto-exec feature. Don't delete.

/*
API:
Start_MonitorPausedVMsAndSuspendThem(delay_minutes)
Stop_MonitorPausedVMsAndSuspendThem()

	The Start function starts a timer to check for idle VMware workstation VMs,
	(a paused VM is a typical idle one), and, if a VM is idle for more than 1 hour,
	I will run "vmrun.exe suspend xxx.vmx" to suspend it.
	
	VMware does NOT provide out-of-box command to query whether a VM is paused,
	so I have to check for vmx-folder all files's modification time to deduce. 

*/

global g_vmwks_exedir := "C:\Program Files (x86)\VMware\VMware Workstation"


return ; The first return in this ahk. It marks the End of auto-execute section.
;
; After this line, you can define hotkeys and functions, 
; or #Include somebody else's AHK partial file(s).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


class vmctl
{
	; Cfg:
	static chk_interval_seconds := 60
	
	static delay_seconds_bfr_suspend := 3600
	; -- this value is changed by Start_MonitorPausedVMsAndSuspendThem()'s argument.
	
	; Runtime data:
	static dictvm := {} ; dict-key is vmxpath
}


Start_MonitorPausedVMsAndSuspendThem(minutes:=60)
{
	if(minutes==0)
		minutes := 1
	
	if(minutes>0)
		vmctl.delay_seconds_bfr_suspend := minutes * 60
	else
		vmctl.delay_seconds_bfr_suspend := -minutes ; take it as seconds, debug purpose

	first_err := ""
	if(not vmctl_timer_MonitorPausedVMs(first_err))
	{
		dev_MsgBoxError("Error occurred querying VM running state, so timer will not start.`n`n" . first_err)
		return
	}

	dev_StartTimerPeriodic("vmctl_timer_MonitorPausedVMs", 1000*vmctl.chk_interval_seconds)
;	Dbgwin_Output(Format("Timer vmctl_timer_MonitorPausedVMs() started, every {} seconds. (delay {} secs)", vmctl.chk_interval_seconds, vmctl.delay_seconds_bfr_suspend)) ;debug
}

Stop_MonitorPausedVMsAndSuspendThem()
{
	dev_StopTimer("vmctl_timer_MonitorPausedVMs")
}


vmctl_timer_MonitorPausedVMs(byref errmsg:="")
{
	vmxlist := vmctl_GetRunningVmxList()
	if(StrIsStartsWith(vmxlist, "[ERROR]"))
	{
		errmsg := vmxlist
		return false
	}
	
	for index,vmxpath in vmxlist
	{
		LastFiletime := vmctl_GetVmLastModifyTime(vmxpath)
		
		if(not vmctl.dictvm.HasKey(vmxpath))
		{
			vmctl.dictvm[vmxpath] := {}
			vmctl.dictvm[vmxpath].LastFiletime := "0"
			vmctl.dictvm[vmxpath].tickcount := 0 ; OS millisec
		}

		if(LastFiletime != vmctl.dictvm[vmxpath].LastFiletime)
		{
			; This means: the VM got some modification since last check.
			; So, update the two time reference to now-time.
			;
			vmctl.dictvm[vmxpath].LastFiletime := LastFiletime
			vmctl.dictvm[vmxpath].tickcount := A_TickCount ; OS millisec
		}
		else
		{
			; The VM has not been modified for a while, so check whether it has been
			; idle for long enough.
			idle_secs := (A_TickCount - vmctl.dictvm[vmxpath].tickcount) / 1000
;			Dbgwin_Output("vmctl:: idle_secs: " idle_secs)

			if(idle_secs >= vmctl.delay_seconds_bfr_suspend)
			{
				msg := "Start suspending VM: " vmxpath
				dev_TooltipAutoClear(msg)
				
				Dbgwin_Output(msg) ; debug
				
				vmctl_SuspendVmx(vmxpath)

				msg := "Done suspending VM: " vmxpath
				dev_TooltipAutoClear(msg)

				vmctl.dictvm[vmxpath].tickcount := A_TickCount
				; -- on simulating VM Suspend, this avoids triggering frequently
			}
		}
	}
	return true
}

vmctl_SuspendVmx(vmxpath)
{
	; For VMwks 16.2.3, we need to Unpause VM first(in case it was paused), 
	; to ensure VM Suspend success.

	cmd := Format("""{}\vmrun.exe"" unpause ""{}""", g_vmwks_exedir, vmxpath)
	dev_RunWaitOne(cmd, "hide")

	cmd := Format("""{}\vmrun.exe"" suspend ""{}""", g_vmwks_exedir, vmxpath)

	dev_RunWaitOne(cmd, "hide")
}

vmctl_GetRunningVmxList()
{
	cmd := Format("""{}\vmrun.exe"" list", g_vmwks_exedir)

/* Output is sth like this:

Total running VMs: 2
M:\_VMS_\pfSense1\pfSense1.vmx
N:\_vms_\Win10vwork\Win10vwork.vmx

*/
	dret := dev_RunWaitOneEx(cmd, "hide")

	if(dret.exitcode==0)
	{
		rawlines := StrSplit(dret.output, "`r`n")
		vmxlist := []
		for index,val in rawlines
		{
			if(Trim(val)=="")
				continue 
				
			if(dev_IsDiskFile(val))
				vmxlist.Push(val)
		}
		return vmxlist ; may be an empty list
	}
	else
	{
		
		errmsg := Format("The following shell command failed:`n`n"
			. "{}`n`n"
			. "Console output is:`n`n"
			. "{}"
		 	, cmd, dret.output)
		
		return "[ERROR] " . errmsg
	}
}

vmctl_GetVmLastModifyTime(vmx_filepath)
{
	; vmx_filepath is a .vmx's fullpath(`vmrun.exe list` reports this)
	; Check all files in the vmx's folder, the latest modification time
	; of all files within, is taken as that VM's modification time.
	;
	; If success, return a string in YYYYMMDD...... format.
	; If fail, return empty string.
	
	if(not dev_IsDiskFile(vmx_filepath))
		return ""
	
	vmxdir := dev_SplitPath(vmx_filepath)

	tt_latest := "0"
	Loop, Files, % vmxdir "\*.*"
	{
;		Dbgwin_Output(A_LoopFileTimeModified " : " A_LoopFileName)
		 if( A_LoopFileTimeModified > tt_latest )
		 	tt_latest := A_LoopFileTimeModified
	}
	
	return tt_latest
}



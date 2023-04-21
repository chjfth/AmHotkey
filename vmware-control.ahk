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

vmctl_InitEnv()

return ; The first return in this ahk. It marks the End of auto-execute section.
;
; After this line, you can define hotkeys and functions, 
; or #Include somebody else's AHK partial file(s).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


class vmctl
{
	static FeatureId := "VmCtl"

	; Cfg:
	static chk_interval_seconds := 60
	
	static delay_seconds_bfr_suspend := 3600
	; -- this value is changed by Start_MonitorPausedVMsAndSuspendThem()'s argument.
	
	;
	; Runtime data:
	;
	
	static dictvm := {} ; dict-key is vmxpath
	
	static smsec_now := 0 ; self maintained seconds as time-reference
}

vmctl_InitEnv()
{
	AmDbg_SetDesc(vmctl.FeatureId, "Debug message for vmware-control.ahk")
	
	dev_StartTimerPeriodic("_vmctl_smsec_inc", 1000)
}

vmctl_dbg(msg)
{
	AmDbg_output(vmctl.FeatureId, msg)
}

_vmctl_smsec_inc()
{
	; smsec: Self-maintained time-point in second.
	;
	; Yes, we need to measure only our program's running time elapse.
	; If Windows sleeps(so all VMs are implicitly paused), we do not want to count up during the sleep.
	; Timer delay accumulation error is not a matter for this scenario.
	
	vmctl.smsec_now++
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
	if(not vmctl_CheckAndSuspendPausedVMs(first_err))
	{
		dev_MsgBoxError("Error occurred querying VM running state, so timer will not start.`n`n" . first_err)
		return
	}

	dev_StartTimerPeriodic("vmctl_CheckAndSuspendPausedVMs", 1000*vmctl.chk_interval_seconds)

	vmctl_dbg(Format("vmctl_CheckAndSuspendPausedVMs() timer started, check every {} seconds, delay {} seconds before suspend."
		, vmctl.chk_interval_seconds, vmctl.delay_seconds_bfr_suspend))
}

Stop_MonitorPausedVMsAndSuspendThem()
{
	dev_StopTimer("vmctl_CheckAndSuspendPausedVMs")
}


vmctl_CheckAndSuspendPausedVMs(byref errmsg:="")
{
	vmxlist := vmctl_GetRunningVmxList()
	if(StrIsStartsWith(vmxlist, "[ERROR]"))
	{
		errmsg := vmxlist
		return false
	}
	
	for index,vmxpath in vmxlist
	{
		smsec_now := vmctl.smsec_now
		LastFiletime := vmctl_GetVmLastModifyTime(vmxpath)
		if(not LastFiletime)
		{
			errmsg := Format("Error get diskfile modification time, in vmctl_GetVmLastModifyTime(""{}"")", vmxpath)
			vmctl_dbg(errmsg)
			dev_MsgBoxError(errmsg)
			continue
		}
		
		if(not vmctl.dictvm.HasKey(vmxpath))
		{
			vmctl.dictvm[vmxpath] := {}
			vmctl.dictvm[vmxpath].LastFiletime := "" ; in AHK TS14 format
			vmctl.dictvm[vmxpath].smsec_idle_start := smsec_now
		}
		
		thisvm := vmctl.dictvm[vmxpath]
		
		if(LastFiletime != thisvm.LastFiletime)
		{
			; This means: the VM got some modification since last check.
			; So, update the two time reference to now-time.
			
			if(thisvm.LastFiletime)
			{
				vmctl_dbg(Format("#{} Activity detected: {} -> {}", index
					, dev_GetDateTimeStrCompact(".", thisvm.LastFiletime), dev_GetDateTimeStrCompact(".", LastFiletime) ))
			}
			
			thisvm.LastFiletime := LastFiletime
			thisvm.smsec_idle_start := smsec_now ; consider it idle from now
		}
		
		idle_secs := smsec_now - thisvm.smsec_idle_start
		remain_secs := vmctl.delay_seconds_bfr_suspend - idle_secs
		
		if(remain_secs>0)
		{
			vmctl_dbg(Format("#{}: Remain {} seconds for: {}", index, remain_secs, vmxpath))
		}
		else
		{
			vmctl_dbg(Format("#{}: Expired {} seconds, now suspend: {}", index, -remain_secs, vmxpath))

			msg := "Start suspending VM: " vmxpath
			dev_TooltipAutoClear(msg)
				
			vmctl_SuspendVmx(vmxpath)

			msg := "Done suspending VM: " vmxpath
			dev_TooltipAutoClear(msg)

			vmctl_dbg(Format("#{}: VM suspend done.", index))

			thisvm.smsec_idle_start := smsec_now
			; -- on simulating VM Suspend, this avoids triggering frequently
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


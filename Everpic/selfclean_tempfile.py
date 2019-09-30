#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import time

wheel = 0

# http://stackoverflow.com/q/1158076/151453
def touch(fname):
    if os.path.exists(fname):
        os.utime(fname, None)
    else:
        open(fname, 'a').close()


def _selfclean_tempfile(folder, prefix, preserve_seconds=3600, scan_delay_seconds=60): # this is internal function
	"""
	Operation:
	1. Get prefix.cleancheck file's modification time(cmtime). If not exist, create it.
	2. Check whether the prefix.cleancheck file has been touched more than scan_delay_seconds,
	   If so, do two things:
	   (1) delete all prefix-matching tempfiles before created preserve_seconds earlier.
	   (2) Update(create if not exist) prefix.cleancheck's modification time to 
	       now time(touch it).
	So, we traverse the folder only every 24 hour, not every call to _selfclean_tempfile.
	"""
	fullprefix = folder+os.sep+prefix
	fp_cleanchk = fullprefix+'.cleancheck'

	now_epsec = time.time()
	try:
		cmtime = os.path.getmtime(fp_cleanchk)
	except OSError:
		# possibly not exist yet, which is normal, so create it now
		cmtime = now_epsec
		open(fp_cleanchk, 'a').close()

	isdebug = False #True

	scan_lag_secs = now_epsec-cmtime - scan_delay_seconds
	if scan_lag_secs >= 0:
		epsec_clear_before = now_epsec-preserve_seconds
		
		if isdebug:
			print "[selfclean] will clear tempfiles before %s"%(tmpfilename_from_epsec(epsec_clear_before, ".999", prefix))
		
		_folder, _dirs, files = next(os.walk(folder)) # Non-recursive walk
		for f in files: 
			fullpath = folder+os.sep+f
			if fullpath==fp_cleanchk:
				continue
			if not f.startswith(prefix):
				continue
			
			if os.path.getmtime(fullpath) < epsec_clear_before:
				try:
					os.remove(fullpath)
				except:
					pass
		os.utime(fp_cleanchk, None)
	else:
		if isdebug:
			print "[selfclean] %d seconds to wait before next rescan"%(-scan_lag_secs)
		


def tmpfilename_from_epsec(epsec, msecpart, prefix, suffix=""): # only filename, no dir prefix
	epsec_local = time.localtime(epsec) 
	return prefix + time.strftime('-%Y%m%d_%H%M%S', epsec_local) + msecpart + suffix


def selfclean_create_tempfile(folder, prefix='temp', suffix='.tmp', 
	preserve_seconds=3600, scan_delay_seconds=60):
	"""
	Return fullpath of the created tempfile.
	
	folder: Create tempfile in `folder`.
	prefix: Prefix of your the created tempfile.
	
	Example: When folder="/user/mytemp" and prefix="everjpeg", suffix=".jpg"
	the generated filepath will be something like:
		/user/mytemp/everjpeg-20150107_203500.333.jpg
	"""

	try:
		os.mkdir(folder)
	except OSError:
		if not os.path.isdir(folder):
			raise OSError('Error in selfclean_create_tempfile(): Cannot create folder "%s" for tempfile.'%(folder))

	trycount = 0
	while True:
		now_epsec = time.time() # epsec is in UTC
		
		millisec = int(now_epsec*1000%1000)
		if millisec==0:
			# For those system not providing millisec part for time.time(),
			# simulate different millisec part inside one second.
			global wheel
			msecpart = ".%03d"%(wheel)
			wheel = wheel+1 if wheel<999 else 0
		else:
			msecpart = ".%03d"%(millisec)

		
		tpath = os.path.join(folder, 
			tmpfilename_from_epsec(now_epsec, msecpart, prefix, suffix))
		try:
			fd = os.open(tpath, os.O_RDWR | os.O_CREAT | os.O_EXCL)
			# Will raise OSError if file exist
		except OSError:
			trycount += 1
			if trycount<=10:
				time.sleep(0.01)
				continue # try again, hopefully with another file name
			else:
				raise OSError('Error in selfclean_create_tempfile(): Cannot create tempfile!')
		os.close(fd)
		break
	
	# Check whether we should clean some old tempfiles.
	_selfclean_tempfile(folder, prefix, preserve_seconds, scan_delay_seconds)

	return tpath



if __name__=='__main__':
	tpath = selfclean_create_tempfile('.', 'chj', '.ppp')
	print "Created tempfile:", tpath
	exit(0)
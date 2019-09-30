#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, traceback
import tempfile
import os
import shlex
import locale
import getopt
import time
import win32api
import win32clipboard as wc

sys.path.append( os.path.join(os.path.dirname(__file__),'../_pyshare'));
import selfclean_tempfile

sys_codepage = locale.getpreferredencoding(True) 

# configure jpg convert quality 95%, 80%, 60%, 40%, 20% etc
jpg_qualities = [95, 80, 60, 40, 20, 10, 5]
img_variants = 2 + len(jpg_qualities) # 2 is png32 and png8

random_id = ""

def set_new_clipboard(text):
	
	if(type(text)!=type(u'')):
		text = unicode(text, sys_codepage)

	is_ok = False
	try_max = 3
	count = 0
	while(count<try_max):
		try:
			wc.OpenClipboard()
			wc.EmptyClipboard()
			wc.SetClipboardData(wc.CF_UNICODETEXT, text)
			is_ok = True
			break
		except win32api.error:
			pass # exit('Unexpected: Windows clipboard function Fail!') # (not fatal)
		finally:
			try:
				wc.CloseClipboard()
			except:
				pass
		time.sleep(0.1)
		count += 1
	
	if is_ok:
		return True
	else:
		exit('In set_new_clipboard(), tried %d times all failed!'%(try_max))

def set_progress_in_clipboard(now, total, imgw=0, imgh=0, imgspec=None, err_detail=""):
	if not imgspec:
		imgspec = "Null|Null"
		
	if(now==0 and total==0):
		text = "[EverpicDone:0/0]"
	elif(now=='#' and total=='#'):
		text = "[EverpicDone:#/#](%dx%d)%s"%(int(imgw), int(imgh), imgspec)
	else:
		text = "[EverpicDone:%d/%d](%dx%d)%s"%(now, total, int(imgw), int(imgh), imgspec)
		if err_detail:
			text += '\n'+err_detail
		
	set_new_clipboard(text)

def set_progress_fail(err_detail):
	set_progress_in_clipboard(img_variants+1, img_variants, 0,0,0, err_detail)
#	time.sleep(12000) # temp!

def ConvertWithParams(cvtparams):
	argvs = [sys.argv[0]] + shlex.split(cvtparams)
	unicode_info = convert_image_fill_clipboard_main(argvs)
	if not unicode_info:
		return None
	
	info = unicode_info.encode(sys_codepage)
		# `info` should not be unicode because shlex.split() does not like it.
		# The returned `info` will be used later by shlex.split() .
	return info

def GenerateImageListForAutohotkey():
	"""
	For a clipboard 640*480 image, I will generate a tempfile named like
	
		imagelist-20150318xxxxx.(640x480).txt
	
	who has content like(each line called an imgspec):

		PNG,32-bit,88KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20150318_111149.509.png
		PNG,8-bit,42KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20150318_111149.562.png
		JPG,80%,66KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20150318_111149.603.jpg
	
	and place the .txt fullpath into clipboard, so that Autohotkey can open 
	this txt and have user choose a best one to use(paste into Evernote etc).

	On starting, "[EverpicDone:0/8]" is placed into clipboard.
	
	On finishing each image file variant generation, I'll put into clipboard something like 
		
		[EverpicDone:1/8](640x480)PNG,32-bit,88KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20150318_111149.509.png
	 or 
	 	[EverpicDone:2/8](640x480)PNG,8-bit,42KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20150318_111149.562.png
	
	so the autohotkey scripts can know the preview-conversion process.
	
	On .txt generated, I'll put to clipboard : (use the # sign)
	
		[EverpicDone:#/#](640x480)PNG,32-bit,88KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20150318_111149.509.png
	
	-- note: for the #/# case, width, height "fields" should be present as well for Autohotkey easy analyzing.
	
	Special: 
	* When no image file to generate, I'll place "[EverpicDone:0/0]" into clipboard.
	* When fail in the midway, sth like "[EverpicDone:9/8]" is placed(done>total).
	"""
	
	# set_progress_in_clipboard(0, img_variants) # mark start
		# I can't do this, which would otherwise overwrite already-in-clipboard image.
	
	txtdir = tempfile.gettempdir()+os.sep+"Everpic"
	img_done = 0
	try:
		# First, generate a full-color png file from clipboard.
		cvtparams = '-t -n --png=32 --ret-string=%w,%h,%k,%p'
		img_info = ConvertWithParams(cvtparams)
		if not img_info:
			set_progress_in_clipboard(0, 0)
			return None
		
		width, height, png32_kb, png32_path = img_info.split(',')

		png32_info = "PNG(32-bit), %s KB|%s"%(png32_kb, png32_path)
		img_done += 1
		set_progress_in_clipboard(img_done, img_variants, width, height, png32_info)

		# Second, generate each image variant and a text-content list.
		# Now use the explicit png32 file as input.
		
		cvtparams = '-t -n --png=8 --ret-string="PNG(8-bit), %k KB|%p" --input='+'"%s"'%(png32_path)
		png8_info = ConvertWithParams(cvtparams)
		img_done += 1
		set_progress_in_clipboard(img_done, img_variants, width, height, png8_info)
		
		jpg_infos = ''
		for jpgq in jpg_qualities:
			cvtparams = '-t -n --jpg='+str(jpgq)+' --ret-string="JPG('+str(jpgq)+'%), %k KB|%p" --input='+'"%s"'%(png32_path)
			jpg_info = ConvertWithParams(cvtparams)
			jpg_infos += jpg_info + '\n'
			
			img_done += 1
			set_progress_in_clipboard(img_done, img_variants, width, height, jpg_info)
		
		# Third, generate the txt file.
		
		suffix = ".(%sx%s).txt"%(width, height)
		txtpath = selfclean_tempfile.selfclean_create_tempfile(txtdir, "imagelist", suffix)
			# On Windows 7, it is like "c:\users\chj\appdata\local\temp\Everpic\imagelist-20150318_111149.667.(640x480).txt"
		
		with open(txtpath, 'w') as f:
			f.write(png32_info+'\n'+png8_info+'\n')
			f.write(jpg_infos)
		
		txt_info = "TxT|%s"%(txtpath) # purpose: pass txtpath to Autohotkey script
		set_progress_in_clipboard('#', '#', width, height, txt_info)
		
	except OSError:
		exit('Unexpected: GenerateImageListForAutohotkey fails!')
	
	return txtpath


try:
	from everpic import convert_image_fill_clipboard_main

	optlist, arglist = getopt.getopt(sys.argv[1:], '', ['id='])
	optdict = dict(optlist)
	if '--id' in optdict:
		random_id = optdict['--id']

	txtpath = GenerateImageListForAutohotkey()

	print "txtpath=",
	print txtpath
	
except SystemExit as e:
	err_detail = u"! Error from Everpic: " + e.code
	set_progress_fail(err_detail)
	sys.stderr.write(err_detail)
	exit(4) 
except:
	exc_string = traceback.format_exc()
	err_detail = u"Python program error from Everpic. See traceback below:\n" + exc_string
	set_progress_fail(err_detail)
	sys.stderr.write(err_detail)
	exit(1)
	
exit(0)


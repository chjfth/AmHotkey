#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import os
import sys
import re
import time
import locale
import tempfile
import getopt
import win32api
import win32clipboard as wc
import Image
from PIL import ImageGrab
	# Thanks to http://stackoverflow.com/a/7045677/151453 

# sys.path.append( os.path.join(os.path.dirname(__file__),'../_pyshare'));
import selfclean_tempfile

DEFAULT_JPG_QUALITY = 60
NOT_PNG = 0

CB_TEXT = 'text'
CB_HTML = 'html'

CF_HTML = wc.RegisterClipboardFormat("HTML Format")

CF_FileNameW = wc.RegisterClipboardFormat("FileNameW")
	# Ways to get "FileNameW" clipboard format:
	# 1. Copy a file in Windows Explorer.
	# 2. From within a Evernote v5 clip, right click an image, select Copy from context menu.

sys_codepage = locale.getpreferredencoding(True)
g_imghint = "" # example: "PNG(32-bit)"

def MakeUnicodePath(path):
	if type(path)!=unicode:
		path = unicode(path, sys_codepage)
	return path

def GetTempImagePath(ext):
	try:
		imgdir = tempfile.gettempdir()+os.sep+"Everpic"
		
		imgdir = MakeUnicodePath(imgdir)
		
		imgpath = selfclean_tempfile.selfclean_create_tempfile(imgdir, "everpic", ext,
			3*24*3600, # keep temp .jpg/.png for 3 days
			3600       # scan whole directory for cleanup every 3600 seconds
			) # On Windows 7, it is like "c:\users\chj\appdata\local\temp\Everpic\everpic-20150108_203112.440.jpg"
	except OSError:
		exit('Unexpected: Cannot create temporary folder "%s"'%(imgdir))
	return imgpath


def get_image_info(imgpath):
	imgfilesize = os.path.getsize(imgpath)
	if imgfilesize<=0:
		exit('Unexpected: Generate image file "%s" is 0 byte.'%(imgpath))
	kb = imgfilesize/1024
	kb = kb if kb>0 else 1
	
	image = Image.open(imgpath)
	return kb, image.size[0], image.size[1]


html_template = """<html>
~^~<br/>
<img src="%(imgname)s"/>
</html>
"""

cfhtml_template_LF = """Version:0.9
StartHTML:0123456789
EndHTML:0123456789
StartFragment:0123456789
EndFragment:0123456789
SourceURL:file:///everpic
<html>
<body>
<!--StartFragment--><div><img src="http://localhost:2017/Everpic-save/%(imgname)s" alt="max-width:%(imwidth)dpx" /><br>
<span style="font-size: 10px; color: rgb(144,144,144)">
%(imkb)d KB (%(imwidth)d*%(imheight)d),%(imghint)s %(imgname)s [%(imdatetime)s (%(imtimezone)s)]
</span></div>~<!--EndFragment-->
</body>
</html>
"""

def gen_CF_HTML_content(imgpath):
	# Todo: check the case that user name has space and Unicode .
	if type(imgpath)!=unicode:
		exit('Unexpected! gen_CF_HTML_content() is not passed as unicode.')

	imgpath_fs = imgpath.replace('\\', '/')
	imgname = os.path.basename(imgpath) # imgname used by template
	imkb, imwidth, imheight = get_image_info(imgpath)
	imdatetime = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())
	imtimezone = "UTC%+g"%(-time.timezone/3600.0)
	imghint = g_imghint

#	html_content = html_template%locals()
#	open(imgpath_fs+'.html', 'w').write(html_content)
		# Generating the .html file is not a must.

	
	cfhtml_template_CRLF = cfhtml_template_LF.replace("\n", "\r\n")
	cfhtml = cfhtml_template_CRLF%locals()
	
	# Do the following ofsXXX calculation so that LF or CRLF in this py file does not matter.
	ofsStartHTML = cfhtml.find('<html>')
	cfhtml = cfhtml.replace("StartHTML:0123456789", "StartHTML:%010d"%(ofsStartHTML))

	strStartFragment = "<!--StartFragment-->"
	ofsStartFragment = cfhtml.find(strStartFragment) + len(strStartFragment)
	cfhtml = cfhtml.replace("StartFragment:0123456789", "StartFragment:%010d"%(ofsStartFragment))
	
	strEndFragment = "<!--EndFragment-->"
	ofsEndFragment = cfhtml.find(strEndFragment)
	cfhtml = cfhtml.replace("EndFragment:0123456789", "EndFragment:%010d"%(ofsEndFragment))
	
	strHTMLCloseTag = "</html>"
	ofsEndHtml = cfhtml.find(strHTMLCloseTag) + len(strHTMLCloseTag)
	cfhtml = cfhtml.replace("EndHTML:0123456789", "EndHTML:%010d"%(ofsEndHtml))
	
	cfhtml_utf8 = cfhtml.encode('utf8') # type(cfhtml)==unicode
	return cfhtml_utf8
	

def get_image_filepath_from_clipboard():
	try:
		wc.OpenClipboard()
		if wc.IsClipboardFormatAvailable(wc.CF_UNICODETEXT):
			upath_src = wc.GetClipboardData(wc.CF_UNICODETEXT)
				# It seems, with CF_UNICODETEXT, wc.GetClipboardData() returns not the raw bytes
				# from clipboard, but converted to Python 'unicode' type
			upath_src = re.sub(u'\u0000.*$', u'', upath_src, flags=re.DOTALL)
				# because there can be garbage chars after the NUL.
				# [2015-03-18] See my note: https://www.evernote.com/shard/s21/nl/2425275/256a14c6-542c-4e14-8fd8-040c70a4315a
		elif wc.IsClipboardFormatAvailable(CF_FileNameW):
			u16str = wc.GetClipboardData(CF_FileNameW)
			upath_src = unicode(u16str, 'utf-16LE')
			upath_src = upath_src.strip(u'\x00') # because there is a trailing NUL char
		elif wc.IsClipboardFormatAvailable(wc.CF_HDROP):
			# Using Everything 1.3.4.686, copying a single file generates a CF_HDROP content with one file in list,
			# so cope with this case.
			filelist = wc.GetClipboardData(wc.CF_HDROP)
			upath_src = filelist[0] # only get the first one, already a unicode string
		else:
			return None

		if len(upath_src)>1024:
			return None
		
		if (upath_src[0].islower() or upath_src[0].isupper()) and (upath_src[1:3]==':\\'):
			pass # looks like a fullpath
		else:
			return None
		
		# todo: May be more "filepath conformance" check
		
	except win32api.error:
		exit('Unexpected: Windows clipboard function Fail!')
	finally:
		wc.CloseClipboard()
	return upath_src

def put_new_clipboard(imgpath, text_or_html):
	# imgpath: The newly generated image's fullpath

	try:
		wc.OpenClipboard()
		wc.EmptyClipboard()
		
		if text_or_html==CB_HTML:
			cfhtml = gen_CF_HTML_content(imgpath)
			wc.SetClipboardData(CF_HTML, cfhtml)
		else: # take it as CB_TEXT
			wc.SetClipboardData(wc.CF_UNICODETEXT, imgpath)
		
	except win32api.error:
		exit('Unexpected: Windows clipboard function Fail!')
	finally:
		wc.CloseClipboard()

def IsFileReadable(inputfile):
	try:
		with open(inputfile) as f:
			return True
	except IOError:
		return False

def convert_image(inputfile, text_or_html, force_temp_jpg, 
	png_bits, jpg_quality, ret_fmt=None, update_clipboard=True):
	"""
	inputfile:
		If None, use clipboard image/filepath ; otherwise, use that inputfile.
	
	text_or_html: 
		* CB_HTML: Generate CF_HTML in clipboard whose content refers to the generated jpg file.
		  You can then Ctrl+V to paste that jpg image into Evernote.
		* CB_TEXT: Generate CF_UNICODETEXT in clipboard, the text is the full path to the
		  generated jpg file. You can then use Evernote right-click menu item "Attach Files..." 
		  to insert the jpg image.

	force_temp_jpg:
		* When existing clipboard format is CF_DIB, this param is ignored, that is, 
		  jpg file is always generated in temp dir.
		* When existing clipboard contains an image file path(foo.png), this param takes effect:
		  If True:  Generate the jpg file in temp dir.
		  If False: Generate the jpg file side-by-side with the existing image file.

	ret_fmt:
		If not null, the text written to stdout will be formated as specified.
		%w : image width in pixels
		%h : image height in pixels
		%k : image file size in KB
		%p : image file path
		For example:
			"%wx%h,%kK,%p"
		will result in something like:
			640x480,23K,C:\temp\20150316202122.jpg
	
	return None is nothing to convert(no image/image-file in clipboard).
	return a string on success(some image file generated).
	Raise exception on error.
	
	"""
	
	explicit_input = inputfile
	
	# INPUT(3 cases) -> Image object -> OUTPUT(file and/or clipboard content) 
	try:
		if inputfile:
			im = Image.open(inputfile)
		else: # get input from clipboard
			im = ImageGrab.grabclipboard()
			if not im:
				# Check clipboard for image file path
				inputfile = get_image_filepath_from_clipboard()
				if not inputfile:
					return None
				else:
					im = Image.open(inputfile)
		
		#
		# Now apply conversion on `im`.
		#
		
		# determine output format
		if png_bits!=0:
			out_ext = '.png'
			is_png = True
			out_mode = 'P' if png_bits==8 else 'RGB' # P means palette mode.
		else:
			out_ext = '.jpg'
			is_png = False
			out_mode = 'RGB'
		
		# determine output image path(outpath)
		if inputfile and not force_temp_jpg:
			outpath = inputfile + out_ext 
				# Append extname instead of replacing, to avoid overwrite input file.
		else:
			outpath = GetTempImagePath(out_ext)

	except IOError: 
		# Raised by Image.open() when the path is not a image file.
		# for PIL. Sigh, PIL does not provide finer exception type.
		#
		#	raise IOError("cannot identify image file") ; from Image.py
		#
		# So we try to open the file ourself, it open success, we consider it a non-image file, 
		# and consider this case as if clipboard is empty.
		if explicit_input or not IsFileReadable(inputfile):
			exit('Cannot open input image file: "%s"\n'%(inputfile))
		else:
			return None
	#except StandardError: # need this?
	#	exit('Unexpected: Generate temporary file "%s" fail!'%(outpath))
	
	#
	# Do actual conversion on `im`.
	#
	
	try:
		im = im.convert('RGB') # converting from '.gif' requires this
		if out_mode=='P':
			im = im.convert('P', palette=Image.ADAPTIVE, colors=256) # 8-bit png
		
		if is_png:
			im.save(outpath, 'PNG')
		else:
			im.save(outpath, 'JPEG', quality=jpg_quality)
	except IOError as e:
		# This IOError is considered fatal.
		exit('Unexpected: Fail to save "%s".\n%s'%(outpath, e.message))

	return put_image_to_clipboard(outpath, text_or_html, ret_fmt, update_clipboard)


def put_image_to_clipboard(imgpath, text_or_html, ret_fmt, update_clipboard):
	try:
		kb, width, height = get_image_info(imgpath)
	except OSError as e: 
		# Raised by get_image_info(), when imgpath open fails.
		exit('Unexpected: Reading just generated "%s" fails!\n%s'%(imgpath. e.message))

	if update_clipboard:
		put_new_clipboard(imgpath, text_or_html)
	
	if(ret_fmt):
		ret_string = ret_fmt
		ret_string = ret_string.replace("%w", "%d"%width)
		ret_string = ret_string.replace("%h", "%d"%height)
		filesize = os.path.getsize(imgpath)
		ret_string = ret_string.replace("%k", "%d"%kb)
		ret_string = ret_string.replace("%p", imgpath)
	else:
		if text_or_html==CB_HTML:
			ret_string = "%d KB(%d*%d) image generated in CF_HTML clipboard."%(kb, width, height)
		else: # take it as CB_TEXT
			ret_string = "%d KB(%d*%d) image generated in:\n%s."%(kb, width, height, imgpath)
		
	return ret_string


def convert_image_fill_clipboard_main(sys_argv):
	optlist, arglist = getopt.getopt(sys_argv[1:], 'hptn', ['input=','png=','jpg=','ret-string=','hint='])
	optdict = dict(optlist)
	if '-h' in optdict:
		text_or_html = CB_HTML # -h: output CF_HTML format in clipboard referencing a image file on disk
	elif '-p' in optdict:
		text_or_html = CB_TEXT # -p: output path text in clipboard
	else:
		text_or_html = CB_HTML
	
	if '--ret-string' in optdict:
		ret_fmt = optdict['--ret-string']
	else:
		ret_fmt = None
	
	if '-n' in optdict:
		update_clipboard = False
	else:
		update_clipboard = True
	
	png_bits = NOT_PNG # so default is jpg
	jpg_quality = DEFAULT_JPG_QUALITY
	is_direct = False
	if '--png' in optdict:   # request generating png 
		png_bits = int(optdict['--png']) # 8 or 32
	elif '--jpg' in optdict: # request generating jpg 
		jpg_quality = int(optdict['--jpg'])

	inputfile = None
	if '--input' in optdict:
		inputfile = MakeUnicodePath(optdict['--input'])
		if (not '--png' in optdict) and (not '--jpg' in optdict):
			is_direct = True
	
	global g_imghint
	if '--hint' in optdict:
		g_imghint = ' '+optdict['--hint']+','

	save_as_temp = True if '-t' in optdict else False

	if(is_direct):
		ret = put_image_to_clipboard(inputfile, text_or_html, ret_fmt, update_clipboard)
	else:
		ret = convert_image(inputfile, text_or_html, save_as_temp, 
			png_bits, jpg_quality, ret_fmt, update_clipboard)
			
	return ret


if __name__=="__main__":
	try:
		info = convert_image_fill_clipboard_main(sys.argv)
	except SystemExit as e:
		print e.code
		print "Fail!"
		exit(1)

	if info:
		# On success, you can Ctrl+V to paste that image into Evernote(using 5.8.1 today)
		print info
	else:
		print "No bitmap content in clipboard yet."
	
	exit(0)


"""
If you want to convert an existing myfile.jpg to CF_HTML clipboard content, use

	everpic.py --input=myfile.jpg

	everpic.py --input=myfile.jpg --png=8

	everpic.py --input=myfile.jpg --png=8 -t

If you want to convert an existing image file to some other format with side-by-side output:

	everpic.py --input=input.png --png=8 -p

"-p" means "need picture only(not CF_HTML)", and the output image fullpath will be 
stored in clipboard.

[2015-03-26] IMPORTANT USAGE HINT:
To ensure paste-into-Evernote (5.8.x today) success, you have to ensure the temp-dir
( e.g. c:\users\chj\appdata\local\temp\Everpic ) is Evernote.exe's current working dir.
You can verify this from ProcessExplorer. So my suggesting is:
1. Update Evernote Windows shortcut(.lnk)'s start-up director to your temp-dir.
2. Avoid using Evernote's Attach Files... function, which will change its working-dir.
My own MEMO:
https://www.evernote.com/shard/s21/nl/2425275/dc03d51f-64c5-432d-8e2b-84369487ff7c
"""

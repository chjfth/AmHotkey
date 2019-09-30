#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, traceback
import win32gui
import win32con

sys.path.append( os.path.join(os.path.dirname(__file__),'../_pyshare'));

# Note: I use exit(4) when I detect explicit error in this .pyw.
# I avoid using exit(1) because I leave exit-code 1 to uncaught error.
# That is, if pywin32 is not available(``import win32gui`` fails), this program returns 1.
# When I use Autohotkey to launch this .pyw and it fails right on ``import win32gui``, 
# this .pyw will not have a user interface to show an error message. 
# So, with and only with an explict exit-code 1, Autohotkey can alert such error with a MsgBox.

try:
	from everpic import convert_image_fill_clipboard_main
	from systray_tooltip import balloon_tip
	
	info = convert_image_fill_clipboard_main(sys.argv)
	
except SystemExit as e:
	balloon_tip(u"! Error from Everpic", e.code, 10)
	exit(4) 
except:
	exc_string = traceback.format_exc()
	win32gui.MessageBox(0, 
		exc_string, 
		u"Python program error from Everpic",
		win32con.MB_OK | win32con.MB_ICONSTOP)
	exit(4)
	

# On success, you can Ctrl+V to paste that image into Evernote(using 5.8.1 today)
if info:
	balloon_tip("Info from Everpic", info, 5)
else:
	balloon_tip("No bitmap in clipboard yet.", " ", 3)
exit(0)


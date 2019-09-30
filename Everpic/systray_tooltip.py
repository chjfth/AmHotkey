#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Thanks to http://stackoverflow.com/a/15921588/151453

from win32api import *
from win32gui import *
import win32con
import sys, os
import struct
import time
import locale

class WindowsBalloonTip:
    def __init__(self, title, msg, duration_seconds):
        message_map = {
                win32con.WM_DESTROY: self.OnDestroy,
        }
        # Register the Window class.
        wc = WNDCLASS()
        hinst = wc.hInstance = GetModuleHandle(None)
        wc.lpszClassName = "PythonTaskbar"
        wc.lpfnWndProc = message_map # could also specify a wndproc.
        classAtom = RegisterClass(wc)
        # Create the Window.
        style = win32con.WS_OVERLAPPED | win32con.WS_SYSMENU
        self.hwnd = CreateWindow( classAtom, "Taskbar", style, \
                0, 0, win32con.CW_USEDEFAULT, win32con.CW_USEDEFAULT, \
                0, 0, hinst, None)
        UpdateWindow(self.hwnd)
        iconPathName = os.path.abspath(os.path.join( sys.path[0], "python2.ico" ))
        icon_flags = win32con.LR_LOADFROMFILE | win32con.LR_DEFAULTSIZE
        try:
           hicon = LoadImage(hinst, iconPathName, \
                    win32con.IMAGE_ICON, 0, 0, icon_flags)
        except:
          hicon = LoadIcon(0, win32con.IDI_APPLICATION)
        flags = NIF_ICON | NIF_MESSAGE | NIF_TIP
        nid = (self.hwnd, 0, flags, win32con.WM_USER+20, hicon, "tooltip")
        Shell_NotifyIcon(NIM_ADD, nid)
        Shell_NotifyIcon(NIM_MODIFY, \
                         (self.hwnd, 0, NIF_INFO, win32con.WM_USER+20,\
                          hicon, "Balloon TOOLtip",msg ,200,title))
        #print "======"+sys.argv[1]
        # self.show_balloon(title, msg) #wrong
        time.sleep(duration_seconds)
        DestroyWindow(self.hwnd)
    
    def OnDestroy(self, hwnd, msg, wparam, lparam):
        nid = (self.hwnd, 0)
        Shell_NotifyIcon(NIM_DELETE, nid)
        PostQuitMessage(0) # Terminate the app.

def balloon_tip(title, msg, duration_seconds=3):
    w=WindowsBalloonTip(title, msg, duration_seconds)

if __name__ == '__main__':
	sysencoding = locale.getpreferredencoding(True) # Good
	titlex = u''
	if len(sys.argv)>1:
		titlex = unicode(sys.argv[1], sysencoding)
	
	balloon_tip(
		u"★ Title for popup"+titlex, 
		u"☆ This is the popup's message"
		)

                 AmHotkey: Modularized Autohotkey scripts
=============================================================================

==== QUICK START ====

These scripts have been verifed with Autohotkey 1.1.24, and new versions should be OK as well.

First, you need to grab a Unicode version of Autohotkey executable(AutoHotkeyU32.exe or AutoHotkeyU64.exe) and place the EXE file in this directory. (download from http://www.autohotkey.com)

Second, Run AutoHotkeyU32.exe with AmHotkey.ahk as parameter. For example:

	D:\AmHotkey\AutoHotkeyU32.exe D:\AmHotkey\AmHotkey.ahk

( I suggest creating a Explorer shortcut(.lnk) for easier launching of above command. )

Now, you should see a dialog box pops up saying hotkeys defined in various ahk modules are active.

Third, to add more hotkeys, you can do either:

* Add them in customize.ahk. You make a copy of customize.ahk.sample with the name customize.ahk, and add new hotkeys at *end* of that file. This is convenient to test trivial hotkeys.
* Write a new "module" as foobar.ahk, and add foobar.ahk to _more_includes_.ahk . This is a good way to share your hotkey modules(named foobar) to others.

Useful hint: After adding/changing new hotkeys in customize.ahk or foobar.ahk, press Win+Alt+R to have them take effect. This has the same result as right-click Autohotkey taskbar tray icon and execute "Reload this Script" menu item.


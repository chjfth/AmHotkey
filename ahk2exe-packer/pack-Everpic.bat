@echo off
@setlocal EnableDelayedExpansion
set batfilenam=%~n0%~x0
set batdir=%~dp0
set batdir=%batdir:~0,-1%

call :EchoAndExec "%batdir%\..\AutoHotkeyU32.exe" "%batdir%\packer.ahk" Everpic

exit /b %ERRORLEVEL%


REM =============================
REM ====== Functions Below ======
REM =============================

:Echos
  REM This function preserves %ERRORLEVEL% for the caller,
  REM and, LastError does NOT pollute the caller.
  setlocal & set LastError=%ERRORLEVEL%
  echo [%batfilenam%] %*
exit /b %LastError%

:EchoAndExec
  echo [%batfilenam%] EXEC: %*
  call %*
exit /b %ERRORLEVEL%

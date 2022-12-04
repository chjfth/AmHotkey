@echo off
setlocal EnableDelayedExpansion
set batfilenam=%~n0%~x0
set batdir=%~dp0
set batdir=%batdir:~0,-1%

PATH=%batdir%;%PATH%

REM This .bat converts a input image file into a series
REM of png and jpg files with various pre-defined image-quality.
REM After each converted file-output, this bat will regenerate a file named
REM <prefix>.progress.done.txt, to indicate overall converting progress,
REM so that the AHK program can report progress on user interface.
REM 
REM Usage:
REM 	prepare.bat foo.bmp
REM
REM This will generate output files:
REM 	foo.imagelist.txt
REM 	foo.progress.done.txt
REM 	foo.8bit.png
REM 	foo.5bit.png
REM 	foo.q95.jpg
REM 	foo.q80.jpg
REM 	foo.q60.jpg
REM 	...

set fpinput=%~1

if not defined fpinput (
	call :Echos No image filename input.
	exit /b 4
)

REM Strip .extname from fpinput, assign to fpPrefix
for %%A in ("%fpinput%") do (
	set fpPrefix=%%~dpA%%~nA
)

set fpImageList=%fpPrefix%.imagelist.txt
echo.> "%fpImageList%"

set fpProgressDone=%fpPrefix%.progress.done.txt
echo.> "%fpProgressDone%"

REM 
set pngCfgs=8bit#256 5bit#32 3bit#8
REM
set jpgQuals=95 80 60 40 20 10

REM Count total cfgs
call :cfgcount %pngCfgs%
set totalcfgs=%ERRORLEVEL%
call :cfgcount %jpgQuals%
set /a totalcfgs=%totalcfgs%+%ERRORLEVEL%

set donecfgs=0


for %%A in (%pngCfgs%) do (

	call :cfgsplit %%A middle colors
	rem	call :Echos [!middle!] [!colors!]
	
	set fpoutput=%fpPrefix%.!middle!.png
	call :EchoAndExec pngquant.exe !colors! --force --output "!fpoutput!" -- "%fpinput%"
	if errorlevel 1 exit /b 4
	
	call :getfilesize_KB filekb "!fpoutput!"
	
	set stageline=PNG ^(!colors! colors^),!filekb!KB,!fpoutput!
	
	echo !stageline!
	echo !stageline!>> "%fpImageList%"
	
	set /a donecfgs=!donecfgs!+1
	echo !donecfgs!/%totalcfgs%> "%fpProgressDone%"
)

set pctchar=%
for %%A in (%jpgQuals%) do (

	set fpoutput=%fpPrefix%.q%%A.jpg
	call :EchoAndExec cjpeg-static.exe -quality %%A -outfile "!fpoutput!" "%fpinput%"
	if errorlevel 1 exit /b 4

	call :getfilesize_KB filekb "!fpoutput!"
	
	set stageline=JPG ^(%%A%% quality^),!filekb!KB,!fpoutput!
	echo !stageline!
	echo !stageline!>> "%fpImageList%"
	
	set /a donecfgs=!donecfgs!+1
	echo !donecfgs!/%totalcfgs%> "%fpProgressDone%"
)


call :Echos fpPrefix=%fpPrefix%



exit /b %ERRORLEVEL%



REM =============================
REM ====== Functions Below ======
REM =============================


:Echos
  REM This function preserves %ERRORLEVEL% for the caller,
  REM and, LastError does NOT pollute the caller.
  setlocal & set LastError=%ERRORLEVEL%
  echo %_vspgINDENTS%[%batfilenam%] %*
exit /b %LastError%

:EchoAndExec
  echo %_vspgINDENTS%[%batfilenam%] EXEC: %*
  call %*
exit /b %ERRORLEVEL%

:EchoVar
  setlocal & set Varname=%~1
  call echo %_vspgINDENTS%[%batfilenam%]%~2 %Varname% = %%%Varname%%%
exit /b 0

:SetErrorlevel
  REM Usage example:
  REM call :SetErrorlevel 4
exit /b %1

REM ====

:getfilesize_KB
REM Usage:
REM 	call :getfilesize_KB filekb d:\test\foo.png
REM Assume foo.png is 33000 bytes.
REM Output:
REM 	filekb=33
  setlocal
  set filepath=%~2
  for %%A in ("%filepath%") do (
    set filesize=%%~zA
  )
  endlocal & (
    set /a "%~1=%filesize%/1000"
  )
exit /b 0

:cfgsplit
REM Usage:
REM 	call :cfgsplit 32bit#"-quality 95" token1 token2
REM Output:
REM 	token1=32bit
REM 	token2="-quality 95"
  setlocal
  set param=%1
  set param=%param:#= %
  set i=1
  for %%p in (%param%) do (
    set token!i!=%%p
    set /a i=i+1
  )
  endlocal & (
    set "%~2=%token1%"
    set "%~3=%token2%"
  )
exit /b 0

:cfgcount
REM Usage:
REM 	call :cfgcount 95 80 60 "one token"
REM Output:
REM 	ERRORLEVEL=4
  setlocal
  set params=%*
  set i=0
  for %%p in (%params%) do (
    set /a i=i+1
  )
exit /b %i%



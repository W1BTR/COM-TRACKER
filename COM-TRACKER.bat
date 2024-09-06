@echo off
mode con: cols=49 lines=30
title W1BTR COM Tracker
setlocal EnableDelayedExpansion
echo Loading . . .
call Bin\CMDS.bat /ts "Prog Assistant COM Companion"
if !errorlevel!==1 cscript //B //Nologo "Bin\CMS.vbs"
goto COMS

:COMS
set check=30
set selectedPort=1
:COMLoop
set num=0
set linecount=0
cls
if not exist "Bin\COMLOG.log" goto :loadCOMLOG
echo [0;96m=================================================[0;7m
if exist Bin\logo.ascii (
    type Bin\logo.ascii
	echo.
)
echo [0;96m=================================================[0m
echo.
echo COM PORTS:
for /f "tokens=1,2,3 delims=, skip=1" %%A in ('type "Bin\COMLOG.log"') do (
	set /a linecount+=1
	set /a num+=1
	set COMPort!num!=%%~A
	set descrp=%%~B
	if "!num!"=="!SelectedPort!" (
		set comcolor=[7m
	) ELSE (
		set comcolor=
	)
	if "%%~C"=="True" (
		echo !comcolor![92m%%~A [0m!comcolor!!descrp:~0,38! [90mNEW[0m
	) ELSE (
		echo !comcolor![96m%%~A  [0m!comcolor!!descrp:~0,38![0m
	)
)
copy /y "Bin\COMLOG.log" "Bin\COMLog.diff" >nul 2>nul
set check=30
:comKBDLoop
"Bin\Kbd.exe" 1
set /a check-=1
if %check%==0 (
	fc "Bin\COMLOG.diff" "Bin\ComLog.log" >nul 2>nul
	if !errorlevel!==1 goto COMLoop
	set check=30
	goto comKBDLoop
)
if %errorlevel%==0 goto comKBDLoop
if %errorlevel%==61 start "" "%~0"
if %errorlevel%==62 goto COMS
if %errorlevel%==68 exit /b
set _errorlevel=%errorlevel%
rem if %_errorlevel%==59 goto options
if %_errorlevel%==80 (
	if not !SelectedPort! GEQ !linecount! (
		set /a SelectedPort+=1
	)
)
if %_errorlevel%==72 (
	if not !SelectedPort! LEQ 1 (
		set /a SelectedPort-=1
	)
)
if %_errorlevel%==13 goto SelectedCOM
goto comloop

:loadCOMLOG
echo Loading . . .
:loadcomlogloop
if not exist "Bin\COMLOG.log"  goto loadcomlogloop
goto comloop

:SelectedCOM
cls
mode !COMPort%SelectedPort%! | more
mode !COMPort%SelectedPort%! | find /i "Not Available" >nul 2>nul
if %errorlevel%==1 (
	echo 1] Change Setting [Baud, Parity, XON, etc]
	echo 2] Enter Text Data into Port
	echo 3] View Text Output
	echo 4] Start a Putty Session
	echo 5] Open Putty
	echo 6] Pipe to Virtual Port [For Hypervisor]
	echo X] Back
) ELSE (
	echo X] Back
)
choice /c 123456X /n

if %errorlevel%==4 (
	putty -serial !COMPort%SelectedPort%!
	goto selectedcom
)
if %errorlevel%==5 (
	putty -serial
	goto selectedcom
)
if %errorlevel%==1 goto comsetting
if %errorlevel%==2 goto DataPort
if %errorlevel%==3 goto TypePort
if %errorlevel%==6 goto passthrough
goto COMS

:passthrough
if "%baudrate%"=="" set baudrate=19200
if "%PipeName%"=="" set PipeName=MyLittlePipe
cls
echo COM PIPE [howardtechnical.com] !COMPort%SelectedPort%!
echo [90mNOTE: This tool cannot create a named pipe,
echo it can only use an existing named pipe otherwise
echo a GLE error will occur.[0m
echo.
echo 1] Change Baud Rate [[96m%baudrate%[0m]
echo 2] Change Pipe Name [[90m\\.\pipe\[96m%PipeName%[0m\]
echo 3] [92mSTART PIPE[0m
echo X] Cancel
choice /c 123x
if %errorlevel%==1 (
	echo.
	echo Enter BAUD RATE:
	set /p baudrate=">"
	goto passthrough
)
if %errorlevel%==2 (
	echo.
	echo Enter Pipe Name:
	set /p PipeName="[90m\\.\pipe\[0m"
	goto passthrough
)
if %errorlevel%==3 (
	echo set cd=%cd% >"%temp%\PASCD.cmd
	echo set Port=!COMPort%SelectedPort%! >>"%temp%\PASCD.cmd
	echo set name=\\.\pipe\%PipeName% >>"%temp%\PASCD.cmd
	echo set baudrate=%baudrate% >>"%temp%\PASCD.cmd
	powershell start -verb runas 'Bin\Piper.bat'
	pause
	goto SelectedCOM
)
goto SelectedCOM

:DataPort
echo Enter data to enter to port
set /p comcommand="!COMPort%SelectedPort%!>"
echo %comcommand%>!COMPort%SelectedPort%!
timeout /t 1 /nobreak >nul
goto selectedcom

:typeport
start "" "Bin\ViewCOM.bat" !COMPort%SelectedPort%!
goto selectedcom

:comsetting
echo Enter setting type followed by and equal
echo sign and it's value for example: BAUD=1200
echo Available Settings are:[90m
echo [BAUD=b] [PARITY=p] [DATA=d] [STOP=s]
echo [to=on|off] [xon=on|off] [odsr=on|off]
echo [octs=on|off] [dtr=on|off|hs]
echo [rts=on|off|hs|tg] [idsr=on|off][0m
echo Or enter X to cancel
set /p modecommand="!COMPort%SelectedPort%!>"
if /i "%modecommand%"=="X" goto SelectedCOM
mode %modecommand%
goto SelectedCOM
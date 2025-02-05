
REM :: Marius Negrutiu (marius.negrutiu@protonmail.com)

@echo off

title %~nx0
set FLAGS_BUILD=%~dp0\flag-build-nsis
set FLAGS_ERROR=%~dp0\flag-error-nsis

cd /d "%~dp0"

:: Extract current GIT branch
set BRANCH=
for /f "usebackq delims=@ " %%f in (`git rev-parse --abbrev-ref HEAD`) do set BRANCH=%%f
if "%BRANCH%" equ "" echo ERROR: Can't extract GIT branch name && exit /B 2
if "%BRANCH%" equ "master" set BRANCH=negrutiu

:: ----------------------------------------------------------------
:PARAMETERS
:: ----------------------------------------------------------------
if /I "%1" neq "/compile-x86" goto :COMPILE_X86_END
	set CONFIG_ARCH=x86&& set CONFIG_ACTIONS=install-compiler install-stubs install-plugins install-utils
	goto :BUILD
:COMPILE_X86_END

if /I "%1" neq "/compile-amd64" goto :COMPILE_AMD64_END
	set CONFIG_ARCH=amd64&& set CONFIG_ACTIONS=install-compiler install-stubs install-plugins install-utils
	goto :BUILD
:COMPILE_AMD64_END

if /I "%1" neq "/distro-x86" goto :DISTRO_X86_END
	set CONFIG_ARCH=x86&& set CONFIG_ACTIONS=dist-installer
	goto :BUILD
:DISTRO_X86_END

if /I "%1" neq "/distro-amd64" goto :DISTRO_AMD64_END
	set CONFIG_ARCH=amd64&& set CONFIG_ACTIONS=dist-installer
	goto :BUILD
:DISTRO_AMD64_END

:: Unknown argument?
if "%1" neq "" echo ERROR: Unknown argument "%1" && pause && exit /B 57


:: ----------------------------------------------------------------
:MAIN
:: ----------------------------------------------------------------
if exist "Contrib\NScurl" (
	echo ----------------------------------------------------------------
	call Contrib\NScurl\_acquire_curl-ca-bundle.bat
	call Contrib\NScurl\_acquire_libcurl-devel.bat
)

echo Compiling...
start "" "%COMSPEC%" /C "%~f0" /compile-x86
start "" "%COMSPEC%" /C "%~f0" /compile-amd64
call :WAIT
if %errorlevel% neq 0 exit /B %errorlevel%


echo Building installers...
start "" "%COMSPEC%" /C "%~f0" /distro-x86
start "" "%COMSPEC%" /C "%~f0" /distro-amd64
call :WAIT
if %errorlevel% neq 0 exit /B %errorlevel%

:: NOTE: .instdist is recreated after each build
echo Moving files around...
cd /d "%~dp0"
call :COPYFILES nsis-mingw-%BRANCH%-x86   nsis-mingw-%BRANCH%-amd64
call :COPYFILES nsis-mingw-%BRANCH%-amd64 nsis-mingw-%BRANCH%-x86

:: Finish
REM pause
exit /B 0


:COPYFILES
set dir1=%~1
set dir2=%~2
if not exist %dir1% exit /B 2
if not exist %dir2% exit /B 2

xcopy %dir1%\.instdist\Plugins\x86-ansi        %dir2%\.instdist\Plugins\x86-ansi      /DEIY
xcopy %dir1%\.instdist\Plugins\x86-unicode     %dir2%\.instdist\Plugins\x86-unicode   /DEIY
xcopy %dir1%\.instdist\Plugins\amd64-unicode   %dir2%\.instdist\Plugins\amd64-unicode /DEIY

xcopy %dir1%\.instdist\Stubs\*-x86-ansi        %dir2%\.instdist\Stubs\ /DY
xcopy %dir1%\.instdist\Stubs\*-x86-unicode     %dir2%\.instdist\Stubs\ /DY
xcopy %dir1%\.instdist\Stubs\*-amd64-unicode   %dir2%\.instdist\Stubs\ /DY

xcopy %dir1%\.instdist\Bin\RegTool-x86.bin     %dir2%\.instdist\Bin\ /DY
xcopy %dir1%\.instdist\Bin\RegTool-amd64.bin   %dir2%\.instdist\Bin\ /DY
exit /B 0


:: ----------------------------------------------------------------
:WAIT
:: ----------------------------------------------------------------
del /Q "%FLAGS_BUILD%-*" 2> NUL
del /Q "%FLAGS_ERROR%-*" 2> NUL

timeout /T 2 /NOBREAK > NUL
:WAIT_LOOP
	if not exist "%FLAGS_BUILD%-*" goto :WAIT_END
	timeout /T 1 /NOBREAK > NUL
	goto :WAIT_LOOP
:WAIT_END
if exist "%FLAGS_ERROR%-*" exit /B 666
exit /B %errorlevel%


::---------------------------------
:BUILD
::---------------------------------
set FLAG_BUILD=%FLAGS_BUILD%-%CONFIG_ARCH%
set FLAG_ERROR=%FLAGS_ERROR%-%CONFIG_ARCH%
echo Building> "%FLAG_BUILD%"
cd /d "%~dp0"

:: e.g. "nsis-mingw-amd64"
set DISTRO=nsis-mingw-%BRANCH%-%CONFIG_ARCH%
title %DISTRO%: %CONFIG_ACTIONS%


call _config.bat
if %errorlevel% neq 0 echo Aborted. && pause && exit /B %errorlevel%
set PATH=%MINGW%\bin;%PATH%;%HTMLHELP_PATH%


:: Extract SVN revision number from GIT commit message
:: e.g. Extract 7012 from "git-svn-id: https://svn.code.sf.net/p/nsis/code/NSIS/trunk@7012 212acab6-be3b-0410-9dea-997c60f758d6"
set VER_REVISION=0
for /f "usebackq tokens=3 delims=@ " %%f in (`git log --grep=git-svn-id: -1 ^| find "trunk@"`) do set VER_REVISION=%%f
if "%VER_REVISION%" equ "0" echo. && set EXITCODE=3 && echo ERROR: Can't extract the last SVN revision number && goto :BUILD_END

set VER_MAJOR=3
set VER_MINOR=9
set VER_BUILD=0

for /f "usebackq" %%f in (`cscript.exe //nologo "%~dp0\DecToHex.vbs" %VER_MAJOR% 2`) do set VER_MAJOR_PACKED=%%f
for /f "usebackq" %%f in (`cscript.exe //nologo "%~dp0\DecToHex.vbs" %VER_MINOR% 3`) do set VER_MINOR_PACKED=%%f
for /f "usebackq" %%f in (`cscript.exe //nologo "%~dp0\DecToHex.vbs" %VER_BUILD% 1`) do set VER_BUILD_PACKED=%%f
set VER_PACKED=0x%VER_MAJOR_PACKED%%VER_MINOR_PACKED%00%VER_BUILD_PACKED%

:: "nsis" -> "nsis-mingw-DISTRO-[arch]"
cd /d "%~dp0"
robocopy . %DISTRO%\ *.* /E /XO /XD .git nsis-* zlib-* libcurl-devel* Debug-* Release-* ... /XF flag-* .git* _*.bat *.7z ... /NJH /NJS /NDL /XJ
if exist Contrib\NScurl (
	rmdir %DISTRO%\Contrib\NScurl\libcurl-devel > NUL 2> NUL
	mklink /J %DISTRO%\Contrib\NScurl\libcurl-devel Contrib\NScurl\libcurl-devel
)

:: Build
echo.
cd /d "%~dp0\%DISTRO%"
call "%PYTHON_PATH%\Scripts\scons" ^
	TOOLSET=gcc,gnulink,mingw ^
	NSIS_SCONS_GNU_ENVPATHHACK=1 ^
	PATH="%MINGW%/bin" ^
	TARGET_ARCH=%CONFIG_ARCH% ^
	DISTNAME="%BRANCH%" ^
	VERSION=%VER_MAJOR%.%VER_MINOR%.%VER_REVISION%.%VER_BUILD% ^
	VER_MAJOR=%VER_MAJOR% VER_MINOR=%VER_MINOR% VER_REVISION=%VER_REVISION% VER_BUILD=%VER_BUILD% ^
	VER_PACKED=%VER_PACKED% ^
	NSIS_CONFIG_LOG=yes ^
	NSIS_CONFIG_LOG_TIMESTAMP=yes ^
	NSIS_MAX_STRLEN=4096 ^
	NSIS_EXTRA_PARAM="/DLINK_INFO=https://github.com/negrutiu/nsis /DNSIS_BIN2=..\..\..\nsis-mingw-%BRANCH%-x86\BIN /DNSIS_BIN3=..\..\..\nsis-mingw-%BRANCH%-amd64\BIN /DVER_PRODUCTNAME=""Unofficial NSIS build by Marius Negrutiu"" /DVER_LEGALTRADEMARKS=https://github.com/negrutiu/nsis /DEXTRA_WELCOME_TEXT=""$\r$\n$\r$\n$\r$\n(*) This is an unofficial build from https://github.com/negrutiu/nsis$\r$\n""" ^
	PREFIX="%CD%\BIN" ^
	ZLIB_W32="%ZLIB_PATH%-mingw-%CONFIG_ARCH%" ^
	STRIP=1 ^
	APPEND_CCFLAGS="%CONFIG_CFLAGS%" ^
	APPEND_LINKFLAGS="%CONFIG_CFLAGS% %CONFIG_LFLAGS%" ^
	%CONFIG_ACTIONS%
set EXITCODE=%errorlevel%

:BUILD_END
if %EXITCODE% neq 0 echo %EXITCODE% > "%FLAG_ERROR%" && pause
REM pause
del "%FLAG_BUILD%"
exit /B %EXITCODE%

@   echo off

:main /? | [/v] [/clean] | [/prefix directory]

:: = DESCRIPTION
:: =   Configures !cfg_PACKAGE!.
:: =
:: = OPTIONS
:: =   /v        Be verbose. Repeat for extra verbosity.
:: =   /clean    Remove files generated by !PROG_NAME!.
:: =   /prefix   Name of directory to install !cfg_PACKAGE! in.
:: =             Default is !prefix!.

:: @author Jan Bruun Andersen
:: @version @(#) Version: 2015-12-07

    verify 2>NUL: other
    setlocal EnableExtensions
    if ErrorLevel 1 (
	echo Error - Unable to enable extensions.
	goto :EOF
    )

    if /i "%~1" == "/trace" shift & prompt $G$G & echo on

:defaults
    set "PROG_FULL=%~f0"    & rem PROG_FULL needs to be set here since we will
			      rem clobber %0 as part of the options processing.

    set "show_help=false"
    set "verbosity=0"
    set "prefix=%UserProfile%\LocalTools\cmd-lib.lib"
    set "cmdlib=src\lib"
    set "action=configure"

    if exist "configure.dat" call :read_cfg "configure.dat"

:getopts
    if /i "%~1" == "/?"		set "show_help=true"	& shift		& goto :getopts

    if /i "%~1" == "/v"		set /a "verbosity+=1"	& shift		& goto :getopts
    if /i "%~1" == "/clean"	set "action=clean"	& shift		& goto :getopts
    if /i "%~1" == "/prefix"	set "prefix=%~2"	& shift & shift	& goto :getopts

    rem cl_init needs to be here, after setting cmdlib.
    for %%F in (cl_init.cmd) do if "" == "%%~$PATH:F" set "PATH=%cmdlib%;%PATH%"
    call cl_init "%PROG_FULL%" || (echo Failed to initialise cmd-lib. & goto :exit)

    set "char1=%~1"
    set "char1=%char1:~0,1%"
    if "%char1%" == "/" (
	echo Unknown option - %1.
	echo.
	call cl_usage "%PROG_FULL%"
	goto :error_exit
    )

    if "%show_help%" == "true" call cl_help "%PROG_FULL%" & goto :EOF

    if not "%~1" == "" (
	echo Extra argument - %1.
	echo.
    	call cl_usage "%PROG_FULL%"
	goto :error_exit
    )

    if not defined prefix (
	echo /prefix directory not defined.
	echo.
    	call cl_usage "%PROG_FULL%"
	goto :error_exit
    )

    if 0%verbosity% geq 2 (
	echo action  = %action%
	echo prefix  = %prefix%
	echo cmdlib  = %cmdlib%
	echo.
    )

    rem .----------------------------------------------------------------------
    rem | This is where the real fun begins!
    rem '----------------------------------------------------------------------

    goto :%action%
:configure
    call cl_token_subst install.cmd.tmpl install.cmd PACKAGE=%cfg_PACKAGE% DST_DIR="%prefix%" CMD_LIB="%cmdlib%"
    goto :exit
:clean
    for %%F in (install.cmd) do (
	if 0%verbosity% geq 1 echo Deleting %%F.
	if exist "%%F" del "%%F"
    )
    goto :exit
goto :EOF

rem .--------------------------------------------------------------------------
rem | Reads configuration values and defines configuration variables.
rem |
rem | The configuration file is a simple text file, where lines starting
rem | with a # is treated as a comment. Everything else should be simple
rem | assignments, e.g.
rem |
rem |   PACKAGE=cmd-lib
rem |
rem | The following values may be defined:
rem |
rem |   PACKAGE         Name of package being configured/installed.
rem |
rem | Each value will be assigned to a variable named cfg_<NAME>.
rem | Anything else will (hopefully) be silently ignored!
rem '--------------------------------------------------------------------------
:read_cfg
    if exist "%~1" (
        for /F "usebackq eol=# tokens=1,* delims==" %%V in ("%~1") do (
            if /i "%%V" == "PACKAGE"    set cfg_%%V=%%W
        )
    )
goto :EOF

rem .--------------------------------------------------------------------------
rem | Displays a selection of variables belonging to this script.
rem | Very handy when debugging.
rem '--------------------------------------------------------------------------
:dump_variables
    echo =======
    echo cwd            = "%CD%"
    echo tmp_dir        = "%tmp_dir%"
    echo.
    echo show_help      = "%show_help%"
    echo verbosity      = "%verbosity%"
    echo action         = "%action%"
    echo prefix         = "%prefix%"
    echo cmdlib         = "%cmdlib%"

    setlocal enabledelayedexpansion
    for /F "usebackq delims== tokens=1,*" %%V in (`set cfg_`) do (
	set "V=%%V          "
	set "V=!V:~0,14!
	echo !V! = "%%W"
    )
    endlocal

    if defined tmp_dir if exist "%tmp_dir%\" (
	echo.
	dir %tmp_dir%
    )

    echo =======
goto :EOF

rem ----------------------------------------------------------------------------
rem Sets ErrorLevel and exit-status. Without a proper exit-status tests like
rem 'command && echo Success || echo Failure' will not work,
rem
rem OBS: NO commands must follow the call to %ComSpec%, not even REM-arks,
rem      or the exit-status will be destroyed. However, null commands like
rem      labels (or ::) is okay.
rem ----------------------------------------------------------------------------
:no_error
    time >NUL: /t	& rem Set ErrorLevel = 0.
    goto :exit
:error_exit
    verify 2>NUL: other	& rem Set ErrorLevel = 1.
:exit
    %ComSpec% /c exit %ErrorLevel%

:: vim: set filetype=dosbatch tabstop=8 softtabstop=4 shiftwidth=4 noexpandtab:
:: vim: set foldmethod=indent

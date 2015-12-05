@   echo off

:main /? | [prefix]

:: = DESCRIPTION
:: =   !PROG_NAME! - configures cmd-lib.
:: =
:: = PARAMETERS
:: =   dest-dir
:: =     Name of directory to install cmd-lib in.

:: @author Jan Bruun Andersen
:: @version @(#) Version: 2015-12-05

    verify 2>NUL: other
    setlocal EnableExtensions
    if ErrorLevel 1 (
	echo Error - Unable to enable extensions.
	goto :EOF
    )

    for %%F in (cl_init.cmd) do if "" == "%%~$PATH:F" PATH %~dp0\src\lib;%PATH%
    call cl_init "%~f0" "%~1" || (echo Failed to initialise cmd-lib. & goto :exit)
    if /i "%~1" == "/trace" shift & prompt $G$G & echo on

:defaults
    set "show_help=false"
    set "prefix=%UserProfile%\LocalTools"

:getopts
    if /i "%~1" == "/?"		set "show_help=true"	& shift		& goto :getopts

    set "char1=%~1"
    set "char1=%char1:~0,1%"
    if "%char1%" == "/" (
	echo Unknown option - %1.
	echo.
	call cl_usage "%PROG_FULL%"
	goto :error_exit
    )

    if "%show_help%" == "true" call cl_help "%PROG_FULL%" & goto :EOF

    set "prefix=%~1" & shift

    if not "%~1" == "" (
	echo Extra argument - %1.
	echo.
    	call cl_usage "%PROG_FULL%"
	goto :error_exit
    )

    if not defined prefix (
	echo Missing argument - dest-dir is empty.
	echo.
    	call cl_usage "%PROG_FULL%"
	goto :error_exit
    )

    rem .----------------------------------------------------------------------
    rem | This is where the real fun begins!
    rem '----------------------------------------------------------------------

    call :subst install.cmd.tmpl install.cmd PROG_NAME=install DST_DIR="%prefix%"

    goto :exit
goto :EOF

:subst in-file out-file [token-assignment...]
    setlocal enabledelayedexpansion

    set "in_file=%~f1"  & shift
    set "out_file=%~f1" & shift

    for /L %%I in (1,1,6) do set "token%%I=" & set "value%%I="

    if not "%~1" == "" set "token1=%1" & set "value1=%~2" & shift & shift
    if not "%~1" == "" set "token2=%1" & set "value2=%~2" & shift & shift
    if not "%~1" == "" set "token3=%1" & set "value3=%~2" & shift & shift
    if not "%~1" == "" set "token4=%1" & set "value4=%~2" & shift & shift
    if not "%~1" == "" set "token5=%1" & set "value5=%~2" & shift & shift
    if not "%~1" == "" set "token6=%1" & set "value6=%~2" & shift & shift

    if true == false (
	if defined token1 echo token1="%token1%", value1="%value1%"
	if defined token2 echo token2="%token2%", value2="%value2%"
	if defined token3 echo token3="%token3%", value3="%value3%"
	if defined token4 echo token4="%token4%", value4="%value4%"
	if defined token5 echo token5="%token5%", value5="%value5%"
	if defined token6 echo token6="%token6%", value6="%value6%"
    )

    if "%out_file%" == "%in_file%" (
	echo Warning - Cowardly refuses to overwrite "%out_file%".
	goto :error_exit
    )

    if exist "%out_file%" del "%out_file%"

    for /F "usebackq delims=" %%I in (`type "%in_file%"`) do (
	set "I=%%I"
	if defined token1 set "I=!I:@%token1%@=%value1%!"
	if defined token2 set "I=!I:@%token2%@=%value2%!"
	if defined token3 set "I=!I:@%token3%@=%value3%!"
	if defined token4 set "I=!I:@%token4%@=%value4%!"
	if defined token5 set "I=!I:@%token5%@=%value5%!"
	if defined token6 set "I=!I:@%token6%@=%value6%!"
	echo.!I!>>"%out_file%"
    )
diff -Bb "%in_file%" "%out_file%"
    endlocal
goto :EOF

rem .--------------------------------------------------------------------------
rem | Displays a selection of variables belonging to this script.
rem | Very handy when debugging.
rem '--------------------------------------------------------------------------
:dump_variables
    echo =======
    echo cwd            = "%CD%"
    echo tmp_dir        = "%tmp_dir%"

    echo show_help      = "%show_help%"
    echo prefix         = "%prefix%"

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
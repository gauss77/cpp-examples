@echo off
setlocal enabledelayedexpansion

@rem only for interactive debugging !
set _DEBUG=0

@rem #########################################################################
@rem ## Environment setup

set _EXITCODE=0

call :env
if not %_EXITCODE%==0 goto end

call :args %*
if not %_EXITCODE%==0 goto end

@rem #########################################################################
@rem ## Main

if %_HELP%==1 (
    call :help
    exit /b !_EXITCODE!
)
if %_CLEAN%==1 (
    call :clean
    if not !_EXITCODE!==0 goto end
)
if %_LINT%==1 (
    call :lint
    if not !_EXITCODE!==0 goto end
)
if %_COMPILE%==1 (
    call :compile
    if not !_EXITCODE!==0 goto end
)
if %_DOC%==1 (
    call :doc
    if not !_EXITCODE!==0 goto end
)
if %_DUMP%==1 (
    call :dump
    if not !_EXITCODE!==0 goto end
)
if %_RUN%==1 (
    call :run
    if not !_EXITCODE!==0 goto end
)
goto end

@rem #########################################################################
@rem ## Subroutines

@rem output parameters: _DEBUG_LABEL, _ERROR_LABEL, _WARNING_LABEL
:env
set _STDOUT_REDIRECT=1^>NUL
if %_DEBUG%==1 set _STDOUT_REDIRECT=1^>CON

set _BASENAME=%~n0
set "_ROOT_DIR=%~dp0"

call :env_colors
set _DEBUG_LABEL=%_NORMAL_BG_CYAN%[%_BASENAME%]%_RESET%
set _ERROR_LABEL=%_STRONG_FG_RED%Error%_RESET%:
set _WARNING_LABEL=%_STRONG_FG_YELLOW%Warning%_RESET%:

set "__CMAKE_LIST_FILE=%_ROOT_DIR%CMakeLists.txt"
if not exist "%__CMAKE_LIST_FILE%" (
    echo %_ERROR_LABEL% File CMakeLists.txt not found 1>&2
    set _EXITCODE=1
    goto :eof
)
set _PROJ_NAME=main
for /f "tokens=1,2,* delims=( " %%f in ('findstr /b project "%__CMAKE_LIST_FILE%" 2^>NUL') do set "_PROJ_NAME=%%g"
set _PROJ_CONFIG=Release
set _PROJ_PLATFORM=x64

set "_SOURCE_DIR=%_ROOT_DIR%src"
set "_TARGET_DIR=%_ROOT_DIR%build"
set "_TARGET_DOCS_DIR=%_TARGET_DIR%\docs"

if not exist "%CMAKE_HOME%\bin\cmake.exe" (
    echo %_ERROR_LABEL% CMake installation directory not found 1>&2
    set _EXITCODE=1
    goto :eof
)
set "_CMAKE_CMD=%CMAKE_HOME%\bin\cmake.exe"

set _CPPCHECK_CMD=
if exist "%CPPCHECK_HOME%\cppcheck.exe" (
    set "_CPPCHECK_CMD=%CPPCHECK_HOME%\cppcheck.exe"
)
if not exist "%DOXYGEN_HOME%\bin\doxygen.exe" (
    echo %_ERROR_LABEL% Doxygen installation not found 1>&2
    set _EXITCODE=1
    goto :eof
)
set "_DOXYGEN_CMD=%DOXYGEN_HOME%\bin\doxygen.exe"

if not exist "%MSYS_HOME%\usr\bin\make.exe" (
    echo %_ERROR_LABEL% MSYS installation directory not found 1>&2
    set _EXITCODE=1
    goto :eof
)
set "_MAKE_CMD=%MSYS_HOME%\usr\bin\make.exe"

if not exist "%MSYS_HOME%\mingw64\bin\gcc.exe" (
    echo %_ERROR_LABEL% MSYS installation directory not found 1>&2
    set _EXITCODE=1
    goto :eof
)
set "_GCC_CMD=%MSYS_HOME%\mingw64\bin\gcc.exe"
set "_GXX_CMD=%MSYS_HOME%\mingw64\bin\g++.exe"
set "_WINDRES_CMD=%MSYS_HOME%\mingw64\bin\windres.exe"

if not exist "%LLVM_HOME%\bin\clang.exe" (
    echo %_ERROR_LABEL% LLVM installation directory not found 1>&2
    set _EXITCODE=1
    goto :eof
)
set "_CLANG_CMD=%LLVM_HOME%\bin\clang.exe"
set "_CLANGXX_CMD=%LLVM_HOME%\bin\clang++.exe"

if not exist "%MSVS_CMAKE_HOME%\bin\cmake.exe" (
    echo %_ERROR_LABEL% MSVS Cmake command not found 1>&2
    set _EXITCODE=1
    goto :eof
)
set "_MSVS_CMAKE_CMD=%MSVS_CMAKE_HOME%\bin\cmake.exe"

if not exist "%MSVS_HOME%\MSBuild\Current\Bin\msbuild.exe" (
    echo %_ERROR_LABEL% MSVS installation directory not found 1>&2
    set _EXITCODE=1
    goto :eof
)
set "_MSBUILD_CMD=%MSVS_HOME%\MSBuild\Current\Bin\msbuild.exe"

set _PELOOK_CMD=pelook.exe
goto :eof

:env_colors
@rem ANSI colors in standard Windows 10 shell
@rem see https://gist.github.com/mlocati/#file-win10colors-cmd
set _RESET=[0m
set _BOLD=[1m
set _UNDERSCORE=[4m
set _INVERSE=[7m

@rem normal foreground colors
set _NORMAL_FG_BLACK=[30m
set _NORMAL_FG_RED=[31m
set _NORMAL_FG_GREEN=[32m
set _NORMAL_FG_YELLOW=[33m
set _NORMAL_FG_BLUE=[34m
set _NORMAL_FG_MAGENTA=[35m
set _NORMAL_FG_CYAN=[36m
set _NORMAL_FG_WHITE=[37m

@rem normal background colors
set _NORMAL_BG_BLACK=[40m
set _NORMAL_BG_RED=[41m
set _NORMAL_BG_GREEN=[42m
set _NORMAL_BG_YELLOW=[43m
set _NORMAL_BG_BLUE=[44m
set _NORMAL_BG_MAGENTA=[45m
set _NORMAL_BG_CYAN=[46m
set _NORMAL_BG_WHITE=[47m

@rem strong foreground colors
set _STRONG_FG_BLACK=[90m
set _STRONG_FG_RED=[91m
set _STRONG_FG_GREEN=[92m
set _STRONG_FG_YELLOW=[93m
set _STRONG_FG_BLUE=[94m
set _STRONG_FG_MAGENTA=[95m
set _STRONG_FG_CYAN=[96m
set _STRONG_FG_WHITE=[97m

@rem strong background colors
set _STRONG_BG_BLACK=[100m
set _STRONG_BG_RED=[101m
set _STRONG_BG_GREEN=[102m
set _STRONG_BG_YELLOW=[103m
set _STRONG_BG_BLUE=[104m
goto :eof

@rem input parameter: %*
@rem output parameters: _CLEAN, _COMPILE, _RUN, _DEBUG, _TOOLSET, _VERBOSE
:args
set _CLEAN=0
set _COMPILE=0
set _DOC=0
set _DOC_OPEN=0
set _DUMP=0
set _HELP=0
set _LINT=0
set _RUN=0
set _TIMER=0
set _TOOLSET=msvc
set _VERBOSE=0
set __N=0
:args_loop
set "__ARG=%~1"
if not defined __ARG (
    if !__N!==0 set _HELP=1
    goto args_done
)
if "%__ARG:~0,1%"=="-" (
    @rem option
    if "%__ARG%"=="-cl" ( set _TOOLSET=msvc
    ) else if "%__ARG%"=="-clang" ( set _TOOLSET=clang
    ) else if "%__ARG%"=="-debug" ( set _DEBUG=1
    ) else if "%__ARG%"=="-gcc" ( set _TOOLSET=gcc
    ) else if "%__ARG%"=="-help" ( set _HELP=1
    ) else if "%__ARG%"=="-msvc" ( set _TOOLSET=msvc
    ) else if "%__ARG%"=="-open" ( set _DOC_OPEN=1
    ) else if "%__ARG%"=="-timer" ( set _TIMER=1
    ) else if "%__ARG%"=="-verbose" ( set _VERBOSE=1
    ) else (
        echo %_ERROR_LABEL% Unknown option %__ARG% 1>&2
        set _EXITCODE=1
        goto args_done
    )
) else (
    @rem subcommand
    if "%__ARG%"=="clean" ( set _CLEAN=1
    ) else if "%__ARG%"=="compile" ( set _COMPILE=1
    ) else if "%__ARG%"=="doc" ( set _DOC=1
    ) else if "%__ARG%"=="dump" ( set _COMPILE=1& set _DUMP=1
    ) else if "%__ARG%"=="help" ( set _HELP=1
    ) else if "%__ARG%"=="lint" ( set _LINT=1
    ) else if "%__ARG%"=="run" ( set _COMPILE=1& set _RUN=1
    ) else (
        echo %_ERROR_LABEL% Unknown subcommand %__ARG% 1>&2
        set _EXITCODE=1
        goto args_done
    )
    set /a __N+=1
)
shift
goto args_loop
:args_done
set _STDOUT_REDIRECT=1^>NUL
if %_DEBUG%==1 set _STDOUT_REDIRECT=1^>CON

if %_LINT%==1 if not defined _CPPCHECK_CMD (
    echo %_WARNING_LABEL% Cppcheck installation not found 1>&2
    set _LINT=0
)
if %_TOOLSET%==clang ( set _TOOLSET_NAME=LLVM/Clang
) else if %_TOOLSET%==gcc (  set _TOOLSET_NAME=MSYS/GCC
) else ( set _TOOLSET_NAME=MSBuild/MSVC
)
if %_DEBUG%==1 (
    echo %_DEBUG_LABEL% Options    : _TIMER=%_TIMER% _TOOLSET=%_TOOLSET% _VERBOSE=%_VERBOSE% 1>&2
    echo %_DEBUG_LABEL% Subcommands: _CLEAN=%_CLEAN% _COMPILE=%_COMPILE% _DOC=%_DOC% _DUMP=%_DUMP% _LINT=%_LINT% _RUN=%_RUN% 1>&2
    echo %_DEBUG_LABEL% Variables  : "CPPCHECK_HOME=%CPPCHECK_HOME%" 1>&2
    echo %_DEBUG_LABEL% Variables  : "DOXYGEN_HOME=%DOXYGEN_HOME%" 1>&2
    echo %_DEBUG_LABEL% Variables  : "GIT_HOME=%GIT_HOME%" 1>&2
    echo %_DEBUG_LABEL% Variables  : "LLVM_HOME=%LLVM_HOME%" ^(clang^) 1>&2
    echo %_DEBUG_LABEL% Variables  : "MSVC_HOME=%MSVC_HOME%" ^(cl^) 1>&2
    echo %_DEBUG_LABEL% Variables  : "MSYS_HOME=%MSYS_HOME%" ^(gcc^) 1>&2
)
if %_TIMER%==1 for /f "delims=" %%i in ('powershell -c "(Get-Date)"') do set _TIMER_START=%%i
goto :eof

:help
if %_VERBOSE%==1 (
    set __BEG_P=%_STRONG_FG_CYAN%
    set __BEG_O=%_STRONG_FG_GREEN%
    set __BEG_N=%_NORMAL_FG_YELLOW%
    set __END=%_RESET%
) else (
    set __BEG_P=
    set __BEG_O=
    set __BEG_N=
    set __END=
)
echo Usage: %__BEG_O%%_BASENAME% { ^<option^> ^| ^<subcommand^> }%__END%
echo.
echo %__BEG_P%Options:%__END%
echo   %__BEG_O%-debug%__END%      display commands executed by this script
echo   %__BEG_O%-cl%__END%         use CL/MSBuild toolset (default)
echo   %__BEG_O%-clang%__END%      use Clang/GNU Make toolset instead of CL/MSBuild
echo   %__BEG_O%-gcc%__END%        use GCC/GNU Make toolset instead of CL/MSBuild
echo   %__BEG_O%-msvc%__END%       use CL/MSBuild toolset ^(alias for option %__BEG_O%-cl%__END%^)
echo   %__BEG_O%-verbose%__END%    display progress messages
echo.
echo %__BEG_P%Subcommands:%__END%
echo   %__BEG_O%clean%__END%       delete generated files
echo   %__BEG_O%compile%__END%     generate executable
echo   %__BEG_O%doc%__END%         generate HTML documentation with %__BEG_N%Doxygen%__END%
echo   %__BEG_O%dump%__END%        dump PE/COFF infos for generated executable
echo   %__BEG_O%help%__END%        display this help message
echo   %__BEG_O%lint%__END%        analyze C++ source files with %__BEG_N%Cppcheck%__END%
echo   %__BEG_O%run%__END%         run the generated executable
goto :eof

:clean
call :rmdir "%_TARGET_DIR%"
goto :eof

@rem input parameter: %1=directory path
:rmdir
set "__DIR=%~1"
if not exist "%__DIR%\" goto :eof
if %_DEBUG%==1 ( echo %_DEBUG_LABEL% rmdir /s /q "%__DIR%" 1>&2
) else if %_VERBOSE%==1 ( echo Delete directory "!__DIR:%_ROOT_DIR%=!" 1>&2
)
rmdir /s /q "%__DIR%"
if not %ERRORLEVEL%==0 (
    echo %_ERROR_LABEL% Failed to delete directory "!__DIR:%_ROOT_DIR%=!" 1>&2
    set _EXITCODE=1
    goto :eof
)
goto :eof

:lint
@rem C++ support in GCC, MSVC and Clang:
@rem https://gcc.gnu.org/projects/cxx-status.html
@rem https://docs.microsoft.com/en-us/cpp/build/reference/std-specify-language-standard-version
@rem https://clang.llvm.org/cxx_status.html
if %_TOOLSET%==gcc ( set __CPPCHECK_OPTS=--template=gcc --std=c++14
) else if %_TOOLSET%==msvc ( set __CPPCHECK_OPTS=--template=vs --std=c++17
) else ( set __CPPCHECK_OPTS=--std=c++14
)
if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%_CPPCHECK_CMD%" %__CPPCHECK_OPTS% "%_SOURCE_DIR%" 1>&2
) else if %_VERBOSE%==1 ( echo Analyze C++ source files in directory "!_SOURCE_DIR=%_ROOT_DIR%=!" 1>&2
)
call "%_CPPCHECK_CMD%" %__CPPCHECK_OPTS% "%_SOURCE_DIR%"
if not %ERRORLEVEL%==0 (
    echo %_ERROR_LABEL% Checking files failed 1>&2
    set _EXITCODE=1
    goto :eof
)
goto :eof

:compile
setlocal
if not exist "%_TARGET_DIR%" mkdir "%_TARGET_DIR%"

if %_DEBUG%==1 ( echo %_DEBUG_LABEL% Configuration: %_PROJ_CONFIG% Platform: %_PROJ_PLATFORM% 1>&2
) else if %_VERBOSE%==1 ( echo Configuration: %_PROJ_CONFIG% Platform: %_PROJ_PLATFORM% 1>&2
)
call :compile_%_TOOLSET%
endlocal
goto :eof

:compile_clang
set "CC=%_CLANG_CMD%"
set "CXX=%_CLANGXX_CMD%"
set "MAKE=%_MAKE_CMD%"
set "RC=%_WINDRES_CMD%"

set __CMAKE_OPTS=-G "Unix Makefiles"

pushd "%_TARGET_DIR%"
if %_DEBUG%==1 echo %_DEBUG_LABEL% Current directory is: %CD% 1>&2

if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%_CMAKE_CMD%" %__CMAKE_OPTS% .. 1>&2
) else if %_VERBOSE%==1 ( echo Generate configuration files into directory "!_TARGET_DIR:%_ROOT_DIR%=!" 1>&2
)
call "%_CMAKE_CMD%" %__CMAKE_OPTS% .. %_STDOUT_REDIRECT%
if not %ERRORLEVEL%==0 (
    popd
    echo %_ERROR_LABEL% Generation of build configuration failed 1>&2
    set _EXITCODE=1
    goto :eof
)
set __MAKE_OPTS=

if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%_MAKE_CMD%" %__MAKE_OPTS% 1>&2
) else if %_VERBOSE%==1 ( echo Generate executable "%_PROJ_NAME%.exe" 1>&2
)
call "%_MAKE_CMD%" %__MAKE_OPTS% %_STDOUT_REDIRECT%
if not %ERRORLEVEL%==0 (
    popd
    echo %_ERROR_LABEL% Failed to generate executable "%_PROJ_NAME%.exe" 1>&2
    set _EXITCODE=1
    goto :eof
)
popd
goto :eof

:compile_gcc
set "CC=%_GCC_CMD%"
set "CXX=%_GXX_CMD%"
set "MAKE=%_MAKE_CMD%"
set "RC=%_WINDRES_CMD%"

set __CMAKE_OPTS=-G "Unix Makefiles"

pushd "%_TARGET_DIR%"
if %_DEBUG%==1 echo %_DEBUG_LABEL% Current directory is: %CD% 1>&2

if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%_CMAKE_CMD%" %__CMAKE_OPTS% .. 1>&2
) else if %_VERBOSE%==1 ( echo Generate configuration files into directory "!_TARGET_DIR:%_ROOT_DIR%=!" 1>&2
)
call "%_CMAKE_CMD%" %__CMAKE_OPTS% .. %_STDOUT_REDIRECT%
if not %ERRORLEVEL%==0 (
    popd
    echo %_ERROR_LABEL% Failed to generate configuration into directory "!_TARGET_DIR:%_ROOT_DIR%=!" 1>&2
    set _EXITCODE=1
    goto :eof
)
set __MAKE_OPTS=

if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%_MAKE_CMD%" %__MAKE_OPTS% 1>&2
) else if %_VERBOSE%==1 ( echo Generate executable "%_PROJ_NAME%.exe" 1>&2
)
call "%_MAKE_CMD%" %__MAKE_OPTS% %_STDOUT_REDIRECT%
if not %ERRORLEVEL%==0 (
    popd
    echo %_ERROR_LABEL% Failed to generate executable "%_PROJ_NAME%.exe" 1>&2
    set _EXITCODE=1
    goto :eof
)
popd
goto :eof

:compile_msvc
set __CMAKE_OPTS=-Thost=%_PROJ_PLATFORM% -A %_PROJ_PLATFORM% -Wdeprecated

pushd "%_TARGET_DIR%"
if %_DEBUG%==1 echo %_DEBUG_LABEL% Current directory is: %CD%

if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%_MSVS_CMAKE_CMD%" %__CMAKE_OPTS% .. 1>&2
) else if %_VERBOSE%==1 ( echo Generate configuration files into directory "!_TARGET_DIR:%_ROOT_DIR%=!" 1>&2
)
call "%_MSVS_CMAKE_CMD%" %__CMAKE_OPTS% .. %_STDOUT_REDIRECT%
if not %ERRORLEVEL%==0 (
    popd
    echo %_ERROR_LABEL% Failed to generate configuration files into directory "!_TARGET_DIR:%_ROOT_DIR%=!" 1>&2
    set _EXITCODE=1
    goto :eof
)
set __MSBUILD_OPTS=/nologo "/p:Configuration=%_PROJ_CONFIG%" "/p:Platform=%_PROJ_PLATFORM%"

if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%_MSBUILD_CMD%" %__MSBUILD_OPTS% "%_PROJ_NAME%.sln" 1>&2
) else if %_VERBOSE%==1 ( echo Generate executable "%_PROJ_NAME%.exe" 1>&2
)
call "%_MSBUILD_CMD%" %__MSBUILD_OPTS% "%_PROJ_NAME%.sln" %_STDOUT_REDIRECT%
if not %ERRORLEVEL%==0 (
    popd
    echo %_ERROR_LABEL% Failed to generate executable "%_PROJ_NAME%.exe" 1>&2
    set _EXITCODE=1
    goto :eof
)
popd
goto :eof

:doc
@rem must be the same as property OUTPUT_DIRECTORY in file Doxyfile
if not exist "%_TARGET_DOCS_DIR%" mkdir "%_TARGET_DOCS_DIR%"

set "__DOXYFILE=%_ROOT_DIR%Doxyfile"
if not exist "%__DOXYFILE%" (
    echo %_ERROR_LABEL% Configuration file for Doxygen not found 1>&2
    set _EXITCODE=1
    goto :eof
)
set __DOXYGEN_OPTS=-s

if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%_DOXYGEN_CMD%" %__DOXYGEN_OPTS% "%__DOXYFILE%" 1>&2
) else if %_VERBOSE%==1 ( echo Generate HTML documentation 1>&2
)
call "%_DOXYGEN_CMD%" %__DOXYGEN_OPTS% "%__DOXYFILE%"
if not %ERRORLEVEL%==0 (
    echo %_ERROR_LABEL% Failed to generate HTML documentation 1>&2
    set _EXITCODE=1
    goto :eof
)
set "__INDEX_FILE=%_TARGET_DOCS_DIR%\html\index.html"
if %_DOC_OPEN%==1 (
    if %_DEBUG%==1 ( echo %_DEBUG_LABEL% start "%_BASENAME%" "%__INDEX_FILE%" 1>&2
    ) else if %_VERBOSE%==1 ( echo Open HTML documentation in default browser 1>&2
    )
    start "%_BASENAME%" "%__INDEX_FILE%"
)
goto :eof

:dump
if not %_TOOLSET%==msvc ( set __TARGET_DIR=%_TARGET_DIR%
) else ( set "__TARGET_DIR=%_TARGET_DIR%\%_PROJ_CONFIG%"
)
set __EXE_FILE=%__TARGET_DIR%\%_PROJ_NAME%.exe
if not exist "%__EXE_FILE%" (
    echo %_ERROR_LABEL% Executable "%_PROJ_NAME%.exe" not found 1>&2
    set _EXITCODE=1
    goto :eof
)
set __PELOOK_OPTS=

if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%_PELOOK_CMD%" %__PELOOK_OPTS% !__EXE_FILE:%_ROOT_DIR%=! 1>&2
) else if %_VERBOSE%==1 ( echo Dump PE/COFF infos for executable !__EXE_FILE:%_ROOT_DIR%=! 1>&2
)
echo executable:           !__EXE_FILE:%_ROOT_DIR%=!
call "%_PELOOK_CMD%" %__PELOOK_OPTS% "%__EXE_FILE%" | findstr "signature machine linkver modules"
if not %ERRORLEVEL%==0 (
    echo %_ERROR_LABEL% Failed to dump executable "%_PROJ_NAME%.exe" 1>&2
    set _EXITCODE=1
    goto :eof
)
goto :eof

:run
if not %_TOOLSET%==msvc ( set "__TARGET_DIR=%_TARGET_DIR%"
) else ( set "__TARGET_DIR=%_TARGET_DIR%\%_PROJ_CONFIG%"
)
set "__EXE_FILE=%__TARGET_DIR%\%_PROJ_NAME%.exe"
if not exist "%__EXE_FILE%" (
    echo %_ERROR_LABEL% Executable "%_PROJ_NAME%.exe" not found 1>&2
    set _EXITCODE=1
    goto :eof
)
if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%__EXE_FILE%" 1>&2
) else if %_VERBOSE%==1 ( echo Execute "!__EXE_FILE:%_ROOT_DIR%=!" 1>&2
)
call "%__EXE_FILE%"
if not %ERRORLEVEL%==0 (
    echo %_ERROR_LABEL% Failed to execute "!__EXE_FILE:%_ROOT_DIR%=!" 1>&2
    set _EXITCODE=1
)
goto :eof

@rem output parameter: _DURATION
:duration
set __START=%~1
set __END=%~2

for /f "delims=" %%i in ('powershell -c "$interval = New-TimeSpan -Start '%__START%' -End '%__END%'; Write-Host $interval"') do set _DURATION=%%i
goto :eof

@rem #########################################################################
@rem ## Cleanups

:end
if %_TIMER%==1 (
    for /f "delims=" %%i in ('powershell -c "(Get-Date)"') do set __TIMER_END=%%i
    call :duration "%_TIMER_START%" "!__TIMER_END!"
    echo Total execution time: !_DURATION! 1>&2
)
if %_DEBUG%==1 echo %_DEBUG_LABEL% _EXITCODE=%_EXITCODE% 1>&2
exit /b %_EXITCODE%
endlocal

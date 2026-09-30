@echo off

rem Declarative list of generated runtime directories required by the project.
rem config.cmd MUST be called by the caller before this file.

if not defined MODELS (
    echo ERROR: MODELS is not defined before runtime-layout.cmd.
    exit /b 1
)

if not defined CACHE (
    echo ERROR: CACHE is not defined before runtime-layout.cmd.
    exit /b 1
)

set RUNTIME_REQUIRED_DIRS="%MODELS%\whisper" "%CACHE%\huggingface\hub" "%CACHE%\huggingface\xet" "%CACHE%\torch" "%CACHE%\pip" "%CACHE%\nltk" "%CACHE%\tmp"

exit /b 0

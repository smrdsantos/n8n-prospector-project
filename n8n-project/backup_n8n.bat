@echo off
setlocal EnableExtensions
chcp 65001 >nul

rem ===== /NOPAUSE precisa vir antes do goto :main =====
set "NOPAUSE="
if /I "%~1"=="/NOPAUSE" set "NOPAUSE=1"

goto :main

:: ========= utils =========
:log
rem Uso: call :log [mensagem...]
setlocal
if "%~1"=="" (
  >>"%LOG%" echo(
) else (
  >>"%LOG%" echo %*
)
endlocal & exit /b 0

:say
rem Uso: call :say [mensagem...]
setlocal
if "%~1"=="" (
  echo(
) else (
  echo %*
)
endlocal & exit /b 0

:maybe_pause
if "%NOPAUSE%"=="1" exit /b 0
pause
exit /b 0

:exec
rem Uso: set "DESC=descricao"; call :exec comando arg1 arg2 ...
setlocal
if not defined DESC set "DESC=(sem descricao)"
call :log === %DESC% ===
>>"%LOG%" echo CMD: %*
call %* >>"%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  call :log [ERROR] %DESC% RC=%RC%
  endlocal & exit /b %RC%
) else (
  call :log [OK] %DESC%
)
endlocal & exit /b 0

:exec_ignore
rem Uso: set "DESC=descricao"; call :exec_ignore comando arg1 arg2 ...
rem Sem interrupcao do fluxo quando RC != 0; loga como [SKIP]
setlocal
if not defined DESC set "DESC=(sem descricao)"
call :log === %DESC% ===
>>"%LOG%" echo CMD: %*
call %* >>"%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  call :log [SKIP] %DESC% RC=%RC%
) else (
  call :log [OK] %DESC%
)
endlocal & exit /b 0

:require_cmd
rem Uso: call :require_cmd nome_comando
setlocal
where %~1 >nul 2>&1
if errorlevel 1 (
  call :say [ERRO] comando nao encontrado: %~1
  call :log  [ERRO] comando nao encontrado: %~1
  endlocal & exit /b 1
)
endlocal & exit /b 0

:: ========= main =========
:main
rem caminhos
set "ROOT=D:\Micro Samuel Atual\Documentos"
set "N8N=%ROOT%\n8n-project"
set "MAGE=%ROOT%\Mage-Projetos"
set "LOGDIR=%ROOT%\backup_logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

rem timestamp (locale-independente)
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set "TS=%%i"

set "LOG=%LOGDIR%\backup_%TS%.log"
set "COMMIT_MSG=Backup do Ambiente de Dados - %TS%"

rem limpeza de logs mais antigos que 30 dias
forfiles /p "%LOGDIR%" /m *.log /d -30 /c "cmd /c del /q @path" >nul 2>&1

rem boot marks (console + log)
call :say [BOOT] batch started - %date% %time%
call :say [BOOT] log file: "%LOG%"
call :log [BOOT] batch started - %date% %time%
call :log [BOOT] log file: "%LOG%"

rem sanidade de caminhos
if not exist "%N8N%" (
  call :say [ERRO] pasta nao existe: %N8N%
  call :log [ERRO] pasta nao existe: %N8N%
  goto :fail
)
if not exist "%MAGE%" (
  call :say [ERRO] pasta nao existe: %MAGE%
  call :log [ERRO] pasta nao existe: %MAGE%
  goto :fail
)

rem checar binarios essenciais
call :require_cmd docker || goto :fail
call :require_cmd git    || goto :fail

rem cabecalho (no log e no console)
call :log
call :log ==========================================================
call :log STOP ENV AND BACKUP - end of day
call :log ==========================================================
call :log Commit: "%COMMIT_MSG%"
call :log Log: "%LOG%"
call :log

call :say
call :say ==========================================================
call :say STOP ENV AND BACKUP - end of day
call :say ==========================================================
call :say Commit: "%COMMIT_MSG%"
call :say Log: "%LOG%"
call :say
call :maybe_pause

rem parar n8n/postgres/jupyter
cd /d "%N8N%"
set "DESC=Stopping data stack - n8n/postgres/jupyter"
call :say === %DESC% ===
call :exec docker compose down || goto :fail

rem parar/remover mage-etl (ignorando erro se nao existir)
set "DESC=Stopping mage-etl - ignore if not running"
call :say === %DESC% ===
call :exec_ignore docker stop mage-etl

set "DESC=Removing mage-etl - ignore if not present"
call :say === %DESC% ===
call :exec_ignore docker rm mage-etl

call :log All services are stopped.
call :log
call :say
call :say All services are stopped.
call :say
call :maybe_pause

rem git backup
cd /d "%ROOT%"
set "DESC=Git add - n8n-project + Mage-Projetos"
call :say === %DESC% ===
call :exec git add --all "n8n-project" "Mage-Projetos" || goto :fail

rem checar se ha staged
git diff --cached --quiet
if "%ERRORLEVEL%"=="0" (
  call :log [WARN] Nothing staged to commit. Skipping commit/push.
  call :say [WARN] Nothing staged to commit. Skipping commit/push.
  goto :end
)

set "DESC=Git commit"
call :say === %DESC% ===
call :exec git commit -m "%COMMIT_MSG%" || goto :fail

set "DESC=Git push"
call :say === %DESC% ===
call :exec git push || goto :fail

goto :end

:fail
call :log
call :log ==========================================================
call :log ERROR OCCURRED - see log:
call :log %LOG%
call :log ==========================================================
call :log
call :say
call :say ==========================================================
call :say ERROR OCCURRED - see log:
call :say %LOG%
call :say ==========================================================
call :say
call :maybe_pause
exit /b 1

:end
call :log
call :log ==========================================================
call :log BACKUP DONE AND ENV STOPPED
call :log ==========================================================
call :log
call :say
call :say ==========================================================
call :say BACKUP DONE AND ENV STOPPED
call :say ==========================================================
call :say
call :maybe_pause
exit /b 0
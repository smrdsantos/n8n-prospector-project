
@echo off
setlocal EnableExtensions
chcp 65001 >nul

rem ======== opcional: /NOPAUSE para rodar sem pausas ========
set "NOPAUSE="
if /I "%~1"=="/NOPAUSE" set "NOPAUSE=1"

goto :main

:: =================== utils (sem blocos) ===================
:log
rem Uso: call :log [mensagem...]
setlocal
if "%~1"=="" goto log_blank
>>"%LOG%" echo %*
endlocal & exit /b 0
:log_blank
>>"%LOG%" echo(
endlocal & exit /b 0

:say
rem Uso: call :say [mensagem...]
setlocal
if "%~1"=="" goto say_blank
echo %*
endlocal & exit /b 0
:say_blank
echo(
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
)
call :log [OK] %DESC%
endlocal & exit /b 0

:exec_ignore
rem Uso: set "DESC=descricao"; call :exec_ignore comando arg1 arg2 ...
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

:wait_docker
rem Uso: call :wait_docker <segundos_timeout>
setlocal
set "TO=%~1"
if "%TO%"=="" set "TO=60"
for /L %%S in (1,1,%TO%) do (
  docker info >nul 2>&1 && ( endlocal & exit /b 0 )
  ping -n 2 127.0.0.1 >nul
)
endlocal & exit /b 1

:: =================== main ===================
:main
rem caminhos
set "ROOT=D:\Micro Samuel Atual\Documentos"
set "N8N=%ROOT%\n8n-project"
set "MAGE=%ROOT%\Mage-Projetos"
set "MAGE_PROJ_DIR=%MAGE%\pipeline_inicial"
set "MAGE_PROJ_NAME=pipeline_inicial"
set "LOGDIR=%ROOT%\backup_logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

rem timestamp (locale-independente)
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set "TS=%%i"

set "LOG=%LOGDIR%\start_%TS%.log"
set "HTML=%N8N%\startup_info.html"
set "HTMLTMP=%N8N%\startup_info.%TS%.tmp"
set "HTMLTS=%N8N%\startup_info.%TS%.html"

rem limpar antigos (opcional)
forfiles /p "%LOGDIR%" /m start_*.log /d -30 /c "cmd /c del /q @path" >nul 2>&1
forfiles /p "%N8N%"   /m startup_info.*.html /d -14 /c "cmd /c del /q @path" >nul 2>&1

rem boot marks
call :say [BOOT] batch started - %date% %time%
call :say [BOOT] log file: "%LOG%"
call :log [BOOT] batch started - %date% %time%
call :log [BOOT] log file: "%LOG%"

rem sanidade
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

rem binários
call :require_cmd docker || goto :fail
call :require_cmd git    || goto :fail

rem header
call :log
call :log ==========================================================
call :log START ENV AND DASHBOARD - ready to work
call :log ==========================================================
call :log HTML: "%HTML%"
call :log Log : "%LOG%"
call :log

call :say
call :say START ENV AND DASHBOARD - ready to work
call :say
call :say HTML: "%HTML%"
call :say Log : "%LOG%"
call :say
call :maybe_pause

rem ===== docker pronto
set "DESC=Aguardando Docker responder - ate 90s"
call :say === %DESC% ===
call :exec call :wait_docker 90 || goto :fail
call :log [OK] Docker pronto

rem ===== subir compose
cd /d "%N8N%"
set "DESC=Subindo stack - docker compose up -d"
call :say === %DESC% ===
call :exec docker compose up -d || goto :fail

rem ===== mage-etl: criar se não existir, senão startar
docker inspect mage-etl >nul 2>&1
if errorlevel 1 (
  set "DESC=Criando container mage-etl"
  call :say === %DESC% ===
  call :exec docker run -d --name mage-etl --restart unless-stopped ^
    -p 6789:6789 -v "%MAGE%":/home/src mageai/mageai mage start %MAGE_PROJ_NAME% || goto :fail
) else (
  for /f %%S in ('docker inspect -f "{{.State.Status}}" mage-etl 2^>nul') do set "ST_MAGE=%%S"
  if /I not "%ST_MAGE%"=="running" (
    set "DESC=Iniciando mage-etl - existente"
    call :say === %DESC% ===
    call :exec docker start mage-etl || goto :fail
  ) else (
    call :log [INFO] mage-etl ja esta em execucao
  )
)

rem ===== gerar HTML
set "N8N_URL=http://localhost:5678/"
set "JUPY_URL=http://localhost:8888/"
set "MAGE_URL=http://localhost:6789/"
set "PG_DESC=tcp://localhost:5432"

for /f %%I in ('docker inspect -f "{{.Config.Image}}" n8n_prospector 2^>nul') do set "IMG_N8N=%%I"
for /f %%S in ('docker inspect -f "{{.State.Status}}" n8n_prospector 2^>nul') do set "ST_N8N=%%S"
for /f %%H in ('docker inspect -f "{{if .State.Health}}{{.State.Health.Status}}{{end}}" n8n_prospector 2^>nul') do set "HL_N8N=%%H"

for /f %%I in ('docker inspect -f "{{.Config.Image}}" jupyter_analysis 2^>nul') do set "IMG_JUP=%%I"
for /f %%S in ('docker inspect -f "{{.State.Status}}" jupyter_analysis 2^>nul') do set "ST_JUP=%%S"
for /f %%H in ('docker inspect -f "{{if .State.Health}}{{.State.Health.Status}}{{end}}" jupyter_analysis 2^>nul') do set "HL_JUP=%%H"

for /f %%I in ('docker inspect -f "{{.Config.Image}}" mage-etl 2^>nul') do set "IMG_MAGE=%%I"
for /f %%S in ('docker inspect -f "{{.State.Status}}" mage-etl 2^>nul') do set "ST_MAGE=%%S"
for /f %%H in ('docker inspect -f "{{if .State.Health}}{{.State.Health.Status}}{{end}}" mage-etl 2^>nul') do set "HL_MAGE=%%H"

for /f %%I in ('docker inspect -f "{{.Config.Image}}" postgres_wh 2^>nul') do set "IMG_PG=%%I"
for /f %%S in ('docker inspect -f "{{.State.Status}}" postgres_wh 2^>nul') do set "ST_PG=%%S"
for /f %%H in ('docker inspect -f "{{if .State.Health}}{{.State.Health.Status}}{{end}}" postgres_wh 2^>nul') do set "HL_PG=%%H"

if not defined IMG_N8N  set "IMG_N8N=-"
if not defined IMG_JUP  set "IMG_JUP=-"
if not defined IMG_MAGE set "IMG_MAGE=-"
if not defined IMG_PG   set "IMG_PG=-"

if not defined ST_N8N  set "ST_N8N=absent"
if not defined ST_JUP  set "ST_JUP=absent"
if not defined ST_MAGE set "ST_MAGE=absent"
if not defined ST_PG   set "ST_PG=absent"

set "TXT_N8N=%ST_N8N% %HL_N8N%"
set "TXT_JUP=%ST_JUP% %HL_JUP%"
set "TXT_MAGE=%ST_MAGE% %HL_MAGE%"
set "TXT_PG=%ST_PG% %HL_PG%"

if exist "%HTMLTMP%" del /q "%HTMLTMP%" >nul 2>&1

> "%HTMLTMP%"  echo ^<!doctype html^>
>>"%HTMLTMP%" echo ^<html lang='pt-br'^>
>>"%HTMLTMP%" echo ^<head^>
>>"%HTMLTMP%" echo   ^<meta charset='utf-8'^/^>
>>"%HTMLTMP%" echo   ^<meta name='viewport' content='width=device-width,initial-scale=1'^/^>
>>"%HTMLTMP%" echo   ^<title^>Ambiente de Dados - Dashboard^</title^>
>>"%HTMLTMP%" echo   ^<style^>
>>"%HTMLTMP%" echo     body{font-family:Segoe UI,Arial,sans-serif;margin:24px;background:#0b1220;color:#e7ebf4}
>>"%HTMLTMP%" echo     h1{margin:0 0 6px 0;font-size:24px}
>>"%HTMLTMP%" echo     .sub{opacity:.8;margin-bottom:16px}
>>"%HTMLTMP%" echo     table{border-collapse:collapse;width:100%%;background:#0f172a;border:1px solid #23304a}
>>"%HTMLTMP%" echo     th,td{padding:10px 12px;border-bottom:1px solid #23304a;text-align:left}
>>"%HTMLTMP%" echo     th{background:#111a2b;color:#c6d4f0;font-weight:600}
>>"%HTMLTMP%" echo     a{color:#a0c7ff;text-decoration:none}
>>"%HTMLTMP%" echo     a:hover{text-decoration:underline}
>>"%HTMLTMP%" echo     .ok{color:#8ef29b}.warn{color:#ffd166}.bad{color:#ff6b6b}
>>"%HTMLTMP%" echo     footer{margin-top:14px;opacity:.7;font-size:12px}
>>"%HTMLTMP%" echo   ^</style^>
>>"%HTMLTMP%" echo ^</head^>
>>"%HTMLTMP%" echo ^<body^>
>>"%HTMLTMP%" echo   ^<h1^>Ambiente de Dados^</h1^>
>>"%HTMLTMP%" echo   ^<div class='sub'^>Gerado em %TS%^</div^>
>>"%HTMLTMP%" echo   ^<table^>
>>"%HTMLTMP%" echo     ^<tr^>^<th^>Name^</th^>^<th^>Image^</th^>^<th^>Port(s)^</th^>^<th^>Status^</th^>^</tr^>
>>"%HTMLTMP%" echo     ^<tr^>^<td^>n8n_prospector^</td^>^<td^>%IMG_N8N%^</td^>^<td^>^<a href='%N8N_URL%' target='_blank'^>5678^</a^>^</td^>^<td^>%TXT_N8N%^</td^>^</tr^>
>>"%HTMLTMP%" echo     ^<tr^>^<td^>jupyter_analysis^</td^>^<td^>%IMG_JUP%^</td^>^<td^>^<a href='%JUPY_URL%' target='_blank'^>8888^</a^>^</td^>^<td^>%TXT_JUP%^</td^>^</tr^>
>>"%HTMLTMP%" echo     ^<tr^>^<td^>mage-etl^</td^>^<td^>%IMG_MAGE%^</td^>^<td^>^<a href='%MAGE_URL%' target='_blank'^>6789^</a^>^</td^>^<td^>%TXT_MAGE%^</td^>^</tr^>
>>"%HTMLTMP%" echo     ^<tr^>^<td^>postgres_wh^</td^>^<td^>%IMG_PG%^</td^>^<td^>5432 (TCP)^</td^>^<td^>%TXT_PG%^</td^>^</tr^>
>>"%HTMLTMP%" echo   ^</table^>
>>"%HTMLTMP%" echo   ^<footer^>Arquivos gerados: startup_info.html e startup_info.%TS%.html^</footer^>
>>"%HTMLTMP%" echo ^</body^>
>>"%HTMLTMP%" echo ^</html^>

copy /y "%HTMLTMP%" "%HTML%"  >nul
copy /y "%HTMLTMP%" "%HTMLTS%" >nul
del /q "%HTMLTMP%" >nul 2>&1

start "" "%HTML%"

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
call :log STARTUP DONE - services up and dashboard opened
call :log ==========================================================
call :log
call :say
call :say STARTUP DONE - services up and dashboard opened
call :say
call :maybe_pause
exit /b 0

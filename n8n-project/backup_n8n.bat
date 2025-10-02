@echo off
setlocal EnableExtensions

REM =================================================================
REM 1) TIMESTAMP E MENSAGEM DE COMMIT (locale-agnostic)
REM =================================================================
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd_HH-mm\""') do set TS=%%i
set "COMMIT_MSG=Backup do Ambiente de Dados - %TS%"

echo.
echo ==========================================================
echo PARAR AMBIENTE E FAZER BACKUP (fim de dia)
echo ==========================================================
echo Commit: "%COMMIT_MSG%"
echo.
pause

REM =================================================================
REM 2) PARAR TODOS OS CONTAINERS DOCKER
REM =================================================================
echo.
echo --- PARANDO STACK DE DADOS (N8N, POSTGRES, JUPYTER) ---
cd /d "D:\Micro Samuel Atual\Documentos\n8n-project"
docker compose down
if errorlevel 1 echo [AVISO] docker compose down retornou erro (sem impacto para o backup).
echo.

echo --- PARANDO STACK DE ETL (MAGE) ---
echo Parando e removendo o container 'mage-etl'...
docker stop mage-etl >NUL 2>&1
docker rm   mage-etl >NUL 2>&1
echo Todos os servicos foram parados.
echo.

REM =================================================================
REM 3) GIT: ADD/COMMIT/PUSH A PARTIR DA RAIZ DO REPOSITORIO
REM =================================================================
echo --- INICIANDO BACKUP PARA O GITHUB ---
cd /d "D:\Micro Samuel Atual\Documentos"

REM Adiciona todas as mudancas (respeitando o .gitignore da raiz)
git add -A

REM Tenta commitar; se nao houver mudancas, nao falha o processo
git commit -m "%COMMIT_MSG%"
if errorlevel 1 (
    echo.
    echo [INFO] Nenhuma mudanca detectada para salvar.
    goto END
)

echo Enviando backup para o GitHub...
git push

:END
echo.
echo ==========================================================
echo BACKUP CONCLUIDO E AMBIENTE DESLIGADO.
echo ==========================================================
echo.
pause
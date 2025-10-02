@echo off
setlocal

:: =================================================================
:: 1. DEFINE A MENSAGEM DE COMMIT COM DATA E HORA
:: =================================================================
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set DATE_STR=%%c-%%b-%%a
for /f "tokens=1-2 delims=:" %%a in ('time /t') do set TIME_STR=%%a-%%b

set COMMIT_MSG="Backup do Ambiente de Dados - %DATE_STR% as %TIME_STR%"

ECHO.
ECHO ==========================================================
ECHO INICIANDO PARADA E BACKUP DO AMBIENTE COMPLETO
ECHO ==========================================================
ECHO.
ECHO Mensagem de Commit: %COMMIT_MSG%
ECHO.
PAUSE

:: =================================================================
:: 2. PARA TODOS OS CONTAINERS DOCKER
:: =================================================================
ECHO.
ECHO --- PARANDO STACK DE DADOS (N8N, POSTGRES, JUPYTER) ---
D:
cd "D:\Micro Samuel Atual\Documentos\n8n-project"
docker compose down
ECHO.
PAUSE

ECHO.
ECHO --- PARANDO STACK DE ETL (MAGE) ---
ECHO Parando e removendo o container 'mage-etl'...
docker stop mage-etl
docker rm mage-etl
ECHO.
ECHO Todos os servicos foram parados.
ECHO.
PAUSE

:: =================================================================
:: 3. EXECUTA O BACKUP COM GIT
:: =================================================================
ECHO.
ECHO --- INICIANDO BACKUP PARA O GITHUB ---
ECHO Navegando para a pasta raiz dos projetos...
D:
cd "D:\Micro Samuel Atual\documentos"

ECHO Adicionando todas as mudancas dos projetos ao Git...
git add n8n-project/ Mage-Projetos/

ECHO Criando Commit...
git commit -m %COMMIT_MSG%

:: Verifica se houve algo para commitar. Se nao, o git commit retorna erro.
if errorlevel 1 (
    ECHO.
    ECHO [ALERTA] Nenhuma mudanca detectada para salvar.
    GOTO END
)

ECHO Enviando backup para o GitHub...
git push

:END
ECHO.
ECHO ==========================================================
ECHO BACKUP CONCLUIDO E AMBIENTE DESLIGADO.
ECHO ==========================================================
ECHO.
PAUSE
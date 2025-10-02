@echo off
setlocal

:: 1. Define variaveis de Data e Hora para a mensagem de commit
:: O formato de data do Windows pode ser diferente, vamos tentar um formato seguro (Ex: 2025-09-29_18-30)
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set DATE_STR=%%c-%%b-%%a
for /f "tokens=1-2 delims=:" %%a in ('time /t') do set TIME_STR=%%a%%b

set COMMIT_MSG="Backup do Projeto - %DATE_STR% as %TIME_STR%"

ECHO.
ECHO --- INICIANDO BACKUP DO PROJETO N8N ---
ECHO Mensagem de Commit: %COMMIT_MSG%
ECHO.

:: 2. Para o container n8n (Garante que os arquivos temporarios estao liberados)
ECHO Parando container N8N...
docker compose stop

:: 3. Adiciona todas as mudancas (incluindo JSONs de workflow e o .gitignore)
ECHO Adicionando mudancas ao Git...
git add .

:: 4. Cria o Commit com a data e hora
ECHO Criando Commit...
git commit -m %COMMIT_MSG%

:: Verifica se houve algo para commitar
if errorlevel 1 (
    ECHO.
    ECHO [ALERTA] Nenhuma mudanca detectada desde o ultimo backup.
    GOTO END
)

:: 5. Envia o backup para o GitHub
ECHO Enviando backup para o GitHub...
git push

:END
ECHO.
ECHO --- BACKUP CONCLUIDO! ---
PAUSE
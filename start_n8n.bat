@echo off
ECHO Iniciando o Docker Desktop (se nao estiver rodando)...
start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"

ECHO.
ECHO Navegando para a pasta do projeto...
D:
cd "D:\Micro Samuel Atual\Documentos\n8n-project"

ECHO.
ECHO Iniciando/Garantindo que o container n8n esteja rodando...
docker compose up -d

ECHO.
ECHO --- VERIFICANDO STATUS DO N8N ---

:STARTUP_CHECK
ECHO Tentando conectar ao N8N (porta 5678)...
:: Tenta se conectar a porta 5678. Curl retorna 0 (sucesso) se conseguir conectar.
curl --silent --fail http://localhost:5678/ > NUL

if %errorlevel% equ 0 (
    GOTO SUCCESS
) else (
    ECHO N8N ainda nao responde. Aguardando 5 segundos...
    timeout /t 5 /nobreak > NUL
    GOTO STARTUP_CHECK
)

:SUCCESS
ECHO.
ECHO [SUCESSO] N8N esta pronto!

ECHO.
ECHO Abrindo o n8n no Chrome (http://localhost:5678)...
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" "http://localhost:5678"

ECHO.
ECHO O ambiente n8n esta rodando. Feche esta janela para parar o processo.
PAUSE
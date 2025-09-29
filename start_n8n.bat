@echo off
ECHO Iniciando o Docker Desktop (se nao estiver rodando)...
start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"

ECHO.
ECHO Aguardando 10 segundos para o Docker inicializar...
timeout /t 10 /nobreak

ECHO.
ECHO Navegando para a pasta do projeto...
D:
cd "D:\Micro Samuel Atual\Documentos\n8n-project"

ECHO.
ECHO Iniciando o container n8n...
docker compose start

ECHO.
ECHO Abrindo o n8n no Chrome (http://localhost:5678)...
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" "http://localhost:5678"

ECHO.
ECHO O ambiente n8n esta rodando. Feche esta janela para parar o processo.
PAUSE
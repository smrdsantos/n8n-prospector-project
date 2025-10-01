@echo off
SETLOCAL EnableDelayedExpansion

ECHO Iniciando o Docker Desktop (se nao estiver rodando)...
start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"

ECHO.
ECHO Navegando para a pasta do projeto...
D:
cd "D:\Micro Samuel Atual\Documentos\n8n-project"

ECHO.
ECHO Iniciando/Garantindo que os containers Docker estejam rodando...
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
ECHO [SUCESSO] O Stack de Dados esta pronto!

ECHO.
ECHO Gerando dashboard de acesso (startup_info.html)...

:: --------------------------------------------------------------------------------
:: GERAÇÃO DO ARQUIVO HTML COM O DASHBOARD DE ACESSO
:: --------------------------------------------------------------------------------
ECHO ^<html^>^<head^>^<title^>Ambiente de Dados - Acessos^</title^>^</head^>^<body style="font-family: Arial, sans-serif; padding: 20px; background-color: #f4f4f9;"^> > startup_info.html
ECHO ^<h1 style="color: #007bff;"^>Ambiente de Engenharia de Dados - Acessos^</h1^> >> startup_info.html
ECHO ^<p^>O seu stack Docker (n8n, PostgreSQL, JupyterLab e Airbyte) iniciou com sucesso!^</p^> >> startup_info.html
ECHO ^<h2 style="color: #333;"^>Detalhes dos Servi^ços:^</h2^> >> startup_info.html
ECHO ^<table border="1" style="width: 80%; border-collapse: collapse; margin-top: 20px;"^> >> startup_info.html
ECHO ^<tr style="background-color: #e9ecef;"^>^<th style="padding: 10px; text-align: left;"^>Servi^ço^</th^>^<th style="padding: 10px; text-align: left;"^>Fun^ção^</th^>^<th style="padding: 10px; text-align: left;"^>Endere^ço^</th^>^<th style="padding: 10px; text-align: left;"^>Credenciais^</th^>^</tr^> >> startup_info.html
ECHO ^<tr^>^<td style="padding: 10px;"^>n8n^</td^>^<td style="padding: 10px;"^>Orquestra^ção (Fluxo de Dados)^</td^>^<td style="padding: 10px;"^>^<a href="http://localhost:5678" target="_blank"^>http://localhost:5678^</a^>^</td^>^<td style="padding: 10px;"^>Seu e-mail e ^<strong^>senha de propriet^ário^</strong^>.^</td^>^</tr^> >> startup_info.html
ECHO ^<tr^>^<td style="padding: 10px;"^>JupyterLab^</td^>^<td style="padding: 10px;"^>Python/An^álise de Dados^</td^>^<td style="padding: 10px;"^>^<a href="http://localhost:8888" target="_blank"^>http://localhost:8888^</a^>^</td^>^<td style="padding: 10px;"^>Entrar com o ^<strong^>Token de Acesso^</strong^>.^</td^>^</tr^> >> startup_info.html
ECHO ^<tr^>^<td style="padding: 10px;"^>Airbyte Web^</td^>^<td style="padding: 10px;"^>Conectores (Extra^ção/Carga)^</td^>^<td style="padding: 10px;"^>^<a href="http://localhost:8000" target="_blank"^>http://localhost:8000^</a^>^</td^>^<td style="padding: 10px;"^>(Acesso direto via navegador)^</td^>^</tr^> >> startup_info.html
ECHO ^</table^> >> startup_info.html
ECHO ^<p style="margin-top: 30px; font-size: 0.9em; color: #666;"^>^<strong^>Lembrete:^</strong^> O Token do JupyterLab ^é o mesmo que a sua senha forte do banco de dados.^</p^> >> startup_info.html
ECHO ^<p style="margin-top: 20px; font-size: 0.9em; color: #666;"^>Para desligar o ambiente, retorne ^à janela do PowerShell e pressione Ctrl+C, ou feche a janela do terminal.^</p^> >> startup_info.html
ECHO ^</body^>^</html^> >> startup_info.html

ECHO.
ECHO Abrindo o Dashboard de Acesso no Chrome...
start "" "startup_info.html"

ECHO.
ECHO O ambiente completo esta rodando. Feche esta janela para parar o processo.
PAUSE
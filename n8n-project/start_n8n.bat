@echo off

ECHO ==========================================================
ECHO INICIANDO AMBIENTE COMPLETO DE ENGENHARIA DE DADOS
ECHO ==========================================================
ECHO.

ECHO Iniciando o Docker Desktop (se nao estiver rodando)...
start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
ECHO Aguardando 15 segundos para o Docker inicializar...
timeout /t 15 /nobreak > NUL
ECHO Docker deve estar pronto.
ECHO.
PAUSE

ECHO.
ECHO --- INICIANDO STACK DE DADOS (N8N, POSTGRES, JUPYTER) ---
ECHO Navegando para a pasta do projeto n8n...
D:
cd "D:\Micro Samuel Atual\Documentos\n8n-project"
docker compose up -d
ECHO.
ECHO Stack N8N iniciado. Verifique a saida acima.
ECHO.
PAUSE

ECHO.
ECHO --- INICIANDO STACK DE ETL (MAGE) ---
ECHO Navegando para a pasta principal do Mage...
D:
cd "D:\Micro Samuel Atual\documentos\Mage-Projetos"

ECHO Verificando o container 'mage-etl'...
docker start mage-etl > NUL 2>&1
if %errorlevel% equ 0 (
    ECHO [INFO] Container 'mage-etl' ja existia e foi iniciado.
) else (
    ECHO [INFO] Container 'mage-etl' nao encontrado. Criando e iniciando um novo...
    docker run -d --name mage-etl -p 6789:6789 -v %cd%:/home/src --network n8n-project_default mageai/mageai mage start pipeline_inicial
)
ECHO.
ECHO Stack Mage iniciado. Verifique a saida acima.
ECHO.
PAUSE

ECHO.
ECHO --- VERIFICANDO STATUS DOS SERVICOS ---
ECHO Esta etapa pode levar alguns instantes...

:CHECK_N8N
ECHO Tentando conectar ao N8N (porta 5678)...
curl --silent --fail http://localhost:5678/ > NUL
if %errorlevel% equ 0 (
    ECHO [OK] N8N esta no ar.
    GOTO CHECK_MAGE
) else (
    ECHO N8N ainda nao responde. Aguardando 5 segundos...
    timeout /t 5 /nobreak > NUL
    GOTO CHECK_N8N
)

:CHECK_MAGE
ECHO Tentando conectar ao Mage (porta 6789)...
curl --silent --fail http://localhost:6789/ > NUL
if %errorlevel% equ 0 (
    ECHO [OK] Mage esta no ar.
) else (
    ECHO Mage ainda nao responde. Aguardando 5 segundos...
    timeout /t 5 /nobreak > NUL
    GOTO CHECK_MAGE
)

ECHO.
ECHO [SUCESSO] O Stack de Dados completo esta pronto!
ECHO.
PAUSE

ECHO.
ECHO [DEBUG] Preparando para gerar o dashboard...
ECHO Gerando dashboard de acesso...

REM ====== GARANTE DIRETORIO CORRETO (Sua sugestao implementada) ======
cd /d "D:\Micro Samuel Atual\Documentos\n8n-project"

REM ====== BLOCO DE GERAÇÃO DE HTML ======
(
    ECHO ^<html^>^<head^>^<title^>Ambiente de Dados - Acessos^</title^>^</head^>
    ECHO ^<body style="font-family: Arial, sans-serif; padding: 20px; background-color: #f4f4f9;"^>
    ECHO ^<h1 style="color: #007bff;"^>Ambiente de Engenharia de Dados - Acessos^</h1^>
    ECHO ^<p^>Seu stack Docker (n8n, PostgreSQL, JupyterLab e Mage) esta online!^</p^>
    ECHO ^<h2 style="color: #333;"^>Detalhes dos Servi^ços:^</h2^>
    ECHO ^<table border="1" style="width: 80%%; border-collapse: collapse; margin-top: 20px;"^>
    ECHO ^<tr style="background-color: #e9ecef;"^>^<th style="padding: 10px; text-align: left;"^>Servi^ço^</th^>^<th style="padding: 10px; text-align: left;"^>Fun^ção^</th^>^<th style="padding: 10px; text-align: left;"^>Endere^ço^</th^>^<th style="padding: 10px; text-align: left;"^>Credenciais^</th^>^</tr^>
    ECHO ^<tr^>^<td style="padding: 10px;"^>Mage^</td^>^<td style="padding: 10px;"^>ETL e Orquestra^ção de Pipelines^</td^>^<td style="padding: 10px;"^>^<a href="http://localhost:6789" target="_blank"^>http://localhost:6789^</a^>^</td^>^<td style="padding: 10px;"^>Login com ^<strong^>seu usu^ário Owner^</strong^> (ou admin@admin.com / admin).^</td^>^</tr^>
    ECHO ^<tr^>^<td style="padding: 10px;"^>n8n^</td^>^<td style="padding: 10px;"^>Automa^ção de Workflows^</td^>^<td style="padding: 10px;"^>^<a href="http://localhost:5678" target="_blank"^>http://localhost:5678^</a^>^</td^>^<td style="padding: 10px;"^>Login com ^<strong^>seu usu^ário Owner^</strong^>.^</td^>^</tr^>
    ECHO ^<tr^>^<td style="padding: 10px;"^>JupyterLab^</td^>^<td style="padding: 10px;"^>An^álise de Dados com Python^</td^>^<td style="padding: 10px;"^>^<a href="http://localhost:8888" target="_blank"^>http://localhost:8888^</a^>^</td^>^<td style="padding: 10px;"^>Token: ^<strong^>!C293112c!^</strong^>^</td^>^</tr^>
    ECHO ^</table^>
    ECHO ^<p style="margin-top: 30px; font-size: 0.9em; color: #666;"^>^<strong^>Lembrete:^</strong^> Para desligar todo o ambiente, execute o script ^<strong^>stop_ambiente.bat^</strong^>.^</p^>
    ECHO ^</body^>^</html^>
) > "dashboard_acessos.html"

ECHO [DEBUG] Bloco de geracao finalizado. Verificando se o arquivo existe...

if exist "dashboard_acessos.html" (
    ECHO [DEBUG] Dashboard gerado com sucesso em 'D:\Micro Samuel Atual\Documentos\n8n-project\'.
) else (
    ECHO [ERRO] Falha na geracao do dashboard! Verifique as permissoes da pasta.
)
ECHO.
PAUSE

ECHO.
ECHO Abrindo o Dashboard de Acesso no seu navegador...
start "" "dashboard_acessos.html"

ECHO.
ECHO O ambiente completo esta rodando.
ECHO Pressione qualquer tecla para finalizar este script (os containers continuarão rodando em segundo plano).
PAUSE
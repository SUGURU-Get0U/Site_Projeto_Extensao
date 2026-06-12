# Inicia o sistema SXF com a chave de criptografia correta.
# Use SEMPRE este script para rodar o app (assim os campos criptografados
# - CPF, telefone, e-mail - aparecem corretamente).
#
# Como rodar:  clique direito > "Executar com PowerShell"  ou no terminal:  .\iniciar.ps1

$env:ENCRYPTION_KEY  = "MUk5mne5GP5v6p9Ao7YywJP9w0weCBCgBoOCc4LaJhk="
$env:FLASK_SECRET_KEY = "sxf-secret-fixo-2026"

Write-Host "Iniciando SXF Sistema em http://127.0.0.1:5000 ..." -ForegroundColor Cyan
python -m flask --app app.app run

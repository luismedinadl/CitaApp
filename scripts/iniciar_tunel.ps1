# Expone la API local con una URL HTTPS temporal de Cloudflare.
# Mantén esta ventana abierta mientras usas CitaApp desde otra red.
$root = Split-Path -Parent $PSScriptRoot
$cloudflared = Join-Path $root 'tools\cloudflared.exe'

if (-not (Test-Path $cloudflared)) {
    throw 'No se encontró tools\cloudflared.exe.'
}

& $cloudflared tunnel --url http://127.0.0.1:8080

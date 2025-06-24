# Configuración
$zoneId = "e79e24ad6d3c2db485322f155502a556"
$recordId = "4f6e57603e46ccb60615f19782ae7a0c"
$apiToken = "ZFYfAKE9Wyq2PQiRKTsGYAuEbpK41TMCjoxAD32z"
$recordName = "cybergos.com.ar"
$recordType = "A"
$ttl = 300
$proxied = $false

# Obtener IP pública actual
$currentIP = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json").ip

# Ruta al archivo que guarda la IP anterior
$ipFile = "$PSScriptRoot\last_ip.txt"

# Leer la IP anterior
$lastIP = if (Test-Path $ipFile) { Get-Content $ipFile -Raw } else { "" }

if ($currentIP -ne $lastIP) {
    Write-Host "La IP ha cambiado de $lastIP a $currentIP. Actualizando en Cloudflare..."

    # Payload para la actualización
    $body = @{
        type = $recordType
        name = $recordName
        content = $currentIP
        ttl = $ttl
        proxied = $proxied
    } | ConvertTo-Json -Depth 3
##
## https://api.cloudflare.com/client/v4/accounts/4f6e57603e46ccb60615f19782ae7a0c/tokens/verify"  -H "Authorization: Bearer ZFYfAKE9Wyq2PQiRKTsGYAuEbpK41TMCjoxAD32z"

    # Llamada a la API
    $response = Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records/$recordId" `
        -Method PUT `
        -Headers @{ "Authorization" = "Bearer $apiToken"; "Content-Type" = "application/json" } `
        -Body $body

    if ($response.success) {
        Write-Host "✅ IP actualizada correctamente en Cloudflare."
        Set-Content -Path $ipFile -Value $currentIP
    } else {
        Write-Host "❌ Error al actualizar la IP en Cloudflare:" $response.errors
    }
} else {
    Write-Host "✔️ La IP no ha cambiado. No se realiza ninguna actualización."
}

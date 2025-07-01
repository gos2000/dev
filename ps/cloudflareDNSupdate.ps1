# Configuración
$zoneId = "e79e24ad6d3c2db485322f155502a556"
$apiToken = "ZFYfAKE9Wyq2PQiRKTsGYAuEbpK41TMCjoxAD32z"
$recordNames = @("cybergos.net.ar", "gitlab.cybergos.net.ar", "app.cybergos.net.ar")  # Lista de registros a actualizar
$recordType = "A"
$ttl = 300  # Solo se usa si el registro no está proxied
$proxied = $true  # Este valor se ignora - el script preserva la configuración actual de cada registro

Write-Host "=== Cloudflare DNS Updater ==="
Write-Host "Registros a procesar: $($recordNames -join ', ')"
Write-Host "Tipo de registro: $recordType"
Write-Host "TTL: $ttl"
Write-Host "Proxied: $proxied"
Write-Host "================================"

# Validar configuración
if (-not $zoneId -or -not $apiToken -or $recordNames.Count -eq 0) {
    Write-Host "❌ Error: Faltan datos de configuración (zoneId, apiToken, o recordNames)"
    exit 1
}

# Función para actualizar un registro DNS específico
function Update-DNSRecord {
    param(
        [string]$ZoneId,
        [string]$RecordName,
        [string]$NewIP,
        [string]$ApiToken,
        [string]$RecordType,
        [int]$TTL,
        [bool]$Proxied
    )
    
    # Buscar el registro DNS y obtener su configuración actual
    $recordInfo = Find-DNSRecord -ZoneId $ZoneId -RecordName $RecordName -ApiToken $ApiToken
    if (-not $recordInfo) {
        Write-Host "❌ No se pudo encontrar el registro para $RecordName"
        return $false
    }
    
    # Usar la configuración actual del proxy en lugar de la configuración global
    $currentProxied = $recordInfo.proxied
    $currentTTL = if ($currentProxied) { 1 } else { $recordInfo.ttl }  # TTL automático si está proxied
    
    # Preparar payload preservando la configuración actual de proxy
    $body = @{
        type = $RecordType
        name = $RecordName
        content = $NewIP
        ttl = $currentTTL
        proxied = $currentProxied
    } | ConvertTo-Json -Depth 3
    
    $proxyStatus = if ($currentProxied) { "🟠 Proxied" } else { "🔘 DNS Only" }
    Write-Host "📤 Actualizando $RecordName ($proxyStatus)..."
    Write-Host "   URL: https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records/$($recordInfo.id)"
    
    try {
        $response = Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records/$($recordInfo.id)" `
            -Method PATCH `
            -Headers @{ "Authorization" = "Bearer $ApiToken"; "Content-Type" = "application/json" } `
            -Body $body

        if ($response.success) {
            $finalProxyStatus = if ($response.result.proxied) { "🟠 Proxied" } else { "🔘 DNS Only" }
            Write-Host "   ✅ $RecordName actualizado: $($response.result.content) ($finalProxyStatus)"
            return $true
        } else {
            Write-Host "   ❌ Error al actualizar ${RecordName}:"
            $response.errors | ForEach-Object { Write-Host "     - $_" }
            return $false
        }
    }
    catch {
        Write-Host "   ❌ Error de conexión para ${RecordName}: $($_.Exception.Message)"
        return $false
    }
}

# Función para buscar el registro DNS correcto
function Find-DNSRecord {
    param(
        [string]$ZoneId,
        [string]$RecordName,
        [string]$ApiToken
    )
    
    try {
        Write-Host "🔍 Buscando registro DNS para $RecordName..."
        $response = Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records?name=$RecordName&type=A" `
            -Method GET `
            -Headers @{ "Authorization" = "Bearer $ApiToken"; "Content-Type" = "application/json" }
        
        if ($response.success -and $response.result.Count -gt 0) {
            $record = $response.result[0]
            $proxyStatus = if ($record.proxied) { "🟠 Proxied" } else { "🔘 DNS Only" }
            Write-Host "✅ Registro encontrado: $($record.name) -> $($record.content) ($proxyStatus) (ID: $($record.id))"
            return @{
                id = $record.id
                proxied = $record.proxied
                ttl = $record.ttl
            }
        } else {
            Write-Host "❌ No se encontró el registro DNS para $RecordName"
            return $null
        }
    }
    catch {
        Write-Host "❌ Error al buscar el registro DNS: $($_.Exception.Message)"
        return $null
    }
}

# Función para verificar la zona
function Test-Zone {
    param(
        [string]$ZoneId,
        [string]$ApiToken
    )
    
    try {
        Write-Host "🔍 Verificando zona..."
        $response = Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneId" `
            -Method GET `
            -Headers @{ "Authorization" = "Bearer $ApiToken"; "Content-Type" = "application/json" }
        
        if ($response.success) {
            Write-Host "✅ Zona verificada: $($response.result.name) (ID: $($response.result.id))"
            return $true
        } else {
            Write-Host "❌ Zona no válida"
            return $false
        }
    }
    catch {
        Write-Host "❌ Error al verificar la zona: $($_.Exception.Message)"
        return $false
    }
}

# Función para listar zonas disponibles
function Get-AvailableZones {
    param(
        [string]$ApiToken
    )
    
    try {
        Write-Host "🔍 Obteniendo zonas disponibles..."
        $response = Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/zones" `
            -Method GET `
            -Headers @{ "Authorization" = "Bearer $ApiToken"; "Content-Type" = "application/json" }
        
        if ($response.success) {
            Write-Host "📋 Zonas disponibles:"
            foreach ($zone in $response.result) {
                Write-Host "  - $($zone.name) (ID: $($zone.id))"
            }
            return $response.result
        } else {
            Write-Host "❌ No se pudieron obtener las zonas"
            return $null
        }
    }
    catch {
        Write-Host "❌ Error al obtener las zonas: $($_.Exception.Message)"
        return $null
    }
}

# Verificar configuración de Cloudflare
Write-Host "🔍 Verificando configuración de Cloudflare..."

# Primero verificar la zona
if (-not (Test-Zone -ZoneId $zoneId -ApiToken $apiToken)) {
    Write-Host "❌ La zona especificada no es válida. Verifique el zoneId."
    Write-Host ""
    Get-AvailableZones -ApiToken $apiToken
    exit 1
}

# Verificar que todos los registros existan
Write-Host "🔍 Verificando registros DNS..."
$validRecords = @()
foreach ($recordName in $recordNames) {
    $recordInfo = Find-DNSRecord -ZoneId $zoneId -RecordName $recordName -ApiToken $apiToken
    if ($recordInfo) {
        $validRecords += @{
            Name = $recordName
            Id = $recordInfo.id
            Proxied = $recordInfo.proxied
            TTL = $recordInfo.ttl
        }
        Write-Host "✅ $recordName encontrado"
    } else {
        Write-Host "❌ $recordName no encontrado - será omitido"
    }
}

if ($validRecords.Count -eq 0) {
    Write-Host "❌ No se encontraron registros DNS válidos."
    exit 1
}

# Obtener IP pública actual
Write-Host "Obteniendo IP pública actual..."
try {
    $currentIP = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -TimeoutSec 10).ip
    Write-Host "IP actual: $currentIP"
}
catch {
    Write-Host "❌ Error al obtener la IP pública: $($_.Exception.Message)"
    exit 1
}

# Ruta al archivo que guarda la IP anterior
$ipFile = "$PSScriptRoot\last_ip.txt"

# Leer la IP anterior
$lastIP = if (Test-Path $ipFile) { 
    $content = (Get-Content $ipFile -Raw).Trim()
    Write-Host "IP anterior: $content"
    $content
} else { 
    Write-Host "No hay IP anterior guardada."
    "" 
}

if ($currentIP -ne $lastIP) {
    Write-Host "🔄 La IP ha cambiado de '$lastIP' a '$currentIP'. Actualizando registros DNS..."
    
    $successCount = 0
    $totalCount = $validRecords.Count
    
    foreach ($record in $validRecords) {
        if (Update-DNSRecord -ZoneId $zoneId -RecordName $record.Name -NewIP $currentIP -ApiToken $apiToken -RecordType $recordType -TTL $ttl -Proxied $proxied) {
            $successCount++
        }
    }
    
    Write-Host ""
    Write-Host "📊 Resumen de actualización:"
    Write-Host "   ✅ Exitosos: $successCount de $totalCount"
    
    if ($successCount -eq $totalCount) {
        Write-Host "🎉 Todos los registros fueron actualizados correctamente."
        Set-Content -Path $ipFile -Value $currentIP
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path "$PSScriptRoot\update_log.txt" -Value "$timestamp - IP actualizada: $lastIP -> $currentIP (Registros: $($recordNames -join ', '))"
    } elseif ($successCount -gt 0) {
        Write-Host "⚠️ Algunos registros fueron actualizados, pero otros fallaron."
        Set-Content -Path $ipFile -Value $currentIP
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path "$PSScriptRoot\update_log.txt" -Value "$timestamp - IP parcialmente actualizada: $lastIP -> $currentIP ($successCount de $totalCount registros)"
    } else {
        Write-Host "❌ No se pudo actualizar ningún registro."
    }
} else {
    Write-Host "✔️ La IP no ha cambiado ($currentIP). No se realiza ninguna actualización."
}

Write-Host "================================"
Write-Host "Script ejecutado el: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

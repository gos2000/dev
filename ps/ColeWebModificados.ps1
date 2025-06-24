# Ruta donde están los archivos a revisar
$sourceFolder = "C:\gabriel\repo\IntSchools\Schools\Schools"

# Carpeta donde se guardará el archivo ZIP
$outputFolder = "C:\gabriel\_autoPublish\schools_web"

# Solicitar al usuario cuántos días atrás buscar archivos modificados
Write-Host "Seleccionar fecha para buscar archivos modificados:" -ForegroundColor Cyan
Write-Host "0 = Hoy ($((Get-Date).ToString('yyyy-MM-dd')))" -ForegroundColor Green
Write-Host "1 = Ayer ($((Get-Date).AddDays(-1).ToString('yyyy-MM-dd')))" -ForegroundColor Yellow
Write-Host "2 = Hace 2 días ($((Get-Date).AddDays(-2).ToString('yyyy-MM-dd')))" -ForegroundColor Yellow
Write-Host "3 = Hace 3 días ($((Get-Date).AddDays(-3).ToString('yyyy-MM-dd')))" -ForegroundColor Yellow
Write-Host "Presiona Enter para usar hoy (0) o ingresa el número de días atrás:" -ForegroundColor White

$daysBack = Read-Host
if ([string]::IsNullOrWhiteSpace($daysBack) -or $daysBack -eq "0") {
    $daysBack = 0
    $selectedDate = Get-Date
} else {
    try {
        $daysBack = [int]$daysBack
        if ($daysBack -lt 0) {
            Write-Host "⚠️ Número inválido, usando hoy (0)" -ForegroundColor Yellow
            $daysBack = 0
            $selectedDate = Get-Date        } else {
            $selectedDate = (Get-Date).AddDays(-$daysBack)
        }
    } catch {
        Write-Host "⚠️ Entrada inválida, usando hoy (0)" -ForegroundColor Yellow
        $daysBack = 0
        $selectedDate = Get-Date
    }
}

Write-Host "📅 Buscando archivos modificados el: $($selectedDate.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan

# Nombre del archivo ZIP (con fecha seleccionada)
$dateString = $selectedDate.ToString("yyyyMMdd HHmm")
$zipFileName = "ArchivosModificados_aspx_$($selectedDate.ToString('yyyyMMdd'))_$dateString.zip"
$zipFilePath = Join-Path $outputFolder $zipFileName

# Obtener archivos modificados en la fecha seleccionada, excluyendo carpetas obj, cacheboletin, _logs
$targetDate = $selectedDate.ToString("yyyy-MM-dd")
$excludeFolders = @('obj', 'cacheboletin', '_log','controllers','_Logs')
$filesToInclude = Get-ChildItem -Path $sourceFolder -Recurse -File | Where-Object {
    $_.LastWriteTime.ToString("yyyy-MM-dd") -eq $targetDate -and
    ($excludeFolders -notcontains $_.Directory.Name) -and
    ($excludeFolders -notcontains $_.Directory.Parent?.Name)
}

if ($filesToInclude) {
    # Crear carpeta temporal para preparar los archivos con su estructura
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tempRoot | Out-Null

    foreach ($file in $filesToInclude) {
        # Calcular la ruta relativa dentro de la carpeta fuente
        $relativePath = $file.FullName.Substring($sourceFolder.Length + 1)
        
        # Definir destino en la carpeta temporal
        $destPath = Join-Path $tempRoot (Split-Path $relativePath)

        # Crear la estructura de carpetas si no existe
        if (-not (Test-Path $destPath)) {
            New-Item -ItemType Directory -Path $destPath | Out-Null
        }

        # Copiar archivo manteniendo estructura
        Copy-Item -Path $file.FullName -Destination $destPath
    }    # Comprimir toda la carpeta temporal (con estructura completa)
    Compress-Archive -Path "$tempRoot\*" -DestinationPath $zipFilePath -CompressionLevel Optimal -Force

    # Limpiar carpeta temporal
    Remove-Item -Path $tempRoot -Recurse -Force

    Write-Host "✅ Archivo ZIP creado: $zipFilePath" -ForegroundColor Green
    Write-Host "📊 Total de archivos incluidos: $($filesToInclude.Count)" -ForegroundColor Green
} else {
    Write-Host "ℹ️ No se encontraron archivos modificados el $($selectedDate.ToString('yyyy-MM-dd'))." -ForegroundColor Yellow
}

explorer.exe $outputFolder 
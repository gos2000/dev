# Ruta donde están los archivos a revisar
$sourceFolder = "C:/gabriel/repo/padeli/Macnab/Src/PadeliSrc/macnab_web/bin/Release/net6.0"

# Carpeta donde se guardará el archivo ZIP
$outputFolder = "C:\gabriel\_autoPublish\padeli_web"
 
# Nombre del archivo ZIP (con fecha actual)
$dateString = Get-Date -Format "yyyyMMdd hhmm"
$zipFileName = "ArchivosModificados_$dateString.zip"
$zipFilePath = Join-Path $outputFolder $zipFileName

# Obtener archivos modificados hoy, excluyendo carpetas obj, cacheboletin, _logs
$today = Get-Date -UFormat "%Y-%m-%d"
$excludeFolders = @('obj', 'cacheboletin', '_log','controllers','_Logs',
                "Controllers", 
                "obj", 
                "Logs", 
                "Exports",
                "reactApp",
                "Files",
                ".csproj.",
                "Microsoft",
                "System",
                "SQL",
                "Serilog",
                "Rotativa",
                "Entity",
                "Castle",
                "Humanizer",
                "EPPlus",
                "dotnet",
                "Dapper",
                "Newtonsoft",
                "RestSharp",
                "win-x64",
                "Macnab.deps",
                "pdb",
                "cache")

$filesToInclude = Get-ChildItem -Path $sourceFolder -Recurse -File | Where-Object {
    $_.LastWriteTime.ToString("yyyy-MM-dd") -eq $today -and
    ($excludeFolders -notcontains $_.Directory.Name) -and
    ($excludeFolders -notcontains $_.Directory.Parent?.Name) -and
    ($excludeFolders -notcontains $_.Name)
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
    }

    # Comprimir toda la carpeta temporal (con estructura completa)
   Compress-Archive -Path "$tempRoot\*" -DestinationPath $zipFilePath -CompressionLevel Optimal -Force

    # Limpiar carpeta temporal
    Remove-Item -Path $tempRoot -Recurse -Force

    Write-Host "✅ Archivo ZIP creado: $zipFilePath" -ForegroundColor Green
} else {
  Write-Host "ℹ️ No se encontraron archivos modificados hoy." -ForegroundColor Yellow
}

explorer.exe $outputFolder
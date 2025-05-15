function Get-LastModifiedZip {
    param([string]$folder)
    return Get-ChildItem -Path $folder -Filter "ArchivosModificados_*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

function Initialize-InFolder {
    param([string]$inFolder)
    if ([string]::IsNullOrWhiteSpace($inFolder)) {
        Write-Host "La variable yourInFolder no está definida correctamente." -ForegroundColor Red
        exit 1
    }
    if (Test-Path $inFolder) { Remove-Item -Path $inFolder -Recurse -Force }
    New-Item -ItemType Directory -Path $inFolder -Force | Out-Null
}

function Expand-ArchiveToFolder {
    param([string]$zipPath, [string]$inFolder)
    Expand-Archive -Path $zipPath -DestinationPath $inFolder -Force
}

function Get-FilesToBackup {
    param([string]$inFolder, [string]$sourceFolder)
    return Get-ChildItem -Path $inFolder -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($inFolder.Length + 1)
        $sourceFile = Join-Path $sourceFolder $relativePath
        if (Test-Path $sourceFile) { $sourceFile }
    }
}

function Test-FilesAreDifferent {
    param(
        [array]$filesToBackup,
        [string]$inFolder,
        [string]$sourceFolder
    )
    $archivosDiferentes = $false
    foreach ($file in $filesToBackup) {
        $relativePath = $file.Substring($sourceFolder.Length + 1)
        $inFile = Join-Path $inFolder $relativePath
        if (Test-Path $inFile) {
            $hashSource = Get-FileHash -Path $file -Algorithm SHA256
            $hashIn = Get-FileHash -Path $inFile -Algorithm SHA256
            if ($hashSource.Hash -ne $hashIn.Hash) {
                $archivosDiferentes = $true
                break
            }
        } else {
            $archivosDiferentes = $true
            break
        }
    }
    return $archivosDiferentes
}

function Backup-OriginalFiles {
    param(
        [array]$filesToBackup,
        [string]$sourceFolder,
        [string]$backupZipPath
    )
    if ($filesToBackup) {
        $tempBackupRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempBackupRoot | Out-Null

        foreach ($file in $filesToBackup) {
            $relativePath = $file.Substring($sourceFolder.Length + 1)
            $destPath = Join-Path $tempBackupRoot (Split-Path $relativePath)
            if (-not (Test-Path $destPath)) {
                New-Item -ItemType Directory -Path $destPath | Out-Null
            }
            Copy-Item -Path $file -Destination $destPath
        }

        Compress-Archive -Path "$tempBackupRoot\*" -DestinationPath $backupZipPath -CompressionLevel Optimal -Force
        Remove-Item -Path $tempBackupRoot -Recurse -Force
        Write-Host "✅ Backup ZIP creado: $backupZipPath" -ForegroundColor Green
    } else {
        Write-Host "ℹ️ No se encontraron archivos para respaldar." -ForegroundColor Yellow
    }
}

function Copy-RestoredFilesToSource {
    param([string]$inFolder, [string]$sourceFolder)
    Write-Host "Copiando archivos restaurados a $sourceFolder..." -ForegroundColor Cyan
    Get-ChildItem -Path $inFolder -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($inFolder.Length + 1)
        $destFile = Join-Path $sourceFolder $relativePath
        $destDir = Split-Path $destFile
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item -Path $_.FullName -Destination $destFile -Force
    }
    Write-Host "✅ Archivos restaurados copiados a $sourceFolder" -ForegroundColor Green
}

function Restore-FromBackupZip {
    param (
        [string]$backupZipPath,
        [string]$restoreFolder
    )

    if (-not (Test-Path $backupZipPath)) {
        Write-Host "No se encontró el archivo de backup: $backupZipPath" -ForegroundColor Red
        return
    }

    $tempRestore = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tempRestore | Out-Null

    try {
        Expand-Archive -Path $backupZipPath -DestinationPath $tempRestore -Force

        Get-ChildItem -Path $tempRestore -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($tempRestore.Length + 1)
            $destFile = Join-Path $restoreFolder $relativePath
            $destDir = Split-Path $destFile
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item -Path $_.FullName -Destination $destFile -Force
        }
        Write-Host "✅ Archivos restaurados desde el backup ZIP a $restoreFolder" -ForegroundColor Green
    } finally {
        Remove-Item -Path $tempRestore -Recurse -Force
    }
}

Export-ModuleMember -Function Get-LastModifiedZip,Initialize-InFolder,Expand-ArchiveToFolder,Get-FilesToBackup,Test-FilesAreDifferent,Backup-OriginalFiles,Copy-RestoredFilesToSource,Restore-FromBackupZip

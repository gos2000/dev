# Importar el módulo de utilidades
Import-Module "$PSScriptRoot\RestoreAndBackupUtils.psm1"

# --- FLUJO PRINCIPAL ---

$zipFile = Get-LastModifiedZip -folder "C:\gabriel\_autoPublish\schools_web"
if (-not $zipFile) {
    Write-Host "No se encontró un archivo ZIP para restaurar." -ForegroundColor Yellow
    exit 1
}

$yourInFolder = "C:\gabriel\_autoPublish\schools_web\IN"
Prepare-InFolder -inFolder $yourInFolder

Expand-ZipToInFolder -zipPath $zipFile.FullName -inFolder $yourInFolder

$sourceFolder = "C:\publish\schollboletin"
$backupFolder = "C:\gabriel\_autoPublish\schools_web"
$dateString = Get-Date -Format "yyyyMMdd_hhmm"
$backupZipName = "BackupArchivosOriginales_$dateString.zip"
$backupZipPath = Join-Path $backupFolder $backupZipName

$filesToBackup = Get-FilesToBackup -inFolder $yourInFolder -sourceFolder $sourceFolder
Backup-OriginalFiles -filesToBackup $filesToBackup -sourceFolder $sourceFolder -backupZipPath $backupZipPath

Copy-RestoredFilesToSource -inFolder $yourInFolder -sourceFolder $sourceFolder

# Interacción para restaurar desde backup ZIP
$restoreAnswer = Read-Host "¿Desea restaurar los archivos originales desde el backup ZIP? (S/N)"
if ($restoreAnswer -eq "S" -or $restoreAnswer -eq "s") {
    Restore-FromBackupZip -backupZipPath $backupZipPath -restoreFolder $sourceFolder
    Write-Host "Restauración completada." -ForegroundColor Green
} else {
    Write-Host "No se realizó la restauración de los archivos originales." -ForegroundColor Yellow
}
# Importar el módulo de utilidades
Import-Module "$PSScriptRoot\RestoreAndBackupUtils.psm1" -Force

# Configuración de variables
$mostrarLog = $false  # Cambia a $false para ocultar logs
$deployfolder="C:\gabriel\_autoPublish\schools_web"
$filefolder = $deployfolder +"\INZIP"
$yourInFolder = $deployfolder +"\IN"
$sourceFolder = "C:\publish\schollboletin"
$backupFolder = "C:\gabriel\_autoPublish\schools_web"
$dateString = Get-Date -Format "yyyyMMdd_hhmm"
$backupZipName = "BackupArchivosOriginales_$dateString.zip"
$backupZipPath = Join-Path $backupFolder $backupZipName

# Configuración de logging
function Write-Log($mensaje) {
    if ($mostrarLog) {
        Write-Host "[LOG] $mensaje" -ForegroundColor Gray
    }
}

# --- FLUJO PRINCIPAL ---

$zipFile = Get-LastModifiedZip -folder $filefolder
if (-not $zipFile) {
    Write-Log "No se encontró un archivo ZIP para restaurar."
    Write-Host "No se encontró un archivo ZIP para restaurar." -ForegroundColor Yellow
    exit 1
}

Write-Log "Preparando carpeta IN: $yourInFolder"
Initialize-InFolder -inFolder $yourInFolder

Write-Log "Descomprimiendo ZIP: $($zipFile.FullName) en $yourInFolder"
Expand-ArchiveToFolder -zipPath $zipFile.FullName -inFolder $yourInFolder

Write-Log "Buscando archivos a respaldar en $sourceFolder comparando con $yourInFolder"
$filesToBackup = Get-FilesToBackup -inFolder $yourInFolder -sourceFolder $sourceFolder

Write-Log "Comparando archivos restaurados con los originales..."
$archivosDiferentes = Test-FilesAreDifferent -filesToBackup $filesToBackup -inFolder $yourInFolder -sourceFolder $sourceFolder

if ($archivosDiferentes) {
    Write-Log "Se detectaron diferencias. Realizando backup y copia."
    Backup-OriginalFiles -filesToBackup $filesToBackup -sourceFolder $sourceFolder -backupZipPath $backupZipPath
    Copy-RestoredFilesToSource -inFolder $yourInFolder -sourceFolder $sourceFolder
    Write-Host "Se realizó backup y copia de archivos modificados." -ForegroundColor Cyan
} else {
    Write-Log "No se detectaron diferencias. No se realiza backup ni copia."
    Write-Host "Los archivos restaurados son idénticos a los originales. No se realiza backup ni copia." -ForegroundColor Yellow
}

# Interacción para restaurar desde backup ZIP
##$restoreAnswer = Read-Host "¿Desea restaurar los archivos originales desde el backup ZIP? (S/N)"
if ($restoreAnswer -eq "S" -or $restoreAnswer -eq "s") {
    Write-Log "Restaurando archivos originales desde el backup ZIP: $backupZipPath"
    Restore-FromBackupZip -backupZipPath $backupZipPath -restoreFolder $sourceFolder
    Write-Host "Restauración completada." -ForegroundColor Green
} else {
    Write-Log "El usuario eligió no restaurar los archivos originales desde el backup ZIP."
    Write-Host "No se realizó la restauración de los archivos originales." -ForegroundColor Yellow
}
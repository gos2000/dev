# Define las variables
$Username = "Administrator"
$Password = "aristonLD00"

# Files/Paths
$remotePath = "macnab/backup"
$LatestTextFile = "macnabprod20241207.rar"

$ftpServer = "ftp://sgintschools.com.ar/$($remotePath)/$($LatestTextFile)"

$localPath = "C:\sqldata\macnab\$LatestTextFile"
Write-Host $ftpServer $localPath
$ftpUsername = "Administrator"
$ftpPassword = "aristonLD00"

# Crea una instancia de WebClient
$webClient = New-Object System.Net.WebClient

# Si el servidor FTP requiere autenticación, establece las credenciales
$webClient.Credentials = New-Object System.Net.NetworkCredential($ftpUsername, $ftpPassword)

# Descarga el archivo
$webClient.DownloadFile($ftpServer, $localPath)

# Limpia la instancia de WebClient
$webClient.Dispose()

Write-Output "Archivo descargado exitosamente a $localPath"
Set-Location C:\SqlData\macnab

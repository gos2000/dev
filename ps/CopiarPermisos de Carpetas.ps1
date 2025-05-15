# Definir las rutas de las carpetas
$carpetaOrigen = "C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Backup"
$carpetaDestino = "F:\SqlData"

# Obtener los permisos (ACLs) de la carpeta de origen
$acl = Get-Acl -Path $carpetaOrigen

# Aplicar los permisos a la carpeta de destino
Set-Acl -Path $carpetaDestino -AclObject $acl

# Mensaje de confirmación
Write-Host "Los permisos se han copiado correctamente de '$carpetaOrigen' a '$carpetaDestino'."
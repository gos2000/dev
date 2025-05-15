# Auth
$Username = "Administrator"
$Password = "aristonLD00"

# Files/Paths
$remotePath = "macnab/publish/in"
 
$LocalDir = "C:\Gabriel\_autoPublish\macnab_web"


$LatestTextFile = Get-ChildItem -Path $LocalDir -Filter *.rar | Sort -Property CreationTime -Descending | Select -First 1
$RemoteFile = "ftp://sgintschools.com.ar/$($remotePath)/$($LatestTextFile.Name)"
 
# Create FTP Request Object
$FTPRequest = [System.Net.FtpWebRequest]::Create("$RemoteFile")
$FTPRequest = [System.Net.FtpWebRequest]$FTPRequest
$FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$FTPRequest.Credentials = new-object System.Net.NetworkCredential($Username, $Password)
$FTPRequest.UseBinary = $true
$FTPRequest.UsePassive = $true

# Read the File for Upload
#$FileContent = Get-Content -Encoding Byte -Path $LatestTextFile.FullName
#$FTPRequest.ContentLength = $FileContent.Length
# Get Stream Request by bytes
#$Run = $FTPRequest.GetRequestStream()
#$Run.Write($FileContent, 0, $FileContent.Length)

$fileStream = [System.IO.File]::OpenRead($LatestTextFile.FullName)
$ftpStream = $FTPRequest.GetRequestStream()
#progreesss

$buffer = New-Object Byte[] 10240
while (($read = $fileStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
    $ftpStream.Write($buffer, 0, $read)
    $pct = ($fileStream.Position / $fileStream.Length)
    Write-Progress `
        -Activity "Uploading" -Status ("{0:P0} complete:" -f $pct) `
        -PercentComplete ($pct * 100)
}
 
# Cleanup
$fileStream.CopyTo($ftpStream)
$ftpStream.Dispose()
$fileStream.Close()
$fileStream.Dispose()


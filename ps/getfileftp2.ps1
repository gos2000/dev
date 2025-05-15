# Config
$Username = "Administrator"
$Password = "aristonLD00"
$LocalFile = "C:\SqlData\"
#e.g. "C:\temp\somefile.txt"
$RemoteFile = "ftp://webmanager.com.ar/padeli/backup/*.rar"
#e.g. "ftp://ftp.server.com/home/some/path/somefile.txt"

try{ 
    # Create a FTPWebRequest
    $FTPRequest = [System.Net.FtpWebRequest]::Create($RemoteFile)
    $FTPRequest.Credentials = New-Object System.Net.NetworkCredential($Username,$Password)
    $FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
    $FTPRequest.UseBinary = $true
    $FTPRequest.KeepAlive = $false
    $FTPRequest.EnableSsl  = $false
    # Send the ftp request
    $FTPResponse = $FTPRequest.GetResponse()
    # Get a download stream from the server response
    $ResponseStream = $FTPResponse.GetResponseStream()
    # Create the target file on the local system and the download buffer
    $LocalFileFile = New-Object IO.FileStream ($LocalFile,[IO.FileMode]::Create)
    [byte[]]$ReadBuffer = New-Object byte[] 1024
    # Loop through the download

    do {
        $ReadLength = $ResponseStream.Read($ReadBuffer,0,1024)
        $LocalFileFile.Write($ReadBuffer,0,$ReadLength)
    }
    while ($ReadLength -ne 0)
    # Close file
    $LocalFileFile.Close()
}catch [Exception]
{
    $Request = $_.Exception
    Write-host "Exception caught: $Request"
}
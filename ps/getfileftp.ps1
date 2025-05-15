function DownloadFtpDirectory($url, $credentials, $localPath)
{
    $listRequest = [Net.WebRequest]::Create($url)
    $listRequest.Method =
        [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    $listRequest.Credentials = $credentials
    
    $lines = New-Object System.Collections.ArrayList

    $listResponse = $listRequest.GetResponse()
    $listStream = $listResponse.GetResponseStream()
    $listReader = New-Object System.IO.StreamReader($listStream)
    while (!$listReader.EndOfStream)
    {
        $line = $listReader.ReadLine()
        $lines.Add($line) | Out-Null
    }
    $listReader.Dispose()
    $listStream.Dispose()
    $listResponse.Dispose()

    foreach ($line in $lines)
    {
        $tokens = $line.Split(" ", 9, [StringSplitOptions]::RemoveEmptyEntries)
        $name = $tokens[8]
        $permissions = $tokens[0]

        $localFilePath = Join-Path $localPath $name
        $fileUrl = ($url + $name)

        if ($permissions[0] -eq 'd')
        {
            if (($name -ne ".") -and ($name -ne ".."))
            {
                if (!(Test-Path $localFilePath -PathType container))
                {
                    Write-Host "Creating directory $localFilePath"
                    New-Item $localFilePath -Type directory | Out-Null
                }

                DownloadFtpDirectory ($fileUrl + "/") $credentials $localFilePath
            }
        }
        else
        {
            Write-Host "Downloading $fileUrl to $localFilePath"

            $downloadRequest = [Net.WebRequest]::Create($fileUrl)
            $downloadRequest.Method =
                [System.Net.WebRequestMethods+Ftp]::DownloadFile
            $downloadRequest.Credentials = $credentials

            $downloadResponse = $downloadRequest.GetResponse()
            $sourceStream = $downloadResponse.GetResponseStream()
            $targetStream = [System.IO.File]::Create($localFilePath)
            $buffer = New-Object byte[] 10240
            while (($read = $sourceStream.Read($buffer, 0, $buffer.Length)) -gt 0)
            {
                $targetStream.Write($buffer, 0, $read);
            }
            $targetStream.Dispose()
            $sourceStream.Dispose()
            $downloadResponse.Dispose()
        }
    }
}

$Username = "Administrator"
$Password = "aristonLD00"

$credentials = New-Object System.Net.NetworkCredential($Username , $Password) 
$url = "ftp://webmanager.com.ar/macnab/backup/"
DownloadFtpDirectory $url $credentials "C:\SqlData\"

# Config
$Username = "Administrator"
$Password = "aristonLD00"
$LocalFile = "C:\SqlData\FILNAME.EXT"
#e.g. "C:\temp\somefile.txt"
$RemoteFile = "ftp://webmanager.com.ar/padeli/backup/padeliprod20231811.rar"
#e.g. "ftp://ftp.server.com/home/some/path/somefile.txt"

try{ 
    # Create a FTPWebRequest
    $FTPRequest = [System.Net.FtpWebRequest]::Create($RemoteFile)
    $FTPRequest.Credentials = New-Object System.Net.NetworkCredential($Username,$Password)
    $FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
    $FTPRequest.UseBinary = $true
    $FTPRequest.KeepAlive = $false
    $FTPRequest.EnableSsl  = $true
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
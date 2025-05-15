$Username = "Administrator"
$Password = "aristonLD00"


function DownloadFtpDirectory($url, $credentials, $localPath)
{
    $listRequest = [Net.WebRequest]::Create($url+"*.rar")
    #$listRequest.Method =[System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
        $listRequest.Method =[System.Net.WebRequestMethods+Ftp]::ListDirectory
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
        Write-Host "linea " $line
        DownloadFile $url$line $localPath"\"$line
    }
}
function DownloadFile($url, $targetFile)

{

   $uri = New-Object "System.Uri" "$url"

   $request = [System.Net.HttpWebRequest]::Create($uri)

   $request.set_Timeout(15000) #15 second timeout

   $response = $request.GetResponse()

   $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)

   $responseStream = $response.GetResponseStream()

   $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create

   $buffer = new-object byte[] 10KB

   $count = $responseStream.Read($buffer,0,$buffer.length)

   $downloadedBytes = $count

   while ($count -gt 0)

   {

       $targetStream.Write($buffer, 0, $count)

       $count = $responseStream.Read($buffer,0,$buffer.length)

       $downloadedBytes = $downloadedBytes + $count

       Write-Progress -activity "Downloading file '$($url.split('/') | Select -Last 1)'" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength)  * 100)

   }

   Write-Progress -activity "Finished downloading file '$($url.split('/') | Select -Last 1)'"

   $targetStream.Flush()

   $targetStream.Close()

   $targetStream.Dispose()

   $responseStream.Dispose()

}

function getftp($RemoteFile,  $LocalFile){
 Write-Host "linea 2 " $RemoteFile 
    try{ 
        # Create a FTPWebRequest
        $FTPRequest = [System.Net.FtpWebRequest]::Create($RemoteFile)
        $FTPRequest.Credentials =   New-Object System.Net.NetworkCredential($Username,$Password)
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
}



$credentials = New-Object System.Net.NetworkCredential($Username , $Password) 
$url = "ftp://webmanager.com.ar/Cole/bkp/cole201620242204.rar"
DownloadFtpDirectory $url $credentials "C:\SqlData\cole"




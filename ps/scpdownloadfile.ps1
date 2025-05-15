try
{
    # Load WinSCP .NET assembly
    Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
    
    $sourceFile="colle/bkp/cole201620242905.rar"

    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::ftp
        HostName = "ftp://webmanager.com.ar/Cole/bkp/cole201620242905.rar"
        UserName = "Administrator"
        Password = "aristonLD00"
       # SshHostKeyFingerprint = "ssh-rsa 2048 xxxxxxxxxxx..."
    }
 
    $session = New-Object WinSCP.Session
    try
    {
        # Will continuously report progress of transfer
        $session.add_FileTransferProgress( { FileTransferProgress($_) } )
 
        # Connect
        $session.Open($sessionOptions)
 
        # Download the file and throw on any error
        $session.GetFiles($sourceFile, "c:\sqldata\cole\").Check()
    }
    finally
    {
        # Terminate line after the last file (if any)
        if ($script:lastFileName -ne $Null)
        {
            Write-Host
        }
 
        # Disconnect, clean up
        $session.Dispose()
    }
 
    exit 0
}
catch
{
    Write-Host "Error: $($_.Exception.Message)"
    exit 1
}
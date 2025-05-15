
$cutoff = (Get-Date).AddHours(-8) 
#'11/01/2022 06:00'
$source = "C:\Gabriel\Repo\Ags\AgsPublishCustomer"
$dest = "C:\Gabriel\Repo\Ags\AgsCustomers\_autoPublish\agsCustomerweb"


$Date   = Read-Host -Prompt "Ingresa la fecha de modificacion : $cutoff"
#$User = Read-Host -Prompt 'Input the user name'
#$Date = Get-Date

if($Date -ne "" -and ($cutoff -lt $Date )){
    $cutoff = $Date
    
}


Write-Host "----------------------
            Fecha en $cutoff 
            Origen: $Source 
            Destino: $dest
----------------------" 

Read-Host -Prompt "Iniciar ejecución : $cutoff"

Get-ChildItem –Path $dest -Recurse | Remove-Item -Recurse -Confirm:$false -Force


Get-ChildItem $source -File -Recurse | Where { $_.LastWriteTime -ge $cutoff } | ForEach {

    $actualSource = Split-Path $_.FullName
    $actualDest = Split-Path $_.FullName.Replace($source,$dest)
    if(
        !$actualDest.Contains("Controllers") -and 
         !$actualDest.Contains("obj") -and 
         !$actualDest.Contains("Logs") -and 
         !$actualDest.Contains("Exports") -and
         !$actualDest.Contains("reactApp") -and
         !$actualDest.Contains("Files") -and
         !$actualDest.Contains(".csproj.") -and
         !$_.Name.Contains("pdb")
         ){
            robocopy $actualSource $actualDest $_.Name /SEC
    }

}

cd $dest
dir

$MSTestCall = 'C:\Program Files\WinRAR\rar.exe'

&$MSTestCall a -ep1 -df -r agsCustomerweb *.* 



$upload = Read-Host -Prompt "Iniciar el upload en ftp (S/n)"

if($upload -eq "S"){
    & ((Split-Path $MyInvocation.InvocationName) + "\2_AgsCustomerUpLoadFtpProgress.ps1")
}
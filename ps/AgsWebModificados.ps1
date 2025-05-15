
$cutoff = Get-Date '27/07/2022 06:00'
$source = "C:\Gabriel\Repo\Ags\AgsPublishCustomer"
$dest = "C:\Gabriel\Repo\Ags\AgsCustomers\_autoPublish\agsCustomerweb"
function Copiar(){

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
         !$_.Name.Contains("pdb")
         ){
            robocopy $actualSource $actualDest $_.Name /SEC
    }

}
}

function zippear(){
cd $dest
dir

$MSTestCall = 'C:\Program Files\WinRAR\rar.exe'

&$MSTestCall a -ep1 -df -r AgsCustomerWeb *.* 
}

function subir(){
#upload fpt agsite
&'C:\Gabriel\Repo\Ags\AgsCustomers\_autoPublish\AgswebUpLoadFtpProgress.ps1'
}
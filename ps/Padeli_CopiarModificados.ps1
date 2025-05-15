#version 2.0 2023
$actualPathScript ="c:\Gabriel\_autoPublish"

set-location $actualPathScript 

$cutoff = [datetime]( Get-Date -Format "yyyy/M/d 0:0:0" )
#'11/01/2022 06:00'
$source = "C:\gabriel\repo\padeli\Macnab\Src\PadeliSrc\macnab_web\bin\Release\net6.0"
            
$dest = "c:\Gabriel\_autoPublish\padeli_web"
$filedeploy = "padeliweb"

Write-Host 'Fecha de proceso {0}'  $cutoff
$Date = (Read-Host -Prompt ('Enter the start time and date of the patch window. Format: {0}' -f  $cutoff) ) 


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

 

Get-ChildItem –Path $dest -Recurse | Remove-Item -Recurse -Confirm:$false -Force



Get-ChildItem $source -File -Recurse | Where { $_.LastWriteTime -ge ($cutoff) } | ForEach {

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
         !$_.Name.Contains("Microsoft") -and
         !$_.Name.Contains("System") -and
         !$_.Name.Contains("SQL") -and
         !$_.Name.Contains("Serilog") -and
         !$_.Name.Contains("Rotativa") -and
         !$_.Name.Contains("Entity") -and
         !$_.Name.Contains("Castle") -and
         !$_.Name.Contains("Humanizer") -and
         !$_.Name.Contains("EPPlus") -and
         !$_.Name.Contains("dotnet") -and
         !$_.Name.Contains("Dapper") -and
         !$_.Name.Contains("Newtonsoft") -and
         !$_.Name.Contains("RestSharp") -and
         !$_.Name.Contains("win-x64") -and
         #!$_.Name.Contains("Macnab.deps") -and
         !$_.Name.Contains("pdb")
         ){
            robocopy $actualSource $actualDest $_.Name /SEC
    }

}

cd $dest
dir


$MSTestCall = 'c:\Program Files\WinRAR\rar.exe'

&$MSTestCall a -ep1 -df -r $filedeploy *.* 

set-location $actualPathScript 

$upload = Read-Host -Prompt "Iniciar el upload en ftp (S/n)"

if($upload -eq "S"){
    #& ((Split-Path $MyInvocation.InvocationName) + ".\padeli_CopiarModificados_UpLoadFtpProgress.ps1")
    Write-Host  "Iniciando la carga en el servidor"
    #ejecutar el script de upload
    & ((Split-Path $MyInvocation.InvocationName) + ".\padeli_CopiarModificados_UpLoadFtpProgress.ps1")
}

Start-Process $dest

function unrar(){

    $MSTestCall = 'c:\Program Files\WinRAR\rar.exe'
    &$MSTestCall x -ibck $filedeploy *.* 
}

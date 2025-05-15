$cutoff = [datetime]( Get-Date -Format "yyyy/M/d 0:0:0" )

$cutoff = [datetime]( Get-Date -Format "yyyy/M/d 0:0:0" )
#'11/01/2022 06:00'
$source = "C:\Gabriel\Repo\IntSchools\Publish\SchoolsMvc\bin"
$dest = "C:\Gabriel\Repo\IntSchools\Publish\SchoolsMvc\bin - copia"
$filedeploy = "macnabweb"

Write-Host 'Fecha de proceso {0}'  $cutoff
$Date = (Read-Host -Prompt ('Enter the start time and date of the patch window. Format: {0}' -f  $cutoff) ) 

function back(){
  $filesbkp=Get-ChildItem –Path $source -Recurse 
  $filesbkp | ForEach {
    Write-Host $_.Name 
    
  }

}

function copiar(){

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
         !$_.Name.Contains("pdb")
         ){
            robocopy $actualSource $actualDest $_.Name /SEC
    }

}

cd $dest
dir

$MSTestCall = 'C:\Program Files\WinRAR\rar.exe'

&$MSTestCall a -ep1 -df -r $filedeploy *.* 


$upload = Read-Host -Prompt "Iniciar el upload en ftp (S/n)"

if($upload -eq "S"){
    & ((Split-Path $MyInvocation.InvocationName) + "\Macnab_CopiarModificados_UpLoadFtpProgress.ps1")
}
}
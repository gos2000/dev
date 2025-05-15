#Copia los archivos nuevos de la carpa y los deja en IN, en un rar para subirlos al servidor por ftp
# GetNews -  para obtener los archivos modificados despues de la fecha seteada
# UploadFtp - sube el rar a la carpeta ftp del servidor


$cutoff = [datetime]( Get-Date -Format "yyyy/M/d 0:0:0" )
#$pathDeploy = 'C:\Gabriel\Repo\Macnab\Deploy'

$pathDeploy = 'C:\Gabriel\Repo\Macnab\Deploy'
$fileIn = $pathDeploy + '\IN'
$finalDest = "C:\Gabriel\Repo\Macnab\Deploy\Publish"

#Origen de archivos modificados
$realese = 'C:\Gabriel\Repo\Macnab\Src\MacnabSrc\macnab_web\bin\Release\net5.0'
            
Write-Host 'Fecha de proceso {0}'  $cutoff
$Date = (Read-Host -Prompt ('Enter the start time and date of the patch window. Format: {0}' -f  $cutoff) ) 

if($Date -ne "" -and ($cutoff -lt $Date )){
    $cutoff = $Date
    
}


Set-Location $fileIn



function GetFiles() {

  $Files = @(
    Get-ChildItem -Path $fileIn  -Recurse |
    Where-Object { ($_.FullName -like "*macnab*.*" -or $_.FullName -like "*.html") -and ($_.CreationTime -gt $cutoff ) } | % { $_.FullName }
  )
  foreach ($File in $Files) {
    Write-Host  $File.replace($fileIn, '') -ForegroundColor Green
   
    #//write-host  (($File | Split-Path -LeafBase) + ($File | Split-Path -Extension))
  }
}

function updateConfig(){

  Add-Content -Path $finalDest"\web.config" $cutoff 
}

function copyfinal() {
  # copy-item $fileIn $finalDest -force -recurse -verbose


  Get-ChildItem $fileIn -File -Recurse  | ForEach-Object {
    $actualSource = Split-Path $_.FullName
    $actualDest = Split-Path $_.FullName.Replace($fileIn, $finalDest)
    Write-Host $actualSource $actualDest $_.Name
    robocopy $actualSource $actualDest $_.Name /SEC
  } 
  explorer $finalDest
}
 
 
#backup
#copyfinal
 
function backup() {
  $destino = $pathDeploy + "\Out" + (Get-Date -Format "yyyymmdd_HHmm")
  if (!(Get-Item $destino) ) {
    Write-Host "no existe"
    New-Item -Path $destino -ItemType "directory"
  }
  else {
    Write-Host "!existe"
  }

  Get-ChildItem $fileIn -File -Recurse  | ForEach-Object {

    $actualSource = Split-Path $_.FullName.Replace($fileIn, $finalDest)
    $actualDest = Split-Path $_.FullName.Replace($fileIn, $destino)
     
    Write-Host $actualSource $actualDest $_.Name
    robocopy $actualSource $actualDest $_.Name /SEC

  }
 
}

function GetNews() {
  
  removeAll

  Get-ChildItem $realese -File -Recurse | Where-Object { $_.LastWriteTime -ge $cutoff } | ForEach-Object {
    $actualSource = Split-Path $_.FullName
    $actualDest = Split-Path $_.FullName.Replace($realese, $fileIn)
    if (
      !$actualDest.Contains("Controllers") -and 
      !$actualDest.Contains("obj") -and 
      !$actualDest.Contains("Logs") -and 
      !$actualDest.Contains("Exports") -and
      !$actualDest.Contains("reactApp") -and
      !$actualDest.Contains("win-x64") -and
      !$_.Name.Contains("pdb")
    ) {
      if ($_.Name.Contains("Macnab") -or $actualDest.Contains("wwwroot") -or $_.Name.Contains(".config") -or $_.Name.Contains("html")) {
        Write-Host $actualSource $actualDest $_.Name
        robocopy $actualSource $actualDest $_.Name /SEC
      }
    }
  }
  Compress

  explorer $fileIn
}

function Compress(){
cd $fileIn
dir
$MSTestCall = 'C:\Program Files\WinRAR\rar.exe'
&$MSTestCall a -ep1 -df -r MacnabWeb *.* 
}

function removeAll() {
  #Get-ChildItem –Path $fileIn -Recurse | Remove-Item -Recurse -Force
  Remove-Item ($fileIn + '\*') -Recurse -Force
}

function UploadFtp(){
#upload fpt agsite
$upload = Read-Host -Prompt "Iniciar el upload en ftp (S/n)"

    if($upload -eq "S"){
      $remotePath = "\macnab\publish\IN"
        $LocalDir = $fileIn 

    Set-Location "C:\Gabriel\_autoPublish"
    &".\GenericUpLoadFtpProgress.ps1" $LocalDir $remotePath
    }
}

#GetNews
#UploadFtp


#GetNews
UploadFtp



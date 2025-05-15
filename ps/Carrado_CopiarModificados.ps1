
$cutoff = [datetime]( Get-Date -Format "yyyy/M/d 0:0:0" )
$source = "C:\Gabriel\Repo\Carrado\Sistema\FeAdminGit\FeAdmin"
$dest = "C:\Gabriel\Repo\Carrado\Sistema\pasar"
$rar = "C:\Program Files\WinRAR\rar.exe"

function deploy(){

Write-Host 'Fecha de proceso {0}'  $cutoff
$today = (Read-Host -Prompt ('Enter the start time and date of the patch window. Format: {0}' -f  $cutoff) ) 

if (![string]::IsNullOrWhiteSpace($today)) {
    $cutoff = [datetime](Get-Date ($today) -Format "yyyy/M/d hh:mm:ss")
 }

Write-Host 'Fecha para procesar proceso ' $cutoff 
Write-Host ' desde  ' $source 
Write-Host ' destino' $dest

Read-Host 'Continuar [Enter]?'

Get-ChildItem –Path $dest -Recurse | Remove-Item -Recurse -Confirm:$false -Force
Get-ChildItem $source -File -Recurse | Where { $_.LastWriteTime -ge ($cutoff) -and
                                             !$_.fullname.Contains("node_modules") -and 
                                             !$_.fullname.Contains("Controllers") -and 
                                             !$_.fullname.Contains("obj") -and 
                                             !$_.fullname.Contains("Logs") -and 
                                             !$_.fullname.Contains("Exports") -and
                                             !$_.fullname.Contains("reactApp") -and
                                             !$_.fullname.Contains("csproj") -and
                                             !$_.Name.Contains("config") -and
                                             !$_.Name.Contains("pdb")  } | ForEach {

    $actualSource = Split-Path $_.FullName
    $actualDest = Split-Path $_.FullName.Replace($source,$dest)
    if(
         !$actualDest.Contains("Controllers") -and 
         !$actualDest.Contains("obj") -and 
         !$actualDest.Contains("Logs") -and 
         !$actualDest.Contains("Exports") -and
         !$actualDest.Contains("reactApp") -and
         !$actualDest.Contains("csproj") -and
         !$actualDest.Contains("config") -and
         !$_.Name.Contains("pdb")
         ){
            robocopy $actualSource $actualDest $_.Name /SEC
    }
    }

}

function clearfiles(){
    Get-ChildItem –Path $dest -Recurse | Remove-Item -Recurse -Confirm:$false -Force
}

function modificados(){
    clearfiles

    Write-Host 'Fecha de proceso {0}'  $cutoff
    $today = (Read-Host -Prompt ('Enter the start time and date of the patch window. Format: {0}' -f  $cutoff) ) 

    if (![string]::IsNullOrWhiteSpace($today)) {
        $cutoff = [datetime](Get-Date ($today) -Format "yyyy/M/d hh:mm:ss")
     }

    Write-Host 'Fecha para procesar proceso ' $cutoff 
    Write-Host ' desde  ' $source 
    Write-Host ' destino' $dest

    Read-Host 'Continuar [Enter]?'
 

    Foreach($file in (Get-ChildItem $source -File -Recurse | Where { 
            !$_.fullname.Contains("node_modules") -and 
            !$_.fullname.Contains("Controllers") -and 
             !$_.fullname.Contains("obj") -and 
             !$_.fullname.Contains("Logs") -and 
             !$_.fullname.Contains("Exports") -and
             !$_.fullname.Contains("reactApp") -and
             !$_.fullname.Contains("csproj") -and
             !$_.Name.Contains("config") -and
             !$_.Name.Contains("pdb")  } ))
    {
        if($file.LastWriteTime -gt ($cutoff) -and !$file.Name.Contains("pdb") ){
            
             $actualSource = Split-Path $file.fullname 
             $actualDest = Split-Path $file.fullname.Replace($source,$dest)
             Write-Host "se copia " $file.fullname $file.LastWriteTime  $actualDest\$file $file
                #Copy-Item -Path $file.fullname -Destination $actualDest\$file -Force
                if(  !$actualDest.Contains("Controllers") -and 
                     !$actualDest.Contains("obj") -and 
                     !$actualDest.Contains("Logs") -and 
                     !$actualDest.Contains("Exports") -and
                     !$actualDest.Contains("reactApp") -and
                     !$actualDest.Contains("csproj") -and
                     !$actualDest.Contains("config") -and
                     !$file.Name.Contains("pdb")){
                    robocopy $actualSource $actualDest  /SEC
             }
            #Move-Item -Path $file.fullname -Destination $LocalPath
        }else{
       # Write-Host $file.fullname $file.LastWriteTime 
        }

    }
}

function backup(){
    $filerar = 'back'+(Get-Date -Format "yyyyMMdd")
    cd $dest
    &$rar a -r0 $filerar $source\*.*
    
}

function rar(){
    $filerar = 'build'+(Get-Date -Format "yyyyMMdd")
    cd $dest
    &$rar a -r0 $filerar *.* 
    Start-Process $dest
}

function fecha(){
  write-host (Get-Date -Format "yyyyMMdd")
}

function copiar(){
deploy
rar
}
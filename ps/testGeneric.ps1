$remotePath = "\macnab\publish\IN"
$LocalDir = "C:\Gabriel\Repo\Macnab\Deploy\IN"

Set-Location "C:\Gabriel\_autoPublish"
&".\GenericUpLoadFtpProgress.ps1"  $remotePath  $LocalDir  
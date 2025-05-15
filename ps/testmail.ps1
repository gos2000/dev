# Configuración SMTP
$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$fromEmail = "noresponder@elizalde.edu.ar"
$password = "Ispe2025!"
$toEmail = "gabrielosantos@gmail.com"
$subject = "Hola desde .NET Core"
$body = "Este es un correo de prueba enviado desde una aplicación de consola en .NET Core."

# Crear objeto de credenciales
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($fromEmail, $securePassword)

# Crear objeto de mensaje
$mailMessage = New-Object System.Net.Mail.MailMessage
$mailMessage.From = $fromEmail
$mailMessage.To.Add($toEmail)
$mailMessage.Subject = $subject
$mailMessage.Body = $body

# Crear objeto SMTP
$smtpClient = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
$smtpClient.EnableSsl = "true"
$smtpClient.Credentials = $credential

# Intentar enviar el correo
try {
    $smtpClient.Send($mailMessage)
    Write-Host "Correo enviado exitosamente a $toEmail"
} catch {
    Write-Host "Error al enviar el correo: $_"
}
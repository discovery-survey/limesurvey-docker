# --- Quick TCP check ---
Test-NetConnection -ComputerName postal.discovery-club.org.ua -Port 587

# --- SMTP send test (no TLS) ---
$SmtpServer = "postal.discovery-club.org.ua"
$Port       = 587

# Change these if needed:
$From = "test@discovery-club.org.ua"
$To   = "valeinikolaev@gmail.com"

# Username can be anything per your config:
$User = "any"
$Pass = ""

function Read-Line($reader) {
    $line = $reader.ReadLine()
    if ($line) { Write-Host "S: $line" }
    return $line
}

$client = New-Object System.Net.Sockets.TcpClient
$client.Connect($SmtpServer, $Port)

$stream = $client.GetStream()
$reader = New-Object System.IO.StreamReader($stream)
$writer = New-Object System.IO.StreamWriter($stream)
$writer.NewLine = "`r`n"
$writer.AutoFlush = $true

# Server banner
Read-Line $reader | Out-Null

# EHLO
$writer.WriteLine("EHLO localhost")
Read-Line $reader | Out-Null
# Some servers return multi-line responses after EHLO
while ($reader.Peek() -ge 0) {
    $stream.ReadTimeout = 200
    try {
        $line = $reader.ReadLine()
        if (!$line) { break }
        Write-Host "S: $line"
        if ($line -match "^\d{3}\s") { break }
    } catch { break }
}

# AUTH LOGIN
$writer.WriteLine("AUTH LOGIN")
Read-Line $reader | Out-Null

$writer.WriteLine([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($User)))
Read-Line $reader | Out-Null

$writer.WriteLine([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($Pass)))
Read-Line $reader | Out-Null

# MAIL / RCPT / DATA
$writer.WriteLine("MAIL FROM:<$From>")
Read-Line $reader | Out-Null

$writer.WriteLine("RCPT TO:<$To>")
Read-Line $reader | Out-Null

$writer.WriteLine("DATA")
Read-Line $reader | Out-Null

$subject = "SMTP test from PowerShell"
$body    = "Hello! This is a raw SMTP test message sent at $(Get-Date -Format o)."

$writer.WriteLine("From: <$From>")
$writer.WriteLine("To: <$To>")
$writer.WriteLine("Subject: $subject")
$writer.WriteLine("Date: $(Get-Date -Format R)")
$writer.WriteLine("")
$writer.WriteLine($body)
$writer.WriteLine(".")
Read-Line $reader | Out-Null

$writer.WriteLine("QUIT")
Read-Line $reader | Out-Null

$reader.Close()
$writer.Close()
$stream.Close()
$client.Close()

Write-Host "Done."

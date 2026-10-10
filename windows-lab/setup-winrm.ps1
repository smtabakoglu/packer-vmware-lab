# LAB-ONLY: Enables WinRM Basic authentication over HTTP (port 5985).
# Do not use this setup for production or untrusted networks.
$ErrorActionPreference = "Stop"
Start-Transcript -Path "C:\Windows\Temp\packer-winrm.log" -Append

Set-Service WinRM -StartupType Automatic
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

if (-not (Get-NetFirewallRule -Name "PackerWinRM" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule `
        -Name "PackerWinRM" `
        -DisplayName "Packer WinRM HTTP" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 5985 `
        -Action Allow
}

Restart-Service WinRM
Write-Host "WinRM configuration completed."
Stop-Transcript

<#
.SYNOPSIS
    Name of script
.DESCRIPTION
    Installs the following applications:
        1. OpenSSH Server
        2. Nano terminal text editor
    Completes the following configurations:
        1. 
        . Set SSH logon banner
.NOTES
    File Name   : Powershell.ps1
    Version     : 0.1
    Author      : BJ Beier - https://github.com/bjbeier/PROJECT-NAME
.EXAMPLE
    Example if applicable
#>

# Check that we are admin!
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an administrator."
    Exit
}

#
# App Installations
#

# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

    # Start the sshd service
    Start-Service sshd

# Install Nano Text Editor
winget install gnu.nano

#
# Configurations
#

# Set OpenSSH to start automatically
Set-Service -Name sshd -StartupType 'Automatic'

# Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
}
    
# Configure Powershell as the default shell for OpenSSH
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# Create SSH login banner
$BannerText = @" 
#################################################################
#                     _    _           _   _                    #
#                    / \  | | ___ _ __| |_| |                   #
#                   / _ \ | |/ _ \ '__| __| |                   #
#                  / ___ \| |  __/ |  | |_|_|                   #
#                 /_/   \_\_|\___|_|   \__(_)                   #
#                                                               #
#  You are entering into a secured area! Your IP, Login Time,   #
#   Username has been noted and has been sent to the server     #
#                       administrator!                          #
#   This service is restricted to authorized users only. All    #
#            activities on this system are logged.              #
#  Unauthorized access will be fully investigated and reported  #
#        to the appropriate law enforcement agencies.           #
#################################################################
"@
New-Item C:\ProgramData\ssh\sshd_banner
Set-Content C:\ProgramData\ssh\sshd_banner $BannerText

# Set SSH login banner file


(Get-Content -path C:\ProgramData\ssh\sshd_config -Raw) -replace '#Banner none','Banner __PROGRAMDATA__/ssh/sshd_banner'
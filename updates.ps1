<#  
.SYNOPSIS
    Windows OS and Application Updates
.DESCRIPTION
    Uses winget to run updates on installed Windows applications and the Powershell module PSWindowsUpdate to install Windows Updates.
.NOTES
    File Name   : updates.ps1
    Version     : 0.1
    Author      : BJ Beier - https://github.com/bjbeier/Windows-Base-Scripts/
#>

# Check if script is running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an administrator to install updates."
    Exit
}

##INSTALL COMPONENTS##

# Install Winget if not already installed
if (!(Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Output "Winget is not installed, installing..."
    Invoke-Expression "Invoke-WebRequest -Uri https://aka.ms/winget-cli -OutFile winget-cli.appxbundle"
    Add-AppxPackage .\winget-cli.appxbundle
    Write-Output "Winget installation complete."
}

# Install PSWindowsUpdates if not already installed
if (!(Get-Command "Get-WindowsUpdate" -ErrorAction SilentlyContinue)) {
    Write-Output "PSWindowsUpdates module is not installed, installing..."
    Install-Module PSWindowsUpdates
    Write-Output "PSWindowsUpdates installation complete."
}

##INSTALL UPDATES##

# Get available application updates using Winget, format as a table and install
Write-Output "
Checking for available application updates."
$wingetUpdates = winget upgrade --accept-source-agreements
if ($wingetUpdates -match "No installed package found matching input criteria.") {
    Write-Output "
No application updates available."
}
else {
#    $wingetUpdatesTable = $wingetUpdates | Select-Object -Property @{Name="Title";Expression={$_.PackageMatchName}}, @{Name="Version";Expression={$_.Version}}
    Write-Output $wingetUpdates
    Write-Output "
Installing application updates."
    winget upgrade --all --silent --force --accept-source-agreements --disable-interactivity --include-unknown
    Write-Output "
Application updates installation complete."
}

# Get available Windows Updates using PSWindowsUpdate, count and install
Write-Output "
Checking for available Windows updates."
$updates = Get-WindowsUpdate

    # Add Microsoft Updates
    Add-WUServiceManager -MicrosoftUpdate -confirm:$false | out-null

if ($updates.Count -gt 0) {
    Write-Output "
Installing Windows updates."
    Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
    Write-Output "
Windows updates installation complete."
}
else {
    Write-Output "
No Windows updates available."
}
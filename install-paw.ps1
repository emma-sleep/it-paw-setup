[CmdletBinding(SupportsShouldProcess=$True)]
param ()

#### Set Variables for the Script ####
## Microsoft Modules
$msModules = @("Microsoft.Graph","ExchangeOnlineManagement","Az.Accounts")
## Emma Modules
$emmaModules = @("psmodule-boarding","psmodule-helpers","psmodule-credentials","psmodule-microsoft365","psmodule-snipeit","psmodule-reports")
## Paths to be created
$paths = @(
    @{  Path = "$([Environment]::GetFolderPath("MyDocuments"))\PowerShell"
        Name = "PowerShell 7 Root" },
    @{  Path = "$([Environment]::GetFolderPath("MyDocuments"))\PowerShell\Modules"
        Name = "PowerShell 7 Modules"},
    @{  Path = "$([Environment]::GetFolderPath("MyDocuments"))\PowerShell\Scripts"
        Name = "PowerShell 7 Scripts"}
)
## Colors for Outputs
$Colors = @{
    Frame = "DarkBlue"
    Text = "DarkCyan"
    Step = "Cyan"
    SubStep = "White"
    Skipped = "Yellow"
    Success = "Green"
}

Write-Host " "
Write-Host " "
Write-Host "+--------------------------------+" -ForegroundColor $Colors.Frame
Write-Host "|" -NoNewline -ForegroundColor $Colors.Frame
Write-Host " IT Admin toolbox' Installation " -ForegroundColor $Colors.Text -NoNewline
Write-Host "|" -ForegroundColor $Colors.Frame
Write-Host "+--------------------------------+" -ForegroundColor $Colors.Frame
Write-Host " "
Write-Host "Installing required softwares:" -ForegroundColor $Colors.Step

### WingetPathUpdater
Write-Host " - Installing WingetPathUpdater..." -ForegroundColor $Colors.SubStep
if(Test-Path "C:\Windows\System32\winget.ps1"){
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}else{
    if(!$WhatIfPreference){
        winget install jazzdelightsme.WingetPathUpdater --nowarn -h --accept-package-agreements --accept-source-agreements
    }
    Write-Host "[Installed]" -ForegroundColor $Colors.Success
}

### Git installation
Write-Host " - Installing Git... " -NoNewline -ForegroundColor $Colors.SubStep
if(!(Get-Command "git" -ErrorAction SilentlyContinue).Path){
    if(!$WhatIfPreference){
        Write-Host ""
        winget install git.git --disable-interactivity --nowarn -h --accept-package-agreements --accept-source-agreements
    }
    Write-Host "[Installed]" -ForegroundColor $Colors.Success
}else{
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}

### OpenSSH
Write-Host " - Installing OpenSSH..." -NoNewline -ForegroundColor $Colors.SubStep
if(!(Get-Command "ssh" -ErrorAction SilentlyContinue).Path){
    if(!$WhatIfPreference){
        Write-Host ""
        winget install Microsoft.OpenSSH.Beta --disable-interactivity --nowarn -h --accept-package-agreements --accept-source-agreements
    }
    Write-Host "[Installed]" -ForegroundColor $Colors.Success
}else{
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}

Write-Host " - Setting up Git sshCommand..." -NoNewline -ForegroundColor $Colors.SubStep
git config --global core.sshCommand 'C:/Windows/System32/OpenSSH/ssh.exe'
Write-Host "[OK]" -ForegroundColor $Colors.Success

### Powershell 7 install
Write-Host " - Installing Powershell 7... " -NoNewline -ForegroundColor $Colors.SubStep
if(!(Get-Command "pwsh" -ErrorAction SilentlyContinue).Path){
    if(!$WhatIfPreference){
        Write-Host ""
        winget install Microsoft.PowerShell --disable-interactivity --nowarn -h --accept-package-agreements --accept-source-agreements
    }
    Write-Host "[Installed]" -ForegroundColor $Colors.Success
}else{
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}

### Create SSH Key (if needed)
Write-Host " "
Write-Host "Setting up SSH (Ed25519):"
New-Variable -Name Key -Value "$env:UserProfile\.ssh\id_ed25519"
Write-Host " - Creating the ssh folder... " -NoNewline -ForegroundColor $Colors.SubStep
If(!(Test-Path "$($env:USERPROFILE)\.ssh")){
    if(!$WhatIfPreference){
        mkdir "$($env:USERPROFILE)\.ssh" -Force -Confirm:$False
    }
    Write-Host "[Created]" -ForegroundColor $Colors.Success
}else{
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}
If(!(Test-Path $Key)){
    Write-Host " - Generating a SSH key... " -ForegroundColor $Colors.SubStep
    if(!$WhatIfPreference){
        ssh-keygen -t ed25519 -f $Key
    }
    Write-Host "[Created]" -ForegroundColor $Colors.Success
}else{
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}

Write-Host " - Fixing permissions on SSH key..." -ForegroundColor $Colors.SubStep
if(!$WhatIfPreference){
    # Remove Inheritance:
    Icacls $Key /c /t /Inheritance:d
    # Set Ownership to Owner:
    # Key's within $env:UserProfile:
    Icacls $Key /c /t /Grant ${env:UserName}:F
    # Key's outside of $env:UserProfile:
    TakeOwn /F $Key
    Icacls $Key /c /t /Grant:r ${env:UserName}:F
    # Remove All Users, except for Owner:
    Icacls $Key /c /t /Remove:g Administrator "Authenticated Users" BUILTIN\Administrators BUILTIN Everyone System Users
}
Write-Host "[OK]" -ForegroundColor $Colors.Success

Write-Host " - Installing and starting SSH-Agent..." -NoNewline -ForegroundColor $Colors.SubStep
if(!$WhatIfPreference){
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"Get-Service ssh-agent | Set-Service -StartupType Automatic -PassThru | Start-Service`"";
    }
}
Write-Host "[OK]" -ForegroundColor $Colors.Success
$ENV:SSH_AUTH_SOCK = $null

Write-Host " - Adding SSH key to the ssh-agent..." -ForegroundColor $Colors.SubStep
ssh-add $Key
Write-Host "[OK]" -ForegroundColor $Colors.Success

Write-Host "---------- SSH Key --------------"
cat "$($Key).pub"
Write-Host "---------- End ------------------"

Remove-Variable -Name Key

Write-Host " - Adding the SSH Key to the Github account..." -NoNewline -ForegroundColor $Colors.SubStep
Start-Process "https://github.com/settings/ssh/new"
Read-Host -Prompt "Add your public SSH key in your github profile. (Do not forget to authorize for SSO!) Once it's done, press any key to continue"

### Creating the necessary folders
Write-Host " "
Write-Host "Setting up the folders structure:"  -ForegroundColor $Colors.Step
Foreach($path in $paths){
    Write-Host -NoNewline " - Folder '$($path.Name)'... " -ForegroundColor $Colors.SubStep
    if(Test-Path $path.Path){
        Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
    }else{
        if(!$WhatIfPreference){
            mkdir $path.Path -Force
        }
        Write-Host "[Created]" -ForegroundColor $Colors.Success
    }
}




### Installing necessary modules
Write-Host " "
Write-Host "Installing all required PowerShell modules:" -ForegroundColor $Colors.Step
Write-Host -NoNewline " - Installing PowershellGet... " -ForegroundColor $Colors.SubStep
if((Get-InstalledModule -Name PowershellGet -ErrorAction SilentlyContinue).count -eq 0){
    if(!$WhatIfPreference){
        if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"Install-Module PowershellGet -Force -Confirm:$false`"";
        }
    }
    Write-Host "[Installed]" -ForegroundColor $Colors.Success
}else{
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}
Import-Module -Name PowershellGet -Force 

foreach($module in $msModules){
    Write-Host -NoNewline " - Installing $module... " -ForegroundColor $Colors.SubStep
    if((Get-InstalledModule -Name $module -ErrorAction SilentlyContinue).count -eq 0){
        if(!$WhatIfPreference){
            if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"Install-Module $module -Force -Confirm:$false`"";
            }
        }
        Write-Host "[Installed]" -ForegroundColor $Colors.Success
    }else{
        Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
    }
}

### Downloading PSProfile from Github
Write-Host " "
Write-Host "Installing PowerShell profiles:" -ForegroundColor $Colors.Step
Write-Host " - Installing Global Profile..." -NoNewline -ForegroundColor $Colors.SubStep
if(Test-Path "$([Environment]::GetFolderPath("MyDocuments"))\PowerShell\psprofile"){
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}else{
    if(!$WhatIfPreference){
        git clone -q git@github.com:emma-sleep/psprofile-windows.git "$([Environment]::GetFolderPath("MyDocuments"))\PowerShell\psprofile"
        if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"New-Item -Path '$PSHOME\Profile.ps1' -Target '$([Environment]::GetFolderPath("MyDocuments"))\PowerShell\psprofile\Microsoft.PowerShell_profile.ps1' -Type SymbolicLink`"";
        }
    }
    Write-Host "[Installed]" -ForegroundColor $Colors.Success
}

### Downloading Emma PS Modules from Github
Write-Host " "
Write-Host "Installing Emma PowerShell modules:" -ForegroundColor $Colors.Step
Foreach($module in $emmaModules){
    Write-Host -NoNewline " - Installing $module... " -ForegroundColor $Colors.SubStep
    if((Get-Module -Name $module -ErrorAction SilentlyContinue).count -eq 0){
        if(!$WhatIfPreference){
            git clone -q git@github.com:emma-sleep/$module.git "$([Environment]::GetFolderPath("MyDocuments"))\PowerShell\Modules\$module"
        }
        Write-Host "[Installed]" -ForegroundColor $Colors.Success
    }else{
        Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
    }
}

### Downloading Emma IT admin Toolbox
Write-Host " "
Write-Host "Installing IT admin Toolbox:" -ForegroundColor $Colors.Step
$module = "it-admin-toolbox"
Write-Host -NoNewline " - Installing $module... " -ForegroundColor $Colors.SubStep
if((Get-Module -Name $module -ErrorAction SilentlyContinue).count -eq 0){
    if(!$WhatIfPreference){
        git clone -q git@github.com:emma-sleep/$module.git "$([Environment]::GetFolderPath("MyDocuments"))\PowerShell\Scripts\$module"
    }
    Write-Host "[Installed]" -ForegroundColor $Colors.Success
}else{
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}


Write-Host " "
Write-Host "+----------------------------------------------------------------+" -ForegroundColor $Colors.Frame
Write-Host "|" -NoNewline -ForegroundColor $Colors.Frame
Write-Host " Installation complete!                                         " -NoNewline -ForegroundColor $Colors.Text
Write-Host "|" -ForegroundColor $Colors.Frame
Write-Host "|" -NoNewline -ForegroundColor $Colors.Frame
Write-Host " Please restart your PowerShell 7 session to apply the changes. " -NoNewline -ForegroundColor $Colors.Text
Write-Host "|" -ForegroundColor $Colors.Frame
Write-Host "+----------------------------------------------------------------+" -ForegroundColor $Colors.Frame
# SIG # Begin signature block
# MIIGEQYJKoZIhvcNAQcCoIIGAjCCBf4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDgosxGjbut0zNX
# Fia3hJgG5eBnP/co9jlNxfe2iS8OE6CCA3cwggNzMIIC+qADAgECAg9UAu4AoWdX
# Oi5N4fIeXUMwCgYIKoZIzj0EAwQwKzEpMCcGA1UEAwwgRW1tYS1TbGVlcCBDZXJ0
# aWZpY2F0ZSBBdXRob3JpdHkwHhcNMjQwODA2MTYwNzEzWhcNMjYxMTA5MTYwNzEz
# WjCBqDELMAkGA1UEBhMCREUxDzANBgNVBAgMBkhlc3NlbjEaMBgGA1UEBwwRRnJh
# bmtmdXJ0IGFtIE1haW4xEzARBgNVBAoMCkVtbWEtU2xlZXAxEDAOBgNVBAsMB0Vt
# bWEgSVQxFzAVBgNVBAMMDk5pY29sYXMgS2FwZmVyMSwwKgYJKoZIhvcNAQkBFh1u
# aWNvbGFzLmthcGZlckBlbW1hLXNsZWVwLmNvbTCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBAO1Nb3oyoRoJOar6z0Gi2eOyV3kjPrcW7nTnfm5vQbzrGVwr
# HpbmYkL7TeYz+rMYBEbRRhFK9wF5GT/M+S5dvEW8Ufq2aXm41IeZnx2mq5r48Vk4
# /XJLPWBMALh08Tnpfhwq67kgMIzL2pN6wHP7e+l20eCOrW6klN3V8bfMtz6luhuG
# wkLy1IYc0yyu72qNtaf/g3ScCQ5X9jQbbMgijL2s1SASx9/3UKnRhOSd3QWwzisx
# ejc5E6rjeHHaPTHLxPzp5uUIivhhqOdLb4BpYIuQsGCNp5nB/7lXG4i3KMJIDbEv
# fef9rQYgCbEHLEXpYcfzrvjujNCC2P7FlxozlCUCAwEAAaOBtzCBtDAJBgNVHRME
# AjAAMB0GA1UdDgQWBBRNEEVRJubH944NocFeUZJHwR1ymjBmBgNVHSMEXzBdgBTS
# M4pM4h6p9UrQNppF1Of9AAKK5aEvpC0wKzEpMCcGA1UEAwwgRW1tYS1TbGVlcCBD
# ZXJ0aWZpY2F0ZSBBdXRob3JpdHmCFCYNGw7TIMaYx4jnPAoA52DDJaymMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMAsGA1UdDwQEAwIHgDAKBggqhkjOPQQDBANnADBkAjBk
# TFR4vNInwGzEOfprM5V9lo8CqJ5q4yy0QGL+EDrQP3F3DCV0CmYutHH45olZU50C
# MHpT92rcQC/4CfpY5StYSf6Y+BBSUXuyzKp889+IbZGcMAM1u6lBe9ozHMi7JM3T
# qzGCAfAwggHsAgEBMD4wKzEpMCcGA1UEAwwgRW1tYS1TbGVlcCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkCD1QC7gChZ1c6Lk3h8h5dQzANBglghkgBZQMEAgEFAKCBhDAY
# BgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3
# AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEi
# BCDdXzKheQk33QhjHtcJiE6haB1q5Iq19Ae38kyAmqa88jANBgkqhkiG9w0BAQEF
# AASCAQBCs/UVxbJclU/hLXrSBAankPyVCw5vV8Pt3fgsWTMiGTx+u3vhX2DpEuh3
# /1fvhBreRirGWFNbr8mRL3ER7g4WGjYUJVmZZ7BDSZu13ABa/5mTonyv0k4gzfw2
# rDWERcq2vTm/qJP6zu5iKg0PDQFmgUpPfswArIWjbiRX+jN9ews0WobvYMB3Op/1
# 1UgZeokLrR6/TsKSnI4BQx3PrLO6T1VLmtKF2qcgY+Br+8HIC4P39nTTA++xLnum
# lkcbFIVM9vCfgEsWqTgzTLA6BPYTKhlP1HaCmGPmV+cXX7+MRtLnFvmn8qZ7Gf8i
# YbuCPQPunOM4PAtROL+6yH7AgCje
# SIG # End signature block

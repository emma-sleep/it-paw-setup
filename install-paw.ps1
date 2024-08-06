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
if(!(Get-Command "ssh-keygen" -ErrorAction SilentlyContinue).Path){
    if(!$WhatIfPreference){
        Write-Host ""
        winget install Microsoft.OpenSSH.Beta --disable-interactivity --nowarn -h --accept-package-agreements --accept-source-agreements
    }
    Write-Host "[Installed]" -ForegroundColor $Colors.Success
}else{
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}

Write-Host " - Setting up Git sshcommand..." -NoNewline -ForegroundColor $Colors.SubStep
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

Write-Host " - Installing SSH-Agent..." -NoNewline -ForegroundColor $Colors.SubStep
if(!$WhatIfPreference){
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"Get-Service ssh-agent | Set-Service -StartupType Automatic -PassThru | Start-Service`"";
    }
}
Write-Host "[OK]" -ForegroundColor $Colors.Success

Write-Host " - Starting SSH-Agent..." -NoNewline -ForegroundColor $Colors.SubStep
if(!$WhatIfPreference){
    start ssh-agent
}
Write-Host "[OK]" -ForegroundColor $Colors.Success

$ENV:SSH_AUTH_SOCK = $null

Write-Host " - Adding SSH key to the ssh-agent..." -ForegroundColor $Colors.SubStep
ssh-add $Key
Write-Host "[OK]" -ForegroundColor $Colors.Success

Write-Host "---------- SSH Key --------------"
cat "$($Key).pub"
Write-Host "---------- End ------------------"
Write-Host " - Adding the SSH Key to the Github account..." -NoNewline -ForegroundColor $Colors.SubStep
Start-Process "https://github.com/settings/ssh/new"
Read-Host -Prompt "Add your public SSH key in your github profile. (Do not forget to authorize for SSO!) Once it's done, press any key to continue"

Remove-Variable -Name Key

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
        Install-Module PowershellGet -Force -Confirm:$false -Scope CurrentUser
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
            Install-Module $module -Force -Confirm:$false -Scope CurrentUser
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
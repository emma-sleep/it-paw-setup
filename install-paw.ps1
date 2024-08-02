[CmdletBinding(SupportsShouldProcess=$True)]
param ()

#### Set Variables for the Script ####
## Microsoft Modules
$msModules = @("PowershellGet","Microsoft.Graph","ExchangeOnlineManagement","Az.Accounts")
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

Write-Host "+--------------------------------+" -ForegroundColor $Colors.Frame
Write-Host "|" -NoNewline -ForegroundColor $Colors.Frame
Write-Host " IT Admin toolbox' Installation " -ForegroundColor $Colors.Text -NoNewline
Write-Host "|" -ForegroundColor $Colors.Frame
Write-Host "+--------------------------------+" -ForegroundColor $Colors.Frame
Write-Host " "
Write-Host "Installing required softwares:" -ForegroundColor $Colors.Step
### Git installation
Write-Host -NoNewline " - Installing Git... " -ForegroundColor $Colors.SubStep
if(!(Get-Command "git" -ErrorAction SilentlyContinue).Path){
    if(!$WhatIfPreference){
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
        winget install Microsoft.OpenSSH.Beta --disable-interactivity --nowarn -h --accept-package-agreements --accept-source-agreements
    }
    Write-Host "[Installed]" -ForegroundColor $Colors.Success
}else{
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}

### Powershell 7 install
Write-Host -NoNewline " - Installing Powershell 7... " -ForegroundColor $Colors.SubStep
if(!(Get-Command "pwsh" -ErrorAction SilentlyContinue).Path){
    if(!$WhatIfPreference){
        winget install Microsoft.PowerShell --disable-interactivity --nowarn -h --accept-package-agreements --accept-source-agreements
    }
    Write-Host "[Installed]" -ForegroundColor $Colors.Success
}else{
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}

### Create SSH Key (if needed)
Write-Host " "
Write-Host "Setting the SSH Key (Ed25519):"
Write-Host " - Creating the ssh folder... " -NoNewline -ForegroundColor $Colors.SubStep
If(!(Test-Path "$($env:USERPROFILE)\.ssh")){
    if(!$WhatIfPreference){
        mkdir "$($env:USERPROFILE)\.ssh" -Force -Confirm:$False
    }
    Write-Host "[Created]" -ForegroundColor $Colors.Success
}else{
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}
If(!(Test-Path "$($env:USERPROFILE)\.ssh\id_ed25519")){
    Write-Host " - Creating a SSH key... " -NoNewline -ForegroundColor $Colors.SubStep
    if(!$WhatIfPreference){
        ssh-keygen -t ed25519 -f "$($env:USERPROFILE)\.ssh\id_ed25519"
    }
    Write-Host "[Created]" -ForegroundColor $Colors.Success
}else{
    Write-Host "[Skipped]" -ForegroundColor $Colors.Skipped
}

Write-Host "---------- SSH Key --------------"
cat "$($env:USERPROFILE)\.ssh\id_ed25519.pub"
Write-Host "---------- End ------------------"
Write-Host " - Adding the SSH Key to the Github account..." -NoNewline -ForegroundColor $Colors.SubStep
Start-Process "https://github.com/settings/ssh/new"
Read-Host -Prompt "Add your public SSH key in your github profile. Once it's done, press any key to continue"

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

foreach($module in $msModules){
    Write-Host -NoNewline " - Installing $module... " -ForegroundColor $Colors.SubStep
    if((Get-InstalledModule -Name $module -ErrorAction SilentlyContinue).count -eq 0){
        if(!$WhatIfPreference){
            Install-Module $module -Force -Confirm:$false
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
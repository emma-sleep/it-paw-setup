# IT PAW Setup
This repository is used to setup our IT Privileged Access Workstations (PAW).

## Prerequisites

Before you install your PAW, you need to have access to Github. 

## Installation

Open a PowerShell prompt and run the following command:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/emma-sleep/it-paw-setup/main/install-paw.ps1'))
```

And that's it! 

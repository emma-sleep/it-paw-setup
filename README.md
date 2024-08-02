# IT PAW Setup
This repository is used to setup our IT Privileged Access Workstations (PAW).

## Prerequisites

Before you install your PAW, you need to have access to Github. 
Please follow the instruction given in our Whizzz card:

https://whizzz.emma-sleep.com/share/card/how-to-become-member-to-emma-github-jZlfdeO

## Installation

Open a PowerShell prompt (as an Administrator) and run the following command:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/emma-sleep/it-paw-setup/main/install-paw.ps1'))
```

And that's it! 

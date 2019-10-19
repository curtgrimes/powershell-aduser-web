# powershell-aduser-web

Simple web-based UI with keyboard shortcuts for navigating `Get-ADUser` results. Provides deep links to Microsoft Teams and the Outlook user availability window. Made this as a shortcut for tasks I do many times a day.

## Installation and Usage

1. Go to [Releases](https://github.com/curtgrimes/powershell-aduser-web/releases/latest)
1. Download the latest release and unzip it
1. Run `server.ps1`

To set up a shortcut with the console minimized you can do something like `pwsh.exe -WindowStyle minimized -File "path\to\server.ps1"`

## Assumptions

This makes some assumptions about your environment:

- You're running this on Windows with Google Chrome installed
- localhost port 8989 is available
- Prior to running you've done `Add-WindowsCapability –online –Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"`
- `Get-ADUser` returns people with certain properties

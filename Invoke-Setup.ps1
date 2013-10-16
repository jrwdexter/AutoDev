# Variables
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Load Scripts
ls $scriptPath -Recurse -Filter "Import*.ps1" | % { . $_.FullName }

# Install Chocolatey
Install-Chocolatey -ProgressBegin 0 -ProgressEnd 20
Install-ChocolateyPackages -ProgressBegin 20 -ProgressEnd 50

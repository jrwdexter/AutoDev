# Variables
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Install Chocolatey
function Install-Chocolatey()
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [int]$ProgressBegin=0,
        [Parameter(Mandatory=$False)]
        [int]$ProgressEnd=100
    )

    Write-Progress -Activity "Chocolatey Installation" -Status "Installing Chocolatey" -PercentComplete $ProgressBegin
    if($env:PATH -NotMatch "Chocolatey")
    {
        iex (New-Object Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')
        $newPath = "$($env:Path);$($env:SYSTEMDRIVE)\Chocolatey\bin"
        $env:PATH = $newPath
        [Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
    }
    Write-Progress -Activity "Chocolatey Installation" -Status "Chocolatey Installation Complete" -PercentComplete $ProgressEnd
}

function Get-InstalledPackages()
{
    if($script:installedPackages -eq $null)
    {
        $script:installedPackages = cver all -localonly | Select-Object -Skip 3 | ? { $_ -NotMatch "^\s*$" } | % {New-Object PSObject -Property @{Name = $_ -Replace "^([\w.]*).*","`$1"; Version = $_ -Replace "^.*\s+([0-9.]+)\s*`$","`$1"}}
    }
    return $script:installedPackages
}

# Install Chocolatey Packages
function Install-ChocolateyPackages()
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [int]$ProgressBegin=0,
        [Parameter(Mandatory=$False)]
        [int]$ProgressEnd=100
    )

    Write-Progress -Activity "Chocolatey Package Installation" -Status "Retrieving Package Information" -PercentComplete $ProgressBegin
    $packages = (Get-Content (Join-Path $scriptPath "../config.json") | Out-String | ConvertFrom-Json).packages
    $packageNum = 0
    foreach($package in $packages)
    {
        $matchedPackage = Get-InstalledPackages | ? {$_.Name -eq $package.name -and $_.version -match $package.version}
        $packageNum++
        $percentage = ($ProgressEnd - $ProgressBegin) * ($packageNum / $packages.count) + $ProgressBegin # Range of 20-50
        Write-Progress -Activity "Chocolatey Package Installation" -Status "Installing Package $($package.Name) ($($package.Version))" -PercentComplete $percentage
        if($matchedPackage -eq $null)
        {
            if($package.Version -eq $null)
            { cinst $package.Name}
            else
            { cinst $package.name -Version $package.version }
        }
    }
    Write-Progress -Activity "Chocolatey Package Installation" -Status "All Packages Installed" -PercentComplete $ProgressEnd
    $script:installedPackages = $null
}

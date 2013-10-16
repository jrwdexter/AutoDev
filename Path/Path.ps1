$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
write-host $scriptPath
$dropboxPath = gc "$($env:APPDATA)\Dropbox\host.db" | % {[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))} | select-object -last 1
$userProfile = $env:USERPROFILE
$configPath = "$($scriptPath.TrimEnd('\'))\config.json"
if(test-path $configPath)
{
    $config = gc $configPath | out-string | ConvertFrom-Json
}
else
{
    write-host "No config.json was found"
    Break
}
write-host "VIM: $($config.SetupVim)"
if ($config.SetupVim)
{
    $vimConfig = "$($env:USERPROFILE)\_vimrc"
    $vimFiles = "$($env:USERPROFILE)\vimfiles"
    if(!test-path $vimConfig)
    {
    }
    if(!test-path $vimFiles)
    {
    }
}

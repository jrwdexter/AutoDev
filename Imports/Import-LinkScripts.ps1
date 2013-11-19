# Variables
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:override = $null

# Foreach link item, create the proper link
function Install-Links()
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [int]$ProgressBegin=0,
        [Parameter(Mandatory=$False)]
        [int]$ProgressEnd=100
    )

    Write-Progress -Activity "Link Binding" -Status "Binding all links" -PercentComplete $ProgressBegin

    $links = (Get-Content (Join-Path $scriptPath "../config.json") | Out-String | ConvertFrom-Json).links

    foreach($link in $links)
    {
        $source = $ExecutionContext.InvokeCommand.ExpandString($link.Source)
        $target = $ExecutionContext.InvokeCommand.ExpandString($link.Target)
        if(Test-NewLink $source $target) {
            # Create links here
            New-Link $link.type $source $target
        }
    }

    Write-Progress -Activity "Link Binding" -Status "Link binding complete" -PercentComplete $ProgressEnd
}

# Test to make sure that the source exists, and the target doesn't.  If the target does, prompt for override.
function Test-NewLink($source, $target)
{
    if((Test-Path $target) -eq $false) {
        throw "Target path $target not found."
    }
    if(Test-Path $source) {
        if($script:override -ne $null) { return $script:override }
        return (Show-ConflictPrompt $source)
    }
    return $true
}

# Prompt the user for conflict resolution.  Always/Never will set a variable for future cases.
function Show-ConflictPrompt($path) {
    $result = Select-Item -Caption "Conflict found." -Message "File or folder $path already exists.  Override?" -Choice "&Yes","&No","&Always","N&ever" -Default 1
    if($result -eq 2) { $script:override = $true }
    if($result -eq 3) { $script:override = $false }
    if($result -eq 2 -or $result -eq 0) {
        Remove-Item -Force -Recurse $path
        return $true
    }
    return $false
}

# Create a new link of any type
function New-Link($type, $source, $target)
{
    if($type -eq "junction") { New-Junction $source $target }
    if($type -eq "hard-link") { New-HardLink $source $target }
    if($type -eq "symbolic-link") { New-SymbolicLink $source $target }
    if($type -eq "copy") { Copy-Item -Recurse $source $target }
}

function New-HardLink($source, $target)
{
    cmd /c "mklink /H `"$source`" `"$target`""
}

# Create a new junction link, using sysinternals located at C:\.  This is expected from the chocolatey installation.
function New-Junction($source, $target)
{
    C:\sysinternals\junction.exe /accepteula $source $target
}

# Code for UI prompt.
Function Select-Item 
{    
<# 
    .Synopsis
        Allows the user to select simple items, returns a number to indicate the selected item. 

    .Description 
        Produces a list on the screen with a caption followed by a message, the options are then
        displayed one after the other, and the user can one. 
  
        Note that help text is not supported in this version. 

    .Example 
        PS> select-item -Caption "Configuring RemoteDesktop" -Message "Do you want to: " -choice "&Disable Remote Desktop",
           "&Enable Remote Desktop","&Cancel"  -default 1
        Will display the following 
  
        Configuring RemoteDesktop   
        Do you want to:   
        [D] Disable Remote Desktop  [E] Enable Remote Desktop  [C] Cancel  [?] Help (default is "E"): 

    .Parameter Choicelist 

        An array of strings, each one is possible choice. The hot key in each choice must be prefixed with an & sign 

    .Parameter Default 

        The zero based item in the array which will be the default choice if the user hits enter. 

    .Parameter Caption 

        The First line of text displayed 

     .Parameter Message 

        The Second line of text displayed     
#> 

Param(   [String[]]$choiceList, 

         [String]$Caption="Please make a selection", 

         [String]$Message="Choices are presented below", 

         [int]$default=0 

      ) 

   $choicedesc = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription] 

   $choiceList | foreach  { $choicedesc.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $_))} 

   $Host.ui.PromptForChoice($caption, $message, $choicedesc, $default) 
}  
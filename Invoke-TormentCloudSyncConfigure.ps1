#Requires -RunAsAdministrator

Function read-HostTimeout {
    ###################################################################
    ##  Description:  Mimics the built-in "read-host" cmdlet but adds an expiration timer for
    ##  receiving the input.  Does not support -assecurestring
    ##
    ##  This script is provided as is and may be freely used and distributed so long as proper
    ##  credit is maintained.
    ##
    ##  Written by: thegeek@thecuriousgeek.org
    ##  Date Modified:  10-24-14
    ###################################################################

    # Set parameters.  Keeping the prompt mandatory
    # just like the original
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$prompt,
	
        [Parameter(Mandatory = $false, Position = 2)]
        [int]$delayInSeconds
    )
	
    # Do the math to convert the delay given into milliseconds
    # and divide by the sleep value so that the correct delay
    # timer value can be set
    $sleep = 250
    $delay = ($delayInSeconds * 1000) / $sleep
    $count = 0
    $charArray = New-Object System.Collections.ArrayList
    Write-host -nonewline "$($prompt)  "
	
    # While loop waits for the first key to be pressed for input and
    # then exits.  If the timer expires it returns null
    While ( (!$host.ui.rawui.KeyAvailable) -and ($count -lt $delay) ) {
        start-sleep -m $sleep
        $count++
        If ($count -eq $delay) { "`n"; return $null }
    }
	
    # Retrieve the key pressed, add it to the char array that is storing
    # all keys pressed and then write it to the same line as the prompt
    $key = $host.ui.rawui.readkey("NoEcho,IncludeKeyUp").Character
    $charArray.Add($key) | out-null
    Write-host -nonewline $key
	
    # This block is where the script keeps reading for a key.  Every time
    # a key is pressed, it checks if it's a carriage return.  If so, it exits the
    # loop and returns the string.  If not it stores the key pressed and
    # then checks if it's a backspace and does the necessary cursor 
    # moving and blanking out of the backspaced character, then resumes 
    # writing. 

    $key = $host.ui.rawui.readkey("NoEcho,IncludeKeyUp")
    While ($key.virtualKeyCode -ne 13) {
        If ($key.virtualKeycode -eq 8) {
            $charArray.Add($key.Character) | out-null
            Write-host -nonewline $key.Character
            $cursor = $host.ui.rawui.get_cursorPosition()
            write-host -nonewline " "
            $host.ui.rawui.set_cursorPosition($cursor)
            $key = $host.ui.rawui.readkey("NoEcho,IncludeKeyUp")
        }
        Else {
            $charArray.Add($key.Character) | out-null
            Write-host -nonewline $key.Character
            $key = $host.ui.rawui.readkey("NoEcho,IncludeKeyUp")
        }
    }
    ""
    $finalString = -join $charArray
    return $finalString
}

Function Get-Folder($initialDirectory) {
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowserDialog.RootFolder = 'MyComputer'
    if ($initialDirectory) { $FolderBrowserDialog.SelectedPath = $initialDirectory }
    [void]$FolderBrowserDialog.ShowDialog()
    return $FolderBrowserDialog.SelectedPath
}

function Install-Sync{

    $Folder = Get-Folder $env:USERPROFILE

    #If the game folder has data it will copy it to the new folder.
    if (Test-Path "$env:USERPROFILE\AppData\LocalLow\InXile Entertainment\Torment\") {
        Robocopy "$env:USERPROFILE\AppData\LocalLow\InXile Entertainment\Torment\" $Folder /XO /E /MOVE /Z
	
        if ($lastExitCode -lt 5) {
            Remove-Item "$env:USERPROFILE\AppData\LocalLow\InXile Entertainment\Torment\" -Force -Recurse
            New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\AppData\LocalLow\InXile Entertainment\Torment\" -Target "$Folder"
		
            #If Registry Key exists changes it to the new value, else it creates a new RegKey.
            if (Test-Path "HKCU:\Software\TormentCloudSync\") {
                Set-Item -Path "HKCU:\Software\TormentCloudSync\" -Value "$Folder"
            }

            else {
                New-Item -Path "HKCU:\Software\TormentCloudSync\" -Value "$Folder"
            }

            Read-HostTimeout -prompt "Installed successfully." -delayInSeconds 15
        }
	
        else {
            Read-HostTimeout -prompt "The copy was not correct. Exiting..." -delayInSeconds 15
        }
	
    }
}

function Remove-Sync {
    if (Test-Path "HKCU:\Software\TormentCloudSync\") {
        $SyncFolder = Get-Item -Path "HKCU:\Software\TormentCloudSync\"
        (Get-Item "$env:USERPROFILE\AppData\LocalLow\InXile Entertainment\Torment\").Delete()
        New-Item -ItemType Directory -Path "$env:USERPROFILE\AppData\LocalLow\InXile Entertainment\Torment\"
        Remove-Item -Path "HKCU:\Software\TormentCloudSync\" -Recurse

        Robocopy $SyncFolder "$env:USERPROFILE\AppData\LocalLow\InXile Entertainment\Torment\" /E
    
        if ($lastExitCode -lt 5) {

            Read-HostTimeout -prompt "Files successfully restored. RegKey Removed. Symlink deleted." -delayInSeconds 15
        }
    
        else {
            Read-HostTimeout -prompt "Files not successfully restored. RegKey Removed. Symlink deleted." -delayInSeconds 15
        }
    
    }

    else {

        (Get-Item "$env:USERPROFILE\AppData\LocalLow\InXile Entertainment\Torment\").Delete()
        Read-HostTimeout -prompt "No registry key found. Symlink deleted." -delayInSeconds 15
    }
    }




 function Select-Install{
    $sel = Read-Host -Prompt "Do you want to (I)nstall, (R)emove, or (C)ancel?"
    ($sel).ToLower()
    return $sel
}

$Selection = Select-Install


if ($Selection -like "i" -or  $Selection -like "install"){
    Install-Sync
}

elseif ($Selection -like "r" -or $Selection -like "remove") {
    Remove-Sync
}

elseif ($Selection -like "c" -or $Selection -like "cancel") {
    
}

else {
    Write-Output "Invalid selection try again or press Ctrl+C to cancel."
    $Selection = Select-Install
}
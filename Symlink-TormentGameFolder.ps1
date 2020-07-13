#Requires -RunAsAdministrator

$host.ui.RawUI.WindowTitle = "Torment Sync"

Function Get-Folder($initialDirectory)
{
	[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
	$FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
	$FolderBrowserDialog.RootFolder = 'MyComputer'
	if ($initialDirectory) { $FolderBrowserDialog.SelectedPath = $initialDirectory }
	[void]$FolderBrowserDialog.ShowDialog()
	return $FolderBrowserDialog.SelectedPath
}

$Folder = Get-Folder $env:USERPROFILE

#If the game folder has data it will copy it to the new folder.
if (Get-ChildItem "$env:USERPROFILE\AppData\LocalLow\InXile Entertainment\Torment\")
{
	Robocopy "$env:USERPROFILE\AppData\LocalLow\InXile Entertainment\Torment\" $Folder /XO /E /MOVE /Z
	
	if ($lastExitCode -lt 5)
	{
		Remove-Item "$env:USERPROFILE\AppData\LocalLow\InXile Entertainment\Torment\" -Force -Recurse
		New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\AppData\LocalLow\InXile Entertainment\Torment\" -Target $Folder
	}
	
	else
	{
		Write-Error "Copy was not correct. Exiting..."
	}
	
}
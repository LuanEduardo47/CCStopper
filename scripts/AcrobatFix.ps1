if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
	Start-Process -FilePath PowerShell -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`" `"$($MyInvocation.MyCommand.UnboundArguments)`""
	Exit
}
Set-Location $PSScriptRoot
Clear-Host

function Set-ConsoleWindow([int]$Width, [int]$Height) {
	$WindowSize = $Host.UI.RawUI.WindowSize
	$WindowSize.Width = [Math]::Min($Width, $Host.UI.RawUI.BufferSize.Width)
	$WindowSize.Height = $Height

	try {
		$Host.UI.RawUI.WindowSize = $WindowSize
	} catch [System.Management.Automation.SetValueInvocationException] {
		$Maxvalue = ($_.Exception.Message | Select-String "\d+").Matches[0].Value
		$WindowSize.Height = $Maxvalue
		$Host.UI.RawUI.WindowSize = $WindowSize
	}
}

$Host.UI.RawUI.WindowTitle = "CCStopper - Acrobat Fix"
# Set-ConsoleWindow -Width 73 -Height 42

function MainScript {
	Do {
		# Thanks https://github.com/massgravel/Microsoft-Activation-Scripts for the UI
		Clear-Host
		Write-Output "`n"
		Write-Output "`n"
		Write-Output "                   _______________________________________________________________"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|                            CCSTOPPER                          `|"
		Write-Output "                  `|                        AcrobatFix Module                      `|"
		Write-Output "                  `|      ___________________________________________________      `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|                  THIS WILL EDIT THE REGISTRY!                 `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|      It is HIGHLY recommended to create a system restore      `|"
		Write-Output "                  `|      point in case something goes wrong.                      `|"
		Write-Output "                  `|      ___________________________________________________      `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|      [1] Make system restore point                            `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|      [2] Proceed without creating restore point               `|"
		Write-Output "                  `|      ___________________________________________________      `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|      [Q] Exit Module                                          `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|_______________________________________________________________`|"
		Write-Output "`n"
		$Invalid = $false
		$Choice = Read-Host ">                                            Select [1,2,Q]"
		Switch($Choice) {
			Q { Exit }
			2 { EditReg }
			1 {
				Clear-Host
				Checkpoint-Computer -Description "Before CCStopper Acrobat Fix Script" -RestorePointType "MODIFY_SETTINGS"
				EditReg
			}
			Default {
				$Invalid = $true
				[Console]::Beep(500,100)
			}
		}
	} Until (!($Invalid))
}

function EditReg {
	# Adds IsAMTEnforced with proper values, then deletes IsNGLEnfoced
	Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Adobe\Adobe Acrobat\DC\Activation" -Name IsAMTEnforced -Value 1
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Adobe\Adobe Acrobat\DC\Activation" -Name IsNGLEnforced
	RestartAsk
}

function RestartAsk {
	Do {
		# Thanks https://github.com/massgravel/Microsoft-Activation-Scripts for the UI
		Clear-Host
		Write-Output "`n"
		Write-Output "`n"
		Write-Output "                   _______________________________________________________________"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|                            CCSTOPPER                          `|"
		Write-Output "                  `|                        AcrobatFix Module                      `|"
		Write-Output "                  `|      ___________________________________________________      `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|                   Acrobat patching complete!                  `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|      The system needs to restart for changes to apply.        `|"
		Write-Output "                  `|      ___________________________________________________      `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|      [1] Restart now.                                         `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|      [2] Skip (You will need to manually restart later)       `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|                                                               `|"
		Write-Output "                  `|_______________________________________________________________`|"
		Write-Output "`n"
		$Invalid = $false
		$Choice = Read-Host ">                                            Select [1,2]: "
		Switch($Choice) {
			2 { Exit }
			1 { Restart-Computer }
			Default {
				$Invalid = $true
				[Console]::Beep(500,100)
			}
		}
	} Until (!($Invalid))
}


# Check if IsNGLEnforced already replaced w/ IsAMTEnforced
$IsAMTEnforced = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Adobe\Adobe Acrobat\DC\Activation").IsAMTEnforced
if($IsAMTEnforced -eq 1) {
	Clear-Host
	Write-Output "Acrobat has already been patched."
	Pause
	Exit
} else {
	# Check if target path exists
	$IsNGLEnforced = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Adobe\Adobe Acrobat\DC\Activation").IsNGLEnforced
	if($null -eq $IsNGLEnforced) {
		Clear-Host
		Write-Output "The target registry key cannot be found. Cannot proceed with Acrobat fix."
		Pause
		Exit
	} else {
		MainScript
	}
}
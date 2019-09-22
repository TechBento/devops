<#
ABOUT THIS SCRIPT: Installs the Amazon CLI on a system.
Created by TechBento DevOps
#>

<#
SECURITY STATEMENT:
List any concerns over this script.
#>

<#
Auditing block. It should be part of every script.
#>
$PSVersionTable.PSVersion
$ErrorActionPreference = "Continue"
$global:currentfile = $MyInvocation.MyCommand.Name #you can use Path to get the full path.
$global:logfile = "c:\ops\logs\$currentfile.txt" #this is where we keep our stuff.
Start-Transcript -Path $logfile
Write-Host "-.. . -... ..- --.DEBUG Callsign: ALPHA"
Write-Host "-.. . -... ..- --.DEBUG Logfile:" $logfile


$global:url = "https://s3.amazonaws.com/aws-cli/AWSCLI64PY3.msi"
$global:installer = "awscli.msi"

<#
MAIN BODY
#>
Write-Host " "
Write-Host "-.. . -... ..- --.DEBUG: Main Body."
Write-Host " ---------------------               --------------------- "
Write-Host " --------------------- SECTION START --------------------- "
Write-Host " ---------------------               --------------------- "
Write-Host " "
Write-Host "DEBUG: Downloading AWSCLI"

$output_dir = "c:\ops\temp\bootstrap\awscli\"
$output = "$output_dir\$installer"
$start_time = Get-Date

New-Item -ItemType directory -Path $output_dir -Force
Invoke-WebRequest -Uri $url -OutFile $output
Write-Output "DEBUG: Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"


#install AWSCLI
Start-Process msiexec.exe -ArgumentList '/i c:\ops\temp\bootstrap\awscli\awscli.msi /q' -Verb runAs -Wait


Write-Host " "
Write-Host " ---------------------               --------------------- "
Write-Host " --------------------- SECTION   END --------------------- "
Write-Host " ---------------------               --------------------- "
Write-Host " "


<#
Auditing block, end. It should be part of every script. 
#>
Write-Host "-.. . -... ..- --.DEBUG : Arrived at the end!"
Stop-Transcript
exit 0

#restarts DropBox service created manually

<#
Download srvany and extract the executable to the Dropbox install directory (C:\Program Files (x86)\Dropbox)
Start DropBox normally, do the whole config, and then remove it from startup.
sc create Dropbox binPath= “C:\Program Files (x86)\Dropbox\srvany.exe” DisplayName= “DropBox"
New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\Dropbox\Parameters
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Dropbox\Parameters -Name Application -PropertyType String -Value "C:\Program Files (x86)\Dropbox\Client\Dropbox.exe"
Might need to use '"C:\Program Files (x86)\Dropbox\Client\Dropbox.exe" /home'
Set Logon as to the user it was configured under.
Start-Service Dropbox
#>

$PSVersionTable.PSVersion
$ErrorActionPreference = "Continue"
$global:currentfile = $MyInvocation.MyCommand.Name #you can use Path to get the full path.
$global:logfile = "c:\ops\logs\$currentfile.txt" #this is where we keep our stuff.
Start-Transcript -Path $logfile
Write-Host "-.. . -... ..- --.DEBUG Callsign: ALPHA"
Write-Host "-.. . -... ..- --.DEBUG Logfile:" $logfile

$global:loopcount = 0
$global:services = @("Dropbox","DbxSvc")


#
#  FUNCTIONS BEGIN BELOW THIS AREA
#
#
#
########

function eventLogPulse
{
Write-EventLog -LogName "Application" -Source "TBPULSE" -EventID 10541 -EntryType Information -Message "PULSE script execution was performed on this system." -Category 1 -RawData 10,20
}

function service-start($ServiceName)
{
    #usage service-start "$Service"

$arrService = Get-Service -Name $ServiceName

    while ($arrService.Status -eq 'Stopped')
    {

        Start-Service $arrService
        write-host $arrService.status
        write-host 'Service starting'
        Start-Sleep -seconds 20
        $arrService.Refresh()
        if ($arrService.Status -eq 'Running')
        {
            Write-Host 'Service is now Running'
        }

    }

}

function service-stop($ServiceName)
{
    #usage service-stop "$Service"

$arrService = Get-Service -Name $ServiceName

    while ($arrService.Status -ne 'Stopped')
    {

        Stop-Service $arrService
        write-host $arrService.status
        write-host 'Service stopping'
        Start-Sleep -seconds 20
        $arrService.Refresh()
        if ($arrService.Status -eq 'Stopped')
        {
            Write-Host 'Service is now Stopped'
        }

    }

}



###################################
# MAIN BODY
###################################

#stop all services
foreach ($service in $services) {

    service-stop $service

}

#do other things that need to be done
Get-Process "DropBox" | Stop-Process -Force

#start all services
foreach ($service in $services) {

    service-start $service


}

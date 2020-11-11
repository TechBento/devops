param([String[]] $processList)
#ABOVE IS PRODUCTION, comment out when debugging

#This is used with BarracudaRMM.
#Schedule this task to run every hour, or as often as practical.
#Configure Barracuda Managed Workplace Monitors look for event 9207 and will throw a critical alert if they see it.  9208 is ignored.

#Call the script with parameters, so script.ps1 process1 process2 process3


$global:message = "PMP recorded this diagnostic event. The Process \`"$process\`" has suddenly terminated."
$global:source = "PMP"

#BELOW IS DEBUG, COMMENT OUT WHEN IN PRODUCTION
#$processList = @("dropbox") #@("dropbox","indesignserver")



function writeeventCritical(){

    if ([System.Diagnostics.EventLog]::SourceExists("$source") -eq $False) {
        New-EventLog -LogName Application -Source "$source"
        Write-Host "Writing CRITICAL event for $process"
        Write-EventLog -LogName "Application" -Source "$source" -EventID 9207 -EntryType Error -Message "$message" -RawData 10,20
    }

    Else

    {
        Write-Host "Writing CRITICAL event for $process"
        Write-EventLog -LogName "Application" -Source "$source" -EventID 9207 -EntryType Error -Message "$message" -RawData 10,20
    }

}

function writeeventInfo(){

    if ([System.Diagnostics.EventLog]::SourceExists("$source") -eq $False) {
        New-EventLog -LogName Application -Source "$source"
        Write-Host "Writing INFO event for $process"
        Write-EventLog -LogName "Application" -Source "$source" -EventID 9208 -EntryType Information -Message "$message" -RawData 10,20
    }

    Else

    {
        Write-Host "Writing INFO event for $process"
        Write-EventLog -LogName "Application" -Source "$source" -EventID 9208 -EntryType Information -Message "$message" -RawData 10,20
    }

}


#main

foreach ($global:process in $processList) {

$processActive = Get-Process $process -ErrorAction SilentlyContinue
    if($processActive -eq $null)
   
    {
         #process is not detected
         Write-host "FAILURE: $process is not running."
         writeeventCritical
    }
   
    else
   
    {
         #process is detected
         Write-host "INFO: $process is running."
         writeeventInfo
    }


}

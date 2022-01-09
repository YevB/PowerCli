################################
### Notes and References
# Based On LucD's comment: https://communities.vmware.com/t5/VMware-PowerCLI-Discussions/PowerCLI-script-VM-creation-date-and-user-info/td-p/1843709
# Note1: this might run a while, since it will fetch quite a few events
# Note2: you can adapt the value in $vmName to pick a specific set of VMs
# Note3: the sample script that was pointed to in the other answer only goes back 1 day

#region Variables

### Requirements
# Install-Module VMware.PowerCLI

### Assumptions

$startDate = Get-Date -Format "dd/MM/YYYY, HH:mm:ss, K"

Get-Module -Name VMware* -ListAvailable  | Import-Module

# Input Parameters
$vCenterServer = '[your VC FQDN or IP]'
$vCenterUser = '[userName]'
$vCenterPass = '[Password]'

#endregion

#region Connections

# Connect to the vCenter
$SecurePassword = ConvertTo-SecureString -String $vCenterPass -AsPlaintext -Force
$vcCredential=New-Object -TypeName System.Management.Automation.PSCredential `
 -ArgumentList $vCenterUser, $SecurePassword
Connect-VIServer $vCenterServer -Credential $vcCredential
Write-Host "Successfully connected to vCenter: $vCenterServer"

#endregion

#region Main

$vmName = '*'
$eventTYpes = 'VmCreatedEvent', 'VmClonedEvent', 'VmDeployedEvent', 'VmRegisteredEvent'


Get-VM -Name $vmName |
   ForEach-Object -Process {
   Get-VIEvent -Entity $_ -MaxSamples ([int]::MaxValue) |
      Where-Object { $eventTYpes -contains $_.GetType().Name } |
      Sort-Object -Property CreatedTime -Descending |
         Select-Object -First 1 | ForEach-Object -Process {
            New-Object PSObject -Property ([ordered]@{
            VM = $_.VM.Name
            CreatedTime = $_.CreatedTime
            User = $_.UserName
            EventType = $_.GetType().Name
         })
      }
   }

$endDate = Get-Date -Format "dd/MM/YYYY, HH:mm:ss, K"

Write-Host "Start time: $startDate"
Write-Host "End Time: $endDate"

#endregion

#region Disconnections

#Disconnect VI Server
Disconnect-VIServer -Server $vCenterServer -Force -Confirm:$false

#endregion
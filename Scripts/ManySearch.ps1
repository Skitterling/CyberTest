
#Setup
$findLoc = "$PSScriptRoot\Finds.txt"

#Find currently running services/apps/whatever that's open to web
$Foundservices = & "$PSScriptRoot\ManyBaby\serviceFind.ps1"
Write-Output "Current open services:"
Add-Content -Path $findLoc -Value "Current open services:"
Write-Output $Foundservices | Format-Table -AutoSize
Add-Content -Path $findLoc $Foundservices


#Search persistience
#Services
$services = & "$PSScriptRoot\ManyBaby\serviceCheck.ps1"
Write-Output "Weird Services: "
Add-Content -Path $findLoc -Value "Weird Services: "
Write-Output $services
$services -split " " | Add-Content -Path $findLoc

#Search Users
$Administrators = (Get-LocalGroupMember -Group "Administrators")
Write-Output "Current Admins:"
Add-Content -Path $findLoc -Value "Current Admins:"
Write-Output $Administrators
Add-Content -Path $findLoc $Administrators

try {
$DomainAdmins = (Get-ADGroupMember -Identity "Domain Admins" -Recursive | Select-Object Name, SamAccountName, ObjectClass)
Write-Output "Current Domain Admins:"
Write-Output $DomainAdmins
Add-Content -Path $findLoc -Value "Current Domain Admins:"
Add-Content -Path $findLoc $DomainAdmins
}
catch {}

#Search Misconfigs
Write-Output "Shares:"
$shares = Get-SmbShare | Where-Object { $_.Special -eq $false } | Out-String
Write-Output $shares
Add-Content -Path $findLoc -Value "Shares:"
Add-Content -Path $findLoc $shares

#check legacy service vulns
Write-Output "Legacy Services:"
$LegacyServs = & "$PSScriptRoot\ManyBaby\legacyCheck.ps1"
Write-Output $LegacyServs | Format-List
Add-Content -Path $findLoc -Value "Legacy Services:"
Add-Content -Path $findLoc $LegacyServs

#mimiKittenz password exfil
#Write-Host "Finding Passwords:"
#& "$PSScriptRoot\ManyBaby\Invoke-mimikittenz.ps1"

#Search Beacons
$Connections = Get-NetTCPConnection -State Established |
    Where-Object { $_.RemoteAddress -notmatch "127.0.0.1|0.0.0.0|^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\." } 

$Beacons = $Connections | Group-Object RemoteAddress | Where-Object { $_.Count -gt 3 }

foreach ($Group in $Beacons) {
    $IP = $Group.Name
    $ProcessID = $Group.Group[0].OwningProcess
    $ProcessName = (Get-Process -Id $ProcessID).ProcessName
    
    Write-Output "[!] Potential Beaconing Detected" -ForegroundColor Red
    Write-Output "Target IP: $IP"
    Write-Output "Process: $ProcessName (PID: $ProcessID)"
    Write-Output "Connection Count: $($Group.Count)"
    Write-Output "----------------------------"
    Add-Content -Path $findLoc "Target IP: $IP"
    Add-Content -Path $findLoc "Process: $ProcessName (PID: $ProcessID)"
    Add-Content -Path $findLoc "Connection Count: $($Group.Count)"
    Add-Content -Path $findLoc "----------------------------"

}
#Search Rootkits

#Search Backdoors

#Check Firewall

Write-Output "Questionable Firewall Rules:"
$wallResult = & "$PSScriptRoot\ManyBaby\wallCheck.ps1"
Write-Output $wallResult | Format-Table -AutoSize
Add-Content -Path $findLoc -Value "Questionable Firewall Rules:"
Add-Content -Path $findLoc $wallResult


#Search hidden EXE
#Write-Host "Renamed Executeables:"
#& "$PSScriptRoot\ManyBaby\exeFind.ps1"\


Read-Host "Finished Search"
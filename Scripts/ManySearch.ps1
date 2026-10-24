
#Setup
$findLoc = "$PSScriptRoot\Finds.txt"



#Search persistience
#Services
$services = & "$PSScriptRoot\ManyBaby\serviceCheck.ps1"
Write-Host "Weird Services: "
Add-Content -Path $findLoc -Value "Weird Services: "
$services -split " " | Add-Content -Path $findLoc

#Search Users
$Administrators = (Get-LocalGroupMember -Group "Administrators")
Write-Host "Current Admins:"
Add-Content -Path $findLoc -Value "Current Admins:"
Write-Host $Administrators
Add-Content -Path $findLoc $Administrators

try {
$DomainAdmins = (Get-ADGroupMember -Identity "Domain Admins" -Recursive | Select-Object Name, SamAccountName, ObjectClass)
Write-Host "Current Domain Admins:"
Write-Host $DomainAdmins
Add-Content -Path $findLoc -Value "Current Domain Admins:"
Add-Content -Path $findLoc $DomainAdmins
}
catch {}

#Search Misconfigs
Write-Host "Shares:"
$shares = Get-SmbShare | Where-Object { $_.Special -eq $false } | Out-String
Write-Host $shares
Add-Content -Path $findLoc -Value "Shares:"
Add-Content -Path $findLoc $shares

#check legacy service vulns
Write-Host "Legacy Services:"
$LegacyServs = & "$PSScriptRoot\ManyBaby\legacyCheck.ps1"
Write-Host $LegacyServs
Add-Content -Path $findLoc -Value "Legacy Services:"
Add-Content -Path $findLoc $LegacyServs

#mimiKittenz password exfil
#Write-Host "Finding Passwords:"
#& "$PSScriptRoot\ManyBaby\Invoke-mimikittenz.ps1"

#Search Beacons
$Connections = Get-NetTCPConnection -State Established |
    Where-Object { $_.RemoteAddress -notmatch "127.0.0.1|0.0.0.0|^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\." } 
    #edit this for current IP ranges "127.0.0.1|0.0.0.0|^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\."

$Beacons = $Connections | Group-Object RemoteAddress | Where-Object { $_.Count -gt 3 }

foreach ($Group in $Beacons) {
    $IP = $Group.Name
    $ProcessID = $Group.Group[0].OwningProcess
    $ProcessName = (Get-Process -Id $ProcessID).ProcessName
    
    Write-Host "[!] Potential Beaconing Detected" -ForegroundColor Red
    Write-Host "Target IP: $IP"
    Write-Host "Process: $ProcessName (PID: $ProcessID)"
    Write-Host "Connection Count: $($Group.Count)"
    Write-Host "----------------------------"
    Add-Content -Path $findLoc Target IP: $IP
    Add-Content -Path $findLoc -Value "Process: $ProcessName (PID: $ProcessID)"
    Add-Content -Path $findLoc "Connection Count: $($Group.Count)"
    Add-Content -Path $findLoc "----------------------------"

}
#Search Rootkits

#Search Backdoors

#Check Firewall

Write-Host "Questionable Firewall Rules:"
$wallResult = & "$PSScriptRoot\ManyBaby\wallCheck.ps1"
Add-Content -Path $findLoc -Value "Questionable Firewall Rules:"
Add-Content -Path $findLoc $wallResult


#Search hidden EXE
#Write-Host "Renamed Executeables:"
#& "$PSScriptRoot\ManyBaby\exeFind.ps1"\


Read-Host "Finished Search"
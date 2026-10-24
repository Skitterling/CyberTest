# Define suspicious criteria
$SuspiciousPorts = @(22, 135, 139, 445, 3389, 5985, 5986) # SSH, RPC, SMB, RDP, WinRM
$SuspiciousPaths = @(":\Users\", ":\Windows\Temp\", ":\AppData\", "\Local\Temp\")

$Rules = Get-NetFirewallRule -Enabled True | 
    Where-Object { $_.Action -eq "Allow" }

$Report = foreach ($Rule in $Rules) {
    # Resolve associated application and port filters
    $AppFilter  = $Rule | Get-NetFirewallApplicationFilter
    $PortFilter = $Rule | Get-NetFirewallPortFilter
    
    $SuspiciousReasons = @()

    # Check 1: Broad open access (Any IP, Any Port)
    if ($PortFilter.LocalPort -eq "Any" -and $PortFilter.RemoteAddress -eq "Any") {
        $SuspiciousReasons += "Completely open (Any port/Any IP)"
    }

    # Check 2: Targets high-risk ports
    foreach ($Port in $SuspiciousPorts) {
        if ($PortFilter.LocalPort -contains $Port) {
            $SuspiciousReasons += "Targets sensitive port ($Port)"
        }
    }

    # Check 3: Runs from user or temporary directories (Common malware landing spots)
    if ($AppFilter.Program) {
        foreach ($Path in $SuspiciousPaths) {
            if ($AppFilter.Program -like "*$Path*") {
                $SuspiciousReasons += "App runs from user/temp directory ($($AppFilter.Program))"
            }
        }
    }

    # If any indicators matched, compile the rule details
    if ($SuspiciousReasons.Count -gt 0) {
        [PSCustomObject]@{
            RuleName    = $Rule.DisplayName
            Group       = $Rule.Group
            Direction   = $Rule.Direction
            Program     = $AppFilter.Program
            LocalPort   = $PortFilter.LocalPort
            Profile     = $Rule.Profile
            Indicators  = ($SuspiciousReasons -join " | ")
        }
    }
}

Write-Output $Report
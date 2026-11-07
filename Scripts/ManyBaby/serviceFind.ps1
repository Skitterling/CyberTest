$services = Get-NetTCPConnection -State Listen | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    
    # Try to find an associated Windows Service name
    $service = Get-CimInstance -ClassName Win32_Service -Filter "ProcessId = $($_.OwningProcess)" -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        "Local Port"   = $_.LocalPort
        "Protocol"     = "TCP"
        "Process ID"   = $_.OwningProcess
        "Process Name" = $process.ProcessName
        "Service Name" = if ($service) { $service.Name } else { "N/A (User Application)" }
        "Executable"   = $process.Path
    }
} | Sort-Object "Local Port"

Write-Output $services
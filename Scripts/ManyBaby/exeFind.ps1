$SearchPath = "C:\"
$ErrorActionPreference = "SilentlyContinue"

Write-Host "Scanning '$SearchPath' for hidden executable files..." -ForegroundColor Cyan


$susEXEs = Get-ChildItem -Path $SearchPath -Recurse -Force | Where-Object {
    $_.PSIsContainer -eq $false -and
     $_.Extension -ne '.exe' -and
     $_.Extension -ne '.dll' -and
     $_.Extension -ne '.tlb' -and
     $_.Extension -ne '.sys' -and
     $_.Extension -ne '.mui'
} | ForEach-Object {
    $file = $_
    try {
        # Read the first 2 bytes to check for the MZ executable signature ('M', 'Z')
        $stream = [System.IO.File]::OpenRead($file.FullName)
        $buffer = New-Object byte[] 2
        $stream.Read($buffer, 0, 2) | Out-Null
        $stream.Close()

        # ASCII 'M' = 77, 'Z' = 90
        if ($buffer[0] -eq 77 -and $buffer[1] -eq 90) {
            [PSCustomObject]@{
                FullName   = $file.FullName
                LengthKB   = [Math]::Round($file.Length / 1KB, 2)
                Extension  = $file.Extension
                LastWrite  = $file.LastWriteTime
                Attributes = $file.Attributes
            }
        }
    } catch {
        # Skip files locked by the system or access denied
    }
}

Write-Output $susEXEs
Write-Host "Simulasi RDP Brute Force - Project Sentinel" -ForegroundColor Yellow
Write-Host "Target: 192.168.10.20 (Windows Endpoint)" -ForegroundColor Cyan
Write-Host "Generating 15 failed authentication attempts..." -ForegroundColor Red

$users = @("administrator","admin","root","fyep-2","db_admin","backup","sysadmin")
$passes = @("wrongpass1","wrongpass2","wrongpass3","wrongpass4","wrongpass5",
            "123456","password","admin","letmein","qwerty",
            "GTCorp2026","sentinel","infradigital","fyep2026","test123")

$count = 0
foreach ($pass in $passes) {
    $user = $users[$count % $users.Count]
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $ds = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
        [System.DirectoryServices.AccountManagement.ContextType]::Machine
    )
    $result = $ds.ValidateCredentials($user, $pass)
    $count++
    Write-Host "[$count/15] Attempt: $user / $pass ? Failed" -ForegroundColor Red
    Start-Sleep -Milliseconds 300
}

Write-Host ""
Write-Host "Selesai: $count authentication attempts" -ForegroundColor Green
Write-Host "Cek Wazuh Dashboard: rule.id: 100004" -ForegroundColor Cyan

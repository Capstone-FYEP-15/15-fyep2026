param([string]$Mode = "full", [int]$FileCount = 60)

$TARGET = "C:\Users\fyep-2\Documents\gtcorp_files"

Write-Host "============================================" -ForegroundColor Blue
Write-Host "  PROJECT SENTINEL - Ransomware Simulator  " -ForegroundColor Blue
Write-Host "  Mode: $Mode | Files: $FileCount          " -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue

$confirm = Read-Host "Jalankan simulasi? (y/n)"
if ($confirm -ne "y") { Write-Host "Dibatalkan."; exit 0 }

if ($Mode -eq "cleanup") {
    Remove-Item -Recurse -Force $TARGET -ErrorAction SilentlyContinue
    Write-Host "Cleanup selesai" -ForegroundColor Green
    exit 0
}

if ($Mode -eq "restore") {
    $locked = Get-ChildItem -Recurse -File $TARGET -ErrorAction SilentlyContinue |
              Where-Object { $_.Extension -eq ".locked" }
    foreach ($file in $locked) {
        Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
    }
    Remove-Item "$TARGET\README_DECRYPT.txt" -Force -ErrorAction SilentlyContinue
    Write-Host "Restore selesai" -ForegroundColor Green
    exit 0
}

# MODE FULL — buat file lalu enkripsi
Write-Host "[1/3] Membuat $FileCount file target..." -ForegroundColor Cyan
$dirs = @("Documents","Database","Finance","HR","Backup")
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path "$TARGET\$d" -Force | Out-Null
}
$perDir = [math]::Ceiling($FileCount / 5)
for ($i = 1; $i -le $perDir; $i++) {
    "CONFIDENTIAL GTCorp Report $i - $(Get-Date)" | Set-Content "$TARGET\Documents\report_$i.docx"
    "DB_RECORD $i - SELECT * FROM customers WHERE id=$i" | Set-Content "$TARGET\Database\record_$i.sql"
    "FINANCIAL DATA Q$i - Revenue $($i * 1000000)" | Set-Content "$TARGET\Finance\ledger_$i.xlsx"
    "EMP$i - John Doe - IT Department" | Set-Content "$TARGET\HR\employee_$i.txt"
    "BACKUP $i - $(Get-Date -Format 'yyyy-MM-dd')" | Set-Content "$TARGET\Backup\backup_$i.bak"
}
$total = (Get-ChildItem -Recurse $TARGET -File).Count
Write-Host "[1/3] $total file dibuat" -ForegroundColor Green

Write-Host "[2/3] Menunggu 15 detik agar Wazuh FIM scan file baru..." -ForegroundColor Cyan
for ($i = 15; $i -gt 0; $i--) {
    Write-Host -NoNewline "`r    Countdown: $i detik...   "
    Start-Sleep 1
}
Write-Host ""

Write-Host "[3/3] Simulasi enkripsi massal dimulai..." -ForegroundColor Yellow
Write-Host "      Ini akan trigger Wazuh FIM alert!" -ForegroundColor Red

$files = Get-ChildItem -Recurse -File $TARGET | Where-Object { $_.Extension -ne ".locked" }
$count = 0
$startTime = Get-Date

foreach ($file in $files) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -eq $null) { $content = "" }
        $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
        $encrypted = "=== SENTINEL-RANSOMWARE-SIM ===" + "`n"
        $encrypted += "Original: $($file.Name)" + "`n"
        $encrypted += "Time: $(Get-Date)" + "`n"
        $encrypted += "=== ENCRYPTED CONTENT ===" + "`n"
        $encrypted += $b64
        $newPath = $file.FullName + ".locked"
        [System.IO.File]::WriteAllText($newPath, $encrypted, [System.Text.Encoding]::UTF8)
        Remove-Item $file.FullName -Force
        $count++
        if ($count % 10 -eq 0) {
            Write-Host "    Progress: $count/$($files.Count) file dienkripsi"
        }
    } catch {
        Write-Host "    Skip: $($file.Name)" -ForegroundColor Gray
    }
}

"=== RANSOM NOTE - PROJECT SENTINEL SIMULATION ===" | Set-Content "$TARGET\README_DECRYPT.txt"
"Waktu: $(Get-Date)" | Add-Content "$TARGET\README_DECRYPT.txt"
"Pelaksana: Yusmadani Firmansyah - FYEP Cybersecurity 2026" | Add-Content "$TARGET\README_DECRYPT.txt"

$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
Write-Host "[3/3] Enkripsi selesai: $count file dalam $duration detik" -ForegroundColor Green
Write-Host ""
Write-Host "Cek Wazuh Dashboard:" -ForegroundColor Cyan
Write-Host "  https://100.84.121.118 -> Security Events -> syscheck" -ForegroundColor Cyan
Write-Host "  rule.groups: syscheck AND agent: windows-endpoint" -ForegroundColor Cyan
Write-Host ""
Write-Host "Untuk restore : -Mode restore" -ForegroundColor Yellow
Write-Host "Untuk cleanup : -Mode cleanup" -ForegroundColor Yellow
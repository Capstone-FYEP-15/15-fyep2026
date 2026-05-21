# Panduan Akses VM — Project Sentinel
**Dokumentasi untuk Seluruh Anggota Tim**
FYEP Cybersecurity 2026 · InfraDigital Foundation

---

## Daftar Isi

1. [Informasi Jaringan & Credentials](#1-informasi-jaringan--credentials)
2. [Setup Awal — Bergabung ke Jaringan Tailscale](#2-setup-awal--bergabung-ke-jaringan-tailscale)
3. [Panduan Akses per VM](#3-panduan-akses-per-vm)
4. [Troubleshooting](#4-troubleshooting)
5. [Hal yang Perlu Diperhatikan](#5-hal-yang-perlu-diperhatikan)

---

## 1. Informasi Jaringan & Credentials

### Daftar VM

| # | VM | IP Lokal | IP Publik | Tailscale IP | Lokasi | Username | Akses | Uptime |
|---|---|---|---|---|---|---|---|---|
| 01 | pfSense | 192.168.10.2 | — | via PC Lab | PC Lab | admin | Browser | Selalu menyala |
| 02 | Honeypot | — | 20.196.144.29 | 100.71.170.81 | Azure | deaginting | SSH | Selalu menyala |
| 03 | Wazuh SIEM | — | 72.155.88.10 | 100.87.181.20 | Azure | dea-2 | SSH + Browser | Selalu menyala |
| 04 | Windows Endpoint | 192.168.10.20 | — | via PC Lab | PC Lab | fyep-2 | RDP + SSH | Saat dibutuhkan |
| 05 | Linux Endpoint | 192.168.10.30 | — | via PC Lab | PC Lab | fyep-1 | SSH | Saat dibutuhkan |
| 06 | Kali Linux | — | — | — | Laptop Yusmadani | — | Lokal | — |

> **Password:** Tanyakan ke Dea (PM) via DM. Jangan bagikan password di grup besar.

### Tailscale Network

| Perangkat | Tailscale IP | Keterangan |
|---|---|---|
| desktop-0j9iojp | 100.101.161.92 | PC Lab — host VM pfSense, Windows, Linux |
| deaginting | 100.71.170.81 | Azure VM — Honeypot |
| dea-2 | 100.87.181.20 | Azure VM — Wazuh SIEM |
| laptop-8rkn3r3o | 100.81.2.27 | Laptop anggota |

> **Catatan:** VM di PC Lab (pfSense, Windows Endpoint, Linux Endpoint) diakses via subnet `192.168.x.x` — bukan via Tailscale IP langsung. Tailscale PC Lab bertindak sebagai jembatan ke subnet tersebut.

---

## 2. Setup Awal — Bergabung ke Jaringan Tailscale

Setiap anggota wajib melakukan setup ini **satu kali** sebelum bisa mengakses semua VM. Semua konektivitas antar VM sudah disiapkan — anggota tinggal join ke jaringan Tailscale tim dan langsung bisa akses.

---

### Step 1 — Install Tailscale

#### Windows

```
1. Buka https://tailscale.com/download/windows
2. Download dan install file .msi
3. Setelah install, Tailscale muncul di system tray (pojok kanan bawah taskbar)
4. Klik ikon Tailscale → "Log in"
5. Login dengan akun tim: nescafe7000@gmail.com
6. Klik "Connect"
```

Buka **PowerShell sebagai Administrator**, jalankan:

```powershell
tailscale up --accept-routes
```

#### Linux / Mac

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Login dengan akun tim dan accept routes
sudo tailscale up --accept-routes
```

Akan muncul link di terminal — buka di browser dan login dengan akun tim `nescafe7000@gmail.com`.

#### Kali Linux

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --accept-routes
```

---

### Step 2 — Verifikasi koneksi

Setelah login, jalankan perintah berikut untuk memastikan semua VM bisa dijangkau:

```bash
# Cek semua perangkat tim terhubung
tailscale status

# Test ke PC Lab
ping 100.101.161.92

# Test ke VM di PC Lab
ping 192.168.10.2     # pfSense
ping 192.168.10.20    # Windows Endpoint
ping 192.168.10.30    # Linux Endpoint

# Test ke Azure VM
ping 100.71.170.81    # Honeypot
ping 100.87.181.20    # Wazuh SIEM
```

Kalau semua ping reply — siap mengakses semua VM.

---

### Step 3 — Install tools akses (jika belum ada)

#### SSH Client

| OS | Cara |
|---|---|
| Windows | Sudah built-in di Windows 10/11 — buka PowerShell atau CMD |
| Linux/Mac | Sudah tersedia default — cek dengan `ssh --version` |

#### RDP Client (untuk Windows Endpoint)

| OS | Cara |
|---|---|
| Windows | Sudah built-in — tekan `Windows + R` → ketik `mstsc` |
| Linux | `sudo apt install remmina -y` |
| Mac | Download **Microsoft Remote Desktop** dari App Store |

---

## 3. Panduan Akses per VM

---

### VM 01 — pfSense (Firewall)

**Fungsi:** Firewall utama, VLAN gateway, micro-segmentation, active response.

**Via browser:**
```
http://192.168.10.2

Username : admin
Password : (tanyakan ke Dea)
```

**Via SSH (aktifkan dulu di web GUI):**
```
pfSense web GUI → System → Advanced → Admin Access
→ centang "Enable Secure Shell" → Save
```
```bash
ssh admin@192.168.10.2
```

---

### VM 02 — Honeypot (Azure)

**Fungsi:** Server jebakan Cowrie + OpenCanary di zona DMZ.

**Via SSH:**
```bash
# Via IP publik
ssh deaginting@20.196.144.29

# Via Tailscale (dari mana saja)
ssh deaginting@100.71.170.81
```

**Cek log honeypot:**
```bash
# Log realtime Cowrie
tail -f /var/log/cowrie/cowrie.log

# Log JSON (untuk integrasi Wazuh)
tail -f /var/log/cowrie/cowrie.json
```

---

### VM 03 — Wazuh SIEM (Azure)

**Fungsi:** SIEM utama — menerima log, menjalankan detection rules, menampilkan dashboard.

**Via browser (Wazuh Dashboard):**
```
https://72.155.88.10

Username : dea-2
Password : (tanyakan ke Dea)
```

**Via SSH:**
```bash
# Via IP publik
ssh dea-2@72.155.88.10

# Via Tailscale (dari mana saja)
ssh dea-2@100.87.181.20
```

---

### VM 04 — Windows Endpoint

**Fungsi:** Target simulasi serangan Windows — brute force RDP, Mimikatz, Pass-the-Hash, ransomware.

**Via RDP:**

| OS | Perintah |
|---|---|
| Windows | `Windows + R` → `mstsc` → Computer: `192.168.10.20` |
| Linux | `remmina -c rdp://fyep-2@192.168.10.20` |
| Mac | Microsoft Remote Desktop → Add PC → `192.168.10.20` |

```
Username : fyep-2
Password : (tanyakan ke Dea)
```

**Via SSH (jika OpenSSH aktif):**
```bash
ssh fyep-2@192.168.10.20
```

---

### VM 05 — Linux Endpoint

**Fungsi:** Target simulasi brute force SSH dan Log4Shell. Merepresentasikan production server.

**Via SSH:**
```bash
ssh fyep-1@192.168.10.30
```

**Perintah berguna setelah masuk:**
```bash
# Cek IP
ip addr show

# Cek status Wazuh agent
systemctl status wazuh-agent

# Monitor log autentikasi
tail -f /var/log/auth.log
```

---

### VM 06 — Kali Linux (Laptop Yusmadani)

**Fungsi:** Mesin simulasi serangan — dijalankan lokal di laptop Yusmadani, tidak perlu akses remote.

Setelah Tailscale aktif di Kali, semua target langsung bisa dijangkau:

```bash
# Verifikasi koneksi ke semua target
ping 192.168.10.20    # Windows Endpoint
ping 192.168.10.30    # Linux Endpoint
ping 192.168.10.2     # pfSense
ping 100.71.170.81    # Honeypot (Azure)

# Verifikasi tools tersedia
nmap --version
hydra --version
msfconsole --version
```

> Untuk keperluan live demo Minggu 4, Romadhona mengoperasikan Kali Linux ini — koordinasikan dengan Yusmadani untuk akses.

---

## 4. Troubleshooting

---

### Tailscale terhubung tapi tidak bisa ping 192.168.x.x

**Penyebab:** `--accept-routes` belum dijalankan di laptop.

```bash
# Linux/Mac
sudo tailscale up --accept-routes

# Windows (PowerShell Admin)
tailscale up --accept-routes
```

---

### Ping berhasil tapi SSH atau RDP gagal

**Cek SSH di Linux Endpoint:**
```bash
sudo systemctl status ssh

# Aktifkan jika belum jalan
sudo systemctl start ssh
sudo systemctl enable ssh

# Izinkan di firewall
sudo ufw allow ssh
```

**Cek RDP di Windows Endpoint:**
```
Windows Security → Firewall & network protection
→ matikan semua (sementara)
```

---

### PC Lab mati — VM pfSense, Windows, Linux tidak bisa diakses

Hubungi anggota yang berada di kampus untuk menyalakan PC Lab. Setelah PC Lab menyala, nyalakan VM dengan urutan:

```
1. VM pfSense  → nyalakan pertama, tunggu boot ±1 menit
2. VM Windows  → nyalakan sesuai kebutuhan
3. VM Linux    → nyalakan sesuai kebutuhan
```

---

### Tailscale di PC Lab tidak aktif setelah restart

Minta anggota di kampus untuk buka PowerShell sebagai Administrator dan jalankan:

```powershell
tailscale up --advertise-routes=192.168.10.0/24,192.168.20.0/24,192.168.30.0/24 --accept-routes
```

---

### Koneksi lambat atau latency tinggi

Normal — koneksi melewati DERP relay Tokyo karena firewall kampus memblokir koneksi langsung. Latency 100–400ms adalah wajar. Untuk transfer file besar atau pekerjaan yang butuh koneksi cepat, lakukan langsung di PC Lab secara fisik.

---

## 5. Hal yang Perlu Diperhatikan

**PC Lab harus menyala untuk akses VM di jaringan lokal.**
VM pfSense, Windows Endpoint, dan Linux Endpoint hanya bisa diakses selama PC Lab menyala dan Tailscale aktif. Koordinasikan dengan anggota yang berada di kampus.

**Jangan matikan pfSense sembarangan.**
pfSense adalah gateway seluruh jaringan lokal. Jika dimatikan, semua VM di VLAN10 dan VLAN20 kehilangan koneksi.

**Snapshot VM sebelum simulasi serangan (Minggu 3).**
```
VMware → klik kanan VM → Snapshot → Take Snapshot
Name: before-attack-simulation
```

**Jangan bagikan credentials di grup besar.**
Minta password via DM ke Dea — jangan kirim di grup WhatsApp yang ada mentor dan panitia.

**Lapor ke PM jika ada masalah akses lebih dari 30 menit.**
Hubungi Dea Kristin Ginting untuk koordinasi penyelesaian.

---

## Ringkasan Cepat

```
Tailscale          → login: nescafe7000@gmail.com
                     jalankan: tailscale up --accept-routes

pfSense            → http://192.168.10.2           (admin)
Honeypot           → ssh deaginting@100.71.170.81
Wazuh Dashboard    → https://72.155.88.10          (dea-2)
Wazuh SSH          → ssh dea-2@100.87.181.20
Windows Endpoint   → RDP 192.168.10.20             (fyep-2)
Linux Endpoint     → ssh fyep-1@192.168.10.30
Kali Linux         → Laptop Yusmadani (lokal)
```

---

*Dibuat oleh: Dea Kristin Ginting (Project Manager)*
*Terakhir diperbarui: 21 Mei 2026*
*Repository: Capstone FYEP-15 / 15-fyep2026 · `/docs/infrastructure/PANDUAN_AKSES_VM.md`*

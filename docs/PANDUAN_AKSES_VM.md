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

| # | VM | IP Lokal | Tailscale IP | Lokasi | VLAN | Username | Akses | Uptime |
|---|---|---|---|---|---|---|---|---|
| 01 | pfSense | 192.168.10.2 | via PC Lab | PC Lab | — | admin | Browser | Selalu menyala |
| 02 | Wazuh SIEM | 192.168.20.10 | 100.84.121.118 | PC Lab | VLAN20 | wazuh-siem | SSH + Browser | Selalu menyala |
| 03 | Honeypot | 192.168.30.10 | — | PC Lab | VLAN30 | honeypot | SSH | Selalu menyala |
| 04 | Windows Endpoint | 192.168.10.20 | via PC Lab | PC Lab | VLAN10 | fyep-2 | RDP + SSH | Saat dibutuhkan |
| 05 | Linux Endpoint | 192.168.10.30 | via PC Lab | PC Lab | VLAN10 | fyep-1 | SSH | Saat dibutuhkan |
| 06 | Kali Linux | — | — | Laptop Yusmadani | — | — | Lokal | Minggu 3 saja |

> **Password:** Tanyakan ke Dea (PM) via DM. Jangan bagikan password di grup besar.

### IP Scheme per VLAN

| VLAN | Subnet | Gateway (pfSense) | VM |
|---|---|---|---|
| VLAN10 — LAN Produksi | 192.168.10.0/24 | 192.168.10.2 | Windows (10.20), Linux (10.30) |
| VLAN20 — Management | 192.168.20.0/24 | 192.168.20.1 | Wazuh SIEM (20.10) |
| VLAN30 — DMZ | 192.168.30.0/24 | 192.168.30.1 | Honeypot (30.10) |

> **Catatan:** VM di PC Lab diakses via subnet `192.168.x.x` melalui Tailscale PC Lab sebagai jembatan. Wazuh Dashboard juga bisa diakses langsung via Tailscale IP `100.84.121.118`.

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
tailscale up --accept-routes --advertise-routes=192.168.10.0/24,192.168.20.0/24,192.168.30.0/24
```

> **Catatan untuk PC Lab:** Gunakan perintah di atas yang menyertakan `--advertise-routes`. Untuk laptop anggota biasa, cukup `tailscale up --accept-routes`.

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

# Test ke VM di VLAN10 (via PC Lab)
ping 192.168.10.2     # pfSense
ping 192.168.10.20    # Windows Endpoint
ping 192.168.10.30    # Linux Endpoint

# Test ke Wazuh (via Tailscale langsung)
ping 100.84.121.118   # Wazuh SIEM

# Test ke VLAN20 dan VLAN30 (via PC Lab)
ping 192.168.20.10    # Wazuh SIEM
ping 192.168.30.10    # Honeypot
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

### VM 02 — Wazuh SIEM (VLAN20 — PC Lab)

**Fungsi:** SIEM utama — menerima log dari semua endpoint, menjalankan detection rules, menampilkan dashboard.

**Via browser (Wazuh Dashboard) — 2 cara:**
```
# Cara 1: via IP lokal (dari jaringan yang terhubung pfSense)
https://192.168.20.10

# Cara 2: via Tailscale (dari mana saja, tanpa perlu PC Lab sebagai jembatan)
https://100.84.121.118

Username : admin
Password : (tanyakan ke Dea)
```

**Via SSH:**
```bash
# Via IP lokal VLAN20
ssh wazuh-siem@192.168.20.10

# Via Tailscale (dari mana saja)
ssh wazuh-siem@100.84.121.118
```

**Perintah berguna setelah masuk:**
```bash
# Cek status semua komponen Wazuh
sudo systemctl status wazuh-manager
sudo systemctl status wazuh-indexer
sudo systemctl status wazuh-dashboard

# Cek agent yang terhubung
sudo /var/ossec/bin/agent_control -l

# Lihat log Wazuh Manager
sudo tail -f /var/ossec/logs/ossec.log
```

---

### VM 03 — Honeypot (VLAN30 — PC Lab)

**Fungsi:** Server jebakan Cowrie (SSH) + OpenCanary (FTP, HTTP) di zona DMZ.

**Via SSH (port admin 22222):**
```bash
# Via IP lokal VLAN30
ssh honeypot@192.168.30.10 -p 22222
```

> **Catatan:** Port 22 di honeypot sudah diredirect ke Cowrie (honeypot). Akses admin menggunakan port 22222.

**Cek log honeypot:**
```bash
# Log realtime Cowrie
sudo tail -f /home/cowrie/cowrie/var/log/cowrie/cowrie.log

# Log JSON (untuk integrasi Wazuh)
sudo tail -f /home/cowrie/cowrie/var/log/cowrie/cowrie.json

# Status service
sudo systemctl status cowrie
sudo systemctl status opencanary
```

---

### VM 04 — Windows Endpoint (VLAN10 — PC Lab)

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

### VM 05 — Linux Endpoint (VLAN10 — PC Lab)

**Fungsi:** Target simulasi brute force SSH dan Log4Shell. Merepresentasikan production server.

**Via SSH:**
```bash
ssh fyep-1@192.168.10.30
```

**Perintah berguna setelah masuk:**
```bash
# Cek IP dan routing
ip addr show
ip route show

# Cek status Wazuh agent
systemctl status wazuh-agent

# Monitor log autentikasi
tail -f /var/log/auth.log

# Cek fix-route service (routing Tailscale)
sudo systemctl status fix-route.service
```

> **Catatan:** VM ini menggunakan `fix-route.service` untuk mencegah Tailscale meng-override routing ke VLAN lain. Jika setelah restart tidak bisa diakses dari VLAN lain, jalankan: `sudo systemctl restart fix-route.service`

---

### VM 06 — Kali Linux (Laptop Yusmadani)

**Fungsi:** Mesin simulasi serangan — dijalankan lokal di laptop Yusmadani, tidak perlu akses remote.

Setelah Tailscale aktif di Kali, semua target langsung bisa dijangkau:

```bash
# Verifikasi koneksi ke semua target
ping 192.168.10.20    # Windows Endpoint
ping 192.168.10.30    # Linux Endpoint
ping 192.168.10.2     # pfSense
ping 192.168.30.10    # Honeypot
ping 192.168.20.10    # Wazuh SIEM

# Verifikasi tools tersedia
nmap --version
hydra --version
msfconsole --version
```


---

## 4. Troubleshooting

---

### Tailscale terhubung tapi tidak bisa ping 192.168.x.x

**Penyebab:** `--accept-routes` belum dijalankan di laptop.

```bash
# Linux/Mac
sudo tailscale up --accept-routes

# Windows (PowerShell Admin)
tailscale up --accept-routes --advertise-routes=192.168.10.0/24,192.168.20.0/24,192.168.30.0/24
```

---

### Linux Endpoint tidak bisa diakses dari VM lain setelah restart

Tailscale meng-override routing ke subnet lain. Jalankan fix:

```bash
# SSH ke fyep-1 via console VMware dulu
sudo systemctl restart fix-route.service
sudo systemctl status fix-route.service

# Verifikasi routing
ip route get 192.168.10.20   # harus via ens33, bukan tailscale0
ip route get 192.168.20.10   # harus via ens33, bukan tailscale0
```

Jika masih via tailscale0:

```bash
sudo ip route del 192.168.10.0/24 table 52 2>/dev/null; true
sudo ip route del 192.168.20.0/24 table 52 2>/dev/null; true
sudo ip route del 192.168.30.0/24 table 52 2>/dev/null; true
```

---

### Ping berhasil tapi SSH atau RDP gagal

**Cek SSH di Linux Endpoint:**
```bash
sudo systemctl status ssh
sudo systemctl start ssh
sudo ufw allow ssh
```

**Cek RDP di Windows Endpoint:**
```
Windows Security → Firewall & network protection → matikan semua (sementara)
```

---

### Wazuh agent tidak bisa connect ke Manager

```bash
# Cek konfigurasi ossec.conf
sudo cat /var/ossec/etc/ossec.conf | grep -A 5 "<server>"
```

Pastikan address sudah `192.168.20.10` bukan `MANAGER_IP`:

```bash
sudo nano /var/ossec/etc/ossec.conf
# Ubah <address>MANAGER_IP</address> → <address>192.168.20.10</address>

sudo systemctl restart wazuh-agent
sudo tail -20 /var/ossec/logs/ossec.log
```

---

### PC Lab mati — VM tidak bisa diakses

Hubungi anggota yang berada di kampus. Setelah PC Lab menyala, nyalakan VM dengan urutan:

```
1. VM pfSense       → nyalakan pertama, tunggu boot ±1 menit
2. VM Wazuh SIEM    → nyalakan kedua
3. VM Honeypot      → nyalakan ketiga
4. VM Windows/Linux → nyalakan sesuai kebutuhan
```

Setelah semua VM menyala, aktifkan kembali Tailscale di PC Lab:

```powershell
tailscale up --accept-routes --advertise-routes=192.168.10.0/24,192.168.20.0/24,192.168.30.0/24
```

---

### Koneksi lambat atau latency tinggi

Normal — koneksi melewati DERP relay Tokyo karena firewall kampus memblokir koneksi langsung. Latency 100–400ms adalah wajar. Untuk transfer file besar atau pekerjaan yang butuh koneksi cepat, lakukan langsung di PC Lab secara fisik.

---

## 5. Hal yang Perlu Diperhatikan

**PC Lab harus menyala untuk akses VM di jaringan lokal.**
pfSense, Wazuh, Honeypot, Windows Endpoint, dan Linux Endpoint hanya bisa diakses selama PC Lab menyala dan Tailscale aktif. Wazuh Dashboard juga bisa diakses via Tailscale IP `100.84.121.118` tanpa bergantung pada subnet routing.

**Jangan matikan pfSense sembarangan.**
pfSense adalah gateway seluruh jaringan lokal. Jika dimatikan, semua VM di VLAN10, VLAN20, dan VLAN30 kehilangan koneksi antar jaringan.

**Urutan menyalakan VM penting.**
pfSense harus menyala lebih dulu sebelum VM lain agar routing antar VLAN berfungsi.

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
Tailscale login    → nescafe7000@gmail.com
Tailscale run      → tailscale up --accept-routes

pfSense GUI        → http://192.168.10.2              (admin)
Wazuh Dashboard    → https://192.168.20.10            (admin)
                   → https://100.84.121.118           (admin) ← via Tailscale langsung
Wazuh SSH          → ssh wazuh-siem@192.168.20.10
                   → ssh wazuh-siem@100.84.121.118
Honeypot SSH       → ssh honeypot@192.168.30.10 -p 22222
Windows Endpoint   → RDP 192.168.10.20                (fyep-2)
Linux Endpoint     → ssh fyep-1@192.168.10.30
Kali Linux         → Laptop Yusmadani (lokal)
```

---


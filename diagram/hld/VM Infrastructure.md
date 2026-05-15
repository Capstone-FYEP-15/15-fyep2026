# VM Infrastructure — Project Sentinel
**Lab Environment Documentation**
FYEP Cybersecurity 2026 · InfraDigital Foundation

---

## Daftar Isi

1. [Ringkasan Kebutuhan VM](#1-ringkasan-kebutuhan-vm)
2. [Spesifikasi 6 VM](#2-spesifikasi-6-vm)
3. [Permasalahan: Tim Berjauhan & Jadwal Tidak Sinkron](#3-permasalahan-tim-berjauhan--jadwal-tidak-sinkron)
4. [Opsi Solusi Lab Environment](#4-opsi-solusi-lab-environment)
5. [Rekomendasi untuk Tim Sentinel](#5-rekomendasi-untuk-tim-sentinel)
6. [Panduan Akses Antar Anggota](#6-panduan-akses-antar-anggota)
7. [Catatan Versi](#7-catatan-versi)

---

## 1. Ringkasan Kebutuhan VM

Project Sentinel membutuhkan **6 VM minimum** yang tersebar di 4 zona jaringan berbeda. Setiap VM menjalankan peran spesifik yang tidak bisa digabung tanpa mengorbankan isolasi jaringan yang menjadi inti arsitektur keamanan ini.

```
Total VM    : 6
Total RAM   : ~20 GB (minimum yang disarankan: 24 GB di host)
Total vCPU  : ~12 vCPU
Total Disk  : ~155 GB
```

| VLAN | Zona | Jumlah VM |
|---|---|---|
| VLAN 30 | DMZ | 2 VM (pfSense + Honeypot) |
| VLAN 10 | LAN Produksi | 2 VM (Windows Endpoint + Linux Endpoint) |
| VLAN 10 | LAN Produksi | 1 VM (Production Server — digabung di Linux Endpoint jika RAM terbatas) |
| VLAN 20 | Management Network | 1 VM (Wazuh SIEM) |
| Attacker | Terisolasi | 1 VM (Kali Linux — digabung ke total 6 dari 7 dengan menggabungkan Production + Linux) |

> **Catatan:** Dokumen ini menggunakan konfigurasi 6 VM dengan menggabungkan **Linux Endpoint dan Production Server** menjadi satu VM. Jika RAM host mencukupi (32 GB+), disarankan tetap pisah menjadi 7 VM untuk isolasi yang lebih bersih.

---

## 2. Spesifikasi 6 VM

---

### VM 01 — pfSense (Firewall / Router)

| Atribut | Detail |
|---|---|
| Zona | DMZ — VLAN 30 |
| OS | pfSense CE 2.7.x atau OPNsense 24.x |
| vCPU | 1 core |
| RAM | 1 GB |
| Disk | 8 GB |
| Network Adapter | 4 adapter (1 per VLAN: WAN, VLAN10, VLAN20, VLAN30) |
| IP | 192.168.30.1 *(gateway DMZ)* |
| **PIC Setup** | **Triyas Niko Saputra** |
| **PIC Konfigurasi** | **Triyas Niko Saputra** |

**Fungsi:**
VM ini adalah gerbang utama dan penegak kebijakan jaringan seluruh lab. Semua traffic antar zona harus melewati pfSense — tidak ada jalur langsung antar VLAN tanpa melalui pemeriksaan firewall rules di sini. pfSense juga menjadi target perintah auto-block IP dari Wazuh Active Response saat serangan terdeteksi.

**Tanggung jawab konfigurasi Triyas:**
- Buat dan assign 4 VLAN (WAN, VLAN10, VLAN20, VLAN30)
- Konfigurasi firewall rules: Production → Management hanya izinkan port 1514
- Konfigurasi firewall rules: blokir semua akses DMZ → Production secara default
- Aktifkan syslog forwarding ke Wazuh (IP VLAN20) via port 514
- Aktifkan pfSense API untuk Active Response Wazuh

**Notes:**
- VM ini harus dibuat dan dikonfigurasi **pertama kali** sebelum VM lain — semua konektivitas jaringan bergantung padanya
- Gunakan Proxmox atau VMware untuk multiple network adapter
- Simpan backup konfigurasi pfSense (menu Diagnostics → Backup) setiap kali ada perubahan besar

---

### VM 02 — Honeypot Server (Cowrie + OpenCanary)

| Atribut | Detail |
|---|---|
| Zona | DMZ — VLAN 30 |
| OS | Ubuntu Server 22.04 LTS |
| vCPU | 1 core |
| RAM | 1 GB |
| Disk | 10 GB |
| Network Adapter | 1 adapter (VLAN30) |
| IP | 192.168.30.10 |
| **PIC Setup VM** | **Triyas Niko Saputra** |
| **PIC Install App** | **Yusmadani Firmansyah** |

**Fungsi:**
Server palsu yang dirancang untuk menjebak penyerang yang sudah masuk ke jaringan. Cowrie mensimulasikan SSH/Telnet server dan merekam semua perintah yang diketik penyerang. OpenCanary menambahkan layanan palsu lain (HTTP, SMB, FTP). Setiap koneksi ke VM ini adalah anomali — pengguna sah tidak pernah menyentuhnya.

**Tanggung jawab Triyas:**
- Buat VM dan install Ubuntu Server 22.04
- Tempatkan di VLAN 30 dengan IP 192.168.30.10
- Pastikan VM tidak bisa melakukan koneksi outbound ke VLAN 10 (Production)
- Serahkan akses SSH ke Yusmadani setelah VM siap

**Tanggung jawab Yusmadani:**
- Install Cowrie SSH honeypot
- Install OpenCanary (HTTP, SMB, FTP palsu)
- Kustomisasi banner dan fake credential agar terlihat seperti server produksi nyata
- Konfigurasi Filebeat untuk forward log JSON ke Wazuh (koordinasi port dengan Rafli)
- Test: SSH dari Kali ke IP ini harus menghasilkan log interaksi

**Notes:**
- Beri hostname yang terlihat menarik: `db-backup-01` atau `admin-server`
- Fake credential contoh: username `admin`, password `Admin123!` — terlihat lemah tapi nyata
- Log Cowrie tersimpan di `/var/log/cowrie/cowrie.json`

---

### VM 03 — Windows Endpoint

| Atribut | Detail |
|---|---|
| Zona | LAN Produksi — VLAN 10 |
| OS | Windows 10 Pro / Windows Server 2019 |
| vCPU | 2 core |
| RAM | 4 GB |
| Disk | 40 GB |
| Network Adapter | 1 adapter (VLAN10) |
| IP | 192.168.10.20 |
| **PIC Setup VM** | **Yusmadani Firmansyah** |
| **PIC Install App** | **Rafli Sujatmiko** |

**Fungsi:**
Endpoint Windows yang merepresentasikan workstation karyawan Global-Tech Corp. VM ini adalah target utama untuk simulasi serangan berbasis Windows: brute force RDP, credential dumping via Mimikatz, Pass-the-Hash lateral movement, eksekusi PowerShell anomali, dan ransomware behavior (enkripsi massal file).

**Tanggung jawab Yusmadani:**
- Buat VM dan install Windows 10/Server 2019
- Aktifkan RDP (Remote Desktop Protocol) untuk simulasi brute force
- Buat user account: `Administrator` (dengan password lemah untuk simulasi) dan `standard_user`
- Tempatkan di VLAN 10
- Serahkan akses RDP ke Rafli setelah VM siap

**Tanggung jawab Rafli:**
- Install Wazuh agent dan enroll ke Wazuh Manager
- Aktifkan File Integrity Monitoring (FIM) di `C:\Windows\System32` dan `C:\Users`
- Aktifkan process monitoring untuk deteksi PowerShell encoded
- Verifikasi Windows Event Log (ID 4625, 4688, 4648) masuk ke Wazuh dashboard
- Install Canary Token di `C:\Users\Administrator\Documents\credentials.xlsx` (koordinasi dengan Romadhona)

**Notes:**
- Windows butuh lisensi — gunakan Windows evaluation (trial 180 hari) yang bisa diunduh gratis dari Microsoft
- Pastikan Windows Firewall tidak memblokir Wazuh agent (port 1514 outbound harus diizinkan)
- Snapshot VM sebelum simulasi serangan dimulai di Minggu 3 — untuk restore jika VM rusak

---

### VM 04 — Linux Endpoint + Production Server

| Atribut | Detail |
|---|---|
| Zona | LAN Produksi — VLAN 10 |
| OS | Ubuntu Server 22.04 LTS |
| vCPU | 2 core |
| RAM | 4 GB |
| Disk | 30 GB |
| Network Adapter | 1 adapter (VLAN10) |
| IP | 192.168.10.30 |
| **PIC Setup VM** | **Yusmadani Firmansyah** |
| **PIC Install App** | **Rafli Sujatmiko** |

**Fungsi:**
VM ini menjalankan dua peran sekaligus karena keterbatasan jumlah VM:

1. **Linux Endpoint** — target simulasi brute force SSH (Hydra) dan Log4Shell exploitation (CVE-2021-44228). Web server Apache dengan Log4j versi rentan di-deploy di sini.
2. **Production Server** — merepresentasikan database produksi Global-Tech Corp yang menjadi target enkripsi pada insiden awal. FIM dikonfigurasi dengan threshold ransomware.

**Tanggung jawab Yusmadani:**
- Buat VM dan install Ubuntu Server 22.04
- Aktifkan SSH (port 22) untuk simulasi brute force
- Deploy web server Apache + aplikasi Java dengan Log4j 2.14.1 (rentan) untuk skenario Log4Shell
- Buat file dummy database di `/var/db/production/` untuk simulasi ransomware FIM
- Tempatkan di VLAN 10
- Serahkan akses SSH ke Rafli setelah VM siap

**Tanggung jawab Rafli:**
- Install Wazuh agent dan enroll ke Wazuh Manager
- Aktifkan auditd dan konfigurasi audit rules
- Aktifkan FIM di `/etc`, `/bin`, `/var/db/production/`
- Konfigurasi FIM threshold ransomware: alert CRITICAL jika > 50 file berubah dalam 1 menit
- Konfigurasi monitoring Apache access log untuk deteksi payload `${jndi:}`
- Install Canary Token di `/etc/db_passwords.conf` (koordinasi dengan Romadhona)
- Verifikasi auth.log, syslog, auditd masuk ke Wazuh dashboard

**Notes:**
- Karena VM ini menjalankan dua peran, pastikan disk 30 GB cukup untuk kedua workload
- Log4Shell PoC: gunakan Docker image `ghcr.io/christophetd/log4shell-vulnerable-app` agar tidak perlu setup Java manual
- Snapshot VM sebelum simulasi serangan Minggu 3

---

### VM 05 — Wazuh SIEM (Manager + Indexer + Dashboard)

| Atribut | Detail |
|---|---|
| Zona | Management Network — VLAN 20 |
| OS | Ubuntu Server 22.04 LTS |
| vCPU | 4 core |
| RAM | 8 GB |
| Disk | 50 GB |
| Network Adapter | 1 adapter (VLAN20) |
| IP | 192.168.20.10 |
| **PIC Setup VM** | **Triyas Niko Saputra** |
| **PIC Install App** | **Rafli Sujatmiko** |

**Fungsi:**
VM terbesar dan terpenting di lab — menjalankan tiga komponen Wazuh sekaligus (all-in-one deployment): Wazuh Manager (memproses log dan menjalankan rules), Wazuh Indexer (menyimpan data berbasis OpenSearch), dan Wazuh Dashboard (UI monitoring berbasis Kibana). Semua log dari 5 VM lainnya mengalir ke sini.

**Tanggung jawab Triyas:**
- Buat VM dengan spesifikasi penuh (4 vCPU, 8 GB RAM) — jangan dikurangi karena Wazuh Indexer sangat memory-intensive
- Tempatkan di VLAN 20
- Pastikan VLAN 20 hanya menerima koneksi dari VLAN lain via port 1514 (agent) dan 514 (syslog)
- Serahkan akses SSH ke Rafli setelah VM siap

**Tanggung jawab Rafli:**
- Install Wazuh all-in-one menggunakan script resmi Wazuh 4.x
- Ganti default credentials admin
- Buat custom detection rules MITRE ATT&CK (T1110, T1059, T1003, T1550, T1078, T1021, T1190, T1486)
- Konfigurasi syslog receiver untuk menerima log pfSense (port 514)
- Konfigurasi Filebeat receiver untuk log honeypot (port 5044)
- Setup Active Response script (Python) untuk auto-block IP via pfSense API
- Setup Telegram bot integration
- Buat dan finalisasi Kibana/Grafana dashboard

**Notes:**
- **VM ini adalah VM paling kritis** — jika VM ini down, seluruh sistem monitoring buta
- Gunakan Wazuh OVA (pre-built image) untuk mempercepat setup: https://documentation.wazuh.com/current/deployment-options/virtual-machine/virtual-machine.html
- RAM 8 GB adalah minimum — jika host hanya punya 16 GB total, Wazuh harus dapat jatah 8 GB ini
- Snapshot setelah konfigurasi dasar selesai (sebelum rules ditambahkan) sebagai restore point

---

### VM 06 — Kali Linux (Attacker Machine)

| Atribut | Detail |
|---|---|
| Zona | Attacker Zone (terisolasi) |
| OS | Kali Linux 2024.x |
| vCPU | 2 core |
| RAM | 2 GB |
| Disk | 20 GB |
| Network Adapter | 1 adapter (VLAN Attacker / NAT terisolasi) |
| IP | 192.168.99.10 |
| **PIC Setup VM** | **Yusmadani Firmansyah** |
| **PIC Install App** | **Yusmadani Firmansyah** |

**Fungsi:**
Mesin penyerang yang digunakan Yusmadani (dan Romadhona saat live demo) untuk menjalankan semua simulasi serangan di Minggu 3. VM ini ditempatkan di VLAN terpisah yang terisolasi — hanya bisa menjangkau target tertentu sesuai skenario yang sedang diuji.

**Tanggung jawab Yusmadani:**
- Install Kali Linux dan verifikasi semua tools tersedia
- Tools yang wajib terinstall dan terverifikasi:
  - `nmap` — port scanning dan reconnaissance
  - `hydra` — brute force SSH dan RDP
  - `metasploit` — exploitation framework
  - `netcat` — reverse shell dan port testing
  - `mimikatz` (via Wine) — credential dumping di Windows
  - `curl` — kirim payload Log4Shell
- Buat bash script automasi untuk setiap skenario serangan
- Koordinasi dengan Triyas untuk VLAN placement dan akses ke target
- Pastikan Kali **tidak bisa** menjangkau VLAN 20 (Management) — verifikasi dengan ping test

**Notes:**
- Kali Linux tersedia gratis di https://www.kali.org/get-kali/
- Untuk simulasi Mimikatz di Windows target, jalankan dari dalam Windows VM langsung (bukan dari Kali) karena Mimikatz adalah Windows binary
- Semua simulasi serangan harus direkam dengan OBS Studio sebelum dijalankan
- Snapshot sebelum setiap sesi simulasi — restore jika ada yang error

---

### Rekap Spesifikasi Total

| VM | OS | vCPU | RAM | Disk | PIC Setup |
|---|---|---|---|---|---|
| 01 pfSense | pfSense CE | 1 | 1 GB | 8 GB | Triyas |
| 02 Honeypot | Ubuntu 22.04 | 1 | 1 GB | 10 GB | Triyas |
| 03 Windows Endpoint | Windows 10 | 2 | 4 GB | 40 GB | Yusmadani |
| 04 Linux + Prod Server | Ubuntu 22.04 | 2 | 4 GB | 30 GB | Yusmadani |
| 05 Wazuh SIEM | Ubuntu 22.04 | 4 | 8 GB | 50 GB | Triyas |
| 06 Kali Linux | Kali 2024.x | 2 | 2 GB | 20 GB | Yusmadani |
| **Total** | | **12 vCPU** | **20 GB** | **158 GB** | |

> **Host yang dibutuhkan:** minimal RAM 24 GB (20 GB untuk VM + 4 GB untuk OS host), disk 200 GB, CPU 8+ core.

---

## 3. Permasalahan: Tim Berjauhan & Jadwal Tidak Sinkron

Ini adalah tantangan terbesar dalam pengerjaan Project Sentinel. Ada tiga masalah yang saling berkaitan:

### Masalah 1 — VM hanya bisa diakses dari satu lokasi

Jika semua VM dijalankan di laptop/PC pribadi satu anggota (misalnya Triyas), anggota lain hanya bisa bekerja kalau:
- Mereka berada di lokasi yang sama dengan Triyas, **atau**
- Komputer Triyas sedang menyala dan terhubung internet

Ini menciptakan ketergantungan yang sangat besar pada satu orang dan satu perangkat.

### Masalah 2 — Jadwal yang tidak bisa disinkronkan

Tim yang berjauhan sulit menemukan waktu yang sama untuk bekerja bersama. Kalau Rafli ingin mengerjakan konfigurasi Wazuh tengah malam sementara komputer host sedang mati, seluruh progres tertahan.

### Masalah 3 — Risiko kehilangan progress

Jika laptop host rusak, mati listrik, atau terhapus tidak sengaja — semua VM dan semua konfigurasi yang sudah dikerjakan ikut hilang. Tanpa backup, ini bisa menghapus progres berminggu-minggu.

---

## 4. Opsi Solusi Lab Environment

### Opsi A — Satu PC/Laptop Pribadi yang Selalu Menyala

Salah satu anggota (paling logis Triyas sebagai PIC setup) mengorbankan satu perangkat untuk dijadikan host permanen selama periode proyek (11 Mei – 3 Juni).

**Cara kerja:**
- Semua 6 VM berjalan di perangkat tersebut 24 jam
- Tailscale diinstall di perangkat host dan di laptop semua anggota
- Anggota lain akses VM via SSH (Linux) atau RDP (Windows) dari laptopnya masing-masing kapan saja

**Kelebihan:**
- Gratis — tidak ada biaya tambahan
- Setup relatif cepat (Tailscale bisa jalan dalam 15 menit)
- Semua anggota bisa kerja mandiri tanpa koordinasi waktu

**Kekurangan:**
- Bergantung pada satu perangkat fisik — kalau rusak atau mati listrik, semua terhenti
- Perangkat host harus punya RAM minimal 24 GB dan tidak bisa dipakai untuk keperluan lain secara bersamaan
- Koneksi internet host harus stabil

**Cocok untuk:** Tim yang salah satu anggotanya punya PC desktop atau laptop lama yang bisa "dikorbankan" selama 3 minggu.

---

### Opsi B — PC Lab Sekolah/Kampus

Jika ada akses ke lab komputer di sekolah atau kampus yang PCnya menyala sepanjang waktu, ini bisa menjadi host VM tanpa mengorbankan perangkat pribadi.

**Cara kerja:**
- Install VMware/VirtualBox + Tailscale di satu PC lab
- Koordinasi dengan pengelola lab untuk memastikan PC tidak dimatikan atau di-reset selama periode proyek
- Semua anggota akses via Tailscale dari mana saja

**Kelebihan:**
- Tidak perlu perangkat pribadi yang dikorbankan
- PC lab biasanya punya spesifikasi yang lebih baik
- Listrik ditanggung lab

**Kekurangan:**
- Perlu izin dari pengelola lab
- Risiko PC di-reset atau dimatikan oleh orang lain
- Tidak semua tim punya akses ke lab yang sesuai

**Cocok untuk:** Tim yang salah satu anggotanya punya akses ke lab komputer dengan PC berperforma tinggi.

---

### Opsi C — VPS Lokal Indonesia (Disarankan jika budget ada)

Sewa VPS dengan RAM besar di provider Indonesia, install Proxmox sebagai hypervisor, lalu jalankan semua 6 VM di sana. Semua anggota akses langsung via browser (Proxmox web UI) atau SSH tanpa perlu Tailscale.

**Provider yang direkomendasikan:**

| Provider | Spesifikasi | Estimasi biaya/bulan | Keunggulan |
|---|---|---|---|
| IDCloudHost | 8 vCPU, 16 GB RAM, 200 GB SSD | ~Rp 350.000 | Server lokal, latency rendah |
| Biznet Gio | 8 vCPU, 16 GB RAM, 200 GB SSD | ~Rp 500.000 | Koneksi stabil, support lokal |
| Hetzner (Jerman) | 8 vCPU, 16 GB RAM, 160 GB SSD | ~€15 (~Rp 250.000) | Termurah, performa tinggi |

> Durasi sewa yang dibutuhkan hanya **3 minggu** (18 Mei – 3 Juni 2026), sehingga biaya aktual bisa lebih rendah jika provider menyediakan billing per jam atau per minggu.

**Kelebihan:**
- Tidak bergantung pada perangkat atau koneksi internet siapapun
- Bisa diakses 24 jam dari mana saja
- Jika ada masalah, tinggal restart VPS dari panel kontrol

**Kekurangan:**
- Ada biaya — perlu kesepakatan tim untuk patungan
- Perlu seseorang (Triyas) yang setup Proxmox di awal (~2-3 jam)
- Nested virtualization harus didukung oleh provider

**Cocok untuk:** Tim yang tidak keberatan patungan Rp 50.000–100.000 per orang untuk kenyamanan kerja selama 3 minggu.

---

### Opsi D — Tailscale + Laptop Pribadi Triyas (Minimum Viable)

Jika tidak ada budget dan tidak ada PC lab, gunakan laptop Triyas sebagai host dengan Tailscale untuk akses remote.

**Cara kerja:**
- Triyas install VMware/VirtualBox + semua 6 VM di laptopnya
- Install Tailscale di laptop Triyas dan di semua laptop anggota
- Anggota lain SSH/RDP ke VM via Tailscale dari mana saja
- Laptop Triyas **harus selalu menyala dan terhubung internet** saat anggota lain sedang bekerja

**Kelebihan:**
- Gratis sepenuhnya
- Setup Tailscale sangat mudah

**Kekurangan:**
- Triyas harus rela laptopnya dipakai sebagai server selama 3 minggu
- Baterai laptop tidak ideal untuk server — sebaiknya selalu terhubung ke charger
- Jika laptop Triyas hang atau perlu dipakai untuk hal lain, semua anggota tidak bisa bekerja

**Cocok untuk:** Opsi darurat jika semua opsi lain tidak memungkinkan.

---

## 5. Rekomendasi untuk Tim Sentinel

Berdasarkan kondisi tim yang berjauhan dan jadwal tidak sinkron, berikut rekomendasi berdasarkan prioritas:

### Rekomendasi Utama — Opsi A atau B (PC yang selalu menyala)

Sebelum memutuskan sewa VPS berbayar, cek dulu apakah ada **satu PC atau laptop lama** di antara anggota yang bisa dijadikan host permanen. PC desktop jauh lebih ideal daripada laptop karena:

- Tidak ada risiko baterai habis
- Bisa menyala terus tanpa overheating
- Biasanya punya RAM lebih besar

Langkah yang disarankan:
1. Tanyakan ke seluruh anggota: siapa yang punya PC desktop atau laptop lama yang tidak aktif dipakai?
2. Jika ada, jadikan itu host VM dengan VMware Workstation / VirtualBox + Tailscale
3. Jika tidak ada, langsung lompat ke Opsi C (VPS)

### Jika tidak ada PC yang bisa dikorbankan — Opsi C (VPS IDCloudHost)

Patungan Rp 70.000 per orang (5 anggota × Rp 70.000 = Rp 350.000) sudah cukup untuk sewa VPS IDCloudHost selama satu bulan dengan spesifikasi yang memadai. Ini jauh lebih murah daripada risiko proyek terhambat karena ketergantungan perangkat.

### Yang tidak disarankan

Jangan menjalankan VM di laptop masing-masing secara terpisah tanpa sinkronisasi — ini akan membuat environment setiap anggota berbeda dan menyulitkan integrasi saat Minggu 3 (simulasi serangan harus dilakukan di environment yang sama).

---

## 6. Panduan Akses Antar Anggota

Setelah host VM ditetapkan (PC pribadi atau VPS), berikut cara masing-masing anggota mengakses VM yang menjadi tanggung jawabnya:

### Rafli — Akses ke Wazuh SIEM (VM 05)

```bash
# SSH ke Wazuh VM dari laptop Rafli
ssh rafli@192.168.20.10

# Akses Wazuh Dashboard via browser
https://192.168.20.10:443
```

### Yusmadani — Akses ke Honeypot (VM 02) dan Kali Linux (VM 06)

```bash
# SSH ke Honeypot VM
ssh yusmadani@192.168.30.10

# Akses Kali Linux via SSH atau langsung di console
ssh yusmadani@192.168.99.10
```

### Rafli — Akses ke Windows Endpoint (VM 03) untuk install Wazuh agent

```
Remote Desktop Connection → 192.168.10.20
Username: Administrator
```

### Rafli — Akses ke Linux Endpoint (VM 04) untuk install Wazuh agent

```bash
ssh rafli@192.168.10.30
```

### Semua anggota — Akses Wazuh Dashboard untuk monitoring

```
Browser → https://192.168.20.10
Username: admin
Password: [ditetapkan Rafli saat setup]
```

> **Catatan:** Jika menggunakan Tailscale, ganti IP di atas dengan Tailscale IP yang diberikan ke masing-masing VM (format: `100.x.x.x`).

---

## 7. Catatan Versi

| Versi | Tanggal | Author | Perubahan |
|---|---|---|---|
| v1.0 | 15 Mei 2026 | Dea Kristin Ginting | Dokumen awal VM infrastructure |

### Keputusan yang masih perlu disepakati tim

- [ ] Siapa yang punya PC/laptop lama yang bisa dijadikan host VM?
- [ ] Apakah tim setuju patungan untuk VPS jika tidak ada perangkat yang tersedia?
- [ ] Provider VPS mana yang dipilih jika jalan VPS?
- [ ] Siapa yang pegang akun VPS/host dan bertanggung jawab jika ada masalah?

> Keputusan ini sebaiknya disepakati sebelum **11 Mei 2026** agar Triyas bisa langsung memulai setup VM di hari pertama tanpa hambatan.

---

*Dokumen ini adalah bagian dari dokumentasi teknis Project Sentinel.*
*Repository: `Capstone FYEP-15 / 15-fyep2026` · Folder: `/docs/infrastructure/`*

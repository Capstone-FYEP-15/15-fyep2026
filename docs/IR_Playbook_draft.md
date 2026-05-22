# Project Sentinel — Incident Response Playbook

**Draft v1.0 — Minggu 2**
Arsitektur Pertahanan Siber Berlapis dengan Deteksi Ancaman Proaktif berbasis Wazuh

---

| Atribut | Detail |
|---|---|
| Dibuat oleh | Dea Kristin Ginting (Project Manager) |
| Direview oleh | Romadhona Fitri Lestari (QA Analyst) — *Pending* |
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

> ⏳ **STATUS: OUTLINE — Akan dilengkapi di Minggu 3 setelah simulasi Mimikatz + Pass-the-Hash selesai. Romadhona akan mereview dan memvalidasi prosedur teknis berdasarkan hasil simulasi aktual.**

| Atribut | Detail |
|---|---|
| Tipe Insiden | Lateral movement menggunakan kredensial curian (Pass-the-Hash, Pass-the-Ticket) |
| Severity Default | CRITICAL (level 12+) |
| MITRE ATT&CK | T1003 — Credential Dumping, T1550.002 — Pass-the-Hash, T1021 — Remote Services |
| Referensi Kasus | MGM/Caesars 2023 — admin credential dicuri via Mimikatz, digunakan untuk enkripsi database |
| PIC Utama | Rafli (SIEM), Triyas (Network isolation), Yusmadani (forensik) |

### Pemetaan MITRE ATT&CK

| Technique ID | Nama Teknik | Taktik | Relevansi |
|---|---|---|---|
| T1003 | OS Credential Dumping | Credential Access | Mimikatz mengakses lsass.exe untuk dump hash |
| T1550.002 | Pass-the-Hash | Defense Evasion | Menggunakan hash NTLM untuk autentikasi tanpa password |
| T1021 | Remote Services | Lateral Movement | Akses ke host lain menggunakan hash curian via SMB/WMI |
| T1078 | Valid Accounts | Defense Evasion | Menggunakan akun admin yang sah dengan hash yang dicuri |

### Deteksi *(outline)*

> Wazuh alert T1003 (akses lsass.exe) + T1550.002 (hash-based auth) + notifikasi Telegram CRITICAL.

### Containment *(outline)*

> Isolasi host sumber secara manual + mikrosegmentasi VLAN oleh Triyas + disable akun admin yang dikompromikan.

### Eradication *(outline)*

> Forensik endpoint: cek memory dump, process list, network connections + identifikasi semua host yang diakses.

### Recovery *(outline)*

> Reimaging host yang dikompromikan + reset semua kredensial admin + verifikasi tidak ada persistence.

### Lessons Learned *(outline)*

> Update IAM policy + perkuat monitoring T1003 + dokumentasi TTP penyerang.

---

## 9. Skenario 4 — Ransomware / Enkripsi Massal

> ⏳ **STATUS: OUTLINE — Akan dilengkapi di Minggu 3 setelah simulasi ransomware behavior (FIM threshold 50 file/menit) selesai. Romadhona akan mereview prosedur recovery berdasarkan hasil simulasi aktual.**

| Atribut | Detail |
|---|---|
| Tipe Insiden | Enkripsi massal file oleh ransomware di endpoint atau production server |
| Severity Default | CRITICAL (level 15) — dampak langsung ke operasional |
| MITRE ATT&CK | T1486 — Data Encrypted for Impact, T1490 — Inhibit System Recovery |
| Referensi Kasus | MGM/Caesars 2023 — database produksi dienkripsi penyerang via credential lateral movement |
| Target Recovery | Maksimal 4 jam downtime (BR-01) — backup restore harus siap |
| PIC Utama | Dea (eskalasi), Triyas (isolasi jaringan), Rafli (forensik SIEM) |

### Pemetaan MITRE ATT&CK

| Technique ID | Nama Teknik | Taktik | Relevansi |
|---|---|---|---|
| T1486 | Data Encrypted for Impact | Impact | Ransomware mengenkripsi file produksi secara massal |
| T1490 | Inhibit System Recovery | Impact | Menghapus shadow copy/backup untuk cegah recovery |
| T1083 | File and Directory Discovery | Discovery | Ransomware mencari file target sebelum enkripsi |
| T1036 | Masquerading | Defense Evasion | Ransomware menyamar sebagai proses sistem yang sah |

### Deteksi *(outline)*

> Wazuh FIM alert CRITICAL: >50 file berubah dalam 1 menit di `/var/db/production` atau `C:\Users\`. Notifikasi Telegram segera.

### Containment *(outline)*

> Triyas ISOLASI TOTAL host yang terinfeksi dari semua VLAN dalam <5 menit. Hentikan semua koneksi SMB/RDP.

### Eradication *(outline)*

> Identifikasi ransomware binary + vector masuk + semua host yang terinfeksi. Jangan restart sebelum forensik selesai.

### Recovery *(outline)*

> Restore dari snapshot VMware terakhir yang bersih. Target: layanan kembali normal dalam 4 jam (BR-01).

### Lessons Learned *(outline)*

> Evaluasi kecepatan deteksi FIM, update backup policy, evaluasi air-gap backup untuk production server.

---

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
| v1.1 | TBD (Minggu 3) | Romadhona Fitri Lestari | Review teknis + finalisasi Skenario 3 (Lateral Movement) + Skenario 4 (Ransomware) berdasarkan simulasi |
| v2.0 | TBD (Minggu 4) | Dea Kristin Ginting | Finalisasi penuh — semua skenario lengkap, lessons learned dari simulasi terintegrasi, siap presentasi |

---

*Project Sentinel · FYEP Cybersecurity 2026 · InfraDigital Foundation*
*Repository: `Capstone FYEP-15 / 15-fyep2026` · `/docs/INCIDENT_RESPONSE_PLAYBOOK.md`*
*CONFIDENTIAL — Hanya untuk penggunaan internal tim Project Sentinel*

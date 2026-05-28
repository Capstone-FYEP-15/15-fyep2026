# Access Control Policy — Project Sentinel
**Global-Tech Corp**

> **Kelompok:** SIEMsalabim Capstone Kelar
> **Topik:** Project Sentinel: Arsitektur Deteksi dan Identifikasi Ancaman On-Premise Terintegrasi
> **Judul:** Arsitektur Pertahanan Siber Berlapis dengan Deteksi Ancaman Proaktif berbasis Wazuh

## Daftar Isi

1. [Pendahuluan](#a-pendahuluan)
2. [Prinsip Dasar](#b-prinsip-dasar)
3. [Daftar Role dan Hak Akses](#c-daftar-role-dan-hak-akses)
4. [Aturan Umum](#d-aturan-umum)
5. [Hasil Implementasi](#e-hasil-implementasi)

---

## A. Pendahuluan

### 1. Latar Belakang

Global-Tech Corp mengalami insiden keamanan siber serius yang mengakibatkan kerugian besar pada operasional perusahaan. Investigasi pasca insiden menemukan bahwa penyebab utama adalah **tidak adanya kontrol akses yang terstruktur dan ketat** antar sistem.

Penyerang yang berhasil masuk ke salah satu titik jaringan dapat bergerak bebas ke seluruh infrastruktur tanpa hambatan, karena hampir semua pengguna memiliki hak akses yang terlalu luas dan tidak terbatas. Kondisi ini diperparah dengan tidak adanya pemisahan yang jelas antara akun administrator, pengguna biasa, dan akun layanan (*service account*).

Dokumen **Access Control Policy** ini disusun sebagai respons langsung atas celah tersebut. Kebijakan ini mendefinisikan secara jelas siapa saja pengguna sistem, apa saja yang boleh mereka akses, dan batasan apa yang harus diterapkan pada setiap akun.

### 2. Tujuan

Dokumen ini disusun dengan tujuan sebagai berikut:

- Mendefinisikan role dan hak akses setiap pengguna di seluruh infrastruktur Global-Tech Corp secara jelas dan terstruktur
- Menerapkan prinsip **Least Privilege** pada seluruh sistem sehingga setiap akun hanya memiliki akses minimum yang dibutuhkan
- Mencegah pergerakan lateral penyerang di dalam jaringan apabila salah satu akun berhasil dikompromikan
- Memastikan setiap aktivitas akses dapat dilacak dan diaudit melalui sistem SIEM (Wazuh)
- Menjadi acuan bagi seluruh anggota tim dalam mengkonfigurasi user dan hak akses di setiap komponen infrastruktur

### 3. Ruang Lingkup

Kebijakan ini berlaku untuk seluruh sistem dan komponen dalam infrastruktur lab Project Sentinel Global-Tech Corp, meliputi:

- **Windows Endpoint** (minimal 1 Windows Server/10)
- **Linux Endpoint** (minimal 1 Ubuntu Server)
- **Jaringan VLAN** yang dikelola pfSense *(koordinasi dengan Network Engineer - Triyas)*
- **Wazuh SIEM Server** sebagai pusat monitoring
- **Honeypot** (Cowrie/OpenCanary) di zona DMZ

---

## B. Prinsip Dasar

Kebijakan akses di Global-Tech Corp dibangun di atas tiga prinsip utama keamanan informasi yang diakui secara internasional:

### 1. Least Privilege (Hak Akses Minimum)

Setiap akun pengguna, aplikasi, atau sistem hanya boleh diberikan **hak akses minimum** yang benar-benar dibutuhkan untuk menjalankan tugasnya — tidak lebih dari itu.

> **Contoh penerapan:** Seorang pegawai di divisi keuangan hanya boleh mengakses aplikasi keuangan dan folder kerjanya sendiri. Ia tidak boleh menginstall software baru, mengubah konfigurasi sistem, atau mengakses data divisi lain.

### 2. Need-to-Know (Akses Berdasarkan Kebutuhan)

Setiap pengguna hanya boleh mengakses informasi dan sumber daya yang **benar-benar relevan** dan dibutuhkan untuk menjalankan tugasnya sehari-hari.

> **Contoh penerapan:** Administrator jaringan boleh mengakses konfigurasi firewall dan VLAN, namun tidak perlu dan tidak boleh mengakses database keuangan perusahaan.

### 3. Separation of Duties (Pemisahan Tanggung Jawab)

Tidak ada satu akun atau satu orang pun yang boleh memiliki **kendali penuh** atas seluruh sistem tanpa pengawasan dari pihak lain.

> **Contoh penerapan:** Akun yang bisa membuat user baru tidak boleh sekaligus bisa menghapus log aktivitas. Dengan demikian, setiap perubahan pada sistem tetap dapat diaudit dan dipertanggungjawabkan.

---

## C. Daftar Role dan Hak Akses

### 1. Windows Endpoint

| Role | Username | Yang Bisa Diakses | Level Akses | Alasan |
|------|----------|-------------------|-------------|--------|
| Administrator | `admin` | Semua sistem, file, konfigurasi, boleh install software | Full access tanpa batasan | Dibutuhkan untuk mengelola dan memelihara seluruh infrastruktur |
| Standard User | `user01` | File kerja pribadi, aplikasi kantor yang sudah terinstall | Terbatas, tidak boleh install software/ubah setting sistem | Pegawai biasa tidak memerlukan akses lebih dari kebutuhan kerja hariannya |
| Service Account | `svc_wazuh` | Hanya service Wazuh agent, tidak bisa akses file lain | Sangat terbatas, tidak bisa digunakan untuk login manual | Akun khusus yang hanya berjalan di background untuk menjalankan Wazuh agent |

### 2. Linux Endpoint

| Role | Username | Yang Boleh Diakses | Level Akses | Alasan |
|------|----------|--------------------|-------------|--------|
| Admin/root | `root` | Semua sistem dan file di Linux | Terbatas sudo, setiap perintah berbahaya harus dikonfirmasi dulu | Dibutuhkan untuk mengelola server Linux, namun tetap dibatasi agar tidak bisa disalahgunakan |
| User biasa | `user01` | Hanya folder home miliknya sendiri (`/home/user01`) | Tidak bisa menggunakan sudo sama sekali | Pengguna biasa tidak memerlukan akses ke konfigurasi sistem |

### 3. Akses per Jaringan VLAN

| Role | VLAN Production (VLAN-10) | VLAN Management (VLAN-20) | VLAN DMZ/Honeypot (VLAN-30) |
|------|---------------------------|---------------------------|------------------------------|
| Administrator | Boleh akses penuh | Boleh akses penuh | Boleh akses penuh |
| Standard User | Boleh akses terbatas | Tidak boleh | Tidak boleh |
| Service Account | Boleh terbatas sesuai service | Tidak boleh | Tidak boleh |

---

## D. Aturan Umum

1. Password minimal **8 karakter**, harus ada angka dan simbol
2. Setiap orang **wajib punya akun sendiri**, dilarang sharing password
3. **Service account** tidak boleh digunakan untuk login manual
4. Akun yang sudah tidak digunakan harus **segera dinonaktifkan**
5. Hak akses **dievaluasi ulang setiap bulan**


## E. Hasil Implementasi

### 1. Konfigurasi User Windows

### 2. Konfigurasi User Linux
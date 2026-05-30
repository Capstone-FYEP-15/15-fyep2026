# SIEM Tuning Log - Project Sentinel
**Analisis Eliminasi False Positive Pasca Simulasi Serangan**

## 1. Analisis dan Klasifikasi Alert Pasca Simulasi
Berdasarkan evaluasi terhadap log keamanan yang dihasilkan selama simulasi taktik serangan (Kasus Colonial Pipeline + MGM), ditemukan beberapa aturan kustom menghasilkan tingkat gangguan (*noise*) yang tinggi:
* **PowerShell Encoded Command (T1059.001):** *True Positive (TP)*. Aturan akurat mendeteksi eksekusi payload obfuscation penyerang.
* **Multiple Failed Logins (T1021):** *High Noise / False Positive (FP)*. Terpicu masif akibat kegagalan login singkat dari aktivitas user biasa dan sinkronisasi berkala komputer lab.
* **Admin Login Outside Working Hours (T1078):** *False Positive (FP)*. Terpicu setiap pukul 23:00 WIB akibat aktivitas skrip *backup* otomatis resmi yang menggunakan akun hak istimewa.

## 2. Matriks Perubahan Tuning Aturan
Untuk meningkatkan kualitas alert, dilakukan optimasi pada 2 aturan kustom:

| Rule ID | MITRE ID | Kondisi Awal (Sebelum) | Kondisi Baru (Sesudah Tuning) | Alasan Teknis Optimasi |
| :--- | :--- | :--- | :--- | :--- |
| **100004** | T1021 | frequency="5"<br>timeframe="60" | frequency="10"<br>timeframe="120" | Memperlebar threshold deteksi untuk mengeliminasi alarm palsu akibat kelalaian manusia (typo password) tanpa kehilangan kemampuan mendeteksi serangan *brute force* yang agresif. |
| **100005 & 100006** | T1078 | Mengawasi seluruh akun admin (`Administrator`, `admin`, `fyep-2`) | Mengecualikan akun layanan tertentu (`!fyep-2`) | Meloloskan (*whitelist*) akun pemeliharaan sistem dari deteksi jam malam guna menghentikan alarm palsu dari aktivitas *automated backup* terjadwal. |

## 3. Hasil Kuantitatif (Signal-to-Noise Ratio)
Evaluasi volume alert dalam jendela observasi 60 menit menunjukkan peningkatan performa deteksi yang signifikan:

* **Jumlah Alert Total Sebelum Tuning:** 142 Alert
* **Jumlah Alert Total Sesudah Tuning:** 18 Alert
* **True Positive (TP) Keamanan:** 15 Alert (Akurasi serangan asli tetap terjaga 100%)
* **False Positive (FP) Tereduksi:** Dari 127 Alert menjadi 3 Alert
* **Efisiensi Reduksi Noise:** **97.6% False Positive Berhasil Dieliminasi**

---
*Catatan: Dokumen visual perbandingan visual dashboard sebelum dan sesudah tuning dilampirkan pada berkas `dashboard_sebelum_tuning.png` dan `dashboard_sesudah_tuning.png` di folder dokumen.*

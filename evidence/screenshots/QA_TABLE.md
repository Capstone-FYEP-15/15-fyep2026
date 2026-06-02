# TABEL QA — VALIDASI SIMULASI SERANGAN
## Project Sentinel — Minggu 3

| Skenario | Serangan Dijalankan | Alert Muncul? | Waktu Deteksi | Level Severity | Status | Catatan |
|----------|--------------------|--------------:|---------------|----------------|--------|---------|
| Network Recon | Nmap scan | Ya | - | 8-12 | True Positive | Rule 100600-604 |
| Brute Force SSH | Hydra rockyou.txt | Ya | - | 5-11 | True Positive | Rule 5763, 100004 |
| Brute Force RDP | Crowbar/Hydra | Ya | - | 5-11 | True Positive | Rule 18134, 100004 |
| Honeypot SSH | SSH ke Cowrie | Ya | - | 12-15 | True Positive | Rule 100100-104 |
| Canary Token Linux | cat /etc/db_passwords.conf | Ya | - | 12 | True Positive | Rule 100200 |
| Canary Token Windows | Akses credentials.xlsx | Ya (workaround) | - | 12-15 | Partial | Rule 100301, via canary-monitor.py bukan native |
| Mimikatz | privilege::debug + sekurlsa | Ya | - | 13 | True Positive | Rule 92900 |
| Lateral Movement SMB | SMB/WMI dari Kali | Ya + Diblokir | - | - | True Positive | Rule 100004 |
| Ransomware FIM | Enkripsi massal 60 file | Ya | - | 12-15 | True Positive | Rule 100700-702 |
| Log4Shell | JNDI payload ke Nginx | Ya | - | 13-15 | True Positive | Rule 100800-803 |
| Admin Login Luar Jam | Login di luar 09:00-17:00 | Ya | - | 10 |True Positive | Rule 100009, 100011 |

---

## Temuan Gap / Kegagalan Deteksi

| Celah | Dampak | Dilaporkan Ke |
|-------|--------|---------------|
| Windows Event ID 4663 tidak diproses native Wazuh | Canary token Windows hanya via workaround canary-monitor.py | Rafli |
| Dua blok syscheck di ossec.conf Windows | FIM tidak berjalan di direktori target awal | Rafli |
| Route ke VLAN20 hilang setelah reboot Windows | Agent Windows disconnect dari Wazuh | Triyas |

---

## Kesimpulan QA

- Total skenario diuji: 11
- Terdeteksi penuh: 10
- Terdeteksi sebagian (workaround): 1
- Tidak terdeteksi: 0
- **Detection Rate: 100% (10 full + 1 partial)**

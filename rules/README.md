# Wazuh Custom Rules — Project Sentinel
**FYEP Cybersecurity 2026 · InfraDigital Foundation**

## Daftar Rule Files

| File | Rule IDs | Fungsi | MITRE |
|---|---|---|---|
| honeypot_rules.xml | 100100-100104 | Deteksi aktivitas honeypot Cowrie | T1059, T1078 |
| canary_token_rules.xml | 100200, 100300-100302 | Deteksi akses canary token | T1083, T1005 |
| custom_mitre_rules.xml | 100001-100011 | Custom MITRE ATT&CK rules | T1059, T1003, T1021, T1078 |
| asset_discovery_rules.xml | 100600-100604 | Asset discovery & rogue device | T1200, T1046 |
| ransomware_rules.xml | 100700-100702 | Ransomware behavior FIM | T1486, T1490 |
| log4shell_rules.xml | 100800-100803 | Log4Shell CVE-2021-44228 | T1190, T1027 |
| local_rules.xml | 100400, 100500 | Local custom rules | - |

## Rule ID Mapping

| Rule ID | Deskripsi | Severity | Status |
|---|---|---|---|
| 100100 | Honeypot SSH connection | HIGH (12) | ✅ Active |
| 100101 | Honeypot login success | CRITICAL (14) | ✅ Active |
| 100102 | Honeypot login failed | MEDIUM (10) | ✅ Active |
| 100103 | Honeypot command executed | HIGH (12) | ✅ Active |
| 100104 | Honeypot file download | CRITICAL (15) | ✅ Active |
| 100200 | Linux canary token accessed | HIGH (12) | ✅ Active |
| 100300 | Windows canary token accessed | HIGH (12) | ✅ Active |
| 100301 | Canary token exfiltration | CRITICAL (15) | ✅ Active |
| 100302 | Canary monitor alert | HIGH (12) | ✅ Active |
| 100001 | PowerShell obfuscation T1059 | HIGH (10) | ✅ Active |
| 100002 | LSASS access Mimikatz T1003 | CRITICAL (13) | ✅ Active |
| 100003 | Windows failed login | LOW (5) | ✅ Active |
| 100004 | Brute force detection T1021 | HIGH (11) | ✅ Active |
| 100005 | Admin login after hours | HIGH (10) | ✅ Active |
| 100006 | Admin login early morning | HIGH (10) | ✅ Active |
| 100009 | SSH login after hours | HIGH (10) | ✅ Active |
| 100010 | Multiple suspicious logins | CRITICAL (12) | ✅ Active |
| 100011 | SSH login late night | HIGH (10) | ✅ Active |
| 100600 | New host detected | MEDIUM (8) | ✅ Active |
| 100601 | Known host offline | MEDIUM (5) | ✅ Active |
| 100602 | Host returned online | MEDIUM (5) | ✅ Active |
| 100603 | Asset scan summary | LOW (5) | ✅ Active |
| 100604 | Rogue device VLAN10 | CRITICAL (12) | ✅ Active |
| 100700 | Ransomware file extension | HIGH (12) | ✅ Active |
| 100701 | Mass file encryption | CRITICAL (15) | ✅ Active |
| 100702 | Ransom note detected | HIGH (14) | ✅ Active |
| 100800 | Log4Shell JNDI payload | CRITICAL (13) | ✅ Active |
| 100801 | Log4Shell protocol variant | CRITICAL (13) | ✅ Active |
| 100802 | Log4Shell multiple attempts | CRITICAL (15) | ✅ Active |
| 100803 | Log4Shell fallback match | CRITICAL (13) | ✅ Active |

## Referensi

- CVE-2021-44228 (Log4Shell): https://github.com/advisories/GHSA-jfh8-c2jp-5v3q
- MGM Resorts 2023 breach: MITRE T1078 (Valid Accounts)
- Colonial Pipeline 2021: MITRE T1021 (Remote Services)
- MITRE ATT&CK Framework: https://attack.mitre.org

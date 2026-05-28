# Script Otomatisasi Reconnaissance - Project Sentinel
# FYEP Cybersecurity 2026

# Menetapkan IP target secara default ke Windows Endpoint
TARGET="192.168.10.20"

echo "======================================="
echo "     Sistem Pengujian Otomatis Lab     "
echo "======================================="
echo "[*] Target Default: $TARGET"
echo "---------------------------------------"

echo "[+] Memeriksa Konektivitas Jaringan (Ping)..."
if ping -c 2 $TARGET &> /dev/null
then
	echo "	[SUCCESS] Target UP dan Merespon!"
else
	echo "	[WARNING] Target DOWN atau ICMP diblokir Firewall pfSense."
fi

echo -e "\n[+] Menjalankan Nmap Fast Port Scanning..."
nmap -F $TARGET

echo -e "\n======================================================"
echo "                  Pengujian Selesai!                  "
echo "======================================================"

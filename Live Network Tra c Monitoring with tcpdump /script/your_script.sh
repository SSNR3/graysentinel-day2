#!/bin/bash
# ------------------------------------------------------------------
# PoC Automation Script: Live Network Traffic Monitoring with tcpdump
# Track: Network Security / Packet Analysis
# ------------------------------------------------------------------

set -e

# Base directory definitions
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="${BASE_DIR}/evidence"
LOGS_DIR="${BASE_DIR}/logs"
PCAP_FILE="${EVIDENCE_DIR}/capture.pcap"

CAPTURE_DURATION=300
INTERFACE="eth0"

# Verify root privileges
if [ "$EUID" -ne 0 ]; then
    echo "[-] Please run this script as root or with sudo."
    exit 1
fi

mkdir -p "$EVIDENCE_DIR" "$LOGS_DIR"

echo "========================================================="
echo "   Live Network Traffic Monitor & Analyzer (tcpdump)    "
echo "========================================================="

# Step 1: Interface validation
echo "[+] Step 1: Checking interface configuration..."
ip -br a | grep "$INTERFACE" || {
    echo "[-] Error: Interface $INTERFACE not found."
    exit 1
}

# Step 2: Live timed packet capture
if [ -f "$PCAP_FILE" ]; then
    echo "[*] Existing capture found at $PCAP_FILE."
    read -p "    Overwrite existing capture? (y/N): " choice
    case "$choice" in
        y|Y )
            echo "[+] Capturing live traffic on $INTERFACE for ${CAPTURE_DURATION}s..."
            timeout "$CAPTURE_DURATION" tcpdump -i "$INTERFACE" -w "$PCAP_FILE" || true
            ;;
        * )
            echo "[*] Skipping capture, using existing file."
            ;;
    esac
else
    echo "[+] Capturing live traffic on $INTERFACE for ${CAPTURE_DURATION}s..."
    timeout "$CAPTURE_DURATION" tcpdump -i "$INTERFACE" -w "$PCAP_FILE" || true
fi

# Step 3: Verify pcap existence
if [ ! -s "$PCAP_FILE" ]; then
    echo "[-] Error: Capture file $PCAP_FILE is empty or missing."
    exit 1
fi

echo ""
echo "========================================================="
echo "                 TRAFFIC ANALYSIS STAGE                  "
echo "========================================================="

# Step 4: Total Packets Captured
echo "[+] Analyzing total packet count..."
TOTAL_PACKETS=$(tcpdump -r "$PCAP_FILE" --count 2>/dev/null | tr -d '[:space:]')
echo "    Total Packets: $TOTAL_PACKETS" | tee "${LOGS_DIR}/total_packets.log"

# Step 5: Top 5 Source IPs
echo ""
echo "[+] Extracting Top 5 Source IP Addresses..."
tcpdump -nnr "$PCAP_FILE" ip 2>/dev/null \
    | awk '{print $3}' \
    | awk -F'.' '{print $1"."$2"."$3"."$4}' \
    | sort \
    | uniq -c \
    | sort -nr \
    | head -n 5 \
    | tee "${LOGS_DIR}/top5_source_ips.log"

# Step 6: Extract ARP Traffic
echo ""
echo "[+] Extracting Layer-2 ARP traffic (first 20 packets)..."
tcpdump -nnr "$PCAP_FILE" arp 2>/dev/null \
    | head -n 20 \
    | tee "${LOGS_DIR}/arp_traffic.log"

# Step 7: Extract ICMP Traffic
echo ""
echo "[+] Extracting Layer-3 ICMP traffic (first 20 packets)..."
tcpdump -nnr "$PCAP_FILE" icmp 2>/dev/null \
    | head -n 20 \
    | tee "${LOGS_DIR}/icmp_traffic.log"

echo ""
echo "========================================================="
echo "[✓] Analysis complete! Logs stored in: ${LOGS_DIR}/"
echo "========================================================="

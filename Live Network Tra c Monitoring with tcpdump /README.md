# Live Network Traffic Monitoring with tcpdump

## Description
This project demonstrates live network traffic capture and packet-level inspection on a Kali Linux virtual environment using `tcpdump`. Network telemetry was captured continuously for 5 minutes and written directly to a `.pcap` evidence file for offline evaluation. Using Berkeley Packet Filter (BPF) syntax and Linux text processing utilities, the capture was analyzed to isolate total packet counts, top communicating source IPs, and protocol-specific patterns including ARP and ICMP transactions.

## Tools Used
* **tcpdump**: Live packet capture, `.pcap` processing, and Berkeley Packet Filter (BPF) querying
* **awk / sort / uniq**: Log parsing, string tokenization, and IP address frequency sorting
* **iproute2 (ip)**: Network adapter discovery and subnet configuration verification

## Lab Setup
* **Kali Linux version:** Kali GNU/Linux Rolling 2026.2 (kernel release verified via `/etc/os-release`)
* **Target:** Default Gateway / Subnet Broadcast (`192.168.179.1` / `192.168.179.2`) and Remote DNS (`8.8.8.8`)
* **Network:** VMware NAT Subnet (`192.168.179.0/24`), local host IP `192.168.179.129`

## Steps Performed
* **Step 1: Network Adapter Verification & Setup:** Validated that network interface `eth0` was active and checked the assigned IPv4 address with `ip -br a`. Created the required folder hierarchy (`evidence/`, `logs/`, `report/`, `screenshots/`, `scripts/`).
* **Step 2: Timed 5-Minute Packet Capture:** Executed `tcpdump` bound to `eth0` using the `timeout` utility for 300 seconds, saving all raw packet bytes directly into `evidence/capture.pcap`. Generated active network traffic via ICMP pings and web requests during the capture window.
* **Step 3: Capture Verification & Packet Count Analysis:** Read the capture index to confirm total frames captured and validated file integrity without truncated headers using `tcpdump --count`.
* **Step 4: Top 5 Source IP Extraction:** Parsed Layer-3 source headers from the raw capture file, trimmed port designations, and aggregated frequencies to identify top talkers.
* **Step 5: Protocol-Specific Inspection (ARP & ICMP):** Applied BPF filters to isolate Layer-2 Address Resolution Protocol frames (`arp`) and Layer-3 Internet Control Message Protocol echo packets (`icmp`).

## Commands Used
```bash
# 1. Check local network interface configuration
ip -br a

# 2. Capture traffic on eth0 for 300 seconds (5 minutes)
sudo timeout 300 tcpdump -i eth0 -w evidence/capture.pcap

# 3. Calculate total packets stored in the pcap
tcpdump -r evidence/capture.pcap --count

# 4. Extract and rank the top 5 source IP addresses
tcpdump -nnr evidence/capture.pcap ip 2>/dev/null | awk '{print $3}' | awk -F'.' '{print $1"."$2"."$3"."$4}' | sort | uniq -c | sort -nr | head -n 5

# 5. Extract the first 20 ARP packets
tcpdump -nnr evidence/capture.pcap arp | head -n 20

# 6. Extract the first 20 ICMP packets
tcpdump -nnr evidence/capture.pcap icmp | head -n 20

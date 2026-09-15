# Live Network Traffic Monitoring with tcpdump

## Description
This proof of concept demonstrates live packet capture and command-line traffic analysis on a Kali Linux virtual machine using `tcpdump`. Network traffic was captured over a 5-minute interval, written to a `.pcap` file, and filtered using Berkeley Packet Filters (BPF) and standard Linux stream editors to identify packet volume, top source talkers, and protocol-specific patterns (ARP and ICMP).

## Tools Used
* **tcpdump**: Packet capture and BPF filtering
* **awk / sort / uniq**: Log parsing and stream aggregation
* **iproute2 / ip**: Network interface verification

## Lab Setup
* **Host Environment:** Kali Linux (Rolling Release)
* **Active Interface:** `eth0`
* **Network Mode:** NAT / Host-Only
* **Capture Duration:** 300 seconds (5 minutes)

## Steps Performed
1. Verified interface configuration and operational state using `ip -br a`.
2. Initiated a 5-minute packet capture with `sudo timeout 300 tcpdump -i eth0 -w evidence/capture.pcap`.
3. Generated auxiliary network traffic (DNS queries, HTTPS sessions, ICMP echoes) to simulate real-world usage.
4. Calculated total packet counts directly from the `.pcap` binary index.
5. Extracted and aggregated the top 5 source IPv4 addresses using `awk`, `sort`, and `uniq`.
6. Filtered raw pcap data for ARP broadcast/unicast resolutions and ICMP echo transactions.

## Commands Used
```bash
# 1. Check network interface
ip -br a

# 2. Capture traffic for 5 minutes
sudo timeout 300 tcpdump -i eth0 -w evidence/capture.pcap

# 3. Total packet count
tcpdump -r evidence/capture.pcap --count

# 4. Top 5 Source IP Addresses
tcpdump -nnr evidence/capture.pcap ip 2>/dev/null | awk '{print $3}' | awk -F'.' '{print $1"."$2"."$3"."$4}' | sort | uniq -c | sort -nr | head -n 5

# 5. Extract ARP traffic
tcpdump -nnr evidence/capture.pcap arp

# 6. Extract ICMP traffic
tcpdump -nnr evidence/capture.pcap icmp

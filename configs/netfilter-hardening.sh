#!/bin/bash
# ------------------------------------------------------------------
# Script: netfilter-hardening.sh
# Purpose: Apply strict ingress/egress policies for the cloud node.
# ------------------------------------------------------------------

echo "[*] Initializing Netfilter Baseline..."

# Flush existing rules
iptables -F
iptables -X

# Set default DROP policy
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT

# Allow established and related connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (Restricted to specific admin IPs in production)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow Edge Proxy Ingress (e.g., HTTPS traffic from CDN)
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p udp --dport 443 -j ACCEPT

echo "[+] Netfilter rules successfully applied."

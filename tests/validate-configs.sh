#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."

command -v bash >/dev/null
bash -n configs/netfilter-hardening.sh
grep -Eq '^net\.ipv4\.ip_forward = 1$' configs/sysctl-tuning.conf
grep -Eq '^net\.ipv6\.conf\.all\.forwarding = 1$' configs/sysctl-tuning.conf
grep -Eq '^net\.ipv4\.tcp_syncookies = 1$' configs/sysctl-tuning.conf
grep -Eq '^net\.ipv4\.conf\.all\.accept_source_route = 0$' configs/sysctl-tuning.conf
grep -Eq '^net\.ipv6\.conf\.all\.accept_redirects = 0$' configs/sysctl-tuning.conf
if grep -Eq '(^|[[:space:]])iptables -A INPUT -p tcp --dport 22([[:space:]]|$)' configs/netfilter-hardening.sh; then
    echo "unrestricted SSH rule found" >&2
    exit 1
fi
grep -Eq 'ADMIN_IPV4_CIDRS|ADMIN_IPV6_CIDRS' configs/netfilter-hardening.sh
grep -Eq 'ALLOW_PUBLIC_HTTPS' configs/netfilter-hardening.sh
printf '%s\n' "configuration validation passed"

#!/usr/bin/env bash
# Apply a conservative netfilter baseline to an edge/origin Linux node.
#
# Required before applying:
#   ADMIN_IPV4_CIDRS="203.0.113.10/32 198.51.100.0/24"
#   ADMIN_IPV6_CIDRS="2001:db8:1234::/48"       # optional
#   EDGE_IPV4_CIDRS="198.51.100.0/24"           # optional but recommended
#   EDGE_IPV6_CIDRS="2001:db8:abcd::/48"        # optional
#
# The script intentionally does not open SSH to the Internet by default.
# Run with --dry-run to inspect the commands without changing the host.
set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly BACKUP_V4="${PWD}/.${SCRIPT_NAME}.$$.iptables"
readonly BACKUP_V6="${PWD}/.${SCRIPT_NAME}.$$.ip6tables"
DRY_RUN=0
APPLIED_V4=0
APPLIED_V6=0

ADMIN_IPV4_CIDRS="${ADMIN_IPV4_CIDRS:-}"
ADMIN_IPV6_CIDRS="${ADMIN_IPV6_CIDRS:-}"
EDGE_IPV4_CIDRS="${EDGE_IPV4_CIDRS:-}"
EDGE_IPV6_CIDRS="${EDGE_IPV6_CIDRS:-}"
ALLOW_PUBLIC_HTTPS="${ALLOW_PUBLIC_HTTPS:-0}"
ALLOW_QUIC="${ALLOW_QUIC:-0}"

usage() {
    cat <<'EOF'
Usage: ADMIN_IPV4_CIDRS="x.x.x.x/32 ..." ./configs/netfilter-hardening.sh [--dry-run]

Admin CIDRs are required. EDGE_*_CIDRS restrict HTTPS to known edge networks;
set ALLOW_PUBLIC_HTTPS=1 only when public HTTPS is an explicit design choice.
Set ALLOW_QUIC=1 to allow UDP/443 in addition to TCP/443.
EOF
}

log() { printf '[%s] %s\n' "$SCRIPT_NAME" "$*"; }
die() { printf '[%s] ERROR: %s\n' "$SCRIPT_NAME" "$*" >&2; exit 1; }

run() {
    if (( DRY_RUN )); then
        printf '+'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

valid_ipv4_cidr() {
    local value="$1" octet prefix
    [[ "$value" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]] || return 1
    prefix="${value##*/}"
    (( prefix <= 32 )) || return 1
    value="${value%/*}"
    IFS=. read -r -a octets <<< "$value"
    for octet in "${octets[@]}"; do (( octet <= 255 )) || return 1; done
}

valid_ipv6_cidr() {
    local value="$1" prefix
    [[ "$value" == */* ]] || return 1
    prefix="${value##*/}"
    [[ "$prefix" =~ ^[0-9]{1,3}$ ]] && (( prefix <= 128 )) || return 1
    [[ "${value%/*}" =~ ^[0-9A-Fa-f:.]+$ ]]
}

validate_list() {
    local family="$1" list="$2" item
    [[ "$list" =~ ^[[:space:],0-9A-Fa-f:./]*$ ]] || die "invalid character in ${family} CIDR list"
    list="${list//,/ }"
    for item in $list; do
        if [[ "$family" == ipv4 ]]; then
            valid_ipv4_cidr "$item" || die "invalid IPv4 CIDR: $item"
        else
            valid_ipv6_cidr "$item" || die "invalid IPv6 CIDR: $item"
        fi
    done
}

validate_inputs() {
    (( EUID == 0 || DRY_RUN )) || die "run as root (or use --dry-run for inspection)"
    [[ "$ALLOW_PUBLIC_HTTPS" =~ ^[01]$ ]] || die "ALLOW_PUBLIC_HTTPS must be 0 or 1"
    [[ "$ALLOW_QUIC" =~ ^[01]$ ]] || die "ALLOW_QUIC must be 0 or 1"
    [[ -n "${ADMIN_IPV4_CIDRS//[[:space:],]/}" || -n "${ADMIN_IPV6_CIDRS//[[:space:],]/}" ]] ||
        die "at least one ADMIN_IPV4_CIDRS or ADMIN_IPV6_CIDRS entry is required"
    validate_list ipv4 "$ADMIN_IPV4_CIDRS"
    validate_list ipv6 "$ADMIN_IPV6_CIDRS"
    validate_list ipv4 "$EDGE_IPV4_CIDRS"
    validate_list ipv6 "$EDGE_IPV6_CIDRS"
    if (( !DRY_RUN )); then
        command -v iptables >/dev/null || die "iptables is not installed"
        command -v ip6tables >/dev/null || die "ip6tables is not installed"
        command -v iptables-save >/dev/null || die "iptables-save is not installed"
        command -v ip6tables-save >/dev/null || die "ip6tables-save is not installed"
        command -v iptables-restore >/dev/null || die "iptables-restore is not installed"
        command -v ip6tables-restore >/dev/null || die "ip6tables-restore is not installed"
    fi
}

rollback() {
    local status=$?
    if (( status != 0 && !DRY_RUN && (APPLIED_V4 || APPLIED_V6) )); then
        log "apply failed; restoring saved rules"
        (( APPLIED_V4 )) && iptables-restore < "$BACKUP_V4" || true
        (( APPLIED_V6 )) && ip6tables-restore < "$BACKUP_V6" || true
    fi
    rm -f "$BACKUP_V4" "$BACKUP_V6"
    exit "$status"
}
trap rollback EXIT

append_sources() {
    local command="$1" port="$2" list="$3" item
    local -a items
    list="${list//,/ }"
    [[ -n "${list//[[:space:]]/}" ]] || return 0
    read -r -a items <<< "$list"
    for item in "${items[@]}"; do
        run "$command" -A INPUT -p tcp --dport "$port" -s "$item" -m conntrack --ctstate NEW -j ACCEPT
    done
}

apply_family() {
    local command="$1" backup="$2" admin="$3" edge="$4" icmp_protocol="$5" item
    local -a edge_items
    edge="${edge//,/ }"
    read -r -a edge_items <<< "$edge"
    run "$command-save" > "$backup"
    run "$command" -F INPUT
    run "$command" -F FORWARD
    run "$command" -F OUTPUT
    run "$command" -P INPUT DROP
    run "$command" -P FORWARD DROP
    run "$command" -P OUTPUT ACCEPT
    run "$command" -A INPUT -i lo -j ACCEPT
    run "$command" -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    run "$command" -A INPUT -p "$icmp_protocol" -j ACCEPT
    append_sources "$command" 22 "$admin"
    if (( ALLOW_PUBLIC_HTTPS )); then
        run "$command" -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT
    else
        append_sources "$command" 443 "$edge"
    fi
    if (( ALLOW_QUIC )); then
        if (( ALLOW_PUBLIC_HTTPS )); then
            run "$command" -A INPUT -p udp --dport 443 -j ACCEPT
        else
            for item in "${edge_items[@]}"; do
                run "$command" -A INPUT -p udp --dport 443 -s "$item" -j ACCEPT
            done
        fi
    fi
}

main() {
    [[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }
    [[ $# -le 1 && ( $# -eq 0 || "$1" == "--dry-run" ) ]] || { usage >&2; exit 2; }
    [[ "${1:-}" != "--dry-run" ]] || DRY_RUN=1
    validate_inputs
    if (( !ALLOW_PUBLIC_HTTPS )) &&
        [[ -z "${EDGE_IPV4_CIDRS//[[:space:],]/}" ]] &&
        [[ -z "${EDGE_IPV6_CIDRS//[[:space:],]/}" ]]; then
        die "configure EDGE_*_CIDRS or explicitly set ALLOW_PUBLIC_HTTPS=1"
    fi
    if (( !DRY_RUN )); then
        iptables-save > "$BACKUP_V4"
        ip6tables-save > "$BACKUP_V6"
    fi
    APPLIED_V4=1
    apply_family iptables "$BACKUP_V4" "$ADMIN_IPV4_CIDRS" "$EDGE_IPV4_CIDRS" icmp
    APPLIED_V6=1
    apply_family ip6tables "$BACKUP_V6" "$ADMIN_IPV6_CIDRS" "$EDGE_IPV6_CIDRS" ipv6-icmp
    log "rules applied; verify SSH and service access before closing this session"
}

main "$@"

# Operations runbook

## Deployment

1. Create a disposable test node and confirm provider firewall rules allow console access and the intended application ports.
2. Set `ADMIN_IPV4_CIDRS` and/or `ADMIN_IPV6_CIDRS` to administrator networks. Set `EDGE_IPV4_CIDRS` and `EDGE_IPV6_CIDRS` to the provider's current egress ranges. Do not use `0.0.0.0/0` for SSH.
3. Run `sudo env ADMIN_IPV4_CIDRS="203.0.113.10/32" EDGE_IPV4_CIDRS="198.51.100.0/24" ./configs/netfilter-hardening.sh --dry-run`.
4. Apply the sysctl file during a maintenance window, verify that BBR is available, then apply the firewall. Keep an existing SSH session open and test a second session.
5. Record the exact rules, kernel version, cloud rules, and validation results.

The script requires root for an apply and saves both firewall tables before changing them. It does not install packages, alter cloud controls, or manage certificates.

## Validation and monitoring

Run `bash tests/validate-configs.sh` and `bash -n configs/netfilter-hardening.sh`. Check `iptables-save`, `ip6tables-save`, `sysctl -a`, service health, logs, and connection metrics. Alert on unexpected SSH attempts, rule changes, forwarding errors, resource exhaustion, and edge health failures. Review edge provider ranges before each planned change.

## Rollback

If access fails, use the existing session or provider console. The script restores its saved rules on a failed apply. For a deliberate manual rollback, restore the backup files named `.netfilter-hardening.sh.<pid>.iptables` and `.netfilter-hardening.sh.<pid>.ip6tables` with `iptables-restore` and `ip6tables-restore`, then remove them. Restore the previous sysctl file and run `sudo sysctl --system`. Treat backups as sensitive because they disclose network policy.

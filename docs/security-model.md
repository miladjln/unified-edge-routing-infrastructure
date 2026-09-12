# Security model

## Purpose and scope

This repository is an educational baseline for a secure edge ingress and origin-protection pattern on Linux and OCI. It demonstrates defense in depth: a managed edge terminates or forwards approved application traffic, while the origin limits network exposure and is hardened at the kernel and firewall layers. It is not a production security certification or a turnkey deployment.

## Assets and trust boundaries

- The origin host, application listener, credentials, logs, and private configuration are assets.
- Clients and the public network are untrusted.
- The edge provider is a separate operational trust boundary. Its account, certificates, access policy, and upstream configuration require independent controls.
- The cloud account, virtual network security lists, and host firewall are separate enforcement layers.
- Administrative SSH is trusted only from explicitly configured administrator CIDRs.

## Threats addressed

The baseline reduces accidental exposure, unsolicited SSH access, spoofed redirects/source routes, and common TCP connection abuse. It provides explicit IPv4 and IPv6 policy, stateful return traffic, and a rollback path when applying firewall rules.

It does not prevent application vulnerabilities, compromised administrator credentials, a compromised edge account, volumetric denial of service, malicious traffic allowed by an edge policy, or host compromise. Cloud controls, patching, identity management, monitoring, backups, and incident response remain necessary.

## Assumptions and limitations

The operator has console or out-of-band recovery access, knows the real administrator and edge CIDRs, and has tested the application with IPv4 and IPv6 as applicable. CIDR lists are inputs, not proof that a network is trustworthy. The sysctl values are a measured starting point, not universal performance advice. Availability and throughput claims must be established by the operator's own tests.

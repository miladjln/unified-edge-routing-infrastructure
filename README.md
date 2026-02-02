# HYBRID DUAL-INBOUND NETWORK ARCHITECTURE
## Bridging XTLS-Vision Stability & Post-Quantum Security

![Architecture Diagram](assets/architecture-diagram.jpg)

> **Status:** Active | **License:** MIT | **Platform:** Oracle Cloud (OCI)

## 📋 Executive Summary
This project implements a high-availability, censorship-resistant network infrastructure designed to solve the **interoperability gap** between modern Post-Quantum security standards and legacy client software.

While advanced clients (such as **Streisand** on iOS) support cutting-edge ML-KEM encryption, a significant number of standard clients on Windows and Android rely on older core versions that lack support for these next-gen protocols. This architecture utilizes a **Dual-Inbound Strategy** to ensure universal access: providing a dedicated lane for modern, secure clients and a compatibility lane for legacy software without requiring immediate user-side updates.

---

## 🏗 System Architecture

The core of this architecture is built upon **Xray-Core** with a split-routing mechanism to handle client fragmentation:

### 1. The Compatibility Stream (Port 443)
* **Target:** Universal Clients (Android, Windows, Legacy iOS) & Standard Cores.
* **Protocol:** `VLESS` + `Reality` + `XTLS-Vision`.
* **Engineering Decision:** **No Auth / Standard Handshake**.
    * *Rationale:* Many widely-used client applications have not yet integrated the latest Xray-core updates required for ML-KEM handshakes. By removing strict authentication headers on this port and adhering to standard TLS 1.3 procedures, we ensure **100% compatibility** with any client version, effectively bypassing "unsupported protocol" errors common in older software ecosystems.

### 2. The Security Stream (Port 2053)
* **Target:** Bleeding-Edge Clients (e.g., Streisand, latest v2rayNG).
* **Protocol:** `VLESS` + `Reality` + `XTLS-Vision`.
* **Security Layer:** **uTLS + ML-KEM (Post-Quantum Cryptography)**.
    * *Rationale:* Designed explicitly for environments and clients that support the latest Xray standards. It enforces **Kyber-768** encryption to protect traffic against "Harvest Now, Decrypt Later" quantum decryption attacks.

---

## 🛡️ Key Features
* **Hybrid Inbound Logic:** Seamlessly handles both legacy (standard core) and next-gen (bleeding-edge) requests.
* **SNI Masquerading:** Simulates `google.com` traffic behavior via HTTP/3 QUIC to evade DPI.
* **Network Optimization:** Kernel-level **Google BBR** congestion control enabled for high-throughput on high-latency links.
* **Dual-Stack Firewall:** Synchronized L3 (Oracle Cloud) and L4 (UFW) rules.

---

## 🚀 Future Roadmap
This project is under active development. Planned features for Phase 2:
- [ ] **Monitoring & Alerting:** Integration with Uptime Kuma for real-time health checks.
- [ ] **Automated Backups:** Cron jobs to backup X-UI database to secure object storage.
- [ ] **Dockerization:** Full containerization of the stack for rapid deployment.
- [ ] **Failover System:** Implementing a Standby Server with DNS Load Balancing.

---

## 🛠️ Deployment
### Prerequisites
* VPS (Ubuntu 20.04/22.04 LTS).
* Xray-Core installed (v1.8.0+).

### Quick Start
1.  **Install Xray:** Use the official script or X-UI panel.
2.  **Config:** Apply the `inbounds` settings from `configs/xray-sample.json`.
3.  **Optimize:** Enable BBR via `sysctl`.

---
*Disclaimer: This project is for educational and research purposes only.*

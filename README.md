# HYBRID NETWORK ARCHITECTURE: TRI-FOLD RESILIENCE SYSTEM
## Bridging Legacy Compatibility, Post-Quantum Security & Network Resilience

![Architecture Diagram](assets/architecture-diagram.jpg)

> **Status:** Active | **License:** MIT | **Platform:** Oracle Cloud (OCI)

## 📋 Executive Summary
This project implements a robust, censorship-resistant network infrastructure designed to address three critical challenges in modern restrictive network environments: **Client Compatibility**, **Quantum Security**, and **Packet Loss Resilience**.

By evolving into a **Tri-Fold Architecture**, the system segregates traffic into three specialized streams, ensuring universal access for legacy devices, maximum security for modern endpoints, and connection stability during high-packet-loss events via gRPC.

---

## 🏗 System Architecture

The core of this architecture is built upon **Xray-Core** with a multi-protocol routing strategy:

### 1. The Compatibility Stream (Port 443)
* **Target:** Legacy Clients, Restrictive Firewalls (Hotels/Airports), & Universal Access.
* **Protocol:** `TCP` + `XTLS-Vision`.
* **Engineering Decision:** **No Auth (Standard TLS 1.3)**.
    * *Rationale:* Designed as the "Golden Gate." By adhering to standard TLS 1.3 handshakes without Xray-specific authentication headers, this port ensures 100% connectibility on restricted networks that whitelist only Port 443, while maintaining compatibility with older client cores.

### 2. The Security Stream (Port 2053)
* **Target:** Modern Desktop Clients & High-Security Contexts.
* **Protocol:** `TCP` + `XTLS-Vision`.
* **Security Layer:** **uTLS + ML-KEM (Post-Quantum Cryptography)**.
    * *Rationale:* A dedicated lane for bleeding-edge clients, enforcing Kyber-768 encryption to future-proof traffic against "Harvest Now, Decrypt Later" quantum attacks.

### 3. The Resilience Stream (Port 2096) 🆕
* **Target:** High Packet Loss Environments & TCP Throttling.
* **Protocol:** **gRPC** + `Reality`.
* **Engineering Decision:** **HTTP/2 Multiplexing**.
    * *Rationale:* Acts as a "Plan C" fallback. When TCP connections are throttled or experience high jitter, gRPC's multiplexing capability maintains stable throughput by managing concurrent streams more efficiently than raw TCP.

---

## 🛡️ Key Features
* **Strategic SNI Masquerading:** Leverages high-reputation domains (e.g., Microsoft/Oracle ecosystem) to blend traffic with legitimate background OS telemetry and updates.
* **Kernel Optimization:** Enabled **Google BBR** for congestion control to maximize bandwidth on high-latency links.
* **Multi-Layer Firewall:** Synchronized Oracle Security Lists (L3) and UFW (L4) allowing seamless UDP/QUIC fallback.

---

## 🚀 Future Roadmap
- [ ] **Automated Failover:** Scripting auto-switch logic based on packet loss metrics.
- [ ] **Dockerization:** Containerizing the Tri-Fold stack for rapid deployment.
- [ ] **Monitoring:** Integration with Prometheus for real-time traffic analysis.

---

## 🛠️ Deployment
### Prerequisites
* VPS (Ubuntu 20.04/22.04 LTS).
* Xray-Core (v1.8.4+).

### Quick Start
1.  **Install Xray:** Deploy using the official script.
2.  **Config:** Apply the `inbounds` settings from `configs/xray-sample.json`.
3.  **Optimize:** Enable BBR via `sysctl`.

---
*Disclaimer: This project is for educational and research purposes only.*

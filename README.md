# Unified Edge Routing & Resilience Architecture

## 📌 Project Overview
This repository contains the architectural design and system baselines for a highly available, fault-tolerant edge routing infrastructure deployed on Oracle Cloud Infrastructure (OCI). 

Engineered to operate reliably in high-latency environments with unpredictable packet loss, this unified architecture bridges edge-level security (CDN proxying) with transport-level resilience (HTTP/2 multiplexing). The focus is on secure traffic encapsulation, origin server protection, and automated system hardening.

## 🏗️ Unified Architecture

The system routes traffic through a secure edge layer, standardizes the transport to ensure compatibility, and utilizes multiplexing to maintain throughput during network congestion.

```mermaid
flowchart LR
    classDef client fill:#f3f4f6,stroke:#9ca3af,stroke-width:2px,color:#1f2937;
    classDef edge fill:#e0f2fe,stroke:#0284c7,stroke-width:2px,color:#0c4a6e;
    classDef internal fill:#ffffff,stroke:#db2777,stroke-width:1px,color:#1f2937;
    classDef internet fill:#dcfce7,stroke:#16a34a,stroke-width:2px,color:#14532d;

    Client([💻 Remote Clients]):::client

    subgraph EdgePerimeter [Edge Perimeter]
        CDN[☁️ CDN Bridge Layer<br>TLS 1.3 Strict Enforcement]:::edge
    end

    subgraph OCILayer [Oracle Cloud Infrastructure]
        direction LR
        FW[🛡️ Ingress Firewall<br>Linux Netfilter]:::internal
        MUX[⚙️ Traffic Multiplexer<br>gRPC / WS Transport]:::internal
        FW -->|Authorized Streams| MUX
    end

    subgraph EgressLayer [External Network]
        WWW((🌐 Global Internet)):::internet
    end

    Client -->|Encrypted Requests| CDN
    CDN -->|Standardized HTTP/WSS| FW
    MUX -->|Decrypted NAT Egress| WWW


🚀 Key Engineering Features
Edge-Proxied Ingress: Standardized transport protocols (WebSocket/gRPC) to integrate seamlessly with CDN reverse proxies, masking the origin IP and absorbing malicious scanning.

Transport Resilience: Leveraged HTTP/2 multiplexing principles to significantly reduce connection drops and maintain stable throughput during TCP throttling events.

Strict Security Perimeter: Enforced end-to-end TLS 1.3 encryption using custom Origin CA certificates, coupled with OS-level Netfilter policies to drop all unauthenticated traffic.

Kernel Optimization: Tuned Linux networking stack by enabling TCP BBR (Bottleneck Bandwidth and RTT) to maximize transmission efficiency over long-distance routes.

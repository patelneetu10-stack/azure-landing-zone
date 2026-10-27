<div align="center">

# 🏛️ Azure Enterprise Landing Zone (CAF)
### Production-Grade Hub-and-Spoke Architecture with Zero-Trust Network Governance

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](#)
[![Azure](https://img.shields.io/badge/Microsoft_Azure-Landing_Zone-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)](#)
[![Security CIS](https://img.shields.io/badge/Compliance-CIS_Azure_v2.0-107C41?style=for-the-badge&logo=checkmarx&logoColor=white)](#)
[![Zero Trust](https://img.shields.io/badge/Security-Zero--Trust_Posture-black?style=for-the-badge&logo=auth0&logoColor=white)](#)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](#)

<p align="center">
  <b>Declarative, secure, and automated enterprise Cloud Adoption Framework (CAF) Landing Zone infrastructure on Microsoft Azure orchestrated via Terraform.</b>
</p>

</div>

---

## 📌 Executive Architecture Overview

This repository provisions an **Enterprise Azure Hub-and-Spoke Landing Zone** adhering strictly to the **Microsoft Cloud Adoption Framework (CAF)** and **CIS Azure Foundations Benchmark v2.0**.

It delivers a hardened perimeter, centralized egress/ingress inspection via **Azure Firewall**, zero-public-IP management using **Azure Bastion**, and strict network isolation across multi-tenant spoke virtual networks.

```mermaid
flowchart TD
    subgraph OnPremises ["🏢 On-Premises / Remote Users"]
        VPN["VPN / ExpressRoute"]
        Admin["SecOps / Admins"]
    end

    subgraph HubVNet ["🛡️ Hub Virtual Network (10.100.0.0/16)"]
        AFW["🔥 Azure Firewall Premium\n(10.100.0.4)"]
        Bastion["🔒 Azure Bastion Host\n(Zero-Public-IP Access)"]
        LAW["📊 Log Analytics Workspace\n(Central Telemetry & Audit)"]
    end

    subgraph SpokeWorkload ["📦 Workload Spoke VNet (10.101.0.0/16)"]
        AppSubnet["💻 App Tier Subnet\n(10.101.1.0/24)"]
        DataSubnet["🗄️ Data Tier Subnet\n(10.101.2.0/24)"]
        PrivateEndpoints["🔗 Private Link Endpoints\n(10.101.3.0/24)"]
        UDR["🔀 User-Defined Route (UDR)\nDefault 0.0.0.0/0 -> AFW"]
    end

    Admin -->|TLS 443| Bastion
    VPN --> HubVNet
    AppSubnet --> UDR --> AFW
    AFW -->|Inspect & Egress| Internet["🌐 Secure Internet / SaaS"]
    Bastion --> AppSubnet
    HubVNet <==>|Bidirectional VNet Peering| SpokeWorkload
    HubVNet -.->|Diagnostic Telemetry| LAW
    SpokeWorkload -.->|Diagnostic Telemetry| LAW
```

---

## ✨ Key Architectural Highlights

- 🔒 **Zero-Trust Network Perimeter:** All egress traffic from workload spokes is forcibly directed via User-Defined Routes (UDR) to Azure Firewall for deep packet inspection.
- 🚫 **Zero Direct Public IPs:** Compute and application workloads have zero public IP exposure; administrative access is restricted to Azure Bastion tunneling over TLS 443.
- ⚡ **Zone-Redundant High Availability:** Azure Firewall and Public IP resources are distributed across multi-availability zones (`["1", "2", "3"]`) for 99.99% SLA resilience.
- 📜 **Policy-as-Code & Drift Mitigation:** Shift-left security automation with Checkov, Trivy, and Terraform format checks built into GitHub Actions workflows.
- 💰 **FinOps Cost Discipline:** Tagging taxonomy enforces cost center allocation, data classification, and automated environment lifecycle decommissioning.

---

## 📂 Repository File Structure

```tree
azure-landing-zone/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml      # CI lint, fmt, validate & Checkov scan
├── .gitignore                    # Enterprise git exclusion rules
├── main.tf                       # Hub, Spokes, Firewall, Bastion & UDR resources
├── variables.tf                  # Type-safe input variables with validation
├── outputs.tf                    # Critical resource IDs, IPs, and endpoints
├── versions.tf                   # Provider versions and Azure Blob remote state
├── terraform.tfvars.example      # Sample production configuration template
└── README.md                     # Architecture documentation
```

---

## 🚀 Quickstart & Deployment Guide

### Prerequisites
1. **Terraform CLI** >= 1.5.0
2. **Azure CLI (`az`)** >= 2.50.0
3. Active Azure Subscription with **Contributor** and **User Access Administrator** roles.

### 1. Authenticate with Azure
```bash
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

### 2. Configure Variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars to customize your IP address ranges and region
```

### 3. Initialize & Validate
```bash
terraform init
terraform fmt -check
terraform validate
```

### 4. Review Plan & Apply
```bash
terraform plan -out=landingzone.tfplan
terraform apply landingzone.tfplan
```

---

## 🛡️ Security & Compliance Guardrails

| Control Area | Implementation Standard |
|---|---|
| **Perimeter Security** | Azure Firewall with centralized application & network rule collections. |
| **Identity & Access** | Azure RBAC with Managed Identities, zero hardcoded secrets. |
| **State File Encryption** | Azure Blob Storage with customer-managed keys (CMK) and Blob Lease Locking. |
| **Traffic Encryption** | TLS 1.3 enforced on all external endpoints; private links for internal services. |
| **Audit Trails** | 90-day retention in central Log Analytics with diagnostic stream to Azure Monitor. |

---

## 📄 License
This architecture is licensed under the [MIT License](LICENSE).

# Proxmox Golden Images

Automated pipeline for building standardized VM templates on Proxmox VE using Packer and GitHub Actions.

## 🚀 Overview

This repository standardizes golden image builds in Proxmox VE. It utilizes **Packer** to drive reproducible image creation and **GitHub Actions** to orchestrate the builds through a self-hosted runner.

### Supported Distributions

| Distribution | Version | VM ID | Workflow File |
| :--- | :--- | :--- | :--- |
| **Rocky Linux** | 9 | `9002` | `.github/workflows/build.yml` |
| **CentOS** | Stream 10 | `9003` | `.github/workflows/centos10.yml` |
| **Ubuntu** | 24.04 LTS | `9004` | `.github/workflows/ubuntu24.yml` |

---

## 📋 Prerequisites

1.  **Proxmox VE Server**: Access to a Proxmox VE environment.
2.  **Proxmox API Token**: Credentials with permissions to create and manage QEMU VMs.
3.  **Self-Hosted Runner**: A Linux machine configured as a GitHub Actions runner with Packer installed.

---

## ⚙️ Configuration

### 1. Proxmox API Token Setup

Run the following commands on your Proxmox host shell to create a dedicated user and token with Administrator permissions:

```bash
# Create user
pveum user add packer@pam --comment "User for Packer automation"

# Assign permissions
pveum acl modify / -user packer@pam -role Administrator

# Generate token
pveum user token add packer@pam packer-token --privsep 0
```

The token creation command outputs a one-time `value` (secret). Save it immediately.

Token details:
- Token ID: `packer@pam!packer-token`
- Secret: the `value` from the token creation output

**GitHub Repository Secrets**
Add the following secrets in GitHub at `Settings` > `Secrets and variables` > `Actions` > `New repository secret`:

| Secret Name            | Description                                | Example Format                               |
|------------------------|--------------------------------------------|----------------------------------------------|
| `PROXMOX_URL`          | Full Proxmox API endpoint URL              | `https://proxmox.example.com:8006/api2/json` |
| `PROXMOX_TOKEN_ID`     | Token ID (user + token name)               | `user@pam!token_name`                        |
| `PROXMOX_TOKEN_SECRET` | Secret value returned when the token is created | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`  |

**Self-Hosted GitHub Runner (Linux)**
This project requires a Linux self-hosted runner for Packer builds.

1. Register the runner:
   Use GitHub at `Settings` > `Actions` > `Runners` > `New self-hosted runner`, choose Linux, then follow the download and configure instructions.

2. Install dependencies (inside the runner directory):
```bash
sudo ./bin/installdependencies.sh
```


adduser gitrunner
apt install sudo
usermod -aG sudo gitrunner
 mv /root/actions-runner /home/gitrunner/
chown -R gitrunner:gitrunner /home/gitrunner/actions-runner
su - gitrunner
 cd actions-runner
apt install sudo


3. Install and start the service:
```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

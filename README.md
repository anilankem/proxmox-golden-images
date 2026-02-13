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

2. Install dependencies (on the runner machine):

   **As root:** install system packages, Packer, and create the `gitrunner` user. Then move the runner into that user’s home and switch to it before configuring the service.

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  curl \
  jq \
  git \
  unzip \
  ca-certificates \
  gnupg \
  lsb-release

sudo rm -f /etc/apt/sources.list.d/hashicorp.list
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://apt.releases.hashicorp.com/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install packer


sudo useradd -m -s /bin/bash gitrunner
sudo usermod -aG sudo gitrunner

# If the runner was extracted as root, move it to gitrunner's home
sudo mv /root/actions-runner /home/gitrunner/
sudo chown -R gitrunner:gitrunner /home/gitrunner/actions-runner
```

   **Inside the runner directory** (if your setup uses `installdependencies.sh`):

```bash
sudo ./bin/installdependencies.sh
```

   **As `gitrunner`** (not root): generate an SSH key for GitHub:

```bash
su - gitrunner
cd ~/actions-runner   # or wherever the runner lives

ssh-keygen -t ed25519 -C "gitrunner@proxmox-packer-runner"
# Press Enter for all prompts (no passphrase for runners)
```

   Files created: `~/.ssh/id_ed25519` and `~/.ssh/id_ed25519.pub`.

   - **Copy the public key:** `cat ~/.ssh/id_ed25519.pub` — copy the whole line.
   - **Add key to GitHub:** GitHub → Settings → SSH and GPG keys → New SSH key (or Repo → Settings → Deploy Keys → Add key → Allow write access for a single repo).
   - **Test connection:** `ssh -T git@github.com`
   - **Use SSH repo URL:** For manual pulls use `git clone git@github.com:<user>/<repo>.git` or `git remote set-url origin git@github.com:<user>/<repo>.git`.
   - **Known hosts (avoid first-time prompt):** `ssh-keyscan github.com >> ~/.ssh/known_hosts`

3. Install and start the service (as `gitrunner`, inside the runner directory):

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```



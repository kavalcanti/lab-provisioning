# Known issues

Some fiddling might be needed to get cloud-init available in proxmox. Storage (local and local-lvm) might 
not be configured for snippet storage.

# Creating cloudinit template

``` bash
# Download the Debian cloud image
cd /tmp
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# Import it as a VM template (creates VM ID 9000)
qm create 9000 --name debian-12-cloud --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 debian-12-generic-amd64.qcow2 local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --agent enabled=1
qm set 9000 --serial0 socket
qm set 9000 --vga qxl 
# Convert to template
qm template 9000

# Clean up
rm debian-12-generic-amd64.qcow2
```

# VM Provisioning with Terraform

## Configuration

All configuration is managed through environment variables in `config/`:

- **`config/infrastructure.env`** - VM specs, network settings (committed to git)
- **`config/secrets.env`** - Proxmox credentials, passwords (gitignored, create from secrets.env.example)

### First Time Setup

```bash
# 1. Copy secrets template
cp config/secrets.env.example config/secrets.env

# 2. Edit with your Proxmox credentials
nano config/secrets.env

# 3. Review infrastructure settings
nano config/infrastructure.env
```

## Provisioning a VM

```bash
# Run the provisioning script (sources config automatically)
./scripts/make-debian.sh

# After VM is created, generate Ansible inventory
./scripts/generate-inventory.sh
```

The scripts will:
1. Source configuration from `config/*.env`
2. Run Terraform to create the VM
3. Show the VM IP address
4. Generate Ansible inventory file

# Ansible Configuration

## Variable Structure
- `group_vars/all/base.yml`: Common settings and defaults
- `group_vars/all/vault.yml`: Encrypted sensitive data (passwords, keys)
- `inventory/*.yml`: Environment-specific overrides

## Initial Setup
```bash
# 1. Configure vault
cp inventory/group_vars/all/vault.example.yml inventory/group_vars/all/vault.yml
ansible-vault encrypt inventory/group_vars/all/vault.yml

# 2. Edit vault
ansible-vault edit inventory/group_vars/all/vault.yml
```

## Initial Server Setup (as root)

Run only once

```bash
ansible-playbook playbooks/90-provisioning.yml \
  -i inventory/deployment.yml \
  --ask-vault-pass

# Production (set env vars first)
export PROD_HOSTNAME="hostname"
export PROD_IP="server-ip"
export PROD_SSH_PORT="4224"  # Optional, defaults to base.yml value

ansible-playbook playbooks/<playbook>.yml -i inventory/production.yml --ask-vault-pass
```

## Playbook Order
1. `00-initial.yml`: Initial setup (run as root)
2. Additional playbooks as needed

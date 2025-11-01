# Multilanguage README Pattern
[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/kavalcanti/lab-provisioning/blob/main/README.md)
[![pt-br](https://img.shields.io/badge/lang-pt--br-green.svg)](https://github.com/kavalcanti/lab-provisioning/blob/main/README.pt-br.md)

# What is this repo?

I have been homelabbing for a while and use proxmox to host VMs for my projects.
I have grown tired of click-ops'ing machines at home, so here is my attempt to
automate some of the effort.

## What does it do?

It creates a new Virtual Machine in the Proxmox host and runs security configuration.
Ansible roles for installing docker and nginx are also available.
It **does not** manage multiple VMs, or stores long term infrastructure details. It is meant for provisioning a single machine.

## How does it do it?

Convenience scripts located in `scripts/`are the main entrypoints for
functionality. This is how you should interact with this tool most of the time.

1. Create a new Debian VM with Terraform.
`scripts/make-debian.sh` 

2. Create a deployment manifest for Ansible
`scripts/generate-inventory.sh` 

3. Run basic security roles. Can only run once per VM.
`scripts/secure-vm.sh` 

4. Install Docker and configure UFW for Docker.
`scripts/install-docker.sh`

Note this will block docker from opening ports through UFW, set up aditional rules if
you are using server:PORT services.

5. Install Nginx and configure UFW for Nginx
`scripts/install-nginx.sh`

# Before you begin

## Create a cloud-init template

I am using a cloud-init image for this. It will need to be created beforehand,
so that terraform can clone it when provisioning a new machine. Here are
instructions to make a Debian template machine. The ansible automation in this
repo will propbably work for any debian base distros.

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

## Proxmox credentials

You will need to create a proxmox API key. I also recommend creating a separate
user for terraform. Enabling QEMU Agent requires SSH login, so the user should
be @PAM, not @PVE. This is probably overkill for homelab, but it is good
practice.

## Known issues

Some fiddling might be needed to get cloud-init available in proxmox. Storage
(local and local-lvm) might not be configured for snippet storage.

Check if snippets storage is configure on the Proxmox host with

```bash
pvesm status --content snippets 
```

If no storage is configured, run

```bash
pvesm set local --content vztmpl,iso,backup,snippets
```

## Configuration

All configuration is managed through environment variables in `config/`:

- **`config/infrastructure.env`** - VM specs, network settings (committed to git)
- **`config/secrets.env`** - Proxmox credentials, passwords (gitignored, create from secrets.env.example)

## First Time Setup

### Terraform configuration and VM specs

```bash
# 1. Copy secrets template
cp config/secrets.env.example config/secrets.env

# 2. Edit with your Proxmox credentials
nano config/secrets.env

# 3. Review infrastructure settings
nano config/infrastructure.env
```

### Ansible configuration and secrets vault

## Variable Structure
- `group_vars/all/base.yml`: Common settings and defaults
- `group_vars/all/vault.yml`: Encrypted sensitive data (passwords, keys)
- `inventory/*.yml`: Environment-specific overrides

A deployment.yml manifest containing details fro the recently created VM can be
generated with `scripts/generate-inventory.sh`.

Set up your Ansible vault

```bash
# 1. Configure vault
cp inventory/group_vars/all/vault.example.yml inventory/group_vars/all/vault.yml
ansible-vault encrypt inventory/group_vars/all/vault.yml

# 2. Edit vault
ansible-vault edit inventory/group_vars/all/vault.yml
```

# VM Provisioning

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

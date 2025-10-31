#!/bin/bash
set -e

# Determine project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== Loading Configuration ==="
# Source configuration files
source "${PROJECT_ROOT}/config/infrastructure.env"
source "${PROJECT_ROOT}/config/secrets.env"

echo "=== Loading SSH Agent ==="
eval "$(ssh-agent -s)"
ssh-add "${PROXMOX_SSH_KEY}"

echo "✓ Configuration loaded"
echo ""

# Change to terraform directory
cd "${PROJECT_ROOT}/terraform/make-debian"

echo "=== Running Terraform ==="
terraform init
echo ""

terraform plan
echo ""

terraform apply
echo ""

# Show the VM IP
echo "=== VM Information ==="
VM_IP=$(terraform output -raw vm_ip)
VM_NAME=$(terraform output -raw vm_name)
echo "VM Name: ${VM_NAME}"
echo "VM IP:   ${VM_IP}"
echo ""
echo "Next: Update Ansible inventory with:"
echo "  ${SCRIPT_DIR}/generate-inventory.sh"

#!/bin/bash
set -e

# Simple script to update Ansible inventory from Terraform outputs

# Determine project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Get Terraform outputs
cd "${PROJECT_ROOT}/terraform/make-debian"

VM_NAME=$(terraform output -raw vm_name)
VM_IP=$(terraform output -raw vm_ip)

# Check if we got an IP
if [[ "${VM_IP}" == "waiting for IP..." ]] || [[ -z "${VM_IP}" ]]; then
    echo "Error: VM IP not available yet"
    echo "Wait a moment and try again"
    exit 1
fi

echo "=== Installing web server ==="
echo "VM Name: ${VM_NAME}"
echo "VM IP:   ${VM_IP}"
echo ""

cd "${PROJECT_ROOT}/ansible"

ansible-playbook playbooks/15-web-server.yml \
  -i inventory/deployment.yml \
  --ask-vault-pass
  
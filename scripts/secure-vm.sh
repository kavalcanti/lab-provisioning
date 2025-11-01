#!/bin/bash
set -e

# Secure the VM after it has been provisioned

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

get_project_root
get_terraform_outputs

echo "=== Securing VM ==="
echo "VM Name: ${VM_NAME}"
echo "VM IP:   ${VM_IP}"
echo ""

run_ansible_playbook "playbooks/90-security.yml"
  
#!/bin/bash
set -e

# Simple script to update Ansible inventory from Terraform outputs

# Determine project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

get_project_root
get_terraform_outputs

echo "=== Installing web server ==="
echo "VM Name: ${VM_NAME}"
echo "VM IP:   ${VM_IP}"
echo ""

run_ansible_playbook "playbooks/15-web-server.yml"
  
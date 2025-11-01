#!/bin/bash
set -e

# Simple script to update Ansible inventory from Terraform outputs

# Determine project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

get_project_root
get_terraform_outputs

# Update inventory file
INVENTORY_FILE="${PROJECT_ROOT}/ansible/inventory/deployment.yml"

echo "Updating Ansible inventory..."
echo "  VM Name: ${VM_NAME}"
echo "  VM IP:   ${VM_IP}"

# Backup existing inventory
if [[ -f "${INVENTORY_FILE}" ]]; then
    cp "${INVENTORY_FILE}" "${INVENTORY_FILE}.backup"
fi

# Create new inventory
cat > "${INVENTORY_FILE}" << EOF
---
# Ansible Inventory - Auto-generated from Terraform
# Generated: $(date '+%Y-%m-%d %H:%M:%S')

all:
  children:
    servers:
      hosts:
        ${VM_NAME}:
          # Initial Connection (used for first connection)
          ansible_host: "${VM_IP}"
          ansible_user: "{{ user_root }}"
          ansible_port: "{{ ssh_port }}"
          ansible_password: "{{ vault_root_password }}"
          ansible_become_password: "{{ vault_devops_password }}"
          
          # Post-setup Connection
          sys_hostname: "${VM_NAME}"
          
      vars:
        # Environment specific overrides
        
        docker_users:
          - "{{ user_devops }}"
EOF

echo "Inventory updated: ${INVENTORY_FILE}"
echo ""
echo "Next: Run Ansible provisioning with:"
echo "  cd ${PROJECT_ROOT}/ansible"
echo "  ansible-playbook -i inventory/deployment.yml playbooks/90-provisioning.yml --ask-vault-pass"


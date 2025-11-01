#!/bin/bash
set -e

# Determine project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

get_project_root
load_config

echo "=== Running Terraform ==="
terraform init
echo ""

terraform plan
echo ""

terraform apply
echo ""

# Show the VM IP
echo "=== VM Information ==="
get_terraform_outputs
echo "VM Name: ${VM_NAME}"
echo "VM IP:   ${VM_IP}"
echo ""

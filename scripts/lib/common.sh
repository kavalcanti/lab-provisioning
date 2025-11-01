#!/bin/bash
# Shared library for lab-provisioning scripts

# Get project root directory
get_project_root() {
    if [[ -z "${PROJECT_ROOT}" ]]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "${script_dir}/../../" && pwd)"
    fi
    export PROJECT_ROOT
}

# Load configuration files
load_config() {
    get_project_root
    source "${PROJECT_ROOT}/config/infrastructure.env"
    source "${PROJECT_ROOT}/config/secrets.env"
}

# Get terraform outputs and export them as environment variables
get_terraform_outputs() {
    get_project_root
    
    local terraform_dir="${PROJECT_ROOT}/terraform/make-debian"
    
    cd "${terraform_dir}" || {
        echo "Error: Cannot access terraform directory: ${terraform_dir}" >&2
        exit 1
    }
    
    VM_NAME=$(terraform output -raw vm_name)
    VM_IP=$(terraform output -raw vm_ip)
    
    if [[ "${VM_IP}" == "waiting for IP..." ]] || [[ -z "${VM_IP}" ]]; then
        echo "Error: VM IP not available yet" >&2
        exit 1
    fi
    
    export VM_NAME VM_IP
}

# Run ansible playbook with common flags
run_ansible_playbook() {
    local playbook="${1}"
    get_project_root
    
    cd "${PROJECT_ROOT}/ansible" || exit 1
    
    ansible-playbook "${playbook}" \
        -i inventory/deployment.yml \
        --ask-vault-pass
}

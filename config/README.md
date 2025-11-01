# Configure VM details and secrets here!

This directory contains variables for most settings.
Provisioning is hard so there might be issues. 
Please do raise it in this repo if you find any!

## Files


### `infrastructure.yml`

Holds most TF_VAR_*s for VM specification.

### `secrets.env` 

Holds Proxmox host and auth creds. VM's cloud-init initial root
password must match value in ansible vault.
#!/bin/bash

# make base config
cd "$(dirname "$0")" && cd ../ansible

ansible-playbook playbooks/90-provisioning.yml \
  -i inventory/deployment.yml \
  --ask-vault-pass
  
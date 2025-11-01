[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/kavalcanti/lab-provisioning/blob/main/README.md)

# O que é esse repo?

Eu faço homelab há alguns anos e uso proxmox para subir VMs para os meus
projetos e stacks em casa. Tou cansado de fazer click-ops para subir VMs, então
fiz esse repo para automatizar esse processso.

## O que ele faz?

Cria uma nova máquina virtual no Proxmox com Terraform e implementa algumas
configurações de segurança. Há Ansible roles para instalar o docker e Nginx
também. 
Ele **não** gerencia várias VMs ou infra maior, nem armazena os detalhes
a longo prazo. Foi feito pra provisionar uma máquina só.

## Como ele faz?

Os scripts de conveniência estão na pasta `scripts/` e devem ser o caminho
principal para fazer tudo funcionar.

1. Criar uma VM Debian com Terraform.
`scripts/make-debian.sh` 

2. Cria um manifesto de deploy para o Ansible da VM recém criada.
`scripts/generate-inventory.sh` 

3. Roda configurações básicas de segurança. Só é possível executar uma vez.
`scripts/secure-vm.sh` 

4. Instala Docker e Docker compose, e configura UFW para o Docker
`scripts/install-docker.sh`

Isso vai bloquear o comportamento padrão do Docker de abrir portas no UFW, será
necessário adicionar regras específicas para este serviço com com `ufw allow
port` se for usar o formato servidor:PORTA.

5. Instala Nginx e configura UFW para tráfego web.
`scripts/install-nginx.sh`

# Antes de começar

## Criar um template com cloud-init.

Estou usando uma imagem cloud-init que precisa ser criada previamente no
Proxmox. Esta imagem será clonada pelo Terraform quando uma nova VM for
provisionada. Aqui estão as instruções para criar este template a partir de uma
imagem Debian 12. Os playbooks Ansible foram feitos pensando em Debian, então
devem funcionar em qualquer distro baseada em Debian.

Deve rodar no no servidor Proxmox.

``` bash
# Baixa a imagem cloud do Debian 12
cd /tmp
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# Importa o qcow2 como uma VM template com id 9000
qm create 9000 --name debian-12-cloud --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 debian-12-generic-amd64.qcow2 local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --agent enabled=1
qm set 9000 --serial0 socket
qm set 9000 --vga qxl 
# Converte para template
qm template 9000

# Limpa o download
rm debian-12-generic-amd64.qcow2
```

## Credenciais do Proxmox

Será necessário criar uma chave de API para o host do Proxmox. Recomendo criar
um novo usuário para esta automação em vez de utilizar o usuário root. Para
habilitar agentes QEMU é necessário acesso via SSH ao host proxmox. Para um
homelab é possível (e mais simples) utilizar o usuário root.

## Problemas conhecidos

Pode ser preciso configurar os storages do Proxmox (local-lvm e local) para
aceitarem snippets.

Verifique se há um storage para snippets no host Proxmox

```bash
pvesm status --content snippets 
```

Caso não esteja configurado, adicione snippets ao storage local

```bash
pvesm set local --content vztmpl,iso,backup,snippets
```

## Configuração

Todas as configurações existem no diretório `config/`:

- **`config/infrastructure.env`** - Especificações da VM e TF_VAR_*
- **`config/secrets.env`** - Credenciais para o host Proxmox (cópia de secrets.env.example)

## Setup inicial

### Configuração do Terraform

```bash
# 1. Copie o template do secrets.env
cp config/secrets.env.example config/secrets.env

# 2. Edite com suas credenciais do Proxmox
nano config/secrets.env

# 3. Defina as configurações para a VM
nano config/infrastructure.env
```

### Configuração do Ansible e vault.

#### Estrutura das variáveis
- `group_vars/all/base.yml`: Configurações comuns e defaults
- `group_vars/all/vault.yml`: Credenciais encriptadas
- `inventory/*.yml`: Variáveis específicas para o ambiente

Um manifesto deployment.yml contendo os detalhes da VM recem criada pode ser gerado com `scripts/generate-inventory.sh`.

Configure o Ansible vault

```bash
# 1. Copie o modelo
cp inventory/group_vars/all/vault.example.yml inventory/group_vars/all/vault.yml
ansible-vault encrypt inventory/group_vars/all/vault.yml

# 2. Edite o vault
ansible-vault edit inventory/group_vars/all/vault.yml
```

# Provisionando VM

```bash
# Rode o script de provisionamento
./scripts/make-debian.sh

# Depois da criar a VM, gere o manifesto de deployment
./scripts/generate-inventory.sh
```

Esse processo irá:
1. Carregar variáveis de ambiente de `config/*.env`
2. Rodar o Terraform para criar a VM
3. Exibir o IP da VM
4. Gerar um manifesto Ansible para VM



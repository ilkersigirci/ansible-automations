# Ansible Cheatsheet

Fast command reference for running this repo from the control node.

## Prerequisites

Make sure SSH works to the target host with the user expected by inventory.
For normal managed hosts that is usually `ilker`; for LXC bootstrap it is root:

```bash
ssh-copy-id ilker@192.168.2.X
ssh-copy-id root@192.168.2.X
```

Install the pinned toolchain and Galaxy collections:

```bash
uv sync --frozen
uv run ansible-galaxy collection install -r collections/requirements.yaml
```

For homeserver secret workflows, configure and unlock `rbw` locally:

```bash
rbw unlock
```

## Inventory Checks

Ping every host:

```bash
uv run ansible all -m ping
```

Ping one group:

```bash
uv run ansible homeserver -m ping
```

List hosts in a group:

```bash
uv run ansible homeserver --list-hosts
```

## Playbook Checks

Syntax-check a playbook:

```bash
uv run ansible-playbook playbooks/setup_debian.yml --syntax-check
```

Dry-run a playbook:

```bash
uv run ansible-playbook playbooks/setup_debian.yml --check --diff
```

Limit a run to one host:

```bash
uv run ansible-playbook playbooks/setup_debian.yml --limit gpu_coding
```

## Root-Level Access (Become)

Prompt for the `become` password when a command needs root privileges:

```bash
uv run ansible-playbook playbooks/setup_debian.yml -K
uv run ansible all -m apt -a "name=curl state=present" -b -K
```

`-K` is short for `--ask-become-pass`.

## Common Playbooks

Bootstrap Debian LXCs and Raspberry Pis:

```bash
uv run ansible-playbook playbooks/setup_debian.yml
```

Update packages and reboot when needed:

```bash
uv run ansible-playbook playbooks/apt_update_reboot.yml
```

Install Nerd Fonts on development devices:

```bash
uv run ansible-playbook playbooks/font.yml
```

Clone or update the homeserver Docker repository:

```bash
uv run ansible-playbook playbooks/homeserver/setup_repo.yml
```

Sync homeserver `.env` files from `rbw`:

```bash
uv run ansible-playbook playbooks/homeserver/sync_env.yml
```

Run a homeserver Docker action:

```bash
uv run ansible-playbook playbooks/homeserver/docker_manage.yml \
  -e homeserver_docker_manage_action=restart \
  --limit localhost,gpu
```

Supported Docker actions are documented in
[Homeserver Docker management](homeserver-docker-manage.md).

## Ad-Hoc Commands

Check disk usage:

```bash
uv run ansible all -a "df -h"
```

Check memory:

```bash
uv run ansible all -a "free -m"
```

Reboot one host:

```bash
uv run ansible gpu_coding -a "sudo reboot"
```

## SSH Agent Forwarding

`ansible.cfg` enables SSH agent forwarding by default:

```ini
[ssh_connection]
ssh_args = -o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s
```

If using the `rbw` SSH agent, point `SSH_AUTH_SOCK` at its socket:

```bash
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/rbw/ssh-agent-socket"
```

## Local Validation

Run pre-commit for changed files:

```bash
uv run pre-commit run --files README.md AGENTS.md docs/ARCHITECTURE.md docs/ANSIBLE_CHEATSHEET.md
```

Run all pre-commit hooks:

```bash
uv run pre-commit run --all-files
```

# ansible-automations

Personal Ansible automation for Debian-family machines, Raspberry Pis, LXCs,
development devices, and homeserver Docker hosts.

This repository is the control-plane glue: it bootstraps hosts, installs Docker,
clones the separate homeserver Docker repository, syncs secrets from `rbw` into
remote `.env` files, and runs the remote `docker-manage.sh` workflows.

## Quick Start

Install the Python/Ansible toolchain and required Galaxy collections:

```bash
uv sync --frozen
uv run ansible-galaxy collection install -r collections/requirements.yaml
```

Check that the configured inventory is reachable:

```bash
uv run ansible all -m ping
```

Syntax-check a playbook before touching hosts:

```bash
uv run ansible-playbook playbooks/setup_debian.yml --syntax-check
```

## Common Workflows

Bootstrap Debian LXCs and Raspberry Pis:

```bash
uv run ansible-playbook playbooks/setup_debian.yml
```

Limit a run to one host when you are making a targeted change:

```bash
uv run ansible-playbook playbooks/setup_debian.yml --limit gpu_coding
```

Sync homeserver `.env` files from `rbw`:

```bash
rbw unlock
uv run ansible-playbook playbooks/homeserver/sync_env.yml
```

Run a homeserver Docker action:

```bash
uv run ansible-playbook playbooks/homeserver/docker_manage.yml \
  -e homeserver_docker_manage_action=restart \
  --limit localhost,gpu
```

## Safety Notes

The default inventory points at real machines. Prefer `--limit`, `--check`, and
`--diff` while developing a change.

Secrets are read from `rbw` on the control node and written to remote `.env`
files. Do not commit generated `.env` files or copied secret values.

SSH agent forwarding is enabled in `ansible.cfg` because private repository
access is part of the homeserver workflow.

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Ansible cheatsheet](docs/ANSIBLE_CHEATSHEET.md)
- [Homeserver Docker management](docs/homeserver-docker-manage.md)
- [Agent index](AGENTS.md)

# ansible-automations

Personal Ansible automation for Debian-family machines, Raspberry Pis, LXCs,
development devices, and homeserver Docker hosts.

This repository is the control-plane glue: it bootstraps hosts, installs Docker,
clones the separate homeserver Docker repository, syncs secrets from `rbw` into
remote `.env` files, and runs homeserver Docker Compose actions.

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

Update a homeserver Docker checkout:

```bash
uv run ansible-playbook playbooks/homeserver/setup_repo.yml --limit localhost,gpu
```

Then sync its `.env` file from `rbw`:

```bash
rbw unlock
uv run ansible-playbook playbooks/homeserver/sync_env.yml --limit localhost,gpu
```

Finally, run a homeserver Docker Compose action:

```bash
uv run ansible-playbook playbooks/homeserver/docker_compose.yml \
  -e task=update \
  --limit gpu
```

### Oracle Bootstrap

```bash
uv run ansible-playbook playbooks/bootstrap_oracle_ubuntu.yml --limit remoteserver
uv run ansible-playbook playbooks/setup_debian.yml --limit remoteserver --ask-become-pass
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
- [Homeserver Docker Compose](docs/homeserver-docker-compose.md)
- [Homeserver Docker management](docs/homeserver-docker-manage.md)
- [Agent index](AGENTS.md)

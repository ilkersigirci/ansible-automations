# ansible-automations

Personal Ansible automation for Debian-family machines, Raspberry Pis, LXCs,
development devices, and homeserver Docker hosts.

This repository provisions hosts and owns the shared inventory. Application
deployment runs from the homeserver Docker repository on `gpu_coding`. See the
[homeserver deployment runbook](https://github.com/ilkersigirci/homeserver-docker/blob/main/docs/RUNNING.md#deploy-from-gpu_coding).

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

### Oracle Bootstrap

```bash
uv run ansible-playbook playbooks/bootstrap_oracle_ubuntu.yml --limit remoteserver
uv run ansible-playbook playbooks/setup_debian.yml --limit remoteserver --ask-become-pass
```

## Safety Notes

The default inventory points at real machines. Prefer `--limit`, `--check`, and
`--diff` while developing a change.

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Ansible cheatsheet](docs/ANSIBLE_CHEATSHEET.md)
- [Agent index](AGENTS.md)

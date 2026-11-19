# Architecture

This document follows the lightweight codemap style from
[matklad's ARCHITECTURE.md](https://matklad.github.io/2021/02/06/ARCHITECTURE.md.html):
short, stable, and focused on where things live.

## Bird's Eye View

This repository is an Ansible control repo for personal infrastructure. It runs
from a local control node and manages Debian-family targets across local network
hosts, Raspberry Pis, LXCs, and Tailscale-reachable homeserver machines.

The `homeserver-docker` repository owns Compose, service scripts and application
deployment. Its Ansible playbooks use this inventory and pinned toolchain on
`coding`. See the [homeserver deployment runbook](https://github.com/ilkersigirci/homeserver-docker/blob/main/docs/RUNNING.md#deploy-from-coding).

There is no long-running application here. `pyproject.toml` and `uv.lock` pin
the automation toolchain: Ansible, Ansible linting, and pre-commit support.

## Codemap

`ansible.cfg` defines the default inventory, role lookup path, host key policy,
and SSH agent forwarding.

`inventory/hosts.yaml` is the host topology. The main groups are `dev_devices`,
`lxcs`, `rpis`, and `homeserver`. The `debian_family` group explicitly
classifies Debian and Ubuntu hosts so OS-specific variables do not affect
future hosts running other operating systems. Proxmox-hosted Debian VMs belong
to its `debian_vm` child group.

`inventory/group_vars` holds shared data. `all.yml` defines the default managed
user, SSH public key, and default `ansible_user`. `debian_family.yml` pins the
managed Python interpreter to Debian's system Python. `lxcs.yml` switches LXC
setup to root. `inventory/host_vars` holds host-specific connection overrides.

`playbooks/setup_debian.yml` bootstraps Debian LXCs and Raspberry Pis with the
`common` and `docker_install` roles.

`playbooks/apt_update_reboot.yml` runs apt maintenance through `apt_update` and
reboots hosts when `/var/run/reboot-required` exists.

`playbooks/font.yml` installs selected Nerd Fonts on `dev_devices`.

`playbooks/rbw.yml` is a local `rbw` demonstration and smoke test.

`roles/common` creates the managed user, installs the SSH key, runs apt
maintenance, installs baseline packages, enables locales, sets the default
system locale, and writes `MY_HOSTNAME` to `/etc/environment`.

`roles/apt_update` is the reusable apt update, dist-upgrade, autoclean, and
autoremove sequence.

`roles/docker_install` installs Docker CE from Docker's deb822 apt repository,
writes daemon options, installs Python support for Docker API modules, adds the
managed user to the `docker` group, and ensures the Docker service is running.

`roles/iptables_allow_all` is a one-time Oracle Ubuntu bootstrap helper. It
installs iptables persistence support, writes an allow-all IPv4
`/etc/iptables/rules.v4`, and applies it with `iptables-restore`.

`roles/check_rbw` checks the controller vault session for the local smoke test
and homeserver deployment playbooks.

`roles/nerd_fonts` downloads selected Nerd Font files and refreshes the font
cache when installation changes.

`collections/requirements.yaml` declares `ansible.posix` for authorized keys.

## Main Flows

Bootstrap flow:

1. Pick hosts from `lxcs` or `rpis`.
2. Apply `common` for users, SSH, packages, locales, and hostname environment.
3. Apply `docker_install` for Docker Engine and daemon configuration.

Oracle Ubuntu bootstrap also applies `iptables_allow_all` once so the initial
cloud firewall rules do not interfere with later setup.

## Architectural Invariants

Inventory is the source of truth for host topology, host addresses, usernames
and static IPs. Avoid hardcoded host data inside roles.

Playbooks choose hosts and compose roles. Roles should remain reusable units of
behavior and should not assume a single host unless their name says so.

Resolved secrets must stay out of git. Secret values should be fetched from
`rbw` on the control node, hidden with `no_log` where practical, and written only
to their remote destination.

Ansible tasks should use fully qualified module names and stay idempotent where
the underlying operation allows it. When a command cannot be naturally
idempotent, define `changed_when` deliberately.

Agent-facing guidance belongs in `docs/`; `AGENTS.md` should remain a short
index to those docs.

## Cross-Cutting Concerns

Tooling is driven through `uv`. Prefer `uv run ansible...`, `uv run
ansible-playbook...`, and `uv run pre-commit...` so the pinned environment is
used consistently.

SSH agent forwarding is part of normal operation because private git access can
be needed from managed hosts.

Validation happens through Ansible syntax checks, pre-commit hooks, and
ansible-lint. For risky host changes, also use `--check`, `--diff`, and
`--limit`.

## Where To Change Things

Add or remove a host in `inventory/hosts.yaml`, then add shared values in
`inventory/group_vars` or host-specific values in `inventory/host_vars`.

Change default users, SSH keys, or baseline packages in `roles/common` and
`inventory/group_vars/all.yml`.

Change Docker installation behavior in `roles/docker_install`.

Change one-time Oracle Ubuntu allow-all iptables behavior in
`roles/iptables_allow_all`.

Add a new workflow as a playbook under `playbooks/`. If the behavior will be
reused, put it behind a role under `roles/`.

Update agent navigation by adding or changing docs under `docs/`, then link them
from `AGENTS.md`.

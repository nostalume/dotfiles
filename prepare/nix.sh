#!/usr/bin/env bash
set -eo pipefail

profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
if ! command -v nix >/dev/null && [ -r "$profile" ]; then
    . "$profile"
fi

if ! command -v nix >/dev/null; then
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install
    if [ -r "$profile" ]; then
        . "$profile"
    fi
fi

nix --version

#!/bin/bash

set -euo pipefail

case "$(uname -s)" in
    Linux)
        if command -v rage >/dev/null 2>&1; then
            exit 0
        fi

        if ! command -v nix >/dev/null 2>&1; then
            echo "Nix not found. Installing Determinate Nix..."
            curl -fsSL https://install.determinate.systems/nix | sh -s -- install
        fi

        if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
            . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        fi

        nix profile install nixpkgs#rage
        command -v rage >/dev/null
        ;;
    Darwin)
        echo "macOS is configuration-only: install Nix and rage explicitly before chezmoi apply."
        ;;
    *)
        echo "Unsupported platform: $(uname -s)" >&2
        exit 1
        ;;
esac

#!/bin/sh

case "$(uname -s)" in
    MINGW*|MSYS*)
        gh_windows='C:/Program Files/GitHub CLI/gh.exe'
        if [ -x "$gh_windows" ]; then
            exec "$gh_windows" auth git-credential "$@"
        fi
        ;;
esac

if command -v gh >/dev/null 2>&1; then
    exec gh auth git-credential "$@"
fi

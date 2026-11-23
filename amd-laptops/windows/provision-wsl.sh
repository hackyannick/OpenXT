#!/bin/bash
#
# Prepare the dedicated WSL2 distribution for OpenXT builds. Run as root
# from build-openxt.ps1 after the repository was cloned into the build
# user's workspace. Safe to run again.
#
# Usage: provision-wsl.sh <build-user>

set -euo pipefail

user="${1:?usage: provision-wsl.sh <build-user>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${here}/../docker/install-build-deps.sh"

# - default user, so plain `wsl -d <distro>` opens the build account
# - no Windows PATH: entries with spaces and Windows tools (e.g. a Windows
#   java.exe or python.exe) must not leak into BitBake's host tools
cat > /etc/wsl.conf << EOF
[user]
default=${user}

[interop]
appendWindowsPath=false
EOF

echo "${user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/openxt-build
chmod 0440 /etc/sudoers.d/openxt-build

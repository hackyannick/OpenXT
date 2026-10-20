#!/bin/bash
#
# Set up an OpenXT master workspace (repo + bordel) with the
# meta-openxt-elitebook-845g7 hardware layer enabled.
#
# Usage: setup-workspace.sh <workspace-dir> [build-id]
#
# Afterwards, follow the bordel README to create certificates, build and
# generate the installer ISO (see README.md in this directory).

set -euo pipefail

usage() {
    echo "Usage: $0 <workspace-dir> [build-id]" >&2
    exit 1
}

[ $# -ge 1 ] && [ $# -le 2 ] || usage

workspace="$1"
build_id="${2:-845g7}"
layer_name="meta-openxt-elitebook-845g7"
layer_src="$(cd "$(dirname "${BASH_SOURCE[0]}")/../${layer_name}" && pwd)"

for tool in repo git; do
    if ! command -v "${tool}" >/dev/null; then
        echo "Missing required tool: ${tool}" >&2
        exit 1
    fi
done

mkdir -p "${workspace}"
cd "${workspace}"

if [ ! -d .repo ]; then
    repo init -u https://github.com/OpenXT/openxt-manifest.git
fi
repo sync

# bordel links ${BASE_DIR}/layers into every build directory, so the layer
# only needs to appear there.
ln -sfn "${layer_src}" "layers/${layer_name}"

openxt/bordel/bordel -i "${build_id}" config --no-repo-branch

bblayers="build-${build_id}/conf/bblayers.conf"
if ! grep -q "${layer_name}" "${bblayers}"; then
    cat >> "${bblayers}" << EOT

# HP EliteBook 845 G7 (AMD Renoir) hardware enablement
BBLAYERS += "\${LAYERS_DIR}/${layer_name}"
EOT
fi

echo
echo "Workspace ready: ${workspace}/build-${build_id}"
echo "Next steps:"
echo "  cd ${workspace}"
echo "  openxt/bordel/bordel -i ${build_id} certs create all"
echo "  openxt/bordel/bordel -i ${build_id} build"
echo "  openxt/bordel/bordel -i ${build_id} deploy iso"

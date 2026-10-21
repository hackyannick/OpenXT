#!/bin/bash
#
# Set up an OpenXT master workspace (repo + bordel) with the
# meta-openxt-elitebook-845g7 hardware layer enabled.
#
# Usage: setup-workspace.sh <workspace-dir> [build-id]
#
# Environment:
#   OPENXT_THREADS  limit BitBake/make parallelism (default: all CPUs)
#
# Clone this repository inside <workspace-dir> if the build will run in
# bordel's Docker container: only the workspace is mounted there.
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

for tool in repo git realpath; do
    if ! command -v "${tool}" >/dev/null; then
        echo "Missing required tool: ${tool}" >&2
        exit 1
    fi
done

mkdir -p "${workspace}"
workspace="$(cd "${workspace}" && pwd)"
cd "${workspace}"

case "${layer_src}/" in
    "${workspace}/"*) ;;
    *)
        echo "Warning: ${layer_src} is outside ${workspace}; the layer will" >&2
        echo "not be visible inside bordel's Docker container." >&2
        ;;
esac

if [ ! -d .repo ]; then
    repo init -u https://github.com/OpenXT/openxt-manifest.git
fi
repo sync

# bordel links ${BASE_DIR}/layers into every build directory, so the layer
# only needs to appear there. Relative, so it also resolves in Docker.
ln -sfn "$(realpath --relative-to=layers "${layer_src}")" "layers/${layer_name}"

# rm_work keeps the build at roughly a third of the disk space.
openxt/bordel/bordel -i "${build_id}" config --no-repo-branch --rmwork

conf="build-${build_id}/conf"
if ! grep -q "${layer_name}" "${conf}/bblayers.conf"; then
    cat >> "${conf}/bblayers.conf" << EOT

# HP EliteBook 845 G7 (AMD Renoir) hardware enablement
BBLAYERS += "\${LAYERS_DIR}/${layer_name}"
EOT
fi

if [ -n "${OPENXT_THREADS:-}" ] && ! grep -q "^# OPENXT_THREADS" "${conf}/local.conf"; then
    cat >> "${conf}/local.conf" << EOT

# OPENXT_THREADS (setup-workspace.sh)
BB_NUMBER_THREADS = "${OPENXT_THREADS}"
PARALLEL_MAKE = "-j ${OPENXT_THREADS}"
EOT
fi

# Each webkitgtk compile job (unified sources) needs up to ~3 GB of RAM, and
# other recipes build at the same time; with one job per CPU the OOM killer
# stops the build. Allow one job per 4 GB, capped at the general parallelism.
if ! grep -q "^PARALLEL_MAKE_pn-webkitgtk" "${conf}/local.conf"; then
    mem_gb=$(( $(awk '/^MemTotal:/ { print $2 }' /proc/meminfo) / 1024 / 1024 ))
    jobs="${OPENXT_THREADS:-$(nproc)}"
    webkit_jobs=$(( mem_gb / 4 ))
    [ "${webkit_jobs}" -gt "${jobs}" ] && webkit_jobs="${jobs}"
    [ "${webkit_jobs}" -lt 1 ] && webkit_jobs=1
    cat >> "${conf}/local.conf" << EOT

# webkitgtk: one compile job per 4 GB RAM (${mem_gb} GB seen at setup)
PARALLEL_MAKE_pn-webkitgtk = "-j ${webkit_jobs}"
EOT
fi

echo
echo "Workspace ready: ${workspace}/build-${build_id}"
echo "Next steps:"
echo "  cd ${workspace}"
echo "  openxt/bordel/bordel -i ${build_id} certs create all"
echo "  openxt/bordel/bordel -i ${build_id} build"
echo "  openxt/bordel/bordel -i ${build_id} deploy iso"

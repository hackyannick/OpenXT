#!/bin/bash
#
# Run the OpenXT build steps inside the WSL2 distribution (as the build
# user). Every step can be run again; finished work is not redone.
#
# Usage: build-in-wsl.sh [setup|fetch|build|iso|all]   (default: all)
#
# Environment:
#   OPENXT_THREADS  BitBake/make parallelism (default: CPUs, at most one
#                   per 2 GB of RAM the WSL VM has)
#   OPENXT_SWAP_GB  minimum swap during the build (default: 16); a swap
#                   file /swapfile is added if WSL provides less

set -euo pipefail

step="${1:-all}"
workspace="${HOME}/openxt-workspace"
build_id="845g7"
layer_repo="${workspace}/OpenXT"

if [ -z "${OPENXT_THREADS:-}" ]; then
    mem_gb=$(( $(awk '/^MemTotal:/ { print $2 }' /proc/meminfo) / 1024 / 1024 ))
    OPENXT_THREADS=$(( mem_gb / 2 ))
    [ "${OPENXT_THREADS}" -gt "$(nproc)" ] && OPENXT_THREADS="$(nproc)"
    [ "${OPENXT_THREADS}" -lt 1 ] && OPENXT_THREADS=1
fi
export OPENXT_THREADS

# repo asks for an identity and colour output on first use.
git config --global user.name >/dev/null || git config --global user.name "OpenXT Builder"
git config --global user.email >/dev/null || git config --global user.email "build@localhost"
git config --global color.ui >/dev/null || git config --global color.ui auto

do_setup() {
    if [ ! -d "${workspace}/build-${build_id}" ]; then
        "${layer_repo}/amd-laptops/setup-workspace.sh" "${workspace}" "${build_id}"
    fi
    cd "${workspace}"
    if ! ls certs/*.pem >/dev/null 2>&1; then
        openxt/bordel/bordel -i "${build_id}" certs create all
    fi
}

do_fetch() {
    "${layer_repo}/amd-laptops/fetch-all.sh" "${workspace}" "${build_id}"
}

# Some compile steps need several GB each (GHC on xenmgr's generated RPC
# modules, webkitgtk, ...), and BitBake runs many at once. Without enough
# swap the OOM killer stops the build ("Killed", exit 137). WSL gives the VM
# only a small swap by default, so add a swap file on the distribution's
# disk. It survives on disk but must be switched on again after every WSL
# restart, so this runs before each build. Not fatal: without it the build
# just has less headroom.
swap_file="/swapfile"
swap_min_gb="${OPENXT_SWAP_GB:-16}"

ensure_swap() {
    local swap_kb
    swap_kb=$(awk '/^SwapTotal:/ { print $2 }' /proc/meminfo)
    if [ "$(( swap_kb / 1024 / 1024 ))" -ge "${swap_min_gb}" ]; then
        return 0
    fi
    if ! sudo swapon --show=NAME --noheadings | grep -qx "${swap_file}"; then
        if [ ! -f "${swap_file}" ]; then
            echo "Creating ${swap_min_gb} GB swap file ${swap_file} ..."
            if ! { sudo fallocate -l "${swap_min_gb}G" "${swap_file}" \
                   && sudo chmod 600 "${swap_file}" \
                   && sudo mkswap "${swap_file}" >/dev/null; }; then
                sudo rm -f "${swap_file}"
                echo "WARNING: could not create ${swap_file}; building without extra swap." >&2
                return 0
            fi
        fi
        sudo swapon "${swap_file}" \
            || echo "WARNING: could not enable ${swap_file}; building without extra swap." >&2
    fi
    free -h | sed -n '1,3p'
}

do_build() {
    ensure_swap
    cd "${workspace}"
    openxt/bordel/bordel -i "${build_id}" build
}

do_iso() {
    cd "${workspace}"
    openxt/bordel/bordel -i "${build_id}" deploy iso
}

echo "OpenXT build: step '${step}', ${OPENXT_THREADS} threads"
case "${step}" in
    setup) do_setup ;;
    fetch) do_setup; do_fetch ;;
    build) do_setup; do_build ;;
    iso)   do_iso ;;
    all)   do_setup; do_fetch; do_build; do_iso ;;
    *)     echo "Unknown step: ${step}" >&2; exit 1 ;;
esac

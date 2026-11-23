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

do_build() {
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

#!/bin/bash
#
# Run only the download (do_fetch) tasks of every image in the bordel
# build-manifest, keep going past failures and list every recipe whose
# sources could not be fetched. Run this before the long build so dead
# download links show up within minutes instead of hours into the build.
#
# Usage: fetch-all.sh <workspace-dir> [build-id]

set -uo pipefail

[ $# -ge 1 ] && [ $# -le 2 ] || { echo "Usage: $0 <workspace-dir> [build-id]" >&2; exit 1; }

build_dir="$1/build-${2:-845g7}"
log="${build_dir}/fetch-all.log"

cd "${build_dir}" || exit 1
# shellcheck disable=SC1091
. ./build_env

: > "${log}"
while read -r l; do
    if [ -z "${l%%#*}" ] || [ -n "${l##*bitbake*}" ]; then
        continue
    fi
    echo "=== ${l}" | tee -a "${log}"
    # No quotes: expands to e.g. MACHINE=xenclient-dom0 bitbake xenclient-dom0-image
    # shellcheck disable=SC2086
    env $l -k --runall=fetch 2>&1 | tee -a "${log}"
done < conf/build-manifest

echo
failed="$(grep -oE "Task \([^)]*:do_fetch\) failed" "${log}" | sort -u)"
if [ -n "${failed}" ]; then
    echo "Failed downloads:"
    echo "${failed}"
    echo
    echo "Details: grep -B5 'do_fetch: Fetcher failure\|Bitbake Fetcher Error' ${log}"
    exit 1
fi
echo "All sources fetched."

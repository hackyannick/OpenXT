#!/bin/bash
#
# Install everything an Ubuntu 20.04 (x86_64) host needs to build OpenXT
# master (Yocto dunfell). Used by the Dockerfile in this directory and by
# ../windows/build-openxt.ps1 (WSL2). Run as root; safe to run again.

set -euo pipefail

GHC_VERSION="${GHC_VERSION:-8.10.7}"
export DEBIAN_FRONTEND=noninteractive

apt-get -o Acquire::Retries=3 update
apt-get -o Acquire::Retries=3 install -yq \
    openssh-client openssl sed wget cvs subversion git coreutils \
    unzip texi2html texinfo docbook-utils gawk diffstat help2man make \
    gcc g++ gcc-multilib build-essential desktop-file-utils chrpath cpio \
    socat xz-utils screen tmux bash-completion python3 python3-pip \
    python3-pexpect python3-git python3-jinja2 iputils-ping \
    guilt acpica-tools quilt bin86 bcc libsdl1.2-dev liburi-perl \
    genisoimage policycoreutils vim rpm curl libncurses5-dev \
    libncursesw5 libtinfo5 libc6-dev-i386 libelf-dev xorriso mtools \
    dosfstools libgmp-dev file ca-certificates locales sudo \
    openjdk-8-jre-headless
rm -rf /var/lib/apt/lists/*

# OE scripts expect bash as /bin/sh.
echo "dash dash/sh boolean false" | debconf-set-selections
dpkg-reconfigure dash

# OpenXT's Haskell components are built with the host GHC.
if ! command -v ghc >/dev/null || ! ghc --numeric-version | grep -qx "${GHC_VERSION}"; then
    tmp="$(mktemp -d)"
    wget -q -P "${tmp}" "https://downloads.haskell.org/~ghc/${GHC_VERSION}/ghc-${GHC_VERSION}-x86_64-deb10-linux.tar.xz"
    tar -C "${tmp}" -xJf "${tmp}/ghc-${GHC_VERSION}-x86_64-deb10-linux.tar.xz"
    (cd "${tmp}/ghc-${GHC_VERSION}" && ./configure --prefix=/usr && make install)
    rm -rf "${tmp}"
fi

if [ ! -x /usr/local/bin/repo ]; then
    curl -sSf https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo
    chmod a+x /usr/local/bin/repo
fi

# bordel's images carry this link for prebuilt tools expecting /lib.
[ -e /lib/ld-linux-x86-64.so.2 ] || ln -s /lib64/ld-linux-x86-64.so.2 /lib/

locale-gen en_US.UTF-8

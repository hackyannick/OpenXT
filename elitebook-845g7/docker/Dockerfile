# x86_64 build environment for OpenXT master (Yocto dunfell).
#
# Based on bordel's openxt-master Dockerfile, but self-contained so the whole
# workspace (repo sync, config, build) can live inside a Docker volume.
# Ubuntu 20.04 is a supported dunfell build host.
#
# On Apple Silicon this runs through Rosetta (--platform linux/amd64).

FROM ubuntu:20.04

ARG UNAME=build
ARG UID=1000
ARG GID=1000
ARG GHC_VERSION=8.10.7

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -yq \
        openssh-client openssl sed wget cvs subversion git coreutils \
        unzip texi2html texinfo docbook-utils gawk diffstat help2man make \
        gcc g++ gcc-multilib build-essential desktop-file-utils chrpath cpio \
        socat xz-utils screen tmux bash-completion python3 python3-pip \
        python3-pexpect python3-git python3-jinja2 iputils-ping \
        guilt acpica-tools quilt bin86 bcc libsdl1.2-dev liburi-perl \
        genisoimage policycoreutils vim rpm curl libncurses5-dev \
        libncursesw5 libtinfo5 libc6-dev-i386 libelf-dev xorriso mtools \
        dosfstools libgmp-dev file ca-certificates locales sudo && \
    rm -rf /var/lib/apt/lists/* && \
    echo "dash dash/sh boolean false" | debconf-set-selections && \
    dpkg-reconfigure dash

# OpenXT's Haskell components are built with the host GHC.
RUN cd /tmp && \
    wget -q https://downloads.haskell.org/~ghc/${GHC_VERSION}/ghc-${GHC_VERSION}-x86_64-deb10-linux.tar.xz && \
    tar Jxf ghc-${GHC_VERSION}-x86_64-deb10-linux.tar.xz && \
    cd ghc-${GHC_VERSION} && \
    ./configure --prefix=/usr && \
    make install && \
    cd /tmp && rm -rf ghc-${GHC_VERSION}*

RUN curl -sSf https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# bordel's images carry this link for prebuilt tools expecting /lib.
RUN [ -e /lib/ld-linux-x86-64.so.2 ] || ln -s /lib64/ld-linux-x86-64.so.2 /lib/

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

RUN groupadd -g ${GID} ${UNAME} && \
    useradd -m -s /bin/bash -u ${UID} -g ${GID} ${UNAME} && \
    mkdir /work && chown ${UNAME}:${UNAME} /work

USER ${UNAME}
WORKDIR /work
ENTRYPOINT ["/bin/bash"]

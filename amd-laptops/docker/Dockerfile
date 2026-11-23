# x86_64 build environment for OpenXT master (Yocto dunfell).
#
# Based on bordel's openxt-master Dockerfile, but self-contained so the whole
# workspace (repo sync, config, build) can live inside a Docker volume.
# Ubuntu 20.04 is a supported dunfell build host.
#
# On Apple Silicon this runs through Rosetta (--platform linux/amd64).

# Override with --build-arg BASE_IMAGE=... to use a registry mirror, e.g.
# mirror.gcr.io/library/ubuntu:20.04 when Docker Hub is not reachable.
ARG BASE_IMAGE=ubuntu:20.04
FROM ${BASE_IMAGE}

ARG UNAME=build
ARG UID=1000
ARG GID=1000
ARG GHC_VERSION=8.10.7

# Shared with the WSL2 build (../windows/build-openxt.ps1).
COPY install-build-deps.sh /usr/local/sbin/install-build-deps.sh
RUN GHC_VERSION=${GHC_VERSION} /usr/local/sbin/install-build-deps.sh

ENV LANG=en_US.UTF-8

RUN groupadd -g ${GID} ${UNAME} && \
    useradd -m -s /bin/bash -u ${UID} -g ${GID} ${UNAME} && \
    mkdir /work && chown ${UNAME}:${UNAME} /work

USER ${UNAME}
WORKDIR /work
ENTRYPOINT ["/bin/bash"]

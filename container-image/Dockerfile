# syntax=docker/dockerfile:1
FROM ubuntu:noble-20250529

ENV MISE_POST=/root/post-mise.sh
ENV DEBIAN_FRONTEND=noninteractive
ENV FPM_VERSION=1.15.1
ENV GUM_DEB=/tmp/gum.deb
ENV GUM_VERSION=0.13.0
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV TERM=linux
ENV YQ_VERSION=4.40.5
ENV MISE_DATA_DIR="/mise"
ENV MISE_CONFIG_DIR="/mise"
ENV MISE_CACHE_DIR="/mise/cache"
ENV MISE_INSTALL_PATH="/usr/local/bin/mise"
ENV PATH="/mise/shims:$PATH"

COPY 01_nodoc /etc/dpkg/dpkg.conf.d/01_nodoc
COPY 01_norecommend /etc/apt/apt.conf.d/01_norecommend
COPY mise-config.toml /root/.config/mise/config.toml

# Install FPM.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN --mount=type=bind,source=post-mise.sh,target=${MISE_POST} \
    apt update && \
    apt -y dist-upgrade && \
    echo '===> Installing packages...' && \
    apt install -y \
        apt-transport-https \
        asciidoc \
        autoconf \
        bash-completion \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        fakeroot \
        file \
        git \
        gpg \
        gpg-agent \
        jq \
        libbz2-dev \
        libcairo2-dev \
        libcurl4 \
        libcurl4-openssl-dev \
        libdb-dev \
        libdbus-1-dev \
        libffi-dev \
        libgdbm6 \
        libgdbm-dev \
        libgirepository1.0-dev \
        libgmp-dev \
        liblzma-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libreadline6-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl3 \
        libssl-dev \
        libxml2 \
        libxml2-dev \
        libxmlsec1-dev \
        libyaml-dev \
        lsb-release \
        gnupg \
        patch \
        pkg-config \
        rpm \
        scdoc \
        software-properties-common \
        tar \
        tk-dev \
        uuid-dev \
        unzip \
        xclip \
        xsltproc \
        xz-utils \
        zlib1g-dev && \
    echo '===> Installing mise...' && \
    curl https://mise.run | sh && \
    mise version && \
    echo "===> Running ${MISE_POST}..." && \
    bash "${MISE_POST}" && \
    echo '===> Installing charmbracelet/gum...' && \
    apt install -y "${GUM_DEB}" && \
    echo "===> Making yq ${YQ_VERSION} executable..." && \
    chmod +x /usr/bin/yq && \
    echo "===> Installing fpm version ${FPM_VERSION}..." && \
    gem install fpm -v "${FPM_VERSION}" && \
    echo '===> making /data a safe git directory...' && \
    git config --global --add safe.directory /data && \
    echo '===> Cleaning up after apt...' && \
    apt autoremove -yqq --purge && \
    apt clean all && \
    rm -rf \
      /var/lib/apt/lists/* \
      /var/log/apt/* \
      /var/log/alternatives.log \
      /var/log/bootstrap.log \
      /var/log/dpkg.log \
      /var/tmp/* \
      /tmp/*

# Define working directory.
WORKDIR /data

ENTRYPOINT ["bash"]

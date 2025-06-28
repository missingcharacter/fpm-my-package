# syntax=docker/dockerfile:1
FROM ubuntu:noble-20250529

ENV ASDF_DIR=/root/.asdf
ENV ASDF_POST=/root/post-asdf.sh
ENV DEBIAN_FRONTEND=noninteractive
ENV FPM_VERSION=1.15.1
ENV GUM_DEB=/tmp/gum.deb
ENV GUM_VERSION=0.13.0
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV TERM=linux
ENV YQ_VERSION=4.40.5

COPY 01_nodoc /etc/dpkg/dpkg.conf.d/01_nodoc
COPY 01_norecommend /etc/apt/apt.conf.d/01_norecommend
COPY asdfrc /root/.asdfrc
COPY tool-versions /root/.tool-versions

# Install FPM.
RUN --mount=type=bind,source=post-asdf.sh,target=${ASDF_POST} \
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
    echo '===> Installing asdf...' && \
    git clone https://github.com/asdf-vm/asdf.git "${ASDF_DIR}" && \
    printf '\n. "${HOME}/.asdf/asdf.sh"\n' >> ~/.bashrc && \
    . "${HOME}/.asdf/asdf.sh" && \
    asdf update && \
    echo '===> Installing asdf plugins...' && \
    awk '{ print $1 }' "${HOME}/.tool-versions" | xargs -L1 asdf plugin add && \
    echo '===> Installing asdf runtimes...' && \
    asdf install && \
    echo '===> Running post-asdf.sh...' && \
    bash "${ASDF_POST}" && \
    echo '===> Installing charmbracelet/gum...' && \
    apt install -y /tmp/gum.deb && \
    echo "===> Installing yq version ${YQ_VERSION}..." && \
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

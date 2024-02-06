# Pull base image.
FROM ubuntu:jammy-20240111

LABEL org.opencontainers.image.source=https://github.com/missingcharacter/fpm-my-package
LABEL org.opencontainers.image.description="Container with ruby fpm and other tools for building packages."
LABEL org.opencontainers.image.licenses=MIT

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
ADD https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 /usr/bin/yq
ADD https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_amd64.deb ${GUM_DEB}

# Install FPM.
RUN --mount=type=bind,source=post-asdf.sh,target=${ASDF_POST} \
    echo '===> Checking for OS updates...' && \
    echo 'deb http://archive.ubuntu.com/ubuntu/ jammy-proposed restricted main multiverse universe' > /etc/apt/sources.list.d/jammy-proposed.list && \
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
        software-properties-common \
        tk-dev \
        uuid-dev \
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
    echo "===> Installing charmbracelet/gum..." && \
    apt install -y /tmp/gum.deb && \
    echo '===> Installing yq version ${YQ_VERSION}...' && \
    chmod +x /usr/bin/yq && \
    echo "===> Installing fpm version ${FPM_VERSION}..." && \
    gem install fpm -v "${FPM_VERSION}" && \
    echo '===> Cleaning up after apt ...' && \
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

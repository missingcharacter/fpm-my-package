# Pull base image.
FROM ruby:3.0.1-buster

ENV FPM_VERSION=1.12.0
ENV DEBIAN_FRONTEND=noninteractive

COPY 01_nodoc /etc/dpkg/dpkg.conf.d/01_nodoc

# Install FPM.
RUN echo "===> Installing fpm version ${FPM_VERSION} ..." && \
    gem install fpm -v "${FPM_VERSION}" && \
    echo '===> Checking for updates...' && \
    apt update && \
    apt install -y \
        asciidoc \
        bash-completion \
        build-essential \
        ca-certificates \
        cmake \
        fakeroot \
        git \
        libcurl4 \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2 \
        libxml2-dev \
        libssl1.1 \
        pkg-config \
        rpm \
        xclip \
        xsltproc && \
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

# Define entrypoint.
ENTRYPOINT ["bash"]

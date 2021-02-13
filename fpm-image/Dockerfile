# Pull base image.
FROM ruby:3.0.0-buster

ENV FPM_VERSION=1.12.0

COPY build-packages.sh /usr/local/bin/build-packages.sh

# Install FPM.
RUN echo "===> Making /usr/local/bin/build-packages.sh executable ..." \
  && export DEBIAN_FRONTEND='noninteractive' \
  && chmod +x /usr/local/bin/build-packages.sh \
  && echo "===> Installing fpm version ${FPM_VERSION} ..." \
  && gem install fpm -v "${FPM_VERSION}" \
  && echo "===> Checking for updates..." \
  && apt update \
  && apt install rpm fakeroot asciidoc xsltproc bash-completion build-essential cmake libcurl4 libcurl4-openssl-dev libssl-dev libxml2 libxml2-dev libssl1.1 pkg-config ca-certificates xclip -y \
  && echo "===> Cleaning up after apt ..." \
  && apt -q -y clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Define working directory.
WORKDIR /data

# Define entrypoint.
ENTRYPOINT ["bash"]

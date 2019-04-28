#
# FPM Dockerfile
#
# https://github.com/dockerfile/fpm
#

# Pull base image.
FROM ruby:2.6.3-stretch

COPY build-packages.sh /usr/local/bin/build-packages.sh

# Install FPM.
RUN echo "===> Making /usr/local/bin/build-packages.sh executable ..." \
  && chmod +x /usr/local/bin/build-packages.sh \
  && echo "===> Installing fpm version 1.11.0 ..." \
  && gem install fpm -v '1.11.0' \
  && echo "===> Checking for updates..." \
  && apt update \
  && apt install rpm -y \
  && echo "===> Cleaning up after apt ..." \
  && apt -q -y clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Define working directory.
WORKDIR /data

# Define entrypoint.
ENTRYPOINT ["bash"]

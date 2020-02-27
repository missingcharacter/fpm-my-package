#!/usr/bin/env bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
export GITROOT
. "${GITROOT}/lib/strict-mode"
strictMode
. "${GITROOT}/lib/utils"

# Make message functions available to 'parallel'
export -f msg_info
export -f msg_error
export -f strictMode
export -f gettoken

# Ensure dependencies are present
if [[ ! -x $(command -v git) || ! -x $(command -v curl) || ! -x $(command -v parallel) ]] ; then
    msg_error "[-] Dependencies unmet.  Please verify that the following are installed and in the PATH:  git, curl, docker, parallel" >&2
    msg_error "[-] For more on 'parallel' go to: https://www.gnu.org/software/parallel/" >&2
    exit 1
fi

PACKAGES=( $(ls built-packages/DEB/*) )

function upload_package () {
  # Enable bash's unofficial strict mode
  strictMode

  local PATH_TO_PACKAGE="${1}"
  local PACKAGE="${PATH_TO_PACKAGE##*/}"
  local FILENAME="${PACKAGE%.*}"
  local FILE_EXT="${PACKAGE##*.}"
  local PACKAGE_INFO="${GITROOT}/packages/$(echo ${FILENAME} | cut -d '_' -f1)"
  local PACKAGE_NAME="$(gettoken NAME ${PACKAGE_INFO})"
  PACKAGE_NAME="${PACKAGE_NAME//\'/}"
  local PACKAGE_VERSION="$(gettoken VERSION ${PACKAGE_INFO})"
  PACKAGE_VERSION="${PACKAGE_VERSION//\'/}"
  local DEB_ARCH="$(echo ${FILENAME} | cut -d '_' -f3)"
  local DEB_DISTROS='buster,bionic,eoan,focal'
  local DEB_COMPONENT='stable'
  local BINTRAY_BASE_URL='https://api.bintray.com/content'
  local BINTRAY_API_KEY="$(gettoken BINTRAY_API_KEY)"
  local BINTRAY_USER='missingcharacter'
  local HTTP_AUTH="${BINTRAY_USER}:${BINTRAY_API_KEY}"
  local BINTRAY_REPO='fpm-my-package'
  local UPLOAD_URL="${BINTRAY_BASE_URL}/${BINTRAY_USER}/${BINTRAY_REPO}/${PACKAGE_NAME}/${PACKAGE_VERSION}/pool/${PACKAGE_NAME}/${PACKAGE};deb_distribution=${DEB_DISTROS};deb_component=stable;deb_architecture=${DEB_ARCH}"

  curl -T "${PATH_TO_PACKAGE}" -u"${HTTP_AUTH}" "${UPLOAD_URL}"
}

# Make upload_package function available to 'parallel'
export -f upload_package

parallel -j+0 --eta 'upload_package {}' ::: "${PACKAGES[@]}"

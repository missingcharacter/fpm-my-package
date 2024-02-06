#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# shellcheck source=/dev/null
. "${HOME}/.asdf/asdf.sh"

THIS_SCRIPT=$(basename "${0}")
PADDING=$(printf %-${#THIS_SCRIPT}s " ")

function usage () {
    echo "Usage:"
    echo "${THIS_SCRIPT} -n <Name of package> -v <Version of package> -r <Release of package> -s <Source of package>"
    echo "${PADDING} -c <Creator of package>  -m <Maintainer of package> -l <License of package>"
    echo "${PADDING} -d <Description of package> -a <RPM dependencies separated by comma> -b <Debian dependencies separated by comma>"
    echo
    exit 1
}

ANSI_NO_COLOR=$'\033[0m'
function msg_info() {
  local GREEN=$'\033[0;32m'
  printf "%s\n" "${GREEN}${*}${ANSI_NO_COLOR}"
}

function string2array() {
  local STRING="${1}"
  local SEPARATOR="${2:-,}"
  tr "${SEPARATOR}" '\n' <<< "${STRING}"
}

function deps2args() {
  declare -a DEPS=( "${@}" )
  local DEPS_AS_STRING=""
  for i in "${DEPS[@]}"; do
    DEPS_AS_STRING="${DEPS_AS_STRING}-d '${i}' "
  done
  echo "${DEPS_AS_STRING}"
}

# Ensure dependencies are present
if [[ ! -x $(command -v fpm) || ! -x $(command -v rpm) || ! -x $(command -v dpkg-deb) ]] ; then
    echo "[-] Dependencies unmet.  Please verify that the following are installed and in the PATH:  fpm, rpm, dpkg-deb" >&2
    exit 1
fi

while getopts ":n:v:r:s:c:m:l:d:a:b:" opt; do
  case ${opt} in
    n)
      export NAME=${OPTARG} ;;
    v)
      export VERSION=${OPTARG} ;;
    r)
      export RELEASE=${OPTARG} ;;
    s)
      export SOURCE=${OPTARG} ;;
    c)
      export VENDOR=${OPTARG} ;;
    m)
      export MAINTAINER=${OPTARG} ;;
    l)
      export LICENSE=${OPTARG} ;;
    d)
      export DESCRIPTION=${OPTARG} ;;
    a)
      mapfile -t RPM_DEPENDENCIES < <(string2array "${OPTARG}") ;;
    b)
      mapfile -t DEB_DEPENDENCIES < <(string2array "${OPTARG}") ;;
    \?)
      usage ;;
    :)
      usage ;;
  esac
done

if [[ -z ${NAME:-""} ]] || [[ -z ${VERSION:-""} ]] || [[ -z ${RELEASE:-""} ]] || [[ -z ${SOURCE:-""} ]] || [[ -z ${VENDOR:-""} ]] || [[ -z ${MAINTAINER:-""} ]] || [[ -z ${LICENSE:-""} ]] || [[ -z ${DESCRIPTION:-""} ]]; then
  usage
fi

if [ -n "${DEB_DEPENDENCIES+x}" ] && [ -n "${RPM_DEPENDENCIES+x}" ]; then
  msg_info "Debian dependencies are ${DEB_DEPENDENCIES[*]}"
  msg_info "RPM dependencies are ${RPM_DEPENDENCIES[*]}"

  DEB_DEPS="$(deps2args "${DEB_DEPENDENCIES[*]}")"
  RPM_DEPS="$(deps2args "${RPM_DEPENDENCIES[*]}")"
else
  msg_info "No dependencies will be set"
  DEB_DEPS=""
  RPM_DEPS=""
fi

CUSTOM_SCRIPT="/data/custom/${NAME}"

if [[ -f "${CUSTOM_SCRIPT}" ]]; then
    bash "${CUSTOM_SCRIPT}"
else
  RPM_OPTS="fpm -s dir -t rpm -n ${NAME} -v ${VERSION} --license ${LICENSE} -a native --url ${SOURCE} --prefix '/usr/local/bin' --iteration ${RELEASE} ${RPM_DEPS} -m '${MAINTAINER}' --description '${DESCRIPTION}' -C ./${NAME}"
  DEB_OPTS="fpm -s dir -t deb -n ${NAME} -v ${VERSION} --license ${LICENSE} -a native --url ${SOURCE} --prefix '/usr/local/bin' --deb-no-default-config-files --iteration ${RELEASE} ${DEB_DEPS} -m '${MAINTAINER}' --description '${DESCRIPTION}' -C ./${NAME}"

  msg_info "Creating RPM"

  echo "fpm options for RPM are: ${RPM_OPTS}"

  eval "${RPM_OPTS}"

  rpm -qpi "${NAME}-${VERSION}-${RELEASE}.x86_64.rpm"

  msg_info "Moving RPM to tmp-files/RPM/"

  mv "${NAME}-${VERSION}-${RELEASE}.x86_64.rpm" tmp-files/RPM/

  msg_info "Creating DEB"

  echo "fpm options for DEB are: ${DEB_OPTS}"

  eval "${DEB_OPTS}"

  dpkg-deb -I "${NAME}_${VERSION}-${RELEASE}_amd64.deb"

  msg_info "Moving DEB to tmp-files/DEB/"

  mv "${NAME}_${VERSION}-${RELEASE}_amd64.deb" tmp-files/DEB/
fi

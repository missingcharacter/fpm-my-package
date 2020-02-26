#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

THIS_SCRIPT=$(basename $0)
PADDING=$(printf %-${#THIS_SCRIPT}s " ")

usage () {
    echo "Usage:"
    echo "${THIS_SCRIPT} -n <Name of package> -v <Version of package> -r <Release of package> -s <Source of package>"
    echo "${PADDING} -c <Creator of package>  -m <Maintainer of package> -l <License of package>"
    echo "${PADDING} -d <Description of package> -a <RPM dependencies separated by comma> -b <Debian dependencies separated by comma>"
    echo
    exit 1
}

msg_info () {
  local GREEN='\033[0;32m'
  local NC='\033[0m' # No Color
  printf "${GREEN}${@}${NC}\n"
}

# Ensure dependencies are present
if [[ ! -x $(which fpm) || ! -x $(which rpm) || ! -x $(which dpkg-deb) ]] ; then
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
      export RPM_DEPENDENCIES=${OPTARG} ;;
    b)
      export DEB_DEPENDENCIES=${OPTARG} ;;
    \?)
      usage ;;
    :)
      usage ;;
  esac
done

if [[ -z ${NAME:-""} ]] || [[ -z ${VERSION:-""} ]] || [[ -z ${RELEASE:-""} ]] || [[ -z ${SOURCE:-""} ]] || [[ -z ${VENDOR:-""} ]] || [[ -z ${MAINTAINER:-""} ]] || [[ -z ${LICENSE:-""} ]] || [[ -z ${DESCRIPTION:-""} ]]; then
  usage
fi

if [ ! -z "${DEB_DEPENDENCIES+x}" ] && [ ! -z "${RPM_DEPENDENCIES+x}" ]; then
  msg_info "Debian dependencies are ${DEB_DEPENDENCIES}"
  msg_info "RPM dependencies are ${RPM_DEPENDENCIES}"

  DEB_DEPS=""
  IFS=','
  for i in $(echo "${DEB_DEPENDENCIES}"); do
    DEB_DEPS="${DEB_DEPS}-d '${i}' "
  done
  IFS=$'\n\t'

  RPM_DEPS=""
  IFS=','
  for i in $(echo "${RPM_DEPENDENCIES}"); do
    RPM_DEPS="${RPM_DEPS}-d '${i}' "
  done
  IFS=$'\n\t'
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

  msg_info "Moving RPM to built-packages/RPM/"

  mv "${NAME}-${VERSION}-${RELEASE}.x86_64.rpm" built-packages/RPM/

  msg_info "Creating DEB"

  echo "fpm options for DEB are: ${DEB_OPTS}"

  eval "${DEB_OPTS}"

  dpkg-deb -I "${NAME}_${VERSION}-${RELEASE}_amd64.deb"

  msg_info "Moving DEB to built-packages/DEB/"

  mv "${NAME}_${VERSION}-${RELEASE}_amd64.deb" built-packages/DEB/
fi

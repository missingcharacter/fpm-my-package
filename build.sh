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

# Make these variables available to 'parallel'
export FPM_TAG='fpm-my-package:0.0.2'
export PACKAGES_DIR='packages/'
PACKAGES=$(ls ${PACKAGES_DIR})
export PACKAGES

# Ensure dependencies are present
if [[ ! -x $(command -v git) || ! -x $(command -v curl) || ! -x $(command -v docker) || ! -x $(command -v parallel) ]] ; then
    msg_error "[-] Dependencies unmet.  Please verify that the following are installed and in the PATH:  git, curl, docker, parallel" >&2
    msg_error "[-] For more on 'parallel' go to: https://www.gnu.org/software/parallel/" >&2
    exit 1
fi

function cleanup () {
  parallel -j+0 --eta 'msg_info "Deleting {1} directory and compressed file"; rm -rf "{1}_DOWN"; rm -rf {1}' ::: "${PACKAGES[@]}"
}

# Make cleanup function available to 'parallel'
export -f cleanup

# Make sure cleanup runs even if this script fails
trap cleanup EXIT

msg_info "Building fpm docker image"

cd fpm-image
docker build -f Dockerfile -t "${FPM_TAG}" .
cd -

function download_and_build () {
  # Enable bash's unofficial strict mode
  strictMode

  local PACKAGE_FILE=${1}

  for i in $(cat "${PACKAGES_DIR}${PACKAGE_FILE}"); do
    local "${i}"
  done

  if [[ -z ${NAME:-""} ]] || [[ -z ${VERSION:-""} ]] || [[ -z ${RELEASE:-""} ]] || [[ -z ${SOURCE:-""} ]] || [[ -z ${VENDOR:-""} ]] || [[ -z ${MAINTAINER:-""} ]] || [[ -z ${LICENSE:-""} ]] || [[ -z ${DESCRIPTION:-""} ]]; then
    msg_error "[-] Package file for ${PACKAGE_FILE} is missing some required variables. See this project's README for more details" >&2
    exit 1
  fi

  echo "Name is ${NAME}, Version is ${VERSION}, Release is ${RELEASE}"
  echo "Source is ${SOURCE}"
  echo "Maintainer is ${MAINTAINER}"
  echo "Vendor is ${VENDOR}, License is ${LICENSE}, Description is ${DESCRIPTION}"
  if [ ! -z "${DEB_DEPENDENCIES+x}" ] && [ ! -z "${RPM_DEPENDENCIES+x}" ]; then
    msg_info "Debian dependencies are ${DEB_DEPENDENCIES}"
    msg_info "RPM dependencies are ${RPM_DEPENDENCIES}"
    local DEP_OPTS="-a ${RPM_DEPENDENCIES} -b ${DEB_DEPENDENCIES}"
  else
    msg_info "No dependencies will be set"
    echo "Note: you need to set DEB_DEPENDENCIES and RPM_DEPENDENCIES or neither"
    local DEP_OPTS=""
  fi

  NAME=${NAME//\'/}
  DOWNLOADED_FILE="${NAME}_DOWN"

  msg_info "Downloading ${NAME} version ${VERSION}"

  curl -L "${SOURCE//\'/}" -o "${DOWNLOADED_FILE}"

  mkdir "${NAME}"

  msg_info "Extracting ${NAME} version ${VERSION}"

  case "$(file "${DOWNLOADED_FILE}")" in
    ${DOWNLOADED_FILE}:\ gzip\ compressed\ data*)
    tar -xzvf "${DOWNLOADED_FILE}" -C "${NAME}"
    ;;
    ${DOWNLOADED_FILE}:\ POSIX\ tar\ archive*)
    tar -xzvf "${DOWNLOADED_FILE}" -C "${NAME}"
    ;;
    ${DOWNLOADED_FILE}:\ Zip\ archive\ data*)
    unzip "${DOWNLOADED_FILE}" -d "${NAME}"
    ;;
    *)
    msg_error "Unknown file type: $(uname)" >&2
    cleanup
    exit 1
    ;;
  esac

  msg_info "Building ${NAME} version ${VERSION}"

  local FPM_OPTS="build-packages.sh -n ${NAME} -v ${VERSION} -r ${RELEASE} -s ${SOURCE} -c ${VENDOR} -l ${LICENSE} ${DEP_OPTS} -m ${MAINTAINER} -d ${DESCRIPTION}"

  msg_info "FPM_OPTS are: ${FPM_OPTS}"


  docker run --rm -v "${PWD}":/data ${FPM_TAG} -c "${FPM_OPTS}"
}

# Make download_and_build function available to 'parallel'
export -f download_and_build

parallel -j+0 --eta 'download_and_build {}' ::: "${PACKAGES[@]}"

cleanup

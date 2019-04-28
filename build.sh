#!/usr/bin/env bash
# Enable bash's unofficial strict mode
export GITROOT=$(git rev-parse --show-toplevel)
. ${GITROOT}/lib/strict-mode
strictMode

THIS_SCRIPT=$(basename $0)
PADDING=$(printf %-${#THIS_SCRIPT}s " ")
# Make these variables available to 'parallel'
export FPM_TAG='fpm-my-package:0.0.1'
export PACKAGES_DIR='packages/'
export PACKAGES=$(ls ${PACKAGES_DIR})

msg_info () {
  local GREEN='\033[0;32m'
  local NC='\033[0m' # No Color
  printf "${GREEN}${@}${NC}\n"
}

msg_error () {
  local LRED='\033[01;31m'
  local NC='\033[0m' # No Color
  printf "${LRED}${@}${NC}\n"
}

# Make message functions available to 'parallel'
export -f msg_info
export -f msg_error

# Ensure dependencies are present
if [[ ! -x $(which git) || ! -x $(which curl) || ! -x $(which docker) || ! -x $(which parallel) ]] ; then
    msg_error "[-] Dependencies unmet.  Please verify that the following are installed and in the PATH:  git, curl, docker, parallel" >&2
    msg_error "[-] For more on 'parallel' go to: https://www.gnu.org/software/parallel/" >&2
    exit 1
fi

cleanup () {
  parallel -j+0 --eta 'msg_info "Deleting {1} directory and compressed file"; rm -rf "{1}_DOWN"; rm -rf {1}' ::: ${PACKAGES[@]}
}

cleanup_untar () {
  local NAME=${1}
  echo "Moving binary to current working directory"
  mv ${NAME}*/${NAME} .
  echo "Removing empty directory"
  rmdir ${NAME}*/
}

# Make cleanup functions available to 'parallel'
export -f cleanup
export -f cleanup_untar

# Make sure cleanup runs even if this script fails
trap cleanup EXIT

msg_info "Building fpm docker image"

cd fpm-image
docker build -f Dockerfile -t ${FPM_TAG} .
cd -

download_and_build () {
  # Enable bash's unofficial strict mode
  . ${GITROOT}/lib/strict-mode
  strictMode

  local PACKAGE_FILE=${1}

  for i in $(cat ${PACKAGES_DIR}${PACKAGE_FILE}); do
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

  curl -L ${SOURCE//\'/} -o ${DOWNLOADED_FILE}

  msg_info "Extracting ${NAME} version ${VERSION}"

  case "$(file ${DOWNLOADED_FILE})" in
    ${DOWNLOADED_FILE}:\ gzip\ compressed\ data*)
    tar -xzvf ${DOWNLOADED_FILE}
    cleanup_untar ${NAME}
    ;;
    ${DOWNLOADED_FILE}:\ POSIX\ tar\ archive*)
    tar -xzvf ${DOWNLOADED_FILE}
    cleanup_untar ${NAME}
    ;;
    ${DOWNLOADED_FILE}:\ Zip\ archive\ data*)
    unzip ${DOWNLOADED_FILE}
    ;;
    *)
    msg_error "Unknown file type: $(uname)" >&2
    cleanup
    exit 1
    ;;
  esac

  msg_info "Building ${NAME} version ${VERSION}"

  FPM_OPTS="build-packages.sh -n ${NAME} -v ${VERSION} -r ${RELEASE} -s ${SOURCE} -c ${VENDOR} -l ${LICENSE} ${DEP_OPTS} -m ${MAINTAINER} -d ${DESCRIPTION}"

  msg_info "FPM_OPTS are: ${FPM_OPTS}"

  docker run --rm -v ${PWD}:/data ${FPM_TAG} -c "${FPM_OPTS}"
}

# Make download_and_build function available to 'parallel'
export -f download_and_build

parallel -j+0 --eta 'download_and_build {}' ::: ${PACKAGES[@]}

cleanup

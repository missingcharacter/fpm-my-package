#!/usr/bin/env bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
export GITROOT
# shellcheck source=./scripts/build-packages.sh
. "${GITROOT}/scripts/lib/strict-mode"
strictMode
# shellcheck source=./scripts/build-packages.sh
. "${GITROOT}/scripts/lib/utils"
# We source asdf to ensure that the correct version of fpm is used
# Also, this script should only be run inside the container
# shellcheck source=/dev/null
. "${HOME}/.asdf/asdf.sh"

THIS_SCRIPT=$(basename "${0}")
PADDING=$(printf %-${#THIS_SCRIPT}s " ")
declare -a DEPENDENCIES=(
  'file'
  'fpm'
  'mktemp'
  'rpm'
  'dpkg-deb'
  'tar'
  'unzip'
  'yq'
)

function usage () {
    echo "Usage:"
    echo "${THIS_SCRIPT} -f, --file <YAML file with package details>"
    echo "${PADDING} -i, --index <Index of package in file>"
    echo "${PADDING} -s, --source-file <Source file to package>"
    echo
    exit 1
}

# Ensure dependencies are present
for dep in "${DEPENDENCIES[@]}"; do
  if [[ ! -x $(command -v "${dep}") ]]; then
    msg_error "[-] Dependency unmet: ${dep}"
    msg_fatal "[-] Please verify that the following are installed and in the PATH: " "${DEPENDENCIES[@]}"
  fi
done

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -f|--file)
      PACKAGES_YAML="${2}"
      shift # past argument
      shift # past value
      ;;
    -i|--index)
      PACKAGE_INDEX="${2}"
      shift # past argument
      shift # past value
      ;;
    -s|--source-file)
      SOURCE_FILE="${2}"
      shift # past argument
      shift # past value
      ;;
    -*)
      msg_error "Unknown option ${1}"
      usage
      ;;
  esac
done

NAME="$(yq e ".packages[${PACKAGE_INDEX}].name" "${PACKAGES_YAML}")"
VERSION="$(yq e ".packages[${PACKAGE_INDEX}].version" "${PACKAGES_YAML}")"
RELEASE="$(yq e ".packages[${PACKAGE_INDEX}].release" "${PACKAGES_YAML}")"
SOURCE="$(yq e ".packages[${PACKAGE_INDEX}].source" "${PACKAGES_YAML}")"
MAINTAINER="$(yq e ".packages[${PACKAGE_INDEX}].maintainer" "${PACKAGES_YAML}")"
LICENSE="$(yq e ".packages[${PACKAGE_INDEX}].license" "${PACKAGES_YAML}")"
DESCRIPTION="$(yq e ".packages[${PACKAGE_INDEX}].description" "${PACKAGES_YAML}")"
NOARCH="$(yq e ".packages[${PACKAGE_INDEX}].noarch" "${PACKAGES_YAML}")"
DEB_ARCH="$(get_arch)"
ARCHITECTURE='native'
RPM_FILE_NAME="${NAME}-${VERSION}-${RELEASE}.$(uname -m).rpm"
DEB_FILE_NAME="${NAME}_${VERSION}-${RELEASE}_${DEB_ARCH}.deb"
if [[ "${NOARCH}" == 'true' ]]; then
  ARCHITECTURE='all'
  RPM_FILE_NAME="${NAME}-${VERSION}-${RELEASE}.noarch.rpm"
  DEB_FILE_NAME="${NAME}_${VERSION}-${RELEASE}_all.deb"
fi
declare -a RPM_DEPS=()
declare -a RPM_FLAGS=()
declare -a DEB_DEPS=()
declare -a DEB_FLAGS=()
declare -a FILES_FLAGS=()

while IFS= read -r dep; do
  if [[ -n ${dep} ]]; then
    RPM_DEPS+=('-d' "${dep}")
  fi
done < <(yq e ".packages[${PACKAGE_INDEX}].rpm_dependencies[]" "${PACKAGES_YAML}")

while IFS= read -r flag; do
  if [[ -n ${flag} ]]; then
    RPM_FLAGS+=("${flag}")
  fi
done < <(yq e ".packages[${PACKAGE_INDEX}].rpm_flags[]" "${PACKAGES_YAML}")

while IFS= read -r dep; do
  if [[ -n ${dep} ]]; then
    DEB_DEPS+=('-d' "${dep}")
  fi
done < <(yq e ".packages[${PACKAGE_INDEX}].deb_dependencies[]" "${PACKAGES_YAML}")

while IFS= read -r flag; do
  if [[ -n ${flag} ]]; then
    DEB_FLAGS+=("${flag}")
  fi
done < <(yq e ".packages[${PACKAGE_INDEX}].deb_flags[]" "${PACKAGES_YAML}")

EXTRACTED_FILE="$(extract_file "${SOURCE_FILE}" "${NAME}" "${VERSION}")"
export EXTRACTED_FILE

CUSTOM_SCRIPT="/data/scripts/custom/${NAME}"

if [[ -f "${CUSTOM_SCRIPT}" ]]; then
  # shellcheck source=/dev/null
  . "${CUSTOM_SCRIPT}" "${VERSION}" "${EXTRACTED_FILE}"
fi

# `eval` is used to expand the variables in the flags
while IFS= read -r flag; do
  if [[ -n ${flag} ]]; then
    FILES_FLAGS+=("$(eval "echo ${flag}")")
    msg_info "Adding flag" "${flag}"
    msg_info "Expanded flag" "$(eval "echo ${flag}")"
  fi
done < <(yq e ".packages[${PACKAGE_INDEX}].files_flags[]" "${PACKAGES_YAML}")

declare -a FPM_OPTS=(
  'fpm' '-s' 'dir' '-n' "${NAME}" '-v' "${VERSION}" '--license' "${LICENSE}"
  '-a' "${ARCHITECTURE}" '--url' "${SOURCE}" '--iteration' "${RELEASE}"
  '-m' "${MAINTAINER}" '--description' "${DESCRIPTION}"
)
declare -a RPM_OPTS=("${FPM_OPTS[@]}" '-t' 'rpm' "${RPM_DEPS[@]}"
  "${RPM_FLAGS[@]}" "${FILES_FLAGS[@]}")
declare -a DEB_OPTS=("${FPM_OPTS[@]}" '-t' 'deb' "${DEB_DEPS[@]}"
  "${DEB_FLAGS[@]}" "${FILES_FLAGS[@]}")

msg_info "Creating RPM"

msg_info "fpm options for RPM are:" "${RPM_OPTS[@]}"

"${RPM_OPTS[@]}"

rpm -qpi "${RPM_FILE_NAME}"

msg_info "Moving RPM to /data/tmp-files/RPM/"

mv "${RPM_FILE_NAME}" /data/tmp-files/RPM/

msg_info "Creating DEB"

msg_info "fpm options for DEB are:" "${DEB_OPTS[@]}"

"${DEB_OPTS[@]}"

dpkg-deb -I "${DEB_FILE_NAME}"

msg_info "Moving DEB to /data/tmp-files/DEB/"

mv "${DEB_FILE_NAME}" /data/tmp-files/DEB/

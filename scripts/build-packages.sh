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
declare -a DEPENDENCIES=("fpm" "rpm" "dpkg-deb")

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
    msg_fatal "[-] Please verify that the following are installed and in the PATH: ${DEPENDENCIES[*]}"
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
ARCH="$(get_arch)"
declare -a RPM_DEPS=()
declare -a DEB_DEPS=()

while IFS= read -r dep; do
  if [[ -n ${dep} ]]; then
    RPM_DEPS+=("${dep}")
  fi
done < <(yq e ".packages[${PACKAGE_INDEX}].rpm_dependencies[]" "${PACKAGES_YAML}")

while IFS= read -r dep; do
  if [[ -n ${dep} ]]; then
    DEB_DEPS+=("${dep}")
  fi
done < <(yq e ".packages[${PACKAGE_INDEX}].deb_dependencies[]" "${PACKAGES_YAML}")

EXTRACTED_FILE="$(extract_file "${SOURCE_FILE}" "${NAME}" "${VERSION}")"

CUSTOM_SCRIPT="/data/scripts/custom/${NAME}"

if [[ -f "${CUSTOM_SCRIPT}" ]]; then
    bash "${CUSTOM_SCRIPT}"
else
  declare -a FPM_OPTS=(
    'fpm' '-s' 'dir' '-n' "${NAME}" '-v' "${VERSION}" '--license' "${LICENSE}"
    '-a' 'native' '--url' "${SOURCE}" '--prefix' '/usr/local/bin'
    '--iteration' "${RELEASE}" '-m' "${MAINTAINER}" '--description' "${DESCRIPTION}"
  )
  declare -a RPM_OPTS=("${FPM_OPTS[@]}" '-t' 'rpm' "${RPM_DEPS[@]}"
    '-C' "./${EXTRACTED_FILE}")
  declare -a DEB_OPTS=("${FPM_OPTS[@]}" '-t' 'deb' "${DEB_DEPS[@]}"
    '-C' "./${EXTRACTED_FILE}")

  msg_info "Creating RPM"

  msg_info "fpm options for RPM are: ${RPM_OPTS[*]}"

  "${RPM_OPTS[@]}"

  rpm -qpi "${NAME}-${VERSION}-${RELEASE}.$(uname -m).rpm"

  msg_info "Moving RPM to tmp-files/RPM/"

  mv "${NAME}-${VERSION}-${RELEASE}.$(uname -m).rpm" tmp-files/RPM/

  msg_info "Creating DEB"

  msg_info "fpm options for DEB are: ${DEB_OPTS[*]}"

  "${DEB_OPTS[@]}"

  dpkg-deb -I "${NAME}_${VERSION}-${RELEASE}_${ARCH}.deb"

  msg_info "Moving DEB to tmp-files/DEB/"

  mv "${NAME}_${VERSION}-${RELEASE}_${ARCH}.deb" tmp-files/DEB/
fi

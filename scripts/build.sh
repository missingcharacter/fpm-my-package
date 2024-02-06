#!/usr/bin/env bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
export GITROOT
# shellcheck source=./scripts/build.sh
. "${GITROOT}/scripts/lib/strict-mode"
strictMode
# shellcheck source=./scripts/build.sh
. "${GITROOT}/scripts/lib/utils"

# Make message functions available to 'parallel'
export ANSI_NO_COLOR
export -f msg_info
export -f msg_error
export -f msg_fatal
export -f strictMode
export -f strictModeFail

# Make these variables available to 'parallel'
export FPM_TAG='fpm-my-package:0.0.3'
export PACKAGES_YAML="${GITROOT}/packages.yaml"
NUMBER_OF_PACKAGES=$(yq e '.packages | length' "${PACKAGES_YAML}")
declare -a REQUIRED_FIELDS=("name" "version" "release" "source" "vendor" "license" "description")
declare -a DEPENDENCIES=("git" "curl" "docker" "parallel")
export  REQUIRED_FIELDS

# Ensure dependencies are present
for dep in "${DEPENDENCIES[@]}"; do
  if [[ ! -x $(command -v "${dep}") ]]; then
    msg_error "[-] Dependency unmet: ${dep}"
    msg_error "[-] Please verify that the following are installed and in the PATH:  git, curl, docker, parallel"
    msg_fatal "[-] For more on 'parallel' go to: https://www.gnu.org/software/parallel/"
  fi
done

function cleanup () {
  parallel -j+0 --eta 'msg_info "Deleting {1} directory and compressed file"; rm -rf "{1}_DOWN"; rm -rf {1}' ::: "$(yq e ".packages[].name" packages.yaml)"
}

# Make cleanup function available to 'parallel'
export -f cleanup

# Make sure cleanup runs even if this script fails
trap cleanup EXIT

msg_info "Building fpm docker image"

cd container-image || exit 1
docker build -f Dockerfile -t "${FPM_TAG}" .
cd - || exit 1

function download_and_build () {
  # Enable bash's unofficial strict mode
  strictMode

  local packages_yaml="${1}"
  local index="${2}"
  local name version release source vendor maintainer license description \
      downloaded_file fpm_opts
  name="$(yq e ".packages[${index}].name" "${packages_yaml}")"
  version="$(yq e ".packages[${index}].version" "${packages_yaml}")"
  release="$(yq e ".packages[${index}].release" "${packages_yaml}")"
  source="$(yq e ".packages[${index}].source" "${packages_yaml}")"
  maintainer="$(yq e ".packages[${index}].maintainer" "${packages_yaml}")"
  license="$(yq e ".packages[${index}].license" "${packages_yaml}")"
  description="$(yq e ".packages[${index}].description" "${packages_yaml}")"

  for field in "${REQUIRED_FIELDS[@]}"; do
    if [[ "$(yq e ".packages[${index}].${field}" "${packages_yaml}")" == 'null' ]]; then
      msg_fatal "[-] Package configuration for ${name} is missing the ${field} field. See this project's README for more details"
    fi
  done

  msg_info "Name is ${name}, Version is ${version}, Release is ${release}"
  msg_info "Source is ${source}"
  msg_info "Maintainer is ${maintainer}"
  msg_info "Vendor is ${vendor}, License is ${license}, Description is ${description}"

  downloaded_file="$(rev <<< "${source}" | cut -d '/' -f 1 | rev)"

  msg_info "Downloading ${name} version ${version}"

  curl -L "${source}" -o "${GITROOT}/${downloaded_file}"

  mkdir "${name}"

  msg_info "Extracting ${name} version ${version}"

  case "$(file "${downloaded_file}")" in
    ${downloaded_file}:\ gzip\ compressed\ data*)
    tar -xzvf "${downloaded_file}" -C "${NAME}"
    ;;
    ${downloaded_file}:\ POSIX\ tar\ archive*)
    tar -xzvf "${downloaded_file}" -C "${NAME}"
    ;;
    ${downloaded_file}:\ Zip\ archive\ data*)
    unzip "${downloaded_file}" -d "${NAME}"
    ;;
    *)
    cleanup
    msg_fatal "Unknown file type: $(uname)"
    ;;
  esac

  msg_info "Building ${name} version ${version}"
  fpm_opts="build-packages.sh -n ${name} -v ${version} -r ${release}"
  fpm_opts+=" -s ${source} -c ${vendor} -l ${license}"

  msg_info "fpm_opts are: ${fpm_opts}"
  docker run --rm \
      --entrypoint 'bash' \
      -v "${GITROOT}":/data \
      ${FPM_TAG} -c "${fpm_opts}"
}

# Make download_and_build function available to 'parallel'
export -f download_and_build

# shellcheck disable=SC2016
parallel -j+0 --eta 'download_and_build ${PACKAGES_YAML} {}' ::: "$(seq 0 "$((NUMBER_OF_PACKAGES-1))")"

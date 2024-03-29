#!/usr/bin/env bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
export GITROOT
# shellcheck source=./scripts/main.sh
. "${GITROOT}/scripts/lib/strict-mode"
strictMode
# shellcheck source=./scripts/main.sh
. "${GITROOT}/scripts/lib/utils"

# Make functions available to 'parallel'
export REQUIRED_FIELDS
export -f download_and_build
export -f join_by
export -f msg_info
export -f msg_error
export -f msg_fatal
export -f strictMode
export -f strictModeFail

# Make these variables available to 'parallel'
USER_IMAGE='missingcharacter/fpm-my-package'
TAG="$(get_tag "${USER_IMAGE}")"
export FPM_TAG="ghcr.io/${USER_IMAGE}:${TAG}"
export PACKAGES_YAML="${GITROOT}/packages.yaml"
NUMBER_OF_PACKAGES=$(yq e '.packages | length' "${PACKAGES_YAML}")
declare -a DEPENDENCIES=(
  'curl'
  'cut'
  'docker'
  'git'
  'gum'
  'parallel'
  'rev'
  'yq'
)

# Ensure dependencies are present
for dep in "${DEPENDENCIES[@]}"; do
  if [[ ! -x $(command -v "${dep}") ]]; then
    msg_error "[-] Dependency unmet: ${dep}"
    msg_error "[-] Please verify that the following are installed and in the PATH: " "${DEPENDENCIES[@]}"
    msg_fatal "[-] For more on 'parallel' go to: https://www.gnu.org/software/parallel/"
  fi
done

# shellcheck disable=SC2016
parallel -j+0 --eta 'download_and_build ${PACKAGES_YAML} {} ${FPM_TAG}' ::: "$(seq 0 "$((NUMBER_OF_PACKAGES-1))")"

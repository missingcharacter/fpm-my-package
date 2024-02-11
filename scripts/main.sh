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
export ANSI_NO_COLOR
export REQUIRED_FIELDS
export -f download_and_build
export -f msg_info
export -f msg_error
export -f msg_fatal
export -f strictMode
export -f strictModeFail

# Make these variables available to 'parallel'
export FPM_TAG='ghcr.io/missingcharacter/fpm-my-package:0.0.3'
export PACKAGES_YAML="${GITROOT}/packages.yaml"
NUMBER_OF_PACKAGES=$(yq e '.packages | length' "${PACKAGES_YAML}")
declare -a DEPENDENCIES=("git" "curl" "docker" "parallel")

# Ensure dependencies are present
for dep in "${DEPENDENCIES[@]}"; do
  if [[ ! -x $(command -v "${dep}") ]]; then
    msg_error "[-] Dependency unmet: ${dep}"
    msg_error "[-] Please verify that the following are installed and in the PATH:  git, curl, docker, parallel"
    msg_fatal "[-] For more on 'parallel' go to: https://www.gnu.org/software/parallel/"
  fi
done

# shellcheck disable=SC2016
parallel -j+0 --eta 'download_and_build ${PACKAGES_YAML} {} ${FPM_TAG}' ::: "$(seq 0 "$((NUMBER_OF_PACKAGES-1))")"

#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

function confirm_install() {
  local runtime="${1}"
  local version="${2}"
  echo "Checking ${runtime} ${version}..."
  case "${runtime}" in
    "golang")
      if grep -q "${version}" <(go version); then
        return 0
      fi
      ;;
    "python")
      if grep -q "${version}" <(python -V); then
        return 0
      fi
      ;;
    "ruby")
      if grep -q "${version}" <(ruby -v); then
        return 0
      fi
      ;;
    "rust")
      if grep -q "${version}" <(rustc --version); then
        return 0
      fi
      ;;
    *)
      echo "Runtime ${runtime} not supported"
      return 1
      ;;
  esac
  return 1
}

while IFS= read -r runtimeVersion; do
  if [[ -n ${runtimeVersion} ]]; then
    runtime="$(cut -d ' ' -f1 <<<"${runtimeVersion}")"
    version="$(cut -d ' ' -f2 <<<"${runtimeVersion}")"
    if ! confirm_install "${runtime}" "${version}"; then
      echo "${runtime} with version ${version} is not installed"
      exit 1
    fi
  fi
done <"${HOME}/.tool-versions"

echo "Updating pip packages"
pip3 list --outdated --local --format=json | jq -r '.[] | "\(.name)==\(.latest_version)"' | grep --color=auto -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U

echo "Updating gems"
gem update --system
gem update

echo "reshim all plugins"
asdf reshim

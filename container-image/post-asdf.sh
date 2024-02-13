#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

function get_os() {
  local kernel_name
  kernel_name="$(uname)"
  case "${kernel_name}" in
    Linux)
      echo -n 'linux'
      ;;
    Darwin)
      echo -n 'darwin'
      ;;
    *)
      echo "Sorry, ${kernel_name} is not supported." >&2
      exit 1
      ;;
  esac
}

function get_arch() {
  case "$(uname -m)" in
    armv5*) echo -n "armv5";;
    armv6*) echo -n "armv6";;
    armv7*) echo -n "armv7";;
    aarch64) echo -n "arm64";;
    x86) echo -n "386";;
    x86_64) echo -n "amd64";;
    i686) echo -n "386";;
    i386) echo -n "386";;
  esac
}

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

OS="$(get_os)"
ARCH="$(get_arch)"
# YQ_VERSION, GUM_VERSION, GUM_DEB are defined in Dockerfile
echo "Downloading yq ${YQ_VERSION} and gum ${GUM_VERSION}"
curl -sL \
    "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_${OS}_${ARCH}" \
    -o /usr/bin/yq
curl -sL \
    "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_${ARCH}.deb" \
    -o "${GUM_DEB}"


echo "Updating pip packages"
# if no packages are outdate just move on
(
  pip3 list --outdated --local --format=json | jq -r '.[] | "\(.name)==\(.latest_version)"' | grep --color=auto -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U
) || true

echo "Updating gems"
gem update --system
gem update

echo "reshim all plugins"
asdf reshim

#!/usr/bin/env bash

set -Eeuo pipefail

: "${NIVIN_PASSWORD:?NIVIN_PASSWORD must be set to enable SSH password login}"
: "${AZP_URL:?AZP_URL must be set to the Azure DevOps organization URL}"
: "${AZP_TOKEN:?AZP_TOKEN must be set to an Azure DevOps PAT}"

AZP_POOL="${AZP_POOL:-Default}"
AZP_AGENT_NAME="${AZP_AGENT_NAME:-$(hostname)}"
AZP_AGENT_VERSION="${AZP_AGENT_VERSION:-4.261.0}"
AZP_WORK="${AZP_WORK:-/azp/_work}"
AZP_AGENT_DIR="${AZP_AGENT_DIR:-/azp/agent}"

printf 'nivin:%s\n' "${NIVIN_PASSWORD}" | chpasswd
unset NIVIN_PASSWORD
ssh-keygen -A
mkdir -p /run/sshd
/usr/sbin/sshd

case "${AZP_URL}" in
  http://*|https://*) ;;
  *) echo "AZP_URL must start with http:// or https://" >&2; exit 1 ;;
esac

mkdir -p "${AZP_AGENT_DIR}" "${AZP_WORK}"
chown -R azp:azp "${AZP_AGENT_DIR}" "${AZP_WORK}"
cd "${AZP_AGENT_DIR}"

if [[ ! -x ./config.sh ]]; then
  archive="vsts-agent-linux-arm64-${AZP_AGENT_VERSION}.tar.gz"
  url="https://download.agent.dev.azure.com/agent/${AZP_AGENT_VERSION}/${archive}"
  tmp_archive="$(mktemp)"
  trap 'rm -f "${tmp_archive}"' EXIT

  echo "Downloading Azure Pipelines agent ${AZP_AGENT_VERSION}..."
  curl --fail --location --retry 5 --retry-delay 2 --silent --show-error \
    --output "${tmp_archive}" "${url}"
  tar --extract --gzip --file "${tmp_archive}" --strip-components=0
  chown -R azp:azp "${AZP_AGENT_DIR}"
  rm -f "${tmp_archive}"
  trap - EXIT
fi

cleanup() {
  if [[ -s /run/sshd.pid ]]; then
    kill -TERM "$(cat /run/sshd.pid)" 2>/dev/null || true
  fi
  su --shell /bin/bash --command \
    'cd "$AZP_AGENT_DIR" && ./config.sh remove --unattended --auth pat --token "$AZP_TOKEN"' \
    azp >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

su --shell /bin/bash --command \
  'cd "$AZP_AGENT_DIR" && ./config.sh \
    --unattended \
    --url "$AZP_URL" \
    --auth pat \
    --token "$AZP_TOKEN" \
    --pool "$AZP_POOL" \
    --agent "$AZP_AGENT_NAME" \
    --work "$AZP_WORK" \
    --replace \
    --acceptTeeEula && exec ./run.sh' \
  azp

# Azure DevOps ARM64 self-hosted agent

This repository builds an Ubuntu 22.04 container for an Azure DevOps self-hosted
agent. The image includes the Azure Pipelines agent runtime and common build
dependencies; the agent is downloaded and registered when the container starts.
The image runs as the unprivileged `azp` user and supports `linux/arm64` (and,
when built with the included workflow, `linux/amd64`).

## Build

```sh
docker build --platform linux/arm64 -t azure-linux-arm64-agent:local .
```

The agent version defaults to `4.261.0` and can be overridden at build time:

```sh
docker build --build-arg AZP_AGENT_VERSION=4.261.0 \
  --platform linux/arm64 -t azure-linux-arm64-agent:local .
```

## Run locally

Set the organization URL and PAT outside the image. Do not add a PAT to the
Dockerfile, a compose file committed to source control, or an image layer.

```sh
export AZP_URL="https://dev.azure.com/your-organization"
export AZP_TOKEN="your-pat"
docker run --rm --name azure-agent \
  -e AZP_URL \
  -e AZP_TOKEN \
  -e AZP_POOL=Default \
  -e AZP_AGENT_NAME="$(hostname)-arm64" \
  azure-linux-arm64-agent:local
```

`AZP_POOL` defaults to `Default`, and `AZP_AGENT_NAME` defaults to the
container hostname. The entrypoint removes the agent registration when the
container stops. Use a persistent volume at `/azp/_work` if retaining task
working data between container replacements is required.

## Azure DevOps token permissions

Create a dedicated Azure DevOps personal access token (PAT) for the agent.
Select the minimum **Agent Pools: Read & manage** scope. The PAT must be
authorized for the target organization and the agent pool must already exist.
Treat the token like a password and provide it only at runtime.

## GitHub Container Registry

Publishing happens automatically when a GitHub Release is published. The
workflow uses Docker Buildx to publish both `linux/amd64` and `linux/arm64`
to:

```text
ghcr.io/<repository-owner>/azure-linux-arm64-agent:<release-tag>
ghcr.io/<repository-owner>/azure-linux-arm64-agent:latest
```

The workflow grants `packages: write` to `GITHUB_TOKEN`; no registry secret is
stored in the image. To pull the image:

```sh
docker pull ghcr.io/<repository-owner>/azure-linux-arm64-agent:latest
```

After the first publication, open the package's **Package settings** page on
GitHub and change **Danger Zone → Change package visibility** to **Public**:

```text
https://github.com/users/<repository-owner>/packages/container/azure-linux-arm64-agent/settings
```

Once the package is public, no registry login is required for pulls:

```sh
docker pull ghcr.io/<repository-owner>/azure-linux-arm64-agent:latest
```

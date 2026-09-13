FROM ubuntu:22.04

ARG TARGETARCH
ARG AZP_AGENT_VERSION=4.261.0

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    AZP_WORK=/azp/_work

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        git \
        jq \
        libicu70 \
        libkrb5-3 \
        liblttng-ust1 \
        libssl3 \
        libunwind8 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash --uid 1000 azp \
    && mkdir -p "${AZP_WORK}" \
    && chown -R azp:azp /azp

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER azp
WORKDIR /azp
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

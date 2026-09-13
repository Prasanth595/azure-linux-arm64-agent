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
        openssh-server \
        sudo \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash --uid 1000 azp \
    && useradd --create-home --shell /bin/bash nivin \
    && usermod --append --groups sudo nivin \
    && passwd --lock nivin \
    && printf 'nivin ALL=(ALL) ALL\n' > /etc/sudoers.d/nivin \
    && chmod 0440 /etc/sudoers.d/nivin \
    && mkdir -p "${AZP_WORK}" \
    && chown -R azp:azp /azp

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /azp
EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

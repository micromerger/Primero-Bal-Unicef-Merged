
# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

ARG BUILD_REGISTRY
ARG POSTGRES_VERSION=15.6
ARG ALPINE_VERSION=3.19
FROM ${BUILD_REGISTRY}postgres:${POSTGRES_VERSION}-alpine${ALPINE_VERSION}

# TODO:
# If you are updating `POSTGRES_VERSION` or `ALPINE_VERSION`,
# run: `docker scout cves primero/postgres:my-tag` to verify whether the versions of the security packages
# listed in SECURITY_UPDATED_PACKAGES are still necessary.
ENV SECURITY_UPDATED_PACKAGES="openssl busybox libxml2 musl musl-utils libxslt"

RUN set -euox pipefail \
        ; apk update \
        ; apk add --no-cache $SECURITY_UPDATED_PACKAGES \
        ; rm -rf /var/cache/apk/*

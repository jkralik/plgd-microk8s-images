FROM docker.io/library/mongo:7.0.40@sha256:296832068f49a66237019ca965879c0c6bc7f2ab0b29b02c57cbe11ce692f7f2

ADD overlay.tar.gz /
COPY --chmod=0755 .build/mongod /usr/bin/mongod
COPY --chmod=0755 .build/mongos /usr/bin/mongos
COPY --chmod=0755 yq /opt/bitnami/common/bin/yq

ENV PATH="/opt/bitnami/mongodb/bin:/opt/bitnami/common/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    BITNAMI_APP_NAME=mongodb APP_VERSION=7.0.40 OS_ARCH=arm64 OS_NAME=linux HOME=/.mongodb
LABEL org.opencontainers.image.source="https://github.com/jkralik/plgd-microk8s-images" \
      org.opencontainers.image.title="MongoDB Pi 4, Bitnami chart compatible" \
      org.opencontainers.image.version="7.0.40-pi4" \
      org.opencontainers.image.description="Unofficial Cortex-A72 server with recovered Bitnami 8.0.13 initialization scripts"
WORKDIR /opt/bitnami/mongodb
USER 1001
ENTRYPOINT ["/opt/bitnami/scripts/mongodb/entrypoint.sh"]
CMD ["/opt/bitnami/scripts/mongodb/run.sh"]

ARG MONGODB_IMAGE
FROM ${MONGODB_IMAGE}
ADD theme.tar /theme/
LABEL org.opencontainers.image.source="https://github.com/jkralik/plgd-microk8s-images" \
      org.opencontainers.image.title="plgd Keycloak theme migration bootstrapper" \
      org.opencontainers.image.version="0.0.1"
USER 1001

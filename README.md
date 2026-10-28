# plgd MicroK8s ARM64 images

Native ARM64 / Raspberry Pi 4 images preserving the MongoDB and Keycloak theme
used by the migrated plgd MicroK8s installation.

## Preserved production images

These tags are registry copies of the working containerd images, not new builds:

| Image | Original OCI manifest SHA256 |
| --- | --- |
| `ghcr.io/jkralik/mongodb-bitnami-pi4:7.0.40` | `acd207f27c4a79946daa6e8ca7bb8df4bee76cfd566f6b7fcd65e122f2ef14bb` |
| `ghcr.io/jkralik/keycloak-theme-pi4:pi-migration-20261027` | `8f06d2c3517f9160c64941590d49be5ceb3c9cff81743264beb3f29399b5cd9a` |

Deploy using the digest, not a mutable build tag. No database files, Kubernetes
Secrets or cluster exports are included in this repository.

## Build

On native Linux ARM64, with Bash, curl, tar, sha256sum and Docker:

```sh
bash scripts/build.sh
bash scripts/smoke-test.sh \
  ghcr.io/jkralik/mongodb-bitnami-pi4:7.0.40-rebuild \
  ghcr.io/jkralik/keycloak-theme-pi4:0.0.1-rebuild
```

For native Buildah instead of Docker:

```sh
sudo env CONTAINER_ENGINE=buildah bash scripts/build.sh
```

`IMAGE_PREFIX` and `VERSION_SUFFIX` control output names. Publishing is explicit:

```sh
docker login ghcr.io
docker push ghcr.io/jkralik/mongodb-bitnami-pi4:7.0.40-rebuild
docker push ghcr.io/jkralik/keycloak-theme-pi4:0.0.1-rebuild
```

[GitHub Actions](.github/workflows/images.yml) builds on a native ARM64 runner,
tests fresh MongoDB initialization and theme integrity, then publishes
`7.0.40-build-<commit>` and `0.0.1-build-<commit>` tags using `GITHUB_TOKEN`.
It does not overwrite the preserved production tags or automatically deploy.
Hosted ARM runners are newer than Cortex-A72: test rebuilt images on the Pi 4
before switching production.

## Inputs and provenance

- [MongoDB Dockerfile](mongodb/Dockerfile): pinned official MongoDB 7.0.40
  Jammy ARM64 base. Stock `mongod`/`mongos` require a newer CPU; they are replaced
  with [themattman's unofficial Pi 4 release](https://github.com/themattman/mongodb-raspberrypi-binaries/releases/tag/r7.0.40-rpi-unofficial).
  Downloads are SHA256-checked before extraction.
- `mongodb/overlay.tar.gz`: recovered immutable filesystem layer
  `sha256:097c2c35164d84554ba58353c22fd93b2aa25e0c26992fcee4dcb44ad047af4c`
  from the working image. Contains Bitnami 8.0.13 initialization scripts,
  configuration templates, ARM64 wait-for-port, OpenSSL 1.1 libraries,
  empty runtime directories, and original license notices. It is not a dump of
  a running container or its volumes.
- `mongodb/yq`: recovered ARM64 mikefarah/yq v4.44.3, SHA256-pinned.
- `keycloak-theme/theme.tar`: original migration build input containing only
  `plgd-keycloak-theme-0.0.1.jar` (SHA256
  `660ae58caf2d519e92a7285935c5c874bb3fbd9dae4fa6b3c7a216d212aa86a3`).
  Upstream: [plgd-dev/keycloak-theme](https://github.com/plgd-dev/keycloak-theme).
  The bootstrapper deliberately retains the original MongoDB-based shell image
  and UID 1001; it supplies `/theme/*` to the Keycloak init container.

All local binary inputs and downloads are covered by
[checksums.sha256](checksums.sha256). Rebuilds reproduce the runtime composition,
**not** the historical image digest: original build timestamps and the original
overlay build recipe are unavailable. This is not a source rebuild of MongoDB,
Bitnami utilities, OpenSSL or the theme JAR.

## Compatibility and licensing

This is an unofficial compatibility image, not a vendor-supported Bitnami build.
MongoDB initialization scripts come from 8.0.13 but the server is 7.0.40.
Do not use it to downgrade an existing MongoDB 8 database. Keep tested backups
and validate replica-set/authentication behavior for any new deployment.

Third-party components retain their own licenses and notices: MongoDB SSPL
(`LICENSE-Community.txt` in the upstream archive and overlay), Bitnami scripts
and wait-for-port Apache-2.0, yq MIT, OpenSSL's notices under
`/usr/share/doc/libssl1.1/copyright`, and theme dependency licenses inside the JAR.
The base image also carries its original package license notices. This
repository does not relicense those components.

## Cluster integration

The `try-plgd-cloud` and `mock-plgd-cloud` Argo Applications use these MongoDB
Helm values, including the immutable digest:

```yaml
mongodb:
  image:
    registry: ghcr.io
    repository: jkralik/mongodb-bitnami-pi4
    tag: 7.0.40
    digest: sha256:acd207f27c4a79946daa6e8ca7bb8df4bee76cfd566f6b7fcd65e122f2ef14bb
```

This covers both the MongoDB server and its `log-dir` init container. Keycloak's
`keycloak-auth-template-bootstrapper` init container uses the preserved theme
image with the digest listed above. Its Helm `startupProbe` is enabled with
`initialDelaySeconds: 30`, `periodSeconds: 10`, `timeoutSeconds: 5` and
`failureThreshold: 90`: Quarkus provider preparation on the CPU-limited Pi can
exceed the old five-minute liveness delay. Readiness and normal liveness checks
remain in place after startup.

The upstream hub chart hardcodes an obsolete nginx image for mock OAuth's
`init-sign-keys`; it has no image override. That Deployment instead uses the
preserved GHCR MongoDB image (for Bash/OpenSSL), with existing Argo
`RespectIgnoreDifferences` exceptions. Its original two signing keys are
preserved in the immutable Kubernetes Secret `mock-oauth-signing-keys`. A
Helm-declared extra Secret volume is mounted read-only into the init container,
which copies the keys to the existing `/keys` emptyDir before initialization.
Both keys were compared byte-for-byte before and after the rollout. Do not
delete that Secret or rotate it without planning token invalidation.

**GitOps boundary:** this repository builds images; it is not the Git source
for those Applications. Their inline Helm values are stored in Argo CD.
Mock OAuth's init image, security context, command and volume mounts remain
live Deployment overrides protected by narrow ignore rules. Argo sync
preserves them, but deleting/recreating the Deployment from the unmodified
upstream chart alone will not restore those overrides. Keep the Application
configuration and signing Secret in your private cluster backup; never commit
their credentials here.

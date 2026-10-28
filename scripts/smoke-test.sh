#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mongo="${1:?Usage: smoke-test.sh MONGODB_IMAGE THEME_IMAGE}"
theme="${2:?Usage: smoke-test.sh MONGODB_IMAGE THEME_IMAGE}"
docker run --rm --entrypoint mongod "$mongo" --version | grep -F 'db version v7.0.40'
actual="$(docker run --rm --entrypoint sha256sum "$theme" /theme/plgd-keycloak-theme-0.0.1.jar)"
[[ "$actual" == '660ae58caf2d519e92a7285935c5c874bb3fbd9dae4fa6b3c7a216d212aa86a3  /theme/plgd-keycloak-theme-0.0.1.jar' ]]
cid="$(docker run --detach --env ALLOW_EMPTY_PASSWORD=yes "$mongo")"
trap 'docker logs "$cid"; docker rm --force --volumes "$cid" >/dev/null' EXIT
for ((i=0; i<90; i++)); do
    if docker exec "$cid" mongosh --quiet --eval 'quit(db.adminCommand({ping:1}).ok === 1 ? 0 : 1)' >/dev/null 2>&1; then
        docker exec "$cid" mongosh --quiet --eval \
            'const d=db.getSiblingDB("image_smoke"); d.check.insertOne({value:42}); quit(d.check.findOne().value === 42 ? 0 : 1)'
        exit 0
    fi
    if [[ "$(docker inspect --format '{{.State.Running}}' "$cid")" != true ]]; then
        echo 'MongoDB exited during initialization.' >&2
        exit 1
    fi
    sleep 2
done
echo 'MongoDB did not become ready within 180 seconds.' >&2
exit 1

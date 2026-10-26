#!/bin/sh
# Einziger Befehl, den der GitHub-Actions-Deploy-Key auf dem DMZ-Host ausführen
# darf. Liegt dort als /usr/local/bin/manga-deploy und wird über den Forced
# Command in ~manga-deploy/.ssh/authorized_keys per sudo aufgerufen.
# Installation: scripts/deploy/setup-dmz.sh
#
# Zieht das neueste API-Image, startet nur manga_api neu und wartet auf healthy.
set -eu

SERVICE=manga_api
CONTAINER=vacation_manga_api

cd /srv/vacation
logger -t manga-deploy "Deploy gestartet"

docker compose pull --quiet "$SERVICE"
docker compose up -d --no-deps "$SERVICE"

status=starting
for _ in $(seq 1 30); do
  status=$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER")
  [ "$status" = healthy ] && break
  [ "$status" = unhealthy ] && break
  sleep 2
done

if [ "$status" != healthy ]; then
  logger -t manga-deploy "Deploy fehlgeschlagen: $status"
  echo "Container ist nicht healthy (Status: $status)" >&2
  docker logs --tail 50 "$CONTAINER" >&2
  exit 1
fi

# Der Workflow vergleicht diese Zeile mit dem gebauten Commit
revision=$(docker inspect -f '{{index .Config.Labels "org.opencontainers.image.revision"}}' "$CONTAINER")
logger -t manga-deploy "Deploy ok, Revision ${revision:-unbekannt}"
echo "revision=${revision}"

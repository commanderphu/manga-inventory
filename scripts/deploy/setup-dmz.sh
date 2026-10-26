#!/bin/bash
# Richtet den Deploy-Zugang für GitHub Actions auf dem DMZ-Host ein.
# Lokal ausführen (nicht auf dem Server): scripts/deploy/setup-dmz.sh
#
# Was entsteht:
#   - System-User manga-deploy, ohne Passwort, NICHT in der docker-Gruppe
#   - /usr/local/bin/manga-deploy (= scripts/deploy/manga-deploy.sh)
#   - sudoers-Regel: manga-deploy darf genau dieses eine Skript als root
#   - SSH-Key mit restrict + Forced Command — egal was der Client schickt,
#     es läuft nur manga-deploy. Kein Shell, kein Port-Forwarding, kein PTY.
#   - GitHub-Environment "production" (nur main) mit den Secrets
#     DMZ_SSH_HOST, DMZ_SSH_KEY, DMZ_KNOWN_HOSTS
#
# Der private Schlüssel existiert danach nur noch als GitHub-Secret.
set -euo pipefail

SSH_TARGET=${SSH_TARGET:-dmz}             # Admin-Zugang aus ~/.ssh/config
PUBLIC_HOST=${PUBLIC_HOST:-46.225.163.35} # so erreicht der GitHub-Runner den Host
REPO=${REPO:-commanderphu/manga-inventory}
ENVIRONMENT=production

here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "==> Deploy-Key erzeugen"
ssh-keygen -q -t ed25519 -N "" -C "github-actions@manga-inventory" -f "$tmp/key"

echo "==> Server einrichten ($SSH_TARGET)"
scp -q "$here/manga-deploy.sh" "$tmp/key.pub" "$SSH_TARGET:/tmp/"
ssh -t "$SSH_TARGET" 'set -e
  sudo install -o root -g root -m 755 /tmp/manga-deploy.sh /usr/local/bin/manga-deploy
  id manga-deploy >/dev/null 2>&1 || sudo useradd --system --create-home --shell /bin/sh manga-deploy
  sudo passwd -l manga-deploy >/dev/null
  echo "manga-deploy ALL=(root) NOPASSWD: /usr/local/bin/manga-deploy" \
    | sudo tee /etc/sudoers.d/manga-deploy >/dev/null
  sudo chmod 440 /etc/sudoers.d/manga-deploy
  sudo visudo -cf /etc/sudoers.d/manga-deploy
  sudo install -d -o manga-deploy -g manga-deploy -m 700 /home/manga-deploy/.ssh
  echo "restrict,command=\"sudo -n /usr/local/bin/manga-deploy\" $(cat /tmp/key.pub)" \
    | sudo tee /home/manga-deploy/.ssh/authorized_keys >/dev/null
  sudo chown manga-deploy:manga-deploy /home/manga-deploy/.ssh/authorized_keys
  sudo chmod 600 /home/manga-deploy/.ssh/authorized_keys
  rm -f /tmp/manga-deploy.sh /tmp/key.pub'

echo "==> Host-Key von $PUBLIC_HOST festhalten"
ssh-keyscan -t ed25519 "$PUBLIC_HOST" 2>/dev/null > "$tmp/known_hosts"
[ -s "$tmp/known_hosts" ] || { echo "ssh-keyscan lieferte nichts" >&2; exit 1; }
ssh-keygen -lf "$tmp/known_hosts"
echo "    Vergleich (Server):"
ssh "$SSH_TARGET" 'ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub'

echo "==> Zugang testen (löst einen echten Deploy des aktuellen :latest aus)"
ssh -i "$tmp/key" -o IdentitiesOnly=yes -o UserKnownHostsFile="$tmp/known_hosts" \
  "manga-deploy@$PUBLIC_HOST"

echo "==> GitHub-Environment $ENVIRONMENT anlegen (nur Branch main)"
gh api -X PUT "repos/$REPO/environments/$ENVIRONMENT" \
  -F 'deployment_branch_policy[protected_branches]=false' \
  -F 'deployment_branch_policy[custom_branch_policies]=true' >/dev/null
gh api -X POST "repos/$REPO/environments/$ENVIRONMENT/deployment-branch-policies" \
  -f name=main -f type=branch >/dev/null 2>&1 || true

echo "==> Secrets setzen"
gh secret set DMZ_SSH_HOST    -R "$REPO" -e "$ENVIRONMENT" --body "$PUBLIC_HOST"
gh secret set DMZ_SSH_KEY     -R "$REPO" -e "$ENVIRONMENT" < "$tmp/key"
gh secret set DMZ_KNOWN_HOSTS -R "$REPO" -e "$ENVIRONMENT" < "$tmp/known_hosts"

echo "==> Fertig. Privater Schlüssel wird lokal gelöscht."

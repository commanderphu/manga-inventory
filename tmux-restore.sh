#!/bin/bash

# Stellt das Manga-Inventory-Fenster der tmux-Session "PhuDev" wieder her
# (Stand 26.10.2026):
#
#   claude --resume Manga-Iventory | zsh (Projektordner)
#                                  | ssh dmz: Logs von manga_api
#
# Läuft PhuDev schon, kommt das Fenster dazu; sonst wird die Session angelegt.
# Das Layout ist der exakte String aus `tmux list-windows`.

SESSION="PhuDev"
WINDOW="claude"
PROJECT="$(cd "$(dirname "$0")" && pwd)"
LAYOUT='0856,189x50,0,0{95x50,0,0,35,93x50,96,0[93x25,96,0,36,93x24,96,26,37]}'

if tmux has-session -t "$SESSION" 2>/dev/null; then
    TARGET=$(tmux new-window -P -F '#{window_id}' -t "$SESSION" -n "$WINDOW" -c "$PROJECT")
else
    tmux new-session -d -s "$SESSION" -n "$WINDOW" -c "$PROJECT" -x 189 -y 50
    TARGET=$(tmux display-message -p -t "$SESSION" '#{window_id}')
fi

# Links: Claude-Session dieses Projekts
tmux send-keys -t "$TARGET".0 'claude --resume Manga-Iventory' C-m

# Rechts oben: Shell im Projekt, rechts unten: API-Logs auf dmz.
# Nach Ctrl-C bleibt man in einer Shell auf dmz statt rauszufliegen.
tmux split-window -h -t "$TARGET" -c "$PROJECT"
tmux split-window -v -t "$TARGET".1 -c "$HOME"
tmux send-keys -t "$TARGET".2 "ssh -t dmz 'sudo docker compose -f /srv/vacation/docker-compose.yml logs -f manga_api; exec \$SHELL -l'" C-m

tmux select-layout -t "$TARGET" "$LAYOUT"
tmux select-pane -t "$TARGET".0
tmux select-window -t "$TARGET"

# Aus einer laufenden tmux-Session heraus umschalten statt verschachteln
if [ -n "$TMUX" ]; then
    tmux switch-client -t "$SESSION"
else
    tmux attach-session -t "$SESSION"
fi

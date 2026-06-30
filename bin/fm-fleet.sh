#!/usr/bin/env bash
# fm-fleet.sh - attach a human viewer to the crew tmux session so the captain can
# watch live workers. Each crewmate/secondmate runs in its own tmux window named
# fm-<id>; fm-spawn also tags each window with an @fm_label user option carrying a
# readable "project · task" description. This script ensures the crew session
# exists, tunes a descriptive status bar for that session only, then attaches.
#
# Usage: bin/fm-fleet.sh [session]
#   session defaults to "firstmate" - the dedicated session fm-spawn uses when
#   firstmate runs outside tmux. Pass a name to target a different crew session.
#
# Run it from a NORMAL terminal tab/window (e.g. a second VS Code terminal), not
# from inside firstmate's own pane. Switch windows once attached with `Ctrl-b w`
# (window picker) or `Ctrl-b n`/`p`. Detach with `Ctrl-b d`; it leaves the workers
# running untouched.
set -eu

SES=${1:-firstmate}

# Ensure the crew session exists so there is always something to attach to, even
# before any worker has been dispatched.
if ! tmux has-session -t "$SES" 2>/dev/null; then
  tmux new-session -d -s "$SES"
fi

# Each worker window: show its @fm_label (project · task) if present, else the raw
# window name. All options are session-scoped (no -g), so the captain's global tmux
# config is never touched and these settings die with the session.
LABEL='#{?#{@fm_label},#{@fm_label},#W}'
tmux set-option -t "$SES" status on
tmux set-option -t "$SES" status-interval 5
tmux set-option -t "$SES" status-left '#[bold] fleet #[default] '
tmux set-option -t "$SES" status-left-length 24
tmux set-option -t "$SES" window-status-format " #I $LABEL "
tmux set-option -t "$SES" window-status-current-format "#[reverse,bold] #I $LABEL #[default]"
tmux set-option -t "$SES" status-right ' %H:%M '

# Attach from a bare terminal; switch if the captain is already inside tmux.
if [ -n "${TMUX:-}" ]; then
  exec tmux switch-client -t "$SES"
else
  exec tmux attach-session -t "$SES"
fi

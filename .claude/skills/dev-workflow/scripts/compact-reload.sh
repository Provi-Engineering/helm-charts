#!/bin/sh
# SessionStart hook for the compact matcher. The event arrives as JSON on stdin with a `cwd` field.
# When the dev-workflow state file exists in that checkout, print it and the instruction to resume
# the workflow; otherwise print nothing. Always exits 0.
input=$(cat 2>/dev/null)
cwd=$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
rel=.claude/dev-workflow-state.yaml
state=
if [ -n "$cwd" ]; then
  if [ -r "$cwd/$rel" ]; then
    state="$cwd/$rel"
  else
    top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
    [ -n "$top" ] && [ -r "$top/$rel" ] && state="$top/$rel"
  fi
elif [ -n "$CLAUDE_PROJECT_DIR" ] && [ -r "$CLAUDE_PROJECT_DIR/$rel" ]; then
  state="$CLAUDE_PROJECT_DIR/$rel"
fi
[ -n "$state" ] || exit 0
cat "$state" 2>/dev/null
printf '\n%s\n' 'Invoke the dev-workflow skill again, then re-read every reference of the current step before continuing.'
exit 0

#!/bin/sh
input=$(cat)

# Icons (JetBrains Nerd Font)
ic_branch=$(printf '\xee\x9c\xa5')
ic_robot=$(printf '\xee\xb8\x8d')

# ANSI — stored as real escape bytes so they work in %s args too
R=$(printf '\033[0m')
magenta=$(printf '\033[35m')
green=$(printf '\033[32m')
yellow=$(printf '\033[33m')
red=$(printf '\033[31m')
gray=$(printf '\033[37m')
dim=$(printf '\033[90m')

# ── Collect data ───────────────────────────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name')
cost_raw=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')
context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# ── Git ────────────────────────────────────────────────────────────────────────
git_branch="" git_flags="" git_state=""
git_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
if [ -n "$git_dir" ]; then
  git_branch=$(git -C "$git_dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$git_branch" ]; then
    p=$(git -C "$git_dir" --no-optional-locks status --porcelain 2>/dev/null)
    [ "$(echo "$p" | grep -c "^.D"       )" -gt 0 ] && git_flags="${git_flags}✘"
    [ "$(echo "$p" | grep -c "^.M"       )" -gt 0 ] && git_flags="${git_flags}!"
    [ "$(echo "$p" | grep -cE "^[MADRC]" )" -gt 0 ] && git_flags="${git_flags}+"
    [ "$(echo "$p" | grep -c "^??"       )" -gt 0 ] && git_flags="${git_flags}?"
    a=$(git -C "$git_dir" --no-optional-locks rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    b=$(git -C "$git_dir" --no-optional-locks rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    [ "$a" -gt 0 ] && git_flags="${git_flags}⇡"
    [ "$b" -gt 0 ] && git_flags="${git_flags}⇣"
    if   [ -f "${git_dir}/.git/MERGE_HEAD" ]; then git_state="MERGING"
    elif [ -d "${git_dir}/.git/rebase-merge" ] || [ -d "${git_dir}/.git/rebase-apply" ]; then git_state="REBASING"
    fi
  fi
fi

# ── Dev env ────────────────────────────────────────────────────────────────────
dev=""
if [ -n "$git_dir" ]; then
  if [ -f "${git_dir}/package.json" ] && command -v node >/dev/null 2>&1; then
    dev="${dev} node $(node -v 2>/dev/null)"
  fi
  if [ -f "${git_dir}/go.mod" ] && command -v go >/dev/null 2>&1; then
    dev="${dev} go $(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')"
  fi
fi
[ -n "$VIRTUAL_ENV" ] && dev="${dev} ($(basename "$VIRTUAL_ENV"))"
dev=$(echo "$dev" | sed 's/^ //')

# ── Context bar ────────────────────────────────────────────────────────────────
bar=""
if [ -n "$context_pct" ]; then
  filled=$(echo "$context_pct" | awk '{printf "%d", int($1/10+0.5)}')
  empty=$((10 - filled))
  f="" i=0; while [ "$i" -lt "$filled" ]; do f="${f}█"; i=$((i+1)); done
  e="" i=0; while [ "$i" -lt "$empty"  ]; do e="${e}░"; i=$((i+1)); done
  if   [ "$filled" -le 5 ]; then bc="$green"
  elif [ "$filled" -le 7 ]; then bc="$yellow"
  else bc="$red"; fi
  bar="${bc}${f}${dim}${e}${R}"
fi

# ── Single line: git | bar | cost | lines | model | dev ───────────────────────
out=""

add() {
  if [ -n "$out" ]; then
    out="${out}  ${1}"
  else
    out="${1}"
  fi
}

# Context bar (first)
[ -n "$bar" ] && add "$bar"

# Git branch + flags + state
if [ -n "$git_branch" ]; then
  seg="${magenta}${ic_branch} ${git_branch}"
  [ -n "$git_flags" ] && seg="${seg} [${git_flags}]"
  seg="${seg}${R}"
  [ -n "$git_state" ] && seg="${seg}  ${red}${git_state}${R}"
  add "$seg"
fi

# Lines — green for added, red for removed
if [ -n "$lines_added" ] && [ -n "$lines_removed" ]; then
  add "${green}+${lines_added} ${red}-${lines_removed}${R}"
fi

# Model
[ -n "$model" ] && add "${gray}${ic_robot} ${model}${R}"

# Dev env
[ -n "$dev" ] && add "${dim}${dev}${R}"

# Cost last — color by amount
if [ -n "$cost_raw" ]; then
  fmt=$(echo "$cost_raw" | awk '{printf "$%.2f", $1}')
  cost_color=$(echo "$cost_raw" | awk -v g="$green" -v y="$yellow" -v r="$red" '{
    if ($1 > 20) print r; else if ($1 > 10) print y; else print g
  }')
  add "${cost_color}${fmt}${R}"
fi

printf "%s\n" "$out"

autoload -Uz colors && colors
setopt interactivecomments

: "${AI_CMD_PROVIDER:=codex}"
: "${AI_CMD_UI:=1}"

_ai_cmd_trim() {
  local s="$1"
  s="${s//$'\r'/}"
  s="${s##$'\n'}"
  s="${s%%$'\n'}"
  print -r -- "$s"
}

_ai_ui_start() {
  local req="$1"
  local shown="$req"
  local label="$AI_CMD_PROVIDER"

  if (( ${#shown} > 48 )); then
    shown="${shown[1,45]}..."
  fi

  [[ "$AI_CMD_UI" == "1" ]] || return 0

  zle -I
  printf '\n'
  print -P "%B%F{45}[${label}]%f%b %F{250}request:%f %F{230}${shown}%f"
}

_ai_ui_done() {
  [[ "$AI_CMD_UI" == "1" ]] || return 0
  print -P "%F{78}✓ command ready%f"
}

_ai_ui_fail() {
  [[ "$AI_CMD_UI" == "1" ]] || return 0
  print -P "%F{203}✗ generation failed%f"
}

_ai_replace_buffer_with_command() {
  emulate -L zsh
  setopt localoptions no_aliases pipefail

  local nl="$1"
  local cmd=""
  local tmp_file="${TMPDIR:-/tmp}/ai-cmd-result.$$"

  [[ -z "${nl// }" ]] && return 1

  rm -f "$tmp_file"

  _ai_ui_start "$nl"

  if ! ai-command-gen "$nl" > "$tmp_file" 2>/dev/null; then
    _ai_ui_fail
    zle -M "AI command generation failed (provider: $AI_CMD_PROVIDER)"
    rm -f "$tmp_file"
    return 1
  fi

  cmd="$(_ai_cmd_trim "$(<"$tmp_file")")"
  rm -f "$tmp_file"

  if [[ -z "${cmd// }" ]]; then
    _ai_ui_fail
    zle -M "AI returned an empty command"
    return 1
  fi

  _ai_ui_done

  BUFFER="$cmd"
  CURSOR=${#BUFFER}
  zle redisplay
  return 0
}

_ai_cmd_from_buffer_widget() {
  _ai_replace_buffer_with_command "$BUFFER"
}
zle -N _ai_cmd_from_buffer_widget
bindkey '\e[9;9u' _ai_cmd_from_buffer_widget

_ai_accept_line() {
  if [[ "$BUFFER" == '# '* ]]; then
    local request="${BUFFER#\# }"
    _ai_replace_buffer_with_command "$request"
    return 0
  fi

  zle .accept-line
}
zle -N accept-line _ai_accept_line

_ai_toggle_provider_widget() {
  if [[ "$AI_CMD_PROVIDER" == "codex" ]]; then
    AI_CMD_PROVIDER="claude"
  else
    AI_CMD_PROVIDER="codex"
  fi
  zle -M "AI provider: $AI_CMD_PROVIDER"
}
zle -N _ai_toggle_provider_widget

aip() {
  AI_CMD_PROVIDER="$1"
}

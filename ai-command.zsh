autoload -Uz colors && colors
setopt interactivecomments

: "${AI_CMD_PROVIDER:=claude}"
: "${AI_CMD_MODEL:=claude-haiku-4-5}"
: "${AI_CMD_UI:=1}"

_ai_cmd_trim() {
  local s="$1"
  s="${s//$'\r'/}"
  s="${s##$'\n'}"
  s="${s%%$'\n'}"
  print -r -- "$s"
}

_ai_ui_prefix() {
  local color="45"

  case "$AI_CMD_PROVIDER" in
    claude)
      color="208"
      ;;
    codex)
      color="45"
      ;;
  esac

  print -nP "%B%F{${color}}[${AI_CMD_PROVIDER}]%f%b"
}

_ai_ui_start() {
  local req="$1"
  local shown="$req"

  [[ "$AI_CMD_UI" == "1" ]] || return 0

  if (( ${#shown} > 42 )); then
    shown="${shown[1,39]}..."
  fi

  zle -I
  printf '\n'
  _ai_ui_prefix
  print -P " %F{250}model:%f %F{111}${AI_CMD_MODEL}%f %F{250}request:%f %F{230}${shown}%f"
}

_ai_ui_done() {
  [[ "$AI_CMD_UI" == "1" ]] || return 0
  _ai_ui_prefix
  print -P " %F{78}✓ command ready%f"
}

_ai_ui_fail() {
  [[ "$AI_CMD_UI" == "1" ]] || return 0
  _ai_ui_prefix
  print -P " %F{203}✗ generation failed%f"
}

_ai_ui_spinner() {
  local pid="$1"
  local -a frames
  local i=1

  [[ "$AI_CMD_UI" == "1" ]] || return 0

  frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

  while kill -0 "$pid" 2>/dev/null; do
    printf '\r\033[2K'
    _ai_ui_prefix
    print -nP " %F{111}${frames[$i]}%f %F{245}thinking...%f"
    sleep 0.08
    i=$(( i % ${#frames} + 1 ))
  done

  printf '\r\033[2K'
}

_ai_replace_buffer_with_command() {
  emulate -L zsh
  setopt localoptions no_aliases pipefail
  unsetopt monitor notify

  local nl="$1"
  local cmd=""
  local tmp_file="${TMPDIR:-/tmp}/ai-cmd-result.$$"
  local pid
  local exit_code=0

  [[ -z "${nl// }" ]] && return 1

  rm -f "$tmp_file"

  _ai_ui_start "$nl"

  {
    ai-command-gen "$nl" > "$tmp_file" 2>/dev/null
  } &
  pid=$!

  _ai_ui_spinner "$pid"

  wait "$pid" || exit_code=$?

  if (( exit_code != 0 )) || [[ ! -s "$tmp_file" ]]; then
    _ai_ui_fail
    zle -M "AI command generation failed (provider: $AI_CMD_PROVIDER, model: $AI_CMD_MODEL)"
    rm -f "$tmp_file"
    zle reset-prompt
    return 1
  fi

  cmd="$(_ai_cmd_trim "$(<"$tmp_file")")"
  rm -f "$tmp_file"

  if [[ -z "${cmd// }" ]]; then
    _ai_ui_fail
    zle -M "AI returned an empty command"
    zle reset-prompt
    return 1
  fi

  _ai_ui_done

  BUFFER="$cmd"
  CURSOR=${#BUFFER}
  zle reset-prompt
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

aim() {
  AI_CMD_MODEL="$1"
}

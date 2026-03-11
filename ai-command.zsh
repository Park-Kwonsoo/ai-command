autoload -Uz colors && colors

: "${AI_CMD_PROVIDER:=codex}"
: "${AI_CMD_UI:=1}"

_ai_cmd_trim() {
  local s="$1"
  s="${s//$'\r'/}"
  s="${s##$'\n'}"
  s="${s%%$'\n'}"
  print -r -- "$s"
}

_ai_ui_panel_start() {
  local req="$1"
  local shown="$req"

  if (( ${#shown} > 68 )); then
    shown="${shown[1,65]}..."
  fi

  print
  print -P "%F{240}╭──────────────────────────────────────────────────────────────╮%f"
  print -P "%F{240}│%f %B%F{45}[codex]%f%b %F{252}Agent%f                                               %F{240}│%f"
  print -P "%F{240}│%f %F{245}request%f  %B%F{230}${shown}%f%b"
  print -P "%F{240}│%f                                                              %F{240}│%f"
  print -P "%F{240}│%f %F{111}preparing command...%f                                      %F{240}│%f"
  print -P "%F{240}╰──────────────────────────────────────────────────────────────╯%f"
}

_ai_ui_panel_tick() {
  local frame="$1"
  local bar="$2"

  printf '\033[2A\r'
  print -nP "%F{240}│%f %F{39}${frame}%f %F{250}thinking%f  %F{240}["
  print -nP "%F{245}${bar}%f"
  print -nP "%F{240}]%f"
  printf '%*s' 16 ''
  print -nP "%F{240}│%f"
  printf '\n'
  print -nP "%F{240}╰──────────────────────────────────────────────────────────────╯%f"
}

_ai_ui_panel_done() {
  printf '\033[2A\r'
  print -nP "%F{240}│%f %F{78}✓%f %F{252}command ready%f  %F{240}["
  print -nP "%F{72}▓▓▓▓▓▓▓▓▓▓▓▓%f"
  print -nP "%F{240}]%f"
  printf '%*s' 11 ''
  print -nP "%F{240}│%f"
  printf '\n'
  print -nP "%F{240}╰──────────────────────────────────────────────────────────────╯%f"
  sleep 0.18
  printf '\r\033[2K\n\033[2K\n'
}

_ai_ui_panel_fail() {
  printf '\033[2A\r'
  print -nP "%F{240}│%f %F{203}✗%f %F{252}generation failed%f                                      %F{240}│%f"
  printf '\n'
  print -nP "%F{240}╰──────────────────────────────────────────────────────────────╯%f"
  sleep 0.35
  printf '\r\033[2K\n\033[2K\n'
}

_ai_replace_buffer_with_command() {
  emulate -L zsh
  setopt localoptions no_aliases pipefail

  local nl="$1"
  local cmd=""
  local tmp_file="${TMPDIR:-/tmp}/ai-cmd-result.$$"
  local pid
  local -a frames bars
  local frame_i=1
  local bar_i=1

  [[ -z "${nl// }" ]] && return 1

  frames=('⠁' '⠂' '⠄' '⡀' '⢀' '⠠' '⠐' '⠈')
  bars=(
    '▓░░░░░░░░░░░'
    '▓▓░░░░░░░░░░'
    '▓▓▓░░░░░░░░░'
    '▓▓▓▓░░░░░░░░'
    '▓▓▓▓▓░░░░░░░'
    '▓▓▓▓▓▓░░░░░░'
    '▓▓▓▓▓▓▓░░░░░'
    '▓▓▓▓▓▓▓▓░░░░'
    '▓▓▓▓▓▓▓▓▓░░░'
    '▓▓▓▓▓▓▓▓▓▓░░'
    '▓▓▓▓▓▓▓▓▓▓▓░'
    '▓▓▓▓▓▓▓▓▓▓▓▓'
  )

  rm -f "$tmp_file"
  [[ "$AI_CMD_UI" == "1" ]] && _ai_ui_panel_start "$nl"

  {
    ai-command-gen "$nl" > "$tmp_file"
  } &
  pid=$!

  if [[ "$AI_CMD_UI" == "1" ]]; then
    while kill -0 "$pid" 2>/dev/null; do
      _ai_ui_panel_tick "${frames[$frame_i]}" "${bars[$bar_i]}"
      sleep 0.09
      frame_i=$(( frame_i % ${#frames} + 1 ))
      bar_i=$(( bar_i % ${#bars} + 1 ))
    done
  fi

  wait "$pid"
  local status=$?

  if (( status != 0 )) || [[ ! -s "$tmp_file" ]]; then
    [[ "$AI_CMD_UI" == "1" ]] && _ai_ui_panel_fail
    zle -M "AI command generation failed (provider: $AI_CMD_PROVIDER)"
    rm -f "$tmp_file"
    return 1
  fi

  cmd="$(_ai_cmd_trim "$(<"$tmp_file")")"
  rm -f "$tmp_file"

  [[ -z "${cmd// }" ]] && return 1

  [[ "$AI_CMD_UI" == "1" ]] && _ai_ui_panel_done

  BUFFER="$cmd"
  CURSOR=${#BUFFER}
  zle redisplay
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

#!/usr/bin/env bash
set -euo pipefail

GHOSTTY_CONFIG="${HOME}/.config/ghostty/config"
ZSHRC="${HOME}/.zshrc"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_ZSH_FILE="${REPO_ROOT}/ai-command.zsh"
AI_BIN_DIR="${REPO_ROOT}/bin"

GHOSTTY_KEYBIND='keybind = cmd+i=csi:9;9u'

BOOTSTRAP_BLOCK=$(cat <<EOF
# >>> ai-command bootstrap >>>
export PATH="${AI_BIN_DIR}:\$PATH"

typeset -g AI_CMD_ROOT="${REPO_ROOT}"
typeset -g AI_CMD_LOADED=0

_ai_command_source() {
  (( AI_CMD_LOADED )) && return 0

  if [[ -f "\$AI_CMD_ROOT/ai-command.zsh.zwc" ]]; then
    source "\$AI_CMD_ROOT/ai-command.zsh.zwc"
  else
    source "\$AI_CMD_ROOT/ai-command.zsh"
  fi

  AI_CMD_LOADED=1
}

_ai_command_widget_bootstrap() {
  _ai_command_source
  _ai_cmd_from_buffer_widget
}
zle -N _ai_command_widget_bootstrap
bindkey '\e[9;9u' _ai_command_widget_bootstrap

_ai_command_accept_line_bootstrap() {
  if [[ "\$BUFFER" == '# '* ]]; then
    _ai_command_source
    _ai_accept_line
    return 0
  fi

  zle .accept-line
}
zle -N accept-line _ai_command_accept_line_bootstrap

autoload -Uz add-zsh-hook

_ai_command_prewarm_once() {
  {
    zcompile "\$AI_CMD_ROOT/ai-command.zsh" 2>/dev/null
  } &!

  add-zsh-hook -d precmd _ai_command_prewarm_once 2>/dev/null
}

add-zsh-hook precmd _ai_command_prewarm_once
# <<< ai-command bootstrap <<<
EOF
)

echo "==> setup start"
echo "repo root: ${REPO_ROOT}"

if [[ ! -f "${AI_ZSH_FILE}" ]]; then
  echo "ERROR: ai-command.zsh not found: ${AI_ZSH_FILE}" >&2
  exit 1
fi

if [[ ! -d "${AI_BIN_DIR}" ]]; then
  echo "ERROR: bin directory not found: ${AI_BIN_DIR}" >&2
  exit 1
fi

if [[ -f "${AI_BIN_DIR}/ai-command-gen" ]]; then
  chmod +x "${AI_BIN_DIR}/ai-command-gen"
fi

mkdir -p "$(dirname "${GHOSTTY_CONFIG}")"
touch "${GHOSTTY_CONFIG}"

echo "==> checking Ghostty keybind"
if grep -Fqx "${GHOSTTY_KEYBIND}" "${GHOSTTY_CONFIG}"; then
  echo "    already exists, skip"
else
  printf '\n%s\n' "${GHOSTTY_KEYBIND}" >> "${GHOSTTY_CONFIG}"
  echo "    added: ${GHOSTTY_KEYBIND}"
fi

touch "${ZSHRC}"

echo "==> checking ~/.zshrc bootstrap block"
if grep -Fq "# >>> ai-command bootstrap >>>" "${ZSHRC}"; then
  echo "    bootstrap already exists, skip"
else
  printf '\n%s\n' "${BOOTSTRAP_BLOCK}" >> "${ZSHRC}"
  echo "    added bootstrap block"
fi

echo
echo "==> done"
echo "next:"
echo "  source ~/.zshrc"
echo "  restart Ghostty"

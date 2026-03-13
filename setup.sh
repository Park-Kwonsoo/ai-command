#!/usr/bin/env bash
set -euo pipefail

GHOSTTY_CONFIG="${HOME}/.config/ghostty/config"
ZSHRC="${HOME}/.zshrc"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_ZSH_FILE="${REPO_ROOT}/ai-command.zsh"
AI_BIN_DIR="${REPO_ROOT}/bin"

GHOSTTY_KEYBIND='keybind = cmd+i=csi:9;9u'

BOOTSTRAP_START='# >>> ai-command bootstrap >>>'
BOOTSTRAP_END='# <<< ai-command bootstrap <<<'

BOOTSTRAP_BLOCK=$(cat <<EOF
${BOOTSTRAP_START}
export PATH="${AI_BIN_DIR}:\$PATH"

typeset -g AI_CMD_ROOT="${REPO_ROOT}"
typeset -g AI_CMD_LOADED=0

_ai_command_source() {
  (( AI_CMD_LOADED )) && return 0
  source "\$AI_CMD_ROOT/ai-command.zsh"
  AI_CMD_LOADED=1
}

_ai_command_widget_bootstrap() {
  _ai_command_source
  ai_command_handle_buffer
}
zle -N _ai_command_widget_bootstrap
bindkey '\e[9;9u' _ai_command_widget_bootstrap

_ai_command_accept_line_bootstrap() {
  if [[ "\$BUFFER" == '# '* ]]; then
    _ai_command_source
    ai_command_handle_hash_line
    return 0
  fi

  zle .accept-line
}
zle -N accept-line _ai_command_accept_line_bootstrap
${BOOTSTRAP_END}
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

rm -f "${REPO_ROOT}/ai-command.zsh.zwc"

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

echo "==> removing old ai-command lines from ~/.zshrc if present"
TMP_ZSHRC="$(mktemp)"

awk '
  BEGIN { skip=0 }
  $0 == "# >>> ai-command bootstrap >>>" { skip=1; next }
  $0 == "# <<< ai-command bootstrap <<<" { skip=0; next }
  skip == 1 { next }

  /ai-command\/bin:\$PATH/ { next }
  /source ".*ai-command\.zsh"/ { next }

  { print }
' "${ZSHRC}" > "${TMP_ZSHRC}"

mv "${TMP_ZSHRC}" "${ZSHRC}"

echo "==> adding bootstrap block"
printf '\n%s\n' "${BOOTSTRAP_BLOCK}" >> "${ZSHRC}"

echo
echo "==> done"
echo "next:"
echo "  source ~/.zshrc"
echo "  restart Ghostty"

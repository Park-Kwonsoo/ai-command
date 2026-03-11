#!/usr/bin/env bash
set -euo pipefail

GHOSTTY_CONFIG="${HOME}/.config/ghostty/config"
ZSHRC="${HOME}/.zshrc"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_ZSH_FILE="${REPO_ROOT}/ai-command.zsh"
AI_BIN_DIR="${REPO_ROOT}/bin"

GHOSTTY_KEYBIND='keybind = cmd+i=csi:9;9u'
ZSH_PATH_LINE="export PATH=\"${AI_BIN_DIR}:\$PATH\""
ZSH_SOURCE_LINE="source \"${AI_ZSH_FILE}\""

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

echo "==> checking ~/.zshrc PATH line"
if grep -Fqx "${ZSH_PATH_LINE}" "${ZSHRC}"; then
  echo "    already exists, skip"
else
  printf '\n%s\n' "${ZSH_PATH_LINE}" >> "${ZSHRC}"
  echo "    added PATH line"
fi

echo "==> checking ~/.zshrc source line"
if grep -Fqx "${ZSH_SOURCE_LINE}" "${ZSHRC}"; then
  echo "    already exists, skip"
else
  printf '%s\n' "${ZSH_SOURCE_LINE}" >> "${ZSHRC}"
  echo "    added source line"
fi

echo
echo "==> done"
echo "next:"
echo "  source ~/.zshrc"
echo "  restart Ghostty"

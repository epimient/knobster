#!/usr/bin/env bash
#
# Knobster — Uninstaller
# ======================

set -uo pipefail

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

log_info()  { echo -e "  ${CYAN}▸${RESET} $*"; }
log_ok()    { echo -e "  ${GREEN}✔${RESET} $*"; }
log_warn()  { echo -e "  ${YELLOW}⚠${RESET} $*"; }
log_error() { echo -e "  ${RED}✘${RESET} $*" >&2; }
log_step()  { echo -e "  ${BOLD}${MAGENTA}──${RESET} ${BOLD}$*${RESET}"; }

BIN_PATH="/usr/local/bin/knobster"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/knobster"
SUDOERS_FILE="/etc/sudoers.d/knobster"
KEYD_CONFIG="/etc/keyd/knobster.conf"

echo -e "${CYAN}"
echo "  ╭──────────────────────────────────────────╮"
echo -e "  │${RESET}        ${BOLD}Knobster Uninstaller${RESET}${CYAN}             │${RESET}"
echo -e "${CYAN}  ╰──────────────────────────────────────────╯${RESET}"
echo
echo -e "  ${YELLOW}⚠${RESET} Esto eliminará Knobster de tu sistema."
read -rp "  ¿Continuar? [s/N]: " confirm

if [[ ! "$confirm" =~ ^[sSyY] ]]; then
    echo
    log_info "Desinstalación cancelada."
    exit 0
fi

echo

# Binary
if [[ -f "$BIN_PATH" ]]; then
    log_step "Eliminando binario..."
    sudo rm -f "$BIN_PATH"
    log_ok "Eliminado: $BIN_PATH"
fi

# Config
if [[ -d "$CONFIG_DIR" ]]; then
    log_step "Eliminando configuración de usuario..."
    rm -rf "$CONFIG_DIR"
    log_ok "Eliminado: $CONFIG_DIR"
fi

# Sudoers
if [[ -f "$SUDOERS_FILE" ]]; then
    log_step "Eliminando permiso sudo..."
    sudo rm -f "$SUDOERS_FILE"
    log_ok "Eliminado: $SUDOERS_FILE"
fi

# keyd config
if [[ -f "$KEYD_CONFIG" ]]; then
    log_step "Eliminando configuración de keyd..."
    sudo rm -f "$KEYD_CONFIG"
    log_ok "Eliminado: $KEYD_CONFIG"
    log_info "Recargando keyd..."
    sudo systemctl restart keyd 2>/dev/null || true
fi

echo
echo -e "  ${GREEN}━━━ Knobster desinstalado ━━━${RESET}"
echo
log_info "keyd no se desinstala por si lo usas para otras configuraciones."
log_info "Si deseas eliminar keyd:"
log_info "  cd ~/keyd && sudo make uninstall   (instalación desde fuente)"
log_info "  o usa tu gestor de paquetes (AUR, etc.)"
echo

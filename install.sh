#!/usr/bin/env bash
#
# Knobster — Installer
# =====================
# Usage: curl -fsSL https://raw.githubusercontent.com/epimient/knobster/main/install.sh | bash
# Or:    sudo ./install.sh

set -uo pipefail

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'
GRAY='\033[90m'
BOLD='\033[1m'
RESET='\033[0m'

log_info()  { echo -e "  ${CYAN}▸${RESET} $*"; }
log_ok()    { echo -e "  ${GREEN}✔${RESET} $*"; }
log_warn()  { echo -e "  ${YELLOW}⚠${RESET} $*"; }
log_error() { echo -e "  ${RED}✘${RESET} $*" >&2; }
log_step()  { echo -e "  ${BOLD}${MAGENTA}──${RESET} ${BOLD}$*${RESET}"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/knobster"
CONFIG_FILE="$CONFIG_DIR/config"
BIN_NAME="knobster"
BIN_PATH="$INSTALL_DIR/$BIN_NAME"
SOURCE_SCRIPT="$SCRIPT_DIR/knobster.sh"

# ───────────────────────────────────────────────
#  Banner
# ───────────────────────────────────────────────

echo -e "${CYAN}"
echo "  ╭──────────────────────────────────────────╮"
echo -e "  │${RESET}          ${BOLD}Knobster Installer${RESET}${CYAN}              │${RESET}"
echo -e "${CYAN}  ╰──────────────────────────────────────────╯${RESET}"
echo

# ───────────────────────────────────────────────
#  Detect OS / Distro
# ───────────────────────────────────────────────

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        echo "$ID"
    elif command -v lsb_release &>/dev/null; then
        lsb_release -is
    else
        echo "unknown"
    fi
}

# ───────────────────────────────────────────────
#  Check / Install keyd
# ───────────────────────────────────────────────

install_keyd() {
    local distro
    distro=$(detect_distro)

    log_step "Instalando keyd..."

    case "$distro" in
        ubuntu|debian)
            log_info "Detectado: $distro"
            log_info "Instalando dependencias..."
            sudo apt update -qq && sudo apt install -y -qq git build-essential
            log_info "Clonando keyd..."
            git clone --depth 1 https://github.com/rvaiya/keyd /tmp/keyd
            cd /tmp/keyd || exit
            make
            sudo make install || { log_error "Error al instalar keyd."; exit 1; }
            sudo systemctl enable --now keyd 2>/dev/null || log_warn "No se pudo habilitar keyd automáticamente."
            cd "$SCRIPT_DIR" || exit
            rm -rf /tmp/keyd
            ;;
        arch)
            log_info "Detectado: Arch Linux"
            log_info "Instalando keyd desde AUR..."
            if command -v yay &>/dev/null; then
                yay -S --noconfirm keyd
            elif command -v paru &>/dev/null; then
                paru -S --noconfirm keyd
            else
                log_info "Instalando yay primero..."
                sudo pacman -S --noconfirm --needed git base-devel
                git clone --depth 1 https://aur.archlinux.org/yay.git /tmp/yay
                cd /tmp/yay || exit
                makepkg -si --noconfirm
                cd "$SCRIPT_DIR" || exit
                rm -rf /tmp/yay
                yay -S --noconfirm keyd
            fi
            sudo systemctl enable --now keyd 2>/dev/null || log_warn "No se pudo habilitar keyd automáticamente."
            ;;
        fedora)
            log_info "Detectado: Fedora"
            sudo dnf install -y git gcc
            git clone --depth 1 https://github.com/rvaiya/keyd /tmp/keyd
            cd /tmp/keyd || exit
            make
            sudo make install || { log_error "Error al instalar keyd."; exit 1; }
            sudo systemctl enable --now keyd 2>/dev/null || log_warn "No se pudo habilitar keyd automáticamente."
            cd "$SCRIPT_DIR" || exit
            rm -rf /tmp/keyd
            ;;
        *)
            log_error "Distribución no detectada automáticamente."
            log_info "Instalando keyd desde fuente..."
            git clone --depth 1 https://github.com/rvaiya/keyd /tmp/keyd
            cd /tmp/keyd || exit
            make
            sudo make install || { log_error "Error al instalar keyd."; exit 1; }
            sudo systemctl enable --now keyd 2>/dev/null || log_warn "No se pudo habilitar keyd automáticamente."
            cd "$SCRIPT_DIR" || exit
            rm -rf /tmp/keyd
            ;;
    esac

    if command -v keyd &>/dev/null; then
        log_ok "keyd instalado correctamente."
    else
        log_error "keyd no se instaló correctamente."
        exit 1
    fi
}

# ───────────────────────────────────────────────
#  Detect Keyboard ID
# ───────────────────────────────────────────────

detect_keyboard_id() {
    log_step "Detectando ID de tu teclado..." >&2

    echo >&2
    echo -e "  ${YELLOW}⚠${RESET} Gira la rueda de ${BOLD}tu teclado${RESET} ahora." >&2
    echo "  El instalador detectará automáticamente el ID." >&2
    echo >&2
    echo -e "  ${GRAY}Presiona Enter cuando estés listo...${RESET}" >&2
    read -r _

    local timeout=15
    local output
    output=$(timeout "$timeout" keyd monitor 2>/dev/null | head -5)

    if [[ -z "$output" ]]; then
        echo >&2
        echo -e "  ${YELLOW}⚠${RESET} No se detectó ninguna señal." >&2
        echo "  Asegúrate de girar la rueda del teclado." >&2
        echo >&2
        read -rp "  Escribe manualmente el ID del teclado (ej: 320f:505b): " manual_id
        if [[ -n "$manual_id" ]]; then
            echo "$manual_id"
            return 0
        fi
        echo "320f:505b"
        log_warn "Usando ID por defecto: 320f:505b" >&2
        return 0
    fi

    local detected_id
    detected_id=$(echo "$output" | grep -oP '^[0-9a-f]{4}:[0-9a-f]{4}' | head -1)

    if [[ -n "$detected_id" ]]; then
        echo "$detected_id"
        log_ok "Teclado detectado: $detected_id" >&2
        return 0
    fi

    echo "320f:505b"
    log_warn "No se pudo extraer ID, usando: 320f:505b" >&2
}

# ───────────────────────────────────────────────
#  Setup sudoers (passwordless)
# ───────────────────────────────────────────────

setup_sudoers() {
    local sudoers_file="/etc/sudoers.d/knobster"

    if [[ -f "$sudoers_file" ]]; then
        log_info "Permiso sudo sin contraseña ya configurado."
        return 0
    fi

    echo
    echo -e "  ${YELLOW}⚠${RESET} ¿Quieres ejecutar Knobster ${BOLD}sin contraseña${RESET} sudo?"
    echo "  (Crea /etc/sudoers.d/knobster para evitar pedir sudo cada vez)"
    read -rp "  [s/N]: " setup_sudo

    if [[ "$setup_sudo" =~ ^[sSyY] ]]; then
        echo "$USER ALL=(ALL) NOPASSWD: $BIN_PATH" | sudo tee "$sudoers_file" >/dev/null
        sudo chmod 440 "$sudoers_file"
        log_ok "Configurado sudo sin contraseña para knobster."
    else
        log_info "Omitido. Usa 'sudo knobster' cada vez."
    fi
}

# ───────────────────────────────────────────────
#  Main Install
# ───────────────────────────────────────────────

main() {
    # Step 1: Check keyd
    log_step "Verificando keyd..."
    if command -v keyd &>/dev/null; then
        log_ok "keyd ya está instalado."
    else
        log_warn "keyd no está instalado."
        echo
        read -rp "  ¿Instalar keyd ahora? [S/n]: " install_keyd_ans
        if [[ ! "$install_keyd_ans" =~ ^[nN] ]]; then
            install_keyd
        else
            log_error "keyd es necesario. Instálalo manualmente: https://github.com/rvaiya/keyd"
            exit 1
        fi
    fi

    # Step 2: Detect keyboard ID
    local detected_id
    detected_id=$(detect_keyboard_id)
    echo

    # Step 3: Create config dir
    log_step "Configurando Knobster..."
    mkdir -p "$CONFIG_DIR"
    log_info "Directorio de configuración: $CONFIG_DIR"

    cat > "$CONFIG_FILE" <<EOF
# Knobster Configuration
# File auto-generated by install.sh

KEYBOARD_ID=$detected_id
EOF
    log_ok "Configuración escrita: $CONFIG_FILE"

    # Step 4: Install binary
    log_step "Instalando knobster..."

    if [[ ! -f "$SOURCE_SCRIPT" ]]; then
        log_info "Descargando knobster.sh desde GitHub..."
        mkdir -p /tmp/knobster-install
        curl -fsSL -o /tmp/knobster-install/knobster.sh \
            https://raw.githubusercontent.com/epimient/knobster/main/knobster.sh
        curl -fsSL -o /tmp/knobster-install/banner.txt \
            https://raw.githubusercontent.com/epimient/knobster/main/banner.txt
        SOURCE_SCRIPT="/tmp/knobster-install/knobster.sh"
    fi

    sudo cp "$SOURCE_SCRIPT" "$BIN_PATH"
    sudo chmod +x "$BIN_PATH"
    log_ok "Binario instalado: $BIN_PATH"

    # Step 5: Passwordless sudo (optional)
    setup_sudoers

    # Step 6: Cleanup temp
    rm -rf /tmp/knobster-install

    # Done
    echo
    echo -e "  ${GREEN}━━━ Knobster instalado exitosamente ━━━${RESET}"
    echo
    echo -e "  Para usarlo:"
    echo -e "    ${CYAN}knobster${RESET}               Menú interactivo"
    echo -e "    ${CYAN}knobster on${RESET}            Activar modo edición"
    echo -e "    ${CYAN}knobster off${RESET}           Volver a volumen normal"
    echo -e "    ${CYAN}knobster status${RESET}        Ver estado"
    echo
    echo -e "  Configuración: ${GRAY}$CONFIG_FILE${RESET}"
    echo
}

main "$@"

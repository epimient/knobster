#!/usr/bin/env bash
#
#  Knobster — Controla la rueda de tu teclado AK820
#  =================================================
#  Menú interactivo para cambiar el comportamiento
#  de la rueda entre modos: edición, programador,
#  multimedia o personalizado.
#
#  Depende de keyd: https://github.com/rvaiya/keyd

set -uo pipefail

# ═══════════════════════════════════════════════
#  CONFIGURACIÓN
# ═══════════════════════════════════════════════

CONFIG_FILE="/etc/keyd/knobster.conf"
KEYBOARD_ID="${KEYBOARD_ID:-320f:505b:d8fffecf}"
EDITOR="${EDITOR:-${VISUAL:-nano}}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ═══════════════════════════════════════════════
#  COLORES
# ═══════════════════════════════════════════════

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
GRAY='\033[90m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

RAINBOW=("$RED" "$YELLOW" "$GREEN" "$CYAN" "$MAGENTA")

# ═══════════════════════════════════════════════
#  BANNER
# ═══════════════════════════════════════════════

read_banner() {
    local banner_file="$SCRIPT_DIR/banner.txt"
    local lines=()
    if [[ -f "$banner_file" ]]; then
        mapfile -t lines < "$banner_file"
    else
        lines=(
            " _  __            _         _            "
            "| |/ /_ __   ___ | |__  ___| |_ ___ _ __ "
            "| ' /| '_ \| / _ \| '_ \/ __| __/ _ \ '__|"
            "| . \| | | | (_) | |_) \__ \ ||  __/ |   "
            "|_|\_\_| |_|\___/|_.__/|___/\__\___|_|   "
        )
    fi
    for i in "${!lines[@]}"; do
        echo -e "  ${RAINBOW[$((i % ${#RAINBOW[@]}))]}${lines[$i]}${RESET}"
    done
    echo
}

# ═══════════════════════════════════════════════
#  HELPERS
# ═══════════════════════════════════════════════

usage() {
    cat <<EOF
Uso: $(basename "$0") [OPCIÓN]

Controla la rueda de tu teclado desde la terminal.

Opciones:
  on          Activar el último modo (edición por defecto)
  off         Volver a volumen normal
  status      Mostrar estado actual
  --help, -h  Mostrar esta ayuda

Sin argumentos abre el menú interactivo.
EOF
    exit 0
}

die() {
    echo -e "${RED}${BOLD}Error:${RESET} $*" >&2
    exit 1
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        die "Se necesita ejecutar como root.\n  sudo $(basename "$0")"
    fi
}

require_keyd() {
    if ! command -v keyd &>/dev/null; then
        die "keyd no está instalado. Instálalo primero:\n  https://github.com/rvaiya/keyd"
    fi
}

reload_keyd() {
    if keyd reload >/dev/null 2>&1; then
        echo -e "  ${GREEN}✔${RESET} keyd recargado correctamente."
    else
        die "No se pudo recargar keyd."
    fi
}

write_config() {
    local mode_name="$1"
    local config_body="$2"

    cat >"$CONFIG_FILE" <<EOF
# Knobster
# Modo: $mode_name
# Generado por knobster

[ids]

$KEYBOARD_ID

$config_body
EOF

    reload_keyd
}

# ═══════════════════════════════════════════════
#  MODOS
# ═══════════════════════════════════════════════

mode_editing() {
    clear
    write_config "Edicion / Timeline" "[main]

volumeup = macro(right right right)
volumedown = macro(left left left)
mute = space
"
    echo
    echo -e "  ${GREEN}━━━ Modo Edición activado ━━━${RESET}"
    echo -e "  ${CYAN}↻${RESET} Rueda arriba  → ${BOLD}avanzar${RESET} timeline (→→→)"
    echo -e "  ${CYAN}↻${RESET} Rueda abajo   → ${BOLD}retroceder${RESET} timeline (←←←)"
    echo -e "  ${CYAN}●${RESET}  Botón rueda  → ${BOLD}play / pause${RESET} (space)"
    sleep 2
}

mode_programmer() {
    clear
    write_config "Programador / Cursor" "[main]

volumeup = up
volumedown = down
mute = enter
"
    echo
    echo -e "  ${GREEN}━━━ Modo Programador activado ━━━${RESET}"
    echo -e "  ${CYAN}↻${RESET} Rueda arriba  → ${BOLD}cursor arriba${RESET} (↑)"
    echo -e "  ${CYAN}↻${RESET} Rueda abajo   → ${BOLD}cursor abajo${RESET} (↓)"
    echo -e "  ${CYAN}●${RESET}  Botón rueda  → ${BOLD}enter${RESET}"
    sleep 2
}

mode_multimedia() {
    clear
    rm -f "$CONFIG_FILE"
    reload_keyd
    echo
    echo -e "  ${GREEN}━━━ Modo Multimedia activado ━━━${RESET}"
    echo -e "  ${CYAN}↻${RESET} Rueda → ${BOLD}volumen normal${RESET}"
    echo -e "  ${CYAN}●${RESET}  Botón → ${BOLD}silenciar${RESET}"
    sleep 2
}

# ═══════════════════════════════════════════════
#  PERSONALIZACIÓN
# ═══════════════════════════════════════════════

show_option_list() {
    local -n items=$1
    for i in "${!items[@]}"; do
        echo -e "  ${CYAN}[$((i+1))]${RESET}  ${items[$i]}"
    done
}

pick_or_custom() {
    local title="$1"
    local -n opts=$2
    local -n vals=$3
    local result_var=$4

    echo -e "  ${YELLOW}▸${RESET} $title"
    echo
    show_option_list opts
    echo
    read -rp "  ❯ Opción [1-${#opts[@]}]: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#opts[@]})); then
        local idx=$((choice - 1))
        if [[ "${vals[$idx]}" == "__custom__" ]]; then
            echo
            read -rp "  ✏  Escribe el comando keyd (ej: right, macro(Ctrl right), f5, esc): " custom_val
            if [[ -z "$custom_val" ]]; then
                custom_val="${vals[0]}"
                echo -e "  ${YELLOW}Valor vacío, usando: $custom_val${RESET}"
            fi
            printf -v "$result_var" "%s" "$custom_val"
        else
            printf -v "$result_var" "%s" "${vals[$idx]}"
        fi
    else
        printf -v "$result_var" "%s" "${vals[0]}"
        echo -e "  ${YELLOW}Opción inválida, usando: ${vals[0]}${RESET}"
    fi
    echo
}

guided_customize() {
    clear
    echo -e "${CYAN}${BOLD}  ╭──────────────────────────────────────────╮${RESET}"
    echo -e "${CYAN}${BOLD}  │${RESET}           Personalizar la rueda            ${CYAN}${BOLD}│${RESET}"
    echo -e "${CYAN}${BOLD}  ╰──────────────────────────────────────────╯${RESET}"
    echo
    echo -e "  ${DIM}Define qué hace cada acción de la rueda.${RESET}"
    echo

    # --- Wheel up ---
    local up_opts=(
        "Flecha derecha →"
        "Flecha derecha x3 →→→"
        "Flecha derecha x5 →→→→→"
        "Flecha arriba ↑"
        "Avanzar página (PageDown)"
        "✏  Escribir comando manualmente"
    )
    local up_vals=(
        "right"
        "macro(right right right)"
        "macro(right right right right right)"
        "up"
        "pagedown"
        "__custom__"
    )
    local wheel_up
    pick_or_custom "¿Qué hace la rueda al girar ${BOLD}ARRIBA${RESET}?" up_opts up_vals wheel_up

    # --- Wheel down ---
    local down_opts=(
        "Flecha izquierda ←"
        "Flecha izquierda x3 ←←←"
        "Flecha izquierda x5 ←←←←←"
        "Flecha abajo ↓"
        "Retroceder página (PageUp)"
        "✏  Escribir comando manualmente"
    )
    local down_vals=(
        "left"
        "macro(left left left)"
        "macro(left left left left left)"
        "down"
        "pageup"
        "__custom__"
    )
    local wheel_down
    pick_or_custom "¿Qué hace la rueda al girar ${BOLD}ABAJO${RESET}?" down_opts down_vals wheel_down

    # --- Button ---
    local btn_opts=(
        "Espacio (Play / Pause)"
        "Enter"
        "Escape"
        "Tab"
        "Ctrl + S (Guardar)"
        "✏  Escribir comando manualmente"
    )
    local btn_vals=(
        "space"
        "enter"
        "esc"
        "tab"
        "macro(C-s)"
        "__custom__"
    )
    local wheel_btn
    pick_or_custom "¿Qué hace al ${BOLD}PRESIONAR${RESET} la rueda?" btn_opts btn_vals wheel_btn

    # --- Apply ---
    local config_body
    config_body="[main]

volumeup = $wheel_up
volumedown = $wheel_down
mute = $wheel_btn
"
    write_config "Personalizado" "$config_body"

    clear
    echo -e "  ${GREEN}━━━ Modo personalizado activado ━━━${RESET}"
    echo
    echo -e "  ${CYAN}↻${RESET} Rueda arriba  → ${BOLD}$wheel_up${RESET}"
    echo -e "  ${CYAN}↻${RESET} Rueda abajo   → ${BOLD}$wheel_down${RESET}"
    echo -e "  ${CYAN}●${RESET}  Botón rueda  → ${BOLD}$wheel_btn${RESET}"
    sleep 2.5
}

edit_config() {
    clear
    echo -e "${CYAN}${BOLD}  ╭──────────────────────────────────────────╮${RESET}"
    echo -e "${CYAN}${BOLD}  │${RESET}           Editar configuración            ${CYAN}${BOLD}│${RESET}"
    echo -e "${CYAN}${BOLD}  ╰──────────────────────────────────────────╯${RESET}"
    echo

    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat >"$CONFIG_FILE" <<EOF
# Knobster - Configuración personalizada
# Edita este archivo y guarda para aplicar cambios.

[ids]

$KEYBOARD_ID

[main]

volumeup = right
volumedown = left
mute = space
EOF
        echo -e "  ${YELLOW}Archivo creado: $CONFIG_FILE${RESET}"
        echo
    fi

    echo -e "  Abriendo ${BOLD}$EDITOR${RESET} ..."
    echo -e "  ${DIM}Archivo: $CONFIG_FILE${RESET}"
    echo
    sleep 1

    $EDITOR "$CONFIG_FILE"

    echo
    if reload_keyd; then
        echo -e "  ${GREEN}✔${RESET} Configuración aplicada desde el editor."
    fi
    sleep 1.5
}

# ═══════════════════════════════════════════════
#  ESTADO
# ═══════════════════════════════════════════════

show_status() {
    clear
    echo -e "${CYAN}${BOLD}  ╭──────────────────────────────────────────╮${RESET}"
    echo -e "${CYAN}${BOLD}  │${RESET}              Estado actual                ${CYAN}${BOLD}│${RESET}"
    echo -e "${CYAN}${BOLD}  ╰──────────────────────────────────────────╯${RESET}"
    echo

    if [[ -f "$CONFIG_FILE" ]]; then
        local mode_line
        mode_line=$(grep "^# Modo:" "$CONFIG_FILE" | sed 's/# Modo: //')
        echo -e "  ${CYAN}●${RESET} Modo:${BOLD} ${mode_line:-Desconocido}${RESET}"
        echo -e "  ${CYAN}●${RESET} ID teclado: ${BOLD}$KEYBOARD_ID${RESET}"
        echo -e "  ${CYAN}●${RESET} Archivo: ${DIM}$CONFIG_FILE${RESET}"
        echo
        echo -e "  ${BOLD}Configuración activa:${RESET}"
        echo -e "  ${GRAY}─────────────────────${RESET}"
        grep -v "^#" "$CONFIG_FILE" | grep -v "^$" | while IFS= read -r line; do
            echo -e "  ${DIM}$line${RESET}"
        done
    else
        echo -e "  ${YELLOW}●${RESET} Modo: ${BOLD}Multimedia / volumen normal${RESET}"
        echo -e "  ${YELLOW}●${RESET} No hay configuración personalizada activa."
    fi

    echo
    read -rp "  Presiona Enter para continuar... " _
}

# ═══════════════════════════════════════════════
#  MENÚ PRINCIPAL
# ═══════════════════════════════════════════════

draw_menu() {
    clear
    read_banner
    echo -e "  ${CYAN}╭──────────────────────────────────────────────────────╮${RESET}"
    echo -e "  ${CYAN}│${RESET}               ${BOLD}${MAGENTA}◉  KNOBSTER${RESET}${RESET}                         ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}        ${DIM}Controla tu rueda como quieras${RESET}            ${CYAN}│${RESET}"
    echo -e "  ${CYAN}├──────────────────────────────────────────────────────┤${RESET}"
    echo -e "  ${CYAN}│${RESET}                                                      ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}    ${BOLD}${YELLOW}[1]${RESET}${RESET}  ${BOLD}Editar Timeline${RESET}                        ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}         ${DIM}↻ Rueda: →→→ / ←←←    ● Botón: Play${RESET}    ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}                                                      ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}    ${BOLD}${YELLOW}[2]${RESET}${RESET}  ${BOLD}Programar Cursor${RESET}                       ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}         ${DIM}↻ Rueda: ↑ / ↓        ● Botón: Enter${RESET}    ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}                                                      ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}    ${BOLD}${YELLOW}[3]${RESET}${RESET}  ${BOLD}Multimedia${RESET}                            ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}         ${DIM}↻ Rueda: volumen      ● Botón: Silenciar${RESET} ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}                                                      ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}    ${BOLD}${YELLOW}[4]${RESET}${RESET}  ${BOLD}Personalizar${RESET}                           ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}         ${DIM}⚙ Configuración a tu medida${RESET}           ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}                                                      ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}    ${BOLD}${YELLOW}[5]${RESET}${RESET}  ${BOLD}Ver estado${RESET}                             ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}    ${BOLD}${YELLOW}[6]${RESET}${RESET}  ${BOLD}Salir${RESET}                                ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}                                                      ${CYAN}│${RESET}"
    echo -e "  ${CYAN}╰──────────────────────────────────────────────────────╯${RESET}"
    echo
}

customize_menu() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}  ╭──────────────────────────────────────────╮${RESET}"
        echo -e "${CYAN}${BOLD}  │${RESET}             Personalizar                ${CYAN}${BOLD}│${RESET}"
        echo -e "${CYAN}${BOLD}  ├──────────────────────────────────────────┤${RESET}"
        echo -e "${CYAN}${BOLD}  │${RESET}                                          ${CYAN}${BOLD}│${RESET}"
        echo -e "${CYAN}${BOLD}  │${RESET}    ${YELLOW}[1]${RESET}  ${BOLD}Configuración guiada${RESET}              ${CYAN}${BOLD}│${RESET}"
        echo -e "${CYAN}${BOLD}  │${RESET}         ${DIM}Paso a paso para tu rueda${RESET}     ${CYAN}${BOLD}│${RESET}"
        echo -e "${CYAN}${BOLD}  │${RESET}                                          ${CYAN}${BOLD}│${RESET}"
        echo -e "${CYAN}${BOLD}  │${RESET}    ${YELLOW}[2]${RESET}  ${BOLD}Editar configuración${RESET}              ${CYAN}${BOLD}│${RESET}"
        echo -e "${CYAN}${BOLD}  │${RESET}         ${DIM}Abrir en $EDITOR${RESET}              ${CYAN}${BOLD}│${RESET}"
        echo -e "${CYAN}${BOLD}  │${RESET}                                          ${CYAN}${BOLD}│${RESET}"
        echo -e "${CYAN}${BOLD}  │${RESET}    ${YELLOW}[3]${RESET}  ${BOLD}Volver al menú principal${RESET}        ${CYAN}${BOLD}│${RESET}"
        echo -e "${CYAN}${BOLD}  │${RESET}                                          ${CYAN}${BOLD}│${RESET}"
        echo -e "${CYAN}${BOLD}  ╰──────────────────────────────────────────╯${RESET}"
        echo
        read -rp "  ❯ Opción [1-3]: " choice

        case "$choice" in
            1) guided_customize; break ;;
            2) edit_config; break ;;
            3) break ;;
            *) echo -e "  ${RED}Opción inválida${RESET}"; sleep 1 ;;
        esac
    done
}

main_menu() {
    while true; do
        draw_menu
        read -rp "  ❯ Opción [1-6]: " choice

        case "$choice" in
            1) mode_editing ;;
            2) mode_programmer ;;
            3) mode_multimedia ;;
            4) customize_menu ;;
            5) show_status ;;
            6)
                echo
                echo -e "  ${CYAN}━━━ ¡Hasta luego! ━━━${RESET}"
                echo
                exit 0
                ;;
            *)
                echo -e "  ${RED}Opción inválida${RESET}"
                sleep 1
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════
#  ENTRY POINTS
# ═══════════════════════════════════════════════

case "${1:-}" in
    --help | -h) usage ;;
    on)
        require_root
        require_keyd
        mode_editing
        ;;
    off)
        require_root
        require_keyd
        mode_multimedia
        ;;
    status)
        require_keyd
        show_status
        ;;
    "")
        require_root
        require_keyd
        main_menu
        ;;
    *)
        echo -e "${RED}Opción desconocida: $1${RESET}" >&2
        usage
        ;;
esac

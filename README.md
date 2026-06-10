<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue" alt="Version">
  <img src="https://img.shields.io/badge/platform-linux-lightgrey" alt="Platform">
  <img src="https://img.shields.io/badge/dependency-keyd-orange" alt="Dependency">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen" alt="PRs welcome">
  <a href="https://github.com/epimient/knobster/actions"><img src="https://github.com/epimient/knobster/actions/workflows/lint.yml/badge.svg" alt="CI"></a>
</p>

<br>

```text
                      _  __            _         _
                     | |/ /_ __   ___ | |__  ___| |_ ___ _ __
                     | ' /| '_ \ / _ \| '_ \/ __| __/ _ \ '__|
                     | . \| | | | (_) | |_) \__ \ ||  __/ |
                     |_|\_\_| |_|\___/|_.__/|___/\__\___|_|
```

# Knobster

**Controla la rueda de tu teclado mecánico como quieras.**

Knobster es una herramienta CLI interactiva para Linux que intercepta las señales de la rueda de volumen de tu teclado y las reasigna a funciones útiles según el contexto: mover el cursor en la línea de tiempo de tu editor de video, navegar código como programador, o simplemente usarla como volumen normal.

---

## Tabla de contenido

- [Cómo funciona](#cómo-funciona)
- [Requisitos del sistema](#requisitos-del-sistema)
- [Instalación](#instalación)
  - [1. Instalar keyd](#1-instalar-keyd)
  - [2. Verificar que keyd funcione](#2-verificar-que-keyd-funcione)
  - [3. Descargar Knobster](#3-descargar-knobster)
- [Configuración inicial](#configuración-inicial)
  - [Detectar el ID de tu teclado](#detectar-el-id-de-tu-teclado)
  - [Configurar la variable KEYBOARD_ID](#configurar-la-variable-keyboard_id)
- [Uso](#uso)
  - [Menú interactivo](#menú-interactivo)
  - [Comandos rápidos](#comandos-rápidos)
- [Modos disponibles](#modos-disponibles)
  - [Modo Editar Timeline](#1-modo-editar-timeline)
  - [Modo Programar Cursor](#2-modo-programar-cursor)
  - [Modo Multimedia](#3-modo-multimedia)
  - [Modo Personalizado](#4-modo-personalizado)
- [Personalización avanzada](#personalización-avanzada)
  - [Configuración guiada](#configuración-guiada)
  - [Edición directa del archivo](#edición-directa-del-archivo)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Solución de problemas](#solución-de-problemas)
- [Licencia](#licencia)
- [Autor](#autor)

---

## Cómo funciona

Knobster usa **keyd**, un daemon de Linux que reasigna teclas a nivel de sistema. Cuando seleccionas un modo, Knobster escribe un archivo de configuración en `/etc/keyd/knobster.conf` con las reglas de reasignación y le indica a keyd que lo recargue.

Las señales `volumeup`, `volumedown` y `mute` del teclado se convierten en las teclas o macros que elijas. Cuando seleccionas "Multimedia", se elimina el archivo de configuración y keyd vuelve al comportamiento por defecto (volumen).

El archivo `/etc/keyd/default.conf` nunca se modifica. Tu configuración general de keyd queda intacta.

```
  ┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
  │  Giras la     │────→│  keyd        │────→│  Acción asignada │
  │  rueda AK820  │     │  intercepta  │     │  (flechas,       │
  │              │     │  la señal    │     │   macros, etc.)  │
  └──────────────┘     └──────────────┘     └──────────────────┘
                              ▲
                              │
                      ┌───────┴───────┐
                      │  knobster.sh  │
                      │  escribe la   │
                      │  config       │
                      └───────────────┘
```

---

## Requisitos del sistema

- **Sistema operativo:** Linux (probado en Ubuntu 24.04, funciona en cualquier distro)
- **keyd:** Daemon de reasignación de teclas ([https://github.com/rvaiya/keyd](https://github.com/rvaiya/keyd))
- **Teclado mecánico** con rueda de volumen detectable por keyd (AK820, Keychron, etc.)
- **Terminal** con soporte de color ANSI (la gran mayoría)
- **bash** 4.0 o superior

---

## Instalación

### Instalación rápida (1-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/epimient/knobster/main/install.sh | bash
```

Esto instala keyd si es necesario, detecta tu teclado automáticamente y deja Knobster listo para usar.

> **Nota:** Para distros basadas en Ubuntu/Debian el instalador compila keyd desde fuente, lo que requiere `git`, `build-essential` y unos segundos.

### Instalación manual

### 1. Instalar keyd

keyd es el motor que intercepta las señales del teclado. No viene preinstalado en la mayoría de las distros.

**Ubuntu / Debian:**

```bash
sudo apt update
sudo apt install -y git build-essential
git clone https://github.com/rvaiya/keyd
cd keyd
make
sudo make install
sudo systemctl enable --now keyd
```

**Arch Linux:**

```bash
yay -S keyd
sudo systemctl enable --now keyd
```

**Fedora:**

```bash
sudo dnf install -y git gcc
git clone https://github.com/rvaiya/keyd
cd keyd
make
sudo make install
sudo systemctl enable --now keyd
```

**Otras distros:** Sigue las instrucciones oficiales en [github.com/rvaiya/keyd](https://github.com/rvaiya/keyd#installation).

### 2. Verificar que keyd funcione

```bash
sudo systemctl status keyd
```

Deberías ver `active (running)`. Si no, inícialo:

```bash
sudo systemctl enable --now keyd
```

### 3. Descargar Knobster

```bash
git clone <url-del-repo> ~/knobster
cd ~/knobster
chmod +x knobster.sh
```

O simplemente copia el archivo `knobster.sh` a tu directorio `~/knobster`:

```bash
mkdir -p ~/knobster
cp knobster.sh ~/knobster/
chmod +x ~/knobster/knobster.sh
```

---

## Configuración inicial

### Detectar el ID de tu teclado

Cada teclado tiene un identificador único que keyd necesita para saber qué dispositivo interceptar. Para descubrirlo:

```bash
sudo keyd monitor
```

Gira la rueda de volumen de tu teclado. Verás algo como:

```
320f:505b:d8fffecf volumeup
320f:505b:d8fffecf volumedown
```

El formato es `id_del_teclado acción`. Copia el **id_del_teclado** (los primeros dos bloques separados por `:`).

> **Nota:** El tercer bloque (`d8fffecf`) es un identificador de sesión que cambia cada vez que conectas el teclado. keyd solo necesita los primeros dos bloques, así que usa `320f:505b`.

### Compatibilidad con otros teclados

Knobster funciona con **cualquier teclado** que keyd pueda detectar. No está limitado al AK820. Si tienes un Keychron, Logitech, Razer, Corsair, o cualquier otro teclado mecánico con rueda de volumen, el proceso es el mismo:

1. Ejecuta `sudo keyd monitor`
2. Gira la rueda de **tu** teclado
3. Copia el ID que aparezca (ej: `04d9:a0a2`)
4. Úsalo como `KEYBOARD_ID`

El script trae el ID del AK820 por defecto, pero eso no impide que lo uses con otro teclado. Solo cambia el ID y todo funciona igual.

```bash
sudo KEYBOARD_ID="04d9:a0a2" ./knobster.sh
```

También puedes tener múltiples teclados con rueda. keyd soporta varios IDs en la sección `[ids]`:

```ini
[ids]

320f:505b
04d9:a0a2
```

Pero Knobster maneja un solo ID por simplicidad. Si necesitas múltiples, edita el archivo `/etc/keyd/knobster.conf` manualmente desde **4 > Editar configuración**.

### Configurar la variable KEYBOARD_ID

Una vez que tienes el ID de tu teclado, puedes pasarlo al script de dos formas:

**Opción 1 — Variable de entorno (no persistente):**

```bash
sudo KEYBOARD_ID="320f:505b" ./knobster.sh
```

**Opción 2 — Editar el script (persistente):**

Abre `knobster.sh` y cambia la línea 18:

```bash
KEYBOARD_ID="${KEYBOARD_ID:-320f:505b}"
```

**Opción 3 — Archivo de configuración de keyd (recomendado):**

Crea o edita `/etc/keyd/default.conf`:

```ini
[ids]
320f:505b

[main]
# tu configuración por defecto aquí
```

keyd aplica este archivo cuando Knobster está en modo Multimedia.

---

## Uso

### Menú interactivo

```bash
sudo ./knobster.sh
```

Esto abre el menú principal con el diseño visual completo:

```
  ╭──────────────────────────────────────────────────────╮
  │               ◉  KNOBSTER                            │
  │       Controla tu rueda como quieras                 │
  ├──────────────────────────────────────────────────────┤
  │                                                      │
  │    [1]  Editar Timeline                              │
  │         ↻ Rueda: →→→ / ←←←    ● Botón: Play         │
  │                                                      │
  │    [2]  Programar Cursor                             │
  │         ↻ Rueda: ↑ / ↓        ● Botón: Enter        │
  │                                                      │
  │    [3]  Multimedia                                   │
  │         ↻ Rueda: volumen      ● Botón: Silenciar    │
  │                                                      │
  │    [4]  Personalizar                                 │
  │         ⚙ Configuración a tu medida                  │
  │                                                      │
  │    [5]  Ver estado                                   │
  │    [6]  Salir                                        │
  │                                                      │
  ╰──────────────────────────────────────────────────────╯
  ❯ Opción [1-6]:
```

Navega con las teclas numéricas (1 al 6). Cada modo se activa al instante y ves una confirmación visual.

### Comandos rápidos

Para evitar abrir el menú cada vez:

| Comando | Efecto |
|---------|--------|
| `sudo ./knobster.sh on` | Activa modo Editar Timeline |
| `sudo ./knobster.sh off` | Vuelve a volumen normal |
| `sudo ./knobster.sh status` | Muestra el estado actual |
| `./knobster.sh --help` | Muestra la ayuda |

```bash
# Ejemplo: crea un alias en tu ~/.bashrc
alias knobster-edicion='sudo ~/knobster/knobster.sh on'
alias knobster-multi='sudo ~/knobster/knobster.sh off'
```

---

## Modos disponibles

### 1. Modo Editar Timeline

Diseñado para editores de video (Kdenlive, DaVinci Resolve, Premiere Pro, etc.).

| Acción | Señal original | Asignación | Efecto |
|--------|---------------|------------|--------|
| Rueda arriba | `volumeup` | `macro(right right right)` | Mueve el cursor 3 frames a la derecha |
| Rueda abajo | `volumedown` | `macro(left left left)` | Mueve el cursor 3 frames a la izquierda |
| Presionar rueda | `mute` | `space` | Reproducir / Pausar |

### 2. Modo Programar Cursor

Diseñado para editores de código (VS Code, Neovim, IntelliJ, etc.).

| Acción | Señal original | Asignación | Efecto |
|--------|---------------|------------|--------|
| Rueda arriba | `volumeup` | `up` | Cursor hacia arriba |
| Rueda abajo | `volumedown` | `down` | Cursor hacia abajo |
| Presionar rueda | `mute` | `enter` | Enter / Confirmar |

### 3. Modo Multimedia

Restaura el comportamiento original de la rueda.

| Acción | Efecto |
|--------|--------|
| Rueda arriba | Subir volumen del sistema |
| Rueda abajo | Bajar volumen del sistema |
| Presionar rueda | Silenciar / Activar sonido |

### 4. Modo Personalizado

Configura cada acción de la rueda a tu gusto (ver [Personalización avanzada](#personalización-avanzada)).

---

## Personalización avanzada

### Configuración guiada

Desde el menú principal, selecciona **4 > 1** y sigue los pasos:

1. **Paso 1:** Elige qué hace la rueda al girar **arriba**
2. **Paso 2:** Elige qué hace la rueda al girar **abajo**
3. **Paso 3:** Elige qué hace al **presionar** la rueda

En cada paso puedes elegir entre opciones predefinidas o escribir tu propio comando keyd (cualquier tecla válida o macro).

**Ejemplos de comandos keyd válidos:**

| Comando | Efecto |
|---------|--------|
| `right` | Flecha derecha |
| `macro(right right right)` | Flecha derecha x3 |
| `macro(Ctrl right)` | Ctrl + Flecha derecha |
| `macro(C-s)` | Ctrl + S (guardar) |
| `up` | Flecha arriba |
| `pagedown` | Avanzar página |
| `home` | Ir al inicio |
| `esc` | Escape |
| `tab` | Tabulador |
| `f5` | Tecla F5 |

### Edición directa del archivo

Desde el menú principal, selecciona **4 > 2** para abrir el archivo de configuración en tu editor favorito (`nano` por defecto, respeta `$EDITOR` y `$VISUAL`).

El archivo se ubica en `/etc/keyd/knobster.conf`. Su estructura es:

```ini
# Knobster
# Modo: Personalizado

[ids]

320f:505b

[main]

volumeup = macro(right right right)
volumedown = macro(left left left)
mute = space
```

Puedes editarlo manualmente con cualquier editor. Al guardar, keyd se recarga automáticamente.

---

## Estructura del proyecto

```
knobster/
├── banner.txt          # Arte ASCII del logo (editable)
├── knobster.sh         # Script principal ejecutable
└── README.md           # Esta documentación
```

Además, en tiempo de ejecución:

| Archivo | Propósito |
|---------|-----------|
| `/etc/keyd/knobster.conf` | Configuración activa de keyd generada por Knobster |
| `/etc/keyd/default.conf` | Configuración por defecto de keyd (no se modifica) |

---

## Solución de problemas

### keyd no está instalado

```text
Error: keyd no está instalado.
```

**Solución:** Sigue los pasos de [Instalación de keyd](#1-instalar-keyd).

### La rueda no responde después de activar un modo

```text
El menú se muestra pero girar la rueda no hace nada.
```

**Causa más común:** El ID del teclado es incorrecto.

**Solución:**

```bash
sudo keyd monitor
```

Gira la rueda. Asegúrate de que el ID que aparece coincide con el que configuraste en Knobster. Si es diferente, actualiza la variable `KEYBOARD_ID`.

### keyd reload falla

```text
Error: No se pudo recargar keyd.
```

**Soluciones:**

```bash
# Verificar que keyd está corriendo
sudo systemctl status keyd

# Si no está corriendo
sudo systemctl enable --now keyd

# Verificar errores en la configuración
sudo keyd reload 2>&1
```

### La rueda no funciona en ninguna aplicación

```text
keyd está funcionando pero la rueda no responde ni como volumen.
```

**Posible causa:** El archivo de configuración tiene errores de sintaxis.

**Solución:**

```bash
# Eliminar la configuración de Knobster
sudo rm -f /etc/keyd/knobster.conf
sudo keyd reload
```

Si el volumen vuelve a funcionar, el problema estaba en la configuración. Usa el modo personalizado para crear una config limpia.

### Error de permisos

```text
Error: Se necesita ejecutar como root.
```

**Solución:** Antepón `sudo` al comando.

```bash
sudo ./knobster.sh
```

### El menú se ve mal (caracteres extraños)

```text
Aparecen caracteres como ╭ ╮ │ en vez del menú.
```

**Solución:** Asegúrate de que tu terminal soporta UTF-8. La mayoría de terminales modernas lo hacen. Si el problema persiste, ejecuta:

```bash
export LANG=en_US.UTF-8
```

Y vuelve a ejecutar el script.

### El banner no se muestra

```text
No aparece el logo "Knobster" al inicio.
```

**Causa:** El archivo `banner.txt` está en una ubicación diferente o falta.

**Solución:** El script busca `banner.txt` en el mismo directorio que `knobster.sh`. Asegúrate de que estén juntos.

```bash
ls -la ~/knobster/banner.txt
```

---

## Teclados compatibles

| Teclado | ID | Reportado por |
|---------|----|---------------|
| Evision AK820 | `320f:505b` | @epimient |
| _¿Tu teclado?_ | `?` | _Abre un issue_ |

Si Knobster funciona con tu teclado, abre un [Issue](https://github.com/epimient/knobster/issues/new?template=feature_request.md) para agregarlo a la lista.

---

## Contribuir

Las contribuciones son bienvenidas. Revisa [`CONTRIBUTING.md`](CONTRIBUTING.md) para guía de estilo y proceso.

- [Reportar un bug](https://github.com/epimient/knobster/issues/new?template=bug_report.md)
- [Solicitar una feature](https://github.com/epimient/knobster/issues/new?template=feature_request.md)
- [Ver changelog](CHANGELOG.md)

---

## Licencia

MIT © 2026 Ing. Eduardo Pimienta

---

## Autor

**Ing. Eduardo Pimienta**

_Desarrollador de software, creador de contenido y entusiasta de los teclados mecánicos._

Proyecto originalmente concebido para el teclado **AK820** y su comunidad Linux.

---

<p align="center">
  <a href="https://github.com/epimient/knobster">GitHub</a>
  ·
  <a href="https://github.com/epimient/knobster/issues">Issues</a>
  ·
  <a href="CONTRIBUTING.md">Contribuir</a>
  <br>
  <sub>Hecho con ❤️ y bash</sub>
</p>

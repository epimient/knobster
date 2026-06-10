# Contribuyendo a Knobster

¡Gracias por tu interés en mejorar Knobster! Este proyecto es open source y toda contribución es bienvenida.

## Cómo contribuir

### Reportar bugs

Si encuentras un error, abre un [Issue](https://github.com/epimient/knobster/issues/new?template=bug_report.md) e incluye:

- Tu distro y versión de Linux
- Modelo de teclado
- Versión de keyd (`keyd --version` o commit hash)
- Output de `sudo systemctl status keyd`
- El mensaje de error completo
- Pasos para reproducir

### Solicitar features

Abre un [Issue](https://github.com/epimient/knobster/issues/new?template=feature_request.md) describiendo:

- Qué te gustaría que hiciera Knobster
- Por qué sería útil
- Cómo imaginas la interacción

### Enviar código (Pull Requests)

1. **Fork** el repo
2. Crea una rama: `git checkout -b feature/mi-idea`
3. Haz tus cambios
4. Asegúrate de que pase el lint: `bash -n knobster.sh install.sh`
5. Commit con mensaje descriptivo
6. Push y abre un Pull Request

### Guía de estilo

- Usa `bash` con `set -uo pipefail`
- Variables en `MAYÚSCULAS` para constantes, `minúsculas` para locales
- Funciones en `snake_case`
- Mensajes de log usando las helpers: `log_info`, `log_ok`, `log_warn`, `log_error`, `log_step`, `log_debug`
- Usa `echo -e` para output con colores, `printf` para formateo preciso
- No uses `set -e`, manejamos errores manualmente

### Probar cambios

```bash
bash -n knobster.sh
bash -n install.sh
# Probar menú (requiere keyd)
sudo ./knobster.sh
```

### Reportar teclados compatibles

Si Knobster funciona con tu teclado, abre un Issue con el modelo y el ID para agregarlo a la tabla de compatibilidad.

## Código de conducta

Sé respetuoso. Este es un proyecto hecho con ❤️ para la comunidad.

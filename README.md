# Tópicos Web y Móvil · 2026-3

Repositorio personal de actividades y evidencias de Diego Rivera Cisneros.

## Proyecto 3 · Rumbo

**[Abrir el proyecto Rumbo](proyectos/rumbo)** · [Repositorio independiente](https://github.com/AnonimousMex/rumbo)

[Informe individual del Proyecto 3](actividades/proyecto-3/22121364_rivera.md) · [Informe del equipo](https://github.com/AnonimousMex/rumbo/blob/main/docs/INFORME_EQUIPO_PROYECTO_3.md) · [Evidencias web y Android](https://github.com/AnonimousMex/rumbo/blob/main/docs/evidencias/README.md)

Rumbo es una plataforma de entregas con microservicios Python, frontend React/TypeScript, cliente Flutter, datasets y modelos entrenados. Sus instrucciones de instalación, arquitectura y pruebas están en el README del proyecto.

La carpeta `proyectos/rumbo` es un **submódulo Git**: este repositorio registra una versión concreta del proyecto, mientras que el código, los commits y el desarrollo del equipo se mantienen en `AnonimousMex/rumbo`. En GitHub, hacer clic en esa carpeta abre la versión enlazada del proyecto.

Las [actividades de la materia](actividades/) se conservan en este repositorio.

### Descargar todo, incluido el proyecto

```bash
git clone --recurse-submodules https://github.com/AnonimousMex/TOPICOS-WEB-Y-MOVIL20263.git
cd TOPICOS-WEB-Y-MOVIL20263
```

Si ya habías clonado este repositorio:

```bash
git pull
git submodule update --init --recursive
```

Una clonación normal sin inicializar submódulos deja la carpeta del proyecto vacía. Para obtener el código completo, usar los comandos anteriores en lugar de depender del ZIP del repositorio principal.

### Actualizar Rumbo

Primero publicar los cambios en el repositorio independiente de Rumbo. Después, desde la raíz de este repositorio:

```bash
git submodule update --init proyectos/rumbo
git submodule update --remote proyectos/rumbo
git add proyectos/rumbo
git commit -m "Actualiza la versión de Rumbo para la entrega"
git push
```

El submódulo sigue la rama `main` al ejecutar `--remote`; los cambios de Rumbo no actualizan automáticamente la referencia guardada en este repositorio. Cada commit del repositorio principal identifica una versión concreta del proyecto.

# Retos de Django — Parte escrita

**Nombre:** Diego Rivera Cisneros  
**Matrícula:** 22121364  
**Equipo:** no indicado en el repositorio; documento individual para integrar al trabajo del equipo.


Se responde la parte teórica. Los retos 1–4 piden código y pruebas en el proyecto del equipo, excluido de esta actualización. No se aportan salidas de terminal ni capturas de una ejecución inexistente.

## Reto 2. Validación y crecimiento

El servidor valida incluso si el formulario ya lo hizo: un cliente puede omitir la interfaz, estar desactualizado o mandar datos malformados. Debe comprobar presencia, tipo, valores finitos y rango, y devolver 400 sin efectos secundarios cuando la entrada sea inválida.

Strategy permite añadir planeadores por vehículo sin agrandar la función de orquestación. Una fábrica selecciona el objeto; las reglas de factibilidad se evalúan antes. No cambiaría una cadena corta de condiciones estables solo para tener más clases.

## Reto 3. Dos clientes

Si el límite de bicicleta vive en JavaScript, cambiarlo solo actualiza el cliente web; el programa Python conserva otro criterio. Al ubicarlo en el backend, ambos consultan el mismo contrato y observan la regla vigente sin duplicarla.

## Reto 4. Memoria y sesiones

Una variable global parece funcionar con un proceso porque las peticiones leen la misma memoria mientras vive ese proceso. Aun así, dos clientes pueden sobrescribir sus destinos y confirmar el del otro. Una sesión identifica a cada cliente y conserva sus datos en un backend compartido. Es necesario configurar la misma base y claves compatibles en todas las réplicas; el almacenamiento local en RAM no lo resuelve.

## Reto 5. Casos sin código

1. **Contrato móvil:** renombrar `medios_disponibles` rompe clientes instalados. Mantendría el campo durante una transición o versionaría el endpoint, documentaría deprecación y mediría el uso antiguo antes de retirarlo. Un campo `version` informativo no implementa compatibilidad por sí solo.
2. **Aviso de las 7:00:** cinco procesos pueden ejecutar cinco veces la misma tarea. Usaría un scheduler único y workers con clave única por repartidor/fecha para tolerar reintentos sin duplicar avisos.
3. **Foto intermitente:** cada contenedor tiene su sistema de archivos; una petición posterior puede caer en otro. Guardaría el archivo en almacenamiento compartido y su referencia en la base. Un volumen local aislado por réplica tampoco garantiza que las demás lo vean.
4. **Docker y venv:** puede desarrollarse enteramente en contenedores sin un venv local si todas las herramientas se ejecutan allí. Si se corre Python en el host, un venv evita conflictos de dependencias. Ninguno sustituye versiones fijadas ni el otro es obligatorio en cualquier flujo.
5. **Doble pago:** las dos peticiones pueden llegar a réplicas distintas. Una bandera en memoria no basta: se necesita idempotencia compartida, restricción única del intento y clave estable también ante el proveedor bancario. Si el estado del banco es incierto, se concilia antes de crear otro intento.

**Fuente:** [retos de la ruta de Django](https://ealcaraz85.github.io/topicoswebmobil/#orgf1a1c36).

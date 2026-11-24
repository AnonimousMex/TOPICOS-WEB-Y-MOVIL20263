# Guía de defensa — Tesitura (Proyectos 1 y 2)

Diego Rivera Cisneros · 22121364 · dominio: instrumentos musicales · el recomendador decide el **nivel de embalaje y seguro** (básico / reforzado / premium).

Esta guía es para estudiar. No va en el repositorio como entrega; si quieres, bórrala antes de subirlo.

---

## 1. La idea en 30 segundos (apréndela de memoria)

> «Es una tienda de instrumentos con tres piezas de inteligencia que el servidor controla. Un **árbol de decisión** entrenado con un dataset que generé en Python propone el embalaje y su confianza. Unas **reglas de negocio** escritas a mano lo corrigen cuando el modelo se queda corto (por ejemplo, un instrumento de más de $15,000 siempre lleva seguro total). Y un **asistente** entrenado con mi propio dataset de intenciones clasifica lo que pregunta el comprador y responde con datos de la base, pero **nunca decide el embalaje por su cuenta**: para eso remite al recomendador. Todo eso vive en un solo Django con SQLite; Flutter solo muestra y manda datos.»

Tres ideas que debes poder repetir:
1. **El modelo estima, las reglas garantizan.** (`reglas.py` va después del modelo.)
2. **La decisión es del servidor.** Flutter no tiene el `.joblib`, ni las reglas, ni confía en lo que envía el cliente.
3. **El asistente entiende; no decide.** El modelo solo predice la *intención*; la respuesta sale del código y de la base.

---

## 2. Cómo arrancarlo para la exposición

```bash
# 1) Backend (desde backend/)
./.venv/bin/python manage.py migrate
./.venv/bin/python manage.py cargar_datos          # 194 productos, 51 marcas
./.venv/bin/python manage.py crear_admin jefe@tienda.mx   # pide la contraseña sin mostrarla
./.venv/bin/python manage.py runserver 8000

# 2) App web (desde app/)
flutter build web --wasm --pwa-strategy=none
python3 servir_web.py 8090 --aislado               # abre http://localhost:8090
```

- Si el puerto 8000 está ocupado (en tu Mac lo ocupa un `ssh`), usa otro (`runserver 8001`) y compila con `--dart-define=API_URL=http://localhost:8001/api`, o cámbialo en la app (icono de servidor → «URL del servidor»). **Esto cumple el requisito «URL base configurable».**
- Pruebas: `./.venv/bin/python manage.py test` (81) y `flutter test` (23).
- Tarjeta de prueba: botón «rellenar con tarjeta de prueba» (4242 4242 4242 4242). El pago es simulado: nunca se guarda el número ni el CVV.

---

## 3. Guion de exposición (≈12–15 min)

El patrón que usaste en el Proyecto 3: **diapositiva corta → ir a la app → volver al código**. Aquí igual. Cada paso dice qué mostrar y qué decir.

| # | Qué muestras | Qué dices (una frase) | Archivo si preguntan |
|---|---|---|---|
| 1 | Diapositiva: el problema | «Un instrumento mal embalado llega dañado; el costo y el seguro dependen del valor, el peso, la humedad del destino y la distancia.» | — |
| 2 | Diapositiva: arquitectura (un solo cuadro: Flutter → JSON → Django → SQLite + `.joblib`) | «Monolito con API: no necesito microservicios (ver §7).» | `tienda/urls.py` |
| 3 | App: inicio, buscar «Yamaha», filtrar | «Catálogo con búsqueda y filtros; todo viene del servidor.» | `views.productos`, `listado_page.dart` |
| 4 | App: **Ingresar → Crear cuenta** (mostrar contraseña débil rechazada) | «Para pagar hace falta cuenta. La contraseña se guarda con hash; el servidor decide los permisos.» | `autenticacion.py`, `cuenta_page.dart` |
| 5 | App: abrir una guitarra → elegir destino | «El recomendador decide por producto y ciudad: muestra nivel, confianza, ranking y la razón.» | `recomendador.py`, `producto_page.dart` |
| 6 | App: pie de página → «Recomendador de embalaje» y captura **el caso donde las reglas corrigen** (ver abajo) | «El modelo dijo “reforzado” con 86 % de confianza; la regla R1 (valor ≥ $15,000) lo subió a “premium”. Aquí se ve por qué no basta el modelo.» | `reglas.py` |
| 7 | App: carrito → pagar con tarjeta de prueba → **folio MUS-…** | «Compra transaccional: todas las líneas o ninguna; llega correo de confirmación.» | `views.checkout`, `correos.py` |
| 8 | App: **Mis compras** y consultar el folio en el chat | «El asistente reconoce mi folio porque estoy autenticado; sin sesión no detalla un pedido ajeno.» | `asistente.py` (`_verificar`) |
| 9 | App: chat — «hola», «¿cómo va mi pedido?», «¿qué guitarra Fender tienen?», **«¿qué embalaje necesito para un piano?»**, «cuál es la capital de Francia» | «Saludo, folio, dominio, remisión al recomendador y fuera de dominio: los cuatro casos que pide el curso.» | `asistente.py` |
| 10 | App (como admin): **Bitácora de auditoría** | «Cada escritura y cada error quedan registrados con usuario, rol, ruta, estado e IP; nunca el cuerpo.» | `auditoria.py` |
| 11 | Terminal: `generar_dataset.py` y `entrenar_recomendador.py` | «Dataset sintético, entrenamiento fuera de la petición, métrica y `.joblib`.» | `ml/` |
| 12 | Diapositiva: patrones + límites honestos | «Strategy, Adapter, Facade, Observer…, y lo que no hice.» | `ANALISIS_PATRONES.md` |

**Caso verificado para la captura (lo corrí con el modelo real):** guitarra, condición nuevo, valor **$15,200**, peso 3 kg, dimensión 105 cm, distancia **15 km**, frágil sí, cantidad 1, humedad baja, zona baja, temporada secas, no urgente → el modelo propone **reforzado (≈ 86 %)** y las reglas lo corrigen a **premium** (R1_VALOR_ALTO). Con un teclado de $15,500 y 20 km pasa lo mismo (reforzado 84 % → premium).

**Truco de ensayo:** haz una vez el recorrido 3→10 completo antes del martes. Así no improvisas frente al profesor.

---

## 4. Mapa de archivos (si te piden «mueve/cambia X»)

Raíz: `proyectos/tienda-musica/`.

### Backend — `backend/`
| Quiero… | Archivo | Qué hay ahí |
|---|---|---|
| Ver las URL de la API | `catalogo/urls.py` y `tienda/urls.py` | Front Controller: cada ruta apunta a una vista |
| Cambiar un endpoint | `catalogo/views.py` | Vistas finas: validan, llaman a servicios, devuelven JSON |
| Tablas | `catalogo/models.py` | `Producto`, `Compra`, `Pedido`, `Correo`, `ConsultaAsistente`, `ContextoAsistente`, `Sesion`, `IntentosLogin`, `Auditoria` |
| Datos de prueba (194 productos) | `catalogo/datos_catalogo.py` + `manage.py cargar_datos` | Catálogo, ciudades, bodega |
| **Cambiar una regla de negocio** | `catalogo/reglas.py` | R1–R8 (pisos y techos sobre el nivel del modelo) |
| **Cambiar el modelo que decide** | `catalogo/recomendador.py` | Interfaz `RecomendadorIA`; `RecomendadorModelo` (.joblib), `RecomendadorReglas` (respaldo), `RecomendadorConRespaldo`, `obtener_recomendador()` |
| Qué lleva cada nivel (materiales, seguro) | `catalogo/niveles.py` | Strategy: `Basico`, `Reforzado`, `Premium` |
| Validar el formulario | `catalogo/validacion.py` | El servidor rechaza campos faltantes con 400 |
| Armar entradas del modelo desde producto + ciudad | `catalogo/envios.py` | El cliente no declara valor ni peso: salen de la base |
| Ubicación actual | `catalogo/geo.py` | Ciudad cercana por distancia (haversine), sin enviarla a terceros |
| Pago simulado | `catalogo/pagos.py` | Solo tarjetas de prueba; descarta número y CVV |
| Correo de confirmación | `catalogo/correos.py` | Modo consola (guarda HTML en `backend/correos_enviados/`) o SMTP con `.env` |
| **Login, registro, token** | `catalogo/autenticacion.py` | Hash, token con SHA-256 en base, bloqueo 5 fallos/15 min, roles |
| **Auditoría** | `catalogo/auditoria.py` + `views.auditoria` | Middleware que escribe en `Auditoria`; solo ADMIN la consulta |
| Asistente (8 capas) | `catalogo/asistente.py` | Seguridad → router → memoria → herramientas → permisos → evidencia → observabilidad → escalamiento |
| Textos que consulta el asistente (RAG) | `catalogo/corpus/*.md` + `chunks.jsonl` | Documentos públicos e internos |
| CORS | `catalogo/cors.py` | Necesario para Flutter web |
| Configuración | `tienda/settings.py` | `.env`, correo, token interno |
| Evaluar el asistente | `manage.py evaluar_asistente` | 16 casos esperados |
| Pruebas | `catalogo/tests.py` | 81 pruebas |

### Aprendizaje automático — `backend/ml/`
| Archivo | Qué hace |
|---|---|
| `generar_dataset.py` | Genera el CSV sintético (`--filas`, `--semilla`, `--faltantes`) |
| `datos/envios_instrumentos.csv` | 10,000 envíos: 12 columnas de entrada + `nivel_embalaje` |
| `entrenar_recomendador.py` | Entrena árbol y bosque, escribe `reportes/entrenamiento.md` y los `.joblib` |
| `modelos/recomendador_arbol.joblib` | **El modelo que usa el servidor** (33 KB) |
| `modelos/recomendador_bosque.joblib` | Comparación (13 MB) |
| `entrenar_asistente.py` | Dataset de intenciones + entrenamiento del asistente |
| `datos/intenciones.csv` | ~746 frases, 12 intenciones, columna `grupo` |
| `modelos/asistente.joblib` | Clasificador de intenciones |
| `usar_modelo.py` / `probar_modelo.py` | Cargar el modelo y predecir sin Django |

### Flutter — `app/lib/`
| Quiero… | Archivo |
|---|---|
| Todas las llamadas HTTP (Facade) | `api.dart` (`RumboApi`, modelos `fromJson`, `token`) |
| Estado global: carrito, sesión, chat | `state.dart` (`Tienda`, `TiendaScope`) |
| Guardar URL del servidor / token | `configuracion_servidor.dart` |
| Colores y animaciones | `theme.dart` |
| Pantallas | `pages/`: `home_page`, `listado_page`, `producto_page`, `carrito_page`, `compra_page`, `recomendar_page`, **`cuenta_page`** (login, mis compras, bitácora) |
| Encabezado, menú de cuenta, chat flotante | `widgets/marco.dart`, `widgets/chat_panel.dart` |
| Ubicación actual | `ubicacion.dart` (`ServicioUbicacion`, inyectable) |
| Pruebas | `test/widget_test.dart` |

---

## 5. Cómo se hizo cada cosa (lo que el profesor pregunta)

### 5.1 El dataset del recomendador
- **Script:** `ml/generar_dataset.py` (Python + numpy + pandas). Reproducible: misma `--semilla` → mismo CSV.
- **Qué contiene:** 10,000 envíos sintéticos. Entradas: `tipo`, `condicion`, `valor_mxn`, `peso_kg`, `dimension_max_cm`, `distancia_km`, `fragil`, `cantidad`, `humedad_destino`, `zona_riesgo`, `temporada`, `urgente`. Salida: `nivel_embalaje`.
- **Cómo se etiqueta:** una «puntuación de riesgo» suma tipo, valor, distancia, fragilidad, peso, humedad (solo daña madera), zona, temporada, urgencia, condición y cantidad; se le suma ruido gaussiano y se cortan dos umbrales (2.2 y 3.7) para obtener ~25 % básico, ~40 % reforzado, ~35 % premium. Además, **5 % de etiquetas se cambian a propósito** para que el modelo no memorice una fórmula perfecta.
- **Por qué sintético:** no tengo envíos reales de una tienda. Lo digo abiertamente: **las métricas miden el dataset, no el mundo real.**
- `--faltantes 0.03` deja huecos al azar para practicar imputación.

### 5.2 El entrenamiento del recomendador
- **Script:** `ml/entrenar_recomendador.py`, **fuera de la petición HTTP** (el servidor solo carga el `.joblib`).
- **Partición:** 8,000 filas entrenamiento / 2,000 prueba (20 %, estratificada, `random_state=42`).
- **Pipeline:** preprocesamiento (mediana para huecos numéricos + one-hot para las categóricas) y modelo, todo dentro del mismo `Pipeline`, así que se guarda junto y no hay desajuste entre entrenamiento y servicio.
- **Modelo principal: árbol de decisión** `max_depth=8`, `min_samples_leaf=5`. Exactitud en prueba **0.767**. **Comparación: Random Forest** (200 árboles, profundidad 10): **0.805**.
- **¿Por qué el árbol si el bosque es mejor?** Es 400 veces más pequeño (33 KB vs 13 MB), se puede **explicar** (`export_text` en el reporte) y la diferencia no justifica perder explicabilidad: las reglas de negocio ya corrigen los errores de seguridad.
- **Sobreajuste:** el reporte incluye una tabla `max_depth` vs exactitud de entrenamiento/prueba; con 8 la brecha es controlada.
- **Matriz de confusión:** el error típico es confundir «reforzado» con sus vecinos, y **nunca** se confunde básico con premium (importa: el peor error sería mandar «básico» a algo que necesita seguro total).
- **Confianza:** es la probabilidad que da el árbol a la clase elegida (`predict_proba`). Es la confianza *del modelo*, no una garantía.

### 5.3 Las reglas (`reglas.py`)
Se aplican **después** del modelo y solo mueven el nivel hacia arriba (pisos) o abajo (techo):
R1 valor ≥ $15,000 → premium · R2 cuerda frotada → ≥ reforzado · R3 peso ≥ 20 kg o dimensión ≥ 120 cm → ≥ reforzado · R4 ≥ 800 km y valor ≥ $5,000 → ≥ reforzado · R5 frágil y ≥ $8,000 → ≥ reforzado · R7 humedad alta en madera → ≥ reforzado · R8 zona de riesgo alta y ≥ $8,000 → premium · R6 accesorio < $800 → máximo reforzado.
La respuesta incluye `corregido_por_reglas` y la lista de reglas con su motivo: ese es el «caso en que las reglas corrigen al modelo».

### 5.4 El entrenamiento del asistente
- **Script:** `ml/entrenar_asistente.py` (dataset incluido en el mismo archivo y exportado a `datos/intenciones.csv`).
- **Dataset propio:** ~746 frases en 12 intenciones (saludo, despedida, consulta de folio, explicar recomendación, buscar producto, ofertas, envíos, devoluciones, etc.), con varias redacciones por idea. Cada fila tiene un **grupo**: las paráfrasis de una misma idea van del mismo lado de la validación para no inflar la métrica con casi-duplicados.
- **Modelo:** TF-IDF (palabras 1–2 + caracteres 2–5, así tolera faltas de ortografía) + **regresión logística** (`class_weight="balanced"`). Métrica: validación cruzada por grupos ≈ **0.78**.
- **Lo que predice el modelo:** solo la **intención**. La respuesta la arma el código (`asistente.py`) con datos de la base (productos, folios) o con recuperación sobre el corpus (RAG con TF-IDF).
- **Fuera de dominio / baja confianza:** el asistente se abstiene o escala a una persona; no inventa.
- **No decide el embalaje:** si preguntas «¿qué embalaje necesito?», remite al recomendador. Eso es lo que pide el curso.

### 5.5 Login, roles y auditoría (lo nuevo)
- **Registro** (`POST /api/auth/registro/`): valida correo y contraseña (8–72 caracteres, mayúscula, minúscula y número) y crea el usuario con el hash PBKDF2 de Django. **La contraseña nunca se guarda en claro.**
- **Login** (`POST /api/auth/login/`): devuelve un **token opaco** (`secrets.token_urlsafe(48)`). En la base solo se guarda su **SHA-256**: si alguien roba la base de datos, los tokens no sirven. Dura 7 días y se revoca con `logout`.
- **Mismo mensaje para «no existe» y «contraseña mala»** y siempre se calcula un hash (aunque el correo no exista), para no revelar qué correos están registrados.
- **Bloqueo:** 5 fallos → cuenta bloqueada 15 min (423).
- **Roles:** `CLIENTE` y `ADMIN` (`is_staff`). El admin se crea con `manage.py crear_admin`; **no hay forma de volverse admin desde la API**.
- **Permisos en el servidor:** pagar exige sesión (401 si no); el correo de la compra es el de la cuenta (no se puede mandar a otro); `/api/auditoria/` solo ADMIN (403 a los demás); el asistente usa el correo de la cuenta para verificar tus folios.
- **Auditoría:** `AuditoriaMiddleware` guarda, para escrituras (POST), errores (≥ 400) y consultas de bitácora: usuario, rol, método, ruta, estado, IP, duración y un `X-Request-Id`. **No guarda el cuerpo** (ahí viajan contraseñas y tarjetas).
- **En Flutter:** `Tienda` guarda el usuario; `RumboApi` añade `Authorization: Bearer` a cada llamada; `AlmacenSesion` guarda el token en el dispositivo y al abrir la app `restaurarSesion()` lo valida con `/auth/yo/`.

---

## 6. Qué tomé de Rumbo y qué simplifiqué (para estudiar la auditoría)

En Rumbo, la auditoría y el login están en:
- `backend/rumbo/services/auth.py` — registro, login, refresh y verificación por código de correo.
- `backend/rumbo/app.py` (middleware, líneas ~170–200) — publica el evento `auditoria.registrada`.
- `backend/rumbo/services/analytics.py` (~línea 164) — recibe el evento y lo escribe en la tabla `AuditLog`.

| Tema | Rumbo (microservicios) | Tesitura (monolito) | Por qué la diferencia |
|---|---|---|---|
| Hash de contraseña | bcrypt, 12 rondas | PBKDF2 de Django | Ambos son hashes lentos con sal; Django ya trae PBKDF2 |
| Sesión | JWT de 15 min + *refresh token* de 7 días en cookie `httpOnly` | Un token opaco de 7 días con hash en base | Un solo servicio: no hace falta que otros servicios verifiquen un JWT sin consultar la base |
| Verificación de correo | Código de 6 dígitos por correo | No lo hice | Fuera del alcance de P1/P2; el correo se usa para confirmaciones |
| Bloqueo | 5 fallos → 15 min | Igual | Misma regla |
| Auditoría | El gateway **publica un evento** por Redis; el servicio de analítica lo guarda | Un **middleware** escribe directo en SQLite | Rumbo tiene procesos separados que necesitan comunicarse por eventos; yo tengo uno solo |
| Qué se audita | Escrituras, errores, reportes y bitácora | Igual (escrituras, errores y bitácora) | Misma política: no auditar cada lectura |
| Roles | ADMIN, CLIENTE, REPARTIDOR | ADMIN, CLIENTE | Mi dominio no tiene repartidores |

**Mensaje para el profesor:** «Es el mismo diseño de seguridad, a escala de monolito. Donde Rumbo necesita un evento entre servicios, aquí basta una llamada dentro del mismo proceso.»

**Lo que debes saber de la auditoría de Rumbo si te preguntan:** nace del requisito de saber *quién hizo qué*; se registra a nivel de petición HTTP (no de negocio), no guarda cuerpos, y está desacoplada del trámite: si falla, el pedido no se cancela.

---

## 7. «¿Por qué no microservicios?» (la pregunta que más te harán)

**Respuesta corta:** porque no tengo ninguna de las razones que los justifican, y distribuir antes de necesitarlo solo agrega costos.

**Respuesta completa (según los apuntes, sección «De una aplicación Django + Flutter a microservicios»):**
1. **Separar Flutter de Django no es microservicios.** Eso es cliente-servidor. Microservicios son *procesos y responsabilidades separados* que se despliegan solos.
2. **Mi sistema es un monolito con API**, y está bien para este alcance: un solo equipo (yo), una sola base, una carga pequeña.
3. **No hay escalamiento independiente que pedir.** El modelo pesa 33 KB y predice en milisegundos dentro del mismo proceso; no hay GPU ni proceso especializado.
4. **Distribuir cuesta:** latencia y fallos de red, fallos parciales, consistencia eventual y costo operativo. Mi compra necesita una **transacción única** (cobro + pedidos + stock); repartirla en servicios la volvería una transacción distribuida.
5. **El monolito ya está modular** (reglas, modelo, pagos, correos, geo y asistente son módulos separados). Si algún día hay que extraer el recomendador, el patrón Adapter (`RecomendadorIA`) ya aísla esa frontera: cambiaría la implementación, no las vistas.
6. **En Rumbo sí lo justifiqué** (Proyecto 3): Pedidos, Despacho e Inteligencia son procesos distintos, con PostgreSQL y Redis, porque hay equipo, necesidad de aislar el modelo y varios clientes.

**Preguntas relacionadas:**
- *«¿Y si se cae la IA?»* En mi monolito, `RecomendadorConRespaldo` responde con reglas simples: la tienda sigue vendiendo.
- *«¿Cuándo extraerías el recomendador?»* Si necesitara escalar aparte, usar otra tecnología (GPU) o lo mantuviera otro equipo.
- *«¿Un endpoint = un microservicio?»* No. Tener varios endpoints en un proceso no es distribuir.

---

## 8. Preguntas probables y respuesta lista

**Modelo y datos**
1. *¿Por qué datos sintéticos?* No existen envíos reales de mi tienda. Los generé con una regla de negocio plausible más ruido (y 5 % de etiquetas cambiadas). Las métricas describen el dataset, no el mundo real.
2. *¿No es trampa que el modelo aprenda la fórmula con la que etiqueté?* Es una limitación real y la declaro: parte de lo que aprende es esa puntuación. El ruido evita una exactitud artificial de 100 %, y las reglas de negocio no dependen del modelo.
3. *¿Qué es la confianza?* La probabilidad que el árbol asigna a la clase elegida.
4. *¿Por qué 0.77 si el bosque da 0.81?* Elegí explicabilidad y tamaño; las reglas cubren los errores peligrosos.
5. *¿Qué es sobreajuste y cómo lo revisaste?* Un modelo que memoriza el entrenamiento. Comparé exactitud de entrenamiento vs prueba por profundidad (tabla del reporte) y limité `max_depth` y `min_samples_leaf`.
6. *¿Por qué una partición estratificada?* Para que las tres clases mantengan su proporción en entrenamiento y prueba.
7. *¿Se reentrena en cada petición?* No. Se entrena una vez (`entrenar_recomendador.py`) y el servidor carga el `.joblib` una sola vez (`lru_cache`).
8. *¿Dónde vive el modelo?* En el servidor. Flutter nunca lo tiene.
9. *¿Qué hace el recomendador si el `.joblib` falta?* `RecomendadorConRespaldo` usa reglas simples.

**Reglas y diferencia modelo/reglas**
10. *¿Cuál es la diferencia entre el modelo y las reglas?* El modelo estima desde ejemplos; las reglas son mínimos de seguridad que no se negocian. Una regla puede subir o bajar el nivel y siempre deja constancia (`corregido_por_reglas`, motivo).
11. *Dame un caso donde corrigen.* Guitarra de $15,200 a 15 km, humedad y zona bajas: el modelo dice reforzado (≈ 86 %) y R1 (valor ≥ $15,000) la sube a premium.

**Asistente**
12. *¿Cómo entrenaste el asistente?* Dataset propio de ~746 frases / 12 intenciones; TF-IDF + regresión logística; validación por grupos ≈ 0.78; guardado en `.joblib`.
13. *¿Entonces el modelo escribe las respuestas?* No. Solo clasifica la intención; la respuesta sale del código y la base. Por eso no inventa precios ni pedidos.
14. *¿Qué pasa con una pregunta fuera de dominio?* Se abstiene o escala a una persona.
15. *¿Qué es RAG aquí?* Recuperar fragmentos del corpus (`catalogo/corpus/`) con TF-IDF y responder citando la fuente; hay corpus público e interno según el rol.
16. *¿Cómo evitas que el chat revele información de otro cliente?* Un folio con dueño solo se detalla si hay sesión y coincide el correo de la cuenta.
17. *¿Y el chat decide el embalaje?* Nunca: remite al recomendador o lee lo registrado.

**Seguridad**
18. *¿Cómo guardas las contraseñas?* Con hash PBKDF2 de Django, nunca en claro.
19. *¿Y el token?* Solo se guarda su SHA-256; vence a los 7 días y se revoca al cerrar sesión.
20. *¿Qué pasa si alguien cambia el rol en Flutter?* Nada: el servidor decide con `is_staff`. Flutter solo muestra u oculta botones; la API responde 403 igual.
21. *¿Por qué guardas el token en el dispositivo y no en una cookie?* Es un compromiso: en web, un token en almacenamiento local es legible por scripts de la misma página; Rumbo usa cookie `httpOnly`. Aquí no hay contenido de terceros y el token vence y se revoca. Si fuera producción, usaría cookie `httpOnly`.
22. *¿Guardas tarjetas?* No. El pago es simulado: solo acepta tarjetas de prueba y descarta número y CVV; se guarda marca, últimos 4 dígitos y una referencia.
23. *¿Qué registra la auditoría?* Usuario, rol, método, ruta, estado, IP y duración de escrituras y errores. No cuerpos.
24. *¿Cómo evitas que un cliente declare un valor falso para pagar menos embalaje?* El cliente manda producto, cantidad y ciudad; el valor, peso y dimensión salen de la base (`envios.py`).

**Arquitectura y patrones**
25. *¿Dónde está Strategy?* `niveles.py`: cada nivel arma su plan; agregar un nivel no toca vistas.
26. *¿Dónde está Adapter?* `recomendador.py` (interfaz `RecomendadorIA`) y `adaptar_respuesta` en `asistente.py`.
27. *¿Facade?* `RumboApi` en `api.dart`.
28. *¿Observer?* `Tienda` (`ChangeNotifier`) + `TiendaScope`.
29. *¿Front Controller?* Django enruta todo desde `urls.py`.
30. *¿Repository?* Parcial: uso el ORM de Django; no escribí una clase propia. Está dicho en `ANALISIS_PATRONES.md`.
31. *¿MVC?* Modelo `models.py`, controlador `views.py`; la «vista» es JSON, no HTML. En Flutter no es MVC clásico: es `State` + composición de widgets + cliente API.
32. *¿Por qué SQLite?* Lo pide el curso para P1/P2 y es suficiente para un proceso. Con varias réplicas pasaría a PostgreSQL.

**Cliente móvil/web**
33. *¿Cómo funciona en web y Android?* Mismo código Dart. Cambia la URL base: `localhost` en web, `10.0.2.2` en el emulador Android, la IP de la Mac en un teléfono. Está probado en web y en el emulador de Android (ver §13).
34. *¿Qué pasa si el servidor no responde?* La fachada captura el error y la pantalla muestra «No se pudo conectar…» con botón de reintento.

---

## 9. Lo que NO debes afirmar (límites honestos)

- Las **fotos** de productos son de Wikimedia Commons y muchas son del modelo genérico o de la marca, no del artículo exacto (créditos en `CREDITOS_IMAGENES.md`).
- **Calificaciones, ventas, existencias, humedad y zona de riesgo** de las ciudades son **datos de demostración**.
- El **pago es simulado** y el **correo** está en modo consola salvo que configures SMTP en `backend/.env`.
- **Android:** la APK 1.0.1 (anterior al login) tiene capturas en `evidencias/android/`; además, el recorrido completo con sesión corrió en el emulador de Android 35 desde el código (compilación de depuración con flutter drive, prueba `app/integration_test/compra_test.dart`, resultado «correcto», 10 capturas en evidencias/android_sesion/): contraseña débil rechazada, registro, embalaje por ciudad, pago con tarjeta de prueba, folio, Mis compras, el chat consultando ese folio y 401 sin sesión. **No está probado:** el archivo APK release con login ejecutando ese recorrido, un teléfono físico y el GPS real. Ver §13.
- **No hay verificación de correo ni recuperación de contraseña** (Rumbo sí tiene códigos por correo).
- Las métricas del modelo (0.77 / 0.81 / 0.78) **no son rendimiento real**.
- **Los apuntes no piden login** en los Proyectos 1 y 2; lo agregué por diseño (cuentas, roles, auditoría). Si te lo preguntan: «es una mejora para pagar y ver mis pedidos; el requisito mínimo ya estaba cubierto sin él».

---

## 10. Checklist contra los apuntes (Proyectos 1 y 2)

**Proyecto 1**
- [x] Django + SQLite, modelos de catálogo y pedidos, datos de prueba → `models.py`, `cargar_datos`
- [x] JSON de listado y detalle → `productos/`, `productos/<id>/`
- [x] `POST` que ejecuta modelo + reglas y registra → `recomendar/`, `envio/`, `pedidos/`, `checkout/`
- [x] `GET` por folio → `pedidos/<folio>/`
- [x] Respuesta con decisión, confianza, si las reglas corrigieron y ranking → `recomendador.recomendar()`
- [x] Flutter: lista, detalle, búsqueda, formulario con campos del modelo, pantalla de recomendación, folio, carga, errores y URL configurable
- [x] Análisis de patrones → `ANALISIS_PATRONES.md`
- [x] Dataset generado con Python → `ml/generar_dataset.py`
- [ ] **Capturas del flujo completo y de un caso donde las reglas corrigen** → hay que tomarlas (tú, con la app corriendo)
- [ ] **Párrafo comparando con el ejemplo de clase** → pendiente de redactar

**Proyecto 2**
- [x] Dataset propio de intenciones, entrenamiento fuera de la petición, `.joblib`, métrica → `ml/entrenar_asistente.py`
- [x] `POST` del asistente con `intencion` y `respuesta`, consulta folios/productos, remite al recomendador
- [x] Pantalla de chat en Flutter que convive con las del Proyecto 1
- [x] Análisis de patrones actualizado (Adapter, separación cliente/servidor, diferencia recomendador/asistente)
- [ ] **Capturas del chat: saludo, folio, dominio y fuera de dominio** → pendiente
- [ ] **Nota breve del enfoque** → este documento y el README la cubren; falta una versión de una página si el profesor la pide aparte

**Extras (no pedidos)**: login con roles y auditoría, pago simulado, correo, ubicación actual, 8 capas del asistente.


---

## 11. Flutter: cómo está armado (para explicarlo y para moverle)

### 11.1 Las cinco ideas
1. **Todo es un widget.** Una pantalla es un árbol de widgets. `StatelessWidget` = no cambia por sí mismo (ej. `ProductoCard`, `Seccion`). `StatefulWidget` = guarda estado que cambia y se redibuja con `setState` (ej. `ListadoPage`: `_cargando`, `_error`, la lista).
2. **Dos tipos de estado.** *Local* (de una pantalla): `State` + `setState`. *Global* (sobrevive a la navegación: carrito, sesión, chat): la clase `Tienda` en `state.dart`, un `ChangeNotifier` que se publica con `TiendaScope` (un `InheritedNotifier`). Cuando `Tienda` llama `notifyListeners()`, solo se redibujan los widgets que la leyeron con `TiendaScope.of(context)`. Es el patrón **Observer**.
3. **Toda la red pasa por una fachada.** Las pantallas nunca usan `http` ni JSON: llaman métodos de `RumboApi` (`api.dart`): `productos()`, `cotizarEnvio()`, `comprar()`, `preguntar()`, `login()`. `RumboApi._pedir()` es el único lugar donde se hace la llamada, se pone el timeout, se decodifica el JSON y se convierten los errores en `ApiException`. Es el patrón **Facade**.
4. **El JSON se convierte en objetos tipados** con `fromJson` (`Producto`, `Recomendacion`, `Usuario`…). Si el servidor cambia un nombre de campo, se corrige en un solo lugar.
5. **Toda carga tiene tres estados:** cargando (`CircularProgressIndicator`), error (`ErrorConReintento` con botón «Reintentar») y datos. Así se cumple «carga y errores de red» del Proyecto 1.

### 11.2 Mapa de archivos de Flutter (`app/lib/`)
| Archivo | Qué hace | Cuándo lo tocarías |
|---|---|---|
| `main.dart` | Arranca la app: lee la URL guardada, crea `Tienda`, monta `MaterialApp` con el tema | Cambiar la pantalla inicial o activar/desactivar el chat (`CHAT`) |
| `api.dart` | `RumboApi` (HTTP), modelos `fromJson`, `ApiException`, `urlBasePorDefecto()` | Agregar un endpoint o un campo |
| `state.dart` | `Tienda`: carrito, destino, ubicación, sesión, chat | Cambiar reglas del carrito o de la sesión |
| `configuracion_servidor.dart` | Guarda la URL del servidor (`ConfiguracionServidor`) y el token (`AlmacenSesion`) | Cambiar dónde se guarda algo |
| `theme.dart` | Colores, formas, duraciones de animación | Cambiar la apariencia |
| `ubicacion.dart` | `ServicioUbicacion` (interfaz) y `UbicacionReal` (GPS/navegador) | Probar sin GPS (se inyecta uno falso) |
| `pages/home_page.dart` | Inicio: banner, marcas, ofertas | |
| `pages/listado_page.dart` | Resultados, filtros, orden, paginación perezosa | Agregar un filtro |
| `pages/producto_page.dart` | Detalle y **embalaje recomendado por ciudad** (`_cotizar`) | Cambiar lo que se muestra de la recomendación |
| `pages/recomendar_page.dart` | **Formulario con los campos del modelo** (Proyecto 1) | Agregar un campo del modelo |
| `pages/carrito_page.dart` | Carrito, destino, tarjeta de prueba, pagar | Cambiar el flujo de pago |
| `pages/compra_page.dart` | Confirmación con **folio**, pago y correo | |
| `pages/cuenta_page.dart` | Login/registro, Mis compras, Bitácora | |
| `widgets/marco.dart` | Encabezado, categorías, menú de cuenta, pie, **botón y panel del chat** | Quitar el chat de la interfaz |
| `widgets/chat_panel.dart` | El **chat** (burbujas, 👍/👎, tarjetas de producto, traza) | Cambiar el chat |
| `widgets/*.dart` (otros) | Piezas reutilizables: tarjeta de producto, selector de destino, formulario de tarjeta | |
| `test/widget_test.dart` | 23 pruebas con un servidor falso | |

### 11.3 Seguir una petición de punta a punta (ejemplo: «embalaje recomendado»)
1. En `producto_page.dart`, el usuario elige una ciudad → `_cotizar()` activa `_cotizando = true` (`setState`) → se muestra el indicador de carga.
2. `_cotizar()` llama `t.api.cotizarEnvio(producto.id, cantidad, destino)`.
3. En `api.dart`, `cotizarEnvio` hace `POST {baseUrl}/envio/` con producto, cantidad y destino a través de `_pedir()` (timeout 15 s; si no hay red lanza `ApiException('No se pudo conectar con…')`).
4. En Django, `urls.py` → `views.envio` → `validacion.py` → `envios.entradas_desde_producto()` (valor, peso y dimensión salen de la base) → `recomendador.recomendar()` (árbol + reglas) → `JsonResponse`.
5. De vuelta en Flutter: `Recomendacion.fromJson(c)` → `setState` guarda el resultado → `_EnvioProtegido`/`_Resultado` pinta nivel, confianza, razón y plan.
6. Si algo falla, el `catch (ApiException e)` guarda `_error` y la pantalla muestra el mensaje con «Reintentar».

### 11.4 Preguntas de Flutter que suelen hacer (y los apuntes también)
- **¿Por qué Flutter dibuja sus propios controles?** Porque usa su propio motor de render (en web, WebAssembly/CanvasKit): la misma interfaz se ve igual en web y Android; no traduce a controles nativos.
- **StatelessWidget vs StatefulWidget:** el primero no tiene estado propio que cambie; el segundo sí y se redibuja con `setState`.
- **¿Qué hace `setState`?** Marca el widget como «sucio» y Flutter vuelve a ejecutar `build`. Hacerlo después de un `await` exige revisar `if (!mounted) return;` por si la pantalla ya se cerró (lo hago en cada carga).
- **¿Para qué `dispose()`?** Libera controladores (`TextEditingController`, `PageController`) al destruir la pantalla.
- **`Column` sin `Expanded` / `ListView` dentro de `Column`:** una `Column` no limita la altura de sus hijos; un `ListView` dentro necesita `Expanded` o altura fija o se desborda.
- **`ListView` vs `SnackBar`:** el primero lista contenido desplazable; el segundo es un aviso temporal.
- **`CircularProgressIndicator` y una llamada real:** el indicador gira mientras el `Future` no termina; es el paralelo visual de la espera de `await`.
- **¿Por qué `async/await` y `Future`?** La llamada HTTP tarda; mientras espera, la interfaz no se congela.
- **¿Cómo se prueba Flutter sin servidor?** `TiendaApp(api: …)` recibe un cliente HTTP falso (inyección de dependencias); las 23 pruebas lo usan.
- **¿Cómo cambia la URL del servidor?** Icono de servidor en el encabezado (se guarda con `ConfiguracionServidor`), o al compilar con `--dart-define=API_URL=…`.
- **¿Por qué `Key('…')` en algunos widgets?** Son identificadores para encontrarlos en las pruebas (`find.byKey`).

---

## 12. «Tumba el chatbot y que lo demás siga funcionando»

### 12.1 Lo que se verificó (con pruebas)
Hay pruebas que apagan el asistente de tres maneras y comprueban que catálogo, recomendador, métricas del modelo, registro, compra completa con folio y correo siguen funcionando:
1. **Apagado por configuración** → el servidor responde **503** con `ASISTENTE_NO_DISPONIBLE`.
2. **Falla en ejecución** (modelo ausente, corpus dañado) → también **503**, no un error 500.
3. **El módulo no se puede importar** → igual, 503; la API de la tienda sigue.
Además probé a mano **quitando el archivo `asistente.joblib`**: `/api/asistente/` da 503, `/api/productos/` y `/api/modelos/` dan 200 (después lo restauré).
En Flutter: si el servidor del asistente responde error, el chat muestra «⚠ El asistente no está disponible…» y se puede seguir comprando; con el interruptor de Flutter el botón y el panel **desaparecen**.

### 12.2 ¿Por qué lo demás sigue funcionando? (la respuesta conceptual)
- **La dependencia va en un solo sentido:** el asistente depende de los modelos de datos (`Pedido`, `Producto`); **nada depende del asistente**. `recomendador.py`, `envios.py`, `pagos.py`, `autenticacion.py`, `checkout` no lo importan.
- **No comparten estado:** el asistente tiene sus propias tablas (`ConsultaAsistente`, `ContextoAsistente`), su propio modelo (`asistente.joblib`) y su propio corpus.
- **El asistente no decide el embalaje:** lo lee del pedido o remite al recomendador. Por eso quitarlo no quita ninguna decisión del dominio. (Al revés sí dolería: sin recomendador no hay embalaje; por eso el recomendador tiene su respaldo de reglas.)
- **Falla aislada:** la vista captura el error y devuelve 503 en vez de reventar; el import del módulo es perezoso (`_servicio_asistente()` en `views.py`), así que un archivo roto no tumba el arranque.
- **En Flutter** el chat es un widget que se pinta aparte (`marco.dart`) y su estado está separado en `Tienda` (lista de mensajes); ninguna pantalla necesita el chat para funcionar. Un error se captura en `enviarChat()` y se muestra como un mensaje, no como una excepción.
- **Es la misma idea que el apunte:** una falla parcial no debe tumbar el resto (en microservicios, «si se apaga `recomendar`, `pedidos` sigue vivo»). Aquí se logra dentro del monolito con **módulos desacoplados**; no hacen falta microservicios para lograrlo.

### 12.3 Si te lo piden en vivo: dos niveles

**Nivel A — apagarlo sin borrar código (30 segundos, reversible)**
- Backend: arrancar con `TESITURA_ASISTENTE=off ./.venv/bin/python manage.py runserver 8000`. (`settings.ASISTENTE_ACTIVO`; lo usa `views._servicio_asistente`.)
- Flutter: `flutter build web --wasm --dart-define=CHAT=false` (o `TiendaApp(chatHabilitado: false)`). Desaparecen el botón «Asistente», el panel y el botón «Preguntar al asistente» de la confirmación.

**Nivel B — quitarlo de verdad (qué archivos se tocan)**
| Dónde | Qué quitar |
|---|---|
| `backend/catalogo/asistente.py` | borrar el archivo |
| `backend/catalogo/urls.py` | las 3 rutas `asistente/…` |
| `backend/catalogo/views.py` | `asistente`, `asistente_feedback`, `asistente_metricas`, `_servicio_asistente`, `_asistente_no_disponible` y la parte del asistente en `modelos` |
| `backend/catalogo/models.py` | `ConsultaAsistente`, `ContextoAsistente` (opcional: requiere migración) |
| `backend/catalogo/management/commands/evaluar_asistente.py` | borrar |
| `backend/catalogo/tests.py` | `AsistenteTests` y `AsistenteCaidoTests` |
| `backend/ml/entrenar_asistente.py`, `ml/datos/intenciones.csv`, `ml/modelos/asistente.joblib`, `catalogo/corpus/` | borrar (opcional) |
| `app/lib/widgets/chat_panel.dart` | borrar el archivo |
| `app/lib/widgets/marco.dart` | el `import`, el botón flotante y el panel |
| `app/lib/pages/compra_page.dart` | el `import` y el botón «Preguntar al asistente» |
| `app/lib/state.dart` | `chat`, `chatAbierto`, `enviarChat`, `calificar`, `alternarChat` |
| `app/lib/api.dart` | `preguntar`, `feedback`, `RespuestaAsistente`, `TarjetaChat` |
Después: `manage.py test` y `flutter test` (borrando las pruebas del chat) deben quedar en verde. Con esto se demuestra que el resto no dependía del chat.

**Si te piden tumbar el RECOMENDADOR en lugar del chatbot:** sin el `.joblib`, `RecomendadorConRespaldo` usa reglas simples y la compra sigue; por eso hay respaldo (el recomendador es la pieza que sí decide algo en el dominio).

### 12.4 Preguntas de esta parte
- *¿Qué pasa si se cae el asistente?* La API responde 503 claro, el chat avisa, y catálogo, recomendador, compra y cuenta siguen funcionando.
- *¿Y si se cae el recomendador?* El respaldo con reglas responde; la tienda sigue vendiendo con una decisión más simple.
- *¿Es lo mismo que microservicios?* No: es desacoplamiento dentro de un monolito. La diferencia es que en microservicios cada pieza es un proceso distinto; aquí si el proceso muere, mueren todas. (Honesto: si se cae el servidor Django completo, cae todo; el aislamiento es de módulos, no de procesos.)
- *¿Cómo sabes que el resto no depende del chat?* Las pruebas `AsistenteCaidoTests` lo apagan de tres formas y comprueban el flujo completo.

---

## 13. La APK de Android: cómo se empaqueta y cómo funciona

### 13.1 Qué es una APK
Un `.apk` es un archivo ZIP con todo lo que Android necesita para instalar y ejecutar la app. La nuestra (`mx.tienda.tienda_musica`, nombre «Tesitura») contiene, verificado abriéndola:
- `classes.dex`: el arranque nativo de Android (lo mínimo, en Kotlin/Java).
- `lib/<arquitectura>/libflutter.so`: el **motor de Flutter** (dibuja la interfaz).
- `lib/<arquitectura>/libapp.so`: **tu código Dart compilado a código máquina** (AOT) en modo release.
- `assets/flutter_assets/`: logos, fuentes, recursos.
- `AndroidManifest.xml`: nombre, permisos y la actividad principal.
Incluye tres arquitecturas (`arm64-v8a`, `armeabi-v7a`, `x86_64`), por eso pesa ≈54 MB; con `--split-per-abi` saldrían APK más chicas, una por arquitectura.

### 13.2 Cómo se construye (paso a paso)
```bash
# desde app/ (con Flutter, JDK 17 y Android SDK instalados)
flutter build apk --release --dart-define=API_URL=http://10.0.2.2:8001/api
# resultado: app/build/app/outputs/flutter-apk/app-release.apk
```
1. **Flutter compila Dart a código nativo** (AOT) para cada arquitectura → `libapp.so`.
2. **Gradle** (`android/app/build.gradle.kts`) junta ese código, el motor, los recursos y el manifiesto.
3. **Firma** la APK (Android no instala APK sin firmar). Aquí `release` usa la **clave debug** (`signingConfig = debug`): sirve para pruebas, **no para publicar en tiendas**. Para publicar se crea una clave propia con `keytool` y se configura en `build.gradle.kts`.
4. **`--dart-define=API_URL=…`** fija la URL del servidor al compilar (se lee con `String.fromEnvironment('API_URL')` en `api.dart`). También se puede cambiar dentro de la app (icono del servidor); esa URL se guarda y sobrevive al reiniciar.
5. Instalación: `adb install -r app-release.apk` (emulador o teléfono con depuración USB), o copiar el archivo y permitir «instalar apps desconocidas».

### 13.3 Qué configura el proyecto Android (`app/android/`)
| Archivo | Qué contiene | Por qué |
|---|---|---|
| `android/app/build.gradle.kts` | `applicationId` y `namespace` = `mx.tienda.tienda_musica`; versión desde `pubspec.yaml` (`1.1.0+3`) | Identifica a la app; es distinto del proyecto Rumbo |
| `AndroidManifest.xml` | permisos `INTERNET` y `ACCESS_COARSE/FINE_LOCATION`; `usesCleartextTraffic="true"`; nombre «Tesitura» | Internet para la API; ubicación para «usar mi ubicación»; HTTP porque el servidor de pruebas no tiene HTTPS |
| `pubspec.yaml` | `http`, `geolocator`, `shared_preferences` | Red, GPS y guardar URL/token |

### 13.4 Cómo funciona ya instalada
1. Android abre `MainActivity` (una `FlutterActivity`), que **arranca el motor de Flutter** y ejecuta `main()` (el mismo `main.dart` que en web).
2. Flutter dibuja toda la interfaz por su cuenta (no usa los botones nativos de Android).
3. Las llamadas a la API usan el paquete `http` sobre el cliente de red de Dart. **No hay CORS en Android**: CORS es una regla de los navegadores; por eso en web hace falta `cors.py` y en Android no.
4. **La URL del servidor cambia según dónde corra**: `localhost` en web; **`10.0.2.2` en el emulador** (así se ve la Mac desde el emulador, porque `localhost` dentro del emulador es el emulador mismo); en un teléfono real, **la IP de la Mac en la misma Wi-Fi** (o un servidor publicado).
5. La ubicación pide el permiso en tiempo de ejecución (`geolocator`); si se niega, la app avisa y deja elegir ciudad.
6. El token y la URL se guardan con `shared_preferences` (en Android, almacenamiento privado de la app; en web, `localStorage`).

### 13.5 Misma app, web y Android: qué cambia y qué no
| Igual | Cambia |
|---|---|
| Todo el código Dart (pantallas, estado, API) | URL base y permisos |
| Reglas, modelo y folio (viven en Django) | CORS solo en web |
| Las pruebas de widgets | Empaquetado: `flutter build web` vs `flutter build apk` |

### 13.6 Lo que está probado (y lo que no)
- **Evidencia en el repo:** `app/integration_test/entrega_test.dart` ejecuta el mismo flujo en Chrome y en un emulador Android; capturas en `evidencias/web/` y `evidencias/android/`; `evidencias/apk.json` guarda versión, firma y **SHA-256** de la APK 1.1.0 (con login), publicada como release `tesitura-v1.1.0`. La 1.0.1 (release `tesitura-v1.0.1`) es **anterior al login**.
- **Android con login, recorrido completo:** el recorrido completo con sesión corrió en el emulador de Android 35 desde el código (compilación de depuración con flutter drive, prueba app/integration_test/compra_test.dart, resultado «correcto», 10 capturas en evidencias/android_sesion/): contraseña débil rechazada, registro, embalaje por ciudad, pago con tarjeta de prueba, folio, Mis compras, el chat consultando ese folio y 401 sin sesión. Además la APK release nueva (54 MB) se instaló y abrió. **No probado:** esa APK release ejecutando el recorrido, un teléfono físico y el GPS real. Al correr la prueba salió un desbordamiento real del logo en pantallas de celular (corregido en `widgets/logo.dart`); la APK debe recompilarse para incluir el arreglo.
- **No probado:** teléfono físico y ubicación con GPS real; correo SMTP real.
- **Ojo si vas a mostrar la APK:** la 1.0.1 **no tiene login** (el carrito responde 401 sin sesión). Muestra la **1.1.0** (versionCode 3): `evidencias/apk.json` guarda su SHA-256 y la copia de la demo está en `~/Documents/TOPICOSWEB/Tesitura-demo.apk`.

### 13.7 Preguntas probables sobre la APK
- *¿Cómo la empaquetaste?* `flutter build apk --release`: Flutter compila Dart a nativo, Gradle arma y firma el `.apk`.
- *¿Por qué `10.0.2.2`?* Es la dirección especial con la que el emulador ve a la Mac; `localhost` ahí apunta al propio emulador.
- *¿Y en un teléfono real?* La IP de la Mac en la misma red, con el servidor escuchando en `0.0.0.0`; y `usesCleartextTraffic` porque es HTTP.
- *¿Está lista para Play Store?* No: firma de depuración, tráfico HTTP permitido y sin ícono/listado de tienda. El curso no pide publicar.
- *¿Por qué un archivo de 54 MB?* Lleva el motor de Flutter y el código nativo de tres arquitecturas; con `--split-per-abi` o un App Bundle (`flutter build appbundle`) baja.
- *¿Qué diferencia hay entre `debug` y `release`?* `debug` usa compilación JIT y trae herramientas de desarrollo (92 MB aquí); `release` compila AOT, optimiza y es el que se entrega.
- *¿Por qué no hace falta CORS en Android?* CORS es una política de seguridad de los navegadores; una app nativa hace peticiones HTTP directas.
- *¿El modelo `.joblib` está dentro de la APK?* No. Vive en el servidor; la APK solo habla JSON con la API.
- *¿Cómo sabes que es la misma app que en web?* Es el mismo código Dart y la misma prueba de integración corre en Chrome y en Android.

### 13.8 Cómo se compiló esta APK (comandos reales)
```bash
cd proyectos/tienda-musica/app
R=/Users/diegoriveracisneros/IA/.tools
export ANDROID_HOME=$R/android-sdk ANDROID_SDK_ROOT=$R/android-sdk ANDROID_USER_HOME=$R/android-user ANDROID_AVD_HOME=$R/android-avd
export JAVA_HOME=$R/java/Contents/Home GRADLE_USER_HOME=$R/gradle
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$R/flutter/bin:$PATH"

flutter build apk --release --dart-define=API_URL=http://10.0.2.2:8001/api
# → app/build/app/outputs/flutter-apk/app-release.apk  (54.0 MB, 54,018,024 bytes)
$ANDROID_HOME/build-tools/*/aapt2 dump badging <apk> | grep -E "^package|application-label"
adb install -r <apk> && adb shell am start -n mx.tienda.tienda_musica/.MainActivity
```
Flutter compila el Dart a nativo (tres arquitecturas), Gradle (`assembleRelease`) arma y la firma con la clave de depuración. Esta versión incluye login, Mis compras, Bitácora y el arreglo del logo. Es la versión `1.1.0+3` (la 1.0.1 era anterior al login); `evidencias/apk.json` guarda su SHA-256. Copia lista para la demo: `~/Documents/TOPICOSWEB/Tesitura-demo.apk`. Prueba del recorrido completo: `flutter drive --driver=test_driver/entrega_driver.dart --target=integration_test/compra_test.dart -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:8001/api`.

---

## 14. Cómo «torear» una pregunta que no sabes

### 14.1 La fórmula de cinco pasos (sirve para cualquier pregunta)
1. **Repite o reformula la pregunta** en voz alta («¿me preguntas por qué guardo el hash del token y no el token?»). Te da 5 segundos y confirma que entendiste.
2. **Responde primero lo que sí sabes**, aunque sea el principio general («un hash no se puede revertir…»).
3. **Ancla a un archivo**: «eso está en `autenticacion.py`». Abrirlo demuestra que el código es tuyo.
4. **Si no lo sabes, dilo sin drama y razona en voz alta:** «eso no lo probé; por cómo está hecho, yo esperaría que… y lo comprobaría con…». Un razonamiento honesto vale más que un invento.
5. **Cierra con el límite y la mejora:** «hoy no lo cubro; lo haría así…».

### 14.2 Frases útiles
- «Buena pregunta; esa decisión la tomé por X, y el costo es Y.»
- «Eso no lo implementé; en mi diseño se agregaría en `<archivo>` porque…»
- «Con mis datos no puedo afirmarlo; lo que sí mido es…»
- «¿Me permites abrir el código y mostrarte dónde ocurre?»
- Evita: «no sé» a secas, «así lo hizo la IA», «es que el modelo lo decide» (el profesor quiere ver que tú decidiste).

### 14.3 Qué responder cuando preguntan por herramientas de IA
Tienes que poder explicar **cada decisión**, no solo mostrar que funciona. Prepárate para: «¿por qué esta regla?», «¿qué pasa si cambio este umbral?», «¿qué hace esta línea?». Si usaste ayuda para escribir código, la respuesta honesta es: «la usé como asistente; la arquitectura, los datos y las decisiones las entiendo y las puedo defender, y la comprobé con pruebas». Para eso sirve estudiar esta guía: ensaya con el código abierto.

### 14.4 Puntos débiles que el profesor puede encontrar (y cómo contestarlos)
Dilos tú primero; es lo que más lo desarma.

| Si lo encuentra | Respuesta honesta y corta |
|---|---|
| `DEBUG = True`, `SECRET_KEY` en el código, `ALLOWED_HOSTS = ['*']` (`settings.py`) | «Son valores de desarrollo. En producción la clave y `DEBUG` salen de variables de entorno y `ALLOWED_HOSTS` se limita al dominio. No lo hice porque el curso no pide despliegue.» |
| `@csrf_exempt` en 11 vistas (`views.py`) | «Es una API para un cliente que no usa cookies de sesión de Django: usa un token en `Authorization`. CSRF protege a navegadores que mandan cookies automáticamente; con token en cabecera no aplica de la misma forma. Aun así, el middleware de CSRF sigue activo para el resto.» |
| CORS con `*` (`cors.py`) | «Es para desarrollo con Flutter web en otro puerto. En producción limitaría el origen al dominio de la app.» |
| No usé Django REST Framework (hay `JsonResponse` y validación manual) | «El curso lo menciona como opción. Con ~15 endpoints pequeños preferí vistas finas y `validacion.py` explícita; con más recursos o permisos por objeto, DRF (serializers y ViewSets) compensaría. El monolito está organizado para migrarlo.» |
| El Django Admin no está registrado (`admin.py` vacío) | «Lo gestiono por API y comandos (`cargar_datos`, `crear_admin`). Registrar los modelos en el admin son unas líneas y daría un panel de soporte.» |
| Tráfico HTTP sin cifrar en Android (`usesCleartextTraffic`) | «El servidor local de pruebas es HTTP. En producción se usa HTTPS y se quita esa bandera.» |
| La APK está firmada con la clave debug | «Es una APK de prácticas. Para publicarla se genera una clave de firma propia (`keytool`) y se configura en `build.gradle.kts`; no se pide publicar en tiendas.» |
| El dataset es sintético y el modelo aprende mi fórmula | «Lo declaro: las métricas describen mi dataset. Con envíos reales reemplazo el CSV y reentreno.» |
| No hay migración de PostgreSQL ni Docker | «El curso pide SQLite para P1/P2. Con réplicas pasaría a PostgreSQL (como en Rumbo).» |
| El token se guarda en el almacenamiento del navegador | «Compromiso conocido; Rumbo usa cookie `httpOnly`. Aquí vence a los 7 días y se revoca al cerrar sesión.» |
| Sin verificación de correo ni recuperación de contraseña | «Fuera de alcance de P1/P2; en Rumbo sí hay códigos por correo.» |

### 14.5 Banco de preguntas extra (tipo «el profe pregunta mucho»)
**Django / servidor**
- *¿Qué es una migración?* Un archivo que describe cambios al esquema de la base; `makemigrations` los genera desde `models.py` y `migrate` los aplica (`catalogo/migrations/`).
- *¿Qué es el ORM y por qué evita inyección SQL?* Traduce objetos Python a SQL **con parámetros**: el valor nunca se concatena a la consulta (`Producto.objects.filter(marca__icontains=…)`).
- *¿Qué es un middleware?* Una capa que envuelve cada petición/respuesta (aquí: CORS y auditoría).
- *¿Qué es `transaction.atomic`?* Hace que varias escrituras sean todo-o-nada (el checkout).
- *¿Qué pasa con las existencias si dos personas compran la última pieza?* `select_for_update()` dentro de la transacción bloquea la fila: el segundo ve que ya no hay y recibe 409.
- *¿Dónde validas?* En el servidor (`validacion.py`); Flutter también valida para dar mejor experiencia, pero no se confía en él.
- *¿Qué códigos HTTP usas?* 200/201 éxito, 400 datos inválidos, 401 sin sesión, 402 pago rechazado, 403 sin permiso, 404 folio inexistente, 409 conflicto de existencias o correo repetido, 423 cuenta bloqueada, 503 asistente no disponible.
- *¿Cómo sabes que funciona?* 81 pruebas de backend y 23 de Flutter (`manage.py test`, `flutter test`).

**Machine learning**
- *Precisión, recall y F1:* precisión = de lo que predije como X, cuánto era X; recall = de lo que era X, cuánto encontré; F1 = su media armónica. Están en `reportes/entrenamiento.md`.
- *¿Qué es TF-IDF?* Pondera cada palabra por lo frecuente que es en la frase y lo rara que es en el corpus; así «embalaje» pesa más que «de».
- *¿Qué es la regresión logística?* Un clasificador lineal que da probabilidades por clase.
- *¿Qué es one-hot?* Convierte una categoría en columnas 0/1 para que el modelo la use.
- *¿Qué es joblib?* Serializa el pipeline entrenado en un archivo para cargarlo sin reentrenar.
- *¿Por qué `random_state`?* Para que el resultado sea reproducible.
- *¿Qué cambiarías para mejorar el modelo?* Datos reales, validación cruzada, más variables (por ejemplo, tipo de transportista) y revisar el desbalance.

**Flutter y Android** → ver §11 y §13.

### 14.6 Cambios pequeños que te pueden pedir en vivo (con el archivo y el paso)
| Te piden… | Haz esto |
|---|---|
| «Agrega una regla: teclado de más de 30 kg → premium» | `reglas.py`: otro `piso("premium", "R9_PESO_TECLADO", …)` dentro de `aplicar_reglas`; prueba en `tests.py` (`ReglasTests`); `manage.py test`. |
| «Cambia el umbral de valor alto a $20,000» | `reglas.py`, R1 (`>= 20000`) y su texto; ajusta la prueba. |
| «Agrega una intención nueva al chat (p. ej. “horario”)» | `entrenar_asistente.py` (frases con su grupo) → `python ml/entrenar_asistente.py` → en `asistente.py` el manejo de esa intención y una sugerencia. |
| «Agrega un campo al formulario del modelo» | Dataset (`generar_dataset.py`) → reentrenar → `validacion.py` → `recomendador.py` → Flutter (`api.dart` `toJson` + `recomendar_page.dart`). |
| «Cambia el cargo del embalaje premium» | `reglas.py` (`COSTO_MXN`). |
| «Cambia el color principal» | `app/lib/theme.dart` (`doom`, `doomClaro`, `doomBrillo`). |
| «Que la sesión dure 1 día» | `autenticacion.py` (`VIGENCIA_DIAS = 1`). |
| «Cambia el límite de intentos de login» | `autenticacion.py` (`MAX_FALLOS`, `BLOQUEO_MIN`). |
| «Cambia la URL del servidor» | Icono del servidor en la app, o `--dart-define=API_URL=…`. |
| «Agrega una ciudad de destino» | `datos_catalogo.py` (`CIUDADES`) y volver a correr `cargar_datos`. |

**Antes de cambiar nada:** di qué archivo tocarás y por qué; haz el cambio mínimo; corre `manage.py test`. Si algo se rompe, léelo en voz alta: casi siempre el mensaje de la prueba te dice qué cambió.

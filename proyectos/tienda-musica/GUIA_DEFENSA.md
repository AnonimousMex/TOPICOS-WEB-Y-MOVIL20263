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
- Pruebas: `./.venv/bin/python manage.py test` (77) y `flutter test` (21).
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
| Pruebas | `catalogo/tests.py` | 77 pruebas |

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
33. *¿Cómo funciona en web y Android?* Mismo código Dart. Cambia la URL base: `localhost` en web, `10.0.2.2` en el emulador Android, la IP de la Mac en un teléfono. Está probado en web; **Android no lo probé** (lo digo).
34. *¿Qué pasa si el servidor no responde?* La fachada captura el error y la pantalla muestra «No se pudo conectar…» con botón de reintento.

---

## 9. Lo que NO debes afirmar (límites honestos)

- Las **fotos** de productos son de Wikimedia Commons y muchas son del modelo genérico o de la marca, no del artículo exacto (créditos en `CREDITOS_IMAGENES.md`).
- **Calificaciones, ventas, existencias, humedad y zona de riesgo** de las ciudades son **datos de demostración**.
- El **pago es simulado** y el **correo** está en modo consola salvo que configures SMTP en `backend/.env`.
- **No verifiqué Android** ni la **ubicación en un dispositivo real**; en web sí funciona el permiso del navegador.
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

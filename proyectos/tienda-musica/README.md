# Tesitura — tienda de música (Proyectos 1 y 2, individual)

**Alumno:** Diego Rivera Cisneros · **Matrícula:** 22121364 · **Dominio:** instrumentos musicales.
**Decisión del recomendador:** nivel de embalaje y seguro del envío (`basico`, `reforzado`, `premium`).

Tienda en línea con 194 productos de 51 marcas, un **recomendador** (modelo entrenado + reglas de negocio) que decide cómo viaja cada instrumento, y un **asistente de negocio** por capas que consulta pedidos y catálogo, responde con documentos citados y nunca adivina la decisión del recomendador. Backend Django + SQLite; cliente Flutter (web y Android).

*Tesitura* es el rango de notas en el que una voz o un instrumento suena cómodo. Logo en `app/assets/logo/` (hexágono de acero con un diapasón verde); paleta gris acero y verde.

## Cobertura de lo que piden los apuntes

Fuente: [apuntes del curso](https://ealcaraz85.github.io/topicoswebmobil/) (Proyecto 1, Proyecto 2, modelo recomendador, asistente y RAG). Estado real, sin adornos:

| Lo que piden los apuntes | Dónde está | Estado |
|---|---|---|
| **Dataset en Python** con opciones `--filas`, `--semilla`, `--faltantes`, `id_envio` fuera de las entradas | `backend/ml/generar_dataset.py` (10,000 filas, 12 entradas + etiqueta) | ✅ |
| Pipeline: imputación, one-hot con `handle_unknown="ignore"`, split 80/20 estratificado `random_state=42`, `DecisionTreeClassifier(max_depth=8, min_samples_leaf=5)` | `backend/ml/entrenar_recomendador.py` | ✅ |
| Métricas por clase, matriz de confusión, `export_text`, comparación de profundidades (sobreajuste), Random Forest opcional | `backend/ml/reportes/entrenamiento.md` (se regenera al entrenar) | ✅ |
| Modelo `.joblib` con versión de scikit-learn, `predict_proba` | `ml/modelos/recomendador_arbol.joblib` y `_bosque.joblib` | ✅ |
| **Reglas de factibilidad separadas del modelo** (`reglas.py`) | `catalogo/reglas.py` (R1–R8) | ✅ |
| **Adapter** con interfaz `RecomendadorIA`, `Sugerencia`, fábrica con caché, respaldo | `catalogo/recomendador.py` | ✅ |
| **Strategy por tipo** + fábrica (`medios.py` del curso) | `catalogo/niveles.py` (`crear_nivel`): plan de materiales, seguro y tiempo | ✅ |
| Endpoint `POST` que valida (400), devuelve decisión + **razón** + **plan** | `POST /api/recomendar/` y `/api/envio/` | ✅ |
| Decidir qué hacer con datos faltantes (rellenar o rechazar) | Se **rechazan con 400** los datos del instrumento; el imputador solo protege el entrenamiento (`validacion.py`) | ✅ decidido |
| Herramientas de línea de comandos | `ml/usar_modelo.py`, `ml/probar_modelo.py` | ✅ |
| Backend: BD SQLite, catálogo y pedidos con datos de prueba, listado/detalle JSON, `POST` con folio, `GET` por folio | `catalogo/` (194 productos, `/api/productos/`, `/api/pedidos/<folio>/`) | ✅ |
| Flutter: catálogo con búsqueda, detalle, formulario con los campos del modelo, pantalla de recomendación (confianza, corrección por reglas, ranking), folio, carga y errores, URL configurable | `app/lib/` (botón ⚙ del encabezado o `--dart-define=API_URL=…`) | ✅ |
| **Caso en que las reglas corrigen al modelo**, explicado | Sección «Caso de corrección» abajo | ✅ |
| Párrafo de comparación con el ejemplo de clase | Abajo | ✅ |
| Análisis de patrones web y móvil | `ANALISIS_PATRONES.md` | ✅ |
| **Capturas** (entradas → recomendación → reglas → registro → folio; chat con saludo, folio, dominio, fuera de dominio) | — | ⏳ **las tomas tú** al probar la app |
| **Asistente**: dataset propio de intenciones, entrenado fuera de la petición, artefacto + métrica | `ml/entrenar_asistente.py`, `ml/datos/intenciones.csv` (746 frases, 12 intenciones), `asistente.joblib` | ✅ |
| Asistente: `POST` con `intencion` y `respuesta`, Adapter, consulta de folio/productos, remite al recomendador | `/api/asistente/`, `catalogo/asistente.py` | ✅ |
| Asistente: **no** frases fijas sin modelo, **no** adivinar la decisión del dominio | Intención por modelo entrenado; «pedir embalaje» → remite al recomendador | ✅ |
| Chat en Flutter junto al resto de la app (un solo producto) | Panel flotante (web) / pantalla completa (móvil) | ✅ |
| **RAG**: corpus propio con fuente y versión, Flutter solo por API, dato vivo por API | `catalogo/corpus/` + `/api/asistente/` | ✅ |
| Análisis del dataset (actividades 1–8 del curso) | Ya entregadas aparte para el dataset de transporte (`actividades/analisis-dataset/`); **no se repitieron** para este dataset | ➖ |

### El chatbot «como el video»

El reel (alvaro.lazarus) habla de **«8 capas que vas agregando a medida que aparecen problemas»**: empezar con un prompt, luego RAG, luego «¿quién puede ver estos documentos?» (permisos) y probar los cambios antes de publicarlos. **El texto del reel no lista las 8 capas**, así que armé las mías con ese espíritu (`catalogo/asistente.py`):

| # | Capa | Qué hace aquí |
|---|---|---|
| 1 | Seguridad de entrada | Bloquea intentos de «ignora tus instrucciones» |
| 2 | Router | Modelo de intenciones + entidades (folio, marca, tipo, presupuesto) |
| 3 | Memoria | «¿y de Fender?», «el más barato», «ese pedido» usan el contexto de la sesión |
| 4 | Herramientas | Catálogo y pedidos (datos vivos en la BD) y RAG sobre el corpus |
| 5 | **Permisos por rol** | Público (corpus público) · cliente (su folio, verificado con su correo) · interno (documentos internos, solo con token) |
| 6 | Respuesta con evidencia | Fuentes citadas, tarjetas de producto, sugerencias y traza «¿Cómo respondí?» |
| 7 | Observabilidad | Cada consulta se registra (sin datos personales: se tacha el correo) con intención, latencia, resultado y 👍/👎; `GET /api/asistente/metricas/` con token |
| 8 | Evaluación + humano | `manage.py evaluar_asistente` (16 casos, antes de cada cambio) y escalamiento a una persona |

Si el video muestra algo concreto que quieras copiar (interfaz, flujo), descríbemelo: no pude verlo, solo leer su texto.

## Estructura

```
backend/   Django + SQLite
  catalogo/        models, reglas, niveles (Strategy), recomendador (Adapter), asistente (8 capas),
                   pagos (simulado), correos, geo, envios, views, tests
  catalogo/corpus/ corpus RAG: público (comprador) e interno (solo con token)
  ml/              generar_dataset, entrenar_recomendador, entrenar_asistente, usar_modelo, probar_modelo,
                   datos/*.csv, modelos/*.joblib, reportes/entrenamiento.md
  scripts/         descargar_imagenes.py, generar_miniaturas.py, generar_creditos.py
app/       Flutter (web + Android) · servir_web.py (sirve la web sin caché)
evidencias/        flujo.json
ANALISIS_PATRONES.md · CREDITOS_IMAGENES.md
```

## Instalación y ejecución

Requisitos: Python 3.12 y Flutter (probado con 3.50).

```bash
# Backend
cd backend
python3.12 -m venv .venv && source .venv/bin/activate
pip install "django>=5.0,<5.3" scikit-learn joblib numpy pandas
python manage.py migrate
python manage.py cargar_datos          # 194 productos de 51 marcas (demo)
python manage.py runserver 8000        # API en http://localhost:8000/api/

# Cliente (otra terminal)
cd app
flutter pub get
flutter run -d chrome                  # web (usa http://localhost:8000/api)
flutter run -d emulator-5554           # Android emulador (usa http://10.0.2.2:8000/api)

# Versión más fluida: compilada a WebAssembly y servida con aislamiento (sin caché, para que Chrome no muestre una versión vieja)
flutter build web --wasm --pwa-strategy=none && python servir_web.py 8090 --aislado   # http://localhost:8090
```

**URL del servidor configurable:** botón ⚙ del encabezado, o al compilar `--dart-define=API_URL=http://192.168.1.10:8000/api` (teléfono físico: IP de la Mac en la misma red).

### Regenerar datos y modelos

Los `.joblib` ya están en el repositorio. Para regenerarlos:

```bash
cd backend
python ml/generar_dataset.py --filas 10000 --semilla 7 --faltantes 0.02   # CSV con 2 % de huecos
python ml/entrenar_recomendador.py                                        # árbol + bosque + reporte
python ml/entrenar_asistente.py                                           # intenciones
python ml/probar_modelo.py                                                # casos de ejemplo
python ml/usar_modelo.py --tipo guitarra --valor 9000 --peso 3 --dimension 105 --km 520 --humedad alta --zona alta
```

Si cambias semilla o filas, el modelo cambia: los casos de ejemplo del README pueden dejar de corregirse igual.

### Pruebas

```bash
cd backend && python manage.py test               # 64 pruebas (reglas, recomendador, geo, catálogo, envío, pagos, checkout, correo, asistente)
cd backend && python manage.py evaluar_asistente  # 16 casos de evaluación del asistente
cd app && flutter test                            # 10 pruebas de widgets con servidor simulado
```

## Recomendador (Proyecto 1)

1. El modelo (árbol de decisión, accuracy **0.77** en prueba; el bosque, **0.81**) estima el nivel con `predict_proba`. Los datos son **sintéticos**: las métricas describen el dataset, no envíos reales (`ml/reportes/entrenamiento.md` muestra el sobreajuste al subir la profundidad).
2. `reglas.py` aplica pisos y techos que no se negocian: R1 valor ≥ \$15,000 → premium; R2 cuerda frotada; R3 pieza pesada/grande; R4 larga distancia con valor; R5 frágil y caro; R6 accesorio barato nunca premium; R7 humedad alta protege la madera; R8 zona de riesgo alto con valor ≥ \$8,000 → premium.
3. `niveles.py` (Strategy) arma el **plan**: materiales, cobertura del seguro, horas de preparación y costo (0, \$149 o \$299).
4. La respuesta incluye `nivel_modelo`, `confianza`, `nivel_final`, `corregido_por_reglas`, `reglas`, `ranking`, **`razon`** (texto) y **`plan`**.

Entradas del modelo: tipo, condición, valor, peso, dimensión, distancia, frágil, cantidad, humedad del destino, zona de riesgo, temporada y urgencia. En la tienda, valor/peso/dimensión salen de la **base de datos** (no del cliente) y humedad/zona de la ciudad. La humedad y la zona de riesgo de cada ciudad son **datos ilustrativos**, no estadísticas reales.

### Caso de corrección

**Guitarra de \$9,000 enviada a Acapulco** (frágil, humedad alta, zona de riesgo alta): el modelo sugiere `reforzado` con ~61 % de confianza; la regla **R8_ZONA_DE_RIESGO** la sube a **`premium`** porque el valor de \$8,000 o más en zona de riesgo alto exige seguro total. Se reproduce con `python ml/usar_modelo.py --tipo guitarra --valor 9000 --peso 3 --dimension 105 --km 520 --humedad alta --zona alta`. Otro: un saxofón de \$15,500 donde el modelo dice `reforzado` y R1 lo sube a `premium`.

### Comparación con el ejemplo de clase

El ejemplo decide el **medio de transporte** (moto, dron, bicicleta, camioneta); aquí se decide el **embalaje y seguro** de un instrumento. Cambian las etiquetas (tres niveles **ordenados** en vez de cuatro medios sin orden), las variables (tipo, valor, fragilidad, humedad, zona, distancia…) y el sentido de las reglas: allá filtran medios imposibles; aquí fijan **pisos y techos** sobre una escala ordenada, por eso una corrección sube o baja un nivel. Se conserva la estructura del curso: dataset generado en Python, árbol entrenado fuera de la petición, reglas separadas, Adapter con interfaz, Strategy por nivel, endpoint con razón y plan, y un cliente Flutter que solo consume JSON.

## Asistente (Proyecto 2)

- **Dataset:** `ml/datos/intenciones.csv`, 746 frases en 12 intenciones (saludo, despedida, consulta de folio, explicar recomendación, pedir recomendación, ver producto, ofertas, guía de compra, envíos, devoluciones/garantía, cuidados, fuera de dominio). Las paráfrasis de una idea comparten `grupo` para no inflar la métrica.
- **Entrenamiento:** TF-IDF de palabras y caracteres + regresión logística, fuera de la petición. Métrica: **0.78** de exactitud en validación cruzada por grupos (5 pliegues); es una prueba académica con frases propias, no calidad con usuarios reales.
- **Por qué no inventa la decisión del recomendador:** no importa el modelo ni las reglas; ante «¿qué embalaje necesita mi violín?» **remite** al recomendador (`accion: abrir_recomendador`), y para un folio solo **lee** lo ya registrado.
- **Rol cliente:** un folio con dueño solo se detalla a quien demuestra el correo de la compra (la app lo manda sola tras comprar, o lo escribes en el chat). Sin verificar no se revela ningún dato.
- **Corpus:** simulado y marcado como «muestra académica, no condición real de venta». Los documentos internos están en un índice aparte y solo responden con el token de administrador.

## Fluidez y animaciones

Se midió el desplazamiento en pantalla Retina (1440×900 a 2x, 30 pasos de rueda con el mouse quieto, Chrome con WebGL por software; mismo método antes y después). Qué se hizo y cuánto ayudó:

| Versión | Inicio: prom. / cuadros > 40 ms | Listado: prom. / cuadros > 40 ms |
|---|---|---|
| Motor normal (CanvasKit) | 27 ms / **36** | 33 ms / **42** |
| **WebAssembly con aislamiento** (la actual) | **17 ms (58 fps) / 1** | **17 ms (59 fps) / 1** |

- **WebAssembly (`skwasm`) + aislamiento** (`flutter build web --wasm` y `python servir_web.py 8090 --aislado`): es el cambio que más pesa. Dibuja en otro hilo, así que los cálculos del contenido no frenan el desplazamiento. Si el navegador no lo soporta (por ejemplo Safari), Flutter carga solo el motor normal y todo sigue funcionando, solo que menos fluido. Sin los encabezados de aislamiento también funciona, con algo menos de mejora.
- **Las fotos eran lo más pesado:** las tarjetas usan **miniaturas de ~29 KB** (`python scripts/generar_miniaturas.py`, `/img/productos_mini/`), sin fundido por imagen, con caché del servidor (`max-age`) y **precarga escalonada** de las que están por aparecer. La ficha del producto usa la foto completa.
- **Sin efectos que Flutter web recalcula en cada cuadro:** el logo es una imagen ya generada (no un dibujo con desenfoque), se quitaron las sombras con desenfoque y el resaltado al pasar el mouse lo da el `InkWell` (antes cada tarjeta que pasaba bajo el cursor reconstruía y animaba).
- El listado construye **solo las tarjetas visibles** (`SliverGrid`).
- **Rueda y trackpad** (`widgets/desplazamiento.dart`): un «tic» movía solo 100 px (una tarjeta mide ~420). La rueda se amplifica ×2 y acelera hasta ×5 si giras seguido, con 200 ms de suavizado; el trackpad se aplica directo. En móvil se usa el desplazamiento nativo. Para desactivarlo: `--dart-define=SCROLL_SUAVE=false`.
- Animaciones con sentido, cortas (160–260 ms) y con la misma curva (`Anim` en `theme.dart`): transición entre pantallas, panel del asistente y su botón, panel de envío que se expande, resultado del recomendador con fundido y resultados del listado que se atenúan mientras cargan.

Nota de método: con el Chrome de pruebas sin WebGL (`--disable-gpu`) todo da 2–3 veces peor y la versión WebAssembly cae al motor normal; esas cifras no representan una Mac con GPU, por eso la tabla usa WebGL.

## La tienda (interfaz)

Inspirada en la organización de tiendas como Mercado Libre y Donner Music (franja de anuncio, encabezado con buscador y carrito, categorías, filtros con conteos, tarjetas con precio/descuento/cuotas, caja de compra), **sin copiar sus logotipos, textos ni imágenes**.

- **Inicio:** carrusel, 51 marcas con logo, ofertas del día, más vendidos, guitarras y teclados.
- **Listado:** filtros por categoría, marca, precio, ofertas, envío gratis y disponibilidad; orden por relevancia, ventas, precio y valoración.
- **Producto:** galería, descuento, cuotas, **Envío protegido** (ciudad o tu ubicación → embalaje, costo, razón, plan y si las reglas corrigieron al modelo).
- **Carrito y compra:** cantidades, correo, destino, pago con tarjeta, embalaje por línea, total y un folio por producto.
- **Recomendador de embalaje (herramienta de bodega):** el formulario completo del Proyecto 1 («formulario con los campos que necesita su modelo → pantalla de recomendación → folio»). **No es una pantalla de compra**: el comprador no la necesita, porque cada producto ya muestra su recomendación al elegir ciudad. Sirve a la bodega para cotizar un instrumento que no está en el catálogo y registrar la cotización con folio; por eso está en el pie de página y no en el menú.
- **Asistente flotante** en web (pantalla completa en móvil).

### Pago con tarjeta (simulado)

**No se cobra nada.** Es una pasarela simulada que solo acepta **tarjetas de prueba**: `4242 4242 4242 4242` (Visa), `5555 5555 5555 4444` (Mastercard), `3782 822463 10005` (Amex, CVV de 4); `4000 0000 0000 0002` se rechaza y `4000 0000 0000 9995` da fondos insuficientes. Cualquier fecha futura y CVV de 3 dígitos. Una tarjeta real **se rechaza a propósito**. El número completo y el CVV se validan y se descartan: solo se guarda la marca y los **últimos 4 dígitos** (hay pruebas que lo comprueban). Cobrar de verdad requeriría una pasarela real (por ejemplo Stripe) con tus llaves y cumplir las reglas de la industria de tarjetas (PCI): no está hecho.

### Correo de confirmación

Al pagar se envía un correo con la referencia, folios, embalaje, total y pago. **Sin configuración funciona en modo consola**: no sale nada a internet; el correo queda en la bandeja del servidor (modelo `Correo`) y como HTML en `backend/correos_enviados/` para abrirlo en el navegador. Para enviarlo de verdad, copia `backend/.env.example` a `backend/.env` (no se sube al repositorio) y llena `TESITURA_SMTP_*` (con Gmail, una «contraseña de aplicación»). Un fallo de correo **no cancela** la compra: queda registrado como `error`. No probé el envío por SMTP real porque no tengo tus credenciales (sí está probado con el backend de pruebas de Django).

### Ubicación actual

El botón «Usar mi ubicación actual» (en el producto y en el carrito) pide permiso al navegador/GPS y convierte las coordenadas en **ciudad más cercana y distancia a la bodega** (Morelia) con una tabla propia: **no se envía a servicios externos**. El servidor usa esa distancia real (y la humedad/zona de la ciudad cercana) para el recomendador, rechaza ubicaciones fuera de México y, si compras con ella, guarda solo coordenadas **redondeadas a ~1 km**. En web necesita `localhost` o HTTPS; en Android pide el permiso de ubicación (no lo probé en un teléfono real).

## Imágenes y logos

Vienen de **Wikimedia Commons** con licencias libres; autor, licencia y fuente de cada una están en [CREDITOS_IMAGENES.md](CREDITOS_IMAGENES.md) y la tienda muestra el crédito bajo cada foto. **49 de 51 logos** (Elixir y Jupiter no tienen uno libre: muestran su nombre) y **145 fotos** para 194 productos; el resto usa un visual generado. Ojo con lo que significan:
- *modelo* (10): foto del modelo exacto.
- *marca* (108): foto de la misma marca y tipo, **puede ser otro modelo**.
- *referencia* (27): foto genérica del tipo de instrumento, **ni marca ni modelo**.

La tienda lo avisa en cada producto. Se descartaron a mano ~50 fotos y varios logos que no correspondían. Para fotos exactas habría que usar las del fabricante con permiso y ponerlas en `imagen_url`. Marcas y logotipos son de sus dueños y se usan solo para identificar productos en esta práctica. Regenerar: `python scripts/descargar_imagenes.py` (revisa `scripts/imagenes_manual.json`).

**Datos demo:** las marcas son conocidas y se eligieron por criterio propio, **no** por un ranking de ventas verificado. Modelos y precios son aproximados; calificaciones, ventas y existencias son inventadas y deterministas.

## API

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/productos/?q=&marca=&categoria=&min=&max=&oferta=1&envio_gratis=1&disponible=1&orden=` | Listado con búsqueda, filtros y orden |
| GET | `/api/productos/<id>/` · `/api/facetas/` · `/api/destinos/` | Detalle con similares · marcas con logo y conteo · ciudades |
| POST | `/api/recomendar/` | Vista previa con el formulario completo (no registra) |
| POST | `/api/envio/` | Embalaje para un producto → ciudad o `ubicacion` (medidas desde la base) |
| POST | `/api/ubicacion/` | `{lat, lon}` → ciudad cercana y km a la bodega (no guarda nada) |
| POST | `/api/pedidos/` | Registra con folio (producto+destino, o formulario completo) |
| POST | `/api/checkout/` | Carrito: valida, **cobra (simulado)**, crea un pedido por línea, manda el correo; todo o nada |
| GET | `/api/pedidos/<folio>/` | Consulta por folio |
| POST | `/api/asistente/` | `{mensaje, sesion, correo}` → intención, respuesta, productos, fuentes, sugerencias, capas |
| POST | `/api/asistente/feedback/` · GET `/api/asistente/metricas/` | 👍/👎 · métricas (encabezado `X-Tesitura-Token`) |
| GET | `/api/modelos/` | Métricas de los modelos |

## Pendiente antes de entregar

- Tomar las **capturas** de la app (catálogo, producto con embalaje, formulario, corrección por reglas, folio y los cuatro casos del chat).
- Aprópiate del código y del `ANALISIS_PATRONES.md`: el profe califica que coincidan y que puedas explicarlos en vivo.
- No probado: envío por SMTP real, la app en Android (emulador o teléfono) ni la ubicación en un dispositivo real.

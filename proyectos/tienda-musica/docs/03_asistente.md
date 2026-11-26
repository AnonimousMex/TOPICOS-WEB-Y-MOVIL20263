# 03 · Asistente conversacional

Responde sobre productos, ofertas, cuidados, envíos y folios dentro del dominio de la tienda. **Nunca decide el embalaje**: remite al recomendador o lee lo ya registrado en un folio.

## Cómo entiende lo que se escribe
1. **Intenciones:** un clasificador entrenado con **746 frases** propias (`ml/datos/intenciones.csv`) reconoce **12 intenciones**: `ver_producto`, `guia_compra`, `cuidados`, `explicar_recomendacion`, `pedir_recomendacion`, `envios`, `devoluciones_garantia`, `fuera_dominio`, `consulta_folio`, `ofertas`, `saludo` y `despedida`.
2. **Representación:** TF-IDF (palabras de 1–2 y caracteres de 2–5) convierte el texto en números.
3. **Clasificador:** regresión logística con clases balanceadas. Validación cruzada por grupos ≈ 0.78 (dataset propio, no usuarios reales).
4. **Entidades:** folio, marca, categoría y presupuesto, extraídas del texto.
5. **Memoria:** contexto corto por sesión («¿y de Fender?», «ese pedido»). No reentrena el modelo; solo recuerda el hilo de la conversación.

## De dónde saca las respuestas
- **Datos vivos:** catálogo y pedidos, consultados en la base.
- **RAG sobre el corpus:** documentos de `backend/catalogo/corpus/` (guías de guitarras y teclados, cuidados, compatibilidad de accesorios, envíos, devoluciones y garantía). El texto recuperado se cita como evidencia.
- Lo que está fuera del dominio recibe un mensaje que reorienta, sin inventar.

## Las 8 capas (`catalogo/asistente.py`)
1. Seguridad de entrada (longitud, intentos de inyección de instrucciones).
2. Router de intenciones y entidades.
3. Memoria de sesión.
4. Herramientas (base de datos o RAG).
5. Permisos: público (corpus público), cliente (su folio, verificado con su correo) e interno (solo con token de administrador).
6. Respuesta con evidencia: fuentes, tarjetas de producto y sugerencias.
7. Observabilidad: cada consulta se registra sin datos personales (intención, latencia, resultado y 👍/👎); métricas solo para el administrador.
8. Evaluación: `manage.py evaluar_asistente` ejecuta 16 casos esperados.

## Apagarlo sin afectar el resto
- Servidor: `TESITURA_ASISTENTE=off ./.venv/bin/python manage.py runserver 8001`. Las rutas `/api/asistente/…` responden **503** con `ASISTENTE_NO_DISPONIBLE`; catálogo, recomendador, pagos y cuentas siguen funcionando.
- Cliente: `--dart-define=CHAT=false` al compilar oculta el botón y el panel del chat.
- Por qué es seguro: la dependencia va en un solo sentido (el asistente usa los modelos de datos; nada del flujo de compra lo importa) y la importación es perezosa.
- Pruebas: `AsistenteCaidoTests` cubre apagado por configuración, falla en ejecución, módulo no importable y compra completa sin asistente.

## Reentrenar
`python ml/entrenar_asistente.py` regenera `ml/modelos/asistente.joblib` a partir de `intenciones.csv`.

# Cinco días: plataforma de pedidos

Práctica de Diego Rivera Cisneros, matrícula 22121364. Implementa el corte web del enunciado: formulario → servicio → proveedor adaptado → medio → pedido; seguimiento HTML y JSON del mismo folio.

## Ejecutar

Python 3.12, desde `practica/`:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 18125
```

Abrir `http://localhost:18125`. Pruebas: `python manage.py test entregas`.

| Responsabilidad | Archivo |
|---|---|
| Entrada HTTP y métodos | `plataforma/urls.py`, `entregas/views.py`; Django hace el despacho |
| CSRF y sesión | Middleware de Django, sin una portería propia por vista |
| Adaptar JSON/XML | `entregas/dominio.py`, `adaptar` → `Sugerencia` |
| Strategy y fábrica simple | `Camioneta`, `Motocicleta`, `Bicicleta`, `Dron`, `crear_medio` |
| Caso de uso, transacción y aviso posterior | `entregas/servicios.py`, `registrar_pedido` |
| Persistencia | `entregas/models.py` y ORM; intento único en la base |
| HTML y JSON mínimo | `templates/entregas/`, `/api/pedidos/<folio>` |

El proveedor de IA es simulado en esta práctica, como permite el enunciado; los modelos entrenados están en los proyectos individuales y en Rumbo. No hay cobro ni envío de correo real. El mapa es un esquema. Se rechazaron Event Sourcing, CQRS y Redux global porque no resuelven este corte.

[Notas de los cinco bloques](NOTAS.md) · [Evidencias](evidencias/resultado.json).

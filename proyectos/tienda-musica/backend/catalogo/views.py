import json

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import validate_email
from django.db import transaction
from django.db.models import Count, F, Max, Min, Q
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_GET, require_POST

from .datos_catalogo import CIUDADES
from . import autenticacion, correos, pagos
from .envios import entradas_desde_producto
from .geo import en_cobertura, resolver_ubicacion
from .imagenes import logo_de, mini_de
from .models import Auditoria, Compra, ConsultaAsistente, Pedido, Producto
from .recomendador import metricas_modelo, recomendar
from .validacion import EntradaInvalida, validar_envio


def _producto_json(p):
    return {
        "id": p.id, "nombre": p.nombre, "marca": p.marca, "categoria": p.categoria,
        "subcategoria": p.subcategoria, "descripcion": p.descripcion,
        "precio_mxn": float(p.precio_mxn),
        "precio_original_mxn": float(p.precio_original_mxn) if p.precio_original_mxn else None,
        "descuento_pct": p.descuento_pct, "peso_kg": float(p.peso_kg),
        "dimension_max_cm": p.dimension_max_cm, "fragil": p.fragil, "existencias": p.existencias,
        "rating": p.rating, "vendidos": p.vendidos, "envio_gratis": p.envio_gratis,
        "imagen_url": p.imagen_url or None, "imagen_mini_url": mini_de(p.imagen_url), "imagen_credito": p.imagen_credito or None,
        "imagen_fuente": p.imagen_fuente or None, "imagen_nivel": p.imagen_nivel or None,
        "marca_logo": logo_de(p.marca),
    }


def _pedido_json(p):
    return {
        "folio": p.folio, "estado": p.estado, "creado": p.creado.isoformat(),
        "producto": p.producto.nombre if p.producto else None,
        "destino": p.destino, "cantidad": p.cantidad, "costo_embalaje_mxn": p.costo_embalaje_mxn,
        "entradas": {
            "tipo": p.tipo, "valor_mxn": float(p.valor_mxn), "peso_kg": float(p.peso_kg),
            "dimension_max_cm": p.dimension_max_cm, "distancia_km": p.distancia_km, "fragil": p.fragil,
        },
        "compra": p.compra.referencia if p.compra else None,
        "recomendacion": {
            "nivel_modelo": p.nivel_modelo, "confianza": p.confianza, "nivel_final": p.nivel_final,
            "corregido_por_reglas": p.corregido, "reglas": p.reglas, "ranking": p.ranking,
            "costo_embalaje_mxn": p.costo_embalaje_mxn,
        },
    }


def _cuerpo(request):
    try:
        datos = json.loads(request.body or b"{}")
    except json.JSONDecodeError:
        raise EntradaInvalida({"cuerpo": "JSON inválido."})
    if not isinstance(datos, dict):
        raise EntradaInvalida({"cuerpo": "Se esperaba un objeto JSON."})
    return datos


def _error(errores, status=400):
    return JsonResponse({"error": "Datos inválidos", "campos": errores}, status=status)


def _crear_pedido(producto, entradas, r, cliente="", destino="", cantidad=1, compra=None):
    return Pedido.objects.create(
        compra=compra, producto=producto, cliente=str(cliente)[:80], destino=destino, cantidad=cantidad,
        tipo=entradas["tipo"], valor_mxn=entradas["valor_mxn"], peso_kg=entradas["peso_kg"],
        dimension_max_cm=entradas["dimension_max_cm"], distancia_km=entradas["distancia_km"],
        fragil=entradas["fragil"], nivel_modelo=r["nivel_modelo"], confianza=r["confianza"],
        nivel_final=r["nivel_final"], reglas=r["reglas"], ranking=r["ranking"],
        costo_embalaje_mxn=r["costo_embalaje_mxn"],
    )


ORDENES = {
    "relevancia": ("-vendidos", "nombre"),
    "mas_vendidos": ("-vendidos", "nombre"),
    "precio_asc": ("precio_mxn", "nombre"),
    "precio_desc": ("-precio_mxn", "nombre"),
    "mejor_valorados": ("-rating", "-vendidos"),
    "nombre": ("nombre",),
}


@require_GET
def productos(request):
    qs = Producto.objects.all()
    g = request.GET
    q = g.get("q", "").strip()
    if q:
        for palabra in q.split():
            qs = qs.filter(Q(nombre__icontains=palabra) | Q(marca__icontains=palabra) | Q(subcategoria__icontains=palabra) | Q(descripcion__icontains=palabra))
    if g.get("categoria"):
        qs = qs.filter(categoria=g["categoria"])
    if g.get("subcategoria"):
        qs = qs.filter(subcategoria=g["subcategoria"])
    if g.get("marca"):
        qs = qs.filter(marca__in=[m for m in g["marca"].split(",") if m])
    try:
        if g.get("min"):
            qs = qs.filter(precio_mxn__gte=float(g["min"]))
        if g.get("max"):
            qs = qs.filter(precio_mxn__lte=float(g["max"]))
    except ValueError:
        return _error({"precio": "Los límites de precio deben ser numéricos."})
    if g.get("oferta") == "1":
        qs = qs.filter(precio_original_mxn__gt=F("precio_mxn"))
    if g.get("envio_gratis") == "1":
        qs = qs.filter(envio_gratis=True)
    if g.get("disponible") == "1":
        qs = qs.filter(existencias__gt=0)
    orden = g.get("orden", "relevancia")
    qs = qs.order_by(*ORDENES.get(orden, ORDENES["relevancia"]))
    lista = [_producto_json(p) for p in qs]
    return JsonResponse({"total": len(lista), "resultados": lista})


@require_GET
def facetas(request):
    base = Producto.objects.all()
    rango = base.aggregate(minimo=Min("precio_mxn"), maximo=Max("precio_mxn"))
    return JsonResponse({
        "marcas": [{**m, "logo": logo_de(m["marca"])} for m in base.values("marca").annotate(total=Count("id")).order_by("-total", "marca")],
        "categorias": list(base.values("categoria").annotate(total=Count("id")).order_by("-total")),
        "subcategorias": list(base.values("categoria", "subcategoria").annotate(total=Count("id")).order_by("categoria", "subcategoria")),
        "precio_min": float(rango["minimo"] or 0), "precio_max": float(rango["maximo"] or 0),
    })


@require_GET
def destinos(request):
    return JsonResponse({"destinos": [{"ciudad": c, "km": d["km"], "humedad": d["humedad"], "zona": d["zona"]} for c, d in CIUDADES.items()]})


@require_GET
def producto_detalle(request, pk):
    try:
        p = Producto.objects.get(pk=pk)
    except Producto.DoesNotExist:
        return JsonResponse({"error": "Producto no encontrado"}, status=404)
    similares = Producto.objects.filter(subcategoria=p.subcategoria).exclude(pk=p.pk).order_by("-vendidos")[:6]
    return JsonResponse({**_producto_json(p), "similares": [_producto_json(s) for s in similares]})


@csrf_exempt
@require_POST
def recomendar_vista(request):
    """Vista previa: calcula modelo + reglas sin registrar nada."""
    try:
        entradas = validar_envio(_cuerpo(request))
    except EntradaInvalida as e:
        return _error(e.errores)
    return JsonResponse({"entradas": entradas, **recomendar(entradas)})


@csrf_exempt
@require_POST
def envio(request):
    """Embalaje recomendado para un producto del catálogo hacia una ciudad o tu ubicación (medidas desde la base)."""
    try:
        datos = _cuerpo(request)
        producto = Producto.objects.filter(pk=datos.get("producto_id")).first()
        if not producto:
            return _error({"producto_id": "El producto no existe."}, 404)
        entradas, cantidad, destino, _, _ = entradas_desde_producto(producto, datos)
    except EntradaInvalida as e:
        return _error(e.errores)
    return JsonResponse({"entradas": entradas, "cantidad": cantidad, "destino": destino, **recomendar(entradas)})


@csrf_exempt
@require_POST
def ubicacion(request):
    """Convierte tu ubicación en ciudad cercana y distancia a la bodega. No guarda nada: es solo una consulta."""
    try:
        datos = _cuerpo(request)
        lat, lon = float(datos["lat"]), float(datos["lon"])
    except (EntradaInvalida, KeyError, TypeError, ValueError):
        return _error({"ubicacion": "Envía lat y lon numéricos."})
    if not (-90 <= lat <= 90 and -180 <= lon <= 180):
        return _error({"ubicacion": "Coordenadas fuera de rango."})
    if not en_cobertura(lat, lon):
        return JsonResponse({"cobertura": False, "mensaje": "Tu ubicación está fuera de la zona de cobertura (México)."})
    return JsonResponse({"cobertura": True, "lat": round(lat, 3), "lon": round(lon, 3), **resolver_ubicacion(lat, lon)})


@csrf_exempt
@require_POST
def pedidos(request):
    """Registra una operación. Recalcula en el servidor: no se confía en lo que muestre el cliente.

    Dos formas: (producto_id, cantidad, destino) con medidas del catálogo, o el formulario
    completo del cotizador (tipo, valor, peso, dimensión, distancia, frágil).
    """
    try:
        datos = _cuerpo(request)
        producto = None
        if datos.get("producto_id") is not None:
            producto = Producto.objects.filter(pk=datos["producto_id"]).first()
            if not producto:
                return _error({"producto_id": "El producto no existe."}, 404)
        if producto and datos.get("destino"):
            entradas, cantidad, destino, _, _ = entradas_desde_producto(producto, datos)
        else:
            entradas, cantidad, destino = validar_envio(datos), 1, ""
    except EntradaInvalida as e:
        return _error(e.errores)
    r = recomendar(entradas)
    pedido = _crear_pedido(producto, entradas, r, datos.get("cliente", ""), destino, cantidad)
    return JsonResponse(_pedido_json(pedido), status=201)


@csrf_exempt
@require_POST
def checkout(request):
    """Compra del carrito: valida, cobra (simulado), crea un pedido con folio por línea y manda el correo.

    Todo o nada: si una línea no tiene stock o el pago se rechaza, no se crea nada ni se toca el inventario.
    Requiere sesión iniciada: la compra queda ligada a la cuenta y el correo de confirmación va al de la cuenta.
    """
    usuario = autenticacion.usuario_de(request)
    if not usuario:
        return JsonResponse({"error": "Inicia sesión para comprar.", "codigo": "NO_AUTORIZADO"}, status=401)
    try:
        datos = _cuerpo(request)
        lineas = datos.get("lineas")
        if not isinstance(lineas, list) or not 1 <= len(lineas) <= 20:
            raise EntradaInvalida({"lineas": "El carrito debe tener entre 1 y 20 líneas."})
        cliente = str(datos.get("cliente", "")).strip()
        if len(cliente) < 2:
            raise EntradaInvalida({"cliente": "Escribe tu nombre."})
        correo = usuario.email  # el correo sale de la cuenta: no se puede mandar la confirmación a otra persona
        try:
            numero, marca = pagos.validar_tarjeta(datos.get("tarjeta"))
        except pagos.PagoInvalido as e:
            raise EntradaInvalida({f"tarjeta.{k}" if k != "tarjeta" else k: v for k, v in e.campos.items()})
        with transaction.atomic():
            preparadas, destino_nombre, lat, lon = [], None, None, None
            for i, linea in enumerate(lineas):
                if not isinstance(linea, dict):
                    raise EntradaInvalida({"lineas": f"Línea {i + 1} inválida."})
                producto = Producto.objects.select_for_update().filter(pk=linea.get("producto_id")).first()
                if not producto:
                    raise EntradaInvalida({"lineas": f"La línea {i + 1} apunta a un producto que no existe."})
                entradas, cantidad, destino_nombre, lat, lon = entradas_desde_producto(producto, {**datos, "cantidad": linea.get("cantidad", 1)})
                if producto.existencias < cantidad:
                    raise EntradaInvalida({"lineas": f"Solo quedan {producto.existencias} de «{producto.nombre}»."})
                preparadas.append((producto, entradas, cantidad, recomendar(entradas)))
            subtotal = sum(e["valor_mxn"] for _, e, _, _ in preparadas)
            embalaje = sum(r["costo_embalaje_mxn"] for *_, r in preparadas)
            try:
                cobro = pagos.cobrar(numero, marca, subtotal + embalaje)
            except pagos.PagoRechazado as e:
                return JsonResponse({"error": "Pago rechazado", "mensaje": e.mensaje, "campos": {"tarjeta": e.mensaje}}, status=402)
            compra = Compra.objects.create(
                usuario=usuario, cliente=cliente, correo=correo, destino=destino_nombre, lat_aprox=lat, lon_aprox=lon,
                subtotal_mxn=subtotal, embalaje_mxn=embalaje, total_mxn=subtotal + embalaje, pago_estado=cobro["estado"],
                pago_marca=cobro["marca"], pago_ultimos4=cobro["ultimos4"], pago_referencia=cobro["referencia"],
            )
            creados = []
            for producto, entradas, cantidad, r in preparadas:
                producto.existencias -= cantidad
                producto.save(update_fields=["existencias"])
                creados.append(_crear_pedido(producto, entradas, r, cliente, destino_nombre, cantidad, compra))
    except EntradaInvalida as e:
        return _error(e.errores, 409 if "lineas" in e.errores else 400)
    try:
        estado_correo = correos.enviar_confirmacion(compra)
    except Exception:  # noqa: BLE001  (un problema de correo nunca debe cancelar una compra ya cobrada)
        estado_correo = "error"
    return JsonResponse({
        "compra": {
            "referencia": compra.referencia, "cliente": cliente, "correo": correo, "destino": destino_nombre,
            "pago": {"estado": cobro["estado"], "marca": cobro["marca"], "ultimos4": cobro["ultimos4"], "referencia": cobro["referencia"]},
            "correo_estado": estado_correo, "modo_correo": settings.CORREO_MODO,
        },
        "pedidos": [_pedido_json(p) for p in creados],
        "subtotal_mxn": float(subtotal), "embalaje_mxn": float(embalaje), "total_mxn": float(subtotal + embalaje),
    }, status=201)


@require_GET
def pedido_detalle(request, folio):
    try:
        return JsonResponse(_pedido_json(Pedido.objects.select_related("producto").get(folio=folio.upper())))
    except Pedido.DoesNotExist:
        return JsonResponse({"error": "Folio no encontrado"}, status=404)


def _servicio_asistente():
    """El asistente es opcional: se importa al usarlo para que, si falta o está roto, el resto de la API siga igual."""
    if not settings.ASISTENTE_ACTIVO:
        return None
    try:
        from . import asistente
        return asistente
    except Exception:  # noqa: BLE001
        return None


def _asistente_no_disponible():
    return JsonResponse({"error": "El asistente no está disponible por ahora. Puedes seguir comprando y usar el recomendador de embalaje.", "codigo": "ASISTENTE_NO_DISPONIBLE"}, status=503)


def _es_admin(request):
    """Administrador = usuario con rol ADMIN (is_staff) o, por compatibilidad, el token interno del asistente."""
    usuario = autenticacion.usuario_de(request)
    if usuario and usuario.is_staff:
        return True
    token = request.headers.get("X-Tesitura-Token", "")
    return bool(settings.TOKEN_ADMIN) and token == settings.TOKEN_ADMIN


@csrf_exempt
@require_POST
def asistente(request):
    try:
        datos = _cuerpo(request)
    except EntradaInvalida as e:
        return _error(e.errores)
    mensaje = datos.get("mensaje")
    if not isinstance(mensaje, str) or not mensaje.strip():
        return _error({"mensaje": "Escribe un mensaje."})
    if len(mensaje) > 500:
        return _error({"mensaje": "Máximo 500 caracteres."})
    servicio = _servicio_asistente()
    if servicio is None:
        return _asistente_no_disponible()
    usuario = autenticacion.usuario_de(request)
    # Con sesión iniciada el correo es el de la cuenta (verificado por el servidor), no el que escriba el cliente.
    correo = usuario.email if usuario else str(datos.get("correo", "")).strip().lower()
    contexto = servicio.Peticion(sesion=str(datos.get("sesion", ""))[:40], correo=correo, admin=_es_admin(request))
    try:
        return JsonResponse(servicio.responder(mensaje, contexto))
    except Exception:  # noqa: BLE001  (modelo ausente, corpus dañado…: el asistente falla solo, no la tienda)
        return _asistente_no_disponible()


@csrf_exempt
@require_POST
def asistente_feedback(request):
    """👍/👎 sobre una respuesta (capa de observabilidad)."""
    if not settings.ASISTENTE_ACTIVO:
        return _asistente_no_disponible()
    try:
        datos = _cuerpo(request)
        valor = int(datos.get("valor"))
        consulta = ConsultaAsistente.objects.filter(pk=datos.get("consulta_id")).first()
    except (EntradaInvalida, TypeError, ValueError):
        return _error({"feedback": "Datos inválidos."})
    if valor not in (-1, 1) or not consulta:
        return _error({"feedback": "Valor (1 o -1) o consulta inválidos."})
    consulta.feedback = valor
    consulta.save(update_fields=["feedback"])
    return JsonResponse({"ok": True})


@require_GET
def asistente_metricas(request):
    """Resumen de uso del asistente. Solo con el token de administrador."""
    if not _es_admin(request):
        return JsonResponse({"error": "Requiere el token de administrador (encabezado X-Tesitura-Token)."}, status=403)
    from django.db.models import Avg, Count
    qs = ConsultaAsistente.objects.all()
    return JsonResponse({
        "consultas": qs.count(),
        "por_intencion": list(qs.values("intencion").annotate(total=Count("id")).order_by("-total")),
        "por_resultado": list(qs.values("resultado").annotate(total=Count("id"))),
        "latencia_promedio_ms": round(qs.aggregate(m=Avg("latencia_ms"))["m"] or 0),
        "feedback_util": qs.filter(feedback=1).count(), "feedback_no_util": qs.filter(feedback=-1).count(),
        "sin_respuesta_util": list(qs.filter(resultado__in=["abstencion", "escalado"]).values_list("mensaje", flat=True)[:20]),
    })


@require_GET
def modelos(request):
    servicio = _servicio_asistente()
    try:
        metricas_chat = servicio.metricas_asistente() if servicio else None
    except Exception:  # noqa: BLE001
        metricas_chat = None
    return JsonResponse({"recomendador": metricas_modelo(), "asistente": metricas_chat})


# ---------- cuentas, sesión y auditoría ----------

def _ip(request):
    return request.META.get("REMOTE_ADDR", "")


def _sesion_json(usuario, token):
    return JsonResponse({"token": token, "usuario": autenticacion.usuario_json(usuario)})


@csrf_exempt
@require_POST
def registro(request):
    try:
        usuario, token = autenticacion.registrar(_cuerpo(request), _ip(request))
    except EntradaInvalida as e:
        return _error(e.errores, 409 if "correo" in e.errores and "Ya existe" in str(e.errores["correo"]) else 400)
    return JsonResponse({"token": token, "usuario": autenticacion.usuario_json(usuario)}, status=201)


@csrf_exempt
@require_POST
def login(request):
    try:
        usuario, token = autenticacion.iniciar_sesion(_cuerpo(request), _ip(request))
    except EntradaInvalida as e:
        return _error(e.errores)
    except autenticacion.NoAutorizado as e:
        return JsonResponse({"error": e.mensaje, "codigo": e.codigo}, status=e.status)
    return _sesion_json(usuario, token)


@csrf_exempt
@require_POST
def logout(request):
    autenticacion.cerrar_sesion(request)
    return JsonResponse({"ok": True})


@require_GET
def yo(request):
    usuario = autenticacion.usuario_de(request)
    if not usuario:
        return JsonResponse({"error": "Sesión inválida o vencida.", "codigo": "NO_AUTORIZADO"}, status=401)
    return JsonResponse({"usuario": autenticacion.usuario_json(usuario)})


@require_GET
def mis_compras(request):
    usuario = autenticacion.usuario_de(request)
    if not usuario:
        return JsonResponse({"error": "Inicia sesión para ver tus compras.", "codigo": "NO_AUTORIZADO"}, status=401)
    compras = usuario.compras.prefetch_related("pedidos__producto").order_by("-id")[:30]
    return JsonResponse({"compras": [{
        "referencia": c.referencia, "total_mxn": float(c.total_mxn), "destino": c.destino, "creada": c.creado.isoformat(),
        "pedidos": [_pedido_json(p) for p in c.pedidos.all()],
    } for c in compras]})


@require_GET
def auditoria(request):
    """Bitácora de accesos. Solo ADMIN."""
    usuario = autenticacion.usuario_de(request)
    if not usuario:
        return JsonResponse({"error": "Inicia sesión.", "codigo": "NO_AUTORIZADO"}, status=401)
    if not usuario.is_staff:
        return JsonResponse({"error": "Solo el administrador puede ver la bitácora.", "codigo": "PROHIBIDO"}, status=403)
    filas = Auditoria.objects.all()[:100]
    return JsonResponse({"registros": [{
        "id": a.request_id, "usuario": a.usuario, "rol": a.rol, "metodo": a.metodo, "ruta": a.ruta, "status": a.status,
        "ip": a.ip, "duracion_ms": a.duracion_ms, "fecha": a.creado.isoformat(),
    } for a in filas]})

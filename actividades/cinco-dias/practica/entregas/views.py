import uuid
from django.http import JsonResponse
from django.shortcuts import render, redirect
from django.views.decorators.http import require_GET, require_POST
from . import servicios
from .dominio import ProveedorNoDisponible

@require_GET
def inicio(request):
    return render(request, 'entregas/inicio.html', {'intento': uuid.uuid4()})

@require_POST
def crear(request):
    try: pedido = servicios.registrar_pedido(request.POST)
    except ProveedorNoDisponible as exc:
        return render(request, 'entregas/inicio.html', {'intento': request.POST.get('intento'), 'error': str(exc)}, status=503)
    except (ValueError, KeyError, TypeError) as exc:
        return render(request, 'entregas/inicio.html', {'intento': uuid.uuid4(), 'error': str(exc)}, status=400)
    return redirect('/pedidos/' + pedido.folio)

@require_GET
def detalle(request, folio):
    pedido = servicios.consultar_pedido(folio)
    return render(request, 'entregas/detalle.html', {'pedido': pedido})

@require_GET
def api_detalle(request, folio):
    return JsonResponse(servicios.resumen(servicios.consultar_pedido(folio)))

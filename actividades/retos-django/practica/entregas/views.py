import json,math,os,socket
from uuid import uuid4
from django.http import JsonResponse,HttpResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Pedido
from .reglas import elegir_medio

memoria={}
borrador_global=None

def respuesta(datos,status=200):
 return JsonResponse({**datos,'atendido_por':socket.gethostname(),'worker':os.getpid()},status=status)

def estado(request):
 return respuesta({'estado':'ok','servicio':'Django','medios_disponibles':['bicicleta','moto','camioneta'],'version':1})

def cotizar(request):
 try:
  valores={k:float(request.GET[k]) for k in ['km','kg']}
  if any(not math.isfinite(n) or n<0 for n in valores.values()):raise ValueError()
 except (KeyError,ValueError,TypeError):
  return respuesta({'error':'km y kg son obligatorios y deben ser números finitos no negativos.'},400)
 medio,motivo=elegir_medio(**valores)
 return respuesta({**valores,'medio':medio,'motivo':motivo})

def web(request):
 return HttpResponse('''<!doctype html><html lang="es"><meta charset="utf-8"><title>Dos clientes, un backend</title><style>body{font:18px system-ui;max-width:800px;margin:60px auto;background:#f1f5fa}main{background:white;padding:32px;border-radius:12px}input,button{font:inherit;padding:10px;margin:10px}pre{white-space:pre-wrap;background:#123;color:white;padding:20px}</style><main><h1>Cotización de un paquete</h1><p>Diego Rivera Cisneros · 22121364</p><form><label>Distancia (km)<input name="km" type="number" value="5" step="any"></label><label>Peso (kg)<input name="kg" type="number" value="2" step="any"></label><button>Cotizar</button></form><pre id="resultado">Sin solicitudes.</pre></main><script>document.querySelector('form').onsubmit=async e=>{e.preventDefault();const r=await fetch('/entregas/cotizar/?'+new URLSearchParams(new FormData(e.target)));document.querySelector('pre').textContent='HTTP '+r.status+'\\n'+JSON.stringify(await r.json(),null,2)}</script></html>''')

def destino_datos(request):
 if request.content_type=='application/json':
  try:datos=json.loads(request.body)
  except (ValueError,UnicodeDecodeError):return None
  return datos.get('destino') if isinstance(datos,dict) else None
 return request.POST.get('destino')

@csrf_exempt
def pedidos(request,folio=None):
 if request.method=='POST' and folio is None:
  valor=destino_datos(request)
  if not isinstance(valor,str) or not valor.strip() or len(valor)>240:return respuesta({'error':'Destino obligatorio, máximo 240 caracteres.'},400)
  p=Pedido.objects.create(destino=valor.strip())
  return respuesta({'folio':p.folio,'destino':p.destino,'estado':p.estado},201)
 if request.method!='GET':return respuesta({'error':'Método no permitido.'},405)
 if folio is None:return respuesta({'pedidos':list(Pedido.objects.values('folio','destino','estado'))})
 try:p=Pedido.objects.get(folio=folio)
 except Pedido.DoesNotExist:return respuesta({'error':'Pedido no encontrado.'},404)
 return respuesta({'folio':p.folio,'destino':p.destino,'estado':p.estado})

@csrf_exempt
def pedidos_mal(request,folio=None):
 if request.method=='POST' and folio is None:
  folio=uuid4().hex[:12].upper();memoria[folio]=destino_datos(request)
  return respuesta({'folio':folio},201)
 if folio not in memoria:return respuesta({'error':'Pedido no encontrado en la memoria de este worker.'},404)
 return respuesta({'folio':folio,'destino':memoria[folio]})

def destino_mal(request):
 global borrador_global
 borrador_global=request.GET.get('destino')
 return respuesta({'destino':borrador_global,'almacenamiento':'variable global'})

def confirmar_mal(request):
 if not borrador_global:return respuesta({'error':'Este worker no tiene el destino.'},400)
 p=Pedido.objects.create(destino=borrador_global)
 return respuesta({'folio':p.folio,'destino':p.destino},201)

def destino(request):
 valor=request.GET.get('destino')
 if not valor or len(valor)>240:return respuesta({'error':'Destino obligatorio, máximo 240 caracteres.'},400)
 request.session['destino']=valor
 return respuesta({'destino':valor,'almacenamiento':'session en base compartida'})

def confirmar(request):
 valor=request.session.get('destino')
 if not valor:return respuesta({'error':'La sesión no tiene destino.'},400)
 p=Pedido.objects.create(destino=valor)
 return respuesta({'folio':p.folio,'destino':p.destino},201)

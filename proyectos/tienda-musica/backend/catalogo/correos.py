"""Correo de confirmación de compra.

Con TESITURA_SMTP_HOST (y usuario/contraseña) en backend/.env se envía por SMTP de verdad.
Sin eso funciona en MODO CONSOLA: no sale nada a internet; el correo queda en la bandeja (modelo Correo)
y como archivo HTML en backend/correos_enviados/ para abrirlo en el navegador.
Un fallo al enviar NUNCA cancela la compra: queda registrado con estado «error».
"""
from html import escape
from pathlib import Path

from django.conf import settings
from django.core.mail import EmailMultiAlternatives

from .models import Correo

CARPETA = Path(__file__).resolve().parent.parent / "correos_enviados"


def _dinero(n):
    return f"${float(n):,.0f}"


def construir(compra):
    pedidos = list(compra.pedidos.select_related("producto"))
    lineas_txt, filas = [], []
    for p in pedidos:
        nombre = p.producto.nombre if p.producto else p.tipo
        lineas_txt.append(f"- {p.cantidad} × {nombre}: folio {p.folio}, embalaje {p.nivel_final}"
                          + (" (ajustado por reglas de seguridad)" if p.corregido else ""))
        filas.append(f"<tr><td style='padding:8px 0;border-bottom:1px solid #e3e7e6'>{p.cantidad} × {escape(nombre)}</td>"
                     f"<td style='padding:8px 0;border-bottom:1px solid #e3e7e6;font-weight:700;color:#1b7f52'>{escape(p.folio)}</td>"
                     f"<td style='padding:8px 0;border-bottom:1px solid #e3e7e6'>{escape(p.nivel_final)}</td></tr>")
    pago = f"{compra.pago_marca.upper()} •••• {compra.pago_ultimos4} (pago simulado, ref. {compra.pago_referencia})"
    texto = "\n".join([
        f"Hola {compra.cliente},", "", f"¡Gracias por tu compra en Tesitura! Referencia: {compra.referencia}", "",
        *lineas_txt, "", f"Productos: {_dinero(compra.subtotal_mxn)}", f"Embalaje y seguro: {_dinero(compra.embalaje_mxn)}",
        f"Total: {_dinero(compra.total_mxn)}", f"Pago: {pago}", f"Entrega en: {compra.destino}", "",
        "Puedes preguntar por tu pedido al asistente de la tienda con tu folio.", "",
        "Este es un correo de la práctica académica Tesitura; no se realizó ningún cargo real.",
    ])
    html = f"""<div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;background:#fff;border:1px solid #cfd6d3">
<div style="background:#12181b;padding:18px 24px;border-bottom:3px solid #3be08f"><span style="color:#fff;font-size:22px;font-weight:800;letter-spacing:3px">TESITURA</span>
<span style="color:#3be08f;font-size:11px;letter-spacing:2px;margin-left:10px">MÚSICA E INSTRUMENTOS</span></div>
<div style="padding:24px;color:#1d2427"><h2 style="margin:0 0 6px">¡Gracias por tu compra, {escape(compra.cliente)}!</h2>
<p style="color:#5b6770;margin:0 0 18px">Referencia <b>{escape(compra.referencia)}</b></p>
<table style="width:100%;border-collapse:collapse;font-size:14px"><tr style="color:#5b6770;text-align:left"><th>Producto</th><th>Folio</th><th>Embalaje</th></tr>{''.join(filas)}</table>
<table style="width:100%;margin-top:16px;font-size:14px"><tr><td>Productos</td><td style="text-align:right">{_dinero(compra.subtotal_mxn)}</td></tr>
<tr><td>Embalaje y seguro</td><td style="text-align:right">{_dinero(compra.embalaje_mxn)}</td></tr>
<tr><td style="font-size:18px;font-weight:700">Total</td><td style="text-align:right;font-size:18px;font-weight:700;color:#1b7f52">{_dinero(compra.total_mxn)}</td></tr></table>
<p style="font-size:13px;color:#5b6770;margin-top:18px">Pago: {escape(pago)}<br>Entrega en: {escape(compra.destino)}</p>
<p style="font-size:12px;color:#8b979e;border-top:1px solid #e3e7e6;padding-top:12px">Correo de una práctica académica: no se realizó ningún cargo real.</p></div></div>"""
    return f"Tesitura · Confirmación de tu compra {compra.referencia}", texto, html


def enviar_confirmacion(compra):
    """Devuelve el estado: enviado | simulado | error."""
    asunto, texto, html = construir(compra)
    estado, error = "simulado", ""
    if settings.CORREO_MODO == "smtp":
        try:
            msg = EmailMultiAlternatives(asunto, texto, settings.DEFAULT_FROM_EMAIL, [compra.correo])
            msg.attach_alternative(html, "text/html")
            msg.send(fail_silently=False)
            estado = "enviado"
        except Exception as e:  # noqa: BLE001
            estado, error = "error", f"{type(e).__name__}: {e}"[:300]
    else:
        CARPETA.mkdir(exist_ok=True)
        (CARPETA / f"{compra.referencia}.html").write_text(html, encoding="utf-8")
    Correo.objects.create(compra=compra, para=compra.correo, asunto=asunto, texto=texto, html=html, estado=estado, error=error)
    return estado

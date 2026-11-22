from django.urls import path

from . import views

urlpatterns = [
    path("productos/", views.productos),
    path("productos/<int:pk>/", views.producto_detalle),
    path("facetas/", views.facetas),
    path("destinos/", views.destinos),
    path("recomendar/", views.recomendar_vista),
    path("envio/", views.envio),
    path("pedidos/", views.pedidos),
    path("checkout/", views.checkout),
    path("pedidos/<str:folio>/", views.pedido_detalle),
    path("ubicacion/", views.ubicacion),
    path("asistente/", views.asistente),
    path("asistente/feedback/", views.asistente_feedback),
    path("asistente/metricas/", views.asistente_metricas),
    path("modelos/", views.modelos),
    path("auth/registro/", views.registro),
    path("auth/login/", views.login),
    path("auth/logout/", views.logout),
    path("auth/yo/", views.yo),
    path("mis-compras/", views.mis_compras),
    path("auditoria/", views.auditoria),
]

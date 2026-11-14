from django.urls import path
from entregas import views
urlpatterns=[
 path('',views.web),path('entregas/',views.web),
 path('entregas/estado/',views.estado),path('entregas/cotizar/',views.cotizar),
 path('entregas/pedidos/',views.pedidos),path('entregas/pedidos/<str:folio>/',views.pedidos),
 path('entregas/pedidos-mal/',views.pedidos_mal),path('entregas/pedidos-mal/<str:folio>/',views.pedidos_mal),
 path('entregas/borrador-mal/destino/',views.destino_mal),path('entregas/borrador-mal/confirmar/',views.confirmar_mal),
 path('entregas/borrador/destino/',views.destino),path('entregas/borrador/confirmar/',views.confirmar),
]

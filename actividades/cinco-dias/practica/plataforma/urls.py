from django.urls import path
from entregas import views
urlpatterns = [path('', views.inicio), path('pedidos', views.crear), path('pedidos/<str:folio>', views.detalle), path('api/pedidos/<str:folio>', views.api_detalle)]

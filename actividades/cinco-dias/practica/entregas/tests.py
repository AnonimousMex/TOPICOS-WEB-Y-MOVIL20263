import uuid
from unittest.mock import patch
from django.db import connection
from django.test import Client, TestCase, TransactionTestCase
from .dominio import ProveedorNoDisponible, adaptar, crear_medio, proveedor
from .models import Pedido
from .servicios import registrar_pedido

class FlujoTests(TestCase):
    def datos(self, **changes):
        return dict(destino='Centro de Morelia', kg='3', km='6', intento=str(uuid.uuid4()), **changes)

    def test_cuatro_medios_y_dos_proveedores(self):
        for kg, km, esperado in [(30, 6, 'camioneta'), (9, 10, 'motocicleta'), (3, 6, 'bicicleta'), (1, 5, 'dron')]:
            for formato in ('json', 'xml'):
                sugerencia = adaptar(proveedor(kg, km, formato), formato)
                self.assertEqual(sugerencia.medio, esperado)
                self.assertGreater(crear_medio(sugerencia.medio).planear(kg, km), 0)
        with self.assertRaises(ValueError): crear_medio('dron').planear(10, 4)

    def test_post_redirige_y_get_no_duplica(self):
        response = self.client.post('/pedidos', self.datos())
        self.assertEqual(response.status_code, 302)
        pedido = Pedido.objects.get()
        self.assertEqual(response.url, '/pedidos/' + pedido.folio)
        self.assertContains(self.client.get(response.url), pedido.folio)
        self.assertContains(self.client.get(response.url), pedido.folio)
        self.assertEqual(Pedido.objects.count(), 1)
        self.assertEqual(self.client.get('/api/pedidos/' + pedido.folio).json(), {'folio': pedido.folio, 'estado': 'registrado', 'eta': pedido.eta})

    def test_repetir_intento_no_registra_dos(self):
        data = self.datos()
        first = self.client.post('/pedidos', data)
        second = self.client.post('/pedidos', data)
        self.assertEqual(first.url, second.url)
        self.assertEqual(Pedido.objects.count(), 1)
        data['kg'] = '4'
        self.assertEqual(self.client.post('/pedidos', data).status_code, 400)
        self.assertEqual(Pedido.objects.count(), 1)

    def test_validacion_backend(self):
        for value in ('nan', 'inf', '-1', '0', 'abc'):
            data = self.datos(); data['kg'] = value
            self.assertEqual(self.client.post('/pedidos', data).status_code, 400)
        data = self.datos(); del data['km']
        self.assertEqual(self.client.post('/pedidos', data).status_code, 400)
        self.assertEqual(Pedido.objects.count(), 0)

    def test_consulta_guardada_no_depende_de_ia(self):
        pedido = registrar_pedido(self.datos())
        with patch('entregas.servicios.proveedor', side_effect=ProveedorNoDisponible('IA apagada')) as remote:
            self.assertEqual(self.client.get('/pedidos/' + pedido.folio).status_code, 200)
            self.assertEqual(self.client.get('/api/pedidos/' + pedido.folio).status_code, 200)
            remote.assert_not_called()
            self.assertEqual(self.client.post('/pedidos', self.datos()).status_code, 503)
        self.assertEqual(Pedido.objects.count(), 1)

    def test_plantilla_y_json_comparten_consulta_sin_sql_en_html(self):
        pedido = registrar_pedido(self.datos())
        with self.assertNumQueries(1): self.assertEqual(self.client.get('/pedidos/' + pedido.folio).status_code, 200)
        with self.assertNumQueries(1): self.assertEqual(self.client.get('/api/pedidos/' + pedido.folio).status_code, 200)

    def test_formulario_tiene_csrf(self):
        self.assertEqual(Client(enforce_csrf_checks=True).post('/pedidos', self.datos()).status_code, 403)

class AvisoTests(TransactionTestCase):
    def test_aviso_posterior_y_fallo_no_revierte_pedido(self):
        def comprobar(folio, fallo):
            self.assertFalse(connection.in_atomic_block)
            self.assertTrue(Pedido.objects.filter(folio=folio).exists())
            raise RuntimeError('Aviso apagado')
        with patch('entregas.servicios.avisar', side_effect=comprobar) as aviso:
            pedido = registrar_pedido(dict(destino='Morelia', kg='3', km='6', intento=str(uuid.uuid4()), aviso_caido='on'))
            aviso.assert_called_once()
        self.assertTrue(Pedido.objects.filter(folio=pedido.folio).exists())

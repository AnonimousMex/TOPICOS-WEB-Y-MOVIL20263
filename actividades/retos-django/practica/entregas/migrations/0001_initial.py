from django.db import migrations,models
import entregas.models
class Migration(migrations.Migration):
 initial=True
 dependencies=[]
 operations=[migrations.CreateModel(name='Pedido',fields=[
 ('id',models.BigAutoField(auto_created=True,primary_key=True,serialize=False,verbose_name='ID')),
 ('folio',models.CharField(default=entregas.models.nuevo_folio,max_length=12,unique=True)),
 ('destino',models.CharField(max_length=240)),('estado',models.CharField(default='registrado',max_length=30))])]

from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'actividades/analisis-dataset'))
import pandas as pd,joblib,json
from sklearn.model_selection import train_test_split
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder,StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.metrics import accuracy_score
from material.entrenar_arbol import NUMERICAS,CATEGORICAS,OBJETIVO
from analizar import fit
out=ROOT/'actividades/microservicios-docker/practica/recomendar/modelo';out.mkdir(parents=True,exist_ok=True)
d=pd.read_csv(ROOT/'actividades/analisis-dataset/datos/envios_medios.csv')
a,b,c,e=train_test_split(d[NUMERICAS+CATEGORICAS],d[OBJETIVO],test_size=.2,stratify=d[OBJETIVO],random_state=42)
models={'arbol':fit(a,c)}
for name,est in [('bosque',RandomForestClassifier(n_estimators=120,random_state=42,n_jobs=2,max_depth=18)),('red',MLPClassifier(hidden_layer_sizes=(64,32),max_iter=800,random_state=42,early_stopping=True))]:
 prep=ColumnTransformer([('num',StandardScaler() if name=='red' else 'passthrough',NUMERICAS),('cat',OneHotEncoder(handle_unknown='ignore'),CATEGORICAS)])
 models[name]=Pipeline([('preparacion',prep),(name,est)]).fit(a,c)
result={}
for name,m in models.items():
 joblib.dump(m,out/f'{name}.joblib',compress=3)
 result[name]={'exactitud_prueba':accuracy_score(e,m.predict(b)),'filas_entrenamiento':len(a),'filas_prueba':len(b)}
print(json.dumps(result,indent=2));(ROOT/'actividades/microservicios-docker/evidencias/entrenamiento.json').write_text(json.dumps(result,indent=2)+'\n')

"""Reproduce las ocho actividades y evalúa los seis CSV; no modifica proyectos."""
from __future__ import annotations
import copy
import hashlib
import importlib.metadata
import json
import platform
import random
from contextlib import contextmanager
from pathlib import Path
import joblib
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, precision_score, recall_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
from sklearn.tree import DecisionTreeClassifier, export_text
from material import generar_dataset as g
from material.entrenar_arbol import NUMERICAS, CATEGORICAS, OBJETIVO

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'resultados'
DATA = ROOT / 'datos'
FEATURES = NUMERICAS + CATEGORICAS
NEW_LIMIT = {'peso_kg': 5, 'volumen_l': 25, 'distancia_km': 25}
OUT.mkdir(exist_ok=True)

def save(name, df):
    df.to_csv(OUT / f'{name}.csv', index=True, encoding='utf-8')
    return df.to_markdown(floatfmt='.4f')

@contextmanager
def limits(new=False):
    old = copy.deepcopy(g.LIMITES)
    if new:
        g.LIMITES['dron'] = NEW_LIMIT.copy()
    try:
        yield
    finally:
        g.LIMITES = old

class SinRuido:
    def gauss(self, mu, sigma):
        return 1.0

def score(m, p):
    return g.puntaje(m, p, SinRuido())

def optimo(df, new=False):
    with limits(new):
        return np.array([min((m for m in g.MEDIOS if g.es_posible(m, p)), key=lambda m: score(m, p))
                         for p in df.to_dict('records')])

def fit(x, y, *, depth=8, leaf=5, weight=None, omit=None):
    nums = [c for c in NUMERICAS if c != omit]
    cats = [c for c in CATEGORICAS if c != omit]
    if 'es_de_noche' in x:
        nums += ['es_de_noche']
    model = Pipeline([
        ('preparacion', ColumnTransformer([('numericas', 'passthrough', nums),
         ('categoricas', OneHotEncoder(handle_unknown='ignore'), cats)])),
        ('arbol', DecisionTreeClassifier(max_depth=depth, min_samples_leaf=leaf,
                                         random_state=42, class_weight=weight))])
    return model.fit(x, y)

def recommend(model, x, new=False):
    proba = model.predict_proba(x)
    raw = model.classes_[proba.argmax(axis=1)]
    ruled = []
    with limits(new):
        for p, row in zip(x.to_dict('records'), proba):
            # Orden estable: igual que sorted(zip(classes_, probabilidades), key=-prob).
            ranking = np.argsort(-row, kind='stable')
            viable = [model.classes_[i] for i in ranking if g.es_posible(model.classes_[i], p)]
            if not viable:
                raise ValueError('Ningún medio viable; no se fuerza camioneta sin validar.')
            ruled.append(viable[0])
    return raw, np.array(ruled), proba.max(axis=1)

def impossible(pred, x):
    return sum(not g.es_posible(m, p) for m, p in zip(pred, x.to_dict('records')))

def metrics(model, x, y):
    raw, ruled, conf = recommend(model, x)
    return {'filas':len(y),'exactitud':accuracy_score(y, raw),
            'exactitud_reglas':accuracy_score(y, ruled),
            'precision_dron':precision_score(np.array(y)=='dron',raw=='dron',zero_division=0),
            'recall_dron':recall_score(np.array(y)=='dron',raw=='dron',zero_division=0),
            'predice_dron':int(sum(raw=='dron')),'imposibles':impossible(raw,x),
            'confianza_media':float(conf.mean())}

def generate(n, seed, *, rain=False, new=False):
    old = g.CLIMAS
    if rain:
        g.CLIMAS = (('despejado',.30),('lluvia',.55),('viento_fuerte',.15))
    rows=[]
    try:
        with limits(new):
            rng=random.Random(seed)
            for i in range(n):
                p=g.generar_paquete(rng)
                m=g.recomendar(p,rng,.03)
                # Reproduce el consumo de azar del generador oficial con faltantes=0.
                for _ in g.COLUMNAS_CON_FALTANTES:
                    rng.random()
                rows.append({'id_envio':f'ENV-{i+1:06d}',**p,OBJETIVO:m})
    finally:
        g.CLIMAS=old
    return pd.DataFrame(rows,columns=g.COLUMNAS)

def main():
    d=generate(10000,42)
    d.to_csv(DATA/'envios_medios.csv',index=False)
    xt,xv,yt,yv=train_test_split(d[FEATURES],d[OBJETIVO],test_size=.2,stratify=d[OBJETIVO],random_state=42)
    assert set(xt.index).isdisjoint(xv.index)
    model=fit(xt,yt)
    joblib.dump(model,OUT/'modelo_medios.joblib')
    raw,ruled,_=recommend(model,xv)
    report=['# Resultados reproducidos','',f'Python {platform.python_version()}; partición estratificada 80/20, semilla 42.',
            'Los porcentajes de las tablas se expresan como fracciones (0.921 = 92.1%).']
    def section(title, text):
        report.extend(['',f'## {title}','',text])
    # 1
    section('1. Retrato',save('01_clases',d[OBJETIVO].value_counts().to_frame('cantidad')))
    for c in ['clima','zona_destino']:
        section('1. '+c,save('01_'+c,pd.crosstab(d[c],d[OBJETIVO],normalize='index')))
    section('1. Límites observados',save('01_limites',d.groupby(OBJETIVO)[['peso_kg','volumen_l','distancia_km']].agg(['min','median','max'])))
    labels_invalid=impossible(d[OBJETIVO],d[FEATURES])
    short=d[(d[OBJETIVO]=='camioneta')&(d.distancia_km<2)]
    big=(short.peso_kg>25)|(short.volumen_l>90)
    cold=short.refrigerado.eq(1)
    summary={'etiquetas_imposibles':labels_invalid,'camionetas_cortas':len(short),
             'camionetas_grandes':int(big.sum()),'camionetas_refrigeradas':int(cold.sum()),
             'justificadas_union':int((big|cold).sum()),'sin_razon_fisica':int((~(big|cold)).sum()),
             'periferia_hasta_7_km':float((d[d.zona_destino=='periferia'].distancia_km<=7).mean())}
    section('1. Justificación física',json.dumps(summary,ensure_ascii=False,indent=2))
    # 2
    hours=pd.crosstab(d.hora_salida,d[OBJETIVO]);save('02_horas',hours)
    night=(d.hora_salida<6)|(d.hora_salida>=21)
    section('2. Día y noche',save('02_noche',pd.crosstab(night,d[OBJETIVO])))
    nx=xt.assign(es_de_noche=((xt.hora_salida<6)|(xt.hora_salida>=21)).astype(int))
    nv=xv.assign(es_de_noche=((xv.hora_salida<6)|(xv.hora_salida>=21)).astype(int))
    section('2. Variable nocturna',save('02_comparacion',pd.DataFrame({'base':metrics(model,xv,yv),'es_de_noche':metrics(fit(nx,yt),nv,yv)}).T))
    # 3
    errors=xv.assign(real=yv,predicho=raw,con_reglas=ruled)
    errors=errors[errors.real!=errors.predicho]
    save('03_errores_detalle',errors)
    section('3. Confusiones',save('03_confusiones',errors.groupby(['real','predicho']).size().to_frame('cantidad').sort_values('cantidad',ascending=False)))
    labels=sorted(yv.unique())
    save('03_matriz',pd.DataFrame(confusion_matrix(yv,raw,labels=labels),index=labels,columns=labels))
    # 4
    prep=model.named_steps['preparacion'];tree=model.named_steps['arbol']
    names=list(prep.get_feature_names_out())
    imports={c:0.0 for c in FEATURES}
    for name,val in zip(names,tree.feature_importances_):
        n=name.split('__',1)[1]
        original=next(c for c in FEATURES if n==c or n.startswith(c+'_'))
        imports[original]+=float(val)
    section('4. Importancia agrupada',save('04_importancias',pd.Series(imports,name='importancia').sort_values(ascending=False).to_frame()))
    ablate={c:accuracy_score(yv,fit(xt,yt,omit=c).predict(xv)) for c in FEATURES}
    section('4. Ablación',save('04_ablacion',pd.DataFrame({'exactitud_sin_columna':ablate}).assign(cambio=lambda t:t.exactitud_sin_columna-accuracy_score(yv,raw))))
    (OUT/'04_arbol.txt').write_text(export_text(tree,feature_names=names,max_depth=3))
    # 5
    train=xt.assign(**{OBJETIVO:yt})
    min_n=int(yt.value_counts().min()); moto_n=int((yt=='moto').sum())
    unders=pd.concat([part.sample(n=min_n,random_state=42) for _,part in train.groupby(OBJETIVO)])
    drone=train[train[OBJETIVO]=='dron']
    overs=pd.concat([train,drone.sample(n=moto_n-len(drone),replace=True,random_state=42)])
    balance={'sin_balancear':(xt,yt,None),'submuestreo':(unders[FEATURES],unders[OBJETIVO],None),
             'repetir_drones':(overs[FEATURES],overs[OBJETIVO],None),'pesos_balanceados':(xt,yt,'balanced')}
    b=[]
    for name,(bx,by,w) in balance.items():
        bm=fit(bx,by,weight=w)
        b.append({'estrategia':name,'entrenamiento':len(bx),**metrics(bm,xv,yv)})
    section('5. Balanceo',save('05_balanceo',pd.DataFrame(b).set_index('estrategia')))
    # Evaluación sesgada deliberada: repetir solo la prueba cambia prevalencia.
    test=xv.assign(**{OBJETIVO:yv})
    biased=pd.concat([part.sample(n=int(yv.value_counts().max()),replace=True,random_state=42) for _,part in test.groupby(OBJETIVO)])
    section('5. Trampa: prueba balanceada',save('05_prueba_sesgada',pd.DataFrame([metrics(model,biased[FEATURES],biased[OBJETIVO])],index=['no_comparable'])))
    # 6
    optimum=optimo(xv); optimum_train=optimo(xt)
    clean=fit(xt,optimum_train)
    _,clean_pred,_=recommend(clean,xv)
    costs={}
    for name,pred in [('optimo',optimum),('etiquetas',np.array(yv)),('modelo_reglas',ruled),('entrenado_optimo',clean_pred)]:
        total=sum(score(m,p) for m,p in zip(pred,xv.to_dict('records')))
        costs[name]={'costo_total':total}
    base=costs['optimo']['costo_total']
    for v in costs.values():v['sobrecosto_porcentaje']=(v['costo_total']/base-1)*100
    section('6. Costos sin ruido (puntos de la fórmula, no pesos)',save('06_costos',pd.DataFrame(costs).T))
    six={'acuerdo_optimo_etiquetas':float(np.mean(optimum==np.array(yv))),
         'modelo_sin_reglas_etiquetas':accuracy_score(yv,raw),'modelo_reglas_etiquetas':accuracy_score(yv,ruled),
         'modelo_reglas_optimo':float(np.mean(ruled==optimum)),
         'errores_reglas_contra_etiqueta':int(sum(ruled!=np.array(yv))),
         'errores_reglas_que_son_optimos':int(sum((ruled!=np.array(yv))&(ruled==optimum)))}
    section('6. Acuerdos',json.dumps(six,indent=2))
    save('06_casos',xv.assign(etiqueta=yv,optimo=optimum,modelo=ruled))
    # 7: propiedades con precondiciones explícitas.
    def properties(m):
        _,before,_=recommend(m,xv)
        half=xv.copy();half['peso_kg']/=2
        same=np.array([all(g.es_posible(v,p)==g.es_posible(v,q) for v in g.MEDIOS)
                       for p,q in zip(xv.to_dict('records'),half.to_dict('records'))])
        _,after,_=recommend(m,half)
        t10=xv.copy();t10['hora_salida']=10
        t16=xv.copy();t16['hora_salida']=16
        _,a,_=recommend(m,t10);_,b,_=recommend(m,t16)
        no=xv.copy();no['fragil']=0
        yes=xv.copy();yes['fragil']=1
        _,f0,_=recommend(m,no);_,f1,_=recommend(m,yes)
        low=xv.copy();low['trafico']='bajo'
        high=xv.copy();high['trafico']='alto'
        _,t0,_=recommend(m,low);_,t1,_=recommend(m,high)
        return {'exactitud':accuracy_score(yv,m.predict(xv)),
                'peso_sin_cambio_factibilidad':int(sum(same&(before!=after))),
                'hora_10_a_16':int(sum(a!=b)),
                'fragil_sale_camioneta':int(sum((f0=='camioneta')&(f1!='camioneta'))),
                'trafico_sale_dron':int(sum((t0=='dron')&(t1!='dron'))),
                'casos_peso_comparables':int(sum(same))}
    deep=fit(xt,yt,depth=None,leaf=1)
    section('7. Coherencia con reglas',save('07_propiedades',pd.DataFrame({'profundidad_8':properties(model),'sin_limite':properties(deep)}).T))
    half=xv.copy();half['distancia_km']/=2
    oh=optimo(half)
    counter=np.where((optimum!='camioneta')&(oh=='camioneta'))[0]
    example=None
    if len(counter):
        i=int(counter[0]);p=xv.iloc[i].to_dict();q=half.iloc[i].to_dict()
        example={'original':p,'distancia_reducida':q['distancia_km'],'optimo_original':optimum[i],
                 'optimo_reducido':oh[i],'costos_original':{m:score(m,p) for m in g.MEDIOS if g.es_posible(m,p)},
                 'costos_reducido':{m:score(m,q) for m in g.MEDIOS if g.es_posible(m,q)}}
    section('7. Contraejemplo de distancia',json.dumps({'cantidad':len(counter),'ejemplo':example},ensure_ascii=False,indent=2))
    cheap=xv.copy();cheap['valor_declarado_mxn']=1000
    costly=xv.copy();costly['valor_declarado_mxn']=30000
    _,c0,_=recommend(model,cheap);_,c1,_=recommend(model,costly)
    o0=optimo(cheap);o1=optimo(costly)
    seven={'datos_valor_mayor_20000':int(sum(d.valor_declarado_mxn>20000)),
           'cambios_modelo_valor':int(sum(c0!=c1)),'cambios_optimo_valor':int(sum(o0!=o1))}
    section('7. Sensibilidad a valor declarado',json.dumps(seven,indent=2))
    # Verificar propiedades contra el oráculo, no solo contra un modelo.
    reduced=xv.copy();reduced['peso_kg']/=2
    same=np.array([all(g.es_posible(v,p)==g.es_posible(v,q) for v in g.MEDIOS)
                   for p,q in zip(xv.to_dict('records'),reduced.to_dict('records'))])
    assert not np.any(same&(optimum!=optimo(reduced)))
    for name,left,right,condition in [
        ('hora',xv.assign(hora_salida=10),xv.assign(hora_salida=16),lambda a,b:a!=b),
        ('fragil',xv.assign(fragil=0),xv.assign(fragil=1),lambda a,b:(a=='camioneta')&(b!='camioneta')),
        ('trafico',xv.assign(trafico='bajo'),xv.assign(trafico='alto'),lambda a,b:(a=='dron')&(b!='dron'))]:
        assert not np.any(condition(optimo(left),optimo(right))),name
    # 8
    scenarios={'referencia':generate(5000,99),'lluvias':generate(5000,99,rain=True),'drones':generate(5000,99,new=True)}
    rows=[]
    for name,frame in scenarios.items():
        frame.to_csv(DATA/f'{name}_99.csv',index=False)
        for updated in ([False,True] if name=='drones' else [False]):
            pr,rr,conf=recommend(model,frame[FEATURES],new=updated)
            with limits(name=='drones'):
                invalid=impossible(rr,frame[FEATURES])
            rows.append({'escenario':name+('_reglas_nuevas' if updated else ''),
                         'exactitud_cruda':accuracy_score(frame[OBJETIVO],pr),
                         'exactitud_reglas':accuracy_score(frame[OBJETIVO],rr),'confianza_media':conf.mean(),
                         'corregidas':np.mean(pr!=rr),'imposibles_finales':invalid,
                         **{f'recomienda_{m}':np.mean(rr==m) for m in g.MEDIOS}})
    section('8. Escenarios de cambio',save('08_escenarios',pd.DataFrame(rows).set_index('escenario')))
    pool=generate(1000,123,new=True)
    pool.to_csv(DATA/'drones_entrenamiento_123.csv',index=False)
    target=scenarios['drones'];retrain=[]
    pool_hash=set(pd.util.hash_pandas_object(pool[FEATURES+[OBJETIVO]],index=False))
    target_hash=set(pd.util.hash_pandas_object(target[FEATURES+[OBJETIVO]],index=False))
    assert pool_hash.isdisjoint(target_hash), 'Adaptación y evaluación comparten filas exactas'
    for n in [200,500,1000]:
        new=pool.sample(n=n,random_state=42)
        # Idea propia: reetiquetar lo viejo con el oráculo nuevo; viable aquí por simulación.
        relabeled=d.copy();relabeled[OBJETIVO]=optimo(d[FEATURES],new=True)
        for name,frame in [('solo_nuevos',new),('viejos_mas_nuevos',pd.concat([d,new])),
                           ('viejos_reetiquetados_mas_nuevos',pd.concat([relabeled,new]))]:
            m=fit(frame[FEATURES],frame[OBJETIVO]);_,pred,_=recommend(m,target[FEATURES],new=True)
            retrain.append({'estrategia':name,'nuevos':n,'total':len(frame),
                            'exactitud_reglas':accuracy_score(target[OBJETIVO],pred),
                            'acuerdo_optimo_nuevo':np.mean(pred==optimo(target[FEATURES],new=True))})
    section('8. Reentrenamiento',save('08_reentrenamiento',pd.DataFrame(retrain)))
    # 6 CSV: el modelo se entrena en la partición de la base, no en las variantes.
    variant_out=ROOT.parent/'analisis-envios-data'/'resultados';variant_out.mkdir(exist_ok=True)
    variants=[];dist=[]
    for path in sorted(DATA.glob('envios[1-6].csv')):
        frame=pd.read_csv(path);x=frame[FEATURES];y=frame[OBJETIVO]
        pred=model.predict(x)
        row_hash=pd.util.hash_pandas_object(frame[FEATURES+[OBJETIVO]],index=False)
        seen_hash=set(pd.util.hash_pandas_object(d.loc[xt.index,FEATURES+[OBJETIVO]],index=False))
        seen=row_hash.isin(seen_hash)
        variants.append({'archivo':path.stem,'filas':len(y),'exactitud_total':accuracy_score(y,pred),
                         'baseline_mayoritaria':y.value_counts(normalize=True).max(),
                         'filas_vistas_entrenamiento':int(seen.sum()),
                         'exactitud_no_vistas':accuracy_score(y[~seen],pred[~seen]) if (~seen).any() else None,
                         'clase_desconocida':int(sum(~y.isin(model.classes_)))})
        for cls,n in y.value_counts().items():dist.append({'archivo':path.stem,'medio':cls,'cantidad':n,'proporcion':n/len(y)})
        labels=sorted(set(y)|set(pred))
        pd.DataFrame(confusion_matrix(y,pred,labels=labels),index=labels,columns=labels).to_csv(variant_out/f'{path.stem}_matriz.csv')
        pd.DataFrame(classification_report(y,pred,output_dict=True,zero_division=0)).T.to_csv(variant_out/f'{path.stem}_metricas.csv')
    pd.DataFrame(variants).to_csv(variant_out/'resumen.csv',index=False)
    pd.DataFrame(dist).to_csv(variant_out/'distribuciones.csv',index=False)
    section('Seis CSV: resultados y solapamiento',pd.DataFrame(variants).to_markdown(index=False,floatfmt='.4f'))
    (OUT/'RESULTADOS.md').write_text('\n'.join(report)+'\n')
    versions={name:importlib.metadata.version(name) for name in ['pandas','numpy','scikit-learn','scipy','joblib','tabulate']}
    meta={'python':platform.python_version(),'versiones':versions,'seed_split':42,'entrenamiento':len(xt),'prueba':len(xv),
          'sha256_entradas':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(DATA.glob('*.csv'))},
          'resumen_actividad_1':summary,'resumen_actividad_6':six,'resumen_actividad_7':seven}
    (OUT/'ejecucion.json').write_text(json.dumps(meta,indent=2,ensure_ascii=False)+'\n')
    print(pd.DataFrame(variants).to_string(index=False))
    print('Verificaciones: partición disjunta y cuatro propiedades del oráculo correctas.')
    print(f'Resultados guardados en {OUT}')

if __name__=='__main__':
    main()

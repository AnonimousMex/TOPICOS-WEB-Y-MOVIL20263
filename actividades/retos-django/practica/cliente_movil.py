import argparse,json,urllib.request
parser=argparse.ArgumentParser()
parser.add_argument('--url',default='http://127.0.0.1:18081/entregas/cotizar/?km=5&kg=2')
args=parser.parse_args()
with urllib.request.urlopen(args.url) as respuesta:datos=json.load(respuesta)
print(json.dumps(datos,ensure_ascii=False,indent=2))

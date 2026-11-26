"""RAG local para auditar Tesitura con un modelo de Ollama (sin internet y sin enviar el código a nadie).

1. Divide el código del proyecto (solo código, sin documentación) en fragmentos de 40 líneas.
2. Indexa los fragmentos con TF-IDF (scikit-learn).
3. Para cada pregunta de auditoría recupera los fragmentos más parecidos y se los pasa al modelo.
4. Guarda la respuesta junto con los archivos y líneas recuperados, para poder verificarla.

Uso (con `ollama serve` corriendo y `ollama pull llama3.2`):
    backend/.venv/bin/python evidencias/auditoria_ia/rag_local.py
Se excluyen .env, la base de datos, modelos, datasets, compilados y dependencias.
"""
import json
import sys
import urllib.request
from pathlib import Path

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

RAIZ = Path(__file__).resolve().parents[2]
EXT = {".py", ".dart", ".kts", ".xml", ".yaml"}  # solo código: los .md contienen respuestas ya escritas y contaminarían la auditoría
EXCLUIR = {".venv", "build", ".dart_tool", "__pycache__", "node_modules", "evidencias", "corpus", "migrations", "modelos", "datos", ".gradle"}
MODELO = sys.argv[1] if len(sys.argv) > 1 else "llama3.2"
PREGUNTAS = [
    "¿Qué valores de configuración de Django no son seguros para producción?",
    "¿Hay secretos o credenciales escritos en el código?",
    "¿Cómo está configurado CORS y qué riesgo tiene?",
    "¿Cómo se protegen las contraseñas y el token de sesión?",
    "¿El cobro del checkout evita cobrar dos veces la misma compra?",
    "¿Se guarda el número completo de la tarjeta o el CVV?",
    "¿El modelo .joblib o el corpus quedan dentro de la app Flutter?",
    "¿Qué rutas de la API exigen sesión o rol de administrador?",
]


def fragmentos():
    salida = []
    for ruta in sorted(RAIZ.rglob("*")):
        if not ruta.is_file() or ruta.suffix not in EXT or EXCLUIR & set(ruta.relative_to(RAIZ).parts):
            continue
        lineas = ruta.read_text(encoding="utf-8", errors="ignore").splitlines()
        for i in range(0, len(lineas), 40):
            texto = "\n".join(lineas[i:i + 40]).strip()
            if len(texto) > 80:
                salida.append((str(ruta.relative_to(RAIZ)), i + 1, texto))
    return salida


def preguntar(prompt):
    cuerpo = json.dumps({"model": MODELO, "prompt": prompt, "stream": False, "options": {"temperature": 0.1}}).encode()
    pet = urllib.request.Request("http://localhost:11434/api/generate", cuerpo, {"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(pet, timeout=600))["response"]


def main():
    frags = fragmentos()
    vec = TfidfVectorizer(token_pattern=r"[A-Za-z_áéíóúñ]{2,}", sublinear_tf=True)
    matriz = vec.fit_transform([f[2] for f in frags])
    print(f"{len(frags)} fragmentos indexados", file=sys.stderr)
    informe = [f"# Auditoría con RAG local ({MODELO})", "", f"Fragmentos indexados: {len(frags)}. Recuperación: TF-IDF, 5 fragmentos por pregunta.", ""]
    for n, pregunta in enumerate(PREGUNTAS, 1):
        sim = cosine_similarity(vec.transform([pregunta]), matriz)[0]
        top = sim.argsort()[::-1][:5]
        contexto = "\n\n".join(f"[{frags[i][0]}:{frags[i][1]}]\n{frags[i][2]}" for i in top)
        prompt = (
            "Eres un auditor de seguridad. Responde en español SOLO con lo que se ve en los fragmentos; "
            "si no está en ellos, di «no hay evidencia en los fragmentos». Cita archivo:línea. No inventes archivos.\n\n"
            f"FRAGMENTOS:\n{contexto}\n\nPREGUNTA: {pregunta}\n"
        )
        print(f"pregunta {n}/{len(PREGUNTAS)}", file=sys.stderr)
        informe += [f"## {n}. {pregunta}", "", preguntar(prompt).strip(), "", "Fragmentos recuperados: " + ", ".join(f"`{frags[i][0]}:{frags[i][1]}`" for i in top), ""]
    (Path(__file__).parent / "salida_rag_llama32.md").write_text("\n".join(informe), encoding="utf-8")


main()

import os
from pathlib import Path
BASE_DIR=Path(__file__).resolve().parent.parent
SECRET_KEY=os.environ.get('DJANGO_SECRET_KEY','laboratorio-academico-22121364-sin-datos-personales')
DEBUG=False
ALLOWED_HOSTS=['localhost','127.0.0.1','web','testserver']
INSTALLED_APPS=['django.contrib.contenttypes','django.contrib.sessions','entregas']
MIDDLEWARE=['django.contrib.sessions.middleware.SessionMiddleware']
ROOT_URLCONF='plataforma.urls'
WSGI_APPLICATION='plataforma.wsgi.application'
if os.environ.get('POSTGRES_HOST'):
 DATABASES={'default':{'ENGINE':'django.db.backends.postgresql','HOST':os.environ['POSTGRES_HOST'],'NAME':'laboratorio','USER':'laboratorio','PASSWORD':os.environ['POSTGRES_PASSWORD']}}
else:
 DATABASES={'default':{'ENGINE':'django.db.backends.sqlite3','NAME':BASE_DIR/'db.sqlite3'}}
SESSION_ENGINE='django.contrib.sessions.backends.db'
DEFAULT_AUTO_FIELD='django.db.models.BigAutoField'
USE_TZ=True

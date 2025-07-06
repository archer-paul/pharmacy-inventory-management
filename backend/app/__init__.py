"""
PharmStock Backend Application
"""

__version__ = "1.0.0"
__author__ = "Paul"
__description__ = "API Backend pour PharmStock - Gestion intelligente des stocks pharmaceutiques"

APP_NAME = "PharmStock Backend"
APP_VERSION = __version__
APP_DESCRIPTION = __description__

tags_metadata = [
    {"name": "health", "description": "Points de terminaison pour vérifier l'état de santé de l'API"},
    {"name": "medication", "description": "Analyse des médicaments via intelligence artificielle"},
    {"name": "system", "description": "Informations système et configuration"},
]

CORS_ORIGINS = [
    "http://localhost:4200",
    "http://127.0.0.1:4200", 
    "https://*.web.app",
    "https://*.firebaseapp.com",
]

import logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger("pharmstock")

def get_app_info():
    return {"name": APP_NAME, "version": APP_VERSION, "description": APP_DESCRIPTION, "author": __author__}

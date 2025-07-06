# PharmStock - Gestion des Stocks Pharmaceutiques

**Français | [English](README.md)**

Une application web moderne destinée aux pharmaciens pour gérer intelligemment leurs stocks de médicaments récupérés à l'hôpital grâce à l'analyse par intelligence artificielle.

## Démonstration en Direct

**🚀 Essayez l'application maintenant : [https://pharmstock-prod-2025.web.app](https://pharmstock-prod-2025.web.app)**

L'application est entièrement déployée et prête à l'emploi. Visitez simplement le lien ci-dessus pour commencer à gérer votre inventaire pharmaceutique.

## Fonctionnalités

- **Scanner Intelligent** : Capture photo avec la caméra du smartphone pour analyser les médicaments
- **Analyse IA** : Extraction automatique des informations médicamenteuses avec Google Gemini Vision
  - Nom du médicament et dosage
  - Laboratoire pharmaceutique
  - Date de péremption
  - Numéro de lot/batch
  - Nombre d'unités (excluant les alvéoles vides)
- **Interface Mobile-First** : Design responsive optimisé pour smartphones
- **Export de Données** : Téléchargement CSV et copie dans le presse-papiers
- **Gestion Multi-Sessions** : Support pour plusieurs sessions de scan
- **Inventaire Temps Réel** : Gestion d'inventaire en direct avec mises à jour automatiques

## Architecture

### Frontend (HTML/CSS/JavaScript)
- **Technologie** : JavaScript vanilla avec standards web modernes
- **UI/UX** : Design moderne vert/blanc, layout responsive mobile-first
- **Caméra** : Accès caméra native avec interface intuitive
- **PWA Ready** : Support hors-ligne et installation mobile

### Backend (Python FastAPI)
- **Framework** : FastAPI avec gestion des fichiers multipart
- **IA** : Intégration Google Gemini Vision pour l'analyse d'images
- **API** : API RESTful avec documentation Swagger automatique
- **CORS** : Configuré pour les environnements de développement et production

### Déploiement (Google Cloud Platform)
- **Backend** : Cloud Run (conteneurisé avec Docker)
- **Frontend** : Firebase Hosting
- **CI/CD** : Cloud Build pour déploiement automatique
- **Secrets** : Secret Manager pour la gestion des clés API

## Parcours Utilisateur

1. **Accueil** : Page d'accueil avec aperçu des fonctionnalités
2. **Scanner** : Interface caméra avec guide visuel et capture intuitive
3. **Analyse** : Indicateur de chargement avec progression durant l'analyse IA
4. **Résultats** : Tableau détaillé avec options d'export et capacité de nouveau scan
5. **Multi-Scan** : Accumulation des résultats pour captures multiples

## Démarrage Rapide

L'application est prête à l'emploi sur **[https://pharmstock-prod-2025.web.app](https://pharmstock-prod-2025.web.app)**

### Pour le Développement

#### Prérequis
- Node.js 18+
- Python 3.11+
- Google Cloud CLI
- Firebase CLI

#### Configuration Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou venv\Scripts\activate  # Windows
pip install -r requirements.txt

# Créer le fichier .env avec votre clé API Gemini
echo "GEMINI_API_KEY=votre_cle_api" > .env

# Démarrer le serveur
python -m uvicorn app.main_storage:app --reload --port 8000
```

#### Développement Frontend
```bash
cd frontend
# Démarrer serveur local (pour développement)
python -m http.server 8080
```

L'application locale sera accessible sur `http://localhost:8080`

## Déploiement Google Cloud

### Prérequis
1. Compte Google Cloud avec facturation activée
2. Clé API Gemini depuis [Google AI Studio](https://makersuite.google.com/app/apikey)

### Déploiement Automatisé
```bash
# 1. Configuration projet GCP
./setup_gcp.sh

# 2. Configuration clé API Gemini
./setup_gemini.sh

# 3. Déploiement application
./deploy_pharmstock.sh
```

### Étapes de Déploiement Manuel

#### 1. Configuration GCP
```bash
gcloud auth login
gcloud config set project VOTRE_PROJECT_ID

# Activer les APIs requises
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

#### 2. Configuration API Gemini
```bash
# Stocker la clé API dans Secret Manager
echo -n "VOTRE_CLE_API_GEMINI" | gcloud secrets create gemini-api-key --data-file=-
```

#### 3. Déploiement Backend
```bash
# Build et déploiement vers Cloud Run
gcloud builds submit --tag gcr.io/VOTRE_PROJECT_ID/pharmstock-backend ./backend
gcloud run deploy pharmstock-backend \
    --image gcr.io/VOTRE_PROJECT_ID/pharmstock-backend \
    --region europe-west1 \
    --allow-unauthenticated \
    --update-secrets GEMINI_API_KEY=gemini-api-key:latest
```

#### 4. Déploiement Frontend
```bash
# Configuration Firebase
firebase login
firebase init hosting
firebase use --add VOTRE_PROJECT_ID

# Déploiement vers Firebase Hosting
firebase deploy
```

## Documentation API

### Analyse de Médicament
```http
POST /analyze-medication
Content-Type: multipart/form-data

file: fichier image
session_id: string (optionnel, défaut: "default")
```

### Format de Réponse
```json
{
  "medications": [
    {
      "id": "uuid",
      "nom": "Nom Médicament 1000mg",
      "laboratoire": "Laboratoire Pharmaceutique",
      "date_peremption": "12/2025",
      "numero_lot": "ABC123",
      "nombre_unites": 8,
      "confiance": 0.95,
      "timestamp": "2025-01-15T10:30:00",
      "session_id": "default"
    }
  ],
  "success": true,
  "message": "Analyse terminée avec succès"
}
```

### Gestion Inventaire
```http
GET /medications?session_id=default     # Obtenir tous les médicaments
DELETE /medications?session_id=default  # Vider l'inventaire
GET /medications/export?session_id=default  # Exporter CSV
GET /health                             # Vérification santé
```

## Configuration

### Variables d'Environnement
- `GEMINI_API_KEY` : Clé API Google Gemini (requis)
- `PORT` : Port du serveur (défaut : 8080 pour Cloud Run)

### Optimisation API
Le prompt Gemini est optimisé pour extraire :
- Nom du médicament avec dosage
- Laboratoire pharmaceutique
- Date de péremption (format DD/MM/YYYY)
- Numéro de lot/batch avec détection améliorée
- Nombre d'unités excluant les alvéoles vides
- Score de confiance pour la qualité d'analyse

## Structure du Projet

```
pharmacy-inventory-management/
├── backend/                    # Application FastAPI
│   ├── app/
│   │   ├── main_storage.py    # Point d'entrée principal
│   │   ├── services/          # Services logique métier
│   │   └── __init__.py        # Métadonnées application
│   ├── Dockerfile             # Configuration conteneur
│   └── requirements.txt       # Dépendances Python
├── frontend/                  # Application web statique
│   ├── index.html            # Fichier application principal
│   ├── firebase.json         # Configuration Firebase hosting
│   └── src/                  # Artefacts Angular originaux (déprécié)
├── deployment/               # Scripts de déploiement
│   ├── setup_gcp.sh         # Configuration projet GCP
│   ├── setup_gemini.sh      # Configuration clé API
│   └── deploy_pharmstock.sh # Automatisation déploiement complet
└── .gcp_config              # Configuration déploiement
```

## Système de Design

### Couleurs
- **Primaire** : Vert médical (#28a745, #20c997)
- **Secondaire** : Blanc/Gris (#f8f9fa, #e9ecef)
- **Accent** : Bleu information (#17a2b8)
- **Erreur** : Rouge (#dc3545)

### Composants
- **Boutons** : Gradients verts avec animations hover
- **Cards** : Ombres subtiles avec coins arrondis
- **Loading** : Spinners animés avec messaging
- **Tableaux** : Responsive avec indicateurs visuels

## Sécurité

### Frontend
- Validation types de fichiers (images uniquement)
- Gestion erreurs utilisateur
- HTTPS requis pour accès caméra

### Backend
- Validation stricte des uploads
- Limitations taille fichiers
- CORS configuré pour domaines autorisés
- Gestion secrets via Google Secret Manager

## Optimisations Performance

### Traitement Images
- Compression automatique avant upload
- Validation et conversion format
- Optimisation taille pour appels API

### Déploiement
- **Bundle** : Assets statiques optimisés
- **Cache** : Headers de cache optimisés
- **CDN** : Distribution globale Firebase Hosting

### Mobile
- **PWA** : Installation écran d'accueil
- **Offline** : Cache assets critiques
- **Touch** : Interface tactile optimisée
- **Responsive** : Breakpoints adaptatifs

## Dépannage

### Problèmes Courants
1. **Caméra non accessible** : Vérifier HTTPS et permissions
2. **Erreur CORS** : Vérifier URL backend dans l'application
3. **Erreur API Gemini** : Vérifier clé API et quotas
4. **Erreur Déploiement** : Vérifier facturation GCP et activation APIs

### Commandes Utiles
```bash
# Logs Cloud Run backend
gcloud logs read --service=pharmstock-backend

# Logs Firebase frontend
firebase hosting:channel:list

# Vérification santé
curl https://pharmstock-backend-dssnndhw7a-ew.a.run.app/health
```

## Gestion des Coûts

### Coûts Google Cloud
- **Cloud Run** : Paiement par requête (coût très faible pour usage typique)
- **Firebase Hosting** : Niveau gratuit suffisant pour la plupart des cas
- **API Gemini** : Paiement par requête (environ 0,001$ par image)
- **Secret Manager** : Coût minimal pour stockage clé API

### Conseils d'Optimisation
- Utiliser Cloud Run min-instances=0 pour efficacité coût
- Surveiller usage API Gemini dans Google Cloud Console
- Configurer alertes facturation pour contrôle coûts

## Feuille de Route

### Version 1.1
- [ ] Système d'authentification utilisateurs
- [ ] Historique des scans et persistance
- [ ] Notifications push pour dates péremption
- [ ] Mode batch pour scan simultané multiple

### Version 1.2
- [ ] Intégration base de données médicaments
- [ ] Suggestions correction automatiques
- [ ] Tableau de bord analytics et rapports
- [ ] API publique pour intégrations tierces

## Licence

Licence MIT - Voir le fichier LICENSE pour les détails.

## Support

Pour les problèmes et questions :
1. Consulter la [section dépannage](#dépannage)
2. Examiner les logs Cloud Run pour problèmes backend
3. Tester l'application en direct sur [https://pharmstock-prod-2025.web.app](https://pharmstock-prod-2025.web.app)

---

**Conçu avec ❤️ par Paul** | **Essayez maintenant : [pharmstock-prod-2025.web.app](https://pharmstock-prod-2025.web.app)**
#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Aucun projet GCP configuré"
    echo "Exécutez d'abord : ./setup_gcp.sh"
    exit 1
fi

echo "🚀 DÉPLOIEMENT PHARMSTOCK SUR GCP"
echo "================================="
echo "Projet: $PROJECT_ID"

# Vérifications préalables
echo "🔍 Vérifications préalables..."

# Vérifier le secret Gemini
if ! gcloud secrets describe gemini-api-key >/dev/null 2>&1; then
    echo "❌ Secret gemini-api-key non trouvé"
    echo "Exécutez d'abord: ./setup_gemini.sh"
    exit 1
fi

echo "✅ Secret Gemini OK"

# Étape 1: Build et déploiement du backend
echo ""
echo "📦 1. Déploiement du backend..."

# Build de l'image Docker
echo "Construction de l'image Docker..."
gcloud builds submit ./backend \
    --tag gcr.io/$PROJECT_ID/pharmstock-backend \
    --timeout=600s

echo "✅ Image construite"

# Déploiement sur Cloud Run
echo "Déploiement sur Cloud Run..."
gcloud run deploy pharmstock-backend \
    --image gcr.io/$PROJECT_ID/pharmstock-backend \
    --region europe-west1 \
    --platform managed \
    --allow-unauthenticated \
    --memory 512Mi \
    --cpu 1 \
    --concurrency 100 \
    --max-instances 5 \
    --min-instances 0 \
    --timeout 300 \
    --update-secrets GEMINI_API_KEY=gemini-api-key:latest

# Récupérer l'URL du backend
BACKEND_URL=$(gcloud run services describe pharmstock-backend --region=europe-west1 --format="value(status.url)")
echo "✅ Backend déployé: $BACKEND_URL"

# Test du backend
echo "🧪 Test du backend..."
if curl -s "$BACKEND_URL/health" | grep -q "healthy"; then
    echo "✅ Backend fonctionne"
else
    echo "⚠️  Backend à vérifier"
fi

# Étape 2: Préparation du frontend
echo ""
echo "🌐 2. Préparation du frontend..."

# Créer une version pour la production
cp frontend/index_multi_final.html frontend/index.html

# Mettre à jour l'URL de l'API dans le frontend
sed -i.bak "s|http://192.168.1.36:8000|$BACKEND_URL|g" frontend/index.html
echo "✅ URL API mise à jour: $BACKEND_URL"

# Étape 3: Configuration et déploiement Firebase
echo ""
echo "🔥 3. Déploiement Firebase..."

# Connexion Firebase
echo "Connexion à Firebase..."
firebase login --no-localhost

# Initialiser Firebase si nécessaire
if [ ! -f .firebaserc ]; then
    echo "Initialisation du projet Firebase..."
    firebase use --add $PROJECT_ID
fi

# Déploiement Firebase
echo "Déploiement sur Firebase Hosting..."
firebase deploy --only hosting --project $PROJECT_ID

# URL finale
FRONTEND_URL="https://$PROJECT_ID.web.app"

# Restaurer le fichier original
mv frontend/index.html.bak frontend/index.html 2>/dev/null || true

echo ""
echo "🎉 DÉPLOIEMENT TERMINÉ !"
echo "======================="
echo "📱 Application: $FRONTEND_URL"
echo "🔗 Backend: $BACKEND_URL"
echo "📚 API Docs: $BACKEND_URL/docs"
echo ""
echo "💰 Monitoring des coûts :"
echo "https://console.cloud.google.com/billing/overview?project=$PROJECT_ID"
echo ""
echo "🧪 Test immédiat :"
echo "curl $BACKEND_URL/health"

echo ""
echo "✅ PharmStock est maintenant accessible partout dans le monde !"

#!/bin/bash
set -e

PROJECT_ID="pharmstock-prod-2025"

echo "🚀 DÉPLOIEMENT PHARMSTOCK MAINTENANT"
echo "=================================="

# Vérifier le secret
if ! gcloud secrets describe gemini-api-key >/dev/null 2>&1; then
    echo "❌ Secret gemini-api-key non trouvé"
    echo "Créez-le d'abord avec votre clé API Gemini"
    exit 1
fi

# Créer le Dockerfile pour le backend
cat > backend/Dockerfile << 'DOCKER_EOF'
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
ENV PORT=8080

WORKDIR /app

# Copier et installer les dépendances
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code de l'application
COPY . .

EXPOSE $PORT

# Commande de démarrage
CMD exec gunicorn --bind :$PORT --workers 1 --worker-class uvicorn.workers.UvicornWorker --timeout 300 app.main_storage:app
DOCKER_EOF

echo "✅ Dockerfile créé"

# Build de l'image
echo "📦 Construction de l'image..."
gcloud builds submit ./backend \
    --tag gcr.io/$PROJECT_ID/pharmstock-backend \
    --timeout=1200s

echo "✅ Image construite"

# Déploiement sur Cloud Run
echo "🏃 Déploiement sur Cloud Run..."
gcloud run deploy pharmstock-backend \
    --image gcr.io/$PROJECT_ID/pharmstock-backend \
    --region europe-west1 \
    --platform managed \
    --allow-unauthenticated \
    --memory 512Mi \
    --cpu 1 \
    --concurrency 80 \
    --max-instances 3 \
    --min-instances 0 \
    --timeout 300 \
    --update-secrets GEMINI_API_KEY=gemini-api-key:latest

# Récupérer l'URL
BACKEND_URL=$(gcloud run services describe pharmstock-backend --region=europe-west1 --format="value(status.url)")

echo ""
echo "🎉 BACKEND DÉPLOYÉ !"
echo "=================="
echo "📡 URL: $BACKEND_URL"
echo "📚 API Docs: $BACKEND_URL/docs"

# Test
echo ""
echo "🧪 Test du backend..."
sleep 5
if curl -s "$BACKEND_URL/health" | grep -q "healthy"; then
    echo "✅ Backend fonctionne parfaitement !"
else
    echo "⚠️  Backend déployé, vérification en cours..."
fi

# Préparer le frontend
echo ""
echo "🌐 Préparation du frontend..."
cp frontend/index_multi_final.html frontend/index.html
sed -i.bak "s|http://192.168.1.36:8000|$BACKEND_URL|g" frontend/index.html

echo "✅ Frontend prêt avec URL: $BACKEND_URL"
echo ""
echo "🔥 POUR LE FRONTEND :"
echo "1. Allez sur https://console.firebase.google.com"
echo "2. Créez un projet (ou utilisez pharmstock-prod-2025)"
echo "3. Hosting > Commencer"
echo "4. Uploadez le dossier frontend/"
echo ""
echo "💾 Sauvegarde :"
echo "BACKEND_URL=$BACKEND_URL" >> .gcp_config

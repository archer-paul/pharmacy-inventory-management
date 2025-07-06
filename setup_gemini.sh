#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Aucun projet GCP configuré"
    echo "Exécutez d'abord : ./setup_gcp.sh"
    exit 1
fi

echo "🔑 CONFIGURATION SECRET GEMINI"
echo "=============================="
echo "Projet: $PROJECT_ID"

# Vérifier si le secret existe déjà
if gcloud secrets describe gemini-api-key >/dev/null 2>&1; then
    echo "✅ Secret gemini-api-key existe déjà"
    read -p "Voulez-vous le mettre à jour ? (y/n): " UPDATE_SECRET
    
    if [[ $UPDATE_SECRET =~ ^[Yy]$ ]]; then
        echo "Entrez votre nouvelle clé API Gemini :"
        read -s GEMINI_KEY
        echo
        echo -n "$GEMINI_KEY" | gcloud secrets versions add gemini-api-key --data-file=-
        echo "✅ Secret mis à jour"
    else
        echo "✅ Secret conservé tel quel"
    fi
else
    echo "Création du secret gemini-api-key..."
    echo "Entrez votre clé API Gemini (elle ne s'affichera pas) :"
    read -s GEMINI_KEY
    echo
    
    if [ -z "$GEMINI_KEY" ]; then
        echo "❌ Clé API vide"
        exit 1
    fi
    
    echo -n "$GEMINI_KEY" | gcloud secrets create gemini-api-key --data-file=-
    echo "✅ Secret créé"
fi

# Accorder les permissions au service Cloud Run
echo "Configuration des permissions..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
COMPUTE_SA="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$COMPUTE_SA" \
    --role="roles/secretmanager.secretAccessor" \
    --quiet

echo "✅ Permissions configurées"

echo ""
echo "🧪 Test du secret..."
SECRET_VALUE=$(gcloud secrets versions access latest --secret="gemini-api-key")
echo "Clé configurée : ${SECRET_VALUE:0:15}..."

echo ""
echo "✅ Configuration Gemini terminée"
echo "Prochaine étape : ./deploy_pharmstock.sh"

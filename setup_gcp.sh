#!/bin/bash
set -e

echo "🔐 CONFIGURATION GCP PHARMSTOCK"
echo "==============================="

# Vérifier les prérequis
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI non installé"
    echo "Installez-le avec : sudo apt-get install google-cloud-cli"
    exit 1
fi

if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI non installé"
    echo "Installez-le avec : npm install -g firebase-tools"
    exit 1
fi

# Étape 1: Connexion à GCP
echo ""
echo "1. 🔐 Connexion à GCP..."
echo "Ceci va ouvrir votre navigateur pour l'authentification"
read -p "Appuyez sur Entrée pour continuer..."

gcloud auth login
gcloud auth application-default login

# Étape 2: Lister les projets existants
echo ""
echo "📋 Projets GCP existants :"
gcloud projects list --format="table(projectId,name,projectNumber)" || echo "Aucun projet trouvé"

echo ""
read -p "Voulez-vous créer un nouveau projet ? (y/n): " CREATE_NEW

if [[ $CREATE_NEW =~ ^[Yy]$ ]]; then
    echo ""
    echo "📝 Création d'un nouveau projet..."
    read -p "ID du projet (ex: pharmstock-prod-2024): " PROJECT_ID
    read -p "Nom d'affichage (ex: PharmStock Production): " PROJECT_NAME
    
    echo "Création du projet $PROJECT_ID..."
    if gcloud projects create $PROJECT_ID --name="$PROJECT_NAME"; then
        echo "✅ Projet $PROJECT_ID créé avec succès"
    else
        echo "❌ Erreur lors de la création du projet"
        exit 1
    fi
else
    echo ""
    echo "📋 Projets disponibles :"
    gcloud projects list --format="table(projectId,name)"
    echo ""
    read -p "ID du projet existant à utiliser: " PROJECT_ID
fi

# Étape 3: Sélectionner le projet
echo ""
echo "⚙️ Configuration du projet $PROJECT_ID..."
gcloud config set project $PROJECT_ID

# Étape 4: Vérifier la facturation
echo ""
echo "💳 Vérification de la facturation..."
BILLING_ENABLED=$(gcloud beta billing projects describe $PROJECT_ID --format="value(billingEnabled)" 2>/dev/null || echo "false")

if [ "$BILLING_ENABLED" = "false" ]; then
    echo "⚠️  FACTURATION NON ACTIVÉE !"
    echo ""
    echo "🔗 Activez la facturation sur :"
    echo "https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
    echo ""
    echo "Une fois activée, relancez ce script."
    exit 1
else
    echo "✅ Facturation activée"
fi

# Étape 5: Activer les APIs nécessaires
echo ""
echo "🔧 Activation des APIs Google Cloud..."
echo "Cela peut prendre quelques minutes..."

gcloud services enable cloudbuild.googleapis.com --quiet
gcloud services enable run.googleapis.com --quiet
gcloud services enable secretmanager.googleapis.com --quiet
gcloud services enable firebase.googleapis.com --quiet
gcloud services enable aiplatform.googleapis.com --quiet

echo "✅ APIs activées"

# Étape 6: Configuration par défaut
echo ""
echo "📍 Configuration des paramètres par défaut..."
gcloud config set compute/region europe-west1
gcloud config set compute/zone europe-west1-b
gcloud config set run/region europe-west1

echo ""
echo "🎉 CONFIGURATION TERMINÉE !"
echo "=========================="
echo "✅ Projet configuré : $PROJECT_ID"
echo "✅ Région définie : europe-west1"
echo "✅ APIs activées"
echo ""
echo "📋 Prochaines étapes :"
echo "1. Configurer le budget sur console.cloud.google.com"
echo "2. Exécuter : ./setup_gemini.sh"
echo "3. Exécuter : ./deploy_pharmstock.sh"

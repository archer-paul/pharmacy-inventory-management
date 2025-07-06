#!/bin/bash
set -e

echo "🔐 CONFIGURATION GCP PHARMSTOCK"
echo "==============================="

# Étape 1: Connexion
echo "1. Connexion à GCP..."
gcloud auth login
gcloud auth application-default login

# Étape 2: Lister les projets existants
echo ""
echo "📋 Projets existants :"
gcloud projects list --format="table(projectId,name,projectNumber)"

echo ""
read -p "Voulez-vous créer un nouveau projet ? (y/n): " CREATE_NEW

if [[ $CREATE_NEW =~ ^[Yy]$ ]]; then
    read -p "Nom du projet (ex: pharmstock-prod): " PROJECT_ID
    read -p "Nom d'affichage (ex: PharmStock Production): " PROJECT_NAME
    
    echo "Création du projet $PROJECT_ID..."
    gcloud projects create $PROJECT_ID --name="$PROJECT_NAME"
    echo "✅ Projet créé"
else
    read -p "ID du projet existant à utiliser: " PROJECT_ID
fi

# Étape 3: Sélectionner le projet
echo "Configuration du projet $PROJECT_ID..."
gcloud config set project $PROJECT_ID

# Étape 4: Vérifier la facturation
echo ""
echo "💳 Vérification de la facturation..."
BILLING_ENABLED=$(gcloud beta billing projects describe $PROJECT_ID --format="value(billingEnabled)" 2>/dev/null || echo "false")

if [ "$BILLING_ENABLED" = "false" ]; then
    echo "⚠️  Facturation non activée !"
    echo "Allez sur console.cloud.google.com > Billing pour l'activer"
    echo "Puis relancez ce script"
    exit 1
else
    echo "✅ Facturation activée"
fi

# Étape 5: Activer les APIs nécessaires
echo ""
echo "🔧 Activation des APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable firebase.googleapis.com
gcloud services enable aiplatform.googleapis.com

echo ""
echo "✅ Configuration terminée !"
echo "Projet configuré : $PROJECT_ID"
echo "Prochaine étape : ./deploy_pharmstock.sh"

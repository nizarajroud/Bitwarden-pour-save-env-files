#!/bin/bash

# Charger les variables d'environnement
source .env

# Vérifier que la session est active
if [ -z "$BW_SESSION" ]; then
    echo "Session Bitwarden non active. Déverrouillage..."
    export BW_SESSION=$(bw unlock --raw)
fi

if [ -z "$1" ]; then
    echo "Usage: get-env.sh <nom-du-projet>"
    echo ""
    echo "Projets disponibles:"
    echo "- $PROJECT_1_NAME"
    echo "- $PROJECT_2_NAME"
    echo "- $PROJECT_3_NAME"
    exit 1
fi

PROJECT_NAME="$1"
ITEM_NAME="$PROJECT_NAME - .env"

# Récupérer le .env
NOTES=$(bw list items --search "$ITEM_NAME" | jq -r '.[0].notes // empty')

if [ -z "$NOTES" ]; then
    echo "❌ Projet '$PROJECT_NAME' introuvable"
    echo ""
    echo "Projets disponibles:"
    echo "- $PROJECT_1_NAME"
    echo "- $PROJECT_2_NAME"
    echo "- $PROJECT_3_NAME"
    exit 1
fi

# Créer le fichier .env
echo "$NOTES" > .env
echo "✅ Fichier .env créé pour $PROJECT_NAME"
#!/bin/bash

# Charger les variables d'environnement
source .env

# Vérifier que la session est active
if [ -z "$BW_SESSION" ]; then
    echo "Session Bitwarden non active. Déverrouillage..."
    export BW_SESSION=$(bw unlock --raw)
fi

# Vérifier si le dossier ENV Files existe
FOLDER_ID=$(bw list folders | jq -r '.[] | select(.name=="ENV Files") | .id')

if [ -z "$FOLDER_ID" ]; then
    echo "Création du dossier ENV Files..."
    FOLDER_ID=$(bw get template folder | jq '.name="ENV Files"' | bw encode | bw create folder | jq -r '.id')
fi

# Construire la liste des projets depuis .env
declare -A PROJECTS
PROJECTS["$PROJECT_1_NAME"]="$PROJECT_1_PATH"
PROJECTS["$PROJECT_2_NAME"]="$PROJECT_2_PATH"
PROJECTS["$PROJECT_3_NAME"]="$PROJECT_3_PATH"

# Sauvegarder chaque .env
for PROJECT_NAME in "${!PROJECTS[@]}"; do
    ENV_FILE="${PROJECTS[$PROJECT_NAME]}"
    
    if [ ! -f "$ENV_FILE" ]; then
        echo "⚠️  Fichier introuvable: $ENV_FILE"
        continue
    fi
    
    ITEM_NAME="$PROJECT_NAME - .env"
    
    # Vérifier si l'item existe déjà
    EXISTING_ID=$(bw list items --search "$ITEM_NAME" | jq -r ".[0].id // empty")
    
    if [ -n "$EXISTING_ID" ]; then
        # Mettre à jour
        ITEM=$(bw get item "$EXISTING_ID")
        UPDATED=$(echo "$ITEM" | jq --arg notes "$(cat "$ENV_FILE")" '.notes=$notes')
        echo "$UPDATED" | bw encode | bw edit item "$EXISTING_ID" > /dev/null
        echo "✅ Mis à jour: $ITEM_NAME"
    else
        # Créer nouveau
        TEMPLATE=$(bw get template item)
        NEW_ITEM=$(echo "$TEMPLATE" | jq \
            --arg name "$ITEM_NAME" \
            --arg notes "$(cat "$ENV_FILE")" \
            --arg folderId "$FOLDER_ID" \
            '.type=2 | .name=$name | .notes=$notes | .folderId=$folderId')
        echo "$NEW_ITEM" | bw encode | bw create item > /dev/null
        echo "✅ Créé: $ITEM_NAME"
    fi
done

# Synchroniser avec le cloud
bw sync
echo ""
echo "🎉 Tous vos .env sont sauvegardés dans Bitwarden!"
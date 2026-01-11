#!/bin/bash

# Charger les variables d'environnement
source .env

# Vérifier que la session est active
if [ -z "$BW_SESSION" ]; then
    echo "Session Bitwarden non active. Déverrouillage..."
    export BW_SESSION=$(bw unlock --raw)
fi

# Vérifier si le dossier ENV Files existe
FOLDER_ID="69254a41-318f-4485-9b3b-b3ce016e8b4d"

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
    EXISTING_ID=$(bw list items --search "$ITEM_NAME" 2>/dev/null | jq -r ".[0].id // empty" 2>/dev/null)
    
    if [ -n "$EXISTING_ID" ]; then
        # Mettre à jour et assigner au dossier
        ITEM=$(bw get item "$EXISTING_ID")
        UPDATED=$(echo "$ITEM" | jq --arg notes "$(cat "$ENV_FILE")" --arg folderId "$FOLDER_ID" '.notes=$notes | .folderId=$folderId')
        echo "$UPDATED" | bw encode | bw edit item "$EXISTING_ID" > /dev/null 2>&1
        echo "✅ Mis à jour: $ITEM_NAME"
    else
        # Créer nouveau item avec JSON manuel
        ENV_CONTENT=$(cat "$ENV_FILE" | jq -Rs .)
        
        ITEM_JSON=$(cat <<EOF
{
  "type": 2,
  "name": "$ITEM_NAME",
  "notes": $ENV_CONTENT,
  "folderId": "$FOLDER_ID",
  "secureNote": {
    "type": 0
  }
}
EOF
)
        
        echo "$ITEM_JSON" | bw encode | bw create item > /dev/null 2>&1
        echo "✅ Créé: $ITEM_NAME"
    fi
done

# Synchroniser avec le cloud
bw sync
echo ""
echo "🎉 Tous vos .env sont sauvegardés dans Bitwarden!"
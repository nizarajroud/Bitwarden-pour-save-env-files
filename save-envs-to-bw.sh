#!/bin/bash

# Charger les variables d'environnement
source .env

# Vérifier que la session est active
if [ -z "$BW_SESSION" ]; then
    echo "Session Bitwarden non active. Déverrouillage..."
    export BW_SESSION=$(bw unlock --raw)
fi

# Vérifier et obtenir le FOLDER_ID dynamiquement
FOLDER_NAME="ENV Files"
FOLDER_ID=$(bw list folders | jq -r ".[] | select(.name==\"$FOLDER_NAME\") | .id")

if [ -z "$FOLDER_ID" ]; then
    echo "❌ Dossier '$FOLDER_NAME' introuvable. Création..."
    FOLDER_ID=$(bw get template folder | jq --arg name "$FOLDER_NAME" '.name=$name' | bw encode | bw create folder | jq -r '.id')
    echo "✅ Dossier créé avec ID: $FOLDER_ID"
else
    echo "📁 Dossier trouvé: $FOLDER_ID"
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
    EXISTING_ID=$(bw list items --search "$ITEM_NAME" 2>/dev/null | jq -r ".[0].id // empty" 2>/dev/null)
    
    if [ -n "$EXISTING_ID" ]; then
        # Mettre à jour et assigner au dossier
        ITEM=$(bw get item "$EXISTING_ID")
        UPDATED=$(echo "$ITEM" | jq --arg notes "$(cat "$ENV_FILE")" --arg folderId "$FOLDER_ID" '.notes=$notes | .folderId=$folderId')
        echo "$UPDATED" | bw encode | bw edit item "$EXISTING_ID" > /dev/null 2>&1
        bw sync > /dev/null 2>&1
        echo "✅ Mis à jour: $ITEM_NAME (Dossier: $FOLDER_ID)"
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
        
        CREATED_ID=$(echo "$ITEM_JSON" | bw encode | bw create item 2>&1 | jq -r '.id // empty')
        
        if [ -n "$CREATED_ID" ]; then
            bw sync > /dev/null 2>&1
            echo "✅ Créé: $ITEM_NAME (ID: $CREATED_ID, Dossier: $FOLDER_ID)"
        else
            echo "❌ Échec de création: $ITEM_NAME"
        fi
    fi
done

# Synchronisation finale
bw sync
echo ""
echo "🎉 Tous vos .env sont sauvegardés dans Bitwarden!"
echo ""
echo "📊 Vérification des items dans le dossier '$FOLDER_NAME':"
bw list items --folderid "$FOLDER_ID" | jq -r '.[] | "  - \(.name)"'
npm install -g @bitwarden/cli
bw --version

config sur keepass 

bw logout && bw login

# 1. Déverrouiller une fois par session
export BW_SESSION=$(bw unlock --raw)

# 2. Sauvegarder tous vos .env (première fois)
save-envs-to-bw.sh

# 3. Lister vos projets
list-envs.sh

# 4. Dans un dossier projet, récupérer le .env
cd ~/projets/monsite
get-env.sh MonSiteWeb


7. Automatiser le déverrouillage
Ajoutez à votre ~/.bashrc :
bash# Fonction pour déverrouiller Bitwarden automatiquement
bw-unlock() {
    if ! bw unlock --check &>/dev/null; then
        export BW_SESSION=$(bw unlock --raw)
        echo "✅ Bitwarden déverrouillé"
    else
        echo "✅ Bitwarden déjà déverrouillé"
    fi
}

# Alias pratiques
alias bwu='bw-unlock'
alias env-save='save-envs-to-bw.sh'
alias env-get='get-env.sh'
alias env-list='list-envs.sh'
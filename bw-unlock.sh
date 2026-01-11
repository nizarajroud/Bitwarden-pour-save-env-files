#!/bin/bash

bw-unlock() {
    if ! bw unlock --check &>/dev/null; then
        export BW_SESSION=$(bw unlock --raw)
        echo "✅ Bitwarden déverrouillé"
    else
        echo "✅ Bitwarden déjà déverrouillé"
    fi
}

#!/usr/bin/env bash
set -e

### ===========================
### CONFIG
### ===========================
GITHUB_USER="brepnm"
REPO_NAME="dotfiles"
DOTFILES_DIR="$HOME/dotfiles"

### ===========================
### CLONE OR UPDATE DOTFILES
### ===========================
if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echo "[+] Cloning dotfiles repo..."
    git clone "https://github.com/$GITHUB_USER/$REPO_NAME.git" "$DOTFILES_DIR"
else
    echo "[+] Updating existing dotfiles repo..."

    cd "$DOTFILES_DIR"

    # Avoid merge errors by stashing
    if ! git diff --quiet; then
        echo "[*] Local changes detected → stashing"
        git stash push -m "install-script-auto-stash" >/dev/null
    fi

    git pull --rebase --autostash
fi


### ===========================
### AUTO-DETECT BASHRC FILE
### ===========================
echo "[+] Searching for bashrc in $DOTFILES_DIR"

CANDIDATES=(
    "$DOTFILES_DIR/.bashrc"
    "$DOTFILES_DIR/bashrc"
    "$DOTFILES_DIR/bash/.bashrc"
    "$DOTFILES_DIR/bash/bashrc"
    "$DOTFILES_DIR/config/.bashrc"
    "$DOTFILES_DIR/config/bashrc"
)

BASHRC_SRC=""

for f in "${CANDIDATES[@]}"; do
    if [ -f "$f" ]; then
        BASHRC_SRC="$f"
        break
    fi
done

if [ -z "$BASHRC_SRC" ]; then
    echo "[ERROR] No bashrc file found in dotfiles repo."
    echo "Create one named either 'bashrc' or '.bashrc' in repo root."
    exit 1
fi

echo "[+] Found bashrc → $BASHRC_SRC"


### ===========================
### CREATE SYMLINK
### ===========================
BASHRC_DEST="$HOME/.bashrc"

# Backup non-symlink bashrc
if [ -e "$BASHRC_DEST" ] && [ ! -L "$BASHRC_DEST" ]; then
    echo "[*] Backing up existing .bashrc → .bashrc.backup"
    mv "$BASHRC_DEST" "$BASHRC_DEST.backup"
fi

# Remove old symlink
if [ -L "$BASHRC_DEST" ]; then
    rm "$BASHRC_DEST"
fi

echo "[+] Creating symlink: $BASHRC_DEST → $BASHRC_SRC"
ln -s "$(cd "$(dirname "$BASHRC_SRC")" && pwd)/$(basename "$BASHRC_SRC")" "$BASHRC_DEST"


### ===========================
### RELOAD BASHRC
### ===========================
if [[ $- == *i* ]]; then
    echo "[+] Reloading bashrc..."
    source "$HOME/.bashrc"
else
    echo "[*] Non-interactive shell — skipping reload."
fi

echo "[✔] Dotfiles installation complete!"

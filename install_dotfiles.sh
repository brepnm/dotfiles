#!/usr/bin/env bash
set -e

### ===========================
### CONFIG
### ===========================
GITHUB_USER="brepnm"
REPO_NAME="dotfiles"
DOTFILES_DIR="$HOME/dotfiles"
BASHRC_SRC="$DOTFILES_DIR/.bashrc"
BASHRC_DEST="$HOME/.bashrc"

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

# Ensure script is executable after pull
chmod +x "$DOTFILES_DIR/install_dotfiles.sh"

### ===========================
### VALIDATE BASHRC EXISTS
### ===========================
if [ ! -f "$BASHRC_SRC" ]; then
    echo "[ERROR] .bashrc not found at $BASHRC_SRC"
    exit 1
fi

echo "[+] Found bashrc → $BASHRC_SRC"

### ===========================
### CREATE SYMLINK (ABSOLUTE PATH)
### ===========================

# Backup non-symlink bashrc
if [ -e "$BASHRC_DEST" ] && [ ! -L "$BASHRC_DEST" ]; then
    echo "[*] Backing up existing .bashrc → .bashrc.backup"
    mv "$BASHRC_DEST" "$BASHRC_DEST.backup"
fi

# Remove old/broken symlink
if [ -L "$BASHRC_DEST" ] || [ -e "$BASHRC_DEST" ]; then
    rm -f "$BASHRC_DEST"
fi

# Create symlink with absolute path
echo "[+] Creating symlink: $BASHRC_DEST → $BASHRC_SRC"
ln -s "$BASHRC_SRC" "$BASHRC_DEST"

# Verify symlink
if [ -L "$BASHRC_DEST" ]; then
    echo "[✔] Symlink created successfully"
    ls -la "$BASHRC_DEST"
else
    echo "[ERROR] Failed to create symlink"
    exit 1
fi

### ===========================
### RELOAD BASHRC
### ===========================
echo "[+] Reloading bashrc..."
if [ -f "$BASHRC_DEST" ]; then
    # Force source in current shell
    source "$BASHRC_DEST"
    echo "[✔] Dotfiles installation complete!"
    echo "[*] Run 'exec bash -l' to fully reload your shell environment"
else
    echo "[ERROR] .bashrc not accessible at $BASHRC_DEST"
    exit 1
fi

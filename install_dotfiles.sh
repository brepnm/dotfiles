#!/usr/bin/env bash

# === CONFIG ===
DOTFILES_DIR="$HOME/dotfiles"      # your repo location
REPO_URL="https://github.com/brepmn/dotfiles.git"  # your repo URL
FILES_TO_LINK=(bashrc)             # files in repo you want linked to $HOME

# === CLONE OR UPDATE DOTFILES ===
if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echo "Cloning dotfiles repository..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
else
    echo "Updating existing dotfiles repository..."
    git -C "$DOTFILES_DIR" pull
fi

# === CREATE SYMLINKS ===
for file in "${FILES_TO_LINK[@]}"; do
    SRC="$DOTFILES_DIR/$file"
    DEST="$HOME/.$file"

    # Backup existing files
    if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
        echo "Backing up existing $DEST → $DEST.backup"
        mv "$DEST" "$DEST.backup"
    fi

    # Remove old symlink
    [ -L "$DEST" ] && rm "$DEST"

    echo "Creating symlink: $DEST → $SRC"
    ln -s "$SRC" "$DEST"
done

echo "Done! Reloading bash..."
source ~/.bashrc
#!/usr/bin/env bash

# === CONFIG ===
DOTFILES_DIR="$HOME/dotfiles"      # your repo location
REPO_URL="https://github.com/brepnm/dotfiles.git"
FILES_TO_LINK=(bashrc)             # name in your repo, NOT dot-prefixed

# === CLONE OR UPDATE DOTFILES ===
if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echo "Cloning dotfiles repository..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
else
    echo "Updating dotfiles..."
    git -C "$DOTFILES_DIR" pull
fi

# === LINK FILES ===
for file in "${FILES_TO_LINK[@]}"; do
    SRC="$DOTFILES_DIR/$file"
    DEST="$HOME/.$file"

    # Ensure file exists in repo
    if [ ! -e "$SRC" ]; then
        echo "ERROR: $SRC does not exist. Check your dotfiles repo."
        exit 1
    fi

    # Backup real files (not symlinks)
    if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
        echo "Backing up $DEST → $DEST.backup"
        mv "$DEST" "$DEST.backup"
    fi

    # Remove old symlink
    [ -L "$DEST" ] && rm "$DEST"

    echo "Linking $DEST → $SRC"
    ln -s "$SRC" "$DEST"
done

# === SOURCE UPDATED BASHRC ===
if [ -f "$HOME/.bashrc" ]; then
    echo "Reloading bashrc..."
    # Only source when interactive (avoid errors on root cron)
    case $- in
        *i*) source "$HOME/.bashrc" ;;
        *) echo "Non-interactive shell, skipping source" ;;
    esac
else
    echo "WARNING: $HOME/.bashrc does not exist after linking."
fi

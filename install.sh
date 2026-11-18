#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Repository: $REPO"


link() {
    local src="$1"
    local dst="$2"

    mkdir -p "$(dirname "$dst")"

    ln -sfn "$src" "$dst"
    echo "Linked: $dst -> $src"
}

# --------------------------
# ~/.config
# --------------------------

for dir in "$REPO/.config/"*; do
    [[ -e "$dir" ]] || continue
    name="$(basename "$dir")"
    link "$dir" "$HOME/.config/$name"
done

# --------------------------
# ~/.local/share
# --------------------------

mkdir -p "$HOME/.local/share"

for dir in "$REPO/.local/share/"*; do
    [[ -e "$dir" ]] || continue
    name="$(basename "$dir")"
    link "$dir" "$HOME/.local/share/$name"
done

# --------------------------
# Home directory dotfiles
# --------------------------

for file in \
    .gtkrc-2.0 \
    .zshrc \
    .qmlls.ini
do
    [[ -e "$REPO/$file" ]] && link "$REPO/$file" "$HOME/$file"
done

echo
echo "Done!"
[[ -d "$BACKUP_DIR" ]] && echo "Backups stored in: $BACKUP_DIR"

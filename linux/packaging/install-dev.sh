#!/usr/bin/env bash
# Instala o atalho e o ícone do Rumo para o seu usuário, apontando para o build
# local. No Wayland o GNOME só mostra o ícone no dock se achar este .desktop.
#
#   linux/packaging/install-dev.sh          # build de debug
#   linux/packaging/install-dev.sh release  # build de release
#
# Para remover: apague os dois arquivos listados no fim.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
mode="${1:-debug}"
bin="$root/build/linux/x64/$mode/bundle/rumo"
apps="$HOME/.local/share/applications"
icons="$HOME/.local/share/icons/hicolor/256x256/apps"

if [ ! -x "$bin" ]; then
  echo "Não achei $bin. Rode antes: flutter build linux --$mode" >&2
  exit 1
fi

mkdir -p "$apps" "$icons"
install -m 644 "$root/assets/icon/rumo-256.png" "$icons/com.thomazte.rumo.png"
sed "s|^Exec=.*|Exec=$bin|" "$root/linux/packaging/com.thomazte.rumo.desktop" > "$apps/com.thomazte.rumo.desktop"
update-desktop-database "$apps" 2>/dev/null || true
gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

echo "Instalado:"
echo "  $apps/com.thomazte.rumo.desktop"
echo "  $icons/com.thomazte.rumo.png"

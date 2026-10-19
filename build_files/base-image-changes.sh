#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

echo "::group:: ===$(basename "$0")==="

FLATPAK_DIR="/usr/share/ublue-os/homebrew"
SYS_FILE="$FLATPAK_DIR/system-flatpaks.Brewfile"
DX_FILE="$FLATPAK_DIR/system-dx-flatpaks.Brewfile"

if [[ ! -f "$SYS_FILE" || ! -f "$DX_FILE" ]]; then
    echo "::error::System Flatpak Brewfiles missing in $FLATPAK_DIR"
    exit 1
fi

# Append core system flatpaks
cat >> "$SYS_FILE" <<'EOF'
flatpak "com.discordapp.Discord"
flatpak "com.getpostman.Postman"
flatpak "com.heroicgameslauncher.hgl"
flatpak "com.jeffser.Alpaca"
flatpak "com.mastermindzh.tidal-hifi"
flatpak "com.valvesoftware.Steam"
flatpak "io.github.dweymouth.supersonic"
flatpak "io.freetubeapp.FreeTube"
flatpak "io.github.dvlv.boxbuddyrs"
flatpak "io.github.pwr_solaar.solaar"
flatpak "io.github.TransmissionRemoteGtk"
flatpak "im.riot.Riot"
flatpak "net.lutris.Lutris"
flatpak "org.freedesktop.Piper"
flatpak "org.gimp.GIMP"
flatpak "org.gnucash.GnuCash"
flatpak "org.keepassxc.KeePassXC"
flatpak "org.libreoffice.LibreOffice"
flatpak "org.torproject.torbrowser-launcher"
flatpak "tv.kodi.Kodi"
EOF

# Remove firefox and deduplicate
sed -i '/firefox/d' "$SYS_FILE"
sort -u -o "$SYS_FILE" "$SYS_FILE"

# Append DX flatpaks and deduplicate
echo 'flatpak "com.flashforge.FlashPrint"' >> "$DX_FILE"
sort -u -o "$DX_FILE" "$DX_FILE"

# update ca-trust
update-ca-trust

echo "::endgroup::"

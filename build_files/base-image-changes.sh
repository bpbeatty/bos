#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

echo "::group:: ===$(basename "$0")==="

flatpak_path='/usr/share/ublue-os/homebrew'
system_flatpaks='system-flatpaks.Brewfile'
dx_flatpaks='system-dx-flatpaks.Brewfile'


if [ ! -f "${flatpak_path}"/"${system_flatpaks}" ] || \
  [ ! -f "${flatpak_path}"/"${dx_flatpaks}" ]; then
  echo "system-flatpak list missing!"
  exit 1
fi

echo 'flatpak "com.discordapp.Discord"
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
flatpak "tv.kodi.Kodi"' \
  >> "${flatpak_path}"/"${system_flatpaks}"
# remove flatpak
sed -i 's/^.*firefox$//g' "${flatpak_path}"/"${system_flatpaks}"
# no duplicates
cat "${flatpak_path}"/"${system_flatpaks}" | sort -u -o \
  "${flatpak_path}"/"${system_flatpaks}"
echo ' flatpak "com.flashforge.FlashPrint"' \
  >> "${flatpak_path}"/"${dx_flatpaks}"
cat "${flatpak_path}"/"${dx_flatpaks}" | sort -u -o \
  "${flatpak_path}"/"${dx_flatpaks}"

echo "::endgroup::"

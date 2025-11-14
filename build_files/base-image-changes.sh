#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

echo "::group:: ===$(basename "$0")==="

if [ ! -f /etc/ublue-os/system-flatpaks.list ] || \
  [ ! -f /etc/ublue-os/system-flatpaks-dx.list ]; then
  echo "system-flatpak list missing!"
  exit 1
fi

echo "app/com.discordapp.Discord
app/com.getpostman.Postman
app/com.heroicgameslauncher.hgl
app/com.jeffser.Alpaca
app/com.mastermindzh.tidal-hifi
app/com.valvesoftware.Steam
app/io.github.dweymouth.supersonic
app/io.freetubeapp.FreeTube
app/io.github.dvlv.boxbuddyrs
app/io.github.pwr_solaar.solaar
app/io.github.TransmissionRemoteGtk
app/im.riot.Riot
app/net.lutris.Lutris
app/org.freedesktop.Piper
app/org.gimp.GIMP
app/org.gnucash.GnuCash
app/org.keepassxc.KeePassXC
app/org.libreoffice.LibreOffice
app/org.torproject.torbrowser-launcher
app/tv.kodi.Kodi" \
  >> /etc/ublue-os/system-flatpaks.list
# remove flatpak
sed -i 's/^.*firefox$//g' /etc/ublue-os/system-flatpaks.list
# no duplicates
cat /etc/ublue-os/system-flatpaks.list | sort -u -o \
  /etc/ublue-os/system-flatpaks.list
echo "app/com.flashforge.FlashPrint" \
  >> /etc/ublue-os/system-flatpaks-dx.list
cat /etc/ublue-os/system-flatpaks-dx.list | sort -u -o \
  /etc/ublue-os/system-flatpaks-dx.list

echo "::endgroup::"

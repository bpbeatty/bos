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
app/com.github.PintaProject.Pinta
app/com.github.rafostar.Clapper
app/com.github.tchx84.Flatseal
app/com.heroicgameslauncher.hgl
app/com.jeffser.Alpaca
app/com.mastermindzh.tidal-hifi
app/com.mattjakeman.ExtensionManager
app/com.valvesoftware.Steam
app/io.freetubeapp.FreeTube
app/io.github.dvlv.boxbuddyrs
app/io.github.flattool.Ignition
app/io.github.flattool.Warehouse
app/io.github.pwr_solaar.solaar
app/io.github.TransmissionRemoteGtk
app/im.riot.Riot
app/io.gitlab.adhami3310.Impression
app/io.missioncenter.MissionCenter
app/net.lutris.Lutris
app/org.freedesktop.Piper
app/org.gimp.GIMP
app/org.gnome.Calculator
app/org.gnome.Calendar
app/org.gnome.Characters
app/org.gnome.Connections
app/org.gnome.Contacts
app/org.gnome.DejaDup
app/org.gnome.FileRoller
app/org.gnome.Firmware
app/org.gnome.Logs
app/org.gnome.Loupe
app/org.gnome.Maps
app/org.gnome.NautilusPreviewer
app/org.gnome.Papers
app/org.gnome.SimpleScan
app/org.gnome.TextEditor
app/org.gnome.Weather
app/org.gnome.baobab
app/org.gnome.clocks
app/org.gnome.font-viewer
app/org.gnucash.GnuCash
app/org.keepassxc.KeePassXC
app/org.libreoffice.LibreOffice
app/org.mozilla.Thunderbird
app/org.torproject.torbrowser-launcher
app/page.tesk.Refine
app/tv.kodi.Kodi
runtime/org.gtk.Gtk3theme.adw-gtk3
runtime/org.gtk.Gtk3theme.adw-gtk3-dark" \
  > /etc/ublue-os/system-flatpaks.list
cat /etc/ublue-os/system-flatpaks.list | sort -u -o \
  /etc/ublue-os/system-flatpaks.list

echo "app/io.github.getnf.embellish
app/io.podman_desktop.PodmanDesktop
app/me.iepure.devtoolbox
app/sh.loft.devpod
app/com.flashforge.FlashPrint" \
  > /etc/ublue-os/system-flatpaks-dx.list
cat /etc/ublue-os/system-flatpaks-dx.list | sort -u -o \
  /etc/ublue-os/system-flatpaks-dx.list

echo "::endgroup::"

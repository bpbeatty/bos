#!/usr/bin/bash

set -eoux pipefail

echo "::group:: ===$(basename "$0")==="

SERVER_PACKAGES=(
    binutils
    bootc
    clevis
    clevis-dracut
    clevis-udisks2
    erofs-utils
    firefox
    firefox-langpacks
    freeipa-client
    gqrx
    just
    jq
    python-ramalama
    rclone
    sbsigntools
    skopeo
    socat
    tmux
    udica
    yq
)

# ROCm Packages
SERVER_PACKAGES+=(
    rocm-clinfo
    rocm-hip
    rocm-opencl
    rocm-smi
)

REMOVE_PACKAGES=(
  bluefin-backgrounds
  bluefin-cli-logos
  bluefin-faces
  bluefin-fastfetch
  bluefin-schemas
  gnome-shell-extension-tailscale-gnome-qs
  tailscale
  ublue-bling
  ublue-brew
  ublue-fastfetch
  ublue-motd
  ublue-os-signing
)

dnf5 remove -y "${REMOVE_PACKAGES[@]}"

dnf5 install -y "${SERVER_PACKAGES[@]}"

# The superior default editor
dnf5 swap -y \
    nano-default-editor vim-default-editor

dnf5 -y remove bluefin-plymouth
dnf5 -y swap bluefin-logos fedora-logos

dnf5 install -y /tmp/rpms/config/bpbeatty-signing*.rpm

# TMUX config
tee /etc/tmux.conf <<'EOF'
# https://www.rushiagr.com/blog/2016/06/16/everything-you-need-to-know-about-tmux-copy-pasting-ubuntu/
set -g prefix C-a
bind C-a send-prefix
unbind C-b

set -g history-limit 10000
set -g allow-rename off

bind-key j command-prompt -p "join pane from:" "join-pane -s '%%'"
bind-key s command-prompt -p "send pane to:" "join-pane -t '%%'"

set-window-option -g mode-keys vi

bind P paste-buffer
bind-key -Tcopy-mode-vi v send -X begin-selection
bind-key -Tcopy-mode-vi y send -X copy-selection
bind-key -Tcopy-mode-vi r send -X rectangel-toggle
bind-key -Tcopy-mode-vi y send -X copy-pipe "xclip -sel clip -i"
# bind-key -t vi-copy 'v' begin-selection
# bind-key -t vi-copy 'y' copy-selection
# bind-key -t vi-copy 'r' rectangle-toggle
# bind -t vi-copy y copy-pipe "xclip -sel clip -i"

# split pane
bind | split-window -h
bind - split-window -v

# window move vi
bind -r C-h select-window -t :-
bind -r C-l select-window -t :+

bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

bind -r L resize-pane -R 8
bind -r H resize-pane -L 8
bind -r K resize-pane -U 8
bind -r J resize-pane -D 8

# Customize status line
set-option -g status-style bg=default
set-option -g status-style fg=colour240
set -g status-right '|%Y-%m-%d %H:%M|'
EOF

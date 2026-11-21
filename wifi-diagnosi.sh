#!/usr/bin/env bash
# Diagnosi WiFi (macOS / Linux). Sola lettura: non modifica nulla.
# Uso: bash wifi-diagnosi.sh > risultato.txt 2>&1
set -u
OS=$(uname -s)
echo "=== Sistema: $OS $(date) ==="

echo; echo "=== Gateway (router) ==="
if [ "$OS" = "Darwin" ]; then GW=$(route -n get default 2>/dev/null | awk '/gateway/{print $2}')
else GW=$(ip route 2>/dev/null | awk '/default/{print $3; exit}'); fi
echo "Gateway: ${GW:-non trovato}"

echo; echo "=== Info WiFi (canale, banda, segnale, rumore) ==="
if [ "$OS" = "Darwin" ]; then
  /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null \
    || system_profiler SPAirPortDataType 2>/dev/null | sed -n '/Current Network/,/Other Local/p' | head -25
else
  iw dev 2>/dev/null | grep -E 'Interface|channel|ssid'
  iw dev 2>/dev/null | awk '/Interface/{print $2}' | while read -r i; do iw dev "$i" link; done
  nmcli -f IN-USE,SSID,CHAN,FREQ,RATE,SIGNAL,SECURITY dev wifi 2>/dev/null | head -30
fi

echo; echo "=== Ping router (20) ==="
[ -n "${GW:-}" ] && ping -c 20 "$GW" | tail -4
echo; echo "=== Ping internet 8.8.8.8 (20) ==="
ping -c 20 8.8.8.8 | tail -4
echo; echo "=== Ping DNS nome (google.com) ==="
ping -c 5 google.com | tail -3

echo; echo "=== Dispositivi in rete (ARP) ==="
arp -a 2>/dev/null

echo; echo "=== Speed test (download 25MB da Cloudflare) ==="
curl -s -o /dev/null -w "Velocita: %{speed_download} byte/s (~%{speed_download} / 125000 Mbit/s)\n" \
  "https://speed.cloudflare.com/__down?bytes=25000000"
echo; echo "Fatto."

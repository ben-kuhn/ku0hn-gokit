# GoKit commissioning checklist (with hardware attached)

Status: system installed and verified 2026-08-03; items below require the rigs/hardware physically attached.

Pending: apply the staged config (`sudo cp ~/configuration-new.nix /etc/nixos/configuration.nix && sudo nixos-rebuild switch && rm ~/configuration-new.nix`), then log out/in once — this activates the gnome-shell-extensions package (system-monitor extension) and the narrowed GPS udev rule.

## Digirigs
- Plug both Digirigs into any direct USB ports. Do NOT put the Digirig
  Lite behind an external hub (Microchip 0424:2412 hub chips would make
  it match as the full Digirig).
- Verify: `ls -l /dev/TS-50 /dev/Digirig-Lite` (both exist; TS-50 only
  after the full Digirig is attached).
- Verify ALSA names: `cat /proc/asound/cards` shows cards `TS50` and
  `TM271`.
- If either check fails: `udevadm info -a /sys/class/sound/cardN` and
  compare against the rules in `configuration.nix` (`services.udev.extraRules`).
  Note: when manually testing ALSA card renames via sysfs, write WITHOUT a
  trailing newline (`echo -n`), otherwise the kernel rejects with EINVAL.
  udev's ATTR{id} writes are unaffected.

## TS-50 (HF)
- Rig menu: CAT baud 9600 (service expects `-s 9600`; if the rig is set
  to 4800, either change the rig menu or edit rigctld-TS50's `-s`).
- `rigctl -m 2 -r localhost:4532 f` returns the VFO frequency.
- `rigctl -m 2 -r localhost:4532 T 1` keys the rig via CAT; `T 0` unkeys.
- WSJT-X: Radio = Hamlib NET rigctl, localhost:4532, PTT = CAT — test.
- pat: `varahf` — start VARA HF (wine, prefix `~/vara`), confirm connect.

## TM-271 (VHF)
- `direwolf -c ~/direwolf-vhf.conf` — confirm RX decodes; PTT keys via
  `/dev/Digirig-Lite` (CM108 GPIO3).
- Route direwolf's audio to the TM271 device in pavucontrol/GNOME sound
  settings (ADEVICE is `pipewire`; routing is per-app and remembered).
- QtSoundModem: pick the TM271 card in its device dropdowns (the copied
  ini has Enzo's `hw:1,0` which may map to the wrong card here); PTT via
  CM108 `/dev/Digirig-Lite`.

## GPS
- Plug in the receiver; `ls -l /dev/gps0`. Receiver is a u-blox 7
  (USB 1546:01a7), already recognized — `/dev/gps0` symlink confirmed
  working. If missing on replacement puck, get IDs with `lsusb` and add
  the vendor/product to the GPS rules in `configuration.nix`, rebuild.
- `cgps` shows a fix; `chronyc sources` shows the GPS refclock reachable.
- pat grid/position updates from gpsd (config already points at
  localhost:2947).

## Bluetooth TNCs (tncd)
- Pair UV-Pro, Mobilinkd TNC3, Mobilinkd TNC4 in GNOME Bluetooth
  settings; `systemctl status tncd` shows clients connecting.

## First GNOME login
- Nextcloud client: re-enter account password (config was copied;
  credentials live in the keyring). Confirm folder syncs including
  `~/.local/share/pat` ↔ /PAT and `~/Ham Radio`.
- gnome-remote-desktop: set RDP credentials (Settings → System → Remote
  Desktop, or `grdctl rdp set-credentials`), confirm port 3389 from Enzo.

## Cloudflared (optional, when wanted)
- Create a new tunnel in the Cloudflare dashboard.
- `sudo sh -c 'mkdir -p /etc/cloudflared && echo TUNNEL_TOKEN=<token> > /etc/cloudflared/env && chmod 600 /etc/cloudflared/env'`
- `sudo systemctl restart cloudflared`.

## VARA licensing note
- The wine prefix was copied from Enzo; if VARA's callsign/license
  registration complains on the new machine, re-enter it in VARA's
  settings dialog.

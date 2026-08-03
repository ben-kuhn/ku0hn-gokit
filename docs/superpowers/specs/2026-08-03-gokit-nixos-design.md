# GoKit NixOS PC — Design

Date: 2026-08-03
Status: Approved pending user review

## Goal

Build and configure a NixOS PC for the ham radio gokit. Same PC model as Enzo
(the current desktop), cloned from Enzo's configuration with gokit-specific
changes. Target machine is PXE-booted into the NixOS installer at
192.168.10.100 (root / <pxe-root-password>).

## Hardware differences from Enzo

| | Enzo | GoKit |
|---|---|---|
| HF rig | Kenwood TS-2000 (CP2102 serial) | Kenwood TS-50 via **Digirig** |
| VHF rig | — | Kenwood TM-271 via **Digirig Lite** |
| SDR hardware | RTL-SDR etc. | none |

## Disk layout (target)

- **NVMe (Samsung 238 GB)** — wiped, GPT, **no LUKS** (unattended field boots):
  - p1: 1 GB EFI System Partition, vfat, mounted `/boot`
  - p2: ~221 GB ext4, mounted `/`
  - p3: 16 GB swap
- **OCZ Vertex2 SATA (107 GB)** — wiped (contains only a broken/truncated
  RAID1 member from an old Ubuntu install; confirmed unrecoverable and
  unwanted). Single ext4 partition mounted `/storage`, mirroring Enzo.

## System configuration

Managed the same way as Enzo: plain `/etc/nixos/configuration.nix` (no
flakes), channels-based, with the `nix-ham-packages` overlay checked out at
`/home/ku0hn/dev/nix-ham-packages` (public repo
`github.com/ben-kuhn/nix-ham-packages`, cloned via https on the GoKit).

Carried over from Enzo unchanged:

- Hostname exception: `networking.hostName = "GoKit"`.
- GNOME + GDM, autologin as `ku0hn`, autoSuspend off,
  gnome-remote-desktop wanted by graphical.target (this is the remote-access
  path).
- Pipewire with the 9k6 low-latency tuning (192 kHz clock, quantum 32,
  wireplumber ALSA low-latency lua, pulse low-latency config).
- fish as default shell, same user account `ku0hn` (same groups, same SSH
  authorized key). Passwords for `ku0hn` and root copied from Enzo's
  `/etc/shadow` hashes.
- Printing (hplip, gutenprint), avahi, flatpak, AppImage binfmt, plocate,
  fonts, Nix GC settings, QT gtk2 theme, allowUnfree,
  permittedInsecurePackages.
- OpenSSH with the same settings.
- tncd service verbatim: server on 127.0.0.1:8005, callsign KU0HN, all three
  Bluetooth clients (UV-Pro, Mobilinkd TNC3, Mobilinkd TNC4). Bluetooth TNCs
  must be re-paired on the GoKit (post-install step).

### Firewall — ON (differs from Enzo)

```nix
networking.firewall.enable = true;
networking.firewall.allowedTCPPorts = [ 22 8080 3389 8000 8001 8300 8301 ];
networking.firewall.allowedUDPPorts = [ 3389 ];
```

(SSH, pat http, RDP/gnome-remote-desktop, direwolf AGW + KISS, linbpq.)

### Package set

**Kept (ham):** wsjtx, fldigi, flrig, direwolf, qtsoundmodem, qttermtcp,
paracon, xastir, pat, chirp, hamlib_4, tqsl, nanovna-saver, linbpq, ldsped,
mercury-modem, packet-browser-client, minicom, socat, alsa-utils, screen.

**Kept (general):** brave (only browser), sublime4, claude-code, opencode,
nextcloud-client, plus the usual CLI base (wget, curl, git, htop, ncdu,
unzip, gparted, file, fuse, vlc, pavucontrol, flameshot, gnome-tweaks,
appimage-run, solaar, piper, simple-scan, wireguard-tools, python3 with
pyserial/requests/pandas/pip).

**Dropped — dev:** docker + docker-compose, libvirtd/virt-manager/spice USB
redirection, debootstrap, flatpak-builder, wireshark (+ group), hugo, gh,
openscad, orca-slicer, ventoy.

**Dropped — SDR:** sdrangel, gqrx, rtl-sdr (+ rtl-sdr udev package), sdrpp.

**Dropped — remote access:** teamviewer (+ service), rustdesk
(gnome-remote-desktop replaces both).

**Dropped — AX.25 kernel stack:** ax25-apps, ax25-tools, and the
`/etc/ax25/axports` file (dead as of kernel 7.2).

**Kept (VARA):** wine and winetricks — VARA HF and VARA FM run under wine.
The WINEPREFIX at `~/vara` (~800 MB, contains both installs) is copied to
the GoKit; pat's `varahf`/`varafm` modem sections come along with the pat
config copy.

**Dropped — desktop apps:** firefox, google-chrome, calibre, joplin-desktop,
thunderbird, signal-desktop, telegram-desktop, gimp, libreoffice, audacity,
easyeffects, transmission, variety, yubico-piv-tool, yubioath-flutter,
yubikey-personalization udev package.

### Cloudflared

Service kept but gated: reads `TUNNEL_TOKEN` from `/etc/cloudflared/env` via
`EnvironmentFile`, with `ConditionPathExists` so it stays inactive until the
user creates a new tunnel in the Cloudflare dashboard and drops the token in.
Enzo's token is tunnel-specific and is NOT copied.

## Rig integration

### TS-50 + Digirig (HF)

- udev: CP2102 (10c4:ea60, the only one in the box, no serial match) →
  `SYMLINK+="TS-50"`.
- `systemd.services.rigctld-TS50` replaces `rigctld-TS2000`:
  `rigctld -m 2011 -r /dev/TS-50 -s 9600 -P RTS -t 4532 -C ptt_type=RTS -C
  serial_handshake=None` (model 2011 = TS-50S; PTT via RTS is the Digirig
  wiring). Exact baud verified against the rig at commissioning.
- `pat` systemd service wants/after `rigctld-TS50`, same port 4532, so the
  existing pat config keeps working.

### TM-271 + Digirig Lite (VHF)

- No CAT. Audio + PTT via CM108 GPIO on the Lite's hidraw device.
- direwolf: `PTT CM108 /dev/Digirig-Lite`, ADEVICE addressed by pinned ALSA
  card name (below).

### CM108 disambiguation (key design point)

Both Digirig and Digirig Lite expose identical C-Media audio+HID
(0d8c:0012), so vendor/product matching cannot tell them apart. Strategy:
**pin by physical USB port.**

1. Each Digirig is assigned a designated USB port on the GoKit (ports
   labeled physically; documented in the repo).
2. udev rules match on the USB port path (`KERNELS` / `ID_PATH`), not IDs:
   - Rename ALSA cards via `ATTR{id}`: card at port A → `TS50`, card at
     port B → `TM271`. Apps then use `plughw:CARD=TM271` etc.; boot-time
     enumeration order stops mattering.
   - hidraw symlink `/dev/Digirig-Lite` created only for the Lite's port
     (Enzo's ID-only rule would have matched both units — fixed here).
3. The full Digirig's hidraw is unused (its PTT is RTS on the CP2102).
4. Digirigs are not yet attached to the target; rules are written against
   the chosen ports now and verified when hardware is connected
   (post-hardware checklist).

## User configuration copied from Enzo

| What | From | Notes |
|---|---|---|
| pat | `~/.config/pat/*.json` | all three configs |
| direwolf | `~/direwolf-*.conf` | ADEVICE/PTT lines adapted to `plughw:CARD=...` + `/dev/Digirig-Lite` |
| QtSoundModem | `~/QtSoundModem.ini` | audio device fields reviewed at commissioning |
| QtTermTCP | `~/QtTermTCP.ini` | |
| paracon | `~/paracon.cfg` | |
| GridTracker | `~/.config/GridTracker2/` (minus caches) + `~/bin/GridTracker2-2.260705.2-x86_64.AppImage` | AppImage is the deliverable app |
| CHIRP | `~/.chirp/` | app state; radio images sync via the `~/Ham Radio` Nextcloud folder |
| VARA | `~/vara/` (WINEPREFIX, ~800 MB) | VARA HF + FM under wine; audio device selection re-checked at commissioning |
| Nextcloud | `~/.config/Nextcloud/nextcloud.cfg` | credentials are in GNOME keyring → one-time re-auth on first login |
| WSJT-X | package only, no config | per user request |

## CHIRP + pat mailbox sync (both machines)

- **CHIRP**: radio images and other configured sync files live in
  `~/Ham Radio`, which is already a Nextcloud sync folder carried over via
  `nextcloud.cfg` — no new sync entry needed. `~/.chirp` (app state) is
  copied once during install.
- **pat mailbox**: default location (`~/.local/share/pat`). Add one new
  Nextcloud folder-sync connection on **both** Enzo and the GoKit:
  `~/.local/share/pat` ↔ server `/Sync/pat`.

Caveat accepted: pat writes its mailbox while running, so running pat on
both machines simultaneously can produce sync conflicts; the server-side
folder is created on first sync.

## Version control

The GoKit's `configuration.nix`, udev rules, and install/commissioning notes
live in this repo under `nixos/`. This spec lives in
`docs/superpowers/specs/`.

## Install flow

1. SSH from Enzo to the installer (sshpass via nix-shell).
2. Partition/format both disks per layout above; mount under `/mnt`.
3. `nixos-generate-config --root /mnt`; replace generated
   `configuration.nix` with the adapted one from this repo.
4. Clone `nix-ham-packages` so it is available both at eval time during
   install and at `/home/ku0hn/dev/nix-ham-packages` on the installed
   system.
5. `nixos-install` with password hashes injected from Enzo's `/etc/shadow`.
6. Reboot, verify boot to GNOME autologin.
7. rsync user configs (table above) from Enzo to the GoKit as `ku0hn`.
8. Add the two new Nextcloud sync-folder entries on both machines.
9. Verify: systemd services (pat, tncd up; rigctld-TS50 restarting until
   hardware attached is expected), firewall rules, remote desktop.

## Post-hardware commissioning checklist (delivered as a doc in the repo)

- Plug Digirig into its labeled port, Digirig Lite into its labeled port;
  verify `/dev/TS-50`, `/dev/Digirig-Lite`, ALSA cards `TS50`/`TM271`.
- Verify rigctld-TS50 talks to the TS-50 (baud/menu settings on rig).
- direwolf receive/transmit test on the TM-271.
- Pair the three Bluetooth TNCs; verify tncd clients connect.
- First GNOME login: Nextcloud re-auth, gnome-remote-desktop credentials.
- Create new Cloudflare tunnel, drop token into `/etc/cloudflared/env`.
- WSJT-X initial setup (no config copied).

## Out of scope

- SDR hardware/software, dev tooling (dropped above).
- Secure Boot / lanzaboote (not active on Enzo either).
- Recovering data from the OCZ disk (confirmed discardable).

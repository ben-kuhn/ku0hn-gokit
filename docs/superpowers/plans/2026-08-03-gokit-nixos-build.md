# GoKit NixOS Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install and configure the GoKit NixOS PC (target at 192.168.10.100) per the approved spec at `docs/superpowers/specs/2026-08-03-gokit-nixos-design.md`.

**Architecture:** Author the GoKit's `configuration.nix` in this repo (`nixos/`), validate it by evaluation on Enzo, remote-install over SSH onto the PXE-booted installer, then rsync user configs from Enzo and patch the rig-specific bits (TS-50 CAT, Digirig Lite CM108 PTT).

**Tech Stack:** NixOS 26.05 (channels, no flakes), `nix-ham-packages` overlay, sgdisk/mkfs over SSH, sshpass, rsync, udev, hamlib, gpsd/chrony.

## Global Constraints

- Target installer: `root@192.168.10.100`, password `<pxe-root-password>`. Same LAN as Enzo (Enzo is 192.168.10.25).
- **RSSH macro** (installer, as root): every plan step written as `RSSH: <cmd>` means
  `nix-shell -p sshpass --run "sshpass -p <pxe-root-password> ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.10.100 '<cmd>'"`
- **RSCP macro** (copy file to installer): `RSCP: <local> <remote-path>` means
  `nix-shell -p sshpass --run "sshpass -p <pxe-root-password> scp -O -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null <local> root@192.168.10.100:<remote-path>"`
- **GSSH macro** (installed GoKit, key auth from Enzo): `ssh -o StrictHostKeyChecking=no ku0hn@192.168.10.100 '<cmd>'` (Enzo's `~/.ssh/id_rsa` is the authorized "frosty@bob" key; if the GoKit gets a different DHCP address after reboot, find it with `nmap -sn 192.168.10.0/24` and substitute).
- Scratch files go in the session scratchpad directory, never `/tmp`.
- `passwords.nix` (real password hashes) is machine-local on the GoKit — NEVER committed to this repo.
- The repo working dir is `/home/ku0hn/dev/ku0hn-gokit`; all commits happen there on branch `main`.
- Everything destructive targets only 192.168.10.100's disks (`/dev/nvme0n1`, `/dev/sda`) — both confirmed wipeable by the user. No destructive commands run against Enzo.

---

### Task 1: Author the GoKit configuration in the repo and validate by evaluation

**Files:**
- Create: `nixos/configuration.nix` (full content below)
- Create: `nixos/README.md`
- Scratch: `<scratchpad>/evaltest/{configuration.nix,hardware-configuration.nix,passwords.nix}`

**Interfaces:**
- Produces: `nixos/configuration.nix` — copied verbatim to `/mnt/etc/nixos/` in Task 4. It imports `./hardware-configuration.nix` (generated on target) and `./passwords.nix` (created in Task 4), and expects `/home/ku0hn/dev/nix-ham-packages` to exist at eval time.

- [ ] **Step 1: Write `nixos/configuration.nix`** with exactly this content:

```nix
# GoKit — ham radio gokit PC. Derived from Enzo's configuration.
# Spec: docs/superpowers/specs/2026-08-03-gokit-nixos-design.md
{ config, pkgs, ... }:
let
    ham-packages = /home/ku0hn/dev/nix-ham-packages;
in
{
  imports =
    [
      ./hardware-configuration.nix
      # Machine-local user/root hashedPassword definitions; not in git.
      ./passwords.nix
      "${ham-packages}/tncd/module.nix"
    ];

  nixpkgs.overlays = [
    (import ham-packages)
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "GoKit";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.autoSuspend = false;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "ku0hn";

  # Primary remote access path.
  systemd.services.gnome-remote-desktop = {
    wantedBy = [ "graphical.target" ];
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Sound: pipewire with the 9k6 low-latency tuning (verbatim from Enzo).
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    extraConfig.pipewire.adjust-sample-rate = {
      "context.properties" = {
        "default.clock.rate" = 192000;
        "default.allowed-rates" = [ 192000 48000 ];
        "default.clock.quantum" = 32;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 32;
      };
    };
  };

  services.pipewire.wireplumber.configPackages = [
    (pkgs.writeTextDir "share/wireplumber/main.lua.d/99-alsa-lowlatency.lua" ''
      alsa_monitor.rules = {
        {
          matches = {{{ "node.name", "matches", "alsa_output.*" }}};
          apply_properties = {
            ["audio.format"] = "S32LE",
            ["audio.rate"] = "96000", -- for USB soundcards it should be twice your desired rate
            ["api.alsa.period-size"] = 2, -- defaults to 1024, tweak by trial-and-error
            -- ["api.alsa.disable-batch"] = true, -- generally, USB soundcards use the batch mode
          },
        },
      }
    '')
  ];

  services.pipewire.extraConfig.pipewire-pulse."92-low-latency" = {
    "context.properties" = [
      {
        name = "libpipewire-module-protocol-pulse";
        args = { };
      }
    ];
    "pulse.properties" = {
      "pulse.min.req" = "32/48000";
      "pulse.default.req" = "32/48000";
      "pulse.max.req" = "32/48000";
      "pulse.min.quantum" = "32/48000";
      "pulse.max.quantum" = "32/48000";
    };
    "stream.properties" = {
      "node.latency" = "32/48000";
      "resample.quality" = 1;
    };
  };

  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;

  users.users.ku0hn = {
    isNormalUser = true;
    description = "Ben Kuhn";
    extraGroups = [ "networkmanager" "wheel" "dialout" "uucp" "plugdev" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwGNPb7ny6maTCGyvttL7xuwfxy7uCTw39ifUdzL2Q0DXPrOqgCHE3AegxmsmuJGvjGLf6QpHQ3Fp9q88Mrgetr0jIvlffVpp2fw6F+SEuZQnV3eee4iMtC2kHqKXdzBA/OU4mtW5oxpyL74cE+hOroW1ImW/2ydgOqzL0pvBTrZN+OYoLChSCAQIr2j73WfjQTMQTkO47togkbpwLnu3fjoE3OSjYtAHR9gvWI/Y2Q96UoJRmzOvuZQGZD/2RSn2kzVaRnL5QthB1zFwTIgNbkayvSKh7d97tbCmU2rO1pVrP0BA0aWnv6cCcEXl5T/FkFapdegdAXKvEn0gGt99L frosty@bob"
    ];
    packages = with pkgs; [
      # Ham radio
      wsjtx
      fldigi
      flrig
      direwolf
      qtsoundmodem
      qttermtcp
      paracon
      xastir
      tqsl
      packet-browser-client
      # VARA runs under wine (WINEPREFIX ~/vara)
      wine
      winetricks
      # General
      brave
      sublime4
      claude-code
      opencode
      nextcloud-client
      variety
      flameshot
      powerline-fonts
      pavucontrol
      gnome-tweaks
      appimage-run
      solaar
    ];
  };

  # udev rules below use GROUP="plugdev". Enzo gets this group from the
  # rtl-sdr module, which the GoKit doesn't have — define it explicitly.
  users.groups.plugdev = { };

  qt.enable = true;
  qt.platformTheme = "gtk2";
  qt.style = "gtk2";

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  environment.systemPackages = with pkgs; [
    wget
    curl
    pciutils
    usbutils
    gitFull
    fish
    htop
    ncdu
    unzip
    gparted
    file
    fuse
    screen
    minicom
    inetutils
    nmap
    socat
    alsa-utils
    vlc
    nanovna-saver
    (python3.withPackages (p: with p; [ pandas requests pip pyserial ]))
    pat
    chirp
    hamlib_4
    linbpq
    ldsped
    mercury-modem
    gpsd
    cloudflared
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "without-password";
      Macs = [ "hmac-sha2-512-etm@openssh.com" "hmac-sha2-256-etm@openssh.com" "umac-128-etm@openssh.com" "hmac-sha2-256" "hmac-sha2-512" ];
    };
  };

  # Cloudflared — inert until /etc/cloudflared/env exists containing
  # TUNNEL_TOKEN=<token from the Cloudflare dashboard for the new tunnel>.
  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
  };
  users.groups.cloudflared = { };

  systemd.services.cloudflared = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "/etc/cloudflared/env";
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run";
      EnvironmentFile = "/etc/cloudflared/env";
      Restart = "always";
      User = "cloudflared";
      Group = "cloudflared";
    };
  };

  # TS-50 CAT via the Digirig's CP2102. PTT via CAT (no RTS override —
  # that was a TS-2000 data-jack quirk).
  systemd.services.rigctld-TS50 = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.hamlib_4}/bin/rigctld -m 2011 -r /dev/TS-50 -s 9600 -t 4532";
      Restart = "always";
      RestartSec = 5;
      User = "ku0hn";
      Group = "users";
    };
  };

  systemd.services.pat = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "rigctld-TS50.service" ];
    after = [ "rigctld-TS50.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.pat}/bin/pat http";
      Restart = "always";
      User = "ku0hn";
      Group = "users";
    };
  };

  services.tncd = {
    enable = true;
    bluetooth.enable = true;
    settings = {
      server = {
        listen_host = "127.0.0.1";
        listen_port = 8005;
        callsign = "KU0HN";
      };
      "client.0" = {
        name = "UV-Pro";
        type = "bluetooth";
        bdaddr = "38:D2:00:01:52:8F";
        ota_baudrate = 1200;
      };
      "client.1" = {
        name = "Mobilinkd TNC3";
        type = "bluetooth";
        bdaddr = "34:81:F4:3D:98:4B";
        ota_baudrate = 1200;
      };
      "client.2" = {
        name = "Mobilinkd TNC4";
        type = "bluetooth";
        bdaddr = "34:81:F4:AA:B3:D3";
        ota_baudrate = 1200;
      };
    };
  };

  # GPS receiver: gpsd feeds pat (localhost:2947) and chrony.
  services.gpsd = {
    enable = true;
    devices = [ "/dev/gps0" ];
    nowait = true;
  };

  # chrony replaces systemd-timesyncd: NTP pools when online, GPS refclock
  # keeps usable time off-grid.
  services.chrony = {
    enable = true;
    extraConfig = ''
      refclock SHM 0 refid GPS precision 1e-1 offset 0.0 delay 0.2
    '';
  };

  services.locate = {
    enable = true;
    package = pkgs.plocate;
    interval = "hourly";
  };

  services.udev.extraRules = ''
    # TS-50 CAT via the Digirig's CP2102 (the only CP2102 in the box).
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="TS-50"

    # Digirig vs Digirig Lite: both are CM108 (0d8c:0012) with no serial
    # number. The full Digirig's CM108 sits behind its internal Microchip
    # hub (0424:2412); the Lite is a bare CM108. Match structurally.
    # Do NOT connect the Lite through an external hub using a Microchip
    # 0424:2412 chip or it will be misidentified.
    # -- ALSA card naming --
    SUBSYSTEM=="sound", KERNEL=="card*", ATTRS{idVendor}=="0d8c", ATTRS{idProduct}=="0012", ENV{DIGIRIG_SND}="1"
    ENV{DIGIRIG_SND}=="1", ATTRS{idVendor}=="0424", ATTRS{idProduct}=="2412", ATTR{id}="TS50", GOTO="digirig_end"
    ENV{DIGIRIG_SND}=="1", ATTR{id}="TM271", GOTO="digirig_end"
    # -- Digirig Lite PTT hidraw (bare CM108 only) --
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0d8c", ATTRS{idProduct}=="0012", ENV{DIGIRIG_HID}="1"
    ENV{DIGIRIG_HID}=="1", ATTRS{idVendor}=="0424", ATTRS{idProduct}=="2412", GOTO="digirig_end"
    ENV{DIGIRIG_HID}=="1", SYMLINK+="Digirig-Lite", MODE="0660", GROUP="plugdev"
    LABEL="digirig_end"

    # GPS receiver -> /dev/gps0 (covers u-blox, Prolific, CH340 serial
    # GPS dongles; confirm actual IDs at commissioning).
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1546", SYMLINK+="gps0"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", SYMLINK+="gps0"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", SYMLINK+="gps0"
  '';

  # GSD udev package needed for GNOME indicators.
  services.udev.packages = with pkgs; [
    gnome-settings-daemon
  ];

  services.flatpak.enable = true;

  programs.appimage.binfmt = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];

  nix = {
    gc = {
      automatic = true;
      options = "--max-freed 1G --delete-older-than 7d";
    };
  };

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 8080 3389 8000 8001 8300 8301 ];
  networking.firewall.allowedUDPPorts = [ 3389 ];

  # Fresh install on the 26.05 channel.
  system.stateVersion = "26.05";
}
```

- [ ] **Step 2: Write `nixos/README.md`**:

```markdown
# GoKit NixOS configuration

- `configuration.nix` — the GoKit's `/etc/nixos/configuration.nix`.
- `hardware-configuration.nix` — generated by `nixos-generate-config` on
  the GoKit; copied back here for record after install.
- `passwords.nix` — NOT in git. Machine-local file on the GoKit defining
  `users.users.{root,ku0hn}.hashedPassword`.
- Requires `github.com/ben-kuhn/nix-ham-packages` cloned at
  `/home/ku0hn/dev/nix-ham-packages` on the GoKit.
- See `COMMISSIONING.md` for the post-hardware checklist.
```

- [ ] **Step 3: Evaluate the config on Enzo to catch errors before install day.** Create stubs and instantiate (no build):

```bash
SCRATCH=<scratchpad>/evaltest
mkdir -p "$SCRATCH"
cp /home/ku0hn/dev/ku0hn-gokit/nixos/configuration.nix "$SCRATCH/"
cat > "$SCRATCH/hardware-configuration.nix" <<'EOF'
{ ... }:
{
  boot.initrd.availableKernelModules = [ ];
  fileSystems."/" = { device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/disk/by-uuid/0000-0000"; fsType = "vfat"; };
  nixpkgs.hostPlatform = "x86_64-linux";
}
EOF
cat > "$SCRATCH/passwords.nix" <<'EOF'
{ ... }:
{
  users.users.root.hashedPassword = "!";
  users.users.ku0hn.hashedPassword = "!";
}
EOF
nix-instantiate '<nixpkgs/nixos>' -A system -I nixos-config="$SCRATCH/configuration.nix" 2>&1 | tail -5
```

Expected: a `/nix/store/...-nixos-system-GoKit-*.drv` path, no errors. The real `nix-ham-packages` at `/home/ku0hn/dev/nix-ham-packages` on Enzo satisfies the overlay import.
If `services.gpsd.devices` or `nowait` is reported as an unknown option, check `nixos-option` / the module source at `<nixpkgs/nixos/modules/services/misc/gpsd.nix>` and adjust to the option names the 26.05 module actually uses (older form: `services.gpsd.device` singular) — then re-run until clean.

- [ ] **Step 4: Commit**

```bash
cd /home/ku0hn/dev/ku0hn-gokit
git add nixos/configuration.nix nixos/README.md
git commit -m "Add GoKit NixOS configuration"
```

---

### Task 2: Validate the Digirig udev mechanism on Enzo (hardware attached here)

**Files:**
- None (read-only inspection plus a reverted sysfs write on Enzo).

**Interfaces:**
- Consumes: the udev rule strategy from `nixos/configuration.nix` (Task 1).
- Produces: confirmation that (a) the full Digirig's sound card has the 0424:2412 hub ancestor, and (b) `/sys/class/sound/cardN/id` is writable (the `ATTR{id}` rename mechanism works). If (b) fails, STOP and revise the design (fallback: wireplumber `node.description` rules + direwolf `ADEVICE` via pipewire routing only).

- [ ] **Step 1: Find the Digirig's ALSA card number on Enzo**

```bash
cat /proc/asound/cards
```

Expected: a card listed as `USB-Audio - USB Audio Device` (the Digirig CM108). Note its number N.

- [ ] **Step 2: Confirm the ancestor chain matches the planned rules**

```bash
udevadm info -a /sys/class/sound/cardN | grep -E 'looking at|idVendor|idProduct' | head -30
```

Expected: an ancestor with `ATTRS{idVendor}=="0d8c"` / `ATTRS{idProduct}=="0012"` (the CM108) and above it an ancestor with `ATTRS{idVendor}=="0424"` / `ATTRS{idProduct}=="2412"` (the internal hub).

- [ ] **Step 3: Confirm the card id is writable, then revert**

```bash
ORIG=$(cat /sys/class/sound/cardN/id)
echo TS50TEST | sudo tee /sys/class/sound/cardN/id
cat /proc/asound/cards | grep TS50TEST
echo "$ORIG" | sudo tee /sys/class/sound/cardN/id
cat /sys/class/sound/cardN/id
```

Expected: rename visible in `/proc/asound/cards`, then reverted to `$ORIG`. (sudo will prompt the user for their password — that's expected.) If the write fails with EPERM/EINVAL, STOP — report to the user and revise the rename strategy before installing.

- [ ] **Step 4: Record the result in the commit message**

```bash
cd /home/ku0hn/dev/ku0hn-gokit
git commit --allow-empty -m "Verify Digirig CM108 hub ancestry and ALSA card id rename on Enzo"
```

---

### Task 3: Partition, format, and mount the target disks

**Files:**
- None local. Remote: wipes `/dev/nvme0n1` and `/dev/sda` on 192.168.10.100.

**Interfaces:**
- Produces: `/mnt` (root), `/mnt/boot` (ESP), `/mnt/storage` (OCZ), active swap — the layout `nixos-generate-config` reads in Task 4.

- [ ] **Step 1: Pre-flight — confirm the target is the installer and disks match expectations**

RSSH: `hostname; lsblk -o NAME,SIZE,MODEL`
Expected: NixOS installer hostname (`nixos`), `nvme0n1` 238.5G SAMSUNG, `sda` 107.1G OCZ-VERTEX2. STOP if anything differs.

- [ ] **Step 2: Disable any auto-activated swap/RAID remnants**

RSSH: `swapoff -a; mdadm --stop /dev/md127 2>/dev/null; true`

- [ ] **Step 3: Partition the NVMe (1G ESP, root, 16G swap)**

RSSH: `sgdisk --zap-all /dev/nvme0n1 && sgdisk -n1:0:+1GiB -t1:ef00 -c1:boot -n2:0:-16GiB -t2:8300 -c2:root -n3:0:0 -t3:8200 -c3:swap /dev/nvme0n1 && sgdisk -p /dev/nvme0n1`
Expected: three partitions printed: 1 ≈ 1 GiB EF00, 2 ≈ 221 GiB 8300, 3 ≈ 16 GiB 8200.

- [ ] **Step 4: Partition the OCZ (single storage partition)**

RSSH: `sgdisk --zap-all /dev/sda && sgdisk -n1:0:0 -t1:8300 -c1:storage /dev/sda && wipefs -a /dev/sda1 && sgdisk -p /dev/sda`
Expected: one ≈107 GiB partition; `wipefs` clears the stale RAID signature inside it.

- [ ] **Step 5: Create filesystems**

RSSH: `mkfs.fat -F32 -n BOOT /dev/nvme0n1p1 && mkfs.ext4 -F -L nixos /dev/nvme0n1p2 && mkswap -L swap /dev/nvme0n1p3 && mkfs.ext4 -F -L storage /dev/sda1`
Expected: all four succeed without error.

- [ ] **Step 6: Mount everything**

RSSH: `mount /dev/nvme0n1p2 /mnt && mkdir -p /mnt/boot /mnt/storage && mount -o umask=0077 /dev/nvme0n1p1 /mnt/boot && mount /dev/sda1 /mnt/storage && swapon /dev/nvme0n1p3 && lsblk -o NAME,FSTYPE,MOUNTPOINT`
Expected: `/mnt`, `/mnt/boot`, `/mnt/storage` mounted; swap `[SWAP]` active.

- [ ] **Step 7: Commit a build-log note**

```bash
cd /home/ku0hn/dev/ku0hn-gokit
git commit --allow-empty -m "GoKit target partitioned: NVMe esp/root/swap, OCZ as /storage"
```

---

### Task 4: Generate hardware config and stage the NixOS configuration on the target

**Files:**
- Create (repo): `nixos/hardware-configuration.nix` (copied back from target)
- Scratch: `<scratchpad>/passwords.nix` (deleted after copying; contains hashes)
- Remote: `/mnt/etc/nixos/{configuration.nix,hardware-configuration.nix,passwords.nix}`, `/mnt/home/ku0hn/dev/nix-ham-packages`

**Interfaces:**
- Consumes: `nixos/configuration.nix` (Task 1); mounted `/mnt` layout (Task 3).
- Produces: a `/mnt` ready for `nixos-install` (Task 5).

- [ ] **Step 1: Generate hardware configuration on the target**

RSSH: `nixos-generate-config --root /mnt && grep -E 'fileSystems|swapDevices|by-uuid' /mnt/etc/nixos/hardware-configuration.nix | head -12`
Expected: entries for `/`, `/boot`, `/storage`, and one swap device (all by-uuid).

- [ ] **Step 2: Copy the GoKit configuration over the generated one**

RSCP: `/home/ku0hn/dev/ku0hn-gokit/nixos/configuration.nix` `/mnt/etc/nixos/configuration.nix`

- [ ] **Step 3: Create passwords.nix from Enzo's shadow entries** (sudo prompts the user; the file never enters the repo)

```bash
sudo sh -c 'printf "{ ... }:\n{\n  users.users.root.hashedPassword = \"%s\";\n  users.users.ku0hn.hashedPassword = \"%s\";\n}\n" "$(getent shadow root | cut -d: -f2)" "$(getent shadow ku0hn | cut -d: -f2)"' > <scratchpad>/passwords.nix
grep -c hashedPassword <scratchpad>/passwords.nix
```

Expected: `2`. (If Enzo's root hash is `!` or `*`, that's fine — root stays locked, matching Enzo; `sudo` still works via wheel.)

- [ ] **Step 4: Copy passwords.nix to the target and delete the local copy**

RSCP: `<scratchpad>/passwords.nix` `/mnt/etc/nixos/passwords.nix`
Then: `rm <scratchpad>/passwords.nix`
Then RSSH: `chmod 600 /mnt/etc/nixos/passwords.nix`

- [ ] **Step 5: Clone nix-ham-packages where both the installer eval and the running system will find it**

RSSH: `mkdir -p /mnt/home/ku0hn/dev && git clone https://github.com/ben-kuhn/nix-ham-packages /mnt/home/ku0hn/dev/nix-ham-packages && mkdir -p /home && ln -sfn /mnt/home/ku0hn /home/ku0hn && ls /home/ku0hn/dev/nix-ham-packages/tncd/module.nix`
Expected: clone succeeds; `module.nix` path listed. (The symlink makes `/home/ku0hn/...` resolve during `nixos-install` evaluation; after reboot the real `/home/ku0hn/dev/nix-ham-packages` exists.)

- [ ] **Step 6: Copy hardware-configuration.nix back into the repo and commit**

```bash
nix-shell -p sshpass --run "sshpass -p <pxe-root-password> scp -O -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.10.100:/mnt/etc/nixos/hardware-configuration.nix /home/ku0hn/dev/ku0hn-gokit/nixos/hardware-configuration.nix"
cd /home/ku0hn/dev/ku0hn-gokit
git add nixos/hardware-configuration.nix
git commit -m "Record GoKit generated hardware configuration"
```

---

### Task 5: Run nixos-install and boot the GoKit

**Files:**
- Remote: installs the full system into `/mnt`.

**Interfaces:**
- Consumes: staged `/mnt` (Task 4).
- Produces: a booted GoKit reachable as `ku0hn@192.168.10.100` with key auth (GSSH) for Tasks 6–7.

- [ ] **Step 1: Run the install** (long — overlay packages like qtsoundmodem/tncd/linbpq compile from source; run in background and poll)

RSSH (background, timeout generous): `nixos-install --no-root-passwd 2>&1 | tail -40`
Expected: ends with `installation finished!` (no root password prompt — `--no-root-passwd` because passwords.nix provides hashes). If it fails on evaluation, fix `/mnt/etc/nixos/configuration.nix` (and mirror the fix into the repo `nixos/configuration.nix` + commit) before retrying.

- [ ] **Step 2: Fix home-directory ownership** (files created by root during staging)

RSSH: `nixos-enter --root /mnt -- chown -R ku0hn:users /home/ku0hn`

- [ ] **Step 3: Reboot into the installed system**

RSSH: `reboot` (connection drop expected)
Then poll from Enzo until SSH answers (up to ~3 min):

```bash
until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ku0hn@192.168.10.100 'hostname' 2>/dev/null; do sleep 10; done
```

Expected: prints `GoKit`. If the address changed post-PXE, locate with `nmap -sn 192.168.10.0/24 | grep -B2 -i gokit` and use that IP for GSSH from here on. Note: the machine PXE-booted originally — if it boots back into PXE instead of the new NVMe install, the user must change boot order in firmware; report and wait.

- [ ] **Step 4: First-boot smoke check**

GSSH: `nixos-version; systemctl is-system-running; loginctl list-sessions --no-legend`
Expected: 26.05 version string; `running` or `degraded` (degraded acceptable at this stage — rigctld-TS50 flaps until the Digirig is attached); a GNOME session for ku0hn (autologin).

- [ ] **Step 5: Commit a build-log note**

```bash
cd /home/ku0hn/dev/ku0hn-gokit
git commit --allow-empty -m "GoKit installed and booted"
```

---

### Task 6: Copy user configurations and data from Enzo, patch for the new rigs

**Files:**
- Remote (GoKit home dir): pat, direwolf, QtSoundModem, QtTermTCP, paracon, GridTracker2, CHIRP, WSJT-X, Nextcloud, VARA prefix, pat mailbox.

**Interfaces:**
- Consumes: booted GoKit with key auth (Task 5).
- Produces: fully populated `/home/ku0hn` matching the spec's copy table.

- [ ] **Step 1: rsync configs and data from Enzo** (~1 GB total, dominated by the VARA prefix)

```bash
GK=ku0hn@192.168.10.100
rsync -a ~/.config/pat/ $GK:.config/pat/
rsync -a ~/direwolf-vhf.conf ~/direwolf-hf.conf ~/direwolf-6m.conf ~/direwolf-9600.conf ~/direwolf-test.conf $GK:
rsync -a ~/QtSoundModem.ini ~/QtTermTCP.ini ~/paracon.cfg $GK:
rsync -a ~/.chirp/ $GK:.chirp/
rsync -a ~/.config/WSJT-X.ini $GK:.config/WSJT-X.ini
rsync -a ~/.local/share/WSJT-X/ $GK:.local/share/WSJT-X/
rsync -a ~/.config/Nextcloud/nextcloud.cfg $GK:.config/Nextcloud/nextcloud.cfg
rsync -a ~/.local/share/pat/ $GK:.local/share/pat/
rsync -a ~/vara/ $GK:vara/
rsync -a ~/bin/GridTracker2-2.260705.2-x86_64.AppImage $GK:bin/
rsync -a --exclude=Cache --exclude='Code Cache' --exclude=GPUCache \
  --exclude=DawnGraphiteCache --exclude=DawnWebGPUCache --exclude=blob_storage \
  --exclude=Crashpad --exclude=logs ~/.config/GridTracker2/ $GK:.config/GridTracker2/
```

Expected: all complete without error.

- [ ] **Step 2: Patch pat configs for the TS-50 and local VARA**

GSSH heredoc:

```bash
ssh ku0hn@192.168.10.100 python3 - <<'EOF'
import json, glob
for f in glob.glob('/home/ku0hn/.config/pat/config*.json'):
    c = json.load(open(f))
    rigs = c.get('hamlib_rigs', {})
    if 'TS-2000' in rigs:
        rigs['TS-50'] = rigs.pop('TS-2000')
    def fix(d):
        if isinstance(d, dict):
            if d.get('rig') == 'TS-2000':
                d['rig'] = 'TS-50'
            if d.get('host') == '192.168.10.25':
                d['host'] = '127.0.0.1'
            for v in d.values():
                fix(v)
        elif isinstance(d, list):
            for v in d:
                fix(v)
    fix(c)
    json.dump(c, open(f, 'w'), indent=2)
    print(f, 'patched')
EOF
```

Expected: three `patched` lines.

- [ ] **Step 3: Verify the patch**

GSSH: `grep -c 'TS-2000' .config/pat/config*.json; grep -o '"TS-50"' .config/pat/config.json | head -1; grep -c '192.168.10.25' .config/pat/config*.json`
Expected: zero TS-2000 matches (grep -c prints 0 per file), `"TS-50"` present, zero 192.168.10.25 matches.

- [ ] **Step 4: Patch direwolf VHF config for CM108 PTT on the Digirig Lite**

GSSH: `sed -i 's|^PTT RIG 2 localhost:4532.*|PTT CM108 /dev/Digirig-Lite|' direwolf-vhf.conf && grep '^PTT' direwolf-vhf.conf`
Expected: `PTT CM108 /dev/Digirig-Lite`. (direwolf-hf.conf keeps `PTT RIG 2 localhost` — CAT PTT through rigctld-TS50. Other confs are legacy, copied unmodified.)

- [ ] **Step 5: Reboot the GoKit so all services re-read the patched configs**

GSSH: `systemctl reboot` — allowed without a password because ku0hn owns the active (autologin) local session, so polkit grants reboot to that user over SSH too. Then poll until back up:

```bash
until ssh -o ConnectTimeout=3 ku0hn@192.168.10.100 'hostname' 2>/dev/null; do sleep 10; done
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.10.100:8080
```

Expected: `GoKit`, then HTTP `200` from pat's web UI (which also proves firewall port 8080 is open). If polkit refuses the reboot, ask the user to run `sudo systemctl restart pat` on the GoKit instead.

- [ ] **Step 6: Commit a build-log note**

```bash
cd /home/ku0hn/dev/ku0hn-gokit
git commit --allow-empty -m "GoKit user configs copied from Enzo and patched for TS-50/TM-271"
```

---

### Task 7: Verify system state on the GoKit

**Files:**
- None (verification only).

**Interfaces:**
- Consumes: fully configured GoKit (Task 6).
- Produces: evidence for the completion report; any failure loops back to the relevant task.

- [ ] **Step 1: Service states**

GSSH: `systemctl --no-pager is-active pat tncd chronyd gpsd display-manager gnome-remote-desktop; echo ---; systemctl --no-pager status rigctld-TS50 | head -5`
Expected: pat/tncd/chronyd/display-manager `active`; gnome-remote-desktop `active`; gpsd `active` (or waiting on device); rigctld-TS50 in a restart loop (`activating`/`failed`) — expected with no Digirig attached, RestartSec=5 keeps it polite.

- [ ] **Step 2: Time sync**

GSSH: `chronyc sources`
Expected: NTP pool sources reachable (`^*` on one); `#? GPS` refclock listed but unreachable (no receiver yet).

- [ ] **Step 3: Firewall behavior from Enzo**

```bash
nmap -p 22,3389,8080,8000,9999 192.168.10.100
```

Expected: 22 open, 8080 open, 3389 open or closed-but-filtered depending on g-r-d session state (must NOT be `filtered`-by-default confusion: the key check is 9999 shows `filtered`, proving the firewall is on, while allowed ports are not filtered). 8000 shows filtered/closed until direwolf runs — it's in the allowlist, so `closed` (not `filtered`) is the expected state.

- [ ] **Step 4: udev rules present on the installed system**

GSSH: `grep -l 'Digirig' /etc/udev/rules.d/99-local.rules /etc/udev/rules.d/* 2>/dev/null | head -3; udevadm control --ping && echo udev-ok`
Expected: the extraRules file (NixOS names it `99-local.rules`) contains the Digirig block; udev responds.

- [ ] **Step 5: Overlay packages actually installed**

GSSH: `which direwolf qtsoundmodem qttermtcp paracon pat rigctld chirp wsjtx fldigi xastir linbpq 2>&1; ls ~/bin/GridTracker2-2.260705.2-x86_64.AppImage && ls -d ~/vara/drive_c`
Expected: every binary resolves to a /run/current-system or /etc/profiles path; AppImage and wine prefix present.

- [ ] **Step 6: Commit a build-log note**

```bash
cd /home/ku0hn/dev/ku0hn-gokit
git commit --allow-empty -m "GoKit system verification complete"
```

---

### Task 8: Write the commissioning checklist

**Files:**
- Create: `nixos/COMMISSIONING.md`

**Interfaces:**
- Consumes: everything above; the spec's post-hardware checklist section.
- Produces: the doc the user follows when the rigs/GPS are physically connected.

- [ ] **Step 1: Write `nixos/COMMISSIONING.md`**:

```markdown
# GoKit commissioning checklist (with hardware attached)

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
- Plug in the receiver; `ls -l /dev/gps0`. If missing, get IDs with
  `lsusb` and add the vendor/product to the GPS rules in
  `configuration.nix`, rebuild.
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
```

- [ ] **Step 2: Commit**

```bash
cd /home/ku0hn/dev/ku0hn-gokit
git add nixos/COMMISSIONING.md
git commit -m "Add GoKit commissioning checklist"
```

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

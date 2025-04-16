# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ 
      ./home-manager.nix
      ../packages/packages.nix
      ../desktop-environments/desktop-enviroments.nix
      inputs.sops-nix.nixosModules.sops
      ../secrets/sops.nix
      # ./wireguard.nix
    ];

  # Enviroment Variables
  environment.variables = {
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    NVD_BACKEND = "direct";
    MOZ_DISABLE_RDD_SANDBOX = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    MUTTER_DEBUG_KMS_THREAD_TYPE = "user";
    NODE_OPTIONS = "--max-old-space-size=4096";
    SGX_ENCLAVE_SIZE = "4G";
    RUST_MIN_STACK = "268435456";
    QT_QPA_PLATFORM = "wayland";
    NIXPKGS_ALLOW_UNFREE = "1"; # Duplication with nixpkgs.config.allowUnfree needed
    WEBKIT_DISABLE_DMABUF_RENDERER = "1"; # Tauri Apps couldnt run because of this on nixos nvidia
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Setup Path
  environment.variables.PATH = "${pkgs.lib.makeBinPath [ pkgs.coreutils ]}:$HOME/.bin";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.timeout = 1;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Allow broken packages
  nixpkgs.config.allowBroken = true;

  # NixOs garbage collection
  nix.gc = {
		automatic = true;
		dates = "weekly";
		options = "--delete-older-than 7d";
	};

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GDM Display Manager
  services.xserver.displayManager.gdm.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "nodeadkeys";
  };

  # Configure console keymap
  console.keyMap = "de-latin1-nodeadkeys";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable Smartcard Support
  hardware.gpgSmartcards.enable = true;
  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.yubikey-manager ];
  environment.etc."chromium/native-messaging-hosts/eu.webeid.json".source = "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";
  environment.etc."opt/chrome/native-messaging-hosts/eu.webeid.json".source = "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";
  # Tell p11-kit to load/proxy opensc-pkcs11.so, providing all available slots
  # (PIN1 for authentication/decryption, PIN2 for signing).
  environment.etc."pkcs11/modules/opensc-pkcs11".text = ''
    module: ${pkgs.opensc}/lib/opensc-pkcs11.so
  '';
  environment.systemPackages = with pkgs; [
    # Wrapper script to tell to Chrome/Chromium to use p11-kit-proxy to load
    # security devices, so they can be used for TLS client auth.
    # Each user needs to run this themselves, it does not work on a system level
    # due to a bug in Chromium:
    #
    # https://bugs.chromium.org/p/chromium/issues/detail?id=16387
    (pkgs.writeShellScriptBin "setup-browser-eid" ''
      NSSDB="''${HOME}/.pki/nssdb"
      mkdir -p ''${NSSDB}

      ${pkgs.nssTools}/bin/modutil -force -dbdir sql:$NSSDB -add p11-kit-proxy \
        -libfile ${pkgs.p11-kit}/lib/p11-kit-proxy.so
    '')
  ];

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tim = {
    isNormalUser = true;
    description = "Tim Lisemer";
    extraGroups = [ "networkmanager" "wheel" "dialout" "docker" ];
  };

  # Some programs need SUID wrappers, can be configured further or are started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Enable Switcheroo
  services.switcherooControl.enable = true;

  # Laptop Lid Switch on External Power
  services.logind.lidSwitchExternalPower = "ignore";

  # Enable Power Profile
  services.power-profiles-daemon.enable = true;

  # Comin
  #services.comin = {
  #  enable = true;
  #  remotes = [{
  #    name = "origin";
  #    url = "https://github.com/TimLisemer/NixOs.git";
  #    auth.access_token_path = config.sops.secrets.github_token.path;
  #    branches.main.name = "main";
  #  }];
  #};
  #systemd.services.comin = {
  #  serviceConfig = {
  #    User = "root";
  #  };
  #};
  
  # VsCode Server
  services.vscode-server.enable = true;

  # Fix Shebang
  services.envfs.enable = true;


  # Enable common container config files in /etc/containers
  services.spice-vdagentd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  virtualisation.containers.enable = true;
  virtualisation.containers.registries.search = [ "docker.io" ];
  virtualisation = {
    docker = {
      enable = true;

      rootless = {
        enable = true;
        setSocketVariable = true;
      };

      # daemon.settings.ipv6 = true;

      # Needed if using btrfs as storage driver which we do.
      storageDriver = "btrfs";
    };
  };
  # Unrestrict ports below 1000.
  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 0;
  };

  # Auto Updates
  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos";
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
    persistent = true;
    allowReboot = false;
  };

  # Syncthing
  services = {
    syncthing = {
      enable = true;
      user = "tim";
      dataDir = "/home/tim";
      configDir = "/home/tim/.config/syncthing";
      overrideDevices = true;                       # overrides any devices added or deleted through the WebUI
      overrideFolders = true;                       # overrides any folders added or deleted through the WebUI
      settings = {
        devices = {
          "tim-server" = { 
            id = "ZKX6K7U-XPIMO7N-QM7KBU7-5OPVX7S-3E4UDW7-YKQBR2P-ZU4DC3F-ZYC34A3";
            autoAcceptFolders = true;
          };
          # "device2" = { id = "DEVICE-ID-GOES-HERE"; };
        };
        folders = {
          "Home" = {                                # Folder ID in Syncthing, also the name of folder (label) by default
            path = "/home/tim";                     # Which folder to add to Syncthing
            devices = [ "Tim-Server" ];             # Which devices to share the folder with
          };
        };
      };
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}

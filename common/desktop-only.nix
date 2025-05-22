# Stuff that only makes sense on bare-metal / desktop NixOS, not inside WSL
{
  config,
  pkgs,
  ...
}: {
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.timeout = 1;

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable the X11 windowing system
  services.xserver.enable = true;

  # Enable the GDM Display Manager
  services.xserver.displayManager.gdm.enable = true;

  # Enable Smartcard Support
  hardware.gpgSmartcards.enable = true;
  services.pcscd.enable = true;
  services.udev.packages = [pkgs.yubikey-manager];
  environment.etc."chromium/native-messaging-hosts/eu.webeid.json".source = "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";
  environment.etc."opt/chrome/native-messaging-hosts/eu.webeid.json".source = "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";
  # Tell p11-kit to load/proxy opensc-pkcs11.so, providing all slots
  # (PIN1 for auth/decrypt, PIN2 for signing).
  environment.etc."pkcs11/modules/opensc-pkcs11".text = ''
    module: ${pkgs.opensc}/lib/opensc-pkcs11.so
  '';
  environment.systemPackages = with pkgs; [
    # Wrapper for Chrome/Chromium to use p11-kit-proxy for PKCS#11
    (writeShellScriptBin "setup-browser-eid" ''
      NSSDB="''${HOME}/.pki/nssdb"
      mkdir -p ''${NSSDB}
      ${pkgs.nssTools}/bin/modutil -force -dbdir sql:$NSSDB \
        -add p11-kit-proxy \
        -libfile ${pkgs.p11-kit}/lib/p11-kit-proxy.so
    '')
  ];

  # Enable sound with PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true  # If you want JACK apps

    # media-session.enable = true  # default session manager
  };

  # Enable touchpad support (libinput default)
  # services.xserver.libinput.enable = true;

  # Enable Switcheroo
  services.switcherooControl.enable = true;

  # Laptop lid switch on external power
  services.logind.lidSwitchExternalPower = "ignore";

  # Enable Power Profiles
  services.power-profiles-daemon.enable = true;

  # Comin (commented out)
  # services.comin = { … };
  # systemd.services.comin = { … };

  # Enable common container config files
  services.spice-vdagentd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  virtualisation.containers.enable = true;
  virtualisation.containers.registries.search = ["docker.io"];
  virtualisation.docker = {
    enable = true;
    rootless.enable = true;
    rootless.setSocketVariable = true;
    # daemon.settings.ipv6 = true
    storageDriver = "btrfs";
  };

  # Unrestrict ports below 1000
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

  # Auto-updates
  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos";
    flags = ["--update-input" "nixpkgs" "-L"]; # print build logs
    dates = "02:00";
    randomizedDelaySec = "45min";
    persistent = true;
    allowReboot = false;
  };
}

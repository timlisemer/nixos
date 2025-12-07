{
  disks,
  config,
  pkgs,
  lib,
  ...
}: {
  # Import the common configuration shared across all machines
  imports = [
    (import ../common/disko.nix {inherit disks;})
    ./desktop-only-imports.nix
    ./tim-pc-hardware-configuration.nix
    ../common/nvidia.nix
  ];

  # Machine specific configurations

  # Enable Wake on LAN for ethernet interface
  systemd.services.wol-enable = {
    description = "Enable Wake on LAN for enp14s0";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp14s0 wol g";
    };
  };

  boot = {
    kernelParams = ["acpi_enforce_resources=lax"];
    kernelModules = ["i2c-dev" "i2c-piix4"];
  };

  hardware = {
    i2c = {
      enable = true;
    };
    bluetooth.settings = {
      General = {
        # The string that remote devices will see
        Name = "Tim-PC";
        DisablePlugins = "hostname";
      };
    };
  };
  # services.udev.extraRules = builtins.readFile ../files/OpenRGB/60-openrgb.rules;

  # Firewall configuration for Matter development
  networking.firewall = lib.mkForce {
    enable = true;

    # TCP ports to open
    allowedTCPPorts = [
      22 # SSH
      5540 # Matter commissioning port
    ];

    # UDP ports to open
    allowedUDPPorts = [
      5353 # Multicast DNS (mDNS)
      5540 # Matter commissioning port
    ];

    allowPing = true;
  };

  # environment.systemPackages = with pkgs; [openrgb-with-all-plugins];
  # services.hardware.openrgb.enable = true;
  # systemd.user.services.openrgb = {
  #   description = "OpenRGB";
  #   wantedBy = ["default.target" "graphical-session.target"];
  #   partOf = ["graphical-session.target"];
  #   serviceConfig = {
  #     # ExecStart = "${pkgs.openrgb-with-all-plugins}/bin/openrgb --startminimized --profile 'On'";
  #     # ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
  #     ExecStart = "/bin/openrgb --startminimized --profile 'On'";
  #     Restart = "on-failure";
  #     RestartSec = "5s";
  #     StartLimitIntervalSec = "10s";
  #     StartLimitBurst = "10";
  #     After = ["graphical-session.target" "network-online.target"];
  #   };
  # };
}

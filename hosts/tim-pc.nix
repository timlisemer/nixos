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
    ../common/amdgpu.nix
    ../services/windows-vm
  ];

  # Windows VM with GPU passthrough (appears as GDM session)
  # Resources are auto-detected at runtime: RAM - 2GB, CPU threads - 2
  services.windows-vm = {
    enable = true;
    vmName = "windows-vm";
    username = "tim";
    passwordFile = /run/secrets/windows_vm_password;
    noHybridGraphics = true; # Desktop PC - GPU always powered

    # Storage: dedicated NVMe drive
    storage = {
      type = "raw";
      device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_2TB_S4J4NZ0R302042B";
    };

    # PCI passthrough devices (isolated IOMMU groups)
    passthrough = {
      gpu = ["03:00.0" "03:00.1"]; # GPU + GPU audio (groups 15, 16)
      usb = ["7b:00.3" "7b:00.4"]; # USB controllers (groups 34, 35)
      audio = ["7b:00.6"]; # Onboard audio (group 36)
    };

    # Hardware types
    cpuType = "amd";
    gpuType = "amd";
  };

  # Machine specific configurations

  # Enable Wake on LAN for ethernet interface
  systemd.services.wol-enable = {
    description = "Enable Wake on LAN for enp16s0";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp16s0 wol g";
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

  # Enable Avahi for Matter/chip-tool (overrides desktop-only.nix mkForce false)
  services.avahi.enable = lib.mkOverride 49 true;

  # chip-tool via Docker wrapper (Matter/CHIP commissioning tool)
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "chip-tool" ''
      IMAGE="ghcr.io/matter-js/chip:latest"
      if ! ${pkgs.docker}/bin/docker image inspect "$IMAGE" &>/dev/null; then
        echo "chip-tool: Docker image not found, pulling $IMAGE..." >&2
        ${pkgs.docker}/bin/docker pull "$IMAGE"
        echo "chip-tool: Image pulled successfully" >&2
      fi
      echo "chip-tool: Starting Matter controller via Docker..." >&2
      exec ${pkgs.docker}/bin/docker run --rm -it \
        --network=host \
        --ipc=host \
        -v /tmp:/tmp \
        -v /run/dbus:/run/dbus:ro \
        -v "$HOME/.chip-tool:/root/.chip-tool" \
        "$IMAGE" \
        chip-tool "$@"
    '')
  ];

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

{
  config,
  pkgs,
  lib,
  hostName,
  ...
}: let
  # Only enable on homeassistant-yellow
  isEnabled = hostName == "homeassistant-yellow";

  # Python environment with all required packages
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      fastapi
      uvicorn
      webauthn
      pydantic
      cryptography
      aiofiles
    ]);

  # Valid hostnames for installation (only disko-compatible hosts)
  # Excluded: homeassistant-yellow (hosts the service), rpi5/tim-pi4 (SD card), tim-wsl (no disk install)
  validHostnames = ["tim-laptop" "tim-pc" "tim-server" "greeter"];
  validHostnamesStr = builtins.concatStringsSep "," validHostnames;

  # The FastAPI application for passkey authentication (external file to avoid Alejandra formatting issues)
  installerApp = pkgs.writeText "passkey_installer.py" (builtins.readFile ../files/install/passkey-installer.py);
in {
  config = lib.mkIf isEnabled {
    # SSH key secret for distribution
    sops.secrets.installer_ssh_key = {
      sopsFile = ../secrets/secrets.yaml;
      mode = "0400";
    };

    # Python passkey service (HTTP on port 8900 - Traefik handles HTTPS termination)
    systemd.services.passkey-installer = {
      description = "Passkey-protected NixOS installer service";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        RP_ID = "nixos.local.yakweide.de";
        RP_NAME = "NixOS Installer";
        RP_ORIGIN = "https://nixos.local.yakweide.de";
        SSH_KEY_PATH = "/run/secrets/installer_ssh_key";
        DATA_DIR = "/var/lib/passkey-installer";
        VALID_HOSTNAMES = validHostnamesStr;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pythonEnv}/bin/uvicorn passkey_installer:app --host 0.0.0.0 --port 8900";
        WorkingDirectory = "/var/lib/passkey-installer";
        StateDirectory = "passkey-installer";
        Restart = "always";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
      };
    };

    # Symlink Python app to service directory (L+ replaces on every rebuild)
    systemd.tmpfiles.rules = [
      "L+ /var/lib/passkey-installer/passkey_installer.py - - - - ${installerApp}"
    ];

    # Firewall rules - only HTTP port needed (Traefik handles HTTPS)
    networking.firewall.allowedTCPPorts = [
      8900 # HTTP for Traefik to reach
    ];

    environment.systemPackages = [pythonEnv];
  };
}

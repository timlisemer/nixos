{
  config,
  pkgs,
  system,
  inputs,
  lib,
  ...
}: let
  unstable = import inputs.nixpkgs-unstable {
    config = {allowUnfree = true;};
    inherit system;
  };
in {
  # Home Assistant native NixOS service configuration
  # Step 1: Imperative configuration using existing Docker volume
  # Step 2 (future): Migrate to declarative configuration

  services.home-assistant = {
    enable = true;

    # Use unstable package for latest features
    package = unstable.home-assistant;

    # Imperative configuration mode - uses existing config directory
    config = null;
    lovelaceConfig = null;

    # Point to existing Docker volume configuration
    configDir = "/mnt/docker-data/volumes/homeassistant/config";

    # Only include components we KNOW are needed
    extraComponents = [
      # From your configuration.yaml
      "default_config"
      "mqtt"
      "wake_on_lan"
      "alexa"
      "google_translate"

      # Essential components
      "met"
      "radio_browser"
      "esphome"

      # Hardware support
      "bluetooth"
      "bluetooth_adapters"
      "homeassistant_yellow"

      # Matter/Thread support
      "matter"
      "thread"
    ];

    # Additional Python packages that might be needed
    extraPackages = ps:
      with ps; [
        # Database support
        psycopg2

        # Common dependencies
        aiohttp
        jinja2
        voluptuous
        pyyaml
        pytz
        python-dateutil
        requests
        pillow

        # Bluetooth support
        bleak
        bleak-retry-connector
        bluetooth-adapters
        bluetooth-auto-recovery
        dbus-fast

        # Network discovery
        netdisco
        zeroconf

        # MQTT support
        paho-mqtt

        # Cryptography
        cryptography

        # Serial communication (for Zigbee/Z-Wave)
        pyserial
        pyserial-asyncio
      ];

    # Extra arguments for the Home Assistant service
    extraArgs = [
      "--log-file"
      "/mnt/docker-data/volumes/homeassistant/config/home-assistant.log"
    ];
  };

  # Ensure the systemd service has proper capabilities and permissions
  systemd.services.home-assistant = {
    serviceConfig = {
      # Network capabilities for discovery and binding
      AmbientCapabilities = ["CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_NET_BIND_SERVICE"];
      CapabilityBoundingSet = ["CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_NET_BIND_SERVICE"];

      # Allow all device access (dedicated Home Assistant Yellow hardware)
      DevicePolicy = lib.mkForce "auto";

      # Allow binding to any address (needed for 0.0.0.0:8123)
      RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" "AF_BLUETOOTH"];

      # Additional paths that might be needed
      ReadWritePaths = [
        "/mnt/docker-data/volumes/homeassistant/config"
        "/mnt/docker-data/volumes/homeassistant/media"
      ];

      # System call filter adjustments for broader compatibility
      SystemCallFilter = ["@system-service" "~@privileged"];
    };

    # Ensure the service starts after network is online
    after = ["network-online.target" "multi-user.target"];
    wants = ["network-online.target"];

    # Environment variables
    environment = {
      TZ = "Europe/Berlin";
      HOME = "/mnt/docker-data/volumes/homeassistant/config";
    };

    # Additional tools that Home Assistant might need
    path = with pkgs; [
      git
      ffmpeg
      nmap
      socat
    ];
  };
}

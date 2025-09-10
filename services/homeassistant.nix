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

    # Point to Home Assistant configuration directory
    configDir = "/var/lib/homeassistant";

    extraComponents = [
      # From the old configuration.yaml
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
      "otbr"

      # Zigbee support
      "zha"
    ];
  };
}

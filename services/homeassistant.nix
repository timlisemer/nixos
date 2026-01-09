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
  stable = import inputs.nixpkgs-stable {
    config = {allowUnfree = true;};
    inherit system;
  };

  better-thermostat-ui-card = pkgs.fetchurl {
    url = "https://github.com/KartoffelToby/better-thermostat-ui-card/releases/download/2.2.1/better-thermostat-ui-card.js";
    sha256 = "sha256-tmE5EzioQQ21bAeMLuvYh/Pnh4Bi0iW254EVeT3fNO4=";
  };

  heizung-dashboard = pkgs.writeText "heizung.yaml" (builtins.readFile ../files/homeassistant/heizung.yaml);

  scripts-yaml = pkgs.writeText "scripts.yaml" (builtins.readFile ../files/homeassistant/scripts.yaml);

  helper-yaml = pkgs.writeText "helper.yaml" (builtins.readFile ../files/homeassistant/helper.yaml);

  climate-control-yaml = pkgs.writeText "climate_control.yaml" (builtins.readFile ../files/homeassistant/automations/climate_control.yaml);

  unavailable-entities-yaml = pkgs.writeText "unavailable_entities.yaml" (builtins.readFile ../files/homeassistant/automations/unavailable_entities.yaml);

  # Create a custom ui-lovelace.yaml that will serve as the default "Overview" dashboard
  # We can make this a redirect to our other dashboards or a simple landing page
  ui-lovelace = pkgs.writeText "ui-lovelace.yaml" (builtins.readFile ../files/homeassistant/overview.yaml);
in {
  # Zigbee2MQTT service
  services.zigbee2mqtt = {
    enable = true;
    settings = {
      permit_join = false;
      frontend = {
        port = 8080;
      };
      mqtt = {
        server = "mqtt://localhost:1883";
      };
      serial = {
        port = "/dev/ttyAMA1";
        adapter = "ember";
      };
      advanced = {
        log_level = "info";
        network_key = "!secret.yaml network_key";
      };
    };
  };

  services.home-assistant = {
    enable = true;

    # Use unstable package for latest features
    package = stable.home-assistant;

    # Extra Python packages for performance optimizations
    # Resolves: aiohttp_fast_zlib warning about zlib_ng and isal not being available
    extraPackages = python3Packages:
      with python3Packages; [
        zlib-ng # Fast zlib replacement using zlib-ng
        isal # Intel ISA-L bindings for fast compression
      ];

    # Declarative configuration mode - managed by NixOS
    config = {
      # Loads default set of integrations. Do not remove.
      default_config = {};

      # My custom section
      my = {};

      # Networking configuration
      homeassistant = {
        external_url = "https://homeassistant.yakweide.de";
        internal_url = "http://10.0.0.2:8123";
        media_dirs = {
          media = "/var/lib/homeassistant/media";
        };
        auth_providers = [
          {
            type = "homeassistant";
          }
          {
            type = "trusted_networks";
            trusted_networks = [
              # Home Network Range
              "10.0.0.0/8"
              # Docker Network Range
              "172.18.0.0/16"
            ];
          }
        ];
        # Include helper.yaml which contains sensor groups and template binary sensors
        packages = {
          helpers = "!include helper.yaml";
        };
      };

      # HTTP configuration for external access and reverse proxy support
      http = {
        server_port = 8123;
        server_host = "0.0.0.0";
        cors_allowed_origins = [
          "https://google.com"
          "https://www.home-assistant.io"
        ];
        login_attempts_threshold = 5;
        # Allow Reverse Proxies
        use_x_forwarded_for = true;
        trusted_proxies = [
          "172.18.0.2"
          "127.0.0.1"
          # Cloudflare IPv4 ranges
          "103.21.244.0/22"
          "103.22.200.0/22"
          "103.31.4.0/22"
          "104.16.0.0/13"
          "104.24.0.0/14"
          "108.162.192.0/18"
          "131.0.72.0/22"
          "141.101.64.0/18"
          "162.158.0.0/15"
          "172.64.0.0/13"
          "173.245.48.0/20"
          "188.114.96.0/20"
          "190.93.240.0/20"
          "197.234.240.0/22"
          "198.41.128.0/17"
          # Cloudflare IPv6 ranges
          "2400:cb00::/32"
          "2606:4700::/32"
          "2803:f800::/32"
          "2405:b500::/32"
          "2405:8100::/32"
          "2a06:98c0::/29"
          "2c0f:f248::/32"
        ];
        # Disable IP bans - pfSense will handle this
        ip_ban_enabled = false;
      };

      # Text to speech
      tts = [
        {
          platform = "google_translate";
        }
      ];

      # MQTT configuration
      mqtt = {
        # Doorbell Chime Status Binary Sensor
        binary_sensor = [
          {
            unique_id = "doorbell_chime_status";
            name = "Doorbell Chime Status";
            state_topic = "home/doorbell/button";
            qos = 0;
            value_template = "{{ 'ON' if value == 'ON' else 'OFF' }}";
          }
        ];
      };

      # Alexa integration
      # Credentials loaded from SOPS secrets via environment variables
      alexa = {
        smart_home = {
          locale = "en-US";
          endpoint = "https://api.eu.amazonalexa.com/v3/events";
          client_id = "${config.sops.placeholder.amazon_client_id}";
          client_secret = "${config.sops.placeholder.amazon_client_secret}";
          filter = {
            include_entities = [
              "switch.monitor"
              "switch.pool_pumpe_steckdose"
              "switch.tim_pc_steckdose"
              "switch.tim_server_steckdose"
              "binary_sensor.doorbell_besucher"
              "camera.doorbell_fliessend"
              "binary_sensor.doorbell_chime_status"
              "switch.audio_receiver"
              "switch.subwoofer"
              "script.boxen"
            ];
            include_entity_globs = [
              "climate.*"
            ];
          };
          entity_config = {
            "binary_sensor.doorbell_besucher" = {
              name = "Haustür";
              description = "Doorbell Press";
              display_categories = "DOORBELL";
            };
            "camera.doorbell_fliessend" = {
              name = "Haustür Kamera";
              description = "Doorbell Camera";
              display_categories = "CAMERA";
            };
            "binary_sensor.doorbell_chime_status" = {
              name = "Hoftor";
              description = "Hoftor Doorbell Press";
              display_categories = "DOORBELL";
            };
          };
        };
      };

      # Load frontend themes from the themes folder
      frontend = {
        themes = "!include_dir_merge_named themes";
      };

      # Lovelace configuration
      lovelace = {
        mode = "yaml";
        resources = [
          {
            url = "/local/better-thermostat-ui-card.js";
            type = "module";
          }
        ];
        dashboards = {
          camera-dashboard = {
            mode = "yaml";
            filename = "/var/lib/homeassistant/dashboards/camera.yaml";
            title = "Kameras";
            icon = "mdi:camera";
            show_in_sidebar = true;
          };
          heizung-dashboard = {
            mode = "yaml";
            filename = "/var/lib/homeassistant/dashboards/heizung.yaml";
            title = "Heizung";
            icon = "mdi:heat-wave";
            show_in_sidebar = true;
          };
        };
      };

      # External file includes
      automation = "!include_dir_merge_list automations";
      scene = "!include scenes.yaml";
      script = "!include scripts.yaml";
      zone = "!include zones.yaml";
    };

    # Lovelace configuration will be added later
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

      # Climate control integrations
      "tado"
      "vicare"

      # Pi-hole integration
      "pi_hole"

      # Camera/Doorbell integrations
      "reolink"

      # Media device integrations (discovered via network)
      "cast" # Google Cast / Chromecast
      "androidtv_remote" # Android TV Remote
      "samsungtv" # Samsung TV
      "homekit_controller" # HomeKit device control
    ];

    customComponents = [
      pkgs.home-assistant-custom-components.better_thermostat
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/homeassistant/www 0755 hass hass"
    "L+ /var/lib/homeassistant/www/better-thermostat-ui-card.js - - - - ${better-thermostat-ui-card}"
    "d /var/lib/homeassistant/dashboards 0755 hass hass"
    "L+ /var/lib/homeassistant/dashboards/heizung.yaml - - - - ${heizung-dashboard}"
    "L+ /var/lib/homeassistant/ui-lovelace.yaml - - - - ${ui-lovelace}"
    "L+ /var/lib/homeassistant/scripts.yaml - - - - ${scripts-yaml}"
    "L+ /var/lib/homeassistant/helper.yaml - - - - ${helper-yaml}"
    "d /var/lib/homeassistant/automations 0755 hass hass"
    "L+ /var/lib/homeassistant/automations/climate_control.yaml - - - - ${climate-control-yaml}"
    "L+ /var/lib/homeassistant/automations/unavailable_entities.yaml - - - - ${unavailable-entities-yaml}"
    # audio_receiver_control.yaml is created by sops.templates below
  ];

  # SOPS template for automation files with secrets
  # Reads the YAML file and substitutes @placeholder@ with actual secrets at runtime
  sops.templates."audio_receiver_control.yaml" = {
    owner = "hass";
    group = "hass";
    mode = "0644";
    path = "/var/lib/homeassistant/automations/audio_receiver_control.yaml";
    content =
      builtins.replaceStrings
      ["@webhook_id_audio_receiver@"]
      [config.sops.placeholder.webhook_id_audio_receiver]
      (builtins.readFile ../files/homeassistant/automations/audio_receiver_control.yaml);
  };
}

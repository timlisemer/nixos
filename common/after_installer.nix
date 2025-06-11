{
  config,
  pkgs,
  ...
}: let
in {
  # Open ports in the firewall
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable entirely:
  networking = {
    firewall.enable = false;
    wireless.userControlled.enable = true;
    wireless.enable = true;
    wireless.secretsFile = config.sops.secrets."wifiENV".path;
    wireless.networks = {
      # SSID
      BND_Observations_VAN_3 = {
        pskRaw = "ext:home_psk";
        priority = 10;
      };
      Noel = {
        pskRaw = "ext:home2_psk";
        priority = 10;
      };
    };
    networkmanager = {
      enable = true;
      # Tell it to ignore every Wi-Fi interface so it touches only Ethernet
      unmanaged = ["type:wifi"]; # or "interface-name:name" for a single card
    };
  };
}

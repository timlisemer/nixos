{
  config,
  pkgs,
  ...
}: {
  networking.wireguard.enable = true;
  networking.wireguard.interfaces = let
    server_ip = "odalb8joqto3nnev.myfritz.net";
    wireguardKey = config.sops.secrets.wireguard_key.path; # Ensure this path is correct
    presharedKey = config.sops.secrets.wireguard_preshared_key.path;
  in {
    FritzBox = {
      # IP address of this machine in the *tunnel network*
      ips = [
        "10.2.0.1/8"
      ];

      # To match firewall allowedUDPPorts (without this wg
      # uses random port numbers).
      listenPort = 57189;

      # Path to the private key file.
      privateKeyFile = wireguardKey;

      peers = [
        {
          publicKey = "KurEHrUhn1j117Abf4ESMMqAwm5YO1QiGe/jeY+OcTs=";
          presharedKeyFile = presharedKey;
          allowedIPs = [
            "10.0.0.0/8"
            "192.168.178.0/24"
            "0.0.0.0/0"
          ];
          endpoint = "${server_ip}:57189";
          persistentKeepalive = 25;
        }
      ];

      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.2/8 -o eth0 -j MASQUERADE
      '';

      # This undoes the above command
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.2/8 -o eth0 -j MASQUERADE
      '';
    };
  };
}

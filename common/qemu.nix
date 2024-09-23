{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    qemu
    quickemu
    (writeShellScriptBin "qemu-system-x86_64-uefi" ''
        qemu-system-x86_64 \
        -bios ${OVMF.fd}/FV/OVMF.fd \
        "$@"
    '')
  ];

  # Systemd service to download Windows 11 files if they don't exist
  # systemd.user.services.downloadWindows11 = {
  #   Unit = {
  #     Description = "Download Windows 11 for QEMU";
  #     After = [ "network-online.target" ];
  #     Wants = [ "network-online.target" ];
  #   };
  #   Service = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.writeShellScript "download-windows11" ''
  #       if [ ! -d /home/tim/.config/qemu/setup/ ]; then
  #         ${pkgs.coreutils}/bin/mkdir -p /home/tim/.config/qemu/setup/
  #         cd /home/tim/.config/qemu/setup
  #         PATH=${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.gnused}/bin:${pkgs.findutils}/bin:${pkgs.util-linux}/bin:${pkgs.gnutar}/bin:${pkgs.which}/bin \
  #         ${pkgs.quickemu}/bin/quickget windows 11
  #       fi
  #     ''}";
  #   };
  #   Install = {
  #     WantedBy = [ "default.target" ];
  #   };
  # };

  # Create a .desktop entry for the Windows 11 VM
  home.file.".local/share/applications/windows11-qemu.desktop".text = ''
    [Desktop Entry]
    Name=Windows 11
    Comment=Launch Windows 11 in QEMU
    Exec=bash -c 'VM_FILES="$HOME/.config/qemu/files"; VM_CONFIGS="$HOME/.config/qemu/configs"; ISO_PATH="$VM_FILES/Win11_23H2_EnglishInternational_x64v2.iso"; DISK_PATH="$VM_FILES/disk.qcow2"; VIRTIO_PATH="$VM_FILES/virtio-win.iso"; [ ! -d "$VM_FILES" ] && mkdir -p "$VM_FILES" && cd "$VM_FILES" && quickget windows 11; quickemu --vm "$VM_CONFIGS/windows-11.conf"; sleep 2; remote-viewer spice://localhost:5930'
    Icon=/home/tim/.local/share/icons/windows11-48.png
    Terminal=false
    Type=Application
    Categories=System;Virtualization;
    StartupWMClass=remote-viewer
'';



  # Ensure the Windows 11 icon is placed in the correct location
  home.file.".local/share/icons/windows11-480.png".source = builtins.toPath ../files/icons/windows11-480.png;
  home.file.".local/share/icons/windows11-48.png".source = builtins.toPath ../files/icons/windows11-48.png;

}

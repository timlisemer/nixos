{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    qemu
    quickemu
    (writeShellScriptBin "qemu-system-x86_64-uefi" ''
      qemu-system-x86_64 \
      -bios ${OVMF.fd}/FV/OVMF.fd \
      "$@"
    '')
  ];

  # Create a .desktop entry for the Windows 11 VM -- https://www.spice-space.org/download.html
  home.file.".local/share/applications/windows11-qemu.desktop".text = ''
    [Desktop Entry]
    Name=Windows 11
    Comment=Launch Windows 11 in QEMU

    Exec=bash -c 'VM_FILES="$HOME/.config/qemu/windows-11"; [ ! -d "$VM_FILES" ] || [ -z "$(ls -A "$VM_FILES")" ] && mkdir -p "$VM_FILES" && cd "$VM_FILES" && quickget windows 11; quickemu --vm "$VM_FILES/windows-11.conf" --display spice --viewer remote-viewer --width 800 --height 800 --extra_args "-drive media=cdrom,index=3,file=windows-11/virtio-win.iso"'
    # If this faulils try without --display spice
    # Exec=bash -c 'VM_FILES="$HOME/.config/qemu/windows-11"; [ ! -d "$VM_FILES" ] || [ -z "$(ls -A "$VM_FILES")" ] && mkdir -p "$VM_FILES" && cd "$VM_FILES" && quickget windows 11; quickemu --vm "$VM_FILES/windows-11.conf" --viewer remote-viewer --width 800 --height 800 --extra_args "-drive media=cdrom,index=3,file=windows-11/virtio-win.iso"'

    Icon=$HOME/.local/share/icons/windows11-48.png
    Terminal=false
    Type=Application
    Categories=System;Virtualization;
    StartupWMClass=remote-viewer
  '';

  # Ensure the Windows 11 icon is placed in the correct location
  home.file = {
    ".local/share/icons/windows11-48.png" = {
      source = builtins.toPath ../files/icons/windows11-48.png;
      force = true;
    };
  };
}

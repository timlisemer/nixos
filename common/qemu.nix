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

  # Create a .desktop entry for the Windows 11 VM -- https://www.spice-space.org/download.html
  home.file.".local/share/applications/windows11-qemu.desktop".text = ''
    [Desktop Entry]
    Name=Windows 11
    Comment=Launch Windows 11 in QEMU
    Exec=bash -c 'VM_FILES="$HOME/.config/qemu/windows-11"; [ ! -d "$VM_FILES" ] || [ -z "$(ls -A "$VM_FILES")" ] && mkdir -p "$VM_FILES" && cd "$VM_FILES" && quickget windows 11; quickemu --vm "$VM_FILES/windows-11.conf" --display none; sleep 2; remote-viewer spice://localhost:5930'
    Icon=/home/tim/.local/share/icons/windows11-48.png
    Terminal=false
    Type=Application
    Categories=System;Virtualization;
    StartupWMClass=remote-viewer
  '';

  # Create a .desktop entry for the Windows 10 VM -- https://www.spice-space.org/download.html
  home.file.".local/share/applications/windows10-qemu.desktop".text = ''
    [Desktop Entry]
    Name=Windows 10
    Comment=Launch Windows 10 in QEMU
    Exec=bash -c 'VM_FILES="$HOME/.config/qemu/windows-10"; [ ! -d "$VM_FILES" ] || [ -z "$(ls -A "$VM_FILES")" ] && mkdir -p "$VM_FILES" && cd "$VM_FILES" && quickget windows 10; quickemu --vm "$VM_FILES/windows-10.conf" --display none; sleep 2; remote-viewer spice://localhost:5930'
    Icon=/home/tim/.local/share/icons/windows10-48.png
    Terminal=false
    Type=Application
    Categories=System;Virtualization;
    StartupWMClass=remote-viewer
  '';

  # Ensure the Windows 11 icon is placed in the correct location
  home.file.".local/share/icons/windows11-48.png".source = builtins.toPath ../files/icons/windows11-48.png;
  home.file.".local/share/icons/windows10-48.png".source = builtins.toPath ../files/icons/windows10-48.png;

}

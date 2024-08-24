{ config, pkgs, ... }:

let
  vscodeExtensions = pkgs.vscode-extensions;
in
{
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscodeExtensions = with vscodeExtensions; [
        ms-python.python
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
      ];
    })

    qtcreator
    jetbrains.clion
    jetbrains.rust-rover
    jetbrains.rider
    jetbrains.idea-community
    jetbrains.pycharm-community
  ];
}

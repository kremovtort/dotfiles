{ pkgs, ... }:
{
  imports = [ ./paneru.nix ];

  system.primaryUser = "kremovtort";

  environment.systemPackages = [ ];

  homebrew = import ./homebrew.nix;

  # Necessary for using flakes on this system.
  nix.enable = false;
  nix.settings.experimental-features = "nix-command flakes";
  # nix-rosetta-builder.onDemand = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;

  security.pam.services.sudo_local.enable = true;
  security.pam.services.sudo_local.reattach = true;
  security.pam.services.sudo_local.touchIdAuth = true;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.kremovtort = {
    name = "kremovtort";
    home = "/Users/kremovtort";
    shell = pkgs.zsh;
  };
}

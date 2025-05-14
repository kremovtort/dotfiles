{ pkgs, ... }: {
  environment.systemPackages = [ ];

  homebrew = import ./homebrew.nix;
  
  # Necessary for using flakes on this system.
  nix.enable = false;
  nix.settings.experimental-features = "nix-command flakes";
  # nix-rosetta-builder.onDemand = true;
  
  services.jankyborders = {
    enable = true;
    width = 6.0;
    hidpi = true;
    blur_radius = 10.0;
    active_color = "0x70FFFFFF";
    inactive_color = "0x00FFFFFF";
  };

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
  };
}

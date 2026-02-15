{...}: {
  nix.settings.experimental-features = "nix-command flakes";
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 3 * 1024;
    }
  ];
}

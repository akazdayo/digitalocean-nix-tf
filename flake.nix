{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      utils,
      ...
    }:
    let
      lib = nixpkgs.lib;

      # DigitalOcean 用 NixOS 設定（ホスト名 "do"）
      nixosConfigurations = {
        do = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # system.build.digitalOceanImage を生やす
            "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"

            (
              {
                pkgs,
                lib,
                ...
              }:
              {
                # DO 側がメタデータから hostname を設定するので空でもOK
                networking.hostName = "";

                # イメージサイズ
                virtualisation.diskSize = lib.mkDefault 8192;

                # qcow2 圧縮（gzip / bzip2 / none）
                virtualisation.digitalOceanImage.compressionMethod = "gzip";

                # SSH
                services.openssh.enable = true;
                services.openssh.openFirewall = true;
                services.openssh.settings = {
                  PasswordAuthentication = false;
                  PermitRootLogin = "prohibit-password";
                };

                environment.systemPackages = with pkgs; [
                  git
                  curl
                ];
                nix.settings.experimental-features = [
                  "nix-command"
                  "flakes"
                ];

                system.stateVersion = "26.05";
              }
            )
          ];
        };
      };
    in
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # いまの形を残すならこれ
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
          ];
        };

        # x86_64-linux のときだけ DO イメージを packages に出す
        packages = lib.optionalAttrs (system == "x86_64-linux") {
          digitalocean-image = nixosConfigurations.do.config.system.build.digitalOceanImage;
        };
      }
    )
    // {
      inherit nixosConfigurations;
    };
}

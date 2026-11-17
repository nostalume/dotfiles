{
  description = "Nostalgia Packages Management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    shed-src = {
      url = "github:nostalume/shed";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, shed-src }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          shed = pkgs.callPackage "${shed-src}/nix/shed.nix" {};
        in {
          default = pkgs.buildEnv {
            name = "nostalgia-packages";
            paths = with pkgs; [
              git
              starship
              neovim
              aria2
              ripgrep
              bat
              fzf
              fd
              just
              eget
              rage
              shed
              rustic
              maple-mono.truetype
              maple-mono.NF-unhinted
              maple-mono.NF-CN-unhinted
            ];
          };
        });
    };
}

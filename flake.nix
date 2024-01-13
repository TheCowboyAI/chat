{
  description = "nginx leptos landing page";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";

  };
  
  outputs = inputs@{ self, nixpkgs, rust-overlay, ... }:
    let
      flakeContext = {
        inherit inputs;
      };
      overlays = [
        rust-overlay.overlays.default
        (final: prev: {
          rustToolchain =
            let
              rust = prev.rust-bin;
            in
            if builtins.pathExists ./rust-toolchain.toml then
              rust.fromRustupToolchainFile ./rust-toolchain.toml
            else if builtins.pathExists ./rust-toolchain then
              rust.fromRustupToolchainFile ./rust-toolchain
            else
              rust.nightlys.latest.default;
        })
      ];
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit overlays system; };
      });
    in
    {
      nixosModules = {
        nginx = import ./nixosModules/nginx.nix flakeContext;
        system = import ./nixosModules/system.nix flakeContext;
      };

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            rustToolchain
            openssl
            openssl.dev
            pkg-config
            cargo-deny
            cargo-edit
            cargo-watch
            cargo-make
            cargo-generate
            cargo-leptos
            cacert
            trunk
            direnv
            lld
            clang
            gcc
            zsh
            git
            starship
            rust-analyzer
            sass
            tailwindcss
          ];
        };
      });
    };
}

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [
          (import rust-overlay)
          (self: super: {
            rustStable =
              (self.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml);
          })

        ];
        pkgs = import nixpkgs { inherit system overlays; };

        devShell = pkgs.mkShell ({
          buildNativeInputs = with pkgs; [
            rustStable
            llvmPackages_12.clang
            llvm_12
          ];

          buildInputs = with pkgs;
            [
              sccache

              openssl_3_0
              pkg-config
              libiconv

            ] ++ lib.optionals stdenv.isDarwin [
              darwin.apple_sdk.frameworks.Security
            ];

          RUSTC_WRAPPER = "sccache";
          LIBCLANG_PATH = "${pkgs.llvmPackages_12.libclang.lib}/lib";
        });
      in {
        packages = rec {
          dev-shell = devShell.inputDerivation;
        };

        inherit devShell;
      });
}

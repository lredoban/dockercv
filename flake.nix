{
  description = "dockercv - Parse ANSI/ASCII file and split text and CSI Sequence";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    godown.url = "github:badele/godown";
    gosect.url = "github:badele/gosect";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      godown,
      gosect,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Go development
            go
            gopls
            gotools # goimports, godoc, etc.
            go-tools # staticcheck, etc.

            # Build tools
            mise

            # Pre-commit hooks
            pre-commit

            # Docker linting
            hadolint

            godown.packages.${system}.default
            gosect.packages.${system}.default
          ];

          shellHook = ''
            echo "🚀 bootcv development environment"
            echo "Go version: $(go version)"
            echo ""
            mise task
          '';
        };
      }
    );
}

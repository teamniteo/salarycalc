{ sources ? import ./sources.nix
}:

let
  overlay = final: pkgs: {
    gitignoreSource = (import sources.gitignore { inherit (pkgs) lib; }).gitignoreSource;
    poetry2nix = import sources.poetry2nix { pkgs = final; };
  };
in
import sources.nixpkgs {
  overlays = [ overlay ];
  config = { allowUnfree = true; };
}

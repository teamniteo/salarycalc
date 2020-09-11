{ sources ? import ./sources.nix
}:

let
  overlay = _: pkgs: {
    gitignoreSource = (import sources.gitignore { inherit (pkgs) lib; }).gitignoreSource;
    poetry2nix = import sources.poetry2nix {
      inherit pkgs;
      inherit (pkgs) poetry;
    };
  };
in import sources.nixpkgs {
 overlays = [ overlay ];
 config = { allowUnfree = true; };
}

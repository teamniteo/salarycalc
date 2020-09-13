{ sources ? import ./sources.nix
}:

let
  overlay = _: pkgs: {
    gitignoreSource = (import sources.gitignore { inherit (pkgs) lib; }).gitignoreSource;
    # currently using the fork at
    # https://github.com/Infinisil/yarn2nix/tree/yarnnix which includes
    # https://github.com/NixOS/nixpkgs/pull/92856 (the current yarn2nix Nix code
    # comes from the yarn2nix module, but it's included in nixpkgs in the future)
    yarn2nix = import sources.yarn2nix {
      inherit pkgs;
      nodejs = pkgs.nodejs-10_x;
    };
    poetry2nix = import sources.poetry2nix {
      inherit pkgs;
      inherit (pkgs) poetry;
    };
  };
in import sources.nixpkgs {
 overlays = [ overlay ];
 config = { allowUnfree = true; };
}

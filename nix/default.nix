{
  sources ? import ./sources.nix,
}:

let
  overlay = _: _: {

  };
in
import sources.nixpkgs {
  overlays = [ overlay ];
  config = {
    allowUnfree = true;
  };
}

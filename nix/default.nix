{
  sources ? import ./sources.nix,
}:

let
  overlay = _: _: {
    inherit (import sources.nixpkgs-unstable { }) gh-actions-lock;
  };
in
import sources.nixpkgs {
  overlays = [ overlay ];
  config = {
    allowUnfree = true;
  };
}

# This function takes a `nix-shell`-able derivation and returns a derivation
# that can be built. The runtime dependencies of the resulting derivation are
# the buildtime dependencies of the input derivation.
{ pkgs, drv }:
let
  config = import <nix/config.nix>;
in
derivation (drv.drvAttrs // {
  name = "${drv.name}-env";
  system = drv.system;
  _derivation_original_builder = drv.builder;
  _derivation_original_args = drv.args;
  builder = pkgs.stdenv.shell;
  args = [ "-c" " export > $out" ];
})

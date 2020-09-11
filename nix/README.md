# Nix

`sources.*` are manipulated by command `niv`, see
[niv](https://github.com/nmattia/niv#commands) for instructions on how to update
packages. `default.nix` then imports those sources and adds them on top of
`nixpkgs` packages.

We have the `nixpkgs-update.yml` GitHub Action to update to latest stable commit
in current channel on 1st day of every month.

{ pkgs ? import ./nix { }
# Allows CI to override this to an empty directory to determine dependencies
# Which then can get cached without the source code itself
, buildSrc ? ./.
}:
let

  buildableShell = import ./nix/buildableShell.nix {
    inherit pkgs;
    # We reimport this file with buildSrc set to /var/empty such that the dev env to
    # upload to cachix doesn't depend on where the project is located in the filesystem
    drv = (import ./. { buildSrc = "/var/empty"; }).devShell;
  };

  removePytestRunner = pkg: pkg.overrideAttrs (old: {
    postPatch = old.postPatch or "" + ''
      substituteInPlace setup.py \
        --replace "'pytest-runner'," "" \
        --replace "'pytest-runner'" "" \
        --replace '"pytest-runner",' "" \
        --replace '"pytest-runner"' ""
    '';
  });

  poetryOverrides = self: super: {
    # Fails when trying to update Nix packages. Research Done here: https://github.com/niteoweb/kai/issues/238
    flake8-debugger = removePytestRunner super.flake8-debugger;
    flake8-mutable = removePytestRunner super.flake8-mutable;
    flake8-print = removePytestRunner super.flake8-print;

  };

  commonPoetryArgs = {
    projectDir = ./.;
    overrides = [
      pkgs.poetry2nix.defaultPoetryOverrides
      poetryOverrides
    ];
  };

 # All dev and non-dev dependencies with knowledge of the salarycalc module in the source
  devEnv = pkgs.poetry2nix.mkPoetryEnv (commonPoetryArgs // {
    editablePackageSources = {
      salarycalc = buildSrc + "./";
    };
  });

  # The development shell definition
  devShell = pkgs.mkShell {
    buildInputs = with pkgs; [
      devEnv
      poetry
      geckodriver
      gitAndTools.pre-commit
      vim
      niv
    ]

    # Currently, both firefox and firefox-bin are broken on Darwin (MacOS)
    # so if you are on a MacBook, you have to manually install firefox.
    # If https://github.com/NixOS/nixpkgs/issues/53979 gets fixed,
    # we can remove this if.
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      pkgs.firefox
    ];

    shellHook = ''
      if [[ -d .git ]]; then
        pre-commit install -f --hook-type pre-commit
        pre-commit install -f --hook-type pre-push
      fi
    '';
  };

in {
  inherit devShell;
  inherit buildableShell;

  # Used to install dependencies for CI and Heroku
  inherit pkgs;
}

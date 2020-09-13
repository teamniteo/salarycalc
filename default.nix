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

  # The development shell definition
  devShell = pkgs.mkShell {
    inputsFrom = [
      dist
    ];
    buildInputs = with pkgs; [
      # common tooling
      devEnv
      gitAndTools.pre-commit
      niv
      vim

      # Elm app
      elmPackages.elm
      elmPackages.elm-format
      elmPackages.elm-analyse
      elmPackages.elm-verify-examples
      elmPackages.elm-test
      elm2nix
      yarn

      # Python helper scripts
      geckodriver
      poetry

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

      dest=${toString buildSrc}/node_modules
      ${copyGeneratedFiles}
    '';
  };

  # Elm stuff
  yarnPkg = pkgs.yarn2nix.mkYarnPackage {
    name = "salarycalc-node-packages";
    src = pkgs.lib.cleanSourceWith {
      src = ./.;
      name = "salarycalc-package.json";
      filter = name: type: baseNameOf (toString name) == "package.json";
    };
    yarnLock = ./yarn.lock;
    publishBinsFor = [
        "parcel-bundler"
        "eslint"
    ];
  };

  copyGeneratedFiles = ''
    echo "symlinking node_modules ..." >> /dev/stderr
    rm -rf $dest
    ln -s ${yarnPkg}/libexec/salarycalc/node_modules $dest
  '';

  dist = pkgs.stdenv.mkDerivation {
    name = "salarycalc-frontend-dist";

    src = pkgs.lib.cleanSourceWith {
      src = pkgs.gitignoreSource buildSrc;
      # parcel reuses the source name
      name = "salarycalc";
    };

    buildInputs = with pkgs.elmPackages; [
      elm
      yarnPkg
      pkgs.yarn
    ];

    patchPhase = ''
      dest=node_modules
      ${copyGeneratedFiles}
    '';

    configurePhase = pkgs.elmPackages.fetchElmDeps {
      elmPackages = import ./elm-srcs.nix;
      registryDat = ./registry.dat;
      inherit (pkgs.elmPackages) elmVersion;
    };

    buildPhase = ''
      rm -rf dist/
      yarn --offline build
    '';

    installPhase = ''
      mkdir -p $out
      cp -R dist/* $out/
    '';
  };


  # Python stuff
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


in {
  inherit dist devShell;
  inherit buildableShell;

  # Used to install dependencies for CI and Heroku
  inherit pkgs;
}

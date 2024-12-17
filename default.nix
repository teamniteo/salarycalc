{ pkgs ? import ./nix { } }:
let

  # The development shell definition
  devShell = pkgs.mkShell {
    buildInputs = with pkgs; [
      # common tooling
      gitAndTools.pre-commit
      niv
      vim

      # Elm app
      elmPackages.elm
      elmPackages.elm-format
      elmPackages.elm-analyse
      elmPackages.elm-verify-examples
      elmPackages.elm-test
      elmPackages.elm-coverage
      elm2nix
      nodePackages.npm
      yarn
      yarnPkg

      # Python helper scripts
      poetry
      poetryEnv

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

      dest=./node_modules
      ${copyGeneratedFiles}

      export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
    '';
  };

  # Elm stuff
  yarnPkg = pkgs.mkYarnPackage {
    name = "salary-calculator-node-packages";
    src = pkgs.lib.cleanSourceWith {
      src = ./.;
      name = "salary-calculator-package.json";
      filter = name: type: baseNameOf (toString name) == "package.json";
    };
    yarnLock = ./yarn.lock;
    publishBinsFor = [
        "eslint"
        "parcel"
    ];
  };

  copyGeneratedFiles = ''
    echo "symlinking node_modules ..." >> /dev/stderr
    rm -rf $dest
    ln -s ${yarnPkg}/libexec/salary-calculator/node_modules $dest
  '';

  # Python stuff
  poetryEnv = pkgs.poetry2nix.mkPoetryEnv {
    python = pkgs.python311;
    projectDir = ./.;
    editablePackageSources = {
      salarycalc = ./.;
    };
    overrides = pkgs.poetry2nix.defaultPoetryOverrides.extend(self: super: {

      flake8-assertive = super.flake8-assertive.overridePythonAttrs (
      old: {
        buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
      });

      pyee = super.pyee.overridePythonAttrs (
        old: {
          patchPhase = ":";
        }
      );

    });
  };

in {
  inherit devShell;

  # Used to install dependencies for CI and Heroku
  inherit pkgs;
}

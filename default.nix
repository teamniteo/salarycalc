{ pkgs ? import ./nix { } }:
let

  # Create a Python environment with playwright and all its dependencies
  pythonWithPlaywright = pkgs.python313.withPackages (
    ps: with ps; [
      playwright
    ]
  );

  # The development shell definition
  devShell = pkgs.mkShell {
    buildInputs = with pkgs; [
      # common tooling
      niv

      # Elm app
      elmPackages.elm
      elmPackages.elm-format
      elmPackages.elm-analyse
      # elmPackages.elm-verify-examples  # currently broken in nixpkgs
      elmPackages.elm-test
      elm2nix
      nodePackages.npm
      yarn
      yarnPkg

      # Python stuff
      python313
      uv
      (pre-commit.override { python3Packages = python313Packages; })
      python313Packages.pre-commit-hooks

      # Support for Playwright
      pythonWithPlaywright
      nodejs
    ];

    shellHook = ''
      if [[ -d .git ]]; then
        pre-commit install -f --hook-type pre-commit
        pre-commit install -f --hook-type pre-push
      fi

      dest=./node_modules
      ${copyGeneratedFiles}

      unset PYTHONPATH
      uv sync --dev
      . .venv/bin/activate

      # Add Playwright and its dependencies to path
      export PYTHONPATH="${pythonWithPlaywright}/${pythonWithPlaywright.sitePackages}:$PYTHONPATH"
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

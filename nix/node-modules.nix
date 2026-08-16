_: {
  perSystem =
    { config, pkgs, ... }:
    let
      pnpm = config.pnpmPackage;
      nodejs = config.nodejsPackage;
      src = ./..;

      pnpmDeps = pkgs.fetchPnpmDeps {
        pname = "pnpm-project-deps";
        version = "1.0.0";
        inherit src pnpm;
        fetcherVersion = 3;
        hash = "sha256-LsPs7Sd+oxFWDDj30gmp6+5Q5bL8Vu5ND95vY4nPD5c=";
      };

      nodeModules = pkgs.stdenvNoCC.mkDerivation {
        name = "pnpm-project-node-modules";
        inherit src pnpmDeps;

        nativeBuildInputs = [
          nodejs
          pkgs.pnpmConfigHook
          pnpm
        ];

        dontBuild = true;

        installPhase = ''
          runHook preInstall
          cp -r node_modules $out
          runHook postInstall
        '';
      };
    in
    {
      # Prebuilt node_modules; consumers symlink this instead of installing.
      packages.nodeModules = nodeModules;

      # `source`-able snippet: writable node_modules, copied from the store
      # above (no re-download; copy, not symlink, so every package resolves
      # to a real path inside the project. Turbopack refuses to compile
      # anything whose resolved path escapes its workspace root, and a
      # top-level `ln -s` into /nix/store fails that check).
      packages.nodeModulesSetup = pkgs.writeShellScript "node-modules-setup" ''
        (
          # node_modules must be a real directory. Clear it first if it's a
          # symlink (dangling, or the old top-level `ln -sfn` style) or a
          # plain file, so `[ ! -d node_modules ]` below reflects reality.
          if [ -L node_modules ] || { [ -e node_modules ] && [ ! -d node_modules ]; }; then
            rm -f node_modules
          fi

          if [ ! -d node_modules ]; then
            mkdir node_modules
            cp -r ${nodeModules}/. node_modules/
            chmod -R u+w node_modules
          fi
        )
      '';
    };
}

{
  description = "Application template";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2605";
    git-hooks = {
      url = "https://flakehub.com/f/cachix/git-hooks.nix/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    git-hooks,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    root = pkgs.runCommand "application-root" {} ''
      mkdir -p "$out/etc/caddy" "$out/srv"
      cp ${./Caddyfile} "$out/etc/caddy/Caddyfile"
      cp -R ${./site}/. "$out/srv/"
    '';
    dockerImage = pkgs.dockerTools.buildLayeredImage {
      name = "application";
      tag = "latest";
      created = "1970-01-01T00:00:01Z";
      contents = [pkgs.caddy root];
      config = {
        Cmd = ["${pkgs.caddy}/bin/caddy" "run" "--config" "/etc/caddy/Caddyfile"];
        ExposedPorts."8080/tcp" = {};
      };
    };
    preCommitCheck = git-hooks.lib.${system}.run {
      package = pkgs.prek;
      src = ./.;
      hooks = {
        actionlint.enable = true;
        alejandra.enable = true;
        check-added-large-files.enable = true;
        check-merge-conflicts.enable = true;
        check-yaml.enable = true;
        end-of-file-fixer.enable = true;
        trim-trailing-whitespace.enable = true;
      };
    };
  in {
    packages.${system} = {
      default = dockerImage;
      inherit dockerImage;
    };

    checks.${system} = {
      inherit dockerImage;
      pre-commit = preCommitCheck;
    };

    formatter.${system} = pkgs.alejandra;

    devShells.${system}.default = pkgs.mkShell {
      packages = preCommitCheck.enabledPackages;
      inherit (preCommitCheck) shellHook;
    };
  };
}

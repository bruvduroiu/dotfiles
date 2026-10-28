# uv2nix: pyproject.toml + uv.lock are the source of truth. `uv add` changes
# deps; Nix follows the lock (commit uv.lock, or the build can't see it).
{
  lib,
  callPackage,
  callPackages,
  runCommand,
  python3,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}:

let
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

  pythonSet = (callPackage pyproject-nix.build.packages { python = python3; }).overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.default
      (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
      # Per-package fixes (native libs, missing build-system) go here.
      (final: prev: { })
    ]
  );

  app = (callPackages pyproject-nix.build.util { }).mkApplication {
    venv = pythonSet.mkVirtualEnv "myapp-env" workspace.deps.default;
    package = pythonSet.myapp;
  };

  # deps.all includes [dependency-groups] dev, where pytest lives.
  testVenv = pythonSet.mkVirtualEnv "myapp-test-env" workspace.deps.all;
in
lib.extendDerivation true {
  tests = lib.optionalAttrs (builtins.pathExists ./tests) {
    pytest = runCommand "myapp-pytest" { nativeBuildInputs = [ testVenv ]; } ''
      cp -r ${./tests} tests
      pytest -p no:cacheprovider tests
      touch $out
    '';
  };
} app

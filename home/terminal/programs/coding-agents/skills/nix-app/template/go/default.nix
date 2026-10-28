{ lib, buildGoModule }:

buildGoModule {
  pname = "myapp";
  version = "0.1.0";

  # Only Go sources: editing shell.nix or a README doesn't rebuild the app.
  # Add embedded assets / testdata here when the code needs them.
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (
      f:
      f.hasExt "go"
      || builtins.elem f.name [
        "go.mod"
        "go.sum"
      ]
    ) ./.;
  };

  # null = no external deps. With deps: set lib.fakeHash, `nix build`, paste the "got:" hash.
  vendorHash = null;

  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
  ];

  meta.mainProgram = "myapp";
}

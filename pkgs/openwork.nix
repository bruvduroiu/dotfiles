{ lib, appimageTools, fetchurl, runtimeProfile ? "", opencodeV2 ? null, ... }:

let
  pname = "openwork";
  version = "0.18.63";
  src = fetchurl {
    url = "https://github.com/different-ai/openwork/releases/download/v${version}/openwork-linux-x86_64-${version}.AppImage";
    hash = "sha256-YPQAGRp/fetPXG+vW6JjWGkWgeqB4tZaGAWZ5V/pPjU=";
  };
  contents = appimageTools.extractType2 {
    inherit pname version src;
    postExtract = lib.optionalString (opencodeV2 != null) ''
      # The desktop unconditionally selects its bundled sidecar, overriding
      # OPENWORK_OPENCODE2_BIN. Replace that entrypoint declaratively.
      rm $out/resources/sidecars/opencode2
      ln -s ${opencodeV2} $out/resources/sidecars/opencode2
    '';
  };
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = contents;

  # The bundled Electron and OpenCode engines expect an FHS environment.
  extraPkgs = pkgs: [ pkgs.libsecret pkgs.git pkgs.ripgrep ];

  profile = runtimeProfile;

  extraInstallCommands = ''
    install -Dm644 ${contents}/com.differentai.openwork.desktop $out/share/applications/openwork.desktop
    substituteInPlace $out/share/applications/openwork.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=openwork'
    cp -r ${contents}/usr/share/icons $out/share/
  '';

  meta = {
    description = "Desktop workspace for AI agents, powered by OpenCode";
    homepage = "https://github.com/different-ai/openwork";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "openwork";
  };
}

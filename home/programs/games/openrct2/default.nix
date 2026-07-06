# Declarative OpenRCT2 (Claude-playable "coding-agent" fork) for Steam Deck
#
# This installs jaysobel/OpenRCT2 @ coding-agent — a fork of OpenRCT2 that adds an
# in-game "AI agent terminal": OpenRCT2 spawns the `claude` CLI (Claude Code) in a
# pseudo-terminal and lets it drive the park through a small JSON-RPC bridge binary
# called `rctctl`. The base game is unchanged, so the original RCT2 game data is
# still REQUIRED to play.
#
# Packaging strategy
#   We override nixpkgs' `openrct2` with `overrideAttrs` rather than rewriting it,
#   so we inherit upstream's data provisioning (the objects/openmusic/opensfx/
#   title-sequences fetchurls + `postUnpack`) and its install() logic untouched.
#   We only swap in the fork source and layer on what the fork additionally needs:
#     * src             -> the jaysobel coding-agent commit (pinned by rev+hash)
#     * python3         -> the fork's root CMakeLists unconditionally
#                          `find_package(Python3 ... REQUIRED)`s it (base does not)
#     * libvterm-neovim -> the agent terminal renders ANSI via libvterm; CMake
#                          probes the pkg-config module `vterm` (the neovim fork's
#                          module/API) and hard-fails (FATAL_ERROR) when missing
#     * cmakeFlags      -> REPLACED: the fork uses DOWNLOAD_OPENMSX (the older
#                          option name), NOT 0.5.x's DOWNLOAD_OPENMUSIC, so the
#                          inherited flag would silently not disable the download
#     * preConfigure="" -> DROPPED: this fork has no assets.json, so nixpkgs 0.5.x's
#                          "grep the asset URLs out of assets.json" check would fail;
#                          the asset versions are pinned in CMakeLists.txt instead
#     * buildFlags      -> `agent_bundle` (game + CLI + rctctl + graphics assets)
#     * doInstallCheck  -> false: versionCheckHook would assert a version string the
#                          fork does not report
#     * postInstall     -> copy the `rctctl` binary out (it has NO install() rule)
#                          and materialise the "repo root" the launcher requires
#
# In-game agent runtime
#   When you open the in-game terminal the launcher (AIAgentLaunch.cpp) first
#   insists on finding a "repo root" — a directory holding BOTH `rctctl/CMakeLists
#   .txt` and `src/`, with the rctctl binary at `<root>/build/rctctl/rctctl` and the
#   agent brief at `<root>/ai-agent-workspace/IN_GAME_AGENT.md`. It locates that
#   root by walking up from the cwd / data dir / exe dir. Because the Nix store has
#   none of that next to the binary, `postInstall` builds a minimal synthetic root
#   under `$out/share/openrct2-agent/repo` and the wrapper `--chdir`s into it so the
#   cwd probe matches on the first try. OpenRCT2 resolves its OWN data via the
#   install prefix / XDG dirs (never cwd), so the chdir is safe for normal play.
#
#   The terminal then launches the real `claude` binary, found by a plain PATH scan
#   (`FindExecutable("claude")`). Two things make that reliable here:
#     1. The Steam Deck profile imports ../../terminal/programs/claude, enabling
#        `programs.claude-code` — so the deck user has a fully configured Claude Code
#        (settings, agents, MCP, plugins) under ~/.claude, read from $HOME at runtime.
#     2. We ALSO prepend `pkgs.claude-code` to this package's own wrapper PATH, so the
#        openrct2 process sees `claude` even when launched from Steam Gaming Mode,
#        which does NOT source the Home Manager session PATH. Both reference the same
#        `pkgs.claude-code`, so the ~/.claude config applies either way.
#   claude-code is unfree (this host already allows unfree for Steam). If `claude` is
#   somehow absent the launcher degrades to a bundled REPL (`scripts/agent_bootstrap.sh`,
#   needs python3 — also on the wrapper PATH); that fallback is spawned via a hardcoded
#   `/bin/bash`, which exists on SteamOS but not on stock NixOS.
#
# RCT2 game data
#   No build-time path is hardcoded. On first launch OpenRCT2 prompts for the RCT2
#   install directory. This works whether RCT2 lives on the internal disk or an SD
#   card. The Steam install is typically at:
#     ~/.steam/steam/steamapps/common/RollerCoaster Tycoon 2 Triple Thrill Pack
#
{ config, pkgs, lib, ... }:

let
  # jaysobel/OpenRCT2 @ coding-agent. Pinned to an exact commit; the fork has no
  # release tags. The hash is the NAR hash of the unpacked fetchFromGitHub output.
  openrct2 = pkgs.openrct2.overrideAttrs (old: {
    pname = "openrct2-agent";
    # Cosmetic only (doInstallCheck is disabled below). The fork tracks a pre-0.5.x
    # tree, so we do NOT label it 0.5.x to avoid implying release parity. (We ship
    # the inherited objects v1.7.9 data — a superset of the fork's pinned v1.7.3.)
    version = "unstable-3c278a85";

    src = pkgs.fetchFromGitHub {
      owner = "jaysobel";
      repo = "OpenRCT2";
      rev = "3c278a8544d3f8f280e5043b5396c3a33751e20e";
      sha256 = "sha256-AQyTFQDr+ORJROoBxhy6KnuCcl/tQqCT1SGjkzsjYig=";
    };

    # The fork's CMake unconditionally requires a Python3 interpreter at configure
    # time (CLI-validation test harness registration). pkg-config + makeWrapper +
    # versionCheckHook are already in the inherited nativeBuildInputs.
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.python3 ];

    # libvterm-neovim ships `vterm.h` + a pkg-config module named `vterm`, which is
    # exactly what `PKG_CHECK_MODULES(LIBVTERM ... IMPORTED_TARGET vterm)` looks for
    # and what the fork's terminal code targets (neovim libvterm 0.3.x API). The
    # unrelated `libvterm` (0.99.x) would not satisfy the probe.
    buildInputs = old.buildInputs ++ [ pkgs.libvterm-neovim ];

    # Replaced wholesale. Same intent as upstream (don't download assets at build
    # time; no Discord RPC) but using THIS fork's option names. Note the fork uses
    # DOWNLOAD_OPENMSX, not 0.5.x's DOWNLOAD_OPENMUSIC. DOWNLOAD_REPLAYS is a
    # CMAKE_DEPENDENT_OPTION that is forced OFF unless WITH_TESTS, so it is omitted.
    cmakeFlags = [
      (lib.cmakeBool "DOWNLOAD_OBJECTS" false)
      (lib.cmakeBool "DOWNLOAD_TITLE_SEQUENCES" false)
      (lib.cmakeBool "DOWNLOAD_OPENSFX" false)
      (lib.cmakeBool "DOWNLOAD_OPENMSX" false)
      (lib.cmakeBool "DISABLE_DISCORD_RPC" true)
    ];

    # Convenience target that builds everything the agent needs in one shot:
    # rctctl + openrct2 + openrct2-cli + graphics (the g2/fonts/tracks .dat
    # generators). `make install` still installs the game/CLI/data regardless,
    # because CMake's `install` target depends on `preinstall` -> `all`.
    buildFlags = [ "agent_bundle" ];

    # Upstream's preConfigure greps asset URLs out of assets.json to verify pinned
    # versions. This fork has no assets.json (versions live in CMakeLists.txt via
    # set(..._VERSION ...)), so that check would error out. Drop it — the inherited
    # fetchurls/postUnpack still supply the data; see residual risk re: objects ver.
    preConfigure = "";

    # Extend the inherited postPatch (which rewrites the doc path in
    # Platform.Linux.cpp — that "/usr/share/doc/openrct2" literal is still present
    # exactly once on this fork) with a Linux/GCC portability fix for the fork's own
    # agent code, which was written against macOS/clang: Diagnostic.cpp uses
    # time/localtime/strftime without <ctime> (libc++ includes it transitively,
    # libstdc++ does not).
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/openrct2/Diagnostic.cpp \
        --replace-fail '#include "Diagnostic.h"' '#include <ctime>${"\n"}#include "Diagnostic.h"'
    '';

    # OpenRCT2 builds with global -Werror and a large strict warning set. The fork's
    # own agent code was written against macOS/clang and trips several warnings that
    # are GCC-only or behave differently there — e.g. ShellProcess.cpp's
    # `errno == EAGAIN || errno == EWOULDBLOCK` (-Wlogical-op: those macros are equal
    # on Linux) and AIAgentTerminal.cpp parameters shadowing window members (-Wshadow).
    # We package this third-party fork rather than maintain it, so downgrade -Werror to
    # plain warnings instead of patching each site. cc-wrapper appends NIX_CFLAGS_COMPILE
    # after the project's own flags, so this wins.
    NIX_CFLAGS_COMPILE = "-Wno-error";

    # The fork reports a different version string than upstream's `version`, which
    # would trip versionCheckHook. Disable the install check entirely.
    doInstallCheck = false;

    # Keep the inherited wrapProgram (rct1Path/rct2Path support — no-ops here since
    # this module pins neither), then provision the agent bits on top.
    postInstall = (old.postInstall or "") + ''

      ###########################################################################
      # jaysobel coding-agent wiring (in-game Claude terminal)
      ###########################################################################
      # postInstall runs from the CMake build dir (<src>/build); the source tree is
      # its parent. agent_bundle built rctctl at build/rctctl/rctctl.
      srcRoot=$(cd .. && pwd)
      rctctlBin=$(find "$PWD" -type f -name rctctl -executable | head -n1)
      if [ -z "$rctctlBin" ]; then
        echo "openrct2-agent: rctctl binary not found after agent_bundle build" >&2
        exit 1
      fi

      # rctctl has no install() rule. Put it on PATH so the agent child (claude or
      # the bootstrap REPL) can discover it.
      install -Dm755 "$rctctlBin" "$out/bin/rctctl"

      # Synthetic "repo root" the launcher insists on. LooksLikeRepoRoot() only
      # checks that rctctl/CMakeLists.txt and src/ exist; FindRctctlBinary() wants
      # <root>/build/rctctl/rctctl; SeedWorkspaceReadme() copies <root>/ai-agent-
      # workspace/IN_GAME_AGENT.md -> $HOME/.openrct2-agent/.claude/CLAUDE.md.
      repo="$out/share/openrct2-agent/repo"
      install -Dm644 "$srcRoot/rctctl/CMakeLists.txt"               "$repo/rctctl/CMakeLists.txt"
      install -Dm755 "$rctctlBin"                                    "$repo/build/rctctl/rctctl"
      install -Dm644 "$srcRoot/ai-agent-workspace/IN_GAME_AGENT.md"  "$repo/ai-agent-workspace/IN_GAME_AGENT.md"
      install -Dm755 "$srcRoot/scripts/agent_bootstrap.sh"           "$repo/scripts/agent_bootstrap.sh"
      mkdir -p "$repo/src"   # marker dir; only its existence is checked

      ###########################################################################
      # Agent terminal fonts
      ###########################################################################
      # The fork's TerminalFontPipeline (AIAgentTerminal.cpp) loads TTFs by hardcoded
      # filename from <data-dir>/data/fonts/ — i.e. $out/share/openrct2/data/fonts/.
      # But CMake's install(DIRECTORY "data/" ...) FLATTENS data/ into
      # $out/share/openrct2, so the bundled TTFs land in $out/share/openrct2/fonts and
      # the loader's data/fonts/ path does not exist → no font loads → the agent
      # console renders blank. Recreate the dir the loader expects, and make the
      # primary monospace a JetBrains Mono NERD FONT (the Mono variant keeps every
      # glyph single-cell) so Claude's TUI icons render instead of tofu. The two Noto
      # Sans Symbols faces (installed by the flattened data/) stay as glyph fallbacks.
      install -Dm644 ${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFontMono-Regular.ttf \
        "$out/share/openrct2/data/fonts/JetBrainsMono-Regular.ttf"
      install -Dm644 "$out/share/openrct2/fonts/NotoSansSymbols-Regular.ttf" \
        "$out/share/openrct2/data/fonts/NotoSansSymbols-Regular.ttf"
      install -Dm644 "$out/share/openrct2/fonts/NotoSansSymbols2-Regular.ttf" \
        "$out/share/openrct2/data/fonts/NotoSansSymbols2-Regular.ttf"

      # Re-wrap: chdir into the synthetic root so DetectRepoRoot()'s cwd seed
      # matches, and make claude (the agent), rctctl, and python3 (REPL fallback)
      # reachable on the openrct2 process PATH regardless of how it was launched —
      # Steam Gaming Mode does not source the Home Manager session PATH. PATH is
      # PREPENDED, so a claude already on PATH (from programs.claude-code) still wins.
      wrapProgram "$out/bin/openrct2" \
        --chdir "$repo" \
        --prefix PATH : "$out/bin" \
        --prefix PATH : ${lib.makeBinPath [ pkgs.claude-code pkgs.python3 pkgs.bash ]}
    '';

    meta = old.meta // {
      description = "OpenRCT2 jaysobel coding-agent fork (Claude-playable RollerCoaster Tycoon 2)";
      homepage = "https://github.com/jaysobel/OpenRCT2";
      changelog = "https://github.com/jaysobel/OpenRCT2/commits/coding-agent";
      mainProgram = "openrct2";
      platforms = lib.platforms.linux;
      broken = false;
    };
  });

  # Steam integration helper
  addToSteamScript = pkgs.writeShellScriptBin "openrct2-add-to-steam" ''
    echo "============================================"
    echo "  Add OpenRCT2 to Steam Gaming Mode"
    echo "============================================"
    echo ""
    echo "To add OpenRCT2 to Steam:"
    echo ""
    echo "1. Switch to Desktop Mode"
    echo "2. Open Steam"
    echo "3. Games -> Add a Non-Steam Game"
    echo "4. Browse to: ${openrct2}/bin/openrct2"
    echo "5. Click 'Add Selected Programs'"
    echo ""
    echo "Or select 'OpenRCT2' from the list."
    echo ""
    echo "On first launch, point OpenRCT2 at your RCT2 data, e.g.:"
    echo "  ~/.steam/steam/steamapps/common/RollerCoaster Tycoon 2 Triple Thrill Pack"
    echo ""
    echo "The game will appear in Gaming Mode!"
    echo ""
    echo "In-game: click the robot toolbar button to open the Claude agent terminal."
  '';

in {
  home.packages = [
    openrct2
    addToSteamScript
  ];

  # Desktop entry for Steam discovery
  xdg.desktopEntries.openrct2 = {
    name = "OpenRCT2";
    genericName = "RollerCoaster Tycoon 2";
    comment = "Open source re-implementation of RollerCoaster Tycoon 2";
    exec = "${openrct2}/bin/openrct2";
    icon = "openrct2";
    categories = [ "Game" "Simulation" ];
    terminal = false;
    settings = {
      StartupWMClass = "openrct2";
      Keywords = "rct;rollercoaster;tycoon;game;gaming;";
    };
  };
}

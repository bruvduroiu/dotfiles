{ lib }:

# Every coding agent on this machine and what it is given: MCP servers (by
# name, from ../coding-mcps) and skills (by name, from ./skills).
#
# `work` decides which MCP pool an agent picks from (`pools` in
# ../coding-mcps): a server in only one pool never reaches the other side's
# agents, so a work integration cannot leak into a personal session, nor the
# reverse. Picking a server outside the agent's pool fails evaluation.
#
# Every agent gets every skill for now, listed explicitly so that narrowing
# one agent is a change to its own entry.
let
  allSkills = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./skills));
in
{
  claude = {
    work = false;
    mcps = [
      "playwright"
      "linear"
      "kratos"
      "grafana"
    ];
    skills = allSkills;
  };
  claude-work = {
    work = true;
    # Figma comes from its official Claude Code plugin, which both accounts
    # load (../claude), so it is not listed here.
    mcps = [
      "playwright"
      "linear"
      "datadog"
      "notion"
    ];
    skills = allSkills;
  };
  codex = {
    work = false;
    # No kratos: Codex takes a bearer token only from an environment variable.
    mcps = [
      "playwright"
      "linear"
      "grafana"
    ];
    skills = allSkills;
  };
  opencode = {
    work = false;
    mcps = [
      "playwright"
      "linear"
      "figma"
      "kratos"
      "grafana"
    ];
    skills = allSkills;
  };
  # Not an agent of its own: the desktop app reads opencode's config, skills
  # included, then layers these MCPs over it through OPENCODE_CONFIG_CONTENT
  # (home/programs/opencode-desktop.nix). Terminal opencode never sees them.
  opencode-desktop = {
    work = false;
    mcps = [ "hey" ];
    skills = [ ];
  };
}

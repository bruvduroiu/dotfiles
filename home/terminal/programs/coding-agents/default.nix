{ lib, pkgs }:

let
  agentDir = ./agents;
  agentFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) (
    builtins.readDir agentDir
  );
  agentNames = map (lib.removeSuffix ".md") (builtins.attrNames agentFiles);

  sourceFor = name: agentDir + "/${name}.md";
  linesFor = name: lib.splitString "\n" (builtins.readFile (sourceFor name));
  fieldFor =
    name: field:
    lib.removePrefix "${field}: " (
      lib.findFirst (lib.hasPrefix "${field}: ") "${field}:" (linesFor name)
    );
  dropUntil =
    predicate: list:
    if list == [ ] || predicate (builtins.head list) then
      list
    else
      dropUntil predicate (builtins.tail list);
  bodyFor =
    name:
    lib.concatStringsSep "\n" (
      lib.drop 1 (dropUntil (line: line == "---") (lib.drop 1 (linesFor name)))
    );
  hasTool = name: tool: lib.hasInfix tool (fieldFor name "tools");
  isWritable = name: hasTool name "Write" || hasTool name "Edit";
  needsWritableSandbox = name: isWritable name || hasTool name "Bash";

  opencodeAgent = name: ''
    ---
    description: ${builtins.toJSON (fieldFor name "description")}
    mode: subagent
    model: openai/gpt-5.6-sol
    permission:
      read: ${if hasTool name "Read" then "allow" else "deny"}
      edit: ${if isWritable name then "allow" else "deny"}
      glob: ${if hasTool name "Glob" then "allow" else "deny"}
      grep: ${if hasTool name "Grep" then "allow" else "deny"}
      bash: ${if hasTool name "Bash" then "allow" else "deny"}
      task: deny
      webfetch: deny
      websearch: deny
    ---

    ${bodyFor name}
  '';

  toml = pkgs.formats.toml { };
  codexAgent = name: {
    description = fieldFor name "description";
    config_file = toml.generate "codex-agent-${name}.toml" {
      developer_instructions = bodyFor name;
      sandbox_mode = if needsWritableSandbox name then "workspace-write" else "read-only";
    };
  };
in
{
  context = ./AGENTS.md;
  skills = ./skills;
  claudeAgents = agentDir;
  opencodeAgents = lib.genAttrs agentNames opencodeAgent;
  codexAgents = lib.genAttrs agentNames codexAgent;
}

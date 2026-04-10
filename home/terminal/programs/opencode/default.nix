{ config
, pkgs
, lib
, ... 
}:

let
  superpowersSrc = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "v5.0.7";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;

    web.enable = true;
    package = pkgs.opencode;

    settings = {
      autoshare = false;
      autoupdate = false;
    };

    agents = {
      plan = ./agents/plan.md;
    };

    skills = {
      superpowers-brainstorming = "${superpowersSrc}/skills/brainstorming";
      superpowers-dispatching-parallel-agents = "${superpowersSrc}/skills/dispatching-parallel-agents";
      superpowers-executing-plans = "${superpowersSrc}/skills/executing-plans";
      superpowers-finishing-a-development-branch = "${superpowersSrc}/skills/finishing-a-development-branch";
      superpowers-receiving-code-review = "${superpowersSrc}/skills/receiving-code-review";
      superpowers-requesting-code-review = "${superpowersSrc}/skills/requesting-code-review";
      superpowers-subagent-driven-development = "${superpowersSrc}/skills/subagent-driven-development";
      superpowers-systematic-debugging = "${superpowersSrc}/skills/systematic-debugging";
      superpowers-test-driven-development = "${superpowersSrc}/skills/test-driven-development";
      superpowers-using-git-worktrees = "${superpowersSrc}/skills/using-git-worktrees";
      superpowers-using-superpowers = "${superpowersSrc}/skills/using-superpowers";
      superpowers-verification-before-completion = "${superpowersSrc}/skills/verification-before-completion";
      superpowers-writing-plans = "${superpowersSrc}/skills/writing-plans";
      superpowers-writing-skills = "${superpowersSrc}/skills/writing-skills";
    };
  };
}

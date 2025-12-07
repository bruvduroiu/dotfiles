{ ... }:
{
  # OpenCode configuration as Nix attrset
  config = {
    "$schema" = "https://opencode.ai/config.json";
    disabled_providers = [
      "openai"
      "gemini"
      "moonshotai"
      "deepseek"
      "perplexity"
    ];
    instructions = [ ];
    keybinds = { };
    tui = { };

    provider = {
      openrouter = {
        npm = "@openrouter/ai-sdk-provider";
        name = "OpenRouter";
        options = {
          apiKey = "{env:OPENROUTER_API_KEY}";
        };
        models = {
          kimi-k2-thinking = {
            id = "moonshotai/kimi-k2-thinking";
            name = "Kimi K2: Thinking";
            options = {
              reasoningEffort = "medium";
              textVerbosity = "medium";
              reasoningSummary = "auto";
            };
          };
        };
      };
    };

    permission = { };

    tools = { };

    lsp = { };

    mcp = { 
      deepwiki = {
        type = "remote";
        url = "https://mcp.deepwiki.com/mcp";
      };
    };
  };
}

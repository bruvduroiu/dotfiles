return {
	provider = "claude", -- Recommend using Claude
  providers = {
    claude = {
      endpoint = "https://api.z.ai/api/anthropic",
      model = "glm4.6",
      timeout = 30000,
      api_key_name = "ANTHROPIC_AUTH_TOKEN",
      extra_request_body = {
        temperature = 0,
        max_tokens = 4096,
      },
    },
		openrouter = {
			__inherited_from = "openai",
			endpoint = "https://openrouter.ai/api/v1",
			api_key_name = "OPENROUTER_API_KEY_AVANTE",
			model = "anthropic/claude-sonnet-4.5",
      extra_request_body ={
        temperature = 0,
        max_tokens = 4096,
      },
		},
  },
	auto_suggestions_provider = nil, -- Since auto-suggestions are a high-frequency operation and therefore expensive, it is recommended to specify an inexpensive provider or even a free provider: copilot
}

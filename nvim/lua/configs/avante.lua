return {
	provider = "openrouter", -- Recommend using Claude
	vendors = {
		["openrouter"] = {
			__inherited_from = "openai",
			endpoint = "https://openrouter.ai/api/v1",
			api_key_name = "OPENROUTER_API_KEY_AVANTE",
			model = "anthropic/claude-3.5-sonnet",
			temperature = 0,
			max_tokens = 4096,
		},
	},
	auto_suggestions_provider = "copilot", -- Since auto-suggestions are a high-frequency operation and therefore expensive, it is recommended to specify an inexpensive provider or even a free provider: copilot
}

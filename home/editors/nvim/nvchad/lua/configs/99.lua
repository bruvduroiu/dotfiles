-- Copyright 2026 Brad White
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
---- Custom OpenRouter provider for ThePrimeagen/99
-- Uses curl via vim.system instead of Nushell.
-- API key is loaded from OPENROUTER_API_KEY env var (set by sops-nix via fish shellInit).

local _99 = require("99")

local cwd = vim.uv.cwd()
local basename = vim.fs.basename(cwd)

local function get_api_key()
  local key = os.getenv("OPENROUTER_API_KEY")
  if key and key ~= "" then
    return key
  end
  return nil
end

local function build_provider()
  local BaseProvider = require("99.providers").BaseProvider

  --- @class OpenRouterProvider : _99.Providers.BaseProvider
  local OpenRouterProvider = setmetatable({}, { __index = BaseProvider })

  function OpenRouterProvider._get_provider_name()
    return "OpenRouterProvider"
  end

  function OpenRouterProvider._get_default_model()
    return "moonshotai/kimi-k2.5"
  end

  -- Required by pickers.lua for provider discovery; unused since make_request is overridden
  function OpenRouterProvider._build_command(_, _, _)
    return { "true" }
  end

  function OpenRouterProvider:make_request(query, context, observer)
    observer.on_start()

    local api_key = get_api_key()
    if not api_key then
      observer.on_stderr("OPENROUTER_API_KEY not set (check secrets.lua or env)\n")
      observer.on_complete("failed", "OPENROUTER_API_KEY not set")
      return
    end

    local system_msg = "You are a code-writing assistant. "
      .. "Output ONLY raw code or raw text as requested. "
      .. "NEVER wrap output in markdown code fences (```) or only add commentary in comments. "
      .. "When asked to write to a file path, output the exact file contents only."

    local payload = vim.json.encode({
      model = context.model,
      messages = {
        { role = "system", content = system_msg },
        { role = "user", content = query },
      },
    })

    local payload_file = os.tmpname()
    local pf = io.open(payload_file, "w")
    pf:write(payload)
    pf:close()

    local accumulated = {}

    local proc = vim.system(
      {
        "curl",
        "-sS",
        "https://openrouter.ai/api/v1/chat/completions",
        "-H",
        "Authorization: Bearer " .. api_key,
        "-H",
        "Content-Type: application/json",
        "-d",
        "@" .. payload_file,
      },
      {
        text = true,
        stdout = vim.schedule_wrap(function(_, data)
          if context:is_cancelled() or not data then
            return
          end
          table.insert(accumulated, data)
          observer.on_stdout(data)
        end),
        stderr = vim.schedule_wrap(function(_, data)
          if data then
            observer.on_stderr(data)
          end
        end),
      },
      vim.schedule_wrap(function(obj)
        os.remove(payload_file)
        if context:is_cancelled() then
          observer.on_complete("cancelled", "")
          return
        end

        if obj.code ~= 0 then
          observer.on_complete("failed", "curl exit code: " .. obj.code .. "\n" .. (obj.stderr or ""))
          return
        end

        local raw = table.concat(accumulated)
        local ok, decoded = pcall(vim.json.decode, raw)
        if not ok then
          observer.on_complete("failed", "Failed to parse API response: " .. raw)
          return
        end

        local content = ""
        if decoded.choices and decoded.choices[1] and decoded.choices[1].message then
          local c = decoded.choices[1].message.content
          if c ~= nil and c ~= vim.NIL then
            content = c
          end
        end

        if content == "" then
          observer.on_complete("failed", "Empty response from OpenRouter: " .. raw)
          return
        end

        -- Strip markdown code fences if the LLM still wraps output
        content = content:gsub("^```[a-z]*\n", ""):gsub("\n```$", "")

        -- Write to tmp_file so _retrieve_response works
        local f = io.open(context.tmp_file, "w")
        if f then
          f:write(content)
          f:close()
        end

        observer.on_complete("success", content)
      end)
    )

    context:_set_process(proc)
  end

  function OpenRouterProvider.fetch_models(callback)
    vim.system(
      {
        "curl",
        "-sS",
        "https://openrouter.ai/api/v1/models",
      },
      { text = true },
      vim.schedule_wrap(function(obj)
        if obj.code ~= 0 then
          callback(nil, "Failed to fetch models from OpenRouter: " .. (obj.stderr or ""))
          return
        end
        local ok, decoded = pcall(vim.json.decode, obj.stdout)
        if not ok then
          callback(nil, "Failed to parse models response")
          return
        end
        local models = {}
        if decoded.data then
          for _, m in ipairs(decoded.data) do
            if m.id then
              table.insert(models, m.id)
            end
          end
        end
        table.sort(models)
        callback(models, nil)
      end)
    )
  end

  return OpenRouterProvider
end

_99.setup({
  provider = _99.Providers.OpenCodeProvider,
  model = "openrouter/z-ai/glm-5.1",
  logger = {
    level = _99.DEBUG,
    path = "/tmp/" .. basename .. ".99.debug",
    print_on_error = true,
  },
  tmp_dir = "./tmp",

  completion = {
    -- cursor_rules = "<custom path to cursor rules>"
    custom_rules = {
      vim.fn.expand("~/.claude/skills/"),
    },
    files = {
      enabled = true,
      max_file_size = 102400,     -- bytes, skip files larger than this
      max_files = 5000,            -- cap on total discovered files
      exclude = { ".env", ".env.*", "node_modules", ".git", ... },
    },
    source = "blink",
  },

  md_files = {
    "CLAUDE.md",
  },
})

import { tool } from "@opencode-ai/plugin"
import { readFile } from "node:fs/promises"

const DD_SITE = process.env.DD_SITE || "datadoghq.com"

// Secrets come either directly from the environment or, on sops-managed
// hosts, from a file referenced by DD_API_KEY_FILE / DD_APP_KEY_FILE so the
// key material never sits in the environment of every process.
async function readSecret(name: string): Promise<string | undefined> {
  const direct = process.env[name]
  if (direct) return direct
  const file = process.env[`${name}_FILE`]
  if (!file) return undefined
  try {
    return (await readFile(file, "utf8")).trim()
  } catch {
    return undefined
  }
}

export default tool({
  description:
    "Search and query logs from Datadog. Use this to find logs by service, status, host, or custom queries using the Datadog log search syntax (same as the Datadog web UI).",
  args: {
    query: tool.schema
      .string()
      .describe(
        "The Datadog log search query. Supports full Datadog query syntax: field:value, boolean operators (AND/OR/NOT), wildcards (*), and more. Examples: 'service:myapp status:error', 'host:prod-* env:production', '@http.status_code:500'",
      ),
    from: tool.schema
      .string()
      .optional()
      .default("-1h")
      .describe(
        "Start time range. Supports relative times like '-1h', '-30m', '-7d', absolute UNIX timestamps in seconds, or ISO-8601 dates. Default: '-1h'.",
      ),
    to: tool.schema
      .string()
      .optional()
      .default("now")
      .describe(
        "End time range. Supports 'now', absolute UNIX timestamps in seconds, or ISO-8601 dates. Default: 'now'.",
      ),
    limit: tool.schema
      .number()
      .int()
      .min(1)
      .max(1000)
      .optional()
      .default(50)
      .describe("Max log events to return (1-1000). Default: 50."),
    sort: tool.schema
      .enum(["timestamp", "-timestamp"])
      .optional()
      .default("-timestamp")
      .describe(
        "Sort order: 'timestamp' for oldest first, '-timestamp' for newest first. Default: '-timestamp'.",
      ),
  },
  async execute(args) {
    const DD_API_KEY = await readSecret("DD_API_KEY")
    const DD_APP_KEY = await readSecret("DD_APP_KEY")
    if (!DD_API_KEY || !DD_APP_KEY) {
      const envDoc =
        "```\nDD_API_KEY=your-datadog-api-key        # or DD_API_KEY_FILE=/path/to/secret\nDD_APP_KEY=your-datadog-application-key  # or DD_APP_KEY_FILE=/path/to/secret\nDD_SITE=datadoghq.com  # optional, for EU: datadoghq.eu\n```"
      return `Datadog API keys are not configured in the environment.\n\nSet these environment variables before using this tool:\n${envDoc}\n\nFor details: https://docs.datadoghq.com/account_management/api-app-keys/`
    }

    const filter = {
      query: args.query,
      from: parseTimeRange(args.from!),
      to: parseTimeRange(args.to!),
    }

    const body: Record<string, unknown> = {
      filter,
      sort: args.sort,
      page: { limit: args.limit },
    }

    const url = `https://api.${DD_SITE}/api/v2/logs/events/search`

    let response: Response
    try {
      response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "DD-API-KEY": DD_API_KEY,
          "DD-APPLICATION-KEY": DD_APP_KEY,
        },
        body: JSON.stringify(body),
      })
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err)
      return `Failed to connect to Datadog API at ${url}: ${msg}`
    }

    if (!response.ok) {
      let errorBody = ""
      try {
        errorBody = await response.text()
      } catch {
        // ignore
      }
      if (response.status === 403) {
        return `Datadog API returned 403 Forbidden. Verify your DD_API_KEY and DD_APP_KEY have the correct permissions.\n\nDetails: ${errorBody}`
      }
      if (response.status === 429) {
        return `Datadog API rate limit exceeded (429). Wait a moment and try again.\n\nDetails: ${errorBody}`
      }
      return `Datadog API error (${response.status}):\nQuery: "${args.query}"\nResponse: ${errorBody}`
    }

    let data: any
    try {
      data = await response.json()
    } catch {
      return `Failed to parse Datadog API response.`
    }

    if (!data.data || data.data.length === 0) {
      return `No logs found matching: "${args.query}"\nTime range: ${filter.from} to ${filter.to}`
    }

    return formatResults(data, args.query!)
  },
})

function parseTimeRange(value: string): string {
  if (value === "now") {
    return new Date().toISOString()
  }

  const unitMs: Record<string, number> = {
    s: 1000,
    m: 60 * 1000,
    h: 60 * 60 * 1000,
    d: 24 * 60 * 60 * 1000,
    w: 7 * 24 * 60 * 60 * 1000,
  }
  const relMatch = value.match(/^-(\d+)(s|m|h|d|w)$/)
  if (relMatch) {
    const amount = parseInt(relMatch[1], 10)
    const ms = (unitMs[relMatch[2]] ?? 0) * amount
    return new Date(Date.now() - ms).toISOString()
  }

  const num = parseInt(value, 10)
  if (!isNaN(num) && num > 0) {
    return new Date(num * 1000).toISOString()
  }

  return value
}

function formatResults(data: any, query: string): string {
  const lines: string[] = []
  const events: any[] = data.data
  const totalCount = data.meta?.page?.totalCount ?? events.length
  const returnedCount = events.length

  lines.push(`Found ${totalCount} logs matching "${query}" (showing ${returnedCount}):`)
  lines.push("")

  for (let i = 0; i < events.length; i++) {
    const event = events[i]
    const attrs = event.attributes ?? {}
    const timestamp = attrs.timestamp ?? attrs["@timestamp"] ?? "unknown"
    const service = attrs.service ?? "unknown"
    const status = attrs.status ?? "none"
    const host = attrs.host ?? attrs.hostname ?? "unknown"
    const message = attrs.message ?? attrs.content ?? JSON.stringify(attrs)

    lines.push(`--- Log ${i + 1} ---`)
    lines.push(`  Time:    ${timestamp}`)
    lines.push(`  Service: ${service}`)
    lines.push(`  Status:  ${status}`)
    lines.push(`  Host:    ${host}`)
    lines.push(`  Message: ${truncate(String(message), 2000)}`)

    const tags: string[] = attrs.tags ?? []
    if (tags.length > 0) {
      lines.push(`  Tags:    ${tags.slice(0, 10).join(", ")}`)
    }

    const importantKeys = [
      "@http.status_code",
      "@http.method",
      "@http.url",
      "env",
      "version",
      "trace_id",
      "span_id",
    ]
    const extras: string[] = []
    for (const key of importantKeys) {
      if (attrs[key] !== undefined) {
        extras.push(`${key}=${attrs[key]}`)
      }
    }
    if (extras.length > 0) {
      lines.push(`  Extra:   ${extras.join(" ")}`)
    }

    lines.push("")
  }

  if (totalCount > returnedCount) {
    lines.push(
      `-- More logs available (${totalCount - returnedCount} remaining). Increase the limit or refine the query to see more.`,
    )
  }

  return lines.join("\n")
}

function truncate(s: string, maxLen: number): string {
  if (s.length <= maxLen) return s
  return s.slice(0, maxLen - 20) + "... [truncated]"
}

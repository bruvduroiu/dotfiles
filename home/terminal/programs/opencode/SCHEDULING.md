# Local scheduling in OpenCode and OpenWork

Both apps load the same pinned `different-ai/opencode-scheduler` plugin from
the shared OpenCode configuration. Restart the app after changing the plugin.
Use the chat tools; OpenWork's Cloud Automations screen is a separate service.

For example, in a workspace chat:

> Use schedule_job to create "morning-review" in this workspace. Every weekday
> at 09:00 (cron `0 9 * * 1-5`), review recent changes and write a short report
> to morning-review.md. Use model openai/gpt-6-astra and timeoutSeconds 600.
> Do not modify other files.

The model calls the tool and returns confirmation. Jobs run with the local
OpenCode CLI and its existing provider authentication. They can use the shared
agents, skills and MCP tools, including Playwright when browser work is requested.
Unattended work must have the permissions it needs; it cannot answer approval
dialogs. Browser work needs the relevant desktop/browser services available.

Useful follow-up requests:

| Request | Tool |
| --- | --- |
| List jobs in this workspace | `list_jobs` |
| List jobs across all workspaces | `list_jobs` with `allScopes: true` |
| Show morning-review's settings | `get_job` |
| Change morning-review to 10:30 weekdays | `update_job`, schedule `30 10 * * 1-5` |
| Run morning-review now | `run_job` |
| Show morning-review's output | `job_logs` |
| Remove morning-review | `delete_job` |

Manage a job from the workspace where it was created. Use unique, descriptive
names. For a job with a different working directory, open that directory as a
workspace to manage it. Avoid `cleanup_global` unless you intend to delete all
scheduler jobs across every workspace.

Cron uses five fields: minute, hour, day of month, month, day of week. Schedules
follow the host's local timezone (currently Asia/Taipei). `0 9 * * *` means daily
at 09:00; `*/30 * * * *` means every half hour; `0 18 * * 5` means Friday at 18:00.
This is a recurring cron scheduler, not a native one-shot alarm service. Delete
a job after its intended run if you only need it once.

The Nix configuration installs the plugin and runtime once. Creating, editing,
and deleting jobs changes mutable user files and needs no NixOS rebuild:

- Definitions: `~/.config/opencode/scheduler/scopes/<scope>/jobs/`
- Output: `~/.config/opencode/logs/scheduler/<scope>/`
- Run history: `~/.config/opencode/scheduler/scopes/<scope>/runs/`
- Units: `~/.config/systemd/user/opencode-job-*.{service,timer}`

Jobs execute through user systemd timers, so the chat app can be closed. The
machine must be awake and the user service manager running. Persistent timers
catch up a missed occurrence when available again; they do not replay every
missed interval. Results are in job logs and standalone OpenCode sessions;
OpenWork's v2 engine shares the normal OpenCode database and credentials.

Inspect the timers directly with:

```sh
systemctl --user list-timers 'opencode-job-*'
```

Local patches support NixOS runtime paths, OpenCode v1/v2 plugin APIs, v2 CLI
arguments, valid systemd calendars, per-workspace lookup, and safe unit fields.
Use prompt-based jobs; legacy command/port/share options are rejected.

# Google Jules Plugin for Antigravity

An Antigravity plugin that integrates the **Google Jules CLI** (`jules`) as a skill and delegatable subagent workflow.

## Features

- **Automatic Authentication & Repo Preflight**: Detects whether `jules` is installed, whether your Google OAuth session is active (prompting you to run `jules login` if expired), and whether your current GitHub repository is connected to Jules.
- **Task Delegation (`skills/jules/SKILL.md`)**: Guides Antigravity (or a spawned subagent) through formulating self-contained prompts, dispatching single or parallel remote sessions (`jules new --repo <owner>/<repo>`), and tracking Session IDs.
- **Non-Blocking Session Monitoring (`agents/jules-delegate.md`)**: Uses Antigravity's native `schedule` timer tool to poll `jules remote list --session` in the background without blocking your main conversation.
- **Safe Patch Inspection & Application**: Previews remote patches via `jules remote pull --session <id>` and applies/verifies them via `jules remote pull --session <id> --apply` or `jules teleport <id>`.

## Prerequisites

1. Install the Google Jules CLI (`jules` available on your `PATH`).
2. Authenticate once in your terminal:
   ```bash
   jules login
   ```
3. Ensure your target GitHub repositories are connected to your Jules account (`jules remote list --repo`).

## Installation

Clone this repository into your Antigravity global plugins directory:

```bash
git clone https://github.com/daniazar/antigravity-jules-plugin.git ~/.gemini/config/plugins/jules
```

Restart Antigravity (or reload the window) so the new plugin directory is discovered.

## Directory Structure

```text
jules/
├── plugin.json                        # Plugin manifest
├── README.md                          # Documentation
├── assets/
│   └── logo.svg                       # Plugin icon
├── agents/
│   └── jules-delegate.md              # Subagent profile for async Jules delegation
└── skills/
    └── jules/
        ├── SKILL.md                   # Core workflow instructions & auth checks
        └── scripts/
            ├── check-jules.ps1        # Windows PowerShell preflight & auth check
            └── check-jules.sh         # macOS/Linux Bash preflight & auth check
```

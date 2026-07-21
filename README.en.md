# Stata MCP — Claude inside your live Stata session

> 한국어 문서: [README.md](README.md)

Connect **Stata** and **Claude** via MCP (Model Context Protocol). The primary environment is **Claude Desktop cowork**. This is the public distribution repository — it ships the built binaries and user docs; the source code is private.

> **Want to cowork with Stata + Claude?** Get in touch — **mhjung0822@gmail.com**. A license key is required and issued on request.

## Why this one

Existing Stata MCP servers are built on **pystata**: they spin up a separate, headless Stata instance inside a Python process, disconnected from the Stata you actually see. This tool takes the opposite approach — it runs **inside the Stata GUI session you already have open** (via Stata's Java integration). Claude works in *your* session, not a shadow copy.

**One session, shared with you:**

- Claude sees the **data you have in memory** and the graphs you drew; its commands and results appear in **your own Results window** and command history.
- **Push from Stata**: `llm push > command` sends any output from your Stata session straight to Claude — the conversation flows both ways.
- **Async execution**: fire a long-running job in the background and keep the conversation going; Claude picks up the results when they are ready, and you watch the progress live in your own Results window. A headless blocking call can't do either.
- **Graphs as structure, not screenshots**: graph specs and data are extracted so Claude can read what is actually plotted — and rebuild it as an interactive D3/HTML chart.
- **Built-in help database**: Claude looks up official Stata syntax on demand instead of guessing from memory.
- **No second Stata instance** — nothing extra to license or keep in sync.

**Built for Stata users, not just developers:**

- **No Python.** Installation is one `net install` line inside Stata; updates come through `adoupdate`. Java is the only prerequisite on the Stata side.
- **A GUI control panel inside Stata** (`db mcp`): start/stop the server, edit settings, and update the help DB by clicking, not from a terminal. The server lives inside Stata and shuts down with it — no orphan processes to manage.
- **Any MCP client.** The server speaks standard MCP Streamable HTTP — Claude Desktop (cowork or chat), Claude Code, and other MCP hosts all connect. The Desktop extension and skill pack are convenience packaging on top, so researchers who never open a code editor can use it too.

The goal is **two interfaces to one session**. Claude does not replace the Stata GUI — you keep using menus, the command window, and the do-file editor as usual, while Claude works alongside in the very same session. Drive the analysis from whichever side is faster at the moment, and hand results back and forth (`llm push` from Stata to Claude, MCP from Claude to Stata).

## Quick start

**1. Install the Stata side** — one line in Stata:

```stata
net install stata-mcp, ///
    from("https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release") ///
    replace
```

Then run once:

```stata
mcp_setup            // downloads the help DB (~32 MB) + registers the User menu
```

**2. License key** *(required)* — request a key at **mhjung0822@gmail.com**, then in Stata:

```stata
mcp_edit_license     // opens the properties file in an editor
```

Paste the key between the quotes of `LICENSE_KEY=""`, save, and apply with `mcp_connect, reset` (no Stata restart needed).

**3. Start the server** — in Stata:

```stata
mcp_connect          // starts the MCP server; stops automatically when Stata exits
```

**4. Register in Claude Desktop (cowork)** — two files:

- **MCP connection** *(required)*: download the one matching your OS — [`stata-mcp-mac.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-mac.mcpb) / [`stata-mcp-win.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-win.mcpb) → **Settings → Extensions → Install from file**, then restart Claude Desktop.
- **Skills** *(recommended)*: [`stata-skills-all.zip`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-skills-all.zip) → **Settings → Skills → Upload**. Upload once; it syncs to every device on the same account. Includes 9 slash commands (`/stata-exec`, `/stata-help`, …), an editable working-style instruction skill, and a panel-merge skill.

## Requirements

| Item | Version |
|---|---|
| Java | 17+ — [Oracle JDK 17](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) |
| Node.js | 20+ — [nodejs.org](https://nodejs.org/) (used by the Claude Desktop extension) |
| Stata | 17+ (19 recommended) |
| Claude Desktop | latest — [download](https://claude.ai/download) |

## Guides

The full step-by-step guides are currently in Korean — [INSTALL.md](INSTALL.md) (install), [USAGE.md](USAGE.md) (usage & troubleshooting), [INSTALL_CHAT.md](INSTALL_CHAT.md) (chat-only environments without cowork). They are command-centric, so they are easy to follow with any translator — or simply ask Claude to walk you through them.

## License

Copyright (c) 2026 mhjung0822. A license key is required to run the software — contact **mhjung0822@gmail.com**.

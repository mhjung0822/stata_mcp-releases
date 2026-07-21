# Installation Guide

> 한국어 문서: [INSTALL.md](INSTALL.md)

Installation is four steps: **① Stata-side install → ② License → ③ Start the server → ④ Register in Claude (extension + skills)**.
The primary environment is **Claude Desktop cowork**.

> ⚠️ **If cowork is not available in your environment** — the extension in step 4-1 is cowork-only.
> To use it in plain chat, register the config file as described in [INSTALL_CHAT.md](INSTALL_CHAT.md) (Korean).
> (The skill upload in 4-2 applies to both.)

For the list of distributed files see [README.en.md](README.en.md); for usage and troubleshooting after install see [USAGE.en.md](USAGE.en.md).

---

## 1. Prerequisites

| Item | Version |
|------|------|
| Java | 17+ — [Oracle JDK 17 download](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) |
| Stata | 17+ (19 recommended) |
| Claude Desktop | latest — [download](https://claude.ai/download) |
| Node.js | v20+ — [nodejs.org download](https://nodejs.org/) |

---

## 2. Stata-side install

One line in Stata:

```stata
net install stata-mcp, ///
    from("https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release") ///
    replace
```

This downloads the two jars plus the ado/dlg files. Then run **`mcp_setup`** once to download the help DB and register the control-panel menu:

```stata
mcp_setup            // downloads the help DB (~32 MB) + registers the User menu
```

> The help DB is large, so it is not bundled with `net install`; `mcp_setup` downloads it on demand (keeps the package light). Internet connection required.

To update later:

```stata
adoupdate stata-mcp, update
mcp_setup, updatedb   // refresh the help DB too (same as the control panel's [Update help DB] button)
```

> ⚠️ A trailing `/` on the URL causes an "is not a Stata download site" error — use the form above exactly, no trailing slash.

### License key (required)

A key is required for the software to run (to request one: mhjung0822@gmail.com). After installing, in Stata:

```stata
mcp_edit_license          // opens stata_mcp.properties (next to the jar) in an editor
```

Paste the key between the quotes of `LICENSE_KEY=""` in the opened file, save, then apply immediately with `mcp_connect, reset` (no Stata restart needed).

- If the key is missing or expired, neither the drone nor the server starts, and the reason is printed in the Results window
- Validation requires an internet connection (offline grace period: up to 72 hours)

> To change the ports (default 8080/8001), edit `BRIDGE_PORT`/`DRONE_PORT` in `stata_mcp.properties` next to the jar — the file is created automatically on first start.

---

## 3. Start the server

```stata
mcp_connect          // starts the MCP server + drone in one go
```

> The server shuts down automatically when you quit Stata. You can also start it from the GUI control panel (`db mcp`) — see [USAGE.en.md](USAGE.en.md).

---

## 4. Register in Claude (cowork)

> **If cowork won't activate on Windows** — the "Virtual Machine Platform" Windows
> feature is required. In an **administrator PowerShell**, enter the line below,
> then **reboot**:
>
> ```powershell
> Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
> ```
>
> After rebooting, enable cowork in Claude Desktop. If it still doesn't work,
> hardware virtualization (Intel VT-x / AMD SVM) is disabled in your BIOS —
> you can check it under Task Manager → Performance → CPU → "Virtualization".

### 4-1. Install the extension (MCP connection)

1. Download the **one** file matching your OS:
   - Mac: [`stata-mcp-mac.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-mac.mcpb)
   - Windows: [`stata-mcp-win.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-win.mcpb)
2. Claude Desktop → **Settings → Extensions** → **Install from file** → select the downloaded `.mcpb`
3. Restart Claude Desktop

> The server from step 3 (`mcp_connect`) must be running for the tools to work. To update, install the new `.mcpb` file from the same screen.

### 4-2. Register the skills (slash commands)

1. [Download `stata-skills-all.zip`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-skills-all.zip)
2. Claude Desktop → **Settings → Skills** → Upload → select the downloaded zip
3. Upload once and it applies automatically to every device on the same account

Included skills:

- **9 slash commands** — `/stata-exec` `/stata-async` `/stata-pull` `/stata-help` `/stata-setup` `/stata-graph-get` `/stata-graph-export` `/stata-data-context` `/stata-data-fullcontext`
- **stata-instruction** (meant to be edited) — applies your output-format / analysis rules / preferences to the session. Edit it in its options after installing (or ask Claude to modify it)
- **stata-panel-merge** — a standard procedure for combining wave-by-wave .dta files into a long panel. Triggered by natural language like "merge the waves / build the panel"

---

## 5. Next steps

[USAGE.en.md](USAGE.en.md) — startup order, control panel, push notifications, help lookup, troubleshooting.

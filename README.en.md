# Stata MCP — Stata × Claude

> 한국어: [README.md](README.md)

Public **distribution repository** for a tool that connects Stata and Claude via MCP (Model Context Protocol). The primary environment is **Claude Desktop cowork**. The source code is private; this repository provides built artifacts and user documentation only.

Installation is four steps: **① Stata-side install → ② License → ③ Start the server → ④ Register in Claude (extension + skills)**.

> The single extension in step 4-1 works for **both cowork and chat**. Use the manual
> registration in [INSTALL_CHAT.md](INSTALL_CHAT.md) (Korean) only if the extension does
> not appear in your tools list. (The skill upload in 4-2 applies to both.)

For usage and troubleshooting after install see [USAGE.en.md](USAGE.en.md).

---

## 1. Prerequisites

| Item | Version |
|------|------|
| Java | No separate install needed — Stata's bundled Java is used (Stata 17 ships an older bundle, so install [JDK 17+](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) there) |
| Stata | 17+ (19 recommended) |
| Claude Desktop | latest — [download](https://claude.ai/download) |
| Node.js | Not needed with the extension (mcpb). Only required for manual config registration ([INSTALL_CHAT.md](INSTALL_CHAT.md)) |

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

> To apply an update, **restart Stata** and reconnect with `mcp_connect`.

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

> ⚠️ **If a red `java.lang.UnsupportedClassVersionError` appears and the drone won't start** — Stata's bundled Java is outdated. Run `update all` in Stata, **restart Stata**, then run `mcp_connect` again. Details in the troubleshooting section of [USAGE.en.md](USAGE.en.md).

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
>
> **To check the current state** — in cmd:
>
> ```
> systeminfo | findstr Hyper
> ```
>
> - A single line saying `A hypervisor has been detected` → ready (virtualization is not the problem)
> - `Virtualization Enabled In Firmware: No` → enable VT-x/SVM in your BIOS
> - All `Yes` but no "detected" line → you haven't rebooted yet

### 4-1. Install the extension (MCP connection)

1. Download the **one** file matching your OS:
   - Mac: [`stata-mcp-mac.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-mac.mcpb)
   - Windows: [`stata-mcp-win.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-win.mcpb)
2. Claude Desktop → **Settings → Extensions** → **Install from file** → select the downloaded `.mcpb`
3. Restart Claude Desktop

> The server from step 3 (`mcp_connect`) must be running for the tools to work. To update, install the new `.mcpb` file from the same screen.

### 4-2. Register the skills (slash commands)

1. [Download `stata-skills-all-en.zip`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-skills-all-en.zip) (individual skills: `claude-plugins/skill-zips-en/`)
2. **Unzip it** — you get 11 per-skill zips
3. Claude Desktop → **Settings → Skills** → Upload → upload the extracted **per-skill zips** (do not upload the bundle zip itself)
4. Upload once and it applies automatically to every device on the same account

> A Korean edition also exists (`stata-skills-all.zip`). The skills share names across the two packs, so install only one language pack per account.

Included skills:

- **9 slash commands** — `/stata-exec` `/stata-async` `/stata-pull` `/stata-help` `/stata-setup` `/stata-graph-get` `/stata-graph-export` `/stata-data-context` `/stata-data-fullcontext`
- **stata-instruction** (meant to be edited) — applies your output-format / analysis rules / preferences to the session. Edit it in its options after installing (or ask Claude to modify it)
- **stata-panel-merge** — a standard procedure for combining wave-by-wave .dta files into a long panel. Triggered by natural language like "merge the waves / build the panel"

---

## 5. Next steps

[USAGE.en.md](USAGE.en.md) — startup order, control panel, push notifications, help lookup, troubleshooting.


---

## License

Copyright (c) 2026 mhjung0822.

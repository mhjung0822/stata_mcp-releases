# Stata MCP — Stata × Claude

> 한국어: [README.md](README.md)

Public **distribution repository** for a tool that connects Stata and Claude via MCP (Model Context Protocol). The primary environment is **Claude Desktop (chat and cowork)**. The source code is private; this repository provides built artifacts and user documentation only.

Installation is four steps: **① Stata-side install → ② License → ③ Start the server → ④ Register in Claude (extension + skills)**.

For usage and troubleshooting after install see [USAGE.en.md](USAGE.en.md).

---

## 1. Prerequisites

| Item | Version |
|------|------|
| Stata | 17+ (19 recommended) |
| Claude Desktop | latest — [download](https://claude.ai/download) |

---

## 2. Stata-side install

One line in Stata:

```stata
net install stata-mcp, from("https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release") replace
```

This downloads the two jars plus the ado/dlg files. Then run **`mcp_setup`** once to download the help DB and register the control-panel menu:

```stata
mcp_setup
```

> The help DB is large, so it is not bundled with `net install`; `mcp_setup` downloads it on demand (keeps the package light). Internet connection required.

To update later:

```stata
adoupdate stata-mcp, update
mcp_setup, updatedb
```

- `mcp_setup, updatedb` — refreshes the help DB too (same as the control panel's [Update help DB] button)

> To apply an update, **restart Stata** and reconnect with `mcp_connect`.

### License key (required)

A key is required for the software to run (to request one: mhjung0822@gmail.com). After installing, in Stata:

```stata
mcp_set_license
```

At the prompt, paste the key you received and press Enter — done. (The **License** field of the control panel `db mcp` + **Save** works too.) Replacing a key works the same way — after replacing, apply immediately with `mcp_connect, reset` (no Stata restart needed).

- If the key is missing or expired, neither the drone nor the server starts, and the reason is printed in the Results window
- Validation requires an internet connection (offline grace period: up to 72 hours)

> To change the ports (default 8080/8001), edit `BRIDGE_PORT`/`DRONE_PORT` in `stata_mcp.properties` next to the jar — the file is created automatically on first start.

---

## 3. Start the server

```stata
mcp_connect
```

Starts the MCP server and the drone in one go.

> The server shuts down automatically when you quit Stata. You can also start it from the GUI control panel (`db mcp`) — see [USAGE.en.md](USAGE.en.md).

> ⚠️ **If a red `java.lang.UnsupportedClassVersionError` appears and the drone won't start** — Stata's bundled Java is outdated. Run `update all` in Stata, **restart Stata**, then run `mcp_connect` again. Details in the troubleshooting section of [USAGE.en.md](USAGE.en.md).

---

## 4. Register in Claude (cowork)

> For environment issues such as cowork not activating on Windows, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) (Korean).

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

For the skill lineup and usage, see [USAGE.en.md](USAGE.en.md).

---

## 5. Connection test

Start with both Stata and Claude Desktop **fully quit** — closing the Claude window
leaves it running in the background, so quit via the tray icon → **Quit** on Windows,
or **⌘Q** on Mac. Then start them in this order:

```
1. Start Stata → run mcp_connect
2. Start Claude Desktop
```

Then, in a new chat (or cowork session):

```
What Stata version am I running?
```

If the version and edition come back (e.g. StataNow/MP 19.5), the installation is complete.

If not, check in order:

1. Stata Results window — does the `mcp_connect` output say `License OK`? (if not, see step 2, License)
2. Claude tools list — is the Stata MCP extension visible? (if not, fully quit and relaunch Claude Desktop)

For everyday usage see [USAGE.en.md](USAGE.en.md) — startup order, control panel, push notifications, help lookup, troubleshooting. Rare environment issues: [TROUBLESHOOTING.md](TROUBLESHOOTING.md) (Korean).


---

## License

Copyright (c) 2026 mhjung0822.

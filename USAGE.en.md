# Usage Guide

> 한국어 문서: [USAGE.md](USAGE.md)

For installation, see [README.en.md](README.en.md).

---

## 1. Standard startup order

```
1. Start Stata → mcp_connect (server + drone in one go)
2. Start Claude Desktop
3. Toggle cowork mode ON
```

From there, ask for Stata work in the chat, or send results from Stata to Claude with `llm push`.

### Control panel (GUI) — buttons instead of commands

Type `mcp` (= `db mcp`) in Stata to open the control-panel dialog — connect / restart / shutdown, server status (including version and license expiry), auto-shutdown settings, license key entry, help-DB update, and uninstall, all as buttons.

```stata
mcp
mcp_setup
```

- `mcp` (= `db mcp`) — control-panel dialog
- `mcp_setup` — setup menu + help-DB download (links for license / start / uninstall)

> Menu-bar registration (User ▸ Stata-MCP) is handled by `mcp_setup`. If the menu
> is missing on the next launch, run `mcp_menu, install` and follow the printed instructions.

> To enter or replace the license key, paste it into the control panel's **License** field and click **Save**, then reconnect as prompted. The **Edit license / properties** button (direct file editing) and `mcp_setup` work too.

**Auto-shutdown** — when you quit Stata, the server cleans itself up shortly after.
Use the control panel's Auto-shutdown group to turn this off (keep the server running)
or adjust the wait time, or use the command:

```stata
mcp_watchdog, grace(120)
mcp_watchdog, enabled(0)
```

- `grace(120)` — clean up the server 120 s after Stata quits
- `enabled(0)` — disable auto-cleanup (server stays after Stata quits)

> If you restart Stata and reconnect within the wait time, the server carries on without dropping the connection.

**Full uninstall**:

```stata
mcp_uninstall
```

- `mcp_uninstall` — preview (deletes nothing): lists targets + a confirm link
- `mcp_uninstall, confirm` — removes ado/dlg/jar + menu registration (keeps license/instructions)
- `mcp_uninstall, confirm all` — also removes the license key and instruction data

> The **Uninstall** button in the control panel (`db mcp`) runs the preview (first line above) as well.

---

## 2. Commands / Push

### 2-1. Requesting commands

Ask for Stata work in plain language in the chat:

```
Load the auto dataset and regress price on mpg and weight
```

Claude then works through this flow:
1. Calls the `executeStata` tool → runs `sysuse auto, clear` / `regress price mpg weight` etc.
2. Receives the Stata results (output, r()/e(), graphs) and shows them in the chat
3. For graph commands the response includes `graphDrawn: true` — when an image is needed, Claude calls `exportGraph` → creates `c(pwd)/g_yyyyMMddHHmm_xxxx.png` and returns `graphPath` (absolute) and `graphFilename` (shown automatically when the cowork panel monitors the working folder)
4. Follow-up questions/instructions are welcome (e.g. "plot the residuals too")

Responses include `rc` (Stata return code, 0 = success), so Claude can tell success from failure immediately; on a syntax error it checks the syntax itself via `getHelp` and retries.

### 2-1b. Long-running commands (async) — set it running and keep talking

For slow commands like bootstrap / simulate / mi impute, Claude uses `executeStataAsync`:

```
Run a 300,000-rep bootstrap → (immediately) "Started. Feel free to do other things while it runs."
   ... chat freely in the meantime (model questions, writing, planning the next analysis) ...
Done → the full results arrive as a push (notification) → "show me the results" → table + interpretation
```

- Other Stata commands during the run get an immediate `busy` response (no waiting, chat never blocks)
- The completed result (full output + `rc` + elapsed time) is delivered to the push store — retrieved via `getPushResults`
- Stored r()/e() results are preserved exactly as in a normal run (query with `getMacro("e(b)")` etc.)
- One job at a time (the Stata engine is single-threaded)

### 2-2. Push from the Stata GUI (both directions)

Analyze directly in the Stata GUI, then send the results to Claude:

```stata
sysuse auto, clear
regress price mpg weight
llm push
```

Variants:

- `llm push` — pushes r()/e() (added to the store + instant notification)
- `llm push > regress price mpg weight` — runs the command after `>`, pushes the output screen + r()/e()
- `llm push, note(main spec for slides) > regress ..., robust` — attaches a note in plain language (easy to find later)
- `llm push, clear` — clears unread items and pushes fresh (cleanup)

- `llm push` **stores** the result and notifies Claude instantly
- Claude picks up unread items one by one — push several times in a row and they accumulate in order

#### The push store — reading does not delete

Retrieved results are not deleted, only **marked as read**. Everything is kept for the session and can be recalled in plain language:

```
"Show me that bootstrap result again"        → found in the history (table of contents) and re-fetched
"Find the ones I ran with robust"            → keyword search over commands, output, and notes
"Tag result #3 with a 'final spec' note"     → attaches a note (searchable)
"Save all results so far to a file"          → writes a snapshot file in the working folder
"Load the file I saved yesterday"            → reloads the snapshot (continue where you left off)
```

- Results are auto-saved even after the session ends — quit in a hurry and pick up next session
- If the server is briefly down, results are kept and delivered later (nothing is lost)

> If the notification doesn't appear on its own, just say **"check the push results"** in the chat.

### 2-3. Graphs / saved files

| Kind | Where it goes |
|---|---|
| Graphs | `g_...png` in the current working folder (created only when an image is needed — not auto-saved) |
| Saved files (`save`/`export` etc.) | exactly the path you specified in Stata |

### 2-4. Help / environment lookup

Tools Claude uses to check Stata syntax on its own — you rarely call them yourself, but they respond to plain language too:

```
"What options does xtreg have?"              → getHelp("xtreg") — overview slice (model list + drill-down keys)
"Details on the vce option of xtreg fe"      → getHelp("xtreg","fe.vce") — just that option's detail (cascading drill-down)
"What command is su again?"                  → abbreviations resolved automatically (su→summarize, standard Stata rules)
"Find commands about cluster-robust errors"  → local keyword search → candidate commands + one-line descriptions
"Show the Stata environment/version"         → getStataEnv — 8 essentials: version, edition (BE/SE/MP), OS, install paths
```

- Help comes from an ontology DB (4,464 nodes) that returns **only the slice you need, cascading down** — the default call is an overview (a few hundred tokens); use a `selector` to descend to a model (`fe`), option group (`fe.se`), option detail (`fe.vce`), `examples`, `stored`, `post.predict`, etc. An invalid selector returns the list of valid selectors for that command. See the `/stata-help` skill for the full syntax
- The DB is downloaded by `mcp_setup`, so lookups **answer instantly even while a long command is running**, with no internet needed at query time
- Help for community packages (SSC etc.) works too, if installed — use the full command name
- Refresh the help DB with `mcp_setup, updatedb` (or the control panel's [Update help DB]) — it is regenerated on the distribution side to track Stata updates

### 2-5. Slash-command skills

Start your session with `/stata-setup` — it checks the environment and working folder and loads your working instructions (output format etc.).

The rest, as needed:

- `/stata-exec command` — run exactly as given, no edits or inference
- `/stata-async command` — fire off long jobs (~30s+) and keep talking → collect on completion with `/stata-pull` (search with `history keyword`; reading preserves items)
- `/stata-pull` — fetch results you pushed from the Stata window with `llm push > command`
- `/stata-help command` — check syntax. When Claude misuses an option, this corrects it (`xtreg` → `xtreg fe` → `xtreg fe.vce`, cascading)
- `/stata-data-context` — resynchronize when Claude's picture of the data is stale (you changed the data in the Stata window). For a full profile use `/stata-data-fullcontext` (+ codebook)
- `/stata-graph-export` — save the current graph as a PNG in the working folder / `/stata-graph-get` — inspect the graph spec

The working instructions (`stata-instruction`) can be edited to change output formats and analysis rules. Panel merging responds to plain language like "merge the waves".

**Natural language vs skills — same job, two styles**

| What you want | In plain language | With a skill | Notes |
|---|---|---|---|
| Open data | "Open the auto dataset" | `/stata-exec sysuse auto` | If you know the exact command,<br>the skill is faster and precise |
| Run a test | "Test for heteroskedasticity" | `/stata-exec estat hettest` | Plain language if you want interpretation,<br>skill if you just want the output |
| Long-running job | "Run a 5000-rep bootstrap" | `/stata-async bootstrap, reps(5000):`<br>`regress price mpg weight foreign` | exec blocks the chat to the end —<br>go async from the start if it's long |
| Check syntax/options | "What vce options are there?" | `/stata-help xtreg fe.vce` | When Claude misuses an option,<br>make it read the original help |
| Collect results | "Get the result I just pushed" | `/stata-pull` | search with `history keyword`,<br>re-fetch with `<id>` |
| Fix stale data picture | "Re-check the current data" | `/stata-data-context` | After changing data in the Stata window,<br>the skill makes it certain |
| Save a graph | "Save the graph as a PNG" | `/stata-graph-export` | exports the current graph<br>to the working folder immediately |

In short: **plain language = your request is interpreted and routed to the right tool or skill** / **a skill = the intended action, performed verbatim**.

### 2-6. Shutting down

#### Full shutdown (server + drone)

```stata
mcp_connect, shutdown
```

Stops both the server and the drone (same as the control panel's [Shutdown] button).

#### Automatic shutdown

When you quit Stata, the server also cleans itself up shortly after (detection ~10 s + grace, 30 s by default). Restart Stata within the grace window and the server carries on — see the Auto-shutdown section above.

> To stop only the server, `mcp_server, stop` also works.

---

## 3. Working-folder (pwd) change detection

If you move the working folder with `cd` in Stata, Claude notices automatically and asks whether to revert or keep the new folder. Write your preferred handling into the working instructions (`stata-instruction`) and it is applied automatically every time.

---

## 4. Troubleshooting

### First-run MCP server approval

The first time you use a new MCP server, an **approval prompt** appears (`Trust this MCP server?` / `Approve` and the like). Tools only work after you approve; once approved, it's automatic afterwards.

### License key problems

Symptom: on `mcp_connect` the drone does not start and a message like this is printed:

```
[Drone] License expired on YYYY-MM-DD. To renew: ...
[Drone] Not starting the drone; shutting down the MCP server as well. Enter a key: mcp_edit_license → save, then mcp_connect, reset
```

| Message | Cause / action |
|---|---|
| License key missing | Open the properties with `mcp_edit_license` and paste your issued key between the quotes of `LICENSE_KEY=""` |
| License key invalid | The key was truncated or altered when copied — paste the full key again |
| License expired | Request a new key and replace it |
| Internet connection required | Validation needs network time (offline longer than 72 hours). Reconnect, then `mcp_connect, reset` |
| Key format is a newer version | Update with `net install stata-mcp, ... replace` |

After replacing the key, `mcp_connect, reset` alone applies it (no Stata restart). Starting 7 days before expiry, `mcp_connect` shows the days remaining.

### UnsupportedClassVersionError on mcp_connect (drone won't start)

Symptom: `mcp_connect` prints this error in red:

```
java.lang.UnsupportedClassVersionError: ... has been compiled by a more recent
version of the Java Runtime (class file version 61.0), this version of the
Java Runtime only recognizes class file versions up to 55.0
```

Stata's bundled Java is outdated. Update Stata to the latest revision:

```stata
update all
```

After updating, **restart Stata** → run `mcp_connect` again.

> If updating is not an option (site licenses etc.), install JDK 17 and point Stata at it with `java set home` — see `help java`. Check the current Java with `java query`.

### When it won't connect

- Run `mcp_connect` again in Stata (reconnects the drone)
- If the server is down, restart it with `mcp_server`
- Check status with the **Server status** button in the control panel (`db mcp`)

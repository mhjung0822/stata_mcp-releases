*! mcp_find_server  v0.1.0  17may2026
*!
*! Locate stata-mcp-server.jar bundled inside the installed Claude Desktop
*! extension (.dxt). Returns r(path) — the absolute path to the jar.
*!
*! Lookup order:
*!   macOS:   ~/Library/Application Support/Claude/Claude Extensions/
*!   Windows: %APPDATA%/Claude/Claude Extensions/
*!
*! The .dxt extracts into a subfolder (typically `local.dxt.<author>.stata-mcp/`)
*! and the jar sits at `<that>/server/stata-mcp-server.jar`. We shell out to
*! `find` (macOS/Linux) or `where /r` (Windows) because Stata has no native
*! recursive file search.
*!
*! Usage:
*!   mcp_find_server
*!   local jar = r(path)
*!   shell java -jar "`jar'" >/dev/null 2>&1 &

program mcp_find_server, rclass
    version 17

    * ─── 1. OS 별 Claude Extensions base 경로 ──────────────────────────────
    if "`c(os)'" == "MacOSX" {
        local base `"`c(home)'/Library/Application Support/Claude/Claude Extensions"'
        local find_cmd `"find "`base'" -name 'stata-mcp-server.jar' -type f"'
    }
    else if "`c(os)'" == "Windows" {
        local appdata : env APPDATA
        if "`appdata'" == "" {
            di as error "mcp_find_server: %APPDATA% environment variable not set"
            exit 198
        }
        local base `"`appdata'\Claude\Claude Extensions"'
        local find_cmd `"where /r "`base'" stata-mcp-server.jar"'
    }
    else {
        di as error "mcp_find_server: unsupported OS (`c(os)')"
        exit 198
    }

    * ─── 2. base 존재 확인 ─────────────────────────────────────────────────
    capture confirm file `"`base'"'
    if _rc {
        di as error "Claude Extensions dir not found: `base'"
        di as error "Install stata-mcp.dxt in Claude Desktop first."
        exit 601
    }

    * ─── 3. recursive search → tempfile ────────────────────────────────────
    tempfile out
    if "`c(os)'" == "Windows" {
        shell `find_cmd' > "`out'" 2>nul
    }
    else {
        shell `find_cmd' 2>/dev/null > "`out'"
    }

    * ─── 4. 첫 매치 읽기 ───────────────────────────────────────────────────
    tempname fh
    capture file open `fh' using `"`out'"', read text
    if _rc {
        di as error "mcp_find_server: failed to read search result"
        exit 602
    }
    file read `fh' line
    capture file close `fh'

    if `"`line'"' == "" {
        di as error "stata-mcp-server.jar not found under: `base'"
        di as error "Install stata-mcp.dxt in Claude Desktop first."
        exit 601
    }

    * ─── 5. return ─────────────────────────────────────────────────────────
    return local path `"`line'"'
    di as text "Found jar: " as result `"`line'"'
end

*! mcp_server  v0.1.0  17may2026
*!
*! Start / check / stop stata-mcp-server.jar located in the Stata
*! PERSONAL ado folder (resolved via `findfile`, so no path argument
*! is needed).
*!
*! Usage:
*!   mcp_server                    // detached background spawn (default)
*!   mcp_server, status            // GET http://127.0.0.1:<port>/status
*!   mcp_server, stop              // terminate any java process running the jar
*!   mcp_server, bridgeport(8090)  // override status check port (default 8080)
*!
*! Notes:
*! - On macOS/Linux uses `shell ... &` (detached background).
*! - On Windows uses `winexec` (asynchronous spawn).
*! - Server lifecycle is independent of Stata once spawned — kill explicitly
*!   via `mcp_server, stop` or `taskkill` / `pkill`.

cap program drop mcp_server
program mcp_server
    version 17.0
    syntax [, STATUS STOP BRIDGEPORT(integer 8080)]

    * ─── stop ──────────────────────────────────────────────────────────────
    if "`stop'" != "" {
        di as text "[Server] terminating stata-mcp-server.jar process..."
        if "`c(os)'" == "Windows" {
            shell taskkill /F /IM java.exe /FI "WINDOWTITLE eq *stata-mcp-server*"
        }
        else {
            shell pkill -f stata-mcp-server.jar
        }
        exit
    }

    * ─── status ────────────────────────────────────────────────────────────
    if "`status'" != "" {
        di as text "[Server] GET http://127.0.0.1:`bridgeport'/status"
        shell curl -s --max-time 2 http://127.0.0.1:`bridgeport'/status
        exit
    }

    * ─── start (default) ───────────────────────────────────────────────────
    capture findfile stata-mcp-server.jar
    if _rc {
        di as error "mcp_server: stata-mcp-server.jar not found in adopath"
        di as error "Copy it to your PERSONAL ado folder (see INSTALL.md section 3)"
        di as error "Current adopath:"
        adopath
        exit 601
    }
    local jar `"`r(fn)'"'

    di as text "[Server] starting: " as result `"`jar'"'
    if "`c(os)'" == "Windows" {
        winexec java -jar `"`jar'"'
    }
    else {
        shell java -jar `"`jar'"' >/dev/null 2>&1 &
    }
    di as text "[Server] spawned (detached). 확인: " ///
        as result `"mcp_server, status"'
end

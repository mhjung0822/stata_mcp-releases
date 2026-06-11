*! mcp_server  v0.2.1  11jun2026
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
*! - On macOS/Linux uses `shell bash -c "... & disown"` — wrapping in bash
*!   with disown is required because Stata itself runs on a JVM, so plain
*!   `shell java ...` binds the new JVM into Stata's JVM hierarchy and the
*!   server cannot run independently. Disowning re-parents java to launchd.
*! - On Windows uses `winexec` (asynchronous CreateProcess — no JVM
*!   hierarchy issue).
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
    * 멱등성: 이미 떠있으면 spawn skip (port 8080 점유 → 새 JVM 이 BindException
    * 으로 죽으면서 server-logs/ 에 잡음 쌓이는 거 방지)
    tempfile chk
    capture shell curl -s --max-time 1 http://127.0.0.1:`bridgeport'/status > "`chk'" 2>/dev/null
    tempname fh
    capture file open `fh' using "`chk'", read text
    if !_rc {
        file read `fh' line
        capture file close `fh'
        if strpos(`"`line'"', "running") > 0 {
            di as text "[Server] already running on port `bridgeport' — skip spawn"
            exit
        }
    }

    capture findfile stata-mcp-server.jar
    if _rc {
        di as error "mcp_server: stata-mcp-server.jar not found in adopath"
        di as error "Copy it to your PERSONAL ado folder (see INSTALL.md section 3)"
        di as error "Current adopath:"
        adopath
        exit 601
    }
    local jar "`r(fn)'"

    if "`c(os)'" == "Windows" {
        winexec java -jar "`jar'"
    }
    else {
        * bash -c "... & disown" 패턴이 필수.
        * Stata 자체가 JVM 위에서 돌아서, `shell java ...` 만 쓰면 새 JVM 이
        * Stata 의 JVM 위계 안에 묶여 독립 실행이 안 됨. bash 라는 비-Java
        * 중간 프로세스가 끼어들어 disown 으로 job table 에서 분리해야
        * java 가 orphan 되어 launchd 로 reparent → Stata 종료에도 생존.
        * quietly — shell 의 잔여 빈 줄 출력 억제.
        quietly shell bash -c "java -jar '`jar'' >/dev/null 2>&1 & disown"
    }
    di as text "[Server] spawned (detached)"
end

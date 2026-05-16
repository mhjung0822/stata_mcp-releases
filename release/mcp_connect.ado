*! mcp_connect  v0.2.0  17may2026
*!
*! Start / stop / reset the full Stata-MCP stack (server jar + drone).
*! Internally invokes mcp_server for the JVM-detached server spawn and
*! javacall for the in-process drone.
*!
*! Usage:
*!   mcp_connect                            // server + drone start
*!   mcp_connect, shutdown                  // drone + server stop
*!   mcp_connect, reset                     // both stop + restart
*!   mcp_connect, bridgeport(8090) droneport(9001)
*!
*! Notes:
*! - `mcp_server` (separate ado) handles the bash-disown spawn so the
*!   server jar runs independently of Stata's JVM hierarchy.
*! - Drone uses Stata's `javacall` and shares the Stata JVM.
*! - If the server is already up, the second spawn fails silently on
*!   port-bind (8080) and leaves the existing server intact.

cap program drop mcp_connect
program mcp_connect
    version 17.0
    syntax [, RESET SHUTDOWN BRIDGEPORT(integer 8080) DRONEPORT(integer 8001)]

    * ─── shutdown: 드론 + 서버 모두 종료 ──────────────────────────────────
    if "`shutdown'" != "" {
        di as text "[Drone] Shutdown 요청..."
        capture javacall com.stata_mcp.drone.StataDrone stop, jars(stata-drone.jar)
        di as text "[Server] Shutdown 요청..."
        capture mcp_server, stop
        exit
    }

    * ─── reset: 둘 다 끄고 다시 시작 ──────────────────────────────────────
    if "`reset'" != "" {
        di as text "[Reset] 드론 + 서버 종료 후 재시작..."
        capture javacall com.stata_mcp.drone.StataDrone stop, jars(stata-drone.jar)
        capture mcp_server, stop
        sleep 1500
    }

    * ─── 서버 먼저 띄움 ───────────────────────────────────────────────────
    di as text "[Server] starting..."
    mcp_server

    * 서버 준비 대기 (Spring Boot 부팅 시간)
    sleep 2000

    * ─── 드론 시작 ────────────────────────────────────────────────────────
    di as text "[Drone] Java Stata-MCP-Drone 시작..."
    javacall com.stata_mcp.drone.StataDrone start, ///
        args("`bridgeport'" "`droneport'") jars(stata-drone.jar)

    * 지침 파일 존재 여부 → 분기 안내
    capture findfile stata-mcp-server.jar
    if !_rc {
        local jardir : subinstr local r(fn) "stata-mcp-server.jar" ""
        local instructions_file `"`jardir'stata_mcp_instructions.md"'
        capture confirm file `"`instructions_file'"'
        if !_rc {
            di as text `"[Setup] 지침 있음 — 편집: {stata mcp_edit_instructions:mcp_edit_instructions}"'
        }
        else {
            di as text `"[Setup] 지침 없음 — 설정: {stata "mcp_edit_instructions, init":mcp_edit_instructions, init}"'
        }
    }
end

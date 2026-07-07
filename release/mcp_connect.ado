*! mcp_connect  v0.3.3  11jun2026
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
*! - Both server and drone are idempotent — if already running, skip spawn.

cap program drop mcp_connect
program mcp_connect
    version 17.0
    syntax [, RESET SHUTDOWN BRIDGEPORT(integer 8080) DRONEPORT(integer 8001)]

    * ─── shutdown: 드론 + 서버 모두 종료 ──────────────────────────────────
    if "`shutdown'" != "" {
        di as text "[Drone] Shutdown requested..."
        capture javacall com.stata_mcp.drone.StataDrone stop, jars(stata-drone.jar)
        di as text "[Server] Shutdown requested..."
        capture mcp_server, stop
        exit
    }

    * ─── reset: 둘 다 끄고 다시 시작 ──────────────────────────────────────
    if "`reset'" != "" {
        di as text "[Reset] Stopping drone + server, then restarting..."
        capture javacall com.stata_mcp.drone.StataDrone stop, jars(stata-drone.jar)
        capture mcp_server, stop
        sleep 1500
    }

    * ─── 서버 먼저 띄움 (mcp_server 가 idempotency 처리) ──────────────────
    di as text "[Server] starting..."
    mcp_server

    * 서버 준비 대기 (Spring Boot 부팅 시간)
    sleep 2000

    * ─── 드론 시작 (이미 떠있으면 skip) ───────────────────────────────────
    tempfile dchk
    capture shell curl -s --max-time 1 http://127.0.0.1:`droneport'/status > "`dchk'" 2>/dev/null
    local drone_up = 0
    tempname dfh
    capture file open `dfh' using "`dchk'", read text
    if !_rc {
        file read `dfh' dline
        capture file close `dfh'
        if `"`dline'"' != "" local drone_up = 1
    }

    if `drone_up' {
        di as text "[Drone] already running on port `droneport' — skip spawn"
        * /status 응답에서 라이선스 만료일 추출해 표시 (fresh 기동 시엔 드론이 직접 출력)
        if regexm(`"`dline'"', `""licenseExp":"([0-9-]+)""') {
            di as text "[Drone] License OK (until " regexs(1) ")"
        }
    }
    else {
        di as text "[Drone] Starting Java Stata-MCP-Drone..."
        javacall com.stata_mcp.drone.StataDrone start, ///
            args("`bridgeport'" "`droneport'") jars(stata-drone.jar)
    }

    * 기동 엔진 — 사용자 안내/제어판은 mcp_set 가 담당.
    * (제어판 [연결] 버튼이 이 명령을 호출해 서버+드론을 기동)
end

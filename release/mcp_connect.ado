*! mcp_connect  v0.3.6  12aug2026
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

    * Windows cmd 는 /dev/null 을 경로로 해석해 명령이 깨짐 → OS 분기 (mcp_server 와 동일)
    local devnul = cond("`c(os)'" == "Windows", "nul", "/dev/null")

    * ─── javapath: Stata 내장 JDK 바이너리 경로 파일 (mcpb 프록시용) ──────
    * Claude Desktop 의 launch 스크립트가 plus/jar/javapath 를 읽어 시스템
    * Java 없이 proxy.jar 를 실행한다. 환경변수는 이미 실행 중인 앱의
    * 프로세스 경계를 못 넘어 파일 채택. 내용이 달라졌을 때만 기록.
    * 개행 없이 1줄 — CRLF 가 섞이면 배치의 set /p 가 \r 를 붙여 경로가 깨짐.
    * 실패는 전부 무해 (프록시가 시스템 java 로 폴백).
    capture {
        local jh = c(java_home)
        if `"`jh'"' != "" {
            local last = substr(`"`jh'"', -1, 1)
            if "`last'" != "/" & "`last'" != "\" local jh `"`jh'/"'
            local jbin ""
            if "`c(os)'" == "Windows" {
                capture confirm file `"`jh'bin\javaw.exe"'
                if !_rc local jbin `"`jh'bin\javaw.exe"'
            }
            else {
                capture confirm file `"`jh'bin/java"'
                if !_rc local jbin `"`jh'bin/java"'
                else {
                    * macOS 번들 레이아웃 (zulu: <home>/Contents/Home/bin/java)
                    capture confirm file `"`jh'Contents/Home/bin/java"'
                    if !_rc local jbin `"`jh'Contents/Home/bin/java"'
                }
            }
            if `"`jbin'"' != "" {
                local jp `"`c(sysdir_plus)'jar/javapath"'
                local cur ""
                tempname jfh
                capture file open `jfh' using `"`jp'"', read text
                if !_rc {
                    file read `jfh' cur
                    capture file close `jfh'
                }
                if `"`macval(cur)'"' != `"`jbin'"' {
                    quietly {
                        file open `jfh' using `"`jp'"', write text replace
                        file write `jfh' `"`jbin'"'
                        file close `jfh'
                    }
                }
            }
        }
    }

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

    * ─── 라이선스 키 선체크 — 없으면 그 자리에서 입력받고 이어서 진행 ──────
    * (실패 후 "mcp_set_license → 재연결" 안내를 거치게 하지 않기 위함.
    *  키가 있지만 만료/변조인 경우는 드론 검증이 잡아 안내한다.)
    mcp_get_license
    if `"$MCP_LICENSE_KEY"' == "" {
        di as text "[License] 라이선스 키가 없습니다 — 지금 입력하면 바로 연결합니다."
        capture noisily mcp_set_license, quiet
        if _rc {
            global MCP_LICENSE_KEY
            di as error "[License] 키가 입력되지 않아 연결을 중단합니다."
            exit 198
        }
    }
    global MCP_LICENSE_KEY

    * ─── 서버 먼저 띄움 (mcp_server 가 idempotency 처리) ──────────────────
    di as text "[Server] starting..."
    mcp_server

    * 서버 준비 대기 (Spring Boot 부팅 시간)
    sleep 2000

    * ─── 드론 시작 (이미 떠있으면 skip) ───────────────────────────────────
    tempfile dchk
    capture shell curl -s --max-time 1 http://127.0.0.1:`droneport'/status > "`dchk'" 2>`devnul'
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
        * /status 응답에서 버전·라이선스 만료일 추출해 표시 (fresh 기동 시엔 드론이 직접 출력)
        if regexm(`"`dline'"', `""version":"([^"]+)""') {
            di as text "[Drone] Stata-MCP v" regexs(1)
        }
        if regexm(`"`dline'"', `""licenseExp":"([0-9-]+)""') {
            di as text "[Drone] License OK (until " regexs(1) ")"
        }
    }
    else {
        di as text "[Drone] Starting Java Stata-MCP-Drone..."
        javacall com.stata_mcp.drone.StataDrone start, ///
            args("`bridgeport'" "`droneport'") jars(stata-drone.jar)
    }

    * 기동 엔진 — 사용자 안내/제어판은 mcp_setup 가 담당.
    * (제어판 [연결] 버튼이 이 명령을 호출해 서버+드론을 기동)
end

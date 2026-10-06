*! mcp_connect  v0.3.11  06oct2026
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

    * ─── Java 버전 체크 — 드론(javacall)·서버(Spring Boot 3) 모두 17+ 필요 ──
    * Stata 번들 JDK 가 17 미만(업데이트 안 된 구버전 설치본)이면 기동 전에 중단.
    * 드론은 Stata JVM 에서만 돌 수 있어 별도 JDK 설치로는 해결 불가 → Stata 업데이트 안내.
    * c(java_version) 이 비어 있으면(JVM 미초기화 등) 판정 없이 통과.
    local jv `"`c(java_version)'"'
    if `"`jv'"' != "" {
        gettoken jmaj jrest : jv, parse(".")
        if "`jmaj'" == "1" {
            * 1.8.0_x 형식
            gettoken dot jrest : jrest, parse(".")
            gettoken jmaj : jrest, parse(".")
        }
        capture confirm integer number `jmaj'
        if !_rc {
            if `jmaj' < 17 {
                di as error "[Stata-MCP] Stata 의 Java 가 `jv' 입니다 — Java 17 이상이 필요합니다."
                di as text  "  Stata 를 업데이트한 뒤 재시작하세요: {stata update all:update all}"
                exit 198
            }
        }
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
    capture shell curl -s --max-time 1 -H "X-Stata-MCP: 1" http://127.0.0.1:`droneport'/status > "`dchk'" 2>`devnul'
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
        * /status 응답에서 버전 추출해 표시 (fresh 기동 시엔 드론이 직접 출력)
        if regexm(`"`dline'"', `""version":"([^"]+)""') {
            di as text "[Drone] Stata-MCP v" regexs(1)
        }
    }
    else {
        di as text "[Drone] Starting Java Stata-MCP-Drone..."
        * 이 세션에 드론 jar 가 로드됨 — 이후 mcp_setup, update 가 jar 교체를 거부하는 근거
        * (Windows 는 파일 잠금, Mac 은 실행 중 JVM 의 jar 를 덮어쓰면 깨짐). 정책 차단돼도 로드는 됨
        global MCP_DRONE_LOADED 1
        capture noisily javacall com.stata_mcp.drone.StataDrone start, ///
            args("`bridgeport'" "`droneport'") jars(stata-drone.jar)
        if _rc == 690 {
            * 원격 정책 차단 (StataDrone.RC_BLOCKED — 제공 종료·강제 업데이트).
            * 안내는 드론이 출력했다. 먼저 띄운 서버까지 내리고 오류 없이 끝낸다.
            capture mcp_server, stop
            exit
        }
        if _rc exit _rc
    }

    * ─── help DB 선체크 — 없으면 1회 제안 ──────────────────────────────────
    * 거절하면 마커 파일을 남겨 매 연결마다 묻지 않는다. 나중엔 mcp_setup.
    * 연결 자체는 이미 끝난 뒤라 다운로드 실패/거절이 연결을 막지 않는다.
    capture confirm file `"`c(sysdir_plus)'jar/help_index_v2.json"'
    if _rc {
        capture confirm file `"`c(sysdir_plus)'jar/helpdb_skip"'
        if _rc {
            di as text "[Setup] 도움말 DB가 없습니다 (~32MB, 최초 1회)."
            di as text "        지금 받으려면 y 입력, 건너뛰려면 그냥 엔터:"
            display _request(mcpyn)
            local yn = lower(strtrim(`"$mcpyn"'))
            capture macro drop mcpyn
            if "`yn'" == "y" {
                capture noisily mcp_setup, updatedb
                capture quietly mcp_menu, install
            }
            else {
                tempname sfh
                capture quietly {
                    file open `sfh' using `"`c(sysdir_plus)'jar/helpdb_skip"', write text replace
                    file write `sfh' "skip"
                    file close `sfh'
                }
                di as text "[Setup] 건너뜀 — 나중에 받으려면: {stata mcp_setup:mcp_setup}"
            }
        }
    }

    * (제어판 [연결] 버튼이 이 명령을 호출해 서버+드론을 기동)
end

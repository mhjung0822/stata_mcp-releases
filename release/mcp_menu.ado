*! mcp_menu  v0.3.1  17jul2026
*!
*! Stata-MCP 제어판(db mcp)을 Stata 의 User 메뉴에 등록.
*! 메뉴는 세션마다 초기화되므로 profile.do 에서 매 시작 시 호출해야 한다.
*!
*! Usage:
*!   mcp_menu            // 현재 세션 메뉴에 등록 (User ▸ Stata-MCP ▸ 제어판...)
*!   mcp_menu, install   // 위 등록 + profile.do 에 'capture mcp_menu' 영구 추가
*!
*! install:
*!   - profile.do 가 있으면  → 맨 아래에 'capture mcp_menu' 추가
*!   - 없으면               → profile.do 생성 후 추가
*!   - 이미 들어있으면       → 중복 추가 안 함 (멱등)
*!   대상 탐색 = Stata 가 시작 시 profile.do 를 찾는 순서 그대로:
*!     ① Stata 설치폴더 c(sysdir_stata) ② 홈 (HOME/USERPROFILE) ③ adopath (findfile).
*!   Stata 는 처음 발견한 profile.do 하나만 실행하므로, 다른 위치의 파일에 쓰면
*!   시작 시 실행되지 않는다 — 반드시 실행되는 그 파일에 추가해야 한다.
*!   아무 데도 없으면 c(sysdir_personal) 에 생성 (adopath 에 있어 시작 시 로드됨).
*!
*! 주의: window menu clear 는 쓰지 않는다(다른 패키지가 등록한 메뉴 보존).

cap program drop mcp_menu
program mcp_menu
    version 17.0
    syntax [, INSTALL]

    * ─── install: profile.do 에 영구 등록 ────────────────────────────────
    if "`install'" != "" {
        * profile.do 탐색 — Stata 시작 시 실행 순서대로. 시작 시엔 처음 발견한
        * 하나만 실행되므로, 기존 파일이 있으면 반드시 그 파일에 append 해야 한다.
        * (시작 시 current dir 는 세션 pwd 와 달라 탐지 불가 — 제외)
        local pf ""

        * ① Stata 설치폴더 — 시작 시 최우선 실행 위치
        capture confirm file `"`c(sysdir_stata)'profile.do"'
        if !_rc {
            local pf `"`c(sysdir_stata)'profile.do"'
        }

        * ② 홈 디렉토리 (Mac/Linux: HOME, Windows: USERPROFILE)
        if `"`pf'"' == "" {
            local home : environment HOME
            if `"`home'"' == "" {
                local home : environment USERPROFILE
            }
            if `"`home'"' != "" {
                capture confirm file `"`home'`c(dirsep)'profile.do"'
                if !_rc {
                    local pf `"`home'`c(dirsep)'profile.do"'
                }
            }
        }

        * ③ adopath 전체 (findfile)
        if `"`pf'"' == "" {
            capture findfile profile.do
            if !_rc {
                local pf `"`r(fn)'"'
            }
        }

        * ④ 아무 데도 없으면 PERSONAL 에 생성
        if `"`pf'"' == "" {
            local pf `"`c(sysdir_personal)'profile.do"'
        }

        * 존재 여부 + 이미 등록됐는지 검사
        local exists 0
        local found  0
        capture confirm file `"`pf'"'
        if !_rc {
            local exists 1
            tempname rfh
            file open `rfh' using `"`pf'"', read text
            file read `rfh' line
            while r(eof) == 0 {
                if regexm(`"`macval(line)'"', "mcp_menu") local found 1
                file read `rfh' line
            }
            file close `rfh'
        }

        if `found' {
            di as text "[Menu] Already registered in profile.do → " as result `"`pf'"'
        }
        else {
            tempname wfh
            capture {
                if `exists' {
                    file open `wfh' using `"`pf'"', write text append
                }
                else {
                    file open `wfh' using `"`pf'"', write text replace
                }
                file write `wfh' _n "* ─── Stata-MCP: User 메뉴에 제어판 등록 (세션마다) ───" _n
                file write `wfh' "capture mcp_menu" _n
                file close `wfh'
            }
            if _rc {
                capture file close `wfh'
                di as error "[Menu] profile.do 쓰기 실패 (권한 문제일 수 있음): " `"`pf'"'
                di as error `"        수동으로 'capture mcp_menu' 한 줄을 profile.do 에 추가하세요."'
                exit
            }
            if `exists' {
                di as text "[Menu] Appended to profile.do → " as result `"`pf'"'
            }
            else {
                di as text "[Menu] Created profile.do and added → " as result `"`pf'"'
            }
        }
    }

    * ─── 현재 세션 메뉴 등록 (세션당 1회만 — 중복 append 방지) ────────────
    * window menu 엔 "있으면 skip" 이 없어서, 가드 없이 여러 번 부르면
    * "Stata-MCP" 메뉴가 중복으로 쌓인다. 세션 전역 플래그로 1회만 등록.
    if "$MCP_MENU_REGISTERED" == "" {
        capture window menu append submenu "stUser" "Stata-MCP"
        capture window menu append item    "Stata-MCP" "Control Panel..." "db mcp"
        window menu refresh
        global MCP_MENU_REGISTERED 1
    }
end

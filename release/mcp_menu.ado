*! mcp_menu  v0.2.0  23jun2026
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
*!   대상 = Stata 설치 폴더 profile.do (c(sysdir_stata)) — 시작 시 가장 먼저 탐색.
*!
*! 주의: window menu clear 는 쓰지 않는다(다른 패키지가 등록한 메뉴 보존).

cap program drop mcp_menu
program mcp_menu
    version 17.0
    syntax [, INSTALL]

    * ─── install: profile.do 에 영구 등록 ────────────────────────────────
    if "`install'" != "" {
        * 대상 = Stata 설치 폴더 (c(sysdir_stata)는 끝에 구분자 포함). 시작 시 가장 먼저 탐색됨
        local pf `"`c(sysdir_stata)'profile.do"'

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
            if `exists' {
                file open `wfh' using `"`pf'"', write text append
            }
            else {
                file open `wfh' using `"`pf'"', write text replace
            }
            file write `wfh' _n "* ─── Stata-MCP: User 메뉴에 제어판 등록 (세션마다) ───" _n
            file write `wfh' "capture mcp_menu" _n
            file close `wfh'
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

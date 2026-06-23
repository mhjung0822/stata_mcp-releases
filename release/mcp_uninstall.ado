*! mcp_uninstall  v0.4.0  23jun2026
*!
*! Stata-MCP 제거 — `net install` 로 깐 것만. Stata 가 추적(stata.trk)하므로
*! 정석 도구 `ado uninstall stata-mcp` 를 쓴다 (수동 경로 추측 없음 = 견고).
*! 개발/수동 위치(personal, ~/Documents/StataMCP/)는 건드리지 않는다.
*!
*! Usage:
*!   mcp_uninstall              // 미리보기 (ado describe — 삭제 안 함)
*!   mcp_uninstall, confirm     // ado uninstall stata-mcp + 메뉴 등록 제거
*!   mcp_uninstall, confirm all // + 자동생성 데이터(라이선스/지침) 까지

cap program drop mcp_uninstall
program mcp_uninstall
    version 17.0
    syntax [, CONFIRM ALL]

    * ─── 미리보기 ────────────────────────────────────────────────────────
    if "`confirm'" == "" {
        di as text ""
        di as text "{bf:[Stata-MCP] Uninstall preview}  (net install package — nothing deleted yet)"
        di as text "Tracked files that {cmd:ado uninstall} will remove:"
        capture ado describe stata-mcp
        if _rc {
            di as text "  (no stata-mcp net install record found — nothing to remove)"
        }
        di as text ""
        di as text "  Delete now:            {stata mcp_uninstall, confirm:mcp_uninstall, confirm}  (keeps license/instructions)"
        di as text "  Delete all incl. data: {stata mcp_uninstall, confirm all:mcp_uninstall, confirm all}"
        di as text ""
        exit
    }

    * ─── 실제 제거 ───────────────────────────────────────────────────────
    di as text "[Uninstall] Stopping server/drone..."
    capture mcp_connect, shutdown
    sleep 2500

    _mcp_unreg_menu
    global MCP_MENU_REGISTERED ""

    di as text "[Uninstall] ado uninstall stata-mcp ..."
    local n 0
    capture ado uninstall stata-mcp
    while _rc == 0 {
        local ++n
        if `n' >= 20 continue, break
        capture ado uninstall stata-mcp
    }
    if `n' == 0 {
        di as text "  (no stata-mcp net install record — nothing removed)"
    }
    else {
        di as text "  Removed `n' stata-mcp net-install record(s)."
    }

    * ─── 자동생성 데이터 (properties=라이선스 / instructions) : all 일 때만 ──
    * .pkg 미포함(런타임 생성)이라 ado uninstall 이 안 지움 — plus/jar/ 에서 직접
    if "`all'" != "" {
        local plus `"`c(sysdir_plus)'"'
        foreach x in stata_mcp.properties stata_mcp_instructions.md     ///
                     stata_mcp_instructions_example_full.md             ///
                     stata_mcp_instructions_example_compact.md {
            capture confirm file `"`plus'jar/`x'"'
            if !_rc {
                capture erase `"`plus'jar/`x'"'
                if !_rc di as text "  Deleted: " as result `"`plus'jar/`x'"'
            }
        }
    }

    di as text "[Uninstall] Done. Restart Stata to clear the menu/commands from memory."
    if "`all'" == "" {
        di as text "  (license/instructions kept — use {stata mcp_uninstall, confirm all:mcp_uninstall, confirm all} to remove them)"
    }
end

* profile.do 에서 mcp_menu 등록 블록 제거 (c(sysdir_stata)/profile.do)
cap program drop _mcp_unreg_menu
program _mcp_unreg_menu
    local pf `"`c(sysdir_stata)'profile.do"'
    capture confirm file `"`pf'"'
    if _rc exit
    tempname rfh
    local nkeep 0
    file open `rfh' using `"`pf'"', read text
    file read `rfh' pline
    while r(eof) == 0 {
        if !regexm(`"`macval(pline)'"', "mcp_menu") ///
         & !regexm(`"`macval(pline)'"', "Stata-MCP: User") {
            local ++nkeep
            local K`nkeep' `"`macval(pline)'"'
        }
        file read `rfh' pline
    }
    file close `rfh'
    tempname wfh
    file open `wfh' using `"`pf'"', write text replace
    forvalues i = 1/`nkeep' {
        file write `wfh' `"`macval(K`i')'"' _n
    }
    file close `wfh'
    di as text "  Removed menu registration: " as result `"`pf'"'
end

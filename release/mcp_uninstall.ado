*! mcp_uninstall  v0.6.0  24jun2026
*!
*! Stata-MCP 제거 — `net install` 한 PLUS 레이아웃만. 개발/수동 위치
*! (c(sysdir_personal), ~/Documents/StataMCP/)는 건드리지 않는다.
*! 되돌리기 어려우므로 dry-run 기본 + 명시 confirm.
*!
*! Usage:
*!   mcp_uninstall              // 미리보기 (삭제 안 함)
*!   mcp_uninstall, confirm     // PLUS 의 ado/dlg/jar + 메뉴 등록 + net 추적 제거
*!   mcp_uninstall, confirm all // + 라이선스/지침 데이터까지
*!
*! 제거 방식 (confirm):
*!   1) ado uninstall stata-mcp  — 단일 설치면 파일 + stata.trk 추적 정리.
*!      중복 설치면 이름이 모호(rc 101)라 무해 실패 →
*!   2) 직접 erase  — c(sysdir_plus) 의 정확한 경로로 잔여 파일 확실히 제거.
*!
*! 주의: 공백 포함 경로(Application Support)를 sub-program 인자로 넘기면
*!       매크로 파싱이 깨지므로, erase 로직은 인라인으로 둔다.

cap program drop mcp_uninstall
program mcp_uninstall
    version 17.0
    syntax [, CONFIRM ALL]

    local plus `"`c(sysdir_plus)'"'
    local ados                                                   ///
        mcp_connect.ado mcp_server.ado mcp_edit_license.ado      ///
        mcp_edit_instructions.ado mcp_load_serset.ado llm.ado    ///
        graph_meta_put.ado mcp.ado mcp.dlg mcp_set.ado           ///
        mcp_menu.ado mcp_set_license.ado mcp_get_license.ado     ///
        mcp_uninstall.ado
    local jars stata-drone.jar stata-mcp-server.jar
    local data stata_mcp.properties stata_mcp_instructions.md    ///
        stata_mcp_instructions_example_full.md                   ///
        stata_mcp_instructions_example_compact.md

    * ─── 대상 경로 목록 구성 (plus 만) ───────────────────────────────────
    *   nfiles / P`i' 에 절대경로 누적 (공백 경로라 list 매크로 대신 인덱스 사용)
    local nfiles 0
    foreach f of local ados {
        local c1 = substr("`f'", 1, 1)
        local ++nfiles
        local P`nfiles' `"`plus'`c1'/`f'"'
    }
    foreach j of local jars {
        local ++nfiles
        local P`nfiles' `"`plus'jar/`j'"'
    }
    if "`all'" != "" {
        foreach x of local data {
            local ++nfiles
            local P`nfiles' `"`plus'jar/`x'"'
        }
    }

    * ─── 미리보기 ────────────────────────────────────────────────────────
    if "`confirm'" == "" {
        di as text ""
        di as text "{bf:[Stata-MCP] Uninstall preview}  (net install / PLUS only — nothing deleted yet)"
        di as text "Files to remove (only existing shown):"
        forvalues i = 1/`nfiles' {
            capture confirm file `"`P`i''"'
            if !_rc di as text "  - " as result `"`P`i''"'
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

    * net 추적 정리 (단일 설치면 파일+trk; 중복이면 모호=무해 실패)
    capture ado uninstall stata-mcp

    di as text "[Uninstall] Deleting files (PLUS):"
    forvalues i = 1/`nfiles' {
        capture confirm file `"`P`i''"'
        if !_rc {
            capture erase `"`P`i''"'
            if !_rc di as text  "  Deleted: " as result `"`P`i''"'
            else    di as error "  Failed:  " `"`P`i''"'
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

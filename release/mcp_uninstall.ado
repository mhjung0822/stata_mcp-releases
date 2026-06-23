*! mcp_uninstall  v0.1.0  23jun2026
*!
*! Stata-MCP 전체 제거. 되돌리기 어려우므로 dry-run 기본 + 명시 confirm.
*!
*! Usage:
*!   mcp_uninstall              // 미리보기 (삭제 안 함)
*!   mcp_uninstall, confirm     // 프로그램 파일(ado/dlg/jar) + 메뉴 등록 제거
*!   mcp_uninstall, confirm all // + 라이선스/지침 데이터까지
*!
*! 위치: ado/dlg = personal + plus/<첫글자>/, jar·데이터 = personal + plus/jar/
*! 데이터(stata_mcp.properties = 라이선스 키 / instructions)는 `all` 일 때만.

cap program drop mcp_uninstall
program mcp_uninstall
    version 17.0
    syntax [, CONFIRM ALL]

    local personal `"`c(sysdir_personal)'"'
    local plus     `"`c(sysdir_plus)'"'

    * ado/dlg — personal + plus/<첫글자>/
    local files                                                  ///
        mcp_connect.ado mcp_server.ado mcp_edit_license.ado      ///
        mcp_edit_instructions.ado mcp_load_serset.ado llm.ado    ///
        graph_meta_put.ado mcp.ado mcp.dlg mcp_set.ado           ///
        mcp_menu.ado mcp_set_license.ado mcp_get_license.ado     ///
        mcp_uninstall.ado
    * jar 옆 (jar + 데이터) — personal + plus/jar/
    local jarside stata-drone.jar stata-mcp-server.jar
    if "`all'" != "" {
        local jarside `jarside' stata_mcp.properties            ///
            stata_mcp_instructions.md                            ///
            stata_mcp_instructions_example_full.md               ///
            stata_mcp_instructions_example_compact.md
    }

    * ─── confirm 없으면 미리보기 ─────────────────────────────────────────
    if "`confirm'" == "" {
        global MCP_UNINST_MODE list
        di as text ""
        di as text "{bf:[Stata-MCP] Uninstall preview}  (nothing deleted yet)"
        di as text "Files to remove (only existing shown):"
    }
    else {
        global MCP_UNINST_MODE erase
        di as text "[Uninstall] Stopping server/drone..."
        capture mcp_connect, shutdown
        sleep 2500
        _mcp_unreg_menu
        global MCP_MENU_REGISTERED ""
        di as text "[Uninstall] Deleting files:"
    }

    * ─── 공통 루프 ───────────────────────────────────────────────────────
    foreach f of local files {
        local c1 = substr("`f'", 1, 1)
        _mcp_do `"`personal'`f'"'
        _mcp_do `"`plus'`c1'/`f'"'
    }
    foreach j of local jarside {
        _mcp_do `"`personal'`j'"'
        _mcp_do `"`plus'jar/`j'"'
    }
    global MCP_UNINST_MODE

    * ─── 마무리 안내 ─────────────────────────────────────────────────────
    if "`confirm'" == "" {
        di as text ""
        di as text "  Delete now:            {stata mcp_uninstall, confirm:mcp_uninstall, confirm}  (keeps license/instructions)"
        di as text "  Delete all incl. data: {stata mcp_uninstall, confirm all:mcp_uninstall, confirm all}"
        di as text ""
    }
    else {
        di as text "[Uninstall] Done. Menu/commands disappear after restarting Stata."
        if "`all'" == "" {
            di as text "  (license/instructions kept — use {stata mcp_uninstall, confirm all:mcp_uninstall, confirm all} to remove them)"
        }
    }
end

* 경로 1건 처리 — 0 = 경로(공백 포함 가능). $MCP_UNINST_MODE 로 list/erase 분기.
cap program drop _mcp_do
program _mcp_do
    capture confirm file `"`0'"'
    if _rc exit
    if "$MCP_UNINST_MODE" == "erase" {
        capture erase `"`0'"'
        if !_rc di as text  "  Deleted: " as result `"`0'"'
        else    di as error "  Failed:  " `"`0'"'
    }
    else {
        di as text "  - " as result `"`0'"'
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

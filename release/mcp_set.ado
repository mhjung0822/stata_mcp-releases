*! mcp_set  v0.6.0  23jun2026
*!
*! Stata-MCP 설정 진입점 — 클릭 가능한 설정 메뉴를 출력한다.
*! 서버·드론은 기동하지 않는다.
*!
*! Usage:
*!   mcp_set               // 설정 메뉴 출력
*!   mcp_set, emptyinstr   // 빈 지침 파일 생성 후 편집기 열기
*!   mcp_set, delinstr     // 지침 파일 삭제

cap program drop mcp_set
program mcp_set
    version 17.0
    syntax [, EMPTYINSTR DELINSTR]

    * jar 옆 지침 파일 경로 (emptyinstr/delinstr 공용)
    if "`emptyinstr'`delinstr'" != "" {
        capture findfile stata-mcp-server.jar
        if _rc {
            di as error "[Instructions] stata-mcp-server.jar not found in adopath; cannot resolve path."
            exit 601
        }
        local jarpath `"`r(fn)'"'
        local jardir : subinstr local jarpath "stata-mcp-server.jar" ""
        local dest `"`jardir'stata_mcp_instructions.md"'
    }

    * ─── 빈 지침 생성 ────────────────────────────────────────────────────
    if "`emptyinstr'" != "" {
        capture confirm file `"`dest'"'
        if !_rc {
            di as error "[Instructions] Already exists: " as result `"`dest'"'
            di as error "               Delete it first: {stata mcp_set, delinstr:mcp_set, delinstr}"
            exit 602
        }
        tempname efh
        file open `efh' using `"`dest'"', write text replace
        file close `efh'
        di as text "[Instructions] Created empty file: " as result `"`dest'"'
        doedit `"`dest'"'
        exit
    }

    * ─── 지침 삭제 ───────────────────────────────────────────────────────
    if "`delinstr'" != "" {
        capture confirm file `"`dest'"'
        if _rc {
            di as text "[Instructions] No file to delete (already absent): " as result `"`dest'"'
            exit
        }
        erase `"`dest'"'
        di as text "[Instructions] Deleted: " as result `"`dest'"'
        exit
    }

    * ─── 설정 메뉴 출력 ──────────────────────────────────────────────────
    di as text ""
    di as text "{bf:[Stata-MCP] Setup}"
    di as text "  Edit license key:             {stata mcp_edit_license:mcp_edit_license}"
    di as text "  Init instructions (example):  {stata mcp_edit_instructions, init:mcp_edit_instructions, init}"
    di as text "  Create empty instructions:    {stata mcp_set, emptyinstr:mcp_set, emptyinstr}"
    di as text "  Delete instructions:          {stata mcp_set, delinstr:mcp_set, delinstr}"
    di as text "  Register control-panel menu:  {stata mcp_menu, install:mcp_menu, install}"
    di as text "  Uninstall (remove all):       {stata mcp_uninstall:mcp_uninstall}"
    di as text ""
end

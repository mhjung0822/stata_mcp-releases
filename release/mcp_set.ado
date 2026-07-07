*! mcp_set  v0.7.0  08jul2026
*!
*! Stata-MCP 설정 진입점 — 클릭 가능한 설정 메뉴를 출력한다.
*! 서버·드론은 기동하지 않는다.
*!
*! Usage:
*!   mcp_set               // 설정 메뉴 출력

cap program drop mcp_set
program mcp_set
    version 17.0
    syntax

    * ─── 설정 메뉴 출력 ──────────────────────────────────────────────────
    di as text ""
    di as text "{bf:[Stata-MCP] Setup}"
    di as text "  Edit license key:             {stata mcp_edit_license:mcp_edit_license}"
    di as text "  Register control-panel menu:  {stata mcp_menu, install:mcp_menu, install}"
    di as text "  Uninstall (remove all):       {stata mcp_uninstall:mcp_uninstall}"
    di as text ""
end

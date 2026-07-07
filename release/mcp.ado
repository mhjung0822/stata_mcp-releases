*! mcp  v0.2.0  23jun2026
*!
*! Stata-MCP 제어판 런처 — db mcp 의 짧은 별칭.
*! 키 prefill 은 다이얼로그(mcp.dlg)의 POSTINIT 가 직접 mcp_get_license 를
*! 돌려 처리하므로 여기선 다이얼로그만 띄운다.
*!
*! Usage:  mcp   (= db mcp)

cap program drop mcp
program mcp
    version 17.0
    db mcp
end

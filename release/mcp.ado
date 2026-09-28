*! mcp  v0.2.1  28sep2026
*!
*! Stata-MCP 제어판 런처 — db mcp 의 짧은 별칭.
*!
*! Usage:  mcp   (= db mcp)

cap program drop mcp
program mcp
    version 17.0
    db mcp
end

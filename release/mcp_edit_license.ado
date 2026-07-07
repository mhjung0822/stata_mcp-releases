*! mcp_edit_license  v0.1.0  10jun2026
*!
*! Open stata_mcp.properties (next to the server jar) in Stata's do-file
*! editor so the user can paste a LICENSE_KEY issued by the developer.
*!
*! Usage:
*!   mcp_edit_license                       // open properties file
*!
*! Implementation note:
*! - Same resolution strategy as mcp_edit_instructions: locate
*!   stata-mcp-server.jar via `findfile` and operate on the properties
*!   file SITTING NEXT TO THE JAR (net install puts jars in PLUS/jar/).
*!   The drone searches its own jar dir first, so this is the same file
*!   the license check reads.
*! - If the file is missing (server never started) it is created, and a
*!   LICENSE_KEY= line is appended when absent — the user only has to
*!   paste the key between the quotes and save.
*! - Key change is picked up by `mcp_connect, reset` (drone re-checks at
*!   start) — no Stata restart needed.

cap program drop mcp_edit_license
program mcp_edit_license
    version 17.0

    * ─── 1. jar 위치 → 그 옆 properties 경로 산정 ─────────────────────────
    capture findfile stata-mcp-server.jar
    if _rc {
        di as error "mcp_edit_license: stata-mcp-server.jar not found in adopath"
        di as error "Install first: net install stata-mcp, from(...)"
        exit 601
    }
    local jarpath `"`r(fn)'"'
    local jardir : subinstr local jarpath "stata-mcp-server.jar" ""
    local dest `"`jardir'stata_mcp.properties"'

    local q = char(34)

    * ─── 2. 파일 없으면 생성, LICENSE_KEY 줄 없으면 추가 ──────────────────
    capture confirm file `"`dest'"'
    if _rc {
        tempname fh
        file open `fh' using `"`dest'"', write text
        file write `fh' "# Stata MCP 환경 설정" _n
        file write `fh' `"LICENSE_KEY=`q'`q'"' _n
        file close `fh'
        di as text "created: " as result `"`dest'"'
    }
    else {
        local has_key = 0
        tempname fh
        file open `fh' using `"`dest'"', read text
        file read `fh' line
        while !r(eof) {
            if strpos(`"`macval(line)'"', "LICENSE_KEY") == 1 local has_key = 1
            file read `fh' line
        }
        file close `fh'
        if !`has_key' {
            file open `fh' using `"`dest'"', write text append
            file write `fh' `"LICENSE_KEY=`q'`q'"' _n
            file close `fh'
            di as text "LICENSE_KEY= 줄 추가됨 — 따옴표 사이에 키를 붙여넣고 저장하세요"
        }
    }

    * ─── 3. 에디터로 열기 ─────────────────────────────────────────────────
    di as text "file path: " as result `"`dest'"'
    di as text "키 저장 후 적용: {stata mcp_connect, reset:mcp_connect, reset}"
    doedit `"`dest'"'
end

*! mcp_get_license  v0.1.0  23jun2026
*!
*! Read current LICENSE_KEY from stata_mcp.properties into global MCP_LICENSE_KEY.
*! 다이얼로그(db mcp) 초기화(POSTINIT)에서 호출 — EDIT 칸 prefill 용.
*! 키가 없으면 global 을 빈 문자열로 둔다.
*!
*! 대상 파일 = 드론 읽기 우선순위와 동일 (mcp_set_license 와 일치):
*!   1) adopath 의 stata_mcp.properties (findfile)
*!   2) 없으면 stata-drone.jar 옆

cap program drop mcp_get_license
program mcp_get_license
    version 17.0
    global MCP_LICENSE_KEY ""

    local target ""
    capture findfile stata_mcp.properties
    if !_rc {
        local target `"`r(fn)'"'
    }
    else {
        capture findfile stata-drone.jar
        if _rc exit 0
        local jarpath `"`r(fn)'"'
        local jardir : subinstr local jarpath "stata-drone.jar" ""
        local target `"`jardir'stata_mcp.properties"'
    }

    capture confirm file `"`target'"'
    if _rc exit 0

    tempname fh
    file open `fh' using `"`target'"', read text
    file read `fh' line
    while r(eof) == 0 {
        if regexm(`"`macval(line)'"', "^[ `=char(9)']*LICENSE_KEY[ `=char(9)']*=(.*)$") {
            local val = strtrim(regexs(1))
            * 양끝 따옴표 제거
            if substr(`"`val'"', 1, 1) == `"""' & substr(`"`val'"', -1, 1) == `"""' {
                local val = substr(`"`val'"', 2, length(`"`val'"') - 2)
            }
            global MCP_LICENSE_KEY `"`val'"'
        }
        file read `fh' line
    }
    file close `fh'
    * 다이얼로그(db mcp)는 POSTINIT 에서 global MCP_LICENSE_KEY 를 EDIT 에 prefill
end

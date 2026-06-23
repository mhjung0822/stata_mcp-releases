*! mcp_set_license  v0.1.0  23jun2026
*!
*! Write LICENSE_KEY into stata_mcp.properties (preserving other keys).
*! 다이얼로그(db mcp)와 커맨드라인 양쪽에서 사용.
*!
*! Usage:
*!   mcp_set_license eyJ2Ijox....Kn_R5Y...
*!   mcp_set_license eyJ2Ijox....Kn_R5Y... , reset
*!
*! 대상 파일 결정 = 드론의 읽기 우선순위와 동일:
*!   1) adopath 에 이미 있는 stata_mcp.properties (findfile)
*!   2) 없으면 stata-drone.jar 옆 (jar-dir/stata_mcp.properties)
*! 기존 BRIDGE_PORT / DRONE_PORT 줄은 보존, LICENSE_KEY 줄만 교체/추가.

cap program drop mcp_set_license
program mcp_set_license
    version 17.0
    gettoken key 0 : 0, parse(",")
    local key = strtrim(`"`key'"')
    syntax [, RESET]

    if `"`key'"' == "" {
        di as error "Usage: mcp_set_license <license-key> [, reset]"
        exit 198
    }

    * ─── 대상 properties 파일 결정 ───────────────────────────────
    local target ""
    capture findfile stata_mcp.properties
    if !_rc {
        local target `"`r(fn)'"'
    }
    else {
        capture findfile stata-drone.jar
        if _rc {
            di as error "Neither stata_mcp.properties nor stata-drone.jar found in adopath."
            di as error "Make sure this is an environment where mcp_connect works."
            exit 601
        }
        local jarpath `"`r(fn)'"'
        local jardir : subinstr local jarpath "stata-drone.jar" ""
        local target `"`jardir'stata_mcp.properties"'
    }

    * ─── 기존 줄 읽어 LICENSE_KEY 만 제외하고 보존 ───────────────
    tempname fh
    local nlines = 0
    capture confirm file `"`target'"'
    if !_rc {
        file open `fh' using `"`target'"', read text
        file read `fh' line
        while r(eof) == 0 {
            if !regexm(`"`macval(line)'"', "^[ `=char(9)']*LICENSE_KEY[ `=char(9)']*=") {
                local ++nlines
                local L`nlines' `"`macval(line)'"'
            }
            file read `fh' line
        }
        file close `fh'
    }

    * ─── 다시 쓰기: 보존줄 + 새 LICENSE_KEY ──────────────────────
    file open `fh' using `"`target'"', write text replace
    forvalues i = 1/`nlines' {
        file write `fh' `"`macval(L`i')'"' _n
    }
    file write `fh' `"LICENSE_KEY="`key'""' _n
    file close `fh'

    di as text "[License] Saved → " as result `"`target'"'
    di as text "[License] Restart the drone to apply: {stata mcp_connect, reset:mcp_connect, reset}"

    if "`reset'" != "" {
        di as text "[License] reset option → running mcp_connect, reset..."
        mcp_connect, reset
    }
end

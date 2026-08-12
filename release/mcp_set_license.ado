*! mcp_set_license  v0.2.1  12aug2026
*!
*! Write LICENSE_KEY into stata_mcp.properties (preserving other keys).
*! 다이얼로그(db mcp)와 커맨드라인 양쪽에서 사용.
*!
*! Usage:
*!   mcp_set_license                        // 프롬프트로 키 입력 (붙여넣기)
*!   mcp_set_license eyJ2Ijox....Kn_R5Y...
*!   mcp_set_license eyJ2Ijox....Kn_R5Y... , reset
*!
*! 대상 파일 = 드론 탐색 체인에 걸릴 수 있는 "모든" 후보를 일괄 갱신:
*!   1) c(sysdir_plus)jar/  — net install 표준 위치 (javacall 이 로드하는 드론 jar 옆).
*!      드론 jar 가 실재하면 properties 가 없어도 생성.
*!   2) findfile stata-drone.jar 옆 — 개발 personal 사본 등 (1)과 다르면 갱신/생성.
*!   3) personal / ~/ado/personal 의 기존 properties — 존재할 때만 키 갱신.
*!
*! 왜 전부 갱신하나 (2026-08-03 사고 교훈): 드론은 "LICENSE_KEY 가 든 첫 파일"을
*! 쓰므로, 탐색 순서 앞쪽 파일에 낡은/틀린 키가 남아 있으면 뒤쪽의 새 키를 가린다.
*! ado 는 javacall 이 어느 jar 를 로드했는지 확정할 수 없어 (findfile ≠ javacall
*! 해석), 한 파일만 고치는 전략은 머신 구성에 따라 어긋난다. 같은 키를 모든
*! 후보에 쓰면 어디를 읽든 같은 답 — 애매함이 사라진다.
*! 기존 BRIDGE_PORT / DRONE_PORT 등 다른 줄은 각 파일에서 보존.

cap program drop mcp_set_license
cap program drop _mcp_lic_write
program mcp_set_license
    version 17.0
    gettoken key 0 : 0, parse(",")
    * 키 없이 옵션만 온 경우 (예: mcp_set_license, quiet) — gettoken 이 쉼표를
    * 키 토큰으로 삼키므로 복원해야 syntax 가 옵션으로 인식한다
    if `"`key'"' == "," {
        local 0 `", `0'"'
        local key ""
    }
    local key = strtrim(`"`key'"')
    syntax [, RESET Quiet]

    * 인수 없이 실행하면 프롬프트로 입력받음 — 사용자는 명령만 치고 키를 붙여넣으면 된다.
    * 주의: 여러 줄 복붙 스크립트(AGENT_INSTALL 등)에서는 인수형을 쓸 것 — 프롬프트가
    * 다음 붙여넣은 줄을 키로 삼켜버린다.
    if `"`key'"' == "" {
        di as text "라이선스 키를 명령어 창에 입력하고 엔터:"
        * _request 매크로 이름은 8자 제한 — 초과 시 display 자체가 invalid syntax
        display _request(_mcpkey)
        local key = strtrim(`"$_mcpkey"')
        global _mcpkey
        if `"`key'"' == "" {
            di as error "키가 입력되지 않았습니다. Usage: mcp_set_license [<license-key>] [, reset]"
            exit 198
        }
    }

    * ─── 후보 수집 (t1..tN + 생성 허용 여부 c1..cN) ─────────────────────────
    local n = 0
    * (1) 표준 위치: plus/jar — 드론 jar 실재 시 생성까지 허용
    capture confirm file `"`c(sysdir_plus)'jar/stata-drone.jar"'
    if !_rc {
        local ++n
        local t`n' `"`c(sysdir_plus)'jar/stata_mcp.properties"'
        local c`n' = 1
    }
    * (2) findfile 로 잡히는 드론 jar 옆 — (1)과 다르면 추가.
    *     (1)이 없을 때만 생성 허용 (개발 personal jar 사본 때문에 불필요한
    *      두 번째 properties 가 생기는 것 방지 — 기존 파일이면 키 갱신은 함)
    capture findfile stata-drone.jar
    if !_rc {
        local jarpath `"`r(fn)'"'
        local jardir : subinstr local jarpath "stata-drone.jar" ""
        local cand `"`jardir'stata_mcp.properties"'
        local dup = 0
        forvalues i = 1/`n' {
            if `"`t`i''"' == `"`cand'"' local dup = 1
        }
        if !`dup' {
            local exists = 0
            capture confirm file `"`cand'"'
            if !_rc local exists = 1
            if `n' == 0 | `exists' {
                local ++n
                local t`n' `"`cand'"'
                local c`n' = cond(`n' == 1, 1, `exists')
            }
        }
    }
    * (3) 드론 탐색 체인의 나머지 고정 경로 (DroneLicense.defaultPropsPaths 와 동일)
    *     — 이미 존재할 때만 키 갱신 (신규 생성 금지)
    local home : env HOME
    if `"`home'"' == "" local home : env USERPROFILE
    local cand1 `"`c(sysdir_personal)'stata_mcp.properties"'
    local cand2 `"`home'/Documents/Stata/ado/personal/stata_mcp.properties"'
    local cand3 `"`home'/ado/personal/stata_mcp.properties"'
    forvalues k = 1/3 {
        capture confirm file `"`cand`k''"'
        if !_rc {
            local dup = 0
            forvalues i = 1/`n' {
                if `"`t`i''"' == `"`cand`k''"' local dup = 1
            }
            if !`dup' {
                local ++n
                local t`n' `"`cand`k''"'
                local c`n' = 0
            }
        }
    }

    if `n' == 0 {
        di as error "mcp_set_license: no stata_mcp.properties location found"
        di as error "Make sure this is an environment where mcp_connect works."
        exit 601
    }

    * ─── 일괄 기록 ──────────────────────────────────────────────────────────
    forvalues i = 1/`n' {
        _mcp_lic_write using `"`t`i''"', key(`key') create(`c`i'')
        di as text "[License] Saved → " as result `"`t`i''"'
    }
    if "`quiet'" == "" {
        di as text "[License] Restart the drone to apply: mcp_connect, reset"
    }

    if "`reset'" != "" {
        di as text "[License] reset option → running mcp_connect, reset..."
        mcp_connect, reset
    }
end

* 한 properties 파일의 LICENSE_KEY 줄만 교체/추가 (다른 줄 보존).
* create(0) 이고 파일이 없으면 아무것도 안 함.
program _mcp_lic_write
    version 17.0
    syntax using/, KEY(string) CREATE(integer)

    capture confirm file `"`using'"'
    if _rc & !`create' exit 0

    tempname fh
    local nlines = 0
    capture confirm file `"`using'"'
    if !_rc {
        file open `fh' using `"`using'"', read text
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

    quietly {
        file open `fh' using `"`using'"', write text replace
        forvalues i = 1/`nlines' {
            file write `fh' `"`macval(L`i')'"' _n
        }
        file write `fh' `"LICENSE_KEY="`key'""' _n
        file close `fh'
    }
end

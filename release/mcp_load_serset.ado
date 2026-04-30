*! version 0.5.0  29apr2026
*! Stata MCP — serset 을 작업 프레임에 로드 + (옵션) Mata 직접 CSV export
*!
*! 사용법:
*!     mcp_load_serset <id> [<frame>] [<path>]
*!
*! 동작:
*!     1. <frame> 을 drop/create 후 `id' serset 을 로드 (`serset use, clear').
*!     2. <path> 주어지면 Mata 의 fopen/fput 으로 CSV 직접 작성.
*!        Stata `export delimited' 를 회피해 user r() 매크로 보존.
*!        (export delimited 는 r(N), r(k) 를 stored results 에 저장 → user r() 손실)
*!     3. <frame> 생략 시 디폴트 `_mcp_ss'.
*!
*! 안전장치 (v0.4.0):
*!     - mata fopen 후 fh 를 Stata scalar `__mcp_fh' 에 등록.
*!     - fput 도중 abort 시 program 측이 cap fclose 로 dangling fh 강제 close.
*!     - file descriptor leak 차단 (Stata 세션 동안 누적되지 않게).
*!
*! v0.5.0 변경:
*!     - 문자 변수 지원. mlabel(make) 같은 string 컬럼이 빈 문자열로 빠지던 문제 fix.
*!       Mata 는 numeric/string 을 같은 matrix 에 못 담으므로 numeric view + string view
*!       두 개로 분리해서 컬럼 인덱스 매핑으로 row 단위 조립.
*!     - CSV escape: 문자열에 콤마/큰따옴표/개행 있으면 RFC 4180 식으로 감쌈 (" + 내부 "" + ").
*!
*! 주의:
*!     - graph_meta_put 직후 `.__GraphXXX.sersets[i].id' 로 얻은 id 사용.
*!     - 원본 serset 은 graph 가 drop 되면 자동 소멸하므로 graph 살아있을 때만.

mata:

string scalar _mcp_csv_esc(string scalar s)
{
    if (strpos(s, ",") | strpos(s, char(34)) | strpos(s, char(10)) | strpos(s, char(13))) {
        return(char(34) + subinstr(s, char(34), char(34) + char(34)) + char(34))
    }
    return(s)
}

void _mcp_serset_to_csv(string scalar fname)
{
    real matrix      Vn
    string matrix    Vs
    real rowvector   ns, nidx, sidx
    real scalar      nr, nc, j, i, fh, kn, ks
    string rowvector vars
    string scalar    line, sval

    nc   = st_nvar()
    nr   = st_nobs()
    vars = st_varname(1..nc)
    ns   = J(1, nc, 0)
    for (j = 1; j <= nc; j++) ns[j] = st_isstrvar(j)

    nidx = selectindex(ns :== 0)
    sidx = selectindex(ns :== 1)
    if (cols(nidx)) st_view (Vn, ., nidx)
    if (cols(sidx)) st_sview(Vs, ., sidx)

    // Mata fopen("w") 는 file 이 이미 존재하면 error 602. 선제 unlink.
    if (fileexists(fname)) unlink(fname)

    fh = fopen(fname, "w")
    st_numscalar("__mcp_fh", fh)
    fput(fh, invtokens(vars, ","))

    for (i = 1; i <= nr; i++) {
        line = ""
        kn = 0; ks = 0
        for (j = 1; j <= nc; j++) {
            if (j > 1) line = line + ","
            if (ns[j]) {
                ks++
                sval = Vs[i, ks]
                line = line + _mcp_csv_esc(sval)
            } else {
                kn++
                if (Vn[i, kn] != .) line = line + strofreal(Vn[i, kn], "%18.0g")
            }
        }
        fput(fh, line)
    }
    fclose(fh)
    st_numscalar("__mcp_fh", 0)
}

end


program mcp_load_serset
    args id frame fname
    if "`frame'" == "" local frame "_mcp_ss"
    cap frame drop `frame'
    cap frame create `frame'
    frame `frame' {
        serset `id'
        qui serset use, clear
        if `"`fname'"' != "" {
            cap scalar drop __mcp_fh
            cap noisily mata: _mcp_serset_to_csv(`"`fname'"')
            local rc = _rc
            if `rc' {
                * mata 함수 abort → dangling fh 강제 close
                cap mata: if (st_numscalar("__mcp_fh") != 0) fclose(st_numscalar("__mcp_fh"))
                cap scalar drop __mcp_fh
                error `rc'
            }
            cap scalar drop __mcp_fh
        }
    }
end

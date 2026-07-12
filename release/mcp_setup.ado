*! mcp_setup  v0.2.0  12jul2026
*!
*! Stata-MCP 설정 진입점 (구 mcp_set 흡수) — help DB 를 GitHub 에서 받아
*! 드론 jar 옆에 배치하고, 제어판 메뉴 등록 + 설정 링크(라이선스/기동/제거)를
*! 출력한다. net install 직후 1회 실행, 이후 설정 허브로도 사용.
*!
*! Usage:
*!   mcp_setup             // help DB 다운로드(없으면) + mcp_menu,install + 설정 메뉴
*!   mcp_setup, updatedb   // help DB 갱신만 (다이얼로그 [Update help DB] 버튼용) — 메뉴/허브 생략
*!
*! help DB (~32MB) 는 pkg 에 번들하지 않고 여기서 온디맨드로 받는다 —
*! net install 을 가볍게 유지하기 위함. 파일은 stata-drone.jar 옆에 둔다
*! (드론 HelpDb/HelpDbV2 의 첫 탐색 위치).

cap program drop mcp_setup
program mcp_setup
    version 17.0
    syntax [, UPDATEDB]

    * ─── 드론 jar 위치 = help DB 배치 대상 (mcp_get_license 와 동일 패턴) ──
    capture findfile stata-drone.jar
    if _rc {
        di as error "[Setup] stata-drone.jar 를 찾을 수 없습니다."
        di as error "        먼저 'net install stata-mcp' 로 패키지를 설치하세요."
        exit 601
    }
    local jarpath `"`r(fn)'"'
    local jardir : subinstr local jarpath "stata-drone.jar" ""

    * ─── help DB 목록 + 원격 base ────────────────────────────────────────
    local base "https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release"
    local files stata_cmd_index.json stata_help_corpus.jsonl help_index_v2.json help_nodes_v2.jsonl

    di as text "[Setup] help DB → " as result `"`jardir'"'
    local ndl = 0
    local nskip = 0
    local nfail = 0
    foreach f of local files {
        local dest `"`jardir'`f'"'
        * updatedb 없고 이미 있으면 skip
        if "`updatedb'" == "" {
            capture confirm file `"`dest'"'
            if !_rc {
                di as text "  skip (있음): `f'"
                local nskip = `nskip' + 1
                continue
            }
        }
        di as text "  다운로드: `f' ..."
        capture copy `"`base'/`f'"' `"`dest'"', replace
        if _rc {
            di as error "  실패: `f'  (rc=`=_rc')"
            local nfail = `nfail' + 1
        }
        else {
            local ndl = `ndl' + 1
        }
    }
    di as text "[Setup] help DB — 다운로드 `ndl', skip `nskip', 실패 `nfail'"
    if `nfail' > 0 {
        di as error "[Setup] 일부 실패 — 인터넷/방화벽 확인 후 'mcp_setup, updatedb' 로 재시도하세요."
    }

    * updatedb = help DB 갱신만 (다이얼로그 [Update help DB] 버튼) — 메뉴 등록/허브 생략
    if "`updatedb'" != "" {
        di as text "[Setup] help DB 갱신 완료."
        exit
    }

    * ─── 제어판 메뉴 등록 (profile.do) ───────────────────────────────────
    di as text "[Setup] 제어판 메뉴 등록..."
    capture mcp_menu, install
    if _rc {
        di as error "[Setup] 메뉴 등록 실패 — 수동으로 'mcp_menu, install' 실행하세요."
    }

    * ─── 설정 허브 (구 mcp_set 흡수 — 클릭 링크, 서버·드론 기동 안 함) ────
    di as text ""
    di as text "{bf:[Stata-MCP] Setup}"
    di as text "  라이선스 키 편집:   {stata mcp_edit_license:mcp_edit_license}"
    di as text "  help DB 갱신:        {stata mcp_setup, updatedb:mcp_setup, updatedb}"
    di as text "  서버·드론 기동:      {stata mcp_connect:mcp_connect}"
    di as text "  제거:               {stata mcp_uninstall:mcp_uninstall}"
    di as text ""
end

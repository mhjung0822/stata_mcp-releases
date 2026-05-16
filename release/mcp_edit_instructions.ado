*! mcp_edit_instructions  v0.3.0  17may2026
*!
*! Open stata_mcp_instructions.md (the Claude analysis-rules file the
*! MCP server feeds via `getInstructions`) in Stata's do-file editor.
*!
*! Usage:
*!   mcp_edit_instructions                   // open existing file
*!   mcp_edit_instructions, init             // fetch compact example next to jar
*!   mcp_edit_instructions, init full        // fetch verbose example next to jar
*!   mcp_edit_instructions, init force       // overwrite existing instructions
*!
*! Implementation note:
*! - We always resolve via `findfile stata-mcp-server.jar` and operate on
*!   the file SITTING NEXT TO THE JAR. `findfile <name>.md` would miss it
*!   because Stata only searches first-letter subfolders (e.g. PLUS/s/)
*!   for non-jar files, while net install places jars in PLUS/jar/.
*!   Going through the jar's location keeps `mcp_edit_instructions` and
*!   the running server reading/writing the same file.

cap program drop mcp_edit_instructions
program mcp_edit_instructions
    version 17.0
    syntax [, INIT FULL FORCE]

    * ─── 1. jar 위치 → 그 옆 instructions 경로 산정 ───────────────────────
    capture findfile stata-mcp-server.jar
    if _rc {
        di as error "mcp_edit_instructions: stata-mcp-server.jar not found in adopath"
        di as error "Install first: net install stata-mcp, from(...)"
        exit 601
    }
    local jarpath `"`r(fn)'"'
    local jardir : subinstr local jarpath "stata-mcp-server.jar" ""
    local dest `"`jardir'stata_mcp_instructions.md"'

    * ─── 2. init: release 에서 예시 다운로드 → dest ───────────────────────
    if "`init'" != "" {
        capture confirm file `"`dest'"'
        if !_rc & "`force'" == "" {
            di as error "Already exists: `dest'"
            di as error "기존 편집 보존 — 덮어쓰려면 mcp_edit_instructions, init force"
            exit 602
        }
        local src "stata_mcp_instructions.md"
        if "`full'" != "" local src "stata_mcp_instructions_example_full.md"
        local URL "https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release/`src'"

        di as text "Downloading: " as result "`src'"
        di as text "         → " as result `"`dest'"'
        copy `"`URL'"' `"`dest'"', replace public
    }

    * ─── 3. dest 존재 여부 → open / guidance ──────────────────────────────
    capture confirm file `"`dest'"'
    if _rc {
        di
        di as txt "stata_mcp_instructions.md 가 아직 없음 (jar 옆: `jardir')"
        di as txt "예시를 받아서 시작하려면:"
        di as txt "    {stata mcp_edit_instructions, init:mcp_edit_instructions, init}       // 간결한 기본"
        di as txt "    {stata mcp_edit_instructions, init full:mcp_edit_instructions, init full}  // 상세 버전"
        di
        exit
    }

    di as text "file path: " as result `"`dest'"'
    doedit `"`dest'"'
end

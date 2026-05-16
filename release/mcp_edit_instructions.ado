*! mcp_edit_instructions  v0.1.0  17may2026
*!
*! Open stata_mcp_instructions.md (the Claude analysis-rules file the
*! MCP server feeds via `getInstructions`) in the OS default editor.
*!
*! Usage:
*!   mcp_edit_instructions                   // open existing file
*!   mcp_edit_instructions, init             // fetch compact example next to jar
*!   mcp_edit_instructions, init full        // fetch verbose example next to jar
*!   mcp_edit_instructions, init force       // overwrite existing instructions
*!
*! Notes:
*! - The file lives next to the server jar (resolved via `findfile`), wherever
*!   `net install` placed it (typically `<PLUS>/s/`).
*! - `, init` downloads the example from the GitHub release and copies it to
*!   the jar's directory so the running server picks it up immediately.

cap program drop mcp_edit_instructions
program mcp_edit_instructions
    version 17.0
    syntax [, INIT FULL FORCE]

    * ─── init: download example next to jar ───────────────────────────────
    if "`init'" != "" {
        capture findfile stata-mcp-server.jar
        if _rc {
            di as error "stata-mcp-server.jar not found in adopath"
            di as error "Install first: net install stata-mcp, from(...)"
            exit 601
        }
        local jarpath `"`r(fn)'"'
        local jardir : subinstr local jarpath "stata-mcp-server.jar" ""
        local dest `"`jardir'stata_mcp_instructions.md"'

        * 기존 편집 보호
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

    * ─── open in default editor ───────────────────────────────────────────
    capture findfile stata_mcp_instructions.md
    if _rc {
        di
        di as txt "stata_mcp_instructions.md 가 아직 없음."
        di as txt "예시를 받아서 시작하려면:"
        di as result "    mcp_edit_instructions, init       " as txt "// 간결한 기본"
        di as result "    mcp_edit_instructions, init full  " as txt "// 상세 버전"
        di
        exit
    }
    local f `"`r(fn)'"'
    di as text "Opening: " as result `"`f'"'
    if "`c(os)'" == "MacOSX" {
        shell open "`f'"
    }
    else if "`c(os)'" == "Windows" {
        shell cmd /c start "" "`f'"
    }
    else {
        shell xdg-open "`f'"
    }
end

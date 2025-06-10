function Get-ScriptAst {
    param([string]$Path)
    $text = Get-Content -Raw -Encoding UTF8 $Path
    if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) {
        $text = $text.Substring(1)
    }
    [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$null, [ref]$null)
}

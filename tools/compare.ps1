<#
.SYNOPSIS
    Compare MoonBit yuecharts SVG output against ECharts JS reference SVG.

.DESCRIPTION
    For each example option source in the examples/ directory:
      1. Renders via ECharts JS (tools/echarts-render.js) -> examples/<name>.ref.svg
      2. Renders via MoonBit  (moon run cmd/main)         -> examples/<name>.svg
    Then opens both in the browser/VS Code for visual inspection and reports
    basic structural differences (element count, viewBox, etc.).

.PARAMETER Examples
    Optional list of example names (without extension) to process. Defaults to
    all examples/*.json plus examples/js/*.js.

.PARAMETER Open
    If set, opens each SVG pair in VS Code after rendering.

.EXAMPLE
    .\tools\compare.ps1
    .\tools\compare.ps1 -Examples bar,line,scatter
    .\tools\compare.ps1 -Examples candlestick -Open
#>
param(
    [string[]] $Examples = @(),
    [switch]   $Open
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot   # e.g. E:\yuecharts
Set-Location $root

# Discover examples
if ($Examples.Count -eq 0) {
    $Examples = @(
        Get-ChildItem examples\*.json -File | Select-Object -ExpandProperty BaseName
        Get-ChildItem examples\js\*.js -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty BaseName
    ) | Sort-Object -Unique
}

Write-Host "=== yuecharts vs ECharts comparison ===" -ForegroundColor Cyan
Write-Host "Examples: $($Examples -join ', ')"
Write-Host ""

$results = @()

foreach ($name in $Examples) {
    $jsonFile = "examples\$name.json"
    $jsFile = "examples\js\$name.js"
    $sourceFile = if (Test-Path $jsFile) { $jsFile } elseif (Test-Path $jsonFile) { $jsonFile } else { $null }
    if ($null -eq $sourceFile) {
        Write-Warning "Skipping '$name': examples\$name.json / examples\js\$name.js not found"
        continue
    }

    $suffix = if ($sourceFile.EndsWith('.js')) { ".jsgen" } else { "" }
    $mbFile  = "examples\$name$suffix.svg"
    $refFile = "examples\$name$suffix.ref.svg"

    Write-Host "-- $name" -ForegroundColor Yellow

    # --- MoonBit render ---
    Write-Host "   [MoonBit] moon run cmd/main --target native ..." -NoNewline
    $mbSvg = if ($sourceFile.EndsWith('.js')) {
        node tools/eval-option.js $sourceFile |
            & moon run cmd/main --target native 2>&1
    } else {
        Get-Content $sourceFile -Encoding UTF8 |
            & moon run cmd/main --target native 2>&1
    }
    # moon prints a progress bar to stderr; strip ANSI / non-SVG lines
    $mbSvg = ($mbSvg | Where-Object { $_ -match '<' }) -join "`n"
    $mbSvg | Set-Content $mbFile -Encoding UTF8
    Write-Host " done -> $mbFile"

    # --- JS render ---
    Write-Host "   [JS]     node tools/echarts-render.js ..." -NoNewline
    $jsSvg = node tools/echarts-render.js $sourceFile 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Warning ($jsSvg | Select-Object -First 5 | Out-String)
        $results += [pscustomobject]@{ Name=$name; MB_elems='?'; JS_elems='?'; Match='ERROR' }
        continue
    }
    $jsSvg | Set-Content $refFile -Encoding UTF8
    Write-Host " done -> $refFile"

    # --- Basic structural diff ---
    $mbElems  = ([regex]::Matches($mbSvg,  '<(rect|path|text|circle|line|polyline|polygon)')).Count
    $jsElems  = ([regex]::Matches($jsSvg,  '<(rect|path|text|circle|line|polyline|polygon)')).Count

    $mbVB = if ($mbSvg  -match 'viewBox="([^"]+)"') { $Matches[1] } else { 'n/a' }
    $jsVB = if ($jsSvg  -match 'viewBox="([^"]+)"') { $Matches[1] } else { 'n/a' }

    $match = if ($mbVB -eq $jsVB) { 'same viewBox' } else { "viewBox: MB=[$mbVB] JS=[$jsVB]" }

    Write-Host ("   Elements  MB={0,-5} JS={1,-5}  | {2}" -f $mbElems, $jsElems, $match)
    Write-Host ""

    $results += [pscustomobject]@{
        Name      = $name
        MB_elems  = $mbElems
        JS_elems  = $jsElems
        ViewBox   = $match
    }

    if ($Open) {
        code $mbFile $refFile
    }
}

Write-Host "=== Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

Write-Host ""
Write-Host "SVG pairs saved in examples\:" -ForegroundColor Green
Write-Host "  <name>.svg / <name>.ref.svg           <- JSON example outputs"
Write-Host "  <name>.jsgen.svg / <name>.jsgen.ref.svg <- JS example outputs"
Write-Host ""
Write-Host "Open both files in a browser or VS Code SVG viewer for visual comparison."

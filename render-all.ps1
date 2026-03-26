Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
Set-Location $root

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$exampleFilesByName = @{}
Get-ChildItem examples\*.json -File | ForEach-Object {
    $exampleFilesByName[$_.BaseName] = $_
}
Get-ChildItem examples\js\*.js -File -ErrorAction SilentlyContinue | ForEach-Object {
    $exampleFilesByName[$_.BaseName] = $_
}
$exampleFiles = $exampleFilesByName.GetEnumerator() |
    Sort-Object Name |
    ForEach-Object { $_.Value }

foreach ($file in $exampleFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $svgName = if ($file.Extension -eq '.js') { "$baseName.jsgen.svg" } else { "$baseName.svg" }
    $svgFile = Join-Path $root "examples\$svgName"

    $moonSvgLines = if ($file.Extension -eq '.js') {
        node tools/eval-option.js $file.FullName | moon run cmd/main --target native 2>&1
    } else {
        Get-Content $file.FullName -Encoding UTF8 | moon run cmd/main --target native 2>&1
    }

    $moonSvg = ($moonSvgLines | Where-Object { $_ -match '<' }) -join "`n"
    [System.IO.File]::WriteAllText($svgFile, $moonSvg, $utf8NoBom)
    Write-Host "Rendered $($file.FullName) -> $svgFile"
}

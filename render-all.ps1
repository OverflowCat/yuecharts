Get-ChildItem examples/*.json | ForEach-Object {
    Get-Content $_.FullName -Raw |
        moon run cmd/main --target native 2>&1 |
        Out-File ($_.FullName -replace '\.json$', '.svg') -Force
}

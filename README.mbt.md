# OverflowCat/yuecharts

## Render examples to SVG

```powershell
# Render a single example
moon run cmd/main -- examples/bar.json > examples/bar.svg
moon run cmd/main -- examples/line.json > examples/line.svg
moon run cmd/main -- examples/mixed.json > examples/mixed.svg

# Render all examples at once
Get-ChildItem examples/*.json | ForEach-Object { moon run cmd/main -- $_.FullName > ($_.FullName -replace '\.json$','.svg') }
```
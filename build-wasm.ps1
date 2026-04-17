moon build --target wasm-gc --strip --release
Copy-Item _build/wasm-gc/release/build/cmd/wasm/wasm.wasm cmd/wasm/wasm-gc.wasm

moon build --target wasm --strip --release
Copy-Item _build/wasm/release/build/cmd/wasm/wasm.wasm cmd/wasm/wasm.wasm

# print the two WASM bin sizes for comparison
$wasmGcFile = Get-Item cmd/wasm/wasm-gc.wasm -ErrorAction SilentlyContinue
$wasmFile = Get-Item cmd/wasm/wasm.wasm -ErrorAction SilentlyContinue

if ($wasmGcFile -and $wasmFile) {
    $wasmGcSize = $wasmGcFile.Length / 1024 / 1024
    $wasmSize = $wasmFile.Length / 1024 / 1024
    $ratio = $wasmGcSize / $wasmSize * 100
    
    Write-Host "`nBuild sizes:" -ForegroundColor Cyan
    Write-Host "  wasm-gc.wasm: $("{0:N2}" -f $wasmGcSize) MB" -ForegroundColor Green
    Write-Host "  wasm.wasm:    $("{0:N2}" -f $wasmSize) MB" -ForegroundColor Green
    Write-Host "  wasm-gc is $("{0:N1}" -f $ratio)% of wasm size" -ForegroundColor Yellow
} else {
    Write-Host "Warning: WASM files not found" -ForegroundColor Red
}

# legacy single page html
# Write-Host "`nOpen http://localhost:8960 in your browser" -ForegroundColor Cyan
# python -m http.server 8960 -d .
# exit 0  # python exits with 1 on Ctrl-C; suppress that

# Now use frontend
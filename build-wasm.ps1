moon build --target wasm-gc --strip --release
Copy-Item _build/wasm-gc/release/build/cmd/wasm/wasm.wasm cmd/wasm/wasm-gc.wasm

moon build --target wasm --strip --release
Copy-Item _build/wasm/release/build/cmd/wasm/wasm.wasm cmd/wasm/wasm.wasm

Write-Host "Open http://localhost:8960 in your browser"
python -m http.server 8960 -d .
exit 0  # python exits with 1 on Ctrl-C; suppress that

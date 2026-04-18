<img width="2562" height="1413" alt="frontend" src="https://github.com/user-attachments/assets/246c8b1c-9615-472f-8b9e-ad546080ed76" />

[![WASM live demo](https://img.shields.io/badge/WASM-live_demo-2ea44f?style=for-the-badge&logo=webassembly&logoColor=white)](https://yue.overflow.cat/) Check web demo at https://yue.overflow.cat/!

# yuecharts

`yuecharts` (pronounced as /yɛ.tʃɑɹts/) is a MoonBit port of [Apache ECharts](https://github.com/apache/echarts). The project targets parity with upstream ECharts behavior where feasible in a non-interactive pipeline, with a strong emphasis on direct source mapping from ECharts TS/JS into MoonBit.

> ⚠️ Disclaimer: This is an unofficial, LLM-driven port of ECharts. It is not affiliated with, maintained by, or endorsed by the original ECharts project.

The project currently contains:

- A static renderer: input JSON, output SVG.
- A MoonBit-first implementation with native and wasm-gc targets.
- A compatibility-focused port that tracks upstream ECharts semantics chart-by-chart and option-by-option.

## Supported Chart Types

The repository currently contains renderers under [chart](chart) for:

- Bar
- Boxplot
- Candlestick
- Chord
- EffectScatter
- Funnel
- Gauge
- Graph
- Heatmap
- Line
- Lines
- Map
- Parallel
- PictorialBar
- Pie
- Radar
- Sankey
- Scatter
- Sunburst
- ThemeRiver
- Tree
- Treemap

See implementation files in [chart](chart).

## Quick Start

Prerequisite: install MoonBit toolchain.

Render one example to SVG (stdout):

```powershell
Get-Content examples/bar.json | moon run cmd/main --target native
```

The CLI entry is implemented in [cmd/main/main.mbt](cmd/main/main.mbt).

Programmatic entry points are in [yuecharts.mbt](yuecharts.mbt), including:

- render pipeline
- register_map
- get_map

## Build

```powershell
moon fmt
moon build --target native
moon build --target wasm-gc --strip --release
# target is at _build/wasm-gc/release/build/cmd/wasm/wasm.wasm
moon build --target wasm --strip --release
# target is at _build/wasm/release/build/cmd/wasm/wasm.wasm
```

Build sizes:
- wasm-gc: 0.56 MB
- wasm:    1.25 MB

## Test

```powershell
moon test --target native
```

## Dynamic features

yuecharts supports a subset of ECharts interaction/action semantics by transforming option/state before rendering.

Examples include:

- legend select/unselect/toggle
- data select/unselect/toggle
- highlight/downplay
- dataZoom subset
- focusNodeAdjacency/unfocusNodeAdjacency (graph)
- dragNode (sankey local position persistence)

## Repository Layout

- [chart](chart): chart renderers
- [component](component): component renderers (legend, axis, visualMap, geo, ...)
- [coord](coord): coordinate systems
- [option](option): option and action parsing
- [graphic](graphic): scene graph primitives
- [svg](svg): SVG painting backend
- [interaction](interaction): interaction envelope/state landing
- [examples](examples): JSON examples
- [tools](tools): export/compare/dev scripts

## License

Apache-2.0.

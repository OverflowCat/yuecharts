# ECharts to yuecharts Port Map

## 2026-03-26 Update

- option/types.mbt now derives Eq for SeriesType, enabling registry/stage filtering to use enum equality directly instead of ad-hoc string names.
- core/registry.mbt, chart/install.mbt, and yuecharts.mbt now store and compare typed @option.SeriesType? for stage/chart applicability; component/install.mbt also aligns aria visual priority with upstream PRIORITY.VISUAL.ARIA = 6000.
- `chart/pictorial_bar.mbt` now additionally translates the `path://` symbol branch from `util/symbol.ts`/`util/graphic.ts` for static cartesian pictorial bars: series-level and item-level `symbol` both work, path symbols are normalized to the upstream `symbolPatternSize = 400` coordinate system, and `itemStyle.opacity` plus `barCategoryGap` now affect the static SVG output.
- `chart/pictorial_bar.mbt` now covers a larger static subset of `installPictorialBar.ts`, `PictorialBarSeries.ts`, and `PictorialBarView.ts`: `symbolSize`, `symbolRepeat`, `symbolClip`, `symbolPosition`, `symbolBoundingData`, `symbolOffset`, and `symbolRepeatDirection` are partially translated for cartesian/category static SVG output.
- `visual/aria.mbt` now covers static `aria.ts` label generation with default English template strings and option overrides parsed through `option/parse.mbt`.
- Added example/reference pairs: `examples/pictorialbar-offset.{json,svg,ref.svg}`, `examples/pictorialbar-symbolsize.{json,svg,ref.svg}`, and `examples/aria-template.{json,svg,ref.svg}`.
- Added `scale/interval_wbtest.mbt`, translating the portable subset of `test/ut/spec/scale/interval.test.ts` onto the current `LinearScale` port.

## 2026-03-27 Update

- Added first-pass polar coordinate plumbing across `option/types.mbt`, `option/parse.mbt`, `coord/polar.mbt`, `layout/polar.mbt`, `core/registry.mbt`, `layout/install.mbt`, and `yuecharts.mbt`, covering static `polar` / `angleAxis` / `radiusAxis` parsing plus root layout creation.
- `component/axis.mbt` now renders static polar angle/radius axes and split lines based on `AngleAxisView.ts` / `RadiusAxisView.ts`.
- `chart/bar.mbt`, `chart/line.mbt`, `chart/scatter.mbt`, and `chart/effect_scatter.mbt` now accept polar render context; `examples/polar-bar.json`, `examples/polar-line.json`, and `examples/polar-scatter.json` were rendered against JS SSR references.
- Current status is still `partial`: the static SVG output now exists and uses the polar coordinate model, but `barPolar.ts` / `LineView.ts` behavior is not yet 1:1 with upstream and the generated element structure still differs from ECharts SSR.
## Scope

This file is a source-to-port map for the ECharts files that matter to the
current MoonBit port work in `gap.md`.

Included:
- all currently implemented yuecharts `.mbt` files
- ECharts chart/component/coord/data/layout/scale/visual/core/model/view files
  that are already translated, partially translated, or are direct blockers for
  missing features in `gap.md`
- direct renderer/animation/processor/label/loading/legacy dependencies that
  affect feature parity

Excluded on purpose:
- `src/i18n/*`
- `src/export/*`
- `src/theme/*`
- generic `src/util/*` files that are not direct translation blockers for the
  current static-SVG port plan

## Legend

- `=> <mbt path>` means the ECharts file has a concrete MoonBit landing place.
- `=>` left blank means not translated / not implemented yet.
- Status:
  - `translated`: there is a focused MoonBit file covering the file's core role
  - `partial`: the logic is merged into a broader `.mbt` file, or only a subset
    of the TS behavior exists
  - `missing`: no real port exists yet

## Current yuecharts tree

```text
E:\yuecharts
├── moon.mod.json
├── moon.pkg
├── yuecharts.mbt
├── yuecharts_test.mbt
├── yuecharts_wbtest.mbt
├── gap.md
├── map.md
├── chart
│   ├── moon.pkg
│   ├── bar.mbt
│   ├── boxplot.mbt
│   ├── candlestick.mbt
│   ├── effect_scatter.mbt
│   ├── funnel.mbt
│   ├── gauge.mbt
│   ├── heatmap.mbt
│   ├── install.mbt
│   ├── line.mbt
│   ├── pictorial_bar.mbt
│   ├── pie.mbt
│   ├── radar.mbt
│   ├── scatter.mbt
│   ├── sunburst.mbt
│   └── treemap.mbt
├── cmd
│   └── main
│       ├── moon.pkg
│       └── main.mbt
├── component
│   ├── moon.pkg
│   ├── axis.mbt
│   ├── grid_lines.mbt
│   ├── install.mbt
│   ├── legend.mbt
│   └── title.mbt
├── core
│   ├── moon.pkg
│   └── registry.mbt
├── coord
│   ├── moon.pkg
│   └── cartesian.mbt
├── graphic
│   ├── moon.pkg
│   ├── color.mbt
│   ├── color_wbtest.mbt
│   ├── element.mbt
│   ├── element_wbtest.mbt
│   ├── transform.mbt
│   └── transform_wbtest.mbt
├── layout
│   ├── moon.pkg
│   ├── grid.mbt
│   ├── grid_wbtest.mbt
│   └── install.mbt
├── option
│   ├── moon.pkg
│   ├── parse.mbt
│   └── types.mbt
├── examples
│   ├── aria-template.json / .svg / .ref.svg
│   ├── bar.json / .svg / .ref.svg
│   ├── boxplot.json / .svg / .ref.svg
│   ├── candlestick.json / .svg / .ref.svg
│   ├── donut.json / .svg
│   ├── effectscatter.json / .svg / .ref.svg
│   ├── funnel.json / .svg / .ref.svg
│   ├── gauge.json / .svg
│   ├── heatmap.json / .svg / .ref.svg
│   ├── line.json / .svg / .ref.svg
│   ├── mixed.json / .svg / .ref.svg
│   ├── multibar.json / .svg
│   ├── pictorialbar.json / .svg / .ref.svg
│   ├── pictorialbar-body-fill.json
│   ├── pictorialbar-clip.json / .svg / .ref.svg
│   ├── pictorialbar-offset.json / .svg / .ref.svg
│   ├── pictorialbar-path.json / .svg / .ref.svg
│   ├── pictorialbar-path-dup.json / .svg / .ref.svg
│   ├── pictorialbar-symbolsize.json / .svg / .ref.svg
│   ├── pie.json / .svg
│   ├── pie-legend-selected.json
│   ├── js
│   │   └── polar-line2.js
│   ├── polar-line2.jsgen.svg / .jsgen.ref.svg
│   ├── radar.json / .svg
│   ├── scatter.json / .svg / .ref.svg
│   ├── sunburst.json / .svg / .echarts.svg
│   └── treemap.json / .svg / .ref.svg
├── scale
│   ├── moon.pkg
│   ├── linear.mbt
│   ├── number_helper_wbtest.mbt
│   ├── ordinal.mbt
│   ├── ordinal_wbtest.mbt
│   └── interval_wbtest.mbt
├── svg
│   ├── moon.pkg
│   └── painter.mbt
├── tools
│   ├── compare.ps1
│   ├── eval-option.js
│   ├── echarts-render.js
│   └── option-loader.js
└── visual
    ├── moon.pkg
    ├── aria.mbt
    └── palette.mbt
```

Notes:
- This tree intentionally lists source, tests, examples, and comparison tools; it omits generated `_build/`, local scratch `_tmp/`, and editor metadata.
- `examples/` is now broad enough to cover every currently implemented chart type, with `.ref.svg` present for many JS-vs-MoonBit comparisons and a few output-only fixtures still waiting for reference baselines.

## Important dependency files outside `echarts/src`

These files are not under `E:\recharts\echarts\src`, but they are real source
dependencies for the current MoonBit port and are explicitly referenced by the
existing `.mbt` comments.

```text
zrender
├── src
│   ├── core
│   │   ├── BoundingRect.ts => graphic/transform.mbt [partial] Feature: bbox geometry
│   │   ├── matrix.ts => graphic/transform.mbt [partial] Feature: affine transform matrix
│   │   └── Point.ts => graphic/transform.mbt [translated] Feature: point geometry
│   ├── graphic
│   │   ├── Path.ts => graphic/element.mbt [partial] Feature: path element model
│   │   ├── Shape.ts => graphic/element.mbt [translated] Feature: scene graph element model
│   │   └── shape
│   │       └── * => graphic/element.mbt [partial] Feature: rect/circle/line/polygon primitives
│   ├── svg
│   │   └── Painter.ts => svg/painter.mbt [translated] Feature: SVG serialization
│   └── tool
│       └── color.ts => graphic/color.mbt [translated] Feature: color parsing and interpolation
```

## ECharts source-to-port mapping tree

```text
E:\recharts\echarts\src
├── echarts.ts => yuecharts.mbt [partial] Feature: top-level render pipeline
├── echarts.all.ts =>  [missing] Feature: full bundle entry
├── echarts.common.ts =>  [missing] Feature: common bundle entry
├── echarts.simple.ts =>  [missing] Feature: simple bundle entry
├── echarts.blank.ts =>  [missing] Feature: blank bundle entry
├── extension.ts => core/registry.mbt [partial] Feature: extension registration API
│
├── animation
│   ├── basicTransition.ts =>  [missing] Feature: animation transition infra
│   ├── customGraphicKeyframeAnimation.ts =>  [missing] Feature: keyframe animation
│   ├── customGraphicTransition.ts =>  [missing] Feature: custom graphic transition
│   ├── morphTransitionHelper.ts =>  [missing] Feature: morph transition
│   └── universalTransition.ts =>  [missing] Feature: universal transition
│
├── core
│   ├── echarts.ts => yuecharts.mbt [partial] Feature: chart lifecycle and render entry
│   ├── extension.ts => core/registry.mbt [partial] Feature: install/register metadata surface
│   ├── CoordinateSystem.ts =>  [missing] Feature: coordinate system registry
│   ├── ExtensionAPI.ts =>  [missing] Feature: extension runtime API
│   ├── ExtendedElement.ts =>  [missing] Feature: graphic extension element layer
│   ├── impl.ts =>  [missing] Feature: impl registration
│   ├── lifecycle.ts =>  [missing] Feature: lifecycle pipeline
│   ├── locale.ts =>  [missing] Feature: locale support
│   ├── Scheduler.ts =>  [missing] Feature: task scheduler
│   └── task.ts =>  [missing] Feature: pipeline task graph
│
├── model
│   ├── Model.ts => option/types.mbt [partial] Feature: generic option model
│   ├── Component.ts => option/types.mbt [partial] Feature: component model base
│   ├── Series.ts => option/types.mbt [partial] Feature: series model base
│   ├── Global.ts => option/parse.mbt [partial] Feature: global option/model state
│   ├── globalDefault.ts => option/types.mbt [partial] Feature: default option values
│   ├── internalComponentCreator.ts =>  [missing] Feature: internal component factory
│   ├── OptionManager.ts => option/parse.mbt [partial] Feature: setOption normalization
│   ├── referHelper.ts =>  [missing] Feature: model reference resolution
│   └── mixin
│       ├── areaStyle.ts => visual/palette.mbt [partial] Feature: area style model mixin
│       ├── dataFormat.ts => option/types.mbt [partial] Feature: data format mixin
│       ├── itemStyle.ts => visual/palette.mbt [partial] Feature: item style model mixin
│       ├── lineStyle.ts => visual/palette.mbt [partial] Feature: line style model mixin
│       ├── makeStyleMapper.ts =>  [missing] Feature: style mapper helper
│       ├── palette.ts => visual/palette.mbt [partial] Feature: palette model mixin
│       └── textStyle.ts => component/title.mbt [partial] Feature: text style model mixin
│
├── view
│   ├── Chart.ts =>  [missing] Feature: chart view base class
│   └── Component.ts =>  [missing] Feature: component view base class
│
├── visual
│   ├── aria.ts => visual/aria.mbt [translated] Feature: aria visual text generation
│   ├── commonVisualTypes.ts =>  [missing] Feature: visual type defs
│   ├── decal.ts =>  [missing] Feature: decal pattern visual
│   ├── helper.ts => visual/palette.mbt [partial] Feature: visual helper glue
│   ├── LegendVisualProvider.ts => component/legend.mbt [partial] Feature: legend visual binding
│   ├── style.ts => visual/palette.mbt [translated] Feature: palette and style defaults
│   ├── symbol.ts =>  [missing] Feature: symbol visual helper
│   ├── tokens.ts => visual/palette.mbt [partial] Feature: default theme tokens
│   ├── visualDefault.ts => visual/palette.mbt [partial] Feature: visual defaults
│   ├── VisualMapping.ts =>  [missing] Feature: visualMap core mapping
│   └── visualSolution.ts =>  [missing] Feature: visual mapping pipeline
│
├── scale
│   ├── Scale.ts =>  [missing] Feature: scale base class
│   ├── Interval.ts => scale/linear.mbt [translated] Feature: linear interval scale
│   ├── Ordinal.ts => scale/ordinal.mbt [translated] Feature: ordinal scale
│   ├── Log.ts =>  [missing] Feature: log scale
│   ├── Time.ts =>  [missing] Feature: time scale
│   ├── helper.ts => scale/linear.mbt [partial] Feature: scale helpers
│   ├── break.ts =>  [missing] Feature: axis break support
│   └── breakImpl.ts =>  [missing] Feature: axis break impl
│
├── data
│   ├── DataDiffer.ts =>  [missing] Feature: data diff
│   ├── DataStore.ts =>  [missing] Feature: columnar data storage
│   ├── Graph.ts =>  [missing] Feature: graph data structure
│   ├── OrdinalMeta.ts =>  [missing] Feature: ordinal metadata
│   ├── SeriesData.ts =>  [missing] Feature: series data container
│   ├── SeriesDimensionDefine.ts =>  [missing] Feature: dimension schema
│   ├── Source.ts =>  [missing] Feature: dataset source abstraction
│   ├── Tree.ts =>  [missing] Feature: tree data structure
│   └── helper
│       ├── createDimensions.ts =>  [missing] Feature: dimension creation
│       ├── dataProvider.ts =>  [missing] Feature: source data provider
│       ├── dataStackHelper.ts =>  [missing] Feature: stacked data helper
│       ├── dataValueHelper.ts =>  [missing] Feature: data value helper
│       ├── dimensionHelper.ts =>  [missing] Feature: dimension helper
│       ├── linkList.ts =>  [missing] Feature: graph/tree link helper
│       ├── linkSeriesData.ts =>  [missing] Feature: linked series data
│       ├── SeriesDataSchema.ts =>  [missing] Feature: series data schema
│       ├── sourceHelper.ts =>  [missing] Feature: source normalization
│       ├── sourceManager.ts =>  [missing] Feature: source manager
│       └── transform.ts =>  [missing] Feature: data transform helper
│
├── coord
│   ├── Axis.ts =>  [missing] Feature: axis base
│   ├── AxisBaseModel.ts => option/types.mbt [partial] Feature: axis option base
│   ├── CoordinateSystem.ts =>  [missing] Feature: coordinate system abstraction
│   ├── View.ts =>  [missing] Feature: generic box/view coordinate system
│   ├── axisAlignTicks.ts =>  [missing] Feature: aligned ticks
│   ├── axisCommonTypes.ts => option/types.mbt [partial] Feature: axis type defs
│   ├── axisDefault.ts => option/types.mbt [partial] Feature: axis defaults
│   ├── axisHelper.ts => component/axis.mbt [partial] Feature: axis helper
│   ├── axisModelCommonMixin.ts => option/types.mbt [partial] Feature: axis model mixin
│   ├── axisModelCreator.ts =>  [missing] Feature: axis model factory
│   ├── axisTickLabelBuilder.ts => component/axis.mbt [partial] Feature: axis tick/label building
│   ├── scaleRawExtentInfo.ts => layout/grid.mbt [partial] Feature: scale extent resolution
│   │
│   ├── cartesian
│   │   ├── Axis2D.ts => coord/cartesian.mbt [translated] Feature: cartesian axis
│   │   ├── AxisModel.ts => option/types.mbt [partial] Feature: cartesian axis model
│   │   ├── Cartesian.ts => coord/cartesian.mbt [partial] Feature: cartesian base
│   │   ├── Cartesian2D.ts => coord/cartesian.mbt [translated] Feature: cartesian2d coordinate
│   │   ├── cartesianAxisHelper.ts => component/axis.mbt [partial] Feature: cartesian axis helper
│   │   ├── defaultAxisExtentFromData.ts => layout/grid.mbt [partial] Feature: axis extent from series data
│   │   ├── Grid.ts => layout/grid.mbt, layout/install.mbt [translated] Feature: grid layout + root layout stage registration
│   │   ├── GridModel.ts => option/types.mbt [partial] Feature: grid option model
│   │   ├── legacyContainLabel.ts =>  [missing] Feature: containLabel compat
│   │   └── prepareCustom.ts =>  [missing] Feature: custom series cartesian adapter
│   │
│   ├── radar
│   │   ├── IndicatorAxis.ts => chart/radar.mbt [partial] Feature: radar indicator axis
│   │   ├── Radar.ts => chart/radar.mbt [partial] Feature: radar coordinate system
│   │   └── RadarModel.ts => option/types.mbt [partial] Feature: radar option model
│   │
│   ├── polar
│   │   ├── AngleAxis.ts => coord/polar.mbt [partial] Feature: polar angle axis
│   │   ├── AxisModel.ts => option/types.mbt, option/parse.mbt [partial] Feature: polar axis model
│   │   ├── Polar.ts => coord/polar.mbt [partial] Feature: polar coordinate system
│   │   ├── polarCreator.ts => layout/polar.mbt, layout/install.mbt [partial] Feature: polar creator
│   │   ├── PolarModel.ts => option/types.mbt, option/parse.mbt [partial] Feature: polar model
│   │   ├── prepareCustom.ts =>  [missing] Feature: polar custom adapter
│   │   └── RadiusAxis.ts => coord/polar.mbt [partial] Feature: polar radius axis
│   │
│   ├── single
│   │   ├── AxisModel.ts =>  [missing] Feature: singleAxis model
│   │   ├── Single.ts =>  [missing] Feature: single coordinate system
│   │   ├── SingleAxis.ts =>  [missing] Feature: single axis
│   │   ├── singleAxisHelper.ts =>  [missing] Feature: singleAxis helper
│   │   ├── singleCreator.ts =>  [missing] Feature: singleAxis creator
│   │   └── prepareCustom.ts =>  [missing] Feature: singleAxis custom adapter
│   │
│   ├── parallel
│   │   ├── AxisModel.ts =>  [missing] Feature: parallel axis model
│   │   ├── Parallel.ts =>  [missing] Feature: parallel coordinate system
│   │   ├── ParallelAxis.ts =>  [missing] Feature: parallel axis
│   │   ├── parallelCreator.ts =>  [missing] Feature: parallel creator
│   │   ├── ParallelModel.ts =>  [missing] Feature: parallel model
│   │   └── parallelPreprocessor.ts =>  [missing] Feature: parallel option preprocessor
│   │
│   ├── geo
│   │   ├── Geo.ts =>  [missing] Feature: geo coordinate system
│   │   ├── geoCreator.ts =>  [missing] Feature: geo creator
│   │   ├── GeoJSONResource.ts =>  [missing] Feature: GeoJSON resource loading
│   │   ├── GeoModel.ts =>  [missing] Feature: geo model
│   │   ├── geoSourceManager.ts =>  [missing] Feature: registered map source manager
│   │   ├── GeoSVGResource.ts =>  [missing] Feature: SVG map resource
│   │   ├── geoTypes.ts =>  [missing] Feature: geo type defs
│   │   ├── parseGeoJson.ts =>  [missing] Feature: GeoJSON parser
│   │   ├── prepareCustom.ts =>  [missing] Feature: geo custom adapter
│   │   ├── Region.ts =>  [missing] Feature: geo region model
│   │   └── fix
│   │       ├── diaoyuIsland.ts =>  [missing] Feature: China map fixup
│   │       ├── geoCoord.ts =>  [missing] Feature: geo coord fixup
│   │       ├── nanhai.ts =>  [missing] Feature: South China Sea fixup
│   │       └── textCoord.ts =>  [missing] Feature: geo label coord fixup
│   │
│   ├── calendar
│   │   ├── Calendar.ts => coord/calendar.mbt [translated] Feature: calendar coordinate system
│   │   ├── CalendarModel.ts => option/types.mbt, option/parse.mbt [partial] Feature: calendar model
│   │   └── prepareCustom.ts => coord/calendar.mbt [translated] Feature: calendar custom adapter
│   │
│   └── matrix
│       ├── Matrix.ts =>  [missing] Feature: matrix coordinate system
│       ├── MatrixBodyCorner.ts =>  [missing] Feature: matrix corner helper
│       ├── matrixCoordHelper.ts =>  [missing] Feature: matrix coord helper
│       ├── MatrixDim.ts =>  [missing] Feature: matrix dimension types
│       ├── MatrixModel.ts =>  [missing] Feature: matrix model
│       └── prepareCustom.ts =>  [missing] Feature: matrix custom adapter
│
├── layout
│   ├── barGrid.ts => chart/bar.mbt [partial] Feature: bar grid layout
│   ├── barPolar.ts => chart/bar.mbt [partial] Feature: bar layout on polar
│   └── points.ts => chart/scatter.mbt, chart/effect_scatter.mbt [partial] Feature: point layout for scatter/effectScatter
│
├── processor
│   ├── dataFilter.ts =>  [missing] Feature: series data filtering
│   ├── dataSample.ts =>  [missing] Feature: data sampling
│   ├── dataStack.ts =>  [missing] Feature: data stacking
│   └── negativeDataFilter.ts =>  [missing] Feature: negative-value filtering
│
├── renderer
│   ├── installCanvasRenderer.ts =>  [missing] Feature: canvas renderer install
│   └── installSVGRenderer.ts => svg/painter.mbt [partial] Feature: SVG renderer install/entry
│
├── loading
│   └── default.ts =>  [missing] Feature: default loading animation
│
├── legacy
│   ├── dataSelectAction.ts =>  [missing] Feature: legacy data select actions
│   └── getTextRect.ts => svg/painter.mbt [partial] Feature: text measuring helper
│
├── label
│   ├── installLabelLayout.ts =>  [missing] Feature: label layout registration
│   ├── labelGuideHelper.ts => chart/pie.mbt [partial] Feature: label guide lines
│   ├── labelLayoutHelper.ts =>  [missing] Feature: generic label layout
│   ├── LabelManager.ts =>  [missing] Feature: label collision manager
│   ├── labelStyle.ts => graphic/element.mbt [partial] Feature: label style
│   └── sectorLabel.ts => chart/pie.mbt [partial] Feature: sector label placement
│
├── preprocessor
│   ├── backwardCompat.ts => option/parse.mbt [partial] Feature: option backward compat
│   └── helper
│       └── compatStyle.ts => option/parse.mbt [partial] Feature: compat style conversion
│
├── component
│   ├── aria/install.ts => component/install.mbt, visual/aria.mbt [partial] Feature: aria component entry + visual registration
│   ├── axisPointer.ts =>  [missing] Feature: axisPointer component entry
│   ├── brush.ts =>  [missing] Feature: brush component entry
│   ├── calendar.ts =>  [missing] Feature: calendar component entry
│   ├── dataset.ts =>  [missing] Feature: dataset component entry
│   ├── dataZoom.ts =>  [missing] Feature: dataZoom component entry
│   ├── dataZoomInside.ts =>  [missing] Feature: inside dataZoom entry
│   ├── dataZoomSelect.ts =>  [missing] Feature: select dataZoom entry
│   ├── dataZoomSlider.ts =>  [missing] Feature: slider dataZoom entry
│   ├── geo.ts =>  [missing] Feature: geo component entry
│   ├── graphic.ts =>  [missing] Feature: graphic component entry
│   ├── grid.ts => layout/grid.mbt [partial] Feature: grid component entry
│   ├── gridSimple.ts =>  [missing] Feature: simple grid entry
│   ├── legend.ts => component/legend.mbt [partial] Feature: legend component entry
│   ├── legendPlain.ts => component/legend.mbt [partial] Feature: plain legend entry
│   ├── legendScroll.ts =>  [missing] Feature: scroll legend entry
│   ├── markArea.ts =>  [missing] Feature: markArea component entry
│   ├── markLine.ts =>  [missing] Feature: markLine component entry
│   ├── markPoint.ts =>  [missing] Feature: markPoint component entry
│   ├── matrix.ts =>  [missing] Feature: matrix component entry
│   ├── parallel.ts =>  [missing] Feature: parallel component entry
│   ├── polar.ts => component/install.mbt, component/axis.mbt [partial] Feature: polar component entry
│   ├── radar.ts => chart/radar.mbt [partial] Feature: radar component entry
│   ├── singleAxis.ts =>  [missing] Feature: singleAxis component entry
│   ├── thumbnail.ts =>  [missing] Feature: thumbnail component entry
│   ├── timeline.ts =>  [missing] Feature: timeline component entry
│   ├── title.ts => component/title.mbt [translated] Feature: title component entry
│   ├── toolbox.ts =>  [missing] Feature: toolbox component entry
│   ├── tooltip.ts =>  [missing] Feature: tooltip component entry
│   ├── transform.ts =>  [missing] Feature: transform component entry
│   ├── visualMap.ts => chart/heatmap.mbt [partial] Feature: visualMap component entry
│   ├── visualMapContinuous.ts => chart/heatmap.mbt [partial] Feature: continuous visualMap entry
│   ├── visualMapPiecewise.ts =>  [missing] Feature: piecewise visualMap entry
│   │
│   ├── title
│   │   └── install.ts => component/title.mbt [translated] Feature: title install/defaults
│   │
│   ├── legend
│   │   ├── install.ts => component/legend.mbt [partial] Feature: legend install
│   │   ├── installLegendPlain.ts => component/legend.mbt [partial] Feature: plain legend install
│   │   ├── installLegendScroll.ts =>  [missing] Feature: scroll legend install
│   │   ├── LegendModel.ts => component/legend.mbt [partial] Feature: legend model
│   │   ├── LegendView.ts => component/legend.mbt [translated] Feature: plain legend view
│   │   ├── legendAction.ts =>  [missing] Feature: legend select action
│   │   ├── legendFilter.ts =>  [missing] Feature: legend filtering
│   │   ├── ScrollableLegendModel.ts =>  [missing] Feature: scroll legend model
│   │   ├── ScrollableLegendView.ts =>  [missing] Feature: scroll legend view
│   │   └── scrollableLegendAction.ts =>  [missing] Feature: scroll legend action
│   │
│   ├── axis
│   │   ├── AngleAxisView.ts =>  [missing] Feature: angle axis view
│   │   ├── AxisBuilder.ts => component/axis.mbt [partial] Feature: axis builder
│   │   ├── axisAction.ts =>  [missing] Feature: axis actions
│   │   ├── axisBreakHelper.ts =>  [missing] Feature: axis break helper
│   │   ├── axisBreakHelperImpl.ts =>  [missing] Feature: axis break impl
│   │   ├── axisSplitHelper.ts => component/grid_lines.mbt [translated] Feature: split line rendering
│   │   ├── AxisView.ts => component/axis.mbt [translated] Feature: axis rendering
│   │   ├── CartesianAxisView.ts => component/axis.mbt [partial] Feature: cartesian axis view
│   │   ├── installBreak.ts =>  [missing] Feature: axis break install
│   │   ├── parallelAxisAction.ts =>  [missing] Feature: parallel axis action
│   │   ├── ParallelAxisView.ts =>  [missing] Feature: parallel axis view
│   │   ├── RadiusAxisView.ts =>  [missing] Feature: radius axis view
│   │   └── SingleAxisView.ts =>  [missing] Feature: single axis view
│   │
│   ├── axisPointer
│   │   ├── AxisPointer.ts =>  [missing] Feature: axisPointer entry
│   │   ├── AxisPointerModel.ts =>  [missing] Feature: axisPointer model
│   │   ├── AxisPointerView.ts =>  [missing] Feature: axisPointer view
│   │   ├── axisTrigger.ts =>  [missing] Feature: axis trigger logic
│   │   ├── BaseAxisPointer.ts =>  [missing] Feature: base axis pointer
│   │   ├── CartesianAxisPointer.ts =>  [missing] Feature: cartesian axis pointer
│   │   ├── findPointFromSeries.ts =>  [missing] Feature: axisPointer point lookup
│   │   ├── globalListener.ts =>  [missing] Feature: global pointer listener
│   │   ├── install.ts =>  [missing] Feature: axisPointer install
│   │   ├── modelHelper.ts =>  [missing] Feature: axisPointer model helper
│   │   ├── PolarAxisPointer.ts =>  [missing] Feature: polar axis pointer
│   │   ├── SingleAxisPointer.ts =>  [missing] Feature: single axis pointer
│   │   └── viewHelper.ts =>  [missing] Feature: axisPointer view helper
│   │
│   ├── tooltip
│   │   ├── helper.ts =>  [missing] Feature: tooltip helper
│   │   ├── install.ts =>  [missing] Feature: tooltip install
│   │   ├── seriesFormatTooltip.ts =>  [missing] Feature: series tooltip formatter
│   │   ├── tooltipMarkup.ts =>  [missing] Feature: tooltip markup builder
│   │   ├── TooltipHTMLContent.ts =>  [missing] Feature: HTML tooltip content
│   │   ├── TooltipModel.ts =>  [missing] Feature: tooltip model
│   │   ├── TooltipRichContent.ts =>  [missing] Feature: rich tooltip content
│   │   └── TooltipView.ts =>  [missing] Feature: tooltip view
│   │
│   ├── dataZoom
│   │   ├── AxisProxy.ts =>  [missing] Feature: axis window proxy
│   │   ├── dataZoomAction.ts =>  [missing] Feature: dataZoom action
│   │   ├── DataZoomModel.ts =>  [missing] Feature: dataZoom model
│   │   ├── dataZoomProcessor.ts =>  [missing] Feature: dataZoom processor
│   │   ├── DataZoomView.ts =>  [missing] Feature: dataZoom base view
│   │   ├── helper.ts =>  [missing] Feature: dataZoom helper
│   │   ├── history.ts =>  [missing] Feature: zoom history
│   │   ├── InsideZoomModel.ts =>  [missing] Feature: inside zoom model
│   │   ├── InsideZoomView.ts =>  [missing] Feature: inside zoom view
│   │   ├── install.ts =>  [missing] Feature: dataZoom install
│   │   ├── installCommon.ts =>  [missing] Feature: common dataZoom install
│   │   ├── installDataZoomInside.ts =>  [missing] Feature: inside dataZoom install
│   │   ├── installDataZoomSelect.ts =>  [missing] Feature: select dataZoom install
│   │   ├── installDataZoomSlider.ts =>  [missing] Feature: slider dataZoom install
│   │   ├── roams.ts =>  [missing] Feature: roam binding
│   │   ├── SelectZoomModel.ts =>  [missing] Feature: select zoom model
│   │   ├── SelectZoomView.ts =>  [missing] Feature: select zoom view
│   │   ├── SliderZoomModel.ts =>  [missing] Feature: slider zoom model
│   │   └── SliderZoomView.ts =>  [missing] Feature: slider zoom view
│   │
│   ├── visualMap
│   │   ├── ContinuousModel.ts =>  [missing] Feature: continuous visualMap model
│   │   ├── ContinuousView.ts =>  [missing] Feature: continuous visualMap view
│   │   ├── helper.ts =>  [missing] Feature: visualMap helper
│   │   ├── install.ts =>  [missing] Feature: visualMap install
│   │   ├── installCommon.ts =>  [missing] Feature: visualMap common install
│   │   ├── installVisualMapContinuous.ts =>  [missing] Feature: continuous visualMap install
│   │   ├── installVisualMapPiecewise.ts =>  [missing] Feature: piecewise visualMap install
│   │   ├── PiecewiseModel.ts =>  [missing] Feature: piecewise visualMap model
│   │   ├── PiecewiseView.ts =>  [missing] Feature: piecewise visualMap view
│   │   ├── preprocessor.ts =>  [missing] Feature: visualMap preprocessor
│   │   ├── typeDefaulter.ts =>  [missing] Feature: visualMap type defaulting
│   │   ├── visualEncoding.ts => chart/heatmap.mbt [partial] Feature: visual encoding
│   │   ├── visualMapAction.ts =>  [missing] Feature: visualMap action
│   │   ├── VisualMapModel.ts => chart/heatmap.mbt [partial] Feature: visualMap model subset
│   │   └── VisualMapView.ts =>  [missing] Feature: visualMap view
│   │
│   ├── marker
│   │   ├── checkMarkerInSeries.ts =>  [missing] Feature: marker precheck
│   │   ├── installMarkArea.ts =>  [missing] Feature: markArea install
│   │   ├── installMarkLine.ts =>  [missing] Feature: markLine install
│   │   ├── installMarkPoint.ts =>  [missing] Feature: markPoint install
│   │   ├── MarkAreaModel.ts =>  [missing] Feature: markArea model
│   │   ├── MarkAreaView.ts =>  [missing] Feature: markArea view
│   │   ├── markerHelper.ts =>  [missing] Feature: marker helper
│   │   ├── MarkerModel.ts =>  [missing] Feature: marker base model
│   │   ├── MarkerView.ts =>  [missing] Feature: marker base view
│   │   ├── MarkLineModel.ts =>  [missing] Feature: markLine model
│   │   ├── MarkLineView.ts =>  [missing] Feature: markLine view
│   │   ├── MarkPointModel.ts =>  [missing] Feature: markPoint model
│   │   └── MarkPointView.ts =>  [missing] Feature: markPoint view
│   │
│   ├── toolbox
│   │   ├── featureManager.ts =>  [missing] Feature: toolbox feature registry
│   │   ├── install.ts =>  [missing] Feature: toolbox install
│   │   ├── ToolboxModel.ts =>  [missing] Feature: toolbox model
│   │   ├── ToolboxView.ts =>  [missing] Feature: toolbox view
│   │   └── feature
│   │       ├── Brush.ts =>  [missing] Feature: toolbox brush feature
│   │       ├── DataView.ts =>  [missing] Feature: toolbox data view
│   │       ├── DataZoom.ts =>  [missing] Feature: toolbox dataZoom feature
│   │       ├── MagicType.ts =>  [missing] Feature: toolbox magicType feature
│   │       ├── Restore.ts =>  [missing] Feature: toolbox restore feature
│   │       └── SaveAsImage.ts =>  [missing] Feature: toolbox saveAsImage feature
│   │
│   ├── timeline
│   │   ├── install.ts =>  [missing] Feature: timeline install
│   │   ├── preprocessor.ts =>  [missing] Feature: timeline preprocessor
│   │   ├── SliderTimelineModel.ts =>  [missing] Feature: slider timeline model
│   │   ├── SliderTimelineView.ts =>  [missing] Feature: slider timeline view
│   │   ├── timelineAction.ts =>  [missing] Feature: timeline action
│   │   ├── TimelineAxis.ts =>  [missing] Feature: timeline axis
│   │   ├── TimelineModel.ts =>  [missing] Feature: timeline model
│   │   └── TimelineView.ts =>  [missing] Feature: timeline view
│   │
│   ├── parallel
│   │   ├── install.ts =>  [missing] Feature: parallel component install
│   │   └── ParallelView.ts =>  [missing] Feature: parallel component view
│   │
│   ├── geo
│   │   ├── install.ts =>  [missing] Feature: geo component install
│   │   └── GeoView.ts =>  [missing] Feature: geo component view
│   │
│   ├── graphic
│   │   ├── install.ts =>  [missing] Feature: graphic component install
│   │   ├── GraphicModel.ts =>  [missing] Feature: graphic model
│   │   └── GraphicView.ts =>  [missing] Feature: graphic view
│   │
│   ├── aria
│   │   ├── install.ts =>  [missing] Feature: aria install
│   │   └── preprocessor.ts =>  [missing] Feature: aria preprocessor
│   │
│   ├── brush
│   │   ├── BrushModel.ts =>  [missing] Feature: brush model
│   │   ├── BrushView.ts =>  [missing] Feature: brush view
│   │   ├── install.ts =>  [missing] Feature: brush install
│   │   ├── preprocessor.ts =>  [missing] Feature: brush preprocessor
│   │   ├── selector.ts =>  [missing] Feature: brush selector
│   │   └── visualEncoding.ts =>  [missing] Feature: brush visual encoding
│   │
│   ├── calendar
│   │   ├── install.ts => component/install.mbt [partial] Feature: calendar install
│   │   └── CalendarView.ts => component/calendar.mbt [translated] Feature: calendar view
│   │
│   ├── matrix
│   │   ├── install.ts =>  [missing] Feature: matrix install
│   │   └── MatrixView.ts =>  [missing] Feature: matrix view
│   │
│   ├── polar
│   │   └── install.ts => layout/polar.mbt, layout/install.mbt, component/install.mbt [partial] Feature: polar install
│   │
│   ├── radar
│   │   ├── install.ts => chart/radar.mbt [partial] Feature: radar install
│   │   └── RadarView.ts => chart/radar.mbt [partial] Feature: radar component view
│   │
│   ├── singleAxis
│   │   └── install.ts =>  [missing] Feature: singleAxis install
│   │
│   ├── grid
│   │   ├── install.ts => layout/grid.mbt [partial] Feature: grid install
│   │   └── installSimple.ts =>  [missing] Feature: simple grid install
│   │
│   ├── dataset
│   │   └── install.ts =>  [missing] Feature: dataset install
│   │
│   ├── transform
│   │   ├── filterTransform.ts =>  [missing] Feature: filter transform
│   │   ├── install.ts =>  [missing] Feature: transform install
│   │   └── sortTransform.ts =>  [missing] Feature: sort transform
│   │
│   ├── thumbnail
│   │   ├── install.ts =>  [missing] Feature: thumbnail install
│   │   ├── ThumbnailBridgeImpl.ts =>  [missing] Feature: thumbnail bridge impl
│   │   ├── ThumbnailModel.ts =>  [missing] Feature: thumbnail model
│   │   └── ThumbnailView.ts =>  [missing] Feature: thumbnail view
│   │
│   └── helper
│       ├── BrushController.ts =>  [missing] Feature: brush interaction controller
│       ├── brushHelper.ts =>  [missing] Feature: brush helper
│       ├── BrushTargetManager.ts =>  [missing] Feature: brush target manager
│       ├── cursorHelper.ts =>  [missing] Feature: cursor helper
│       ├── interactionMutex.ts =>  [missing] Feature: interaction mutex
│       ├── listComponent.ts =>  [missing] Feature: list component helper
│       ├── MapDraw.ts =>  [missing] Feature: geo/map drawing helper
│       ├── RoamController.ts =>  [missing] Feature: roam interaction controller
│       ├── roamHelper.ts =>  [missing] Feature: roam helper/action sync
│       ├── sliderMove.ts =>  [missing] Feature: slider move helper
│       └── thumbnailBridge.ts =>  [missing] Feature: thumbnail bridge helper
│
├── chart
│   ├── bar.ts => chart/bar.mbt [partial] Feature: bar chart entry
│   ├── boxplot.ts => chart/boxplot.mbt [partial] Feature: boxplot chart entry
│   ├── candlestick.ts => chart/candlestick.mbt [partial] Feature: candlestick chart entry
│   ├── chord.ts =>  [missing] Feature: chord chart entry
│   ├── custom.ts =>  [missing] Feature: custom chart entry
│   ├── effectScatter.ts => chart/effect_scatter.mbt [partial] Feature: effectScatter chart entry
│   ├── funnel.ts => chart/funnel.mbt [partial] Feature: funnel chart entry
│   ├── gauge.ts => chart/gauge.mbt [partial] Feature: gauge chart entry
│   ├── graph.ts =>  [missing] Feature: graph chart entry
│   ├── heatmap.ts => chart/heatmap.mbt [partial] Feature: heatmap chart entry
│   ├── line.ts => chart/line.mbt [partial] Feature: line chart entry
│   ├── lines.ts =>  [missing] Feature: lines chart entry
│   ├── map.ts =>  [missing] Feature: map chart entry
│   ├── parallel.ts =>  [missing] Feature: parallel chart entry
│   ├── pictorialBar.ts => chart/pictorial_bar.mbt [partial] Feature: pictorial bar chart entry
│   ├── pie.ts => chart/pie.mbt [partial] Feature: pie chart entry
│   ├── radar.ts => chart/radar.mbt [partial] Feature: radar chart entry
│   ├── sankey.ts =>  [missing] Feature: sankey chart entry
│   ├── scatter.ts => chart/scatter.mbt [partial] Feature: scatter chart entry
│   ├── sunburst.ts => chart/sunburst.mbt [partial] Feature: sunburst chart entry
│   ├── themeRiver.ts =>  [missing] Feature: themeRiver chart entry
│   ├── tree.ts =>  [missing] Feature: tree chart entry
│   └── treemap.ts => chart/treemap.mbt [partial] Feature: treemap chart entry
│   │
│   ├── helper
│   │   ├── createClipPathFromCoordSys.ts =>  [missing] Feature: series clip path helper
│   │   ├── createGraphFromNodeEdge.ts =>  [missing] Feature: graph/sankey/chord data builder
│   │   ├── createRenderPlanner.ts =>  [missing] Feature: progressive render planner
│   │   ├── createSeriesData.ts =>  [missing] Feature: general series data creation
│   │   ├── createSeriesDataSimply.ts =>  [missing] Feature: simple series data creation
│   │   ├── EffectLine.ts =>  [missing] Feature: animated line effect
│   │   ├── EffectPolyline.ts =>  [missing] Feature: animated polyline effect
│   │   ├── EffectSymbol.ts =>  [missing] Feature: animated symbol effect
│   │   ├── enableAriaDecalForTree.ts =>  [missing] Feature: tree aria/decal helper
│   │   ├── labelHelper.ts => chart/pie.mbt [partial] Feature: chart label helper
│   │   ├── LargeLineDraw.ts =>  [missing] Feature: large line draw
│   │   ├── LargeSymbolDraw.ts =>  [missing] Feature: large symbol draw
│   │   ├── Line.ts =>  [missing] Feature: line primitive helper
│   │   ├── LineDraw.ts =>  [missing] Feature: line draw helper
│   │   ├── LinePath.ts =>  [missing] Feature: line path helper
│   │   ├── multipleGraphEdgeHelper.ts =>  [missing] Feature: multi-edge graph helper
│   │   ├── Polyline.ts =>  [missing] Feature: polyline helper
│   │   ├── sectorHelper.ts => chart/pie.mbt [partial] Feature: sector path helper
│   │   ├── Symbol.ts =>  [missing] Feature: chart symbol helper
│   │   ├── SymbolDraw.ts =>  [missing] Feature: symbol draw helper
│   │   ├── treeHelper.ts =>  [missing] Feature: tree helper
│   │   └── whiskerBoxCommon.ts => chart/boxplot.mbt [partial] Feature: boxplot/candlestick common geometry
│   │
│   ├── line
│   │   ├── helper.ts => chart/line.mbt [partial] Feature: line helper
│   │   ├── install.ts => chart/line.mbt [partial] Feature: line install
│   │   ├── lineAnimationDiff.ts =>  [missing] Feature: line update diff
│   │   ├── LineSeries.ts => chart/line.mbt [partial] Feature: line series model
│   │   ├── LineView.ts => chart/line.mbt [translated] Feature: line renderer
│   │   └── poly.ts => chart/line.mbt [partial] Feature: line/polyline path helper
│   │
│   ├── bar
│   │   ├── BarSeries.ts => chart/bar.mbt [partial] Feature: bar series model
│   │   ├── BarView.ts => chart/bar.mbt [translated] Feature: bar renderer
│   │   ├── BaseBarSeries.ts => chart/bar.mbt [partial] Feature: base bar model
│   │   ├── install.ts => chart/bar.mbt [partial] Feature: bar install
│   │   ├── installPictorialBar.ts => chart/pictorial_bar.mbt [partial] Feature: pictorial bar install
│   │   ├── PictorialBarSeries.ts => chart/pictorial_bar.mbt [partial] Feature: pictorial bar series
│   │   └── PictorialBarView.ts => chart/pictorial_bar.mbt [partial] Feature: pictorial bar view
│   │
│   ├── scatter
│   │   ├── install.ts => chart/scatter.mbt [partial] Feature: scatter install
│   │   ├── jitterLayout.ts =>  [missing] Feature: scatter jitter
│   │   ├── ScatterSeries.ts => chart/scatter.mbt [partial] Feature: scatter series model
│   │   └── ScatterView.ts => chart/scatter.mbt [translated] Feature: scatter renderer
│   │
│   ├── effectScatter
│   │   ├── EffectScatterSeries.ts => chart/effect_scatter.mbt [partial] Feature: effectScatter series
│   │   ├── EffectScatterView.ts => chart/effect_scatter.mbt [translated] Feature: effectScatter renderer
│   │   └── install.ts => chart/effect_scatter.mbt [partial] Feature: effectScatter install
│   │
│   ├── pie
│   │   ├── install.ts => chart/pie.mbt [partial] Feature: pie install
│   │   ├── labelLayout.ts => chart/pie.mbt [partial] Feature: pie label layout
│   │   ├── pieLayout.ts => chart/pie.mbt [translated] Feature: pie layout
│   │   ├── PieSeries.ts => chart/pie.mbt [partial] Feature: pie series model
│   │   └── PieView.ts => chart/pie.mbt [translated] Feature: pie renderer
│   │
│   ├── sunburst
│   │   ├── install.ts => chart/sunburst.mbt [partial] Feature: sunburst install
│   │   ├── SunburstPiece.ts => chart/sunburst.mbt [partial] Feature: sunburst piece geometry
│   │   ├── SunburstSeries.ts => chart/sunburst.mbt [partial] Feature: sunburst series model
│   │   ├── sunburstAction.ts =>  [missing] Feature: sunburst action
│   │   ├── sunburstLayout.ts => chart/sunburst.mbt [translated] Feature: sunburst layout
│   │   ├── sunburstVisual.ts => chart/sunburst.mbt [partial] Feature: sunburst visual
│   │   └── SunburstView.ts => chart/sunburst.mbt [translated] Feature: sunburst renderer
│   │
│   ├── treemap
│   │   ├── Breadcrumb.ts =>  [missing] Feature: treemap breadcrumb
│   │   ├── install.ts => chart/treemap.mbt [partial] Feature: treemap install
│   │   ├── treemapAction.ts =>  [missing] Feature: treemap action
│   │   ├── treemapLayout.ts => chart/treemap.mbt [translated] Feature: treemap layout
│   │   ├── TreemapSeries.ts => chart/treemap.mbt [partial] Feature: treemap series model
│   │   ├── treemapVisual.ts => chart/treemap.mbt [partial] Feature: treemap visual
│   │   └── TreemapView.ts => chart/treemap.mbt [translated] Feature: treemap renderer
│   │
│   ├── funnel
│   │   ├── FunnelSeries.ts => chart/funnel.mbt [partial] Feature: funnel series model
│   │   ├── funnelLayout.ts => chart/funnel.mbt [translated] Feature: funnel layout
│   │   ├── FunnelView.ts => chart/funnel.mbt [translated] Feature: funnel renderer
│   │   └── install.ts => chart/funnel.mbt [partial] Feature: funnel install
│   │
│   ├── gauge
│   │   ├── GaugeSeries.ts => chart/gauge.mbt [partial] Feature: gauge series model
│   │   ├── GaugeView.ts => chart/gauge.mbt [translated] Feature: gauge renderer
│   │   ├── install.ts => chart/gauge.mbt [partial] Feature: gauge install
│   │   └── PointerPath.ts => chart/gauge.mbt [partial] Feature: gauge pointer path
│   │
│   ├── radar
│   │   ├── backwardCompat.ts => option/parse.mbt [partial] Feature: radar backward compat
│   │   ├── install.ts => chart/radar.mbt [partial] Feature: radar install
│   │   ├── radarLayout.ts => chart/radar.mbt [translated] Feature: radar layout
│   │   ├── RadarSeries.ts => chart/radar.mbt [partial] Feature: radar series model
│   │   └── RadarView.ts => chart/radar.mbt [translated] Feature: radar renderer
│   │
│   ├── heatmap
│   │   ├── HeatmapLayer.ts =>  [missing] Feature: canvas heatmap layer
│   │   ├── HeatmapSeries.ts => chart/heatmap.mbt, option/types.mbt, option/parse.mbt [partial] Feature: heatmap series model incl. calendar coordinateSystem/data parsing
│   │   ├── HeatmapView.ts => chart/heatmap.mbt [translated] Feature: heatmap renderer incl. calendar branch
│   │   └── install.ts => chart/install.mbt, chart/heatmap.mbt [partial] Feature: heatmap install
│   │
│   ├── candlestick
│   │   ├── candlestickLayout.ts => chart/candlestick.mbt [translated] Feature: candlestick layout
│   │   ├── CandlestickSeries.ts => chart/candlestick.mbt [partial] Feature: candlestick series model
│   │   ├── candlestickVisual.ts => chart/candlestick.mbt [partial] Feature: candlestick visual
│   │   ├── CandlestickView.ts => chart/candlestick.mbt [translated] Feature: candlestick renderer
│   │   ├── install.ts => chart/candlestick.mbt [partial] Feature: candlestick install
│   │   └── preprocessor.ts => option/parse.mbt [partial] Feature: candlestick preprocessor
│   │
│   ├── boxplot
│   │   ├── boxplotLayout.ts => chart/boxplot.mbt [translated] Feature: boxplot layout
│   │   ├── BoxplotSeries.ts => chart/boxplot.mbt [partial] Feature: boxplot series model
│   │   ├── boxplotTransform.ts =>  [missing] Feature: boxplot transform
│   │   ├── BoxplotView.ts => chart/boxplot.mbt [translated] Feature: boxplot renderer
│   │   ├── install.ts => chart/boxplot.mbt [partial] Feature: boxplot install
│   │   └── prepareBoxplotData.ts =>  [missing] Feature: boxplot data preparation
│   │
│   ├── graph
│   │   ├── adjustEdge.ts =>  [missing] Feature: graph edge adjustment
│   │   ├── categoryFilter.ts =>  [missing] Feature: graph category filter
│   │   ├── categoryVisual.ts =>  [missing] Feature: graph category visual
│   │   ├── circularLayout.ts =>  [missing] Feature: graph circular layout
│   │   ├── circularLayoutHelper.ts =>  [missing] Feature: graph circular helper
│   │   ├── createView.ts =>  [missing] Feature: graph view coord creator
│   │   ├── edgeVisual.ts =>  [missing] Feature: graph edge visual
│   │   ├── forceHelper.ts =>  [missing] Feature: graph force helper
│   │   ├── forceLayout.ts =>  [missing] Feature: graph force layout
│   │   ├── GraphSeries.ts =>  [missing] Feature: graph series model
│   │   ├── graphHelper.ts =>  [missing] Feature: graph helper
│   │   ├── GraphView.ts =>  [missing] Feature: graph renderer
│   │   ├── install.ts =>  [missing] Feature: graph install
│   │   ├── simpleLayout.ts =>  [missing] Feature: graph simple layout
│   │   └── simpleLayoutHelper.ts =>  [missing] Feature: graph simple layout helper
│   │
│   ├── chord
│   │   ├── ChordEdge.ts =>  [missing] Feature: chord edge shape
│   │   ├── chordLayout.ts =>  [missing] Feature: chord layout
│   │   ├── ChordPiece.ts =>  [missing] Feature: chord piece shape
│   │   ├── ChordSeries.ts =>  [missing] Feature: chord series model
│   │   ├── ChordView.ts =>  [missing] Feature: chord renderer
│   │   └── install.ts =>  [missing] Feature: chord install
│   │
│   ├── sankey
│   │   ├── install.ts =>  [missing] Feature: sankey install
│   │   ├── sankeyLayout.ts =>  [missing] Feature: sankey layout
│   │   ├── SankeySeries.ts =>  [missing] Feature: sankey series model
│   │   ├── sankeyVisual.ts =>  [missing] Feature: sankey visual
│   │   └── SankeyView.ts =>  [missing] Feature: sankey renderer
│   │
│   ├── tree
│   │   ├── install.ts =>  [missing] Feature: tree install
│   │   ├── layoutHelper.ts =>  [missing] Feature: tree layout helper
│   │   ├── traversalHelper.ts =>  [missing] Feature: tree traversal helper
│   │   ├── treeAction.ts =>  [missing] Feature: tree action
│   │   ├── treeLayout.ts =>  [missing] Feature: tree layout
│   │   ├── TreeSeries.ts =>  [missing] Feature: tree series model
│   │   ├── treeVisual.ts =>  [missing] Feature: tree visual
│   │   └── TreeView.ts =>  [missing] Feature: tree renderer
│   │
│   ├── themeRiver
│   │   ├── install.ts =>  [missing] Feature: themeRiver install
│   │   ├── themeRiverLayout.ts =>  [missing] Feature: themeRiver layout
│   │   ├── ThemeRiverSeries.ts =>  [missing] Feature: themeRiver series model
│   │   └── ThemeRiverView.ts =>  [missing] Feature: themeRiver renderer
│   │
│   ├── parallel
│   │   ├── install.ts =>  [missing] Feature: parallel chart install
│   │   ├── ParallelSeries.ts =>  [missing] Feature: parallel series model
│   │   ├── parallelVisual.ts =>  [missing] Feature: parallel visual
│   │   └── ParallelView.ts =>  [missing] Feature: parallel chart renderer
│   │
│   ├── lines
│   │   ├── install.ts =>  [missing] Feature: lines install
│   │   ├── linesLayout.ts =>  [missing] Feature: lines layout
│   │   ├── LinesSeries.ts =>  [missing] Feature: lines series model
│   │   ├── linesVisual.ts =>  [missing] Feature: lines visual
│   │   └── LinesView.ts =>  [missing] Feature: lines renderer
│   │
│   ├── map
│   │   ├── install.ts =>  [missing] Feature: map install
│   │   ├── mapDataStatistic.ts =>  [missing] Feature: map statistic processor
│   │   ├── MapSeries.ts =>  [missing] Feature: map series model
│   │   ├── mapSymbolLayout.ts =>  [missing] Feature: map symbol layout
│   │   └── MapView.ts =>  [missing] Feature: map renderer
│   │
│   └── custom
│       ├── CustomSeries.ts =>  [missing] Feature: custom series model
│       ├── customSeriesRegister.ts =>  [missing] Feature: custom renderItem registry
│       ├── CustomView.ts =>  [missing] Feature: custom renderer
│       └── install.ts =>  [missing] Feature: custom install
│
└── notes
    ├── Current MoonBit infra files with the widest coverage:
    │   ├── core/registry.mbt [minimal registry + ChartViewLike/ComponentViewLike/ScaleLike/CoordLike + stage priority/execution key]
    │   ├── layout/install.mbt [root layout stage registration + priority]
    │   ├── yuecharts.mbt [top-level processor/layout/visual sequencing + registry-driven dispatch]
    │   ├── option/parse.mbt [JSON parsing and option normalization subset]
    │   ├── option/types.mbt [shared option structures]
    │   ├── layout/grid.mbt [grid bbox and cartesian scale building]
    │   ├── coord/cartesian.mbt [cartesian coordinate object]
    │   ├── scale/linear.mbt [linear scale]
    │   ├── scale/ordinal.mbt [ordinal scale]
    │   ├── visual/aria.mbt [static aria label generation]
    │   ├── visual/palette.mbt [palette and partial style defaults]
    │   ├── graphic/color.mbt [color parsing]
    │   ├── graphic/element.mbt [scene graph primitives]
    │   ├── graphic/transform.mbt [transform matrix subset]
    │   └── svg/painter.mbt [SVG serialization]
    └── Important parity gap:
        Most translated MoonBit files currently merge multiple TS files into one
        renderer-oriented `.mbt`, so many TS `SeriesModel` / `install.ts` /
        `visual.ts` / `action.ts` files are still only partially covered even
        when the final static SVG output exists.
```



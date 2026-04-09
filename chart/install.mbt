// Corresponds to: echarts/src/chart/*/install.ts for the currently implemented chart types.

///|
struct BarChartView {}

///|
pub impl @core.ChartViewLike for BarChartView with render(_self, ctx) {
  render_bars(ctx.option, ctx.coord, polar=ctx.polar)
}

///|
struct LineChartView {}

///|
pub impl @core.ChartViewLike for LineChartView with render(_self, ctx) {
  render_lines(ctx.option, ctx.coord, polar=ctx.polar)
}

///|
struct ParallelChartView {}

///|
pub impl @core.ChartViewLike for ParallelChartView with render(_self, ctx) {
  render_parallels(ctx.option, parallel=ctx.parallel)
}

///|
struct LinesChartView {}

///|
pub impl @core.ChartViewLike for LinesChartView with render(_self, ctx) {
  render_lines_chart(ctx.option, ctx.coord, polar=ctx.polar, geo=ctx.geo)
}

///|
struct PictorialBarChartView {}

///|
pub impl @core.ChartViewLike for PictorialBarChartView with render(_self, ctx) {
  render_pictorial_bars(ctx.option, ctx.coord)
}

///|
struct MapChartView {}

///|
pub impl @core.ChartViewLike for MapChartView with render(_self, ctx) {
  render_maps(ctx.option, geo=ctx.geo)
}

///|
struct ScatterChartView {}

///|
pub impl @core.ChartViewLike for ScatterChartView with render(_self, ctx) {
  render_scatters(ctx.option, ctx.coord, polar=ctx.polar, geo=ctx.geo)
}

///|
struct EffectScatterChartView {}

///|
pub impl @core.ChartViewLike for EffectScatterChartView with render(_self, ctx) {
  render_effect_scatters(ctx.option, ctx.coord, polar=ctx.polar, geo=ctx.geo)
}

///|
struct PieChartView {}

///|
pub impl @core.ChartViewLike for PieChartView with render(_self, ctx) {
  render_pies(ctx.option, ctx.coord)
}

///|
struct SunburstChartView {}

///|
pub impl @core.ChartViewLike for SunburstChartView with render(_self, ctx) {
  render_sunbursts(ctx.option, ctx.coord)
}

///|
struct TreemapChartView {}

///|
pub impl @core.ChartViewLike for TreemapChartView with render(_self, ctx) {
  render_treemaps(ctx.option, ctx.coord)
}

///|
struct RadarChartView {}

///|
pub impl @core.ChartViewLike for RadarChartView with render(_self, ctx) {
  render_radars(ctx.option)
}

///|
struct CandlestickChartView {}

///|
pub impl @core.ChartViewLike for CandlestickChartView with render(_self, ctx) {
  render_candlesticks(ctx.option, ctx.coord)
}

///|
struct HeatmapChartView {}

///|
pub impl @core.ChartViewLike for HeatmapChartView with render(_self, ctx) {
  render_heatmaps(
    ctx.option,
    ctx.coord,
    calendar?=ctx.calendar,
    matrix?=@coord.Matrix::build(ctx.option),
  )
}

///|
struct BoxplotChartView {}

///|
pub impl @core.ChartViewLike for BoxplotChartView with render(_self, ctx) {
  render_boxplots(ctx.option, ctx.coord)
}

///|
struct FunnelChartView {}

///|
pub impl @core.ChartViewLike for FunnelChartView with render(_self, ctx) {
  render_funnels(ctx.option, ctx.coord)
}

///|
struct GaugeChartView {}

///|
pub impl @core.ChartViewLike for GaugeChartView with render(_self, ctx) {
  render_gauges(ctx.option)
}

///|
struct TreeChartView {}

///|
pub impl @core.ChartViewLike for TreeChartView with render(_self, ctx) {
  render_trees(ctx.option, ctx.coord)
}

///|
struct ThemeRiverChartView {}

///|
pub impl @core.ChartViewLike for ThemeRiverChartView with render(_self, ctx) {
  render_theme_rivers(ctx.option, ctx.single)
}

///|
struct ChordChartView {}

///|
pub impl @core.ChartViewLike for ChordChartView with render(_self, ctx) {
  render_chords(ctx.option, ctx.coord)
}

///|
struct SankeyChartView {}

///|
pub impl @core.ChartViewLike for SankeyChartView with render(_self, ctx) {
  render_sankeys(ctx.option, ctx.view)
}

///|
fn register_chart(
  registry : @core.Registry,
  series_type : @option.SeriesType,
  has_data_filter : Bool,
  has_negative_filter : Bool,
  view : &@core.ChartViewLike,
) -> Unit {
  registry.register_chart(@core.ChartRegistration::new(series_type, view))
  if has_data_filter {
    registry.register_processor(
      @core.ProcessorRegistration::new(
        Some(series_type),
        1000,
        Some("data_filter"),
      ),
    )
  }
  if has_negative_filter {
    registry.register_processor(
      @core.ProcessorRegistration::new(
        Some(series_type),
        1000,
        Some("negative_data_filter"),
      ),
    )
  }
}

///|
pub fn install_bar(registry : @core.Registry) -> Unit {
  // echarts/src/chart/bar/install.ts
  // echarts/src/chart/bar/BarSeries.ts
  // echarts/src/chart/bar/BarView.ts
  // layout: echarts/src/layout/barGrid.ts, echarts/src/layout/barPolar.ts
  register_chart(registry, @option.SeriesType::Bar, false, false, BarChartView::{

  })
}

///|
pub fn install_line(registry : @core.Registry) -> Unit {
  // echarts/src/chart/line/install.ts
  // echarts/src/chart/line/LineSeries.ts
  // echarts/src/chart/line/LineView.ts
  // layout: echarts/src/layout/points.ts
  register_chart(registry, @option.SeriesType::Line, false, false, LineChartView::{

  })
}

///|
pub fn install_parallel(registry : @core.Registry) -> Unit {
  // echarts/src/chart/parallel/install.ts
  // echarts/src/chart/parallel/ParallelSeries.ts
  // echarts/src/chart/parallel/ParallelView.ts
  // visual: echarts/src/chart/parallel/parallelVisual.ts
  register_chart(registry, @option.SeriesType::Parallel, false, false, ParallelChartView::{

  })
}

///|
pub fn install_lines(registry : @core.Registry) -> Unit {
  // echarts/src/chart/lines/install.ts
  // echarts/src/chart/lines/LinesSeries.ts
  // echarts/src/chart/lines/LinesView.ts
  // layout: echarts/src/chart/lines/linesLayout.ts
  register_chart(registry, @option.SeriesType::Lines, false, false, LinesChartView::{

  })
}

///|
pub fn install_pictorial_bar(registry : @core.Registry) -> Unit {
  // echarts/src/chart/bar/installPictorialBar.ts
  // echarts/src/chart/bar/PictorialBarSeries.ts
  // echarts/src/chart/bar/PictorialBarView.ts
  // layout: echarts/src/layout/barGrid.ts
  register_chart(registry, @option.SeriesType::PictorialBar, false, false, PictorialBarChartView::{

  })
}

///|
pub fn install_map(registry : @core.Registry) -> Unit {
  // echarts/src/chart/map/install.ts
  // echarts/src/chart/map/MapSeries.ts
  // echarts/src/chart/map/MapView.ts
  // processor: echarts/src/chart/map/mapDataStatistic.ts
  register_chart(registry, @option.SeriesType::Map, false, false, MapChartView::{

  })
  registry.register_processor(
    @core.ProcessorRegistration::new(
      Some(@option.SeriesType::Map),
      5000,
      Some("map_data_statistic"),
    ),
  )
}

///|
pub fn install_scatter(registry : @core.Registry) -> Unit {
  // echarts/src/chart/scatter/install.ts
  // echarts/src/chart/scatter/ScatterSeries.ts
  // echarts/src/chart/scatter/ScatterView.ts
  // layout: echarts/src/layout/points.ts
  register_chart(registry, @option.SeriesType::Scatter, false, false, ScatterChartView::{

  })
}

///|
pub fn install_effect_scatter(registry : @core.Registry) -> Unit {
  // echarts/src/chart/effectScatter/install.ts
  // echarts/src/chart/effectScatter/EffectScatterSeries.ts
  // echarts/src/chart/effectScatter/EffectScatterView.ts
  // layout: echarts/src/layout/points.ts
  register_chart(registry, @option.SeriesType::EffectScatter, false, false, EffectScatterChartView::{

  })
}

///|
pub fn install_pie(registry : @core.Registry) -> Unit {
  // echarts/src/chart/pie/install.ts
  // echarts/src/chart/pie/PieSeries.ts
  // echarts/src/chart/pie/PieView.ts
  // layout: echarts/src/chart/pie/pieLayout.ts
  // visual: echarts/src/chart/pie/labelLayout.ts
  // processor: echarts/src/processor/dataFilter.ts, negativeDataFilter.ts
  register_chart(registry, @option.SeriesType::Pie, true, true, PieChartView::{

  })
}

///|
pub fn install_sunburst(registry : @core.Registry) -> Unit {
  // echarts/src/chart/sunburst/install.ts
  // echarts/src/chart/sunburst/SunburstSeries.ts
  // echarts/src/chart/sunburst/SunburstView.ts
  // layout: echarts/src/chart/sunburst/sunburstLayout.ts
  // visual: echarts/src/chart/sunburst/sunburstVisual.ts
  // processor: echarts/src/processor/dataFilter.ts
  register_chart(registry, @option.SeriesType::Sunburst, true, false, SunburstChartView::{

  })
}

///|
pub fn install_treemap(registry : @core.Registry) -> Unit {
  // echarts/src/chart/treemap/install.ts
  // echarts/src/chart/treemap/TreemapSeries.ts
  // echarts/src/chart/treemap/TreemapView.ts
  // layout: echarts/src/chart/treemap/treemapLayout.ts
  // visual: echarts/src/chart/treemap/treemapVisual.ts
  register_chart(registry, @option.SeriesType::Treemap, false, false, TreemapChartView::{

  })
}

///|
pub fn install_radar(registry : @core.Registry) -> Unit {
  // echarts/src/chart/radar/install.ts
  // echarts/src/chart/radar/RadarSeries.ts
  // echarts/src/chart/radar/RadarView.ts
  // layout: echarts/src/chart/radar/radarLayout.ts
  // processor: echarts/src/processor/dataFilter.ts
  register_chart(registry, @option.SeriesType::Radar, true, false, RadarChartView::{

  })
}

///|
pub fn install_candlestick(registry : @core.Registry) -> Unit {
  // echarts/src/chart/candlestick/install.ts
  // echarts/src/chart/candlestick/CandlestickSeries.ts
  // echarts/src/chart/candlestick/CandlestickView.ts
  // layout: echarts/src/chart/candlestick/candlestickLayout.ts
  // visual: echarts/src/chart/candlestick/candlestickVisual.ts
  register_chart(registry, @option.SeriesType::Candlestick, false, false, CandlestickChartView::{

  })
}

///|
pub fn install_heatmap(registry : @core.Registry) -> Unit {
  // echarts/src/chart/heatmap/install.ts
  // echarts/src/chart/heatmap/HeatmapSeries.ts
  // echarts/src/chart/heatmap/HeatmapView.ts
  register_chart(registry, @option.SeriesType::Heatmap, false, false, HeatmapChartView::{

  })
}

///|
pub fn install_boxplot(registry : @core.Registry) -> Unit {
  // echarts/src/chart/boxplot/install.ts
  // echarts/src/chart/boxplot/BoxplotSeries.ts
  // echarts/src/chart/boxplot/BoxplotView.ts
  // layout: echarts/src/chart/boxplot/boxplotLayout.ts
  register_chart(registry, @option.SeriesType::Boxplot, false, false, BoxplotChartView::{

  })
}

///|
pub fn install_funnel(registry : @core.Registry) -> Unit {
  // echarts/src/chart/funnel/install.ts
  // echarts/src/chart/funnel/FunnelSeries.ts
  // echarts/src/chart/funnel/FunnelView.ts
  // layout: echarts/src/chart/funnel/funnelLayout.ts
  // processor: echarts/src/processor/dataFilter.ts
  register_chart(registry, @option.SeriesType::Funnel, true, false, FunnelChartView::{

  })
}

///|
pub fn install_gauge(registry : @core.Registry) -> Unit {
  // echarts/src/chart/gauge/install.ts
  // echarts/src/chart/gauge/GaugeSeries.ts
  // echarts/src/chart/gauge/GaugeView.ts
  register_chart(registry, @option.SeriesType::Gauge, false, false, GaugeChartView::{

  })
}

///|
pub fn install_theme_river(registry : @core.Registry) -> Unit {
  // echarts/src/chart/themeRiver/install.ts
  // echarts/src/chart/themeRiver/ThemeRiverSeries.ts
  // echarts/src/chart/themeRiver/ThemeRiverView.ts
  // layout: echarts/src/chart/themeRiver/themeRiverLayout.ts
  // processor: echarts/src/processor/dataFilter.ts
  register_chart(registry, @option.SeriesType::ThemeRiver, true, false, ThemeRiverChartView::{

  })
}

///|
pub fn install_tree(registry : @core.Registry) -> Unit {
  // echarts/src/chart/tree/install.ts
  // echarts/src/chart/tree/TreeSeries.ts
  // echarts/src/chart/tree/TreeView.ts
  // layout: echarts/src/chart/tree/treeLayout.ts
  // visual: echarts/src/chart/tree/treeVisual.ts
  register_chart(registry, @option.SeriesType::Tree, false, false, TreeChartView::{

  })
}

///|
pub fn install_chord(registry : @core.Registry) -> Unit {
  // echarts/src/chart/chord/install.ts
  // echarts/src/chart/chord/ChordSeries.ts
  // echarts/src/chart/chord/ChordView.ts
  // layout: echarts/src/chart/chord/chordLayout.ts
  // processor: echarts/src/processor/dataFilter.ts
  register_chart(registry, @option.SeriesType::Chord, true, false, ChordChartView::{

  })
}

///|
pub fn install_sankey(registry : @core.Registry) -> Unit {
  // echarts/src/chart/sankey/install.ts
  // echarts/src/chart/sankey/SankeySeries.ts
  // echarts/src/chart/sankey/SankeyView.ts
  // layout: echarts/src/chart/sankey/sankeyLayout.ts
  // visual: echarts/src/chart/sankey/sankeyVisual.ts
  register_chart(registry, @option.SeriesType::Sankey, false, false, SankeyChartView::{

  })
}

///|
pub fn install_all(registry : @core.Registry) -> Unit {
  install_bar(registry)
  install_heatmap(registry)
  install_candlestick(registry)
  install_boxplot(registry)
  install_pictorial_bar(registry)
  install_line(registry)
  install_parallel(registry)
  install_map(registry)
  install_lines(registry)
  install_scatter(registry)
  install_effect_scatter(registry)
  install_pie(registry)
  install_sunburst(registry)
  install_treemap(registry)
  install_funnel(registry)
  install_radar(registry)
  install_gauge(registry)
  install_theme_river(registry)
  install_tree(registry)
  install_chord(registry)
  install_sankey(registry)
}

// Corresponds to: echarts/src/chart/*/install.ts for the currently implemented chart types.

///|
struct BarChartView {}

///|
pub impl @core.ChartViewLike for BarChartView with render(_self, ctx) {
  render_bars(ctx.option, ctx.coord)
}

///|
struct LineChartView {}

///|
pub impl @core.ChartViewLike for LineChartView with render(_self, ctx) {
  render_lines(ctx.option, ctx.coord)
}

///|
struct PictorialBarChartView {}

///|
pub impl @core.ChartViewLike for PictorialBarChartView with render(_self, ctx) {
  render_pictorial_bars(ctx.option, ctx.coord)
}

///|
struct ScatterChartView {}

///|
pub impl @core.ChartViewLike for ScatterChartView with render(_self, ctx) {
  render_scatters(ctx.option, ctx.coord)
}

///|
struct EffectScatterChartView {}

///|
pub impl @core.ChartViewLike for EffectScatterChartView with render(_self, ctx) {
  render_effect_scatters(ctx.option, ctx.coord)
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
  render_heatmaps(ctx.option, ctx.coord)
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
fn register_chart(
  registry : @core.Registry,
  series_type : @option.SeriesType,
  install_source : String,
  model_source : String,
  view_source : String,
  layout_sources : Array[String],
  visual_sources : Array[String],
  processor_sources : Array[String],
  stage_series_type : String,
  view : &@core.ChartViewLike,
) -> Unit {
  registry.register_chart(
    @core.ChartRegistration::new(
      series_type, install_source, model_source, view_source, layout_sources, visual_sources,
      processor_sources, view,
    ),
  )
  let mut i = 0
  while i < layout_sources.length() {
    registry.register_layout(
      @core.LayoutRegistration::new(
        "layout",
        layout_sources[i],
        Some(stage_series_type),
        2000,
        None,
      ),
    )
    i = i + 1
  }
  let mut j = 0
  while j < visual_sources.length() {
    registry.register_visual(
      @core.VisualRegistration::new(
        "visual",
        visual_sources[j],
        Some(stage_series_type),
        3000,
        None,
      ),
    )
    j = j + 1
  }
  let mut k = 0
  while k < processor_sources.length() {
    registry.register_processor(
      @core.ProcessorRegistration::new(
        "processor",
        processor_sources[k],
        Some(stage_series_type),
        1000,
        None,
      ),
    )
    k = k + 1
  }
}

///|
pub fn install_bar(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::Bar,
    "echarts/src/chart/bar/install.ts",
    "echarts/src/chart/bar/BarSeries.ts",
    "echarts/src/chart/bar/BarView.ts",
    ["echarts/src/layout/barGrid.ts"],
    [],
    ["echarts/src/processor/dataSample.ts"],
    "bar",
    BarChartView::{  },
  )
}

///|
pub fn install_line(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::Line,
    "echarts/src/chart/line/install.ts",
    "echarts/src/chart/line/LineSeries.ts",
    "echarts/src/chart/line/LineView.ts",
    ["echarts/src/layout/points.ts"],
    ["echarts/src/chart/line/install.ts"],
    ["echarts/src/processor/dataSample.ts"],
    "line",
    LineChartView::{  },
  )
}

///|
pub fn install_pictorial_bar(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::PictorialBar,
    "echarts/src/chart/bar/installPictorialBar.ts",
    "echarts/src/chart/bar/PictorialBarSeries.ts",
    "echarts/src/chart/bar/PictorialBarView.ts",
    ["echarts/src/layout/barGrid.ts"],
    [],
    [],
    "pictorialBar",
    PictorialBarChartView::{  },
  )
}

///|
pub fn install_scatter(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::Scatter,
    "echarts/src/chart/scatter/install.ts",
    "echarts/src/chart/scatter/ScatterSeries.ts",
    "echarts/src/chart/scatter/ScatterView.ts",
    ["echarts/src/layout/points.ts"],
    [],
    [],
    "scatter",
    ScatterChartView::{  },
  )
}

///|
pub fn install_effect_scatter(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::EffectScatter,
    "echarts/src/chart/effectScatter/install.ts",
    "echarts/src/chart/effectScatter/EffectScatterSeries.ts",
    "echarts/src/chart/effectScatter/EffectScatterView.ts",
    ["echarts/src/layout/points.ts"],
    [],
    [],
    "effectScatter",
    EffectScatterChartView::{  },
  )
}

///|
pub fn install_pie(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::Pie,
    "echarts/src/chart/pie/install.ts",
    "echarts/src/chart/pie/PieSeries.ts",
    "echarts/src/chart/pie/PieView.ts",
    ["echarts/src/chart/pie/pieLayout.ts"],
    ["echarts/src/chart/pie/labelLayout.ts"],
    [],
    "pie",
    PieChartView::{  },
  )
}

///|
pub fn install_sunburst(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::Sunburst,
    "echarts/src/chart/sunburst/install.ts",
    "echarts/src/chart/sunburst/SunburstSeries.ts",
    "echarts/src/chart/sunburst/SunburstView.ts",
    ["echarts/src/chart/sunburst/sunburstLayout.ts"],
    ["echarts/src/chart/sunburst/sunburstVisual.ts"],
    [],
    "sunburst",
    SunburstChartView::{  },
  )
}

///|
pub fn install_treemap(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::Treemap,
    "echarts/src/chart/treemap/install.ts",
    "echarts/src/chart/treemap/TreemapSeries.ts",
    "echarts/src/chart/treemap/TreemapView.ts",
    ["echarts/src/chart/treemap/treemapLayout.ts"],
    ["echarts/src/chart/treemap/treemapVisual.ts"],
    [],
    "treemap",
    TreemapChartView::{  },
  )
}

///|
pub fn install_radar(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::Radar,
    "echarts/src/chart/radar/install.ts",
    "echarts/src/chart/radar/RadarSeries.ts",
    "echarts/src/chart/radar/RadarView.ts",
    ["echarts/src/chart/radar/radarLayout.ts"],
    [],
    [],
    "radar",
    RadarChartView::{  },
  )
}

///|
pub fn install_candlestick(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::Candlestick,
    "echarts/src/chart/candlestick/install.ts",
    "echarts/src/chart/candlestick/CandlestickSeries.ts",
    "echarts/src/chart/candlestick/CandlestickView.ts",
    ["echarts/src/chart/candlestick/candlestickLayout.ts"],
    ["echarts/src/chart/candlestick/candlestickVisual.ts"],
    [],
    "candlestick",
    CandlestickChartView::{  },
  )
}

///|
pub fn install_heatmap(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::Heatmap,
    "echarts/src/chart/heatmap/install.ts",
    "echarts/src/chart/heatmap/HeatmapSeries.ts",
    "echarts/src/chart/heatmap/HeatmapView.ts",
    [],
    [],
    [],
    "heatmap",
    HeatmapChartView::{  },
  )
}

///|
pub fn install_boxplot(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::Boxplot,
    "echarts/src/chart/boxplot/install.ts",
    "echarts/src/chart/boxplot/BoxplotSeries.ts",
    "echarts/src/chart/boxplot/BoxplotView.ts",
    ["echarts/src/chart/boxplot/boxplotLayout.ts"],
    [],
    [],
    "boxplot",
    BoxplotChartView::{  },
  )
}

///|
pub fn install_funnel(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::Funnel,
    "echarts/src/chart/funnel/install.ts",
    "echarts/src/chart/funnel/FunnelSeries.ts",
    "echarts/src/chart/funnel/FunnelView.ts",
    ["echarts/src/chart/funnel/funnelLayout.ts"],
    [],
    [],
    "funnel",
    FunnelChartView::{  },
  )
}

///|
pub fn install_gauge(registry : @core.Registry) -> Unit {
  register_chart(
    registry,
    @option.SeriesType::Gauge,
    "echarts/src/chart/gauge/install.ts",
    "echarts/src/chart/gauge/GaugeSeries.ts",
    "echarts/src/chart/gauge/GaugeView.ts",
    [],
    [],
    [],
    "gauge",
    GaugeChartView::{  },
  )
}

///|
pub fn install_all(registry : @core.Registry) -> Unit {
  install_bar(registry)
  install_heatmap(registry)
  install_candlestick(registry)
  install_boxplot(registry)
  install_pictorial_bar(registry)
  install_line(registry)
  install_scatter(registry)
  install_effect_scatter(registry)
  install_pie(registry)
  install_sunburst(registry)
  install_treemap(registry)
  install_funnel(registry)
  install_radar(registry)
  install_gauge(registry)
}

// Corresponds to: echarts/src/coord/axisCommonTypes.ts
// echarts/src/component/axis/AxisModel.ts
// and various echarts/src/option/*.ts files

///|
/// Axis type.
pub(all) enum AxisType {
  Value // continuous numeric
  Category // discrete string categories
  Time // time series
  Log // logarithmic
} derive(Eq)

///|
/// Position of an axis.
pub enum AxisPosition {
  Bottom
  Top
  Left
  Right
}

///|
/// Corresponds to: echarts/src/util/types.ts AxisBreakOption
/// An axis break removes a segment [start, end] from the visible axis range,
/// replacing it with a small visual gap.
pub(all) struct AxisBreakOption {
  start : Double
  end : Double
  /// Gap size: percentage string like "1.5%" or absolute number string like "50".
  gap : String
}

///|
pub impl Default for AxisBreakOption with default() {
  { start: 0.0, end: 0.0, gap: "1.5%" }
}

///|
/// Corresponds to: echarts/src/coord/axisCommonTypes.ts BreakAreaOption
/// Controls the visual appearance of axis break markers (zigzag shapes).
pub(all) struct BreakAreaOption {
  /// Zigzag amplitude in pixels (half-width of the zigzag wave on each side).
  zigzag_amplitude : Double
  /// Min span between zigzag points in pixels.
  zigzag_min_span : Double
  /// Max span between zigzag points in pixels.
  zigzag_max_span : Double
  /// Zigzag z-index (visual priority among chart elements).
  zigzag_z : Double?
  /// Fill color of the break area; None means use background color.
  color : String?
  /// Opacity of the break area fill (0–1).
  opacity : Double
}

///|
pub impl Default for BreakAreaOption with default() {
  {
    zigzag_amplitude: 4.0,
    zigzag_min_span: 8.0,
    zigzag_max_span: 15.0,
    zigzag_z: None,
    color: None,
    opacity: 1.0,
  }
}

///|
/// X or Y axis configuration.
pub(all) struct AxisOption {
  axis_type : AxisType
  position : AxisPosition?
  name : String?
  data : Array[String] // category labels
  min : Double?
  max : Double?
  // echarts/src/coord/axisCommonTypes.ts: scale
  // When true, axis does not force include 0; fits to data range.
  scale : Bool
  grid_index : Int?
  polar_index : Int?
  start_angle : Double?
  end_angle : Double?
  clockwise : Bool?
  inverse : Bool
  // echarts/src/coord/axisHelper.ts:makeLabelFormatter
  label_formatter : String?
  // echarts/src/util/types.ts: AxisBreakOption — axis break segments
  breaks : Array[AxisBreakOption]
  // echarts/src/coord/axisCommonTypes.ts: BreakAreaOption — break visual style
  break_area : BreakAreaOption?
}

///|
/// Corresponds to: echarts/src/coord/parallel/AxisModel.ts
pub(all) struct ParallelAxisOption {
  axis_type : AxisType
  dim : Int
  parallel_index : Int
  name : String?
  data : Array[String]
  min : Double?
  max : Double?
  inverse : Bool
  show : Bool
}

///|
pub fn ParallelAxisOption::default() -> ParallelAxisOption {
  {
    axis_type: AxisType::Value,
    dim: 0,
    parallel_index: 0,
    name: None,
    data: [],
    min: None,
    max: None,
    inverse: false,
    show: true,
  }
}

///|
pub fn AxisOption::default_x() -> AxisOption {
  {
    axis_type: AxisType::Category,
    position: Some(AxisPosition::Bottom),
    name: None,
    data: [],
    min: None,
    max: None,
    scale: false,
    grid_index: None,
    polar_index: None,
    start_angle: None,
    end_angle: None,
    clockwise: None,
    inverse: false,
    label_formatter: None,
    breaks: [],
    break_area: None,
  }
}

///|
pub fn AxisOption::default_y() -> AxisOption {
  {
    axis_type: AxisType::Value,
    position: Some(AxisPosition::Left),
    name: None,
    data: [],
    min: None,
    max: None,
    scale: false,
    grid_index: None,
    polar_index: None,
    start_angle: None,
    end_angle: None,
    clockwise: None,
    inverse: false,
    label_formatter: None,
    breaks: [],
    break_area: None,
  }
}

///|
/// Polar coordinate component option.
/// Corresponds to: echarts/src/coord/polar/PolarModel.ts
pub(all) struct PolarOption {
  center : Array[String]
  radius : Array[String]
}

///|
pub impl Default for PolarOption with default() {
  { center: ["50%", "50%"], radius: ["0", "80%"] }
}

///|
/// Corresponds to: echarts/src/coord/geo/GeoModel.ts
pub(all) struct GeoLabelOption {
  show : Bool
  color : String
  position : String?
  distance : Double?
  font_weight : String?
  rotate : Double?
  /// Pie-only rotate modes from echarts/src/chart/pie/PieSeries.ts:
  /// "radial", "tangential", "tangential-noflip".
  rotate_mode : String?
  /// Pie-only label alignment mode.
  align_to : String?
  /// Pie-only label edge distance; percentage strings are kept as strings.
  edge_distance : String?
  /// Pie-only label bleed margin.
  bleed_margin : Double?
  /// Pie-only distance between text and label line.
  distance_to_label_line : Double?
  font_size : Double
  font_family : String
  // echarts/src/model/mixin/dataFormat.ts: getFormattedLabel -> formatTpl
  formatter : String?
}

///|
pub impl Default for GeoLabelOption with default() {
  {
    show: false,
    color: "#54555a",
    position: None,
    distance: None,
    font_weight: None,
    rotate: None,
    rotate_mode: None,
    align_to: None,
    edge_distance: None,
    bleed_margin: None,
    distance_to_label_line: None,
    font_size: 12.0,
    font_family: "sans-serif",
    formatter: None,
  }
}

///|
pub(all) struct GeoLabelPatchOption {
  show : Bool?
  color : String?
  position : String?
  distance : Double?
  font_weight : String?
  rotate : Double?
  rotate_mode : String?
  align_to : String?
  edge_distance : String?
  bleed_margin : Double?
  distance_to_label_line : Double?
  font_size : Double?
  font_family : String?
  formatter : String?
}

///|
pub impl Default for GeoLabelPatchOption with default() {
  {
    show: None,
    color: None,
    position: None,
    distance: None,
    font_weight: None,
    rotate: None,
    rotate_mode: None,
    align_to: None,
    edge_distance: None,
    bleed_margin: None,
    distance_to_label_line: None,
    font_size: None,
    font_family: None,
    formatter: None,
  }
}

///|
/// Root `textStyle` option.
pub(all) struct ChartTextStyleOption {
  color : String?
  font_size : Double?
  font_family : String?
  font_weight : String?
}

///|
pub impl Default for ChartTextStyleOption with default() {
  { color: None, font_size: None, font_family: None, font_weight: None }
}

///|
/// Corresponds to: echarts/src/coord/geo/GeoModel.ts
pub(all) struct GeoNameMapEntry {
  from_name : String
  to_name : String
}

///|
pub(all) struct GeoItemStyleOption {
  area_color : String?
  border_color : String
  border_width : Double
}

///|
pub impl Default for GeoItemStyleOption with default() {
  { area_color: None, border_color: "#b7b9be", border_width: 0.5 }
}

///|
pub(all) struct GeoItemStylePatchOption {
  color : String?
  area_color : String?
  border_color : String?
  border_width : Double?
  opacity : Double?
  border_radius : Array[Double]? // [tl, tr, br, bl] per-corner radii
}

///|
pub impl Default for GeoItemStylePatchOption with default() {
  {
    color: None,
    area_color: None,
    border_color: None,
    border_width: None,
    opacity: None,
    border_radius: None,
  }
}

///|
pub(all) struct GeoStateOption {
  item_style : GeoItemStylePatchOption?
  label : GeoLabelPatchOption?
}

///|
pub impl Default for GeoStateOption with default() {
  { item_style: None, label: None }
}

///|
pub(all) struct GeoStatesOption {
  emphasis : GeoStateOption?
  select : GeoStateOption?
  blur : GeoStateOption?
}

///|
pub impl Default for GeoStatesOption with default() {
  { emphasis: None, select: None, blur: None }
}

///|
pub(all) struct GeoRegionOption {
  name : String
  label : GeoLabelPatchOption?
  item_style : GeoItemStylePatchOption?
  selected : Bool?
  silent : Bool?
  states : GeoStatesOption
}

///|
pub(all) struct GeoOption {
  map : String
  center : Array[String]?
  zoom : Double
  left : String?
  top : String?
  right : String?
  bottom : String?
  width : String?
  height : String?
  layout_center : Array[String]?
  layout_size : String?
  bounding_coords : Array[Array[Double]]?
  roam : Bool
  aspect_scale : Double?
  name_property : String?
  silent : Bool
  label : GeoLabelOption
  item_style : GeoItemStyleOption
  states : GeoStatesOption
  name_map : Array[GeoNameMapEntry]
  regions : Array[GeoRegionOption]
}

///|
pub impl Default for GeoOption with default() {
  {
    map: "",
    center: None,
    zoom: 1.0,
    left: Some("center"),
    top: Some("center"),
    right: None,
    bottom: None,
    width: None,
    height: None,
    layout_center: None,
    layout_size: None,
    bounding_coords: None,
    roam: false,
    aspect_scale: None,
    name_property: None,
    silent: false,
    label: GeoLabelOption::default(),
    item_style: GeoItemStyleOption::default(),
    states: GeoStatesOption::default(),
    name_map: [],
    regions: [],
  }
}

///|
/// Static map registration for stdin/JSON rendering.
pub(all) struct MapSpecialAreaOption {
  name : String
  left : Double
  top : Double
  width : Double
  height : Double
}

///|
pub(all) struct MapRegistryOption {
  name : String
  geo_json : Json?
  svg : String?
  special_areas : Array[MapSpecialAreaOption]
}

///|
/// Grid layout specification.
pub(all) struct GridOption {
  left : String
  right : String
  top : String
  bottom : String
  width : String?
  height : String?
  contain_label : Bool
}

///|
/// A size specification: pixel value or percentage string.
pub(all) enum SizeSpec {
  Px(Double)
  Pct(Double) // 0-100
}

///|
pub impl Default for GridOption with default() {
  // ECharts default: left='15%', right='10%', top=65, bottom=80
  // See echarts/src/coord/cartesian/GridModel.ts
  {
    left: "15%",
    right: "10%",
    top: "65",
    bottom: "80",
    width: None,
    height: None,
    contain_label: false,
  }
}

///|
/// Corresponds to: echarts/src/coord/parallel/ParallelModel.ts
pub(all) struct ParallelOption {
  left : SizeSpec
  right : SizeSpec
  top : SizeSpec
  bottom : SizeSpec
  layout : String
  axis_expandable : Bool
  axis_expand_center : Int?
  axis_expand_count : Int
  axis_expand_width : Double
}

///|
pub impl Default for ParallelOption with default() {
  {
    left: SizeSpec::Px(80.0),
    right: SizeSpec::Px(80.0),
    top: SizeSpec::Px(60.0),
    bottom: SizeSpec::Px(60.0),
    layout: "horizontal",
    axis_expandable: false,
    axis_expand_center: None,
    axis_expand_count: 0,
    axis_expand_width: 50.0,
  }
}

///|
pub(all) enum MapValueCalculationType {
  Sum
  Average
  Min
  Max
} derive(Eq)

///|
/// Series type.
pub(all) enum SeriesType {
  // pub`(all)` enum to construct the "never constructed" variant outside of the current package
  Line
  Parallel
  Lines
  Bar
  PictorialBar
  Scatter
  EffectScatter
  Pie
  Sunburst
  Treemap
  Radar
  Candlestick
  Heatmap
  Boxplot
  Funnel
  Gauge
  Map
  ThemeRiver
  Tree
  Chord
  Sankey
  Graph
} derive(Eq)

///|
/// Data value in a series: can be a number, an array, or null.
pub(all) enum DataValue {
  Num(Double)
  Vec(Array[Double])
  DateValue(String, Double)
  Null
} derive(Default)

///|
/// One item in a series data array.
pub(all) struct DataItem {
  value : DataValue
  raw_value_parts : Array[Json]?
  raw_item : Json?
  id : String?
  name : String?
  depth : Int?
  source : String?
  target : String?
  symbol : String?
  coords : Array[Array[Double]]?
  from_name : String?
  to_name : String?
  cursor : String?
  selected : Bool?
  silent : Bool?
  label : GeoLabelPatchOption?
  item_style : GeoItemStylePatchOption?
  states : GeoStatesOption
  children : Array[DataItem]
  collapsed : Bool?
  // For gauge chart per-item title/detail offsetCenter overrides
  // Corresponds to: echarts/src/chart/gauge/GaugeSeries.ts GaugeDataItemOption
  title_offset_center : Array[String]? // [x%, y%] relative to gauge radius
  detail_offset_center : Array[String]? // [x%, y%] relative to gauge radius
  // Emphasis state from highlight/downplay dispatchAction.
  // Corresponds to: echarts/src/util/states.ts HOVER_STATE_EMPHASIS
  highlighted : Bool?
}

///|
pub enum SymbolBoundingData {
  Single(Double)
  Pair(Double, Double)
}

///|

///|
/// Corresponds to: echarts/src/chart/sankey/SankeySeries.ts
pub(all) struct SankeyLevelOption {
  depth : Int
  label : GeoLabelPatchOption?
  item_style : GeoItemStylePatchOption?
  line_style_color : String?
  line_style_width : Double?
  line_style_opacity : Double?
  line_style_curveness : Double?
}

///|
/// Corresponds to: echarts/src/chart/treemap/TreemapSeries.ts
pub(all) struct TreemapUpperLabelOption {
  show : Bool
  height : Double
}

///|
pub impl Default for TreemapUpperLabelOption with default() {
  { show: false, height: 20.0 }
}

///|
pub(all) struct TreemapItemStyleOption {
  color : String?
  border_color : String?
  border_width : Double?
  gap_width : Double?
}

///|
pub impl Default for TreemapItemStyleOption with default() {
  { color: None, border_color: None, border_width: None, gap_width: None }
}

///|
pub(all) struct TreemapLevelOption {
  item_style : TreemapItemStyleOption?
  upper_label : TreemapUpperLabelOption?
  color_saturation : Array[Double]?
  color_alpha : Array[Double]?
}

///|
pub impl Default for TreemapLevelOption with default() {
  {
    item_style: None,
    upper_label: None,
    color_saturation: None,
    color_alpha: None,
  }
}

///|

///|
/// Series configuration.
pub(all) struct SeriesOption {
  series_type : SeriesType
  name : String?
  data : Array[DataItem]
  original_data : Array[DataItem]?
  link_data : Array[DataItem]
  symbol : String?
  symbol_values : Array[String]?
  symbol_size_values : Array[String]?
  symbol_repeat : String?
  symbol_repeat_count : Int?
  symbol_repeat_fixed : Bool
  symbol_margin : String?
  symbol_clip : Bool
  symbol_position : String?
  symbol_rotate : Double?
  symbol_bounding_data : SymbolBoundingData?
  symbol_offset : Array[String]?
  symbol_repeat_direction : String?
  bar_width : String?
  bar_max_width : String?
  bar_min_width : String?
  bar_gap : String?
  bar_category_gap : String?
  bar_min_height : Double
  bar_min_angle : Double
  large : Bool
  large_threshold : Int
  round_cap : Bool
  show_background : Bool
  x_axis_index : Int
  y_axis_index : Int
  parallel_index : Int
  radius_axis_index : Int
  angle_axis_index : Int
  polar_index : Int
  coordinate_system : String?
  calendar_index : Int
  matrix_index : Int
  geo_index : Int
  // For radar: index into ChartOption.radar[]
  radar_index : Int
  map_name : String?
  show_legend_symbol : Bool
  zoom : Double
  name_property : String?
  left : String?
  top : String?
  right : String?
  bottom : String?
  width : String?
  height : String?
  layout_center : Array[String]?
  layout_size : String?
  bounding_coords : Array[Array[Double]]?
  stack : String?
  // For funnel charts
  funnel_sort : String
  funnel_orient : String
  funnel_gap : Double
  funnel_align : String
  funnel_min : Double?
  funnel_max : Double?
  funnel_min_size : String
  funnel_max_size : String
  // For themeRiver: [before, after] gap on axis orthogonal direction
  boundary_gap : Array[String]
  // smooth: 0.0 = straight lines; >0.0 = cubic Bezier curvature factor.
  // Corresponds to: LineSeries smooth (Bool or number 0-1).
  smooth : Double
  // step: "" | "start" | "end" | "middle" — step-line mode for line series.
  // Corresponds to: LineSeries.ts `step` option.
  step : String
  // show_symbol: whether to render data point symbols on line series.
  // Corresponds to: LineSeries.ts `showSymbol` (default true).
  show_symbol : Bool
  polyline : Bool
  clip : Bool
  symbol_size : Double
  color : String?
  line_style_color : String?
  line_style_width : Double?
  line_style_opacity : Double?
  line_style_curveness : Double?
  item_style : String? // color override
  item_opacity : Double?
  label : GeoLabelOption?
  geo_item_style : GeoItemStylePatchOption?
  background_style : GeoItemStylePatchOption?
  silent : Bool
  states : GeoStatesOption
  area_style : Bool
  encode_x : String?
  encode_y : String?
  // For pie charts
  radius : Array[String]
  center : Array[String]
  // For sunburst charts
  min_angle : Double // option degrees, default 0
  pad_angle : Double // option degrees, default varies by series
  clockwise : Bool // default true
  // For gauge charts
  start_angle : Double // option degrees, default 225 (ECharts GaugeSeries.ts default)
  end_angle : Double // option degrees, default -45
  min_val : Double // data min, default 0
  max_val : Double // data max, default 100
  split_number : Int // tick divisions, default 10
  map_value_calculation : MapValueCalculationType
  active_opacity : Double?
  inactive_opacity : Double?
  // tree chart options
  tree_layout : String
  tree_orient : String
  tree_edge_shape : String
  tree_edge_fork_position : String
  tree_left : String
  tree_top : String
  tree_right : String
  tree_bottom : String
  tree_expand_and_collapse : Bool
  tree_initial_depth : Int
  tree_node_scale_ratio : Double
  tree_leaves_label : GeoLabelPatchOption?
  tree_leaves_geo_item_style : GeoItemStylePatchOption?
  tree_leaves_symbol : String?
  tree_leaves_symbol_size : Double?
  tree_leaves_line_style_color : String?
  tree_leaves_line_style_width : Double?
  tree_leaves_line_style_opacity : Double?
  tree_leaves_line_style_curveness : Double?
  // sankey chart options
  sankey_orient : String
  sankey_node_width : Double
  sankey_node_gap : Double
  sankey_layout_iterations : Int
  sankey_node_align : String
  sankey_left : SizeSpec?
  sankey_top : SizeSpec?
  sankey_right : SizeSpec?
  sankey_bottom : SizeSpec?
  sankey_width : SizeSpec?
  sankey_height : SizeSpec?
  sankey_levels : Array[SankeyLevelOption]
  treemap_upper_label : TreemapUpperLabelOption?
  treemap_item_style : TreemapItemStyleOption?
  treemap_levels : Array[TreemapLevelOption]
  // Gauge-specific series-level options
  // Corresponds to: echarts/src/chart/gauge/GaugeSeries.ts
  gauge_progress_show : Bool
  gauge_progress_overlap : Bool
  gauge_progress_width : Double // default 10.0
  gauge_progress_round_cap : Bool // progress.roundCap, default false
  gauge_progress_clip : Bool // progress.clip, default true
  gauge_round_cap : Bool // axisLine.roundCap, default false
  gauge_detail_formatter : String?
  gauge_detail_color : String?
  gauge_detail_font_size : Double // default 30.0
  gauge_detail_offset_center : Array[String] // default ["0", "40%"]
  gauge_title_font_size : Double // default 16.0
  gauge_title_offset_center : Array[String] // default ["0", "20%"]
  // Gauge axisLine styling
  // Corresponds to: echarts/src/chart/gauge/GaugeSeries.ts axisLine
  gauge_axis_line_colors : Array[(Double, String)] // axisLine.lineStyle.color, default [[1,"#e8ebf0"]]
  gauge_axis_line_width : Double // axisLine.lineStyle.width, default 10.0
  // Gauge splitLine styling
  // Corresponds to: echarts/src/chart/gauge/GaugeSeries.ts splitLine
  gauge_split_line_show : Bool // splitLine.show, default true
  gauge_split_line_length : Double // splitLine.length, default 10.0
  gauge_split_line_distance : Double // splitLine.distance, default 10.0
  gauge_split_line_color : String // splitLine.lineStyle.color, default "#54555a"
  gauge_split_line_width : Double // splitLine.lineStyle.width, default 3.0
  // Gauge axisTick styling
  // Corresponds to: echarts/src/chart/gauge/GaugeSeries.ts axisTick
  gauge_axis_tick_show : Bool // axisTick.show, default true
  gauge_axis_tick_length : Double // axisTick.length, default 6.0
  gauge_axis_tick_distance : Double // axisTick.distance, default 10.0
  gauge_axis_tick_color : String // axisTick.lineStyle.color, default "#b0b2b5"
  gauge_axis_tick_width : Double // axisTick.lineStyle.width, default 1.0
  gauge_axis_tick_split_number : Int // axisTick.splitNumber, default 5
  // Gauge axisLabel styling
  // Corresponds to: echarts/src/chart/gauge/GaugeSeries.ts axisLabel
  gauge_axis_label_show : Bool // axisLabel.show, default true
  gauge_axis_label_color : String // axisLabel.color, default "#54555a"
  gauge_axis_label_distance : Double // axisLabel.distance, default 15.0
  gauge_axis_label_font_size : Double // axisLabel.fontSize, default 12.0
  // Gauge pointer styling
  // Corresponds to: echarts/src/chart/gauge/GaugeSeries.ts pointer
  gauge_pointer_show : Bool // pointer.show, default true
  gauge_pointer_color : String? // pointer.itemStyle.color, default None (palette)
  gauge_pointer_length : String // pointer.length, default "60%"
  gauge_pointer_width : Double // pointer.width, default 6.0
  gauge_pointer_offset_center : Array[String] // pointer.offsetCenter, default ["0","0"]
  gauge_pointer_icon : String? // pointer.icon, default None
  // Gauge anchor styling
  // Corresponds to: echarts/src/chart/gauge/GaugeSeries.ts anchor
  gauge_anchor_show : Bool // anchor.show, default false
  gauge_anchor_size : Double // anchor.size, default 6.0
  gauge_anchor_color : String? // anchor.itemStyle.color, default None
  gauge_anchor_border_color : String? // anchor.itemStyle.borderColor, default None
  gauge_anchor_border_width : Double // anchor.itemStyle.borderWidth, default 0.0
  // Candlestick-specific itemStyle
  // Corresponds to: echarts/src/chart/candlestick/CandlestickSeries.ts
  candle_color_up : String? // itemStyle.color (bullish/close>=open)
  candle_color_down : String? // itemStyle.color0 (bearish/close<open)
  candle_border_color_up : String? // itemStyle.borderColor
  candle_border_color_down : String? // itemStyle.borderColor0
  candle_border_color_doji : String? // itemStyle.borderColorDoji (open==close)
  candle_border_color0_doji : String? // itemStyle.borderColor0Doji (open==close, bearish color)
  candle_border_width : Double // itemStyle.borderWidth, default 1.0
  // Graph-specific options
  // Corresponds to: echarts/src/chart/graph/GraphSeries.ts
  graph_layout : String
  graph_categories : Array[String]
  graph_force_edge_length : Double
  graph_force_repulsion : Double
  graph_force_gravity : Double
  graph_circular_rotate_label : Bool // circular.rotateLabel, default false
  // Pie-specific options
  // Corresponds to: echarts/src/chart/pie/PieSeries.ts
  pie_selected_mode : String? // selectedMode: 'single' | 'multiple' | 'series' | boolean (None = disabled)
  pie_selected_offset : Double // selectedOffset, default 10.0
  pie_rose_type : String? // roseType: "radius" | "area"
  pie_min_show_label_angle : Double // minShowLabelAngle, default 0
  pie_avoid_label_overlap : Bool // avoidLabelOverlap, default true
  pie_label_layout_hide_overlap : Bool // labelLayout.hideOverlap, default true
  pie_percent_precision : Int // percentPrecision, default 2
  pie_still_show_zero_sum : Bool // stillShowZeroSum, default true
  pie_show_empty_circle : Bool // showEmptyCircle, default true
  pie_empty_circle_color : String? // emptyCircleStyle.color
  pie_label_line_show : Bool // labelLine.show, default true
  pie_label_line_length : Double // labelLine.length, default 15
  pie_label_line_length2 : Double // labelLine.length2, default 30
  pie_label_line_smooth : Double // labelLine.smooth, default 0
  pie_label_line_min_turn_angle : Double // labelLine.minTurnAngle, default 90
  pie_label_line_max_surface_angle : Double // labelLine.maxSurfaceAngle, default 90
  pie_label_line_color : String? // labelLine.lineStyle.color
  pie_label_line_width : Double // labelLine.lineStyle.width, default 1
  pie_label_line_type : String // labelLine.lineStyle.type, default "solid"
  pie_label_line_opacity : Double? // labelLine.lineStyle.opacity
  pie_animation_type : String? // animationType: "expansion" | "scale"
  pie_animation_duration : Double? // animationDuration, default 1000
  pie_animation_easing : String? // animationEasing, default "cubicInOut"
  pie_animation_type_update : String? // animationTypeUpdate: "transition" | "expansion"
  pie_animation_duration_update : Double? // animationDurationUpdate, default 500
  pie_animation_easing_update : String? // animationEasingUpdate, default "cubicInOut"
  // Generic labelLine.show — used by funnel (and potentially others) to toggle
  // the connector line between the segment and the outer label.
  // Corresponds to: FunnelSeries.ts labelLine.show, default true
  label_line_show : Bool
}

///|
pub fn SeriesOption::default_line() -> SeriesOption {
  {
    series_type: SeriesType::Line,
    name: None,
    data: [],
    original_data: None,
    link_data: [],
    symbol: None,
    symbol_values: None,
    symbol_size_values: None,
    symbol_repeat: None,
    symbol_repeat_count: None,
    symbol_repeat_fixed: false,
    symbol_margin: None,
    symbol_clip: false,
    symbol_position: None,
    symbol_rotate: None,
    symbol_bounding_data: None,
    symbol_offset: None,
    symbol_repeat_direction: None,
    bar_width: None,
    bar_max_width: None,
    bar_min_width: None,
    bar_gap: None,
    bar_category_gap: None,
    bar_min_height: 0.0,
    bar_min_angle: 0.0,
    large: false,
    large_threshold: 400,
    round_cap: false,
    show_background: false,
    x_axis_index: 0,
    y_axis_index: 0,
    parallel_index: 0,
    radius_axis_index: 0,
    angle_axis_index: 0,
    polar_index: 0,
    coordinate_system: None,
    calendar_index: 0,
    matrix_index: 0,
    geo_index: -1,
    radar_index: 0,
    map_name: None,
    show_legend_symbol: false,
    zoom: 1.0,
    name_property: Some("name"),
    left: None,
    top: None,
    right: None,
    bottom: None,
    width: None,
    height: None,
    layout_center: None,
    layout_size: None,
    bounding_coords: None,
    stack: None,
    funnel_sort: "descending",
    funnel_orient: "vertical",
    funnel_gap: 0.0,
    funnel_align: "center",
    funnel_min: None,
    funnel_max: None,
    funnel_min_size: "0%",
    funnel_max_size: "100%",
    boundary_gap: [],
    smooth: 0.0,
    step: "",
    show_symbol: true,
    polyline: false,
    clip: false,
    symbol_size: 4.0,
    color: None,
    line_style_color: None,
    line_style_width: None,
    line_style_opacity: None,
    line_style_curveness: None,
    item_style: None,
    item_opacity: None,
    label: None,
    geo_item_style: None,
    background_style: None,
    silent: false,
    states: GeoStatesOption::default(),
    area_style: false,
    encode_x: None,
    encode_y: None,
    radius: [],
    center: [],
    min_angle: 0.0,
    pad_angle: 0.0,
    clockwise: true,
    start_angle: 225.0,
    end_angle: -45.0,
    min_val: 0.0,
    max_val: 100.0,
    split_number: 10,
    map_value_calculation: MapValueCalculationType::Sum,
    active_opacity: None,
    inactive_opacity: None,
    // tree chart options
    tree_layout: "orthogonal",
    tree_orient: "LR",
    tree_edge_shape: "curve",
    tree_edge_fork_position: "50%",
    tree_expand_and_collapse: true,
    tree_initial_depth: 2,
    tree_left: "12%",
    tree_top: "12%",
    tree_right: "12%",
    tree_bottom: "12%",
    tree_node_scale_ratio: 0.4,
    tree_leaves_label: None,
    tree_leaves_geo_item_style: None,
    tree_leaves_symbol: None,
    tree_leaves_symbol_size: None,
    tree_leaves_line_style_color: None,
    tree_leaves_line_style_width: None,
    tree_leaves_line_style_opacity: None,
    tree_leaves_line_style_curveness: None,
    sankey_orient: "horizontal",
    sankey_node_width: 20.0,
    sankey_node_gap: 8.0,
    sankey_layout_iterations: 32,
    sankey_node_align: "justify",
    sankey_left: None,
    sankey_top: None,
    sankey_right: None,
    sankey_bottom: None,
    sankey_width: None,
    sankey_height: None,
    sankey_levels: [],
    treemap_upper_label: None,
    treemap_item_style: None,
    treemap_levels: [],
    gauge_progress_show: false,
    gauge_progress_overlap: true,
    gauge_progress_width: 10.0,
    gauge_progress_round_cap: false,
    gauge_progress_clip: true,
    gauge_round_cap: false,
    gauge_detail_formatter: None,
    gauge_detail_color: None,
    gauge_detail_font_size: 30.0,
    gauge_detail_offset_center: ["0", "40%"],
    gauge_title_font_size: 16.0,
    gauge_title_offset_center: ["0", "20%"],
    gauge_axis_line_colors: [(1.0, "#e8ebf0")],
    gauge_axis_line_width: 10.0,
    gauge_split_line_show: true,
    gauge_split_line_length: 10.0,
    gauge_split_line_distance: 10.0,
    gauge_split_line_color: "#54555a",
    gauge_split_line_width: 3.0,
    gauge_axis_tick_show: true,
    gauge_axis_tick_length: 6.0,
    gauge_axis_tick_distance: 10.0,
    gauge_axis_tick_color: "#b0b2b5",
    gauge_axis_tick_width: 1.0,
    gauge_axis_tick_split_number: 5,
    gauge_axis_label_show: true,
    gauge_axis_label_color: "#54555a",
    gauge_axis_label_distance: 15.0,
    gauge_axis_label_font_size: 12.0,
    gauge_pointer_show: true,
    gauge_pointer_color: None,
    gauge_pointer_length: "60%",
    gauge_pointer_width: 6.0,
    gauge_pointer_offset_center: ["0", "0"],
    gauge_pointer_icon: None,
    gauge_anchor_show: false,
    gauge_anchor_size: 6.0,
    gauge_anchor_color: None,
    gauge_anchor_border_color: None,
    gauge_anchor_border_width: 0.0,
    candle_color_up: None,
    candle_color_down: None,
    candle_border_color_up: None,
    candle_border_color_down: None,
    candle_border_color_doji: None,
    candle_border_color0_doji: None,
    candle_border_width: 1.0,
    graph_layout: "none",
    graph_categories: [],
    graph_force_edge_length: 30.0,
    graph_force_repulsion: 50.0,
    graph_force_gravity: 0.1,
    pie_selected_mode: None,
    pie_selected_offset: 10.0,
    graph_circular_rotate_label: false,
    pie_rose_type: None,
    pie_min_show_label_angle: 0.0,
    pie_avoid_label_overlap: true,
    pie_label_layout_hide_overlap: false,
    pie_percent_precision: 2,
    pie_still_show_zero_sum: true,
    pie_show_empty_circle: true,
    pie_empty_circle_color: Some("lightgray"),
    pie_label_line_show: true,
    pie_label_line_length: 15.0,
    pie_label_line_length2: 30.0,
    pie_label_line_smooth: 0.0,
    pie_label_line_min_turn_angle: 90.0,
    pie_label_line_max_surface_angle: 90.0,
    pie_label_line_color: None,
    pie_label_line_width: 1.0,
    pie_label_line_type: "solid",
    pie_label_line_opacity: None,
    pie_animation_type: None,
    pie_animation_duration: None,
    pie_animation_easing: None,
    pie_animation_type_update: None,
    pie_animation_duration_update: None,
    pie_animation_easing_update: None,
    label_line_show: true,
  }
}

///|
pub fn SeriesOption::default_graph() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Graph,
    graph_layout: "none",
    graph_categories: [],
    graph_force_edge_length: 30.0,
    graph_force_repulsion: 50.0,
    graph_force_gravity: 0.1,
    graph_circular_rotate_label: false,
  }
}

///|

///|
pub fn SeriesOption::default_bar() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Bar,
    background_style: Some({
      color: Some("rgba(180, 180, 180, 0.2)"),
      area_color: None,
      border_color: None,
      border_width: Some(0.0),
      opacity: Some(1.0),
      border_radius: None,
    }),
  }
}

///|
pub fn SeriesOption::default_funnel() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Funnel,
    left: Some("80"),
    top: Some("60"),
    right: Some("80"),
    bottom: Some("65"),
    funnel_sort: "descending",
    funnel_orient: "vertical",
    funnel_gap: 0.0,
    funnel_align: "center",
    funnel_min: None,
    funnel_max: None,
    funnel_min_size: "0%",
    funnel_max_size: "100%",
    label: Some({
      ..GeoLabelOption::default(),
      show: true,
      color: "#333333",
      position: Some("right"),
    }),
  }
}

///|
pub fn SeriesOption::default_parallel() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Parallel,
    coordinate_system: Some("parallel"),
    parallel_index: 0,
    line_style_width: Some(1.0),
    line_style_opacity: Some(0.45),
    active_opacity: Some(1.0),
    inactive_opacity: Some(0.05),
  }
}

///|
pub fn SeriesOption::default_lines() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Lines,
    coordinate_system: Some("geo"),
    polyline: false,
    clip: true,
    symbol: Some("none"),
    symbol_values: Some(["none", "none"]),
    symbol_size_values: Some(["10", "10"]),
  }
}

///|
pub fn SeriesOption::default_pictorial_bar() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::PictorialBar,
    symbol: Some("circle"),
    symbol_repeat: Some("false"),
    symbol_repeat_count: None,
    symbol_repeat_fixed: false,
    symbol_margin: Some("15%"),
    symbol_clip: false,
    symbol_position: Some("start"),
    symbol_rotate: None,
    symbol_bounding_data: None,
    symbol_offset: None,
    symbol_repeat_direction: Some("end"),
    bar_gap: Some("-100%"),
    bar_category_gap: None,
  }
}

///|
pub fn SeriesOption::default_scatter() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Scatter,
    symbol_size: 10.0,
  }
}

///|
pub fn SeriesOption::default_effect_scatter() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::EffectScatter,
    symbol_size: 10.0,
  }
}

///|
/// <=> echarts/src/chart/pie/PieSeries.ts:defaultOption
pub fn SeriesOption::default_pie() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Pie,
    radius: ["0%", "75%"],
    center: ["50%", "50%"],
    label: Some({
      ..GeoLabelOption::default(),
      show: true,
      position: Some("outer"),
      align_to: Some("none"),
      edge_distance: Some("25%"),
      distance_to_label_line: Some(5.0),
      rotate: Some(0.0),
    }),
    start_angle: 90.0,
    end_angle: 0.0 / 0.0,
    clockwise: true,
    min_angle: 0.0,
    pad_angle: 0.0,
    pie_label_layout_hide_overlap: true,
    pie_animation_type: Some("expansion"),
    pie_animation_duration: Some(1000.0),
    pie_animation_easing: Some("cubicInOut"),
    pie_animation_type_update: Some("transition"),
    pie_animation_duration_update: Some(500.0),
    pie_animation_easing_update: Some("cubicInOut"),
  }
}

///|
pub fn SeriesOption::default_sunburst() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Sunburst,
    radius: ["0%", "75%"],
    center: ["50%", "50%"],
    start_angle: 90.0,
    min_angle: 0.0,
    clockwise: true,
  }
}

///|
pub fn SeriesOption::default_treemap() -> SeriesOption {
  { ..SeriesOption::default_line(), series_type: SeriesType::Treemap }
}

///|
pub fn SeriesOption::default_tree() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Tree,
    symbol: Some("emptyCircle"),
    symbol_size: 7.0,
    tree_layout: "orthogonal",
    tree_orient: "LR",
    tree_edge_shape: "curve",
    tree_edge_fork_position: "50%",
    tree_expand_and_collapse: true,
    tree_initial_depth: 2,
    tree_left: "12%",
    tree_top: "12%",
    tree_right: "12%",
    tree_bottom: "12%",
    tree_node_scale_ratio: 0.4,
    line_style_curveness: Some(0.5),
    line_style_width: Some(1.5),
    // Tree labels follow the series text default color in ECharts SSR.
    label: Some({ ..GeoLabelOption::default(), show: true, color: "#333" }),
  }
}

///|
pub fn SeriesOption::default_chord() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Chord,
    coordinate_system: Some("none"),
    center: ["50%", "50%"],
    radius: ["70%", "80%"],
    clockwise: true,
    start_angle: 90.0,
    min_angle: 0.0,
    pad_angle: 3.0,
    line_style_color: Some("source"),
    line_style_width: Some(0.0),
    line_style_opacity: Some(0.2),
    label: Some({
      ..GeoLabelOption::default(),
      show: true,
      color: "#54555a",
      position: Some("outside"),
      distance: Some(5.0),
    }),
  }
}

///|
pub fn SeriesOption::default_sankey() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Sankey,
    coordinate_system: Some("view"),
    line_style_color: Some("#86878c"),
    line_style_opacity: Some(0.2),
    line_style_curveness: Some(0.5),
    label: Some({
      ..GeoLabelOption::default(),
      show: true,
      color: "#333",
      position: Some("outer"),
      distance: Some(5.0),
    }),
    sankey_left: Some(SizeSpec::Pct(5.0)),
    sankey_top: Some(SizeSpec::Pct(5.0)),
    sankey_right: Some(SizeSpec::Pct(20.0)),
    sankey_bottom: Some(SizeSpec::Pct(5.0)),
  }
}

///|
pub fn SeriesOption::default_gauge() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Gauge,
    radius: ["75%"],
    center: ["50%", "50%"],
  }
}

///|
pub fn SeriesOption::default_map() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Map,
    coordinate_system: Some("geo"),
    left: Some("center"),
    top: Some("center"),
    show_legend_symbol: true,
    zoom: 1.0,
  }
}

///|
pub fn SeriesOption::default_theme_river() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::ThemeRiver,
    coordinate_system: Some("singleAxis"),
    boundary_gap: ["10%", "10%"],
  }
}

///|
/// Title component.
/// Corresponds to: echarts/src/component/title/install.ts
pub struct TitleOption {
  text : String
  subtext : String
  left : String // "left" | "center" | "right" | pixel
  top : String
  text_align : String?
  text_style : TitleTextStyleOption
  subtext_style : TitleTextStyleOption
}

///|
pub struct TitleTextStyleOption {
  color : String
  font_size : Double
  font_weight : String
  font_family : String
}

///|
pub impl Default for TitleOption with default() {
  // ECharts default: left='center', top='auto'
  // See echarts/src/component/title/install.ts
  {
    text: "",
    subtext: "",
    left: "center",
    top: "auto",
    text_align: None,
    text_style: TitleTextStyleOption::default(),
    subtext_style: TitleTextStyleOption::default_subtext(),
  }
}

///|
pub impl Default for TitleTextStyleOption with default() {
  {
    color: "#3c3c41",
    font_size: 18.0,
    font_weight: "bold",
    font_family: "sans-serif",
  }
}

///|
pub fn TitleTextStyleOption::default_subtext() -> TitleTextStyleOption {
  {
    color: "#86878c",
    font_size: 12.0,
    font_weight: "normal",
    font_family: "sans-serif",
  }
}

///|
pub struct LegendSelection {
  name : String
  selected : Bool
}

///|
/// Legend component.
pub struct LegendOption {
  show : Bool
  left : String
  top : String
  bottom : String
  orient : String // "horizontal" | "vertical"
  data : Array[String]
  selected : Array[LegendSelection]
}

///|
pub impl Default for LegendOption with default() {
  // ECharts default: left:"center", bottom:15 (tokens.size.m), orient:"horizontal"
  {
    show: true,
    left: "center",
    top: "",
    bottom: "15",
    orient: "horizontal",
    data: [],
    selected: [],
  }
}

///|
pub fn LegendOption::is_selected(self : LegendOption, name : String) -> Bool {
  for i, _ in self.selected {
    let item = self.selected[i]
    if item.name == name {
      return item.selected
    }
  }
  true
}

///|
/// One indicator axis in a radar component.
/// Corresponds to: echarts/src/coord/radar/RadarModel.ts (indicator type)
pub struct RadarIndicator {
  name : String
  max : Double? // axis max; None = auto
  min : Double? // axis min; None = 0
}

///|
/// Radar coordinate component option.
/// Corresponds to: echarts/src/coord/radar/RadarModel.ts
pub struct RadarOption {
  indicator : Array[RadarIndicator]
  center : Array[String] // ["50%","50%"]
  radius : String // "75%" or pixel value
  start_angle : Double // default 90
  clockwise : Bool // default false (counterclockwise in ECharts)
  split_number : Int // number of concentric rings; default 5
}

///|
pub impl Default for RadarOption with default() {
  {
    indicator: [],
    center: ["50%", "50%"],
    radius: "75%",
    start_angle: 90.0,
    clockwise: false,
    split_number: 5,
  }
}

///|
pub struct AriaOption {
  enabled : Bool
  label_enabled : Bool
  description : String?
  general_with_title : String
  general_without_title : String
  series_max_count : Int
  series_single_prefix : String
  series_single_with_name : String
  series_single_without_name : String
  series_multiple_prefix : String
  series_multiple_with_name : String
  series_multiple_without_name : String
  series_multiple_separator_middle : String
  series_multiple_separator_end : String
  data_max_count : Int
  data_all_data : String
  data_partial_data : String
  data_with_name : String
  data_without_name : String
  data_separator_middle : String
  data_separator_end : String
}

///|
pub impl Default for AriaOption with default() {
  {
    enabled: false,
    label_enabled: true,
    description: None,
    general_with_title: "This is a chart about \"{title}\".",
    general_without_title: "This is a chart",
    series_max_count: 10,
    series_single_prefix: "",
    series_single_with_name: " with type {seriesType} named {seriesName}.",
    series_single_without_name: " with type {seriesType}.",
    series_multiple_prefix: ". It consists of {seriesCount} series count.",
    series_multiple_with_name: " The {seriesId} series is a {seriesType} representing {seriesName}.",
    series_multiple_without_name: " The {seriesId} series is a {seriesType}.",
    series_multiple_separator_middle: "",
    series_multiple_separator_end: "",
    data_max_count: 10,
    data_all_data: "The data is as follows: ",
    data_partial_data: "The first {displayCnt} items are: ",
    data_with_name: "the data for {name} is {value}",
    data_without_name: "{value}",
    data_separator_middle: ", ",
    data_separator_end: ". ",
  }
}

///|
pub struct VisualMapInRange {
  color : Array[String]
  symbol_size : Array[Double]
  opacity : Array[Double]
}

///|
pub impl Default for VisualMapInRange with default() {
  { color: [], symbol_size: [], opacity: [] }
}

///|
/// Corresponds to: echarts/src/component/visualMap/PiecewiseModel.ts
pub(all) struct VisualMapPieceOption {
  min : Double?
  max : Double?
  gt : Double?
  gte : Double?
  lt : Double?
  lte : Double?
  value : String?
  label : String?
  color : String?
  symbol : String?
}

///|
pub impl Default for VisualMapPieceOption with default() {
  {
    min: None,
    max: None,
    gt: None,
    gte: None,
    lt: None,
    lte: None,
    value: None,
    label: None,
    color: None,
    symbol: None,
  }
}

///|
pub(all) struct VisualMapSelection {
  key : String
  selected : Bool
}

///|
pub struct VisualMapOption {
  map_type : String?
  /// Minimum value of the mapped range.
  min : Double
  /// Maximum value of the mapped range.
  max : Double
  /// None means apply to all series; Some(n) means apply only to series n.
  series_index : Int?
  dimension : Int
  color : Array[String]
  text : Array[String]
  in_range : VisualMapInRange
  out_of_range : VisualMapInRange?
  text_style : ChartTextStyleOption?
  pieces : Array[VisualMapPieceOption]
  categories : Array[String]
  split_number : Int
  selected : Array[VisualMapSelection]
  /// Continuous visualMap selected range [min, max].
  /// Corresponds to: echarts/src/component/visualMap/ContinuousModel.ts range
  range : Array[Double]
  selected_mode : String
  show_label : Bool?
  item_gap : Double
  inverse : Bool
  align : String
  item_symbol : String
  min_open : Bool
  max_open : Bool
  precision : Int
  // Layout / rendering fields (from VisualMapModel.ts defaults):
  orient : String // "horizontal" | "vertical", default "vertical"
  left : String? // pixel or %; default None (ECharts: left=0 as fallback)
  right : String? // pixel or %; default None
  top : String? // pixel or %; default None
  bottom : String? // pixel or %; default None (ECharts: bottom=0 as fallback)
  show : Bool // whether to show the legend, default true
  item_width : Double? // default None → resolved to 20 (DEFAULT_BAR_BOUND[0])
  item_height : Double? // default None → resolved to 140 (DEFAULT_BAR_BOUND[1])
  controller_in_range : VisualMapInRange? // from controller.inRange
}

///|
pub impl Default for VisualMapOption with default() {
  {
    map_type: None,
    min: 0.0,
    max: 100.0,
    series_index: None,
    dimension: 0,
    color: [],
    text: [],
    in_range: VisualMapInRange::default(),
    out_of_range: None,
    text_style: None,
    pieces: [],
    categories: [],
    split_number: 0,
    selected: [],
    range: [],
    selected_mode: "multiple",
    show_label: None,
    item_gap: 10.0,
    inverse: false,
    align: "auto",
    item_symbol: "roundRect",
    min_open: false,
    max_open: false,
    precision: 0,
    orient: "vertical",
    left: None,
    right: None,
    top: None,
    bottom: None,
    show: true,
    item_width: None,
    item_height: None,
    controller_in_range: None,
  }
}

///|
pub enum CalendarCellSize {
  Auto
  Px(Double)
}

///|
pub struct CalendarSplitLineOption {
  show : Bool
  color : String
  width : Double
}

///|
pub impl Default for CalendarSplitLineOption with default() {
  { show: true, color: "#000000", width: 1.0 }
}

///|
pub struct CalendarItemStyleOption {
  color : String
  border_width : Double
  border_color : String
}

///|
pub impl Default for CalendarItemStyleOption with default() {
  { color: "#ffffff", border_width: 1.0, border_color: "#cccccc" }
}

///|
pub struct CalendarDayLabelOption {
  show : Bool
  first_day : Int
  position : String
  margin : String
  name_map : Array[String]?
  color : String
  font_size : Double
  font_family : String
  font_weight : String
  silent : Bool
}

///|
pub impl Default for CalendarDayLabelOption with default() {
  {
    show: true,
    first_day: 0,
    position: "start",
    margin: "10",
    name_map: None,
    color: "#000000",
    font_size: 12.0,
    font_family: "sans-serif",
    font_weight: "normal",
    silent: false,
  }
}

///|
pub struct CalendarMonthLabelOption {
  show : Bool
  position : String
  margin : Double
  align : String
  formatter : String?
  name_map : Array[String]?
  color : String
  font_size : Double
  font_family : String
  font_weight : String
  silent : Bool
}

///|
pub impl Default for CalendarMonthLabelOption with default() {
  {
    show: true,
    position: "start",
    margin: 10.0,
    align: "center",
    formatter: None,
    name_map: None,
    color: "#000000",
    font_size: 12.0,
    font_family: "sans-serif",
    font_weight: "normal",
    silent: false,
  }
}

///|
pub struct CalendarYearLabelOption {
  show : Bool
  position : String?
  margin : Double
  formatter : String?
  color : String
  font_size : Double
  font_family : String
  font_weight : String
  silent : Bool
}

///|
pub impl Default for CalendarYearLabelOption with default() {
  {
    show: true,
    position: None,
    margin: 30.0,
    formatter: None,
    color: "#cccccc",
    font_size: 20.0,
    font_family: "sans-serif",
    font_weight: "bolder",
    silent: false,
  }
}

///|
/// Calendar coordinate component option.
/// Corresponds to: echarts/src/coord/calendar/CalendarModel.ts
pub struct CalendarOption {
  left : SizeSpec?
  top : SizeSpec?
  right : SizeSpec?
  bottom : SizeSpec?
  width : SizeSpec?
  height : SizeSpec?
  cell_size : Array[CalendarCellSize]
  orient : String
  range : Array[String]
  split_line : CalendarSplitLineOption
  item_style : CalendarItemStyleOption
  day_label : CalendarDayLabelOption
  month_label : CalendarMonthLabelOption
  year_label : CalendarYearLabelOption
}

///|
pub impl Default for CalendarOption with default() {
  {
    left: Some(SizeSpec::Px(80.0)),
    top: Some(SizeSpec::Px(60.0)),
    right: None,
    bottom: None,
    width: None,
    height: None,
    cell_size: [CalendarCellSize::Px(20.0), CalendarCellSize::Px(20.0)],
    orient: "horizontal",
    range: [],
    split_line: CalendarSplitLineOption::default(),
    item_style: CalendarItemStyleOption::default(),
    day_label: CalendarDayLabelOption::default(),
    month_label: CalendarMonthLabelOption::default(),
    year_label: CalendarYearLabelOption::default(),
  }
}

///|
pub struct MatrixLabelOption {
  show : Bool
  color : String
  font_size : Double
  font_family : String
  font_weight : String
}

///|
pub impl Default for MatrixLabelOption with default() {
  {
    show: true,
    color: "#54555a",
    font_size: 12.0,
    font_family: "sans-serif",
    font_weight: "normal",
  }
}

///|
pub struct MatrixItemStyleOption {
  color : String
  border_color : String
  border_width : Double
}

///|
pub impl Default for MatrixItemStyleOption with default() {
  { color: "none", border_color: "#d7dbe3", border_width: 1.0 }
}

///|
pub struct MatrixLineStyleOption {
  color : String
  width : Double
}

///|
pub impl Default for MatrixLineStyleOption with default() {
  { color: "#54555a", width: 1.0 }
}

///|
pub(all) struct MatrixDimensionLevelOption {
  level_size : SizeSpec?
}

///|
pub impl Default for MatrixDimensionLevelOption with default() {
  { level_size: None }
}

///|
pub(all) struct MatrixDimensionCellOption {
  value : String?
  size : SizeSpec?
  children : Array[MatrixDimensionCellOption]
  item_style : MatrixItemStyleOption?
  label : MatrixLabelOption?
}

///|
pub(all) struct MatrixDimensionOption {
  show : Bool
  data : Array[MatrixDimensionCellOption]
  length : Int?
  level_size : SizeSpec?
  levels : Array[MatrixDimensionLevelOption]
  item_style : MatrixItemStyleOption
  label : MatrixLabelOption
  divider_line_style : MatrixLineStyleOption
}

///|
pub impl Default for MatrixDimensionOption with default() {
  {
    show: true,
    data: [],
    length: None,
    level_size: None,
    levels: [],
    item_style: MatrixItemStyleOption::default(),
    label: MatrixLabelOption::default(),
    divider_line_style: MatrixLineStyleOption::default(),
  }
}

///|
pub(all) enum MatrixCoordValue {
  Locator(Int)
  Name(String)
  Missing
}

///|
pub(all) enum MatrixCoordPart {
  Value(MatrixCoordValue)
  Range(MatrixCoordValue, MatrixCoordValue)
  Missing
}

///|
pub(all) struct MatrixBodyCellOption {
  coord : Array[MatrixCoordPart]
  value : String?
  item_style : MatrixItemStyleOption?
  label : MatrixLabelOption?
  coord_clamp : Bool
  merge_cells : Bool
}

///|
pub(all) struct MatrixBodyOption {
  data : Array[MatrixBodyCellOption]
  item_style : MatrixItemStyleOption
  label : MatrixLabelOption
}

///|
pub impl Default for MatrixBodyOption with default() {
  {
    data: [],
    item_style: MatrixItemStyleOption::default(),
    label: MatrixLabelOption::default(),
  }
}

///|
pub(all) struct MatrixOption {
  left : SizeSpec?
  top : SizeSpec?
  right : SizeSpec?
  bottom : SizeSpec?
  width : SizeSpec?
  height : SizeSpec?
  x : MatrixDimensionOption
  y : MatrixDimensionOption
  body : MatrixBodyOption
  corner : MatrixBodyOption
  background_style : MatrixItemStyleOption
  border_z2 : Double?
}

///|
pub impl Default for MatrixOption with default() {
  {
    left: Some(SizeSpec::Pct(10.0)),
    top: Some(SizeSpec::Pct(10.0)),
    right: Some(SizeSpec::Pct(10.0)),
    bottom: Some(SizeSpec::Pct(10.0)),
    width: None,
    height: None,
    x: MatrixDimensionOption::default(),
    y: MatrixDimensionOption::default(),
    body: MatrixBodyOption::default(),
    corner: {
      ..MatrixBodyOption::default(),
      item_style: { color: "none", border_color: "none", border_width: 1.0 },
    },
    background_style: {
      color: "none",
      border_color: "#54555a",
      border_width: 1.0,
    },
    border_z2: None,
  }
}

///|
pub(all) struct SingleAxisLineStyleOption {
  width : Double
  line_type : String
}

///|
pub impl Default for SingleAxisLineStyleOption with default() {
  { width: 1.0, line_type: "solid" }
}

///|
pub(all) struct SingleAxisLineOption {
  show : Bool
  line_style : SingleAxisLineStyleOption
}

///|
pub impl Default for SingleAxisLineOption with default() {
  { show: true, line_style: SingleAxisLineStyleOption::default() }
}

///|
pub(all) struct SingleAxisTickOption {
  show : Bool
  length : Double
  width : Double
  inside : Bool
}

///|
pub impl Default for SingleAxisTickOption with default() {
  { show: true, length: 6.0, width: 1.0, inside: false }
}

///|
pub(all) struct SingleAxisLabelOption {
  show : Bool
  inside : Bool
  rotate : Double
}

///|
pub impl Default for SingleAxisLabelOption with default() {
  { show: true, inside: false, rotate: 0.0 }
}

///|
pub(all) struct SingleAxisSplitLineOption {
  show : Bool
  line_type : String
  opacity : Double
}

///|
pub impl Default for SingleAxisSplitLineOption with default() {
  { show: true, line_type: "dashed", opacity: 0.2 }
}

///|
/// Corresponds to: echarts/src/coord/single/AxisModel.ts
pub(all) struct SingleAxisOption {
  axis_type : AxisType
  orient : String // "horizontal" | "vertical"
  position : String // "top" | "bottom" | "left" | "right"
  left : SizeSpec?
  top : SizeSpec?
  right : SizeSpec?
  bottom : SizeSpec?
  width : SizeSpec?
  height : SizeSpec?
  min : Double?
  max : Double?
  data : Array[String]
  inverse : Bool
  axis_line : SingleAxisLineOption
  axis_tick : SingleAxisTickOption
  axis_label : SingleAxisLabelOption
  split_line : SingleAxisSplitLineOption
}

///|
pub impl Default for SingleAxisOption with default() {
  {
    axis_type: AxisType::Value,
    orient: "horizontal",
    position: "bottom",
    left: Some(SizeSpec::Pct(5.0)),
    top: Some(SizeSpec::Pct(5.0)),
    right: Some(SizeSpec::Pct(5.0)),
    bottom: Some(SizeSpec::Pct(5.0)),
    width: None,
    height: None,
    min: None,
    max: None,
    data: [],
    inverse: false,
    axis_line: SingleAxisLineOption::default(),
    axis_tick: SingleAxisTickOption::default(),
    axis_label: SingleAxisLabelOption::default(),
    split_line: SingleAxisSplitLineOption::default(),
  }
}

///|
/// Corresponds to: echarts/src/component/dataZoom/DataZoomModel.ts DataZoomOption
/// Minimal subset used for range state tracking in static rendering.
pub(all) struct DataZoomOption {
  // Percent range 0-100
  start : Double
  end : Double
  // Value-based range (overrides percent when set)
  start_value : String?
  end_value : String?
}

///|
pub impl Default for DataZoomOption with default() {
  { start: 0.0, end: 100.0, start_value: None, end_value: None }
}

///|
/// Root chart option.
pub(all) struct ChartOption {
  width : Double
  height : Double
  text_style : ChartTextStyleOption
  title : TitleOption?
  titles : Array[TitleOption]
  legend : LegendOption?
  x_axis : Array[AxisOption]
  y_axis : Array[AxisOption]
  angle_axis : Array[AxisOption]
  radius_axis : Array[AxisOption]
  grid : Array[GridOption]
  polar : Array[PolarOption]
  parallel : Array[ParallelOption]
  parallel_axis : Array[ParallelAxisOption]
  geo : Array[GeoOption]
  calendar : Array[CalendarOption]
  matrix : Array[MatrixOption]
  radar : Array[RadarOption]
  single_axis : Array[SingleAxisOption]
  series : Array[SeriesOption]
  map_registry : Array[MapRegistryOption]
  background_color : String?
  aria : AriaOption?
  visual_map : Array[VisualMapOption]
  data_zoom : Array[DataZoomOption]
}

///|

///|
pub impl Default for ChartOption with default() {
  {
    width: 600.0,
    height: 400.0,
    text_style: ChartTextStyleOption::default(),
    title: None,
    titles: [],
    legend: None,
    x_axis: [],
    y_axis: [],
    angle_axis: [],
    radius_axis: [],
    grid: [GridOption::default()],
    polar: [],
    parallel: [],
    parallel_axis: [],
    geo: [],
    calendar: [],
    matrix: [],
    radar: [],
    single_axis: [],
    series: [],
    map_registry: [],
    background_color: None,
    aria: None,
    visual_map: [],
    data_zoom: [],
  }
}

///|
/// Template label formatter.
/// <=> echarts/src/util/format.ts:formatTpl
///
/// Substitutes {a} → series_name, {b} → name, {c} → value, {d} → percent.
/// Multi-series aliases: {a0} = {a}, {b0} = {b}, etc. (first series only).
/// Corresponds to TPL_VAR_ALIAS = ['a','b','c','d','e','f','g'] and
/// $vars = ['seriesName','name','value'] in upstream format.ts.
pub fn format_label_tpl(
  tpl : String,
  series_name : String,
  name : String,
  value : String,
  percent : String?,
) -> String {
  // Map single-index aliases {a0}/{b0}/{c0}/{d0} → {a}/{b}/{c}/{d}
  let mut result = tpl
  result = result.replace(old="{a0}", new="{a}")
  result = result.replace(old="{b0}", new="{b}")
  result = result.replace(old="{c0}", new="{c}")
  result = result.replace(old="{d0}", new="{d}")
  // Substitute core variables
  result = result.replace(old="{a}", new=series_name)
  result = result.replace(old="{b}", new=name)
  result = result.replace(old="{c}", new=value)
  match percent {
    Some(p) => result = result.replace(old="{d}", new=p)
    None => ()
  }
  // {value} for axis-label style templates (axisHelper.ts:makeLabelFormatter)
  result = result.replace(old="{value}", new=value)
  strip_rich_text_style(result)
}

///|
/// Rich text template branch in ECharts supports style wrappers like
/// `{name|text}`. Since style-token rendering is not yet implemented in
/// MoonBit SVG text, keep text content and drop wrapper markers.
/// <=> echarts/src/label/labelStyle.ts + format.ts rich text pipeline
fn strip_rich_text_style(text : String) -> String {
  let out = StringBuilder::new()
  let mut in_brace = false
  let mut seen_pipe = false
  let mut head = StringBuilder::new()
  let mut body = StringBuilder::new()

  for ch in text {
    if !in_brace {
      if ch == '{' {
        in_brace = true
        seen_pipe = false
        head = StringBuilder::new()
        body = StringBuilder::new()
      } else {
        out.write_char(ch)
      }
      continue
    }

    if ch == '}' {
      if seen_pipe {
        out.write_string(body.to_string())
      } else {
        out.write_char('{')
        out.write_string(head.to_string())
        out.write_char('}')
      }
      in_brace = false
      continue
    }

    if ch == '|' && !seen_pipe {
      seen_pipe = true
      continue
    }

    if seen_pipe {
      body.write_char(ch)
    } else {
      head.write_char(ch)
    }
  }

  // Keep unfinished template text as-is when missing closing brace.
  if in_brace {
    out.write_char('{')
    out.write_string(head.to_string())
    if seen_pipe {
      out.write_char('|')
    }
    out.write_string(body.to_string())
  }

  out.to_string()
}

///|
/// Apply GeoLabelOption.formatter to produce the label text for a data item.
/// Falls back to the item name if no formatter is set.
/// <=> echarts/src/model/mixin/dataFormat.ts:getFormattedLabel (string branch)
pub fn apply_label_formatter(
  label : GeoLabelOption?,
  series_name : String,
  item_name : String,
  value : String,
  percent : String?,
) -> String {
  match label {
    Some({ formatter: Some(tpl), .. }) if tpl != "" =>
      format_label_tpl(tpl, series_name, item_name, value, percent)
    _ => item_name
  }
}

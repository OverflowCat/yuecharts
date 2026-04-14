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
/// X or Y axis configuration.
pub(all) struct AxisOption {
  axis_type : AxisType
  position : AxisPosition?
  name : String?
  data : Array[String] // category labels
  min : Double?
  max : Double?
  grid_index : Int?
  polar_index : Int?
  start_angle : Double?
  end_angle : Double?
  clockwise : Bool?
  inverse : Bool
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
    grid_index: None,
    polar_index: None,
    start_angle: None,
    end_angle: None,
    clockwise: None,
    inverse: false,
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
    grid_index: None,
    polar_index: None,
    start_angle: None,
    end_angle: None,
    clockwise: None,
    inverse: false,
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
  font_size : Double
  font_family : String
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
    font_size: 12.0,
    font_family: "sans-serif",
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
  font_size : Double?
  font_family : String?
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
    font_size: None,
    font_family: None,
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
  { area_color: None, border_color: "#8f98a3", border_width: 0.5 }
}

///|
pub(all) struct GeoItemStylePatchOption {
  color : String?
  area_color : String?
  border_color : String?
  border_width : Double?
  opacity : Double?
}

///|
pub impl Default for GeoItemStylePatchOption with default() {
  {
    color: None,
    area_color: None,
    border_color: None,
    border_width: None,
    opacity: None,
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
} derive(Eq)

///|
/// Data value in a series: can be a number, an array, or null.
pub(all) enum DataValue {
  Num(Double)
  Vec(Array[Double])
  DateValue(String, Double)
  Null
}

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
  bar_gap : String?
  bar_category_gap : String?
  bar_min_height : Double
  bar_min_angle : Double
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
  // For themeRiver: [before, after] gap on axis orthogonal direction
  boundary_gap : Array[String]
  smooth : Bool
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
    bar_gap: None,
    bar_category_gap: None,
    bar_min_height: 0.0,
    bar_min_angle: 0.0,
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
    geo_index: 0,
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
    boundary_gap: [],
    smooth: false,
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
pub fn SeriesOption::default_pie() -> SeriesOption {
  {
    ..SeriesOption::default_line(),
    series_type: SeriesType::Pie,
    radius: ["0%", "75%"],
    center: ["50%", "50%"],
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
    label: Some({ ..GeoLabelOption::default(), show: true }),
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
      show: true,
      color: "#54555a",
      position: Some("outside"),
      distance: Some(5.0),
      font_weight: None,
      rotate: None,
      font_size: 12.0,
      font_family: "sans-serif",
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
      show: true,
      color: "#333333",
      position: Some("right"),
      distance: None,
      font_weight: None,
      rotate: None,
      font_size: 12.0,
      font_family: "sans-serif",
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
    selected: [],
  }
}

///|
pub fn LegendOption::is_selected(self : LegendOption, name : String) -> Bool {
  let mut i = 0
  while i < self.selected.length() {
    let item = self.selected[i]
    if item.name == name {
      return item.selected
    }
    i += 1
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
  series_index : Int
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
    series_index: 0,
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
/// Root chart option.
pub(all) struct ChartOption {
  width : Double
  height : Double
  text_style : ChartTextStyleOption
  title : TitleOption?
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
}

///|

///|
pub impl Default for ChartOption with default() {
  {
    width: 600.0,
    height: 400.0,
    text_style: ChartTextStyleOption::default(),
    title: None,
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
  }
}

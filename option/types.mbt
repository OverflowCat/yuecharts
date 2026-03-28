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
}

///|
pub impl Default for GeoLabelOption with default() {
  { show: false, color: "#54555a" }
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
pub(all) struct GeoRegionOption {
  name : String
  label : GeoLabelOption?
  item_style : GeoItemStyleOption?
}

///|
pub(all) struct GeoOption {
  map : String
  roam : Bool
  aspect_scale : Double?
  label : GeoLabelOption
  item_style : GeoItemStyleOption
  name_map : Array[GeoNameMapEntry]
  regions : Array[GeoRegionOption]
}

///|
pub impl Default for GeoOption with default() {
  {
    map: "",
    roam: false,
    aspect_scale: None,
    label: GeoLabelOption::default(),
    item_style: GeoItemStyleOption::default(),
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
  special_areas : Array[MapSpecialAreaOption]
}

///|
/// Grid layout specification.
pub(all) struct GridOption {
  left : SizeSpec
  right : SizeSpec
  top : SizeSpec
  bottom : SizeSpec
  width : SizeSpec?
  height : SizeSpec?
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
    left: SizeSpec::Pct(15.0),
    right: SizeSpec::Pct(10.0),
    top: SizeSpec::Px(65.0),
    bottom: SizeSpec::Px(80.0),
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
  name : String?
  symbol : String?
  coords : Array[Array[Double]]?
  from_name : String?
  to_name : String?
  children : Array[DataItem]
}

///|
pub enum SymbolBoundingData {
  Single(Double)
  Pair(Double, Double)
}

///|

///|
/// Series configuration.
pub(all) struct SeriesOption {
  series_type : SeriesType
  name : String?
  data : Array[DataItem]
  symbol : String?
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
  x_axis_index : Int
  y_axis_index : Int
  parallel_index : Int
  radius_axis_index : Int
  angle_axis_index : Int
  polar_index : Int
  coordinate_system : String?
  calendar_index : Int
  geo_index : Int
  // For radar: index into ChartOption.radar[]
  radar_index : Int
  map_name : String?
  stack : String?
  smooth : Bool
  polyline : Bool
  symbol_size : Double
  color : String?
  line_style_color : String?
  line_style_width : Double?
  line_style_opacity : Double?
  line_style_curveness : Double?
  item_style : String? // color override
  item_opacity : Double?
  area_style : Bool
  encode_x : String?
  encode_y : String?
  // For pie charts
  radius : Array[String]
  center : Array[String]
  // For sunburst charts
  min_angle : Double // option degrees, default 0
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
}

///|
pub fn SeriesOption::default_line() -> SeriesOption {
  {
    series_type: SeriesType::Line,
    name: None,
    data: [],
    symbol: None,
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
    x_axis_index: 0,
    y_axis_index: 0,
    parallel_index: 0,
    radius_axis_index: 0,
    angle_axis_index: 0,
    polar_index: 0,
    coordinate_system: None,
    calendar_index: 0,
    geo_index: 0,
    radar_index: 0,
    map_name: None,
    stack: None,
    smooth: false,
    polyline: false,
    symbol_size: 4.0,
    color: None,
    line_style_color: None,
    line_style_width: None,
    line_style_opacity: None,
    line_style_curveness: None,
    item_style: None,
    item_opacity: None,
    area_style: false,
    encode_x: None,
    encode_y: None,
    radius: [],
    center: [],
    min_angle: 0.0,
    clockwise: true,
    start_angle: 225.0,
    end_angle: -45.0,
    min_val: 0.0,
    max_val: 100.0,
    split_number: 10,
    map_value_calculation: MapValueCalculationType::Sum,
    active_opacity: None,
    inactive_opacity: None,
  }
}

///|

///|
pub fn SeriesOption::default_bar() -> SeriesOption {
  { ..SeriesOption::default_line(), series_type: SeriesType::Bar }
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
    symbol: Some("none"),
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
  }
}

///|
/// Title component.
pub struct TitleOption {
  text : String
  subtext : String
  left : String // "left" | "center" | "right" | pixel
  top : String
}

///|
pub impl Default for TitleOption with default() {
  // ECharts default: left='center', top='auto'
  // See echarts/src/component/title/install.ts
  { text: "", subtext: "", left: "center", top: "auto" }
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
}

///|
pub impl Default for VisualMapInRange with default() {
  { color: [], symbol_size: [] }
}

///|
pub struct VisualMapOption {
  /// Minimum value of the mapped range.
  min : Double
  /// Maximum value of the mapped range.
  max : Double
  series_index : Int
  dimension : Int
  in_range : VisualMapInRange
}

///|
pub impl Default for VisualMapOption with default() {
  {
    min: 0.0,
    max: 100.0,
    series_index: 0,
    dimension: 0,
    in_range: VisualMapInRange::default(),
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
/// Root chart option.
pub(all) struct ChartOption {
  width : Double
  height : Double
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
  radar : Array[RadarOption]
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
    width: 800.0,
    height: 600.0,
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
    radar: [],
    series: [],
    map_registry: [],
    background_color: None,
    aria: None,
    visual_map: [],
  }
}

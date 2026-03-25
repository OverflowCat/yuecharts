// Corresponds to: echarts/src/coord/axisCommonTypes.ts
// echarts/src/component/axis/AxisModel.ts
// and various echarts/src/option/*.ts files

///|
/// Axis type.
pub enum AxisType {
  Value // continuous numeric
  Category // discrete string categories
  Time // time series
  Log // logarithmic
}

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
pub struct AxisOption {
  axis_type : AxisType
  position : AxisPosition?
  name : String?
  data : Array[String] // category labels
  min : Double?
  max : Double?
  grid_index : Int?
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
  }
}

///|
/// Grid layout specification.
pub struct GridOption {
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
pub enum SizeSpec {
  Px(Double)
  Pct(Double) // 0-100
}

///|
pub fn GridOption::default() -> GridOption {
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
/// Series type.
pub enum SeriesType {
  Line
  Bar
  Scatter
  Pie
  Sunburst
  Treemap
  Radar
  Candlestick
  Heatmap
  Boxplot
  Funnel
  Gauge
}

///|
/// Data value in a series: can be a number, an array, or null.
pub enum DataValue {
  Num(Double)
  Vec(Array[Double])
  Null
}

///|
/// One item in a series data array.
pub struct DataItem {
  value : DataValue
  name : String?
  children : Array[DataItem]
}

///|
/// Series configuration.
pub struct SeriesOption {
  series_type : SeriesType
  name : String?
  data : Array[DataItem]
  x_axis_index : Int
  y_axis_index : Int
  // For radar: index into ChartOption.radar[]
  radar_index : Int
  stack : String?
  smooth : Bool
  symbol_size : Double
  color : String?
  line_style_width : Double?
  item_style : String? // color override
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
}

///|
pub fn SeriesOption::default_line() -> SeriesOption {
  {
    series_type: SeriesType::Line,
    name: None,
    data: [],
    x_axis_index: 0,
    y_axis_index: 0,
    radar_index: 0,
    stack: None,
    smooth: false,
    symbol_size: 4.0,
    color: None,
    line_style_width: None,
    item_style: None,
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
  }
}

///|
pub fn SeriesOption::default_bar() -> SeriesOption {
  { ..SeriesOption::default_line(), series_type: SeriesType::Bar }
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
/// Title component.
pub struct TitleOption {
  text : String
  subtext : String
  left : String // "left" | "center" | "right" | pixel
  top : String
}

///|
pub fn TitleOption::default() -> TitleOption {
  { text: "", subtext: "", left: "auto", top: "auto" }
}

///|
/// Legend component.
pub struct LegendOption {
  show : Bool
  left : String
  top : String
  bottom : String
  orient : String // "horizontal" | "vertical"
}

///|
pub fn LegendOption::default() -> LegendOption {
  // ECharts default: left:"center", bottom:15 (tokens.size.m), orient:"horizontal"
  { show: true, left: "center", top: "", bottom: "15", orient: "horizontal" }
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
pub fn RadarOption::default() -> RadarOption {
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
/// Visual map configuration: maps a numeric value range to visual properties.
/// Corresponds to echarts/src/component/visualMap/VisualMapModel.ts
pub struct VisualMapOption {
  /// Minimum value of the mapped range.
  min : Double
  /// Maximum value of the mapped range.
  max : Double
}

///|
pub fn VisualMapOption::default() -> VisualMapOption {
  { min: 0.0, max: 100.0 }
}

///|
/// Root chart option.
pub struct ChartOption {
  width : Double
  height : Double
  title : TitleOption?
  legend : LegendOption?
  x_axis : Array[AxisOption]
  y_axis : Array[AxisOption]
  grid : Array[GridOption]
  radar : Array[RadarOption]
  series : Array[SeriesOption]
  background_color : String?
  visual_map : VisualMapOption?
}

///|
pub fn ChartOption::default() -> ChartOption {
  {
    width: 800.0,
    height: 600.0,
    title: None,
    legend: None,
    x_axis: [],
    y_axis: [],
    grid: [GridOption::default()],
    radar: [],
    series: [],
    background_color: None,
    visual_map: None,
  }
}

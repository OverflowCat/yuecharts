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
  {
    left: SizeSpec::Px(80.0),
    right: SizeSpec::Px(30.0),
    top: SizeSpec::Px(60.0),
    bottom: SizeSpec::Px(60.0),
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
  Radar
  Candlestick
  Heatmap
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
}

///|
/// Series configuration.
pub struct SeriesOption {
  series_type : SeriesType
  name : String?
  data : Array[DataItem]
  x_axis_index : Int
  y_axis_index : Int
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
}

///|
pub fn SeriesOption::default_line() -> SeriesOption {
  {
    series_type: SeriesType::Line,
    name: None,
    data: [],
    x_axis_index: 0,
    y_axis_index: 0,
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
  orient : String // "horizontal" | "vertical"
}

///|
pub fn LegendOption::default() -> LegendOption {
  { show: true, left: "center", top: "top", orient: "horizontal" }
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
  series : Array[SeriesOption]
  background_color : String?
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
    series: [],
    background_color: None,
  }
}

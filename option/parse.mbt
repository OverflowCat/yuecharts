// Corresponds to: echarts/src/core/echarts.ts (setOption processing)
// and echarts/src/util/model.ts (option normalization)

///|
/// Parse a JSON string into a ChartOption.
pub fn parse(json_str : String) -> ChartOption raise @json.ParseError {
  let j = @json.parse(json_str)
  parse_chart_option(j)
}

///|
fn parse_chart_option(j : Json) -> ChartOption {
  let base = ChartOption::default()
  let width = j_number(j, "width", base.width)
  let height = j_number(j, "height", base.height)
  let background_color = j_string_opt(j, "backgroundColor")
  let title = match j_field(j, "title") {
    Some(t) => Some(parse_title(t))
    None => None
  }
  let legend = match j_field(j, "legend") {
    Some(l) => Some(parse_legend(l))
    None => None
  }
  // x_axis can be object or array
  let x_axis = match j_field(j, "xAxis") {
    Some(Array(arr)) => arr.map(parse_axis_option_x)
    Some(obj) if obj is Object(_) => [parse_axis_option_x(obj)]
    _ => [AxisOption::default_x()]
  }
  let y_axis = match j_field(j, "yAxis") {
    Some(Array(arr)) => arr.map(parse_axis_option_y)
    Some(obj) if obj is Object(_) => [parse_axis_option_y(obj)]
    _ => [AxisOption::default_y()]
  }
  let grid = match j_field(j, "grid") {
    Some(Array(arr)) => arr.map(parse_grid_option)
    Some(obj) if obj is Object(_) => [parse_grid_option(obj)]
    _ => [GridOption::default()]
  }
  let series = match j_field(j, "series") {
    Some(Array(arr)) => arr.map(parse_series_option)
    Some(obj) if obj is Object(_) => [parse_series_option(obj)]
    _ => []
  }
  {
    width,
    height,
    title,
    legend,
    x_axis,
    y_axis,
    grid,
    series,
    background_color,
  }
}

///|
fn parse_title(j : Json) -> TitleOption {
  let base = TitleOption::default()
  {
    text: j_string(j, "text", base.text),
    subtext: j_string(j, "subtext", base.subtext),
    left: j_string(j, "left", base.left),
    top: j_string(j, "top", base.top),
  }
}

///|
fn parse_legend(j : Json) -> LegendOption {
  let base = LegendOption::default()
  {
    show: j_bool(j, "show", base.show),
    left: j_string(j, "left", base.left),
    top: j_string(j, "top", base.top),
    orient: j_string(j, "orient", base.orient),
  }
}

///|
fn parse_axis_option_x(j : Json) -> AxisOption {
  parse_axis_option(j, AxisOption::default_x())
}

///|
fn parse_axis_option_y(j : Json) -> AxisOption {
  parse_axis_option(j, AxisOption::default_y())
}

///|
fn parse_axis_option(j : Json, base : AxisOption) -> AxisOption {
  let axis_type = match j_string(j, "type", "") {
    "value" => AxisType::Value
    "category" => AxisType::Category
    "time" => AxisType::Time
    "log" => AxisType::Log
    _ => base.axis_type
  }
  let position = match j_string(j, "position", "") {
    "bottom" => Some(AxisPosition::Bottom)
    "top" => Some(AxisPosition::Top)
    "left" => Some(AxisPosition::Left)
    "right" => Some(AxisPosition::Right)
    _ => base.position
  }
  let data = match j_field(j, "data") {
    Some(Array(arr)) =>
      arr.map(fn(item) {
        match item {
          String(s) => s
          _ => item.to_string()
        }
      })
    _ => base.data
  }
  let name = j_string_opt(j, "name")
  let min = j_number_opt(j, "min")
  let max = j_number_opt(j, "max")
  { axis_type, position, name, data, min, max, grid_index: base.grid_index }
}

///|
fn parse_grid_option(j : Json) -> GridOption {
  let base = GridOption::default()
  {
    left: parse_size_spec(j, "left", base.left),
    right: parse_size_spec(j, "right", base.right),
    top: parse_size_spec(j, "top", base.top),
    bottom: parse_size_spec(j, "bottom", base.bottom),
    width: None,
    height: None,
    contain_label: j_bool(j, "containLabel", base.contain_label),
  }
}

///|
fn parse_size_spec(j : Json, key : String, default_val : SizeSpec) -> SizeSpec {
  match j_field(j, key) {
    Some(Number(n, ..)) => SizeSpec::Px(n)
    Some(String(s)) =>
      if s.has_suffix("%") {
        let pct_str = s[:s.length() - 1]
        let r = try? @strconv.parse_double(pct_str.to_string())
        match r {
          Ok(pct) => SizeSpec::Pct(pct)
          Err(_) => default_val
        }
      } else {
        let r = try? @strconv.parse_double(s)
        match r {
          Ok(px) => SizeSpec::Px(px)
          Err(_) => default_val
        }
      }
    _ => default_val
  }
}

///|
fn parse_series_option(j : Json) -> SeriesOption {
  let series_type = match j_string(j, "type", "line") {
    "line" => SeriesType::Line
    "bar" => SeriesType::Bar
    "scatter" => SeriesType::Scatter
    "pie" => SeriesType::Pie
    "radar" => SeriesType::Radar
    "candlestick" => SeriesType::Candlestick
    "heatmap" => SeriesType::Heatmap
    _ => SeriesType::Line
  }
  let base = match series_type {
    Line => SeriesOption::default_line()
    Bar => SeriesOption::default_bar()
    Scatter => SeriesOption::default_scatter()
    Pie => SeriesOption::default_pie()
    _ => SeriesOption::default_line()
  }
  let data = match j_field(j, "data") {
    Some(Array(arr)) => arr.map(parse_data_item)
    _ => base.data
  }
  let name = j_string_opt(j, "name")
  let x_axis_index = j_int(j, "xAxisIndex", base.x_axis_index)
  let y_axis_index = j_int(j, "yAxisIndex", base.y_axis_index)
  let smooth = j_bool(j, "smooth", base.smooth)
  let symbol_size = j_number(j, "symbolSize", base.symbol_size)
  let color = match j_string_opt(j, "color") {
    Some(c) => Some(c)
    None => base.color
  }
  let area_style = match j_field(j, "areaStyle") {
    None => base.area_style
    Some(Null) => base.area_style
    Some(_) => true
  }
  let stack = j_string_opt(j, "stack")
  let radius = match j_field(j, "radius") {
    Some(Array(arr)) =>
      arr.map(fn(v) {
        match v {
          String(s) => s
          Number(n, ..) => "\{n}"
          _ => ""
        }
      })
    Some(String(s)) => [s]
    _ => base.radius
  }
  let center = match j_field(j, "center") {
    Some(Array(arr)) =>
      arr.map(fn(v) {
        match v {
          String(s) => s
          Number(n, ..) => "\{n}"
          _ => ""
        }
      })
    Some(String(s)) => [s]
    _ => base.center
  }
  {
    series_type,
    name,
    data,
    x_axis_index,
    y_axis_index,
    stack,
    smooth,
    symbol_size,
    color,
    line_style_width: None,
    item_style: None,
    area_style,
    encode_x: None,
    encode_y: None,
    radius,
    center,
  }
}

///|
fn parse_data_item(j : Json) -> DataItem {
  match j {
    Number(n, ..) => { value: DataValue::Num(n), name: None }
    Null => { value: DataValue::Null, name: None }
    True => { value: DataValue::Num(1.0), name: None }
    False => { value: DataValue::Num(0.0), name: None }
    Array(arr) => {
      let nums = arr.map(fn(v) {
        match v {
          Number(n, ..) => n
          _ => 0.0
        }
      })
      { value: DataValue::Vec(nums), name: None }
    }
    Object(_) => {
      let v = match j_field(j, "value") {
        Some(Number(n, ..)) => DataValue::Num(n)
        Some(Array(arr)) => {
          let nums = arr.map(fn(vv) {
            match vv {
              Number(n, ..) => n
              _ => 0.0
            }
          })
          DataValue::Vec(nums)
        }
        _ => DataValue::Null
      }
      let name = match j_field(j, "name") {
        Some(String(s)) => Some(s)
        _ => None
      }
      { value: v, name }
    }
    _ => { value: DataValue::Null, name: None }
  }
}

// ---- JSON access helpers ----

///|
/// Get a field from a JSON object.
fn j_field(j : Json, key : String) -> Json? {
  match j {
    Object(map) => map.get(key)
    _ => None
  }
}

///|
fn j_number(j : Json, key : String, default_val : Double) -> Double {
  match j_field(j, key) {
    Some(Number(n, ..)) => n
    _ => default_val
  }
}

///|
fn j_number_opt(j : Json, key : String) -> Double? {
  match j_field(j, key) {
    Some(Number(n, ..)) => Some(n)
    _ => None
  }
}

///|
fn j_string(j : Json, key : String, default_val : String) -> String {
  match j_field(j, key) {
    Some(String(s)) => s
    _ => default_val
  }
}

///|
fn j_string_opt(j : Json, key : String) -> String? {
  match j_field(j, key) {
    Some(String(s)) => Some(s)
    _ => None
  }
}

///|
fn j_bool(j : Json, key : String, default_val : Bool) -> Bool {
  match j_field(j, key) {
    Some(True) => true
    Some(False) => false
    _ => default_val
  }
}

///|
fn j_int(j : Json, key : String, default_val : Int) -> Int {
  match j_field(j, key) {
    Some(Number(n, ..)) => n.to_int()
    _ => default_val
  }
}

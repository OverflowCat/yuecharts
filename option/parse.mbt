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
  let aria = match j_field(j, "aria") {
    Some(a) => Some(parse_aria_option(a))
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
  let radar = match j_field(j, "radar") {
    Some(Array(arr)) => arr.map(parse_radar_option)
    Some(obj) if obj is Object(_) => [parse_radar_option(obj)]
    _ => []
  }
  let series = match j_field(j, "series") {
    Some(Array(arr)) => arr.map(parse_series_option)
    Some(obj) if obj is Object(_) => [parse_series_option(obj)]
    _ => []
  }
  let visual_map = match j_field(j, "visualMap") {
    Some(vm) => Some(parse_visual_map(vm))
    None => None
  }
  {
    width,
    height,
    title,
    legend,
    x_axis,
    y_axis,
    grid,
    radar,
    series,
    background_color,
    aria,
    visual_map,
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
    bottom: j_string(j, "bottom", base.bottom),
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
    "pictorialBar" => SeriesType::PictorialBar
    "scatter" => SeriesType::Scatter
    "effectScatter" => SeriesType::EffectScatter
    "pie" => SeriesType::Pie
    "sunburst" => SeriesType::Sunburst
    "treemap" => SeriesType::Treemap
    "radar" => SeriesType::Radar
    "candlestick" => SeriesType::Candlestick
    "heatmap" => SeriesType::Heatmap
    "boxplot" => SeriesType::Boxplot
    "funnel" => SeriesType::Funnel
    "gauge" => SeriesType::Gauge
    _ => SeriesType::Line
  }
  let base = match series_type {
    Line => SeriesOption::default_line()
    Bar => SeriesOption::default_bar()
    PictorialBar => SeriesOption::default_pictorial_bar()
    Scatter => SeriesOption::default_scatter()
    EffectScatter => SeriesOption::default_effect_scatter()
    Pie => SeriesOption::default_pie()
    Sunburst => SeriesOption::default_sunburst()
    Treemap => SeriesOption::default_treemap()
    Gauge => SeriesOption::default_gauge()
    _ => SeriesOption::default_line()
  }
  // Note: Candlestick, Heatmap, Boxplot, Radar use default_line as base defaults.
  let data = match j_field(j, "data") {
    Some(Array(arr)) => arr.map(parse_data_item)
    _ => base.data
  }
  let name = j_string_opt(j, "name")
  let x_axis_index = j_int(j, "xAxisIndex", base.x_axis_index)
  let y_axis_index = j_int(j, "yAxisIndex", base.y_axis_index)
  let radar_index = j_int(j, "radarIndex", base.radar_index)
  let smooth = j_bool(j, "smooth", base.smooth)
  let symbol_size_values = parse_symbol_size_values(j)
  let symbol_size = j_number(j, "symbolSize", base.symbol_size)
  let symbol = match j_field(j, "symbol") {
    Some(String(s)) => Some(s)
    _ => base.symbol
  }
  let (symbol_repeat, symbol_repeat_count, symbol_repeat_fixed) = parse_symbol_repeat(
    j, base,
  )
  let symbol_margin = match j_field(j, "symbolMargin") {
    Some(String(s)) => Some(s)
    Some(Number(n, ..)) => Some("\{n}")
    _ => base.symbol_margin
  }
  let symbol_clip = j_bool(j, "symbolClip", base.symbol_clip)
  let symbol_position = match j_field(j, "symbolPosition") {
    Some(String(s)) => Some(s)
    _ => base.symbol_position
  }
  let symbol_rotate = j_number_opt(j, "symbolRotate")
  let symbol_bounding_data = parse_symbol_bounding_data(j)
  let symbol_offset = parse_symbol_offset(j)
  let symbol_repeat_direction = match j_field(j, "symbolRepeatDirection") {
    Some(String(s)) => Some(s)
    _ => base.symbol_repeat_direction
  }
  let bar_gap = match j_field(j, "barGap") {
    Some(String(s)) => Some(s)
    Some(Number(n, ..)) => Some("\{n}")
    _ => base.bar_gap
  }
  let bar_category_gap = match j_field(j, "barCategoryGap") {
    Some(String(s)) => Some(s)
    Some(Number(n, ..)) => Some("\{n}")
    _ => base.bar_category_gap
  }
  let color = match j_string_opt(j, "color") {
    Some(c) => Some(c)
    None => base.color
  }
  let item_style = match j_field(j, "itemStyle") {
    Some(style) =>
      match j_field(style, "color") {
        Some(String(s)) => Some(s)
        _ => None
      }
    _ => None
  }
  let item_opacity = match j_field(j, "itemStyle") {
    Some(style) =>
      match j_field(style, "opacity") {
        Some(Number(n, ..)) => Some(n)
        _ => None
      }
    _ => None
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
  let min_angle = j_number(j, "minAngle", base.min_angle)
  let clockwise = j_bool(j, "clockwise", base.clockwise)
  let start_angle = j_number(j, "startAngle", base.start_angle)
  let end_angle = j_number(j, "endAngle", base.end_angle)
  let min_val = j_number(j, "min", base.min_val)
  let max_val = j_number(j, "max", base.max_val)
  let split_number = j_int(j, "splitNumber", base.split_number)
  {
    series_type,
    name,
    data,
    symbol,
    symbol_size_values,
    symbol_repeat,
    symbol_repeat_count,
    symbol_repeat_fixed,
    symbol_margin,
    symbol_clip,
    symbol_position,
    symbol_rotate,
    symbol_bounding_data,
    symbol_offset,
    symbol_repeat_direction,
    bar_gap,
    bar_category_gap,
    x_axis_index,
    y_axis_index,
    radar_index,
    stack,
    smooth,
    symbol_size,
    color,
    line_style_width: None,
    item_style,
    item_opacity,
    area_style,
    encode_x: None,
    encode_y: None,
    radius,
    center,
    min_angle,
    clockwise,
    start_angle,
    end_angle,
    min_val,
    max_val,
    split_number,
  }
}

///|
fn parse_data_item(j : Json) -> DataItem {
  match j {
    Number(n, ..) =>
      { value: DataValue::Num(n), name: None, symbol: None, children: [] }
    Null => { value: DataValue::Null, name: None, symbol: None, children: [] }
    True =>
      { value: DataValue::Num(1.0), name: None, symbol: None, children: [] }
    False =>
      { value: DataValue::Num(0.0), name: None, symbol: None, children: [] }
    Array(arr) => {
      let nums = arr.map(fn(v) {
        match v {
          Number(n, ..) => n
          _ => 0.0
        }
      })
      { value: DataValue::Vec(nums), name: None, symbol: None, children: [] }
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
      let symbol = match j_field(j, "symbol") {
        Some(String(s)) => Some(s)
        _ => None
      }
      let children = match j_field(j, "children") {
        Some(Array(arr)) => arr.map(parse_data_item)
        _ => []
      }
      { value: v, name, symbol, children }
    }
    _ => { value: DataValue::Null, name: None, symbol: None, children: [] }
  }
}

// ---- JSON access helpers ----

///|
/// Parse a single RadarOption from JSON.
/// Corresponds to echarts/src/coord/radar/RadarModel.ts option parsing.
fn parse_radar_option(j : Json) -> RadarOption {
  let base = RadarOption::default()
  let indicator = match j_field(j, "indicator") {
    Some(Array(arr)) => arr.map(parse_radar_indicator)
    _ => []
  }
  let center = match j_field(j, "center") {
    Some(Array(arr)) =>
      arr.map(fn(v) {
        match v {
          String(s) => s
          Number(n, ..) => "\{n}"
          _ => "50%"
        }
      })
    _ => base.center
  }
  let radius = match j_field(j, "radius") {
    Some(String(s)) => s
    Some(Number(n, ..)) => "\{n}"
    _ => base.radius
  }
  let start_angle = j_number(j, "startAngle", base.start_angle)
  let clockwise = j_bool(j, "clockwise", base.clockwise)
  let split_number = j_int(j, "splitNumber", base.split_number)
  { indicator, center, radius, start_angle, clockwise, split_number }
}

///|
fn parse_radar_indicator(j : Json) -> RadarIndicator {
  let name = match j_field(j, "name") {
    Some(String(s)) => s
    _ => ""
  }
  let max = j_number_opt(j, "max")
  let min = j_number_opt(j, "min")
  { name, max, min }
}

///|
/// Parse a visualMap option. Supports continuous visualMap.
/// Corresponds to echarts/src/component/visualMap/VisualMapModel.ts
fn parse_aria_option(j : Json) -> AriaOption {
  let base = AriaOption::default()
  let show_enabled = match j_field(j, "show") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  let enabled = match j_field(j, "enabled") {
    Some(True) => true
    Some(False) => false
    _ => show_enabled.unwrap_or(base.enabled)
  }
  let label = match j_field(j, "label") {
    Some(v) => v
    None => j
  }
  let label_enabled = match j_field(label, "enabled") {
    Some(True) => true
    Some(False) => false
    _ => base.label_enabled
  }
  let description = match j_field(label, "description") {
    Some(String(s)) => Some(s)
    _ => j_string_opt(j, "description")
  }
  let general = match j_field(label, "general") {
    Some(v) => v
    None => j
  }
  let series = match j_field(label, "series") {
    Some(v) => v
    None => j
  }
  let data = match j_field(label, "data") {
    Some(v) => v
    None => j
  }
  let series_single = match j_field(series, "single") {
    Some(v) => v
    None => series
  }
  let series_multiple = match j_field(series, "multiple") {
    Some(v) => v
    None => series
  }
  let series_separator = match j_field(series_multiple, "separator") {
    Some(v) => v
    None => series_multiple
  }
  let data_separator = match j_field(data, "separator") {
    Some(v) => v
    None => data
  }
  {
    enabled,
    label_enabled,
    description,
    general_with_title: j_string(general, "withTitle", base.general_with_title),
    general_without_title: j_string(
      general,
      "withoutTitle",
      base.general_without_title,
    ),
    series_max_count: j_int(series, "maxCount", base.series_max_count),
    series_single_prefix: j_string(
      series_single,
      "prefix",
      base.series_single_prefix,
    ),
    series_single_with_name: j_string(
      series_single,
      "withName",
      base.series_single_with_name,
    ),
    series_single_without_name: j_string(
      series_single,
      "withoutName",
      base.series_single_without_name,
    ),
    series_multiple_prefix: j_string(
      series_multiple,
      "prefix",
      base.series_multiple_prefix,
    ),
    series_multiple_with_name: j_string(
      series_multiple,
      "withName",
      base.series_multiple_with_name,
    ),
    series_multiple_without_name: j_string(
      series_multiple,
      "withoutName",
      base.series_multiple_without_name,
    ),
    series_multiple_separator_middle: j_string(
      series_separator,
      "middle",
      base.series_multiple_separator_middle,
    ),
    series_multiple_separator_end: j_string(
      series_separator,
      "end",
      base.series_multiple_separator_end,
    ),
    data_max_count: j_int(data, "maxCount", base.data_max_count),
    data_all_data: j_string(data, "allData", base.data_all_data),
    data_partial_data: j_string(data, "partialData", base.data_partial_data),
    data_with_name: j_string(data, "withName", base.data_with_name),
    data_without_name: j_string(data, "withoutName", base.data_without_name),
    data_separator_middle: j_string(
      data_separator,
      "middle",
      base.data_separator_middle,
    ),
    data_separator_end: j_string(data_separator, "end", base.data_separator_end),
  }
}

///|
fn parse_symbol_repeat(j : Json, base : SeriesOption) -> (String?, Int?, Bool) {
  match j_field(j, "symbolRepeat") {
    Some(True) => (Some("true"), None, false)
    Some(False) => (Some("false"), None, false)
    Some(Number(n, ..)) => (Some("number"), Some(n.to_int()), false)
    Some(String(s)) =>
      if s == "fixed" {
        (Some("fixed"), None, true)
      } else {
        (Some(s), None, false)
      }
    _ =>
      (base.symbol_repeat, base.symbol_repeat_count, base.symbol_repeat_fixed)
  }
}

///|
fn parse_symbol_bounding_data(j : Json) -> SymbolBoundingData? {
  match j_field(j, "symbolBoundingData") {
    Some(Number(n, ..)) => Some(Single(n))
    Some(Array(arr)) =>
      if arr.length() >= 2 {
        let a = match arr[0] {
          Number(n, ..) => n
          _ => 0.0
        }
        let b = match arr[1] {
          Number(n, ..) => n
          _ => 0.0
        }
        Some(Pair(a, b))
      } else {
        None
      }
    _ => None
  }
}

///|
fn parse_symbol_size_values(j : Json) -> Array[String]? {
  match j_field(j, "symbolSize") {
    Some(String(s)) => Some([s, s])
    Some(Number(n, ..)) => {
      let value = "\{n}"
      Some([value, value])
    }
    Some(Array(arr)) => {
      let values : Array[String] = []
      let mut i = 0
      while i < arr.length() && i < 2 {
        match arr[i] {
          String(s) => values.push(s)
          Number(n, ..) => values.push("\{n}")
          _ => values.push("0")
        }
        i = i + 1
      }
      if values.length() == 1 {
        Some([values[0], values[0]])
      } else if values.length() >= 2 {
        Some([values[0], values[1]])
      } else {
        None
      }
    }
    _ => None
  }
}

///|
fn parse_symbol_offset(j : Json) -> Array[String]? {
  match j_field(j, "symbolOffset") {
    Some(String(s)) => Some([s, s])
    Some(Number(n, ..)) => {
      let value = "\{n}"
      Some([value, value])
    }
    Some(Array(arr)) => {
      let values : Array[String] = []
      let mut i = 0
      while i < arr.length() && i < 2 {
        match arr[i] {
          String(s) => values.push(s)
          Number(n, ..) => values.push("\{n}")
          _ => values.push("0")
        }
        i = i + 1
      }
      if values.length() == 1 {
        Some([values[0], values[0]])
      } else if values.length() >= 2 {
        Some([values[0], values[1]])
      } else {
        None
      }
    }
    _ => None
  }
}

///|

///|
fn parse_visual_map(j : Json) -> VisualMapOption {
  let base = VisualMapOption::default()
  { min: j_number(j, "min", base.min), max: j_number(j, "max", base.max) }
}

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

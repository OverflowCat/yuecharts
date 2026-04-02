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
  let title = j_parse_optional(j, "title", parse_title)
  let legend = j_parse_optional(j, "legend", parse_legend)
  let aria = j_parse_optional(j, "aria", parse_aria_option)
  let x_axis = j_parse_one_or_many(j, "xAxis", parse_axis_option_x, [
    AxisOption::default_x(),
  ])
  let y_axis = j_parse_one_or_many(j, "yAxis", parse_axis_option_y, [
    AxisOption::default_y(),
  ])
  let angle_axis = j_parse_one_or_many(
    j,
    "angleAxis",
    parse_angle_axis_option,
    [],
  )
  let radius_axis = j_parse_one_or_many(
    j,
    "radiusAxis",
    parse_radius_axis_option,
    [],
  )
  let grid = j_parse_one_or_many(j, "grid", parse_grid_option, [
    GridOption::default(),
  ])
  let polar = j_parse_one_or_many(j, "polar", parse_polar_option, [])
  let parallel = j_parse_one_or_many(j, "parallel", parse_parallel_option, [])
  let parallel_axis = j_parse_one_or_many(
    j,
    "parallelAxis",
    parse_parallel_axis_option,
    [],
  )
  let geo = j_parse_one_or_many(j, "geo", parse_geo_option, [])
  let calendar = j_parse_one_or_many(j, "calendar", parse_calendar_option, [])
  let matrix = j_parse_one_or_many(j, "matrix", parse_matrix_option, [])
  let radar = j_parse_one_or_many(j, "radar", parse_radar_option, [])
  let single_axis = j_parse_one_or_many(
    j,
    "singleAxis",
    parse_single_axis_option,
    [],
  )
  let series = j_parse_one_or_many(j, "series", parse_series_option, [])
  let map_registry = j_parse_one_or_many(j, "maps", parse_map_registry_option, [])
  let visual_map = j_parse_one_or_many(j, "visualMap", parse_visual_map, [])
  {
    width,
    height,
    title,
    legend,
    x_axis,
    y_axis,
    angle_axis,
    radius_axis,
    grid,
    polar,
    parallel,
    parallel_axis,
    geo,
    calendar,
    matrix,
    radar,
    single_axis,
    series,
    map_registry,
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
    selected: parse_legend_selected(j),
  }
}

///|
fn parse_legend_selected(j : Json) -> Array[LegendSelection] {
  match j_field(j, "selected") {
    Some(Object(map)) => {
      let items : Array[LegendSelection] = []
      for name, value in map {
        let selected = match value {
          True => true
          False => false
          _ => true
        }
        items.push({ name, selected })
      }
      items
    }
    _ => []
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
fn parse_angle_axis_option(j : Json) -> AxisOption {
  let base = {
    ..AxisOption::default_x(),
    start_angle: Some(90.0),
    clockwise: Some(true),
  }
  parse_axis_option(j, base)
}

///|
fn parse_radius_axis_option(j : Json) -> AxisOption {
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
  let data = j_string_array_lossy(j, "data", base.data)
  let name = j_string_opt(j, "name")
  let min = j_number_opt(j, "min")
  let max = j_number_opt(j, "max")
  let grid_index = Some(j_int(j, "gridIndex", base.grid_index.unwrap_or(0)))
  let polar_index = Some(j_int(j, "polarIndex", base.polar_index.unwrap_or(0)))
  let start_angle = match j_field(j, "startAngle") {
    Some(Number(n, ..)) => Some(n)
    _ => base.start_angle
  }
  let end_angle = match j_field(j, "endAngle") {
    Some(Number(n, ..)) => Some(n)
    _ => base.end_angle
  }
  let clockwise = match j_field(j, "clockwise") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => base.clockwise
  }
  let inverse = j_bool(j, "inverse", base.inverse)
  {
    axis_type,
    position,
    name,
    data,
    min,
    max,
    grid_index,
    polar_index,
    start_angle,
    end_angle,
    clockwise,
    inverse,
  }
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
fn parse_polar_option(j : Json) -> PolarOption {
  let base = PolarOption::default()
  let center = j_stringish_array(j, "center", base.center)
  let radius = match j_field(j, "radius") {
    Some(Array(arr)) => arr.map(json_to_stringish_zero)
    Some(String(s)) => ["0", s]
    Some(Number(n, ..)) => ["0", "\{n}"]
    _ => base.radius
  }
  { center, radius }
}

///|
fn parse_geo_option(j : Json) -> GeoOption {
  let base = GeoOption::default()
  {
    map: j_string(j, "map", base.map),
    roam: j_bool(j, "roam", base.roam),
    aspect_scale: j_number_opt(j, "aspectScale"),
    silent: j_bool(j, "silent", base.silent),
    label: parse_geo_label_option(j_field_or_self(j, "label")),
    item_style: parse_geo_item_style_option(j_field_or_self(j, "itemStyle")),
    states: parse_geo_states_option(j),
    name_map: parse_geo_name_map(j),
    regions: j_parse_array(j, "regions", parse_geo_region_option, []),
  }
}

///|
fn parse_parallel_option(j : Json) -> ParallelOption {
  let base = ParallelOption::default()
  {
    left: parse_size_spec(j, "left", base.left),
    right: parse_size_spec(j, "right", base.right),
    top: parse_size_spec(j, "top", base.top),
    bottom: parse_size_spec(j, "bottom", base.bottom),
    layout: j_string(j, "layout", base.layout),
    axis_expandable: j_bool(j, "axisExpandable", base.axis_expandable),
    axis_expand_center: match j_field(j, "axisExpandCenter") {
      Some(Number(n, ..)) => Some(n.to_int())
      _ => base.axis_expand_center
    },
    axis_expand_count: j_int(j, "axisExpandCount", base.axis_expand_count),
    axis_expand_width: j_number(j, "axisExpandWidth", base.axis_expand_width),
  }
}

///|
fn parse_parallel_axis_option(j : Json) -> ParallelAxisOption {
  let base = ParallelAxisOption::default()
  {
    axis_type: match j_string(j, "type", "") {
      "category" => AxisType::Category
      "time" => AxisType::Time
      "log" => AxisType::Log
      "value" => AxisType::Value
      _ => base.axis_type
    },
    dim: j_int(j, "dim", base.dim),
    parallel_index: j_int(j, "parallelIndex", base.parallel_index),
    name: j_string_opt(j, "name"),
    data: j_string_array_lossy(j, "data", base.data),
    min: j_number_opt(j, "min"),
    max: j_number_opt(j, "max"),
    inverse: j_bool(j, "inverse", base.inverse),
    show: j_bool(j, "show", base.show),
  }
}

///|
fn parse_single_axis_option(j : Json) -> SingleAxisOption {
  let base = SingleAxisOption::default()
  {
    axis_type: match j_string(j, "type", "") {
      "category" => AxisType::Category
      "time" => AxisType::Time
      "log" => AxisType::Log
      "value" => AxisType::Value
      _ => base.axis_type
    },
    orient: j_string(j, "orient", base.orient),
    position: j_string(j, "position", base.position),
    left: parse_size_spec_opt(j, "left", base.left),
    top: parse_size_spec_opt(j, "top", base.top),
    right: parse_size_spec_opt(j, "right", base.right),
    bottom: parse_size_spec_opt(j, "bottom", base.bottom),
    width: parse_size_spec_opt(j, "width", base.width),
    height: parse_size_spec_opt(j, "height", base.height),
    min: j_number_opt(j, "min"),
    max: j_number_opt(j, "max"),
    data: j_string_array_lossy(j, "data", base.data),
    inverse: j_bool(j, "inverse", base.inverse),
  }
}

///|
fn parse_geo_item_style_option(j : Json) -> GeoItemStyleOption {
  let base = GeoItemStyleOption::default()
  {
    area_color: j_string_opt(j, "areaColor"),
    border_color: j_string(j, "borderColor", base.border_color),
    border_width: j_number(j, "borderWidth", base.border_width),
  }
}

///|
fn parse_geo_item_style_patch_option(j : Json) -> GeoItemStylePatchOption {
  {
    color: j_string_opt(j, "color"),
    area_color: j_string_opt(j, "areaColor"),
    border_color: j_string_opt(j, "borderColor"),
    border_width: j_number_opt(j, "borderWidth"),
  }
}

///|
fn parse_geo_state_option(j : Json) -> GeoStateOption {
  {
    item_style: match j_field(j, "itemStyle") {
      Some(value) => Some(parse_geo_item_style_patch_option(value))
      None => None
    },
    label: match j_field(j, "label") {
      Some(value) => Some(parse_geo_label_patch_option(value))
      None => None
    },
  }
}

///|
fn parse_geo_states_option(j : Json) -> GeoStatesOption {
  {
    emphasis: match j_field(j, "emphasis") {
      Some(value) => Some(parse_geo_state_option(value))
      None => None
    },
    select: match j_field(j, "select") {
      Some(value) => Some(parse_geo_state_option(value))
      None => None
    },
    blur: match j_field(j, "blur") {
      Some(value) => Some(parse_geo_state_option(value))
      None => None
    },
  }
}

///|
fn parse_geo_region_option(j : Json) -> GeoRegionOption {
  {
    name: j_string(j, "name", ""),
    label: match j_field(j, "label") {
      Some(value) => Some(parse_geo_label_patch_option(value))
      None => None
    },
    item_style: match j_field(j, "itemStyle") {
      Some(value) => Some(parse_geo_item_style_patch_option(value))
      None => None
    },
    selected: match j_field(j, "selected") {
      Some(True) => Some(true)
      Some(False) => Some(false)
      _ => None
    },
    silent: match j_field(j, "silent") {
      Some(True) => Some(true)
      Some(False) => Some(false)
      _ => None
    },
    states: parse_geo_states_option(j),
  }
}

///|
fn parse_geo_name_map(j : Json) -> Array[GeoNameMapEntry] {
  match j_field(j, "nameMap") {
    Some(Object(map)) => {
      let entries : Array[GeoNameMapEntry] = []
      for from_name, to_json in map {
        match to_json {
          String(to_name) => entries.push({ from_name, to_name })
          _ => ()
        }
      }
      entries
    }
    _ => []
  }
}

///|
fn parse_geo_label_option(j : Json) -> GeoLabelOption {
  let base = GeoLabelOption::default()
  {
    show: j_bool(j, "show", base.show),
    color: j_string(j, "color", base.color),
    position: j_string_opt(j, "position"),
    distance: j_number_opt(j, "distance"),
    font_weight: j_string_opt(j, "fontWeight"),
  }
}

///|
fn parse_geo_label_patch_option(j : Json) -> GeoLabelPatchOption {
  {
    show: match j_field(j, "show") {
      Some(True) => Some(true)
      Some(False) => Some(false)
      _ => None
    },
    color: j_string_opt(j, "color"),
    position: j_string_opt(j, "position"),
    distance: j_number_opt(j, "distance"),
    font_weight: j_string_opt(j, "fontWeight"),
  }
}

///|
fn parse_map_registry_option(j : Json) -> MapRegistryOption {
  {
    name: j_string(j, "name", ""),
    geo_json: j_field(j, "geoJSON"),
    special_areas: parse_map_special_areas(j),
  }
}

///|
fn parse_map_special_areas(j : Json) -> Array[MapSpecialAreaOption] {
  match j_field(j, "specialAreas") {
    Some(Object(map)) => {
      let result : Array[MapSpecialAreaOption] = []
      for name, value in map {
        result.push({
          name,
          left: j_number(value, "left", 0.0),
          top: j_number(value, "top", 0.0),
          width: j_number(value, "width", 0.0),
          height: j_number(value, "height", 0.0),
        })
      }
      result
    }
    _ => []
  }
}

///|
fn parse_calendar_option(j : Json) -> CalendarOption {
  let base = CalendarOption::default()
  {
    left: parse_size_spec_opt(j, "left", base.left),
    top: parse_size_spec_opt(j, "top", base.top),
    right: parse_size_spec_opt(j, "right", base.right),
    bottom: parse_size_spec_opt(j, "bottom", base.bottom),
    width: parse_size_spec_opt(j, "width", base.width),
    height: parse_size_spec_opt(j, "height", base.height),
    cell_size: parse_calendar_cell_size(j, base.cell_size),
    orient: j_string(j, "orient", base.orient),
    range: parse_calendar_range(j, base.range),
    split_line: parse_calendar_split_line(j),
    item_style: parse_calendar_item_style(j),
    day_label: parse_calendar_day_label(j),
    month_label: parse_calendar_month_label(j),
    year_label: parse_calendar_year_label(j),
  }
}

///|
fn parse_matrix_option(j : Json) -> MatrixOption {
  let base = MatrixOption::default()
  {
    left: parse_size_spec_opt(j, "left", base.left),
    top: parse_size_spec_opt(j, "top", base.top),
    right: parse_size_spec_opt(j, "right", base.right),
    bottom: parse_size_spec_opt(j, "bottom", base.bottom),
    width: parse_size_spec_opt(j, "width", base.width),
    height: parse_size_spec_opt(j, "height", base.height),
    x: parse_matrix_dimension_option(j_field_or_self(j, "x")),
    y: parse_matrix_dimension_option(j_field_or_self(j, "y")),
    body: parse_matrix_body_option(j_field_or_self(j, "body")),
    corner: parse_matrix_body_option(j_field_or_self(j, "corner")),
    background_style: parse_matrix_item_style_option(
      j_field_or_self(j, "backgroundStyle"),
      base.background_style,
    ),
    border_z2: j_number_opt(j, "borderZ2"),
  }
}

///|
fn parse_matrix_dimension_option(j : Json) -> MatrixDimensionOption {
  let base = MatrixDimensionOption::default()
  {
    show: j_bool(j, "show", base.show),
    data: parse_matrix_dimension_cells(j_field(j, "data")),
    length: match j_field(j, "length") {
      Some(Number(n, ..)) => Some(n.to_int())
      _ => base.length
    },
    level_size: parse_size_spec_opt(j, "levelSize", base.level_size),
    levels: parse_matrix_dimension_levels(j),
    item_style: parse_matrix_item_style_option(
      j_field_or_self(j, "itemStyle"),
      base.item_style,
    ),
    label: parse_matrix_label_option(j_field_or_self(j, "label"), base.label),
    divider_line_style: parse_matrix_line_style_option(
      j_field_or_self(j, "dividerLineStyle"),
      base.divider_line_style,
    ),
  }
}

///|
fn parse_matrix_dimension_levels(j : Json) -> Array[MatrixDimensionLevelOption] {
  match j_field(j, "levels") {
    Some(Array(arr)) => {
      let out : Array[MatrixDimensionLevelOption] = []
      let mut i = 0
      while i < arr.length() {
        out.push({ level_size: parse_size_spec_opt(arr[i], "levelSize", None) })
        i += 1
      }
      out
    }
    _ => []
  }
}

///|
fn parse_matrix_dimension_cells(j : Json?) -> Array[MatrixDimensionCellOption] {
  match j {
    Some(Array(arr)) => arr.map(parse_matrix_dimension_cell)
    _ => []
  }
}

///|
fn parse_matrix_dimension_cell(j : Json) -> MatrixDimensionCellOption {
  match j {
    String(s) =>
      {
        value: Some(s),
        size: None,
        children: [],
        item_style: None,
        label: None,
      }
    Number(n, ..) =>
      {
        value: Some("\{n}"),
        size: None,
        children: [],
        item_style: None,
        label: None,
      }
    _ =>
      {
        value: j_string_opt(j, "value"),
        size: parse_size_spec_opt(j, "size", None),
        children: parse_matrix_dimension_cells(j_field(j, "children")),
        item_style: parse_matrix_item_style_optional(j_field(j, "itemStyle")),
        label: parse_matrix_label_optional(j_field(j, "label")),
      }
  }
}

///|
fn parse_matrix_body_option(j : Json) -> MatrixBodyOption {
  let base = MatrixBodyOption::default()
  {
    data: parse_matrix_body_cells(j_field(j, "data")),
    item_style: parse_matrix_item_style_option(
      j_field_or_self(j, "itemStyle"),
      base.item_style,
    ),
    label: parse_matrix_label_option(j_field_or_self(j, "label"), base.label),
  }
}

///|
fn parse_matrix_body_cells(j : Json?) -> Array[MatrixBodyCellOption] {
  match j {
    Some(Array(arr)) => arr.map(parse_matrix_body_cell)
    _ => []
  }
}

///|
fn parse_matrix_body_cell(j : Json) -> MatrixBodyCellOption {
  {
    coord: parse_matrix_coord_pair(j_field(j, "coord")),
    value: j_string_opt(j, "value"),
    item_style: parse_matrix_item_style_optional(j_field(j, "itemStyle")),
    label: parse_matrix_label_optional(j_field(j, "label")),
    coord_clamp: j_bool(j, "coordClamp", false),
    merge_cells: j_bool(j, "mergeCells", false),
  }
}

///|
fn parse_matrix_coord_pair(j : Json?) -> Array[MatrixCoordPart] {
  match j {
    Some(Array(arr)) => {
      let out : Array[MatrixCoordPart] = []
      let mut i = 0
      while i < arr.length() && i < 2 {
        out.push(parse_matrix_coord_part(arr[i]))
        i += 1
      }
      out
    }
    _ => []
  }
}

///|
fn parse_matrix_coord_part(j : Json) -> MatrixCoordPart {
  match j {
    Null => Missing
    Array(arr) =>
      if arr.length() == 0 {
        Missing
      } else if arr.length() == 1 {
        Value(parse_matrix_coord_value(arr[0]))
      } else {
        Range(
          parse_matrix_coord_value(arr[0]),
          parse_matrix_coord_value(arr[arr.length() - 1]),
        )
      }
    _ => Value(parse_matrix_coord_value(j))
  }
}

///|
fn parse_matrix_coord_value(j : Json) -> MatrixCoordValue {
  match j {
    Number(n, ..) => Locator(n.to_int())
    Null => Missing
    String(s) => {
      let parsed = try? @strconv.parse_int(s, base=10)
      match parsed {
        Ok(v) => Locator(v)
        Err(_) => Name(s)
      }
    }
    _ => Missing
  }
}

///|
fn parse_matrix_item_style_optional(j : Json?) -> MatrixItemStyleOption? {
  match j {
    Some(value) =>
      Some(
        parse_matrix_item_style_option(value, MatrixItemStyleOption::default()),
      )
    None => None
  }
}

///|
fn parse_matrix_item_style_option(
  j : Json,
  base : MatrixItemStyleOption,
) -> MatrixItemStyleOption {
  {
    color: j_string(j, "color", base.color),
    border_color: j_string(j, "borderColor", base.border_color),
    border_width: j_number(j, "borderWidth", base.border_width),
  }
}

///|
fn parse_matrix_label_optional(j : Json?) -> MatrixLabelOption? {
  match j {
    Some(value) =>
      Some(parse_matrix_label_option(value, MatrixLabelOption::default()))
    None => None
  }
}

///|
fn parse_matrix_label_option(
  j : Json,
  base : MatrixLabelOption,
) -> MatrixLabelOption {
  {
    show: j_bool(j, "show", base.show),
    color: j_string(j, "color", base.color),
    font_size: j_number(j, "fontSize", base.font_size),
    font_family: j_string(j, "fontFamily", base.font_family),
    font_weight: j_string(j, "fontWeight", base.font_weight),
  }
}

///|
fn parse_matrix_line_style_option(
  j : Json,
  base : MatrixLineStyleOption,
) -> MatrixLineStyleOption {
  {
    color: j_string(j, "color", base.color),
    width: j_number(j, "width", base.width),
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
fn parse_size_spec_opt(
  j : Json,
  key : String,
  default_val : SizeSpec?,
) -> SizeSpec? {
  match j_field(j, key) {
    Some(Number(n, ..)) => Some(SizeSpec::Px(n))
    Some(String(s)) =>
      if s.has_suffix("%") {
        let pct_str = s[:s.length() - 1]
        let r = try? @strconv.parse_double(pct_str.to_string())
        r.map(pct => Some(SizeSpec::Pct(pct))).unwrap_or(default_val)
      } else {
        let r = try? @strconv.parse_double(s)
        r.map(px => Some(SizeSpec::Px(px))).unwrap_or(default_val)
      }
    _ => default_val
  }
}

///|
fn parse_series_option(j : Json) -> SeriesOption {
  let series_type = match j_string(j, "type", "line") {
    "line" => SeriesType::Line
    "parallel" => SeriesType::Parallel
    "lines" => SeriesType::Lines
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
    "map" => SeriesType::Map
    "themeRiver" => SeriesType::ThemeRiver
    "tree" => SeriesType::Tree
    "chord" => SeriesType::Chord
    _ => SeriesType::Line
  }
  let base = match series_type {
    Line => SeriesOption::default_line()
    Parallel => SeriesOption::default_parallel()
    Lines => SeriesOption::default_lines()
    Bar => SeriesOption::default_bar()
    PictorialBar => SeriesOption::default_pictorial_bar()
    Scatter => SeriesOption::default_scatter()
    EffectScatter => SeriesOption::default_effect_scatter()
    Pie => SeriesOption::default_pie()
    Sunburst => SeriesOption::default_sunburst()
    Treemap => SeriesOption::default_treemap()
    Gauge => SeriesOption::default_gauge()
    Map => SeriesOption::default_map()
    ThemeRiver => SeriesOption::default_theme_river()
    Tree => SeriesOption::default_tree()
    Chord => SeriesOption::default_chord()
    _ => SeriesOption::default_line()
  }
  // Note: Candlestick, Heatmap, Boxplot, Radar use default_line as base defaults.
  let data = match j_field(j, "data") {
    Some(Array(arr)) =>
      if series_type == SeriesType::ThemeRiver {
        arr.map(parse_data_item_theme_river)
      } else {
        arr.map(parse_data_item)
      }
    None =>
      match j_field(j, "nodes") {
        Some(Array(arr)) => arr.map(parse_data_item)
        _ => base.data
      }
    _ => base.data
  }
  let link_data = match j_field(j, "links") {
    Some(Array(arr)) => arr.map(parse_data_item)
    None =>
      match j_field(j, "edges") {
        Some(Array(arr)) => arr.map(parse_data_item)
        _ => base.link_data
      }
    _ => base.link_data
  }
  let name = j_string_opt(j, "name")
  let x_axis_index = j_int(j, "xAxisIndex", base.x_axis_index)
  let y_axis_index = j_int(j, "yAxisIndex", base.y_axis_index)
  let parallel_index = j_int(j, "parallelIndex", base.parallel_index)
  let radius_axis_index = j_int(j, "radiusAxisIndex", base.radius_axis_index)
  let angle_axis_index = j_int(j, "angleAxisIndex", base.angle_axis_index)
  let polar_index = j_int(j, "polarIndex", base.polar_index)
  let coordinate_system = j_string_opt(j, "coordinateSystem")
  let calendar_index = j_int(j, "calendarIndex", base.calendar_index)
  let matrix_index = j_int(j, "matrixIndex", base.matrix_index)
  let geo_index = j_int(j, "geoIndex", base.geo_index)
  let radar_index = j_int(j, "radarIndex", base.radar_index)
  let map_name = j_string_opt(j, "map")
  let boundary_gap = j_stringish_array(j, "boundaryGap", base.boundary_gap)
  let symbol_values = parse_symbol_values(j)
  let symbol_size_values = parse_symbol_size_values(j)
  let symbol_size = j_number(j, "symbolSize", base.symbol_size)
  let symbol = j_string_or_number_as_string_opt(j, "symbol", base.symbol)
  let (symbol_repeat, symbol_repeat_count, symbol_repeat_fixed) = parse_symbol_repeat(
    j, base,
  )
  let symbol_margin = j_string_or_number_as_string_opt(
    j,
    "symbolMargin",
    base.symbol_margin,
  )
  let symbol_clip = j_bool(j, "symbolClip", base.symbol_clip)
  let symbol_position = j_string_or_number_as_string_opt(
    j,
    "symbolPosition",
    base.symbol_position,
  )
  let symbol_rotate = j_number_opt(j, "symbolRotate")
  let symbol_bounding_data = parse_symbol_bounding_data(j)
  let symbol_offset = parse_symbol_offset(j)
  let symbol_repeat_direction = j_string_or_number_as_string_opt(
    j,
    "symbolRepeatDirection",
    base.symbol_repeat_direction,
  )
  let bar_gap = j_string_or_number_as_string_opt(j, "barGap", base.bar_gap)
  let bar_category_gap = j_string_or_number_as_string_opt(
    j,
    "barCategoryGap",
    base.bar_category_gap,
  )
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
  let geo_item_style = match j_field(j, "itemStyle") {
    Some(style) => Some(parse_geo_item_style_patch_option(style))
    None => None
  }
  let item_opacity = match j_field(j, "itemStyle") {
    Some(style) =>
      match j_field(style, "opacity") {
        Some(Number(n, ..)) => Some(n)
        _ => None
      }
    _ => None
  }
  let label = match j_field(j, "label") {
    Some(value) => Some(parse_geo_label_option(value))
    None => base.label
  }
  let area_style = match j_field(j, "areaStyle") {
    None => base.area_style
    Some(Null) => base.area_style
    Some(_) => true
  }
  let stack = j_string_opt(j, "stack")
  let smooth = j_bool(j, "smooth", base.smooth)
  let polyline = j_bool(j, "polyline", base.polyline)
  let clip = j_bool(j, "clip", base.clip)
  let line_style = j_field_or_self(j, "lineStyle")
  let line_style_color = match j_string_opt(line_style, "color") {
    Some(color) => Some(color)
    None => base.line_style_color
  }
  let line_style_width = match j_number_opt(line_style, "width") {
    Some(width) => Some(width)
    None => base.line_style_width
  }
  let line_style_opacity = match j_number_opt(line_style, "opacity") {
    Some(opacity) => Some(opacity)
    None => base.line_style_opacity
  }
  let line_style_curveness = j_number_opt(line_style, "curveness")
  let radius = j_stringish_array(j, "radius", base.radius)
  let center = j_stringish_array(j, "center", base.center)
  let min_angle = j_number(j, "minAngle", base.min_angle)
  let pad_angle = j_number(j, "padAngle", base.pad_angle)
  let clockwise = j_bool(j, "clockwise", base.clockwise)
  let start_angle = j_number(j, "startAngle", base.start_angle)
  let end_angle = j_number(j, "endAngle", base.end_angle)
  let min_val = j_number(j, "min", base.min_val)
  let max_val = j_number(j, "max", base.max_val)
  let split_number = j_int(j, "splitNumber", base.split_number)
  let map_value_calculation = match j_string(j, "mapValueCalculation", "sum") {
    "average" => MapValueCalculationType::Average
    "min" => MapValueCalculationType::Min
    "max" => MapValueCalculationType::Max
    _ => MapValueCalculationType::Sum
  }
  let active_opacity = j_number_opt(j, "activeOpacity")
  let inactive_opacity = j_number_opt(j, "inactiveOpacity")
  let silent = j_bool(j, "silent", base.silent)
  let states = parse_geo_states_option(j)
  // tree chart options
  let tree_layout = j_string(j, "layout", base.tree_layout)
  let tree_orient = j_string(j, "orient", base.tree_orient)
  let tree_edge_shape = j_string(j, "edgeShape", base.tree_edge_shape)
  let tree_edge_fork_position = j_string(
    j,
    "edgeForkPosition",
    base.tree_edge_fork_position,
  )
  let tree_expand_and_collapse = j_bool(
    j,
    "expandAndCollapse",
    base.tree_expand_and_collapse,
  )
  let tree_initial_depth = j_int(j, "initialTreeDepth", base.tree_initial_depth)
  let tree_left = j_string(j, "left", base.tree_left)
  let tree_top = j_string(j, "top", base.tree_top)
  let tree_right = j_string(j, "right", base.tree_right)
  let tree_bottom = j_string(j, "bottom", base.tree_bottom)
  let tree_node_scale_ratio = j_number(
    j,
    "nodeScaleRatio",
    base.tree_node_scale_ratio,
  )
  {
    series_type,
    name,
    data,
    link_data,
    symbol,
    symbol_values,
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
    parallel_index,
    radius_axis_index,
    angle_axis_index,
    polar_index,
    coordinate_system,
    calendar_index,
    matrix_index,
    geo_index,
    radar_index,
    map_name,
    stack,
    boundary_gap,
    smooth,
    polyline,
    clip,
    symbol_size,
    color,
    line_style_color,
    line_style_width,
    line_style_opacity,
    line_style_curveness,
    item_style,
    item_opacity,
    label,
    geo_item_style,
    silent,
    states,
    area_style,
    encode_x: None,
    encode_y: None,
    radius,
    center,
    min_angle,
    pad_angle,
    clockwise,
    start_angle,
    end_angle,
    min_val,
    max_val,
    split_number,
    map_value_calculation,
    active_opacity,
    inactive_opacity,
    tree_layout,
    tree_orient,
    tree_edge_shape,
    tree_edge_fork_position,
    tree_expand_and_collapse,
    tree_initial_depth,
    tree_left,
    tree_top,
    tree_right,
    tree_bottom,
    tree_node_scale_ratio,
  }
}

///|
fn parse_data_item(j : Json) -> DataItem {
  match j {
    Number(n, ..) =>
      {
        value: DataValue::Num(n),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
      }
    Null =>
      {
        value: DataValue::Null,
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
      }
    True =>
      {
        value: DataValue::Num(1.0),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
      }
    False =>
      {
        value: DataValue::Num(0.0),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
      }
    Array(arr) => parse_data_array_item(arr)
    { "value": Number(n, ..), .. } => parse_data_object(j, DataValue::Num(n))
    { "value": Array(arr), .. } =>
      parse_data_object(j, parse_data_array_value(arr))
    Object(_) => parse_data_object(j, DataValue::Null)
    _ =>
      {
        value: DataValue::Null,
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
      }
  }
}

///|
fn parse_data_array_item(arr : Array[Json]) -> DataItem {
  {
    value: parse_data_array_value(arr),
    raw_value_parts: Some(arr),
    raw_item: None,
    id: None,
    name: None,
    source: None,
    target: None,
    symbol: None,
    coords: None,
    from_name: None,
    to_name: None,
    cursor: None,
    selected: None,
    silent: None,
    label: None,
    item_style: None,
    states: GeoStatesOption::default(),
    children: [],
    collapsed: None,
  }
}

///|
fn parse_data_array_value(arr : Array[Json]) -> DataValue {
  match arr {
    [String(date), Number(n, ..)] => DataValue::DateValue(date, n)
    _ => DataValue::Vec(arr.map(json_number_or_zero))
  }
}

///|
// Corresponds to: ThemeRiverSeries.ts data format [date, value, name]
fn parse_data_item_theme_river(j : Json) -> DataItem {
  match j {
    Array([String(date), Number(val, ..), String(name)]) =>
      {
        value: DataValue::DateValue(date, val),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: Some(name),
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
      }
    Array([Number(x, ..), Number(val, ..), String(name)]) => {
      let key = if x.to_int().to_double() == x {
        x.to_int().to_string()
      } else {
        x.to_string()
      }
      {
        value: DataValue::DateValue(key, val),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: Some(name),
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
      }
    }
    Array([String(date), Number(val, ..)]) =>
      {
        value: DataValue::DateValue(date, val),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
      }
    Array([Number(x, ..), Number(val, ..)]) => {
      let key = if x.to_int().to_double() == x {
        x.to_int().to_string()
      } else {
        x.to_string()
      }
      {
        value: DataValue::DateValue(key, val),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
      }
    }
    _ => parse_data_item(j)
  }
}

///|
fn parse_data_coords(j : Json) -> Array[Array[Double]]? {
  match j_field(j, "coords") {
    Some(Array(coords_arr)) => {
      let coords : Array[Array[Double]] = []
      let mut i = 0
      while i < coords_arr.length() {
        match coords_arr[i] {
          Array(pair) => {
            let coord : Array[Double] = []
            let mut j = 0
            while j < pair.length() {
              match pair[j] {
                Number(n, ..) => coord.push(n)
                _ => ()
              }
              j += 1
            }
            if coord.length() >= 2 {
              coords.push(coord)
            }
          }
          _ => ()
        }
        i += 1
      }
      Some(coords)
    }
    _ => None
  }
}

///|
// ---- JSON access helpers ----

///|
/// Parse a single RadarOption from JSON.
/// Corresponds to echarts/src/coord/radar/RadarModel.ts option parsing.
fn parse_radar_option(j : Json) -> RadarOption {
  let base = RadarOption::default()
  let indicator = j_parse_array(j, "indicator", parse_radar_indicator, [])
  let center = j_stringish_array(j, "center", base.center)
  let radius = j_string_or_number(j, "radius", base.radius)
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
fn parse_calendar_cell_size(
  j : Json,
  default_val : Array[CalendarCellSize],
) -> Array[CalendarCellSize] {
  match j_field(j, "cellSize") {
    Some(value) =>
      match value {
        Number(n, ..) => [CalendarCellSize::Px(n), CalendarCellSize::Px(n)]
        String("auto") => [CalendarCellSize::Auto, CalendarCellSize::Auto]
        Array(arr) => {
          let parsed : Array[CalendarCellSize] = []
          let mut i = 0
          while i < arr.length() && i < 2 {
            parsed.push(parse_calendar_cell_size_item(arr[i]))
            i += 1
          }
          if parsed.length() == 1 {
            parsed.push(parsed[0])
          }
          if parsed.length() == 2 {
            parsed
          } else {
            default_val
          }
        }
        _ => default_val
      }
    None => default_val
  }
}

///|
fn parse_calendar_cell_size_item(j : Json) -> CalendarCellSize {
  match j {
    Number(n, ..) => CalendarCellSize::Px(n)
    String("auto") => CalendarCellSize::Auto
    _ => CalendarCellSize::Auto
  }
}

///|
fn parse_calendar_range(j : Json, default_val : Array[String]) -> Array[String] {
  match j_field(j, "range") {
    Some(String(s)) => [s]
    Some(Number(n, ..)) => ["\{n.to_int()}"]
    Some(Array(arr)) => arr.map(json_to_stringish_empty)
    _ => default_val
  }
}

///|
fn parse_calendar_split_line(j : Json) -> CalendarSplitLineOption {
  let base = CalendarSplitLineOption::default()
  let split_line = j_field_or_self(j, "splitLine")
  let line_style = j_field_or_self(split_line, "lineStyle")
  {
    show: j_bool(split_line, "show", base.show),
    color: j_string(line_style, "color", base.color),
    width: j_number(line_style, "width", base.width),
  }
}

///|
fn parse_calendar_item_style(j : Json) -> CalendarItemStyleOption {
  let base = CalendarItemStyleOption::default()
  let item_style = j_field_or_self(j, "itemStyle")
  {
    color: j_string(item_style, "color", base.color),
    border_width: j_number(item_style, "borderWidth", base.border_width),
    border_color: j_string(item_style, "borderColor", base.border_color),
  }
}

///|
fn parse_calendar_day_label(j : Json) -> CalendarDayLabelOption {
  let base = CalendarDayLabelOption::default()
  let label = j_field_or_self(j, "dayLabel")
  {
    show: j_bool(label, "show", base.show),
    first_day: j_int(label, "firstDay", base.first_day),
    position: j_string(label, "position", base.position),
    margin: j_string_or_number(label, "margin", base.margin),
    name_map: parse_name_map(label),
    color: j_string(label, "color", base.color),
    font_size: j_number(label, "fontSize", base.font_size),
    font_family: j_string(label, "fontFamily", base.font_family),
    font_weight: j_string(label, "fontWeight", base.font_weight),
    silent: j_bool(label, "silent", base.silent),
  }
}

///|
fn parse_calendar_month_label(j : Json) -> CalendarMonthLabelOption {
  let base = CalendarMonthLabelOption::default()
  let label = j_field_or_self(j, "monthLabel")
  {
    show: j_bool(label, "show", base.show),
    position: j_string(label, "position", base.position),
    margin: j_number(label, "margin", base.margin),
    align: j_string(label, "align", base.align),
    formatter: j_string_opt(label, "formatter"),
    name_map: parse_name_map(label),
    color: j_string(label, "color", base.color),
    font_size: j_number(label, "fontSize", base.font_size),
    font_family: j_string(label, "fontFamily", base.font_family),
    font_weight: j_string(label, "fontWeight", base.font_weight),
    silent: j_bool(label, "silent", base.silent),
  }
}

///|
fn parse_calendar_year_label(j : Json) -> CalendarYearLabelOption {
  let base = CalendarYearLabelOption::default()
  let label = j_field_or_self(j, "yearLabel")
  {
    show: j_bool(label, "show", base.show),
    position: j_string_opt(label, "position"),
    margin: j_number(label, "margin", base.margin),
    formatter: j_string_opt(label, "formatter"),
    color: j_string(label, "color", base.color),
    font_size: j_number(label, "fontSize", base.font_size),
    font_family: j_string(label, "fontFamily", base.font_family),
    font_weight: j_string(label, "fontWeight", base.font_weight),
    silent: j_bool(label, "silent", base.silent),
  }
}

///|
fn parse_name_map(j : Json) -> Array[String]? {
  match j_field(j, "nameMap") {
    Some(Array(arr)) => Some(arr.map(json_to_stringish_empty))
    _ => None
  }
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
  let label = j_field_or_self(j, "label")
  let label_enabled = match j_field(label, "enabled") {
    Some(True) => true
    Some(False) => false
    _ => base.label_enabled
  }
  let description = match j_field(label, "description") {
    Some(String(s)) => Some(s)
    _ => j_string_opt(j, "description")
  }
  let general = j_field_or_self(label, "general")
  let series = j_field_or_self(label, "series")
  let data = j_field_or_self(label, "data")
  let series_single = j_field_or_self(series, "single")
  let series_multiple = j_field_or_self(series, "multiple")
  let series_separator = j_field_or_self(series_multiple, "separator")
  let data_separator = j_field_or_self(data, "separator")
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
    Some(Array(arr)) => pair_symbol_bounding_data(arr)
    _ => None
  }
}

///|
fn parse_symbol_size_values(j : Json) -> Array[String]? {
  j_stringish_pair_opt(j, "symbolSize")
}

///|
fn parse_symbol_values(j : Json) -> Array[String]? {
  match j_field(j, "symbol") {
    Some(String(s)) => Some([s, s])
    Some(Array(arr)) => pair_strings_from_json(arr)
    _ => None
  }
}

///|
fn parse_symbol_offset(j : Json) -> Array[String]? {
  j_stringish_pair_opt(j, "symbolOffset")
}

///|

///|
fn parse_visual_map(j : Json) -> VisualMapOption {
  let base = VisualMapOption::default()
  {
    min: j_number(j, "min", base.min),
    max: j_number(j, "max", base.max),
    series_index: j_int(j, "seriesIndex", base.series_index),
    dimension: j_int(j, "dimension", base.dimension),
    in_range: parse_visual_map_in_range(j_field_or_self(j, "inRange")),
  }
}

///|
fn parse_visual_map_in_range(j : Json) -> VisualMapInRange {
  let base = VisualMapInRange::default()
  {
    color: j_stringish_array(j, "color", base.color),
    symbol_size: parse_number_pair(j_field(j, "symbolSize")),
    opacity: parse_number_pair(j_field(j, "opacity")),
  }
}

///|
fn parse_number_pair(j : Json?) -> Array[Double] {
  match j {
    Some(Array(arr)) => {
      let result : Array[Double] = []
      let mut i = 0
      while i < arr.length() && i < 2 {
        result.push(json_number_or_zero(arr[i]))
        i += 1
      }
      result
    }
    Some(Number(n, ..)) => [n, n]
    _ => []
  }
}

///|
fn[T] j_parse_optional(j : Json, key : String, parse_one : (Json) -> T) -> T? {
  match j_field(j, key) {
    Some(value) => Some(parse_one(value))
    None => None
  }
}

///|
fn[T] j_parse_array(
  j : Json,
  key : String,
  parse_one : (Json) -> T,
  default_val : Array[T],
) -> Array[T] {
  match j_field(j, key) {
    Some(Array(arr)) => arr.map(parse_one)
    _ => default_val
  }
}

///|
fn[T] j_parse_one_or_many(
  j : Json,
  key : String,
  parse_one : (Json) -> T,
  default_val : Array[T],
) -> Array[T] {
  match j_field(j, key) {
    Some(value) =>
      match value {
        Array(arr) => arr.map(parse_one)
        Object(_) => [parse_one(value)]
        _ => default_val
      }
    None => default_val
  }
}

///|
fn j_field_or_self(j : Json, key : String) -> Json {
  match j_field(j, key) {
    Some(value) => value
    None => j
  }
}

///|
fn j_string_or_number(j : Json, key : String, default_val : String) -> String {
  match j_field(j, key) {
    Some(String(s)) => s
    Some(Number(n, ..)) => "\{n}"
    _ => default_val
  }
}

///|
fn j_string_or_number_as_string_opt(
  j : Json,
  key : String,
  default_val : String?,
) -> String? {
  match j_field(j, key) {
    Some(String(s)) => Some(s)
    Some(Number(n, ..)) => Some("\{n}")
    _ => default_val
  }
}

///|
fn j_string_array_lossy(
  j : Json,
  key : String,
  default_val : Array[String],
) -> Array[String] {
  match j_field(j, key) {
    Some(Array(arr)) =>
      arr.map(fn(item) {
        match item {
          String(s) => s
          _ => item.to_string()
        }
      })
    _ => default_val
  }
}

///|
fn j_stringish_array(
  j : Json,
  key : String,
  default_val : Array[String],
) -> Array[String] {
  match j_field(j, key) {
    Some(Array(arr)) => arr.map(json_to_stringish_empty)
    Some(String(s)) => [s]
    _ => default_val
  }
}

///|
fn j_stringish_pair_opt(j : Json, key : String) -> Array[String]? {
  match j_field(j, key) {
    Some(String(s)) => Some([s, s])
    Some(Number(n, ..)) => {
      let value = "\{n}"
      Some([value, value])
    }
    Some(Array(arr)) => pair_strings_from_json(arr)
    _ => None
  }
}

///|
fn pair_strings_from_json(arr : Array[Json]) -> Array[String]? {
  match arr {
    [] => None
    [first] => {
      let value = json_to_stringish_zero(first)
      Some([value, value])
    }
    [first, second, ..] =>
      Some([json_to_stringish_zero(first), json_to_stringish_zero(second)])
  }
}

///|
fn pair_symbol_bounding_data(arr : Array[Json]) -> SymbolBoundingData? {
  match arr {
    [first, second, ..] =>
      Some(Pair(json_number_or_zero(first), json_number_or_zero(second)))
    _ => None
  }
}

///|
fn parse_data_object(j : Json, value : DataValue) -> DataItem {
  let raw_value_parts = match j_field(j, "value") {
    Some(Array(arr)) => Some(arr)
    _ => None
  }
  let id = j_string_or_number_as_string_opt(j, "id", None)
  let name = j_string_opt(j, "name")
  let source = j_string_or_number_as_string_opt(j, "source", None)
  let target = j_string_or_number_as_string_opt(j, "target", None)
  let symbol = j_string_opt(j, "symbol")
  let coords = parse_data_coords(j)
  let from_name = j_string_opt(j, "fromName")
  let to_name = j_string_opt(j, "toName")
  let cursor = j_string_opt(j, "cursor")
  let selected = match j_field(j, "selected") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  let silent = match j_field(j, "silent") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  let label = match j_field(j, "label") {
    Some(value) => Some(parse_geo_label_patch_option(value))
    None => None
  }
  let item_style = match j_field(j, "itemStyle") {
    Some(style) => Some(parse_geo_item_style_patch_option(style))
    None => None
  }
  let children = j_parse_array(j, "children", parse_data_item, [])
  let collapsed = match j_field(j, "collapsed") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  {
    value,
    raw_value_parts,
    raw_item: Some(j),
    id,
    name,
    source,
    target,
    symbol,
    coords,
    from_name,
    to_name,
    cursor,
    selected,
    silent,
    label,
    item_style,
    states: parse_geo_states_option(j),
    children,
    collapsed,
  }
}

///|
fn json_number_or_zero(j : Json) -> Double {
  match j {
    Number(n, ..) => n
    _ => 0.0
  }
}

///|
fn json_to_stringish_zero(j : Json) -> String {
  match j {
    String(s) => s
    Number(n, ..) => "\{n}"
    _ => "0"
  }
}

///|
fn json_to_stringish_empty(j : Json) -> String {
  match j {
    String(s) => s
    Number(n, ..) => "\{n}"
    _ => ""
  }
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

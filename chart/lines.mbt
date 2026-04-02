// Corresponds to: echarts/src/chart/lines/LinesSeries.ts
//                  echarts/src/chart/lines/linesLayout.ts
//                  echarts/src/chart/lines/LinesView.ts
//                  echarts/src/chart/lines/install.ts

///|
fn lines_chart_json_field(j : Json, key : String) -> Json? {
  match j {
    Object(map) => map.get(key)
    _ => None
  }
}

///|
fn lines_chart_json_field_or_self(j : Json, key : String) -> Json {
  lines_chart_json_field(j, key).unwrap_or(j)
}

///|
fn lines_chart_json_string_opt(j : Json, key : String) -> String? {
  match lines_chart_json_field(j, key) {
    Some(String(s)) => Some(s)
    _ => None
  }
}

///|
fn lines_chart_json_number_opt(j : Json, key : String) -> Double? {
  match lines_chart_json_field(j, key) {
    Some(Number(n, ..)) => Some(n)
    _ => None
  }
}

///|
fn lines_chart_json_string_pair_opt(j : Json, key : String) -> Array[String]? {
  match lines_chart_json_field(j, key) {
    Some(String(s)) => Some([s, s])
    Some(Array(arr)) =>
      match arr {
        [] => None
        [String(first)] => Some([first, first])
        [String(first), String(second), ..] => Some([first, second])
        _ => None
      }
    _ => None
  }
}

///|
fn lines_chart_json_number_pair_opt(j : Json, key : String) -> Array[Double]? {
  match lines_chart_json_field(j, key) {
    Some(Number(n, ..)) => Some([n, n])
    Some(Array(arr)) =>
      match arr {
        [] => None
        [Number(first, ..)] => Some([first, first])
        [Number(first, ..), Number(second, ..), ..] => Some([first, second])
        _ => None
      }
    _ => None
  }
}

///|
fn lines_chart_parse_double_string(value : String, fallback : Double) -> Double {
  let parsed = try? @strconv.parse_double(value)
  match parsed {
    Ok(n) => n
    _ => fallback
  }
}

///|
fn lines_chart_item_line_style(item : @option.DataItem) -> Json? {
  item.raw_item.map(raw => lines_chart_json_field_or_self(raw, "lineStyle"))
}

///|
fn lines_chart_item_symbol_pair(item : @option.DataItem) -> Array[String]? {
  match item.raw_item {
    Some(raw) => lines_chart_json_string_pair_opt(raw, "symbol")
    None => None
  }
}

///|
fn lines_chart_item_symbol_size_pair(item : @option.DataItem) -> Array[Double]? {
  match item.raw_item {
    Some(raw) => lines_chart_json_number_pair_opt(raw, "symbolSize")
    None => None
  }
}

///|
fn lines_chart_item_color(
  item : @option.DataItem,
  series : @option.SeriesOption,
  series_index : Int,
) -> String {
  let base_color = series.line_style_color.unwrap_or(
    series.color.unwrap_or(@visual.palette_color(series_index)),
  )
  match lines_chart_item_line_style(item) {
    Some(line_style) =>
      match lines_chart_json_string_opt(line_style, "color") {
        Some(color) => color
        None => base_color
      }
    None => base_color
  }
}

///|
fn lines_chart_item_width(
  item : @option.DataItem,
  series : @option.SeriesOption,
) -> Double {
  let base_width = series.line_style_width.unwrap_or(1.0)
  match lines_chart_item_line_style(item) {
    Some(line_style) =>
      match lines_chart_json_number_opt(line_style, "width") {
        Some(width) => width
        None => base_width
      }
    None => base_width
  }
}

///|
fn lines_chart_item_opacity(
  item : @option.DataItem,
  series : @option.SeriesOption,
) -> Double {
  let base_opacity = series.line_style_opacity.unwrap_or(0.5)
  match lines_chart_item_line_style(item) {
    Some(line_style) =>
      match lines_chart_json_number_opt(line_style, "opacity") {
        Some(opacity) => opacity
        None => base_opacity
      }
    None => base_opacity
  }
}

///|
fn lines_chart_item_curveness(
  item : @option.DataItem,
  series : @option.SeriesOption,
) -> Double {
  let base_curveness = series.line_style_curveness.unwrap_or(0.0)
  match lines_chart_item_line_style(item) {
    Some(line_style) =>
      match lines_chart_json_number_opt(line_style, "curveness") {
        Some(curveness) => curveness
        None => base_curveness
      }
    None => base_curveness
  }
}

///|
fn lines_chart_series_symbol_pair(
  series : @option.SeriesOption,
) -> Array[String] {
  match series.symbol_values {
    Some(values) if values.length() >= 2 => [values[0], values[1]]
    Some(values) if values.length() == 1 => [values[0], values[0]]
    _ =>
      match series.symbol {
        Some(symbol) => [symbol, symbol]
        None => ["none", "none"]
      }
  }
}

///|
fn lines_chart_series_symbol_size_pair(
  series : @option.SeriesOption,
) -> Array[Double] {
  match series.symbol_size_values {
    Some(values) if values.length() >= 2 =>
      [
        lines_chart_parse_double_string(values[0], series.symbol_size),
        lines_chart_parse_double_string(values[1], series.symbol_size),
      ]
    Some(values) if values.length() == 1 => {
      let value = lines_chart_parse_double_string(values[0], series.symbol_size)
      [value, value]
    }
    _ => [series.symbol_size, series.symbol_size]
  }
}

///|
fn lines_chart_symbol_pair(
  item : @option.DataItem,
  series : @option.SeriesOption,
) -> Array[String] {
  match lines_chart_item_symbol_pair(item) {
    Some(values) if values.length() >= 2 => [values[0], values[1]]
    Some(values) if values.length() == 1 => [values[0], values[0]]
    _ => lines_chart_series_symbol_pair(series)
  }
}

///|
fn lines_chart_symbol_size_pair(
  item : @option.DataItem,
  series : @option.SeriesOption,
) -> Array[Double] {
  match lines_chart_item_symbol_size_pair(item) {
    Some(values) if values.length() >= 2 => [values[0], values[1]]
    Some(values) if values.length() == 1 => [values[0], values[0]]
    _ => lines_chart_series_symbol_size_pair(series)
  }
}

///|
fn lines_chart_item_coords(item : @option.DataItem) -> Array[Array[Double]]? {
  match item.coords {
    Some(coords) if coords.length() >= 2 => Some(coords)
    _ => None
  }
}

///|
fn lines_chart_geo_named_coords(
  item : @option.DataItem,
  geo : @coord.Geo,
) -> Array[Array[Double]]? {
  match (item.from_name, item.to_name) {
    (Some(from_name), Some(to_name)) =>
      match (geo.region_by_name(from_name), geo.region_by_name(to_name)) {
        (Some(from_region), Some(to_region)) =>
          Some([
            [from_region.center.x, from_region.center.y],
            [to_region.center.x, to_region.center.y],
          ])
        _ => None
      }
    _ => None
  }
}

///|
fn lines_chart_coord_to_point(
  series : @option.SeriesOption,
  coord_pair : Array[Double],
  coord : @coord.Cartesian2D,
  coord_index : Int,
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
) -> @graphic.Point? {
  if coord_pair.length() < 2 {
    return None
  }
  match (series.coordinate_system, polar, geo) {
    (Some("geo"), _, Some(g)) =>
      Some(g.data_to_point(coord_pair[0], coord_pair[1]))
    (Some("polar"), Some(p), _) =>
      Some(p.data_to_point(Num(coord_pair[0]), Num(coord_pair[1]), coord_index))
    _ => {
      let x_idx = series.x_axis_index
      let y_idx = series.y_axis_index
      let px = if x_idx < coord.x_scales.length() {
        match coord.x_scales[x_idx] {
          Ordinal(s) => s.band_center(coord_pair[0].to_int())
          Linear(s) => s.data_to_pixel(coord_pair[0])
        }
      } else {
        coord.bbox.x
      }
      let py = coord.num_y(y_idx, coord_pair[1])
      Some(@graphic.Point::new(px, py))
    }
  }
}

///|
fn lines_chart_points(
  series : @option.SeriesOption,
  item : @option.DataItem,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
) -> Array[@graphic.Point] {
  let raw_coords = match (lines_chart_item_coords(item), geo) {
    (Some(coords), _) => Some(coords)
    (None, Some(g)) => lines_chart_geo_named_coords(item, g)
    _ => None
  }
  match raw_coords {
    Some(coords_arr) => {
      let points : Array[@graphic.Point] = []
      let mut i = 0
      while i < coords_arr.length() {
        match
          lines_chart_coord_to_point(
            series,
            coords_arr[i],
            coord,
            i,
            polar~,
            geo~,
          ) {
          Some(point) => points.push(point)
          None => ()
        }
        i += 1
      }
      points
    }
    None => []
  }
}

///|
fn lines_chart_curve_path(
  start : @graphic.Point,
  end : @graphic.Point,
  curveness : Double,
) -> String {
  let control = lines_chart_curve_control(start, end, curveness)
  "M \{start.x} \{start.y} Q \{control.x} \{control.y} \{end.x} \{end.y}"
}

///|
fn lines_chart_curve_control(
  start : @graphic.Point,
  end : @graphic.Point,
  curveness : Double,
) -> @graphic.Point {
  let cx = (start.x + end.x) / 2.0 - (start.y - end.y) * curveness
  let cy = (start.y + end.y) / 2.0 - (end.x - start.x) * curveness
  @graphic.Point::new(cx, cy)
}

///|
fn lines_chart_symbol_rotation(
  dx : Double,
  dy : Double,
  at_end : Bool,
) -> Double {
  let base = if at_end { @math.PI / 2.0 } else { -@math.PI / 2.0 }
  base + @math.atan2(dy, dx)
}

///|
fn lines_chart_endpoint_direction(
  points : Array[@graphic.Point],
  at_end : Bool,
  control? : @graphic.Point? = None,
) -> (Double, Double) {
  if points.length() < 2 {
    return (1.0, 0.0)
  }
  match control {
    Some(cp) =>
      if at_end {
        (
          points[points.length() - 1].x - cp.x,
          points[points.length() - 1].y - cp.y,
        )
      } else {
        (cp.x - points[0].x, cp.y - points[0].y)
      }
    None =>
      if at_end {
        let end = points[points.length() - 1]
        let prev = points[points.length() - 2]
        (end.x - prev.x, end.y - prev.y)
      } else {
        (points[1].x - points[0].x, points[1].y - points[0].y)
      }
  }
}

///|
fn lines_chart_symbol_element(
  symbol : String,
  size_w : Double,
  size_h : Double,
  color : String,
  opacity : Double,
  point : @graphic.Point,
  rotation : Double,
) -> @graphic.Element? {
  if symbol == "none" || size_w <= 0.0 || size_h <= 0.0 {
    return None
  }
  let local_symbol = @graphic.make_symbol(
    symbol,
    -size_w / 2.0,
    -size_h / 2.0,
    size_w,
    size_h,
    color,
    opacity,
  )
  let transform = @graphic.Matrix::translate(point.x, point.y).then(
    @graphic.Matrix::rotate(rotation),
  )
  Some(@graphic.Element::group_transformed([local_symbol], transform))
}

///|
fn lines_chart_endpoint_symbols(
  item : @option.DataItem,
  series : @option.SeriesOption,
  points : Array[@graphic.Point],
  color : String,
  opacity : Double,
  control? : @graphic.Point? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let symbols = lines_chart_symbol_pair(item, series)
  let sizes = lines_chart_symbol_size_pair(item, series)
  if points.length() < 2 {
    return elems
  }
  let (from_dx, from_dy) = lines_chart_endpoint_direction(
    points,
    false,
    control~,
  )
  let (to_dx, to_dy) = lines_chart_endpoint_direction(points, true, control~)
  match
    lines_chart_symbol_element(
      symbols[0],
      sizes[0],
      sizes[0],
      color,
      opacity,
      points[0],
      lines_chart_symbol_rotation(from_dx, from_dy, false),
    ) {
    Some(elem) => elems.push(elem)
    None => ()
  }
  match
    lines_chart_symbol_element(
      symbols[1],
      sizes[1],
      sizes[1],
      color,
      opacity,
      points[points.length() - 1],
      lines_chart_symbol_rotation(to_dx, to_dy, true),
    ) {
    Some(elem) => elems.push(elem)
    None => ()
  }
  elems
}

///|
fn lines_chart_cartesian_clip_bbox(
  series : @option.SeriesOption,
  coord : @coord.Cartesian2D,
) -> @graphic.BBox {
  let line_width = series.line_style_width.unwrap_or(0.0)
  let half = line_width / 2.0
  @graphic.BBox::new(
    coord.bbox.x - half,
    coord.bbox.y - half,
    coord.bbox.width + line_width,
    coord.bbox.height + line_width,
  )
}

///|
fn lines_chart_round_tenth(v : Double) -> Double {
  (v * 10.0 + 0.5).to_int().to_double() / 10.0
}

///|
fn lines_chart_r4(v : Double) -> String {
  let scaled = (v * 10000.0 + 0.5).to_int().to_double() / 10000.0
  scaled.to_string()
}

///|
fn lines_chart_polar_clip_path(polar : @coord.Polar) -> String {
  let area = polar.get_area()
  let cx = lines_chart_round_tenth(area.cx)
  let cy = lines_chart_round_tenth(area.cy)
  let r0 = lines_chart_round_tenth(area.r0)
  let r = lines_chart_round_tenth(area.r)
  let a0 = area.start_angle
  let a1 = area.end_angle
  let outer_x0 = cx + r * @math.cos(a0)
  let outer_y0 = cy + r * @math.sin(a0)
  let outer_x1 = cx + r * @math.cos(a1)
  let outer_y1 = cy + r * @math.sin(a1)
  let span = if a1 >= a0 { a1 - a0 } else { a0 - a1 }
  let large_arc = if span > @math.PI { 1 } else { 0 }
  let outer_sweep = if area.clockwise { 1 } else { 0 }
  let inner_sweep = if area.clockwise { 0 } else { 1 }
  if r0 <= 0.5 {
    "M \{lines_chart_r4(cx)} \{lines_chart_r4(cy)} L \{lines_chart_r4(outer_x0)} \{lines_chart_r4(outer_y0)} A \{lines_chart_r4(r)} \{lines_chart_r4(r)} 0 \{large_arc} \{outer_sweep} \{lines_chart_r4(outer_x1)} \{lines_chart_r4(outer_y1)} Z"
  } else {
    let inner_x0 = cx + r0 * @math.cos(a0)
    let inner_y0 = cy + r0 * @math.sin(a0)
    let inner_x1 = cx + r0 * @math.cos(a1)
    let inner_y1 = cy + r0 * @math.sin(a1)
    "M \{lines_chart_r4(outer_x0)} \{lines_chart_r4(outer_y0)} A \{lines_chart_r4(r)} \{lines_chart_r4(r)} 0 \{large_arc} \{outer_sweep} \{lines_chart_r4(outer_x1)} \{lines_chart_r4(outer_y1)} L \{lines_chart_r4(inner_x1)} \{lines_chart_r4(inner_y1)} A \{lines_chart_r4(r0)} \{lines_chart_r4(r0)} 0 \{large_arc} \{inner_sweep} \{lines_chart_r4(inner_x0)} \{lines_chart_r4(inner_y0)} Z"
  }
}

///|
pub fn render_lines_chart_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
) -> Array[@graphic.Element] {
  let line_elems : Array[@graphic.Element] = []
  let mut di = 0
  while di < series.data.length() {
    let item = series.data[di]
    let points = lines_chart_points(series, item, coord, polar~, geo~)
    let color = lines_chart_item_color(item, series, series_index)
    let width = lines_chart_item_width(item, series)
    let opacity = lines_chart_item_opacity(item, series)
    let curveness = lines_chart_item_curveness(item, series)
    if points.length() >= 2 {
      if series.polyline || points.length() > 2 {
        line_elems.push(
          @graphic.Element::polyline_custom_opacity(
            points, color, width, "round", "round", opacity,
          ),
        )
        line_elems.append(
          lines_chart_endpoint_symbols(item, series, points, color, opacity),
        )
      } else if curveness != 0.0 {
        let control = lines_chart_curve_control(points[0], points[1], curveness)
        line_elems.push(
          @graphic.Element::path_stroke_custom(
            lines_chart_curve_path(points[0], points[1], curveness),
            color,
            width,
            "round",
            "round",
            opacity,
          ),
        )
        line_elems.append(
          lines_chart_endpoint_symbols(
            item,
            series,
            points,
            color,
            opacity,
            control=Some(control),
          ),
        )
      } else {
        line_elems.push(
          @graphic.Element::polyline_custom_opacity(
            [points[0], points[1]],
            color,
            width,
            "round",
            "round",
            opacity,
          ),
        )
        line_elems.append(
          lines_chart_endpoint_symbols(item, series, points, color, opacity),
        )
      }
    }
    di += 1
  }
  if line_elems.length() == 0 {
    []
  } else if series.clip &&
    series.coordinate_system != Some("geo") &&
    series.coordinate_system != Some("polar") {
    [
      @graphic.Element::group_clipped(
        line_elems,
        lines_chart_cartesian_clip_bbox(series, coord),
      ),
    ]
  } else if series.clip && polar is Some(p) {
    [
      @graphic.Element::group_clipped_path(
        line_elems,
        lines_chart_polar_clip_path(p),
      ),
    ]
  } else {
    line_elems
  }
}

///|
pub fn render_lines_chart(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    match series.series_type {
      Lines =>
        elems.append(render_lines_chart_series(series, si, coord, polar~, geo~))
      _ => ()
    }
    si += 1
  }
  elems
}

/// <=> echarts/src/chart/line/LineView.ts

///|
/// <=> zrender/src/graphic/helper/smoothBezier.ts:smoothBezier
fn line_smooth_path(points : Array[@graphic.Point], smooth : Double) -> String {
  let n = points.length()
  if n == 0 {
    return ""
  }
  if n == 1 {
    return "M \{points[0].x} \{points[0].y}"
  }
  if n == 2 {
    return "M \{points[0].x} \{points[0].y} L \{points[1].x} \{points[1].y}"
  }
  fn point_at(points : Array[@graphic.Point], idx : Int) -> @graphic.Point {
    if idx < 0 {
      points[0]
    } else if idx >= points.length() {
      points[points.length() - 1]
    } else {
      points[idx]
    }
  }
  let buf = StringBuilder::new()
  buf.write_string("M \{points[0].x} \{points[0].y}")
  let mut i = 0
  while i < n - 1 {
    let p0 = point_at(points, i - 1)
    let p1 = point_at(points, i)
    let p2 = point_at(points, i + 1)
    let p3 = point_at(points, i + 2)
    let cp1x = p1.x + smooth * (p2.x - p0.x) / 2.0
    let cp1y = p1.y + smooth * (p2.y - p0.y) / 2.0
    let cp2x = p2.x - smooth * (p3.x - p1.x) / 2.0
    let cp2y = p2.y - smooth * (p3.y - p1.y) / 2.0
    buf.write_string(" C \{cp1x} \{cp1y} \{cp2x} \{cp2y} \{p2.x} \{p2.y}")
    i += 1
  }
  buf.to_string()
}

///|
/// <=> echarts/src/chart/line/LineView.ts:drawSeriesSymbol
/// Generate step-line path for 'start', 'end', 'middle' modes.
fn line_step_path(points : Array[@graphic.Point], step : String) -> String {
  let n = points.length()
  if n == 0 {
    return ""
  }
  if n == 1 {
    return "M \{points[0].x} \{points[0].y}"
  }
  let buf = StringBuilder::new()
  buf.write_string("M \{points[0].x} \{points[0].y}")
  let mut i = 0
  while i < n - 1 {
    let p1 = points[i]
    let p2 = points[i + 1]
    match step {
      "start" => {
        // horizontal then vertical
        buf.write_string(" L \{p2.x} \{p1.y}")
        buf.write_string(" L \{p2.x} \{p2.y}")
      }
      "middle" => {
        // midpoint horizontal step
        let mx = (p1.x + p2.x) / 2.0
        buf.write_string(" L \{mx} \{p1.y}")
        buf.write_string(" L \{mx} \{p2.y}")
        buf.write_string(" L \{p2.x} \{p2.y}")
      }
      _ => {
        // "end" (default): vertical then horizontal
        buf.write_string(" L \{p1.x} \{p2.y}")
        buf.write_string(" L \{p2.x} \{p2.y}")
      }
    }
    i += 1
  }
  buf.to_string()
}

///|
fn line_path(
  points : Array[@graphic.Point],
  smooth : Double,
  step : String,
) -> String {
  if step != "" {
    line_step_path(points, step)
  } else if smooth > 0.0 {
    line_smooth_path(points, smooth)
  } else {
    let buf = StringBuilder::new()
    if points.length() == 0 {
      return ""
    }
    buf.write_string("M \{points[0].x} \{points[0].y}")
    let mut i = 1
    while i < points.length() {
      let p = points[i]
      buf.write_string(" L \{p.x} \{p.y}")
      i += 1
    }
    buf.to_string()
  }
}

///|
fn line_path_line_segment(path : String) -> String {
  if path.has_prefix("M ") {
    "L " + path[2:].to_string()
  } else if path.has_prefix("M") {
    "L" + path[1:].to_string()
  } else {
    path
  }
}

///|
fn line_reverse_points(points : Array[@graphic.Point]) -> Array[@graphic.Point] {
  let reversed : Array[@graphic.Point] = []
  let mut i = points.length() - 1
  while i >= 0 {
    reversed.push(points[i])
    i -= 1
  }
  reversed
}

///|
fn line_point_value(item : @option.DataItem) -> (Double, Double) {
  match item.value {
    Num(n) => (n, n)
    Vec(arr) =>
      if arr.length() > 1 {
        (arr[0], arr[1])
      } else if arr.length() > 0 {
        (arr[0], arr[0])
      } else {
        (0.0, 0.0)
      }
    DateValue(_, n) => (n, n)
    Null => (0.0, 0.0)
  }
}

///|
fn line_point_for_cartesian(
  value_x : Double,
  value_y : Double,
  data_index : Int,
  coord : @coord.Cartesian2D,
  x_idx : Int,
  y_idx : Int,
) -> @graphic.Point {
  let px = if x_idx < coord.x_scales.length() {
    match coord.x_scales[x_idx] {
      Ordinal(s) => s.band_center(data_index)
      Linear(s) => s.data_to_pixel(value_x)
    }
  } else {
    coord.bbox.x
  }
  let py = if y_idx < coord.y_scales.length() {
    match coord.y_scales[y_idx] {
      Ordinal(s) => s.band_center(data_index)
      Linear(s) => s.data_to_pixel(value_y)
      BreakLinear(s) => s.data_to_pixel(value_y)
    }
  } else {
    coord.bbox.bottom()
  }
  @graphic.Point::new(px, py)
}

///|
fn polar_line_point(
  item : @option.DataItem,
  data_index : Int,
  polar : @coord.Polar,
) -> @graphic.Point {
  match item.value {
    Num(n) =>
      polar.data_to_point(Num(n), Num(data_index.to_double()), data_index)
    Vec(arr) =>
      if arr.length() >= 2 {
        polar.data_to_point(Num(arr[0]), Num(arr[1]), data_index)
      } else if arr.length() == 1 {
        polar.data_to_point(
          Num(arr[0]),
          Num(data_index.to_double()),
          data_index,
        )
      } else {
        polar.data_to_point(Num(0.0), Num(data_index.to_double()), data_index)
      }
    DateValue(_, n) =>
      polar.data_to_point(Num(n), Num(data_index.to_double()), data_index)
    Null =>
      polar.data_to_point(Num(0.0), Num(data_index.to_double()), data_index)
  }
}

///|
fn polar_area_path(
  points : Array[@graphic.Point],
  polar : @coord.Polar,
) -> String {
  let path_buf = StringBuilder::new()
  path_buf.write_string("M \{points[0].x} \{points[0].y}")
  let mut pi = 1
  while pi < points.length() {
    let p = points[pi]
    path_buf.write_string(" L \{p.x} \{p.y}")
    pi += 1
  }
  path_buf.write_string(" L \{polar.cx} \{polar.cy} Z")
  path_buf.to_string()
}

///|
fn line_baseline_point_for_cartesian(
  x : Double,
  baseline_value : Double,
  coord : @coord.Cartesian2D,
  y_idx : Int,
) -> @graphic.Point {
  let py = if y_idx < coord.y_scales.length() {
    match coord.y_scales[y_idx] {
      Ordinal(s) => s.band_center(0)
      Linear(s) => s.data_to_pixel(baseline_value)
      BreakLinear(s) => s.data_to_pixel(baseline_value)
    }
  } else {
    coord.bbox.bottom()
  }
  @graphic.Point::new(x, py)
}

///|
pub fn render_line_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  baseline_values? : Array[Double]? = None,
  stacked_values? : Array[Double]? = None,
  polar? : @coord.Polar? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let color = series.color.unwrap_or(@visual.palette_color(series_index))
  let stroke_color = series.line_style_color.unwrap_or(color)
  let stroke_width = series.line_style_width.unwrap_or(2.0)
  let stroke_opacity = series.line_style_opacity.unwrap_or(1.0)
  let points : Array[@graphic.Point] = []
  let nd = series.data.length()
  let mut di = 0
  while di < nd {
    let item = series.data[di]
    let (value_x, raw_y) = line_point_value(item)
    let value_y = match stacked_values {
      Some(values) => if di < values.length() { values[di] } else { raw_y }
      None => raw_y
    }
    match (series.coordinate_system, polar) {
      (Some("polar"), Some(p)) => points.push(polar_line_point(item, di, p))
      _ =>
        points.push(
          line_point_for_cartesian(value_x, value_y, di, coord, x_idx, y_idx),
        )
    }
    di += 1
  }
  if points.length() == 0 {
    return elems
  }
  if series.area_style {
    let area_color = series.area_style_color.unwrap_or(color)
    let area_opacity = series.area_style_opacity.unwrap_or(0.7)
    match (series.coordinate_system, polar) {
      (Some("polar"), Some(p)) =>
        elems.push(
          @graphic.Element::path_filled(
            polar_area_path(points, p),
            area_color,
            area_opacity,
          ),
        )
      _ => {
        let base_points : Array[@graphic.Point] = []
        match baseline_values {
          Some(values) => {
            let mut bi = 0
            while bi < points.length() {
              let baseline_val = if bi < values.length() {
                values[bi]
              } else {
                0.0
              }
              base_points.push(
                line_baseline_point_for_cartesian(
                  points[bi].x,
                  baseline_val,
                  coord,
                  y_idx,
                ),
              )
              bi += 1
            }
          }
          None => {
            let base_y = coord.bbox.y + coord.bbox.height
            for p in points {
              base_points.push(@graphic.Point::new(p.x, base_y))
            }
          }
        }

        let top_path = line_path(points, series.smooth, series.step)
        let bottom_reversed = line_reverse_points(base_points)
        let bottom_path = line_path(bottom_reversed, series.smooth, series.step)
        let area_path = top_path +
          " " +
          line_path_line_segment(bottom_path) +
          " Z"
        elems.push(
          @graphic.Element::path_filled(area_path, area_color, area_opacity),
        )
      }
    }
  }
  elems.push(
    @graphic.Element::path_stroke_custom(
      line_path(points, series.smooth, series.step),
      stroke_color,
      stroke_width,
      "butt",
      "bevel",
      stroke_opacity,
    ),
  )

  if series.show_symbol {
    // Check if any point is highlighted; if so apply emphasis/blur states to all symbols.
    let any_highlighted = @visual.has_any_highlighted(series.data)

    for pi, _ in points {
      let p = points[pi]
      let item = series.data[pi]
      let circle = @graphic.Element::circle_colored(
        p.x,
        p.y,
        series.symbol_size * 0.5,
        stroke_color,
      )

      // Apply emphasis/blur states if any point is highlighted
      let result = if any_highlighted {
        let emphasis_fill = match item.highlighted {
          Some(true) => @visual.lift_hex_color(stroke_color)
          _ => stroke_color
        }
        let emphasis_style : @graphic.DisplayStateStyle = {
          fill: Some(emphasis_fill),
          stroke: None,
          line_width: None,
          stroke_no_scale: false,
        }
        let blur_style : @graphic.DisplayStateStyle = {
          fill: None,
          stroke: None,
          line_width: None,
          stroke_no_scale: false,
        }
        circle.with_emphasis_style(emphasis_style).with_blur_style(blur_style)
      } else {
        circle
      }
      elems.push(result)
    }
  }
  elems
}

///|
priv struct LineStackState {
  key : String
  sums : Array[Double]
}

///|
fn line_stack_group_key(series : @option.SeriesOption) -> String? {
  match series.stack {
    Some(stack_name) =>
      match series.coordinate_system {
        Some("polar") =>
          Some(
            "polar::\{series.polar_index}::\{series.radius_axis_index}::\{series.angle_axis_index}::\{stack_name}",
          )
        _ =>
          Some(
            "cartesian::\{series.x_axis_index}::\{series.y_axis_index}::\{stack_name}",
          )
      }
    None => None
  }
}

///|
fn line_find_stack_state_index(
  states : Array[LineStackState],
  key : String,
) -> Int {
  let mut i = 0
  while i < states.length() {
    if states[i].key == key {
      return i
    }
    i += 1
  }
  -1
}

///|
fn line_series_values_for_stack(series : @option.SeriesOption) -> Array[Double] {
  let values : Array[Double] = []
  for item in series.data {
    let (_, vy) = line_point_value(item)
    values.push(vy)
  }
  values
}

///|
pub fn render_lines(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  polars? : Array[@coord.Polar] = [],
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let stack_states : Array[LineStackState] = []

  let mut color_idx = 0
  for si, _ in opt.series {
    let series = opt.series[si]
    match series.series_type {
      Line => ()
      _ => {
        color_idx += 1
        continue
      }
    }
    // Select polar based on polarIndex
    let polar : @coord.Polar? = if series.coordinate_system == Some("polar") {
      let polar_idx = series.polar_index
      if polar_idx >= 0 && polar_idx < polars.length() {
        Some(polars[polar_idx])
      } else {
        None
      }
    } else {
      None
    }

    let (baseline_values, stacked_values) = match line_stack_group_key(series) {
      Some(stack_key) => {
        let mut stack_index = line_find_stack_state_index(
          stack_states, stack_key,
        )
        if stack_index < 0 {
          let initial : Array[Double] = []
          let mut init_i = 0
          while init_i < series.data.length() {
            initial.push(0.0)
            init_i += 1
          }
          stack_states.push({ key: stack_key, sums: initial })
          stack_index = stack_states.length() - 1
        }

        let base_vals : Array[Double] = []
        for sum in stack_states[stack_index].sums {
          base_vals.push(sum)
        }

        let values = line_series_values_for_stack(series)
        let mut ui = 0
        while ui < values.length() {
          if ui < stack_states[stack_index].sums.length() {
            stack_states[stack_index].sums[ui] = stack_states[stack_index].sums[ui] +
              values[ui]
          } else {
            stack_states[stack_index].sums.push(values[ui])
          }
          ui += 1
        }
        let top_vals : Array[Double] = []
        for sum in stack_states[stack_index].sums {
          top_vals.push(sum)
        }
        (Some(base_vals), Some(top_vals))
      }
      None => (None, None)
    }

    elems.append(
      render_line_series(
        series,
        color_idx,
        coord,
        baseline_values~,
        stacked_values~,
        polar~,
      ),
    )
    color_idx += 1
  }
  elems
}

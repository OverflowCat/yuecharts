// Corresponds to: echarts/src/chart/line/LineView.ts

///|
/// Render a LineSeries to polyline/path scene graph elements.
pub fn render_line_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let color = match series.color {
    Some(c) => c
    None => @visual.palette_color(series_index)
  }
  // Build pixel points
  let points : Array[@graphic.Point] = []
  let nd = series.data.length()
  let mut di = 0
  while di < nd {
    let item = series.data[di]
    di = di + 1
    let px = if x_idx < coord.x_scales.length() {
      match coord.x_scales[x_idx] {
        Ordinal(s) =>
          match s.data_to_pixel(di.to_string()) {
            Some(v) => v
            None => coord.bbox.x + (di - 1).to_double() * 10.0
          }
        Linear(s) => {
          let v = match item.value {
            Num(n) => n
            Vec(arr) => if arr.length() > 0 { arr[0] } else { 0.0 }
            Null => 0.0
          }
          s.data_to_pixel(v)
        }
      }
    } else {
      coord.bbox.x
    }
    let py = match item.value {
      Num(n) => coord.num_y(y_idx, n)
      Vec(arr) =>
        if arr.length() > 1 {
          coord.num_y(y_idx, arr[1])
        } else {
          coord.bbox.y + coord.bbox.height
        }
      Null => coord.bbox.y + coord.bbox.height
    }
    points.push(@graphic.Point::new(px, py))
  }
  if points.length() == 0 {
    return elems
  }
  // Area fill if areaStyle is set
  if series.area_style {
    let base_y = coord.bbox.y + coord.bbox.height
    let path_buf = StringBuilder::new()
    path_buf.write_string("M \{(points[0].x)} \{base_y}")
    let mut pi = 0
    while pi < points.length() {
      let p = points[pi]
      pi = pi + 1
      path_buf.write_string(" L \{p.x} \{p.y}")
    }
    path_buf.write_string(" L \{(points[points.length() - 1].x)} \{base_y} Z")
    elems.push(@graphic.Element::path_filled(path_buf.to_string(), color, 0.3))
  }
  // Polyline
  elems.push(@graphic.Element::polyline_stroked(points, color))
  // Data point dots
  let mut pi = 0
  while pi < points.length() {
    let p = points[pi]
    pi = pi + 1
    elems.push(
      @graphic.Element::circle_colored(
        p.x,
        p.y,
        series.symbol_size * 0.5,
        color,
      ),
    )
  }
  elems
}

///|
/// Render all line series from a ChartOption to scene graph elements.
pub fn render_lines(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut si = 0
  let mut color_idx = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si = si + 1
    match series.series_type {
      Line => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let series_elems = render_line_series(series, color_idx, coord)
    let mut ei = 0
    while ei < series_elems.length() {
      elems.push(series_elems[ei])
      ei = ei + 1
    }
    color_idx = color_idx + 1
  }
  elems
}

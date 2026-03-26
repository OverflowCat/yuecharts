// Corresponds to: echarts/src/chart/line/LineView.ts

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
pub fn render_line_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let color = match series.color {
    Some(c) => c
    None => @visual.palette_color(series_index)
  }
  let points : Array[@graphic.Point] = []
  let nd = series.data.length()
  let mut di = 0
  while di < nd {
    let item = series.data[di]
    match (series.coordinate_system, polar) {
      (Some("polar"), Some(p)) => points.push(polar_line_point(item, di, p))
      _ => {
        let px = if x_idx < coord.x_scales.length() {
          match coord.x_scales[x_idx] {
            Ordinal(s) => s.band_center(di)
            Linear(s) => {
              let v = match item.value {
                Num(n) => n
                Vec(arr) => if arr.length() > 0 { arr[0] } else { 0.0 }
                DateValue(_, n) => n
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
          DateValue(_, n) => coord.num_y(y_idx, n)
          Null => coord.bbox.y + coord.bbox.height
        }
        points.push(@graphic.Point::new(px, py))
      }
    }
    di += 1
  }
  if points.length() == 0 {
    return elems
  }
  if series.area_style {
    match (series.coordinate_system, polar) {
      (Some("polar"), Some(p)) =>
        elems.push(
          @graphic.Element::path_filled(polar_area_path(points, p), color, 0.3),
        )
      _ => {
        let base_y = coord.bbox.y + coord.bbox.height
        let path_buf = StringBuilder::new()
        path_buf.write_string("M \{points[0].x} \{base_y}")
        let mut pi = 0
        while pi < points.length() {
          let p = points[pi]
          pi += 1
          path_buf.write_string(" L \{p.x} \{p.y}")
        }
        path_buf.write_string(" L \{points[points.length() - 1].x} \{base_y} Z")
        elems.push(
          @graphic.Element::path_filled(path_buf.to_string(), color, 0.3),
        )
      }
    }
  }
  elems.push(@graphic.Element::polyline_stroked(points, color))
  let mut pi = 0
  while pi < points.length() {
    let p = points[pi]
    pi += 1
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
pub fn render_lines(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut si = 0
  let mut color_idx = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si += 1
    match series.series_type {
      Line => ()
      _ => {
        color_idx += 1
        continue
      }
    }
    let series_elems = render_line_series(series, color_idx, coord, polar~)
    let mut ei = 0
    while ei < series_elems.length() {
      elems.push(series_elems[ei])
      ei += 1
    }
    color_idx += 1
  }
  elems
}

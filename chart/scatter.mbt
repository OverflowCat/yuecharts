// Corresponds to: echarts/src/chart/scatter/ScatterView.ts
//                  echarts/src/layout/points.ts

///|
fn scatter_point(
  series : @option.SeriesOption,
  data_index : Int,
  item : @option.DataItem,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
) -> @graphic.Point? {
  match (series.coordinate_system, polar) {
    (Some("polar"), Some(p)) =>
      match item.value {
        Null => None
        Num(n) =>
          Some(p.data_to_point(Num(n), Num(data_index.to_double()), data_index))
        Vec(arr) =>
          if arr.length() >= 2 {
            Some(p.data_to_point(Num(arr[0]), Num(arr[1]), data_index))
          } else if arr.length() == 1 {
            Some(
              p.data_to_point(
                Num(arr[0]),
                Num(data_index.to_double()),
                data_index,
              ),
            )
          } else {
            None
          }
        DateValue(_, n) =>
          Some(p.data_to_point(Num(n), Num(data_index.to_double()), data_index))
      }
    _ => {
      let x_idx = series.x_axis_index
      let y_idx = series.y_axis_index
      let nd = series.data.length()
      let nd_f = if nd > 0 { nd.to_double() } else { 1.0 }
      match item.value {
        Null => None
        Num(n) => {
          let px = if x_idx < coord.x_scales.length() {
            match coord.x_scales[x_idx] {
              Ordinal(s) => s.band_center(data_index)
              Linear(s) =>
                s.range_min +
                data_index.to_double() * (s.range_max - s.range_min) / nd_f
            }
          } else {
            coord.bbox.x
          }
          let py = coord.num_y(y_idx, n)
          Some(@graphic.Point::new(px, py))
        }
        Vec(arr) =>
          if arr.length() >= 2 {
            let px = if x_idx < coord.x_scales.length() {
              match coord.x_scales[x_idx] {
                Ordinal(s) => s.band_center(arr[0].to_int())
                Linear(s) => s.data_to_pixel(arr[0])
              }
            } else {
              coord.bbox.x
            }
            let py = coord.num_y(y_idx, arr[1])
            Some(@graphic.Point::new(px, py))
          } else if arr.length() == 1 {
            let px = if x_idx < coord.x_scales.length() {
              match coord.x_scales[x_idx] {
                Ordinal(s) => s.band_center(data_index)
                Linear(s) =>
                  s.range_min +
                  data_index.to_double() * (s.range_max - s.range_min) / nd_f
              }
            } else {
              coord.bbox.x
            }
            let py = coord.num_y(y_idx, arr[0])
            Some(@graphic.Point::new(px, py))
          } else {
            None
          }
        DateValue(_, n) => {
          let px = if x_idx < coord.x_scales.length() {
            match coord.x_scales[x_idx] {
              Ordinal(s) => s.band_center(data_index)
              Linear(s) =>
                s.range_min +
                data_index.to_double() * (s.range_max - s.range_min) / nd_f
            }
          } else {
            coord.bbox.x
          }
          let py = coord.num_y(y_idx, n)
          Some(@graphic.Point::new(px, py))
        }
      }
    }
  }
}

///|
pub fn render_scatter_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
) -> Array[@graphic.Element] {
  let color = series.color.unwrap_or(@visual.palette_color(series_index))
  series.data
  .iter()
  .mapi(fn(di, item) {
    if scatter_point(series, di, item, coord, polar~) is Some(point) {
      let e = @graphic.Element::circle_colored(
        point.x,
        point.y,
        series.symbol_size * 0.5,
        color,
      )
      Some(e)
    } else {
      None
    }
  })
  .filter_map(e => e) // no .enumerate() or .filter_mapi()
  .collect()
}

///|
pub fn render_scatters(
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
      Scatter => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let series_elems = render_scatter_series(series, color_idx, coord, polar~)
    elems.append(series_elems)
    color_idx = color_idx + 1
  }
  elems
}

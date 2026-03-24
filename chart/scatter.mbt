// Corresponds to: echarts/src/chart/scatter/ScatterView.ts

///|
/// Render a ScatterSeries to Circle scene graph elements.
pub fn render_scatter_series(
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
  let nd = series.data.length()
  let nd_f = if nd > 0 { nd.to_double() } else { 1.0 }
  let mut di = 0
  while di < nd {
    let item = series.data[di]
    di = di + 1
    match item.value {
      Null => ()
      Num(n) => {
        let px = if x_idx < coord.x_scales.length() {
          match coord.x_scales[x_idx] {
            Ordinal(s) => s.band_center(di - 1)
            Linear(s) =>
              s.range_min +
              (di - 1).to_double() * (s.range_max - s.range_min) / nd_f
          }
        } else {
          coord.bbox.x
        }
        let py = coord.num_y(y_idx, n)
        elems.push(
          @graphic.Element::circle_colored(
            px,
            py,
            series.symbol_size * 0.5,
            color,
          ),
        )
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
          elems.push(
            @graphic.Element::circle_colored(
              px,
              py,
              series.symbol_size * 0.5,
              color,
            ),
          )
        } else if arr.length() == 1 {
          let px = if x_idx < coord.x_scales.length() {
            match coord.x_scales[x_idx] {
              Ordinal(s) => s.band_center(di - 1)
              Linear(s) =>
                s.range_min +
                (di - 1).to_double() * (s.range_max - s.range_min) / nd_f
            }
          } else {
            coord.bbox.x
          }
          let py = coord.num_y(y_idx, arr[0])
          elems.push(
            @graphic.Element::circle_colored(
              px,
              py,
              series.symbol_size * 0.5,
              color,
            ),
          )
        }
    }
  }
  elems
}

///|
/// Render all scatter series from a ChartOption to scene graph elements.
pub fn render_scatters(
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
      Scatter => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let series_elems = render_scatter_series(series, color_idx, coord)
    let mut ei = 0
    while ei < series_elems.length() {
      elems.push(series_elems[ei])
      ei = ei + 1
    }
    color_idx = color_idx + 1
  }
  elems
}

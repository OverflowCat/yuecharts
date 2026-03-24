///|
/// Render a BarSeries to Rect scene graph elements.
pub fn render_bar_series(
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
  let base_y = coord.bbox.y + coord.bbox.height
  if x_idx >= coord.x_scales.length() {
    return elems
  }
  match coord.x_scales[x_idx] {
    Ordinal(s) => {
      let bar_w = s.band_width()
      let nd = series.data.length()
      let mut di = 0
      while di < nd {
        let item = series.data[di]
        di = di + 1
        // Use category at this index
        let cat_px = if di - 1 < s.categories.length() {
          s.band_center(di - 1)
        } else {
          coord.bbox.x
        }
        let bar_x = cat_px - bar_w * 0.5
        let value = match item.value {
          Num(n) => n
          Vec(arr) => if arr.length() > 1 { arr[1] } else { 0.0 }
          Null => 0.0
        }
        let top_y = coord.num_y(y_idx, value)
        let bar_h = base_y - top_y
        if bar_h > 0.0 {
          elems.push(
            @graphic.Element::rect_colored(
              bar_x,
              top_y,
              bar_w * 0.8,
              bar_h,
              color,
            ),
          )
        }
      }
    }
    Linear(s) => {
      // For linear x-axis, use data x values
      let nd = series.data.length()
      let bar_w = 10.0
      let mut di = 0
      while di < nd {
        let item = series.data[di]
        di = di + 1
        let (x_val, y_val) = match item.value {
          Num(n) => (di.to_double(), n)
          Vec(arr) =>
            if arr.length() > 1 {
              (arr[0], arr[1])
            } else if arr.length() > 0 {
              (di.to_double(), arr[0])
            } else {
              (di.to_double(), 0.0)
            }
          Null => (di.to_double(), 0.0)
        }
        let bar_x = s.data_to_pixel(x_val) - bar_w * 0.5
        let top_y = coord.num_y(y_idx, y_val)
        let bar_h = base_y - top_y
        if bar_h > 0.0 {
          elems.push(
            @graphic.Element::rect_colored(bar_x, top_y, bar_w, bar_h, color),
          )
        }
      }
    }
  }
  elems
}

///|
/// Render all bar series from a ChartOption to scene graph elements.
pub fn render_bars(
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
      Bar => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let series_elems = render_bar_series(series, color_idx, coord)
    let mut ei = 0
    while ei < series_elems.length() {
      elems.push(series_elems[ei])
      ei = ei + 1
    }
    color_idx = color_idx + 1
  }
  elems
}

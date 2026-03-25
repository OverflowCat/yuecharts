// Corresponds to: echarts/src/chart/bar/BarView.ts
// and echarts/src/layout/barGrid.ts (bar grouping / side-by-side layout)

///|
/// Render a BarSeries to Rect scene graph elements.
/// bar_index: 0-based index of this series among all bar series on the same x-axis.
/// total_bars: total number of bar series on the same x-axis.
pub fn render_bar_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  bar_index : Int,
  total_bars : Int,
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
      // ECharts barGrid.ts side-by-side layout:
      // categoryGapPercent = max(35 - n*4, 15)%
      // totalSpan = bandStep * (1 - categoryGapPercent/100)
      // barWidth = totalSpan / n / 1.3  (barGap default = 30%)
      // bar_i left edge = bandCenter - totalSpan/2 + i * barWidth * 1.3
      let band_step = s.band_step()
      let n = if total_bars > 0 { total_bars } else { 1 }
      let cat_gap_pct = if 35 - n * 4 > 15 {
        (35 - n * 4).to_double()
      } else {
        15.0
      }
      let total_span = band_step * (1.0 - cat_gap_pct / 100.0)
      let bar_w = total_span / n.to_double() / 1.3
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
        let bar_x = cat_px -
          total_span / 2.0 +
          bar_index.to_double() * bar_w * 1.3
        let value = match item.value {
          Num(n) => n
          Vec(arr) => if arr.length() > 1 { arr[1] } else { 0.0 }
          Null => 0.0
        }
        let top_y = coord.num_y(y_idx, value)
        let bar_h = base_y - top_y
        if bar_h > 0.0 {
          elems.push(
            @graphic.Element::rect_colored(bar_x, top_y, bar_w, bar_h, color),
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
  // --- Pre-compute bar counts per x-axis ---
  // Build an array bar_counts[xi] = number of bar series on x-axis xi.
  let mut color_idx = 0
  let max_xi = opt.x_axis.length()
  let bar_counts : Array[Int] = []
  let bar_rank_cursor : Array[Int] = []
  let mut xi_init = 0
  while xi_init <= max_xi {
    bar_counts.push(0)
    bar_rank_cursor.push(0)
    xi_init = xi_init + 1
  }
  let mut count_i = 0
  while count_i < opt.series.length() {
    let s = opt.series[count_i]
    count_i = count_i + 1
    match s.series_type {
      Bar => {
        let xi = if s.x_axis_index < max_xi { s.x_axis_index } else { 0 }
        bar_counts[xi] = bar_counts[xi] + 1
      }
      _ => ()
    }
  }
  // --- Render each bar series ---
  let mut sr = 0
  color_idx = 0
  while sr < opt.series.length() {
    let series = opt.series[sr]
    sr = sr + 1
    match series.series_type {
      Bar => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let xi = if series.x_axis_index < max_xi { series.x_axis_index } else { 0 }
    let total = bar_counts[xi]
    let rank = bar_rank_cursor[xi]
    bar_rank_cursor[xi] = rank + 1
    let series_elems = render_bar_series(series, color_idx, coord, rank, total)
    let mut ei = 0
    while ei < series_elems.length() {
      elems.push(series_elems[ei])
      ei = ei + 1
    }
    color_idx = color_idx + 1
  }
  elems
}

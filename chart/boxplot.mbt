// Corresponds to: echarts/src/chart/boxplot/ (BoxplotView.ts, boxplotLayout.ts)
//
// Data format per item: Vec([min, Q1, median, Q3, max])
// Rendered as: box (Q1–Q3) + median line + whiskers to min/max

///|
/// Render a single boxplot series to scene graph elements.
pub fn render_boxplot_series(
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
  let box_w = if x_idx < coord.x_scales.length() {
    match coord.x_scales[x_idx] {
      Ordinal(s) => s.band_width() * 0.5
      Linear(_) => 8.0
    }
  } else {
    8.0
  }
  let nd = series.data.length()
  let mut di = 0
  while di < nd {
    let item = series.data[di]
    di = di + 1
    match item.value {
      Vec(arr) if arr.length() >= 5 => {
        let v_min = arr[0]
        let q1 = arr[1]
        let median = arr[2]
        let q3 = arr[3]
        let v_max = arr[4]
        let cx = if x_idx < coord.x_scales.length() {
          match coord.x_scales[x_idx] {
            Ordinal(s) => s.band_center(di - 1)
            Linear(s) => s.data_to_pixel((di - 1).to_double())
          }
        } else {
          coord.bbox.x + (di - 1).to_double() * box_w * 3.0
        }
        // Pixel Y positions
        let y_min = coord.num_y(y_idx, v_min)
        let y_q1 = coord.num_y(y_idx, q1)
        let y_med = coord.num_y(y_idx, median)
        let y_q3 = coord.num_y(y_idx, q3)
        let y_max = coord.num_y(y_idx, v_max)
        // Box top = q3_y (higher value = lower pixel), box bottom = q1_y
        let box_top = if y_q3 < y_q1 { y_q3 } else { y_q1 }
        let box_bot = if y_q3 > y_q1 { y_q3 } else { y_q1 }
        let box_h = box_bot - box_top
        // Box: draw four border lines (top, bottom, left, right)
        let bx0 = cx - box_w * 0.5
        let bx1 = cx + box_w * 0.5
        let effective_bot = if box_h < 1.0 { box_top + 1.0 } else { box_bot }
        // Top edge
        elems.push(
          @graphic.Element::line_colored(bx0, box_top, bx1, box_top, color, 1.5),
        )
        // Bottom edge
        elems.push(
          @graphic.Element::line_colored(
            bx0, effective_bot, bx1, effective_bot, color, 1.5,
          ),
        )
        // Left edge
        elems.push(
          @graphic.Element::line_colored(
            bx0, box_top, bx0, effective_bot, color, 1.5,
          ),
        )
        // Right edge
        elems.push(
          @graphic.Element::line_colored(
            bx1, box_top, bx1, effective_bot, color, 1.5,
          ),
        )
        // Median line (bold, inside box)
        elems.push(
          @graphic.Element::line_colored(
            cx - box_w * 0.5,
            y_med,
            cx + box_w * 0.5,
            y_med,
            color,
            2.0,
          ),
        )
        // Upper whisker: from box_top (q3) to y_max (high value → lower y)
        elems.push(
          @graphic.Element::line_colored(cx, box_top, cx, y_max, color, 1.0),
        )
        // Upper cap
        elems.push(
          @graphic.Element::line_colored(
            cx - box_w * 0.25,
            y_max,
            cx + box_w * 0.25,
            y_max,
            color,
            1.0,
          ),
        )
        // Lower whisker: from box_bot (q1) to y_min (low value → higher y)
        elems.push(
          @graphic.Element::line_colored(cx, box_bot, cx, y_min, color, 1.0),
        )
        // Lower cap
        elems.push(
          @graphic.Element::line_colored(
            cx - box_w * 0.25,
            y_min,
            cx + box_w * 0.25,
            y_min,
            color,
            1.0,
          ),
        )
      }
      _ => ()
    }
  }
  elems
}

///|
/// Render all boxplot series from a ChartOption to scene graph elements.
pub fn render_boxplots(
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
      Boxplot => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let series_elems = render_boxplot_series(series, color_idx, coord)
    let mut ei = 0
    while ei < series_elems.length() {
      elems.push(series_elems[ei])
      ei = ei + 1
    }
    color_idx = color_idx + 1
  }
  elems
}

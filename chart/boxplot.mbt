/// <=> echarts/src/chart/boxplot/BoxplotView.ts
/// <=> echarts/src/chart/boxplot/boxplotLayout.ts
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
  let color = series.color.unwrap_or(@visual.palette_color(series_index))
  let any_highlighted = @visual.has_any_highlighted(series.data)
  let emphasis_style : @graphic.DisplayStateStyle = {
    fill: None,
    stroke: Some(@visual.lift_hex_color(color)),
    line_width: None,
    stroke_no_scale: false,
  }
  let blur_style : @graphic.DisplayStateStyle = {
    fill: None,
    stroke: None,
    line_width: None,
    stroke_no_scale: false,
  }
  // Use itemStyle.borderWidth if specified, otherwise default 1.5
  let line_w = series.geo_item_style.bind(s => s.border_width).unwrap_or(1.5)
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
    di += 1
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
        let top_edge = @graphic.Element::line_colored(
          bx0, box_top, bx1, box_top, color, line_w,
        )
        elems.push(
          if any_highlighted {
            top_edge
            .with_emphasis_style(emphasis_style)
            .with_blur_style(blur_style)
          } else {
            top_edge
          },
        )
        // Bottom edge
        let bottom_edge = @graphic.Element::line_colored(
          bx0, effective_bot, bx1, effective_bot, color, line_w,
        )
        elems.push(
          if any_highlighted {
            bottom_edge
            .with_emphasis_style(emphasis_style)
            .with_blur_style(blur_style)
          } else {
            bottom_edge
          },
        )
        // Left edge
        let left_edge = @graphic.Element::line_colored(
          bx0, box_top, bx0, effective_bot, color, line_w,
        )
        elems.push(
          if any_highlighted {
            left_edge
            .with_emphasis_style(emphasis_style)
            .with_blur_style(blur_style)
          } else {
            left_edge
          },
        )
        // Right edge
        let right_edge = @graphic.Element::line_colored(
          bx1, box_top, bx1, effective_bot, color, line_w,
        )
        elems.push(
          if any_highlighted {
            right_edge
            .with_emphasis_style(emphasis_style)
            .with_blur_style(blur_style)
          } else {
            right_edge
          },
        )
        // Median line (bold, inside box)
        let med_line = @graphic.Element::line_colored(
          cx - box_w * 0.5,
          y_med,
          cx + box_w * 0.5,
          y_med,
          color,
          line_w * 1.333,
        )
        elems.push(
          if any_highlighted {
            med_line
            .with_emphasis_style(emphasis_style)
            .with_blur_style(blur_style)
          } else {
            med_line
          },
        )
        // Upper whisker: from box_top (q3) to y_max (high value → lower y)
        let upper_whisker = @graphic.Element::line_colored(
          cx, box_top, cx, y_max, color, 1.0,
        )
        elems.push(
          if any_highlighted {
            upper_whisker
            .with_emphasis_style(emphasis_style)
            .with_blur_style(blur_style)
          } else {
            upper_whisker
          },
        )
        // Upper cap
        let upper_cap = @graphic.Element::line_colored(
          cx - box_w * 0.25,
          y_max,
          cx + box_w * 0.25,
          y_max,
          color,
          1.0,
        )
        elems.push(
          if any_highlighted {
            upper_cap
            .with_emphasis_style(emphasis_style)
            .with_blur_style(blur_style)
          } else {
            upper_cap
          },
        )
        // Lower whisker: from box_bot (q1) to y_min (low value → higher y)
        let lower_whisker = @graphic.Element::line_colored(
          cx, box_bot, cx, y_min, color, 1.0,
        )
        elems.push(
          if any_highlighted {
            lower_whisker
            .with_emphasis_style(emphasis_style)
            .with_blur_style(blur_style)
          } else {
            lower_whisker
          },
        )
        // Lower cap
        let lower_cap = @graphic.Element::line_colored(
          cx - box_w * 0.25,
          y_min,
          cx + box_w * 0.25,
          y_min,
          color,
          1.0,
        )
        elems.push(
          if any_highlighted {
            lower_cap
            .with_emphasis_style(emphasis_style)
            .with_blur_style(blur_style)
          } else {
            lower_cap
          },
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

  let mut color_idx = 0
  for si, _ in opt.series {
    let series = opt.series[si]
    match series.series_type {
      Boxplot => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    elems.append(render_boxplot_series(series, color_idx, coord))
    color_idx = color_idx + 1
  }
  elems
}

// Corresponds to: echarts/src/chart/funnel/FunnelView.ts
//                  echarts/src/chart/funnel/funnelLayout.ts
//
// Funnel chart renderer.
//
// Layout algorithm (funnelLayout.ts):
//   sort = 'descending' (default): largest item at top
//   orient = 'vertical' (default)
//   minSize = '0%', maxSize = '100%' of viewWidth
//   funnelAlign = 'center' (default)
//   gap = 0 (default pixel gap between items)
//   viewRect: uses ECharts box layout; we default to chart bounds shrunk by margins
//     left=80, right=60, top=60, bottom=60 (matches grid defaults)
//
// For each item (sorted descending by value):
//   itemHeight = viewHeight / itemCount  (no gap in simplest case)
//   itemWidth  = linearMap(value, [min,max], [minSizePx, maxSizePx])
//   trapezoid top   = [cx - topW/2,    y_offset]
//                     [cx + topW/2,    y_offset]
//   trapezoid bottom= [cx - bottomW/2, y_offset + itemH]
//                     [cx + bottomW/2, y_offset + itemH]
//   points order: top-left, top-right, bottom-right, bottom-left (for polygon)
//
// Note: the "bottom" width of item[i] = "top" width of item[i+1].
//       For the last item, top == bottom (rectangle).

///|
/// Linear mapping: value in [src_lo, src_hi] → [dst_lo, dst_hi], clamped.
fn linear_map(
  value : Double,
  src_lo : Double,
  src_hi : Double,
  dst_lo : Double,
  dst_hi : Double,
) -> Double {
  if src_hi <= src_lo {
    return dst_lo
  }
  let t = (value - src_lo) / (src_hi - src_lo)
  let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
  dst_lo + t_clamped * (dst_hi - dst_lo)
}

///|
/// Render all funnel series.
pub fn render_funnels(
  opt : @option.ChartOption,
  _coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut color_idx = 0
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si = si + 1
    match series.series_type {
      Funnel => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let series_elems = render_funnel_series(
      series,
      color_idx,
      opt.width,
      opt.height,
    )
    let mut i = 0
    while i < series_elems.length() {
      elems.push(series_elems[i])
      i = i + 1
    }
    color_idx = color_idx + 1
  }
  elems
}

///|
/// Render a single funnel series.
pub fn render_funnel_series(
  series : @option.SeriesOption,
  series_index : Int,
  chart_width : Double,
  chart_height : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let nd = series.data.length()
  if nd == 0 {
    return elems
  }

  // --- View rect (matches ECharts box layout defaults for funnel) ---
  // Observed from ECharts 6 output: left=80, right=80, top=60, bottom=65
  let margin_left = 80.0
  let margin_right = 80.0
  let margin_top = 60.0
  let margin_bottom = 65.0
  let view_x = margin_left
  let view_y = margin_top
  let view_w = chart_width - margin_left - margin_right
  let view_h = chart_height - margin_top - margin_bottom
  let cx = view_x + view_w / 2.0 // center x for centering trapezoids

  // Collect values and sort descending
  let values : Array[Double] = []
  let mut di = 0
  while di < nd {
    let item = series.data[di]
    di = di + 1
    let v = match item.value {
      Num(n) => n
      _ => 0.0
    }
    values.push(v)
  }

  // Sort indices descending by value (stable insertion sort)
  let indices : Array[Int] = []
  let mut ii = 0
  while ii < nd {
    indices.push(ii)
    ii = ii + 1
  }
  // Simple insertion sort descending
  let mut a = 0
  while a < indices.length() {
    let mut b = a
    while b > 0 && values[indices[b - 1]] < values[indices[b]] {
      let tmp = indices[b - 1]
      indices[b - 1] = indices[b]
      indices[b] = tmp
      b = b - 1
    }
    a = a + 1
  }

  // Data extent
  let v_min = 0.0
  let mut v_max = 0.0
  let mut fi = 0
  while fi < nd {
    if values[fi] > v_max {
      v_max = values[fi]
    }
    fi = fi + 1
  }

  // minSize=0%, maxSize=100% of viewWidth
  let min_size = 0.0
  let max_size = view_w

  // Gap between items (default 0 in ECharts for classic funnel)
  let gap = 0.0
  let item_h = (view_h - gap * (nd - 1).to_double()) / nd.to_double()

  // Width for each sorted item: linearMap(value, [v_min, v_max], [min_size, max_size])
  let widths : Array[Double] = []
  let mut wi = 0
  while wi < nd {
    let idx = indices[wi]
    let w = linear_map(values[idx], v_min, v_max, min_size, max_size)
    widths.push(w)
    wi = wi + 1
  }

  let mut ki = 0
  while ki < nd {
    let orig_idx = indices[ki]
    // Top width = widths[ki], bottom width = widths[ki+1] (or same if last)
    let top_w = widths[ki]
    let bot_w = if ki + 1 < nd { widths[ki + 1] } else { 0.0 }
    let y_top = view_y + ki.to_double() * (item_h + gap)
    let y_bot = y_top + item_h

    let pts = [
      @graphic.Point::new(cx - top_w / 2.0, y_top), // top-left
      @graphic.Point::new(cx + top_w / 2.0, y_top), // top-right
      @graphic.Point::new(cx + bot_w / 2.0, y_bot), // bottom-right
      @graphic.Point::new(cx - bot_w / 2.0, y_bot), // bottom-left
    ]
    let color_str = @visual.palette_color(series_index + orig_idx)
    let color = @graphic.Color::from_string(color_str).unwrap_or(@graphic.black)
    elems.push(
      @graphic.Element::polygon_fill_stroke(
        pts, color, @graphic.white, 1.0, 1.0,
      ),
    )
    // Label: name inside the trapezoid
    let label_name = match series.data[orig_idx].name {
      Some(n) => n
      None => ""
    }
    if label_name != "" {
      let lx = cx
      let ly = (y_top + y_bot) / 2.0
      elems.push(
        @graphic.Element::text_colored(
          lx,
          ly,
          label_name,
          @graphic.TextAnchor::middle(),
          @graphic.TextBaseline::middle(),
          "#ffffff",
        ),
      )
    }
    ki = ki + 1
  }
  elems
}

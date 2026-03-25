// Corresponds to: echarts/src/chart/gauge/GaugeView.ts
//                  echarts/src/chart/gauge/GaugeSeries.ts
//
// Gauge chart renderer.
//
// ECharts defaults (GaugeSeries.ts):
//   center = ['50%', '50%']
//   radius = '75%'
//   startAngle = 225 (option degrees)
//   endAngle = -45  (option degrees)
//   clockwise = true
//   min = 0, max = 100, splitNumber = 10
//   axisLine.lineStyle.width = 10 (gauge track width)
//   pointer.length = '60%' of r, pointer.width = 6
//   splitLine.length = 10, lineStyle.width = 3 (color = axisTick neutral70 #54555a)
//   axisTick.length = 6, lineStyle.width = 1
//
// Angle convention (GaugeView.ts):
//   angle_rad = -option_degrees / 180 * PI
//   x = cx + r * Math.cos(angle_rad)
//   y = cy + r * Math.sin(angle_rad)   ← PLUS sin (y-down screen coords, like pie chart)
//
// With these defaults:
//   startAngle_rad = -225/180*PI = -5PI/4  → lower-left → 7-8 o'clock ✓
//   endAngle_rad   = +45/180*PI  = +PI/4   → lower-right → 4-5 o'clock ✓
//   Arc spans 270° going counterclockwise (SVG sweep-flag=0, large-arc=1)

///|
/// Build SVG arc path segment.
/// angle_from and angle_to in radians (ECharts convention: x=cx+r*cos, y=cy+r*sin).
/// sweep: 0 = counterclockwise in screen (CCW), 1 = clockwise.
fn gauge_arc_path(
  cx : Double,
  cy : Double,
  r : Double,
  a0 : Double,
  a1 : Double,
  sweep : Int,
) -> String {
  let x0 = cx + r * @math.cos(a0)
  let y0 = cy + r * @math.sin(a0)
  let x1 = cx + r * @math.cos(a1)
  let y1 = cy + r * @math.sin(a1)
  let span = {
    let d = a1 - a0
    if d < 0.0 {
      -d
    } else {
      d
    }
  }
  let large = if span > @math.PI { 1 } else { 0 }
  "M \{r4(x0)} \{r4(y0)} A \{r4(r)} \{r4(r)} 0 \{large} \{sweep} \{r4(x1)} \{r4(y1)}"
}

///|
/// Format a gauge tick label value: integer if whole, else two decimal places.
fn fmt_gauge_val(v : Double) -> String {
  let iv = v.to_int()
  let fv = if v >= 0.0 { v - iv.to_double() } else { -(-v - (-iv).to_double()) }
  let diff = if fv < 0.0 { -fv } else { fv }
  if diff < 1.0e-6 {
    iv.to_string()
  } else {
    // two decimal places
    let scaled = (v * 100.0 + 0.5).to_int()
    let whole = scaled / 100
    let frac = {
      let f = scaled % 100
      if f < 0 {
        -f
      } else {
        f
      }
    }
    let frac_str = if frac < 10 { "0\{frac}" } else { frac.to_string() }
    "\{whole}.\{frac_str}"
  }
}

///|
/// Render all gauge series in the chart option.
pub fn render_gauges(opt : @option.ChartOption) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut si = 0
  let mut color_idx = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si = si + 1
    match series.series_type {
      @option.Gauge => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let gauge_elems = render_gauge_series(
      series,
      color_idx,
      opt.width,
      opt.height,
    )
    let mut i = 0
    while i < gauge_elems.length() {
      elems.push(gauge_elems[i])
      i = i + 1
    }
    color_idx = color_idx + 1
  }
  elems
}

///|
/// Render a single gauge series.
pub fn render_gauge_series(
  series : @option.SeriesOption,
  series_index : Int,
  chart_width : Double,
  chart_height : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let _ = series_index

  // --- Center ---
  let cx = if series.center.length() >= 1 {
    parse_pct_or_px(series.center[0], chart_width)
  } else {
    chart_width * 0.5
  }
  let cy = if series.center.length() >= 2 {
    parse_pct_or_px(series.center[1], chart_height)
  } else {
    chart_height * 0.5
  }

  // --- Radius (relative to min(width,height)/2) ---
  let ref_r = (if chart_width < chart_height {
      chart_width
    } else {
      chart_height
    }) /
    2.0
  let r = if series.radius.length() >= 1 {
    parse_pct_or_px(series.radius[0], ref_r)
  } else {
    ref_r * 0.75
  }

  // --- Angles in radians (ECharts convention: angle_rad = -option_deg * PI/180) ---
  // With y = cy + r*sin(angle_rad) (y-down screen coords):
  //   startAngle_option=225 → angle_rad=-5PI/4 → lower-left (7-8 o'clock) ✓
  //   endAngle_option=-45   → angle_rad=+PI/4  → lower-right (4-5 o'clock) ✓
  //   Arc goes CCW (positive angle direction) from start to end, spanning 270°.
  let start_rad = -(series.start_angle * @math.PI / 180.0)
  let end_rad_raw = -(series.end_angle * @math.PI / 180.0)
  // Normalize: ensure end_rad > start_rad so the arc spans correctly.
  let end_rad = if end_rad_raw > start_rad {
    end_rad_raw
  } else {
    end_rad_raw + 2.0 * @math.PI
  }
  let angle_span = end_rad - start_rad

  // --- Value → percent → angle ---
  let min_v = series.min_val
  let max_v = series.max_val
  let value = if series.data.length() > 0 {
    match series.data[0].value {
      @option.Num(n) => n
      @option.Vec(arr) => if arr.length() > 0 { arr[0] } else { min_v }
      @option.Null => min_v
    }
  } else {
    min_v
  }
  let percent = if max_v > min_v {
    let p = (value - min_v) / (max_v - min_v)
    if p < 0.0 {
      0.0
    } else if p > 1.0 {
      1.0
    } else {
      p
    }
  } else {
    0.0
  }
  let value_rad = start_rad + angle_span * percent

  // --- Layout constants (GaugeSeries.ts defaults) ---
  let track_width = 10.0 // axisLine.lineStyle.width
  let track_r = r - track_width * 0.5
  let split_len = 10.0 // splitLine.length
  let tick_len = 6.0 // axisTick.length
  let label_gap = 25.0 // approx distance from inner track edge to label baseline
  let pointer_length = r * 0.6 // pointer.length = '60%'
  let split_n = if series.split_number > 0 { series.split_number } else { 10 }

  // --- ECharts default colors ---
  let track_bg_color = "#ebedf0" // tokens.color.neutral10 (track background)
  let split_color = "#54555a" // tokens.color.axisTick = neutral70
  let tick_color = "#b0b2b5" // tokens.color.axisTickMinor (approximate)
  let label_color = "#54555a" // tokens.color.axisLabel
  let progress_color = @visual.palette_color(0) // first palette color

  // --- 1. Background track arc (full gauge range, light gray) ---
  let bg_arc = gauge_arc_path(cx, cy, track_r, start_rad, end_rad, 0)
  elems.push(
    @graphic.Element::path_stroked_round(bg_arc, track_bg_color, track_width),
  )

  // --- 2. Progress arc (startAngle → valueAngle, palette color) ---
  if percent > 0.0 {
    let prog_arc = gauge_arc_path(cx, cy, track_r, start_rad, value_rad, 0)
    elems.push(
      @graphic.Element::path_stroked_round(
        prog_arc, progress_color, track_width,
      ),
    )
  }

  // --- 3. Split lines and labels ---
  // Split lines at (splitNumber + 1) equally-spaced angle positions.
  let mut ssi = 0
  while ssi <= split_n {
    let a = start_rad + angle_span * ssi.to_double() / split_n.to_double()
    let ux = @math.cos(a)
    let uy = @math.sin(a)
    // Line from outer rim inward
    let ox = cx + r * ux
    let oy = cy + r * uy
    let ix = cx + (r - split_len) * ux
    let iy = cy + (r - split_len) * uy
    elems.push(@graphic.Element::line_colored(ox, oy, ix, iy, split_color, 2.0))
    // Label
    let split_val = min_v +
      (max_v - min_v) * ssi.to_double() / split_n.to_double()
    let lx = cx + (r - split_len - label_gap) * ux
    let ly = cy + (r - split_len - label_gap) * uy
    elems.push(
      @graphic.Element::text_colored(
        lx,
        ly,
        fmt_gauge_val(split_val),
        @graphic.TextAnchor::middle(),
        @graphic.TextBaseline::middle(),
        label_color,
      ),
    )
    ssi = ssi + 1
  }

  // --- 4. Minor ticks (5 per split section) ---
  let minor_per_split = 5
  let minor_total = split_n * minor_per_split
  let mut ti = 0
  while ti <= minor_total {
    // Skip positions that coincide with split lines (every minor_per_split)
    if ti % minor_per_split == 0 {
      ti = ti + 1
      continue
    }
    let a = start_rad + angle_span * ti.to_double() / minor_total.to_double()
    let ux = @math.cos(a)
    let uy = @math.sin(a)
    let ox = cx + r * ux
    let oy = cy + r * uy
    let ix = cx + (r - tick_len) * ux
    let iy = cy + (r - tick_len) * uy
    elems.push(@graphic.Element::line_colored(ox, oy, ix, iy, tick_color, 1.0))
    ti = ti + 1
  }

  // --- 5. Pointer ---
  // Triangle needle: tip at value_rad direction, base at center (3px wide).
  let ptr_tip_x = cx + pointer_length * @math.cos(value_rad)
  let ptr_tip_y = cy + pointer_length * @math.sin(value_rad)
  let perp_angle = value_rad + @math.PI / 2.0
  let base_half_w = 3.0
  let px0 = cx + base_half_w * @math.cos(perp_angle)
  let py0 = cy + base_half_w * @math.sin(perp_angle)
  let px1 = cx - base_half_w * @math.cos(perp_angle)
  let py1 = cy - base_half_w * @math.sin(perp_angle)
  // Small back anchor opposite direction
  let back_x = cx - r * 0.1 * @math.cos(value_rad)
  let back_y = cy - r * 0.1 * @math.sin(value_rad)
  let ptr_d = "M \{r4(px0)} \{r4(py0)} L \{r4(ptr_tip_x)} \{r4(ptr_tip_y)} L \{r4(px1)} \{r4(py1)} L \{r4(back_x)} \{r4(back_y)} Z"
  elems.push(@graphic.Element::path_filled(ptr_d, progress_color, 1.0))

  // --- 6. Center anchor dot ---
  elems.push(@graphic.Element::circle_colored(cx, cy, 6.0, progress_color))
  elems.push(@graphic.Element::circle_colored(cx, cy, 3.0, "#ffffff"))

  // --- 7. Value label (center display) ---
  let val_label = fmt_gauge_val(value)
  let val_y = cy + r * 0.5
  elems.push(
    @graphic.Element::text_colored(
      cx,
      val_y,
      val_label,
      @graphic.TextAnchor::middle(),
      @graphic.TextBaseline::middle(),
      "#3c3c41",
    ),
  )

  elems
}

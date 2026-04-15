/// <=> echarts/src/chart/gauge/GaugeView.ts
/// <=> echarts/src/chart/gauge/GaugeSeries.ts
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
//   Gauge axisLine/progress is rendered as a ring sector like GaugeView.ts,
//   with outer SVG sweep-flag=1 and inner reverse arc sweep-flag=0.

///|
/// Build SVG sector path for the gauge axis line / progress ring.
/// Corresponds to the graphic.Sector path used in echarts/src/chart/gauge/GaugeView.ts.
fn gauge_sector_path(
  cx : Double,
  cy : Double,
  r0 : Double,
  r : Double,
  a0 : Double,
  a1 : Double,
) -> String {
  let outer_x0 = cx + r * @math.cos(a0)
  let outer_y0 = cy + r * @math.sin(a0)
  let outer_x1 = cx + r * @math.cos(a1)
  let outer_y1 = cy + r * @math.sin(a1)
  let span = {
    let d = a1 - a0
    if d < 0.0 {
      -d
    } else {
      d
    }
  }
  let large_arc = if span > @math.PI { 1 } else { 0 }
  let inner_x0 = cx + r0 * @math.cos(a0)
  let inner_y0 = cy + r0 * @math.sin(a0)
  let inner_x1 = cx + r0 * @math.cos(a1)
  let inner_y1 = cy + r0 * @math.sin(a1)
  "M \{r4(outer_x0)} \{r4(outer_y0)} A \{r4(r)} \{r4(r)} 0 \{large_arc} 1 \{r4(outer_x1)} \{r4(outer_y1)} L \{r4(inner_x1)} \{r4(inner_y1)} A \{r4(r0)} \{r4(r0)} 0 \{large_arc} 0 \{r4(inner_x0)} \{r4(inner_y0)} Z"
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
    si += 1
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
      i += 1
    }
    color_idx = color_idx + 1
  }
  elems
}

///|
/// Render a single gauge series.
/// Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderMain
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
  let start_rad = -(series.start_angle * @math.PI / 180.0)
  let end_rad_raw = -(series.end_angle * @math.PI / 180.0)
  let end_rad = if end_rad_raw > start_rad {
    end_rad_raw
  } else {
    end_rad_raw + 2.0 * @math.PI
  }
  let angle_span = end_rad - start_rad

  let min_v = series.min_val
  let max_v = series.max_val

  // --- Layout constants (GaugeSeries.ts defaults) ---
  let track_width = 10.0 // axisLine.lineStyle.width
  let track_inner_r = r - track_width
  let split_len = 10.0 // splitLine.length
  let tick_len = 6.0 // axisTick.length
  let label_gap = 25.0 // approx distance from inner track edge to label baseline
  let split_n = if series.split_number > 0 { series.split_number } else { 10 }

  // --- ECharts default colors ---
  let track_bg_color = "#e8ebf0"
  let split_color = "#54555a"
  let tick_color = "#b0b2b5"
  let label_color = "#54555a"

  // --- 1. Background track arc ---
  // GaugeView.ts: axisLine sector rendered as full range background.
  let bg_arc = gauge_sector_path(cx, cy, track_inner_r, r, start_rad, end_rad)
  elems.push(@graphic.Element::path_filled(bg_arc, track_bg_color, 1.0))

  // --- 2. Progress arcs (one per data item) ---
  // Corresponds to: GaugeView.ts _renderPointer createProgress()
  let data_count = series.data.length()
  if series.gauge_progress_show && data_count > 0 {
    // Render in reverse order so higher-value arcs appear on top (overlap mode)
    // Corresponds to: z2 = linearMap(value, [min, max], [100, 0]) in GaugeView.ts
    let prog_width = series.gauge_progress_width
    let mut di = data_count - 1
    while di >= 0 {
      let item = series.data[di]
      let value = match item.value {
        @option.Num(n) => n
        @option.Vec(arr) => if arr.length() > 0 { arr[0] } else { min_v }
        @option.DateValue(_, n) => n
        @option.Null => min_v
      }
      let pct = if max_v > min_v {
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
      if pct > 0.0 {
        let value_rad = start_rad + angle_span * pct
        // overlap=true: all arcs share the same r0..r band (just stacked by z2)
        // overlap=false: each arc gets a narrower sub-band
        let mut arc_r = r
        let mut arc_r0 = r - prog_width
        if series.gauge_progress_overlap {
          arc_r = r
          arc_r0 = r - prog_width
        } else {
          arc_r = r - di.to_double() * prog_width
          arc_r0 = r - (di.to_double() + 1.0) * prog_width
        }
        let prog_color = @visual.palette_color(di)
        let prog_arc = gauge_sector_path(
          cx, cy, arc_r0, arc_r, start_rad, value_rad,
        )
        elems.push(@graphic.Element::path_filled(prog_arc, prog_color, 1.0))
      }
      di -= 1
    }
  } else if data_count > 0 && not(series.gauge_progress_show) {
    // Legacy single-value progress (backwards compat when progress.show=false)
    let value = match series.data[0].value {
      @option.Num(n) => n
      @option.Vec(arr) => if arr.length() > 0 { arr[0] } else { min_v }
      @option.DateValue(_, n) => n
      @option.Null => min_v
    }
    let pct = if max_v > min_v {
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
    if pct > 0.0 {
      let value_rad = start_rad + angle_span * pct
      let prog_color = @visual.palette_color(0)
      let prog_arc = gauge_sector_path(
        cx, cy, track_inner_r, r, start_rad, value_rad,
      )
      elems.push(@graphic.Element::path_filled(prog_arc, prog_color, 1.0))
    }
  }

  // --- 3. Split lines and labels ---
  // Corresponds to: GaugeView.ts _renderTicks
  let mut ssi = 0
  while ssi <= split_n {
    let a = start_rad + angle_span * ssi.to_double() / split_n.to_double()
    let ux = @math.cos(a)
    let uy = @math.sin(a)
    let ox = cx + r * ux
    let oy = cy + r * uy
    let ix = cx + (r - split_len) * ux
    let iy = cy + (r - split_len) * uy
    elems.push(@graphic.Element::line_colored(ox, oy, ix, iy, split_color, 2.0))
    let split_val = min_v +
      (max_v - min_v) * ssi.to_double() / split_n.to_double()
    let lx = cx + (r - split_len - label_gap) * ux
    let ly = cy + (r - split_len - label_gap) * uy
    elems.push(
      @graphic.Element::text_colored(
        lx,
        ly,
        fmt_gauge_val(split_val),
        @graphic.TextAnchor::Middle,
        @graphic.TextBaseline::Middle,
        label_color,
      ),
    )
    ssi = ssi + 1
  }

  // --- 4. Minor ticks ---
  let minor_per_split = 5
  let minor_total = split_n * minor_per_split
  let mut ti = 0
  while ti <= minor_total {
    if ti % minor_per_split == 0 {
      ti += 1
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
    ti += 1
  }

  // --- 5. Pointer ---
  // For multi-item gauges the pointer aims at the first data item by convention.
  // Corresponds to: GaugeView.ts _renderPointer createPointer()
  let ptr_value = if data_count > 0 {
    match series.data[0].value {
      @option.Num(n) => n
      @option.Vec(arr) => if arr.length() > 0 { arr[0] } else { min_v }
      @option.DateValue(_, n) => n
      @option.Null => min_v
    }
  } else {
    min_v
  }
  let ptr_pct = if max_v > min_v {
    let p = (ptr_value - min_v) / (max_v - min_v)
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
  let value_rad = start_rad + angle_span * ptr_pct
  let pointer_length = r * 0.6
  let ptr_tip_x = cx + pointer_length * @math.cos(value_rad)
  let ptr_tip_y = cy + pointer_length * @math.sin(value_rad)
  let perp_angle = value_rad + @math.PI / 2.0
  let base_half_w = 3.0
  let px0 = cx + base_half_w * @math.cos(perp_angle)
  let py0 = cy + base_half_w * @math.sin(perp_angle)
  let px1 = cx - base_half_w * @math.cos(perp_angle)
  let py1 = cy - base_half_w * @math.sin(perp_angle)
  let back_x = cx - r * 0.1 * @math.cos(value_rad)
  let back_y = cy - r * 0.1 * @math.sin(value_rad)
  let ptr_d = "M \{r4(px0)} \{r4(py0)} L \{r4(ptr_tip_x)} \{r4(ptr_tip_y)} L \{r4(px1)} \{r4(py1)} L \{r4(back_x)} \{r4(back_y)} Z"
  let ptr_color = @visual.palette_color(0)
  elems.push(@graphic.Element::path_filled(ptr_d, ptr_color, 1.0))

  // --- 6. Anchor dot ---
  elems.push(@graphic.Element::circle_colored(cx, cy, 6.0, ptr_color))
  elems.push(@graphic.Element::circle_colored(cx, cy, 3.0, "#ffffff"))

  // --- 7. Per-item title and detail ---
  // Corresponds to: GaugeView.ts _renderTitleAndDetail
  let mut di = 0
  while di < data_count {
    let item = series.data[di]
    let value = match item.value {
      @option.Num(n) => n
      @option.Vec(arr) => if arr.length() > 0 { arr[0] } else { min_v }
      @option.DateValue(_, n) => n
      @option.Null => min_v
    }
    let item_color = @visual.palette_color(di)

    // Title text (item name)
    let title_oc : Array[String] = match item.title_offset_center {
      Some(oc) => oc
      None => series.gauge_title_offset_center
    }
    let title_x = if title_oc.length() >= 1 {
      cx + parse_pct_or_px(title_oc[0], r)
    } else {
      cx
    }
    let title_y = if title_oc.length() >= 2 {
      cy + parse_pct_or_px(title_oc[1], r)
    } else {
      cy
    }
    let item_name = item.name.unwrap_or("")
    if item_name != "" {
      elems.push(
        @graphic.Element::text_custom(
          title_x,
          title_y,
          item_name,
          @graphic.TextAnchor::Middle,
          @graphic.TextBaseline::Middle,
          item_color,
          series.gauge_title_font_size,
          "sans-serif",
          "normal",
        ),
      )
    }

    // Detail text (formatted value)
    let detail_oc : Array[String] = match item.detail_offset_center {
      Some(oc) => oc
      None => series.gauge_detail_offset_center
    }
    let detail_x = if detail_oc.length() >= 1 {
      cx + parse_pct_or_px(detail_oc[0], r)
    } else {
      cx
    }
    let detail_y = if detail_oc.length() >= 2 {
      cy + parse_pct_or_px(detail_oc[1], r)
    } else {
      cy
    }
    // Format the value using detail.formatter if set
    // Corresponds to: GaugeView.ts formatLabel(value, formatter)
    let val_str = fmt_gauge_val(value)
    let detail_text = match series.gauge_detail_formatter {
      Some(fmt) => fmt.replace(old="{value}", new=val_str)
      None => val_str
    }
    let detail_color = match series.gauge_detail_color {
      Some(c) => if c == "inherit" { item_color } else { c }
      None => item_color
    }
    elems.push(
      @graphic.Element::text_custom(
        detail_x,
        detail_y,
        detail_text,
        @graphic.TextAnchor::Middle,
        @graphic.TextBaseline::Middle,
        detail_color,
        series.gauge_detail_font_size,
        "sans-serif",
        "bold",
      ),
    )
    di += 1
  }

  elems
}

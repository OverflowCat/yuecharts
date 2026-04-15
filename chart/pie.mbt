/// <=> echarts/src/chart/pie/PieView.ts
/// <=> echarts/src/chart/pie/pieLayout.ts
//
// Pie / donut chart renderer.
//
// Mapping from ECharts pieLayout.ts:
//   startAngle = -seriesModel.get('startAngle') * RADIAN    (default: -90° = -π/2)
//   clockwise  = true (default)  → SVG sweep-flag = 1
//   unitRadian = 2π / sum
//   each slice: [currentAngle, currentAngle + value*unitRadian]
//
// Screen-coordinate arc formula (y increases downward):
//   x = cx + r * cos(angle)
//   y = cy + r * sin(angle)        ← note: PLUS (not minus) for screen coords
// At startAngle = -π/2: (cx, cy-r) = top centre of circle ✓
//
// SVG arc path for a sector [a0, a1] with outer radius R, inner radius R0:
//   If R0 == 0 (pie): "M cx cy L x0 y0 A R R 0 <large> 1 x1 y1 Z"
//   If R0 > 0 (donut):
//     "M x0 y0 A R R 0 <large> 1 x1 y1 L xi1 yi1 A R0 R0 0 <large> 0 xi0 yi0 Z"
//   where large = 1 if (a1-a0) > π else 0

///|
fn parse_pct_or_px(s : String, reference : Double) -> Double {
  if s.has_suffix("%") {
    let inner = s[:s.length() - 1]
    let r = try? @strconv.parse_double(inner.to_string())
    match r {
      Ok(v) => v / 100.0 * reference
      Err(_) => 0.0
    }
  } else {
    let r = try? @strconv.parse_double(s)
    match r {
      Ok(v) => v
      Err(_) => 0.0
    }
  }
}

///|
/// Round a Double to 4 decimal places for clean SVG output.
fn r4(v : Double) -> String {
  // Multiply by 10000, round, divide back, format
  let scaled = (v * 10000.0 + 0.5).to_int().to_double() / 10000.0
  scaled.to_string()
}

///|
/// Render all pie/donut series in the option to scene graph elements.
pub fn render_pies(
  opt : @option.ChartOption,
  _coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut color_idx = 0
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si += 1
    match series.series_type {
      Pie => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let series_elems = render_pie_series(
      series,
      color_idx,
      opt.width,
      opt.height,
    )
    let mut i = 0
    while i < series_elems.length() {
      elems.push(series_elems[i])
      i += 1
    }
    color_idx = color_idx + 1
  }
  elems
}

///|
/// Render a single pie series.
pub fn render_pie_series(
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

  // --- Parse center ---
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

  // --- Parse radius ---
  // ECharts: percentage relative to min(width, height) / 2
  let ref_r = (if chart_width < chart_height {
      chart_width
    } else {
      chart_height
    }) /
    2.0
  let r_inner = if series.radius.length() >= 1 {
    parse_pct_or_px(series.radius[0], ref_r)
  } else {
    0.0
  }
  let r_outer = if series.radius.length() >= 2 {
    parse_pct_or_px(series.radius[1], ref_r)
  } else if series.radius.length() == 1 {
    parse_pct_or_px(series.radius[0], ref_r)
  } else {
    ref_r * 0.75 // ECharts default: 75%
  }

  // --- Compute total ---
  let mut total = 0.0
  let mut di = 0
  while di < nd {
    let item = series.data[di]
    di += 1
    match item.value {
      Num(n) if n > 0.0 => total = total + n
      _ => ()
    }
  }
  if total <= 0.0 {
    // Empty-circle fallback: render a gray ring when there is no data.
    // Corresponds to: PieView.ts emptyCircle handling (emptyCircleStyle).
    let empty_color = "#e0e2e5"
    let empty_path = if r_inner <= 0.5 {
      "M \{r4(cx)} \{r4(cy - r_outer)} A \{r4(r_outer)} \{r4(r_outer)} 0 1 1 \{r4(cx - 0.001)} \{r4(cy - r_outer)} Z"
    } else {
      let ro = r_outer
      let ri = r_inner
      "M \{r4(cx)} \{r4(cy - ro)} A \{r4(ro)} \{r4(ro)} 0 1 1 \{r4(cx - 0.001)} \{r4(cy - ro)} Z M \{r4(cx)} \{r4(cy - ri)} A \{r4(ri)} \{r4(ri)} 0 1 0 \{r4(cx - 0.001)} \{r4(cy - ri)} Z"
    }
    elems.push(@graphic.Element::path_filled(empty_path, empty_color, 1.0))
    return elems
  }

  // --- ECharts defaults ---
  // startAngle option default = 90, converted: startAngle = -90 * π/180 = -π/2
  // clockwise = true → SVG sweep-flag = 1
  let start_angle = -@math.PI / 2.0 // = -90° in screen coords
  let pi2 = @math.PI * 2.0
  let selected_offset = series.pie_selected_offset

  let mut current_angle = start_angle

  let mut di2 = 0
  while di2 < nd {
    let item = series.data[di2]
    let slice_color = @visual.palette_color(series_index + di2)
    di2 = di2 + 1
    let value = match item.value {
      Num(n) if n > 0.0 => n
      _ => continue
    }
    let span = value / total * pi2
    let a0 = current_angle
    let a1 = current_angle + span
    current_angle = a1
    let mid_angle = (a0 + a1) / 2.0

    // selected offset: shift slice outward from center.
    // Corresponds to: PieView.ts PieSeriesModel selectedOffset.
    let is_selected = item.selected == Some(true)
    let off = if is_selected { selected_offset } else { 0.0 }
    let slice_cx = cx + off * @math.cos(mid_angle)
    let slice_cy = cy + off * @math.sin(mid_angle)

    let large_arc = if span > @math.PI { 1 } else { 0 }

    // Outer arc points (relative to possibly-offset slice center)
    let x0 = slice_cx + r_outer * @math.cos(a0)
    let y0 = slice_cy + r_outer * @math.sin(a0)
    let x1 = slice_cx + r_outer * @math.cos(a1)
    let y1 = slice_cy + r_outer * @math.sin(a1)

    let path_d = if r_inner <= 0.5 {
      // Full pie: M cx cy L x0 y0 A R R 0 large 1 x1 y1 Z
      "M \{r4(slice_cx)} \{r4(slice_cy)} L \{r4(x0)} \{r4(y0)} A \{r4(r_outer)} \{r4(r_outer)} 0 \{large_arc} 1 \{r4(x1)} \{r4(y1)} Z"
    } else {
      // Donut ring: outer arc forward, inner arc backward
      let xi0 = slice_cx + r_inner * @math.cos(a0)
      let yi0 = slice_cy + r_inner * @math.sin(a0)
      let xi1 = slice_cx + r_inner * @math.cos(a1)
      let yi1 = slice_cy + r_inner * @math.sin(a1)
      "M \{r4(x0)} \{r4(y0)} A \{r4(r_outer)} \{r4(r_outer)} 0 \{large_arc} 1 \{r4(x1)} \{r4(y1)} L \{r4(xi1)} \{r4(yi1)} A \{r4(r_inner)} \{r4(r_inner)} 0 \{large_arc} 0 \{r4(xi0)} \{r4(yi0)} Z"
    }

    elems.push(
      @graphic.Element::path_fill_stroke(
        path_d, slice_color, "#ffffff", 1.0, 1.0,
      ),
    )

    // Label: midpoint angle, outside the slice
    // Apply formatter: {a}=seriesName {b}=name {c}=value {d}=percent
    // <=> echarts/src/chart/pie/PieView.ts + dataFormat.ts getFormattedLabel
    let item_name = match item.name {
      Some(n) => n
      None => ""
    }
    let series_name = series.name.unwrap_or("")
    let value_str = if value.to_int().to_double() == value {
      value.to_int().to_string()
    } else {
      value.to_string()
    }
    let pct_raw = value / total * 100.0
    let pct_int = (pct_raw * 100.0).round().to_int()
    let pct_f = pct_int.to_double() / 100.0
    let percent_str = if pct_f.to_int().to_double() == pct_f {
      pct_f.to_int().to_string()
    } else {
      pct_f.to_string()
    }
    let label_text = @option.apply_label_formatter(
      series.label,
      series_name,
      item_name,
      value_str,
      Some(percent_str),
    )
    if label_text != "" {
      // labelLine (polyline from arc edge to label).
      // Corresponds to: PieView.ts LabelLine + pieLayout labelLineTarget.
      let line_r1 = r_outer + 6.0 // arc edge outward extension
      let line_r2 = r_outer + 20.0 // elbow point
      let elbow_x = slice_cx + line_r2 * @math.cos(mid_angle)
      let elbow_y = slice_cy + line_r2 * @math.sin(mid_angle)
      let edge_x = slice_cx + line_r1 * @math.cos(mid_angle)
      let edge_y = slice_cy + line_r1 * @math.sin(mid_angle)
      // Horizontal extension for label anchor
      let label_stub_len = 8.0
      let goes_right = @math.cos(mid_angle) >= 0.0
      let stub_x = elbow_x +
        (if goes_right { label_stub_len } else { -label_stub_len })
      let stub_y = elbow_y
      elems.push(
        @graphic.Element::line_colored(
          edge_x, edge_y, elbow_x, elbow_y, slice_color, 1.0,
        ),
      )
      elems.push(
        @graphic.Element::line_colored(
          elbow_x, elbow_y, stub_x, stub_y, slice_color, 1.0,
        ),
      )
      let label_r = r_outer + 20.0
      let lx = slice_cx +
        label_r * @math.cos(mid_angle) +
        (if goes_right {
          label_stub_len + 3.0
        } else {
          -(label_stub_len + 3.0)
        })
      let ly = slice_cy + label_r * @math.sin(mid_angle)
      // Anchor: left if right half, right if left half
      let anchor = if goes_right {
        @graphic.TextAnchor::Start
      } else {
        @graphic.TextAnchor::End
      }
      elems.push(
        @graphic.Element::text_colored(
          lx,
          ly,
          label_text,
          anchor,
          @graphic.TextBaseline::Middle,
          "#333333",
        ),
      )
    }
  }
  elems
}

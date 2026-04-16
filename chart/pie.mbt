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
    let r = try? @string.parse_double(inner.to_string())
    match r {
      Ok(v) => v / 100.0 * reference
      Err(_) => 0.0
    }
  } else {
    let r = try? @string.parse_double(s)
    match r {
      Ok(v) => v
      Err(_) => 0.0
    }
  }
}

///|
/// <=> echarts/src/util/number.ts:linearMap (subset)
fn pie_linear_map(
  value : Double,
  in_min : Double,
  in_max : Double,
  out_min : Double,
  out_max : Double,
) -> Double {
  let in_span = in_max - in_min
  if in_span == 0.0 {
    return out_min
  }
  out_min + (value - in_min) / in_span * (out_max - out_min)
}

///|
/// <=> echarts/src/util/layout.ts:getLayoutRect (subset for pie box layout)
fn pie_layout_value(value : String, total : Double) -> Double {
  if value == "center" ||
    value == "middle" ||
    value == "right" ||
    value == "bottom" {
    return 0.0 / 0.0
  }
  if value.has_suffix("%") {
    let pct = value[:value.length() - 1]
    let parsed = try? @string.parse_double(pct.to_string())
    match parsed {
      Ok(v) => v / 100.0 * total
      Err(_) => 0.0 / 0.0
    }
  } else {
    let parsed = try? @string.parse_double(value)
    match parsed {
      Ok(v) => v
      Err(_) => 0.0 / 0.0
    }
  }
}

///|
fn pie_layout_value_opt(value : String?, total : Double) -> Double {
  match value {
    Some(v) => pie_layout_value(v, total)
    None => 0.0 / 0.0
  }
}

///|
/// <=> echarts/src/util/layout.ts:getLayoutRect
fn pie_get_layout_rect(
  series : @option.SeriesOption,
  container : @graphic.BBox,
) -> @graphic.BBox {
  let container_width = container.width
  let container_height = container.height

  let mut left = pie_layout_value_opt(series.left, container_width)
  let mut top = pie_layout_value_opt(series.top, container_height)
  let right = pie_layout_value_opt(series.right, container_width)
  let bottom = pie_layout_value_opt(series.bottom, container_height)
  let mut width = pie_layout_value_opt(series.width, container_width)
  let mut height = pie_layout_value_opt(series.height, container_height)

  if width.is_nan() {
    width = container_width - right - left
  }
  if height.is_nan() {
    height = container_height - bottom - top
  }

  match series.left.unwrap_or(series.right.unwrap_or("")) {
    "center" => left = container_width / 2.0 - width / 2.0
    "right" => left = container_width - width - right
    _ => ()
  }
  match series.top.unwrap_or(series.bottom.unwrap_or("")) {
    "center" | "middle" => top = container_height / 2.0 - height / 2.0
    "bottom" => top = container_height - height - bottom
    _ => ()
  }

  if left.is_nan() {
    left = container_width - right - width
  }
  if top.is_nan() {
    top = container_height - bottom - height
  }

  left = if left.is_nan() { 0.0 } else { left }
  top = if top.is_nan() { 0.0 } else { top }
  if width.is_nan() {
    width = container_width - left - (if right.is_nan() { 0.0 } else { right })
  }
  if height.is_nan() {
    height = container_height -
      top -
      (if bottom.is_nan() { 0.0 } else { bottom })
  }

  @graphic.BBox::new(container.x + left, container.y + top, width, height)
}

///|
/// <=> echarts/src/core/CoordinateSystem.ts:getCoordForBoxCoordSys
///    + echarts/src/chart/pie/PieSeries.ts registerLayOutOnCoordSysUsage(getCoord2=center)
fn pie_parse_matrix_coord_value(value : String) -> @option.MatrixCoordValue {
  let parsed = try? @string.parse_int(value, base=10)
  match parsed {
    Ok(v) => @option.MatrixCoordValue::Locator(v)
    Err(_) => @option.MatrixCoordValue::Name(value)
  }
}

///|
/// <=> echarts/src/util/layout.ts:getViewRectAndCenterForCircleLayout
/// Matrix branch: when `center` is used as `coord2`, center equals refContainer center.
fn pie_resolve_view_rect_and_center(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
) -> (@graphic.BBox, Double, Double) {
  let full = @graphic.BBox::new(0.0, 0.0, opt.width, opt.height)

  if series.coordinate_system == Some("matrix") && series.center.length() >= 2 {
    match @coord.Matrix::build(opt) {
      Some(matrix) => {
        let x_coord = pie_parse_matrix_coord_value(series.center[0])
        let y_coord = pie_parse_matrix_coord_value(series.center[1])
        match (matrix.resolve_x(x_coord), matrix.resolve_y(y_coord)) {
          (Some(xi), Some(yi)) => {
            let cell_layout = matrix.data_to_layout(xi, yi, clamp=false)
            let ref_container = cell_layout.content_rect
            if !ref_container.x.is_nan() && !ref_container.y.is_nan() {
              let view_rect = pie_get_layout_rect(series, ref_container)
              return (
                view_rect,
                ref_container.center_x(),
                ref_container.center_y(),
              )
            }
          }
          _ => ()
        }
      }
      None => ()
    }
  }

  let view_rect = pie_get_layout_rect(series, full)
  let cx = if series.center.length() >= 1 {
    parse_pct_or_px(series.center[0], view_rect.width) + view_rect.x
  } else {
    view_rect.center_x()
  }
  let cy = if series.center.length() >= 2 {
    parse_pct_or_px(series.center[1], view_rect.height) + view_rect.y
  } else {
    view_rect.center_y()
  }
  (view_rect, cx, cy)
}

///|
/// Round a Double to 4 decimal places for clean SVG output.
fn r4(v : Double) -> String {
  // Multiply by 10000, round, divide back, format
  let scaled = (v * 10000.0 + 0.5).to_int().to_double() / 10000.0
  scaled.to_string()
}

///|
/// <=> echarts/src/chart/pie/pieLayout.ts
/// Compute clockwise/counterclockwise directed sweep in [0, 2π].
fn pie_directed_sweep(
  start_angle : Double,
  end_angle : Double,
  clockwise : Bool,
) -> Double {
  let pi2 = @math.PI * 2.0
  let mut delta = if clockwise {
    end_angle - start_angle
  } else {
    start_angle - end_angle
  }
  while delta < 0.0 {
    delta = delta + pi2
  }
  while delta > pi2 {
    delta = delta - pi2
  }
  delta
}

///|
/// <=> echarts/src/util/number.ts (percent precision rounding behavior subset)
fn pie_format_percent(value : Double, precision : Int) -> String {
  let p = if precision < 0 { 0 } else { precision }
  let mut scale = 1.0
  let mut i = 0
  while i < p {
    scale = scale * 10.0
    i = i + 1
  }
  let rounded = (value * scale).round() / scale
  if rounded.to_int().to_double() == rounded {
    rounded.to_int().to_string()
  } else {
    rounded.to_string()
  }
}

///|
/// Render all pie/donut series in the option to scene graph elements.
pub fn render_pies(
  opt : @option.ChartOption,
  _coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut color_idx = 0

  for si, _ in opt.series {
    let series = opt.series[si]
    match series.series_type {
      Pie => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let series_elems = render_pie_series(opt, series, color_idx)

    for i, _ in series_elems {
      elems.push(series_elems[i])
    }
    color_idx = color_idx + 1
  }
  elems
}

///|
/// Render a single pie series.
pub fn render_pie_series(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
  series_index : Int,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let nd = series.data.length()
  if nd == 0 {
    return elems
  }

  // --- Parse viewRect + center ---
  let (view_rect, cx, cy) = pie_resolve_view_rect_and_center(opt, series)

  // --- Parse radius ---
  // ECharts: percentage relative to min(viewRect.width, viewRect.height) / 2
  let ref_r = (if view_rect.width < view_rect.height {
      view_rect.width
    } else {
      view_rect.height
    }) /
    2.0
  let (r_inner, r_outer) = if series.radius.length() >= 2 {
    (
      parse_pct_or_px(series.radius[0], ref_r),
      parse_pct_or_px(series.radius[1], ref_r),
    )
  } else if series.radius.length() == 1 {
    // <=> echarts/src/util/layout.ts:getCircleLayout
    // scalar radius means [0, radius]
    (0.0, parse_pct_or_px(series.radius[0], ref_r))
  } else {
    (0.0, ref_r * 0.75)
  }

  let r_outer = if r_outer >= 0.0 { r_outer } else { 0.0 }
  let r_inner = if r_inner >= 0.0 {
    if r_inner <= r_outer {
      r_inner
    } else {
      r_outer
    }
  } else {
    0.0
  }

  // --- Compute totals ---
  let mut total_positive = 0.0
  let mut positive_count = 0
  let mut non_negative_count = 0
  let mut max_value = 0.0
  let mut di = 0
  while di < nd {
    let item = series.data[di]
    di += 1
    match item.value {
      Num(n) if n > 0.0 => {
        total_positive = total_positive + n
        positive_count = positive_count + 1
        non_negative_count = non_negative_count + 1
        if n > max_value {
          max_value = n
        }
      }
      Num(n) if n >= 0.0 => non_negative_count = non_negative_count + 1
      _ => ()
    }
  }

  let zero_sum_mode = total_positive <= 0.0 &&
    series.pie_still_show_zero_sum &&
    non_negative_count > 0

  if total_positive <= 0.0 && !zero_sum_mode {
    if !series.pie_show_empty_circle {
      return elems
    }
    // Empty-circle fallback: render a gray ring when there is no data.
    // Corresponds to: PieView.ts emptyCircle handling (emptyCircleStyle).
    let empty_color = series.pie_empty_circle_color.unwrap_or("#e0e2e5")
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

  // --- ECharts pie layout controls ---
  // startAngle/endAngle options are in degrees and converted by negative sign.
  let clockwise = series.clockwise
  let dir = if clockwise { 1.0 } else { -1.0 }
  let start_angle = -series.start_angle / 180.0 * @math.PI
  let end_angle = if series.end_angle.is_nan() {
    0.0 / 0.0
  } else {
    -series.end_angle / 180.0 * @math.PI
  }
  let pi2 = @math.PI * 2.0
  let selected_offset = series.pie_selected_offset
  let rose_type = series.pie_rose_type
  let min_angle_rad = if series.min_angle > 0.0 {
    series.min_angle / 180.0 * @math.PI
  } else {
    0.0
  }
  let pad_angle_rad = if series.pad_angle > 0.0 {
    series.pad_angle / 180.0 * @math.PI
  } else {
    0.0
  }
  let min_show_label_angle = if series.pie_min_show_label_angle > 0.0 {
    series.pie_min_show_label_angle
  } else {
    0.0
  }
  let rose_enabled = match rose_type {
    Some("radius") => true
    Some("area") => true
    _ => false
  }
  let rose_area_mode = rose_type == Some("area")
  let render_indices : Array[Int] = []
  let render_values : Array[Double] = []
  let angle_weights : Array[Double] = []
  let mut di2 = 0
  while di2 < nd {
    let item = series.data[di2]
    match item.value {
      Num(n) if n > 0.0 => {
        render_indices.push(di2)
        render_values.push(n)
        angle_weights.push(if rose_area_mode { 1.0 } else { n })
      }
      Num(n) if zero_sum_mode && n >= 0.0 => {
        render_indices.push(di2)
        render_values.push(n)
        angle_weights.push(1.0)
      }
      _ => ()
    }
    di2 = di2 + 1
  }

  if render_indices.length() == 0 {
    return elems
  }

  let total_weight = angle_weights.fold(init=0.0, fn(acc, v) { acc + v })
  let total_sweep = if end_angle.is_nan() {
    pi2
  } else {
    pie_directed_sweep(start_angle, end_angle, clockwise)
  }

  let n_slices = render_indices.length().to_double()
  let pad_total = if n_slices > 0.0 { pad_angle_rad * n_slices } else { 0.0 }
  let available_sweep = if total_sweep > pad_total {
    total_sweep - pad_total
  } else {
    0.0
  }
  let effective_min_angle = if n_slices > 0.0 &&
    min_angle_rad * n_slices > available_sweep {
    available_sweep / n_slices
  } else {
    min_angle_rad
  }

  let spans : Array[Double] = []
  for i, _ in angle_weights {
    let w = angle_weights[i]
    let raw = if total_weight > 0.0 {
      available_sweep * w / total_weight
    } else {
      0.0
    }
    spans.push(
      if raw >= effective_min_angle {
        raw
      } else {
        effective_min_angle
      },
    )
  }
  let span_sum = spans.fold(init=0.0, fn(acc, v) { acc + v })
  if span_sum > 0.0 {
    let scale = available_sweep / span_sum
    for i, _ in spans {
      spans[i] = spans[i] * scale
    }
  }

  let mut current_angle = start_angle

  for k, _ in render_indices {
    let data_idx = render_indices[k]
    let item = series.data[data_idx]
    let value = render_values[k]
    let span = spans[k]
    let slice_color = @visual.palette_color(series_index + data_idx)

    // <=> echarts/src/chart/pie/pieLayout.ts
    // r = roseType ? linearMap(value, [0, max], [r0, r]) : r
    let slice_r_outer = if rose_enabled && max_value > 0.0 {
      pie_linear_map(value, 0.0, max_value, r_inner, r_outer)
    } else {
      r_outer
    }
    let a0 = current_angle
    let a1 = current_angle + dir * span
    current_angle = a1 + dir * pad_angle_rad
    let mid_angle = (a0 + a1) / 2.0

    // selected offset: shift slice outward from center.
    // Corresponds to: PieView.ts PieSeriesModel selectedOffset.
    let is_selected = item.selected == Some(true)
    let off = if is_selected { selected_offset } else { 0.0 }
    let slice_cx = cx + off * @math.cos(mid_angle)
    let slice_cy = cy + off * @math.sin(mid_angle)

    let large_arc = if span > @math.PI { 1 } else { 0 }
    let outer_sweep = if clockwise { 1 } else { 0 }
    let inner_sweep = if clockwise { 0 } else { 1 }

    // Outer arc points (relative to possibly-offset slice center)
    let x0 = slice_cx + slice_r_outer * @math.cos(a0)
    let y0 = slice_cy + slice_r_outer * @math.sin(a0)
    let x1 = slice_cx + slice_r_outer * @math.cos(a1)
    let y1 = slice_cy + slice_r_outer * @math.sin(a1)

    let path_d = if r_inner <= 0.5 {
      // Full pie: M cx cy L x0 y0 A R R 0 large 1 x1 y1 Z
      "M \{r4(slice_cx)} \{r4(slice_cy)} L \{r4(x0)} \{r4(y0)} A \{r4(slice_r_outer)} \{r4(slice_r_outer)} 0 \{large_arc} \{outer_sweep} \{r4(x1)} \{r4(y1)} Z"
    } else {
      // Donut ring: outer arc forward, inner arc backward
      let xi0 = slice_cx + r_inner * @math.cos(a0)
      let yi0 = slice_cy + r_inner * @math.sin(a0)
      let xi1 = slice_cx + r_inner * @math.cos(a1)
      let yi1 = slice_cy + r_inner * @math.sin(a1)
      "M \{r4(x0)} \{r4(y0)} A \{r4(slice_r_outer)} \{r4(slice_r_outer)} 0 \{large_arc} \{outer_sweep} \{r4(x1)} \{r4(y1)} L \{r4(xi1)} \{r4(yi1)} A \{r4(r_inner)} \{r4(r_inner)} 0 \{large_arc} \{inner_sweep} \{r4(xi0)} \{r4(yi0)} Z"
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
    let pct_raw = if total_weight > 0.0 {
      angle_weights[k] / total_weight * 100.0
    } else {
      0.0
    }
    let percent_str = pie_format_percent(pct_raw, series.pie_percent_precision)
    let label_text = @option.apply_label_formatter(
      series.label,
      series_name,
      item_name,
      value_str,
      Some(percent_str),
    )
    if label_text != "" {
      let span_deg = span / @math.PI * 180.0
      if span_deg < min_show_label_angle {
        continue
      }
      let label_position = match series.label {
        Some({ position: Some(pos), .. }) => pos
        _ => "outside"
      }
      if label_position == "inside" ||
        label_position == "inner" ||
        label_position == "center" {
        let inside_r = if label_position == "center" {
          (r_inner + slice_r_outer) / 2.0
        } else {
          (r_inner + slice_r_outer) / 2.0
        }
        let lx = slice_cx + inside_r * @math.cos(mid_angle)
        let ly = slice_cy + inside_r * @math.sin(mid_angle)
        let normalized_label = label_text.replace(old="\\n", new="\n")
        let label_lines = normalized_label
          .split("\n")
          // .map(StringView::to_string)
          .collect()
        let line_height = 14.0
        for line_idx, line in label_lines {
          if line != "" {
            elems.push(
              @graphic.Element::text_colored(
                lx,
                ly + line_height * line_idx.to_double(),
                line,
                @graphic.TextAnchor::Middle,
                @graphic.TextBaseline::Middle,
                "#333333",
              ),
            )
          }
        }
        continue
      }

      // labelLine (polyline from arc edge to label).
      // Corresponds to: PieView.ts LabelLine + pieLayout labelLineTarget.
      let line_r1 = slice_r_outer + series.pie_label_line_length
      let line_r2 = line_r1 + series.pie_label_line_length2
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
      if series.pie_label_line_show {
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
      }
      let label_r = line_r2
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
      let normalized_label = label_text.replace(old="\\n", new="\n")
      let label_lines : Array[String] = normalized_label
        .split("\n")
        .map(StringView::to_string)
        .collect()
      let line_height = 14.0
      for line_idx, line in label_lines {
        if line != "" {
          let line_color = if line_idx == 0 { "#333333" } else { "#999999" }
          elems.push(
            @graphic.Element::text_colored(
              lx,
              ly + line_height * line_idx.to_double(),
              line,
              anchor,
              @graphic.TextBaseline::Middle,
              line_color,
            ),
          )
        }
      }
    }
  }
  elems
}

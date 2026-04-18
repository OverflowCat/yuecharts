// Corresponds to: echarts/src/component/axis/AxisView.ts
//                  echarts/src/component/axis/AxisBuilder.ts
//                  echarts/src/component/axis/AngleAxisView.ts
//                  echarts/src/component/axis/RadiusAxisView.ts
//                  echarts/src/component/axis/SingleAxisView.ts

///|
let axis_line_color : String = "#54555a"

///|
/// Apply an axisLabel string template formatter to a tick label.
/// Template uses {value} as the substitution variable.
/// <=> echarts/src/coord/axisHelper.ts:makeLabelFormatter (string branch)
fn apply_axis_label_fmt(formatter : String?, label : String) -> String {
  match formatter {
    Some(tpl) if tpl != "" => tpl.replace(old="{value}", new=label)
    _ => label
  }
}

///|
/// <=> echarts/src/scale/Time.ts:getFormattedLabel
fn axis_pad2(v : Int) -> String {
  if v < 10 {
    "0\{v}"
  } else {
    v.to_string()
  }
}

///|
/// <=> echarts/src/scale/Time.ts:getFormattedLabel
fn axis_format_time_hhmm_utc(ms : Double) -> String {
  let total_minutes = (ms / 60000.0).floor().to_int()
  let mins_of_day = (total_minutes % 1440 + 1440) % 1440
  let hh = mins_of_day / 60
  let mm = mins_of_day % 60
  "\{axis_pad2(hh)}:\{axis_pad2(mm)}"
}

///|
/// <=> echarts/src/coord/axisHelper.ts:makeLabelFormatter
fn axis_tick_label(
  ax : @option.AxisOption,
  raw_label : String,
  tick_value : Double,
) -> String {
  let label = if ax.axis_type == Time {
    axis_format_time_hhmm_utc(tick_value)
  } else {
    raw_label
  }
  apply_axis_label_fmt(ax.label_formatter, label)
}

///|
let polar_axis_split_line_color : String = "#dbdee4"

///|
fn has_cartesian_axis_series(opt : @option.ChartOption) -> Bool {
  let mut i = 0
  while i < opt.series.length() {
    let series = opt.series[i]
    match series.series_type {
      @option.Bar
      | @option.Line
      | @option.Lines
      | @option.PictorialBar
      | @option.Scatter
      | @option.EffectScatter
      | @option.Candlestick
      | @option.Boxplot =>
        if series.coordinate_system != Some("polar") &&
          series.coordinate_system != Some("geo") {
          return true
        }
      @option.Heatmap =>
        if series.coordinate_system != Some("calendar") {
          return true
        }
      _ => ()
    }
    i += 1
  }
  false
}

///|
fn r4(v : Double) -> String {
  ((v * 10000.0).round() / 10000.0).to_string()
}

///|
fn arc_path(
  cx : Double,
  cy : Double,
  r : Double,
  start_angle : Double,
  end_angle : Double,
) -> String {
  let x0 = cx + r * @math.cos(start_angle)
  let y0 = cy + r * @math.sin(start_angle)
  let x1 = cx + r * @math.cos(end_angle)
  let y1 = cy + r * @math.sin(end_angle)
  let large = if (end_angle - start_angle).abs() > @math.PI { 1 } else { 0 }
  "M \{r4(x0)} \{r4(y0)} A \{r4(r)} \{r4(r)} 0 \{large} 1 \{r4(x1)} \{r4(y1)}"
}

///|
fn ring_path(
  cx : Double,
  cy : Double,
  r0 : Double,
  r : Double,
  start_angle : Double,
  end_angle : Double,
) -> String {
  let x0 = cx + r * @math.cos(start_angle)
  let y0 = cy + r * @math.sin(start_angle)
  let x1 = cx + r * @math.cos(end_angle)
  let y1 = cy + r * @math.sin(end_angle)
  let xi0 = cx + r0 * @math.cos(start_angle)
  let yi0 = cy + r0 * @math.sin(start_angle)
  let xi1 = cx + r0 * @math.cos(end_angle)
  let yi1 = cy + r0 * @math.sin(end_angle)
  let large = if (end_angle - start_angle).abs() > @math.PI { 1 } else { 0 }
  "M \{r4(x0)} \{r4(y0)} A \{r4(r)} \{r4(r)} 0 \{large} 1 \{r4(x1)} \{r4(y1)} L \{r4(xi1)} \{r4(yi1)} A \{r4(r0)} \{r4(r0)} 0 \{large} 0 \{r4(xi0)} \{r4(yi0)} Z"
}

///|
fn axis_font_family(global_font_family : StringView?) -> StringView {
  global_font_family.unwrap_or("sans-serif")
}

///|
pub fn render_axes(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  global_font_family : StringView?,
  polars? : Array[@coord.Polar] = [],
  single? : @coord.Single? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  if has_cartesian_axis_series(opt) {
    opt.x_axis.eachi((i, ax) => {
      render_x_axis(ax, coord, i, elems, global_font_family)
    })
    opt.y_axis.eachi((j, ax) => {
      render_y_axis(ax, coord, j, elems, global_font_family)
    })
  }
  // Render all polar coordinate systems
  for polar in polars {
    render_polar_axes(polar, elems, global_font_family)
  }
  match single {
    Some(single_coord) =>
      render_single_axis(opt, single_coord, elems, global_font_family)
    None => ()
  }
  elems
}

///|
fn render_x_axis(
  ax : @option.AxisOption,
  coord : @coord.Cartesian2D,
  axis_index : Int,
  elems : Array[@graphic.Element],
  global_font_family : StringView?,
) -> Unit {
  let bbox = coord.bbox
  // echarts/src/component/axis/AxisBuilder.ts: axisLabel.color / fontSize
  let lbl_color = ax.axis_label_color.unwrap_or(axis_line_color)
  let lbl_size = ax.axis_label_font_size.unwrap_or(12.0)
  let pos = match ax.position {
    Some(Top) => bbox.y
    _ => bbox.y + bbox.height
  }
  // echarts/src/component/axis/SplitAreaView.ts — alternating background bands
  if ax.split_area_show && axis_index < coord.x_scales.length() {
    match coord.x_scales[axis_index] {
      Ordinal(s) => {
        let n = s.categories.length()
        let step = s.band_step()
        let mut bi = 0
        while bi < n {
          if bi % 2 == 0 {
            elems.push(
              @graphic.Element::rect_colored_opacity(
                bbox.x + bi.to_double() * step,
                bbox.y,
                step,
                bbox.height,
                "rgb(234,237,245)",
                0.5,
              ),
            )
          }
          bi += 1
        }
      }
      _ => ()
    }
  }
  elems.push(
    @graphic.Element::line_colored(
      bbox.x,
      pos,
      bbox.x + bbox.width,
      pos,
      axis_line_color,
      1.0,
    ),
  )
  if axis_index >= coord.x_scales.length() {
    return
  }
  match coord.x_scales[axis_index] {
    Ordinal(s) => {
      let ticks = s.ticks()
      let mut ti = 0
      while ti < ticks.length() {
        let tick = ticks[ti]
        ti += 1
        let px = tick.value
        let tick_y1 = if pos == bbox.y { pos - 4.0 } else { pos }
        let tick_y2 = if pos == bbox.y { pos } else { pos + 4.0 }
        elems.push(
          @graphic.Element::line_colored(
            px, tick_y1, px, tick_y2, axis_line_color, 1.0,
          ),
        )
        let label_y = if pos == bbox.y { pos - 8.0 } else { pos + 14.0 }
        let baseline = if pos == bbox.y {
          @graphic.TextBaseline::Bottom
        } else {
          @graphic.TextBaseline::Hanging
        }
        elems.push(
          @graphic.Element::text_custom(
            px,
            label_y,
            apply_axis_label_fmt(ax.label_formatter, tick.label),
            @graphic.TextAnchor::Middle,
            baseline,
            lbl_color,
            lbl_size,
            global_font_family |> axis_font_family,
            "normal",
          ),
        )
      }
    }
    Linear(s) => {
      let ticks = s.ticks(5)
      let mut ti = 0
      while ti < ticks.length() {
        let tick = ticks[ti]
        ti += 1
        let px = s.data_to_pixel(tick.value)
        let tick_y1 = if pos == bbox.y { pos - 4.0 } else { pos }
        let tick_y2 = if pos == bbox.y { pos } else { pos + 4.0 }
        elems.push(
          @graphic.Element::line_colored(
            px, tick_y1, px, tick_y2, axis_line_color, 1.0,
          ),
        )
        let label_y = if pos == bbox.y { pos - 8.0 } else { pos + 14.0 }
        let baseline : @graphic.TextBaseline = if pos == bbox.y {
          @graphic.TextBaseline::Bottom
        } else {
          @graphic.TextBaseline::Hanging
        }
        elems.push(
          @graphic.Element::text_custom(
            px,
            label_y,
            axis_tick_label(ax, tick.label, tick.value),
            @graphic.TextAnchor::Middle,
            baseline,
            lbl_color,
            lbl_size,
            axis_font_family(global_font_family),
            "normal",
          ),
        )
      }
    }
    BreakLinear(s) => {
      // <=> echarts/src/component/axis/AxisBuilder.ts (break tick rendering)
      let ticks = s.ticks(5)
      let mut ti = 0
      while ti < ticks.length() {
        let tick = ticks[ti]
        ti += 1
        let px = s.data_to_pixel(tick.value)
        let tick_y1 = if pos == bbox.y { pos - 4.0 } else { pos }
        let tick_y2 = if pos == bbox.y { pos } else { pos + 4.0 }
        elems.push(
          @graphic.Element::line_colored(
            px, tick_y1, px, tick_y2, axis_line_color, 1.0,
          ),
        )
        let label_y = if pos == bbox.y { pos - 8.0 } else { pos + 14.0 }
        let baseline : @graphic.TextBaseline = if pos == bbox.y {
          @graphic.TextBaseline::Bottom
        } else {
          @graphic.TextBaseline::Hanging
        }
        elems.push(
          @graphic.Element::text_custom(
            px,
            label_y,
            axis_tick_label(ax, tick.label, tick.value),
            @graphic.TextAnchor::Middle,
            baseline,
            lbl_color,
            lbl_size,
            axis_font_family(global_font_family),
            "normal",
          ),
        )
      }
    }
  }
}

///|
fn render_y_axis(
  ax : @option.AxisOption,
  coord : @coord.Cartesian2D,
  axis_index : Int,
  elems : Array[@graphic.Element],
  global_font_family : StringView?,
) -> Unit {
  let bbox = coord.bbox
  // echarts/src/component/axis/AxisBuilder.ts: axisLabel.color / fontSize
  let lbl_color = ax.axis_label_color.unwrap_or(axis_line_color)
  let lbl_size = ax.axis_label_font_size.unwrap_or(12.0)
  let pos = match ax.position {
    Some(Right) => bbox.x + bbox.width
    _ => bbox.x
  }
  elems.push(
    @graphic.Element::line_colored(
      pos,
      bbox.y,
      pos,
      bbox.y + bbox.height,
      axis_line_color,
      1.0,
    ),
  )
  if axis_index >= coord.y_scales.length() {
    return
  }
  match coord.y_scales[axis_index] {
    Ordinal(s) => {
      let ticks = s.ticks()
      let mut ti = 0
      while ti < ticks.length() {
        let tick = ticks[ti]
        ti += 1
        let py = tick.value
        let tick_x1 = if pos == bbox.x { pos - 4.0 } else { pos }
        let tick_x2 = if pos == bbox.x { pos } else { pos + 4.0 }
        elems.push(
          @graphic.Element::line_colored(
            tick_x1, py, tick_x2, py, axis_line_color, 1.0,
          ),
        )
        let label_x = if pos == bbox.x { pos - 8.0 } else { pos + 8.0 }
        let anchor = if pos == bbox.x {
          @graphic.TextAnchor::End
        } else {
          @graphic.TextAnchor::Start
        }
        elems.push(
          @graphic.Element::text_custom(
            label_x,
            py,
            apply_axis_label_fmt(ax.label_formatter, tick.label),
            anchor,
            @graphic.TextBaseline::Middle,
            lbl_color,
            lbl_size,
            axis_font_family(global_font_family),
            "normal",
          ),
        )
      }
    }
    Linear(s) => {
      let ticks = s.ticks(5)
      let mut ti = 0
      while ti < ticks.length() {
        let tick = ticks[ti]
        ti += 1
        let py = s.data_to_pixel(tick.value)
        let tick_x1 = if pos == bbox.x { pos - 4.0 } else { pos }
        let tick_x2 = if pos == bbox.x { pos } else { pos + 4.0 }
        elems.push(
          @graphic.Element::line_colored(
            tick_x1, py, tick_x2, py, axis_line_color, 1.0,
          ),
        )
        let label_x = if pos == bbox.x { pos - 8.0 } else { pos + 8.0 }
        let anchor : @graphic.TextAnchor = if pos == bbox.x {
          @graphic.TextAnchor::End
        } else {
          @graphic.TextAnchor::Start
        }
        elems.push(
          @graphic.Element::text_custom(
            label_x,
            py,
            apply_axis_label_fmt(ax.label_formatter, tick.label),
            anchor,
            @graphic.TextBaseline::Middle,
            lbl_color,
            lbl_size,
            axis_font_family(global_font_family),
            "normal",
          ),
        )
      }
    }
    BreakLinear(s) => {
      // Render ticks and labels for a break-aware linear scale.
      // <=> echarts/src/component/axis/AxisBuilder.ts (break tick rendering)
      let ticks = s.ticks(5)
      let mut ti = 0
      while ti < ticks.length() {
        let tick = ticks[ti]
        ti += 1
        let py = s.data_to_pixel(tick.value)
        let tick_x1 = if pos == bbox.x { pos - 4.0 } else { pos }
        let tick_x2 = if pos == bbox.x { pos } else { pos + 4.0 }
        elems.push(
          @graphic.Element::line_colored(
            tick_x1, py, tick_x2, py, axis_line_color, 1.0,
          ),
        )
        let label_x = if pos == bbox.x { pos - 8.0 } else { pos + 8.0 }
        let anchor : @graphic.TextAnchor = if pos == bbox.x {
          @graphic.TextAnchor::End
        } else {
          @graphic.TextAnchor::Start
        }
        elems.push(
          @graphic.Element::text_custom(
            label_x,
            py,
            apply_axis_label_fmt(ax.label_formatter, tick.label),
            anchor,
            @graphic.TextBaseline::Middle,
            lbl_color,
            lbl_size,
            axis_font_family(global_font_family),
            "normal",
          ),
        )
      }
      // Render zigzag break markers.
      // <=> echarts/src/component/axis/axisBreakHelperImpl.ts rectCoordBuildBreakAxis
      let break_area = ax.break_area.unwrap_or(
        @option.BreakAreaOption::default(),
      )
      for brk in s.breaks {
        let py_min = s.data_to_pixel(brk.vmin)
        let py_max = s.data_to_pixel(brk.vmax)
        // On a Y axis, vmin has larger pixel Y (bottom) since Y is inverted.
        let y_top = py_min.min(py_max)
        let y_bot = py_min.max(py_max)
        render_y_axis_break(
          bbox, pos, ax, break_area, y_top, y_bot, elems, global_font_family,
        )
      }
    }
  }
}

///|
/// Background pass: render only break-boundary tick marks on the Y axis.
/// The polygon fill + zigzag polylines are deferred to render_break_polygon_overlay
/// (Foreground) so they paint OVER bar series.
/// <=> echarts/src/component/axis/axisBreakHelperImpl.ts addZigzagShapes background ticks
fn render_y_axis_break(
  bbox : @graphic.BBox,
  pos : Double, // x position of the axis line
  ax : @option.AxisOption,
  break_area : @option.BreakAreaOption,
  y_top : Double, // pixel y of the upper break boundary
  y_bot : Double, // pixel y of the lower break boundary
  elems : Array[@graphic.Element],
  global_font_family : StringView?,
) -> Unit {
  let _ = bbox
  let _ = break_area
  // NOTE: polygon fill + zigzag polylines are rendered in the Foreground pass
  // (render_break_polygon_overlay) so they paint OVER bars.
  // Here we only emit break-boundary tick marks.
  let tick_x1 = if pos == bbox.x { pos - 4.0 } else { pos }
  let tick_x2 = if pos == bbox.x { pos } else { pos + 4.0 }
  elems.push(
    @graphic.Element::line_colored(
      tick_x1, y_top, tick_x2, y_top, axis_line_color, 1.0,
    ),
  )
  elems.push(
    @graphic.Element::line_colored(
      tick_x1, y_bot, tick_x2, y_bot, axis_line_color, 1.0,
    ),
  )
  // Labels for break boundaries (show the vmin/vmax values)
  let _ = global_font_family
  let _ = ax
}

///|
/// Deterministic stand-in for the cached `Math.random()` sequence used by the
/// upstream axis break helper. This keeps static SVG output stable while still
/// producing irregular zigzag spacing.
/// <=> echarts/src/component/axis/axisBreakHelperImpl.ts:addZigzagShapes
fn break_zigzag_next_random(seed : Double) -> (Double, Double) {
  let next_seed = (seed * 1103515245.0 + 12345.0) % 2147483647.0
  (next_seed, next_seed / 2147483647.0)
}

///|
/// Build a deterministic seed for the static zigzag sequence.
/// <=> echarts/src/component/axis/axisBreakHelperImpl.ts:addZigzagShapes
fn break_zigzag_seed(
  bbox : @graphic.BBox,
  y_top : Double,
  y_bot : Double,
  break_area : @option.BreakAreaOption,
) -> Double {
  let raw = bbox.x * 13.0 +
    bbox.y * 17.0 +
    bbox.width * 19.0 +
    bbox.height * 23.0 +
    y_top * 29.0 +
    y_bot * 31.0 +
    break_area.zigzag_amplitude * 37.0 +
    break_area.zigzag_min_span * 41.0 +
    break_area.zigzag_max_span * 43.0
  if raw < 1.0 {
    1.0
  } else {
    raw
  }
}

///|
/// <=> echarts/src/component/axis/axisBreakHelperImpl.ts:addZigzagShapes
fn break_zigzag_polyline(
  points : Array[@graphic.Point],
  stroke_color : String,
) -> @graphic.Element {
  @graphic.Element::polyline_custom(points, stroke_color, 2.0, "round", "round")
}

///|
/// Foreground pass: draw the filled polygon + zigzag polylines for one break.
/// Must run AFTER bar/line series so the overlay covers bar segments in the break.
/// <=> echarts/src/component/axis/axisBreakHelperImpl.ts addZigzagShapes (Foreground z)
pub fn render_break_polygon_overlay(
  bbox : @graphic.BBox,
  y_top : Double,
  y_bot : Double,
  break_area : @option.BreakAreaOption,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let amp = break_area.zigzag_amplitude
  let min_span = if break_area.zigzag_min_span < 2.0 {
    2.0
  } else {
    break_area.zigzag_min_span
  }
  let max_span = if break_area.zigzag_max_span < min_span {
    min_span
  } else {
    break_area.zigzag_max_span
  }
  let fill = break_area.color.unwrap_or("#ffffff")
  let opacity = break_area.opacity
  let x_start = bbox.x
  let x_end = bbox.x + bbox.width
  let points_a : Array[@graphic.Point] = []
  let points_b : Array[@graphic.Point] = []
  let mut x = x_start
  let mut swap = true
  let mut first = true
  let mut seed = break_zigzag_seed(bbox, y_top, y_bot, break_area)
  while x <= x_end + 0.001 {
    let cx = if x > x_end { x_end } else { x }
    let ya : Double = if first || cx == x_end {
      y_top
    } else if swap {
      y_top - amp
    } else {
      y_top + amp
    }
    let yb : Double = if first || cx == x_end {
      y_bot
    } else if swap {
      y_bot + amp
    } else {
      y_bot - amp
    }
    points_a.push({ x: cx, y: ya })
    points_b.push({ x: cx, y: yb })
    first = false
    swap = !swap
    let next = break_zigzag_next_random(seed)
    seed = next.0
    let span = next.1 * (max_span - min_span) + min_span
    if cx >= x_end {
      break
    }
    x += span
  }
  let polygon_pts : Array[@graphic.Point] = []
  for p in points_a {
    polygon_pts.push(p)
  }
  let nb = points_b.length()
  let mut bi = nb - 1
  while bi >= 0 {
    polygon_pts.push(points_b[bi])
    bi -= 1
  }
  let fill_color = match @graphic.Color::from_string(fill) {
    Some(c) => c
    None => @graphic.white
  }
  elems.push(@graphic.Element::polygon_filled(polygon_pts, fill_color, opacity))
  elems.push(break_zigzag_polyline(points_a, "#aaaaaa"))
  elems.push(break_zigzag_polyline(points_b, "#aaaaaa"))
  elems
}

///|
/// Foreground: render break area overlays for all Y-axes that have breaks.
/// <=> echarts/src/component/axis/axisBreakHelperImpl.ts rectCoordBuildBreakAxis (overlay phase)
pub fn render_break_area_overlays(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut axis_index = 0
  while axis_index < opt.y_axis.length() {
    let ax = opt.y_axis[axis_index]
    if ax.breaks.length() > 0 && axis_index < coord.y_scales.length() {
      match coord.y_scales[axis_index] {
        BreakLinear(s) => {
          let bbox = coord.bbox
          let pos = if axis_index == 0 { bbox.x } else { bbox.x + bbox.width }
          let break_area = ax.break_area.unwrap_or(
            @option.BreakAreaOption::default(),
          )
          for brk in s.breaks {
            let py_min = s.data_to_pixel(brk.vmin)
            let py_max = s.data_to_pixel(brk.vmax)
            let y_top = py_min.min(py_max)
            let y_bot = py_min.max(py_max)
            let overlay = render_break_polygon_overlay(
              bbox, y_top, y_bot, break_area,
            )
            for e in overlay {
              elems.push(e)
            }
            // Also add tick marks on the right edge of the chart plot area
            let _ = pos
          }
        }
        _ => ()
      }
    }
    axis_index += 1
  }
  elems
}

///|
fn render_polar_axes(
  polar : @coord.Polar,
  elems : Array[@graphic.Element],
  global_font_family : StringView?,
) -> Unit {
  render_angle_axis(polar, elems, global_font_family)
  render_radius_axis(polar, elems, global_font_family)
}

///|
fn render_angle_axis(
  polar : @coord.Polar,
  elems : Array[@graphic.Element],
  global_font_family : StringView?,
) -> Unit {
  let axis = polar.angle_axis
  let area = polar.get_area()
  let angle_span = (polar.angle_axis.extent_end - polar.angle_axis.extent_start).abs()
  let is_full_circle = angle_span >= 360.0
  if area.r0 <= 0.0 {
    if is_full_circle {
      elems.push(
        @graphic.Element::circle_stroked(
          area.cx,
          area.cy,
          area.r,
          axis_line_color,
        ),
      )
    } else {
      elems.push(
        @graphic.Element::path_stroked(
          arc_path(area.cx, area.cy, area.r, area.start_angle, area.end_angle),
          axis_line_color,
        ),
      )
    }
  } else {
    elems.push(
      @graphic.Element::path_fill_stroke(
        ring_path(
          area.cx,
          area.cy,
          area.r0,
          area.r,
          area.start_angle,
          area.end_angle,
        ),
        "transparent",
        axis_line_color,
        1.0,
        1.0,
      ),
    )
  }
  let outer_r = area.r
  let ticks = axis.ticks()
  let mut i = 0
  while i < ticks.length() {
    let tick = ticks[i]
    let angle = tick.value
    let p0 = polar.coord_to_point(outer_r, angle)
    let p1 = polar.coord_to_point(outer_r + 4.0, angle)
    elems.push(
      @graphic.Element::line_colored(
        p0.x,
        p0.y,
        p1.x,
        p1.y,
        axis_line_color,
        1.0,
      ),
    )
    let sp0 = polar.coord_to_point(area.r0, angle)
    let sp1 = polar.coord_to_point(area.r, angle)
    elems.push(
      @graphic.Element::line_colored(
        sp0.x,
        sp0.y,
        sp1.x,
        sp1.y,
        polar_axis_split_line_color,
        1.0,
      ),
    )
    let label_pt = polar.coord_to_point(outer_r + 16.0, angle)
    let dx = label_pt.x - polar.cx
    let dy = label_pt.y - polar.cy
    let anchor : @graphic.TextAnchor = if dx.abs() / (outer_r + 16.0) < 0.3 {
      @graphic.TextAnchor::Middle
    } else if dx > 0.0 {
      @graphic.TextAnchor::Start
    } else {
      @graphic.TextAnchor::End
    }
    let baseline : @graphic.TextBaseline = if dy.abs() / (outer_r + 16.0) < 0.3 {
      @graphic.TextBaseline::Middle
    } else if dy > 0.0 {
      @graphic.TextBaseline::Top
    } else {
      @graphic.TextBaseline::Bottom
    }
    elems.push(
      @graphic.Element::text_custom(
        label_pt.x,
        label_pt.y,
        tick.label,
        anchor,
        baseline,
        axis_line_color,
        12.0,
        axis_font_family(global_font_family),
        "normal",
      ),
    )
    i += 1
  }
}

///|
fn render_radius_axis(
  polar : @coord.Polar,
  elems : Array[@graphic.Element],
  global_font_family : StringView?,
) -> Unit {
  let axis = polar.radius_axis
  let axis_angle = polar.angle_axis.extent_start
  let axis_radian = axis_angle / 180.0 * @math.PI
  let unit_x = @math.cos(axis_radian)
  let unit_y = -@math.sin(axis_radian)
  let tick_normal_x = unit_y
  let tick_normal_y = -unit_x
  let radius_ticks = axis.ticks()
  let mut i = 0
  while i < radius_ticks.length() {
    let tick = radius_ticks[i]
    let radius = tick.value
    let axis_pt = polar.coord_to_point(radius, axis_angle)
    let line_end : @graphic.Point = {
      x: axis_pt.x + tick_normal_x * 5.0,
      y: axis_pt.y + tick_normal_y * 5.0,
    }
    elems.push(
      @graphic.Element::line_colored(
        axis_pt.x,
        axis_pt.y,
        line_end.x,
        line_end.y,
        axis_line_color,
        1.0,
      ),
    )
    let label_pt : @graphic.Point = {
      x: axis_pt.x + tick_normal_x * 8.0,
      y: axis_pt.y + tick_normal_y * 8.0,
    }
    let anchor : @graphic.TextAnchor = if tick_normal_x.abs() < 0.3 {
      @graphic.TextAnchor::Middle
    } else if tick_normal_x > 0.0 {
      @graphic.TextAnchor::Start
    } else {
      @graphic.TextAnchor::End
    }
    let baseline : @graphic.TextBaseline = if tick_normal_y.abs() < 0.3 {
      @graphic.TextBaseline::Middle
    } else if tick_normal_y > 0.0 {
      @graphic.TextBaseline::Top
    } else {
      @graphic.TextBaseline::Bottom
    }
    elems.push(
      @graphic.Element::text_custom(
        label_pt.x,
        label_pt.y,
        tick.label,
        anchor,
        baseline,
        axis_line_color,
        12.0,
        axis_font_family(global_font_family),
        "normal",
      ),
    )
    if radius > 0.0 {
      let angle_span = (polar.angle_axis.extent_end -
      polar.angle_axis.extent_start).abs()
      if angle_span >= 360.0 {
        elems.push(
          @graphic.Element::circle_stroked(
            polar.cx,
            polar.cy,
            radius,
            polar_axis_split_line_color,
          ),
        )
      } else {
        elems.push(
          @graphic.Element::path_stroked(
            arc_path(
              polar.cx,
              polar.cy,
              radius,
              -polar.angle_axis.extent_start / 180.0 * @math.PI,
              -polar.angle_axis.extent_end / 180.0 * @math.PI,
            ),
            polar_axis_split_line_color,
          ),
        )
      }
    }
    i += 1
  }
  let start = polar.coord_to_point(polar.radius_axis.extent_start, axis_angle)
  let end = polar.coord_to_point(polar.radius_axis.extent_end, axis_angle)
  elems.push(
    @graphic.Element::line_colored(
      start.x,
      start.y,
      end.x,
      end.y,
      axis_line_color,
      1.0,
    ),
  )
}

///|
fn single_axis_split_line(
  axis_option : @option.SingleAxisOption,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> @graphic.Element {
  let dash = if axis_option.split_line.line_type == "dashed" {
    [4.0, 2.0]
  } else {
    []
  }
  @graphic.Element::line_colored_dashed(
    x1,
    y1,
    x2,
    y2,
    polar_axis_split_line_color,
    1.0,
    dash,
    axis_option.split_line.opacity,
  )
}

///|
fn single_axis_tick_and_label(
  single_coord : @coord.Single,
  axis_option : @option.SingleAxisOption,
  layout : @coord.SingleLayout,
  tick : @coord.SingleTick,
  elems : Array[@graphic.Element],
  global_font_family : StringView?,
) -> Unit {
  let tick_dir = layout.tick_direction.to_double()
  let label_dir = layout.label_direction.to_double()
  let tick_length = axis_option.axis_tick.length
  if single_coord.orient == "horizontal" {
    let px = single_axis_value_to_pixel(single_coord, tick.value)
    if axis_option.axis_tick.show {
      elems.push(
        @graphic.Element::line_colored(
          px,
          layout.y,
          px,
          layout.y + tick_dir * tick_length,
          axis_line_color,
          axis_option.axis_tick.width,
        ),
      )
    }
    if axis_option.axis_label.show {
      let baseline : @graphic.TextBaseline = if label_dir < 0.0 {
        @graphic.TextBaseline::Bottom
      } else {
        @graphic.TextBaseline::Hanging
      }
      elems.push(
        @graphic.Element::text_custom(
          px,
          layout.y + label_dir * (tick_length + 4.0),
          tick.label,
          @graphic.TextAnchor::Middle,
          baseline,
          axis_line_color,
          12.0,
          axis_font_family(global_font_family),
          "normal",
        ),
      )
    }
  } else {
    let py = single_axis_value_to_pixel(single_coord, tick.value)
    if axis_option.axis_tick.show {
      elems.push(
        @graphic.Element::line_colored(
          layout.x,
          py,
          layout.x + tick_dir * tick_length,
          py,
          axis_line_color,
          axis_option.axis_tick.width,
        ),
      )
    }
    if axis_option.axis_label.show {
      let anchor : @graphic.TextAnchor = if label_dir < 0.0 {
        @graphic.TextAnchor::End
      } else {
        @graphic.TextAnchor::Start
      }
      elems.push(
        @graphic.Element::text_custom(
          layout.x + label_dir * (tick_length + 4.0),
          py,
          tick.label,
          anchor,
          @graphic.TextBaseline::Middle,
          axis_line_color,
          12.0,
          axis_font_family(global_font_family),
          "normal",
        ),
      )
    }
  }
}

///|
fn single_axis_value_to_pixel(
  single_coord : @coord.Single,
  value : Double,
) -> Double {
  let range = single_coord.max_val - single_coord.min_val
  if range == 0.0 {
    return if single_coord.orient == "horizontal" {
      single_coord.bbox.x + single_coord.bbox.width / 2.0
    } else {
      single_coord.bbox.y + single_coord.bbox.height / 2.0
    }
  }
  let t = (value - single_coord.min_val) / range
  let t_oriented = if single_coord.inverse { 1.0 - t } else { t }
  if single_coord.orient == "horizontal" {
    single_coord.bbox.x + t_oriented * single_coord.bbox.width
  } else {
    single_coord.bbox.y + (1.0 - t_oriented) * single_coord.bbox.height
  }
}

///|
fn render_single_axis(
  opt : @option.ChartOption,
  single_coord : @coord.Single,
  elems : Array[@graphic.Element],
  global_font_family : StringView?,
) -> Unit {
  if opt.single_axis.length() == 0 {
    return
  }
  let axis_option = opt.single_axis[0]
  let layout = single_coord.layout(axis_option)
  let (axis_x1, axis_y1, axis_x2, axis_y2) = if single_coord.orient ==
    "horizontal" {
    (
      single_coord.bbox.x,
      layout.y,
      single_coord.bbox.x + single_coord.bbox.width,
      layout.y,
    )
  } else {
    (
      layout.x,
      single_coord.bbox.y,
      layout.x,
      single_coord.bbox.y + single_coord.bbox.height,
    )
  }
  let ticks = single_coord.axis_ticks(7)
  let mut i = 0
  while i < ticks.length() {
    let tick = ticks[i]
    let pixel = single_axis_value_to_pixel(single_coord, tick.value)
    if axis_option.split_line.show {
      if single_coord.orient == "horizontal" {
        elems.push(
          single_axis_split_line(
            axis_option,
            pixel,
            single_coord.bbox.y,
            pixel,
            single_coord.bbox.y + single_coord.bbox.height,
          ),
        )
      } else {
        elems.push(
          single_axis_split_line(
            axis_option,
            single_coord.bbox.x,
            pixel,
            single_coord.bbox.x + single_coord.bbox.width,
            pixel,
          ),
        )
      }
    }
    single_axis_tick_and_label(
      single_coord, axis_option, layout, tick, elems, global_font_family,
    )
    i += 1
  }
  if axis_option.axis_line.show {
    elems.push(
      @graphic.Element::line_colored(
        axis_x1,
        axis_y1,
        axis_x2,
        axis_y2,
        axis_line_color,
        axis_option.axis_line.line_style.width,
      ),
    )
  }
}

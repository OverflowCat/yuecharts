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
fn axis_font_family(global_font_family : String?) -> String {
  match global_font_family {
    Some(font_family) => font_family
    None => "sans-serif"
  }
}

///|
pub fn render_axes(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  global_font_family : String?,
  polar? : @coord.Polar? = None,
  single? : @coord.Single? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  if has_cartesian_axis_series(opt) {
    let mut i = 0
    while i < opt.x_axis.length() {
      render_x_axis(opt.x_axis[i], coord, i, elems, global_font_family)
      i += 1
    }
    let mut j = 0
    while j < opt.y_axis.length() {
      render_y_axis(opt.y_axis[j], coord, j, elems, global_font_family)
      j += 1
    }
  }
  match polar {
    Some(p) => render_polar_axes(p, elems, global_font_family)
    None => ()
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
  global_font_family : String?,
) -> Unit {
  let bbox = coord.bbox
  let pos = match ax.position {
    Some(Top) => bbox.y
    _ => bbox.y + bbox.height
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
            axis_line_color,
            12.0,
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
            apply_axis_label_fmt(ax.label_formatter, tick.label),
            @graphic.TextAnchor::Middle,
            baseline,
            axis_line_color,
            12.0,
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
  global_font_family : String?,
) -> Unit {
  let bbox = coord.bbox
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
            axis_line_color,
            12.0,
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
            axis_line_color,
            12.0,
            axis_font_family(global_font_family),
            "normal",
          ),
        )
      }
    }
  }
}

///|
fn render_polar_axes(
  polar : @coord.Polar,
  elems : Array[@graphic.Element],
  global_font_family : String?,
) -> Unit {
  render_angle_axis(polar, elems, global_font_family)
  render_radius_axis(polar, elems, global_font_family)
}

///|
fn render_angle_axis(
  polar : @coord.Polar,
  elems : Array[@graphic.Element],
  global_font_family : String?,
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
  global_font_family : String?,
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
  global_font_family : String?,
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
  global_font_family : String?,
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

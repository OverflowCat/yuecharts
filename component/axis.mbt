// Corresponds to: echarts/src/component/axis/AxisView.ts
//                  echarts/src/component/axis/AxisBuilder.ts
//                  echarts/src/component/axis/AngleAxisView.ts
//                  echarts/src/component/axis/RadiusAxisView.ts

///|
let axis_line_color : String = "#54555a"

///|
let polar_axis_split_line_color : String = "#dbdee4"

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
pub fn render_axes(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut i = 0
  while i < opt.x_axis.length() {
    render_x_axis(opt.x_axis[i], coord, i, elems)
    i += 1
  }
  let mut j = 0
  while j < opt.y_axis.length() {
    render_y_axis(opt.y_axis[j], coord, j, elems)
    j += 1
  }
  match polar {
    Some(p) => render_polar_axes(p, elems)
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
          @graphic.Element::text_colored(
            px,
            label_y,
            tick.label,
            @graphic.TextAnchor::Middle,
            baseline,
            axis_line_color,
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
          @graphic.Element::text_colored(
            px,
            label_y,
            tick.label,
            @graphic.TextAnchor::Middle,
            baseline,
            axis_line_color,
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
          @graphic.Element::text_colored(
            label_x,
            py,
            tick.label,
            anchor,
            @graphic.TextBaseline::Middle,
            axis_line_color,
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
          @graphic.Element::text_colored(
            label_x,
            py,
            tick.label,
            anchor,
            @graphic.TextBaseline::Middle,
            axis_line_color,
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
) -> Unit {
  render_angle_axis(polar, elems)
  render_radius_axis(polar, elems)
}

///|
fn render_angle_axis(
  polar : @coord.Polar,
  elems : Array[@graphic.Element],
) -> Unit {
  let axis = polar.angle_axis
  let area = polar.get_area()
  if area.r0 <= 0.0 {
    elems.push(
      @graphic.Element::path_stroked(
        arc_path(area.cx, area.cy, area.r, area.start_angle, area.end_angle),
        axis_line_color,
      ),
    )
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
      @graphic.Element::text_colored(
        label_pt.x,
        label_pt.y,
        tick.label,
        anchor,
        baseline,
        axis_line_color,
      ),
    )
    i += 1
  }
}

///|
fn render_radius_axis(
  polar : @coord.Polar,
  elems : Array[@graphic.Element],
) -> Unit {
  let axis = polar.radius_axis
  let axis_angle = polar.angle_axis.extent_start
  let radius_ticks = axis.ticks()
  let mut i = 0
  while i < radius_ticks.length() {
    let tick = radius_ticks[i]
    let radius = tick.value
    let line_start = polar.coord_to_point(radius, axis_angle)
    let line_end = polar.coord_to_point(radius + 4.0, axis_angle)
    elems.push(
      @graphic.Element::line_colored(
        line_start.x,
        line_start.y,
        line_end.x,
        line_end.y,
        axis_line_color,
        1.0,
      ),
    )
    let label_pt = polar.coord_to_point(radius + 12.0, axis_angle)
    elems.push(
      @graphic.Element::text_colored(
        label_pt.x,
        label_pt.y,
        tick.label,
        @graphic.TextAnchor::Start,
        @graphic.TextBaseline::Middle,
        axis_line_color,
      ),
    )
    if radius > 0.0 {
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

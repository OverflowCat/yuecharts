// Corresponds to: echarts/src/component/axis/AxisView.ts
// and echarts/src/component/axis/AxisBuilder.ts

// Default axis colors from ECharts tokens (visual/tokens.ts):
//   axisLine / axisTick / axisLabel: tokens.color.neutral70 = #54555a

///|
let axis_line_color : String = "#54555a"

///|
/// Render all x-axes and y-axes to the scene graph.
pub fn render_axes(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut i = 0
  while i < opt.x_axis.length() {
    render_x_axis(opt.x_axis[i], coord, i, elems)
    i = i + 1
  }
  let mut j = 0
  while j < opt.y_axis.length() {
    render_y_axis(opt.y_axis[j], coord, j, elems)
    j = j + 1
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
  // Axis baseline
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
  // Ticks and labels
  if axis_index >= coord.x_scales.length() {
    return
  }
  match coord.x_scales[axis_index] {
    Ordinal(s) => {
      let ticks = s.ticks()
      let mut ti = 0
      while ti < ticks.length() {
        let tick = ticks[ti]
        ti = ti + 1
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
          @graphic.TextBaseline::bottom()
        } else {
          @graphic.TextBaseline::hanging()
        }
        elems.push(
          @graphic.Element::text_colored(
            px,
            label_y,
            tick.label,
            @graphic.TextAnchor::middle(),
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
        ti = ti + 1
        let px = s.data_to_pixel(tick.value)
        let tick_y1 = if pos == bbox.y { pos - 4.0 } else { pos }
        let tick_y2 = if pos == bbox.y { pos } else { pos + 4.0 }
        elems.push(
          @graphic.Element::line_colored(
            px, tick_y1, px, tick_y2, axis_line_color, 1.0,
          ),
        )
        let label_y = if pos == bbox.y { pos - 8.0 } else { pos + 14.0 }
        let baseline = if pos == bbox.y {
          @graphic.TextBaseline::bottom()
        } else {
          @graphic.TextBaseline::hanging()
        }
        elems.push(
          @graphic.Element::text_colored(
            px,
            label_y,
            tick.label,
            @graphic.TextAnchor::middle(),
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
  // Axis baseline
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
  // Ticks and labels
  if axis_index >= coord.y_scales.length() {
    return
  }
  match coord.y_scales[axis_index] {
    Ordinal(s) => {
      let ticks = s.ticks()
      let mut ti = 0
      while ti < ticks.length() {
        let tick = ticks[ti]
        ti = ti + 1
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
          @graphic.TextAnchor::end()
        } else {
          @graphic.TextAnchor::start()
        }
        elems.push(
          @graphic.Element::text_colored(
            label_x,
            py,
            tick.label,
            anchor,
            @graphic.TextBaseline::middle(),
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
        ti = ti + 1
        let py = s.data_to_pixel(tick.value)
        let tick_x1 = if pos == bbox.x { pos - 4.0 } else { pos }
        let tick_x2 = if pos == bbox.x { pos } else { pos + 4.0 }
        elems.push(
          @graphic.Element::line_colored(
            tick_x1, py, tick_x2, py, axis_line_color, 1.0,
          ),
        )
        let label_x = if pos == bbox.x { pos - 8.0 } else { pos + 8.0 }
        let anchor = if pos == bbox.x {
          @graphic.TextAnchor::end()
        } else {
          @graphic.TextAnchor::start()
        }
        elems.push(
          @graphic.Element::text_colored(
            label_x,
            py,
            tick.label,
            anchor,
            @graphic.TextBaseline::middle(),
            axis_line_color,
          ),
        )
      }
    }
  }
}

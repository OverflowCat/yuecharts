// Corresponds to: echarts/src/component/parallel/ParallelView.ts
//                  echarts/src/component/axis/ParallelAxisView.ts
//                  echarts/src/component/parallel/install.ts

///|
let parallel_component_axis_line_color : String = "#54555a"

///|
pub fn render_parallel_component(
  _opt : @option.ChartOption,
  parallel? : @coord.Parallel? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  match parallel {
    None => elems
    Some(coord) => {
      let mut i = 0
      while i < coord.axes.length() && i < coord.axis_layouts.length() {
        let axis = coord.axes[i]
        let layout = coord.axis_layouts[i]
        if axis.show {
          parallel_render_axis(axis, layout, coord, elems)
        }
        i += 1
      }
      elems
    }
  }
}

///|
fn parallel_render_axis(
  axis : @coord.ParallelAxis,
  layout : @coord.ParallelAxisLayout,
  parallel : @coord.Parallel,
  elems : Array[@graphic.Element],
) -> Unit {
  if parallel.layout == "vertical" {
    elems.push(
      @graphic.Element::line_colored(
        parallel.bbox.x,
        layout.position.y,
        parallel.bbox.x + parallel.bbox.width,
        layout.position.y,
        parallel_component_axis_line_color,
        1.0,
      ),
    )
    let ticks = axis.ticks()
    let mut i = 0
    while i < ticks.length() {
      let tick = ticks[i]
      let x = parallel_tick_coord(axis, tick, i)
      elems.push(
        @graphic.Element::line_colored(
          x,
          layout.position.y,
          x,
          layout.position.y + 4.0,
          parallel_component_axis_line_color,
          1.0,
        ),
      )
      elems.push(
        @graphic.Element::text_colored(
          x,
          layout.position.y + 12.0,
          tick.label,
          @graphic.TextAnchor::Middle,
          @graphic.TextBaseline::Hanging,
          parallel_component_axis_line_color,
        ),
      )
      i += 1
    }
    match axis.name {
      Some(name) =>
        elems.push(
          @graphic.Element::text_colored(
            parallel.bbox.x - 10.0,
            layout.position.y,
            name,
            @graphic.TextAnchor::End,
            @graphic.TextBaseline::Middle,
            parallel_component_axis_line_color,
          ),
        )
      None => ()
    }
  } else {
    elems.push(
      @graphic.Element::line_colored(
        layout.position.x,
        parallel.bbox.y,
        layout.position.x,
        parallel.bbox.y + parallel.bbox.height,
        parallel_component_axis_line_color,
        1.0,
      ),
    )
    let ticks = axis.ticks()
    let mut i = 0
    while i < ticks.length() {
      let tick = ticks[i]
      let y = parallel_tick_coord(axis, tick, i)
      elems.push(
        @graphic.Element::line_colored(
          layout.position.x,
          y,
          layout.position.x + 4.0,
          y,
          parallel_component_axis_line_color,
          1.0,
        ),
      )
      elems.push(
        @graphic.Element::text_colored(
          layout.position.x + 8.0,
          y,
          tick.label,
          @graphic.TextAnchor::Start,
          @graphic.TextBaseline::Middle,
          parallel_component_axis_line_color,
        ),
      )
      i += 1
    }
    match axis.name {
      Some(name) =>
        elems.push(
          @graphic.Element::text_colored(
            layout.position.x,
            parallel.bbox.y - 18.0,
            name,
            @graphic.TextAnchor::Middle,
            @graphic.TextBaseline::Hanging,
            parallel_component_axis_line_color,
          ),
        )
      None => ()
    }
  }
}

///|
fn parallel_tick_coord(
  axis : @coord.ParallelAxis,
  tick : @scale.Tick,
  _tick_index : Int,
) -> Double {
  match axis.scale {
    @coord.ParallelAxisScale::Linear(scale) => scale.data_to_pixel(tick.value)
    @coord.ParallelAxisScale::Ordinal(_) => tick.value
  }
}

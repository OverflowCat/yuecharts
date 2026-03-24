// Corresponds to: echarts/src/component/axis/axisSplitHelper.ts

///|
/// Render background grid lines for all y-axes.
pub fn render_grid_lines(coord : @coord.Cartesian2D) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let bbox = coord.bbox
  // Y-axis grid lines (horizontal)
  let mut i = 0
  while i < coord.y_scales.length() {
    match coord.y_scales[i] {
      Linear(s) => {
        let ticks = s.ticks(5)
        let mut ti = 0
        while ti < ticks.length() {
          let tick = ticks[ti]
          ti = ti + 1
          let py = s.data_to_pixel(tick.value)
          elems.push(
            @graphic.Element::line(bbox.x, py, bbox.x + bbox.width, py),
          )
        }
      }
      Ordinal(s) => {
        let ticks = s.ticks()
        let mut ti = 0
        while ti < ticks.length() {
          let tick = ticks[ti]
          ti = ti + 1
          let py = tick.value
          elems.push(
            @graphic.Element::line(bbox.x, py, bbox.x + bbox.width, py),
          )
        }
      }
    }
    i = i + 1
  }
  elems
}

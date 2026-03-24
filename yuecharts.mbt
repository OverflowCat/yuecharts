///|
/// Render an ECharts JSON option string to an SVG string.
/// Returns an error string with "ERROR: ..." prefix on failure.
pub fn render(json_str : String) -> String {
  let opt = try @option.parse(json_str) catch {
    err => return "ERROR: failed to parse JSON: \{err}"
  } noraise {
    res => res
  }
  let coord = @layout.build_cartesian(opt)
  let elems : Array[@graphic.Element] = []
  // Background grid lines
  let grid_elems = @component.render_grid_lines(coord)
  let mut i = 0
  while i < grid_elems.length() {
    elems.push(grid_elems[i])
    i = i + 1
  }
  // Axes
  let axis_elems = @component.render_axes(opt, coord)
  let mut j = 0
  while j < axis_elems.length() {
    elems.push(axis_elems[j])
    j = j + 1
  }
  // Series: bars
  let bar_elems = @chart.render_bars(opt, coord)
  let mut k = 0
  while k < bar_elems.length() {
    elems.push(bar_elems[k])
    k = k + 1
  }
  // Series: lines
  let line_elems = @chart.render_lines(opt, coord)
  let mut l = 0
  while l < line_elems.length() {
    elems.push(line_elems[l])
    l = l + 1
  }
  // Title
  match opt.title {
    Some(title) =>
      elems.push(@graphic.Element::text(opt.width * 0.5, 20.0, title.text))
    None => ()
  }
  let bg = match opt.background_color {
    Some(c) => @graphic.Color::from_hex(c)
    None => None
  }
  @svg.paint(elems, opt.width, opt.height, bg)
}

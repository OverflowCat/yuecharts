// Top-level module
// Corresponds to: echarts/src/echarts.ts (core rendering pipeline)
// and echarts/src/core/echarts.ts (init and render logic)

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
  // Series: heatmap (rendered before lines/bars so it sits behind)
  let heat_elems = @chart.render_heatmaps(opt, coord)
  let mut hi = 0
  while hi < heat_elems.length() {
    elems.push(heat_elems[hi])
    hi = hi + 1
  }
  // Series: candlestick
  let candle_elems = @chart.render_candlesticks(opt, coord)
  let mut cdi = 0
  while cdi < candle_elems.length() {
    elems.push(candle_elems[cdi])
    cdi = cdi + 1
  }
  // Series: boxplot
  let box_elems = @chart.render_boxplots(opt, coord)
  let mut bxi = 0
  while bxi < box_elems.length() {
    elems.push(box_elems[bxi])
    bxi = bxi + 1
  }
  // Series: lines
  let line_elems = @chart.render_lines(opt, coord)
  let mut l = 0
  while l < line_elems.length() {
    elems.push(line_elems[l])
    l = l + 1
  }
  // Series: scatter
  let scatter_elems = @chart.render_scatters(opt, coord)
  let mut sci = 0
  while sci < scatter_elems.length() {
    elems.push(scatter_elems[sci])
    sci = sci + 1
  }
  // Title component
  let title_elems = @component.render_title(opt)
  let mut ti = 0
  while ti < title_elems.length() {
    elems.push(title_elems[ti])
    ti = ti + 1
  }
  // Legend component
  let legend_elems = @component.render_legend(opt)
  let mut lei = 0
  while lei < legend_elems.length() {
    elems.push(legend_elems[lei])
    lei = lei + 1
  }
  let bg = match opt.background_color {
    Some(c) => @graphic.Color::from_hex(c)
    None => None
  }
  @svg.paint(elems, opt.width, opt.height, bg)
}

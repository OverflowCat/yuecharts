// Top-level module
// Corresponds to: echarts/src/echarts.ts (core rendering pipeline)
// and echarts/src/core/echarts.ts (init and render logic)

///|
/// Returns true if any series uses the Cartesian coordinate system.
fn has_cartesian_series(opt : @option.ChartOption) -> Bool {
  let mut i = 0
  while i < opt.series.length() {
    let s = opt.series[i]
    i += 1
    match s.series_type {
      @option.Bar
      | @option.Line
      | @option.PictorialBar
      | @option.Scatter
      | @option.EffectScatter
      | @option.Heatmap
      | @option.Candlestick
      | @option.Boxplot => return true
      _ => ()
    }
  }
  false
}

///|
fn append_elements(
  elems : Array[@graphic.Element],
  items : Array[@graphic.Element],
) -> Unit {
  let mut i = 0
  while i < items.length() {
    elems.push(items[i])
    i += 1
  }
}

///|
fn build_registry() -> @core.Registry {
  let registry = @core.Registry::new()
  @layout.install_all(registry)
  @chart.install_all(registry)
  @component.install_all(registry)
  registry
}

///|
fn has_registered_series_type(
  opt : @option.ChartOption,
  series_type : @option.SeriesType?,
) -> Bool {
  match series_type {
    None => true
    Some(target) => {
      let mut i = 0
      while i < opt.series.length() {
        if opt.series[i].series_type == target {
          return true
        }
        i += 1
      }
      false
    }
  }
}

///|
fn is_legend_selected(opt : @option.ChartOption, name : String?) -> Bool {
  match (name, opt.legend) {
    (Some(value), Some(lg)) => @option.LegendOption::is_selected(lg, value)
    _ => true
  }
}

///|
fn filter_series_data_by_legend(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
) -> @option.SeriesOption {
  let filtered : Array[@option.DataItem] = []
  let mut i = 0
  while i < series.data.length() {
    let item = series.data[i]
    if is_legend_selected(opt, item.name) {
      filtered.push(item)
    }
    i += 1
  }
  { ..series, data: filtered }
}

///|
fn filter_series_negative_values(
  series : @option.SeriesOption,
) -> @option.SeriesOption {
  let filtered : Array[@option.DataItem] = []
  let mut i = 0
  while i < series.data.length() {
    let item = series.data[i]
    let keep = match item.value {
      @option.Num(n) => n >= 0.0
      _ => true
    }
    if keep {
      filtered.push(item)
    }
    i += 1
  }
  { ..series, data: filtered }
}

///|
fn apply_processor_to_option(
  opt : @option.ChartOption,
  series_type : @option.SeriesType?,
  execution_key : String?,
) -> @option.ChartOption {
  let next_series : Array[@option.SeriesOption] = []
  let mut i = 0
  while i < opt.series.length() {
    let series = opt.series[i]
    let matches_type = match series_type {
      Some(target) => series.series_type == target
      None => true
    }
    let next = if matches_type {
      match execution_key {
        Some("data_filter") => filter_series_data_by_legend(opt, series)
        Some("negative_data_filter") => filter_series_negative_values(series)
        _ => series
      }
    } else {
      series
    }
    next_series.push(next)
    i += 1
  }
  { ..opt, series: next_series }
}

///|
fn new_flags(count : Int) -> Array[Bool] {
  let flags : Array[Bool] = []
  let mut i = 0
  while i < count {
    flags.push(false)
    i += 1
  }
  flags
}

///|
fn next_layout_index(
  registry : @core.Registry,
  opt : @option.ChartOption,
  visited : Array[Bool],
) -> Int? {
  let mut best_index = -1
  let mut best_priority = 0
  let mut i = 0
  while i < registry.layouts.length() {
    let registration = registry.layouts[i]
    if !visited[i] && has_registered_series_type(opt, registration.series_type) {
      if best_index == -1 || registration.priority < best_priority {
        best_index = i
        best_priority = registration.priority
      }
    }
    i += 1
  }
  if best_index == -1 {
    None
  } else {
    Some(best_index)
  }
}

///|
fn next_visual_index(
  registry : @core.Registry,
  opt : @option.ChartOption,
  visited : Array[Bool],
) -> Int? {
  let mut best_index = -1
  let mut best_priority = 0
  let mut i = 0
  while i < registry.visuals.length() {
    let registration = registry.visuals[i]
    if !visited[i] && has_registered_series_type(opt, registration.series_type) {
      if best_index == -1 || registration.priority < best_priority {
        best_index = i
        best_priority = registration.priority
      }
    }
    i += 1
  }
  if best_index == -1 {
    None
  } else {
    Some(best_index)
  }
}

///|
fn next_processor_index(
  registry : @core.Registry,
  opt : @option.ChartOption,
  visited : Array[Bool],
) -> Int? {
  let mut best_index = -1
  let mut best_priority = 0
  let mut i = 0
  while i < registry.processors.length() {
    let registration = registry.processors[i]
    if !visited[i] && has_registered_series_type(opt, registration.series_type) {
      if best_index == -1 || registration.priority < best_priority {
        best_index = i
        best_priority = registration.priority
      }
    }
    i += 1
  }
  if best_index == -1 {
    None
  } else {
    Some(best_index)
  }
}

///|
fn run_registered_processors(
  registry : @core.Registry,
  opt : @option.ChartOption,
) -> @option.ChartOption {
  let visited = new_flags(registry.processors.length())
  let mut current = opt
  let mut done = 0
  while done < registry.processors.length() {
    match next_processor_index(registry, current, visited) {
      None => done = registry.processors.length()
      Some(index) => {
        visited[index] = true
        done = done + 1
        let registration = registry.processors[index]
        current = apply_processor_to_option(
          current,
          registration.series_type,
          registration.execution_key,
        )
      }
    }
  }
  current
}

///|
fn run_registered_layouts(
  registry : @core.Registry,
  raw_opt : @option.ChartOption,
  opt : @option.ChartOption,
) -> @core.RenderContext {
  let mut coord = @layout.build_cartesian(opt)
  let mut calendar = @coord.Calendar::build(opt)
  let visited = new_flags(registry.layouts.length())
  let mut done = 0
  while done < registry.layouts.length() {
    match next_layout_index(registry, opt, visited) {
      None => done = registry.layouts.length()
      Some(index) => {
        visited[index] = true
        done = done + 1
        let registration = registry.layouts[index]
        match registration.execution_key {
          Some("build_cartesian") => coord = @layout.build_cartesian(opt)
          Some("build_calendar") => calendar = @coord.Calendar::build(opt)
          _ => ()
        }
      }
    }
  }
  @core.RenderContext::new(raw_opt, opt, coord, calendar)
}

///|
fn run_registered_visuals(
  registry : @core.Registry,
  opt : @option.ChartOption,
) -> String? {
  let visited = new_flags(registry.visuals.length())
  let mut aria_label = None
  let mut done = 0
  while done < registry.visuals.length() {
    match next_visual_index(registry, opt, visited) {
      None => done = registry.visuals.length()
      Some(index) => {
        visited[index] = true
        done = done + 1
        let registration = registry.visuals[index]
        match registration.execution_key {
          Some("aria_label") => aria_label = @visual.aria_label(opt)
          _ => ()
        }
      }
    }
  }
  aria_label
}

///|
fn render_registered_components(
  elems : Array[@graphic.Element],
  registry : @core.Registry,
  ctx : @core.RenderContext,
  stage : @core.ComponentRenderStage,
  has_cartesian : Bool,
) -> Unit {
  let mut i = 0
  while i < registry.components.length() {
    let registration = registry.components[i]
    i += 1
    let stage_matches = match registration.render_stage {
      Background => stage == @core.ComponentRenderStage::Background
      Foreground => stage == @core.ComponentRenderStage::Foreground
    }
    if !stage_matches {
      continue
    }
    if registration.requires_cartesian && !has_cartesian {
      continue
    }
    append_elements(elems, registration.view.render(ctx))
  }
}

///|
fn render_registered_charts(
  elems : Array[@graphic.Element],
  registry : @core.Registry,
  ctx : @core.RenderContext,
) -> Unit {
  let mut i = 0
  while i < registry.charts.length() {
    let registration = registry.charts[i]
    i += 1
    if !has_registered_series_type(ctx.option, Some(registration.series_type)) {
      continue
    }
    append_elements(elems, registration.view.render(ctx))
  }
}

///|
/// Render an ECharts JSON option string to an SVG string.
/// Returns an error string with "ERROR: ..." prefix on failure.
pub fn render(json_str : String) -> String {
  let opt = try @option.parse(json_str) catch {
    err => return "ERROR: failed to parse JSON: \{err}"
  } noraise {
    res => res
  }
  let registry = build_registry()
  let processed_opt = run_registered_processors(registry, opt)
  let ctx = run_registered_layouts(registry, opt, processed_opt)
  let aria_label = run_registered_visuals(registry, processed_opt)
  let elems : Array[@graphic.Element] = []
  let has_cartesian = has_cartesian_series(processed_opt)
  render_registered_components(
    elems,
    registry,
    ctx,
    @core.ComponentRenderStage::background(),
    has_cartesian,
  )
  render_registered_charts(elems, registry, ctx)
  render_registered_components(
    elems,
    registry,
    ctx,
    @core.ComponentRenderStage::foreground(),
    has_cartesian,
  )
  let bg = match processed_opt.background_color {
    Some(c) => @graphic.Color::from_hex(c)
    None => None
  }
  let accessibility = match aria_label {
    Some(label) =>
      Some(@svg.SvgAccessibility::new("img", Some(label), None, Some(label)))
    None => None
  }
  @svg.paint(
    elems,
    processed_opt.width,
    processed_opt.height,
    bg,
    accessibility,
  )
}

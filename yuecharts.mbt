// Top-level module
// Corresponds to: echarts/src/echarts.ts (core rendering pipeline)
// and echarts/src/core/echarts.ts (init and render logic)

///|
/// Returns true if any series uses the Cartesian coordinate system.
fn has_cartesian_series(opt : @option.ChartOption) -> Bool {
  for i, _ in opt.series {
    let s = opt.series[i]
    match s.series_type {
      @option.Bar
      | @option.Line
      | @option.Lines
      | @option.PictorialBar
      | @option.Scatter
      | @option.EffectScatter
      | @option.Candlestick
      | @option.Boxplot =>
        if s.coordinate_system != Some("polar") &&
          s.coordinate_system != Some("geo") {
          return true
        }
      @option.Heatmap =>
        if s.coordinate_system != Some("calendar") {
          if s.coordinate_system != Some("matrix") {
            return true
          }
        }
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
  for i, _ in items {
    elems.push(items[i])
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
/// Register a global geo map resource, compatible with `echarts.registerMap`.
pub fn register_map(
  map_name : String,
  geo_json : Json,
  special_areas : Array[@option.MapSpecialAreaOption],
) -> Unit {
  @coord.register_global_map(map_name, geo_json, special_areas)
}

///|
/// Get a registered geo map, compatible with `echarts.getMap`.
pub fn get_map(map_name : String) -> @coord.GeoMapForUser? {
  @coord.get_global_map_for_user(map_name)
}

///|
fn has_registered_series_type(
  opt : @option.ChartOption,
  series_type : @option.SeriesType?,
) -> Bool {
  match series_type {
    None => true
    Some(target) => {
      for i, _ in opt.series {
        if opt.series[i].series_type == target {
          return true
        }
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
  for i, _ in series.data {
    let item = series.data[i]
    if is_legend_selected(opt, item.name) {
      filtered.push(item)
    }
  }
  let filtered_links : Array[@option.DataItem] = []
  if series.series_type == @option.SeriesType::Chord {
    for item in series.link_data {
      let source_selected = is_legend_selected(opt, item.source)
      let target_selected = is_legend_selected(opt, item.target)
      if source_selected && target_selected {
        filtered_links.push(item)
      }
    }
  }
  {
    ..series,
    data: filtered,
    link_data: if series.series_type == @option.SeriesType::Chord {
      filtered_links
    } else {
      series.link_data
    },
  }
}

///|
fn filter_series_negative_values(
  series : @option.SeriesOption,
) -> @option.SeriesOption {
  let filtered : Array[@option.DataItem] = []
  for i, _ in series.data {
    let item = series.data[i]
    let keep = match item.value {
      @option.Num(n) => n >= 0.0
      _ => true
    }
    if keep {
      filtered.push(item)
    }
  }
  { ..series, data: filtered }
}

///|
fn apply_processor_to_option(
  opt : @option.ChartOption,
  series_type : @option.SeriesType?,
  execution_key : String?,
) -> @option.ChartOption {
  if execution_key == Some("map_data_statistic") {
    return @chart.apply_map_data_statistic(opt)
  }
  let next_series : Array[@option.SeriesOption] = []
  for i, _ in opt.series {
    let series = opt.series[i]
    let matches_type = series_type.map_or(true, target => {
      series.series_type == target
    })
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
  }
  { ..opt, series: next_series }
}

///|
fn next_visual_index(
  registry : @core.Registry,
  opt : @option.ChartOption,
  visited : Array[Bool],
) -> Int? {
  let mut best_index = -1
  let mut best_priority = 0

  for i, _ in registry.visuals {
    let registration = registry.visuals[i]
    if !visited[i] && has_registered_series_type(opt, registration.series_type) {
      if best_index == -1 || registration.priority < best_priority {
        best_index = i
        best_priority = registration.priority
      }
    }
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
  for i, registration in registry.processors {
    if !visited[i] && has_registered_series_type(opt, registration.series_type) {
      if best_index == -1 || registration.priority < best_priority {
        best_index = i
        best_priority = registration.priority
      }
    }
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
  let visited = Array::make(registry.processors.length(), false)
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
  let state = registry.coordinate_system_manager.create(opt)
  let coord = match state.cartesian {
    Some(value) => value
    None => @layout.build_cartesian(opt)
  }
  @core.RenderContext::new(
    raw_opt,
    opt,
    coord,
    state.polar,
    state.parallel,
    state.geo,
    state.calendar,
    state.single,
    state.view,
  )
}

///|
fn run_registered_visuals(
  registry : @core.Registry,
  opt : @option.ChartOption,
) -> String? {
  let visited = Array::make(registry.visuals.length(), false)
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
  for registration in registry.components {
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
  for i, _ in registry.charts {
    let registration = registry.charts[i]
    if !has_registered_series_type(ctx.option, Some(registration.series_type)) {
      continue
    }
    append_elements(elems, registration.view.render(ctx))
  }
}

///|
/// Render an ECharts JSON option string to an SVG string.
/// Returns an error string with "ERROR: ..." prefix on failure.
pub fn version() -> String {
  "0.4.15"
}

///|
pub fn render(json_str : String) -> String {
  let opt = try @option.parse(json_str) catch {
    // strip error details for WASM size
    _err => return "ERROR: failed to parse JSON" // : \{err}"
  } noraise {
    res => res
  }
  let registry = build_registry()
  let processed_opt = run_registered_processors(registry, opt)
  let ctx = run_registered_layouts(registry, opt, processed_opt)
  let aria_label = run_registered_visuals(registry, processed_opt)
  let elems : Array[@graphic.Element] = []
  let has_cartesian = has_cartesian_series(processed_opt)
  render_registered_components(elems, registry, ctx, Background, has_cartesian)
  render_registered_charts(elems, registry, ctx)
  render_registered_components(elems, registry, ctx, Foreground, has_cartesian)
  let bg = match processed_opt.background_color {
    Some(c) => @graphic.Color::from_hex(c)
    None => None
  }
  let accessibility = aria_label.map(label => {
    @svg.SvgAccessibility::new("img", Some(label), None, Some(label))
  })
  @svg.paint(
    elems,
    processed_opt.width,
    processed_opt.height,
    bg,
    accessibility,
  )
}

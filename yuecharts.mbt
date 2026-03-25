// Top-level module
// Corresponds to: echarts/src/echarts.ts (core rendering pipeline)
// and echarts/src/core/echarts.ts (init and render logic)

///|
/// Returns true if any series uses the Cartesian coordinate system.
fn has_cartesian_series(opt : @option.ChartOption) -> Bool {
  let mut i = 0
  while i < opt.series.length() {
    let s = opt.series[i]
    i = i + 1
    match s.series_type {
      @option.Bar
      | @option.Line
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
    i = i + 1
  }
}

///|
fn build_registry() -> @core.Registry {
  let registry = @core.Registry::new()
  @chart.install_all(registry)
  @component.install_all(registry)
  registry
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
    i = i + 1
    let stage_matches = match registration.render_stage {
      Background =>
        match stage {
          Background => true
          Foreground => false
        }
      Foreground =>
        match stage {
          Background => false
          Foreground => true
        }
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
    i = i + 1
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
  let coord = @layout.build_cartesian(opt)
  let registry = build_registry()
  let ctx = @core.RenderContext::new(opt, coord)
  let elems : Array[@graphic.Element] = []
  let has_cartesian = has_cartesian_series(opt)
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
  let bg = match opt.background_color {
    Some(c) => @graphic.Color::from_hex(c)
    None => None
  }
  @svg.paint(elems, opt.width, opt.height, bg)
}

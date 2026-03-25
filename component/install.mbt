// Corresponds to: echarts/src/component/axis/install.ts
// and echarts/src/component/grid/installSimple.ts
// and echarts/src/component/title/install.ts
// and echarts/src/component/legend/install.ts

///|
struct GridLinesComponentView {}

///|
pub impl @core.ComponentViewLike for GridLinesComponentView with render(
  _self,
  ctx,
) {
  render_grid_lines(ctx.coord)
}

///|
struct AxisComponentView {}

///|
pub impl @core.ComponentViewLike for AxisComponentView with render(_self, ctx) {
  render_axes(ctx.option, ctx.coord)
}

///|
struct TitleComponentView {}

///|
pub impl @core.ComponentViewLike for TitleComponentView with render(_self, ctx) {
  render_title(ctx.option)
}

///|
struct LegendComponentView {}

///|
pub impl @core.ComponentViewLike for LegendComponentView with render(_self, ctx) {
  render_legend(ctx.option)
}

///|
fn register_component(
  registry : @core.Registry,
  component_type : String,
  install_source : String,
  model_source : String,
  view_source : String,
  render_stage : @core.ComponentRenderStage,
  requires_cartesian : Bool,
  view : &@core.ComponentViewLike,
) -> Unit {
  registry.register_component(
    @core.ComponentRegistration::new(
      component_type, install_source, model_source, view_source, render_stage, requires_cartesian,
      view,
    ),
  )
}

///|
pub fn install_grid_lines(registry : @core.Registry) -> Unit {
  register_component(
    registry,
    "grid",
    "echarts/src/component/grid/installSimple.ts",
    "echarts/src/coord/cartesian/GridModel.ts",
    "echarts/src/component/axis/axisSplitHelper.ts",
    @core.ComponentRenderStage::background(),
    true,
    GridLinesComponentView::{  },
  )
}

///|
pub fn install_axis(registry : @core.Registry) -> Unit {
  register_component(
    registry,
    "axis",
    "echarts/src/component/axis/install.ts",
    "echarts/src/component/axis/AxisModel.ts",
    "echarts/src/component/axis/AxisView.ts",
    @core.ComponentRenderStage::background(),
    true,
    AxisComponentView::{  },
  )
}

///|
pub fn install_title(registry : @core.Registry) -> Unit {
  register_component(
    registry,
    "title",
    "echarts/src/component/title/install.ts",
    "echarts/src/component/title/install.ts",
    "echarts/src/component/title/install.ts",
    @core.ComponentRenderStage::foreground(),
    false,
    TitleComponentView::{  },
  )
}

///|
pub fn install_legend(registry : @core.Registry) -> Unit {
  register_component(
    registry,
    "legend",
    "echarts/src/component/legend/install.ts",
    "echarts/src/component/legend/LegendModel.ts",
    "echarts/src/component/legend/LegendView.ts",
    @core.ComponentRenderStage::foreground(),
    false,
    LegendComponentView::{  },
  )
}

///|
pub fn install_aria(registry : @core.Registry) -> Unit {
  registry.register_visual(
    @core.VisualRegistration::new(
      "visual-aria",
      "echarts/src/visual/aria.ts",
      None,
      9000,
      Some("aria_label"),
    ),
  )
}

///|
pub fn install_all(registry : @core.Registry) -> Unit {
  install_grid_lines(registry)
  install_axis(registry)
  install_title(registry)
  install_legend(registry)
  install_aria(registry)
}

// Corresponds to: echarts/src/component/axis/install.ts
// and echarts/src/component/grid/installSimple.ts
// and echarts/src/component/title/install.ts
// and echarts/src/component/legend/install.ts
// and echarts/src/component/calendar/install.ts
// and echarts/src/component/polar/install.ts
// and echarts/src/component/geo/install.ts
// and echarts/src/component/singleAxis/install.ts

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
  render_axes(
    ctx.option,
    ctx.coord,
    ctx.option.text_style.font_family,
    polar=ctx.polar,
    single=ctx.single,
  )
}

///|
struct ParallelComponentView {}

///|
pub impl @core.ComponentViewLike for ParallelComponentView with render(
  _self,
  ctx,
) {
  render_parallel_component(ctx.option, parallel=ctx.parallel)
}

///|
struct GeoComponentView {}

///|
pub impl @core.ComponentViewLike for GeoComponentView with render(_self, ctx) {
  render_geo_component(ctx.option, geo=ctx.geo)
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
  render_legend(ctx.raw_option)
}

///|
struct CalendarComponentView {}

///|
pub impl @core.ComponentViewLike for CalendarComponentView with render(
  _self,
  ctx,
) {
  render_calendar(ctx.option, calendar?=ctx.calendar)
}

///|
struct MatrixComponentView {}

///|
pub impl @core.ComponentViewLike for MatrixComponentView with render(_self, ctx) {
  render_matrix(ctx.option, matrix?=@coord.Matrix::build(ctx.option))
}

///|
fn register_component(
  registry : @core.Registry,
  render_stage : @core.ComponentRenderStage,
  requires_cartesian : Bool,
  view : &@core.ComponentViewLike,
) -> Unit {
  registry.register_component(
    @core.ComponentRegistration::new(render_stage, requires_cartesian, view),
  )
}

///|
pub fn install_grid_lines(registry : @core.Registry) -> Unit {
  // echarts/src/component/grid/installSimple.ts
  // echarts/src/coord/cartesian/GridModel.ts
  // echarts/src/component/axis/axisSplitHelper.ts
  register_component(registry, Background, true, GridLinesComponentView::{  })
}

///|
pub fn install_axis(registry : @core.Registry) -> Unit {
  // echarts/src/component/axis/install.ts
  // echarts/src/component/axis/AxisView.ts
  register_component(registry, Background, false, AxisComponentView::{  })
}

///|

///|
pub fn install_parallel(registry : @core.Registry) -> Unit {
  // echarts/src/component/parallel/install.ts
  // echarts/src/component/parallel/ParallelView.ts
  // echarts/src/component/axis/ParallelAxisView.ts
  register_component(registry, Foreground, false, ParallelComponentView::{  })
}

///|
pub fn install_geo(registry : @core.Registry) -> Unit {
  // echarts/src/component/geo/install.ts
  // echarts/src/component/helper/MapDraw.ts
  // echarts/src/component/helper/geoGraphic.ts
  register_component(registry, Background, false, GeoComponentView::{  })
}

///|
pub fn install_title(registry : @core.Registry) -> Unit {
  // echarts/src/component/title/install.ts
  register_component(registry, Foreground, false, TitleComponentView::{  })
}

///|
pub fn install_legend(registry : @core.Registry) -> Unit {
  // echarts/src/component/legend/install.ts
  // echarts/src/component/legend/LegendModel.ts
  // echarts/src/component/legend/LegendView.ts
  register_component(registry, Foreground, false, LegendComponentView::{  })
}

///|
pub fn install_aria(registry : @core.Registry) -> Unit {
  // echarts/src/visual/aria.ts
  registry.register_visual(
    @core.VisualRegistration::new(None, 6000, Some("aria_label")),
  )
}

///|
pub fn install_calendar(registry : @core.Registry) -> Unit {
  // echarts/src/component/calendar/install.ts
  // echarts/src/coord/calendar/CalendarModel.ts
  // echarts/src/component/calendar/CalendarView.ts
  register_component(registry, Background, false, CalendarComponentView::{  })
}

///|
pub fn install_matrix(registry : @core.Registry) -> Unit {
  // echarts/src/component/matrix/install.ts
  // echarts/src/coord/matrix/MatrixModel.ts
  // echarts/src/component/matrix/MatrixView.ts
  register_component(registry, Background, false, MatrixComponentView::{  })
}

///|
pub fn install_all(registry : @core.Registry) -> Unit {
  install_grid_lines(registry)
  install_axis(registry)
  install_parallel(registry)
  install_geo(registry)
  install_title(registry)
  install_legend(registry)
  install_calendar(registry)
  install_matrix(registry)
  install_aria(registry)
}

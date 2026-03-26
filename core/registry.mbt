// Corresponds to: echarts/src/extension.ts
// and echarts/src/view/Chart.ts, echarts/src/view/Component.ts
// and echarts/src/core/echarts.ts registration/pipeline entry points.

///|
pub struct RenderContext {
  raw_option : @option.ChartOption
  option : @option.ChartOption
  coord : @coord.Cartesian2D
  polar : @coord.Polar?
  calendar : @coord.Calendar?
}

///|
pub fn RenderContext::new(
  raw_option : @option.ChartOption,
  option : @option.ChartOption,
  coord : @coord.Cartesian2D,
  polar : @coord.Polar?,
  calendar : @coord.Calendar?,
) -> RenderContext {
  { raw_option, option, coord, polar, calendar }
}

///|
pub struct ScaleTick {
  value : Double
  label : String
}

///|
pub(open) trait ChartViewLike {
  render(Self, RenderContext) -> Array[@graphic.Element]
  update_transform(Self, RenderContext) -> Unit = _
  remove(Self) -> Unit = _
}

///|
impl ChartViewLike with update_transform(_self, _ctx) {
  ()
}

///|
impl ChartViewLike with remove(_self) {
  ()
}

///|
pub(open) trait ComponentViewLike {
  render(Self, RenderContext) -> Array[@graphic.Element]
  update_view(Self, RenderContext) -> Unit = _
  remove(Self) -> Unit = _
}

///|
impl ComponentViewLike with update_view(_self, _ctx) {
  ()
}

///|
impl ComponentViewLike with remove(_self) {
  ()
}

///|
pub(open) trait ScaleLike {
  axis_kind(Self) -> String
  ticks(Self, Int) -> Array[ScaleTick]
}

///|
pub struct LinearScaleAdapter {
  source : @scale.LinearScale
}

///|
pub fn LinearScaleAdapter::new(
  source : @scale.LinearScale,
) -> LinearScaleAdapter {
  { source, }
}

///|
pub impl ScaleLike for LinearScaleAdapter with axis_kind(_self) {
  "value"
}

///|
pub impl ScaleLike for LinearScaleAdapter with ticks(self, count) {
  let source_ticks = self.source.ticks(count)
  let result : Array[ScaleTick] = []
  let mut i = 0
  while i < source_ticks.length() {
    let tick = source_ticks[i]
    result.push({ value: tick.value, label: tick.label })
    i += 1
  }
  result
}

///|
pub struct OrdinalScaleAdapter {
  source : @scale.OrdinalScale
}

///|
pub fn OrdinalScaleAdapter::new(
  source : @scale.OrdinalScale,
) -> OrdinalScaleAdapter {
  { source, }
}

///|
pub impl ScaleLike for OrdinalScaleAdapter with axis_kind(_self) {
  "category"
}

///|
pub impl ScaleLike for OrdinalScaleAdapter with ticks(self, _count) {
  let source_ticks = self.source.ticks()
  let result : Array[ScaleTick] = []
  let mut i = 0
  while i < source_ticks.length() {
    let tick = source_ticks[i]
    result.push({ value: tick.value, label: tick.label })
    i += 1
  }
  result
}

///|
pub(open) trait CoordLike {
  plot_bbox(Self) -> @graphic.BBox
}

///|
pub struct CartesianCoordAdapter {
  source : @coord.Cartesian2D
}

///|
pub fn CartesianCoordAdapter::new(
  source : @coord.Cartesian2D,
) -> CartesianCoordAdapter {
  { source, }
}

///|
pub impl CoordLike for CartesianCoordAdapter with plot_bbox(self) {
  self.source.bbox
}

///|
pub(all) enum ComponentRenderStage {
  Background
  Foreground
} derive(Eq)

///|
pub struct ChartRegistration {
  series_type : @option.SeriesType
  view : &ChartViewLike
}

///|
pub struct ComponentRegistration {
  render_stage : ComponentRenderStage
  requires_cartesian : Bool
  view : &ComponentViewLike
}

///|
pub fn ChartRegistration::new(
  series_type : @option.SeriesType,
  view : &ChartViewLike,
) -> ChartRegistration {
  { series_type, view }
}

///|
pub fn ComponentRegistration::new(
  render_stage : ComponentRenderStage,
  requires_cartesian : Bool,
  view : &ComponentViewLike,
) -> ComponentRegistration {
  { render_stage, requires_cartesian, view }
}

///|
pub struct LayoutRegistration {
  series_type : @option.SeriesType?
  priority : Int
  execution_key : String?
}

///|
pub struct VisualRegistration {
  series_type : @option.SeriesType?
  priority : Int
  execution_key : String?
}

///|
pub struct ProcessorRegistration {
  series_type : @option.SeriesType?
  priority : Int
  execution_key : String?
}

///|
pub fn LayoutRegistration::new(
  series_type : @option.SeriesType?,
  priority : Int,
  execution_key : String?,
) -> LayoutRegistration {
  { series_type, priority, execution_key }
}

///|
pub fn VisualRegistration::new(
  series_type : @option.SeriesType?,
  priority : Int,
  execution_key : String?,
) -> VisualRegistration {
  { series_type, priority, execution_key }
}

///|
pub fn ProcessorRegistration::new(
  series_type : @option.SeriesType?,
  priority : Int,
  execution_key : String?,
) -> ProcessorRegistration {
  { series_type, priority, execution_key }
}

///|
pub struct Registry {
  charts : Array[ChartRegistration]
  components : Array[ComponentRegistration]
  layouts : Array[LayoutRegistration]
  visuals : Array[VisualRegistration]
  processors : Array[ProcessorRegistration]
}

///|
pub fn Registry::new() -> Registry {
  let charts : Array[ChartRegistration] = []
  let components : Array[ComponentRegistration] = []
  let layouts : Array[LayoutRegistration] = []
  let visuals : Array[VisualRegistration] = []
  let processors : Array[ProcessorRegistration] = []
  { charts, components, layouts, visuals, processors }
}

///|
pub fn Registry::register_chart(
  self : Registry,
  registration : ChartRegistration,
) -> Unit {
  self.charts.push(registration)
}

///|
pub fn Registry::register_component(
  self : Registry,
  registration : ComponentRegistration,
) -> Unit {
  self.components.push(registration)
}

///|
pub fn Registry::register_layout(
  self : Registry,
  registration : LayoutRegistration,
) -> Unit {
  self.layouts.push(registration)
}

///|
pub fn Registry::register_visual(
  self : Registry,
  registration : VisualRegistration,
) -> Unit {
  self.visuals.push(registration)
}

///|
pub fn Registry::register_processor(
  self : Registry,
  registration : ProcessorRegistration,
) -> Unit {
  self.processors.push(registration)
}

// Corresponds to: echarts/src/component/grid/installSimple.ts
//                  echarts/src/component/calendar/install.ts
//                  echarts/src/component/polar/install.ts
//                  echarts/src/component/parallel/install.ts
//                  echarts/src/component/geo/install.ts
//                  echarts/src/component/singleAxis/install.ts
//                  echarts/src/coord/View.ts
//                  echarts/src/chart/sankey/sankeyLayout.ts

///|
struct CartesianCoordinateSystemCreator {}

///|
pub impl @core.CoordinateSystemCreatorLike for CartesianCoordinateSystemCreator with type_name(
  _self,
) {
  "cartesian2d"
}

///|
pub impl @core.CoordinateSystemCreatorLike for CartesianCoordinateSystemCreator with create(
  _self,
  opt,
  state,
) {
  { ..state, cartesian: Some(build_cartesian(opt)) }
}

///|
struct PolarCoordinateSystemCreator {}

///|
pub impl @core.CoordinateSystemCreatorLike for PolarCoordinateSystemCreator with type_name(
  _self,
) {
  "polar"
}

///|
pub impl @core.CoordinateSystemCreatorLike for PolarCoordinateSystemCreator with create(
  _self,
  opt,
  state,
) {
  { ..state, polars: build_polar(opt) }
}

///|
struct ParallelCoordinateSystemCreator {}

///|
pub impl @core.CoordinateSystemCreatorLike for ParallelCoordinateSystemCreator with type_name(
  _self,
) {
  "parallel"
}

///|
pub impl @core.CoordinateSystemCreatorLike for ParallelCoordinateSystemCreator with create(
  _self,
  opt,
  state,
) {
  { ..state, parallel: @coord.Parallel::build(opt) }
}

///|
struct GeoCoordinateSystemCreator {}

///|
pub impl @core.CoordinateSystemCreatorLike for GeoCoordinateSystemCreator with type_name(
  _self,
) {
  "geo"
}

///|
pub impl @core.CoordinateSystemCreatorLike for GeoCoordinateSystemCreator with create(
  _self,
  opt,
  state,
) {
  { ..state, geo: @coord.Geo::build(opt) }
}

///|
struct CalendarCoordinateSystemCreator {}

///|
pub impl @core.CoordinateSystemCreatorLike for CalendarCoordinateSystemCreator with type_name(
  _self,
) {
  "calendar"
}

///|
pub impl @core.CoordinateSystemCreatorLike for CalendarCoordinateSystemCreator with create(
  _self,
  opt,
  state,
) {
  { ..state, calendar: @coord.Calendar::build(opt) }
}

///|
pub impl @core.CoordinateSystemCreatorLike for CalendarCoordinateSystemCreator with can_be_non_series_box(
  _self,
) {
  true
}

///|
struct SingleCoordinateSystemCreator {}

///|
pub impl @core.CoordinateSystemCreatorLike for SingleCoordinateSystemCreator with type_name(
  _self,
) {
  "single"
}

///|
pub impl @core.CoordinateSystemCreatorLike for SingleCoordinateSystemCreator with create(
  _self,
  opt,
  state,
) {
  { ..state, single: @coord.Single::build(opt) }
}

///|
struct ViewCoordinateSystemCreator {}

///|
pub impl @core.CoordinateSystemCreatorLike for ViewCoordinateSystemCreator with type_name(
  _self,
) {
  "view"
}

///|
pub impl @core.CoordinateSystemCreatorLike for ViewCoordinateSystemCreator with create(
  _self,
  opt,
  state,
) {
  { ..state, view: @coord.View::build(opt) }
}

///|
pub fn install_all(registry : @core.Registry) -> Unit {
  registry.register_coordinate_system(CartesianCoordinateSystemCreator::{  })
  registry.register_coordinate_system(PolarCoordinateSystemCreator::{  })
  registry.register_coordinate_system(ParallelCoordinateSystemCreator::{  })
  registry.register_coordinate_system(GeoCoordinateSystemCreator::{  })
  registry.register_coordinate_system(CalendarCoordinateSystemCreator::{  })
  registry.register_coordinate_system(SingleCoordinateSystemCreator::{  })
  registry.register_coordinate_system(ViewCoordinateSystemCreator::{  })
}

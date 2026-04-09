// Whitebox tests for core/coordinate_system.mbt.

///|
fn test_single_runtime() -> @coord.Single {
  {
    bbox: { x: 0.0, y: 0.0, width: 10.0, height: 10.0 },
    orient: "horizontal",
    axis_type: @option.AxisType::Value,
    min_val: 0.0,
    max_val: 1.0,
    inverse: false,
    position: "bottom",
    labels: [],
    time_labels: [],
  }
}

///|
struct TestNonSeriesCreator {}

///|
pub impl CoordinateSystemCreatorLike for TestNonSeriesCreator with type_name(
  _self,
) {
  "test-non-series"
}

///|
pub impl CoordinateSystemCreatorLike for TestNonSeriesCreator with create(
  _self,
  _opt,
  state,
) {
  { ..state, single: Some(test_single_runtime()) }
}

///|
pub impl CoordinateSystemCreatorLike for TestNonSeriesCreator with can_be_non_series_box(
  _self,
) {
  true
}

///|
struct TestNormalCreator {}

///|
pub impl CoordinateSystemCreatorLike for TestNormalCreator with type_name(_self) {
  "test-normal"
}

///|
pub impl CoordinateSystemCreatorLike for TestNormalCreator with create(
  _self,
  _opt,
  state,
) {
  let cartesian = match state.single {
    Some(_) =>
      Some(
        @coord.Cartesian2D::new(@graphic.BBox::new(1.0, 2.0, 3.0, 4.0), [], []),
      )
    None => None
  }
  { ..state, cartesian, }
}

///|
test "coordinate system manager runs non-series creators before normal creators" {
  let manager = CoordinateSystemManager::new()
  manager.register(TestNormalCreator::{  })
  manager.register(TestNonSeriesCreator::{  })
  let state = manager.create(@option.ChartOption::default())
  assert_true(state.single is Some(_))
  assert_eq(state.cartesian.unwrap().bbox.x, 1.0)
  assert_true(manager.get("test-normal") is Some(_))
  assert_true(manager.get("missing") is None)
}

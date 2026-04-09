// Corresponds to: echarts/src/core/CoordinateSystem.ts
//                  echarts/src/coord/CoordinateSystem.ts

///|
pub(all) struct CoordinateSystemState {
  cartesian : @coord.Cartesian2D?
  polar : @coord.Polar?
  parallel : @coord.Parallel?
  geo : @coord.Geo?
  calendar : @coord.Calendar?
  single : @coord.Single?
  view : Array[@coord.View]
}

///|
pub fn CoordinateSystemState::new() -> CoordinateSystemState {
  {
    cartesian: None,
    polar: None,
    parallel: None,
    geo: None,
    calendar: None,
    single: None,
    view: [],
  }
}

///|
pub(open) trait CoordinateSystemCreatorLike {
  type_name(Self) -> String
  create(Self, @option.ChartOption, CoordinateSystemState) -> CoordinateSystemState
  can_be_non_series_box(Self) -> Bool = _
}

///|
impl CoordinateSystemCreatorLike with can_be_non_series_box(_self) {
  false
}

///|
pub struct CoordinateSystemManager {
  normal_creators : Array[&CoordinateSystemCreatorLike]
  non_series_box_creators : Array[&CoordinateSystemCreatorLike]
}

///|
pub fn CoordinateSystemManager::new() -> CoordinateSystemManager {
  { normal_creators: [], non_series_box_creators: [] }
}

///|
pub fn CoordinateSystemManager::register(
  self : CoordinateSystemManager,
  creator : &CoordinateSystemCreatorLike,
) -> Unit {
  if creator.can_be_non_series_box() {
    self.non_series_box_creators.push(creator)
  } else {
    self.normal_creators.push(creator)
  }
}

///|
pub fn CoordinateSystemManager::get(
  self : CoordinateSystemManager,
  type_name : String,
) -> &CoordinateSystemCreatorLike? {
  let mut i = 0
  while i < self.normal_creators.length() {
    if self.normal_creators[i].type_name() == type_name {
      return Some(self.normal_creators[i])
    }
    i += 1
  }
  i = 0
  while i < self.non_series_box_creators.length() {
    if self.non_series_box_creators[i].type_name() == type_name {
      return Some(self.non_series_box_creators[i])
    }
    i += 1
  }
  None
}

///|
fn coordinate_system_run_creators(
  creators : Array[&CoordinateSystemCreatorLike],
  opt : @option.ChartOption,
  state : CoordinateSystemState,
) -> CoordinateSystemState {
  let mut next_state = state
  let mut i = 0
  while i < creators.length() {
    next_state = creators[i].create(opt, next_state)
    i += 1
  }
  next_state
}

///|
pub fn CoordinateSystemManager::create(
  self : CoordinateSystemManager,
  opt : @option.ChartOption,
) -> CoordinateSystemState {
  let state = CoordinateSystemState::new()
  let after_non_series = coordinate_system_run_creators(
    self.non_series_box_creators,
    opt,
    state,
  )
  coordinate_system_run_creators(self.normal_creators, opt, after_non_series)
}

// Corresponds to: echarts/src/coord/cartesian/Grid.ts
// and echarts/src/coord/calendar/Calendar.ts
// and the root cartesian/calendar layout hookup in echarts/src/chart/*/install.ts.

///|
pub fn install_all(registry : @core.Registry) -> Unit {
  // echarts/src/coord/cartesian/Grid.ts
  registry.register_layout(
    @core.LayoutRegistration::new(None, 100, Some("build_cartesian")),
  )
  // echarts/src/coord/calendar/Calendar.ts
  registry.register_layout(
    @core.LayoutRegistration::new(None, 110, Some("build_calendar")),
  )
  // echarts/src/coord/parallel/parallelCreator.ts
  registry.register_layout(
    @core.LayoutRegistration::new(
      Some(@option.SeriesType::Parallel),
      108,
      Some("build_parallel"),
    ),
  )
  // echarts/src/coord/polar/polarCreator.ts
  registry.register_layout(
    @core.LayoutRegistration::new(None, 105, Some("build_polar")),
  )
  // echarts/src/coord/single/singleCreator.ts
  registry.register_layout(
    @core.LayoutRegistration::new(
      Some(@option.SeriesType::ThemeRiver),
      109,
      Some("build_single"),
    ),
  )
}

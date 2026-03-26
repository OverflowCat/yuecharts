// Corresponds to: echarts/src/coord/cartesian/Grid.ts
// and echarts/src/coord/calendar/Calendar.ts
// and the root cartesian/calendar layout hookup in echarts/src/chart/*/install.ts.

///|
pub fn install_all(registry : @core.Registry) -> Unit {
  registry.register_layout(
    @core.LayoutRegistration::new(
      "layout-root",
      "echarts/src/coord/cartesian/Grid.ts",
      None,
      100,
      Some("build_cartesian"),
    ),
  )
  registry.register_layout(
    @core.LayoutRegistration::new(
      "layout-root",
      "echarts/src/coord/calendar/Calendar.ts",
      None,
      110,
      Some("build_calendar"),
    ),
  )
}

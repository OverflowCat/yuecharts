// Corresponds to: echarts/src/coord/cartesian/Grid.ts
// and the root cartesian layout hookup in echarts/src/chart/*/install.ts.

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
}

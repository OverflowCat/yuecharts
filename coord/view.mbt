// Corresponds to: echarts/src/coord/View.ts
//                  echarts/src/util/layout.ts (getLayoutRect subset)
//                  echarts/src/chart/sankey/sankeyLayout.ts

///|
pub(all) struct View {
  series_index : Int
  bounding_rect : @graphic.BBox
  view_rect : @graphic.BBox
  center_option : Array[String]
  zoom : Double
}

///|
fn view_resolve_size(spec : @option.SizeSpec, total : Double) -> Double {
  match spec {
    @option.SizeSpec::Px(px) => px
    @option.SizeSpec::Pct(pct) => total * pct / 100.0
  }
}

///|
fn view_parse_percent_with_offset(
  value : String,
  total : Double,
  offset : Double,
) -> Double {
  if value.has_suffix("%") {
    let pct_str = value[:value.length() - 1].to_string()
    let parsed = try? @string.parse_double(pct_str)
    match parsed {
      Ok(pct) => offset + total * pct / 100.0
      _ => offset
    }
  } else {
    let parsed = try? @string.parse_double(value)
    match parsed {
      Ok(px) => px
      _ => offset
    }
  }
}

///|
fn view_sankey_layout_rect(
  series : @option.SeriesOption,
  opt : @option.ChartOption,
) -> @graphic.BBox {
  let left = view_resolve_size(
    series.sankey_left.unwrap_or(@option.SizeSpec::Pct(5.0)),
    opt.width,
  )
  let top = view_resolve_size(
    series.sankey_top.unwrap_or(@option.SizeSpec::Pct(5.0)),
    opt.height,
  )
  let right = view_resolve_size(
    series.sankey_right.unwrap_or(@option.SizeSpec::Pct(20.0)),
    opt.width,
  )
  let bottom = view_resolve_size(
    series.sankey_bottom.unwrap_or(@option.SizeSpec::Pct(5.0)),
    opt.height,
  )
  let width = match series.sankey_width {
    Some(spec) => view_resolve_size(spec, opt.width)
    None => opt.width - left - right
  }
  let height = match series.sankey_height {
    Some(spec) => view_resolve_size(spec, opt.height)
    None => opt.height - top - bottom
  }
  @graphic.BBox::new(left, top, width.max(0.0), height.max(0.0))
}

///|
fn View::center_raw_internal(self : View) -> @graphic.Point {
  if self.center_option.length() >= 2 {
    let rect = self.bounding_rect
    @graphic.Point::new(
      view_parse_percent_with_offset(self.center_option[0], rect.width, rect.x),
      view_parse_percent_with_offset(self.center_option[1], rect.height, rect.y),
    )
  } else {
    self.default_center_raw()
  }
}

///|
pub fn View::default_center_raw(self : View) -> @graphic.Point {
  @graphic.Point::new(
    self.bounding_rect.center_x(),
    self.bounding_rect.center_y(),
  )
}

///|
fn View::raw_to_view(self : View, point : @graphic.Point) -> @graphic.Point {
  let source = self.bounding_rect
  let target = self.view_rect
  let sx = if source.width == 0.0 { 1.0 } else { target.width / source.width }
  let sy = if source.height == 0.0 {
    1.0
  } else {
    target.height / source.height
  }
  @graphic.Point::new(
    target.x + (point.x - source.x) * sx,
    target.y + (point.y - source.y) * sy,
  )
}

///|
pub fn View::default_center(self : View) -> @graphic.Point {
  self.raw_to_view(self.default_center_raw())
}

///|
pub fn View::center(self : View) -> @graphic.Point {
  self.raw_to_view(self.center_raw_internal())
}

///|
pub fn View::get_view_rect_after_roam(self : View) -> @graphic.BBox {
  let default_center = self.default_center()
  let center = self.center()
  @graphic.BBox::new(
    default_center.x + (self.view_rect.x - center.x) * self.zoom,
    default_center.y + (self.view_rect.y - center.y) * self.zoom,
    self.view_rect.width * self.zoom,
    self.view_rect.height * self.zoom,
  )
}

///|
pub fn View::data_to_point(self : View, data : Array[Double]) -> Array[Double] {
  let source_x = data.get(0).unwrap_or(0.0)
  let source_y = data.get(1).unwrap_or(0.0)
  let raw_point = self.raw_to_view(@graphic.Point::new(source_x, source_y))
  let default_center = self.default_center()
  let center = self.center()
  [
    default_center.x + (raw_point.x - center.x) * self.zoom,
    default_center.y + (raw_point.y - center.y) * self.zoom,
  ]
}

///|
pub fn View::point_to_data(self : View, point : Array[Double]) -> Array[Double] {
  let pixel_x = point.get(0).unwrap_or(0.0)
  let pixel_y = point.get(1).unwrap_or(0.0)
  let default_center = self.default_center()
  let center = self.center()
  let zoom = if self.zoom == 0.0 { 1.0 } else { self.zoom }
  let raw_x = center.x + (pixel_x - default_center.x) / zoom
  let raw_y = center.y + (pixel_y - default_center.y) / zoom
  let source = self.bounding_rect
  let target = self.view_rect
  let sx = if source.width == 0.0 { 1.0 } else { target.width / source.width }
  let sy = if source.height == 0.0 {
    1.0
  } else {
    target.height / source.height
  }
  [source.x + (raw_x - target.x) / sx, source.y + (raw_y - target.y) / sy]
}

///|
pub fn View::contain_point(self : View, point : Array[Double]) -> Bool {
  let rect = self.get_view_rect_after_roam()
  let x = point.get(0).unwrap_or(0.0)
  let y = point.get(1).unwrap_or(0.0)
  x >= rect.x && x <= rect.right() && y >= rect.y && y <= rect.bottom()
}

///|
fn view_build_sankey(
  series : @option.SeriesOption,
  series_index : Int,
  opt : @option.ChartOption,
) -> View {
  let view_rect = view_sankey_layout_rect(series, opt)
  {
    series_index,
    bounding_rect: @graphic.BBox::new(
      0.0,
      0.0,
      view_rect.width,
      view_rect.height,
    ),
    view_rect,
    center_option: series.center,
    zoom: if series.zoom <= 0.0 {
      1.0
    } else {
      series.zoom
    },
  }
}

///|
pub fn View::build(opt : @option.ChartOption) -> Array[View] {
  let views : Array[View] = []

  for i, _ in opt.series {
    let series = opt.series[i]
    if series.series_type == @option.SeriesType::Sankey &&
      series.coordinate_system == Some("view") {
      views.push(view_build_sankey(series, i, opt))
    }
  }
  views
}

///|
pub fn View::find_for_series(views : Array[View], series_index : Int) -> View? {
  for view in views {
    if view.series_index == series_index {
      return Some(view)
    }
  }
  None
}

// Corresponds to: echarts/src/component/geo/GeoView.ts
//                  echarts/src/component/helper/MapDraw.ts
//                  echarts/src/component/helper/geoGraphic.ts

///|
fn geo_region_option_by_name(
  geo_opt : @option.GeoOption,
  name : String,
) -> @option.GeoRegionOption? {
  let mut i = 0
  while i < geo_opt.regions.length() {
    let region_opt = geo_opt.regions[i]
    if region_opt.name == name {
      return Some(region_opt)
    }
    i += 1
  }
  None
}

///|
fn geo_region_border_color(
  geo_opt : @option.GeoOption,
  region_opt : @option.GeoRegionOption?,
) -> String {
  match region_opt {
    Some(region) =>
      match region.item_style {
        Some(item_style) => item_style.border_color
        None => geo_opt.item_style.border_color
      }
    None => geo_opt.item_style.border_color
  }
}

///|
fn geo_region_border_width(
  geo_opt : @option.GeoOption,
  region_opt : @option.GeoRegionOption?,
) -> Double {
  match region_opt {
    Some(region) =>
      match region.item_style {
        Some(item_style) => item_style.border_width
        None => geo_opt.item_style.border_width
      }
    None => geo_opt.item_style.border_width
  }
}

///|
fn geo_region_label_show(
  geo_opt : @option.GeoOption,
  region_opt : @option.GeoRegionOption?,
) -> Bool {
  match region_opt {
    Some(region) =>
      match region.label {
        Some(label) => label.show
        None => geo_opt.label.show
      }
    None => geo_opt.label.show
  }
}

///|
fn geo_region_label_color(
  geo_opt : @option.GeoOption,
  region_opt : @option.GeoRegionOption?,
) -> String {
  match region_opt {
    Some(region) =>
      match region.label {
        Some(label) => label.color
        None => geo_opt.label.color
      }
    None => geo_opt.label.color
  }
}

///|
fn render_geo_region_outline(
  rings : Array[Array[@graphic.Point]],
  border_color : String,
  border_width : Double,
) -> @graphic.Element {
  @graphic.Element::path_stroke_custom(
    geo_rings_path_d(rings),
    border_color,
    border_width,
    "butt",
    "miter",
    1.0,
  )
}

///|
fn geo_rings_path_d(rings : Array[Array[@graphic.Point]]) -> String {
  let buf = StringBuilder::new()
  let mut ring_index = 0
  while ring_index < rings.length() {
    let points = rings[ring_index]
    if points.length() > 0 {
      buf.write_string("M ")
      buf.write_string("\{points[0].x} \{points[0].y}")
      let mut point_index = 1
      while point_index < points.length() {
        buf.write_string(" L ")
        buf.write_string("\{points[point_index].x} \{points[point_index].y}")
        point_index += 1
      }
      buf.write_string(" Z")
    }
    ring_index += 1
  }
  buf.to_string()
}

///|
pub fn render_geo_component(
  opt : @option.ChartOption,
  geo? : @coord.Geo? = None,
) -> Array[@graphic.Element] {
  let geo = match geo {
    Some(value) => value
    None => return []
  }
  let elems : Array[@graphic.Element] = []
  let geo_opt = if opt.geo.length() > 0 {
    opt.geo[0]
  } else {
    @option.GeoOption::default()
  }
  let mut region_index = 0
  while region_index < geo.regions.length() {
    let region = geo.regions[region_index]
    let region_opt = geo_region_option_by_name(geo_opt, region.name)
    let polygons = region.screen_polygon_rings(geo)
    let border_color = geo_region_border_color(geo_opt, region_opt)
    let border_width = geo_region_border_width(geo_opt, region_opt)
    let mut polygon_index = 0
    while polygon_index < polygons.length() {
      elems.push(
        render_geo_region_outline(
          polygons[polygon_index],
          border_color,
          border_width,
        ),
      )
      polygon_index += 1
    }
    if geo_region_label_show(geo_opt, region_opt) {
      let center = region.screen_center(geo)
      elems.push(
        @graphic.Element::text_colored(
          center.x,
          center.y,
          region.name,
          @graphic.TextAnchor::Middle,
          @graphic.TextBaseline::Middle,
          geo_region_label_color(geo_opt, region_opt),
        ),
      )
    }
    region_index += 1
  }
  elems
}

// Corresponds to: echarts/src/chart/map/MapView.ts
//                  echarts/src/chart/map/MapSeries.ts
//                  echarts/src/chart/map/mapDataStatistic.ts
//                  echarts/src/component/helper/MapDraw.ts
//                  echarts/src/component/visualMap/ContinuousModel.ts
//                  echarts/src/visual/VisualMapping.ts

///|
let map_default_fill = "#f3f5f8"

///|
fn map_series_uses_geo(series : @option.SeriesOption) -> Bool {
  series.coordinate_system.unwrap_or("geo") == "geo"
}

///|
fn map_data_item_by_name(
  series : @option.SeriesOption,
  name : String,
) -> @option.DataItem? {
  let mut i = 0
  while i < series.data.length() {
    let item = series.data[i]
    if item.name == Some(name) {
      return Some(item)
    }
    i += 1
  }
  None
}

///|
fn map_geo_option(opt : @option.ChartOption) -> @option.GeoOption {
  if opt.geo.length() > 0 {
    opt.geo[0]
  } else {
    @option.GeoOption::default()
  }
}

///|
fn map_region_option_by_name(
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
fn map_region_fill(
  opt : @option.ChartOption,
  geo_opt : @option.GeoOption,
  series_index : Int,
  region_name : String,
  item : @option.DataItem?,
) -> String {
  let fallback = map_region_fill_fallback(opt, geo_opt, series_index, item)
  match map_region_option_by_name(geo_opt, region_name) {
    Some(region) =>
      region.item_style
      .map(style => style.area_color.unwrap_or(fallback))
      .unwrap_or(fallback)
    None => fallback
  }
}

///|
fn map_region_fill_fallback(
  opt : @option.ChartOption,
  geo_opt : @option.GeoOption,
  series_index : Int,
  item : @option.DataItem?,
) -> String {
  match item {
    Some(data_item) =>
      geo_visual_map_color(opt, series_index, data_item).unwrap_or(
        geo_opt.item_style.area_color.unwrap_or(map_default_fill),
      )
    None => geo_opt.item_style.area_color.unwrap_or(map_default_fill)
  }
}

///|
fn map_region_stroke_color(
  geo_opt : @option.GeoOption,
  region_name : String,
) -> String {
  match map_region_option_by_name(geo_opt, region_name) {
    Some(region) =>
      region.item_style
      .map(style => style.border_color)
      .unwrap_or(geo_opt.item_style.border_color)
    None => geo_opt.item_style.border_color
  }
}

///|
fn map_region_stroke_width(
  geo_opt : @option.GeoOption,
  region_name : String,
) -> Double {
  match map_region_option_by_name(geo_opt, region_name) {
    Some(region) =>
      region.item_style
      .map(style => style.border_width)
      .unwrap_or(geo_opt.item_style.border_width)
    None => geo_opt.item_style.border_width
  }
}

///|
fn render_map_region_polygon(
  rings : Array[Array[@graphic.Point]],
  fill : String,
  stroke_color_str : String,
  stroke_width : Double,
) -> @graphic.Element {
  @graphic.Element::path_fill_stroke(
    map_rings_path_d(rings),
    fill,
    stroke_color_str,
    stroke_width,
    1.0,
  )
}

///|
fn map_rings_path_d(rings : Array[Array[@graphic.Point]]) -> String {
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
pub fn render_maps(
  opt : @option.ChartOption,
  geo? : @coord.Geo? = None,
) -> Array[@graphic.Element] {
  guard geo is Some(geo) else { [] }
  let elems : Array[@graphic.Element] = []
  let geo_opt = map_geo_option(opt)
  let mut series_index = 0
  while series_index < opt.series.length() {
    let series = opt.series[series_index]
    match series.series_type {
      Map =>
        if map_series_uses_geo(series) {
          let mut region_index = 0
          while region_index < geo.regions.length() {
            let region = geo.regions[region_index]
            let item = map_data_item_by_name(series, region.name)
            let fill = map_region_fill(
              opt,
              geo_opt,
              series_index,
              region.name,
              item,
            )
            let stroke_color = map_region_stroke_color(geo_opt, region.name)
            let stroke_width = map_region_stroke_width(geo_opt, region.name)
            let polygons = region.screen_polygon_rings(geo)
            let mut polygon_index = 0
            while polygon_index < polygons.length() {
              elems.push(
                render_map_region_polygon(
                  polygons[polygon_index],
                  fill,
                  stroke_color,
                  stroke_width,
                ),
              )
              polygon_index += 1
            }
            region_index += 1
          }
        }
      _ => ()
    }
    series_index += 1
  }
  elems
}

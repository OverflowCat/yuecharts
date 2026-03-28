// Corresponds to: echarts/src/chart/map/MapView.ts
//                  echarts/src/chart/map/MapSeries.ts
//                  echarts/src/chart/map/mapDataStatistic.ts
//                  echarts/src/component/helper/MapDraw.ts
//                  echarts/src/component/visualMap/ContinuousModel.ts
//                  echarts/src/visual/VisualMapping.ts

///|
let map_default_fill = "#f3f5f8"

///|
fn map_series_group_key(series : @option.SeriesOption) -> String {
  if map_series_uses_geo(series) {
    "geo:\{series.geo_index}"
  } else {
    let map_name = series.map_name.unwrap_or("")
    "map:\{map_name}"
  }
}

///|
fn map_series_uses_geo(series : @option.SeriesOption) -> Bool {
  series.coordinate_system.unwrap_or("geo") == "geo"
}

///|
fn map_has_drawn_group(drawn_groups : Array[String], key : String) -> Bool {
  let mut i = 0
  while i < drawn_groups.length() {
    if drawn_groups[i] == key {
      return true
    }
    i += 1
  }
  false
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
fn map_data_item_numeric_value(item : @option.DataItem) -> Double? {
  match item.value {
    Num(value) =>
      if value.is_nan() {
        None
      } else {
        Some(value)
      }
    _ => None
  }
}

///|
fn map_value_list_by_name(
  names : Array[String],
  values_list : Array[Array[Double]],
  name : String,
) -> Array[Double]? {
  let mut i = 0
  while i < names.length() {
    if names[i] == name {
      return Some(values_list[i])
    }
    i += 1
  }
  None
}

///|
fn map_push_stat_value(
  names : Array[String],
  values_list : Array[Array[Double]],
  name : String,
  value : Double,
) -> Unit {
  let mut i = 0
  while i < names.length() {
    if names[i] == name {
      values_list[i].push(value)
      return
    }
    i += 1
  }
  names.push(name)
  values_list.push([value])
}

///|
fn map_statistic_value(
  values : Array[Double],
  statistic_type : @option.MapValueCalculationType,
) -> Double? {
  if values.length() == 0 {
    return None
  }
  let mut sum = 0.0
  let mut min = values[0]
  let mut max = values[0]
  let mut i = 0
  while i < values.length() {
    let value = values[i]
    if value < min {
      min = value
    }
    if value > max {
      max = value
    }
    sum += value
    i += 1
  }
  Some(match statistic_type {
    Sum => sum
    Average => sum / values.length().to_double()
    Min => min
    Max => max
  })
}

///|
fn map_aggregated_data_for_group(
  series_group : Array[@option.SeriesOption],
) -> Array[@option.DataItem] {
  let names : Array[String] = []
  let values_list : Array[Array[Double]] = []
  let templates : Array[@option.DataItem] = []
  let mut group_index = 0
  while group_index < series_group.length() {
    let series = series_group[group_index]
    let mut item_index = 0
    while item_index < series.data.length() {
      let item = series.data[item_index]
      match item.name {
        Some(name) => {
          if map_value_list_by_name(names, values_list, name) is None {
            templates.push(item)
          }
          match map_data_item_numeric_value(item) {
            Some(value) => map_push_stat_value(names, values_list, name, value)
            None => ()
          }
        }
        None => ()
      }
      item_index += 1
    }
    group_index += 1
  }
  let statistic_type = series_group[0].map_value_calculation
  let aggregated : Array[@option.DataItem] = []
  let mut i = 0
  while i < names.length() {
    let template = templates[i]
    let values = values_list[i]
    let value = map_statistic_value(values, statistic_type).map_or(
      @option.DataValue::Null,
      statistic => @option.DataValue::Num(statistic),
    )
    aggregated.push({ ..template, value, name: Some(names[i]) })
    i += 1
  }
  aggregated
}

///|
fn map_series_group(
  opt : @option.ChartOption,
  start_index : Int,
) -> Array[@option.SeriesOption] {
  let target = opt.series[start_index]
  let target_key = map_series_group_key(target)
  let group : Array[@option.SeriesOption] = []
  let mut i = 0
  while i < opt.series.length() {
    let series = opt.series[i]
    if series.series_type == Map && map_series_group_key(series) == target_key {
      group.push(series)
    }
    i += 1
  }
  group
}

///|
pub fn apply_map_data_statistic(
  opt : @option.ChartOption,
) -> @option.ChartOption {
  let next_series : Array[@option.SeriesOption] = []
  let mut i = 0
  while i < opt.series.length() {
    next_series.push(opt.series[i])
    i += 1
  }
  let processed_groups : Array[String] = []
  let mut series_index = 0
  while series_index < opt.series.length() {
    let series = opt.series[series_index]
    if series.series_type == Map {
      let group_key = map_series_group_key(series)
      if !map_has_drawn_group(processed_groups, group_key) {
        processed_groups.push(group_key)
        let group = map_series_group(opt, series_index)
        let aggregated = map_aggregated_data_for_group(group)
        let mut j = 0
        while j < opt.series.length() {
          let candidate = opt.series[j]
          if candidate.series_type == Map &&
            map_series_group_key(candidate) == group_key {
            next_series[j] = { ..candidate, data: aggregated }
          }
          j += 1
        }
      }
    }
    series_index += 1
  }
  { ..opt, series: next_series }
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
  let drawn_groups : Array[String] = []
  let mut series_index = 0
  while series_index < opt.series.length() {
    let series = opt.series[series_index]
    match series.series_type {
      Map =>
        if map_series_uses_geo(series) {
          let group_key = map_series_group_key(series)
          if map_has_drawn_group(drawn_groups, group_key) {
            series_index += 1
            continue
          }
          drawn_groups.push(group_key)
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

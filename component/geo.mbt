// Corresponds to: echarts/src/component/geo/GeoView.ts
//                  echarts/src/component/helper/MapDraw.ts
//                  echarts/src/component/helper/geoGraphic.ts

///|
let geo_default_fill = "rgba(234,237,245,0.5)"

///|
fn geo_region_option_by_name(
  geo_opt : @option.GeoOption,
  name : String,
) -> @option.GeoRegionOption? {
  for i, _ in geo_opt.regions {
    let region_opt = geo_opt.regions[i]
    if region_opt.name == name {
      return Some(region_opt)
    }
  }
  None
}

///|
fn geo_region_border_color(
  geo_opt : @option.GeoOption,
  region_opt : @option.GeoRegionOption?,
  region : @coord.GeoRegion,
) -> String {
  match region_opt {
    Some(region_patch) =>
      region_patch.item_style
      .bind(style => style.border_color)
      .unwrap_or(
        region.svg_stroke_color().unwrap_or(geo_opt.item_style.border_color),
      )
    None => region.svg_stroke_color().unwrap_or(geo_opt.item_style.border_color)
  }
}

///|
fn geo_region_border_width(
  geo_opt : @option.GeoOption,
  region_opt : @option.GeoRegionOption?,
  region : @coord.GeoRegion,
) -> Double {
  match region_opt {
    Some(region_patch) =>
      region_patch.item_style
      .bind(style => style.border_width)
      .unwrap_or(
        region.svg_stroke_width().unwrap_or(geo_opt.item_style.border_width),
      )
    None => region.svg_stroke_width().unwrap_or(geo_opt.item_style.border_width)
  }
}

///|
fn geo_region_fill_color(
  geo_opt : @option.GeoOption,
  region_opt : @option.GeoRegionOption?,
  region : @coord.GeoRegion,
) -> String {
  match region_opt {
    Some(region_patch) =>
      region_patch.item_style
      .bind(style => style.area_color)
      .unwrap_or(
        geo_opt.item_style.area_color.unwrap_or(
          region.svg_fill().unwrap_or(geo_default_fill),
        ),
      )
    None =>
      geo_opt.item_style.area_color.unwrap_or(
        region.svg_fill().unwrap_or(geo_default_fill),
      )
  }
}

///|
fn geo_region_silent(region_opt : @option.GeoRegionOption?) -> Bool {
  match region_opt {
    Some(region) => region.silent.unwrap_or(false)
    None => false
  }
}

///|
fn geo_region_is_selected(region_opt : @option.GeoRegionOption?) -> Bool {
  match region_opt {
    Some(region) => region.selected.unwrap_or(false)
    None => false
  }
}

///|
fn geo_state_item_style(
  states : @option.GeoStatesOption,
  state_name : String,
) -> @option.GeoItemStylePatchOption? {
  match state_name {
    "emphasis" => states.emphasis.bind(state => state.item_style)
    "select" => states.select.bind(state => state.item_style)
    "blur" => states.blur.bind(state => state.item_style)
    _ => None
  }
}

///|
fn geo_state_label(
  states : @option.GeoStatesOption,
  state_name : String,
) -> @option.GeoLabelPatchOption? {
  match state_name {
    "emphasis" => states.emphasis.bind(state => state.label)
    "select" => states.select.bind(state => state.label)
    "blur" => states.blur.bind(state => state.label)
    _ => None
  }
}

///|
fn geo_region_state_style(
  geo_opt : @option.GeoOption,
  region_opt : @option.GeoRegionOption?,
  state_name : String,
) -> @graphic.DisplayStateStyle? {
  let style = match region_opt {
    Some(region) =>
      match geo_state_item_style(region.states, state_name) {
        Some(style) => Some(style)
        None => geo_state_item_style(geo_opt.states, state_name)
      }
    None => geo_state_item_style(geo_opt.states, state_name)
  }
  style.map(style => {
    fill: style.area_color,
    stroke: style.border_color,
    line_width: style.border_width,
    stroke_no_scale: false,
  })
}

///|
fn geo_region_label_show(
  geo_opt : @option.GeoOption,
  region_opt : @option.GeoRegionOption?,
) -> Bool {
  match region_opt {
    Some(region) =>
      region.label.bind(label => label.show).unwrap_or(geo_opt.label.show)
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
      region.label.bind(label => label.color).unwrap_or(geo_opt.label.color)
    None => geo_opt.label.color
  }
}

///|
fn geo_region_label_state_style(
  geo_opt : @option.GeoOption,
  region_opt : @option.GeoRegionOption?,
  state_name : String,
) -> @graphic.DisplayStateStyle? {
  let label = match region_opt {
    Some(region) =>
      match geo_state_label(region.states, state_name) {
        Some(label) => Some(label)
        None => geo_state_label(geo_opt.states, state_name)
      }
    None => geo_state_label(geo_opt.states, state_name)
  }
  match label {
    Some(label) =>
      Some({
        fill: label.color,
        stroke: None,
        line_width: None,
        stroke_no_scale: false,
      })
    None => None
  }
}

///|
fn render_geo_region_outline(
  rings : Array[Array[@graphic.Point]],
  fill : String,
  border_color : String,
  border_width : Double,
  silent : Bool,
  selected : Bool,
  emphasis_style : @graphic.DisplayStateStyle?,
  select_style : @graphic.DisplayStateStyle?,
) -> @graphic.Element {
  let element = @graphic.Element::path_fill_stroke(
    geo_rings_path_d(rings),
    fill,
    border_color,
    border_width,
    1.0,
  ).with_silent(silent)
  let element = match emphasis_style {
    Some(style) => element.with_emphasis_style(style)
    None => element
  }
  let element = match select_style {
    Some(style) => element.with_select_style(style)
    None => element
  }
  if selected {
    element.with_current_states(["select"])
  } else {
    element
  }
}

///|
fn geo_rings_path_d(rings : Array[Array[@graphic.Point]]) -> String {
  let buf = StringBuilder::new()

  for ring_index, _ in rings {
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
  }
  buf.to_string()
}

///|
pub fn render_geo_component(
  opt : @option.ChartOption,
  geo? : @coord.Geo? = None,
) -> Array[@graphic.Element] {
  if opt.geo.length() == 0 {
    return []
  }
  guard geo is Some(geo) else { [] }
  let elems : Array[@graphic.Element] = []
  let geo_opt = if opt.geo.length() > 0 {
    opt.geo[0]
  } else {
    @option.GeoOption::default()
  }

  for region_index, _ in geo.regions {
    let region = geo.regions[region_index]
    let region_opt = geo_region_option_by_name(geo_opt, region.name)
    let polygons = region.screen_polygon_rings(geo)
    let fill = geo_region_fill_color(geo_opt, region_opt, region)
    let border_color = geo_region_border_color(geo_opt, region_opt, region)
    let border_width = geo_region_border_width(geo_opt, region_opt, region)
    let silent = geo_opt.silent || geo_region_silent(region_opt)
    let selected = geo_region_is_selected(region_opt)
    let emphasis_style = geo_region_state_style(geo_opt, region_opt, "emphasis")
    let select_style = geo_region_state_style(geo_opt, region_opt, "select")

    for polygon_index, _ in polygons {
      elems.push(
        render_geo_region_outline(
          polygons[polygon_index],
          fill,
          border_color,
          border_width,
          silent,
          selected,
          emphasis_style,
          select_style,
        ),
      )
    }
    if geo_region_label_show(geo_opt, region_opt) {
      let center = region.screen_center(geo)
      let label = @graphic.Element::text_colored(
        center.x,
        center.y,
        region.name,
        @graphic.TextAnchor::Middle,
        @graphic.TextBaseline::Central,
        geo_region_label_color(geo_opt, region_opt),
      ).with_silent(silent)
      let label = match
        geo_region_label_state_style(geo_opt, region_opt, "emphasis") {
        Some(style) => label.with_emphasis_style(style)
        None => label
      }
      let label = match
        geo_region_label_state_style(geo_opt, region_opt, "select") {
        Some(style) => label.with_select_style(style)
        None => label
      }
      let label = if selected {
        label.with_current_states(["select"])
      } else {
        label
      }
      elems.push(label)
    }
  }
  elems
}

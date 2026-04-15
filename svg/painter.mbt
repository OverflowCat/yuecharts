// Corresponds to: zrender/src/svg/Painter.ts, zrender/src/svg/core.ts,
// zrender/src/svg/graphic.ts, zrender/src/svg/cssEmphasis.ts,
// zrender/src/svg/cssClassId.ts
// Renders graphic elements to SVG output

///|
pub struct CssProperty {
  name : String
  value : String
}

///|
pub struct CssNode {
  selector : String
  properties : Array[CssProperty]
}

///|
pub struct CssStyleCacheEntry {
  style_key : String
  class_name : String
}

///|
pub struct SvgLinearGradientStop {
  offset : Double
  color : String
}

///|
pub struct SvgLinearGradientDef {
  spec : String
  id : String
  x1 : Double
  y1 : Double
  x2 : Double
  y2 : Double
  stops : Array[SvgLinearGradientStop]
}

///|
pub struct BrushScope {
  zr_id : String
  css_nodes : Array[CssNode]
  css_style_cache : Array[CssStyleCacheEntry]
  gradient_defs : Array[SvgLinearGradientDef]
  next_class_id : Int
  next_gradient_id : Int
  emphasis : Bool
}

///|
pub fn BrushScope::new() -> BrushScope {
  {
    zr_id: "zr0",
    css_nodes: [],
    css_style_cache: [],
    gradient_defs: [],
    next_class_id: 0,
    next_gradient_id: 0,
    emphasis: true,
  }
}

///|
fn points_to_svg(points : Array[@graphic.Point]) -> String {
  let buf = StringBuilder::new()
  for i, p in points {
    if i > 0 {
      buf.write_char(' ')
    }
    buf.write_string("\{p.x},\{p.y}")
  }
  buf.to_string()
}

///|
fn opacity_attr(op : Double) -> String {
  if op >= 1.0 {
    ""
  } else {
    " opacity=\"\{op}\""
  }
}

///|
fn css_style_key(properties : Array[CssProperty], with_hover : Bool) -> String {
  let buf = StringBuilder::new()
  if with_hover {
    buf.write_string("hover|")
  } else {
    buf.write_string("plain|")
  }
  let mut i = 0
  while i < properties.length() {
    if i > 0 {
      buf.write_char(';')
    }
    let property = properties[i]
    buf.write_string(property.name)
    buf.write_char('=')
    buf.write_string(property.value)
    i += 1
  }
  buf.to_string()
}

///|
fn css_join_classes(class_names : Array[String]) -> String {
  let buf = StringBuilder::new()
  let mut i = 0
  while i < class_names.length() {
    if i > 0 {
      buf.write_char(' ')
    }
    buf.write_string(class_names[i])
    i += 1
  }
  buf.to_string()
}

///|
fn css_cached_class_name(
  scope : Ref[BrushScope],
  properties : Array[CssProperty],
  with_hover : Bool,
) -> String {
  let style_key = css_style_key(properties, with_hover)
  let mut i = 0
  while i < scope.val.css_style_cache.length() {
    let entry = scope.val.css_style_cache[i]
    if entry.style_key == style_key {
      return entry.class_name
    }
    i += 1
  }
  let class_name = "\{scope.val.zr_id}-cls-\{scope.val.next_class_id}"
  scope.val.css_style_cache.push({ style_key, class_name })
  scope.val.css_nodes.push({
    selector: if with_hover {
      ".\{class_name}:hover"
    } else {
      ".\{class_name}"
    },
    properties,
  })
  scope.val = { ..scope.val, next_class_id: scope.val.next_class_id + 1 }
  class_name
}

///|
fn current_state_contains(
  current_states : Array[String],
  target : String,
) -> Bool {
  let mut i = 0
  while i < current_states.length() {
    if current_states[i] == target {
      return true
    }
    i += 1
  }
  false
}

///|
fn active_display_style(
  meta : @graphic.DisplayableMeta,
) -> @graphic.DisplayStateStyle? {
  if current_state_contains(meta.current_states, "select") {
    meta.states.select
  } else if current_state_contains(meta.current_states, "blur") {
    meta.states.blur
  } else if current_state_contains(meta.current_states, "emphasis") {
    meta.states.emphasis
  } else {
    None
  }
}

///|
fn active_fill_value(
  meta : @graphic.DisplayableMeta,
  normal_fill : String?,
) -> String? {
  match active_display_style(meta).bind(style => style.fill) {
    Some(fill) => Some(fill)
    None => normal_fill
  }
}

///|
fn active_stroke_value(
  meta : @graphic.DisplayableMeta,
  normal_stroke : String?,
) -> String? {
  match active_display_style(meta).bind(style => style.stroke) {
    Some(stroke) => Some(stroke)
    None => normal_stroke
  }
}

///|
fn active_line_width_value(
  meta : @graphic.DisplayableMeta,
  normal_line_width : Double?,
) -> Double? {
  match active_display_style(meta).bind(style => style.line_width) {
    Some(line_width) => Some(line_width)
    None => normal_line_width
  }
}

///|
fn lift_color_or_self(color : String) -> String {
  @graphic.Color::lift_color_string(color).unwrap_or(color)
}

///|
fn resolve_gradient_spec(
  scope : Ref[BrushScope],
  color_str : String,
) -> String? {
  if !color_str.has_prefix("__linear_gradient__|") {
    return None
  }
  let parts = color_str.split("|").collect()
  let mut x1 = 0.0
  let mut y1 = 0.0
  let mut x2 = 0.0
  let mut y2 = 1.0
  let stops : Array[SvgLinearGradientStop] = []
  let mut i = 1
  while i < parts.length() {
    let part = parts[i].to_string()
    if part.has_prefix("x=") {
      let parsed = try? @string.parse_double(part[2:].to_string())
      match parsed {
        Ok(v) => x1 = v
        Err(_) => ()
      }
    } else if part.has_prefix("y=") {
      let parsed = try? @string.parse_double(part[2:].to_string())
      match parsed {
        Ok(v) => y1 = v
        Err(_) => ()
      }
    } else if part.has_prefix("x2=") {
      let parsed = try? @string.parse_double(part[3:].to_string())
      match parsed {
        Ok(v) => x2 = v
        Err(_) => ()
      }
    } else if part.has_prefix("y2=") {
      let parsed = try? @string.parse_double(part[3:].to_string())
      match parsed {
        Ok(v) => y2 = v
        Err(_) => ()
      }
    } else if part.has_prefix("stops=") {
      let stop_specs = part[6:].to_string().split(";").collect()
      for stop_spec in stop_specs {
        let stop_spec_str = stop_spec.to_string()
        let stop_sep = stop_spec_str.find(":")
        match stop_sep {
          Some(idx) => {
            let offset_text = stop_spec_str[:idx].to_string()
            let color_text = stop_spec_str[idx + 1:].to_string()
            let parsed = try? @string.parse_double(offset_text)
            match parsed {
              Ok(offset) => stops.push({ offset, color: color_text })
              Err(_) => ()
            }
          }
          None => ()
        }
      }
    }
    i += 1
  }
  if stops.length() == 0 {
    return None
  }
  let mut j = 0
  while j < scope.val.gradient_defs.length() {
    let existing = scope.val.gradient_defs[j]
    if existing.spec == color_str {
      return Some(existing.id)
    }
    j += 1
  }
  let id = "\{scope.val.zr_id}-g\{scope.val.next_gradient_id}"
  scope.val = { ..scope.val, next_gradient_id: scope.val.next_gradient_id + 1 }
  scope.val.gradient_defs.push({ spec: color_str, id, x1, y1, x2, y2, stops })
  Some(id)
}

///|
fn color_string_attrs(
  attr_name : String,
  color_str : String,
  scope : Ref[BrushScope],
) -> String {
  let buf = StringBuilder::new()
  match resolve_gradient_spec(scope, color_str) {
    Some(id) => buf.write_string(" \{attr_name}=\"url(#\{id})\"")
    None =>
      match @graphic.Color::from_string(color_str) {
        Some(color) => {
          buf.write_string(" \{attr_name}=\"\{color.to_svg_attr()}\"")
          match color.svg_opacity() {
            Some(opacity) =>
              buf.write_string(
                " \{attr_name}-opacity=\"\{@graphic.format_opacity(opacity)}\"",
              )
            None => ()
          }
        }
        None => buf.write_string(" \{attr_name}=\"\{color_str}\"")
      }
  }
  buf.to_string()
}

///|
fn fill_string_attr(color_str : String, scope : Ref[BrushScope]) -> String {
  color_string_attrs("fill", color_str, scope)
}

///|
fn write_stroke_attr_from_base(
  buf : StringBuilder,
  stroke_color : String?,
  stroke_width : Double?,
  dash : Array[Double],
  line_cap : String,
  line_join : String,
  scope : Ref[BrushScope],
) -> Unit {
  match stroke_color {
    Some(stroke_color) => {
      buf.write_string(color_string_attrs("stroke", stroke_color, scope))
      match stroke_width {
        Some(stroke_width) =>
          buf.write_string(" stroke-width=\"\{stroke_width}\"")
        None => ()
      }
      if dash.length() > 0 {
        let dash_str = dash
          .iter()
          .map(fn(d) { d.to_string() })
          .collect()
          .join(",")
        buf.write_string(" stroke-dasharray=\"\{dash_str}\"")
      }
      if line_cap != "butt" {
        buf.write_string(" stroke-linecap=\"\{line_cap}\"")
      }
      if line_join != "miter" {
        buf.write_string(" stroke-linejoin=\"\{line_join}\"")
      }
    }
    None => buf.write_string(" stroke=\"none\"")
  }
}

///|
fn line_path_d(l : @graphic.LineData) -> String {
  "M\{l.x1} \{l.y1}L\{l.x2} \{l.y2}"
}

///|
fn emphasis_fill_value(
  meta : @graphic.DisplayableMeta,
  normal_fill : String?,
) -> String? {
  let from_fill = if current_state_contains(meta.current_states, "select") {
    match meta.states.select {
      Some(select_style) =>
        match select_style.fill {
          Some(fill) => Some(fill)
          None => normal_fill
        }
      None => normal_fill
    }
  } else {
    normal_fill
  }
  match meta.states.emphasis.bind(style => style.fill) {
    Some(fill) => Some(lift_color_or_self(fill))
    None => from_fill.map(fill => lift_color_or_self(fill))
  }
}

///|
fn emphasis_hover_properties(
  meta : @graphic.DisplayableMeta,
  normal_fill : String?,
  scope : Ref[BrushScope],
) -> Array[CssProperty] {
  let properties : Array[CssProperty] = []
  if meta.silent {
    properties.push({ name: "pointer-events", value: "none" })
    return properties
  }
  properties.push({ name: "cursor", value: "pointer" })
  match emphasis_fill_value(meta, normal_fill) {
    Some(fill) =>
      properties.push({
        name: "fill",
        value: match resolve_gradient_spec(scope, fill) {
          Some(id) => "url(#\{id})"
          None => fill
        },
      })
    None => ()
  }
  match meta.states.emphasis {
    Some(style) => {
      match style.stroke {
        Some(stroke) =>
          properties.push({
            name: "stroke",
            value: match resolve_gradient_spec(scope, stroke) {
              Some(id) => "url(#\{id})"
              None => stroke
            },
          })
        None => ()
      }
      match style.line_width {
        Some(line_width) =>
          properties.push({
            name: "stroke-width",
            value: line_width.to_string(),
          })
        None => ()
      }
    }
    None => ()
  }
  properties
}

///|
fn pointer_events_visible_attr(
  fill_value : String?,
  stroke_value : String?,
) -> String? {
  if fill_value == None || stroke_value == None {
    Some("visible")
  } else {
    None
  }
}

///|
fn displayable_class_value(
  meta : @graphic.DisplayableMeta,
  normal_fill : String?,
  scope : Ref[BrushScope],
) -> String? {
  let class_names : Array[String] = []
  match meta.class_name {
    Some(class_name) => class_names.push(class_name)
    None => ()
  }
  if scope.val.emphasis {
    let hover_properties = emphasis_hover_properties(meta, normal_fill, scope)
    if hover_properties.length() > 0 {
      class_names.push(css_cached_class_name(scope, hover_properties, true))
    }
  }
  if class_names.length() > 0 {
    Some(css_join_classes(class_names))
  } else {
    None
  }
}

///|
fn write_displayable_class_attr(
  buf : StringBuilder,
  meta : @graphic.DisplayableMeta,
  normal_fill : String?,
  scope : Ref[BrushScope],
) -> Unit {
  match displayable_class_value(meta, normal_fill, scope) {
    Some(class_value) => buf.write_string(" class=\"\{class_value}\"")
    None => ()
  }
}

///|
fn write_displayable_ecmeta_attrs(
  buf : StringBuilder,
  meta : @graphic.DisplayableMeta,
) -> Unit {
  for attr in meta.ecmeta_attrs {
    buf.write_string(" ecmeta_\{attr.key.to_lower()}=\"\{attr.value}\"")
  }
}

///|
fn gradient_stop_attrs(stop : SvgLinearGradientStop) -> Array[XmlAttr] {
  let attrs : Array[XmlAttr] = []
  attrs.push(XmlAttr::new("offset", "\{stop.offset * 100.0}%"))
  match @graphic.Color::from_string(stop.color) {
    Some(color) => {
      attrs.push(XmlAttr::new("stop-color", color.to_svg_attr()))
      match color.svg_opacity() {
        Some(opacity) =>
          attrs.push(
            XmlAttr::new("stop-opacity", @graphic.format_opacity(opacity)),
          )
        None => ()
      }
    }
    None => attrs.push(XmlAttr::new("stop-color", stop.color))
  }
  attrs
}

///|
fn gradient_defs_node(scope : Ref[BrushScope]) -> XmlNode? {
  if scope.val.gradient_defs.length() == 0 {
    return None
  }
  let defs_children : Array[XmlNode] = []
  for gradient in scope.val.gradient_defs {
    let gradient_attrs : Array[XmlAttr] = [
      XmlAttr::new("id", gradient.id),
      XmlAttr::new("gradientUnits", "objectBoundingBox"),
      XmlAttr::new("x1", gradient.x1.to_string()),
      XmlAttr::new("y1", gradient.y1.to_string()),
      XmlAttr::new("x2", gradient.x2.to_string()),
      XmlAttr::new("y2", gradient.y2.to_string()),
    ]
    let stop_nodes : Array[XmlNode] = []
    for stop in gradient.stops {
      stop_nodes.push(XmlNode::empty("stop", gradient_stop_attrs(stop)))
    }
    defs_children.push(
      XmlNode::element("linearGradient", gradient_attrs, stop_nodes),
    )
  }
  Some(XmlNode::element("defs", [], defs_children))
}

///|
fn gradient_defs_string(scope : Ref[BrushScope]) -> String {
  match gradient_defs_node(scope) {
    Some(node) => {
      let pretty = node.to_pretty_string("  ")
      "\{pretty}\n"
    }
    None => ""
  }
}

///|
fn push_color_xml_attrs(
  attrs : Array[XmlAttr],
  attr_name : String,
  color_str : String,
  scope : Ref[BrushScope],
) -> Unit {
  match resolve_gradient_spec(scope, color_str) {
    Some(id) => push_xml_attr(attrs, attr_name, "url(#\{id})")
    None =>
      match @graphic.Color::from_string(color_str) {
        Some(color) => {
          push_xml_attr(attrs, attr_name, color.to_svg_attr())
          match color.svg_opacity() {
            Some(opacity) =>
              push_xml_attr(
                attrs,
                "\{attr_name}-opacity",
                @graphic.format_opacity(opacity),
              )
            None => ()
          }
        }
        None => push_xml_attr(attrs, attr_name, color_str)
      }
  }
}

///|
fn render_element(
  buf : StringBuilder,
  elem : @graphic.Element,
  indent : String,
  clip_counter : Ref[Int],
  scope : Ref[BrushScope],
) -> Unit {
  match elem {
    Group(g) => render_group(buf, g, indent, clip_counter, scope)
    Rect(r) => render_rect(buf, r, indent, scope)
    Circle(c) => render_circle(buf, c, indent, scope)
    Line(l) => render_line(buf, l, indent, scope)
    Polyline(pl) => render_polyline(buf, pl, indent, scope)
    Polygon(pg) => render_polygon(buf, pg, indent, scope)
    Path(p) => render_path(buf, p, indent, scope)
    Text(t) => render_text(buf, t, indent, scope)
  }
}

///|
fn render_group(
  buf : StringBuilder,
  g : @graphic.GroupData,
  indent : String,
  clip_counter : Ref[Int],
  scope : Ref[BrushScope],
) -> Unit {
  let next = indent + "  "
  match (g.clip_rect, g.clip_path) {
    (Some(cr), _) => {
      let clip_id = "clip-\{clip_counter.val}"
      clip_counter.val = clip_counter.val + 1
      buf.write_string(indent)
      buf.write_string("<clipPath id=\"\{clip_id}\">\n")
      buf.write_string(next)
      buf.write_string(
        "<rect x=\"\{cr.x}\" y=\"\{cr.y}\" width=\"\{cr.width}\" height=\"\{cr.height}\"/>\n",
      )
      buf.write_string(indent + "</clipPath>\n")
      buf.write_string(indent)
      buf.write_string("<g clip-path=\"url(#\{clip_id})\"")
      match g.transform {
        Some(m) => buf.write_string(" transform=\"\{m}\"")
        None => ()
      }
      if g.opacity < 1.0 {
        buf.write_string(" opacity=\"\{g.opacity}\"")
      }
      buf.write_string(">\n")
      for child in g.children {
        render_element(buf, child, next, clip_counter, scope)
      }
      buf.write_string(indent + "</g>\n")
    }
    (None, Some(path_d)) => {
      let clip_id = "clip-\{clip_counter.val}"
      clip_counter.val = clip_counter.val + 1
      buf.write_string(indent)
      buf.write_string("<clipPath id=\"\{clip_id}\">\n")
      buf.write_string(next)
      buf.write_string("<path d=\"\{path_d}\"/>\n")
      buf.write_string(indent + "</clipPath>\n")
      buf.write_string(indent)
      buf.write_string("<g clip-path=\"url(#\{clip_id})\"")
      match g.transform {
        Some(m) => buf.write_string(" transform=\"\{m}\"")
        None => ()
      }
      if g.opacity < 1.0 {
        buf.write_string(" opacity=\"\{g.opacity}\"")
      }
      buf.write_string(">\n")
      for child in g.children {
        render_element(buf, child, next, clip_counter, scope)
      }
      buf.write_string(indent + "</g>\n")
    }
    (None, None) => {
      buf.write_string(indent)
      buf.write_string("<g")
      match g.transform {
        Some(m) => buf.write_string(" transform=\"\{m}\"")
        None => ()
      }
      if g.opacity < 1.0 {
        buf.write_string(" opacity=\"\{g.opacity}\"")
      }
      buf.write_string(">\n")
      for child in g.children {
        render_element(buf, child, next, clip_counter, scope)
      }
      buf.write_string(indent + "</g>\n")
    }
  }
}

///|
fn render_rect(
  buf : StringBuilder,
  r : @graphic.RectData,
  indent : String,
  scope : Ref[BrushScope],
) -> Unit {
  let fill_value = active_fill_value(r.meta, r.fill.map(fill => fill.color))
  let stroke_value = active_stroke_value(
    r.meta,
    r.stroke.map(stroke => stroke.color),
  )
  let stroke_width = active_line_width_value(
    r.meta,
    r.stroke.map(stroke => stroke.width),
  )
  buf.write_string(indent)
  buf.write_string(
    "<rect x=\"\{r.bbox.x}\" y=\"\{r.bbox.y}\" width=\"\{r.bbox.width}\" height=\"\{r.bbox.height}\"",
  )
  if r.rx > 0.0 {
    buf.write_string(" rx=\"\{r.rx}\"")
  }
  if r.ry > 0.0 {
    buf.write_string(" ry=\"\{r.ry}\"")
  }
  match fill_value {
    Some(fill_value) => buf.write_string(fill_string_attr(fill_value, scope))
    None => buf.write_string(" fill=\"none\"")
  }
  match r.stroke {
    Some(s) =>
      write_stroke_attr_from_base(
        buf,
        stroke_value,
        stroke_width,
        s.dash,
        s.line_cap,
        s.line_join,
        scope,
      )
    None =>
      write_stroke_attr_from_base(
        buf,
        stroke_value,
        stroke_width,
        [],
        "butt",
        "miter",
        scope,
      )
  }
  buf.write_string(opacity_attr(r.opacity))
  match pointer_events_visible_attr(fill_value, stroke_value) {
    Some(value) => buf.write_string(" pointer-events=\"\{value}\"")
    None => ()
  }
  write_displayable_ecmeta_attrs(buf, r.meta)
  write_displayable_class_attr(buf, r.meta, fill_value, scope)
  buf.write_string("/>\n")
}

///|
fn render_circle(
  buf : StringBuilder,
  c : @graphic.CircleData,
  indent : String,
  scope : Ref[BrushScope],
) -> Unit {
  let fill_value = active_fill_value(c.meta, c.fill.map(fill => fill.color))
  let stroke_value = active_stroke_value(
    c.meta,
    c.stroke.map(stroke => stroke.color),
  )
  let stroke_width = active_line_width_value(
    c.meta,
    c.stroke.map(stroke => stroke.width),
  )
  buf.write_string(indent)
  buf.write_string("<circle cx=\"\{c.cx}\" cy=\"\{c.cy}\" r=\"\{c.r}\"")
  match fill_value {
    Some(fill_value) => buf.write_string(fill_string_attr(fill_value, scope))
    None => buf.write_string(" fill=\"none\"")
  }
  match c.stroke {
    Some(s) =>
      write_stroke_attr_from_base(
        buf,
        stroke_value,
        stroke_width,
        s.dash,
        s.line_cap,
        s.line_join,
        scope,
      )
    None =>
      write_stroke_attr_from_base(
        buf,
        stroke_value,
        stroke_width,
        [],
        "butt",
        "miter",
        scope,
      )
  }
  buf.write_string(opacity_attr(c.opacity))
  match pointer_events_visible_attr(fill_value, stroke_value) {
    Some(value) => buf.write_string(" pointer-events=\"\{value}\"")
    None => ()
  }
  write_displayable_ecmeta_attrs(buf, c.meta)
  write_displayable_class_attr(buf, c.meta, fill_value, scope)
  buf.write_string("/>\n")
}

///|
fn render_line(
  buf : StringBuilder,
  l : @graphic.LineData,
  indent : String,
  scope : Ref[BrushScope],
) -> Unit {
  let stroke_value = active_stroke_value(l.meta, Some(l.stroke.color))
  let stroke_width = active_line_width_value(l.meta, Some(l.stroke.width))
  buf.write_string(indent)
  buf.write_string("<path d=\"\{line_path_d(l)}\"")
  write_stroke_attr_from_base(
    buf,
    stroke_value,
    stroke_width,
    l.stroke.dash,
    l.stroke.line_cap,
    l.stroke.line_join,
    scope,
  )
  buf.write_string(" fill=\"none\"")
  buf.write_string(opacity_attr(l.opacity))
  write_displayable_ecmeta_attrs(buf, l.meta)
  write_displayable_class_attr(buf, l.meta, None, scope)
  buf.write_string("/>\n")
}

///|
fn render_polyline(
  buf : StringBuilder,
  pl : @graphic.PolylineData,
  indent : String,
  scope : Ref[BrushScope],
) -> Unit {
  let fill_value = active_fill_value(pl.meta, Some(pl.fill.to_svg()))
  let stroke_value = active_stroke_value(pl.meta, Some(pl.stroke.color))
  let stroke_width = active_line_width_value(pl.meta, Some(pl.stroke.width))
  buf.write_string(indent)
  buf.write_string("<polyline points=\"\{points_to_svg(pl.points)}\"")
  match fill_value {
    Some(fill_value) => buf.write_string(fill_string_attr(fill_value, scope))
    None => buf.write_string(" fill=\"none\"")
  }
  write_stroke_attr_from_base(
    buf,
    stroke_value,
    stroke_width,
    pl.stroke.dash,
    pl.stroke.line_cap,
    pl.stroke.line_join,
    scope,
  )
  buf.write_string(opacity_attr(pl.opacity))
  match pointer_events_visible_attr(fill_value, stroke_value) {
    Some(value) => buf.write_string(" pointer-events=\"\{value}\"")
    None => ()
  }
  write_displayable_ecmeta_attrs(buf, pl.meta)
  write_displayable_class_attr(buf, pl.meta, fill_value, scope)
  buf.write_string("/>\n")
}

///|
fn render_polygon(
  buf : StringBuilder,
  pg : @graphic.PolygonData,
  indent : String,
  scope : Ref[BrushScope],
) -> Unit {
  let fill_value = active_fill_value(pg.meta, pg.fill.map(fill => fill.color))
  let stroke_value = active_stroke_value(
    pg.meta,
    pg.stroke.map(stroke => stroke.color),
  )
  let stroke_width = active_line_width_value(
    pg.meta,
    pg.stroke.map(stroke => stroke.width),
  )
  buf.write_string(indent)
  buf.write_string("<polygon points=\"\{points_to_svg(pg.points)}\"")
  match fill_value {
    Some(fill_value) => buf.write_string(fill_string_attr(fill_value, scope))
    None => buf.write_string(" fill=\"none\"")
  }
  match pg.stroke {
    Some(s) =>
      write_stroke_attr_from_base(
        buf,
        stroke_value,
        stroke_width,
        s.dash,
        s.line_cap,
        s.line_join,
        scope,
      )
    None =>
      write_stroke_attr_from_base(
        buf,
        stroke_value,
        stroke_width,
        [],
        "butt",
        "miter",
        scope,
      )
  }
  buf.write_string(opacity_attr(pg.opacity))
  match pointer_events_visible_attr(fill_value, stroke_value) {
    Some(value) => buf.write_string(" pointer-events=\"\{value}\"")
    None => ()
  }
  write_displayable_ecmeta_attrs(buf, pg.meta)
  write_displayable_class_attr(buf, pg.meta, fill_value, scope)
  buf.write_string("/>\n")
}

///|
fn render_path(
  buf : StringBuilder,
  p : @graphic.PathData,
  indent : String,
  scope : Ref[BrushScope],
) -> Unit {
  let fill_value = active_fill_value(p.meta, p.fill.map(fill => fill.color))
  let stroke_value = active_stroke_value(
    p.meta,
    p.stroke.map(stroke => stroke.color),
  )
  let stroke_width = active_line_width_value(
    p.meta,
    p.stroke.map(stroke => stroke.width),
  )
  buf.write_string(indent)
  buf.write_string("<path d=\"\{p.d}\"")
  match fill_value {
    Some(fill_value) => buf.write_string(fill_string_attr(fill_value, scope))
    None => buf.write_string(" fill=\"none\"")
  }
  match p.stroke {
    Some(s) =>
      write_stroke_attr_from_base(
        buf,
        stroke_value,
        stroke_width,
        s.dash,
        s.line_cap,
        s.line_join,
        scope,
      )
    None =>
      write_stroke_attr_from_base(
        buf,
        stroke_value,
        stroke_width,
        [],
        "butt",
        "miter",
        scope,
      )
  }
  buf.write_string(opacity_attr(p.opacity))
  match pointer_events_visible_attr(fill_value, stroke_value) {
    Some(value) => buf.write_string(" pointer-events=\"\{value}\"")
    None => ()
  }
  write_displayable_ecmeta_attrs(buf, p.meta)
  write_displayable_class_attr(buf, p.meta, fill_value, scope)
  buf.write_string("/>\n")
}

///|
fn render_text(
  buf : StringBuilder,
  t : @graphic.TextData,
  indent : String,
  scope : Ref[BrushScope],
) -> Unit {
  buf.write_string(indent)
  let s = t.style
  let fill_value = active_fill_value(t.meta, Some(s.fill.to_svg())).unwrap_or(
    s.fill.to_svg(),
  )
  buf.write_string("<text x=\"\{t.x}\" y=\"\{t.y}\"")
  buf.write_string(fill_string_attr(fill_value, scope))
  buf.write_string(" font-size=\"\{s.font_size}\"")
  if s.font_family != "sans-serif" {
    buf.write_string(" font-family=\"\{s.font_family}\"")
  }
  if s.font_weight != "normal" {
    buf.write_string(" font-weight=\"\{s.font_weight}\"")
  }
  let anchor_str = s.anchor.to_svg()
  if anchor_str != "start" {
    buf.write_string(" text-anchor=\"\{anchor_str}\"")
  }
  let baseline_str = s.baseline.to_svg()
  if baseline_str != "alphabetic" {
    buf.write_string(" dominant-baseline=\"\{baseline_str}\"")
  }
  buf.write_string(opacity_attr(t.opacity))
  write_displayable_ecmeta_attrs(buf, t.meta)
  write_displayable_class_attr(buf, t.meta, Some(fill_value), scope)
  buf.write_string(">")
  buf.write_string(painter_xml_escape(t.content))
  buf.write_string("</text>\n")
}

///|
fn css_nodes_to_string(css_nodes : Array[CssNode]) -> String {
  if css_nodes.length() == 0 {
    return ""
  }
  let buf = StringBuilder::new()
  buf.write_string("<![CDATA[\n")
  let mut node_index = 0
  while node_index < css_nodes.length() {
    let node = css_nodes[node_index]
    buf.write_string(node.selector)
    buf.write_string(" {\n")
    let mut property_index = 0
    while property_index < node.properties.length() {
      let property = node.properties[property_index]
      buf.write_string(property.name)
      buf.write_char(':')
      buf.write_string(property.value)
      buf.write_string(";\n")
      property_index += 1
    }
    buf.write_string("}\n")
    node_index += 1
  }
  buf.write_string("]]>")
  buf.to_string()
}

///|
fn painter_xml_escape(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    match c {
      '&' => buf.write_string("&amp;")
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
fn push_xml_attr(attrs : Array[XmlAttr], name : String, value : String) -> Unit {
  attrs.push(XmlAttr::new(name, value))
}

///|
fn push_xml_attr_opt(
  attrs : Array[XmlAttr],
  name : String,
  value : String?,
) -> Unit {
  match value {
    Some(value) => attrs.push(XmlAttr::new(name, value))
    None => ()
  }
}

///|
fn push_displayable_ecmeta_attrs(
  attrs : Array[XmlAttr],
  meta : @graphic.DisplayableMeta,
) -> Unit {
  for attr in meta.ecmeta_attrs {
    push_xml_attr(attrs, "ecmeta_\{attr.key.to_lower()}", attr.value)
  }
}

///|
fn push_stroke_attrs_from_base(
  attrs : Array[XmlAttr],
  stroke_color : String?,
  stroke_width : Double?,
  dash : Array[Double],
  line_cap : String,
  line_join : String,
  scope : Ref[BrushScope],
) -> Unit {
  match stroke_color {
    Some(stroke_color) => {
      push_color_xml_attrs(attrs, "stroke", stroke_color, scope)
      match stroke_width {
        Some(stroke_width) =>
          push_xml_attr(attrs, "stroke-width", stroke_width.to_string())
        None => ()
      }
      if dash.length() > 0 {
        let dash_str = dash
          .iter()
          .map(fn(d) { d.to_string() })
          .collect()
          .join(",")
        push_xml_attr(attrs, "stroke-dasharray", dash_str)
      }
      if line_cap != "butt" {
        push_xml_attr(attrs, "stroke-linecap", line_cap)
      }
      if line_join != "miter" {
        push_xml_attr(attrs, "stroke-linejoin", line_join)
      }
    }
    None => push_xml_attr(attrs, "stroke", "none")
  }
}

///|
fn build_element_nodes(
  elem : @graphic.Element,
  clip_counter : Ref[Int],
  scope : Ref[BrushScope],
) -> Array[XmlNode] {
  match elem {
    Group(g) => build_group_nodes(g, clip_counter, scope)
    Rect(r) => [build_rect_node(r, scope)]
    Circle(c) => [build_circle_node(c, scope)]
    Line(l) => [build_line_node(l, scope)]
    Polyline(pl) => [build_polyline_node(pl, scope)]
    Polygon(pg) => [build_polygon_node(pg, scope)]
    Path(p) => [build_path_node(p, scope)]
    Text(t) => [build_text_node(t, scope)]
  }
}

///|
fn append_xml_nodes(dst : Array[XmlNode], src : Array[XmlNode]) -> Unit {
  for node in src {
    dst.push(node)
  }
}

///|
fn build_group_nodes(
  g : @graphic.GroupData,
  clip_counter : Ref[Int],
  scope : Ref[BrushScope],
) -> Array[XmlNode] {
  let attrs : Array[XmlAttr] = []
  match g.transform {
    Some(m) => push_xml_attr(attrs, "transform", "\{m}")
    None => ()
  }
  if g.opacity < 1.0 {
    push_xml_attr(attrs, "opacity", g.opacity.to_string())
  }
  let children : Array[XmlNode] = []
  for child in g.children {
    append_xml_nodes(children, build_element_nodes(child, clip_counter, scope))
  }
  match (g.clip_rect, g.clip_path) {
    (Some(cr), _) => {
      let clip_id = "clip-\{clip_counter.val}"
      clip_counter.val = clip_counter.val + 1
      let clip_rect_attrs : Array[XmlAttr] = []
      push_xml_attr(clip_rect_attrs, "x", cr.x.to_string())
      push_xml_attr(clip_rect_attrs, "y", cr.y.to_string())
      push_xml_attr(clip_rect_attrs, "width", cr.width.to_string())
      push_xml_attr(clip_rect_attrs, "height", cr.height.to_string())
      let clip_node = XmlNode::element(
        "clipPath",
        [XmlAttr::new("id", clip_id)],
        [XmlNode::empty("rect", clip_rect_attrs)],
      )
      let group_attrs : Array[XmlAttr] = [
        XmlAttr::new("clip-path", "url(#\{clip_id})"),
      ]
      for attr in attrs {
        group_attrs.push(attr)
      }
      [clip_node, XmlNode::element("g", group_attrs, children)]
    }
    (None, Some(path_d)) => {
      let clip_id = "clip-\{clip_counter.val}"
      clip_counter.val = clip_counter.val + 1
      let clip_path_node = XmlNode::element(
        "clipPath",
        [XmlAttr::new("id", clip_id)],
        [XmlNode::empty("path", [XmlAttr::new("d", path_d)])],
      )
      let group_attrs : Array[XmlAttr] = [
        XmlAttr::new("clip-path", "url(#\{clip_id})"),
      ]
      for attr in attrs {
        group_attrs.push(attr)
      }
      [clip_path_node, XmlNode::element("g", group_attrs, children)]
    }
    (None, None) => [XmlNode::element("g", attrs, children)]
  }
}

///|
fn build_rect_node(r : @graphic.RectData, scope : Ref[BrushScope]) -> XmlNode {
  let fill_value = active_fill_value(r.meta, r.fill.map(fill => fill.color))
  let stroke_value = active_stroke_value(
    r.meta,
    r.stroke.map(stroke => stroke.color),
  )
  let stroke_width = active_line_width_value(
    r.meta,
    r.stroke.map(stroke => stroke.width),
  )
  let attrs : Array[XmlAttr] = []
  push_xml_attr(attrs, "x", r.bbox.x.to_string())
  push_xml_attr(attrs, "y", r.bbox.y.to_string())
  push_xml_attr(attrs, "width", r.bbox.width.to_string())
  push_xml_attr(attrs, "height", r.bbox.height.to_string())
  if r.rx > 0.0 {
    push_xml_attr(attrs, "rx", r.rx.to_string())
  }
  if r.ry > 0.0 {
    push_xml_attr(attrs, "ry", r.ry.to_string())
  }
  match fill_value {
    Some(fill_value) => push_color_xml_attrs(attrs, "fill", fill_value, scope)
    None => push_xml_attr(attrs, "fill", "none")
  }
  match r.stroke {
    Some(s) =>
      push_stroke_attrs_from_base(
        attrs,
        stroke_value,
        stroke_width,
        s.dash,
        s.line_cap,
        s.line_join,
        scope,
      )
    None =>
      push_stroke_attrs_from_base(
        attrs,
        stroke_value,
        stroke_width,
        [],
        "butt",
        "miter",
        scope,
      )
  }
  if r.opacity < 1.0 {
    push_xml_attr(attrs, "opacity", r.opacity.to_string())
  }
  match pointer_events_visible_attr(fill_value, stroke_value) {
    Some(value) => push_xml_attr(attrs, "pointer-events", value)
    None => ()
  }
  push_displayable_ecmeta_attrs(attrs, r.meta)
  push_xml_attr_opt(
    attrs,
    "class",
    displayable_class_value(r.meta, fill_value, scope),
  )
  XmlNode::empty("rect", attrs)
}

///|
fn build_circle_node(
  c : @graphic.CircleData,
  scope : Ref[BrushScope],
) -> XmlNode {
  let fill_value = active_fill_value(c.meta, c.fill.map(fill => fill.color))
  let stroke_value = active_stroke_value(
    c.meta,
    c.stroke.map(stroke => stroke.color),
  )
  let stroke_width = active_line_width_value(
    c.meta,
    c.stroke.map(stroke => stroke.width),
  )
  let attrs : Array[XmlAttr] = []
  push_xml_attr(attrs, "cx", c.cx.to_string())
  push_xml_attr(attrs, "cy", c.cy.to_string())
  push_xml_attr(attrs, "r", c.r.to_string())
  match fill_value {
    Some(fill_value) => push_color_xml_attrs(attrs, "fill", fill_value, scope)
    None => push_xml_attr(attrs, "fill", "none")
  }
  match c.stroke {
    Some(s) =>
      push_stroke_attrs_from_base(
        attrs,
        stroke_value,
        stroke_width,
        s.dash,
        s.line_cap,
        s.line_join,
        scope,
      )
    None =>
      push_stroke_attrs_from_base(
        attrs,
        stroke_value,
        stroke_width,
        [],
        "butt",
        "miter",
        scope,
      )
  }
  if c.opacity < 1.0 {
    push_xml_attr(attrs, "opacity", c.opacity.to_string())
  }
  match pointer_events_visible_attr(fill_value, stroke_value) {
    Some(value) => push_xml_attr(attrs, "pointer-events", value)
    None => ()
  }
  push_displayable_ecmeta_attrs(attrs, c.meta)
  push_xml_attr_opt(
    attrs,
    "class",
    displayable_class_value(c.meta, fill_value, scope),
  )
  XmlNode::empty("circle", attrs)
}

///|
fn build_line_node(l : @graphic.LineData, scope : Ref[BrushScope]) -> XmlNode {
  let stroke_value = active_stroke_value(l.meta, Some(l.stroke.color))
  let stroke_width = active_line_width_value(l.meta, Some(l.stroke.width))
  let attrs : Array[XmlAttr] = []
  push_xml_attr(attrs, "d", line_path_d(l))
  push_stroke_attrs_from_base(
    attrs,
    stroke_value,
    stroke_width,
    l.stroke.dash,
    l.stroke.line_cap,
    l.stroke.line_join,
    scope,
  )
  push_xml_attr(attrs, "fill", "none")
  if l.opacity < 1.0 {
    push_xml_attr(attrs, "opacity", l.opacity.to_string())
  }
  push_displayable_ecmeta_attrs(attrs, l.meta)
  push_xml_attr_opt(
    attrs,
    "class",
    displayable_class_value(l.meta, None, scope),
  )
  XmlNode::empty("path", attrs)
}

///|
fn build_polyline_node(
  pl : @graphic.PolylineData,
  scope : Ref[BrushScope],
) -> XmlNode {
  let fill_value = active_fill_value(pl.meta, Some(pl.fill.to_svg()))
  let stroke_value = active_stroke_value(pl.meta, Some(pl.stroke.color))
  let stroke_width = active_line_width_value(pl.meta, Some(pl.stroke.width))
  let attrs : Array[XmlAttr] = []
  push_xml_attr(attrs, "points", points_to_svg(pl.points))
  match fill_value {
    Some(fill_value) => push_color_xml_attrs(attrs, "fill", fill_value, scope)
    None => push_xml_attr(attrs, "fill", "none")
  }
  push_stroke_attrs_from_base(
    attrs,
    stroke_value,
    stroke_width,
    pl.stroke.dash,
    pl.stroke.line_cap,
    pl.stroke.line_join,
    scope,
  )
  if pl.opacity < 1.0 {
    push_xml_attr(attrs, "opacity", pl.opacity.to_string())
  }
  match pointer_events_visible_attr(fill_value, stroke_value) {
    Some(value) => push_xml_attr(attrs, "pointer-events", value)
    None => ()
  }
  push_displayable_ecmeta_attrs(attrs, pl.meta)
  push_xml_attr_opt(
    attrs,
    "class",
    displayable_class_value(pl.meta, fill_value, scope),
  )
  XmlNode::empty("polyline", attrs)
}

///|
fn build_polygon_node(
  pg : @graphic.PolygonData,
  scope : Ref[BrushScope],
) -> XmlNode {
  let fill_value = active_fill_value(pg.meta, pg.fill.map(fill => fill.color))
  let stroke_value = active_stroke_value(
    pg.meta,
    pg.stroke.map(stroke => stroke.color),
  )
  let stroke_width = active_line_width_value(
    pg.meta,
    pg.stroke.map(stroke => stroke.width),
  )
  let attrs : Array[XmlAttr] = []
  push_xml_attr(attrs, "points", points_to_svg(pg.points))
  match fill_value {
    Some(fill_value) => push_color_xml_attrs(attrs, "fill", fill_value, scope)
    None => push_xml_attr(attrs, "fill", "none")
  }
  match pg.stroke {
    Some(s) =>
      push_stroke_attrs_from_base(
        attrs,
        stroke_value,
        stroke_width,
        s.dash,
        s.line_cap,
        s.line_join,
        scope,
      )
    None =>
      push_stroke_attrs_from_base(
        attrs,
        stroke_value,
        stroke_width,
        [],
        "butt",
        "miter",
        scope,
      )
  }
  if pg.opacity < 1.0 {
    push_xml_attr(attrs, "opacity", pg.opacity.to_string())
  }
  match pointer_events_visible_attr(fill_value, stroke_value) {
    Some(value) => push_xml_attr(attrs, "pointer-events", value)
    None => ()
  }
  push_displayable_ecmeta_attrs(attrs, pg.meta)
  push_xml_attr_opt(
    attrs,
    "class",
    displayable_class_value(pg.meta, fill_value, scope),
  )
  XmlNode::empty("polygon", attrs)
}

///|
fn build_path_node(p : @graphic.PathData, scope : Ref[BrushScope]) -> XmlNode {
  let fill_value = active_fill_value(p.meta, p.fill.map(fill => fill.color))
  let stroke_value = active_stroke_value(
    p.meta,
    p.stroke.map(stroke => stroke.color),
  )
  let stroke_width = active_line_width_value(
    p.meta,
    p.stroke.map(stroke => stroke.width),
  )
  let attrs : Array[XmlAttr] = []
  push_xml_attr(attrs, "d", p.d)
  match fill_value {
    Some(fill_value) => push_color_xml_attrs(attrs, "fill", fill_value, scope)
    None => push_xml_attr(attrs, "fill", "none")
  }
  match p.stroke {
    Some(s) =>
      push_stroke_attrs_from_base(
        attrs,
        stroke_value,
        stroke_width,
        s.dash,
        s.line_cap,
        s.line_join,
        scope,
      )
    None =>
      push_stroke_attrs_from_base(
        attrs,
        stroke_value,
        stroke_width,
        [],
        "butt",
        "miter",
        scope,
      )
  }
  if p.opacity < 1.0 {
    push_xml_attr(attrs, "opacity", p.opacity.to_string())
  }
  match pointer_events_visible_attr(fill_value, stroke_value) {
    Some(value) => push_xml_attr(attrs, "pointer-events", value)
    None => ()
  }
  push_displayable_ecmeta_attrs(attrs, p.meta)
  push_xml_attr_opt(
    attrs,
    "class",
    displayable_class_value(p.meta, fill_value, scope),
  )
  XmlNode::empty("path", attrs)
}

///|
fn build_text_node(t : @graphic.TextData, scope : Ref[BrushScope]) -> XmlNode {
  let s = t.style
  let fill_value = active_fill_value(t.meta, Some(s.fill.to_svg())).unwrap_or(
    s.fill.to_svg(),
  )
  let attrs : Array[XmlAttr] = []
  push_xml_attr(attrs, "x", t.x.to_string())
  push_xml_attr(attrs, "y", t.y.to_string())
  push_color_xml_attrs(attrs, "fill", fill_value, scope)
  push_xml_attr(attrs, "font-size", s.font_size.to_string())
  if s.font_family != "sans-serif" {
    push_xml_attr(attrs, "font-family", s.font_family)
  }
  if s.font_weight != "normal" {
    push_xml_attr(attrs, "font-weight", s.font_weight)
  }
  let anchor_str = s.anchor.to_svg()
  if anchor_str != "start" {
    push_xml_attr(attrs, "text-anchor", anchor_str)
  }
  let baseline_str = s.baseline.to_svg()
  if baseline_str != "alphabetic" {
    push_xml_attr(attrs, "dominant-baseline", baseline_str)
  }
  if t.opacity < 1.0 {
    push_xml_attr(attrs, "opacity", t.opacity.to_string())
  }
  push_displayable_ecmeta_attrs(attrs, t.meta)
  push_xml_attr_opt(
    attrs,
    "class",
    displayable_class_value(t.meta, Some(fill_value), scope),
  )
  XmlNode::element("text", attrs, [XmlNode::text_escaped(t.content)])
}

///|
pub fn paint_xml(
  elements : Array[@graphic.Element],
  width : Double,
  height : Double,
  background : @graphic.Color?,
  accessibility : SvgAccessibility?,
) -> XmlNode {
  let clip_counter : Ref[Int] = Ref::new(0)
  let scope : Ref[BrushScope] = Ref::new(BrushScope::new())
  let children : Array[XmlNode] = []
  match accessibility {
    Some(acc) => {
      match acc.title {
        Some(title) =>
          children.push(
            XmlNode::element("title", [], [XmlNode::text_escaped(title)]),
          )
        None => ()
      }
      match acc.desc {
        Some(desc) =>
          children.push(
            XmlNode::element("desc", [], [XmlNode::text_escaped(desc)]),
          )
        None => ()
      }
    }
    None => ()
  }
  let body_children : Array[XmlNode] = []
  for elem in elements {
    append_xml_nodes(
      body_children,
      build_element_nodes(elem, clip_counter, scope),
    )
  }
  match gradient_defs_node(scope) {
    Some(node) => children.push(node)
    None => ()
  }
  match background {
    Some(bg) => {
      let bg_attrs : Array[XmlAttr] = [
        XmlAttr::new("x", "0"),
        XmlAttr::new("y", "0"),
        XmlAttr::new("width", width.to_string()),
        XmlAttr::new("height", height.to_string()),
      ]
      push_color_xml_attrs(bg_attrs, "fill", bg.to_svg(), scope)
      children.push(XmlNode::empty("rect", bg_attrs))
    }
    None => ()
  }
  append_xml_nodes(children, body_children)
  let css_text = css_nodes_to_string(scope.val.css_nodes)
  if css_text != "" {
    children.push(XmlNode::element("style", [], [XmlNode::text_raw(css_text)]))
  }
  let svg_attrs : Array[XmlAttr] = [
    XmlAttr::new("width", width.to_string()),
    XmlAttr::new("height", height.to_string()),
    XmlAttr::new("xmlns", "http://www.w3.org/2000/svg"),
    XmlAttr::new("xmlns:xlink", "http://www.w3.org/1999/xlink"),
    XmlAttr::new("version", "1.1"),
    XmlAttr::new("baseProfile", "full"),
    XmlAttr::new("viewBox", "0 0 \{width} \{height}"),
  ]
  match accessibility {
    Some(acc) => {
      push_xml_attr(svg_attrs, "role", acc.role)
      match acc.aria_label {
        Some(label) => push_xml_attr(svg_attrs, "aria-label", label)
        None => ()
      }
    }
    None => ()
  }
  XmlNode::element("svg", svg_attrs, children)
}

///|
pub struct SvgAccessibility {
  role : String
  aria_label : String?
  title : String?
  desc : String?
}

///|
pub fn SvgAccessibility::new(
  role : String,
  aria_label : String?,
  title : String?,
  desc : String?,
) -> SvgAccessibility {
  { role, aria_label, title, desc }
}

///|
/// Render a list of elements to an SVG document string.
pub fn paint(
  elements : Array[@graphic.Element],
  width : Double,
  height : Double,
  background : @graphic.Color?,
  accessibility : SvgAccessibility?,
) -> String {
  let body_buf = StringBuilder::new()
  let clip_counter : Ref[Int] = Ref::new(0)
  let scope : Ref[BrushScope] = Ref::new(BrushScope::new())
  let background_str = match background {
    Some(bg) => {
      let attrs = color_string_attrs("fill", bg.to_svg(), scope)
      Some(
        "  <rect x=\"0\" y=\"0\" width=\"\{width}\" height=\"\{height}\"\{attrs}/>\n",
      )
    }
    None => None
  }
  for elem in elements {
    render_element(body_buf, elem, "  ", clip_counter, scope)
  }
  let css_text = css_nodes_to_string(scope.val.css_nodes)
  let defs_text = gradient_defs_string(scope)

  let buf = StringBuilder::new()
  buf.write_string("<svg width=\"\{width}\" height=\"\{height}\"")
  buf.write_string(" xmlns=\"http://www.w3.org/2000/svg\"")
  buf.write_string(" xmlns:xlink=\"http://www.w3.org/1999/xlink\"")
  buf.write_string(" version=\"1.1\"")
  buf.write_string(" baseProfile=\"full\"")
  buf.write_string(" viewBox=\"0 0 \{width} \{height}\"")
  match accessibility {
    Some(acc) => {
      buf.write_string(" role=\"\{acc.role}\"")
      match acc.aria_label {
        Some(label) =>
          buf.write_string(" aria-label=\"\{painter_xml_escape(label)}\"")
        None => ()
      }
    }
    None => ()
  }
  buf.write_string(">\n")
  match accessibility {
    Some(acc) => {
      match acc.title {
        Some(title) =>
          buf.write_string("  <title>\{painter_xml_escape(title)}</title>\n")
        None => ()
      }
      match acc.desc {
        Some(desc) =>
          buf.write_string("  <desc>\{painter_xml_escape(desc)}</desc>\n")
        None => ()
      }
    }
    None => ()
  }
  buf.write_string(defs_text)
  match background_str {
    Some(bg_str) => buf.write_string(bg_str)
    None => ()
  }
  buf.write_string(body_buf.to_string())
  if css_text != "" {
    buf.write_string("<style>")
    buf.write_string(css_text)
    buf.write_string("</style>\n")
  }
  buf.write_string("</svg>")
  buf.to_string()
}

///|
pub fn paint_utf8(
  elements : Array[@graphic.Element],
  width : Double,
  height : Double,
  background : @graphic.Color?,
  accessibility : SvgAccessibility?,
) -> Bytes {
  paint_xml(elements, width, height, background, accessibility).to_pretty_utf8(
    "  ",
  )
}

///|
pub fn paint_utf16le(
  elements : Array[@graphic.Element],
  width : Double,
  height : Double,
  background : @graphic.Color?,
  accessibility : SvgAccessibility?,
) -> Bytes {
  paint_xml(elements, width, height, background, accessibility).to_pretty_utf16le(
    "  ",
  )
}

///|
pub fn paint_utf16(
  elements : Array[@graphic.Element],
  width : Double,
  height : Double,
  background : @graphic.Color?,
  accessibility : SvgAccessibility?,
) -> Bytes {
  paint_utf16le(elements, width, height, background, accessibility)
}

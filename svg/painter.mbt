// Corresponds to: zrender/src/svg/Painter.ts, zrender/src/svg/core.ts,
// zrender/src/svg/cssEmphasis.ts
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
pub struct BrushScope {
  css_nodes : Array[CssNode]
  css_style_cache : Array[CssStyleCacheEntry]
  next_class_id : Int
  emphasis : Bool
}

///|
pub fn BrushScope::new() -> BrushScope {
  { css_nodes: [], css_style_cache: [], next_class_id: 0, emphasis: true }
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
fn stroke_attrs(s : @graphic.StrokeStyle) -> String {
  let buf = StringBuilder::new()
  buf.write_string(" stroke=\"\{s.color.to_svg()}\"")
  buf.write_string(" stroke-width=\"\{s.width}\"")
  if s.dash.length() > 0 {
    let dash_str = s.dash
      .iter()
      .map(fn(d) { d.to_string() })
      .collect()
      .join(",")
    buf.write_string(" stroke-dasharray=\"\{dash_str}\"")
  }
  if s.line_cap != "butt" {
    buf.write_string(" stroke-linecap=\"\{s.line_cap}\"")
  }
  if s.line_join != "miter" {
    buf.write_string(" stroke-linejoin=\"\{s.line_join}\"")
  }
  buf.to_string()
}

///|
fn fill_attr(color : @graphic.Color) -> String {
  " fill=\"\{color.to_svg()}\""
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
  let class_name = "zr-cls-\{scope.val.next_class_id}"
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
  match active_display_style(meta) {
    Some(style) =>
      match style.fill {
        Some(fill) => Some(fill)
        None => normal_fill
      }
    None => normal_fill
  }
}

///|
fn active_stroke_value(
  meta : @graphic.DisplayableMeta,
  normal_stroke : String?,
) -> String? {
  match active_display_style(meta) {
    Some(style) =>
      match style.stroke {
        Some(stroke) => Some(stroke)
        None => normal_stroke
      }
    None => normal_stroke
  }
}

///|
fn active_line_width_value(
  meta : @graphic.DisplayableMeta,
  normal_line_width : Double?,
) -> Double? {
  match active_display_style(meta) {
    Some(style) =>
      match style.line_width {
        Some(line_width) => Some(line_width)
        None => normal_line_width
      }
    None => normal_line_width
  }
}

///|
fn fill_string_attr(color_str : String) -> String {
  " fill=\"\{color_str}\""
}

///|
fn write_stroke_attr_from_base(
  buf : StringBuilder,
  stroke_color : String?,
  stroke_width : Double?,
  dash : Array[Double],
  line_cap : String,
  line_join : String,
) -> Unit {
  match stroke_color {
    Some(stroke_color) => {
      buf.write_string(" stroke=\"\{stroke_color}\"")
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
fn emphasis_fill_value(
  meta : @graphic.DisplayableMeta,
  normal_fill : String?,
) -> String? {
  match meta.states.emphasis {
    Some(style) =>
      match style.fill {
        Some(fill) => Some(fill)
        None => {
          let from_fill = if current_state_contains(
              meta.current_states,
              "select",
            ) {
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
          match from_fill {
            Some(fill) =>
              match @graphic.Color::lift_color_string(fill) {
                Some(lifted_fill) => Some(lifted_fill)
                None => Some(fill)
              }
            None => None
          }
        }
      }
    None => None
  }
}

///|
fn emphasis_hover_properties(
  meta : @graphic.DisplayableMeta,
  normal_fill : String?,
) -> Array[CssProperty] {
  let properties : Array[CssProperty] = []
  if meta.silent {
    properties.push({ name: "pointer-events", value: "none" })
    return properties
  }
  match meta.states.emphasis {
    Some(style) => {
      properties.push({ name: "cursor", value: "pointer" })
      match emphasis_fill_value(meta, normal_fill) {
        Some(fill) => properties.push({ name: "fill", value: fill })
        None => ()
      }
      match style.stroke {
        Some(stroke) => properties.push({ name: "stroke", value: stroke })
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
fn write_displayable_class_attr(
  buf : StringBuilder,
  meta : @graphic.DisplayableMeta,
  normal_fill : String?,
  scope : Ref[BrushScope],
) -> Unit {
  let class_names : Array[String] = []
  match meta.class_name {
    Some(class_name) => class_names.push(class_name)
    None => ()
  }
  if scope.val.emphasis {
    let hover_properties = emphasis_hover_properties(meta, normal_fill)
    if hover_properties.length() > 0 {
      class_names.push(css_cached_class_name(scope, hover_properties, true))
    }
  }
  if class_names.length() > 0 {
    buf.write_string(" class=\"\{css_join_classes(class_names)}\"")
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
  match g.clip_rect {
    Some(cr) => {
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
    None => {
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
  let fill_value = active_fill_value(
    r.meta,
    r.fill.map(fill => fill.color.to_svg()),
  )
  let stroke_value = active_stroke_value(
    r.meta,
    r.stroke.map(stroke => stroke.color.to_svg()),
  )
  let stroke_width = active_line_width_value(
    r.meta,
    r.stroke.map(stroke => stroke.width),
  )
  buf.write_string(indent)
  buf.write_string(
    "<rect x=\"\{r.bbox.x}\" y=\"\{r.bbox.y}\" width=\"\{r.bbox.width}\" height=\"\{r.bbox.height}\"",
  )
  write_displayable_class_attr(buf, r.meta, fill_value, scope)
  if r.rx > 0.0 {
    buf.write_string(" rx=\"\{r.rx}\"")
  }
  if r.ry > 0.0 {
    buf.write_string(" ry=\"\{r.ry}\"")
  }
  match fill_value {
    Some(fill_value) => buf.write_string(fill_string_attr(fill_value))
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
      )
    None =>
      write_stroke_attr_from_base(
        buf,
        stroke_value,
        stroke_width,
        [],
        "butt",
        "miter",
      )
  }
  buf.write_string(opacity_attr(r.opacity))
  buf.write_string("/>\n")
}

///|
fn render_circle(
  buf : StringBuilder,
  c : @graphic.CircleData,
  indent : String,
  scope : Ref[BrushScope],
) -> Unit {
  let fill_value = active_fill_value(
    c.meta,
    c.fill.map(fill => fill.color.to_svg()),
  )
  let stroke_value = active_stroke_value(
    c.meta,
    c.stroke.map(stroke => stroke.color.to_svg()),
  )
  let stroke_width = active_line_width_value(
    c.meta,
    c.stroke.map(stroke => stroke.width),
  )
  buf.write_string(indent)
  buf.write_string("<circle cx=\"\{c.cx}\" cy=\"\{c.cy}\" r=\"\{c.r}\"")
  write_displayable_class_attr(buf, c.meta, fill_value, scope)
  match fill_value {
    Some(fill_value) => buf.write_string(fill_string_attr(fill_value))
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
      )
    None =>
      write_stroke_attr_from_base(
        buf,
        stroke_value,
        stroke_width,
        [],
        "butt",
        "miter",
      )
  }
  buf.write_string(opacity_attr(c.opacity))
  buf.write_string("/>\n")
}

///|
fn render_line(
  buf : StringBuilder,
  l : @graphic.LineData,
  indent : String,
  scope : Ref[BrushScope],
) -> Unit {
  let stroke_value = active_stroke_value(l.meta, Some(l.stroke.color.to_svg()))
  let stroke_width = active_line_width_value(l.meta, Some(l.stroke.width))
  buf.write_string(indent)
  buf.write_string(
    "<line x1=\"\{l.x1}\" y1=\"\{l.y1}\" x2=\"\{l.x2}\" y2=\"\{l.y2}\"",
  )
  write_displayable_class_attr(buf, l.meta, None, scope)
  write_stroke_attr_from_base(
    buf,
    stroke_value,
    stroke_width,
    l.stroke.dash,
    l.stroke.line_cap,
    l.stroke.line_join,
  )
  buf.write_string(" fill=\"none\"")
  buf.write_string(opacity_attr(l.opacity))
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
  let stroke_value = active_stroke_value(
    pl.meta,
    Some(pl.stroke.color.to_svg()),
  )
  let stroke_width = active_line_width_value(pl.meta, Some(pl.stroke.width))
  buf.write_string(indent)
  buf.write_string("<polyline points=\"\{points_to_svg(pl.points)}\"")
  write_displayable_class_attr(buf, pl.meta, fill_value, scope)
  match fill_value {
    Some(fill_value) => buf.write_string(fill_string_attr(fill_value))
    None => buf.write_string(" fill=\"none\"")
  }
  write_stroke_attr_from_base(
    buf,
    stroke_value,
    stroke_width,
    pl.stroke.dash,
    pl.stroke.line_cap,
    pl.stroke.line_join,
  )
  buf.write_string(opacity_attr(pl.opacity))
  buf.write_string("/>\n")
}

///|
fn render_polygon(
  buf : StringBuilder,
  pg : @graphic.PolygonData,
  indent : String,
  scope : Ref[BrushScope],
) -> Unit {
  let fill_value = active_fill_value(
    pg.meta,
    pg.fill.map(fill => fill.color.to_svg()),
  )
  let stroke_value = active_stroke_value(
    pg.meta,
    pg.stroke.map(stroke => stroke.color.to_svg()),
  )
  let stroke_width = active_line_width_value(
    pg.meta,
    pg.stroke.map(stroke => stroke.width),
  )
  buf.write_string(indent)
  buf.write_string("<polygon points=\"\{points_to_svg(pg.points)}\"")
  write_displayable_class_attr(buf, pg.meta, fill_value, scope)
  match fill_value {
    Some(fill_value) => buf.write_string(fill_string_attr(fill_value))
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
      )
    None =>
      write_stroke_attr_from_base(
        buf,
        stroke_value,
        stroke_width,
        [],
        "butt",
        "miter",
      )
  }
  buf.write_string(opacity_attr(pg.opacity))
  buf.write_string("/>\n")
}

///|
fn render_path(
  buf : StringBuilder,
  p : @graphic.PathData,
  indent : String,
  scope : Ref[BrushScope],
) -> Unit {
  let fill_value = active_fill_value(
    p.meta,
    p.fill.map(fill => fill.color.to_svg()),
  )
  let stroke_value = active_stroke_value(
    p.meta,
    p.stroke.map(stroke => stroke.color.to_svg()),
  )
  let stroke_width = active_line_width_value(
    p.meta,
    p.stroke.map(stroke => stroke.width),
  )
  buf.write_string(indent)
  buf.write_string("<path d=\"\{p.d}\"")
  write_displayable_class_attr(buf, p.meta, fill_value, scope)
  match fill_value {
    Some(fill_value) => buf.write_string(fill_string_attr(fill_value))
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
      )
    None =>
      write_stroke_attr_from_base(
        buf,
        stroke_value,
        stroke_width,
        [],
        "butt",
        "miter",
      )
  }
  buf.write_string(opacity_attr(p.opacity))
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
  buf.write_string("<text x=\"\{t.x}\" y=\"\{t.y}\" fill=\"\{fill_value}\"")
  write_displayable_class_attr(buf, t.meta, Some(fill_value), scope)
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
  buf.write_string(">")
  buf.write_string(xml_escape(t.content))
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
fn xml_escape(s : String) -> String {
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
  for elem in elements {
    render_element(body_buf, elem, "  ", clip_counter, scope)
  }
  let css_text = css_nodes_to_string(scope.val.css_nodes)

  let buf = StringBuilder::new()
  buf.write_string("<svg xmlns=\"http://www.w3.org/2000/svg\"")
  buf.write_string(
    " width=\"\{width}\" height=\"\{height}\" viewBox=\"0 0 \{width} \{height}\"",
  )
  match accessibility {
    Some(acc) => {
      buf.write_string(" role=\"\{acc.role}\"")
      match acc.aria_label {
        Some(label) => buf.write_string(" aria-label=\"\{xml_escape(label)}\"")
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
          buf.write_string("  <title>\{xml_escape(title)}</title>\n")
        None => ()
      }
      match acc.desc {
        Some(desc) => buf.write_string("  <desc>\{xml_escape(desc)}</desc>\n")
        None => ()
      }
    }
    None => ()
  }
  match background {
    Some(bg) =>
      buf.write_string(
        "  <rect x=\"0\" y=\"0\" width=\"\{width}\" height=\"\{height}\" fill=\"\{bg.to_svg()}\"/>\n",
      )
    None => ()
  }
  if css_text != "" {
    buf.write_string("  <style>")
    buf.write_string(css_text)
    buf.write_string("</style>\n")
  }
  buf.write_string(body_buf.to_string())
  buf.write_string("</svg>")
  buf.to_string()
}

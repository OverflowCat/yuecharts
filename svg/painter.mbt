// Corresponds to: zrender/src/svg/Painter.ts
// Renders graphic elements to SVG output

///|
/// SVG painter: walks the scene graph and produces an SVG string.
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
fn render_element(
  buf : StringBuilder,
  elem : @graphic.Element,
  indent : String,
) -> Unit {
  match elem {
    Group(g) => render_group(buf, g, indent)
    Rect(r) => render_rect(buf, r, indent)
    Circle(c) => render_circle(buf, c, indent)
    Line(l) => render_line(buf, l, indent)
    Polyline(pl) => render_polyline(buf, pl, indent)
    Polygon(pg) => render_polygon(buf, pg, indent)
    Path(p) => render_path(buf, p, indent)
    Text(t) => render_text(buf, t, indent)
  }
}

///|
fn render_group(
  buf : StringBuilder,
  g : @graphic.GroupData,
  indent : String,
) -> Unit {
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
  let next = indent + "  "
  for child in g.children {
    render_element(buf, child, next)
  }
  buf.write_string(indent + "</g>\n")
}

///|
fn render_rect(
  buf : StringBuilder,
  r : @graphic.RectData,
  indent : String,
) -> Unit {
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
  match r.fill {
    Some(f) => buf.write_string(fill_attr(f.color))
    None => buf.write_string(" fill=\"none\"")
  }
  match r.stroke {
    Some(s) => buf.write_string(stroke_attrs(s))
    None => buf.write_string(" stroke=\"none\"")
  }
  buf.write_string(opacity_attr(r.opacity))
  buf.write_string("/>\n")
}

///|
fn render_circle(
  buf : StringBuilder,
  c : @graphic.CircleData,
  indent : String,
) -> Unit {
  buf.write_string(indent)
  buf.write_string("<circle cx=\"\{c.cx}\" cy=\"\{c.cy}\" r=\"\{c.r}\"")
  match c.fill {
    Some(f) => buf.write_string(fill_attr(f.color))
    None => buf.write_string(" fill=\"none\"")
  }
  match c.stroke {
    Some(s) => buf.write_string(stroke_attrs(s))
    None => buf.write_string(" stroke=\"none\"")
  }
  buf.write_string(opacity_attr(c.opacity))
  buf.write_string("/>\n")
}

///|
fn render_line(
  buf : StringBuilder,
  l : @graphic.LineData,
  indent : String,
) -> Unit {
  buf.write_string(indent)
  buf.write_string(
    "<line x1=\"\{l.x1}\" y1=\"\{l.y1}\" x2=\"\{l.x2}\" y2=\"\{l.y2}\"",
  )
  buf.write_string(stroke_attrs(l.stroke))
  buf.write_string(" fill=\"none\"")
  buf.write_string(opacity_attr(l.opacity))
  buf.write_string("/>\n")
}

///|
fn render_polyline(
  buf : StringBuilder,
  pl : @graphic.PolylineData,
  indent : String,
) -> Unit {
  buf.write_string(indent)
  buf.write_string("<polyline points=\"\{points_to_svg(pl.points)}\"")
  buf.write_string(fill_attr(pl.fill))
  buf.write_string(stroke_attrs(pl.stroke))
  buf.write_string(opacity_attr(pl.opacity))
  buf.write_string("/>\n")
}

///|
fn render_polygon(
  buf : StringBuilder,
  pg : @graphic.PolygonData,
  indent : String,
) -> Unit {
  buf.write_string(indent)
  buf.write_string("<polygon points=\"\{points_to_svg(pg.points)}\"")
  match pg.fill {
    Some(f) => buf.write_string(fill_attr(f.color))
    None => buf.write_string(" fill=\"none\"")
  }
  match pg.stroke {
    Some(s) => buf.write_string(stroke_attrs(s))
    None => buf.write_string(" stroke=\"none\"")
  }
  buf.write_string(opacity_attr(pg.opacity))
  buf.write_string("/>\n")
}

///|
fn render_path(
  buf : StringBuilder,
  p : @graphic.PathData,
  indent : String,
) -> Unit {
  buf.write_string(indent)
  buf.write_string("<path d=\"\{p.d}\"")
  match p.fill {
    Some(f) => buf.write_string(fill_attr(f.color))
    None => buf.write_string(" fill=\"none\"")
  }
  match p.stroke {
    Some(s) => buf.write_string(stroke_attrs(s))
    None => buf.write_string(" stroke=\"none\"")
  }
  buf.write_string(opacity_attr(p.opacity))
  buf.write_string("/>\n")
}

///|
fn render_text(
  buf : StringBuilder,
  t : @graphic.TextData,
  indent : String,
) -> Unit {
  buf.write_string(indent)
  let s = t.style
  buf.write_string(
    "<text x=\"\{t.x}\" y=\"\{t.y}\" fill=\"\{s.fill.to_svg()}\"",
  )
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
  // Escape XML special chars in text content
  buf.write_string(">")
  buf.write_string(xml_escape(t.content))
  buf.write_string("</text>\n")
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
/// Render a list of elements to an SVG document string.
pub fn paint(
  elements : Array[@graphic.Element],
  width : Double,
  height : Double,
  background : @graphic.Color?,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{width}\" height=\"\{height}\" viewBox=\"0 0 \{width} \{height}\">\n",
  )
  match background {
    Some(bg) =>
      buf.write_string(
        "  <rect x=\"0\" y=\"0\" width=\"\{width}\" height=\"\{height}\" fill=\"\{bg.to_svg()}\"/>\n",
      )
    None => ()
  }
  for elem in elements {
    render_element(buf, elem, "  ")
  }
  buf.write_string("</svg>")
  buf.to_string()
}

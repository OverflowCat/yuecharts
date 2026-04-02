// Corresponds to: zrender/src/Element.ts, zrender/src/graphic/Displayable.ts,
// zrender/src/graphic/Shape.ts, zrender/src/graphic/Path.ts
// and various zrender/src/graphic/shape/* primitives (Rect, Circle, Line, Text, etc.)

///|
/// Style applied to strokes (lines, borders).
pub struct StrokeStyle {
  color : Color
  width : Double
  dash : Array[Double]
  line_cap : String // "butt" | "round" | "square"
  line_join : String // "miter" | "round" | "bevel"
}

///|
pub impl Default for StrokeStyle with default() {
  { color: black, width: 1.0, dash: [], line_cap: "butt", line_join: "miter" }
}

///|
/// Style applied to filled shapes.
pub struct FillStyle {
  color : Color
}

///|
pub impl Default for FillStyle with default() {
  { color: black }
}

///|
/// Text anchor alignment.
pub(all) enum TextAnchor {
  Start
  Middle
  End
}

///|
pub fn TextAnchor::to_svg(self : TextAnchor) -> String {
  match self {
    Start => "start"
    Middle => "middle"
    End => "end"
  }
}

///|
/// Text baseline alignment.
pub(all) enum TextBaseline {
  Auto
  Top
  Hanging
  Middle
  /// SVG "central" — equivalent to CSS middle, used by ECharts for title/labels
  Central
  Alphabetic
  Ideographic
  Bottom
}

///|
pub fn TextBaseline::auto() -> TextBaseline {
  Auto
}

///|
pub fn TextBaseline::to_svg(self : TextBaseline) -> String {
  match self {
    Auto => "auto"
    Top => "text-top"
    Hanging => "hanging"
    Middle => "middle"
    Central => "central"
    Alphabetic => "alphabetic"
    Ideographic => "ideographic"
    Bottom => "text-bottom"
  }
}

///|
/// Style for text elements.
pub struct TextStyle {
  fill : Color
  font_size : Double
  font_family : String
  font_weight : String
  anchor : TextAnchor
  baseline : TextBaseline
}

///|
pub impl Default for TextStyle with default() {
  {
    fill: black,
    font_size: 12.0,
    font_family: "sans-serif",
    font_weight: "normal",
    anchor: TextAnchor::Start,
    baseline: TextBaseline::Alphabetic,
  }
}

///|
/// Corresponds to: zrender/src/graphic/Displayable.ts (state style payload)
pub(all) struct DisplayStateStyle {
  fill : String?
  stroke : String?
  line_width : Double?
  stroke_no_scale : Bool
}

///|
pub impl Default for DisplayStateStyle with default() {
  { fill: None, stroke: None, line_width: None, stroke_no_scale: false }
}

///|
/// Corresponds to: zrender/src/graphic/Displayable.ts (states bag)
pub(all) struct DisplayStates {
  emphasis : DisplayStateStyle?
  select : DisplayStateStyle?
  blur : DisplayStateStyle?
}

///|
pub impl Default for DisplayStates with default() {
  { emphasis: None, select: None, blur: None }
}

///|
/// Corresponds to: zrender/src/graphic/Displayable.ts (interactive metadata)
pub(all) struct DisplayableMeta {
  class_name : String?
  silent : Bool
  current_states : Array[String]
  states : DisplayStates
}

///|
pub impl Default for DisplayableMeta with default() {
  {
    class_name: None,
    silent: false,
    current_states: [],
    states: DisplayStates::default(),
  }
}

///|
/// Scene graph element — the core ADT for the graphic layer.
pub enum Element {
  /// A group containing child elements (used for transforming/clipping subtrees).
  Group(GroupData)
  /// A rectangle.
  Rect(RectData)
  /// A circle.
  Circle(CircleData)
  /// A straight line segment.
  Line(LineData)
  /// An open polyline (stroke only).
  Polyline(PolylineData)
  /// A closed polygon (fill + stroke).
  Polygon(PolygonData)
  /// An SVG path element.
  Path(PathData)
  /// A text label.
  Text(TextData)
}

///|
pub struct GroupData {
  children : Array[Element]
  transform : Matrix?
  clip_rect : BBox?
  clip_path : String?
  opacity : Double
}

///|
pub fn GroupData::new(children : Array[Element]) -> GroupData {
  { children, transform: None, clip_rect: None, clip_path: None, opacity: 1.0 }
}

///|
pub struct RectData {
  bbox : BBox
  rx : Double // corner radius x
  ry : Double // corner radius y
  fill : FillStyle?
  stroke : StrokeStyle?
  opacity : Double
  meta : DisplayableMeta
}

///|
pub fn RectData::new(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> RectData {
  {
    bbox: BBox::new(x, y, w, h),
    rx: 0.0,
    ry: 0.0,
    fill: Some(FillStyle::default()),
    stroke: None,
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  }
}

///|
pub struct CircleData {
  cx : Double
  cy : Double
  r : Double
  fill : FillStyle?
  stroke : StrokeStyle?
  opacity : Double
  meta : DisplayableMeta
}

///|
pub fn CircleData::new(cx : Double, cy : Double, r : Double) -> CircleData {
  {
    cx,
    cy,
    r,
    fill: Some(FillStyle::default()),
    stroke: None,
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  }
}

///|
pub struct LineData {
  x1 : Double
  y1 : Double
  x2 : Double
  y2 : Double
  stroke : StrokeStyle
  opacity : Double
  meta : DisplayableMeta
}

///|
pub fn LineData::new(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> LineData {
  {
    x1,
    y1,
    x2,
    y2,
    stroke: StrokeStyle::default(),
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  }
}

///|
pub struct PolylineData {
  points : Array[Point]
  stroke : StrokeStyle
  fill : Color // usually transparent
  opacity : Double
  meta : DisplayableMeta
}

///|
pub fn PolylineData::new(points : Array[Point]) -> PolylineData {
  {
    points,
    stroke: StrokeStyle::default(),
    fill: transparent,
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  }
}

///|
pub struct PolygonData {
  points : Array[Point]
  fill : FillStyle?
  stroke : StrokeStyle?
  opacity : Double
  meta : DisplayableMeta
}

///|
pub fn PolygonData::new(points : Array[Point]) -> PolygonData {
  {
    points,
    fill: Some(FillStyle::default()),
    stroke: None,
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  }
}

///|
/// SVG path data (the `d` attribute value).
pub struct PathData {
  d : String
  fill : FillStyle?
  stroke : StrokeStyle?
  opacity : Double
  meta : DisplayableMeta
}

///|
pub fn PathData::new(d : String) -> PathData {
  {
    d,
    fill: None,
    stroke: Some(StrokeStyle::default()),
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  }
}

///|
pub struct TextData {
  x : Double
  y : Double
  content : String
  style : TextStyle
  opacity : Double
  meta : DisplayableMeta
}

///|
pub fn TextData::new(x : Double, y : Double, content : String) -> TextData {
  {
    x,
    y,
    content,
    style: TextStyle::default(),
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  }
}

///|
pub fn TextData::with_anchor(self : TextData, anchor : TextAnchor) -> TextData {
  { ..self, style: { ..self.style, anchor, } }
}

///|
pub fn TextData::with_baseline(
  self : TextData,
  baseline : TextBaseline,
) -> TextData {
  { ..self, style: { ..self.style, baseline, } }
}

///|
pub fn Element::with_silent(self : Element, silent : Bool) -> Element {
  match self {
    Group(g) => Group(g)
    Rect(r) => Rect({ ..r, meta: { ..r.meta, silent, } })
    Circle(c) => Circle({ ..c, meta: { ..c.meta, silent, } })
    Line(l) => Line({ ..l, meta: { ..l.meta, silent, } })
    Polyline(pl) => Polyline({ ..pl, meta: { ..pl.meta, silent, } })
    Polygon(pg) => Polygon({ ..pg, meta: { ..pg.meta, silent, } })
    Path(p) => Path({ ..p, meta: { ..p.meta, silent, } })
    Text(t) => Text({ ..t, meta: { ..t.meta, silent, } })
  }
}

///|
pub fn Element::with_emphasis_style(
  self : Element,
  style : DisplayStateStyle,
) -> Element {
  match self {
    Group(g) => Group(g)
    Rect(r) =>
      Rect({
        ..r,
        meta: { ..r.meta, states: { ..r.meta.states, emphasis: Some(style) } },
      })
    Circle(c) =>
      Circle({
        ..c,
        meta: { ..c.meta, states: { ..c.meta.states, emphasis: Some(style) } },
      })
    Line(l) =>
      Line({
        ..l,
        meta: { ..l.meta, states: { ..l.meta.states, emphasis: Some(style) } },
      })
    Polyline(pl) =>
      Polyline({
        ..pl,
        meta: { ..pl.meta, states: { ..pl.meta.states, emphasis: Some(style) } },
      })
    Polygon(pg) =>
      Polygon({
        ..pg,
        meta: { ..pg.meta, states: { ..pg.meta.states, emphasis: Some(style) } },
      })
    Path(p) =>
      Path({
        ..p,
        meta: { ..p.meta, states: { ..p.meta.states, emphasis: Some(style) } },
      })
    Text(t) =>
      Text({
        ..t,
        meta: { ..t.meta, states: { ..t.meta.states, emphasis: Some(style) } },
      })
  }
}

///|
pub fn Element::with_select_style(
  self : Element,
  style : DisplayStateStyle,
) -> Element {
  match self {
    Group(g) => Group(g)
    Rect(r) =>
      Rect({
        ..r,
        meta: { ..r.meta, states: { ..r.meta.states, select: Some(style) } },
      })
    Circle(c) =>
      Circle({
        ..c,
        meta: { ..c.meta, states: { ..c.meta.states, select: Some(style) } },
      })
    Line(l) =>
      Line({
        ..l,
        meta: { ..l.meta, states: { ..l.meta.states, select: Some(style) } },
      })
    Polyline(pl) =>
      Polyline({
        ..pl,
        meta: { ..pl.meta, states: { ..pl.meta.states, select: Some(style) } },
      })
    Polygon(pg) =>
      Polygon({
        ..pg,
        meta: { ..pg.meta, states: { ..pg.meta.states, select: Some(style) } },
      })
    Path(p) =>
      Path({
        ..p,
        meta: { ..p.meta, states: { ..p.meta.states, select: Some(style) } },
      })
    Text(t) =>
      Text({
        ..t,
        meta: { ..t.meta, states: { ..t.meta.states, select: Some(style) } },
      })
  }
}

///|
pub fn Element::with_current_states(
  self : Element,
  current_states : Array[String],
) -> Element {
  match self {
    Group(g) => Group(g)
    Rect(r) => Rect({ ..r, meta: { ..r.meta, current_states, } })
    Circle(c) => Circle({ ..c, meta: { ..c.meta, current_states, } })
    Line(l) => Line({ ..l, meta: { ..l.meta, current_states, } })
    Polyline(pl) => Polyline({ ..pl, meta: { ..pl.meta, current_states, } })
    Polygon(pg) => Polygon({ ..pg, meta: { ..pg.meta, current_states, } })
    Path(p) => Path({ ..p, meta: { ..p.meta, current_states, } })
    Text(t) => Text({ ..t, meta: { ..t.meta, current_states, } })
  }
}

// ---- builder helpers ----

///|
pub fn Element::group(children : Array[Element]) -> Element {
  Group(GroupData::new(children))
}

///|
pub fn Element::group_transformed(
  children : Array[Element],
  transform : Matrix,
) -> Element {
  Group({ ..GroupData::new(children), transform: Some(transform) })
}

///|
pub fn Element::group_transformed_opacity(
  children : Array[Element],
  transform : Matrix,
  opacity : Double,
) -> Element {
  Group({ ..GroupData::new(children), transform: Some(transform), opacity })
}

///|
pub fn Element::group_clipped(
  children : Array[Element],
  clip_rect : BBox,
) -> Element {
  Group({ ..GroupData::new(children), clip_rect: Some(clip_rect) })
}

///|
pub fn Element::group_clipped_path(
  children : Array[Element],
  clip_path : String,
) -> Element {
  Group({ ..GroupData::new(children), clip_path: Some(clip_path) })
}

///|
pub fn Element::rect(x : Double, y : Double, w : Double, h : Double) -> Element {
  Rect(RectData::new(x, y, w, h))
}

///|
pub fn Element::circle(cx : Double, cy : Double, r : Double) -> Element {
  Circle(CircleData::new(cx, cy, r))
}

///|
pub fn Element::line(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Element {
  Line(LineData::new(x1, y1, x2, y2))
}

///|
/// Line stroked with a CSS/hex color string and specified width.
pub fn Element::line_colored(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  color_str : String,
  width : Double,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  let stroke = { color, width, dash: [], line_cap: "butt", line_join: "miter" }
  Line({
    x1,
    y1,
    x2,
    y2,
    stroke,
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Line stroked with a CSS/hex color string, dash pattern, and explicit opacity.
pub fn Element::line_colored_dashed(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  color_str : String,
  width : Double,
  dash : Array[Double],
  opacity : Double,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  let stroke = { color, width, dash, line_cap: "butt", line_join: "miter" }
  Line({ x1, y1, x2, y2, stroke, opacity, meta: DisplayableMeta::default() })
}

///|
/// Text element with anchor, baseline, and explicit fill color.
pub fn Element::text_colored(
  x : Double,
  y : Double,
  content : String,
  anchor : TextAnchor,
  baseline : TextBaseline,
  color_str : String,
) -> Element {
  let fill = Color::from_string(color_str).unwrap_or(black)
  let data = TextData::new(x, y, content)
    .with_anchor(anchor)
    .with_baseline(baseline)
  Text({ ..data, style: { ..data.style, fill, } })
}

///|
/// Title text element: bold, 18px, `dominant-baseline="central"`.
/// Matches ECharts title style from echarts/src/component/title/install.ts:
///   fontSize=18, fontWeight='bold', fill=tokens.color.neutral80.
pub fn Element::text_title(
  x : Double,
  y : Double,
  content : String,
  anchor : TextAnchor,
  color_str : String,
) -> Element {
  let fill = Color::from_string(color_str).unwrap_or(black)
  let style = {
    fill,
    font_size: 18.0,
    font_family: "sans-serif",
    font_weight: "bold",
    anchor,
    baseline: TextBaseline::Central, // dominant-baseline="central"
  }
  Text({ x, y, content, style, opacity: 1.0, meta: DisplayableMeta::default() })
}

///|
pub fn Element::polyline(points : Array[Point]) -> Element {
  Polyline(PolylineData::new(points))
}

///|
pub fn Element::polygon(points : Array[Point]) -> Element {
  Polygon(PolygonData::new(points))
}

///|
pub fn Element::path(d : String) -> Element {
  Path(PathData::new(d))
}

///|
pub fn Element::text(x : Double, y : Double, content : String) -> Element {
  Text(TextData::new(x, y, content))
}

///|
/// Text element with custom anchor and baseline.
pub fn Element::text_styled(
  x : Double,
  y : Double,
  content : String,
  anchor : TextAnchor,
  baseline : TextBaseline,
) -> Element {
  let data = TextData::new(x, y, content)
    .with_anchor(anchor)
    .with_baseline(baseline)
  Text(data)
}

///|
/// Rect filled with a CSS/hex color string (falls back to black on parse failure).
pub fn Element::rect_colored(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  color_str : String,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  Rect({
    bbox: BBox::new(x, y, w, h),
    rx: 0.0,
    ry: 0.0,
    fill: Some({ color, }),
    stroke: None,
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
pub fn Element::rect_colored_opacity(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  color_str : String,
  opacity : Double,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  Rect({
    bbox: BBox::new(x, y, w, h),
    rx: 0.0,
    ry: 0.0,
    fill: Some({ color, }),
    stroke: None,
    opacity,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Polyline stroked with a CSS/hex color string.
pub fn Element::polyline_stroked(
  points : Array[Point],
  color_str : String,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  let stroke = {
    color,
    width: 2.0,
    dash: [],
    line_cap: "round",
    line_join: "round",
  }
  Polyline({
    points,
    stroke,
    fill: transparent,
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Thin polyline for connector/leader lines (stroke-width=1, butt cap).
pub fn Element::polyline_leader(
  points : Array[Point],
  color_str : String,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  let stroke = {
    color,
    width: 1.0,
    dash: [],
    line_cap: "butt",
    line_join: "miter",
  }
  Polyline({
    points,
    stroke,
    fill: transparent,
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Circle filled with a CSS/hex color string.
pub fn Element::circle_colored(
  cx : Double,
  cy : Double,
  r : Double,
  color_str : String,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  Circle({
    cx,
    cy,
    r,
    fill: Some({ color, }),
    stroke: None,
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Circle filled with a CSS/hex color string and explicit element opacity.
pub fn Element::circle_colored_opacity(
  cx : Double,
  cy : Double,
  r : Double,
  color_str : String,
  opacity : Double,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  Circle({
    cx,
    cy,
    r,
    fill: Some({ color, }),
    stroke: None,
    opacity,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Rect with stroke only (fill = transparent), stroked with the given color.
pub fn Element::rect_outlined(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  color_str : String,
  stroke_width : Double,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  let stroke = {
    color,
    width: stroke_width,
    dash: [],
    line_cap: "butt",
    line_join: "miter",
  }
  Rect({
    bbox: BBox::new(x, y, w, h),
    rx: 0.0,
    ry: 0.0,
    fill: None,
    stroke: Some(stroke),
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Circle stroked with a CSS/hex color string (no fill).
pub fn Element::circle_stroked(
  cx : Double,
  cy : Double,
  r : Double,
  color_str : String,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  let stroke = {
    color,
    width: 1.0,
    dash: [],
    line_cap: "butt",
    line_join: "miter",
  }
  Circle({
    cx,
    cy,
    r,
    fill: None,
    stroke: Some(stroke),
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Circle with both a fill and a stroke.
pub fn Element::circle_fill_stroke(
  cx : Double,
  cy : Double,
  r : Double,
  fill_str : String,
  stroke_str : String,
  stroke_width : Double,
) -> Element {
  let fill_color = Color::from_string(fill_str).unwrap_or(black)
  let stroke_color = Color::from_string(stroke_str).unwrap_or(black)
  Circle({
    cx,
    cy,
    r,
    fill: Some({ color: fill_color }),
    stroke: Some({
      color: stroke_color,
      width: stroke_width,
      dash: [],
      line_cap: "butt",
      line_join: "miter",
    }),
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Path stroked with a CSS/hex color string.
pub fn Element::path_stroked(d : String, color_str : String) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  let stroke = {
    color,
    width: 1.0,
    dash: [],
    line_cap: "butt",
    line_join: "miter",
  }
  Path({
    d,
    fill: None,
    stroke: Some(stroke),
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Path stroked with round line caps and configurable width (for thick arcs).
pub fn Element::path_stroked_round(
  d : String,
  color_str : String,
  width : Double,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  let stroke = { color, width, dash: [], line_cap: "round", line_join: "round" }
  Path({
    d,
    fill: None,
    stroke: Some(stroke),
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Path filled with a CSS/hex color string (semi-transparent area).
pub fn Element::path_filled(
  d : String,
  color_str : String,
  opacity : Double,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  Path({
    d,
    fill: Some({ color, }),
    stroke: None,
    opacity,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Path with both fill and stroke colors.
pub fn Element::path_fill_stroke(
  d : String,
  fill_color_str : String,
  stroke_color_str : String,
  stroke_width : Double,
  opacity : Double,
) -> Element {
  let fill = Color::from_string(fill_color_str).unwrap_or(black)
  let stroke_c = Color::from_string(stroke_color_str).unwrap_or(black)
  Path({
    d,
    fill: Some({ color: fill }),
    stroke: Some({
      color: stroke_c,
      width: stroke_width,
      dash: [],
      line_cap: "butt",
      line_join: "miter",
    }),
    opacity,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Polygon with stroke only (no fill).
pub fn Element::polygon_stroked(
  pts : Array[Point],
  stroke_color : Color,
  stroke_width : Double,
) -> Element {
  Polygon({
    points: pts,
    fill: None,
    stroke: Some({
      color: stroke_color,
      width: stroke_width,
      dash: [],
      line_cap: "butt",
      line_join: "miter",
    }),
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Polygon with stroke only (no fill), round line joins (for series lines).
pub fn Element::polygon_stroked_round(
  pts : Array[Point],
  stroke_color : Color,
  stroke_width : Double,
) -> Element {
  Polygon({
    points: pts,
    fill: None,
    stroke: Some({
      color: stroke_color,
      width: stroke_width,
      dash: [],
      line_cap: "round",
      line_join: "round",
    }),
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Polygon with both fill and stroke colors.
pub fn Element::polygon_fill_stroke(
  pts : Array[Point],
  fill_color : Color,
  stroke_color : Color,
  stroke_width : Double,
  opacity : Double,
) -> Element {
  Polygon({
    points: pts,
    fill: Some({ color: fill_color }),
    stroke: Some({
      color: stroke_color,
      width: stroke_width,
      dash: [],
      line_cap: "round",
      line_join: "round",
    }),
    opacity,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Rect with both fill and stroke colors.
pub fn Element::rect_fill_stroke(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  fill_color_str : String,
  stroke_color_str : String,
  stroke_width : Double,
) -> Element {
  let fill = Color::from_string(fill_color_str).unwrap_or(black)
  let stroke_c = Color::from_string(stroke_color_str).unwrap_or(black)
  Rect({
    bbox: BBox::new(x, y, w, h),
    rx: 0.0,
    ry: 0.0,
    fill: Some({ color: fill }),
    stroke: Some({
      color: stroke_c,
      width: stroke_width,
      dash: [],
      line_cap: "butt",
      line_join: "miter",
    }),
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Rect with both fill and stroke colors and explicit element opacity.
pub fn Element::rect_fill_stroke_opacity(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  fill_color_str : String,
  stroke_color_str : String,
  stroke_width : Double,
  opacity : Double,
) -> Element {
  let fill = Color::from_string(fill_color_str).unwrap_or(black)
  let stroke_c = Color::from_string(stroke_color_str).unwrap_or(black)
  Rect({
    bbox: BBox::new(x, y, w, h),
    rx: 0.0,
    ry: 0.0,
    fill: Some({ color: fill }),
    stroke: Some({
      color: stroke_c,
      width: stroke_width,
      dash: [],
      line_cap: "butt",
      line_join: "miter",
    }),
    opacity,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Polyline with explicit stroke color/width/cap/join.
pub fn Element::polyline_custom(
  points : Array[Point],
  color_str : String,
  width : Double,
  line_cap : String,
  line_join : String,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  Polyline({
    points,
    stroke: { color, width, dash: [], line_cap, line_join },
    fill: transparent,
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Text element with explicit style fields.
pub fn Element::text_custom(
  x : Double,
  y : Double,
  content : String,
  anchor : TextAnchor,
  baseline : TextBaseline,
  color_str : String,
  font_size : Double,
  font_family : String,
  font_weight : String,
) -> Element {
  let fill = Color::from_string(color_str).unwrap_or(black)
  Text({
    x,
    y,
    content,
    style: { fill, font_size, font_family, font_weight, anchor, baseline },
    opacity: 1.0,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Polyline with explicit stroke color/width/cap/join and element opacity.
pub fn Element::polyline_custom_opacity(
  points : Array[Point],
  color_str : String,
  width : Double,
  line_cap : String,
  line_join : String,
  opacity : Double,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  Polyline({
    points,
    stroke: { color, width, dash: [], line_cap, line_join },
    fill: transparent,
    opacity,
    meta: DisplayableMeta::default(),
  })
}

///|
/// Path stroked with explicit stroke color/width/cap/join and element opacity.
pub fn Element::path_stroke_custom(
  d : String,
  color_str : String,
  width : Double,
  line_cap : String,
  line_join : String,
  opacity : Double,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  Path({
    d,
    fill: None,
    stroke: Some({ color, width, dash: [], line_cap, line_join }),
    opacity,
    meta: DisplayableMeta::default(),
  })
}

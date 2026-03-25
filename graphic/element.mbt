// Corresponds to: zrender/src/graphic/Shape.ts, zrender/src/graphic/Path.ts
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
pub fn StrokeStyle::default() -> StrokeStyle {
  { color: black, width: 1.0, dash: [], line_cap: "butt", line_join: "miter" }
}

///|
/// Style applied to filled shapes.
pub struct FillStyle {
  color : Color
}

///|
pub fn FillStyle::default() -> FillStyle {
  { color: black }
}

///|
/// Text anchor alignment.
pub enum TextAnchor {
  Start
  Middle
  End
}

///|
pub fn TextAnchor::start() -> TextAnchor {
  Start
}

///|
pub fn TextAnchor::middle() -> TextAnchor {
  Middle
}

///|
pub fn TextAnchor::end() -> TextAnchor {
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
pub enum TextBaseline {
  Auto
  Top
  Hanging
  Middle
  Central // SVG "central" — equivalent to CSS middle, used by ECharts for title/labels
  Alphabetic
  Ideographic
  Bottom
}

///|
pub fn TextBaseline::auto() -> TextBaseline {
  Auto
}

///|
pub fn TextBaseline::top() -> TextBaseline {
  Top
}

///|
pub fn TextBaseline::hanging() -> TextBaseline {
  Hanging
}

///|
pub fn TextBaseline::middle() -> TextBaseline {
  Middle
}

///|
pub fn TextBaseline::central() -> TextBaseline {
  Central
}

///|
pub fn TextBaseline::alphabetic() -> TextBaseline {
  Alphabetic
}

///|
pub fn TextBaseline::ideographic() -> TextBaseline {
  Ideographic
}

///|
pub fn TextBaseline::bottom() -> TextBaseline {
  Bottom
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
pub fn TextStyle::default() -> TextStyle {
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
  opacity : Double
}

///|
pub fn GroupData::new(children : Array[Element]) -> GroupData {
  { children, transform: None, clip_rect: None, opacity: 1.0 }
}

///|
pub struct RectData {
  bbox : BBox
  rx : Double // corner radius x
  ry : Double // corner radius y
  fill : FillStyle?
  stroke : StrokeStyle?
  opacity : Double
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
}

///|
pub fn CircleData::new(cx : Double, cy : Double, r : Double) -> CircleData {
  { cx, cy, r, fill: Some(FillStyle::default()), stroke: None, opacity: 1.0 }
}

///|
pub struct LineData {
  x1 : Double
  y1 : Double
  x2 : Double
  y2 : Double
  stroke : StrokeStyle
  opacity : Double
}

///|
pub fn LineData::new(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> LineData {
  { x1, y1, x2, y2, stroke: StrokeStyle::default(), opacity: 1.0 }
}

///|
pub struct PolylineData {
  points : Array[Point]
  stroke : StrokeStyle
  fill : Color // usually transparent
  opacity : Double
}

///|
pub fn PolylineData::new(points : Array[Point]) -> PolylineData {
  { points, stroke: StrokeStyle::default(), fill: transparent, opacity: 1.0 }
}

///|
pub struct PolygonData {
  points : Array[Point]
  fill : FillStyle?
  stroke : StrokeStyle?
  opacity : Double
}

///|
pub fn PolygonData::new(points : Array[Point]) -> PolygonData {
  { points, fill: Some(FillStyle::default()), stroke: None, opacity: 1.0 }
}

///|
/// SVG path data (the `d` attribute value).
pub struct PathData {
  d : String
  fill : FillStyle?
  stroke : StrokeStyle?
  opacity : Double
}

///|
pub fn PathData::new(d : String) -> PathData {
  { d, fill: None, stroke: Some(StrokeStyle::default()), opacity: 1.0 }
}

///|
pub struct TextData {
  x : Double
  y : Double
  content : String
  style : TextStyle
  opacity : Double
}

///|
pub fn TextData::new(x : Double, y : Double, content : String) -> TextData {
  { x, y, content, style: TextStyle::default(), opacity: 1.0 }
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

// ---- builder helpers ----

///|
pub fn Element::group(children : Array[Element]) -> Element {
  Group(GroupData::new(children))
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
  Line({ x1, y1, x2, y2, stroke, opacity: 1.0 })
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
  Text({ x, y, content, style, opacity: 1.0 })
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
  Polyline({ points, stroke, fill: transparent, opacity: 1.0 })
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
  Polyline({ points, stroke, fill: transparent, opacity: 1.0 })
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
  Circle({ cx, cy, r, fill: Some({ color, }), stroke: None, opacity: 1.0 })
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
  Circle({ cx, cy, r, fill: Some({ color, }), stroke: None, opacity })
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
  Path({ d, fill: None, stroke: Some(stroke), opacity: 1.0 })
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
  Path({ d, fill: None, stroke: Some(stroke), opacity: 1.0 })
}

///|
/// Path filled with a CSS/hex color string (semi-transparent area).
pub fn Element::path_filled(
  d : String,
  color_str : String,
  opacity : Double,
) -> Element {
  let color = Color::from_string(color_str).unwrap_or(black)
  Path({ d, fill: Some({ color, }), stroke: None, opacity })
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
  })
}

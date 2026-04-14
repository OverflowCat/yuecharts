// Corresponds to: echarts/src/coord/geo/GeoSVGResource.ts

///|
pub struct GeoSvgResource {
  map_name : String
  svg : String
}

///|
pub fn GeoSvgResource::load(
  self : GeoSvgResource,
  _name_map : Array[@option.GeoNameMapEntry],
  _name_property : String,
) -> GeoLoadedResource {
  let root = geo_svg_parse_root(self.svg)
  match root {
    Some(root_node) => {
      let raw_regions = geo_svg_collect_regions(
        root_node,
        geo_svg_identity_transform(),
        false,
      )
      let bounding_rect = geo_svg_bounding_rect(root_node, raw_regions)
      let transform = geo_svg_root_transform(root_node, bounding_rect)
      let regions = if geo_svg_transform_is_identity(transform) {
        raw_regions
      } else {
        geo_svg_collect_regions(root_node, transform, false)
      }
      { regions, bounding_rect }
    }
    None =>
      { regions: [], bounding_rect: @graphic.BBox::new(0.0, 0.0, 0.0, 0.0) }
  }
}

///|
pub(all) struct GeoSvgTransform {
  sx : Double
  sy : Double
  tx : Double
  ty : Double
}

///|
fn geo_svg_identity_transform() -> GeoSvgTransform {
  { sx: 1.0, sy: 1.0, tx: 0.0, ty: 0.0 }
}

///|
fn geo_svg_transform_is_identity(transform : GeoSvgTransform) -> Bool {
  transform.sx == 1.0 &&
  transform.sy == 1.0 &&
  transform.tx == 0.0 &&
  transform.ty == 0.0
}

///|
fn geo_svg_apply_transform(
  pt : @graphic.Point,
  transform : GeoSvgTransform,
) -> @graphic.Point {
  @graphic.Point::new(
    pt.x * transform.sx + transform.tx,
    pt.y * transform.sy + transform.ty,
  )
}

///|
pub(all) struct GeoSvgAttr {
  name : String
  value : String
}

///|
pub(all) struct GeoSvgNode {
  tag : String
  attrs : Array[GeoSvgAttr]
  children : Array[GeoSvgNode]
}

///|
pub(all) struct GeoSvgShapeStyle {
  fill : String?
  stroke_color : String?
  stroke_width : Double?
}

///|
fn geo_svg_make_attr(name : String, value : String) -> GeoSvgAttr {
  { name, value }
}

///|
fn geo_svg_attr_value(node : GeoSvgNode, name : String) -> String? {
  let mut i = 0
  while i < node.attrs.length() {
    let attr = node.attrs[i]
    if attr.name == name {
      return Some(attr.value)
    }
    i += 1
  }
  None
}

///|
fn geo_svg_attr_double(node : GeoSvgNode, name : String) -> Double? {
  match geo_svg_attr_value(node, name) {
    Some(value) => {
      let parsed = try? @strconv.parse_double(value)
      match parsed {
        Ok(v) => Some(v)
        Err(_) => None
      }
    }
    None => None
  }
}

///|
fn geo_svg_shape_style(node : GeoSvgNode) -> GeoSvgShapeStyle? {
  let fill = match geo_svg_attr_value(node, "fill") {
    Some(value) if value != "none" && value != "" => Some(value)
    _ => None
  }
  let stroke = match geo_svg_attr_value(node, "stroke") {
    Some(value) if value != "none" && value != "" => Some(value)
    _ => None
  }
  let stroke_width = match geo_svg_attr_double(node, "stroke-width") {
    Some(value) => Some(value)
    None => None
  }
  if fill is None && stroke is None && stroke_width is None {
    None
  } else {
    Some({ fill, stroke_color: stroke, stroke_width })
  }
}

///|
fn geo_svg_first_style(node : GeoSvgNode) -> GeoSvgShapeStyle? {
  match geo_svg_shape_style(node) {
    Some(style) => Some(style)
    None => {
      let mut i = 0
      while i < node.children.length() {
        match geo_svg_first_style(node.children[i]) {
          Some(style) => return Some(style)
          None => ()
        }
        i += 1
      }
      None
    }
  }
}

///|
fn geo_svg_shape_name(node : GeoSvgNode) -> String? {
  match geo_svg_attr_value(node, "name") {
    Some(value) if value != "" => Some(value)
    _ => None
  }
}

///|
fn geo_svg_is_region_tag(tag : String) -> Bool {
  match tag {
    "rect"
    | "circle"
    | "line"
    | "ellipse"
    | "polygon"
    | "polyline"
    | "path"
    | "g"
    | "text"
    | "tspan" => true
    _ => false
  }
}

///|
fn geo_svg_region_bbox(geometries : Array[GeoGeometry]) -> @graphic.BBox {
  if geometries.length() == 0 {
    return @graphic.BBox::new(0.0, 0.0, 0.0, 0.0)
  }
  let mut min_x = 0.0
  let mut min_y = 0.0
  let mut max_x = 0.0
  let mut max_y = 0.0
  let mut first = true
  let mut i = 0
  while i < geometries.length() {
    match geometries[i] {
      Polygon(polygon) => {
        let mut j = 0
        while j < polygon.exterior.length() {
          let pt = polygon.exterior[j]
          if first {
            min_x = pt.x
            max_x = pt.x
            min_y = pt.y
            max_y = pt.y
            first = false
          } else {
            if pt.x < min_x {
              min_x = pt.x
            }
            if pt.x > max_x {
              max_x = pt.x
            }
            if pt.y < min_y {
              min_y = pt.y
            }
            if pt.y > max_y {
              max_y = pt.y
            }
          }
          j += 1
        }
        let mut k = 0
        while k < polygon.interiors.length() {
          let interior = polygon.interiors[k]
          let mut m = 0
          while m < interior.length() {
            let pt = interior[m]
            if first {
              min_x = pt.x
              max_x = pt.x
              min_y = pt.y
              max_y = pt.y
              first = false
            } else {
              if pt.x < min_x {
                min_x = pt.x
              }
              if pt.x > max_x {
                max_x = pt.x
              }
              if pt.y < min_y {
                min_y = pt.y
              }
              if pt.y > max_y {
                max_y = pt.y
              }
            }
            m += 1
          }
          k += 1
        }
      }
      LineString(lines) => {
        let mut j = 0
        while j < lines.points.length() {
          let points = lines.points[j]
          let mut k = 0
          while k < points.length() {
            let pt = points[k]
            if first {
              min_x = pt.x
              max_x = pt.x
              min_y = pt.y
              max_y = pt.y
              first = false
            } else {
              if pt.x < min_x {
                min_x = pt.x
              }
              if pt.x > max_x {
                max_x = pt.x
              }
              if pt.y < min_y {
                min_y = pt.y
              }
              if pt.y > max_y {
                max_y = pt.y
              }
            }
            k += 1
          }
          j += 1
        }
      }
    }
    i += 1
  }
  @graphic.BBox::new(min_x, min_y, max_x - min_x, max_y - min_y)
}

///|
fn geo_svg_root_view_box(node : GeoSvgNode) -> @graphic.BBox? {
  match geo_svg_attr_value(node, "viewBox") {
    Some(value) => {
      let values = geo_svg_number_list(value)
      if values.length() >= 4 {
        Some(@graphic.BBox::new(values[0], values[1], values[2], values[3]))
      } else {
        None
      }
    }
    None => None
  }
}

///|
fn geo_svg_root_transform(
  node : GeoSvgNode,
  bounding_rect : @graphic.BBox,
) -> GeoSvgTransform {
  match geo_svg_root_view_box(node) {
    Some(view_box) => {
      let scale_x = if view_box.width == 0.0 {
        1.0
      } else {
        bounding_rect.width / view_box.width
      }
      let scale_y = if view_box.height == 0.0 {
        1.0
      } else {
        bounding_rect.height / view_box.height
      }
      let scale = if scale_x < scale_y { scale_x } else { scale_y }
      let tx = bounding_rect.x +
        (bounding_rect.width - view_box.width * scale) / 2.0 -
        view_box.x * scale
      let ty = bounding_rect.y +
        (bounding_rect.height - view_box.height * scale) / 2.0 -
        view_box.y * scale
      { sx: scale, sy: scale, tx, ty }
    }
    None => geo_svg_identity_transform()
  }
}

///|
fn geo_svg_bounding_rect(
  root : GeoSvgNode,
  regions : Array[GeoRegion],
) -> @graphic.BBox {
  let width = geo_svg_attr_double(root, "width")
  let height = geo_svg_attr_double(root, "height")
  let view_box = geo_svg_root_view_box(root)
  match (width, height, view_box) {
    (Some(w), Some(h), _) => @graphic.BBox::new(0.0, 0.0, w, h)
    (Some(w), None, Some(view_box_rect)) =>
      @graphic.BBox::new(0.0, 0.0, w, view_box_rect.height)
    (None, Some(h), Some(view_box_rect)) =>
      @graphic.BBox::new(0.0, 0.0, view_box_rect.width, h)
    (None, None, Some(view_box_rect)) => view_box_rect
    _ => geo_svg_regions_bbox(regions)
  }
}

///|
fn geo_svg_collect_regions(
  node : GeoSvgNode,
  transform : GeoSvgTransform,
  in_named_region : Bool,
) -> Array[GeoRegion] {
  let drafts : Array[GeoRegion] = []
  let _ = geo_svg_collect_regions_into(node, transform, in_named_region, drafts)
  drafts
}

///|
fn geo_svg_collect_regions_into(
  node : GeoSvgNode,
  transform : GeoSvgTransform,
  in_named_region : Bool,
  out : Array[GeoRegion],
) -> Array[GeoGeometry] {
  let geometries = geo_svg_node_geometries(node, transform)
  let named = geo_svg_shape_name(node)
  let next_in_named_region = match named {
    Some(_) => true
    None => in_named_region
  }
  let mut i = 0
  while i < node.children.length() {
    let child_geometries = geo_svg_collect_regions_into(
      node.children[i],
      transform,
      next_in_named_region,
      out,
    )
    let mut j = 0
    while j < child_geometries.length() {
      geometries.push(child_geometries[j])
      j += 1
    }
    i += 1
  }
  if geo_svg_is_region_tag(node.tag) {
    let should_emit = match named {
      Some(_) => true
      None => !in_named_region && geometries.length() > 0
    }
    if should_emit {
      let region_name = match named {
        Some(name) => name
        None => ""
      }
      let style = match geo_svg_shape_style(node) {
        Some(style) => style
        None =>
          match geo_svg_first_style(node) {
            Some(style) => style
            None => { fill: None, stroke_color: None, stroke_width: None }
          }
      }
      out.push(geo_svg_make_region(region_name, geometries, style))
      []
    } else {
      geometries
    }
  } else {
    geometries
  }
}

///|
fn geo_svg_make_region(
  name : String,
  geometries : Array[GeoGeometry],
  style : GeoSvgShapeStyle,
) -> GeoRegion {
  let bbox = geo_svg_region_bbox(geometries)
  {
    name,
    geometries,
    center: @graphic.Point::new(bbox.center_x(), bbox.center_y()),
    data_bbox: bbox,
    source_fill: style.fill,
    source_stroke_color: style.stroke_color,
    source_stroke_width: style.stroke_width,
  }
}

///|
fn geo_svg_node_geometries(
  node : GeoSvgNode,
  transform : GeoSvgTransform,
) -> Array[GeoGeometry] {
  match node.tag {
    "rect" => geo_svg_rect_geometries(node, transform)
    "circle" => geo_svg_circle_geometries(node, transform)
    "ellipse" => geo_svg_ellipse_geometries(node, transform)
    "polygon" => geo_svg_polygon_geometries(node, transform)
    "polyline" => geo_svg_polyline_geometries(node, transform)
    "line" => geo_svg_line_geometries(node, transform)
    "path" => geo_svg_path_geometries(node, transform)
    _ => []
  }
}

///|
fn geo_svg_rect_geometries(
  node : GeoSvgNode,
  transform : GeoSvgTransform,
) -> Array[GeoGeometry] {
  let x = geo_svg_attr_double(node, "x").unwrap_or(0.0)
  let y = geo_svg_attr_double(node, "y").unwrap_or(0.0)
  let width = geo_svg_attr_double(node, "width").unwrap_or(0.0)
  let height = geo_svg_attr_double(node, "height").unwrap_or(0.0)
  let p0 = geo_svg_apply_transform(@graphic.Point::new(x, y), transform)
  let p1 = geo_svg_apply_transform(@graphic.Point::new(x + width, y), transform)
  let p2 = geo_svg_apply_transform(
    @graphic.Point::new(x + width, y + height),
    transform,
  )
  let p3 = geo_svg_apply_transform(
    @graphic.Point::new(x, y + height),
    transform,
  )
  [Polygon({ exterior: [p0, p1, p2, p3], interiors: [] })]
}

///|
fn geo_svg_circle_geometries(
  node : GeoSvgNode,
  transform : GeoSvgTransform,
) -> Array[GeoGeometry] {
  let cx = geo_svg_attr_double(node, "cx").unwrap_or(0.0)
  let cy = geo_svg_attr_double(node, "cy").unwrap_or(0.0)
  let r = geo_svg_attr_double(node, "r").unwrap_or(0.0)
  geo_svg_circle_points(cx, cy, r, transform)
}

///|
fn geo_svg_ellipse_geometries(
  node : GeoSvgNode,
  transform : GeoSvgTransform,
) -> Array[GeoGeometry] {
  let cx = geo_svg_attr_double(node, "cx").unwrap_or(0.0)
  let cy = geo_svg_attr_double(node, "cy").unwrap_or(0.0)
  let rx = geo_svg_attr_double(node, "rx").unwrap_or(0.0)
  let ry = geo_svg_attr_double(node, "ry").unwrap_or(0.0)
  geo_svg_ellipse_points(cx, cy, rx, ry, transform)
}

///|
fn geo_svg_polygon_geometries(
  node : GeoSvgNode,
  transform : GeoSvgTransform,
) -> Array[GeoGeometry] {
  match geo_svg_parse_points_attr(node) {
    Some(points) =>
      if points.length() >= 3 {
        [
          Polygon({
            exterior: geo_svg_transform_points(points, transform),
            interiors: [],
          }),
        ]
      } else {
        []
      }
    None => []
  }
}

///|
fn geo_svg_polyline_geometries(
  node : GeoSvgNode,
  transform : GeoSvgTransform,
) -> Array[GeoGeometry] {
  match geo_svg_parse_points_attr(node) {
    Some(points) if points.length() >= 2 =>
      [LineString({ points: [geo_svg_transform_points(points, transform)] })]
    _ => []
  }
}

///|
fn geo_svg_line_geometries(
  node : GeoSvgNode,
  transform : GeoSvgTransform,
) -> Array[GeoGeometry] {
  let x1 = geo_svg_attr_double(node, "x1").unwrap_or(0.0)
  let y1 = geo_svg_attr_double(node, "y1").unwrap_or(0.0)
  let x2 = geo_svg_attr_double(node, "x2").unwrap_or(0.0)
  let y2 = geo_svg_attr_double(node, "y2").unwrap_or(0.0)
  [
    LineString({
      points: [
        [
          geo_svg_apply_transform(@graphic.Point::new(x1, y1), transform),
          geo_svg_apply_transform(@graphic.Point::new(x2, y2), transform),
        ],
      ],
    }),
  ]
}

///|
fn geo_svg_path_geometries(
  node : GeoSvgNode,
  transform : GeoSvgTransform,
) -> Array[GeoGeometry] {
  match geo_svg_attr_value(node, "d") {
    Some(d) => geo_svg_parse_path_geometries(d, transform)
    None => []
  }
}

///|
fn geo_svg_circle_points(
  cx : Double,
  cy : Double,
  r : Double,
  transform : GeoSvgTransform,
) -> Array[GeoGeometry] {
  let points : Array[@graphic.Point] = []
  let mut i = 0
  while i < 24 {
    let angle = 2.0 * @math.PI * i.to_double() / 24.0
    points.push(
      geo_svg_apply_transform(
        @graphic.Point::new(
          cx + @math.cos(angle) * r,
          cy + @math.sin(angle) * r,
        ),
        transform,
      ),
    )
    i += 1
  }
  [Polygon({ exterior: points, interiors: [] })]
}

///|
fn geo_svg_ellipse_points(
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
  transform : GeoSvgTransform,
) -> Array[GeoGeometry] {
  let points : Array[@graphic.Point] = []
  let mut i = 0
  while i < 24 {
    let angle = 2.0 * @math.PI * i.to_double() / 24.0
    points.push(
      geo_svg_apply_transform(
        @graphic.Point::new(
          cx + @math.cos(angle) * rx,
          cy + @math.sin(angle) * ry,
        ),
        transform,
      ),
    )
    i += 1
  }
  [Polygon({ exterior: points, interiors: [] })]
}

///|
fn geo_svg_transform_points(
  points : Array[@graphic.Point],
  transform : GeoSvgTransform,
) -> Array[@graphic.Point] {
  points.map(pt => geo_svg_apply_transform(pt, transform))
}

///|
fn geo_svg_parse_points_attr(node : GeoSvgNode) -> Array[@graphic.Point]? {
  match geo_svg_attr_value(node, "points") {
    Some(points_text) => {
      let points : Array[@graphic.Point] = []
      let mut i = 0
      while i < points_text.length() {
        guard @graphic.parse_path_number(points_text, i) is Some((x, i1)) else {
          break
        }
        guard @graphic.parse_path_number(points_text, i1) is Some((y, i2)) else {
          break
        }
        points.push(@graphic.Point::new(x, y))
        i = i2
      }
      Some(points)
    }
    None => None
  }
}

///|
fn geo_svg_parse_path_geometries(
  d : String,
  transform : GeoSvgTransform,
) -> Array[GeoGeometry] {
  let mut i = 0
  let mut cmd = ' '
  let mut current_points : Array[@graphic.Point] = []
  let regions : Array[GeoGeometry] = []
  let mut current_x = 0.0
  let mut current_y = 0.0
  let mut closed = false
  while i < d.length() {
    i = @graphic.skip_path_separators(d, i)
    if i >= d.length() {
      break
    }
    let ch = d[i].unsafe_to_char()
    if @graphic.is_path_command(ch) {
      if ch == 'Z' || ch == 'z' {
        closed = true
        if current_points.length() > 0 {
          regions.push(Polygon({ exterior: current_points, interiors: [] }))
        }
        current_points = []
      }
      cmd = ch
      i += 1
      continue
    }
    match cmd {
      'M' | 'm' => {
        guard @graphic.parse_path_number(d, i) is Some((x0, i1)) else { break }
        guard @graphic.parse_path_number(d, i1) is Some((y0, i2)) else { break }
        let x = if cmd == 'm' { current_x + x0 } else { x0 }
        let y = if cmd == 'm' { current_y + y0 } else { y0 }
        current_x = x
        current_y = y
        if current_points.length() > 0 {
          if closed || current_points.length() >= 3 {
            regions.push(Polygon({ exterior: current_points, interiors: [] }))
          } else if current_points.length() >= 2 {
            regions.push(LineString({ points: [current_points] }))
          }
          current_points = []
          closed = false
        }
        current_points.push(
          geo_svg_apply_transform(@graphic.Point::new(x, y), transform),
        )
        i = i2
        cmd = if cmd == 'm' { 'l' } else { 'L' }
      }
      'L' | 'l' => {
        guard @graphic.parse_path_number(d, i) is Some((x0, i1)) else { break }
        guard @graphic.parse_path_number(d, i1) is Some((y0, i2)) else { break }
        let x = if cmd == 'l' { current_x + x0 } else { x0 }
        let y = if cmd == 'l' { current_y + y0 } else { y0 }
        current_x = x
        current_y = y
        current_points.push(
          geo_svg_apply_transform(@graphic.Point::new(x, y), transform),
        )
        i = i2
      }
      'H' | 'h' => {
        guard @graphic.parse_path_number(d, i) is Some((x0, i1)) else { break }
        let x = if cmd == 'h' { current_x + x0 } else { x0 }
        current_x = x
        current_points.push(
          geo_svg_apply_transform(@graphic.Point::new(x, current_y), transform),
        )
        i = i1
      }
      'V' | 'v' => {
        guard @graphic.parse_path_number(d, i) is Some((y0, i1)) else { break }
        let y = if cmd == 'v' { current_y + y0 } else { y0 }
        current_y = y
        current_points.push(
          geo_svg_apply_transform(@graphic.Point::new(current_x, y), transform),
        )
        i = i1
      }
      'C' | 'c' => {
        let end = geo_svg_skip_path_numbers(d, i, 6)
        match end {
          Some((x3, y3, i6)) => {
            let x = if cmd == 'c' { current_x + x3 } else { x3 }
            let y = if cmd == 'c' { current_y + y3 } else { y3 }
            current_x = x
            current_y = y
            current_points.push(
              geo_svg_apply_transform(@graphic.Point::new(x, y), transform),
            )
            i = i6
          }
          None => break
        }
      }
      'S' | 's' | 'Q' | 'q' => {
        let end = geo_svg_skip_path_numbers(d, i, 4)
        match end {
          Some((x1, y1, i4)) => {
            let x = if cmd == 's' || cmd == 'q' { current_x + x1 } else { x1 }
            let y = if cmd == 's' || cmd == 'q' { current_y + y1 } else { y1 }
            current_x = x
            current_y = y
            current_points.push(
              geo_svg_apply_transform(@graphic.Point::new(x, y), transform),
            )
            i = i4
          }
          None => break
        }
      }
      'T' | 't' => {
        guard @graphic.parse_path_number(d, i) is Some((x0, i1)) else { break }
        guard @graphic.parse_path_number(d, i1) is Some((y0, i2)) else { break }
        let x = if cmd == 't' { current_x + x0 } else { x0 }
        let y = if cmd == 't' { current_y + y0 } else { y0 }
        current_x = x
        current_y = y
        current_points.push(
          geo_svg_apply_transform(@graphic.Point::new(x, y), transform),
        )
        i = i2
      }
      'A' | 'a' => {
        let end = geo_svg_skip_path_numbers(d, i, 7)
        match end {
          Some((x0, y0, i7)) => {
            let x = if cmd == 'a' { current_x + x0 } else { x0 }
            let y = if cmd == 'a' { current_y + y0 } else { y0 }
            current_x = x
            current_y = y
            current_points.push(
              geo_svg_apply_transform(@graphic.Point::new(x, y), transform),
            )
            i = i7
          }
          None => break
        }
      }
      _ => i += 1
    }
  }
  if current_points.length() > 0 {
    if closed || current_points.length() >= 3 {
      regions.push(Polygon({ exterior: current_points, interiors: [] }))
    } else if current_points.length() >= 2 {
      regions.push(LineString({ points: [current_points] }))
    }
  }
  if regions.length() == 0 {
    match @graphic.path_bbox(d) {
      Some((min_x, min_y, max_x, max_y)) =>
        [
          Polygon({
            exterior: [
              geo_svg_apply_transform(
                @graphic.Point::new(min_x, min_y),
                transform,
              ),
              geo_svg_apply_transform(
                @graphic.Point::new(max_x, min_y),
                transform,
              ),
              geo_svg_apply_transform(
                @graphic.Point::new(max_x, max_y),
                transform,
              ),
              geo_svg_apply_transform(
                @graphic.Point::new(min_x, max_y),
                transform,
              ),
            ],
            interiors: [],
          }),
        ]
      None => []
    }
  } else {
    regions
  }
}

///|
fn geo_svg_skip_path_numbers(
  d : String,
  start : Int,
  count : Int,
) -> (Double, Double, Int)? {
  let mut i = start
  let values : Array[Double] = []
  let mut j = 0
  while j < count {
    match @graphic.parse_path_number(d, i) {
      Some((value, next_i)) => {
        values.push(value)
        i = next_i
      }
      None => return None
    }
    j += 1
  }
  if values.length() >= 2 {
    Some((values[values.length() - 2], values[values.length() - 1], i))
  } else {
    None
  }
}

///|
fn geo_svg_number_list(text : String) -> Array[Double] {
  let values : Array[Double] = []
  let mut i = 0
  while i < text.length() {
    match @graphic.parse_path_number(text, i) {
      Some((value, next_i)) => {
        values.push(value)
        i = next_i
      }
      None => i += 1
    }
  }
  values
}

///|
fn geo_svg_parse_root(svg : String) -> GeoSvgNode? {
  match svg.find("<svg") {
    Some(start) =>
      match geo_svg_parse_node(svg, start) {
        Some((node, _)) => Some(node)
        None => None
      }
    None => None
  }
}

///|
fn geo_svg_parse_node(svg : String, start : Int) -> (GeoSvgNode, Int)? {
  if start + 1 >= svg.length() || svg[start].unsafe_to_char() != '<' {
    return None
  }
  if svg[start + 1].unsafe_to_char() == '?' {
    return None
  }
  if svg[start + 1].unsafe_to_char() == '!' {
    return None
  }
  if svg[start + 1].unsafe_to_char() == '/' {
    return None
  }
  let tag_end = geo_svg_find_tag_end(svg, start + 1)
  match tag_end {
    Some(end_index) => {
      let body = svg[start + 1:end_index].to_string()
      let parsed = geo_svg_parse_tag_body(body)
      match parsed {
        Some((node, self_closing)) =>
          if self_closing {
            Some((node, end_index + 1))
          } else {
            let (children, next_i) = geo_svg_parse_children(
              svg,
              end_index + 1,
              node.tag,
            )
            Some(({ ..node, children, }, next_i))
          }
        None => None
      }
    }
    None => None
  }
}

///|
fn geo_svg_find_tag_end(svg : String, start : Int) -> Int? {
  let mut i = start
  let mut in_quote : Char? = None
  while i < svg.length() {
    let ch = svg[i].unsafe_to_char()
    match in_quote {
      Some(q) => if ch == q { in_quote = None }
      None =>
        if ch == '"' || ch == '\'' {
          in_quote = Some(ch)
        } else if ch == '>' {
          return Some(i)
        }
    }
    i += 1
  }
  None
}

///|
fn geo_svg_parse_children(
  svg : String,
  start : Int,
  parent_tag : String,
) -> (Array[GeoSvgNode], Int) {
  let children : Array[GeoSvgNode] = []
  let mut i = start
  while i < svg.length() {
    while i < svg.length() && svg[i].unsafe_to_char() != '<' {
      i += 1
    }
    if i >= svg.length() {
      break
    }
    if i + 1 < svg.length() && svg[i + 1].unsafe_to_char() == '/' {
      let close_end = geo_svg_find_tag_end(svg, i + 2)
      match close_end {
        Some(end_index) => {
          let close_tag = geo_svg_trim_ascii(svg[i + 2:end_index].to_string())
          if close_tag == parent_tag {
            return (children, end_index + 1)
          }
          i = end_index + 1
        }
        None => break
      }
      continue
    }
    match geo_svg_parse_node(svg, i) {
      Some((node, next_i)) => {
        children.push(node)
        i = next_i
      }
      None => i += 1
    }
  }
  (children, i)
}

///|
fn geo_svg_parse_tag_body(body : String) -> (GeoSvgNode, Bool)? {
  let mut i = 0
  i = geo_svg_skip_ascii_ws(body, i)
  let tag_start = i
  while i < body.length() {
    let ch = body[i].unsafe_to_char()
    if geo_svg_is_name_char(ch) {
      i += 1
    } else {
      break
    }
  }
  if i <= tag_start {
    return None
  }
  let tag = body[tag_start:i].to_string()
  let attrs : Array[GeoSvgAttr] = []
  let mut self_closing = false
  while i < body.length() {
    i = geo_svg_skip_ascii_ws(body, i)
    if i >= body.length() {
      break
    }
    let ch = body[i].unsafe_to_char()
    if ch == '/' {
      self_closing = true
      break
    }
    let name_start = i
    while i < body.length() {
      let c = body[i].unsafe_to_char()
      if geo_svg_is_name_char(c) {
        i += 1
      } else {
        break
      }
    }
    if i <= name_start {
      break
    }
    let name = body[name_start:i].to_string()
    i = geo_svg_skip_ascii_ws(body, i)
    let mut value = ""
    if i < body.length() && body[i].unsafe_to_char() == '=' {
      i += 1
      i = geo_svg_skip_ascii_ws(body, i)
      if i < body.length() {
        let quote = body[i].unsafe_to_char()
        if quote == '"' || quote == '\'' {
          i += 1
          let value_start = i
          while i < body.length() && body[i].unsafe_to_char() != quote {
            i += 1
          }
          value = body[value_start:i].to_string()
          if i < body.length() {
            i += 1
          }
        } else {
          let value_start = i
          while i < body.length() {
            let c = body[i].unsafe_to_char()
            if c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '/' {
              break
            }
            i += 1
          }
          value = body[value_start:i].to_string()
        }
      }
    }
    attrs.push(geo_svg_make_attr(name, value))
  }
  Some(({ tag, attrs, children: [] }, self_closing))
}

///|
fn geo_svg_skip_ascii_ws(text : String, i : Int) -> Int {
  let mut i = i
  while i < text.length() {
    let ch = text[i].unsafe_to_char()
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      i += 1
    } else {
      break
    }
  }
  i
}

///|
fn geo_svg_is_name_char(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') ||
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= '0' && ch <= '9') ||
  ch == ':' ||
  ch == '-' ||
  ch == '_' ||
  ch == '.'
}

///|
fn geo_svg_trim_ascii(text : String) -> String {
  let mut start = 0
  let mut end = text.length()
  while start < end {
    let ch = text[start].unsafe_to_char()
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      start += 1
    } else {
      break
    }
  }
  while end > start {
    let ch = text[end - 1].unsafe_to_char()
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      end -= 1
    } else {
      break
    }
  }
  text[start:end].to_string()
}

///|
fn geo_svg_regions_bbox(regions : Array[GeoRegion]) -> @graphic.BBox {
  if regions.length() == 0 {
    return @graphic.BBox::new(0.0, 0.0, 0.0, 0.0)
  }
  let mut min_x = regions[0].data_bbox.x
  let mut max_x = regions[0].data_bbox.right()
  let mut min_y = regions[0].data_bbox.y
  let mut max_y = regions[0].data_bbox.bottom()
  let mut i = 1
  while i < regions.length() {
    let bbox = regions[i].data_bbox
    if bbox.x < min_x {
      min_x = bbox.x
    }
    if bbox.right() > max_x {
      max_x = bbox.right()
    }
    if bbox.y < min_y {
      min_y = bbox.y
    }
    if bbox.bottom() > max_y {
      max_y = bbox.bottom()
    }
    i += 1
  }
  @graphic.BBox::new(min_x, min_y, max_x - min_x, max_y - min_y)
}

/// <=> echarts/src/chart/pie/PieView.ts
/// <=> echarts/src/chart/pie/pieLayout.ts
/// <=> echarts/src/chart/pie/labelLayout.ts
//
// Pie / donut chart renderer.
//
// Mapping from ECharts pieLayout.ts:
//   startAngle = -seriesModel.get('startAngle') * RADIAN    (default: -90° = -π/2)
//   clockwise  = true (default)  → SVG sweep-flag = 1
//   unitRadian = 2π / sum
//   each slice: [currentAngle, currentAngle + value*unitRadian]
//
// Screen-coordinate arc formula (y increases downward):
//   x = cx + r * cos(angle)
//   y = cy + r * sin(angle)        ← note: PLUS (not minus) for screen coords
// At startAngle = -π/2: (cx, cy-r) = top centre of circle ✓
//
// SVG arc path for a sector [a0, a1] with outer radius R, inner radius R0:
//   If R0 == 0 (pie): "M cx cy L x0 y0 A R R 0 <large> 1 x1 y1 Z"
//   If R0 > 0 (donut):
//     "M x0 y0 A R R 0 <large> 1 x1 y1 L xi1 yi1 A R0 R0 0 <large> 0 xi0 yi0 Z"
//   where large = 1 if (a1-a0) > π else 0

///|
fn parse_pct_or_px(s : String, reference : Double) -> Double {
  if s.has_suffix("%") {
    let inner = s[:s.length() - 1]
    let r = try? @string.parse_double(inner.to_string())
    match r {
      Ok(v) => v / 100.0 * reference
      Err(_) => 0.0
    }
  } else {
    let r = try? @string.parse_double(s)
    match r {
      Ok(v) => v
      Err(_) => 0.0
    }
  }
}

///|
/// <=> echarts/src/util/number.ts:linearMap (subset)
fn pie_linear_map(
  value : Double,
  in_min : Double,
  in_max : Double,
  out_min : Double,
  out_max : Double,
) -> Double {
  let in_span = in_max - in_min
  if in_span == 0.0 {
    return out_min
  }
  out_min + (value - in_min) / in_span * (out_max - out_min)
}

///|
/// <=> echarts/src/util/layout.ts:getLayoutRect (subset for pie box layout)
fn pie_layout_value(value : String, total : Double) -> Double {
  if value == "center" ||
    value == "middle" ||
    value == "right" ||
    value == "bottom" {
    return 0.0 / 0.0
  }
  if value.has_suffix("%") {
    let pct = value[:value.length() - 1]
    let parsed = try? @string.parse_double(pct.to_string())
    match parsed {
      Ok(v) => v / 100.0 * total
      Err(_) => 0.0 / 0.0
    }
  } else {
    let parsed = try? @string.parse_double(value)
    match parsed {
      Ok(v) => v
      Err(_) => 0.0 / 0.0
    }
  }
}

///|
fn pie_layout_value_opt(value : String?, total : Double) -> Double {
  match value {
    Some(v) => pie_layout_value(v, total)
    None => 0.0 / 0.0
  }
}

///|
/// <=> echarts/src/util/layout.ts:getLayoutRect
fn pie_get_layout_rect(
  series : @option.SeriesOption,
  container : @graphic.BBox,
) -> @graphic.BBox {
  let container_width = container.width
  let container_height = container.height

  let mut left = pie_layout_value_opt(series.left, container_width)
  let mut top = pie_layout_value_opt(series.top, container_height)
  let right = pie_layout_value_opt(series.right, container_width)
  let bottom = pie_layout_value_opt(series.bottom, container_height)
  let mut width = pie_layout_value_opt(series.width, container_width)
  let mut height = pie_layout_value_opt(series.height, container_height)

  if width.is_nan() {
    width = container_width - right - left
  }
  if height.is_nan() {
    height = container_height - bottom - top
  }

  match series.left.unwrap_or(series.right.unwrap_or("")) {
    "center" => left = container_width / 2.0 - width / 2.0
    "right" => left = container_width - width - right
    _ => ()
  }
  match series.top.unwrap_or(series.bottom.unwrap_or("")) {
    "center" | "middle" => top = container_height / 2.0 - height / 2.0
    "bottom" => top = container_height - height - bottom
    _ => ()
  }

  if left.is_nan() {
    left = container_width - right - width
  }
  if top.is_nan() {
    top = container_height - bottom - height
  }

  left = if left.is_nan() { 0.0 } else { left }
  top = if top.is_nan() { 0.0 } else { top }
  if width.is_nan() {
    width = container_width - left - (if right.is_nan() { 0.0 } else { right })
  }
  if height.is_nan() {
    height = container_height -
      top -
      (if bottom.is_nan() { 0.0 } else { bottom })
  }

  @graphic.BBox::new(container.x + left, container.y + top, width, height)
}

///|
/// <=> echarts/src/core/CoordinateSystem.ts:getCoordForBoxCoordSys
///    + echarts/src/chart/pie/PieSeries.ts registerLayOutOnCoordSysUsage(getCoord2=center)
fn pie_parse_matrix_coord_value(value : String) -> @option.MatrixCoordValue {
  let parsed = try? @string.parse_int(value, base=10)
  match parsed {
    Ok(v) => @option.MatrixCoordValue::Locator(v)
    Err(_) => @option.MatrixCoordValue::Name(value)
  }
}

///|
/// <=> echarts/src/util/layout.ts:getViewRectAndCenterForCircleLayout
/// Matrix branch: when `center` is used as `coord2`, center equals refContainer center.
fn pie_resolve_view_rect_and_center(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
) -> (@graphic.BBox, Double, Double) {
  let full = @graphic.BBox::new(0.0, 0.0, opt.width, opt.height)

  if series.coordinate_system == Some("matrix") && series.center.length() >= 2 {
    match @coord.Matrix::build(opt) {
      Some(matrix) => {
        let x_coord = pie_parse_matrix_coord_value(series.center[0])
        let y_coord = pie_parse_matrix_coord_value(series.center[1])
        match (matrix.resolve_x(x_coord), matrix.resolve_y(y_coord)) {
          (Some(xi), Some(yi)) => {
            let cell_layout = matrix.data_to_layout(xi, yi, clamp=false)
            let ref_container = cell_layout.content_rect
            if !ref_container.x.is_nan() && !ref_container.y.is_nan() {
              let view_rect = pie_get_layout_rect(series, ref_container)
              return (
                view_rect,
                ref_container.center_x(),
                ref_container.center_y(),
              )
            }
          }
          _ => ()
        }
      }
      None => ()
    }
  }

  let view_rect = pie_get_layout_rect(series, full)
  let cx = if series.center.length() >= 1 {
    parse_pct_or_px(series.center[0], view_rect.width) + view_rect.x
  } else {
    view_rect.center_x()
  }
  let cy = if series.center.length() >= 2 {
    parse_pct_or_px(series.center[1], view_rect.height) + view_rect.y
  } else {
    view_rect.center_y()
  }
  (view_rect, cx, cy)
}

///|
/// Round a Double to 4 decimal places for clean SVG output.
fn r4(v : Double) -> String {
  // Multiply by 10000, round, divide back, format
  let scaled = (v * 10000.0 + 0.5).to_int().to_double() / 10000.0
  scaled.to_string()
}

///|
/// <=> echarts/src/chart/pie/pieLayout.ts
/// Compute clockwise/counterclockwise directed sweep in [0, 2π].
fn pie_directed_sweep(
  start_angle : Double,
  end_angle : Double,
  clockwise : Bool,
) -> Double {
  let pi2 = @math.PI * 2.0
  let mut delta = if clockwise {
    end_angle - start_angle
  } else {
    start_angle - end_angle
  }
  while delta < 0.0 {
    delta = delta + pi2
  }
  while delta > pi2 {
    delta = delta - pi2
  }
  delta
}

///|
/// <=> echarts/src/util/number.ts (percent precision rounding behavior subset)
fn pie_format_percent(value : Double, precision : Int) -> String {
  let p = if precision < 0 { 0 } else { precision }
  let mut scale = 1.0
  let mut i = 0
  while i < p {
    scale = scale * 10.0
    i = i + 1
  }
  let rounded = (value * scale).round() / scale
  if rounded.to_int().to_double() == rounded {
    rounded.to_int().to_string()
  } else {
    rounded.to_string()
  }
}

///|
/// Internal pie label layout state.
/// <=> echarts/src/chart/pie/labelLayout.ts
priv struct PieLabelPlan {
  text_lines : Array[String]
  x : Double
  y : Double
  text_width : Double
  height : Double
  text_color : String
  font_size : Double
  font_family : StringView
  font_weight : String
  text_anchor : @graphic.TextAnchor
  text_baseline : @graphic.TextBaseline
  rotation : Double?
  opacity : Double
  side_sign : Int
  surface_normal : @graphic.Point
  align_to : String
  bleed_margin : Double
  distance_to_label_line : Double
  line_points : Array[@graphic.Point]?
  line_show : Bool
  line_color : String
  line_width : Double
  line_type : String
  line_opacity : Double
  line_smooth : Double
  line_min_turn_angle : Double
  line_max_surface_angle : Double
}

///|
fn pie_label_lines(text : String) -> Array[String] {
  text
  .replace(old="\\n", new="\n")
  .split("\n")
  .map(StringView::to_string)
  .collect()
}

///|
fn pie_estimate_text_width(lines : Array[String], font_size : Double) -> Double {
  let mut max_chars = 0
  for line in lines {
    let char_count = line.length()
    if char_count > max_chars {
      max_chars = char_count
    }
  }
  max_chars.to_double() * font_size * 0.6
}

///|
fn pie_estimate_text_height(
  lines : Array[String],
  font_size : Double,
) -> Double {
  let line_height = font_size * 1.2
  lines.length().to_double() * line_height
}

///|
fn pie_side_sign(nx : Double) -> Int {
  if nx < 0.0 {
    -1
  } else {
    1
  }
}

///|
fn pie_tangential_rotation(
  nx : Double,
  ny : Double,
  flip_downward : Bool,
) -> Double {
  let mut rad = @math.atan2(nx, ny)
  if rad < 0.0 {
    rad = @math.PI * 2.0 + rad
  }
  let is_down = ny > 0.0
  if is_down && flip_downward {
    rad = @math.PI + rad
  }
  rad - @math.PI
}

///|
/// <=> echarts/src/label/sectorLabel.ts:setSectorTextRotation
fn pie_label_rotation_rad(
  position : String,
  rotate : Double?,
  rotate_mode : String?,
  nx : Double,
  ny : Double,
  mid_angle : Double,
) -> Double? {
  match rotate {
    Some(value) => Some(value / 180.0 * @math.PI)
    None => {
      if position == "center" {
        return Some(0.0)
      }
      match rotate_mode {
        Some("radial") =>
          Some(if nx < 0.0 { -mid_angle + @math.PI } else { -mid_angle })
        Some("tangential") => Some(pie_tangential_rotation(nx, ny, true))
        Some("tangential-noflip") =>
          if position != "outside" && position != "outer" {
            Some(pie_tangential_rotation(nx, ny, false))
          } else {
            None
          }
        _ => None
      }
    }
  }
}

///|
fn pie_label_line_dash(line_type : String) -> Array[Double] {
  match line_type {
    "dashed" => [4.0, 2.0]
    "dotted" => [1.0, 2.0]
    _ => []
  }
}

///|
fn pie_point_distance(a : @graphic.Point, b : @graphic.Point) -> Double {
  let dx = a.x - b.x
  let dy = a.y - b.y
  (dx * dx + dy * dy).sqrt()
}

///|
fn pie_point_sub(a : @graphic.Point, b : @graphic.Point) -> @graphic.Point {
  @graphic.Point::new(a.x - b.x, a.y - b.y)
}

///|
fn pie_point_dot(a : @graphic.Point, b : @graphic.Point) -> Double {
  a.x * b.x + a.y * b.y
}

///|
fn pie_point_len(a : @graphic.Point) -> Double {
  (a.x * a.x + a.y * a.y).sqrt()
}

///|
fn pie_point_scale(a : @graphic.Point, scale : Double) -> @graphic.Point {
  @graphic.Point::new(a.x * scale, a.y * scale)
}

///|
fn pie_point_scale_add(
  base : @graphic.Point,
  dir : @graphic.Point,
  scale : Double,
) -> @graphic.Point {
  @graphic.Point::new(base.x + dir.x * scale, base.y + dir.y * scale)
}

///|
fn pie_point_lerp(
  a : @graphic.Point,
  b : @graphic.Point,
  t : Double,
) -> @graphic.Point {
  @graphic.Point::new(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t)
}

///|
fn pie_project_point_to_line(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  x : Double,
  y : Double,
  limit_to_ends : Bool,
) -> (@graphic.Point, Double) {
  let dx = x - x1
  let dy = y - y1
  let mut dx1 = x2 - x1
  let mut dy1 = y2 - y1
  let line_len = (dx1 * dx1 + dy1 * dy1).sqrt()
  if line_len == 0.0 {
    let out = @graphic.Point::new(x1, y1)
    let dist = ((x1 - x) * (x1 - x) + (y1 - y) * (y1 - y)).sqrt()
    return (out, dist)
  }
  dx1 = dx1 / line_len
  dy1 = dy1 / line_len
  let projected_len = dx * dx1 + dy * dy1
  let mut t = projected_len / line_len
  if limit_to_ends {
    t = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
  }
  t = t * line_len
  let ox = x1 + t * dx1
  let oy = y1 + t * dy1
  let dist = ((ox - x) * (ox - x) + (oy - y) * (oy - y)).sqrt()
  (@graphic.Point::new(ox, oy), dist)
}

///|
/// <=> echarts/src/label/labelGuideHelper.ts:limitTurnAngle
fn pie_limit_turn_angle(
  line_points : Array[@graphic.Point],
  min_turn_angle : Double,
) -> Unit {
  if !(min_turn_angle <= 180.0 && min_turn_angle > 0.0) {
    return
  }
  let min_turn_angle_rad = min_turn_angle / 180.0 * @math.PI
  let pt0 = line_points[0]
  let pt1 = line_points[1]
  let pt2 = line_points[2]
  let dir = pie_point_sub(pt0, pt1)
  let dir2 = pie_point_sub(pt2, pt1)
  let len1 = pie_point_len(dir)
  let len2 = pie_point_len(dir2)
  if len1 < 0.001 || len2 < 0.001 {
    return
  }
  let dir_norm = pie_point_scale(dir, 1.0 / len1)
  let dir2_norm = pie_point_scale(dir2, 1.0 / len2)
  let angle_cos = pie_point_dot(dir_norm, dir2_norm)
  let min_turn_angle_cos = @math.cos(min_turn_angle_rad)
  if min_turn_angle_cos < angle_cos {
    let (proj_point, d) = pie_project_point_to_line(
      pt1.x,
      pt1.y,
      pt2.x,
      pt2.y,
      pt0.x,
      pt0.y,
      false,
    )
    let mut tmp_proj_point = pie_point_scale_add(
      proj_point,
      dir2_norm,
      d / @math.tan(@math.PI - min_turn_angle_rad),
    )
    let t = if pt2.x != pt1.x {
      (tmp_proj_point.x - pt1.x) / (pt2.x - pt1.x)
    } else {
      (tmp_proj_point.y - pt1.y) / (pt2.y - pt1.y)
    }
    if t.is_nan() {
      return
    }
    if t < 0.0 {
      tmp_proj_point = pt1
    } else if t > 1.0 {
      tmp_proj_point = pt2
    }
    line_points[1] = tmp_proj_point
  }
}

///|
/// <=> echarts/src/label/labelGuideHelper.ts:limitSurfaceAngle
fn pie_limit_surface_angle(
  line_points : Array[@graphic.Point],
  surface_normal : @graphic.Point,
  max_surface_angle : Double,
) -> Unit {
  if !(max_surface_angle <= 180.0 && max_surface_angle > 0.0) {
    return
  }
  let max_surface_angle_rad = max_surface_angle / 180.0 * @math.PI
  let pt0 = line_points[0]
  let pt1 = line_points[1]
  let pt2 = line_points[2]
  let dir = pie_point_sub(pt1, pt0)
  let dir2 = pie_point_sub(pt2, pt1)
  let len1 = pie_point_len(dir)
  let len2 = pie_point_len(dir2)
  if len1 < 0.001 || len2 < 0.001 {
    return
  }
  let dir_norm = pie_point_scale(dir, 1.0 / len1)
  let dir2_norm = pie_point_scale(dir2, 1.0 / len2)
  let angle_cos = pie_point_dot(dir_norm, surface_normal)
  let max_surface_angle_cos = @math.cos(max_surface_angle_rad)
  if angle_cos < max_surface_angle_cos {
    let (proj_point, d) = pie_project_point_to_line(
      pt1.x,
      pt1.y,
      pt2.x,
      pt2.y,
      pt0.x,
      pt0.y,
      false,
    )
    let half_pi = @math.PI / 2.0
    let angle2 = @math.acos(pie_point_dot(dir2_norm, surface_normal))
    let new_angle = half_pi + angle2 - max_surface_angle_rad
    let mut tmp_proj_point = if new_angle >= half_pi {
      pt2
    } else {
      pie_point_scale_add(
        proj_point,
        dir2_norm,
        d / @math.tan(@math.PI / 2.0 - new_angle),
      )
    }
    let t = if pt2.x != pt1.x {
      (tmp_proj_point.x - pt1.x) / (pt2.x - pt1.x)
    } else {
      (tmp_proj_point.y - pt1.y) / (pt2.y - pt1.y)
    }
    if t.is_nan() {
      return
    }
    if t < 0.0 {
      tmp_proj_point = pt1
    } else if t > 1.0 {
      tmp_proj_point = pt2
    }
    line_points[1] = tmp_proj_point
  }
}

///|
fn pie_build_label_line_path(
  points : Array[@graphic.Point],
  smooth : Double,
) -> String {
  let p0 = points[0]
  let p1 = points[1]
  let p2 = points[2]
  if smooth > 0.0 {
    let len1 = pie_point_distance(p0, p1)
    let len2 = pie_point_distance(p1, p2)
    if len1 > 0.0 && len2 > 0.0 {
      let min_len = if len1 < len2 { len1 } else { len2 }
      let move_len = min_len * smooth
      let mid_point0 = pie_point_lerp(p1, p0, move_len / len1)
      let mid_point2 = pie_point_lerp(p1, p2, move_len / len2)
      let mid_point1 = pie_point_lerp(mid_point0, mid_point2, 0.5)
      return "M \{r4(p0.x)} \{r4(p0.y)} C \{r4(mid_point0.x)} \{r4(mid_point0.y)} \{r4(mid_point0.x)} \{r4(mid_point0.y)} \{r4(mid_point1.x)} \{r4(mid_point1.y)} C \{r4(mid_point2.x)} \{r4(mid_point2.y)} \{r4(mid_point2.x)} \{r4(mid_point2.y)} \{r4(p2.x)} \{r4(p2.y)}"
    } else {
      return "M \{r4(p0.x)} \{r4(p0.y)} L \{r4(p1.x)} \{r4(p1.y)} L \{r4(p2.x)} \{r4(p2.y)}"
    }
  } else {
    return "M \{r4(p0.x)} \{r4(p0.y)} L \{r4(p1.x)} \{r4(p1.y)} L \{r4(p2.x)} \{r4(p2.y)}"
  }
}

///|
fn pie_render_label_lines(plan : PieLabelPlan) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let line_count = plan.text_lines.length()
  if line_count == 0 {
    return elems
  }
  let line_height = plan.font_size * 1.2
  let start_y = plan.y - (line_count.to_double() - 1.0) * line_height / 2.0
  let mut i = 0
  while i < line_count {
    let line = plan.text_lines[i]
    if line != "" {
      let mut text_elem = @graphic.Element::text_custom(
        plan.x,
        start_y + i.to_double() * line_height,
        line,
        plan.text_anchor,
        plan.text_baseline,
        plan.text_color,
        plan.font_size,
        plan.font_family,
        plan.font_weight,
      ).with_opacity(plan.opacity)
      match plan.rotation {
        Some(rotation) =>
          if rotation != 0.0 && !rotation.is_nan() {
            text_elem = text_elem.with_rotation(rotation)
          }
        None => ()
      }
      elems.push(text_elem)
    }
    i += 1
  }
  elems
}

///|
fn pie_render_label_plan(plan : PieLabelPlan) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  if plan.line_show {
    match plan.line_points {
      Some(points) => {
        let path_d = pie_build_label_line_path(points, plan.line_smooth)
        let dash = pie_label_line_dash(plan.line_type)
        let line_elem = if dash.length() > 0 {
          @graphic.Element::path_stroke_custom_dashed(
            path_d,
            plan.line_color,
            plan.line_width,
            "butt",
            "miter",
            dash,
            plan.line_opacity,
          )
        } else {
          @graphic.Element::path_stroke_custom(
            path_d,
            plan.line_color,
            plan.line_width,
            "butt",
            "miter",
            plan.line_opacity,
          )
        }
        elems.push(line_elem)
      }
      None => ()
    }
  }
  let text_elems = pie_render_label_lines(plan)
  for e in text_elems {
    elems.push(e)
  }
  elems
}

///|
/// <=> echarts/src/chart/pie/labelLayout.ts
fn pie_resolve_label_option(
  series : @option.SeriesOption,
  item : @option.DataItem,
) -> @option.GeoLabelOption {
  let base = series.label.unwrap_or(@option.GeoLabelOption::default())
  match item.label {
    Some(label) => {
      let show = match label.show {
        Some(v) => v
        None => base.show
      }
      let color = match label.color {
        Some(v) => v
        None => base.color
      }
      let position = match label.position {
        Some(v) => Some(v)
        None => base.position
      }
      let distance = match label.distance {
        Some(v) => Some(v)
        None => base.distance
      }
      let font_weight = match label.font_weight {
        Some(v) => Some(v)
        None => base.font_weight
      }
      let rotate_mode = match label.rotate_mode {
        Some(v) => Some(v)
        None => base.rotate_mode
      }
      let align_to = match label.align_to {
        Some(v) => Some(v)
        None => base.align_to
      }
      let edge_distance = match label.edge_distance {
        Some(v) => Some(v)
        None => base.edge_distance
      }
      let bleed_margin = match label.bleed_margin {
        Some(v) => Some(v)
        None => base.bleed_margin
      }
      let distance_to_label_line = match label.distance_to_label_line {
        Some(v) => Some(v)
        None => base.distance_to_label_line
      }
      let font_size = match label.font_size {
        Some(v) => v
        None => base.font_size
      }
      let font_family = match label.font_family {
        Some(v) => v
        None => base.font_family
      }
      let formatter = match label.formatter {
        Some(v) => Some(v)
        None => base.formatter
      }
      let rotate = match label.rotate {
        Some(v) => Some(v)
        None =>
          match label.rotate_mode {
            Some(_) => None
            None => base.rotate
          }
      }
      {
        show,
        color,
        position,
        distance,
        font_weight,
        rotate,
        rotate_mode,
        align_to,
        edge_distance,
        bleed_margin,
        distance_to_label_line,
        font_size,
        font_family,
        formatter,
      }
    }
    None => base
  }
}

///|
/// <=> echarts/src/chart/pie/labelLayout.ts
fn pie_build_label_plan(
  series : @option.SeriesOption,
  label : @option.GeoLabelOption,
  label_text : String,
  slice_color : String,
  slice_opacity : Double,
  slice_cx : Double,
  slice_cy : Double,
  r_inner : Double,
  r_outer : Double,
  slice_r_outer : Double,
  mid_angle : Double,
  nx : Double,
  ny : Double,
  view_rect : @graphic.BBox,
) -> PieLabelPlan {
  let text_lines = pie_label_lines(label_text)
  let font_size = label.font_size
  let text_width = pie_estimate_text_width(text_lines, font_size)
  let height = pie_estimate_text_height(text_lines, font_size)
  let position = label.position.unwrap_or("outer")
  let is_inside = position == "inside" ||
    position == "inner" ||
    position == "center"
  let side_sign = pie_side_sign(nx)
  let align_to = label.align_to.unwrap_or("none")
  let edge_distance = parse_pct_or_px(
    label.edge_distance.unwrap_or("25%"),
    view_rect.width,
  )
  let bleed_margin = label.bleed_margin.unwrap_or(
    if view_rect.width > 200.0 && view_rect.height > 200.0 {
      10.0
    } else {
      2.0
    },
  )
  let distance_to_label_line = label.distance_to_label_line.unwrap_or(5.0)
  let rotation = pie_label_rotation_rad(
    position,
    label.rotate,
    label.rotate_mode,
    nx,
    ny,
    mid_angle,
  )
  let text_color = if label.color == "inherit" {
    slice_color
  } else {
    label.color
  }
  let text_anchor = if is_inside {
    @graphic.TextAnchor::Middle
  } else if align_to == "edge" {
    if side_sign > 0 {
      @graphic.TextAnchor::End
    } else {
      @graphic.TextAnchor::Start
    }
  } else if side_sign > 0 {
    @graphic.TextAnchor::Start
  } else {
    @graphic.TextAnchor::End
  }
  let text_baseline = @graphic.TextBaseline::Middle
  if is_inside {
    let inside_offset = match label.distance {
      Some(v) => v
      None => 5.0
    }
    let inside_r = (r_inner + slice_r_outer) / 2.0
    let x = if position == "center" {
      slice_cx
    } else {
      slice_cx + (inside_r + inside_offset) * @math.cos(mid_angle)
    }
    let y = if position == "center" {
      slice_cy
    } else {
      slice_cy + (inside_r + inside_offset) * @math.sin(mid_angle)
    }
    {
      text_lines,
      x,
      y,
      text_width,
      height,
      text_color,
      font_size,
      font_family: label.font_family,
      font_weight: label.font_weight.unwrap_or("normal"),
      text_anchor,
      text_baseline,
      rotation,
      opacity: slice_opacity,
      side_sign,
      surface_normal: @graphic.Point::new(nx, ny),
      align_to,
      bleed_margin,
      distance_to_label_line,
      line_points: None,
      line_show: false,
      line_color: slice_color,
      line_width: series.pie_label_line_width,
      line_type: series.pie_label_line_type,
      line_opacity: match series.pie_label_line_opacity {
        Some(v) => v
        None => slice_opacity
      },
      line_smooth: series.pie_label_line_smooth,
      line_min_turn_angle: series.pie_label_line_min_turn_angle,
      line_max_surface_angle: series.pie_label_line_max_surface_angle,
    }
  } else {
    let line_start_x = slice_cx + slice_r_outer * @math.cos(mid_angle)
    let line_start_y = slice_cy + slice_r_outer * @math.sin(mid_angle)
    let line_mid_r = r_outer + series.pie_label_line_length
    let line_mid_x = slice_cx + line_mid_r * @math.cos(mid_angle)
    let line_mid_y = slice_cy + line_mid_r * @math.sin(mid_angle)
    let line_end_x = line_mid_x +
      (if side_sign > 0 {
        series.pie_label_line_length2
      } else {
        -series.pie_label_line_length2
      })
    let line_end_y = line_mid_y
    let x = if align_to == "edge" {
      if side_sign > 0 {
        view_rect.right() - edge_distance
      } else {
        view_rect.x + edge_distance
      }
    } else {
      line_end_x +
      (if side_sign > 0 {
        distance_to_label_line
      } else {
        -distance_to_label_line
      })
    }
    {
      text_lines,
      x,
      y: line_end_y,
      text_width,
      height,
      text_color,
      font_size,
      font_family: label.font_family,
      font_weight: label.font_weight.unwrap_or("normal"),
      text_anchor,
      text_baseline,
      rotation,
      opacity: slice_opacity,
      side_sign,
      surface_normal: @graphic.Point::new(nx, ny),
      align_to,
      bleed_margin,
      distance_to_label_line,
      line_points: Some([
        @graphic.Point::new(line_start_x, line_start_y),
        @graphic.Point::new(line_mid_x, line_mid_y),
        @graphic.Point::new(line_end_x, line_end_y),
      ]),
      line_show: series.pie_label_line_show,
      line_color: match series.pie_label_line_color {
        Some(v) => v
        None => slice_color
      },
      line_width: series.pie_label_line_width,
      line_type: series.pie_label_line_type,
      line_opacity: match series.pie_label_line_opacity {
        Some(v) => v
        None => slice_opacity
      },
      line_smooth: series.pie_label_line_smooth,
      line_min_turn_angle: series.pie_label_line_min_turn_angle,
      line_max_surface_angle: series.pie_label_line_max_surface_angle,
    }
  }
}

///|
fn pie_sort_indices_by_y(
  indices : Array[Int],
  plans : Array[PieLabelPlan],
) -> Array[Int] {
  let sorted : Array[Int] = []
  for idx in indices {
    sorted.push(idx)
  }
  let mut a = 1
  while a < sorted.length() {
    let key = sorted[a]
    let key_y = plans[key].y
    let mut b = a
    while b > 0 && plans[sorted[b - 1]].y > key_y {
      sorted[b] = sorted[b - 1]
      b -= 1
    }
    sorted[b] = key
    a += 1
  }
  sorted
}

///|
/// <=> echarts/src/chart/pie/labelLayout.ts:avoidOverlap
fn pie_adjust_label_side(
  plans : Array[PieLabelPlan],
  indices : Array[Int],
  view_rect : @graphic.BBox,
) -> Unit {
  if indices.length() < 2 {
    return
  }
  let sorted = pie_sort_indices_by_y(indices, plans)
  let gap = 2.0
  let mut i = 0
  while i < sorted.length() {
    let idx = sorted[i]
    let plan = plans[idx]
    let half_h = plan.height / 2.0
    let min_y = view_rect.y + plan.bleed_margin + half_h
    let max_y = view_rect.bottom() - plan.bleed_margin - half_h
    let mut y = plan.y
    if i == 0 {
      if y < min_y {
        y = min_y
      }
    } else {
      let prev = plans[sorted[i - 1]]
      let prev_bottom = prev.y + prev.height / 2.0
      let wanted = prev_bottom + gap + half_h
      if y < wanted {
        y = wanted
      }
      if y < min_y {
        y = min_y
      }
    }
    if y > max_y {
      y = max_y
    }
    plans[idx] = { ..plan, y, }
    i += 1
  }

  let first_idx = sorted[0]
  let last_idx = sorted[sorted.length() - 1]
  let first_plan = plans[first_idx]
  let last_plan = plans[last_idx]
  let top_limit = view_rect.y + first_plan.bleed_margin
  let bottom_limit = view_rect.bottom() - last_plan.bleed_margin
  let last_bottom = last_plan.y + last_plan.height / 2.0
  if last_bottom > bottom_limit {
    let delta = last_bottom - bottom_limit
    for idx in sorted {
      plans[idx] = { ..plans[idx], y: plans[idx].y - delta }
    }
  }
  let first_top_after = plans[first_idx].y - plans[first_idx].height / 2.0
  if first_top_after < top_limit {
    let delta = top_limit - first_top_after
    for idx in sorted {
      plans[idx] = { ..plans[idx], y: plans[idx].y + delta }
    }
  }
}

///|
/// <=> echarts/src/chart/pie/labelLayout.ts:avoidOverlap
fn pie_adjust_label_plans(
  plans : Array[PieLabelPlan],
  view_rect : @graphic.BBox,
) -> Unit {
  let left_indices : Array[Int] = []
  let right_indices : Array[Int] = []
  for i, _ in plans {
    let plan = plans[i]
    match plan.line_points {
      Some(_) =>
        if plan.side_sign < 0 {
          left_indices.push(i)
        } else {
          right_indices.push(i)
        }
      None => ()
    }
  }
  pie_adjust_label_side(plans, right_indices, view_rect)
  pie_adjust_label_side(plans, left_indices, view_rect)
}

///|
/// <=> echarts/src/chart/pie/labelLayout.ts
fn pie_finalize_label_plan(
  plan : PieLabelPlan,
  view_rect : @graphic.BBox,
) -> PieLabelPlan {
  match plan.line_points {
    Some(points) => {
      let mut text_x = plan.x
      if plan.align_to != "edge" {
        if plan.side_sign > 0 {
          let max_x = view_rect.right() - plan.bleed_margin - plan.text_width
          if text_x > max_x {
            text_x = max_x
          }
        } else {
          let min_x = view_rect.x + plan.bleed_margin + plan.text_width
          if text_x < min_x {
            text_x = min_x
          }
        }
      }
      let line_end_x = if plan.align_to == "edge" {
        text_x +
        plan.side_sign.to_double() *
        (plan.text_width + plan.distance_to_label_line)
      } else {
        text_x - plan.side_sign.to_double() * plan.distance_to_label_line
      }
      let dist = points[1].x - points[2].x
      let line_points = points
      line_points[1] = @graphic.Point::new(line_end_x + dist, plan.y)
      line_points[2] = @graphic.Point::new(line_end_x, plan.y)
      { ..plan, x: text_x, y: plan.y, line_points: Some(line_points) }
    }
    None => plan
  }
}

///|
/// Render all pie/donut series in the option to scene graph elements.
pub fn render_pies(
  opt : @option.ChartOption,
  _coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut color_idx = 0

  for si, _ in opt.series {
    let series = opt.series[si]
    match series.series_type {
      Pie => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let series_elems = render_pie_series(opt, series, color_idx)

    for i, _ in series_elems {
      elems.push(series_elems[i])
    }
    color_idx = color_idx + 1
  }
  elems
}

///|
/// Render a single pie series.
pub fn render_pie_series(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
  series_index : Int,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let label_plans : Array[PieLabelPlan] = []
  let mut has_label_rotate = false
  let nd = series.data.length()
  if nd == 0 {
    return elems
  }

  // --- Parse viewRect + center ---
  let (view_rect, cx, cy) = pie_resolve_view_rect_and_center(opt, series)

  // --- Parse radius ---
  // ECharts: percentage relative to min(viewRect.width, viewRect.height) / 2
  let ref_r = (if view_rect.width < view_rect.height {
      view_rect.width
    } else {
      view_rect.height
    }) /
    2.0
  let (r_inner, r_outer) = if series.radius.length() >= 2 {
    (
      parse_pct_or_px(series.radius[0], ref_r),
      parse_pct_or_px(series.radius[1], ref_r),
    )
  } else if series.radius.length() == 1 {
    // <=> echarts/src/util/layout.ts:getCircleLayout
    // scalar radius means [0, radius]
    (0.0, parse_pct_or_px(series.radius[0], ref_r))
  } else {
    (0.0, ref_r * 0.75)
  }

  let r_outer = if r_outer >= 0.0 { r_outer } else { 0.0 }
  let r_inner = if r_inner >= 0.0 {
    if r_inner <= r_outer {
      r_inner
    } else {
      r_outer
    }
  } else {
    0.0
  }

  // --- Compute totals ---
  let mut total_positive = 0.0
  let mut positive_count = 0
  let mut non_negative_count = 0
  let mut max_value = 0.0
  let mut di = 0
  while di < nd {
    let item = series.data[di]
    di += 1
    match item.value {
      Num(n) if n > 0.0 => {
        total_positive = total_positive + n
        positive_count = positive_count + 1
        non_negative_count = non_negative_count + 1
        if n > max_value {
          max_value = n
        }
      }
      Num(n) if n >= 0.0 => non_negative_count = non_negative_count + 1
      _ => ()
    }
  }

  let zero_sum_mode = total_positive <= 0.0 &&
    series.pie_still_show_zero_sum &&
    non_negative_count > 0

  if total_positive <= 0.0 && !zero_sum_mode {
    if !series.pie_show_empty_circle {
      return elems
    }
    // Empty-circle fallback: render a gray ring when there is no data.
    // Corresponds to: PieView.ts emptyCircle handling (emptyCircleStyle).
    let empty_color = series.pie_empty_circle_color.unwrap_or("#e0e2e5")
    let empty_path = if r_inner <= 0.5 {
      "M \{r4(cx)} \{r4(cy - r_outer)} A \{r4(r_outer)} \{r4(r_outer)} 0 1 1 \{r4(cx - 0.001)} \{r4(cy - r_outer)} Z"
    } else {
      let ro = r_outer
      let ri = r_inner
      "M \{r4(cx)} \{r4(cy - ro)} A \{r4(ro)} \{r4(ro)} 0 1 1 \{r4(cx - 0.001)} \{r4(cy - ro)} Z M \{r4(cx)} \{r4(cy - ri)} A \{r4(ri)} \{r4(ri)} 0 1 0 \{r4(cx - 0.001)} \{r4(cy - ri)} Z"
    }
    elems.push(@graphic.Element::path_filled(empty_path, empty_color, 1.0))
    return elems
  }

  // --- ECharts pie layout controls ---
  // startAngle/endAngle options are in degrees and converted by negative sign.
  let clockwise = series.clockwise
  let dir = if clockwise { 1.0 } else { -1.0 }
  let start_angle = -series.start_angle / 180.0 * @math.PI
  let end_angle = if series.end_angle.is_nan() {
    0.0 / 0.0
  } else {
    -series.end_angle / 180.0 * @math.PI
  }
  let pi2 = @math.PI * 2.0
  let selected_offset = series.pie_selected_offset
  let rose_type = series.pie_rose_type
  let min_angle_rad = if series.min_angle > 0.0 {
    series.min_angle / 180.0 * @math.PI
  } else {
    0.0
  }
  let pad_angle_rad = if series.pad_angle > 0.0 {
    series.pad_angle / 180.0 * @math.PI
  } else {
    0.0
  }
  let min_show_label_angle = if series.pie_min_show_label_angle > 0.0 {
    series.pie_min_show_label_angle
  } else {
    0.0
  }
  let rose_enabled = match rose_type {
    Some("radius") => true
    Some("area") => true
    _ => false
  }
  let rose_area_mode = rose_type == Some("area")
  let selected_flags = @option.pie_selected_flags(
    series.data,
    series.pie_selected_mode,
  )
  let render_indices : Array[Int] = []
  let render_values : Array[Double] = []
  let angle_weights : Array[Double] = []
  let mut di2 = 0
  while di2 < nd {
    let item = series.data[di2]
    match item.value {
      Num(n) if n > 0.0 => {
        render_indices.push(di2)
        render_values.push(n)
        angle_weights.push(if rose_area_mode { 1.0 } else { n })
      }
      Num(n) if zero_sum_mode && n >= 0.0 => {
        render_indices.push(di2)
        render_values.push(n)
        angle_weights.push(1.0)
      }
      _ => ()
    }
    di2 = di2 + 1
  }

  if render_indices.length() == 0 {
    return elems
  }

  let total_weight = angle_weights.fold(init=0.0, fn(acc, v) { acc + v })
  let total_sweep = if end_angle.is_nan() {
    pi2
  } else {
    pie_directed_sweep(start_angle, end_angle, clockwise)
  }

  let n_slices = render_indices.length().to_double()
  let pad_total = if n_slices > 0.0 { pad_angle_rad * n_slices } else { 0.0 }
  let available_sweep = if total_sweep > pad_total {
    total_sweep - pad_total
  } else {
    0.0
  }
  let effective_min_angle = if n_slices > 0.0 &&
    min_angle_rad * n_slices > available_sweep {
    available_sweep / n_slices
  } else {
    min_angle_rad
  }

  let spans : Array[Double] = []
  for i, _ in angle_weights {
    let w = angle_weights[i]
    let raw = if total_weight > 0.0 {
      available_sweep * w / total_weight
    } else {
      0.0
    }
    spans.push(
      if raw >= effective_min_angle {
        raw
      } else {
        effective_min_angle
      },
    )
  }
  let span_sum = spans.fold(init=0.0, fn(acc, v) { acc + v })
  if span_sum > 0.0 {
    let scale = available_sweep / span_sum
    for i, _ in spans {
      spans[i] = spans[i] * scale
    }
  }

  let mut current_angle = start_angle

  // Check if any slice is highlighted; if so non-highlighted slices blur to 0.1 opacity.
  // <=> echarts/src/util/states.ts:createBlurDefaultState
  let any_highlighted = @visual.has_any_highlighted(series.data)

  for k, _ in render_indices {
    let data_idx = render_indices[k]
    let item = series.data[data_idx]
    let value = render_values[k]
    let span = spans[k]
    let base_slice_color = match item.item_style {
      Some({ color: Some(c), .. }) => c
      _ =>
        match series.item_style {
          Some(c) => c
          None => @visual.palette_color(series_index + data_idx)
        }
    }
    // Emphasis: lift color if highlighted; blur: reduce opacity if peer is highlighted.
    // <=> echarts/src/util/states.ts:resolve_item_emphasis_color_opacity
    let (slice_color, slice_opacity) = @visual.resolve_item_emphasis_color_opacity(
      item, any_highlighted, base_slice_color, 1.0,
    )

    // <=> echarts/src/chart/pie/pieLayout.ts
    // r = roseType ? linearMap(value, [0, max], [r0, r]) : r
    let slice_r_outer = if rose_enabled && max_value > 0.0 {
      pie_linear_map(value, 0.0, max_value, r_inner, r_outer)
    } else {
      r_outer
    }
    let a0 = current_angle
    let a1 = current_angle + dir * span
    current_angle = a1 + dir * pad_angle_rad
    let mid_angle = (a0 + a1) / 2.0

    // selected offset: shift slice outward from center.
    // Corresponds to: PieView.ts PieSeriesModel selectedOffset.
    let is_selected = selected_flags[k]
    let off = if is_selected { selected_offset } else { 0.0 }
    let slice_cx = cx + off * @math.cos(mid_angle)
    let slice_cy = cy + off * @math.sin(mid_angle)

    let large_arc = if span > @math.PI { 1 } else { 0 }
    let outer_sweep = if clockwise { 1 } else { 0 }
    let inner_sweep = if clockwise { 0 } else { 1 }

    // Outer arc points (relative to possibly-offset slice center)
    let x0 = slice_cx + slice_r_outer * @math.cos(a0)
    let y0 = slice_cy + slice_r_outer * @math.sin(a0)
    let x1 = slice_cx + slice_r_outer * @math.cos(a1)
    let y1 = slice_cy + slice_r_outer * @math.sin(a1)

    let path_d = if r_inner <= 0.5 {
      // Full pie: M cx cy L x0 y0 A R R 0 large 1 x1 y1 Z
      "M \{r4(slice_cx)} \{r4(slice_cy)} L \{r4(x0)} \{r4(y0)} A \{r4(slice_r_outer)} \{r4(slice_r_outer)} 0 \{large_arc} \{outer_sweep} \{r4(x1)} \{r4(y1)} Z"
    } else {
      // Donut ring: outer arc forward, inner arc backward
      let xi0 = slice_cx + r_inner * @math.cos(a0)
      let yi0 = slice_cy + r_inner * @math.sin(a0)
      let xi1 = slice_cx + r_inner * @math.cos(a1)
      let yi1 = slice_cy + r_inner * @math.sin(a1)
      "M \{r4(x0)} \{r4(y0)} A \{r4(slice_r_outer)} \{r4(slice_r_outer)} 0 \{large_arc} \{outer_sweep} \{r4(x1)} \{r4(y1)} L \{r4(xi1)} \{r4(yi1)} A \{r4(r_inner)} \{r4(r_inner)} 0 \{large_arc} \{inner_sweep} \{r4(xi0)} \{r4(yi0)} Z"
    }

    elems.push(
      @graphic.Element::path_fill_stroke(
        path_d, slice_color, "#ffffff", 1.0, slice_opacity,
      ),
    )

    // Label: midpoint angle, outside the slice
    // Apply formatter: {a}=seriesName {b}=name {c}=value {d}=percent
    // <=> echarts/src/chart/pie/PieView.ts + dataFormat.ts getFormattedLabel
    let label_opt = pie_resolve_label_option(series, item)
    if label_opt.show {
      let item_name = match item.name {
        Some(n) => n
        None => ""
      }
      let series_name = series.name.unwrap_or("")
      let value_str = if value.to_int().to_double() == value {
        value.to_int().to_string()
      } else {
        value.to_string()
      }
      let pct_raw = if total_weight > 0.0 {
        angle_weights[k] / total_weight * 100.0
      } else {
        0.0
      }
      let percent_str = pie_format_percent(
        pct_raw,
        series.pie_percent_precision,
      )
      let label_text = @option.apply_label_formatter(
        Some(label_opt),
        series_name,
        item_name,
        value_str,
        Some(percent_str),
      )
      if label_text != "" {
        let span_deg = span / @math.PI * 180.0
        if span_deg < min_show_label_angle {
          continue
        }
        let plan = pie_build_label_plan(
          series,
          pie_resolve_label_option(series, item),
          label_text,
          slice_color,
          slice_opacity,
          slice_cx,
          slice_cy,
          r_inner,
          r_outer,
          slice_r_outer,
          mid_angle,
          @math.cos(mid_angle),
          @math.sin(mid_angle),
          view_rect,
        )
        match plan.rotation {
          Some(rotation) =>
            if rotation != 0.0 && !rotation.is_nan() {
              has_label_rotate = true
            }
          None => ()
        }
        label_plans.push(plan)
      }
    }
  }
  // Upstream pie uses both the pie-specific avoidLabelOverlap switch and the
  // generic labelLayout.hideOverlap default in the static overlap pass.
  if (series.pie_avoid_label_overlap || series.pie_label_layout_hide_overlap) &&
    !has_label_rotate {
    pie_adjust_label_plans(label_plans, view_rect)
  }
  for i, _ in label_plans {
    let plan = pie_finalize_label_plan(label_plans[i], view_rect)
    let final_plan = match plan.line_points {
      Some(points) => {
        let line_points = points
        pie_limit_turn_angle(line_points, plan.line_min_turn_angle)
        pie_limit_surface_angle(
          line_points,
          plan.surface_normal,
          plan.line_max_surface_angle,
        )
        { ..plan, line_points: Some(line_points) }
      }
      None => plan
    }
    let plan_elems = pie_render_label_plan(final_plan)
    for e in plan_elems {
      elems.push(e)
    }
  }
  elems
}

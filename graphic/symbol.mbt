// Corresponds to: echarts/src/util/symbol.ts (createSymbol, makePath)
// Symbol creation utilities used by chart types that render custom symbols.

///|
/// Create a path Element normalized to a 400×400 coordinate space,
/// then wrapped in a group with a transform that maps it to (x,y,w,h).
/// Corresponds to graphic.makePath(..., BoundingRect, 'cover') in zrender.
pub fn normalized_path_symbol_with_opacity(
  d : String,
  color : String,
  opacity : Double,
) -> Element {
  match path_bbox(d) {
    Some(bounds) =>
      normalized_path_symbol_with_bounds(d, color, opacity, bounds)
    None =>
      match fallback_path_bbox(d) {
        Some(bounds) =>
          normalized_path_symbol_with_bounds(d, color, opacity, bounds)
        None => Element::path_filled(d, color, opacity)
      }
  }
}

///|
pub fn normalized_path_symbol_with_bounds(
  d : String,
  color : String,
  opacity : Double,
  bounds : (Double, Double, Double, Double),
) -> Element {
  let symbol_pattern_size = 400.0
  let (min_x, min_y, max_x, max_y) = bounds
  let width = max_x - min_x
  let height = max_y - min_y
  let sx = if width.abs() > 0.000001 {
    symbol_pattern_size / width
  } else {
    1.0
  }
  let sy = if height.abs() > 0.000001 {
    symbol_pattern_size / height
  } else {
    1.0
  }
  let transform = Matrix::translate(
    -(symbol_pattern_size / 2.0) - min_x * sx,
    -(symbol_pattern_size / 2.0) - min_y * sy,
  ).then(Matrix::scale(sx, sy))
  Element::group_transformed(
    [Element::path_filled(d, color, opacity)],
    transform,
  )
}

///|
fn triangle_path(x : Double, y : Double, w : Double, h : Double) -> String {
  let cx = x + w / 2.0
  let top = y
  let right = x + w
  let bottom = y + h
  let left = x
  "M \{cx} \{top} L \{right} \{bottom} L \{left} \{bottom} Z"
}

///|
fn square_rect(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> (Double, Double, Double, Double) {
  let size = if w < h { w } else { h }
  (x, y, size, size)
}

///|
fn diamond_path(x : Double, y : Double, w : Double, h : Double) -> String {
  let cx = x + w / 2.0
  let cy = y + h / 2.0
  let right = x + w
  let bottom = y + h
  let left = x
  "M \{cx} \{y} L \{right} \{cy} L \{cx} \{bottom} L \{left} \{cy} Z"
}

///|
fn pin_path(x : Double, y : Double, w : Double, h : Double) -> String {
  let cx = x + w / 2.0
  let cy = y + h / 2.0
  let body_w = w / 5.0 * 3.0
  let body_h = if body_w > h { body_w } else { h }
  let r = body_w / 2.0
  let dy = r * r / (body_h - r)
  let circle_cy = cy - body_h / 2.0 + r + dy
  let angle = @math.asin(dy / r)
  let dx = @math.cos(angle) * r
  let tan_x = @math.sin(angle)
  let tan_y = @math.cos(angle)
  let cp_len = r * 0.6
  let cp_len2 = r * 0.7
  let start_x = cx - dx
  let start_y = circle_cy + dy
  let end_x = cx + dx
  let end_y = circle_cy + dy
  let arc_start = @math.PI - angle
  let arc_end = 2.0 * @math.PI + angle
  let large_arc = if (arc_end - arc_start).abs() > @math.PI { 1 } else { 0 }
  let tip_y = cy + body_h / 2.0
  "M \{start_x} \{start_y} A \{r} \{r} 0 \{large_arc} 1 \{end_x} \{end_y} C \{end_x - tan_x * cp_len} \{end_y + tan_y * cp_len} \{cx} \{tip_y - cp_len2} \{cx} \{tip_y} C \{cx} \{tip_y - cp_len2} \{start_x + tan_x * cp_len} \{start_y + tan_y * cp_len} \{start_x} \{start_y} Z"
}

///|
fn arrow_path(x : Double, y : Double, w : Double, h : Double) -> String {
  let cy = y + h / 2.0
  let right = x + w
  let left = x
  let stem = x + w / 3.0
  let top = y
  let bottom = y + h
  let notch_top = y + h * 0.25
  let notch_bottom = y + h * 0.75
  "M \{right} \{cy} L \{stem} \{top} L \{stem} \{notch_top} L \{left} \{notch_top} L \{left} \{notch_bottom} L \{stem} \{notch_bottom} L \{stem} \{bottom} Z"
}

///|
fn symbol_path(
  shape : String,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> String? {
  match shape {
    "triangle" => Some(triangle_path(x, y, w, h))
    "diamond" => Some(diamond_path(x, y, w, h))
    "arrow" => Some(arrow_path(x, y, w, h))
    "pin" => Some(pin_path(x, y, w, h))
    "roundRect" =>
      Some(round_rect_path(x, y, w, h, if w < h { w * 0.25 } else { h * 0.25 }))
    _ => None
  }
}

///|
fn normalized_path_symbol_fill_stroke_with_bounds(
  d : String,
  fill_color : String,
  stroke_color : String,
  stroke_width : Double,
  opacity : Double,
  bounds : (Double, Double, Double, Double),
) -> Element {
  let symbol_pattern_size = 400.0
  let (min_x, min_y, max_x, max_y) = bounds
  let width = max_x - min_x
  let height = max_y - min_y
  let sx = if width.abs() > 0.000001 {
    symbol_pattern_size / width
  } else {
    1.0
  }
  let sy = if height.abs() > 0.000001 {
    symbol_pattern_size / height
  } else {
    1.0
  }
  let transform = Matrix::translate(
    -(symbol_pattern_size / 2.0) - min_x * sx,
    -(symbol_pattern_size / 2.0) - min_y * sy,
  ).then(Matrix::scale(sx, sy))
  Element::group_transformed(
    [
      Element::path_fill_stroke(
        d, fill_color, stroke_color, stroke_width, opacity,
      ),
    ],
    transform,
  )
}

///|
fn normalized_path_symbol_fill_stroke(
  d : String,
  fill_color : String,
  stroke_color : String,
  stroke_width : Double,
  opacity : Double,
) -> Element {
  match path_bbox(d) {
    Some(bounds) =>
      normalized_path_symbol_fill_stroke_with_bounds(
        d, fill_color, stroke_color, stroke_width, opacity, bounds,
      )
    None =>
      match fallback_path_bbox(d) {
        Some(bounds) =>
          normalized_path_symbol_fill_stroke_with_bounds(
            d, fill_color, stroke_color, stroke_width, opacity, bounds,
          )
        None =>
          Element::path_fill_stroke(
            d, fill_color, stroke_color, stroke_width, opacity,
          )
      }
  }
}

///|
/// Create a symbol element of the given type at (x, y, w, h).
/// Corresponds to createSymbol() in echarts/src/util/symbol.ts.
pub fn make_symbol(
  symbol : String,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  color : String,
  opacity : Double,
) -> Element {
  match symbol {
    "rect" => Element::rect_colored_opacity(x, y, w, h, color, opacity)
    "triangle" =>
      Element::path_filled(triangle_path(x, y, w, h), color, opacity)
    "diamond" => Element::path_filled(diamond_path(x, y, w, h), color, opacity)
    "arrow" => Element::path_filled(arrow_path(x, y, w, h), color, opacity)
    "roundRect" => {
      let d = round_rect_path(
        x,
        y,
        w,
        h,
        if w < h {
          w * 0.25
        } else {
          h * 0.25
        },
      )
      Element::path_filled(d, color, opacity)
    }
    _ if symbol.has_prefix("path://") => {
      let d = symbol[7:].to_string()
      let symbol_pattern_size = 400.0
      let transform = Matrix::translate(x + w / 2.0, y + h / 2.0).then(
        Matrix::scale(w / symbol_pattern_size, h / symbol_pattern_size),
      )
      Element::group_transformed(
        [normalized_path_symbol_with_opacity(d, color, opacity)],
        transform,
      )
    }
    _ => {
      let r = if w < h { w / 2.0 } else { h / 2.0 }
      Element::circle_colored_opacity(
        x + w / 2.0,
        y + h / 2.0,
        r,
        color,
        opacity,
      )
    }
  }
}

///|
/// Create a symbol element with explicit fill and stroke.
/// Used by chart types like tree that need `emptyCircle`-style symbols.
pub fn make_symbol_fill_stroke(
  symbol : String,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  fill_color : String,
  stroke_color : String,
  stroke_width : Double,
  opacity : Double,
) -> Element {
  match symbol {
    "rect" =>
      Element::rect_fill_stroke_opacity(
        x, y, w, h, fill_color, stroke_color, stroke_width, opacity,
      )
    "square" => {
      let (rx, ry, rw, rh) = square_rect(x, y, w, h)
      Element::rect_fill_stroke_opacity(
        rx, ry, rw, rh, fill_color, stroke_color, stroke_width, opacity,
      )
    }
    "circle" =>
      Element::circle_fill_stroke(
        x + w / 2.0,
        y + h / 2.0,
        if w < h {
          w / 2.0
        } else {
          h / 2.0
        },
        fill_color,
        stroke_color,
        stroke_width,
      )
    "emptyCircle" =>
      Element::circle_fill_stroke(
        x + w / 2.0,
        y + h / 2.0,
        if w < h {
          w / 2.0
        } else {
          h / 2.0
        },
        fill_color,
        stroke_color,
        stroke_width,
      )
    "line" =>
      Element::line_colored(
        x,
        y + h / 2.0,
        x + w,
        y + h / 2.0,
        stroke_color,
        stroke_width,
      )
    _ if symbol.has_prefix("path://") => {
      let d = symbol[7:].to_string()
      let symbol_pattern_size = 400.0
      let transform = Matrix::translate(x + w / 2.0, y + h / 2.0).then(
        Matrix::scale(w / symbol_pattern_size, h / symbol_pattern_size),
      )
      Element::group_transformed(
        [
          normalized_path_symbol_fill_stroke(
            d, fill_color, stroke_color, stroke_width, opacity,
          ),
        ],
        transform,
      )
    }
    _ =>
      match symbol_path(symbol, x, y, w, h) {
        Some(d) =>
          Element::path_fill_stroke(
            d, fill_color, stroke_color, stroke_width, opacity,
          )
        None =>
          Element::circle_fill_stroke(
            x + w / 2.0,
            y + h / 2.0,
            if w < h {
              w / 2.0
            } else {
              h / 2.0
            },
            fill_color,
            stroke_color,
            stroke_width,
          )
      }
  }
}

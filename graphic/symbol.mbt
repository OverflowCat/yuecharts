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
fn diamond_path(x : Double, y : Double, w : Double, h : Double) -> String {
  let cx = x + w / 2.0
  let cy = y + h / 2.0
  let right = x + w
  let bottom = y + h
  let left = x
  "M \{cx} \{y} L \{right} \{cy} L \{cx} \{bottom} L \{left} \{cy} Z"
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

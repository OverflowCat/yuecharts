// Corresponds to: zrender/src/core/Point.ts, zrender/src/core/BoundingRect.ts,
// zrender/src/core/matrix.ts (for transformations),
// zrender/src/graphic/helper/subPixelOptimize.ts (sub-pixel snapping),
// and echarts/src/util/graphic.ts (lineLineIntersect, expandOrShrinkRect).

///|
/// 2D point.
pub(all) struct Point {
  x : Double
  y : Double
}

///|
pub fn Point::new(x : Double, y : Double) -> Point {
  { x, y }
}

///|
pub impl Show for Point with output(self, logger) {
  logger.write_string("\{self.x},\{self.y}")
}

///|
/// Axis-aligned bounding box.
pub struct BBox {
  x : Double
  y : Double
  width : Double
  height : Double
}

///|
pub fn BBox::new(
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> BBox {
  { x, y, width, height }
}

///|
pub fn BBox::right(self : BBox) -> Double {
  self.x + self.width
}

///|
pub fn BBox::bottom(self : BBox) -> Double {
  self.y + self.height
}

///|
pub fn BBox::center_x(self : BBox) -> Double {
  self.x + self.width / 2.0
}

///|
pub fn BBox::center_y(self : BBox) -> Double {
  self.y + self.height / 2.0
}

///|
/// 2×3 affine transform matrix (row-major).
/// [ a  c  e ]
/// [ b  d  f ]
/// [ 0  0  1 ]
pub struct Matrix {
  a : Double
  b : Double
  c : Double
  d : Double
  e : Double
  f : Double
}

///|
/// Identity matrix.
pub let identity : Matrix = { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 }

///|
pub fn Matrix::translate(tx : Double, ty : Double) -> Matrix {
  { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: tx, f: ty }
}

///|
pub fn Matrix::scale(sx : Double, sy : Double) -> Matrix {
  { a: sx, b: 0.0, c: 0.0, d: sy, e: 0.0, f: 0.0 }
}

///|
pub fn Matrix::rotate(rad : Double) -> Matrix {
  let c = @math.cos(rad)
  let s = @math.sin(rad)
  { a: c, b: s, c: -s, d: c, e: 0.0, f: 0.0 }
}

///|
/// Apply this matrix then other (this * other).
pub fn Matrix::then(self : Matrix, other : Matrix) -> Matrix {
  {
    a: self.a * other.a + self.c * other.b,
    b: self.b * other.a + self.d * other.b,
    c: self.a * other.c + self.c * other.d,
    d: self.b * other.c + self.d * other.d,
    e: self.a * other.e + self.c * other.f + self.e,
    f: self.b * other.e + self.d * other.f + self.f,
  }
}

///|
/// Transform a point by this matrix.
pub fn Matrix::apply(self : Matrix, p : Point) -> Point {
  {
    x: self.a * p.x + self.c * p.y + self.e,
    y: self.b * p.x + self.d * p.y + self.f,
  }
}

///|
pub impl Show for Matrix with output(self, logger) {
  logger.write_string(
    "matrix(\{self.a},\{self.b},\{self.c},\{self.d},\{self.e},\{self.f})",
  )
}

// ---------------------------------------------------------------------------
// Sub-pixel optimization helpers
// From: zrender/src/graphic/helper/subPixelOptimize.ts
// ---------------------------------------------------------------------------

///|
/// Snaps a single coordinate to the nearest pixel boundary to avoid canvas
/// blur when drawing thin lines.
///
/// `line_width` = 0 means no optimization.
/// `positive` controls whether the half-pixel nudge goes positive or negative.
pub fn sub_pixel_optimize(
  position : Double,
  line_width : Double,
  positive : Bool,
) -> Double {
  if line_width == 0.0 {
    return position
  }
  let doubled = (position * 2.0).round().to_int()
  let rounded_lw = line_width.round().to_int()
  if (doubled + rounded_lw) % 2 == 0 {
    doubled.to_double() / 2.0
  } else {
    (doubled.to_double() + (if positive { 1.0 } else { -1.0 })) / 2.0
  }
}

///|
/// Sub-pixel optimize a line segment.
/// If x1 == x2 (vertical line), both are snapped; same for y1 == y2.
/// Returns optimized (x1, y1, x2, y2).
pub fn sub_pixel_optimize_line(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  line_width : Double,
) -> (Double, Double, Double, Double) {
  let mut ox1 = x1
  let mut ox2 = x2
  let mut oy1 = y1
  let mut oy2 = y2
  if line_width != 0.0 {
    if (x1 * 2.0).round().to_int() == (x2 * 2.0).round().to_int() {
      let sx = sub_pixel_optimize(x1, line_width, true)
      ox1 = sx
      ox2 = sx
    }
    if (y1 * 2.0).round().to_int() == (y2 * 2.0).round().to_int() {
      let sy = sub_pixel_optimize(y1, line_width, true)
      oy1 = sy
      oy2 = sy
    }
  }
  (ox1, oy1, ox2, oy2)
}

///|
/// Sub-pixel optimize a rectangle.
/// Returns a BBox with snapped coordinates/dimensions.
pub fn sub_pixel_optimize_rect(
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  line_width : Double,
) -> BBox {
  if line_width == 0.0 {
    return { x, y, width, height }
  }
  let new_x = sub_pixel_optimize(x, line_width, true)
  let new_y = sub_pixel_optimize(y, line_width, true)
  let new_w = (sub_pixel_optimize(x + width, line_width, false) - new_x).max(
    if width == 0.0 {
      0.0
    } else {
      1.0
    },
  )
  let new_h = (sub_pixel_optimize(y + height, line_width, false) - new_y).max(
    if height == 0.0 {
      0.0
    } else {
      1.0
    },
  )
  { x: new_x, y: new_y, width: new_w, height: new_h }
}

// ---------------------------------------------------------------------------
// 2D line intersection
// From: echarts/src/util/graphic.ts  lineLineIntersect / crossProduct2d
// ---------------------------------------------------------------------------

///|
fn cross_product_2d(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Double {
  x1 * y2 - x2 * y1
}

///|
fn near_zero(val : Double) -> Bool {
  val <= 1.0e-6 && val >= -1.0e-6
}

///|
/// Returns true if line segment (a1→a2) intersects line segment (b1→b2).
/// Parallel / collinear segments return false.
pub fn line_line_intersect(
  a1x : Double,
  a1y : Double,
  a2x : Double,
  a2y : Double,
  b1x : Double,
  b1y : Double,
  b2x : Double,
  b2y : Double,
) -> Bool {
  let mx = a2x - a1x
  let my = a2y - a1y
  let nx = b2x - b1x
  let ny = b2y - b1y
  let nm_cross = cross_product_2d(nx, ny, mx, my)
  if near_zero(nm_cross) {
    return false
  }
  let b1a1x = a1x - b1x
  let b1a1y = a1y - b1y
  let q = cross_product_2d(b1a1x, b1a1y, mx, my) / nm_cross
  if q < 0.0 || q > 1.0 {
    return false
  }
  let p = cross_product_2d(b1a1x, b1a1y, nx, ny) / nm_cross
  if p < 0.0 || p > 1.0 {
    return false
  }
  true
}

// ---------------------------------------------------------------------------
// Rect expand / shrink
// From: echarts/src/util/graphic.ts  expandOrShrinkRect
// ---------------------------------------------------------------------------

///|
/// Internal helper: expand/shrink one dimension (x/width or y/height).
/// `lt_delta` is the left or top delta; `rb_delta` is the right or bottom delta.
/// Returns (new_pos, new_size), clamped to min_size >= 0.
fn expand_dim(
  pos : Double,
  size : Double,
  lt_delta : Double,
  rb_delta : Double,
) -> (Double, Double) {
  let delta_sum = lt_delta + rb_delta
  let new_size = size + delta_sum
  if new_size < 0.0 {
    // Clamp to zero and find a reasonable position.
    let adj = if lt_delta >= 0.0 {
      -lt_delta
    } else if rb_delta >= 0.0 {
      size + rb_delta
    } else if delta_sum.abs() > 1.0e-8 {
      size * lt_delta / delta_sum
    } else {
      0.0
    }
    (pos + adj, 0.0)
  } else {
    (pos - lt_delta, new_size)
  }
}

///|
/// Expand (shrink=false) or shrink (shrink=true) `bbox` by `[top, right, bottom, left]`
/// deltas (CSS order).  When `no_negative=true` any negative delta is clamped to zero.
/// Returns a new BBox (does not mutate the input).
///
/// Ports `expandOrShrinkRect` from echarts/src/util/graphic.ts.
pub fn expand_or_shrink_bbox(
  bbox : BBox,
  top : Double,
  right : Double,
  bottom : Double,
  left : Double,
  shrink : Bool,
  no_negative : Bool,
) -> BBox {
  let t = if no_negative && top < 0.0 { 0.0 } else { top }
  let r = if no_negative && right < 0.0 { 0.0 } else { right }
  let b = if no_negative && bottom < 0.0 { 0.0 } else { bottom }
  let l = if no_negative && left < 0.0 { 0.0 } else { left }
  // shrink = flip sign so that positive delta reduces the rect
  let dt = if shrink { -t } else { t }
  let dr = if shrink { -r } else { r }
  let db = if shrink { -b } else { b }
  let dl = if shrink { -l } else { l }
  // x dimension: left = dl, right = dr
  let (new_x, new_w) = expand_dim(bbox.x, bbox.width, dl, dr)
  // y dimension: top = dt, bottom = db
  let (new_y, new_h) = expand_dim(bbox.y, bbox.height, dt, db)
  { x: new_x, y: new_y, width: new_w, height: new_h }
}

// Corresponds to: zrender/src/core/Point.ts, zrender/src/core/BoundingRect.ts
// and zrender/src/core/matrix.ts (for transformations)

///|
/// 2D point.
pub struct Point {
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

// Tests for graphic/transform.mbt
// Corresponds to: zrender/src/core/Point.ts, BoundingRect.ts, matrix.ts

///|
test "Point construction and Show" {
  let p = Point::new(3.0, 4.0)
  assert_eq(p.x, 3.0)
  assert_eq(p.y, 4.0)
  assert_eq(p.to_string(), "3,4")
}

///|
test "BBox geometry helpers" {
  let b = BBox::new(10.0, 20.0, 100.0, 50.0)
  assert_eq(b.right(), 110.0)
  assert_eq(b.bottom(), 70.0)
  assert_eq(b.center_x(), 60.0)
  assert_eq(b.center_y(), 45.0)
}

///|
test "BBox zero-size" {
  let b = BBox::new(0.0, 0.0, 0.0, 0.0)
  assert_eq(b.right(), 0.0)
  assert_eq(b.bottom(), 0.0)
  assert_eq(b.center_x(), 0.0)
  assert_eq(b.center_y(), 0.0)
}

///|
test "Matrix identity" {
  assert_eq(identity.a, 1.0)
  assert_eq(identity.b, 0.0)
  assert_eq(identity.c, 0.0)
  assert_eq(identity.d, 1.0)
  assert_eq(identity.e, 0.0)
  assert_eq(identity.f, 0.0)
}

///|
test "Matrix identity apply is no-op" {
  let p = Point::new(5.0, 7.0)
  let q = identity.apply(p)
  assert_eq(q.x, 5.0)
  assert_eq(q.y, 7.0)
}

///|
test "Matrix translate" {
  let t = Matrix::translate(10.0, 20.0)
  let p = Point::new(1.0, 2.0)
  let q = t.apply(p)
  assert_eq(q.x, 11.0)
  assert_eq(q.y, 22.0)
}

///|
test "Matrix scale" {
  let s = Matrix::scale(2.0, 3.0)
  let p = Point::new(4.0, 5.0)
  let q = s.apply(p)
  assert_eq(q.x, 8.0)
  assert_eq(q.y, 15.0)
}

///|
test "Matrix then (composition)" {
  let t = Matrix::translate(5.0, 0.0)
  let s = Matrix::scale(2.0, 2.0)
  // t.then(s): the composed matrix: apply to (1,1)
  // Matrix::then multiplies as self * other in column-major sense
  // trace: ts.a=2, ts.e=5, so x=2*1+0*1+5=7
  let ts = t.then(s)
  let q = ts.apply(Point::new(1.0, 1.0))
  assert_eq(q.x, 7.0)
  assert_eq(q.y, 2.0)
}

///|
test "Matrix then with identity" {
  let t = Matrix::translate(3.0, 4.0)
  let ti = t.then(identity)
  let p = Point::new(1.0, 1.0)
  assert_eq(ti.apply(p).x, t.apply(p).x)
  assert_eq(ti.apply(p).y, t.apply(p).y)
}

///|
test "Matrix show" {
  let m = Matrix::translate(1.0, 2.0)
  assert_eq(m.to_string(), "matrix(1,0,0,1,1,2)")
}

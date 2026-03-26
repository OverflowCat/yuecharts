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

// ---------------------------------------------------------------------------
// sub_pixel_optimize
// Ported from: echarts/test/ut/spec/util/graphic.test.ts  subPixelOptimize_base
// ---------------------------------------------------------------------------

///|
test "sub_pixel_optimize base" {
  assert_eq(sub_pixel_optimize(5.0, 1.0, false), 4.5)
  assert_eq(sub_pixel_optimize(5.0, 2.0, false), 5.0)
  assert_eq(sub_pixel_optimize(5.0, 43.0, false), 4.5)
  assert_eq(sub_pixel_optimize(7.5, 1.0, false), 7.5)
  assert_eq(sub_pixel_optimize(7.5, 2.0, false), 7.0)
  assert_eq(sub_pixel_optimize(14.0, 1.0, true), 14.5)
  assert_eq(sub_pixel_optimize(14.0, 2.0, true), 14.0)
  assert_eq(sub_pixel_optimize(-11.0, 1.0, false), -11.5)
  assert_eq(sub_pixel_optimize(-11.0, 2.0, false), -11.0)
  assert_eq(sub_pixel_optimize(0.0, 2.0, false), 0.0)
  assert_eq(sub_pixel_optimize(0.0, 1.0, false), -0.5)
  // line_width=0 → no optimization
  assert_eq(sub_pixel_optimize(5.0, 0.0, false), 5.0)
}

// ---------------------------------------------------------------------------
// sub_pixel_optimize_line
// Ported from: echarts/test/ut/spec/util/graphic.test.ts  subPixelOptimize_line
// ---------------------------------------------------------------------------

///|
test "sub_pixel_optimize_line diagonal - no snapping" {
  // x1≠x2 and y1≠y2, nothing to snap
  assert_eq(
    sub_pixel_optimize_line(5.0, 11.0, 3.0, 7.0, 1.0),
    (5.0, 11.0, 3.0, 7.0),
  )
}

///|
test "sub_pixel_optimize_line vertical x1==x2" {
  // round(5*2)==round(5*2), so x snapped
  assert_eq(
    sub_pixel_optimize_line(5.0, 11.0, 5.0, 7.0, 1.0),
    (5.5, 11.0, 5.5, 7.0),
  )
}

///|
test "sub_pixel_optimize_line vertical even linewidth - no snap needed" {
  assert_eq(
    sub_pixel_optimize_line(5.0, 11.0, 5.0, 7.0, 2.0),
    (5.0, 11.0, 5.0, 7.0),
  )
}

///|
test "sub_pixel_optimize_line horizontal y1==y2" {
  assert_eq(
    sub_pixel_optimize_line(5.0, 11.0, 15.0, 11.0, 1.0),
    (5.0, 11.5, 15.0, 11.5),
  )
}

///|
test "sub_pixel_optimize_line horizontal even linewidth - no snap needed" {
  assert_eq(
    sub_pixel_optimize_line(5.0, 11.0, 15.0, 11.0, 2.0),
    (5.0, 11.0, 15.0, 11.0),
  )
}

///|
test "sub_pixel_optimize_line horizontal odd linewidth 3" {
  assert_eq(
    sub_pixel_optimize_line(5.0, 11.0, 15.0, 11.0, 3.0),
    (5.0, 11.5, 15.0, 11.5),
  )
}

///|
test "sub_pixel_optimize_line already-half-pixel y - no snap needed" {
  assert_eq(
    sub_pixel_optimize_line(5.0, 11.0, 15.0, 11.5, 3.0),
    (5.0, 11.0, 15.0, 11.5),
  )
}

///|
test "sub_pixel_optimize_line both already half y - no snap needed" {
  assert_eq(
    sub_pixel_optimize_line(5.0, 11.5, 15.0, 11.5, 3.0),
    (5.0, 11.5, 15.0, 11.5),
  )
}

///|
test "sub_pixel_optimize_line even linewidth 4 - snap to integer" {
  assert_eq(
    sub_pixel_optimize_line(5.0, 11.5, 15.0, 11.5, 4.0),
    (5.0, 12.0, 15.0, 12.0),
  )
}

// ---------------------------------------------------------------------------
// sub_pixel_optimize_rect
// Ported from: echarts/test/ut/spec/util/graphic.test.ts  subPixelOptimize_rect
// ---------------------------------------------------------------------------

///|
test "sub_pixel_optimize_rect odd linewidth 1" {
  let r = sub_pixel_optimize_rect(5.0, 11.0, 3.0, 7.0, 1.0)
  assert_eq(r.x, 5.5)
  assert_eq(r.y, 11.5)
  assert_eq(r.width, 2.0)
  assert_eq(r.height, 6.0)
}

///|
test "sub_pixel_optimize_rect even linewidth 2 - no snap" {
  let r = sub_pixel_optimize_rect(5.0, 11.0, 3.0, 7.0, 2.0)
  assert_eq(r.x, 5.0)
  assert_eq(r.y, 11.0)
  assert_eq(r.width, 3.0)
  assert_eq(r.height, 7.0)
}

///|
test "sub_pixel_optimize_rect odd linewidth 3" {
  let r = sub_pixel_optimize_rect(5.0, 11.0, 3.0, 7.0, 3.0)
  assert_eq(r.x, 5.5)
  assert_eq(r.y, 11.5)
  assert_eq(r.width, 2.0)
  assert_eq(r.height, 6.0)
}

///|
test "sub_pixel_optimize_rect boundary width=1" {
  let r = sub_pixel_optimize_rect(5.0, 11.0, 1.0, 7.0, 1.0)
  assert_eq(r.x, 5.5)
  assert_eq(r.y, 11.5)
  assert_eq(r.width, 1.0)
  assert_eq(r.height, 6.0)
}

///|
test "sub_pixel_optimize_rect zero height" {
  let r = sub_pixel_optimize_rect(5.0, 11.0, 1.0, 0.0, 1.0)
  assert_eq(r.x, 5.5)
  assert_eq(r.y, 11.5)
  assert_eq(r.width, 1.0)
  assert_eq(r.height, 0.0)
}

// ---------------------------------------------------------------------------
// line_line_intersect
// Ported from: echarts/test/ut/spec/util/graphic.test.ts  lineLineIntersect
// ---------------------------------------------------------------------------

///|
test "line_line_intersect degenerate point" {
  assert_eq(
    line_line_intersect(10.0, 10.0, 30.0, 30.0, 10.0, 10.0, 10.0, 10.0),
    false,
  )
}

///|
test "line_line_intersect parallel and collinear" {
  // parallel
  assert_eq(
    line_line_intersect(10.0, 20.0, 30.0, 40.0, 100.0, 220.0, 120.0, 240.0),
    false,
  )
  // collinear, non-overlapping
  assert_eq(
    line_line_intersect(10.0, 10.0, 30.0, 30.0, 40.0, 40.0, 50.0, 50.0),
    false,
  )
  // identical
  assert_eq(
    line_line_intersect(10.0, 10.0, 30.0, 30.0, 10.0, 10.0, 30.0, 30.0),
    false,
  )
  // B contained in A (collinear)
  assert_eq(
    line_line_intersect(10.0, 10.0, 30.0, 30.0, 20.0, 20.0, 30.0, 30.0),
    false,
  )
  assert_eq(
    line_line_intersect(10.0, 10.0, 30.0, 30.0, 20.0, 20.0, 22.0, 22.0),
    false,
  )
}

///|
test "line_line_intersect intersecting" {
  assert_eq(
    line_line_intersect(10.0, 20.0, 30.0, 40.0, 12.0, 20.0, 30.0, 40.0),
    true,
  )
  assert_eq(
    line_line_intersect(10.0, 20.0, 30.0, 40.0, 12.0, 20.0, 20.0, 42.0),
    true,
  )
}

// ---------------------------------------------------------------------------
// expand_or_shrink_bbox
// Ported from: echarts/test/ut/spec/util/graphic.test.ts  expandOrShrinkRect
// ---------------------------------------------------------------------------

///|
test "expand_or_shrink_bbox expand with noNegative" {
  // delta=[top=10, right=20, bottom=30, left=40], expand, no_negative
  let r = expand_or_shrink_bbox(
    BBox::new(100.0, 200.0, 300.0, 400.0),
    10.0,
    20.0,
    30.0,
    40.0,
    false,
    true,
  )
  assert_eq(r.x, 60.0)
  assert_eq(r.y, 190.0)
  assert_eq(r.width, 360.0)
  assert_eq(r.height, 440.0)
}

///|
test "expand_or_shrink_bbox expand negative delta clamped to 0" {
  // All delta negative → clamped to 0 → rect unchanged
  let r = expand_or_shrink_bbox(
    BBox::new(100.0, 200.0, 300.0, 400.0),
    -10.0,
    -20.0,
    -30.0,
    -40.0,
    false,
    true,
  )
  assert_eq(r.x, 100.0)
  assert_eq(r.y, 200.0)
  assert_eq(r.width, 300.0)
  assert_eq(r.height, 400.0)
}

///|
test "expand_or_shrink_bbox shrink negative delta clamped to 0" {
  let r = expand_or_shrink_bbox(
    BBox::new(100.0, 200.0, 300.0, 400.0),
    -10.0,
    -20.0,
    -30.0,
    -40.0,
    true,
    true,
  )
  assert_eq(r.x, 100.0)
  assert_eq(r.y, 200.0)
  assert_eq(r.width, 300.0)
  assert_eq(r.height, 400.0)
}

///|
test "expand_or_shrink_bbox shrink with noNegative" {
  let r = expand_or_shrink_bbox(
    BBox::new(100.0, 200.0, 300.0, 400.0),
    10.0,
    20.0,
    30.0,
    40.0,
    true,
    true,
  )
  assert_eq(r.x, 140.0)
  assert_eq(r.y, 210.0)
  assert_eq(r.width, 240.0)
  assert_eq(r.height, 360.0)
}

///|
test "expand_or_shrink_bbox shrink clamps width to zero" {
  // delta=[10, 200, 30, 120] shrink → width underflows
  let r = expand_or_shrink_bbox(
    BBox::new(100.0, 200.0, 300.0, 400.0),
    10.0,
    200.0,
    30.0,
    120.0,
    true,
    true,
  )
  assert_eq(r.x, 212.5)
  assert_eq(r.y, 210.0)
  assert_eq(r.width, 0.0)
  assert_eq(r.height, 360.0)
}

///|
test "expand_or_shrink_bbox shrink clamps height to zero" {
  // delta=[200, 20, 300, 40] shrink → height underflows
  let r = expand_or_shrink_bbox(
    BBox::new(100.0, 200.0, 300.0, 400.0),
    200.0,
    20.0,
    300.0,
    40.0,
    true,
    true,
  )
  assert_eq(r.x, 140.0)
  assert_eq(r.y, 360.0)
  assert_eq(r.width, 240.0)
  assert_eq(r.height, 0.0)
}

///|
test "expand_or_shrink_bbox zero delta - no change" {
  let r = expand_or_shrink_bbox(
    BBox::new(100.0, 200.0, 300.0, 400.0),
    0.0,
    0.0,
    0.0,
    0.0,
    false,
    true,
  )
  assert_eq(r.x, 100.0)
  assert_eq(r.y, 200.0)
  assert_eq(r.width, 300.0)
  assert_eq(r.height, 400.0)
}

///|
test "expand_or_shrink_bbox expand negative delta no clamp" {
  // noNegative=false: negative deltas allowed (shrink effect while expanding)
  let r = expand_or_shrink_bbox(
    BBox::new(0.0, 100.0, 200.0, 300.0),
    -10.0,
    -20.0,
    -30.0,
    -40.0,
    false,
    false,
  )
  assert_eq(r.x, 40.0)
  assert_eq(r.y, 110.0)
  assert_eq(r.width, 140.0)
  assert_eq(r.height, 260.0)
}

///|
test "expand_or_shrink_bbox width underflows no-clamp lt-positive" {
  // delta=[-10, 0, -40, -10], expand, noNeg=false → width underflows, lt>=0 case
  let r = expand_or_shrink_bbox(
    BBox::new(0.0, 100.0, 5.0, 30.0),
    -10.0,
    0.0,
    -40.0,
    -10.0,
    false,
    false,
  )
  assert_eq(r.x, 5.0)
  assert_eq(r.y, 106.0)
  assert_eq(r.width, 0.0)
  assert_eq(r.height, 0.0)
}

///|
test "expand_or_shrink_bbox height underflows zero oldSize" {
  // delta=[-10, -10, -40, 0], expand, noNeg=false → height underflows from 0
  let r = expand_or_shrink_bbox(
    BBox::new(10.0, 100.0, 5.0, 0.0),
    -10.0,
    -10.0,
    -40.0,
    0.0,
    false,
    false,
  )
  assert_eq(r.x, 10.0)
  assert_eq(r.y, 100.0)
  assert_eq(r.width, 0.0)
  assert_eq(r.height, 0.0)
}

///|
test "expand_or_shrink_bbox expand from zero-size rect" {
  // delta=[10, -10, 40, 20], expand, noNeg=false → grow on both axes
  let r = expand_or_shrink_bbox(
    BBox::new(5.0, 0.0, 0.0, 0.0),
    10.0,
    -10.0,
    40.0,
    20.0,
    false,
    false,
  )
  assert_eq(r.x, -15.0)
  assert_eq(r.y, -10.0)
  assert_eq(r.width, 10.0)
  assert_eq(r.height, 50.0)
}

///|
test "expand_or_shrink_bbox both axes underflow" {
  // delta=[-45, -50, 10, 20], expand, noNeg=false
  let r = expand_or_shrink_bbox(
    BBox::new(5.0, 0.0, 15.0, 20.0),
    -45.0,
    -50.0,
    10.0,
    20.0,
    false,
    false,
  )
  assert_eq(r.x, -15.0)
  assert_eq(r.y, 30.0)
  assert_eq(r.width, 0.0)
  assert_eq(r.height, 0.0)
}

///|
test "expand_or_shrink_bbox uniform scalar expand" {
  // scalar 10 → equivalent to [10, 10, 10, 10]
  let r = expand_or_shrink_bbox(
    BBox::new(100.0, 200.0, 300.0, 400.0),
    10.0,
    10.0,
    10.0,
    10.0,
    false,
    true,
  )
  assert_eq(r.x, 90.0)
  assert_eq(r.y, 190.0)
  assert_eq(r.width, 320.0)
  assert_eq(r.height, 420.0)
}

///|
test "expand_or_shrink_bbox uniform scalar shrink" {
  let r = expand_or_shrink_bbox(
    BBox::new(100.0, 200.0, 300.0, 400.0),
    10.0,
    10.0,
    10.0,
    10.0,
    true,
    true,
  )
  assert_eq(r.x, 110.0)
  assert_eq(r.y, 210.0)
  assert_eq(r.width, 280.0)
  assert_eq(r.height, 380.0)
}

///|
test "expand_or_shrink_bbox negative scalar expand clamped to 0" {
  // -10 all sides, noNegative=true → clamped to 0, no change
  let r = expand_or_shrink_bbox(
    BBox::new(100.0, 200.0, 300.0, 400.0),
    -10.0,
    -10.0,
    -10.0,
    -10.0,
    false,
    true,
  )
  assert_eq(r.x, 100.0)
  assert_eq(r.y, 200.0)
  assert_eq(r.width, 300.0)
  assert_eq(r.height, 400.0)
}

///|
test "expand_or_shrink_bbox negative scalar shrink clamped to 0" {
  let r = expand_or_shrink_bbox(
    BBox::new(100.0, 200.0, 300.0, 400.0),
    -10.0,
    -10.0,
    -10.0,
    -10.0,
    true,
    true,
  )
  assert_eq(r.x, 100.0)
  assert_eq(r.y, 200.0)
  assert_eq(r.width, 300.0)
  assert_eq(r.height, 400.0)
}

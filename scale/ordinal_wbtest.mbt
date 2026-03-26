// Corresponds to: echarts/src/scale/Ordinal.ts
// White-box tests for OrdinalScale.

///|
fn approx_eq_ord(a : Double, b : Double) -> Bool {
  let diff = if a > b { a - b } else { b - a }
  diff < 1.0e-9
}

///|
test "ordinal_scale band_step" {
  // 4 categories over [0, 400]
  let s = OrdinalScale::new(["a", "b", "c", "d"], 0.0, 400.0, 0.0)
  assert_true(approx_eq_ord(s.band_step(), 100.0))
}

///|
test "ordinal_scale band_width with padding" {
  // padding 0.2 → band_width = step * (1 - 0.2) = 80
  let s = OrdinalScale::new(["a", "b", "c", "d"], 0.0, 400.0, 0.2)
  assert_true(approx_eq_ord(s.band_step(), 100.0))
  assert_true(approx_eq_ord(s.band_width(), 80.0))
}

///|
test "ordinal_scale band_center" {
  let s = OrdinalScale::new(["a", "b", "c"], 0.0, 300.0, 0.0)
  // step = 100; centers at 50, 150, 250
  assert_true(approx_eq_ord(s.band_center(0), 50.0))
  assert_true(approx_eq_ord(s.band_center(1), 150.0))
  assert_true(approx_eq_ord(s.band_center(2), 250.0))
}

///|
test "ordinal_scale band_start no padding" {
  let s = OrdinalScale::new(["a", "b", "c"], 0.0, 300.0, 0.0)
  // half_pad = 0; starts at 0, 100, 200
  assert_true(approx_eq_ord(s.band_start(0), 0.0))
  assert_true(approx_eq_ord(s.band_start(1), 100.0))
  assert_true(approx_eq_ord(s.band_start(2), 200.0))
}

///|
test "ordinal_scale band_start with padding" {
  // step = 100, padding = 0.2 → half_pad = 10
  let s = OrdinalScale::new(["a", "b", "c"], 0.0, 300.0, 0.2)
  assert_true(approx_eq_ord(s.band_start(0), 10.0))
  assert_true(approx_eq_ord(s.band_start(1), 110.0))
  assert_true(approx_eq_ord(s.band_start(2), 210.0))
}

///|
test "ordinal_scale index_of found and not found" {
  let s = OrdinalScale::new(
    ["Mon", "Tue", "Wed", "Thu", "Fri"],
    0.0,
    500.0,
    0.0,
  )
  assert_eq(s.index_of("Mon"), Some(0))
  assert_eq(s.index_of("Wed"), Some(2))
  assert_eq(s.index_of("Fri"), Some(4))
  assert_eq(s.index_of("Sat"), None)
  assert_eq(s.index_of(""), None)
}

///|
test "ordinal_scale data_to_pixel" {
  let s = OrdinalScale::new(["a", "b", "c"], 0.0, 300.0, 0.0)
  // step = 100; center of "a" = 50, "b" = 150, "c" = 250
  assert_eq(s.data_to_pixel("a"), Some(50.0))
  assert_eq(s.data_to_pixel("b"), Some(150.0))
  assert_eq(s.data_to_pixel("c"), Some(250.0))
  assert_eq(s.data_to_pixel("d"), None)
}

///|
test "ordinal_scale empty categories" {
  let s = OrdinalScale::new([], 0.0, 100.0, 0.0)
  assert_true(approx_eq_ord(s.band_step(), 0.0))
  assert_true(approx_eq_ord(s.band_width(), 0.0))
  assert_eq(s.index_of("x"), None)
  assert_eq(s.data_to_pixel("x"), None)
}

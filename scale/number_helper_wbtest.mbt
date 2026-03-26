// Corresponds to: echarts/src/util/number.ts
// Tests for get_precision_safe, linear_map, and add_safe ported from
// echarts/test/ut/spec/util/number.test.ts.

///|
fn approx(a : Double, b : Double) -> Bool {
  if a.is_nan() && b.is_nan() {
    return true
  }
  if a.is_inf() && b.is_inf() {
    return (a > 0.0) == (b > 0.0)
  }
  let diff = if a > b { a - b } else { b - a }
  diff < 1.0e-9
}

// ===== get_precision_safe =====

///|
test "get_precision_safe basic integer cases" {
  assert_eq(get_precision_safe(10.0), 0)
  assert_eq(get_precision_safe(1.0), 0)
  assert_eq(get_precision_safe(0.0), 0)
  assert_eq(get_precision_safe(1.0e30), 0)
}

///|
test "get_precision_safe fractional cases" {
  assert_eq(get_precision_safe(0.1), 1)
  assert_eq(get_precision_safe(0.0032), 4)
  assert_eq(get_precision_safe(0.0000000000034), 13)
}

///|
test "get_precision_safe scientific notation" {
  assert_eq(get_precision_safe(1.0e100), 0)
  assert_eq(get_precision_safe(3.456e100), 0)
  assert_eq(get_precision_safe(3.456e-100), 103)
  assert_eq(get_precision_safe(3.4e-10), 11)
  assert_eq(get_precision_safe(3.4), 1)
  assert_eq(get_precision_safe(3.0), 0)
  assert_eq(get_precision_safe(3.45e1), 1) // 34.5 → 1 decimal
  assert_eq(get_precision_safe(3.45e-1), 3) // 0.345 → 3 decimals
  assert_eq(get_precision_safe(3.45e2), 0) // 345 → 0 decimals
  assert_eq(get_precision_safe(0.456e2), 1) // 45.6 → 1 decimal
  assert_eq(get_precision_safe(0.456e-2), 5) // 0.00456 → 5 decimals
  assert_eq(get_precision_safe(0.4e2), 0) // 40.0 → 0 decimals
  assert_eq(get_precision_safe(0.4e-2), 3) // 0.004 → 3 decimals
}

// ===== linear_map =====

///|
test "linear_map accuracy error fix" {
  // Should not be 17724.899999999998 — same accuracy fix as JS.
  let r = linear_map(100.0, 0.0, 100.0, -15918.3, 17724.9, true)
  assert_true(approx(r, 17724.9))

  let r2 = linear_map(100.0, 0.0, 100.0, -62.83, 83.56, true)
  assert_true(approx(r2, 83.56))
}

///|
test "linear_map clamp normal range" {
  // bigger than max
  assert_true(
    approx(linear_map(100.1, 0.0, 100.0, -15918.3, 17724.9, true), 17724.9),
  )
  // smaller than min
  assert_true(
    approx(linear_map(-2.0, 0.0, 100.0, -15918.3, 17724.9, true), -15918.3),
  )
  // equals max
  assert_true(
    approx(linear_map(100.0, 0.0, 100.0, -15918.3, 17724.9, true), 17724.9),
  )
  // equals min
  assert_true(
    approx(linear_map(0.0, 0.0, 100.0, -15918.3, 17724.9, true), -15918.3),
  )
}

///|
test "linear_map clamp inverse range" {
  // bigger than domain max → clamped to r1 (which is r0's side for inverse range)
  assert_true(
    approx(linear_map(102.0, 0.0, 100.0, 17724.9, -15918.3, true), -15918.3),
  )
  // smaller than domain min → clamped to r0
  assert_true(
    approx(linear_map(-0.001, 0.0, 100.0, 17724.9, -15918.3, true), 17724.9),
  )
}

///|
test "linear_map clamp inverse domain" {
  // domain [100, 0] (inverse): val=102 is bigger than d0=100 → r0
  assert_true(
    approx(linear_map(102.0, 100.0, 0.0, -15918.3, 17724.9, true), -15918.3),
  )
  // val=-0.001 is less than d1=0 → r1
  assert_true(
    approx(linear_map(-0.001, 100.0, 0.0, -15918.3, 17724.9, true), 17724.9),
  )
}

///|
test "linear_map no_clamp normal range" {
  assert_true(
    approx(
      linear_map(100.1, 0.0, 100.0, -15918.3, 17724.9, false),
      17758.543199999996,
    ),
  )
  assert_true(
    approx(linear_map(-2.0, 0.0, 100.0, -15918.3, 17724.9, false), -16591.164),
  )
  assert_true(
    approx(linear_map(100.0, 0.0, 100.0, -15918.3, 17724.9, false), 17724.9),
  )
  assert_true(
    approx(linear_map(0.0, 0.0, 100.0, -15918.3, 17724.9, false), -15918.3),
  )
}

///|
test "linear_map no_clamp inverse range" {
  assert_true(
    approx(
      linear_map(102.0, 0.0, 100.0, 17724.9, -15918.3, false),
      -16591.163999999997,
    ),
  )
  assert_true(
    approx(
      linear_map(-0.001, 0.0, 100.0, 17724.9, -15918.3, false),
      17725.236432,
    ),
  )
  assert_true(
    approx(linear_map(100.0, 0.0, 100.0, 17724.9, -15918.3, false), -15918.3),
  )
  assert_true(
    approx(linear_map(0.0, 0.0, 100.0, 17724.9, -15918.3, false), 17724.9),
  )
}

///|
test "linear_map normal mapping" {
  // normal — both clamp=true and false give same result (value in domain)
  assert_true(approx(linear_map(40.0, 0.0, 100.0, 444.0, 555.0, true), 488.4))
  assert_true(approx(linear_map(40.0, 0.0, 100.0, 444.0, 555.0, false), 488.4))
  // inverse range
  assert_true(approx(linear_map(40.0, 0.0, 100.0, 555.0, 444.0, true), 510.6))
  // inverse domain and range
  assert_true(approx(linear_map(40.0, 100.0, 0.0, 555.0, 444.0, true), 488.4))
  // inverse domain
  assert_true(approx(linear_map(40.0, 100.0, 0.0, 444.0, 555.0, true), 510.6))
}

///|
test "linear_map zero domain" {
  // zero domain → midpoint of range (regardless of clamp)
  assert_true(
    approx(
      linear_map(
        40.0, 1212222223.2323232, 1212222223.2323232, 444.0, 555.0, true,
      ),
      499.5,
    ),
  )
  assert_true(
    approx(
      linear_map(
        40.0, 1212222223.2323232, 1212222223.2323232, 444.0, 555.0, false,
      ),
      499.5,
    ),
  )
  // zero range → return r0
  let r = linear_map(
    40.0, 0.0, 100.0, 1221212.1221372238, 1221212.1221372238, true,
  )
  assert_true(approx(r, 1221212.1221372238))
}

// ===== add_safe =====

///|
test "add_safe basic integer arithmetic" {
  assert_true(approx(add_safe(1.0, 0.0), 1.0))
  assert_true(approx(add_safe(1.0, 1.0), 2.0))
  assert_true(approx(add_safe(1.0, -45.0), -44.0))
  assert_true(approx(add_safe(1.0, 22.0), 23.0))
  assert_true(approx(add_safe(100.0, 100.0), 200.0))
  assert_true(approx(add_safe(0.0, 0.0), 0.0))
  assert_true(approx(add_safe(-1.0, 1.0), 0.0))
  assert_true(approx(add_safe(54.0, -54.0), 0.0))
  assert_true(approx(add_safe(99999.0, 1.0), 100000.0))
}

///|
test "add_safe float precision fix" {
  // Key floating-point cases that bare + fails
  assert_true(approx(add_safe(0.1, 0.2), 0.3))
  assert_true(approx(add_safe(2.3, -0.3), 2.0))
  assert_true(approx(add_safe(33643.2, -15918.3), 17724.9))
  assert_true(approx(add_safe(146.39, -62.83), 83.56))
  assert_true(approx(add_safe(1.09, -0.13), 0.96))
  assert_true(approx(add_safe(1.0, 0.09), 1.09))
  assert_true(approx(add_safe(1.0, -0.0001), 0.9999))
  assert_true(approx(add_safe(-0.01, 0.01), 0.0))
  assert_true(approx(add_safe(9.99, -9.99), 0.0))
  assert_true(approx(add_safe(-999.99, 0.01), -999.98))
}

///|
test "add_safe NaN propagation" {
  let nan = 0.0 / 0.0
  assert_true(add_safe(1.0, nan).is_nan())
  assert_true(add_safe(nan, 1.0).is_nan())
  assert_true(add_safe(nan, nan).is_nan())
}

///|
test "add_safe infinity" {
  let inf = 1.0 / 0.0
  let neg_inf = -1.0 / 0.0
  assert_true(add_safe(1.0, inf).is_inf())
  assert_true(add_safe(1.0, neg_inf).is_neg_inf())
  assert_true(add_safe(inf, inf).is_pos_inf())
  assert_true(add_safe(inf, neg_inf).is_nan())
  assert_true(add_safe(neg_inf, neg_inf).is_neg_inf())
}

///|
test "add_safe mixed scale" {
  assert_true(approx(add_safe(1.0, 6.1915), 7.1915))
  assert_true(approx(add_safe(1.0, -1.02), -0.02))
  assert_true(approx(add_safe(1.0, 8.0e5), 800001.0))
  assert_true(approx(add_safe(1.0, 9.0e12), 9000000000001.0))
  assert_true(approx(add_safe(43534.5435, 0.054645), 43534.598145))
  assert_true(approx(add_safe(3.333, -4.0), -0.667))
  assert_true(approx(add_safe(-1.0, -0.1), -1.1))
}

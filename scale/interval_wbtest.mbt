// Corresponds to: echarts/test/ut/spec/scale/interval.test.ts
// and validates the current port in scale/linear.mbt, which corresponds to
// echarts/src/scale/Interval.ts.

///|
fn approx_eq(a : Double, b : Double) -> Bool {
  let diff = if a > b { a - b } else { b - a }
  diff < 0.0000000001
}

///|
test "scale_interval ticks_small_value" {
  let scale = LinearScale::new(0.0, 0.0000034, 0.0, 100.0)
  let ticks = scale.ticks(7)
  let expected_values = [
    0.0, 0.0000005, 0.000001, 0.0000015, 0.000002, 0.0000025, 0.000003, 0.0000035,
  ]
  let expected_labels = [
    "0.0000000", "0.0000005", "0.0000010", "0.0000015", "0.0000020", "0.0000025",
    "0.0000030", "0.0000035",
  ]

  assert_eq(ticks.length(), expected_values.length())

  for i, _ in ticks {
    assert_true(approx_eq(ticks[i].value, expected_values[i]))
    assert_eq(ticks[i].label, expected_labels[i])
    assert_true(!ticks[i].label.contains("e"))
  }
}

///|
test "scale_interval cases" {
  let cases = [
    (LinearScale::new(3.7210923755786733e-8, 176.4352516752083, 0.0, 100.0), 1),
    (LinearScale::new(1550932.3941785, 1550932.3941786, 0.0, 100.0), 5),
    (LinearScale::new(-3711126.9907707, -3711126.990770699, 0.0, 100.0), 5),
  ]

  for case in cases {
    let (scale, split_number) = case
    let ticks = scale.ticks(split_number)
    assert_true(ticks.length() > 0)
    assert_true(ticks[0].value <= ticks[ticks.length() - 1].value)
    assert_true(ticks[0].label != "")
    assert_true(ticks[ticks.length() - 1].label != "")
  }
}

///|
test "scale_linear data_to_pixel and pixel_to_data" {
  // Maps domain [0, 100] to range [0, 500]
  let scale = LinearScale::new(0.0, 100.0, 0.0, 500.0)
  // midpoint
  assert_true(approx_eq(scale.data_to_pixel(50.0), 250.0))
  // min edge
  assert_true(approx_eq(scale.data_to_pixel(0.0), 0.0))
  // max edge
  assert_true(approx_eq(scale.data_to_pixel(100.0), 500.0))
  // inverse: pixel -> data
  assert_true(approx_eq(scale.pixel_to_data(250.0), 50.0))
  assert_true(approx_eq(scale.pixel_to_data(0.0), 0.0))
  assert_true(approx_eq(scale.pixel_to_data(500.0), 100.0))
}

///|
test "scale_linear data_to_pixel inverted range" {
  // Some charts invert the y-axis: range goes from pixel_bottom to pixel_top
  let scale = LinearScale::new(0.0, 100.0, 400.0, 0.0)
  // value 0 → pixel 400 (bottom), value 100 → pixel 0 (top)
  assert_true(approx_eq(scale.data_to_pixel(0.0), 400.0))
  assert_true(approx_eq(scale.data_to_pixel(100.0), 0.0))
  assert_true(approx_eq(scale.data_to_pixel(50.0), 200.0))
}

///|
test "scale_linear extend grows domain" {
  let scale = LinearScale::new(0.0, 10.0, 0.0, 100.0)
  let ticks_before = scale.ticks(5)
  assert_true(ticks_before[ticks_before.length() - 1].value <= 15.0)
  scale.extend(50.0)
  let ticks_after = scale.ticks(5)
  // nice_max should now cover 50
  assert_true(ticks_after[ticks_after.length() - 1].value >= 50.0)
}

///|
test "scale_linear step values" {
  // Domain [0, 10] with 5 ticks → step should be 2
  let scale = LinearScale::new(0.0, 10.0, 0.0, 100.0)
  assert_true(approx_eq(scale.step(5), 2.0))
  // Domain [0, 100] with 5 ticks → step should be 20
  let scale2 = LinearScale::new(0.0, 100.0, 0.0, 500.0)
  assert_true(approx_eq(scale2.step(5), 20.0))
}

///|
test "format_tick integer step" {
  // When step >= 1, labels should be integers
  let scale = LinearScale::new(0.0, 10.0, 0.0, 100.0)
  let ticks = scale.ticks(5)
  for tick in ticks {
    assert_true(!tick.label.contains("."))
  }
}

///|
test "format_tick fractional step" {
  // Domain [0, 1] with ~5 ticks → step is 0.2, labels should have 1 decimal
  let scale = LinearScale::new(0.0, 1.0, 0.0, 100.0)
  let ticks = scale.ticks(5)
  // Check labels like "0.0", "0.2", "0.4", "0.6", "0.8", "1.0"
  for tick in ticks {
    if tick.value > 0.0 && tick.value < 1.0 {
      assert_true(tick.label.contains("."))
      // No scientific notation
      assert_true(!tick.label.contains("e"))
    }
  }
}

// Whitebox tests for coord/single.mbt.

///|
test "single axis keeps upstream default type value" {
  let json_str =
    #|{
    #|  "singleAxis": {},
    #|  "series": [{
    #|    "type": "themeRiver",
    #|    "data": [[0, 2, "A"], [2, 4, "A"]]
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let single = Single::build(opt).unwrap()
  assert_true(single.axis_type == @option.AxisType::Value)
  assert_eq(single.min_val, 0.0)
  assert_eq(single.max_val, 2.0)
}

///|
test "single axis converts between data and point in horizontal mode" {
  let json_str =
    #|{
    #|  "width": 800,
    #|  "height": 600,
    #|  "singleAxis": { "min": 0, "max": 2 },
    #|  "series": [{
    #|    "type": "themeRiver",
    #|    "data": [[0, 2, "A"], [2, 4, "A"]]
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let single = Single::build(opt).unwrap()
  let point = single.data_to_point("1")
  assert_eq(point.x, 400.0)
  assert_eq(point.y, 300.0)
  assert_eq(single.point_to_data(@graphic.Point::new(400.0, 300.0))[0], 1.0)
  assert_true(single.contain_point(@graphic.Point::new(400.0, 300.0)))
}

///|
test "single axis layout follows singleAxisHelper top-axis directions" {
  let json_str =
    #|{
    #|  "singleAxis": {
    #|    "position": "top",
    #|    "axisTick": { "inside": true },
    #|    "axisLabel": { "inside": true, "rotate": 30 }
    #|  },
    #|  "series": [{
    #|    "type": "themeRiver",
    #|    "data": [[0, 2, "A"], [2, 4, "A"]]
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let single = Single::build(opt).unwrap()
  let layout = single.layout(opt.single_axis[0])
  assert_eq(layout.y, single.bbox.y)
  assert_eq(layout.tick_direction, 1)
  assert_eq(layout.label_direction, 1)
  assert_eq(layout.label_rotate, -30.0)
  assert_eq(single.prepare_custom().coord_sys.type_name, "singleAxis")
}

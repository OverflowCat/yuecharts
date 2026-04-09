// Whitebox tests for coord/view.mbt.

///|
test "view builds sankey layout rect from box-layout defaults" {
  let json_str =
    #|{
    #|  "width": 500,
    #|  "height": 400,
    #|  "series": [{
    #|    "type": "sankey",
    #|    "data": [{"name": "A"}, {"name": "B"}],
    #|    "links": [{"source": "A", "target": "B", "value": 1}]
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let views = View::build(opt)
  assert_eq(views.length(), 1)
  let view = views[0]
  assert_eq(view.series_index, 0)
  assert_eq(view.view_rect.x, 25.0)
  assert_eq(view.view_rect.y, 20.0)
  assert_eq(view.view_rect.width, 375.0)
  assert_eq(view.view_rect.height, 360.0)
  assert_eq(view.data_to_point([0.0, 0.0]), [25.0, 20.0])
  assert_eq(view.point_to_data([25.0, 20.0]), [0.0, 0.0])
  assert_true(view.contain_point([30.0, 30.0]))
  assert_true(View::find_for_series(views, 0) is Some(_))
}

///|
test "view applies initial center and zoom like upstream roam transform" {
  let json_str =
    #|{
    #|  "width": 500,
    #|  "height": 400,
    #|  "series": [{
    #|    "type": "sankey",
    #|    "center": ["0%", "0%"],
    #|    "zoom": 2,
    #|    "data": [{"name": "A"}, {"name": "B"}],
    #|    "links": [{"source": "A", "target": "B", "value": 1}]
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let view = View::build(opt)[0]
  let point = view.data_to_point([0.0, 0.0])
  assert_eq(point[0], 212.5)
  assert_eq(point[1], 200.0)
  assert_eq(view.point_to_data(point), [0.0, 0.0])
  let rect = view.get_view_rect_after_roam()
  assert_eq(rect.x, 212.5)
  assert_eq(rect.y, 200.0)
  assert_eq(rect.width, 750.0)
  assert_eq(rect.height, 720.0)
  assert_true(!view.contain_point([100.0, 100.0]))
}

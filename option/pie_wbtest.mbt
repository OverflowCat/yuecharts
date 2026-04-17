// Corresponds to: echarts/src/chart/pie/PieSeries.ts
// White-box tests for pie option parsing.

///|
test "pie roseType parses radius and area" {
  let radius_series = parse_series_option(
    @json.parse(
      (
        #|{
        #|  "type": "pie",
        #|  "roseType": "radius"
        #|}
      ),
    ),
  )
  assert_eq(radius_series.pie_rose_type, Some("radius"))

  let area_series = parse_series_option(
    @json.parse(
      (
        #|{
        #|  "type": "pie",
        #|  "roseType": "area"
        #|}
      ),
    ),
  )
  assert_eq(area_series.pie_rose_type, Some("area"))
}

///|
test "pie roseType ignores unsupported values" {
  let series = parse_series_option(
    @json.parse(
      (
        #|{
        #|  "type": "pie",
        #|  "roseType": "not-supported"
        #|}
      ),
    ),
  )
  assert_eq(series.pie_rose_type, None)
}

///|
test "pie label parsing covers alignTo rotate and edgeDistance alias" {
  let series = parse_series_option(
    @json.parse(
      (
        #|{
        #|  "type": "pie",
        #|  "label": {
        #|    "position": "outer",
        #|    "rotate": false,
        #|    "alignTo": "edge",
        #|    "margin": 20,
        #|    "bleedMargin": 7,
        #|    "distanceToLabelLine": 9
        #|  }
        #|}
      ),
    ),
  )
  match series.label {
    Some(label) => {
      assert_eq(label.rotate, Some(0.0))
      assert_eq(label.rotate_mode, None)
      assert_eq(label.align_to, Some("edge"))
      assert_eq(label.edge_distance, Some("20"))
      assert_eq(label.bleed_margin, Some(7.0))
      assert_eq(label.distance_to_label_line, Some(9.0))
    }
    None => assert_true(false)
  }
}

///|
test "pie labelLine parsing covers smooth and lineStyle fields" {
  let series = parse_series_option(
    @json.parse(
      (
        #|{
        #|  "type": "pie",
        #|  "labelLine": {
        #|    "show": true,
        #|    "length": 15,
        #|    "length2": 0,
        #|    "smooth": true,
        #|    "minTurnAngle": 30,
        #|    "maxSurfaceAngle": 80,
        #|    "lineStyle": {
        #|      "color": "#112233",
        #|      "width": 2,
        #|      "type": "dotted",
        #|      "opacity": 0.4
        #|    }
        #|  }
        #|}
      ),
    ),
  )
  assert_eq(series.pie_label_line_show, true)
  assert_eq(series.pie_label_line_length, 15.0)
  assert_eq(series.pie_label_line_length2, 0.0)
  assert_eq(series.pie_label_line_smooth, 0.3)
  assert_eq(series.pie_label_line_min_turn_angle, 30.0)
  assert_eq(series.pie_label_line_max_surface_angle, 80.0)
  assert_eq(series.pie_label_line_color, Some("#112233"))
  assert_eq(series.pie_label_line_width, 2.0)
  assert_eq(series.pie_label_line_type, "dotted")
  assert_eq(series.pie_label_line_opacity, Some(0.4))
}

///|
test "pie selectedMode true parses as single selection" {
  let series = parse_series_option(
    @json.parse(
      (
        #|{
        #|  "type": "pie",
        #|  "selectedMode": true
        #|}
      ),
    ),
  )
  assert_eq(series.pie_selected_mode, Some("single"))
}

///|
test "pie animation and labelLayout parsing covers defaults and overrides" {
  let defaults = SeriesOption::default_pie()
  assert_eq(defaults.pie_label_layout_hide_overlap, true)
  assert_eq(defaults.pie_animation_type, Some("expansion"))
  assert_eq(defaults.pie_animation_duration, Some(1000.0))
  assert_eq(defaults.pie_animation_easing, Some("cubicInOut"))
  assert_eq(defaults.pie_animation_type_update, Some("transition"))
  assert_eq(defaults.pie_animation_duration_update, Some(500.0))
  assert_eq(defaults.pie_animation_easing_update, Some("cubicInOut"))

  let series = parse_series_option(
    @json.parse(
      (
        #|{
        #|  "type": "pie",
        #|  "labelLayout": { "hideOverlap": false },
        #|  "animationType": "scale",
        #|  "animationDuration": 750,
        #|  "animationEasing": "linear",
        #|  "animationTypeUpdate": "expansion",
        #|  "animationDurationUpdate": 240,
        #|  "animationEasingUpdate": "cubicOut"
        #|}
      ),
    ),
  )
  assert_eq(series.pie_label_layout_hide_overlap, false)
  assert_eq(series.pie_animation_type, Some("scale"))
  assert_eq(series.pie_animation_duration, Some(750.0))
  assert_eq(series.pie_animation_easing, Some("linear"))
  assert_eq(series.pie_animation_type_update, Some("expansion"))
  assert_eq(series.pie_animation_duration_update, Some(240.0))
  assert_eq(series.pie_animation_easing_update, Some("cubicOut"))
}

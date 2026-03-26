// Tests for graphic/element.mbt
// Corresponds to: zrender/src/graphic/Shape.ts, text baseline/anchor SVG mapping

///|
test "TextAnchor to_svg" {
  assert_eq(TextAnchor::Start.to_svg(), "start")
  assert_eq(TextAnchor::Middle.to_svg(), "middle")
  assert_eq(TextAnchor::End.to_svg(), "end")
}

///|
test "TextBaseline to_svg" {
  assert_eq(TextBaseline::Auto.to_svg(), "auto")
  assert_eq(TextBaseline::Top.to_svg(), "text-top")
  assert_eq(TextBaseline::Hanging.to_svg(), "hanging")
  assert_eq(TextBaseline::Middle.to_svg(), "middle")
  assert_eq(TextBaseline::Central.to_svg(), "central")
  assert_eq(TextBaseline::Alphabetic.to_svg(), "alphabetic")
  assert_eq(TextBaseline::Ideographic.to_svg(), "ideographic")
  assert_eq(TextBaseline::Bottom.to_svg(), "text-bottom")
}

///|
test "StrokeStyle default fields" {
  let s = StrokeStyle::default()
  assert_eq(s.width, 1.0)
  assert_eq(s.line_cap, "butt")
  assert_eq(s.line_join, "miter")
  assert_eq(s.dash.length(), 0)
}

///|
test "FillStyle default" {
  let f = FillStyle::default()
  // default fill is black
  assert_eq(f.color.to_svg(), "#000000")
}

///|
test "TextStyle default fields" {
  let t = TextStyle::default()
  assert_eq(t.font_size, 12.0)
  assert_eq(t.font_family, "sans-serif")
  assert_eq(t.font_weight, "normal")
  assert_eq(t.anchor.to_svg(), "start")
  assert_eq(t.baseline.to_svg(), "alphabetic")
}

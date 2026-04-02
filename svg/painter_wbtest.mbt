// Corresponds to: zrender/src/svg/Painter.ts, zrender/src/svg/core.ts
// White-box tests for string-vs-XML SVG painter parity.

///|
fn sample_paint_elements() -> Array[@graphic.Element] {
  let emphasis : @graphic.DisplayStateStyle = {
    fill: Some("#55aa33"),
    stroke: Some("#112233"),
    line_width: Some(2.5),
    stroke_no_scale: false,
  }
  let rect = @graphic.Element::rect_fill_stroke(
    10.0, 12.0, 30.0, 18.0, "#ffcc00", "#223344", 1.5,
  ).with_emphasis_style(emphasis)
  let line = @graphic.Element::line_colored_dashed(
    0.0,
    0.0,
    40.0,
    10.0,
    "#445566",
    2.0,
    [4.0, 2.0],
    0.7,
  )
  let clipped = @graphic.Element::group_clipped_path(
    [rect, line],
    "M0 0L40 0L40 20L0 20Z",
  )
  let transformed = @graphic.Element::group_transformed_opacity(
    [clipped],
    @graphic.Matrix::translate(3.0, 4.0),
    0.8,
  )
  let label = @graphic.Element::text_custom(
    16.0,
    24.0,
    "<A&B>",
    @graphic.TextAnchor::Middle,
    @graphic.TextBaseline::Central,
    "#101010",
    14.0,
    "serif",
    "bold",
  )
  [transformed, label]
}

///|
fn sample_accessibility() -> SvgAccessibility {
  SvgAccessibility::new(
    "img",
    Some("aria & label"),
    Some("title <x>"),
    Some("desc \"y\""),
  )
}

///|
fn sample_expected_svg() -> String {
  let expected =
    #|<svg xmlns="http://www.w3.org/2000/svg" width="96" height="72" viewBox="0 0 96 72" role="img" aria-label="aria &amp; label">
    #|  <title>title &lt;x&gt;</title>
    #|  <desc>desc &quot;y&quot;</desc>
    #|  <rect x="0" y="0" width="96" height="72" fill="#ffffff"/>
    #|  <style><![CDATA[
    #|.zr-cls-0:hover {
    #|cursor:pointer;
    #|fill:#55aa33;
    #|stroke:#112233;
    #|stroke-width:2.5;
    #|}
    #|]]></style>
    #|  <g transform="matrix(1,0,0,1,3,4)" opacity="0.8">
    #|    <clipPath id="clip-0">
    #|      <path d="M0 0L40 0L40 20L0 20Z"/>
    #|    </clipPath>
    #|    <g clip-path="url(#clip-0)">
    #|      <rect x="10" y="12" width="30" height="18" class="zr-cls-0" fill="#ffcc00" stroke="#223344" stroke-width="1.5"/>
    #|      <line x1="0" y1="0" x2="40" y2="10" stroke="#445566" stroke-width="2" stroke-dasharray="4,2" fill="none" opacity="0.7"/>
    #|    </g>
    #|  </g>
    #|  <text x="16" y="24" fill="#101010" font-size="14" font-family="serif" font-weight="bold" text-anchor="middle" dominant-baseline="central">&lt;A&amp;B&gt;</text>
    #|</svg>
  expected
}

///|
test "paint concat backend matches expected svg commands" {
  let elements = sample_paint_elements()
  let accessibility = Some(sample_accessibility())
  let expected = sample_expected_svg()
  let rendered = paint(
    elements,
    96.0,
    72.0,
    Some(@graphic.white),
    accessibility,
  )
  assert_eq(rendered, expected)
}

///|
test "paint xml-node backend matches expected svg commands" {
  let elements = sample_paint_elements()
  let accessibility = Some(sample_accessibility())
  let expected = sample_expected_svg()
  let rendered = paint_xml(
    elements,
    96.0,
    72.0,
    Some(@graphic.white),
    accessibility,
  ).to_pretty_string("  ")
  assert_eq(rendered, expected)
}

///|
test "paint utf8 and utf16le backends match expected svg commands" {
  let elements = sample_paint_elements()
  let accessibility = Some(sample_accessibility())
  let expected = sample_expected_svg()
  let utf8 = paint_utf8(
    elements,
    96.0,
    72.0,
    Some(@graphic.white),
    accessibility,
  )
  let utf16 = paint_utf16le(
    elements,
    96.0,
    72.0,
    Some(@graphic.white),
    accessibility,
  )
  assert_eq(@utf8.decode_lossy(utf8[:]), expected)
  assert_eq(
    @utf16.decode_lossy(
      utf16[:],
      ignore_bom=true,
      endianness=@utf16.Endian::Little,
    ),
    expected,
  )
}

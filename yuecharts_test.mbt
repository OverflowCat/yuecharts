// Blackbox tests run against the package's public API. Use `@yuecharts` to import.
// Prefer high-level behaviors over implementation details.
// Run `moon test` to execute and `moon test --update` to refresh snapshots.

// ECharts 6 default palette (first two entries used in tests).

///|
let palette_0 = "#5070dd" // series index 0

///|
let palette_1 = "#b6d634" // series index 1

///|
/// Bar series must use palette[0] fill color.
test "bar series uses palette color" {
  let json_str =
    #|{
    #|  "width": 600, "height": 400,
    #|  "xAxis": {"type": "category", "data": ["Mon","Tue","Wed"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [{"type": "bar", "data": [120, 200, 150]}]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(palette_0))
}

///|
/// Line series must use palette[0] for stroke and circle fill.
test "line series uses palette color" {
  let json_str =
    #|{
    #|  "width": 600, "height": 400,
    #|  "xAxis": {"type": "category", "data": ["Mon","Tue","Wed"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [{"type": "line", "data": [10, 20, 15]}]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(palette_0))
}

///|
/// Effect scatter series must use palette[0] and emit ripple circles.
test "effect scatter uses palette color and ripple circles" {
  let json_str =
    #|{
    #|  "width": 600, "height": 400,
    #|  "xAxis": {"type": "value"},
    #|  "yAxis": {"type": "value"},
    #|  "series": [{"type": "effectScatter", "symbolSize": 12, "data": [[10, 8], [12, 6]]}]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(palette_0))
  assert_true(svg.contains("opacity=\"0.33333333333333337\""))
  assert_true(svg.contains("opacity=\"0.6666666666666667\""))
}

///|
/// Two line series must use palette[0] and palette[1] respectively.
test "two line series use distinct palette colors" {
  let json_str =
    #|{
    #|  "width": 600, "height": 400,
    #|  "xAxis": {"type": "category", "data": ["Mon","Tue","Wed"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [
    #|    {"type": "line", "data": [10, 20, 15]},
    #|    {"type": "line", "data": [5, 12, 8]}
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(palette_0))
  assert_true(svg.contains(palette_1))
}

///|
/// Mixed bar+line: bar gets palette[0], line gets palette[1].
test "mixed bar+line uses palette[0] and palette[1]" {
  let json_str =
    #|{
    #|  "width": 700, "height": 450,
    #|  "xAxis": {"type": "category", "data": ["Jan","Feb","Mar","Apr","May","Jun"]},
    #|  "yAxis": [{"type": "value"}, {"type": "value"}],
    #|  "series": [
    #|    {"type": "bar", "data": [2.6, 5.9, 9.0, 26.4, 28.7, 70.7]},
    #|    {"type": "line", "yAxisIndex": 1, "data": [2.0, 2.2, 3.3, 4.5, 6.3, 10.2]}
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(palette_0))
  assert_true(svg.contains(palette_1))
}

///|
/// Snapshot test: full SVG output of the bar example.
test "bar example snapshot" {
  let json_str =
    #|{
    #|  "width": 600, "height": 400,
    #|  "xAxis": {"type": "category", "data": ["Mon","Tue","Wed"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [{"type": "bar", "data": [120, 200, 150]}]
    #|}
  let svg = @yuecharts.render(json_str)
  inspect(
    svg,
    content=(
      #|<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400" viewBox="0 0 600 400">
      #|  <line x1="90" y1="320" x2="540" y2="320" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="90" y1="256.25" x2="540" y2="256.25" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="90" y1="192.5" x2="540" y2="192.5" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="90" y1="128.75" x2="540" y2="128.75" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="90" y1="65" x2="540" y2="65" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="90" y1="320" x2="540" y2="320" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <line x1="165" y1="320" x2="165" y2="324" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="165" y="334" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Mon</text>
      #|  <line x1="315" y1="320" x2="315" y2="324" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="315" y="334" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Tue</text>
      #|  <line x1="465" y1="320" x2="465" y2="324" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="465" y="334" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Wed</text>
      #|  <line x1="90" y1="65" x2="90" y2="320" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <line x1="86" y1="320" x2="90" y2="320" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="82" y="320" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">0</text>
      #|  <line x1="86" y1="256.25" x2="90" y2="256.25" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="82" y="256.25" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">50</text>
      #|  <line x1="86" y1="192.5" x2="90" y2="192.5" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="82" y="192.5" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">100</text>
      #|  <line x1="86" y1="128.75" x2="90" y2="128.75" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="82" y="128.75" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">150</text>
      #|  <line x1="86" y1="65" x2="90" y2="65" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="82" y="65" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">200</text>
      #|  <rect x="113.25" y="167" width="79.6153846153846" height="153" fill="#5070dd" stroke="none"/>
      #|  <rect x="263.25" y="65" width="79.6153846153846" height="255" fill="#5070dd" stroke="none"/>
      #|  <rect x="413.25" y="128.75" width="79.6153846153846" height="191.25" fill="#5070dd" stroke="none"/>
      #|</svg>
    ),
  )
}

///|
/// Snapshot test: full SVG output of the mixed bar+line example.
test "mixed example snapshot" {
  let json_str =
    #|{
    #|  "width": 700, "height": 450,
    #|  "xAxis": {"type": "category", "data": ["Jan","Feb","Mar","Apr","May","Jun"]},
    #|  "yAxis": [{"type": "value"}, {"type": "value"}],
    #|  "series": [
    #|    {"type": "bar", "data": [2.6, 5.9, 9.0, 26.4, 28.7, 70.7]},
    #|    {"type": "line", "yAxisIndex": 1, "data": [2.0, 2.2, 3.3, 4.5, 6.3, 10.2]}
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  inspect(
    svg,
    content=(
      #|<svg xmlns="http://www.w3.org/2000/svg" width="700" height="450" viewBox="0 0 700 450">
      #|  <line x1="105" y1="370" x2="630" y2="370" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="105" y1="293.75" x2="630" y2="293.75" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="105" y1="217.5" x2="630" y2="217.5" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="105" y1="141.25" x2="630" y2="141.25" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="105" y1="65" x2="630" y2="65" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="105" y1="370" x2="630" y2="370" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="105" y1="319.1666666666667" x2="630" y2="319.1666666666667" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="105" y1="268.33333333333337" x2="630" y2="268.33333333333337" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="105" y1="217.5" x2="630" y2="217.5" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="105" y1="166.66666666666669" x2="630" y2="166.66666666666669" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="105" y1="115.83333333333331" x2="630" y2="115.83333333333331" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="105" y1="65" x2="630" y2="65" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="105" y1="370" x2="630" y2="370" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <line x1="148.75" y1="370" x2="148.75" y2="374" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="148.75" y="384" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Jan</text>
      #|  <line x1="236.25" y1="370" x2="236.25" y2="374" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="236.25" y="384" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Feb</text>
      #|  <line x1="323.75" y1="370" x2="323.75" y2="374" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="323.75" y="384" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Mar</text>
      #|  <line x1="411.25" y1="370" x2="411.25" y2="374" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="411.25" y="384" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Apr</text>
      #|  <line x1="498.75" y1="370" x2="498.75" y2="374" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="498.75" y="384" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">May</text>
      #|  <line x1="586.25" y1="370" x2="586.25" y2="374" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="586.25" y="384" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Jun</text>
      #|  <line x1="105" y1="65" x2="105" y2="370" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <line x1="101" y1="370" x2="105" y2="370" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="97" y="370" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">0</text>
      #|  <line x1="101" y1="293.75" x2="105" y2="293.75" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="97" y="293.75" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">20</text>
      #|  <line x1="101" y1="217.5" x2="105" y2="217.5" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="97" y="217.5" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">40</text>
      #|  <line x1="101" y1="141.25" x2="105" y2="141.25" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="97" y="141.25" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">60</text>
      #|  <line x1="101" y1="65" x2="105" y2="65" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="97" y="65" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">80</text>
      #|  <line x1="105" y1="65" x2="105" y2="370" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <line x1="101" y1="370" x2="105" y2="370" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="97" y="370" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">0</text>
      #|  <line x1="101" y1="319.1666666666667" x2="105" y2="319.1666666666667" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="97" y="319.1666666666667" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">2</text>
      #|  <line x1="101" y1="268.33333333333337" x2="105" y2="268.33333333333337" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="97" y="268.33333333333337" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">4</text>
      #|  <line x1="101" y1="217.5" x2="105" y2="217.5" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="97" y="217.5" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">6</text>
      #|  <line x1="101" y1="166.66666666666669" x2="105" y2="166.66666666666669" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="97" y="166.66666666666669" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">8</text>
      #|  <line x1="101" y1="115.83333333333331" x2="105" y2="115.83333333333331" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="97" y="115.83333333333331" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">10</text>
      #|  <line x1="101" y1="65" x2="105" y2="65" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="97" y="65" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">12</text>
      #|  <rect x="118.5625" y="360.0875" width="46.442307692307686" height="9.912500000000023" fill="#5070dd" stroke="none"/>
      #|  <rect x="206.0625" y="347.50625" width="46.442307692307686" height="22.493749999999977" fill="#5070dd" stroke="none"/>
      #|  <rect x="293.5625" y="335.6875" width="46.442307692307686" height="34.3125" fill="#5070dd" stroke="none"/>
      #|  <rect x="381.0625" y="269.35" width="46.442307692307686" height="100.64999999999998" fill="#5070dd" stroke="none"/>
      #|  <rect x="468.5625" y="260.58125" width="46.442307692307686" height="109.41874999999999" fill="#5070dd" stroke="none"/>
      #|  <rect x="556.0625" y="100.45625000000001" width="46.442307692307686" height="269.54375" fill="#5070dd" stroke="none"/>
      #|  <polyline points="148.75,319.1666666666667 236.25,314.0833333333333 323.75,286.125 411.25,255.625 498.75,209.875 586.25,110.75" fill="none" stroke="#b6d634" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
      #|  <circle cx="148.75" cy="319.1666666666667" r="2" fill="#b6d634" stroke="none"/>
      #|  <circle cx="236.25" cy="314.0833333333333" r="2" fill="#b6d634" stroke="none"/>
      #|  <circle cx="323.75" cy="286.125" r="2" fill="#b6d634" stroke="none"/>
      #|  <circle cx="411.25" cy="255.625" r="2" fill="#b6d634" stroke="none"/>
      #|  <circle cx="498.75" cy="209.875" r="2" fill="#b6d634" stroke="none"/>
      #|  <circle cx="586.25" cy="110.75" r="2" fill="#b6d634" stroke="none"/>
      #|</svg>
    ),
  )
}

///|
test "pictorial bar uses palette color and circle symbols" {
  let json_str =
    #|{
    #|  "width": 640, "height": 420,
    #|  "xAxis": {"type": "category", "data": ["A", "B", "C", "D"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [
    #|    {"type": "pictorialBar", "symbol": "circle", "symbolRepeat": true, "data": [12, 20, 15, 8]}
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(palette_0))
  assert_true(svg.contains("<circle"))
}

///|
test "aria label is emitted on svg root" {
  let json_str =
    #|{
    #|  "width": 480, "height": 320,
    #|  "title": {"text": "Accessibility Demo"},
    #|  "aria": {"enabled": true, "description": "Screen reader summary"},
    #|  "xAxis": {"type": "category", "data": ["Mon","Tue"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [{"type": "bar", "name": "Visits", "data": [12, 18]}]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("role=\"img\""))
  assert_true(svg.contains("aria-label=\"Screen reader summary\""))
  assert_true(svg.contains("<desc>Screen reader summary</desc>"))
}

///|
test "pictorial bar clip and bounding data trim symbols" {
  let json_str =
    #|{
    #|  "width": 640, "height": 420,
    #|  "xAxis": {"type": "category", "data": ["A", "B", "C"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [
    #|    {
    #|      "type": "pictorialBar",
    #|      "symbol": "roundRect",
    #|      "symbolRepeat": "fixed",
    #|      "symbolBoundingData": 24,
    #|      "symbolClip": true,
    #|      "data": [12, 20, 6]
    #|    }
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("<path d="))
  assert_true(svg.contains(palette_0))
}

///|
test "aria template text is generated from defaults" {
  let json_str =
    #|{
    #|  "width": 480, "height": 320,
    #|  "title": {"text": "ARIA Template"},
    #|  "aria": {"enabled": true},
    #|  "xAxis": {"type": "category", "data": ["Mon","Tue"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [{"type": "bar", "name": "Visits", "data": [12, 18]}]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(
    svg.contains("aria-label=\"This is a chart about &quot;ARIA Template&quot;"),
  )
  assert_true(svg.contains("with type Bar chart named Visits."))
  assert_true(svg.contains("The data is as follows: 12, 18."))
}

///|
test "pictorial bar symbol offset affects output" {
  let base_json =
    #|{
    #|  "width": 420, "height": 320,
    #|  "xAxis": {"type": "category", "data": ["A"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [{
    #|    "type": "pictorialBar",
    #|    "symbol": "rect",
    #|    "data": [12]
    #|  }]
    #|}
  let offset_json =
    #|{
    #|  "width": 420, "height": 320,
    #|  "xAxis": {"type": "category", "data": ["A"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [{
    #|    "type": "pictorialBar",
    #|    "symbol": "rect",
    #|    "symbolOffset": [10, -4],
    #|    "data": [12]
    #|  }]
    #|}
  let base_svg = @yuecharts.render(base_json)
  let offset_svg = @yuecharts.render(offset_json)
  assert_true(base_svg.contains("x=\"111.825\""))
  assert_true(offset_svg.contains("x=\"121.825\""))
  assert_true(base_svg != offset_svg)
}

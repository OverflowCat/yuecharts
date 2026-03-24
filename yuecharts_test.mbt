// Blackbox tests run against the package's public API. Use `@yuecharts` to import.
// Prefer high-level behaviors over implementation details.
// Run `moon test` to execute and `moon test --update` to refresh snapshots.

// ECharts 5 default palette (first two entries used in tests).
///|
let palette_0 = "#5470c6" // series index 0

///|
let palette_1 = "#91cc75" // series index 1

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
      #|  <line x1="80" y1="340" x2="570" y2="340" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="270" x2="570" y2="270" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="200" x2="570" y2="200" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="130" x2="570" y2="130" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="60" x2="570" y2="60" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="340" x2="570" y2="340" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="161.66666666666669" y1="340" x2="161.66666666666669" y2="344" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="161.66666666666669" y="354" fill="#000000" font-size="12">Mon</text>
      #|  <line x1="325" y1="340" x2="325" y2="344" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="325" y="354" fill="#000000" font-size="12">Tue</text>
      #|  <line x1="488.33333333333337" y1="340" x2="488.33333333333337" y2="344" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="488.33333333333337" y="354" fill="#000000" font-size="12">Wed</text>
      #|  <line x1="80" y1="60" x2="80" y2="340" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="76" y1="340" x2="80" y2="340" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="344" fill="#000000" font-size="12">120</text>
      #|  <line x1="76" y1="270" x2="80" y2="270" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="274" fill="#000000" font-size="12">140</text>
      #|  <line x1="76" y1="200" x2="80" y2="200" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="204" fill="#000000" font-size="12">160</text>
      #|  <line x1="76" y1="130" x2="80" y2="130" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="134" fill="#000000" font-size="12">180</text>
      #|  <line x1="76" y1="60" x2="80" y2="60" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="64" fill="#000000" font-size="12">200</text>
      #|  <rect x="251.5" y="60" width="117.60000000000001" height="280" fill="#5470c6" stroke="none"/>
      #|  <rect x="414.83333333333337" y="235" width="117.60000000000001" height="105" fill="#5470c6" stroke="none"/>
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
      #|  <line x1="80" y1="390" x2="670" y2="390" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="307.5" x2="670" y2="307.5" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="225" x2="670" y2="225" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="142.5" x2="670" y2="142.5" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="60" x2="670" y2="60" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="390" x2="670" y2="390" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="316.6666666666667" x2="670" y2="316.6666666666667" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="243.33333333333334" x2="670" y2="243.33333333333334" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="170" x2="670" y2="170" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="96.66666666666669" x2="670" y2="96.66666666666669" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="390" x2="670" y2="390" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="129.16666666666666" y1="390" x2="129.16666666666666" y2="394" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="129.16666666666666" y="404" fill="#000000" font-size="12">Jan</text>
      #|  <line x1="227.5" y1="390" x2="227.5" y2="394" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="227.5" y="404" fill="#000000" font-size="12">Feb</text>
      #|  <line x1="325.8333333333333" y1="390" x2="325.8333333333333" y2="394" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="325.8333333333333" y="404" fill="#000000" font-size="12">Mar</text>
      #|  <line x1="424.16666666666663" y1="390" x2="424.16666666666663" y2="394" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="424.16666666666663" y="404" fill="#000000" font-size="12">Apr</text>
      #|  <line x1="522.5" y1="390" x2="522.5" y2="394" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="522.5" y="404" fill="#000000" font-size="12">May</text>
      #|  <line x1="620.8333333333333" y1="390" x2="620.8333333333333" y2="394" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="620.8333333333333" y="404" fill="#000000" font-size="12">Jun</text>
      #|  <line x1="80" y1="60" x2="80" y2="390" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="76" y1="390" x2="80" y2="390" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="394" fill="#000000" font-size="12">0</text>
      #|  <line x1="76" y1="307.5" x2="80" y2="307.5" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="311.5" fill="#000000" font-size="12">20</text>
      #|  <line x1="76" y1="225" x2="80" y2="225" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="229" fill="#000000" font-size="12">40</text>
      #|  <line x1="76" y1="142.5" x2="80" y2="142.5" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="146.5" fill="#000000" font-size="12">60</text>
      #|  <line x1="76" y1="60" x2="80" y2="60" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="64" fill="#000000" font-size="12">80</text>
      #|  <line x1="80" y1="60" x2="80" y2="390" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <line x1="76" y1="390" x2="80" y2="390" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="394" fill="#000000" font-size="12">2</text>
      #|  <line x1="76" y1="316.6666666666667" x2="80" y2="316.6666666666667" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="320.6666666666667" fill="#000000" font-size="12">4</text>
      #|  <line x1="76" y1="243.33333333333334" x2="80" y2="243.33333333333334" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="247.33333333333334" fill="#000000" font-size="12">6</text>
      #|  <line x1="76" y1="170" x2="80" y2="170" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="174" fill="#000000" font-size="12">8</text>
      #|  <line x1="76" y1="96.66666666666669" x2="80" y2="96.66666666666669" stroke="#000000" stroke-width="1" fill="none"/>
      #|  <text x="72" y="100.66666666666669" fill="#000000" font-size="12">10</text>
      #|  <rect x="84.91666666666666" y="379.275" width="70.8" height="10.725000000000023" fill="#5470c6" stroke="none"/>
      #|  <rect x="183.25" y="365.6625" width="70.8" height="24.337499999999977" fill="#5470c6" stroke="none"/>
      #|  <rect x="281.5833333333333" y="352.875" width="70.8" height="37.125" fill="#5470c6" stroke="none"/>
      #|  <rect x="379.91666666666663" y="281.1" width="70.8" height="108.89999999999998" fill="#5470c6" stroke="none"/>
      #|  <rect x="478.25" y="271.6125" width="70.8" height="118.38749999999999" fill="#5470c6" stroke="none"/>
      #|  <rect x="576.5833333333333" y="98.36250000000001" width="70.8" height="291.6375" fill="#5470c6" stroke="none"/>
      #|  <polyline points="80,390 90,382.6666666666667 100,342.3333333333333 110,298.3333333333333 120,232.33333333333334 130,89.33333333333337" fill="none" stroke="#91cc75" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
      #|  <circle cx="80" cy="390" r="2" fill="#91cc75" stroke="none"/>
      #|  <circle cx="90" cy="382.6666666666667" r="2" fill="#91cc75" stroke="none"/>
      #|  <circle cx="100" cy="342.3333333333333" r="2" fill="#91cc75" stroke="none"/>
      #|  <circle cx="110" cy="298.3333333333333" r="2" fill="#91cc75" stroke="none"/>
      #|  <circle cx="120" cy="232.33333333333334" r="2" fill="#91cc75" stroke="none"/>
      #|  <circle cx="130" cy="89.33333333333337" r="2" fill="#91cc75" stroke="none"/>
      #|</svg>
    ),
  )
}

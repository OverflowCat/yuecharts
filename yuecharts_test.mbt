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
      #|  <line x1="80" y1="340" x2="570" y2="340" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="270" x2="570" y2="270" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="200" x2="570" y2="200" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="130" x2="570" y2="130" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="60" x2="570" y2="60" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="340" x2="570" y2="340" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <line x1="161.66666666666669" y1="340" x2="161.66666666666669" y2="344" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="161.66666666666669" y="354" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Mon</text>
      #|  <line x1="325" y1="340" x2="325" y2="344" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="325" y="354" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Tue</text>
      #|  <line x1="488.33333333333337" y1="340" x2="488.33333333333337" y2="344" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="488.33333333333337" y="354" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Wed</text>
      #|  <line x1="80" y1="60" x2="80" y2="340" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <line x1="76" y1="340" x2="80" y2="340" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="340" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">0</text>
      #|  <line x1="76" y1="270" x2="80" y2="270" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="270" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">50</text>
      #|  <line x1="76" y1="200" x2="80" y2="200" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="200" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">100</text>
      #|  <line x1="76" y1="130" x2="80" y2="130" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="130" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">150</text>
      #|  <line x1="76" y1="60" x2="80" y2="60" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="60" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">200</text>
      #|  <rect x="88.16666666666669" y="172" width="117.60000000000001" height="168" fill="#5070dd" stroke="none"/>
      #|  <rect x="251.5" y="60" width="117.60000000000001" height="280" fill="#5070dd" stroke="none"/>
      #|  <rect x="414.83333333333337" y="130" width="117.60000000000001" height="210" fill="#5070dd" stroke="none"/>
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
      #|  <line x1="80" y1="390" x2="670" y2="390" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="307.5" x2="670" y2="307.5" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="225" x2="670" y2="225" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="142.5" x2="670" y2="142.5" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="60" x2="670" y2="60" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="390" x2="670" y2="390" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="335" x2="670" y2="335" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="280" x2="670" y2="280" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="225" x2="670" y2="225" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="170" x2="670" y2="170" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="115" x2="670" y2="115" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="60" x2="670" y2="60" stroke="#dbdee4" stroke-width="1" fill="none"/>
      #|  <line x1="80" y1="390" x2="670" y2="390" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <line x1="129.16666666666666" y1="390" x2="129.16666666666666" y2="394" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="129.16666666666666" y="404" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Jan</text>
      #|  <line x1="227.5" y1="390" x2="227.5" y2="394" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="227.5" y="404" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Feb</text>
      #|  <line x1="325.8333333333333" y1="390" x2="325.8333333333333" y2="394" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="325.8333333333333" y="404" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Mar</text>
      #|  <line x1="424.16666666666663" y1="390" x2="424.16666666666663" y2="394" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="424.16666666666663" y="404" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Apr</text>
      #|  <line x1="522.5" y1="390" x2="522.5" y2="394" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="522.5" y="404" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">May</text>
      #|  <line x1="620.8333333333333" y1="390" x2="620.8333333333333" y2="394" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="620.8333333333333" y="404" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging">Jun</text>
      #|  <line x1="80" y1="60" x2="80" y2="390" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <line x1="76" y1="390" x2="80" y2="390" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="390" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">0</text>
      #|  <line x1="76" y1="307.5" x2="80" y2="307.5" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="307.5" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">20</text>
      #|  <line x1="76" y1="225" x2="80" y2="225" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="225" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">40</text>
      #|  <line x1="76" y1="142.5" x2="80" y2="142.5" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="142.5" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">60</text>
      #|  <line x1="76" y1="60" x2="80" y2="60" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="60" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">80</text>
      #|  <line x1="80" y1="60" x2="80" y2="390" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <line x1="76" y1="390" x2="80" y2="390" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="390" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">0</text>
      #|  <line x1="76" y1="335" x2="80" y2="335" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="335" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">2</text>
      #|  <line x1="76" y1="280" x2="80" y2="280" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="280" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">4</text>
      #|  <line x1="76" y1="225" x2="80" y2="225" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="225" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">6</text>
      #|  <line x1="76" y1="170" x2="80" y2="170" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="170" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">8</text>
      #|  <line x1="76" y1="115" x2="80" y2="115" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="115" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">10</text>
      #|  <line x1="76" y1="60" x2="80" y2="60" stroke="#54555a" stroke-width="1" fill="none"/>
      #|  <text x="72" y="60" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle">12</text>
      #|  <rect x="84.91666666666666" y="379.275" width="70.8" height="10.725000000000023" fill="#5070dd" stroke="none"/>
      #|  <rect x="183.25" y="365.6625" width="70.8" height="24.337499999999977" fill="#5070dd" stroke="none"/>
      #|  <rect x="281.5833333333333" y="352.875" width="70.8" height="37.125" fill="#5070dd" stroke="none"/>
      #|  <rect x="379.91666666666663" y="281.1" width="70.8" height="108.89999999999998" fill="#5070dd" stroke="none"/>
      #|  <rect x="478.25" y="271.6125" width="70.8" height="118.38749999999999" fill="#5070dd" stroke="none"/>
      #|  <rect x="576.5833333333333" y="98.36250000000001" width="70.8" height="291.6375" fill="#5070dd" stroke="none"/>
      #|  <polyline points="129.16666666666666,335 227.5,329.5 325.8333333333333,299.25 424.16666666666663,266.25 522.5,216.75 620.8333333333333,109.5" fill="none" stroke="#b6d634" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
      #|  <circle cx="129.16666666666666" cy="335" r="2" fill="#b6d634" stroke="none"/>
      #|  <circle cx="227.5" cy="329.5" r="2" fill="#b6d634" stroke="none"/>
      #|  <circle cx="325.8333333333333" cy="299.25" r="2" fill="#b6d634" stroke="none"/>
      #|  <circle cx="424.16666666666663" cy="266.25" r="2" fill="#b6d634" stroke="none"/>
      #|  <circle cx="522.5" cy="216.75" r="2" fill="#b6d634" stroke="none"/>
      #|  <circle cx="620.8333333333333" cy="109.5" r="2" fill="#b6d634" stroke="none"/>
      #|</svg>
    ),
  )
}

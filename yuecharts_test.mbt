// Blackbox tests run against the package's public API. Use `@yuecharts` to import.
// Prefer high-level behaviors over implementation details.
// Run `moon test` to execute and `moon test --update` to refresh snapshots.

// ECharts 6 default palette (first two entries used in tests).

///|
let palette_0 = "#5070dd" // series index 0

///|
let palette_1 = "#b6d634" // series index 1

///|
fn count_substring(haystack : String, needle : String) -> Int {
  haystack.split(needle).map(StringView::to_string).collect().length() - 1
}

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
/// ThemeRiver should render stream area paths and stream labels.
test "themeRiver renders paths and labels" {
  let json_str =
    #|{
    #|  "width": 600, "height": 400,
    #|  "singleAxis": {"type": "time", "left": "8%", "right": "8%", "top": "12%", "bottom": "18%", "position": "bottom"},
    #|  "series": [{
    #|    "type": "themeRiver",
    #|    "coordinateSystem": "singleAxis",
    #|    "data": [
    #|      ["2015/11/08", 10, "DQ"], ["2015/11/09", 15, "DQ"], ["2015/11/10", 20, "DQ"],
    #|      ["2015/11/08", 20, "TY"], ["2015/11/09", 18, "TY"], ["2015/11/10", 16, "TY"]
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(palette_0))
  assert_true(svg.contains(palette_1))
  assert_true(svg.contains(">DQ</text>"))
  assert_true(svg.contains(">TY</text>"))
  assert_true(count_substring(svg, "<path") >= 2)
}

///|
/// ThemeRiver boundaryGap should accept percent and pixel forms.
test "themeRiver boundaryGap percent and px" {
  let json_str =
    #|{
    #|  "width": 600, "height": 400,
    #|  "singleAxis": {"type": "time", "left": "8%", "right": "8%", "top": "12%", "bottom": "18%", "position": "bottom"},
    #|  "series": [{
    #|    "type": "themeRiver",
    #|    "coordinateSystem": "singleAxis",
    #|    "boundaryGap": ["20%", 12],
    #|    "data": [
    #|      ["2015/11/08", 10, "A"], ["2015/11/09", 14, "A"], ["2015/11/10", 18, "A"],
    #|      ["2015/11/08", 8, "B"], ["2015/11/09", 6, "B"], ["2015/11/10", 4, "B"]
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">A</text>"))
  assert_true(svg.contains(">B</text>"))
  assert_true(count_substring(svg, "<path") >= 2)
}

///|
/// ThemeRiver singleAxis time ticks should use formatted source labels, not raw day-count numbers.
test "themeRiver singleAxis formats time ticks and draws split lines" {
  let json_str =
    #|{
    #|  "width": 600,
    #|  "height": 400,
    #|  "singleAxis": {"type": "time", "left": "8%", "right": "8%", "top": "12%", "bottom": "18%", "position": "bottom"},
    #|  "series": [{
    #|    "type": "themeRiver",
    #|    "data": [
    #|      ["2015/11/08", 10, "A"], ["2015/11/09", 14, "A"], ["2015/11/10", 18, "A"],
    #|      ["2015/11/08", 8, "B"], ["2015/11/09", 6, "B"], ["2015/11/10", 4, "B"]
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">8</text>"))
  assert_true(svg.contains(">9</text>"))
  assert_true(svg.contains(">10</text>"))
  assert_true(!svg.contains(">16747</text>"))
  assert_true(svg.contains("stroke-dasharray=\"4,2\""))
}

///|
/// ThemeRiver should fill missing (time, name) pairs with zero values.
/// Corresponds to ThemeRiverSeries.fixData() behavior.
test "themeRiver fixData fills missing time points" {
  let json_str =
    #|{
    #|  "width": 600, "height": 400,
    #|  "singleAxis": {"type": "time", "left": "8%", "right": "8%", "top": "12%", "bottom": "18%", "position": "bottom"},
    #|  "series": [{
    #|    "type": "themeRiver",
    #|    "data": [
    #|      ["2015/11/08", 10, "A"], ["2015/11/09", 14, "A"], ["2015/11/10", 18, "A"],
    #|      ["2015/11/09", 6, "B"]
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">A</text>"))
  assert_true(svg.contains(">B</text>"))
  assert_true(count_substring(svg, "<path") >= 2)
  // With >=3 points after fillData, smooth path includes cubic Bezier commands.
  assert_true(svg.contains(" C "))
}

///|
/// ThemeRiver should ignore items without name.
/// Corresponds to `filter(option.data, dataItem => dataItem[2] !== undefined)`.
test "themeRiver ignores unnamed items" {
  let json_str =
    #|{
    #|  "width": 600, "height": 400,
    #|  "singleAxis": {"type": "time"},
    #|  "series": [{
    #|    "type": "themeRiver",
    #|    "data": [
    #|      ["2015/11/08", 10, "Named"],
    #|      ["2015/11/09", 12]
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Named</text>"))
  assert_true(!svg.contains(">default</text>"))
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
test "pictorial bar repeat emits multiple symbols" {
  let json_str =
    #|{
    #|  "width": 640, "height": 420,
    #|  "xAxis": {"type": "category", "data": ["A"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [
    #|    {
    #|      "type": "pictorialBar",
    #|      "symbol": "circle",
    #|      "symbolRepeat": true,
    #|      "symbolSize": ["40%", "20%"],
    #|      "data": [12]
    #|    }
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  let count = count_substring(svg, "<circle")
  assert_true(count > 1)
}

///|
test "pictorial bar path symbol uses normalized path transform" {
  let json_str =
    #|{
    #|  "xAxis": {"type": "category", "data": ["A"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [{
    #|    "type": "pictorialBar",
    #|    "symbol": "path://M0,10 L10,10 C5.5,10 5.5,5 5,0 C4.5,5 4.5,10 0,10 z",
    #|    "barCategoryGap": "-130%",
    #|    "itemStyle": {"opacity": 0.5},
    #|    "data": [12]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("matrix(40,0,0,40,-200,-200)"))
  assert_true(svg.contains("opacity=\"0.5\""))
}

///|
test "pictorial bar item symbol overrides series symbol" {
  let json_str =
    #|{
    #|  "xAxis": {"type": "category", "data": ["A"]},
    #|  "yAxis": {"type": "value"},
    #|  "series": [{
    #|    "type": "pictorialBar",
    #|    "symbol": "circle",
    #|    "data": [{
    #|      "value": 12,
    #|      "symbol": "path://M0,10 L10,10 C5.5,10 5.5,5 5,0 C4.5,5 4.5,10 0,10 z"
    #|    }]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("matrix(40,0,0,40,-200,-200)"))
  assert_true(!svg.contains("<circle"))
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

///|
test "pie legend selection and negative filter affect rendered slices" {
  let json_str =
    #|{
    #|  "width": 800,
    #|  "height": 600,
    #|  "legend": {"selected": {"Bananas": false}},
    #|  "series": [{
    #|    "type": "pie",
    #|    "data": [
    #|      {"value": 40, "name": "Apples"},
    #|      {"value": 20, "name": "Bananas"},
    #|      {"value": -5, "name": "Neg"}
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_eq(count_substring(svg, "<path d=\"M 400 300 L"), 1)
  assert_true(svg.contains("fill=\"#d7dbe3\""))
  assert_true(svg.contains(">Bananas</text>"))
  assert_true(!svg.contains("#b6d634"))
}

///|
test "geo map and scatter render with visual map" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1,
    #|    "label": { "show": true, "color": "#555555" }
    #|  },
    #|  "visualMap": [
    #|    {
    #|      "seriesIndex": 0,
    #|      "min": 0,
    #|      "max": 100,
    #|      "dimension": 2,
    #|      "inRange": { "symbolSize": [5, 30] }
    #|    },
    #|    {
    #|      "seriesIndex": 1,
    #|      "min": 0,
    #|      "max": 100,
    #|      "dimension": 0,
    #|      "inRange": { "color": ["#deebf7", "#3182bd"] }
    #|    }
    #|  ],
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Alpha", "cp": [5, 5] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]] }
    #|        },
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Beta", "cp": [15, 5] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[10,0],[20,0],[20,10],[10,10],[10,0]]] }
    #|        }
    #|      ]
    #|    }
    #|  }],
    #|  "series": [
    #|    {
    #|      "type": "scatter",
    #|      "coordinateSystem": "geo",
    #|      "data": [[2, 2, 0], [18, 8, 100]]
    #|    },
    #|    {
    #|      "type": "map",
    #|      "geoIndex": 0,
    #|      "map": "",
    #|      "data": [{ "name": "Alpha", "value": 0 }, { "name": "Beta", "value": 100 }]
    #|    }
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("<path d=\"M "))
  assert_true(svg.contains(">Alpha</text>"))
  assert_true(svg.contains(">Beta</text>"))
  assert_true(svg.contains("fill=\"#deebf7\""))
  assert_true(svg.contains("fill=\"#3182bd\""))
  assert_true(svg.contains("r=\"2.5\""))
  assert_true(svg.contains("r=\"15\""))
}

///|
test "effect scatter supports geo coordinate system" {
  let json_str =
    #|{
    #|  "width": 220,
    #|  "height": 160,
    #|  "geo": { "map": "demo", "aspectScale": 1 },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Only", "cp": [5, 5] },
    #|        "geometry": { "type": "Polygon", "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]] }
    #|      }]
    #|    }
    #|  }],
    #|  "series": [{
    #|    "type": "effectScatter",
    #|    "coordinateSystem": "geo",
    #|    "symbolSize": 12,
    #|    "data": [[5, 5, 1]]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("opacity=\"0.33333333333333337\""))
  assert_true(svg.contains("opacity=\"0.6666666666666667\""))
}

///|
test "lines series supports geo named regions and polyline" {
  let json_str =
    #|{
    #|  "width": 320,
    #|  "height": 220,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1,
    #|    "label": { "show": true, "color": "#555555" }
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Alpha", "cp": [3, 5] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[0,0],[6,0],[6,10],[0,10],[0,0]]] }
    #|        },
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Beta", "cp": [10, 7] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[6,2],[14,2],[14,12],[6,12],[6,2]]] }
    #|        },
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Gamma", "cp": [17, 5] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[14,0],[20,0],[20,10],[14,10],[14,0]]] }
    #|        }
    #|      ]
    #|    }
    #|  }],
    #|  "series": [
    #|    {
    #|      "type": "map",
    #|      "geoIndex": 0,
    #|      "data": [
    #|        { "name": "Alpha", "value": 1 },
    #|        { "name": "Beta", "value": 2 },
    #|        { "name": "Gamma", "value": 3 }
    #|      ]
    #|    },
    #|    {
    #|      "type": "lines",
    #|      "coordinateSystem": "geo",
    #|      "lineStyle": { "width": 2, "curveness": 0.25 },
    #|      "data": [{ "fromName": "Alpha", "toName": "Gamma" }]
    #|    },
    #|    {
    #|      "type": "lines",
    #|      "coordinateSystem": "geo",
    #|      "polyline": true,
    #|      "lineStyle": { "width": 1.5, "opacity": 0.8, "color": "#ff6b6b" },
    #|      "data": [{ "coords": [[2,2],[10,11],[18,2]] }]
    #|    }
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Alpha</text>"))
  assert_true(svg.contains(">Gamma</text>"))
  assert_true(svg.contains("<path d=\"M "))
  assert_true(svg.contains(" Q "))
  assert_true(svg.contains("stroke-width=\"2\""))
  assert_true(svg.contains("<polyline points=\""))
  assert_true(svg.contains("stroke=\"#ff6b6b\""))
  assert_true(svg.contains("opacity=\"0.8\""))
}

///|
test "lines cartesian series clips and honors item lineStyle" {
  let json_str =
    #|{
    #|  "width": 360,
    #|  "height": 240,
    #|  "xAxis": { "type": "value", "min": 0, "max": 10 },
    #|  "yAxis": { "type": "value", "min": 0, "max": 10 },
    #|  "series": [
    #|    {
    #|      "type": "lines",
    #|      "coordinateSystem": "cartesian2d",
    #|      "clip": true,
    #|      "lineStyle": { "color": "#5070dd", "width": 2, "opacity": 0.35 },
    #|      "data": [
    #|        {
    #|          "coords": [[-2, 2], [5, 5]],
    #|          "lineStyle": {
    #|            "color": "#dd4444",
    #|            "width": 3,
    #|            "opacity": 0.9,
    #|            "curveness": 0.25
    #|          }
    #|        },
    #|        { "coords": [[1, 1], [9, 8]] }
    #|      ]
    #|    },
    #|    {
    #|      "type": "lines",
    #|      "coordinateSystem": "cartesian2d",
    #|      "clip": false,
    #|      "polyline": true,
    #|      "lineStyle": { "color": "#73c0de", "width": 1.5, "opacity": 0.8 },
    #|      "data": [{ "coords": [[1, 8], [4, 9], [8, 7], [12, 6]] }]
    #|    }
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_eq(count_substring(svg, "<clipPath id=\"clip-"), 1)
  assert_true(svg.contains("stroke=\"#dd4444\""))
  assert_true(svg.contains("stroke-width=\"3\""))
  assert_true(svg.contains("opacity=\"0.9\""))
  assert_true(svg.contains(" Q "))
  assert_true(svg.contains("stroke=\"#5070dd\""))
  assert_true(svg.contains("opacity=\"0.35\""))
  assert_true(svg.contains("stroke=\"#73c0de\""))
}

///|
test "lines polar series renders curved and polyline paths" {
  let json_str =
    #|{
    #|  "width": 320,
    #|  "height": 240,
    #|  "polar": {},
    #|  "angleAxis": { "type": "value", "min": 0, "max": 360, "startAngle": 90 },
    #|  "radiusAxis": { "type": "value", "min": 0, "max": 100 },
    #|  "series": [
    #|    {
    #|      "type": "lines",
    #|      "coordinateSystem": "polar",
    #|      "clip": false,
    #|      "lineStyle": { "width": 2, "opacity": 0.5 },
    #|      "data": [
    #|        {
    #|          "coords": [[20, 20], [75, 120]],
    #|          "lineStyle": {
    #|            "color": "#dd4444",
    #|            "width": 3,
    #|            "opacity": 0.85,
    #|            "curveness": 0.2
    #|          }
    #|        }
    #|      ]
    #|    },
    #|    {
    #|      "type": "lines",
    #|      "coordinateSystem": "polar",
    #|      "clip": false,
    #|      "polyline": true,
    #|      "lineStyle": { "color": "#5070dd", "width": 1.5, "opacity": 0.6 },
    #|      "data": [{ "coords": [[10, 200], [25, 220], [80, 300]] }]
    #|    }
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("stroke=\"#dd4444\""))
  assert_true(svg.contains("stroke-width=\"3\""))
  assert_true(svg.contains("opacity=\"0.85\""))
  assert_true(svg.contains(" Q "))
  assert_true(svg.contains("<polyline points=\""))
  assert_true(svg.contains("stroke=\"#5070dd\""))
  assert_true(svg.contains("opacity=\"0.6\""))
}

///|
test "lines series renders endpoint symbols with item overrides" {
  let json_str =
    #|{
    #|  "width": 320,
    #|  "height": 220,
    #|  "xAxis": { "type": "value", "min": 0, "max": 10 },
    #|  "yAxis": { "type": "value", "min": 0, "max": 10 },
    #|  "series": [{
    #|    "type": "lines",
    #|    "coordinateSystem": "cartesian2d",
    #|    "symbol": ["circle", "arrow"],
    #|    "symbolSize": [10, 16],
    #|    "lineStyle": { "color": "#5070dd", "width": 2, "opacity": 0.6 },
    #|    "data": [
    #|      { "coords": [[1, 1], [9, 7]] },
    #|      {
    #|        "coords": [[2, 8], [8, 2]],
    #|        "symbol": ["diamond", "rect"],
    #|        "symbolSize": [12, 18],
    #|        "lineStyle": { "color": "#dd4444", "curveness": 0.2, "opacity": 0.9 }
    #|      }
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("stroke=\"#5070dd\""))
  assert_true(svg.contains("stroke=\"#dd4444\""))
  assert_true(svg.contains("<circle cx=\"0\" cy=\"0\" r=\"5\""))
  assert_true(svg.contains("fill=\"#5070dd\""))
  assert_true(count_substring(svg, "fill=\"#dd4444\"") >= 2)
  assert_true(count_substring(svg, "transform=\"matrix(") >= 4)
}

///|
test "lines polar series uses sector clip path when clip is true" {
  let json_str =
    #|{
    #|  "width": 320,
    #|  "height": 240,
    #|  "polar": {},
    #|  "angleAxis": { "type": "value", "min": 0, "max": 180, "startAngle": 90 },
    #|  "radiusAxis": { "type": "value", "min": 0, "max": 100 },
    #|  "series": [{
    #|    "type": "lines",
    #|    "coordinateSystem": "polar",
    #|    "clip": true,
    #|    "symbol": ["circle", "arrow"],
    #|    "symbolSize": [8, 14],
    #|    "lineStyle": { "color": "#5070dd", "width": 2, "opacity": 0.6 },
    #|    "data": [
    #|      { "coords": [[20, 20], [110, 140]] },
    #|      {
    #|        "coords": [[15, 160], [45, 200], [90, 300]],
    #|        "symbol": ["diamond", "rect"],
    #|        "symbolSize": [10, 16],
    #|        "lineStyle": { "color": "#dd4444", "opacity": 0.9 }
    #|      }
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_eq(count_substring(svg, "<clipPath id=\"clip-"), 1)
  assert_true(svg.contains("<clipPath id=\"clip-0\">"))
  assert_true(svg.contains("<path d=\"M "))
  assert_true(svg.contains("clip-path=\"url(#clip-0)\""))
  assert_true(svg.contains("A 96 96"))
  assert_true(svg.contains("stroke=\"#5070dd\""))
}

///|
test "geo nameMap and regions override labels and style" {
  let json_str =
    #|{
    #|  "width": 280,
    #|  "height": 180,
    #|  "geo": {
    #|    "map": "demo",
    #|    "nameMap": { "rawA": "Alpha", "rawB": "Bravo" },
    #|    "label": { "show": true, "color": "#666666" },
    #|    "itemStyle": { "areaColor": "#f0f0f0", "borderColor": "#999999", "borderWidth": 1 },
    #|    "regions": [
    #|      {
    #|        "name": "Alpha",
    #|        "label": { "show": true, "color": "#aa0000" },
    #|        "itemStyle": { "areaColor": "#ffd166", "borderColor": "#003366", "borderWidth": 3 }
    #|      },
    #|      {
    #|        "name": "Bravo",
    #|        "label": { "show": false }
    #|      }
    #|    ]
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "rawA", "cp": [5, 5] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]] }
    #|        },
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "rawB", "cp": [15, 5] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[10,0],[20,0],[20,10],[10,10],[10,0]]] }
    #|        }
    #|      ]
    #|    }
    #|  }],
    #|  "series": [{
    #|    "type": "map",
    #|    "geoIndex": 0,
    #|    "data": [{ "name": "Alpha", "value": 1 }, { "name": "Bravo", "value": 2 }]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Alpha</text>"))
  assert_true(!svg.contains(">Bravo</text>"))
  assert_true(svg.contains("fill=\"#ffd166\""))
  assert_true(svg.contains("stroke=\"#003366\""))
  assert_true(svg.contains("stroke-width=\"3\""))
  assert_true(svg.contains("fill=\"#f0f0f0\""))
  assert_true(svg.contains("stroke=\"#999999\""))
}

///|
test "geo specialAreas reposition region before viewport fit" {
  let json_str =
    #|{
    #|  "width": 320,
    #|  "height": 200,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1,
    #|    "label": { "show": true, "color": "#444444" }
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Main", "cp": [5, 5] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]] }
    #|        },
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Inset", "cp": [25, 5] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[20,0],[30,0],[30,10],[20,10],[20,0]]] }
    #|        }
    #|      ]
    #|    },
    #|    "specialAreas": {
    #|      "Inset": { "left": 4, "top": 12, "width": 4, "height": 4 }
    #|    }
    #|  }],
    #|  "series": [{
    #|    "type": "map",
    #|    "data": [{ "name": "Main", "value": 1 }, { "name": "Inset", "value": 2 }]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Main</text>"))
  assert_true(svg.contains(">Inset</text>"))
  assert_true(svg.contains("M 110 180 L 210 180 L 210 80"))
  assert_true(svg.contains("M 150 60 L 190 60 L 190 20"))
}

///|
test "geo compressed geojson renders map region" {
  let json_str =
    #|{
    #|  "width": 220,
    #|  "height": 160,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1,
    #|    "label": { "show": true, "color": "#444444" }
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "UTF8Encoding": true,
    #|      "UTF8Scale": 1,
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Compressed", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "encodeOffsets": [[0, 0]],
    #|          "coordinates": ["@@T@@TS@@S"]
    #|        }
    #|      }]
    #|    }
    #|  }],
    #|  "series": [{
    #|    "type": "map",
    #|    "map": "demo",
    #|    "data": [{ "name": "Compressed", "value": 1 }]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("<path d=\"M "))
  assert_true(svg.contains(">Compressed</text>"))
}

///|
test "geo multiline region contributes label but not polygon fill" {
  let json_str =
    #|{
    #|  "width": 220,
    #|  "height": 160,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1,
    #|    "label": { "show": true, "color": "#444444" }
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Route" },
    #|        "geometry": {
    #|          "type": "MultiLineString",
    #|          "coordinates": [
    #|            [[0, 0], [10, 0], [10, 5]],
    #|            [[2, 8], [8, 12]]
    #|          ]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Route</text>"))
  assert_true(!svg.contains("<polygon"))
}

///|
test "geo polygon interiors render as compound path" {
  let json_str =
    #|{
    #|  "width": 220,
    #|  "height": 160,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1,
    #|    "label": { "show": true, "color": "#444444" }
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Donut", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [
    #|            [[0,0],[10,0],[10,10],[0,10],[0,0]],
    #|            [[3,3],[3,7],[7,7],[7,3],[3,3]]
    #|          ]
    #|        }
    #|      }]
    #|    }
    #|  }],
    #|  "series": [{
    #|    "type": "map",
    #|    "map": "demo",
    #|    "data": [{ "name": "Donut", "value": 1 }]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Donut</text>"))
  assert_true(svg.contains("<path d=\"M "))
  assert_true(svg.contains(" ZM "))
  assert_true(!svg.contains("<polygon"))
}

///|
test "map data statistic aggregates same-geo series and draws once" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1,
    #|    "label": { "show": true, "color": "#444444" }
    #|  },
    #|  "visualMap": [{
    #|    "seriesIndex": 0,
    #|    "min": 0,
    #|    "max": 100,
    #|    "dimension": 0,
    #|    "inRange": { "color": ["#deebf7", "#3182bd"] }
    #|  }],
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Alpha", "cp": [5, 5] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]] }
    #|        },
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Beta", "cp": [15, 5] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[10,0],[20,0],[20,10],[10,10],[10,0]]] }
    #|        }
    #|      ]
    #|    }
    #|  }],
    #|  "series": [
    #|    {
    #|      "type": "map",
    #|      "mapValueCalculation": "max",
    #|      "data": [
    #|        { "name": "Alpha", "value": 0 },
    #|        { "name": "Beta", "value": 0 }
    #|      ]
    #|    },
    #|    {
    #|      "type": "map",
    #|      "data": [
    #|        { "name": "Alpha", "value": 100 }
    #|      ]
    #|    }
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  // 2 geo outlines (fill=none) + 2 map fill paths.
  assert_eq(count_substring(svg, "<path d=\"M "), 4)
  assert_eq(count_substring(svg, "fill=\"none\""), 2)
  assert_eq(count_substring(svg, "fill=\"#3182bd\""), 1)
  assert_eq(count_substring(svg, "fill=\"#deebf7\""), 1)
  assert_true(svg.contains("fill=\"#3182bd\""))
  assert_true(svg.contains("fill=\"#deebf7\""))
}

///|
test "map series renders without geo component when map is specified on series" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "visualMap": {
    #|    "seriesIndex": 0,
    #|    "min": 0,
    #|    "max": 100,
    #|    "dimension": 0,
    #|    "inRange": { "color": ["#deebf7", "#3182bd"] }
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Alpha", "cp": [5, 5] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]] }
    #|        },
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Beta", "cp": [15, 5] },
    #|          "geometry": { "type": "Polygon", "coordinates": [[[10,0],[20,0],[20,10],[10,10],[10,0]]] }
    #|        }
    #|      ]
    #|    }
    #|  }],
    #|  "series": [{
    #|    "type": "map",
    #|    "map": "demo",
    #|    "data": [
    #|      { "name": "Alpha", "value": 0 },
    #|      { "name": "Beta", "value": 100 }
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_eq(count_substring(svg, "<path d=\"M "), 2)
  assert_true(svg.contains("fill=\"#deebf7\""))
  assert_true(svg.contains("fill=\"#3182bd\""))
}

///|
test "parallel coordinates render axes and polylines" {
  let json_str =
    #|{
    #|  "width": 420,
    #|  "height": 280,
    #|  "parallel": { "left": 50, "right": 50, "top": 30, "bottom": 30 },
    #|  "parallelAxis": [
    #|    { "dim": 0, "name": "A", "type": "value" },
    #|    { "dim": 1, "name": "B", "type": "value" },
    #|    { "dim": 2, "name": "C", "type": "value" }
    #|  ],
    #|  "series": [{
    #|    "type": "parallel",
    #|    "data": [[1, 2, 3], [2, 3, 1]]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(
    svg.contains(
      "<text x=\"50\" y=\"12\" fill=\"#54555a\" font-size=\"12\" text-anchor=\"middle\" dominant-baseline=\"hanging\">A</text>",
    ),
  )
  assert_true(
    svg.contains(
      "<text x=\"210\" y=\"12\" fill=\"#54555a\" font-size=\"12\" text-anchor=\"middle\" dominant-baseline=\"hanging\">B</text>",
    ),
  )
  assert_true(
    svg.contains(
      "<text x=\"370\" y=\"12\" fill=\"#54555a\" font-size=\"12\" text-anchor=\"middle\" dominant-baseline=\"hanging\">C</text>",
    ),
  )
  assert_true(svg.contains("stroke=\"#5070dd\""))
  assert_true(count_substring(svg, "<polyline points=") >= 2)
}

///|
test "parallel skips missing values and clips series group" {
  let json_str =
    #|{
    #|  "width": 420,
    #|  "height": 280,
    #|  "parallel": { "left": 50, "right": 50, "top": 30, "bottom": 30 },
    #|  "parallelAxis": [
    #|    { "dim": 0, "name": "A", "type": "value" },
    #|    { "dim": 1, "name": "B", "type": "value" },
    #|    { "dim": 2, "name": "C", "type": "value" }
    #|  ],
    #|  "series": [{
    #|    "type": "parallel",
    #|    "data": [[1, 2, 3], [2, 3], null]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_eq(count_substring(svg, "<clipPath id=\"clip-"), 1)
  assert_eq(count_substring(svg, "<polyline points="), 2)
  assert_true(svg.contains("<polyline points=\"50,30 210,30\""))
}

///|
test "matrix heatmap renders headers and colored body cells" {
  let json_str =
    #|{
    #|  "width": 520,
    #|  "height": 320,
    #|  "matrix": {
    #|    "left": 70,
    #|    "top": 50,
    #|    "right": 40,
    #|    "bottom": 30,
    #|    "x": {
    #|      "levelSize": 28,
    #|      "data": [
    #|        { "value": "North", "children": ["Q1", "Q2"] },
    #|        { "value": "South", "children": ["Q3", "Q4"] }
    #|      ]
    #|    },
    #|    "y": {
    #|      "levelSize": 56,
    #|      "data": [
    #|        { "value": "Team A", "children": ["Alice", "Bob"] },
    #|        { "value": "Team B", "children": ["Carol", "Dave"] }
    #|      ]
    #|    }
    #|  },
    #|  "visualMap": { "min": 0, "max": 10 },
    #|  "series": [{
    #|    "type": "heatmap",
    #|    "coordinateSystem": "matrix",
    #|    "data": [[0,0,1],[1,0,4],[2,1,8],[3,3,10]]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">North</text>"))
  assert_true(svg.contains(">South</text>"))
  assert_true(svg.contains(">Alice</text>"))
  assert_true(svg.contains(">Dave</text>"))
  assert_true(svg.contains("#5070dd"))
  assert_true(svg.contains("#c6d1f4"))
}

///|
test "matrix body coordClamp mergeCells and corner locators render once" {
  let json_str =
    #|{
    #|  "width": 420,
    #|  "height": 260,
    #|  "matrix": {
    #|    "left": 60,
    #|    "top": 40,
    #|    "right": 30,
    #|    "bottom": 24,
    #|    "x": { "levelSize": 28, "data": ["Mon", "Tue", "Wed"] },
    #|    "y": { "levelSize": 58, "data": ["AM", "PM", "Night"] },
    #|    "corner": {
    #|      "data": [{ "coord": [-1, -1], "value": "Time" }]
    #|    },
    #|    "body": {
    #|      "itemStyle": {
    #|        "color": "#ffffff",
    #|        "borderColor": "#d7dbe3",
    #|        "borderWidth": 1
    #|      },
    #|      "data": [{
    #|        "coord": [null, 1],
    #|        "coordClamp": true,
    #|        "mergeCells": true,
    #|        "value": "Break",
    #|        "itemStyle": {
    #|          "color": "#f3f5f9",
    #|          "borderColor": "#aeb7c5",
    #|          "borderWidth": 1
    #|        }
    #|      }]
    #|    }
    #|  }
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Time</text>"))
  assert_true(svg.contains(">Break</text>"))
  assert_eq(count_substring(svg, ">Break</text>"), 1)
}

///|
test "matrix heatmap accepts string coords in data value arrays" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 220,
    #|  "matrix": {
    #|    "left": 20,
    #|    "top": 20,
    #|    "width": 160,
    #|    "height": 140,
    #|    "x": { "data": ["A", "B"] },
    #|    "y": { "data": ["C", "D"] },
    #|    "body": {
    #|      "itemStyle": {
    #|        "color": "#ffffff",
    #|        "borderColor": "#d7dbe3",
    #|        "borderWidth": 1
    #|      }
    #|    }
    #|  },
    #|  "visualMap": { "min": 0, "max": 10 },
    #|  "series": [{
    #|    "type": "heatmap",
    #|    "coordinateSystem": "matrix",
    #|    "data": [
    #|      { "value": ["A", "C", 2] },
    #|      { "value": ["B", "D", 8] }
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(
    svg.contains(
      "<rect x=\"73.33333333333334\" y=\"66.66666666666666\" width=\"53.333333333333336\" height=\"46.666666666666664\"",
    ),
  )
  assert_true(
    svg.contains(
      "<rect x=\"126.66666666666669\" y=\"113.33333333333331\" width=\"53.333333333333336\" height=\"46.666666666666664\"",
    ),
  )
}

///|
test "standalone map emits hover css from svg renderer" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Alpha", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }],
    #|  "series": [{
    #|    "type": "map",
    #|    "map": "demo",
    #|    "data": [{ "name": "Alpha", "value": 1 }]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("<style><![CDATA["))
  assert_true(svg.contains(":hover {"))
  assert_true(svg.contains("cursor:pointer;"))
  assert_true(svg.contains("class=\"zr-cls-0\""))
}

///|
test "map data item emphasis style and silent feed svg hover css" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Alpha", "cp": [5, 5] },
    #|          "geometry": {
    #|            "type": "Polygon",
    #|            "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|          }
    #|        },
    #|        {
    #|          "type": "Feature",
    #|          "properties": { "name": "Beta", "cp": [15, 5] },
    #|          "geometry": {
    #|            "type": "Polygon",
    #|            "coordinates": [[[10,0],[20,0],[20,10],[10,10],[10,0]]]
    #|          }
    #|        }
    #|      ]
    #|    }
    #|  }],
    #|  "series": [{
    #|    "type": "map",
    #|    "map": "demo",
    #|    "data": [
    #|      {
    #|        "name": "Alpha",
    #|        "value": 1,
    #|        "emphasis": { "itemStyle": { "areaColor": "#ff0000" } }
    #|      },
    #|      {
    #|        "name": "Beta",
    #|        "value": 2,
    #|        "silent": true
    #|      }
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("fill:#ff0000;"))
  assert_true(svg.contains("pointer-events:none;"))
}

///|
test "geo top-level emphasis style feeds svg hover css" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Alpha", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }],
    #|  "geo": {
    #|    "map": "demo",
    #|    "emphasis": {
    #|      "itemStyle": { "borderColor": "#00ff00", "borderWidth": 3 }
    #|    },
    #|    "label": { "show": true }
    #|  },
    #|  "series": []
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("stroke:#00ff00;"))
  assert_true(svg.contains("stroke-width:3;"))
}

///|
test "geo top-level silent feeds svg hover css" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Alpha", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }],
    #|  "geo": {
    #|    "map": "demo",
    #|    "silent": true,
    #|    "label": { "show": true }
    #|  },
    #|  "series": []
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("pointer-events:none;"))
}

///|
test "map label emphasis color feeds text hover css" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Alpha", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }],
    #|  "series": [{
    #|    "type": "map",
    #|    "map": "demo",
    #|    "label": { "show": true, "color": "#111111" },
    #|    "emphasis": { "label": { "color": "#ff00ff" } },
    #|    "data": [{ "name": "Alpha", "value": 1 }]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Alpha</text>"))
  assert_true(svg.contains("fill:#ff00ff;"))
}

///|
test "geo label emphasis color feeds text hover css" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Alpha", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }],
    #|  "geo": {
    #|    "map": "demo",
    #|    "label": { "show": true, "color": "#111111" },
    #|    "emphasis": { "label": { "color": "#00ffff" } }
    #|  },
    #|  "series": []
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Alpha</text>"))
  assert_true(svg.contains("fill:#00ffff;"))
}

///|
test "map selected item applies current select style in static svg" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Alpha", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }],
    #|  "series": [{
    #|    "type": "map",
    #|    "map": "demo",
    #|    "label": { "show": true, "color": "#111111" },
    #|    "select": {
    #|      "itemStyle": { "areaColor": "#ff8800" },
    #|      "label": { "color": "#0088ff" }
    #|    },
    #|    "data": [{
    #|      "name": "Alpha",
    #|      "value": 1,
    #|      "selected": true
    #|    }]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("fill=\"#ff8800\""))
  assert_true(svg.contains("<text x=\"130\" y=\"90\" fill=\"#0088ff\""))
}

///|
test "geo selected region applies current select style in static svg" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Alpha", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }],
    #|  "geo": {
    #|    "map": "demo",
    #|    "label": { "show": true, "color": "#111111" },
    #|    "select": {
    #|      "itemStyle": { "borderColor": "#ff0000", "borderWidth": 2 },
    #|      "label": { "color": "#00aa00" }
    #|    },
    #|    "regions": [{
    #|      "name": "Alpha",
    #|      "selected": true
    #|    }]
    #|  },
    #|  "series": []
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("stroke=\"#ff0000\""))
  assert_true(svg.contains("stroke-width=\"2\""))
  assert_true(svg.contains("<text x=\"130\" y=\"90\" fill=\"#00aa00\""))
}

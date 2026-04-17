// Blackbox tests run against the package's public API. Use `@yuecharts` to import.
// Prefer high-level behaviors over implementation details.
// Run `moon test` to execute and `moon test --update` to refresh snapshots.

// ECharts 6 default palette (first two entries used in tests).

///|
let palette_0 = "#5070dd" // series index 0

///|
let palette_1 = "#b6d634" // series index 1

///|
test "version reports current release" {
  assert_eq(@yuecharts.version(), "0.4.15")
}

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
/// xAxis/yAxis with scale=true should keep data extent and use nice interval expansion.
/// Equivalent behavior in ECharts effectScatter example: x=[140,190], y=[40,110].
test "effect scatter value axes respect scale true nice extent" {
  let json_str =
    #|{
    #|  "width": 600,
    #|  "height": 400,
    #|  "xAxis": {"type": "value", "scale": true},
    #|  "yAxis": {"type": "value", "scale": true},
    #|  "series": [
    #|    {
    #|      "type": "effectScatter",
    #|      "symbolSize": 20,
    #|      "data": [[172.7, 105.2], [153.4, 42.0]]
    #|    },
    #|    {
    #|      "type": "scatter",
    #|      "data": [[147.2, 49.8], [182.9, 81.8], [165.1, 104.1], [176.5, 87.8], [160.0, 43.2]]
    #|    }
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">140</text>"))
  assert_true(svg.contains(">190</text>"))
  assert_true(svg.contains(">40</text>"))
  assert_true(svg.contains(">110</text>"))
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
/// Tree polyline labels should keep the central baseline and default series text color.
test "tree polyline simple labels use central baseline" {
  let json_str =
    #|{
    #|  "width": 800,
    #|  "height": 500,
    #|  "series": [{
    #|    "type": "tree",
    #|    "data": [{
    #|      "name": "Root",
    #|      "children": [
    #|        {
    #|          "name": "Branch A",
    #|          "children": [
    #|            { "name": "Leaf A1" },
    #|            { "name": "Leaf A2" },
    #|            { "name": "Leaf A3" }
    #|          ]
    #|        },
    #|        {
    #|          "name": "Branch B",
    #|          "children": [
    #|            { "name": "Leaf B1" },
    #|            {
    #|              "name": "Sub B2",
    #|              "children": [
    #|                { "name": "Leaf B2a" },
    #|                { "name": "Leaf B2b" }
    #|              ]
    #|            }
    #|          ]
    #|        },
    #|        {
    #|          "name": "Branch C",
    #|          "children": [
    #|            { "name": "Leaf C1" }
    #|          ]
    #|        }
    #|      ]
    #|    }],
    #|    "top": "5%",
    #|    "left": "10%",
    #|    "bottom": "5%",
    #|    "right": "25%",
    #|    "symbolSize": 7,
    #|    "orient": "LR",
    #|    "edgeShape": "polyline",
    #|    "edgeForkPosition": "50%",
    #|    "expandAndCollapse": false
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("dominant-baseline=\"central\""))
  assert_true(svg.contains("fill=\"#333333\""))
  assert_true(!svg.contains("dominant-baseline=\"middle\""))
}

///|
/// Treemap upper labels should reserve a parent header strip and show parent names above children.
test "treemap show-parent reserves upper labels" {
  let json_str =
    #|{
    #|  "width": 600,
    #|  "height": 400,
    #|  "series": [{
    #|    "type": "treemap",
    #|    "label": { "show": true, "formatter": "{b}" },
    #|    "upperLabel": { "show": true, "height": 30 },
    #|    "data": [{
    #|      "name": "Speech",
    #|      "children": [{
    #|        "name": "Voices",
    #|        "children": [
    #|          { "name": "Ting-Ting.SpeechVoice", "value": 76 },
    #|          { "name": "Alex.SpeechVoice", "value": 92 }
    #|        ]
    #|      }]
    #|    }]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Speech</text>"))
  assert_true(svg.contains(">Voices</text>"))
  assert_true(svg.contains(">Ting-Ting.SpeechVoice</text>"))
  assert_true(svg.contains("x=\"25\" y=\"65\""))
  assert_true(svg.contains("x=\"26\" y=\"95\""))
  assert_true(svg.contains("fill=\"#333333\""))
}

///|
/// Treemap parents without upperLabel should keep the JS-style parent/content split while children keep palette fills.
test "treemap parent content keeps palette fill" {
  let json_str =
    #|{
    #|  "width": 760,
    #|  "height": 520,
    #|  "series": [{
    #|    "type": "treemap",
    #|    "data": [
    #|      {
    #|        "name": "Product",
    #|        "children": [
    #|          { "name": "Core", "value": 14 },
    #|          { "name": "API", "value": 10 }
    #|        ]
    #|      }
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("fill=\"#ffffff\""))
  assert_true(svg.contains("fill=\"#5473de\""))
  assert_true(svg.contains("fill=\"#c2dd55\""))
  assert_true(svg.contains(">Product</text>"))
}

///|
/// Tree leaves config should behave like TreeSeries leavesModel for static label/item/line style inheritance.
test "tree leaves styles and node overrides render" {
  let json_str =
    #|{
    #|  "width": 800,
    #|  "height": 500,
    #|  "series": [{
    #|    "type": "tree",
    #|    "top": "8%",
    #|    "left": "10%",
    #|    "bottom": "8%",
    #|    "right": "20%",
    #|    "symbolSize": 7,
    #|    "orient": "LR",
    #|    "edgeShape": "curve",
    #|    "expandAndCollapse": false,
    #|    "itemStyle": {"color": "#6a8f3a", "borderWidth": 2},
    #|    "lineStyle": {"color": "#c9cdd4", "width": 1.5, "curveness": 0.5},
    #|    "label": {"show": true, "color": "#333333", "distance": 6},
    #|    "leaves": {
    #|      "symbolSize": 11,
    #|      "label": {"color": "#aa336a", "position": "right", "rotate": 0, "fontSize": 14, "fontWeight": "bold"},
    #|      "itemStyle": {"color": "#ffcc00", "borderColor": "#aa336a", "borderWidth": 3},
    #|      "lineStyle": {"color": "#aa336a", "width": 2.5, "opacity": 0.8}
    #|    },
    #|    "data": [{
    #|      "name": "Root",
    #|      "itemStyle": {"color": "#4c78dd"},
    #|      "children": [
    #|        {
    #|          "name": "Branch Left",
    #|          "lineStyle": {"color": "#2f4f4f", "width": 4},
    #|          "children": [
    #|            {"name": "Leaf A"},
    #|            {
    #|              "name": "Leaf B",
    #|              "itemStyle": {"color": "#00aaff", "borderColor": "#003355", "borderWidth": 1.5},
    #|              "symbolSize": 15,
    #|              "label": {"color": "#003355", "position": "left"}
    #|            }
    #|          ]
    #|        },
    #|        {
    #|          "name": "Branch Right",
    #|          "label": {"position": "right"},
    #|          "children": [{"name": "Leaf C"}]
    #|        }
    #|      ]
    #|    }]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("stroke=\"#aa336a\" stroke-width=\"2.5\""))
  assert_true(svg.contains("stroke=\"#ffcc00\""))
  assert_true(svg.contains("stroke=\"#00aaff\""))
  assert_true(svg.contains("fill=\"#aa336a\" font-size=\"14\""))
  assert_true(svg.contains("font-weight=\"bold\""))
  assert_true(svg.contains("fill=\"#003355\""))
  assert_true(!svg.contains("stroke=\"#aa336a\" stroke-width=\"3\""))
}

///|
/// Radial tree labels should be emitted as rotated transformed text groups.
test "tree radial labels use transformed groups" {
  let json_str =
    #|{
    #|  "width": 800,
    #|  "height": 500,
    #|  "series": [{
    #|    "type": "tree",
    #|    "layout": "radial",
    #|    "top": "8%",
    #|    "left": "8%",
    #|    "bottom": "8%",
    #|    "right": "8%",
    #|    "symbolSize": 8,
    #|    "expandAndCollapse": false,
    #|    "data": [{
    #|      "name": "Root",
    #|      "children": [
    #|        {"name": "North", "children": [{"name": "North-1"}, {"name": "North-2"}]},
    #|        {"name": "East", "children": [{"name": "East-1"}, {"name": "East-2"}]},
    #|        {"name": "South", "children": [{"name": "South-1"}]},
    #|        {"name": "West", "children": [{"name": "West-1"}, {"name": "West-2"}]}
    #|      ]
    #|    }]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("<g transform=\"matrix("))
  assert_true(svg.contains(">North-1</text>"))
  assert_true(svg.contains(">West-2</text>"))
}

///|
/// Tree symbols should follow series -> leaves -> item symbol precedence.
test "tree symbol shapes render from series leaves and item overrides" {
  let json_str =
    #|{
    #|  "width": 800,
    #|  "height": 500,
    #|  "series": [{
    #|    "type": "tree",
    #|    "top": "10%",
    #|    "left": "10%",
    #|    "bottom": "10%",
    #|    "right": "20%",
    #|    "orient": "LR",
    #|    "expandAndCollapse": false,
    #|    "symbol": "diamond",
    #|    "symbolSize": 14,
    #|    "itemStyle": {"color": "#cc88ff", "borderColor": "#442266", "borderWidth": 2},
    #|    "leaves": {
    #|      "symbol": "rect",
    #|      "symbolSize": 16,
    #|      "itemStyle": {"color": "#ffee88", "borderColor": "#663300", "borderWidth": 2}
    #|    },
    #|    "data": [{
    #|      "name": "Root",
    #|      "children": [
    #|        {
    #|          "name": "Branch A",
    #|          "children": [
    #|            {"name": "Leaf Rect"},
    #|            {
    #|              "name": "Leaf Triangle",
    #|              "symbol": "triangle",
    #|              "symbolSize": 18,
    #|              "itemStyle": {"color": "#88ddff", "borderColor": "#224466", "borderWidth": 2}
    #|            }
    #|          ]
    #|        },
    #|        {
    #|          "name": "Branch B",
    #|          "symbol": "roundRect",
    #|          "children": [
    #|            {
    #|              "name": "Leaf Path",
    #|              "symbol": "path://M0 -120 L104 60 L-104 60 Z",
    #|              "symbolSize": 20,
    #|              "itemStyle": {"color": "#99e0aa", "borderColor": "#225533", "borderWidth": 2}
    #|            }
    #|          ]
    #|        }
    #|      ]
    #|    }]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("<rect "))
  assert_true(svg.contains("fill=\"#cc88ff\""))
  assert_true(svg.contains("fill=\"#ffee88\""))
  assert_true(svg.contains("fill=\"#88ddff\""))
  assert_true(svg.contains("fill=\"#99e0aa\""))
  assert_true(svg.contains("stroke=\"#442266\""))
  assert_true(svg.contains("stroke=\"#224466\""))
  assert_true(svg.contains("stroke=\"#225533\""))
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
      #|<svg width="600" height="400" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" baseProfile="full" viewBox="0 0 600 400">
      #|  <path d="M165 65L165 320" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M315 65L315 320" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M465 65L465 320" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M90 320L540 320" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M90 256.25L540 256.25" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M90 192.5L540 192.5" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M90 128.75L540 128.75" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M90 65L540 65" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M90 320L540 320" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M165 320L165 324" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="165" y="334" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging" class="zr0-cls-1">Mon</text>
      #|  <path d="M315 320L315 324" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="315" y="334" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging" class="zr0-cls-1">Tue</text>
      #|  <path d="M465 320L465 324" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="465" y="334" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging" class="zr0-cls-1">Wed</text>
      #|  <path d="M90 65L90 320" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M86 320L90 320" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="82" y="320" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">0</text>
      #|  <path d="M86 256.25L90 256.25" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="82" y="256.25" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">50</text>
      #|  <path d="M86 192.5L90 192.5" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="82" y="192.5" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">100</text>
      #|  <path d="M86 128.75L90 128.75" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="82" y="128.75" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">150</text>
      #|  <path d="M86 65L90 65" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="82" y="65" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">200</text>
      #|  <path d="M118.4 320l93.2 0l0 -153l-93.1 0Z" fill="#5070dd" stroke="none" pointer-events="visible" ecmeta_series_index="0" ecmeta_data_index="0" ecmeta_ssr_type="chart" class="zr0-cls-2"/>
      #|  <path d="M268.4 320l93.2 0l0 -255l-93.1 0Z" fill="#5070dd" stroke="none" pointer-events="visible" ecmeta_series_index="0" ecmeta_data_index="1" ecmeta_ssr_type="chart" class="zr0-cls-2"/>
      #|  <path d="M418.4 320l93.2 0l0 -191.2l-93.1 0Z" fill="#5070dd" stroke="none" pointer-events="visible" ecmeta_series_index="0" ecmeta_data_index="2" ecmeta_ssr_type="chart" class="zr0-cls-2"/>
      #|<style><![CDATA[
      #|.zr0-cls-0:hover {
      #|cursor:pointer;
      #|}
      #|.zr0-cls-1:hover {
      #|cursor:pointer;
      #|fill:#5c5d63;
      #|}
      #|.zr0-cls-2:hover {
      #|cursor:pointer;
      #|fill:#587bf3;
      #|}
      #|]]></style>
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
      #|<svg width="700" height="450" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" baseProfile="full" viewBox="0 0 700 450">
      #|  <path d="M148.75 65L148.75 370" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M236.25 65L236.25 370" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M323.75 65L323.75 370" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M411.25 65L411.25 370" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M498.75 65L498.75 370" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M586.25 65L586.25 370" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 370L630 370" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 293.75L630 293.75" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 217.5L630 217.5" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 141.25L630 141.25" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 65L630 65" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 370L630 370" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 319.1666666666667L630 319.1666666666667" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 268.33333333333337L630 268.33333333333337" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 217.5L630 217.5" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 166.66666666666669L630 166.66666666666669" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 115.83333333333331L630 115.83333333333331" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 65L630 65" stroke="#dbdee4" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M105 370L630 370" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M148.75 370L148.75 374" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="148.75" y="384" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging" class="zr0-cls-1">Jan</text>
      #|  <path d="M236.25 370L236.25 374" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="236.25" y="384" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging" class="zr0-cls-1">Feb</text>
      #|  <path d="M323.75 370L323.75 374" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="323.75" y="384" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging" class="zr0-cls-1">Mar</text>
      #|  <path d="M411.25 370L411.25 374" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="411.25" y="384" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging" class="zr0-cls-1">Apr</text>
      #|  <path d="M498.75 370L498.75 374" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="498.75" y="384" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging" class="zr0-cls-1">May</text>
      #|  <path d="M586.25 370L586.25 374" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="586.25" y="384" fill="#54555a" font-size="12" text-anchor="middle" dominant-baseline="hanging" class="zr0-cls-1">Jun</text>
      #|  <path d="M105 65L105 370" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M101 370L105 370" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="97" y="370" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">0</text>
      #|  <path d="M101 293.75L105 293.75" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="97" y="293.75" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">20</text>
      #|  <path d="M101 217.5L105 217.5" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="97" y="217.5" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">40</text>
      #|  <path d="M101 141.25L105 141.25" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="97" y="141.25" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">60</text>
      #|  <path d="M101 65L105 65" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="97" y="65" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">80</text>
      #|  <path d="M105 65L105 370" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <path d="M101 370L105 370" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="97" y="370" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">0</text>
      #|  <path d="M101 319.1666666666667L105 319.1666666666667" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="97" y="319.1666666666667" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">2</text>
      #|  <path d="M101 268.33333333333337L105 268.33333333333337" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="97" y="268.33333333333337" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">4</text>
      #|  <path d="M101 217.5L105 217.5" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="97" y="217.5" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">6</text>
      #|  <path d="M101 166.66666666666669L105 166.66666666666669" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="97" y="166.66666666666669" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">8</text>
      #|  <path d="M101 115.83333333333331L105 115.83333333333331" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="97" y="115.83333333333331" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">10</text>
      #|  <path d="M101 65L105 65" stroke="#54555a" stroke-width="1" fill="none" class="zr0-cls-0"/>
      #|  <text x="97" y="65" fill="#54555a" font-size="12" text-anchor="end" dominant-baseline="middle" class="zr0-cls-1">12</text>
      #|  <path d="M121.6 370l54.3 0l0 -9.9l-54.3 0Z" fill="#5070dd" stroke="none" pointer-events="visible" ecmeta_series_index="0" ecmeta_data_index="0" ecmeta_ssr_type="chart" class="zr0-cls-2"/>
      #|  <path d="M209.1 370l54.3 0l0 -22.5l-54.3 0Z" fill="#5070dd" stroke="none" pointer-events="visible" ecmeta_series_index="0" ecmeta_data_index="1" ecmeta_ssr_type="chart" class="zr0-cls-2"/>
      #|  <path d="M296.6 370l54.3 0l0 -34.3l-54.3 0Z" fill="#5070dd" stroke="none" pointer-events="visible" ecmeta_series_index="0" ecmeta_data_index="2" ecmeta_ssr_type="chart" class="zr0-cls-2"/>
      #|  <path d="M384.1 370l54.3 0l0 -100.6l-54.3 0Z" fill="#5070dd" stroke="none" pointer-events="visible" ecmeta_series_index="0" ecmeta_data_index="3" ecmeta_ssr_type="chart" class="zr0-cls-2"/>
      #|  <path d="M471.6 370l54.3 0l0 -109.4l-54.3 0Z" fill="#5070dd" stroke="none" pointer-events="visible" ecmeta_series_index="0" ecmeta_data_index="4" ecmeta_ssr_type="chart" class="zr0-cls-2"/>
      #|  <path d="M559.1 370l54.3 0l0 -269.5l-54.3 0Z" fill="#5070dd" stroke="none" pointer-events="visible" ecmeta_series_index="0" ecmeta_data_index="5" ecmeta_ssr_type="chart" class="zr0-cls-2"/>
      #|  <path d="M 148.75 319.1666666666667 L 236.25 314.0833333333333 L 323.75 286.125 L 411.25 255.625 L 498.75 209.875 L 586.25 110.75" fill="none" stroke="#b6d634" stroke-width="2" stroke-linejoin="bevel" pointer-events="visible" class="zr0-cls-0"/>
      #|  <circle cx="148.75" cy="319.1666666666667" r="2" fill="#b6d634" stroke="none" pointer-events="visible" class="zr0-cls-3"/>
      #|  <circle cx="236.25" cy="314.0833333333333" r="2" fill="#b6d634" stroke="none" pointer-events="visible" class="zr0-cls-3"/>
      #|  <circle cx="323.75" cy="286.125" r="2" fill="#b6d634" stroke="none" pointer-events="visible" class="zr0-cls-3"/>
      #|  <circle cx="411.25" cy="255.625" r="2" fill="#b6d634" stroke="none" pointer-events="visible" class="zr0-cls-3"/>
      #|  <circle cx="498.75" cy="209.875" r="2" fill="#b6d634" stroke="none" pointer-events="visible" class="zr0-cls-3"/>
      #|  <circle cx="586.25" cy="110.75" r="2" fill="#b6d634" stroke="none" pointer-events="visible" class="zr0-cls-3"/>
      #|<style><![CDATA[
      #|.zr0-cls-0:hover {
      #|cursor:pointer;
      #|}
      #|.zr0-cls-1:hover {
      #|cursor:pointer;
      #|fill:#5c5d63;
      #|}
      #|.zr0-cls-2:hover {
      #|cursor:pointer;
      #|fill:#587bf3;
      #|}
      #|.zr0-cls-3:hover {
      #|cursor:pointer;
      #|fill:#c8eb39;
      #|}
      #|]]></style>
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
  assert_true(svg.contains("matrix(2.5875,0,0,0.6375,315,192.5)"))
  assert_true(svg.contains("opacity=\"0.5\""))
}

///|
test "pictorial bar body-fill centers the grid vertically" {
  let json_str =
    #|{
    #|  "tooltip": {},
    #|  "legend": {
    #|    "data": ["typeA", "typeB"],
    #|    "selectedMode": "single"
    #|  },
    #|  "xAxis": {
    #|    "data": ["a", "b", "c", "d", "e"],
    #|    "axisTick": {"show": false},
    #|    "axisLine": {"show": false},
    #|    "axisLabel": {"show": false}
    #|  },
    #|  "yAxis": {
    #|    "max": 150,
    #|    "offset": 20,
    #|    "splitLine": {"show": false}
    #|  },
    #|  "grid": {
    #|    "top": "center",
    #|    "height": 230
    #|  },
    #|  "series": [{
    #|    "type": "pictorialBar",
    #|    "symbolClip": true,
    #|    "symbolBoundingData": 150,
    #|    "data": [123, 34, 101, 89, 72]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("M90 85L90 315"))
  assert_true(svg.contains("fill=\"#5070dd\""))
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
test "dataset filter transform partitions data to multiple pies" {
  let json_str =
    #|{
    #|  "width": 600,
    #|  "height": 400,
    #|  "dataset": [
    #|    {
    #|      "source": [
    #|        ["Product", "Sales", "Price", "Year"],
    #|        ["Cake", 123, 32, 2011],
    #|        ["Cereal", 231, 14, 2011],
    #|        ["Tofu", 235, 5, 2011],
    #|        ["Dumpling", 341, 25, 2011],
    #|        ["Biscuit", 122, 29, 2011],
    #|        ["Cake", 143, 30, 2012],
    #|        ["Cereal", 201, 19, 2012],
    #|        ["Tofu", 255, 7, 2012],
    #|        ["Dumpling", 241, 27, 2012],
    #|        ["Biscuit", 102, 34, 2012],
    #|        ["Cake", 153, 28, 2013],
    #|        ["Cereal", 181, 21, 2013],
    #|        ["Tofu", 395, 4, 2013],
    #|        ["Dumpling", 281, 31, 2013],
    #|        ["Biscuit", 92, 39, 2013],
    #|        ["Cake", 223, 29, 2014],
    #|        ["Cereal", 211, 17, 2014],
    #|        ["Tofu", 345, 3, 2014],
    #|        ["Dumpling", 211, 35, 2014],
    #|        ["Biscuit", 72, 24, 2014]
    #|      ]
    #|    },
    #|    {
    #|      "transform": {
    #|        "type": "filter",
    #|        "config": {"dimension": "Year", "value": 2011}
    #|      }
    #|    },
    #|    {
    #|      "transform": {
    #|        "type": "filter",
    #|        "config": {"dimension": "Year", "value": 2012}
    #|      }
    #|    },
    #|    {
    #|      "transform": {
    #|        "type": "filter",
    #|        "config": {"dimension": "Year", "value": 2013}
    #|      }
    #|    }
    #|  ],
    #|  "series": [
    #|    {"type": "pie", "radius": 50, "center": ["50%", "25%"], "datasetIndex": 1},
    #|    {"type": "pie", "radius": 50, "center": ["50%", "50%"], "datasetIndex": 2},
    #|    {"type": "pie", "radius": 50, "center": ["50%", "75%"], "datasetIndex": 3}
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  // 3 pies * 5 products = 15 sectors in this fixture.
  assert_eq(count_substring(svg, "stroke=\"#ffffff\""), 15)
  // Ensure labels from dataset rows are visible.
  assert_true(svg.contains(">Cake</text>"))
  assert_true(svg.contains(">Tofu</text>"))
  // No 2014 values should leak into the rendered pies.
  assert_true(!svg.contains(">223</text>"))
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
test "scatter anscombe quartet renders four grids" {
  let json_str =
    #|{
    #|  "width": 600,
    #|  "height": 400,
    #|  "title": {"text": "Anscombe's quartet", "left": "center", "top": 0},
    #|  "grid": [
    #|    {"left": "7%", "top": "7%", "width": "38%", "height": "38%"},
    #|    {"right": "7%", "top": "7%", "width": "38%", "height": "38%"},
    #|    {"left": "7%", "bottom": "7%", "width": "38%", "height": "38%"},
    #|    {"right": "7%", "bottom": "7%", "width": "38%", "height": "38%"}
    #|  ],
    #|  "xAxis": [
    #|    {"gridIndex": 0, "min": 0, "max": 20},
    #|    {"gridIndex": 1, "min": 0, "max": 20},
    #|    {"gridIndex": 2, "min": 0, "max": 20},
    #|    {"gridIndex": 3, "min": 0, "max": 20}
    #|  ],
    #|  "yAxis": [
    #|    {"gridIndex": 0, "min": 0, "max": 15},
    #|    {"gridIndex": 1, "min": 0, "max": 15},
    #|    {"gridIndex": 2, "min": 0, "max": 15},
    #|    {"gridIndex": 3, "min": 0, "max": 15}
    #|  ],
    #|  "series": [
    #|    {"name": "I", "type": "scatter", "xAxisIndex": 0, "yAxisIndex": 0, "data": [[10,8.04],[8,6.95],[13,7.58],[9,8.81],[11,8.33],[14,9.96],[6,7.24],[4,4.26],[12,10.84],[7,4.82],[5,5.68]]},
    #|    {"name": "II", "type": "scatter", "xAxisIndex": 1, "yAxisIndex": 1, "data": [[10,9.14],[8,8.14],[13,8.74],[9,8.77],[11,9.26],[14,8.1],[6,6.13],[4,3.1],[12,9.13],[7,7.26],[5,4.74]]},
    #|    {"name": "III", "type": "scatter", "xAxisIndex": 2, "yAxisIndex": 2, "data": [[10,7.46],[8,6.77],[13,12.74],[9,7.11],[11,7.81],[14,8.84],[6,6.08],[4,5.39],[12,8.15],[7,6.42],[5,5.73]]},
    #|    {"name": "IV", "type": "scatter", "xAxisIndex": 3, "yAxisIndex": 3, "data": [[8,6.58],[8,5.76],[8,7.71],[8,8.84],[8,8.47],[8,7.04],[8,5.25],[19,12.5],[8,5.56],[8,7.91],[8,6.89]]}
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("Anscombe&#39;s quartet"))
  assert_true(count_substring(svg, ">20</text>") >= 4)
  assert_true(count_substring(svg, ">15</text>") >= 4)
  assert_true(count_substring(svg, "<circle") >= 44)
}

///|
test "continuous visual map renders standalone legend bar" {
  let json_str =
    #|{
    #|  "width": 220,
    #|  "height": 180,
    #|  "visualMap": [{
    #|    "min": 0,
    #|    "max": 100,
    #|    "show": true,
    #|    "inRange": { "color": ["#3182bd"] }
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(count_substring(svg, "<rect x=\"15\"") >= 20)
  assert_true(svg.contains("#3182bd"))
  assert_true(svg.contains("#b7b9be"))
  assert_true(svg.contains(">100</text>"))
  assert_true(svg.contains(">0</text>"))
}

///|
test "piecewise visual map renders standalone items" {
  let json_str =
    #|{
    #|  "width": 320,
    #|  "height": 220,
    #|  "visualMap": [{
    #|    "type": "piecewise",
    #|    "left": "20",
    #|    "top": "10",
    #|    "showLabel": true,
    #|    "text": ["High", "Low"],
    #|    "pieces": [
    #|      { "min": 0, "max": 10, "label": "0-10", "color": "#d94e5d" },
    #|      { "min": 10, "max": 20, "label": "10-20" },
    #|      { "min": 20, "max": 30, "label": "20-30", "color": "#50a3ba" }
    #|    ],
    #|    "inRange": { "color": ["#d94e5d", "#eac736", "#50a3ba"] }
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">High</text>"))
  assert_true(svg.contains(">Low</text>"))
  assert_true(svg.contains(">0-10</text>"))
  assert_true(svg.contains(">10-20</text>"))
  assert_true(svg.contains(">20-30</text>"))
  assert_true(svg.contains("#d94e5d"))
  assert_true(svg.contains("#50a3ba"))
}

///|
test "piecewise visual map splitNumber opens ends" {
  let json_str =
    #|{
    #|  "width": 320,
    #|  "height": 220,
    #|  "visualMap": [{
    #|    "type": "piecewise",
    #|    "left": "20",
    #|    "top": "10",
    #|    "min": 0,
    #|    "max": 30,
    #|    "splitNumber": 3,
    #|    "minOpen": true,
    #|    "maxOpen": true,
    #|    "showLabel": true,
    #|    "text": ["High", "Low"],
    #|    "inRange": { "color": ["#d94e5d", "#eac736", "#50a3ba"] }
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("&lt; 0"))
  assert_true(svg.contains("&gt; 30"))
  assert_true(count_substring(svg, "<path") >= 5)
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
/// Polar radius axis ticks/labels should use mapped coords and perpendicular offset like RadiusAxisView.
test "polar radius axis uses mapped coords and perpendicular label offset" {
  let json_str =
    #|{
    #|  "width": 600,
    #|  "height": 400,
    #|  "polar": {},
    #|  "angleAxis": {
    #|    "type": "category",
    #|    "data": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    #|  },
    #|  "radiusAxis": {},
    #|  "series": [{
    #|    "type": "bar",
    #|    "coordinateSystem": "polar",
    #|    "data": [120, 200, 150, 80, 70, 110, 130]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("<circle cx=\"300\" cy=\"200\" r=\"40\""))
  assert_true(svg.contains("<circle cx=\"300\" cy=\"200\" r=\"160\""))
  assert_true(svg.contains("<text x=\"292\" y=\"200\""))
  assert_true(svg.contains("<text x=\"292\" y=\"40\""))
  assert_true(!svg.contains("<text x=\"300\" y=\"188\""))
}

///|
test "polar bar stack shares stack layout across series" {
  let json_str =
    #|{
    #|  "width": 600,
    #|  "height": 400,
    #|  "angleAxis": {},
    #|  "radiusAxis": {
    #|    "type": "category",
    #|    "data": ["Mon", "Tue", "Wed", "Thu"]
    #|  },
    #|  "polar": {},
    #|  "series": [
    #|    { "type": "bar", "coordinateSystem": "polar", "name": "A", "stack": "a", "data": [1, 2, 3, 4] },
    #|    { "type": "bar", "coordinateSystem": "polar", "name": "B", "stack": "a", "data": [2, 4, 6, 8] },
    #|    { "type": "bar", "coordinateSystem": "polar", "name": "C", "stack": "a", "data": [1, 2, 3, 4] }
    #|  ],
    #|  "legend": { "show": true, "data": ["A", "B", "C"] }
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">A</text>"))
  assert_true(svg.contains(">B</text>"))
  assert_true(svg.contains(">C</text>"))
  assert_true(svg.contains("#5070dd"))
  assert_true(svg.contains("#b6d634"))
  assert_true(svg.contains("#505372"))
}

///|
test "polar bar stack radial renders visible sectors" {
  let json_str =
    #|{
    #|  "width": 600,
    #|  "height": 400,
    #|  "angleAxis": {
    #|    "type": "category",
    #|    "data": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    #|  },
    #|  "radiusAxis": {},
    #|  "polar": {},
    #|  "series": [
    #|    {
    #|      "type": "bar",
    #|      "data": [1, 2, 3, 4, 3, 5, 1],
    #|      "coordinateSystem": "polar",
    #|      "name": "A",
    #|      "stack": "a",
    #|      "emphasis": { "focus": "series" }
    #|    },
    #|    {
    #|      "type": "bar",
    #|      "data": [2, 4, 6, 1, 3, 2, 1],
    #|      "coordinateSystem": "polar",
    #|      "name": "B",
    #|      "stack": "a",
    #|      "emphasis": { "focus": "series" }
    #|    },
    #|    {
    #|      "type": "bar",
    #|      "data": [1, 2, 3, 4, 1, 2, 5],
    #|      "coordinateSystem": "polar",
    #|      "name": "C",
    #|      "stack": "a",
    #|      "emphasis": { "focus": "series" }
    #|    }
    #|  ],
    #|  "legend": { "show": true, "data": ["A", "B", "C"] }
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(
    svg.contains(
      "M 295.315 187.5169 A 13.3333 13.3333 0 0 1 304.685 187.5169 L 300 200 Z",
    ),
  )
  assert_true(
    svg.contains("M 418.914 183.892 A 120 120 0 0 1 400.1488 266.1076"),
  )
  assert_true(svg.contains(">12</text>"))
  assert_true(svg.contains("fill=\"#5070dd\""))
  assert_true(svg.contains("fill=\"#b6d634\""))
  assert_true(svg.contains("fill=\"#505372\""))
}

///|
test "polar bar real estate keeps transparent stacks invisible" {
  let json_str =
    #|{
    #|  "width": 800,
    #|  "height": 500,
    #|  "angleAxis": { "type": "category", "data": ["A", "B", "C"] },
    #|  "radiusAxis": {},
    #|  "polar": {},
    #|  "series": [
    #|    {
    #|      "type": "bar",
    #|      "coordinateSystem": "polar",
    #|      "stack": "Min Max",
    #|      "silent": true,
    #|      "itemStyle": { "color": "transparent" },
    #|      "data": [10, 20, 30]
    #|    },
    #|    {
    #|      "type": "bar",
    #|      "coordinateSystem": "polar",
    #|      "name": "Range",
    #|      "stack": "Min Max",
    #|      "data": [5, 10, 15]
    #|    },
    #|    {
    #|      "type": "bar",
    #|      "coordinateSystem": "polar",
    #|      "stack": "Average",
    #|      "silent": true,
    #|      "itemStyle": { "color": "transparent" },
    #|      "data": [40, 50, 60]
    #|    },
    #|    {
    #|      "type": "bar",
    #|      "coordinateSystem": "polar",
    #|      "name": "Average",
    #|      "stack": "Average",
    #|      "barGap": "-100%",
    #|      "data": [7, 8, 9]
    #|    }
    #|  ],
    #|  "legend": { "show": true, "data": ["Range", "Average"] }
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Range</text>"))
  assert_true(svg.contains(">Average</text>"))
  assert_true(svg.contains("#b6d634"))
  assert_true(svg.contains("#ff994d"))
  assert_true(count_substring(svg, "fill=\"none\"") >= 2)
}

///|
test "bar background renders under bars" {
  let json_str =
    #|{
    #|  "width": 600,
    #|  "height": 400,
    #|  "xAxis": {
    #|    "type": "category",
    #|    "data": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    #|  },
    #|  "yAxis": {
    #|    "type": "value"
    #|  },
    #|  "series": [{
    #|    "type": "bar",
    #|    "showBackground": true,
    #|    "backgroundStyle": {
    #|      "color": "rgba(180, 180, 180, 0.2)"
    #|    },
    #|    "data": [120, 200, 150, 80, 70, 110, 130]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_eq(count_substring(svg, "fill-opacity=\"0.2\""), 7)
  assert_eq(count_substring(svg, "rgb(180,180,180)"), 7)
  assert_true(!svg.contains("rgba(180,180,180,0.2)"))
  assert_true(svg.contains("ecmeta_series_index=\"0\""))
  assert_true(svg.contains("ecmeta_data_index=\"0\""))
  assert_true(svg.contains("ecmeta_ssr_type=\"chart\""))
}

///|
test "polar roundCap renders bordered rounded bars" {
  let json_str =
    #|{
    #|  "width": 400,
    #|  "height": 300,
    #|  "angleAxis": {
    #|    "max": 2,
    #|    "startAngle": 30,
    #|    "splitLine": { "show": false }
    #|  },
    #|  "radiusAxis": {
    #|    "type": "category",
    #|    "data": ["v", "w", "x", "y", "z"],
    #|    "z": 10
    #|  },
    #|  "polar": {},
    #|  "series": [
    #|    {
    #|      "type": "bar",
    #|      "coordinateSystem": "polar",
    #|      "name": "Without Round Cap",
    #|      "data": [4, 3, 2, 1, 0],
    #|      "itemStyle": {
    #|        "borderColor": "red",
    #|        "opacity": 0.8,
    #|        "borderWidth": 1
    #|      }
    #|    },
    #|    {
    #|      "type": "bar",
    #|      "coordinateSystem": "polar",
    #|      "name": "With Round Cap",
    #|      "roundCap": true,
    #|      "data": [4, 3, 2, 1, 0],
    #|      "itemStyle": {
    #|        "borderColor": "green",
    #|        "opacity": 0.8,
    #|        "borderWidth": 1
    #|      }
    #|    }
    #|  ],
    #|  "legend": {
    #|    "show": true,
    #|    "data": ["Without Round Cap", "With Round Cap"]
    #|  }
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Without Round Cap</text>"))
  assert_true(svg.contains(">With Round Cap</text>"))
  assert_true(count_substring(svg, "stroke=\"#ff0000\"") >= 5)
  assert_true(count_substring(svg, "stroke=\"#008000\"") >= 5)
  assert_true(count_substring(svg, "opacity=\"0.8\"") >= 10)
}

///|
/// Polar prepareCustom should expose the coord sys bounds used by custom series.
test "polar prepareCustom exposes coord sys bounds" {
  let json_str =
    #|{
    #|  "width": 600,
    #|  "height": 400,
    #|  "polar": {},
    #|  "angleAxis": {
    #|    "type": "category",
    #|    "data": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    #|  },
    #|  "radiusAxis": {},
    #|  "series": [{
    #|    "type": "bar",
    #|    "coordinateSystem": "polar",
    #|    "data": [120, 200, 150, 80, 70, 110, 130]
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  match @layout.build_polar(opt) {
    Some(polar) => {
      let prepared = polar.prepare_custom()
      assert_eq(prepared.coord_sys.type_name, "polar")
      assert_eq(prepared.coord_sys.cx, 300.0)
      assert_eq(prepared.coord_sys.cy, 200.0)
      assert_eq(prepared.coord_sys.r0, 0.0)
      assert_eq(prepared.coord_sys.r, 160.0)
    }
    None => assert_true(false)
  }
}

///|
test "lines series renders static labels on non-polyline paths" {
  let json_str =
    #|{
    #|  "width": 360,
    #|  "height": 240,
    #|  "xAxis": { "type": "value", "min": 0, "max": 10 },
    #|  "yAxis": { "type": "value", "min": 0, "max": 10 },
    #|  "series": [{
    #|    "type": "lines",
    #|    "coordinateSystem": "cartesian2d",
    #|    "label": { "show": true, "position": "end" },
    #|    "lineStyle": { "color": "#5070dd", "width": 2, "opacity": 0.8 },
    #|    "data": [
    #|      { "name": "Arrive", "coords": [[1, 1], [8, 7]] },
    #|      {
    #|        "name": "Depart",
    #|        "coords": [[2, 8], [7, 3]],
    #|        "label": { "position": "start", "color": "#dd4444" },
    #|        "lineStyle": { "color": "#dd4444", "opacity": 0.9 }
    #|      },
    #|      {
    #|        "name": "Arc",
    #|        "coords": [[1, 6], [9, 6]],
    #|        "label": { "position": "middle", "distance": 10, "fontWeight": "bold" },
    #|        "lineStyle": { "color": "#73c0de", "curveness": 0.35, "opacity": 0.7 }
    #|      }
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains(">Arrive</text>"))
  assert_true(svg.contains(">Depart</text>"))
  assert_true(svg.contains(">Arc</text>"))
  assert_true(svg.contains("fill=\"#5070dd\""))
  assert_true(svg.contains("fill=\"#dd4444\""))
  assert_true(svg.contains("font-weight=\"bold\""))
  assert_true(count_substring(svg, "transform=\"matrix(") >= 3)
}

///|
test "lines series parses flat coords array data" {
  let json_str =
    #|{
    #|  "width": 320,
    #|  "height": 220,
    #|  "xAxis": { "type": "value", "min": 0, "max": 10 },
    #|  "yAxis": { "type": "value", "min": 0, "max": 10 },
    #|  "series": [{
    #|    "type": "lines",
    #|    "coordinateSystem": "cartesian2d",
    #|    "clip": true,
    #|    "lineStyle": { "color": "#5070dd", "width": 2, "opacity": 0.7 },
    #|    "data": [2, 1, 1, 9, 7, 3, 2, 8, 5, 5, 8, 2]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("clip-path=\"url(#clip-0)\""))
  assert_eq(count_substring(svg, "stroke=\"#5070dd\""), 2)
  assert_true(svg.contains("<polyline points=\"72,132.5 264,87.5\""))
  assert_true(svg.contains("<polyline points=\"96,80 168,102.5 240,125\""))
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
test "geo svg map renders source fill and stroke" {
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
    #|    "svg": "<svg width='100' height='100' viewBox='0 0 100 100'><g name='Alpha'><path d='M 0 0 L 10 0 L 10 10 L 0 10 Z' fill='#123456' stroke='#654321' stroke-width='2'/></g></svg>"
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("fill=\"#123456\""))
  assert_true(svg.contains("stroke=\"#654321\""))
  assert_true(svg.contains("stroke-width=\"2\""))
  assert_true(svg.contains(">Alpha</text>"))
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
    #|      "geoIndex": 0,
    #|      "mapValueCalculation": "max",
    #|      "data": [
    #|        { "name": "Alpha", "value": 0 },
    #|        { "name": "Beta", "value": 0 }
    #|      ]
    #|    },
    #|    {
    #|      "type": "map",
    #|      "geoIndex": 0,
    #|      "data": [
    #|        { "name": "Alpha", "value": 100 }
    #|      ]
    #|    }
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  // 2 geo outlines (rgba fill) + 2 map fill paths (visual-map colored).
  assert_eq(count_substring(svg, "<path d=\"M "), 4)
  assert_eq(count_substring(svg, "fill=\"rgb(234,237,245)\""), 2)
  assert_eq(count_substring(svg, "fill=\"#3182bd\""), 1)
  assert_eq(count_substring(svg, "fill=\"#deebf7\""), 1)
  assert_true(svg.contains("fill=\"#3182bd\""))
  assert_true(svg.contains("fill=\"#deebf7\""))
}

///|
test "map showLegendSymbol can suppress series symbols" {
  let json_str =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "legend": {},
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
    #|      "name": "Series A",
    #|      "type": "map",
    #|      "map": "demo",
    #|      "showLegendSymbol": false,
    #|      "data": [
    #|        { "name": "Alpha", "value": 0 },
    #|        { "name": "Beta", "value": 0 }
    #|      ]
    #|    },
    #|    {
    #|      "name": "Series B",
    #|      "type": "map",
    #|      "map": "demo",
    #|      "data": [
    #|        { "name": "Alpha", "value": 100 }
    #|      ]
    #|    }
    #|  ]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_eq(count_substring(svg, "<circle"), 1)
  assert_true(svg.contains(">Series A</text>"))
  assert_true(svg.contains(">Series B</text>"))
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
  assert_true(svg.contains("<text x=\"50\" y=\"12\""))
  assert_true(svg.contains(">A</text>"))
  assert_true(svg.contains("<text x=\"210\" y=\"12\""))
  assert_true(svg.contains(">B</text>"))
  assert_true(svg.contains("<text x=\"370\" y=\"12\""))
  assert_true(svg.contains(">C</text>"))
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
test "heatmap uses the last matching visualMap for a series" {
  let json_str =
    #|{
    #|  "width": 220,
    #|  "height": 180,
    #|  "xAxis": { "type": "category", "data": ["A"] },
    #|  "yAxis": { "type": "category", "data": ["B"] },
    #|  "visualMap": [
    #|    {
    #|      "show": false,
    #|      "seriesIndex": 0,
    #|      "min": 0,
    #|      "max": 10,
    #|      "inRange": { "color": ["#111111"] }
    #|    },
    #|    {
    #|      "show": false,
    #|      "seriesIndex": 0,
    #|      "min": 0,
    #|      "max": 10,
    #|      "inRange": { "color": ["#ff0000"] }
    #|    }
    #|  ],
    #|  "series": [{
    #|    "type": "heatmap",
    #|    "data": [[0, 0, 5]]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("fill=\"#ff0000\""))
  assert_true(!svg.contains("#111111"))
}

///|
test "heatmap piecewise selection uses inactive color for unselected pieces" {
  let json_str =
    #|{
    #|  "width": 220,
    #|  "height": 180,
    #|  "xAxis": { "type": "category", "data": ["A", "B"] },
    #|  "yAxis": { "type": "category", "data": ["C"] },
    #|  "visualMap": {
    #|    "show": false,
    #|    "type": "piecewise",
    #|    "seriesIndex": 0,
    #|    "pieces": [
    #|      { "min": 0, "max": 5, "color": "#00aa00" },
    #|      { "min": 5, "max": 10, "color": "#ff0000" }
    #|    ],
    #|    "selected": { "0": false, "1": true }
    #|  },
    #|  "series": [{
    #|    "type": "heatmap",
    #|    "data": [[0, 0, 2], [1, 0, 8]]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("fill=\"none\""))
  assert_true(svg.contains("fill=\"#ff0000\""))
  assert_true(!svg.contains("#00aa00"))
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
  assert_true(svg.contains("class=\"zr0-cls-0\""))
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

///|
test "register map API feeds get_map and geo render" {
  let source_json =
    #|{
    #|  "maps": [{
    #|    "name": "registered-demo",
    #|    "geoJson": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Alpha", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    },
    #|    "specialAreas": {
    #|      "Alpha": { "left": 0, "top": 0, "width": 10, "height": 10 }
    #|    }
    #|  }]
    #|}
  let source_opt = @option.parse(source_json)
  let map_entry = source_opt.map_registry[0]
  match map_entry.geo_json {
    Some(geo_json) =>
      @yuecharts.register_map(map_entry.name, geo_json, map_entry.special_areas)
    None => assert_true(false)
  }
  match @yuecharts.get_map("registered-demo") {
    Some(map_for_user) => {
      match map_for_user.geo_json {
        { "type": String("FeatureCollection"), .. } => assert_true(true)
        _ => assert_true(false)
      }
      assert_eq(map_for_user.special_areas.length(), 1)
      assert_eq(map_for_user.special_areas[0].name, "Alpha")
    }
    None => assert_true(false)
  }
  let render_json =
    #|{
    #|  "width": 260,
    #|  "height": 180,
    #|  "geo": {
    #|    "map": "registered-demo",
    #|    "label": { "show": true, "color": "#444444" }
    #|  },
    #|  "series": []
    #|}
  let svg = @yuecharts.render(render_json)
  assert_true(svg.contains(">Alpha</text>"))
}

///|
test "sankey renders node rects and edge bands" {
  let json_str =
    #|{
    #|  "width": 600,
    #|  "height": 400,
    #|  "series": [{
    #|    "type": "sankey",
    #|    "data": [
    #|      {"name": "a"},
    #|      {"name": "b"},
    #|      {"name": "a1"},
    #|      {"name": "a2"},
    #|      {"name": "b1"},
    #|      {"name": "c"}
    #|    ],
    #|    "links": [
    #|      {"source": "a", "target": "a1", "value": 5},
    #|      {"source": "a", "target": "a2", "value": 3},
    #|      {"source": "b", "target": "b1", "value": 8},
    #|      {"source": "a", "target": "b1", "value": 3},
    #|      {"source": "b1", "target": "a1", "value": 1},
    #|      {"source": "b1", "target": "c", "value": 2}
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("fill=\"#86878c\""))
  assert_true(count_substring(svg, "<rect") >= 6)
  assert_true(count_substring(svg, "<path") >= 6)
  assert_true(svg.contains(">a</text>"))
  assert_true(svg.contains(">b1</text>"))
}

///|
test "sankey vertical labels and levels styles render" {
  let json_str =
    #|{
    #|  "width": 640,
    #|  "height": 420,
    #|  "series": [{
    #|    "type": "sankey",
    #|    "orient": "vertical",
    #|    "label": {"position": "top"},
    #|    "data": [
    #|      {"name": "src", "depth": 0},
    #|      {"name": "mid", "depth": 1},
    #|      {"name": "dst", "depth": 2}
    #|    ],
    #|    "links": [
    #|      {"source": "src", "target": "mid", "value": 6},
    #|      {"source": "mid", "target": "dst", "value": 4}
    #|    ],
    #|    "levels": [
    #|      {"depth": 0, "itemStyle": {"color": "#fbb4ae"}, "lineStyle": {"color": "source", "opacity": 0.6}},
    #|      {"depth": 1, "itemStyle": {"color": "#b3cde3", "borderColor": "#5f7992", "borderWidth": 1.5}}
    #|    ]
    #|  }]
    #|}
  let svg = @yuecharts.render(json_str)
  assert_true(svg.contains("fill=\"#fbb4ae\""))
  assert_true(svg.contains("fill=\"#b3cde3\""))
  assert_true(svg.contains("stroke=\"#5f7992\""))
  assert_true(svg.contains(">src</text>"))
  assert_true(svg.contains(">mid</text>"))
}

///|
/// Pie chart highlight dispatch action: highlighted item gets lifted color,
/// non-highlighted items get opacity="0.1" (blur effect).
/// <=> echarts/src/util/states.ts:createEmphasisDefaultState / createBlurDefaultState
test "pie highlight emphasis lifts color and blurs others" {
  let json_str =
    #|{
    #|  "option": {
    #|    "series": [{
    #|      "type": "pie",
    #|      "data": [
    #|        {"name": "A", "value": 40},
    #|        {"name": "B", "value": 30},
    #|        {"name": "C", "value": 30}
    #|      ]
    #|    }]
    #|  },
    #|  "dispatchActions": [{"type": "highlight", "seriesIndex": 0, "dataIndex": 0}]
    #|}
  let svg = @yuecharts.render(json_str)
  // Item 0 (A) is highlighted: fill color should be lifted from #5070dd to #587bf3
  assert_true(svg.contains("fill=\"#587bf3\""))
  // Items 1 and 2 should be blurred: opacity="0.1"
  assert_true(svg.contains("opacity=\"0.1\""))
}

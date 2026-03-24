// Corresponds to: echarts/src/component/legend/LegendView.ts
//                  echarts/src/component/legend/LegendModel.ts
//
// Plain horizontal legend: coloured icon rectangles followed by series names.
//
// Default values (from LegendModel.ts):
//   left: "center", bottom: tokens.size.m (=15), orient: "horizontal"
//   itemWidth: 25, itemHeight: 14, itemGap: 8
//   textX = itemWidth + 5  (text placed 5px right of icon)
//   text y: itemHeight / 2, verticalAlign: "middle"
//   padding: 5 (around the whole legend group)
//   textStyle.fontSize: 12
//
// ECharts default token color for legend labels: tokens.color.secondary = neutral70 ≈ #54555a

///|
/// Parse a legend position value string to a pixel Double.
/// Handles "", "auto", named values ("top","bottom","center","left","right"),
/// and numeric strings like "15", "0".
fn legend_parse_pos(s : String, fallback : Double) -> Double {
  if s == "" || s == "auto" {
    fallback
  } else {
    let r = try? @strconv.parse_double(s)
    match r {
      Ok(v) => v
      Err(_) => fallback
    }
  }
}

///|
/// Render the legend to scene graph elements.
/// Returns an empty array if legend is not shown or no named series exist.
pub fn render_legend(opt : @option.ChartOption) -> Array[@graphic.Element] {
  // Only render if legend is set and show=true.
  let lg = match opt.legend {
    Some(l) if l.show => l
    _ => return []
  }
  let elems : Array[@graphic.Element] = []
  // Collect (color, name) pairs for all named series.
  let items : Array[(String, String)] = []
  let mut ci = 0
  while ci < opt.series.length() {
    let s = opt.series[ci]
    ci = ci + 1
    match s.name {
      Some(n) if n != "" => {
        let color = match s.color {
          Some(c) => c
          None => @visual.palette_color(ci - 1)
        }
        items.push((color, n))
      }
      _ => ()
    }
  }
  if items.length() == 0 {
    return elems
  }
  // Layout constants matching ECharts LegendModel defaults.
  let item_w = 25.0 // itemWidth default = 25
  let item_h = 14.0 // itemHeight default = 14
  let icon_text_gap = 5.0 // textX = itemWidth + 5 in LegendView.ts
  let item_gap = 8.0 // itemGap default = 8
  let padding = 5.0 // padding default = 5
  let char_w = 7.0 // approximate pixel width per character at font-size 12
  // Compute total content width for centering.
  let mut total_w = 0.0
  let mut wi = 0
  while wi < items.length() {
    let (_, name) = items[wi]
    wi = wi + 1
    total_w = total_w +
      item_w +
      icon_text_gap +
      name.length().to_double() * char_w
    if wi < items.length() {
      total_w = total_w + item_gap
    }
  }
  // Resolve horizontal start x (matching legend.left).
  let start_x = match lg.left {
    "center" => (opt.width - total_w) * 0.5
    "right" => opt.width - total_w - padding
    "left" => padding
    _ => {
      // Treat as numeric pixel value; fall back to left-aligned.
      let v = legend_parse_pos(lg.left, padding)
      v
    }
  }
  // Resolve vertical icon centre-line (matching legend.top / legend.bottom).
  // ECharts default: bottom = 15, placing group bottom at chart_height - 15.
  // Group height = itemHeight + 2*padding; icon centre = group top + padding + itemHeight/2.
  let icon_cy = if lg.top != "" && lg.top != "auto" {
    match lg.top {
      "top" => padding + item_h * 0.5
      "middle" | "center" => opt.height * 0.5
      "bottom" => opt.height - padding - item_h * 0.5
      _ => {
        let top_px = legend_parse_pos(lg.top, padding)
        top_px + padding + item_h * 0.5
      }
    }
  } else {
    // Use bottom (default = "15")
    let bottom_px = legend_parse_pos(lg.bottom, 15.0)
    opt.height - bottom_px - padding - item_h * 0.5
  }
  let icon_top = icon_cy - item_h * 0.5
  let mut cx = start_x
  let mut ii = 0
  while ii < items.length() {
    let (color, name) = items[ii]
    ii = ii + 1
    // Coloured icon rectangle (itemWidth × itemHeight).
    elems.push(
      @graphic.Element::rect_colored(cx, icon_top, item_w, item_h, color),
    )
    // Label text: x = icon right + 5, y = icon centre, verticalAlign = middle.
    elems.push(
      @graphic.Element::text_colored(
        cx + item_w + icon_text_gap,
        icon_cy,
        name,
        @graphic.TextAnchor::start(),
        @graphic.TextBaseline::middle(),
        "#54555a", // tokens.color.secondary ≈ neutral70
      ),
    )
    cx = cx +
      item_w +
      icon_text_gap +
      name.length().to_double() * char_w +
      item_gap
  }
  elems
}

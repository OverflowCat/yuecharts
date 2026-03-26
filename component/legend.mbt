// Corresponds to: echarts/src/component/legend/LegendView.ts
//                  echarts/src/component/legend/LegendModel.ts
//                  and echarts/src/processor/dataFilter.ts legend selection coupling.
//
// Plain horizontal legend: coloured icon rectangles followed by legend item names.
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
fn append_data_legend_items(
  items : Array[(String, String, Bool)],
  lg : @option.LegendOption,
  series : @option.SeriesOption,
  series_index : Int,
) -> Unit {
  let mut i = 0
  while i < series.data.length() {
    let item = series.data[i]
    let name = match item.name {
      Some(n) => n
      None => ""
    }
    if name != "" {
      let color = @visual.palette_color(series_index + i)
      let selected = @option.LegendOption::is_selected(lg, name)
      items.push((color, name, selected))
    }
    i = i + 1
  }
}

///|
pub fn render_legend(opt : @option.ChartOption) -> Array[@graphic.Element] {
  let lg = match opt.legend {
    Some(l) if l.show => l
    _ => return []
  }
  let elems : Array[@graphic.Element] = []
  let items : Array[(String, String, Bool)] = []
  let mut ci = 0
  while ci < opt.series.length() {
    let s = opt.series[ci]
    match s.series_type {
      @option.Pie | @option.Funnel | @option.Sunburst =>
        append_data_legend_items(items, lg, s, ci)
      _ =>
        match s.name {
          Some(n) if n != "" => {
            let color = match s.color {
              Some(c) => c
              None => @visual.palette_color(ci)
            }
            let selected = @option.LegendOption::is_selected(lg, n)
            items.push((color, n, selected))
          }
          _ => ()
        }
    }
    ci = ci + 1
  }
  if items.length() == 0 {
    return elems
  }
  let item_w = 25.0
  let item_h = 14.0
  let icon_text_gap = 5.0
  let item_gap = 8.0
  let padding = 5.0
  let char_w = 7.0
  let mut total_w = 0.0
  let mut wi = 0
  while wi < items.length() {
    let (_, name, _) = items[wi]
    wi = wi + 1
    total_w = total_w +
      item_w +
      icon_text_gap +
      name.length().to_double() * char_w
    if wi < items.length() {
      total_w = total_w + item_gap
    }
  }
  let start_x = match lg.left {
    "center" => (opt.width - total_w) * 0.5
    "right" => opt.width - total_w - padding
    "left" => padding
    _ => legend_parse_pos(lg.left, padding)
  }
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
    let bottom_px = legend_parse_pos(lg.bottom, 15.0)
    opt.height - bottom_px - padding - item_h * 0.5
  }
  let icon_top = icon_cy - item_h * 0.5
  let mut cx = start_x
  let mut ii = 0
  while ii < items.length() {
    let (color, name, selected) = items[ii]
    ii = ii + 1
    let icon_color = if selected { color } else { "#d7dbe3" }
    let text_color = if selected { "#54555a" } else { "#a0a4ab" }
    elems.push(
      @graphic.Element::rect_colored(cx, icon_top, item_w, item_h, icon_color),
    )
    elems.push(
      @graphic.Element::text_colored(
        cx + item_w + icon_text_gap,
        icon_cy,
        name,
        @graphic.TextAnchor::start(),
        @graphic.TextBaseline::middle(),
        text_color,
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

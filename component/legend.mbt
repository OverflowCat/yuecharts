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
    let r = try? @string.parse_double(s)
    r.unwrap_or(fallback)
  }
}

///|
fn legend_has_name(
  items : Array[(String, String, Bool)],
  name : String,
) -> Bool {
  let mut i = 0
  while i < items.length() {
    let (_, item_name, _) = items[i]
    if item_name == name {
      return true
    }
    i += 1
  }
  false
}

///|
/// Radar default uses colorBy:'data', so palette assignment for legend items must
/// advance across all radar data items in chart order.
/// <=> echarts/src/chart/radar/RadarSeries.ts:defaultOption
/// <=> echarts/src/visual/style.ts:dataColorPaletteTask
fn legend_radar_palette_index(
  opt : @option.ChartOption,
  series_index : Int,
  data_index : Int,
) -> Int {
  let mut ordinal = 0
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    if series.series_type == @option.SeriesType::Radar {
      if si == series_index {
        return ordinal + data_index
      }
      ordinal = ordinal + series.data.length()
    }
    si += 1
  }
  ordinal + data_index
}

///|
fn legend_data_item_color(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
  item : @option.DataItem,
  series_index : Int,
  data_index : Int,
) -> String {
  let palette_index = if series.series_type == @option.SeriesType::Radar {
    legend_radar_palette_index(opt, series_index, data_index)
  } else {
    series_index + data_index
  }
  match item.item_style {
    Some(style) =>
      match style.color {
        Some(color) => color
        None =>
          match style.area_color {
            Some(color) => color
            None =>
              match series.color {
                Some(color) => color
                None => @visual.palette_color(palette_index)
              }
          }
      }
    None =>
      match series.color {
        Some(color) => color
        None => @visual.palette_color(palette_index)
      }
  }
}

///|
fn legend_find_data_color(opt : @option.ChartOption, name : String) -> String {
  for si, _ in opt.series {
    let series = opt.series[si]
    match series.series_type {
      @option.SeriesType::Pie
      | @option.SeriesType::Funnel
      | @option.SeriesType::Sunburst
      | @option.SeriesType::Chord
      | @option.SeriesType::Radar =>
        for di, _ in series.data {
          let item = series.data[di]
          if item.name.unwrap_or("") == name {
            return legend_data_item_color(opt, series, item, si, di)
          }
        }
      _ =>
        if series.name.unwrap_or("") == name {
          return series.color.unwrap_or(@visual.palette_color(si))
        }
    }
  }
  @visual.palette_color(0)
}

///|
fn append_data_legend_items(
  items : Array[(String, String, Bool)],
  lg : @option.LegendOption,
  opt : @option.ChartOption,
  series : @option.SeriesOption,
  series_index : Int,
) -> Unit {
  for i, _ in series.data {
    let item = series.data[i]
    let name = item.name.unwrap_or("")
    if name != "" && !legend_has_name(items, name) {
      let color = legend_data_item_color(opt, series, item, series_index, i)
      let selected = @option.LegendOption::is_selected(lg, name)
      items.push((color, name, selected))
    }
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
  if lg.data.length() > 0 {
    let mut di = 0
    while di < lg.data.length() {
      let name = lg.data[di]
      if name != "" && !legend_has_name(items, name) {
        let color = legend_find_data_color(opt, name)
        let selected = @option.LegendOption::is_selected(lg, name)
        items.push((color, name, selected))
      }
      di += 1
    }
  } else {
    let mut ci = 0
    while ci < opt.series.length() {
      let s = opt.series[ci]
      match s.series_type {
        @option.SeriesType::Pie
        | @option.SeriesType::Funnel
        | @option.SeriesType::Sunburst
        | @option.SeriesType::Chord
        | @option.SeriesType::Radar =>
          append_data_legend_items(items, lg, opt, s, ci)
        _ =>
          match s.name {
            Some(n) if n != "" && !legend_has_name(items, n) => {
              let color = s.color.unwrap_or(@visual.palette_color(ci))
              let selected = @option.LegendOption::is_selected(lg, n)
              items.push((color, n, selected))
            }
            _ => ()
          }
      }
      ci += 1
    }
  }
  if items.length() == 0 {
    return elems
  }
  let item_w = 25.0
  let item_h = 14.0
  let icon_text_gap = 5.0
  let padding = 5.0
  let char_w = 7.0
  let orient = lg.orient
  if orient == "vertical" {
    let item_gap = 10.0
    let mut max_name_w = 0.0
    for wi, _ in items {
      let (_, name, _) = items[wi]
      let name_w = name.length().to_double() * char_w
      if name_w > max_name_w {
        max_name_w = name_w
      }
    }
    let total_h = if items.length() > 0 {
      items.length().to_double() * item_h +
      (items.length() - 1).to_double() * item_gap
    } else {
      0.0
    }
    let total_w = item_w + icon_text_gap + max_name_w
    let start_x = match lg.left {
      "center" => (opt.width - total_w) * 0.5
      "right" => opt.width - total_w - padding
      "left" => padding
      _ => legend_parse_pos(lg.left, padding)
    }
    let icon_top = if lg.top != "" && lg.top != "auto" {
      match lg.top {
        "top" => padding
        "middle" | "center" => (opt.height - total_h) * 0.5
        "bottom" => opt.height - padding - total_h
        _ => legend_parse_pos(lg.top, padding)
      }
    } else {
      let bottom_px = legend_parse_pos(lg.bottom, 15.0)
      opt.height - bottom_px - padding - total_h
    }
    for ii, _ in items {
      let (color, name, selected) = items[ii]
      let icon_color = if selected { color } else { "#d7dbe3" }
      let text_color = if selected { "#54555a" } else { "#a0a4ab" }
      let item_y = icon_top + ii.to_double() * (item_h + item_gap)
      elems.push(
        @graphic.Element::rect_colored(
          start_x, item_y, item_w, item_h, icon_color,
        ),
      )
      elems.push(
        @graphic.Element::text_colored(
          start_x + item_w + icon_text_gap,
          item_y + item_h * 0.5,
          name,
          @graphic.TextAnchor::Start,
          @graphic.TextBaseline::Middle,
          text_color,
        ),
      )
    }
  } else {
    let item_gap = 8.0
    let mut total_w = 0.0
    let mut wi = 0
    while wi < items.length() {
      let (_, name, _) = items[wi]
      total_w = total_w +
        item_w +
        icon_text_gap +
        name.length().to_double() * char_w
      if wi < items.length() {
        total_w = total_w + item_gap
      }
      wi += 1
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
          @graphic.TextAnchor::Start,
          @graphic.TextBaseline::Middle,
          text_color,
        ),
      )
      cx = cx +
        item_w +
        icon_text_gap +
        name.length().to_double() * char_w +
        item_gap
      ii += 1
    }
  }
  elems
}

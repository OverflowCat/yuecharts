// Corresponds to: echarts/src/chart/treemap/TreemapSeries.ts
//                  echarts/src/chart/treemap/treemapLayout.ts
//                  echarts/src/chart/treemap/TreemapView.ts

///|
priv struct TreemapRect {
  x : Double
  y : Double
  width : Double
  height : Double
}

///|
fn treemap_complete_tree_value(item : @option.DataItem) -> Double {
  let mut child_sum = 0.0
  let mut i = 0
  while i < item.children.length() {
    child_sum = child_sum + treemap_complete_tree_value(item.children[i])
    i += 1
  }
  let own_value = match item.value {
    @option.Num(n) => n
    @option.Vec(arr) => if arr.length() > 0 { arr[0] } else { child_sum }
    @option.DateValue(_, n) => n
    @option.Null => child_sum
  }
  if own_value < 0.0 {
    0.0
  } else {
    own_value
  }
}

///|
fn worst_row_score(
  row_areas : Array[Double],
  row_area : Double,
  row_fixed_length : Double,
  ratio : Double,
) -> Double {
  let mut area_max = 0.0
  let mut area_min = 1.0e300
  let mut i = 0
  while i < row_areas.length() {
    let area = row_areas[i]
    if area > 0.0 {
      if area > area_max {
        area_max = area
      }
      if area < area_min {
        area_min = area
      }
    }
    i += 1
  }
  let square_area = row_area * row_area
  let f = row_fixed_length * row_fixed_length * ratio
  if square_area <= 0.0 || area_min <= 0.0 {
    1.0e300
  } else {
    let a = f * area_max / square_area
    let b = square_area / (f * area_min)
    if a > b {
      a
    } else {
      b
    }
  }
}

///|
fn position_row(
  rects : Array[TreemapRect],
  row_indices : Array[Int],
  areas : Array[Double],
  row_area : Double,
  row_fixed_length : Double,
  rect : TreemapRect,
  flush : Bool,
) -> TreemapRect {
  let horizontal = row_fixed_length == rect.width
  let mut last = if horizontal { rect.x } else { rect.y }
  let mut row_other_length = if row_fixed_length > 0.0 {
    row_area / row_fixed_length
  } else {
    0.0
  }
  if flush ||
    row_other_length > (if horizontal { rect.height } else { rect.width }) {
    row_other_length = if horizontal { rect.height } else { rect.width }
  }
  let mut i = 0
  while i < row_indices.length() {
    let idx = row_indices[i]
    let step = if row_other_length > 0.0 {
      areas[idx] / row_other_length
    } else {
      0.0
    }
    let remain = if horizontal {
      rect.x + rect.width - last
    } else {
      rect.y + rect.height - last
    }
    let mod_len = if i == row_indices.length() - 1 || remain < step {
      remain
    } else {
      step
    }
    rects[idx] = if horizontal {
      { x: last, y: rect.y, width: mod_len, height: row_other_length }
    } else {
      { x: rect.x, y: last, width: row_other_length, height: mod_len }
    }
    last = last + mod_len
    i += 1
  }
  if horizontal {
    {
      x: rect.x,
      y: rect.y + row_other_length,
      width: rect.width,
      height: rect.height - row_other_length,
    }
  } else {
    {
      x: rect.x + row_other_length,
      y: rect.y,
      width: rect.width - row_other_length,
      height: rect.height,
    }
  }
}

///|
fn layout_squarify(
  values : Array[Double],
  rect : TreemapRect,
) -> Array[TreemapRect] {
  let rects : Array[TreemapRect] = []
  let mut init_i = 0
  while init_i < values.length() {
    rects.push({ x: rect.x, y: rect.y, width: 0.0, height: 0.0 })
    init_i = init_i + 1
  }
  let ratio = 1.61803398875
  let mut remaining = rect
  let mut row_indices : Array[Int] = []
  let mut row_areas : Array[Double] = []
  let mut row_area = 0.0
  let mut best = 1.0e300
  let mut i = 0
  while i < values.length() {
    let area = values[i]
    row_indices.push(i)
    row_areas.push(area)
    row_area = row_area + area
    let row_fixed_length = if remaining.width < remaining.height {
      remaining.width
    } else {
      remaining.height
    }
    let score = worst_row_score(row_areas, row_area, row_fixed_length, ratio)
    if score <= best {
      best = score
      i += 1
    } else {
      let last_index = row_indices.length() - 1
      row_area = row_area - row_areas[last_index]
      let _ = row_indices.pop()
      let _ = row_areas.pop()
      let fixed_length = if remaining.width < remaining.height {
        remaining.width
      } else {
        remaining.height
      }
      remaining = position_row(
        rects, row_indices, values, row_area, fixed_length, remaining, false,
      )
      row_indices = []
      row_areas = []
      row_area = 0.0
      best = 1.0e300
    }
  }
  if row_indices.length() > 0 {
    let fixed_length = if remaining.width < remaining.height {
      remaining.width
    } else {
      remaining.height
    }
    let _ = position_row(
      rects, row_indices, values, row_area, fixed_length, remaining, true,
    )
  }
  rects
}

///|
fn sort_children_desc(
  children : Array[@option.DataItem],
) -> Array[@option.DataItem] {
  let sorted : Array[@option.DataItem] = []
  let mut i = 0
  while i < children.length() {
    sorted.push(children[i])
    i += 1
  }
  let mut a = 0
  while a < sorted.length() {
    let mut b = a
    while b > 0 &&
          treemap_complete_tree_value(sorted[b - 1]) <
          treemap_complete_tree_value(sorted[b]) {
      let tmp = sorted[b - 1]
      sorted[b - 1] = sorted[b]
      sorted[b] = tmp
      b = b - 1
    }
    a = a + 1
  }
  sorted
}

///|
fn treemap_item_style_for_depth(
  series : @option.SeriesOption,
  depth : Int,
) -> @option.TreemapItemStyleOption? {
  if depth < series.treemap_levels.length() {
    match series.treemap_levels[depth].item_style {
      Some(style) => Some(style)
      None => series.treemap_item_style
    }
  } else {
    series.treemap_item_style
  }
}

///|
fn treemap_parent_fill_color(
  series : @option.SeriesOption,
  depth : Int,
) -> String {
  match treemap_item_style_for_depth(series, depth) {
    Some(style) =>
      match style.border_color {
        Some(color) => color
        None => "#ffffff"
      }
    None => "#ffffff"
  }
}

///|
fn treemap_leaf_fill_color(
  series : @option.SeriesOption,
  depth : Int,
  color_seed : Int,
  ri : Int,
  value : Double,
  sibling_min : Double,
  sibling_max : Double,
) -> String {
  let fallback = @visual.palette_color(color_seed + ri)
  match treemap_item_style_for_depth(series, depth) {
    Some(style) =>
      match style.color {
        Some(color) =>
          treemap_apply_level_visuals(
            series, depth, color, value, sibling_min, sibling_max,
          )
        None =>
          treemap_apply_level_visuals(
            series, depth, fallback, value, sibling_min, sibling_max,
          )
      }
    None =>
      treemap_apply_level_visuals(
        series, depth, fallback, value, sibling_min, sibling_max,
      )
  }
}

///|
fn treemap_apply_level_visuals(
  series : @option.SeriesOption,
  depth : Int,
  color : String,
  value : Double,
  sibling_min : Double,
  sibling_max : Double,
) -> String {
  let _ = series
  let _ = value
  let _ = sibling_min
  let _ = sibling_max
  let lightness = if depth > 0 { Some(0.6) } else { None }
  let alpha = None
  treemap_modify_color(color, lightness, alpha)
}

///|
fn treemap_modify_color(
  color : String,
  lightness : Double?,
  alpha : Double?,
) -> String {
  let parsed = match @graphic.Color::from_string(color) {
    Some(c) => c
    None => return color
  }
  let (h, s, l) = treemap_rgb_to_hsl(parsed.r, parsed.g, parsed.b)
  let final_l = match lightness {
    Some(v) => v
    None => l
  }
  let (rgb_r, rgb_g, rgb_b) = treemap_hsl_to_rgb(h, s, final_l)
  let final_alpha = match alpha {
    Some(v) =>
      if v <= 1.0 {
        (v * 255.0).round().to_int()
      } else {
        v.round().to_int()
      }
    None => parsed.a
  }
  if final_alpha >= 255 {
    "#\{treemap_hex2(rgb_r)}\{treemap_hex2(rgb_g)}\{treemap_hex2(rgb_b)}"
  } else {
    "rgba(\{rgb_r},\{rgb_g},\{rgb_b},\{@graphic.format_opacity(final_alpha.to_double() / 255.0)})"
  }
}

///|
fn treemap_rgb_to_hsl(r : Int, g : Int, b : Int) -> (Double, Double, Double) {
  let rf = r.to_double() / 255.0
  let gf = g.to_double() / 255.0
  let bf = b.to_double() / 255.0
  let max = if rf > gf {
    if rf > bf {
      rf
    } else {
      bf
    }
  } else if gf > bf {
    gf
  } else {
    bf
  }
  let min = if rf < gf {
    if rf < bf {
      rf
    } else {
      bf
    }
  } else if gf < bf {
    gf
  } else {
    bf
  }
  let l = (max + min) / 2.0
  if max == min {
    (0.0, 0.0, l)
  } else {
    let d = max - min
    let s = if l > 0.5 { d / (2.0 - max - min) } else { d / (max + min) }
    let mut h = if max == rf {
      (gf - bf) / d
    } else if max == gf {
      (bf - rf) / d + 2.0
    } else {
      (rf - gf) / d + 4.0
    }
    if max == rf && gf < bf {
      h = h + 6.0
    }
    (h / 6.0, s, l)
  }
}

///|
fn treemap_hsl_to_rgb(h : Double, s : Double, l : Double) -> (Int, Int, Int) {
  if s <= 0.0 {
    let v = (l * 255.0).round().to_int()
    (v, v, v)
  } else {
    let q = if l < 0.5 { l * (1.0 + s) } else { l + s - l * s }
    let p = 2.0 * l - q
    let r = treemap_hue_to_rgb(p, q, h + 1.0 / 3.0)
    let g = treemap_hue_to_rgb(p, q, h)
    let b = treemap_hue_to_rgb(p, q, h - 1.0 / 3.0)
    (
      (r * 255.0).round().to_int(),
      (g * 255.0).round().to_int(),
      (b * 255.0).round().to_int(),
    )
  }
}

///|
fn treemap_hue_to_rgb(p : Double, q : Double, t_in : Double) -> Double {
  let mut t = t_in
  if t < 0.0 {
    t = t + 1.0
  }
  if t > 1.0 {
    t = t - 1.0
  }
  if t < 1.0 / 6.0 {
    p + (q - p) * 6.0 * t
  } else if t < 1.0 / 2.0 {
    q
  } else if t < 2.0 / 3.0 {
    p + (q - p) * (2.0 / 3.0 - t) * 6.0
  } else {
    p
  }
}

///|
fn treemap_hex2(v : Int) -> String {
  let n = if v < 0 { 0 } else if v > 255 { 255 } else { v }
  let hi = n / 16
  let lo = n % 16
  "\{treemap_hex_digit(hi)}\{treemap_hex_digit(lo)}"
}

///|
fn treemap_hex_digit(n : Int) -> String {
  match n {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "a"
    11 => "b"
    12 => "c"
    13 => "d"
    14 => "e"
    _ => "f"
  }
}

///|
fn treemap_upper_label_height(series : @option.SeriesOption) -> Double {
  match series.treemap_upper_label {
    Some(upper_label) => if upper_label.show { upper_label.height } else { 0.0 }
    None => 0.0
  }
}

///|
fn render_treemap_children(
  series : @option.SeriesOption,
  elems : Array[@graphic.Element],
  children : Array[@option.DataItem],
  rect : TreemapRect,
  depth : Int,
  color_seed : Int,
) -> Unit {
  if children.length() == 0 || rect.width <= 1.0 || rect.height <= 1.0 {
    return
  }
  let sorted = sort_children_desc(children)
  let areas : Array[Double] = []
  let total_area = rect.width * rect.height
  let mut value_sum = 0.0
  let mut i = 0
  while i < sorted.length() {
    value_sum = value_sum + treemap_complete_tree_value(sorted[i])
    i += 1
  }
  if value_sum <= 0.0 {
    return
  }
  i = 0
  while i < sorted.length() {
    areas.push(treemap_complete_tree_value(sorted[i]) / value_sum * total_area)
    i += 1
  }
  let rects = layout_squarify(areas, rect)
  let upper_label_height = treemap_upper_label_height(series)
  let mut sibling_min = 1.0e300
  let mut sibling_max = -1.0e300
  let sibling_values : Array[Double] = []
  let mut vi = 0
  while vi < sorted.length() {
    let v = treemap_complete_tree_value(sorted[vi])
    sibling_values.push(v)
    if v < sibling_min {
      sibling_min = v
    }
    if v > sibling_max {
      sibling_max = v
    }
    vi += 1
  }
  let mut ri = 0
  while ri < sorted.length() {
    let node = sorted[ri]
    let child_rect = rects[ri]
    let node_value = sibling_values[ri]
    if child_rect.width > 0.5 && child_rect.height > 0.5 {
      let label = match node.name {
        Some(s) => s
        None => ""
      }
      let is_parent = node.children.length() > 0
      if is_parent {
        let parent_fill = treemap_parent_fill_color(series, depth)
        elems.push(
          @graphic.Element::rect_colored(
            child_rect.x,
            child_rect.y,
            child_rect.width,
            child_rect.height,
            parent_fill,
          ),
        )
        elems.push(
          @graphic.Element::rect_outlined(
            child_rect.x,
            child_rect.y,
            child_rect.width,
            child_rect.height,
            "#ffffff",
            1.0,
          ),
        )
        let content_rect : TreemapRect = if upper_label_height > 0.0 {
          {
            x: child_rect.x + 1.0,
            y: child_rect.y + upper_label_height,
            width: child_rect.width - 2.0,
            height: child_rect.height - upper_label_height - 1.0,
          }
        } else {
          {
            x: child_rect.x + 1.0,
            y: child_rect.y + 1.0,
            width: child_rect.width - 2.0,
            height: child_rect.height - 2.0,
          }
        }
        if content_rect.width > 1.0 && content_rect.height > 1.0 {
          let content_fill = treemap_leaf_fill_color(
            series, depth, color_seed, ri, node_value, sibling_min, sibling_max,
          )
          elems.push(
            @graphic.Element::rect_colored(
              content_rect.x,
              content_rect.y,
              content_rect.width,
              content_rect.height,
              content_fill,
            ),
          )
        }
        if label != "" &&
          upper_label_height > 0.0 &&
          child_rect.height >= upper_label_height + 6.0 {
          elems.push(
            @graphic.Element::text_colored(
              child_rect.x + 5.0,
              child_rect.y + upper_label_height / 2.0,
              label,
              @graphic.TextAnchor::Start,
              @graphic.TextBaseline::Middle,
              "#333333",
            ),
          )
        }
        if label != "" &&
          upper_label_height <= 0.0 &&
          content_rect.width >= 48.0 &&
          content_rect.height >= 22.0 {
          elems.push(
            @graphic.Element::text_colored(
              content_rect.x + 5.0,
              content_rect.y + 16.0,
              label,
              @graphic.TextAnchor::Start,
              @graphic.TextBaseline::Middle,
              "#ffffff",
            ),
          )
        }
        if content_rect.width > 1.0 && content_rect.height > 1.0 {
          render_treemap_children(
            series,
            elems,
            node.children,
            content_rect,
            depth + 1,
            color_seed + ri,
          )
        }
      } else {
        let fill_color = treemap_leaf_fill_color(
          series, depth, color_seed, ri, node_value, sibling_min, sibling_max,
        )
        elems.push(
          @graphic.Element::rect_colored(
            child_rect.x,
            child_rect.y,
            child_rect.width,
            child_rect.height,
            fill_color,
          ),
        )
        elems.push(
          @graphic.Element::rect_outlined(
            child_rect.x,
            child_rect.y,
            child_rect.width,
            child_rect.height,
            "#ffffff",
            1.0,
          ),
        )
        if label != "" && child_rect.width >= 48.0 && child_rect.height >= 22.0 {
          elems.push(
            @graphic.Element::text_colored(
              child_rect.x + 6.0,
              child_rect.y + 16.0,
              label,
              @graphic.TextAnchor::Start,
              @graphic.TextBaseline::Middle,
              "#ffffff",
            ),
          )
        }
      }
    }
    ri += 1
  }
}

///|
pub fn render_treemaps(
  opt : @option.ChartOption,
  _coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut color_idx = 0
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si += 1
    match series.series_type {
      Treemap => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let series_elems = render_treemap_series(
      series,
      color_idx,
      opt.width,
      opt.height,
    )
    let mut i = 0
    while i < series_elems.length() {
      elems.push(series_elems[i])
      i += 1
    }
    color_idx = color_idx + 1
  }
  elems
}

///|
pub fn render_treemap_series(
  series : @option.SeriesOption,
  series_index : Int,
  chart_width : Double,
  chart_height : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  if series.data.length() == 0 {
    return elems
  }
  let margin_left = 20.0
  let margin_right = 20.0
  let margin_top = 50.0
  let margin_bottom = 50.0
  let root_rect : TreemapRect = {
    x: margin_left,
    y: margin_top,
    width: chart_width - margin_left - margin_right,
    height: chart_height - margin_top - margin_bottom,
  }
  render_treemap_children(
    series,
    elems,
    series.data,
    root_rect,
    0,
    series_index,
  )
  elems
}

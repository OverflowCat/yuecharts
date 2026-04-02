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
fn render_treemap_children(
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
  let mut ri = 0
  while ri < sorted.length() {
    let node = sorted[ri]
    let child_rect = rects[ri]
    let fill_color = @visual.palette_color(color_seed + ri + depth * 3)
    if child_rect.width > 0.5 && child_rect.height > 0.5 {
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
      let label = match node.name {
        Some(s) => s
        None => ""
      }
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
      if node.children.length() > 0 {
        render_treemap_children(
          elems,
          node.children,
          {
            x: child_rect.x + 1.0,
            y: child_rect.y + 1.0,
            width: child_rect.width - 2.0,
            height: child_rect.height - 2.0,
          },
          depth + 1,
          color_seed + ri + 1,
        )
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
  render_treemap_children(elems, series.data, root_rect, 0, series_index)
  elems
}

/// <=> echarts/src/chart/sunburst/SunburstView.ts
/// <=> echarts/src/chart/sunburst/sunburstLayout.ts
/// <=> echarts/src/chart/sunburst/SunburstSeries.ts

///|
fn data_item_value(item : @option.DataItem) -> Double {
  let derived = match item.value {
    @option.Num(n) => n
    @option.Vec(arr) => if arr.length() > 0 { arr[0] } else { 0.0 }
    @option.DateValue(_, n) => n
    @option.Null => {
      let mut sum = 0.0

      for i, _ in item.children {
        sum = sum + complete_tree_value(item.children[i])
      }
      sum
    }
  }
  if derived < 0.0 {
    0.0
  } else {
    derived
  }
}

///|
fn complete_tree_value(item : @option.DataItem) -> Double {
  let mut child_sum = 0.0

  for i, _ in item.children {
    child_sum = child_sum + complete_tree_value(item.children[i])
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
fn tree_height(item : @option.DataItem) -> Int {
  if item.children.length() == 0 {
    return 1
  }
  let mut max_child = 0

  for i, _ in item.children {
    let h = tree_height(item.children[i])
    if h > max_child {
      max_child = h
    }
  }
  max_child + 1
}

///|
fn abs_double(v : Double) -> Double {
  if v < 0.0 {
    -v
  } else {
    v
  }
}

///|
fn sector_path(
  cx : Double,
  cy : Double,
  r0 : Double,
  r : Double,
  a0 : Double,
  a1 : Double,
  clockwise : Bool,
) -> String {
  let outer_x0 = cx + r * @math.cos(a0)
  let outer_y0 = cy + r * @math.sin(a0)
  let outer_x1 = cx + r * @math.cos(a1)
  let outer_y1 = cy + r * @math.sin(a1)
  let span = abs_double(a1 - a0)
  let large_arc = if span > @math.PI { 1 } else { 0 }
  let outer_sweep = if clockwise { 1 } else { 0 }
  let inner_sweep = if clockwise { 0 } else { 1 }
  if r0 <= 0.5 {
    "M \{r4(cx)} \{r4(cy)} L \{r4(outer_x0)} \{r4(outer_y0)} A \{r4(r)} \{r4(r)} 0 \{large_arc} \{outer_sweep} \{r4(outer_x1)} \{r4(outer_y1)} Z"
  } else {
    let inner_x0 = cx + r0 * @math.cos(a0)
    let inner_y0 = cy + r0 * @math.sin(a0)
    let inner_x1 = cx + r0 * @math.cos(a1)
    let inner_y1 = cy + r0 * @math.sin(a1)
    "M \{r4(outer_x0)} \{r4(outer_y0)} A \{r4(r)} \{r4(r)} 0 \{large_arc} \{outer_sweep} \{r4(outer_x1)} \{r4(outer_y1)} L \{r4(inner_x1)} \{r4(inner_y1)} A \{r4(r0)} \{r4(r0)} 0 \{large_arc} \{inner_sweep} \{r4(inner_x0)} \{r4(inner_y0)} Z"
  }
}

///|
fn sorted_indices_desc(values : Array[Double]) -> Array[Int] {
  let indices : Array[Int] = []
  let mut i = 0
  while i < values.length() {
    indices.push(i)
    i += 1
  }
  let mut a = 0
  while a < indices.length() {
    let mut b = a
    while b > 0 && values[indices[b - 1]] < values[indices[b]] {
      let tmp = indices[b - 1]
      indices[b - 1] = indices[b]
      indices[b] = tmp
      b = b - 1
    }
    a += 1
  }
  indices
}

///|
fn sunburst_color_at_ratio(colors : Array[String], ratio : Double) -> String {
  if colors.length() == 0 {
    return "#cccccc"
  }
  if colors.length() == 1 {
    return colors[0]
  }
  let t = if ratio < 0.0 { 0.0 } else if ratio > 1.0 { 1.0 } else { ratio }
  let total = colors.length() - 1
  let scaled = t * total.to_double()
  let index = scaled.floor().to_int()
  let next_index = if index + 1 < colors.length() { index + 1 } else { index }
  let local_t = scaled - index.to_double()
  let start_color = @graphic.Color::from_string(colors[index]).unwrap_or(
    @graphic.black,
  )
  let end_color = @graphic.Color::from_string(colors[next_index]).unwrap_or(
    start_color,
  )
  @graphic.Color::lerp(start_color, end_color, local_t).to_svg()
}

///|
fn sunburst_has_any_highlighted(nodes : Array[@option.DataItem]) -> Bool {
  for node in nodes {
    if node.highlighted == Some(true) {
      return true
    }
    if node.children.length() > 0 && sunburst_has_any_highlighted(node.children) {
      return true
    }
  }
  false
}

///|
fn render_sunburst_node(
  elems : Array[@graphic.Element],
  node : @option.DataItem,
  depth : Int,
  start_angle : Double,
  sweep_angle : Double,
  min_angle : Double,
  top_color_idx : Int,
  cx : Double,
  cy : Double,
  inner_radius : Double,
  radius_per_level : Double,
  clockwise : Bool,
  vm_colors : Array[String],
  vm_min : Double,
  vm_max : Double,
  any_highlighted : Bool,
) -> Unit {
  let r0 = inner_radius + depth.to_double() * radius_per_level
  let r1 = r0 + radius_per_level
  // Determine fill color: itemStyle override > visualMap > palette
  let node_value = complete_tree_value(node)
  let fill_color = if vm_colors.length() > 0 && vm_max > vm_min {
    // visualMap overrides itemStyle.color (matches ECharts visual processor order)
    let ratio = (node_value - vm_min) / (vm_max - vm_min)
    sunburst_color_at_ratio(vm_colors, ratio)
  } else {
    match node.item_style {
      Some(style) => style.color.unwrap_or(@visual.palette_color(top_color_idx))
      None => @visual.palette_color(top_color_idx)
    }
  }
  let opacity = {
    let o = 0.95 - depth.to_double() * 0.14
    if o < 0.38 {
      0.38
    } else {
      o
    }
  }
  let end_angle = if clockwise {
    start_angle + sweep_angle
  } else {
    start_angle - sweep_angle
  }
  let path_d = sector_path(cx, cy, r0, r1, start_angle, end_angle, clockwise)
  let item_highlighted = node.highlighted == Some(true)
  let emphasis_fill = if item_highlighted {
    @visual.lift_hex_color(fill_color)
  } else {
    fill_color
  }
  let emphasis_style : @graphic.DisplayStateStyle = {
    fill: Some(emphasis_fill),
    stroke: None,
    line_width: None,
    stroke_no_scale: false,
  }
  let blur_style : @graphic.DisplayStateStyle = {
    fill: None,
    stroke: None,
    line_width: None,
    stroke_no_scale: false,
  }
  let sector_elem = @graphic.Element::path_fill_stroke(
    path_d, fill_color, "#ffffff", 1.0, opacity,
  )
  elems.push(
    if any_highlighted {
      sector_elem
      .with_emphasis_style(emphasis_style)
      .with_blur_style(blur_style)
    } else {
      sector_elem
    },
  )

  let label = match node.name {
    Some(s) => s
    None => ""
  }
  if label != "" && sweep_angle >= 0.28 {
    let mid = if clockwise {
      start_angle + sweep_angle / 2.0
    } else {
      start_angle - sweep_angle / 2.0
    }
    let label_r = (r0 + r1) / 2.0
    let lx = cx + label_r * @math.cos(mid)
    let ly = cy + label_r * @math.sin(mid)
    elems.push(
      @graphic.Element::text_colored(
        lx,
        ly,
        label,
        @graphic.TextAnchor::Middle,
        @graphic.TextBaseline::Middle,
        "#ffffff",
      ),
    )
  }

  if node.children.length() == 0 {
    return
  }

  let child_values : Array[Double] = []

  for i, _ in node.children {
    let v = complete_tree_value(node.children[i])
    child_values.push(v)
  }
  // Use the parent node's own declared value as denominator, not sum of children.
  // This matches ECharts sunburstLayout.ts: each node's angle = node.getValue() * unitRadian,
  // so children only fill the portion proportional to their value vs parent's value.
  let total = {
    let pv = data_item_value(node)
    if pv > 0.0 {
      pv
    } else {
      let mut s = 0.0

      for fi, _ in child_values {
        s = s + child_values[fi]
      }
      s
    }
  }
  let order = sorted_indices_desc(child_values)
  let mut child_angle = start_angle
  let child_min_angle = if min_angle * node.children.length().to_double() >
    sweep_angle {
    0.0
  } else {
    min_angle
  }
  let fallback_span = if node.children.length() > 0 {
    sweep_angle / node.children.length().to_double()
  } else {
    0.0
  }
  let mut oi = 0
  while oi < order.length() {
    let idx = order[oi]
    let child = node.children[idx]
    let child_value = child_values[idx]
    let child_span = if total > 0.0 {
      let s = sweep_angle * child_value / total
      if s < child_min_angle {
        child_min_angle
      } else {
        s
      }
    } else {
      fallback_span
    }
    if child_span > 0.0 {
      render_sunburst_node(
        elems,
        child,
        depth + 1,
        child_angle,
        child_span,
        min_angle,
        top_color_idx,
        cx,
        cy,
        inner_radius,
        radius_per_level,
        clockwise,
        vm_colors,
        vm_min,
        vm_max,
        any_highlighted,
      )
      child_angle = if clockwise {
        child_angle + child_span
      } else {
        child_angle - child_span
      }
    }
    oi = oi + 1
  }
}

///|
pub fn render_sunbursts(
  opt : @option.ChartOption,
  _coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  // Find first continuous visualMap for sunburst color mapping
  let vm_colors : Array[String] = []
  let mut vm_min = 0.0
  let mut vm_max = 0.0
  for vm in opt.visual_map {
    let colors = vm.in_range.color
    if colors.length() >= 2 {
      vm_colors.append(colors)
      vm_min = vm.min
      vm_max = vm.max
      break
    }
  }
  let mut color_idx = 0

  for si, _ in opt.series {
    let series = opt.series[si]
    match series.series_type {
      Sunburst => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let series_elems = render_sunburst_series(
      series,
      color_idx,
      opt.width,
      opt.height,
      vm_colors,
      vm_min,
      vm_max,
    )

    for i, _ in series_elems {
      elems.push(series_elems[i])
    }
    color_idx = color_idx + 1
  }
  elems
}

///|
pub fn render_sunburst_series(
  series : @option.SeriesOption,
  series_index : Int,
  chart_width : Double,
  chart_height : Double,
  vm_colors : Array[String],
  vm_min : Double,
  vm_max : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  if series.data.length() == 0 {
    return elems
  }
  let any_highlighted = sunburst_has_any_highlighted(series.data)

  let cx = if series.center.length() >= 1 {
    parse_pct_or_px(series.center[0], chart_width)
  } else {
    chart_width * 0.5
  }
  let cy = if series.center.length() >= 2 {
    parse_pct_or_px(series.center[1], chart_height)
  } else {
    chart_height * 0.5
  }
  let ref_r = (if chart_width < chart_height {
      chart_width
    } else {
      chart_height
    }) /
    2.0
  let r_inner = if series.radius.length() >= 1 {
    parse_pct_or_px(series.radius[0], ref_r)
  } else {
    0.0
  }
  let r_outer = if series.radius.length() >= 2 {
    parse_pct_or_px(series.radius[1], ref_r)
  } else if series.radius.length() == 1 {
    parse_pct_or_px(series.radius[0], ref_r)
  } else {
    ref_r * 0.75
  }

  let mut total = 0.0
  let mut max_height = 0
  let root_values : Array[Double] = []

  for i, _ in series.data {
    let node = series.data[i]
    let v = data_item_value(node)
    root_values.push(v)
    total = total + v
    let h = tree_height(node)
    if h > max_height {
      max_height = h
    }
  }
  if max_height <= 0 {
    return elems
  }

  let start_angle = -(series.start_angle * @math.PI / 180.0)
  let min_angle = series.min_angle * @math.PI / 180.0
  let radius_per_level = (r_outer - r_inner) / max_height.to_double()
  let order = sorted_indices_desc(root_values)
  let mut current_angle = start_angle
  let full_span = @math.PI * 2.0
  let fallback_span = full_span / series.data.length().to_double()
  let root_min_angle = if min_angle * series.data.length().to_double() >
    full_span {
    0.0
  } else {
    min_angle
  }
  let mut oi = 0
  while oi < order.length() {
    let idx = order[oi]
    let node = series.data[idx]
    let v = root_values[idx]
    let sweep = if total > 0.0 {
      let s = full_span * v / total
      if s < root_min_angle {
        root_min_angle
      } else {
        s
      }
    } else {
      fallback_span
    }
    if sweep > 0.0 {
      render_sunburst_node(
        elems,
        node,
        0,
        current_angle,
        sweep,
        min_angle,
        series_index + oi,
        cx,
        cy,
        r_inner,
        radius_per_level,
        series.clockwise,
        vm_colors,
        vm_min,
        vm_max,
        any_highlighted,
      )
      current_angle = if series.clockwise {
        current_angle + sweep
      } else {
        current_angle - sweep
      }
    }
    oi = oi + 1
  }

  elems
}

// Corresponds to: echarts/src/chart/chord/ChordSeries.ts
//                  echarts/src/chart/chord/chordLayout.ts
//                  echarts/src/chart/chord/ChordPiece.ts
//                  echarts/src/chart/chord/ChordEdge.ts
//                  echarts/src/chart/chord/ChordView.ts

///|
priv struct ChordNode {
  name : String
  item : @option.DataItem
  mut angle : Double
  mut ratio : Double
  mut start_angle : Double
  mut end_angle : Double
}

///|
priv struct ChordEdgeLayout {
  item : @option.DataItem
  source_index : Int
  target_index : Int
  mut value : Double
  mut s_start_angle : Double
  mut s_end_angle : Double
  mut t_start_angle : Double
  mut t_end_angle : Double
}

///|
fn chord_r4(v : Double) -> String {
  let rounded = (v * 10000.0).round() / 10000.0
  if rounded == rounded.to_int().to_double() {
    rounded.to_int().to_string()
  } else {
    rounded.to_string()
  }
}

///|
fn chord_abs(v : Double) -> Double {
  if v < 0.0 {
    -v
  } else {
    v
  }
}

///|
fn chord_min(a : Double, b : Double) -> Double {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn chord_max(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn chord_parse_pct_or_px(s : String, reference : Double) -> Double {
  if s.has_suffix("%") {
    let inner = s[:s.length() - 1]
    let parsed = try? @strconv.parse_double(inner.to_string())
    match parsed {
      Ok(v) => v / 100.0 * reference
      Err(_) => 0.0
    }
  } else {
    let parsed = try? @strconv.parse_double(s)
    match parsed {
      Ok(v) => v
      Err(_) => 0.0
    }
  }
}

///|
fn chord_mod_pi2(radian : Double) -> Double {
  let n = (radian / @math.PI * 100000000.0).round() / 100000000.0
  n % 2.0 * @math.PI
}

///|
fn chord_normalize_arc_angles(
  start_angle : Double,
  end_angle : Double,
  anticlockwise : Bool,
) -> (Double, Double) {
  let mut new_start = chord_mod_pi2(start_angle)
  if new_start < 0.0 {
    new_start = new_start + @math.PI * 2.0
  }
  let delta = new_start - start_angle
  let mut new_end = end_angle + delta
  let pi2 = @math.PI * 2.0
  if !anticlockwise && new_end - new_start >= pi2 {
    new_end = new_start + pi2
  } else if anticlockwise && new_start - new_end >= pi2 {
    new_end = new_start - pi2
  } else if !anticlockwise && new_start > new_end {
    new_end = new_start + (pi2 - chord_mod_pi2(new_start - new_end))
  } else if anticlockwise && new_start < new_end {
    new_end = new_start - (pi2 - chord_mod_pi2(new_end - new_start))
  }
  (new_start, new_end)
}

///|
fn chord_data_value(item : @option.DataItem) -> Double {
  match item.value {
    @option.Num(n) => n
    @option.Vec(arr) => if arr.length() > 0 { arr[0] } else { 0.0 }
    @option.DateValue(_, n) => n
    @option.Null => 0.0
  }
}

///|
fn chord_node_key(item : @option.DataItem, index : Int) -> String {
  match item.id {
    Some(id) => id
    None =>
      match item.name {
        Some(name) => name
        None => index.to_string()
      }
  }
}

///|
fn chord_find_node_index(lookup : Array[(String, Int)], key : String) -> Int? {
  let mut i = 0
  while i < lookup.length() {
    let (candidate, index) = lookup[i]
    if candidate == key {
      return Some(index)
    }
    i += 1
  }
  None
}

///|
fn chord_node_fill_color(
  series : @option.SeriesOption,
  node : ChordNode,
  color_index : Int,
) -> String {
  match node.item.item_style {
    Some(style) =>
      match style.color {
        Some(color) => color
        None =>
          match series.item_style {
            Some(color) => color
            None => @visual.palette_color(color_index)
          }
      }
    None =>
      match series.item_style {
        Some(color) => color
        None => @visual.palette_color(color_index)
      }
  }
}

///|
fn chord_node_border_color(
  series : @option.SeriesOption,
  node : ChordNode,
) -> String? {
  match node.item.item_style {
    Some(style) =>
      match style.border_color {
        Some(color) => Some(color)
        None =>
          match series.geo_item_style {
            Some(series_style) => series_style.border_color
            None => None
          }
      }
    None =>
      match series.geo_item_style {
        Some(series_style) => series_style.border_color
        None => None
      }
  }
}

///|
fn chord_node_border_width(
  series : @option.SeriesOption,
  node : ChordNode,
) -> Double {
  match node.item.item_style {
    Some(style) =>
      match style.border_width {
        Some(width) => width
        None =>
          match series.geo_item_style {
            Some(series_style) => series_style.border_width.unwrap_or(0.0)
            None => 0.0
          }
      }
    None =>
      match series.geo_item_style {
        Some(series_style) => series_style.border_width.unwrap_or(0.0)
        None => 0.0
      }
  }
}

///|
fn chord_label_show(series : @option.SeriesOption, node : ChordNode) -> Bool {
  match node.item.label {
    Some(label) => label.show.unwrap_or(series.label.map_or(false, l => l.show))
    None => series.label.map_or(false, l => l.show)
  }
}

///|
fn chord_label_position(
  series : @option.SeriesOption,
  node : ChordNode,
) -> String {
  match node.item.label {
    Some(label) =>
      match label.position {
        Some(position) => position
        None =>
          series.label.map_or("outside", l => l.position.unwrap_or("outside"))
      }
    None => series.label.map_or("outside", l => l.position.unwrap_or("outside"))
  }
}

///|
fn chord_label_distance(
  series : @option.SeriesOption,
  node : ChordNode,
) -> Double {
  match node.item.label {
    Some(label) =>
      match label.distance {
        Some(distance) => distance
        None => series.label.map_or(5.0, l => l.distance.unwrap_or(5.0))
      }
    None => series.label.map_or(5.0, l => l.distance.unwrap_or(5.0))
  }
}

///|
fn chord_label_color(
  series : @option.SeriesOption,
  node : ChordNode,
  position : String,
) -> String {
  let fallback = if position == "inside" { "#ffffff" } else { "#54555a" }
  match node.item.label {
    Some(label) =>
      match label.color {
        Some(color) => color
        None => series.label.map_or(fallback, l => l.color)
      }
    None => series.label.map_or(fallback, l => l.color)
  }
}

///|
fn chord_label_weight(
  series : @option.SeriesOption,
  node : ChordNode,
) -> String {
  match node.item.label {
    Some(label) =>
      match label.font_weight {
        Some(weight) => weight
        None =>
          series.label.map_or("normal", l => l.font_weight.unwrap_or("normal"))
      }
    None =>
      series.label.map_or("normal", l => l.font_weight.unwrap_or("normal"))
  }
}

///|
fn chord_sector_path(
  cx : Double,
  cy : Double,
  r0 : Double,
  r : Double,
  start_angle : Double,
  end_angle : Double,
  clockwise : Bool,
) -> String {
  let outer_x0 = cx + r * @math.cos(start_angle)
  let outer_y0 = cy + r * @math.sin(start_angle)
  let outer_x1 = cx + r * @math.cos(end_angle)
  let outer_y1 = cy + r * @math.sin(end_angle)
  let span = chord_abs(end_angle - start_angle)
  let large_arc = if span > @math.PI { 1 } else { 0 }
  let outer_sweep = if clockwise { 1 } else { 0 }
  let inner_sweep = if clockwise { 0 } else { 1 }
  if r0 <= 0.5 {
    "M \{chord_r4(cx)} \{chord_r4(cy)} L \{chord_r4(outer_x0)} \{chord_r4(outer_y0)} A \{chord_r4(r)} \{chord_r4(r)} 0 \{large_arc} \{outer_sweep} \{chord_r4(outer_x1)} \{chord_r4(outer_y1)} Z"
  } else {
    let inner_x0 = cx + r0 * @math.cos(start_angle)
    let inner_y0 = cy + r0 * @math.sin(start_angle)
    let inner_x1 = cx + r0 * @math.cos(end_angle)
    let inner_y1 = cy + r0 * @math.sin(end_angle)
    "M \{chord_r4(outer_x0)} \{chord_r4(outer_y0)} A \{chord_r4(r)} \{chord_r4(r)} 0 \{large_arc} \{outer_sweep} \{chord_r4(outer_x1)} \{chord_r4(outer_y1)} L \{chord_r4(inner_x1)} \{chord_r4(inner_y1)} A \{chord_r4(r0)} \{chord_r4(r0)} 0 \{large_arc} \{inner_sweep} \{chord_r4(inner_x0)} \{chord_r4(inner_y0)} Z"
  }
}

///|
fn chord_edge_path(
  edge : ChordEdgeLayout,
  cx : Double,
  cy : Double,
  r : Double,
  clockwise : Bool,
) -> String {
  let ratio = 0.7
  let s1x = cx + r * @math.cos(edge.s_start_angle)
  let s1y = cy + r * @math.sin(edge.s_start_angle)
  let s2x = cx + r * @math.cos(edge.s_end_angle)
  let s2y = cy + r * @math.sin(edge.s_end_angle)
  let t1x = cx + r * @math.cos(edge.t_start_angle)
  let t1y = cy + r * @math.sin(edge.t_start_angle)
  let t2x = cx + r * @math.cos(edge.t_end_angle)
  let t2y = cy + r * @math.sin(edge.t_end_angle)
  let cp1x = (cx - s2x) * ratio + s2x
  let cp1y = (cy - s2y) * ratio + s2y
  let cp2x = (cx - t1x) * ratio + t1x
  let cp2y = (cy - t1y) * ratio + t1y
  let cp3x = (cx - t2x) * ratio + t2x
  let cp3y = (cy - t2y) * ratio + t2y
  let cp4x = (cx - s1x) * ratio + s1x
  let cp4y = (cy - s1y) * ratio + s1y
  let s_large_arc = if chord_abs(edge.s_end_angle - edge.s_start_angle) >
    @math.PI {
    1
  } else {
    0
  }
  let t_large_arc = if chord_abs(edge.t_end_angle - edge.t_start_angle) >
    @math.PI {
    1
  } else {
    0
  }
  let sweep = if clockwise { 1 } else { 0 }
  "M \{chord_r4(s1x)} \{chord_r4(s1y)} A \{chord_r4(r)} \{chord_r4(r)} 0 \{s_large_arc} \{sweep} \{chord_r4(s2x)} \{chord_r4(s2y)} C \{chord_r4(cp1x)} \{chord_r4(cp1y)} \{chord_r4(cp2x)} \{chord_r4(cp2y)} \{chord_r4(t1x)} \{chord_r4(t1y)} A \{chord_r4(r)} \{chord_r4(r)} 0 \{t_large_arc} \{sweep} \{chord_r4(t2x)} \{chord_r4(t2y)} C \{chord_r4(cp3x)} \{chord_r4(cp3y)} \{chord_r4(cp4x)} \{chord_r4(cp4y)} \{chord_r4(s1x)} \{chord_r4(s1y)} Z"
}

///|
fn chord_edge_fill_color(
  series : @option.SeriesOption,
  edge : ChordEdgeLayout,
  node_colors : Array[String],
) -> String {
  let line_color = series.line_style_color.unwrap_or("source")
  match line_color {
    "source" => node_colors[edge.source_index]
    "target" => node_colors[edge.target_index]
    "gradient" => node_colors[edge.source_index]
    _ => line_color
  }
}

///|
fn chord_is_node_selected(
  opt : @option.ChartOption,
  node : @option.DataItem,
) -> Bool {
  match node.name {
    Some(name) =>
      match opt.legend {
        Some(legend) => legend.is_selected(name)
        None => true
      }
    None => true
  }
}

///|
fn chord_build_graph(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
) -> (Array[ChordNode], Array[ChordEdgeLayout]) {
  let nodes : Array[ChordNode] = []
  let lookup : Array[(String, Int)] = []
  let mut i = 0
  while i < series.data.length() {
    let item = series.data[i]
    if chord_is_node_selected(opt, item) {
      let key = chord_node_key(item, i)
      let name = item.name.unwrap_or(key)
      let index = nodes.length()
      nodes.push({
        name,
        item,
        angle: 0.0,
        ratio: 1.0,
        start_angle: 0.0,
        end_angle: 0.0,
      })
      lookup.push((key, index))
    }
    i += 1
  }

  let edges : Array[ChordEdgeLayout] = []
  let mut edge_index = 0
  while edge_index < series.link_data.length() {
    let item = series.link_data[edge_index]
    match (item.source, item.target) {
      (Some(source), Some(target)) =>
        match
          (
            chord_find_node_index(lookup, source),
            chord_find_node_index(lookup, target),
          ) {
          (Some(source_index), Some(target_index)) =>
            edges.push({
              item,
              source_index,
              target_index,
              value: 0.0,
              s_start_angle: 0.0,
              s_end_angle: 0.0,
              t_start_angle: 0.0,
              t_end_angle: 0.0,
            })
          _ => ()
        }
      _ => ()
    }
    edge_index += 1
  }
  (nodes, edges)
}

///|
fn chord_layout(
  series : @option.SeriesOption,
  chart_width : Double,
  chart_height : Double,
  nodes : Array[ChordNode],
  edges : Array[ChordEdgeLayout],
) -> (Double, Double, Double, Double, Bool, Bool) {
  if edges.length() == 0 || nodes.length() == 0 {
    return (0.0, 0.0, 0.0, 0.0, false, series.clockwise)
  }

  let cx = if series.center.length() >= 1 {
    chord_parse_pct_or_px(series.center[0], chart_width)
  } else {
    chart_width / 2.0
  }
  let cy = if series.center.length() >= 2 {
    chord_parse_pct_or_px(series.center[1], chart_height)
  } else {
    chart_height / 2.0
  }
  let ref_radius = (if chart_width < chart_height {
      chart_width
    } else {
      chart_height
    }) /
    2.0
  let r0 = if series.radius.length() >= 1 {
    chord_parse_pct_or_px(series.radius[0], ref_radius)
  } else {
    ref_radius * 0.7
  }
  let r = if series.radius.length() >= 2 {
    chord_parse_pct_or_px(series.radius[1], ref_radius)
  } else {
    ref_radius * 0.8
  }

  let mut node_data_sum = 0.0
  let mut edge_data_sum = 0.0
  let mut i = 0
  while i < nodes.length() {
    node_data_sum = node_data_sum + chord_data_value(nodes[i].item)
    i += 1
  }
  let mut ei = 0
  while ei < edges.length() {
    edge_data_sum = edge_data_sum + chord_data_value(edges[ei].item)
    ei += 1
  }
  let all_zero = node_data_sum == 0.0 && edge_data_sum == 0.0

  let pad_angle_deg = chord_max(series.pad_angle, 0.0)
  let mut pad_angle = pad_angle_deg * @math.PI / 180.0
  let mut min_angle = chord_max(series.min_angle, 0.0) * @math.PI / 180.0
  let clockwise = series.clockwise
  let dir = if clockwise { 1.0 } else { -1.0 }

  let node_values : Array[Double] = []
  i = 0
  while i < nodes.length() {
    node_values.push(0.0)
    i += 1
  }

  let mut rendered_node_count = 0
  ei = 0
  while ei < edges.length() {
    let edge = edges[ei]
    let value = if all_zero { 1.0 } else { chord_data_value(edge.item) }
    edges[ei].value = value
    if all_zero && (value > 0.0 || min_angle > 0.0) {
      rendered_node_count += 2
    }
    node_values[edge.source_index] = node_values[edge.source_index] + value
    node_values[edge.target_index] = node_values[edge.target_index] + value
    ei += 1
  }

  let mut node_value_sum = 0.0
  i = 0
  while i < nodes.length() {
    let explicit_value = chord_data_value(nodes[i].item)
    if explicit_value == explicit_value {
      node_values[i] = chord_max(explicit_value, node_values[i])
    }
    if !all_zero && (node_values[i] > 0.0 || min_angle > 0.0) {
      rendered_node_count += 1
    }
    node_value_sum = node_value_sum + node_values[i]
    i += 1
  }

  if rendered_node_count == 0 || node_value_sum == 0.0 {
    return (cx, cy, r0, r, false, clockwise)
  }

  let start_angle = -series.start_angle * @math.PI / 180.0
  let end_angle = start_angle + @math.PI * 2.0
  let (normalized_start_angle, normalized_end_angle) = chord_normalize_arc_angles(
    start_angle,
    end_angle,
    !clockwise,
  )
  let total_angle = normalized_end_angle - normalized_start_angle
  let abs_total_angle = chord_abs(total_angle)
  let rendered_count_f = rendered_node_count.to_double()
  if pad_angle * rendered_count_f >= abs_total_angle {
    pad_angle = chord_max(
      0.0,
      (abs_total_angle - min_angle * rendered_count_f) / rendered_count_f,
    )
  }
  if (pad_angle + min_angle) * rendered_count_f >= abs_total_angle {
    min_angle = (abs_total_angle - pad_angle * rendered_count_f) /
      rendered_count_f
  }

  let unit_angle = (total_angle - pad_angle * rendered_count_f * dir) /
    node_value_sum

  let mut total_deficit = 0.0
  let mut total_surplus = 0.0
  let mut total_surplus_span = 0.0
  i = 0
  while i < nodes.length() {
    let span_angle = unit_angle * node_values[i] * dir
    let abs_span_angle = chord_abs(span_angle)
    if abs_span_angle < min_angle {
      total_deficit = total_deficit + min_angle - abs_span_angle
    } else {
      total_surplus = total_surplus + abs_span_angle - min_angle
      total_surplus_span = total_surplus_span + abs_span_angle
    }
    nodes[i].angle = span_angle
    nodes[i].ratio = 1.0
    i += 1
  }

  let mut surplus_as_much_as_possible = false
  if total_deficit > total_surplus {
    let scale = if total_surplus != 0.0 {
      total_deficit / total_surplus
    } else {
      1.0
    }
    i = 0
    while i < nodes.length() {
      let span_angle = nodes[i].angle
      if chord_abs(span_angle) >= min_angle {
        nodes[i].angle = span_angle * scale
        nodes[i].ratio = scale
      } else {
        nodes[i].angle = min_angle
        nodes[i].ratio = if min_angle == 0.0 {
          1.0
        } else {
          span_angle / min_angle
        }
      }
      i += 1
    }
  } else {
    i = 0
    while i < nodes.length() && !surplus_as_much_as_possible {
      let span_angle = nodes[i].angle
      let borrow_ratio = if total_surplus_span == 0.0 {
        1.0
      } else {
        chord_min(span_angle / total_surplus_span, 1.0)
      }
      let borrow_angle = borrow_ratio * total_deficit
      if span_angle - borrow_angle < min_angle {
        surplus_as_much_as_possible = true
      }
      i += 1
    }
  }

  let mut rest_deficit = total_deficit
  i = 0
  while i < nodes.length() && rest_deficit > 0.0 {
    let span_angle = nodes[i].angle
    if span_angle > min_angle && min_angle > 0.0 {
      let borrow_ratio = if surplus_as_much_as_possible ||
        total_surplus_span == 0.0 {
        1.0
      } else {
        chord_min(span_angle / total_surplus_span, 1.0)
      }
      let max_borrow_angle = span_angle - min_angle
      let borrow_angle = chord_min(
        max_borrow_angle,
        chord_min(rest_deficit, total_deficit * borrow_ratio),
      )
      rest_deficit = rest_deficit - borrow_angle
      nodes[i].angle = span_angle - borrow_angle
      nodes[i].ratio = (span_angle - borrow_angle) / span_angle
    } else if min_angle > 0.0 {
      nodes[i].angle = min_angle
      nodes[i].ratio = if span_angle == 0.0 {
        1.0
      } else {
        min_angle / span_angle
      }
    }
    i += 1
  }

  let mut angle = normalized_start_angle
  let edge_acc_angle : Array[Double] = []
  i = 0
  while i < nodes.length() {
    let span_angle = chord_max(nodes[i].angle, min_angle)
    nodes[i].start_angle = angle
    nodes[i].end_angle = angle + span_angle * dir
    nodes[i].angle = span_angle
    edge_acc_angle.push(angle)
    angle = angle + (span_angle + pad_angle) * dir
    i += 1
  }

  ei = 0
  while ei < edges.length() {
    let edge = edges[ei]
    let span_angle = unit_angle * edge.value * dir
    let s_start_angle = edge_acc_angle[edge.source_index]
    let s_span = chord_abs(nodes[edge.source_index].ratio * span_angle)
    let s_end_angle = s_start_angle + s_span * dir
    let t_start_angle = edge_acc_angle[edge.target_index]
    let t_span = chord_abs(nodes[edge.target_index].ratio * span_angle)
    let t_end_angle = t_start_angle + t_span * dir
    edges[ei].s_start_angle = s_start_angle
    edges[ei].s_end_angle = s_end_angle
    edges[ei].t_start_angle = t_start_angle
    edges[ei].t_end_angle = t_end_angle
    edge_acc_angle[edge.source_index] = s_end_angle
    edge_acc_angle[edge.target_index] = t_end_angle
    ei += 1
  }

  (cx, cy, r0, r, true, clockwise)
}

///|
fn chord_render_labels(
  elems : Array[@graphic.Element],
  series : @option.SeriesOption,
  nodes : Array[ChordNode],
  cx : Double,
  cy : Double,
  r0 : Double,
  r : Double,
) -> Unit {
  let mut i = 0
  while i < nodes.length() {
    let node = nodes[i]
    if chord_label_show(series, node) && node.name != "" {
      let position = chord_label_position(series, node)
      let distance = chord_label_distance(series, node)
      let label_r = if position == "inside" {
        (r + r0) / 2.0
      } else {
        r + distance
      }
      let mid_angle = (node.start_angle + node.end_angle) / 2.0
      let dx = @math.cos(mid_angle)
      let dy = @math.sin(mid_angle)
      let x = dx * label_r + cx
      let y = dy * label_r + cy
      let anchor = if position == "inside" {
        @graphic.TextAnchor::Middle
      } else if dx > 0.0 {
        @graphic.TextAnchor::Start
      } else {
        @graphic.TextAnchor::End
      }
      let baseline = if position == "inside" {
        @graphic.TextBaseline::Middle
      } else if dy > 0.0 {
        @graphic.TextBaseline::Top
      } else {
        @graphic.TextBaseline::Bottom
      }
      elems.push(
        @graphic.Element::text_custom(
          x,
          y,
          node.name,
          anchor,
          baseline,
          chord_label_color(series, node, position),
          12.0,
          "sans-serif",
          chord_label_weight(series, node),
        ),
      )
    }
    i += 1
  }
}

///|
pub fn render_chords(
  opt : @option.ChartOption,
  _coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    match series.series_type {
      @option.SeriesType::Chord => {
        let series_elems = render_chord_series(opt, series, si)
        let mut i = 0
        while i < series_elems.length() {
          elems.push(series_elems[i])
          i += 1
        }
      }
      _ => ()
    }
    si += 1
  }
  elems
}

///|
pub fn render_chord_series(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
  series_index : Int,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let (nodes, edges) = chord_build_graph(opt, series)
  let (cx, cy, r0, r, has_layout, clockwise) = chord_layout(
    series,
    opt.width,
    opt.height,
    nodes,
    edges,
  )
  if !has_layout {
    return elems
  }

  let node_colors : Array[String] = []
  let mut i = 0
  while i < nodes.length() {
    node_colors.push(chord_node_fill_color(series, nodes[i], series_index + i))
    i += 1
  }

  let edge_opacity = series.line_style_opacity.unwrap_or(0.2)
  let edge_width = series.line_style_width.unwrap_or(0.0)
  let mut ei = 0
  while ei < edges.length() {
    let edge = edges[ei]
    let fill_color = chord_edge_fill_color(series, edge, node_colors)
    let d = chord_edge_path(edge, cx, cy, r0, clockwise)
    if edge_width > 0.0 {
      elems.push(
        @graphic.Element::path_fill_stroke(
          d, fill_color, fill_color, edge_width, edge_opacity,
        ),
      )
    } else {
      elems.push(@graphic.Element::path_filled(d, fill_color, edge_opacity))
    }
    ei += 1
  }

  i = 0
  while i < nodes.length() {
    let node = nodes[i]
    let d = chord_sector_path(
      cx,
      cy,
      r0,
      r,
      node.start_angle,
      node.end_angle,
      clockwise,
    )
    let fill_color = node_colors[i]
    let border_width = chord_node_border_width(series, node)
    match chord_node_border_color(series, node) {
      Some(border_color) =>
        if border_width > 0.0 {
          elems.push(
            @graphic.Element::path_fill_stroke(
              d, fill_color, border_color, border_width, 1.0,
            ),
          )
        } else {
          elems.push(@graphic.Element::path_filled(d, fill_color, 1.0))
        }
      None => elems.push(@graphic.Element::path_filled(d, fill_color, 1.0))
    }
    i += 1
  }

  chord_render_labels(elems, series, nodes, cx, cy, r0, r)
  elems
}

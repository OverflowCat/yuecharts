/// <=> echarts/src/chart/sankey/SankeySeries.ts
/// <=> echarts/src/chart/sankey/sankeyLayout.ts
/// <=> echarts/src/chart/sankey/SankeyView.ts
/// <=> echarts/src/chart/sankey/sankeyVisual.ts

///|
priv struct SankeyNode {
  item : @option.DataItem
  name : String
  mut in_edges : Array[Int]
  mut out_edges : Array[Int]
  mut value : Double
  mut depth : Int
  mut sk_node_height : Int
  mut x : Double
  mut y : Double
  mut dx : Double
  mut dy : Double
}

///|
priv struct SankeyEdge {
  source_index : Int
  target_index : Int
  value : Double
  mut dy : Double
  mut sy : Double
  mut ty : Double
}

///|
priv struct SankeyBox {
  x : Double
  y : Double
  width : Double
  height : Double
}

///|
priv struct SankeyResolvedLabelStyle {
  show : Bool
  color : String
  position : String
  distance : Double
  font_size : Double
  font_family : String
  font_weight : String
}

///|
fn sankey_r4(v : Double) -> String {
  let rounded = (v * 10000.0).round() / 10000.0
  if rounded == rounded.to_int().to_double() {
    rounded.to_int().to_string()
  } else {
    rounded.to_string()
  }
}

///|
fn sankey_data_value(item : @option.DataItem) -> Double {
  match item.value {
    @option.Num(n) => n
    @option.Vec(arr) => arr.get(0).unwrap_or(0.0)
    @option.DateValue(_, n) => n
    @option.Null => 0.0
  }
}

///|
fn sankey_node_key(item : @option.DataItem, index : Int) -> String {
  item.id.unwrap_or(item.name.unwrap_or(index.to_string()))
}

///|
fn sankey_find_node_index(lookup : Array[(String, Int)], key : String) -> Int? {
  let mut i = 0
  for i, _ in lookup {
    if lookup[i].0 == key {
      return Some(lookup[i].1)
    }
  }
  None
}

///|
fn sankey_build_graph(
  series : @option.SeriesOption,
) -> (Array[SankeyNode], Array[SankeyEdge]) {
  let nodes : Array[SankeyNode] = []
  let lookup : Array[(String, Int)] = []
  let mut i = 0
  for i, _ in series.data {
    let item = series.data[i]
    let key = sankey_node_key(item, i)
    let name = item.name.unwrap_or(key)
    let index = nodes.length()
    nodes.push({
      item,
      name,
      in_edges: [],
      out_edges: [],
      value: 0.0,
      depth: 0,
      sk_node_height: 0,
      x: 0.0,
      y: 0.0,
      dx: 0.0,
      dy: 0.0,
    })
    lookup.push((key, index))
  }

  let edges : Array[SankeyEdge] = []
  i = 0
  while i < series.link_data.length() {
    let item = series.link_data[i]
    match (item.source, item.target) {
      (Some(source), Some(target)) =>
        match
          (
            sankey_find_node_index(lookup, source),
            sankey_find_node_index(lookup, target),
          ) {
          (Some(source_index), Some(target_index)) => {
            let edge_index = edges.length()
            edges.push({
              source_index,
              target_index,
              value: sankey_data_value(item),
              dy: 0.0,
              sy: 0.0,
              ty: 0.0,
            })
            nodes[source_index].out_edges.push(edge_index)
            nodes[target_index].in_edges.push(edge_index)
          }
          _ => ()
        }
      _ => ()
    }
    i += 1
  }

  (nodes, edges)
}

///|
fn sankey_compute_node_values(
  nodes : Array[SankeyNode],
  edges : Array[SankeyEdge],
) -> Unit {
  for node in nodes {
    let mut out_sum = 0.0
    for edge_index in node.out_edges {
      out_sum += edges[edge_index].value
    }
    let mut in_sum = 0.0
    for edge_index in node.in_edges {
      in_sum += edges[edge_index].value
    }
    node.value = out_sum.max(in_sum).max(sankey_data_value(node.item))
  }
}

///|
fn sankey_resolve_size(spec : @option.SizeSpec, total : Double) -> Double {
  match spec {
    @option.SizeSpec::Px(px) => px
    @option.SizeSpec::Pct(pct) => total * pct / 100.0
  }
}

///|
fn sankey_box(
  series : @option.SeriesOption,
  opt : @option.ChartOption,
  view : @coord.View?,
) -> SankeyBox {
  match view {
    Some(coord) =>
      {
        x: 0.0,
        y: 0.0,
        width: coord.bounding_rect.width,
        height: coord.bounding_rect.height,
      }
    None => {
      let left = series.sankey_left.map_or(0.0, spec => {
        sankey_resolve_size(spec, opt.width)
      })
      let top = series.sankey_top.map_or(0.0, spec => {
        sankey_resolve_size(spec, opt.height)
      })
      let right = series.sankey_right.map_or(0.0, spec => {
        sankey_resolve_size(spec, opt.width)
      })
      let bottom = series.sankey_bottom.map_or(0.0, spec => {
        sankey_resolve_size(spec, opt.height)
      })
      let width = series.sankey_width.map_or(opt.width - left - right, spec => {
        sankey_resolve_size(spec, opt.width)
      })
      let height = series.sankey_height.map_or(opt.height - top - bottom, spec => {
        sankey_resolve_size(spec, opt.height)
      })
      { x: left, y: top, width: width.max(0.0), height: height.max(0.0) }
    }
  }
}

///|
fn sankey_view_scale(view : @coord.View?) -> Double {
  view.map_or(1.0, coord => coord.zoom)
}

///|
fn sankey_project_point(
  box : SankeyBox,
  view : @coord.View?,
  x : Double,
  y : Double,
) -> (Double, Double) {
  match view {
    Some(coord) => {
      let point = coord.data_to_point([x, y])
      (point[0], point[1])
    }
    None => (box.x + x, box.y + y)
  }
}

///|
fn sankey_clip_rect(box : SankeyBox, view : @coord.View?) -> @graphic.BBox {
  match view {
    Some(coord) => {
      let rect = coord.get_view_rect_after_roam()
      @graphic.BBox::new(
        rect.x - 10.0,
        rect.y - 10.0,
        rect.width + 20.0,
        rect.height + 20.0,
      )
    }
    None =>
      @graphic.BBox::new(
        box.x - 10.0,
        box.y - 10.0,
        box.width + 20.0,
        box.height + 20.0,
      )
  }
}

///|
fn sankey_is_item_depth(node : SankeyNode) -> Bool {
  node.item.depth.map_or(false, depth => depth >= 0)
}

///|
fn sankey_adjust_node_align_right(
  nodes : Array[SankeyNode],
  edges : Array[SankeyEdge],
  max_depth : Int,
) -> Unit {
  let mut remain_nodes : Array[Int] = []
  let mut i = 0
  for i, _ in nodes {
    remain_nodes.push(i)
  }
  let mut next_source_nodes : Array[Int] = []
  let mut node_height = 0
  while remain_nodes.length() > 0 {
    i = 0
    while i < remain_nodes.length() {
      let node_index = remain_nodes[i]
      nodes[node_index].sk_node_height = node_height
      let mut j = 0
      for j, _ in nodes[node_index].in_edges {
        let source_index = edges[nodes[node_index].in_edges[j]].source_index
        if !next_source_nodes.contains(source_index) {
          next_source_nodes.push(source_index)
        }
      }
      i += 1
    }
    remain_nodes = next_source_nodes
    next_source_nodes = []
    node_height += 1
  }
  i = 0
  while i < nodes.length() {
    if !sankey_is_item_depth(nodes[i]) {
      let depth = max_depth - nodes[i].sk_node_height
      nodes[i].depth = if depth < 0 { 0 } else { depth }
    }
    i += 1
  }
}

///|
fn sankey_move_sinks_right(nodes : Array[SankeyNode], max_depth : Int) -> Unit {
  let mut i = 0
  for i, _ in nodes {
    if !sankey_is_item_depth(nodes[i]) && nodes[i].out_edges.length() == 0 {
      nodes[i].depth = max_depth
    }
  }
}

///|
fn sankey_compute_node_breadths(
  series : @option.SeriesOption,
  nodes : Array[SankeyNode],
  edges : Array[SankeyEdge],
  box : SankeyBox,
) -> Bool {
  let node_width = series.sankey_node_width
  let orient = series.sankey_orient
  let remain_edges : Array[Int] = []
  let indegrees : Array[Int] = []
  let mut zero_indegrees : Array[Int] = []
  let mut next_target_nodes : Array[Int] = []
  let mut i = 0
  for i, _ in edges {
    remain_edges.push(1)
  }
  i = 0
  while i < nodes.length() {
    let indegree = nodes[i].in_edges.length()
    indegrees.push(indegree)
    if indegree == 0 {
      zero_indegrees.push(i)
    }
    i += 1
  }
  let mut breadth = 0
  let mut max_node_depth = -1
  while zero_indegrees.length() > 0 {
    i = 0
    while i < zero_indegrees.length() {
      let node_index = zero_indegrees[i]
      let item_depth = nodes[node_index].item.depth.unwrap_or(-1)
      let is_item_depth = item_depth >= 0
      if is_item_depth && item_depth > max_node_depth {
        max_node_depth = item_depth
      }
      nodes[node_index].depth = if is_item_depth { item_depth } else { breadth }
      if orient == "vertical" {
        nodes[node_index].dy = node_width
      } else {
        nodes[node_index].dx = node_width
      }
      let mut j = 0
      for j, _ in nodes[node_index].out_edges {
        let edge_index = nodes[node_index].out_edges[j]
        remain_edges[edge_index] = 0
        let target_index = edges[edge_index].target_index
        indegrees[target_index] = indegrees[target_index] - 1
        if indegrees[target_index] == 0 &&
          !next_target_nodes.contains(target_index) {
          next_target_nodes.push(target_index)
        }
      }
      i += 1
    }
    breadth += 1
    zero_indegrees = next_target_nodes
    next_target_nodes = []
  }
  i = 0
  while i < remain_edges.length() {
    if remain_edges[i] == 1 {
      return false
    }
    i += 1
  }
  let max_depth = if max_node_depth > breadth - 1 {
    max_node_depth
  } else {
    breadth - 1
  }
  match series.sankey_node_align {
    "right" => sankey_adjust_node_align_right(nodes, edges, max_depth)
    "justify" => sankey_move_sinks_right(nodes, max_depth)
    _ => ()
  }
  let span = if orient == "vertical" { box.height } else { box.width }
  let kx = if max_depth <= 0 {
    0.0
  } else {
    0.0.max((span - node_width) / max_depth.to_double())
  }
  for node in nodes {
    let coord = node.depth.to_double() * kx
    if orient == "vertical" {
      node.y = coord
    } else {
      node.x = coord
    }
  }
  true
}

///|
fn sankey_prepare_nodes_by_breadth(
  nodes : Array[SankeyNode],
) -> Array[Array[Int]] {
  let mut max_depth = 0
  let mut i = 0
  for i, _ in nodes {
    if nodes[i].depth > max_depth {
      max_depth = nodes[i].depth
    }
  }
  let groups : Array[Array[Int]] = []
  let mut depth = 0
  while depth <= max_depth {
    let group : Array[Int] = []
    i = 0
    while i < nodes.length() {
      if nodes[i].depth == depth {
        group.push(i)
      }
      i += 1
    }
    if group.length() > 0 {
      groups.push(group)
    }
    depth += 1
  }
  groups
}

///|
fn sankey_initialize_node_depths(
  series : @option.SeriesOption,
  nodes : Array[SankeyNode],
  edges : Array[SankeyEdge],
  box : SankeyBox,
  groups : Array[Array[Int]],
) -> Unit {
  let cross_span = if series.sankey_orient == "vertical" {
    box.width
  } else {
    box.height
  }
  let mut min_ky = 1.0 / 0.0
  let mut i = 0
  for i, _ in groups {
    let group = groups[i]
    let mut sum = 0.0
    let mut j = 0
    for j, _ in group {
      sum = sum + nodes[group[j]].value
    }
    if sum > 0.0 {
      let ky = (
          cross_span - (group.length() - 1).to_double() * series.sankey_node_gap
        ) /
        sum
      if ky < min_ky {
        min_ky = ky
      }
    }
  }
  if min_ky != min_ky || min_ky == 1.0 / 0.0 {
    min_ky = 0.0
  }
  i = 0
  while i < groups.length() {
    let group = groups[i]
    let mut j = 0
    for j, _ in group {
      let node_index = group[j]
      let node_extent = nodes[node_index].value * min_ky
      if series.sankey_orient == "vertical" {
        nodes[node_index].x = j.to_double()
        nodes[node_index].dx = node_extent
      } else {
        nodes[node_index].y = j.to_double()
        nodes[node_index].dy = node_extent
      }
    }
    i += 1
  }
  i = 0
  while i < edges.length() {
    edges[i].dy = edges[i].value * min_ky
    i += 1
  }
}

///|
fn sankey_node_cross_coord(node : SankeyNode, orient : String) -> Double {
  if orient == "vertical" {
    node.x
  } else {
    node.y
  }
}

///|
fn sankey_node_cross_size(node : SankeyNode, orient : String) -> Double {
  if orient == "vertical" {
    node.dx
  } else {
    node.dy
  }
}

///|
fn sankey_set_node_cross_coord(
  nodes : Array[SankeyNode],
  index : Int,
  orient : String,
  value : Double,
) -> Unit {
  if orient == "vertical" {
    nodes[index].x = value
  } else {
    nodes[index].y = value
  }
}

///|
fn sankey_resolve_collisions(
  series : @option.SeriesOption,
  nodes : Array[SankeyNode],
  groups : Array[Array[Int]],
  box : SankeyBox,
) -> Unit {
  let orient = series.sankey_orient
  let view_cross = if orient == "vertical" { box.width } else { box.height }
  let mut i = 0
  for i, _ in groups {
    let group = groups[i]
    let ordered : Array[Int] = []
    let used : Array[Bool] = []
    let mut j = 0
    for j, _ in group {
      used.push(false)
    }
    let mut picked = 0
    for picked, _ in group {
      let mut best = -1
      j = 0
      while j < group.length() {
        if !used[j] &&
          (
            best == -1 ||
            sankey_node_cross_coord(nodes[group[j]], orient) <
            sankey_node_cross_coord(nodes[group[best]], orient)
          ) {
          best = j
        }
        j += 1
      }
      if best >= 0 {
        used[best] = true
        ordered.push(group[best])
      }
    }
    let mut cursor = 0.0
    j = 0
    while j < ordered.length() {
      let node_index = ordered[j]
      let current = sankey_node_cross_coord(nodes[node_index], orient)
      let overlap = cursor - current
      if overlap > 0.0 {
        sankey_set_node_cross_coord(
          nodes,
          node_index,
          orient,
          current + overlap,
        )
      }
      cursor = sankey_node_cross_coord(nodes[node_index], orient) +
        sankey_node_cross_size(nodes[node_index], orient) +
        series.sankey_node_gap
      j += 1
    }
    let overflow = cursor - series.sankey_node_gap - view_cross
    if overflow > 0.0 && ordered.length() > 0 {
      let last_index = ordered[ordered.length() - 1]
      let last_coord = sankey_node_cross_coord(nodes[last_index], orient) -
        overflow
      sankey_set_node_cross_coord(nodes, last_index, orient, last_coord)
      cursor = last_coord
      let mut k = ordered.length() - 1
      while k > 0 {
        let prev_index = ordered[k - 1]
        let prev_coord = sankey_node_cross_coord(nodes[prev_index], orient)
        let prev_overlap = prev_coord +
          sankey_node_cross_size(nodes[prev_index], orient) +
          series.sankey_node_gap -
          cursor
        if prev_overlap > 0.0 {
          sankey_set_node_cross_coord(
            nodes,
            prev_index,
            orient,
            prev_coord - prev_overlap,
          )
        }
        cursor = sankey_node_cross_coord(nodes[prev_index], orient)
        k -= 1
      }
    }
  }
}

///|
fn sankey_node_center(node : SankeyNode, orient : String) -> Double {
  if orient == "vertical" {
    node.x + node.dx / 2.0
  } else {
    node.y + node.dy / 2.0
  }
}

///|
fn sankey_sum_edge_values(
  edge_indices : Array[Int],
  edges : Array[SankeyEdge],
) -> Double {
  let mut sum = 0.0
  let mut i = 0
  for i, _ in edge_indices {
    let value = edges[edge_indices[i]].value
    if value == value {
      sum = sum + value
    }
  }
  sum
}

///|
fn sankey_relax_right_to_left(
  series : @option.SeriesOption,
  nodes : Array[SankeyNode],
  edges : Array[SankeyEdge],
  groups : Array[Array[Int]],
  alpha : Double,
) -> Unit {
  let orient = series.sankey_orient
  let mut gi = groups.length()
  while gi > 0 {
    let group = groups[gi - 1]
    let mut i = 0
    for i, _ in group {
      let node_index = group[i]
      if nodes[node_index].out_edges.length() > 0 {
        let out_sum = sankey_sum_edge_values(nodes[node_index].out_edges, edges)
        let weighted = if out_sum > 0.0 {
          let mut total = 0.0
          let mut j = 0
          for j, _ in nodes[node_index].out_edges {
            let edge = edges[nodes[node_index].out_edges[j]]
            total = total +
              sankey_node_center(nodes[edge.target_index], orient) * edge.value
          }
          total / out_sum
        } else {
          let count = nodes[node_index].out_edges.length()
          let mut total = 0.0
          let mut j = 0
          while j < count {
            total = total +
              sankey_node_center(
                nodes[edges[nodes[node_index].out_edges[j]].target_index],
                orient,
              )
            j += 1
          }
          total / count.to_double()
        }
        let next = sankey_node_cross_coord(nodes[node_index], orient) +
          (weighted - sankey_node_center(nodes[node_index], orient)) * alpha
        sankey_set_node_cross_coord(nodes, node_index, orient, next)
      }
    }
    gi -= 1
  }
}

///|
fn sankey_relax_left_to_right(
  series : @option.SeriesOption,
  nodes : Array[SankeyNode],
  edges : Array[SankeyEdge],
  groups : Array[Array[Int]],
  alpha : Double,
) -> Unit {
  let orient = series.sankey_orient
  let mut gi = 0
  for gi, _ in groups {
    let group = groups[gi]
    let mut i = 0
    for i, _ in group {
      let node_index = group[i]
      if nodes[node_index].in_edges.length() > 0 {
        let in_sum = sankey_sum_edge_values(nodes[node_index].in_edges, edges)
        let weighted = if in_sum > 0.0 {
          let mut total = 0.0
          let mut j = 0
          for j, _ in nodes[node_index].in_edges {
            let edge = edges[nodes[node_index].in_edges[j]]
            total = total +
              sankey_node_center(nodes[edge.source_index], orient) * edge.value
          }
          total / in_sum
        } else {
          let count = nodes[node_index].in_edges.length()
          let mut total = 0.0
          let mut j = 0
          while j < count {
            total = total +
              sankey_node_center(
                nodes[edges[nodes[node_index].in_edges[j]].source_index],
                orient,
              )
            j += 1
          }
          total / count.to_double()
        }
        let next = sankey_node_cross_coord(nodes[node_index], orient) +
          (weighted - sankey_node_center(nodes[node_index], orient)) * alpha
        sankey_set_node_cross_coord(nodes, node_index, orient, next)
      }
    }
  }
}

///|
fn sankey_compute_node_depths(
  series : @option.SeriesOption,
  nodes : Array[SankeyNode],
  edges : Array[SankeyEdge],
  box : SankeyBox,
  iterations : Int,
) -> Unit {
  let groups = sankey_prepare_nodes_by_breadth(nodes)
  sankey_initialize_node_depths(series, nodes, edges, box, groups)
  sankey_resolve_collisions(series, nodes, groups, box)
  let mut alpha = 1.0
  let mut remain = iterations
  while remain > 0 {
    alpha = alpha * 0.99
    sankey_relax_right_to_left(series, nodes, edges, groups, alpha)
    sankey_resolve_collisions(series, nodes, groups, box)
    sankey_relax_left_to_right(series, nodes, edges, groups, alpha)
    sankey_resolve_collisions(series, nodes, groups, box)
    remain -= 1
  }
}

///|
fn sankey_sort_edge_indices(
  edge_indices : Array[Int],
  nodes : Array[SankeyNode],
  edges : Array[SankeyEdge],
  orient : String,
  use_target : Bool,
) -> Array[Int] {
  let ordered : Array[Int] = []
  let used : Array[Bool] = []
  let mut i = 0
  for i, _ in edge_indices {
    used.push(false)
  }
  for picked, _ in edge_indices {
    let mut best = -1
    let mut j = 0
    for j, _ in edge_indices {
      if !used[j] {
        let current_node = if use_target {
          nodes[edges[edge_indices[j]].target_index]
        } else {
          nodes[edges[edge_indices[j]].source_index]
        }
        let better = if best == -1 {
          true
        } else {
          let best_node = if use_target {
            nodes[edges[edge_indices[best]].target_index]
          } else {
            nodes[edges[edge_indices[best]].source_index]
          }
          sankey_node_cross_coord(current_node, orient) <
          sankey_node_cross_coord(best_node, orient)
        }
        if better {
          best = j
        }
      }
    }
    if best >= 0 {
      used[best] = true
      ordered.push(edge_indices[best])
    }
  }
  ordered
}

///|
fn sankey_compute_edge_depths(
  series : @option.SeriesOption,
  nodes : Array[SankeyNode],
  edges : Array[SankeyEdge],
) -> Unit {
  let orient = series.sankey_orient
  let mut i = 0
  for i, _ in nodes {
    nodes[i].out_edges = sankey_sort_edge_indices(
      nodes[i].out_edges,
      nodes,
      edges,
      orient,
      true,
    )
    nodes[i].in_edges = sankey_sort_edge_indices(
      nodes[i].in_edges,
      nodes,
      edges,
      orient,
      false,
    )
  }
  i = 0
  while i < nodes.length() {
    let mut sy = 0.0
    let mut j = 0
    for j, _ in nodes[i].out_edges {
      let edge_index = nodes[i].out_edges[j]
      edges[edge_index].sy = sy
      sy = sy + edges[edge_index].dy
    }
    let mut ty = 0.0
    j = 0
    while j < nodes[i].in_edges.length() {
      let edge_index = nodes[i].in_edges[j]
      edges[edge_index].ty = ty
      ty = ty + edges[edge_index].dy
      j += 1
    }
    i += 1
  }
}

///|
fn sankey_layout(
  series : @option.SeriesOption,
  nodes : Array[SankeyNode],
  edges : Array[SankeyEdge],
  box : SankeyBox,
) -> Bool {
  sankey_compute_node_values(nodes, edges)
  let mut has_zero_value = false
  let mut i = 0
  while i < nodes.length() && !has_zero_value {
    if nodes[i].value == 0.0 {
      has_zero_value = true
    }
    i += 1
  }
  let iterations = if has_zero_value {
    0
  } else {
    series.sankey_layout_iterations
  }
  if !sankey_compute_node_breadths(series, nodes, edges, box) {
    return false
  }
  sankey_compute_node_depths(series, nodes, edges, box, iterations)
  sankey_compute_edge_depths(series, nodes, edges)
  true
}

///|
fn sankey_level_for_depth(
  series : @option.SeriesOption,
  depth : Int,
) -> @option.SankeyLevelOption? {
  for i, _ in series.sankey_levels {
    if series.sankey_levels[i].depth == depth {
      return Some(series.sankey_levels[i])
    }
  }
  None
}

///|
fn sankey_palette_color(t : Double) -> String {
  let palette = @visual.echarts_palette
  if palette.length() == 0 {
    return "#5070dd"
  }
  if palette.length() == 1 {
    return palette[0]
  }
  let normalized = t.clamp(min=0.0, max=1.0)
  let scaled = normalized * (palette.length() - 1).to_double()
  let lower = scaled.to_int()
  let upper = if lower + 1 < palette.length() { lower + 1 } else { lower }
  let local_t = scaled - lower.to_double()
  let lower_color = @graphic.Color::from_string(palette[lower]).unwrap_or(
    @graphic.black,
  )
  let upper_color = @graphic.Color::from_string(palette[upper]).unwrap_or(
    @graphic.black,
  )
  @graphic.Color::lerp(lower_color, upper_color, local_t).to_svg()
}

///|
fn sankey_default_node_color(
  value : Double,
  min_value : Double,
  max_value : Double,
) -> String {
  if max_value <= min_value {
    return @visual.echarts_palette[@visual.echarts_palette.length() - 1]
  }
  sankey_palette_color((value - min_value) / (max_value - min_value))
}

///|
fn sankey_node_fill_color(
  node : SankeyNode,
  level : @option.SankeyLevelOption?,
  default_color : String,
) -> String {
  let level_default = level.map_or(default_color, level_value => {
    level_value.item_style.map_or(default_color, style => {
      style.color.unwrap_or(default_color)
    })
  })
  node.item.item_style.map_or(level_default, style => {
    style.color.unwrap_or(level_default)
  })
}

///|
fn sankey_node_border_color(
  node : SankeyNode,
  level : @option.SankeyLevelOption?,
) -> String? {
  let level_color = level.bind(level_value => {
    level_value.item_style.bind(style => style.border_color)
  })
  match node.item.item_style.bind(style => style.border_color) {
    Some(color) => Some(color)
    None => level_color
  }
}

///|
fn sankey_node_border_width(
  node : SankeyNode,
  level : @option.SankeyLevelOption?,
) -> Double {
  let level_width = level
    .bind(level_value => {
      level_value.item_style.bind(style => style.border_width)
    })
    .unwrap_or(0.0)
  node.item.item_style.bind(style => style.border_width).unwrap_or(level_width)
}

///|
fn sankey_apply_label_patch(
  style : SankeyResolvedLabelStyle,
  patch : @option.GeoLabelPatchOption?,
) -> SankeyResolvedLabelStyle {
  patch
  .map(p => {
    show: p.show.unwrap_or(style.show),
    color: p.color.unwrap_or(style.color),
    position: p.position.unwrap_or(style.position),
    distance: p.distance.unwrap_or(style.distance),
    font_size: p.font_size.unwrap_or(style.font_size),
    font_family: p.font_family.unwrap_or(style.font_family),
    font_weight: p.font_weight.unwrap_or(style.font_weight),
  })
  .unwrap_or(style)
}

///|
fn sankey_resolve_label_style(
  series : @option.SeriesOption,
  node : SankeyNode,
  level : @option.SankeyLevelOption?,
) -> SankeyResolvedLabelStyle {
  let base = series.label.unwrap_or_default()
  let initial : SankeyResolvedLabelStyle = {
    show: base.show,
    color: base.color,
    position: base.position.unwrap_or("right"),
    distance: base.distance.unwrap_or(5.0),
    font_size: base.font_size,
    font_family: base.font_family,
    font_weight: base.font_weight.unwrap_or("normal"),
  }
  let level_style = sankey_apply_label_patch(
    initial,
    level.bind(value => value.label),
  )
  sankey_apply_label_patch(level_style, node.item.label)
}

///|
fn sankey_edge_style_value(
  level : @option.SankeyLevelOption?,
  level_selector : (@option.SankeyLevelOption) -> String?,
  fallback : String?,
  default_value : String,
) -> String {
  let base = fallback.unwrap_or(default_value)
  level.bind(value => level_selector(value)).unwrap_or(base)
}

///|
fn sankey_edge_opacity(
  series : @option.SeriesOption,
  level : @option.SankeyLevelOption?,
) -> Double {
  let base = series.line_style_opacity.unwrap_or(0.2)
  level.map_or(base, value => value.line_style_opacity.unwrap_or(base))
}

///|
fn sankey_edge_width(
  series : @option.SeriesOption,
  level : @option.SankeyLevelOption?,
) -> Double {
  let base = series.line_style_width.unwrap_or(0.0)
  level.map_or(base, value => value.line_style_width.unwrap_or(base))
}

///|
fn sankey_edge_curveness(
  series : @option.SeriesOption,
  level : @option.SankeyLevelOption?,
) -> Double {
  let base = series.line_style_curveness.unwrap_or(0.5)
  level.map_or(base, value => value.line_style_curveness.unwrap_or(base))
}

///|
fn sankey_edge_fill_color(
  series : @option.SeriesOption,
  edge : SankeyEdge,
  level : @option.SankeyLevelOption?,
  node_colors : Array[String],
) -> String {
  let color_spec = sankey_edge_style_value(
    level,
    fn(level_value) { level_value.line_style_color },
    series.line_style_color,
    "#86878c",
  )
  match color_spec {
    "source" => node_colors[edge.source_index]
    "target" => node_colors[edge.target_index]
    "gradient" => node_colors[edge.source_index]
    _ => color_spec
  }
}

///|
fn sankey_edge_path(
  series : @option.SeriesOption,
  edge : SankeyEdge,
  nodes : Array[SankeyNode],
  box : SankeyBox,
  view : @coord.View?,
  curveness : Double,
) -> String {
  let extent = edge.dy.max(1)
  let source = nodes[edge.source_index]
  let target = nodes[edge.target_index]
  if series.sankey_orient == "vertical" {
    let (x1, y1) = sankey_project_point(
      box,
      view,
      source.x + edge.sy,
      source.y + source.dy,
    )
    let (x2, y2) = sankey_project_point(box, view, target.x + edge.ty, target.y)
    let (x2b, y2b) = sankey_project_point(
      box,
      view,
      target.x + edge.ty + extent,
      target.y,
    )
    let (x1b, y1b) = sankey_project_point(
      box,
      view,
      source.x + edge.sy + extent,
      source.y + source.dy,
    )
    let cpx1 = x1
    let cpy1 = y1 * (1.0 - curveness) + y2 * curveness
    let cpx2 = x2
    let cpy2 = y1 * curveness + y2 * (1.0 - curveness)
    let cpx2b = x2b
    let cpy2b = cpy2
    let cpx1b = x1b
    let cpy1b = cpy1
    "M \{sankey_r4(x1)} \{sankey_r4(y1)} C \{sankey_r4(cpx1)} \{sankey_r4(cpy1)} \{sankey_r4(cpx2)} \{sankey_r4(cpy2)} \{sankey_r4(x2)} \{sankey_r4(y2)} L \{sankey_r4(x2b)} \{sankey_r4(y2b)} C \{sankey_r4(cpx2b)} \{sankey_r4(cpy2b)} \{sankey_r4(cpx1b)} \{sankey_r4(cpy1b)} \{sankey_r4(x1b)} \{sankey_r4(y1b)} Z"
  } else {
    let (x1, y1) = sankey_project_point(
      box,
      view,
      source.x + source.dx,
      source.y + edge.sy,
    )
    let (x2, y2) = sankey_project_point(box, view, target.x, target.y + edge.ty)
    let (x2b, y2b) = sankey_project_point(
      box,
      view,
      target.x,
      target.y + edge.ty + extent,
    )
    let (x1b, y1b) = sankey_project_point(
      box,
      view,
      source.x + source.dx,
      source.y + edge.sy + extent,
    )
    let cpx1 = x1 * (1.0 - curveness) + x2 * curveness
    let cpy1 = y1
    let cpx2 = x1 * curveness + x2 * (1.0 - curveness)
    let cpy2 = y2
    let cpx2b = cpx2
    let cpy2b = y2b
    let cpx1b = cpx1
    let cpy1b = y1b
    "M \{sankey_r4(x1)} \{sankey_r4(y1)} C \{sankey_r4(cpx1)} \{sankey_r4(cpy1)} \{sankey_r4(cpx2)} \{sankey_r4(cpy2)} \{sankey_r4(x2)} \{sankey_r4(y2)} L \{sankey_r4(x2b)} \{sankey_r4(y2b)} C \{sankey_r4(cpx2b)} \{sankey_r4(cpy2b)} \{sankey_r4(cpx1b)} \{sankey_r4(cpy1b)} \{sankey_r4(x1b)} \{sankey_r4(y1b)} Z"
  }
}

///|
fn sankey_label_geometry(
  node : SankeyNode,
  box : SankeyBox,
  view : @coord.View?,
  style : SankeyResolvedLabelStyle,
) -> (Double, Double, @graphic.TextAnchor, @graphic.TextBaseline) {
  let x = node.x
  let y = node.y
  let mid_x = x + node.dx / 2.0
  let mid_y = y + node.dy / 2.0
  match style.position {
    "left" => {
      let (tx, ty) = sankey_project_point(box, view, x - style.distance, mid_y)
      (tx, ty, @graphic.TextAnchor::End, @graphic.TextBaseline::Middle)
    }
    "top" => {
      let (tx, ty) = sankey_project_point(box, view, mid_x, y - style.distance)
      (tx, ty, @graphic.TextAnchor::Middle, @graphic.TextBaseline::Bottom)
    }
    "bottom" => {
      let (tx, ty) = sankey_project_point(
        box,
        view,
        mid_x,
        y + node.dy + style.distance,
      )
      (tx, ty, @graphic.TextAnchor::Middle, @graphic.TextBaseline::Top)
    }
    "inside"
    | "insideLeft"
    | "insideRight"
    | "insideTop"
    | "insideBottom"
    | "center" => {
      let (tx, ty) = sankey_project_point(box, view, mid_x, mid_y)
      (tx, ty, @graphic.TextAnchor::Middle, @graphic.TextBaseline::Middle)
    }
    _ => {
      let (tx, ty) = sankey_project_point(
        box,
        view,
        x + node.dx + style.distance,
        mid_y,
      )
      (tx, ty, @graphic.TextAnchor::Start, @graphic.TextBaseline::Middle)
    }
  }
}

///|
fn sankey_render_series(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
  view : @coord.View?,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let (nodes, edges) = sankey_build_graph(series)
  if nodes.length() == 0 {
    return elems
  }
  let box = sankey_box(series, opt, view)
  if !sankey_layout(series, nodes, edges, box) {
    return elems
  }

  let mut min_value = nodes[0].value
  let mut max_value = nodes[0].value
  for node in nodes {
    if node.value < min_value {
      min_value = node.value
    }
    if node.value > max_value {
      max_value = node.value
    }
  }
  let node_colors : Array[String] = []
  let mut i = 0
  for i, _ in nodes {
    let default_color = sankey_default_node_color(
      nodes[i].value,
      min_value,
      max_value,
    )
    let level = sankey_level_for_depth(series, nodes[i].depth)
    node_colors.push(sankey_node_fill_color(nodes[i], level, default_color))
  }

  i = 0
  while i < edges.length() {
    let level = sankey_level_for_depth(
      series,
      nodes[edges[i].source_index].depth,
    )
    let fill_color = sankey_edge_fill_color(
      series,
      edges[i],
      level,
      node_colors,
    )
    let opacity = sankey_edge_opacity(series, level)
    let width = sankey_edge_width(series, level) * sankey_view_scale(view)
    let curveness = sankey_edge_curveness(series, level)
    let path = sankey_edge_path(series, edges[i], nodes, box, view, curveness)
    if width > 0.0 {
      elems.push(
        @graphic.Element::path_fill_stroke(
          path, fill_color, fill_color, width, opacity,
        ),
      )
    } else {
      elems.push(@graphic.Element::path_filled(path, fill_color, opacity))
    }
    i += 1
  }

  i = 0
  while i < nodes.length() {
    let level = sankey_level_for_depth(series, nodes[i].depth)
    let (x0, y0) = sankey_project_point(box, view, nodes[i].x, nodes[i].y)
    let (x1, y1) = sankey_project_point(
      box,
      view,
      nodes[i].x + nodes[i].dx,
      nodes[i].y + nodes[i].dy,
    )
    let x = if x0 < x1 { x0 } else { x1 }
    let y = if y0 < y1 { y0 } else { y1 }
    let width = (x1 - x0).abs()
    let height = (y1 - y0).abs()
    let border_width = sankey_node_border_width(nodes[i], level) *
      sankey_view_scale(view)
    match sankey_node_border_color(nodes[i], level) {
      Some(border_color) if border_width > 0.0 =>
        elems.push(
          @graphic.Element::rect_fill_stroke(
            x,
            y,
            width,
            height,
            node_colors[i],
            border_color,
            border_width,
          ),
        )
      _ =>
        elems.push(
          @graphic.Element::rect_colored(x, y, width, height, node_colors[i]),
        )
    }
    let label_style = sankey_resolve_label_style(series, nodes[i], level)
    if label_style.show && nodes[i].name != "" {
      let (text_x, text_y, anchor, baseline) = sankey_label_geometry(
        nodes[i],
        box,
        view,
        label_style,
      )
      elems.push(
        @graphic.Element::text_custom(
          text_x,
          text_y,
          nodes[i].name,
          anchor,
          baseline,
          label_style.color,
          label_style.font_size * sankey_view_scale(view),
          label_style.font_family,
          label_style.font_weight,
        ),
      )
    }
    i += 1
  }

  [@graphic.Element::group_clipped(elems, sankey_clip_rect(box, view))]
}

///|
pub fn render_sankeys(
  opt : @option.ChartOption,
  views : Array[@coord.View],
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut i = 0
  for i, _ in opt.series {
    let series = opt.series[i]
    if series.series_type == @option.SeriesType::Sankey {
      let view = @coord.View::find_for_series(views, i)
      let series_elems = sankey_render_series(opt, series, view)
      let mut j = 0
      for j, _ in series_elems {
        elems.push(series_elems[j])
      }
    }
  }
  elems
}

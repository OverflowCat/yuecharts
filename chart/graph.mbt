/// <=> echarts/src/chart/graph/GraphSeries.ts
/// <=> echarts/src/chart/graph/GraphView.ts
/// <=> echarts/src/chart/graph/forceLayout.ts
/// <=> echarts/src/chart/graph/forceHelper.ts
/// <=> echarts/src/chart/graph/categoryVisual.ts

///|
/// Force layout node (Verlet integration).
/// Corresponds to: echarts/src/chart/graph/forceHelper.ts LayoutNode
priv struct GraphNode {
  mut x : Double // current position x
  mut y : Double // current position y
  mut px : Double // previous position x
  mut py : Double // previous position y
  w : Double // weight / repulsion
  fixed : Bool
}

///|
/// Force layout edge.
/// Corresponds to: echarts/src/chart/graph/forceHelper.ts LayoutEdge
priv struct GraphEdge {
  n1 : Int // index into node array
  n2 : Int // index into node array
  d : Double // desired edge length
  link_index : Int // index into series.link_data
}

///|
/// Resolve a node's category index from its raw JSON item.
/// Corresponds to: echarts/src/chart/graph/GraphSeries.ts getNodeCategory
fn graph_item_category(item : @option.DataItem) -> Int? {
  match item.raw_item {
    Some(Object(obj)) =>
      match obj.get("category") {
        Some(Number(n, ..)) => Some(n.to_int())
        _ => None
      }
    _ => None
  }
}

///|
/// Simple deterministic pseudo-random (LCG) for initial placement.
fn graph_lcg(seed : Int) -> Double {
  let a = 1664525
  let c = 1013904223
  let m = 4294967296.0 // 2^32
  let next = (a * seed + c).to_double() % m
  next / m
}

///|
/// linearMap: map a value from [d0,d1] to [r0,r1].
/// Returns NaN-safe midpoint if domain is empty.
/// Corresponds to: echarts/src/util/number.ts linearMap
fn graph_linear_map(
  val : Double,
  d0 : Double,
  d1 : Double,
  r0 : Double,
  r1 : Double,
) -> Double {
  if d1 == d0 {
    (r0 + r1) / 2.0
  } else {
    r0 + (val - d0) / (d1 - d0) * (r1 - r0)
  }
}

///|
/// Run force-directed layout to convergence.
/// Corresponds to: echarts/src/chart/graph/forceHelper.ts forceLayout step loop
fn graph_force_layout(
  nodes : Array[GraphNode],
  edges : Array[GraphEdge],
  cx : Double,
  cy : Double,
  width : Double,
  height : Double,
  gravity : Double,
) -> Unit {
  let n_nodes = nodes.length()
  let n_edges = edges.length()
  if n_nodes == 0 {
    return
  }
  // warmUp: friction = initialFriction * 0.8
  let mut friction = 0.6 * 0.8
  // Run until friction < 0.01 (≈ 477 steps from 0.48), use 600 for safety
  let mut iter = 0
  while iter < 600 {
    iter += 1
    // Spring forces – moves p directly
    let mut ei = 0
    while ei < n_edges {
      let e = edges[ei]
      let n1 = nodes[e.n1]
      let n2 = nodes[e.n2]
      let dx = n2.x - n1.x
      let dy = n2.y - n1.y
      let dist = (dx * dx + dy * dy).sqrt()
      if dist == 0.0 {
        ei = ei + 1
        continue
      }
      let spring = dist - e.d
      let ux = dx / dist
      let uy = dy / dist
      let w_sum = n1.w + n2.w
      let w = if w_sum == 0.0 { 0.5 } else { n2.w / w_sum }
      if !n1.fixed {
        n1.x = n1.x + ux * w * spring * friction
        n1.y = n1.y + uy * w * spring * friction
      }
      if !n2.fixed {
        n2.x = n2.x - ux * (1.0 - w) * spring * friction
        n2.y = n2.y - uy * (1.0 - w) * spring * friction
      }
      ei = ei + 1
    }
    // Gravity – moves p directly toward center
    let mut ni = 0
    while ni < n_nodes {
      let n = nodes[ni]
      if !n.fixed {
        n.x = n.x + (cx - n.x) * gravity * friction
        n.y = n.y + (cy - n.y) * gravity * friction
      }
      ni = ni + 1
    }
    // Repulsion – accumulates into pp (prev position)
    let mut i = 0
    while i < n_nodes {
      let n1 = nodes[i]
      let mut j = i + 1
      while j < n_nodes {
        let n2 = nodes[j]
        let dx = n2.x - n1.x
        let dy = n2.y - n1.y
        let d_sq = dx * dx + dy * dy
        let d = if d_sq == 0.0 { 1.0 } else { d_sq.sqrt() }
        let rep_dx = if d_sq == 0.0 {
          graph_lcg(i * 1000 + j) - 0.5
        } else {
          dx
        }
        let rep_dy = if d_sq == 0.0 {
          graph_lcg(i * 1000 + j + 1) - 0.5
        } else {
          dy
        }
        let rep_fact = (n1.w + n2.w) / d / d
        if !n1.fixed {
          n1.px = n1.px + rep_dx * rep_fact
          n1.py = n1.py + rep_dy * rep_fact
        }
        if !n2.fixed {
          n2.px = n2.px - rep_dx * rep_fact
          n2.py = n2.py - rep_dy * rep_fact
        }
        j = j + 1
      }
      i = i + 1
    }
    // Verlet integration step
    let mut vi = 0
    while vi < n_nodes {
      let n = nodes[vi]
      if !n.fixed {
        let vx = n.x - n.px
        let vy = n.y - n.py
        n.x = n.x + vx * friction
        n.y = n.y + vy * friction
        n.px = n.x
        n.py = n.y
      }
      vi += 1
    }
    friction = friction * 0.992
    if friction < 0.01 {
      break
    }
  }
  // Ignore width/height (used only for bounds initialization)
  let _ = width
  let _ = height
}

///|
/// Render all graph series.
/// Corresponds to: echarts/src/chart/graph/GraphView.ts render
pub fn render_graphs(
  opt : @option.ChartOption,
  _coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut color_idx = 0

  for si, _ in opt.series {
    let series = opt.series[si]
    if series.series_type != @option.SeriesType::Graph {
      color_idx += 1
      continue
    }
    render_graph_series(elems, series, color_idx, opt.width, opt.height)
    color_idx += 1
  }
  elems
}

///|
/// Get node ID string from a DataItem (node).
/// Corresponds to: echarts/src/chart/graph/GraphSeries.ts node id
fn graph_node_id(item : @option.DataItem) -> String {
  match item.id {
    Some(s) => s
    None =>
      match item.name {
        Some(n) => n
        None => ""
      }
  }
}

///|
/// Render a single graph series.
/// Corresponds to: echarts/src/chart/graph/GraphView.ts render + forceLayout
fn render_graph_series(
  elems : Array[@graphic.Element],
  series : @option.SeriesOption,
  series_index : Int,
  chart_width : Double,
  chart_height : Double,
) -> Unit {
  let n_nodes = series.data.length()
  if n_nodes == 0 {
    return
  }

  // Determine render rect (full canvas with small padding)
  let pad = 30.0
  let rect_x = pad
  let rect_y = pad
  let rect_w = chart_width - pad * 2.0
  let rect_h = chart_height - pad * 2.0
  let cx = rect_x + rect_w / 2.0
  let cy = rect_y + rect_h / 2.0

  // --- Compute value extents for repulsion/edgeLength linearMap ---
  // Corresponds to: echarts/src/chart/graph/forceLayout.ts nodeDataExtent
  let mut node_val_min = 0.0
  let mut node_val_max = 0.0
  let mut node_first = true
  let mut nv = 0
  while nv < n_nodes {
    let v = match series.data[nv].value {
      @option.DataValue::Num(n) => n
      _ => 0.0
    }
    if node_first {
      node_val_min = v
      node_val_max = v
      node_first = false
    } else {
      if v < node_val_min {
        node_val_min = v
      }
      if v > node_val_max {
        node_val_max = v
      }
    }
    nv = nv + 1
  }

  let repulsion = series.graph_force_repulsion
  let edge_len = series.graph_force_edge_length

  // Build force nodes with deterministic initial positions
  let force_nodes : Array[GraphNode] = []
  let mut ni = 0
  while ni < n_nodes {
    let item = series.data[ni]
    let v = match item.value {
      @option.DataValue::Num(n) => n
      _ => 0.0
    }
    let rep = graph_linear_map(
      v, node_val_min, node_val_max, repulsion, repulsion,
    )
    // Deterministic initial position: spread nodes across canvas
    let seed1 = ni * 2 + 1
    let seed2 = ni * 2 + 2
    let init_x = rect_x + graph_lcg(seed1) * rect_w
    let init_y = rect_y + graph_lcg(seed2) * rect_h
    force_nodes.push({
      x: init_x,
      y: init_y,
      px: init_x,
      py: init_y,
      w: rep,
      fixed: false,
    })
    ni = ni + 1
  }

  // Build id → index map for edge lookup
  let id_to_idx : Map[String, Int] = {}
  let mut ii = 0
  while ii < n_nodes {
    let id = graph_node_id(series.data[ii])
    if id != "" {
      id_to_idx[id] = ii
    }
    ii = ii + 1
  }

  // Build force edges from series.link_data
  // Corresponds to: echarts/src/chart/graph/forceLayout.ts edges mapping
  let force_edges : Array[GraphEdge] = []
  let n_links = series.link_data.length()
  let mut li = 0
  while li < n_links {
    let link = series.link_data[li]
    let src_id = link.source.unwrap_or("")
    let tgt_id = link.target.unwrap_or("")
    match (id_to_idx.get(src_id), id_to_idx.get(tgt_id)) {
      (Some(s_idx), Some(t_idx)) =>
        force_edges.push({ n1: s_idx, n2: t_idx, d: edge_len, link_index: li })
      _ => ()
    }
    li = li + 1
  }

  // Run layout depending on mode
  // Corresponds to: echarts/src/chart/graph/simpleLayoutHelper.ts simpleLayout
  //                 echarts/src/chart/graph/circularLayoutHelper.ts circularLayout
  if series.graph_layout == "force" {
    graph_force_layout(
      force_nodes,
      force_edges,
      cx,
      cy,
      rect_w,
      rect_h,
      series.graph_force_gravity,
    )
  } else if series.graph_layout == "none" || series.graph_layout == "" {
    // Simple/none layout: use x/y from each node's raw data as pixel offsets
    // relative to the chart rect origin.
    // Corresponds to: echarts/src/chart/graph/simpleLayoutHelper.ts simpleLayout
    let mut ni2 = 0
    while ni2 < n_nodes {
      let item = series.data[ni2]
      match item.raw_item {
        Some(Object(obj)) => {
          let nx = match obj.get("x") {
            Some(Number(n, ..)) => rect_x + n
            _ => force_nodes[ni2].x
          }
          let ny = match obj.get("y") {
            Some(Number(n, ..)) => rect_y + n
            _ => force_nodes[ni2].y
          }
          force_nodes[ni2].x = nx
          force_nodes[ni2].y = ny
        }
        _ => ()
      }
      ni2 += 1
    }
  } else if series.graph_layout == "circular" {
    // Circular layout: place n_nodes evenly on a circle.
    // Corresponds to: echarts/src/chart/graph/circularLayoutHelper.ts circularLayout
    let circ_r = (if rect_w < rect_h { rect_w } else { rect_h }) / 2.0
    let twopi = 6.283185307179586
    let mut ni2 = 0
    while ni2 < n_nodes {
      let angle = twopi * ni2.to_double() / n_nodes.to_double()
      force_nodes[ni2].x = cx + circ_r * @math.cos(angle)
      force_nodes[ni2].y = cy + circ_r * @math.sin(angle)
      ni2 += 1
    }
  }

  // ---- Rendering ----
  // Default node symbol size: 10px (ECharts default symbolSize for graph)
  let sym_size = if series.symbol_size > 0.0 {
    series.symbol_size
  } else {
    10.0
  }
  let node_r = sym_size / 2.0

  // Category → color mapping (palette index = category index)
  // Corresponds to: echarts/src/chart/graph/categoryVisual.ts
  let n_cats = series.graph_categories.length()
  let any_node_highlighted = @visual.has_any_highlighted(series.data)
  let any_edge_highlighted = @visual.has_any_highlighted(series.link_data)
  let any_highlighted = any_node_highlighted || any_edge_highlighted

  // Render edges first (below nodes)
  let mut ej = 0
  while ej < force_edges.length() {
    let fe = force_edges[ej]
    let n1 = force_nodes[fe.n1]
    let n2 = force_nodes[fe.n2]
    let edge_color = match series.line_style_color {
      Some(c) => c
      None => "#aaaaaa"
    }
    let edge_width = series.line_style_width.unwrap_or(1.0)
    let edge_opacity = series.line_style_opacity.unwrap_or(0.5)
    let link_item = if fe.link_index >= 0 &&
      fe.link_index < series.link_data.length() {
      Some(series.link_data[fe.link_index])
    } else {
      None
    }
    let item_highlighted = link_item.map_or(false, item => {
      item.highlighted == Some(true)
    })
    let emphasis_color = if item_highlighted {
      @visual.lift_hex_color(edge_color)
    } else {
      edge_color
    }
    let emphasis_style : @graphic.DisplayStateStyle = {
      fill: None,
      stroke: Some(emphasis_color),
      line_width: None,
      stroke_no_scale: false,
    }
    let blur_style : @graphic.DisplayStateStyle = {
      fill: None,
      stroke: None,
      line_width: None,
      stroke_no_scale: false,
    }
    let edge_elem = @graphic.Element::line_colored_dashed(
      n1.x,
      n1.y,
      n2.x,
      n2.y,
      edge_color,
      edge_width,
      [],
      edge_opacity,
    )
    elems.push(
      if any_highlighted {
        edge_elem
        .with_emphasis_style(emphasis_style)
        .with_blur_style(blur_style)
      } else {
        edge_elem
      },
    )
    ej = ej + 1
  }

  // Render nodes and labels
  let label_show = match series.label {
    Some(l) => l.show
    None => true
  }
  let label_position = match series.label {
    Some(l) => l.position.unwrap_or("right")
    None => "right"
  }
  let label_color = match series.label {
    Some(l) => l.color
    None => "#333"
  }
  let label_font_size = match series.label {
    Some(l) => l.font_size
    None => 12.0
  }
  let use_rotated_label = series.graph_layout == "circular" &&
    series.graph_circular_rotate_label

  let mut nri = 0
  while nri < n_nodes {
    let item = series.data[nri]
    let fn_node = force_nodes[nri]

    // Determine node color: item.item_style.color > category color > palette
    let cat_idx = graph_item_category(item)
    let fill_color = match item.item_style {
      Some(style) =>
        style.color.unwrap_or(
          match cat_idx {
            Some(ci) =>
              @visual.palette_color(ci % (if n_cats > 0 { n_cats } else { 9 }))
            None => @visual.palette_color(series_index)
          },
        )
      None =>
        match cat_idx {
          Some(ci) =>
            @visual.palette_color(ci % (if n_cats > 0 { n_cats } else { 9 }))
          None => @visual.palette_color(series_index)
        }
    }
    let item_highlighted = item.highlighted == Some(true)
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
    let node_elem = @graphic.Element::circle_fill_stroke(
      fn_node.x,
      fn_node.y,
      node_r,
      fill_color,
      "#ffffff",
      1.0,
    )
    elems.push(
      if any_highlighted {
        node_elem
        .with_emphasis_style(emphasis_style)
        .with_blur_style(blur_style)
      } else {
        node_elem
      },
    )

    // Render label
    if label_show {
      let label_text = match item.name {
        Some(s) => s
        None => ""
      }
      if label_text != "" {
        if use_rotated_label {
          // Compute angle of this node relative to center
          let angle_rad = @math.atan2(fn_node.y - cy, fn_node.x - cx)
          // Place label at the outer edge of the node
          let lx = fn_node.x + (node_r + 4.0) * @math.cos(angle_rad)
          let ly = fn_node.y + (node_r + 4.0) * @math.sin(angle_rad)
          // with_rotation takes radians
          let _ = label_font_size
          elems.push(
            @graphic.Element::text_colored(
              lx,
              ly,
              label_text,
              @graphic.TextAnchor::Start,
              @graphic.TextBaseline::Middle,
              label_color,
            ).with_rotation(angle_rad),
          )
        } else {
          let (lx, ly, anchor, baseline) = match label_position {
            "right" =>
              (
                fn_node.x + node_r + 3.0,
                fn_node.y,
                @graphic.TextAnchor::Start,
                @graphic.TextBaseline::Middle,
              )
            "left" =>
              (
                fn_node.x - node_r - 3.0,
                fn_node.y,
                @graphic.TextAnchor::End,
                @graphic.TextBaseline::Middle,
              )
            "top" =>
              (
                fn_node.x,
                fn_node.y - node_r - 3.0,
                @graphic.TextAnchor::Middle,
                @graphic.TextBaseline::Bottom,
              )
            "bottom" =>
              (
                fn_node.x,
                fn_node.y + node_r + 3.0,
                @graphic.TextAnchor::Middle,
                @graphic.TextBaseline::Hanging,
              )
            _ =>
              (
                fn_node.x + node_r + 3.0,
                fn_node.y,
                @graphic.TextAnchor::Start,
                @graphic.TextBaseline::Middle,
              )
          }
          let _ = label_font_size
          elems.push(
            @graphic.Element::text_colored(
              lx, ly, label_text, anchor, baseline, label_color,
            ),
          )
        }
      }
    }
    nri = nri + 1
  }
}

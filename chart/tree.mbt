// Corresponds to: echarts/src/chart/tree/TreeSeries.ts
//                  echarts/src/chart/tree/TreeView.ts
//                  echarts/src/chart/tree/treeLayout.ts
//                  echarts/src/chart/tree/layoutHelper.ts (Reingold-Tilford)
//                  echarts/src/chart/tree/traversalHelper.ts
//                  echarts/src/chart/tree/treeVisual.ts
//                  echarts/src/data/Tree.ts

// ----- Tree node data structure (corresponds to echarts/src/data/Tree.ts) -----

///|
priv struct TreeNode {
  name : String
  mut depth : Int
  mut height : Int
  mut parent_node : TreeNode?
  mut data_index : Int
  children : Array[TreeNode]
  mut is_expand : Bool
  // layout result
  mut layout_x : Double
  mut layout_y : Double
  // for radial
  mut raw_x : Double
  mut raw_y : Double
  // hierNode fields (Reingold-Tilford)
  mut default_ancestor : TreeNode?
  mut ancestor : TreeNode?
  mut prelim : Double
  mut modifier : Double
  mut change : Double
  mut shift : Double
  mut hier_i : Int
  mut thread : TreeNode?
  // original DataItem reference
  item : @option.DataItem
}

///|
fn TreeNode::new(name : String, item : @option.DataItem) -> TreeNode {
  let node : TreeNode = {
    name,
    depth: 0,
    height: 0,
    parent_node: None,
    data_index: -1,
    children: [],
    is_expand: false,
    layout_x: 0.0,
    layout_y: 0.0,
    raw_x: 0.0,
    raw_y: 0.0,
    default_ancestor: None,
    ancestor: None,
    prelim: 0.0,
    modifier: 0.0,
    change: 0.0,
    shift: 0.0,
    hier_i: 0,
    thread: None,
    item,
  }
  node.ancestor = Some(node)
  node
}

///|
fn TreeNode::update_depth_and_height(self : TreeNode, depth : Int) -> Unit {
  self.depth = depth
  let mut max_child_height = 0
  let mut i = 0
  while i < self.children.length() {
    let child = self.children[i]
    child.update_depth_and_height(depth + 1)
    if child.height > max_child_height {
      max_child_height = child.height
    }
    i += 1
  }
  self.height = max_child_height + 1
}

// ----- Build tree from DataItem[] (corresponds to Tree.createTree) -----

///|
fn tree_build(
  data : Array[@option.DataItem],
  series_name : String?,
) -> TreeNode {
  // ECharts TreeSeries.getInitialData creates:
  //   root = { name: option.name, children: option.data }
  //   tree = Tree.createTree(root, ...)
  // tree.root is the wrapper node, tree.root.children[0] is data[0].
  // We mirror that structure: virtual_root.children = built hierarchy from data.
  let wrapper_item = @option.DataItem::{
    value: @option.DataValue::Null,
    raw_value_parts: None,
    raw_item: None,
    name: series_name,
    symbol: None,
    coords: None,
    from_name: None,
    to_name: None,
    cursor: None,
    selected: None,
    silent: None,
    label: None,
    item_style: None,
    states: @option.GeoStatesOption::default(),
    children: data,
    collapsed: None,
  }
  let all_nodes : Array[TreeNode] = []
  let virtual_root = tree_build_hierarchy(wrapper_item, all_nodes)
  virtual_root.is_expand = true
  virtual_root.update_depth_and_height(0)
  // assign data_index in preorder (using unconditional traversal)
  let mut idx = 0
  let stack : Array[TreeNode] = [virtual_root]
  while stack.length() > 0 {
    let node = stack.pop().unwrap()
    node.data_index = idx
    idx += 1
    let mut i = node.children.length() - 1
    while i >= 0 {
      stack.push(node.children[i])
      i -= 1
    }
  }
  virtual_root
}

///|
fn tree_build_hierarchy(
  item : @option.DataItem,
  all_nodes : Array[TreeNode],
) -> TreeNode {
  let name = item.name.unwrap_or("")
  let node = TreeNode::new(name, item)
  all_nodes.push(node)
  let mut i = 0
  while i < item.children.length() {
    let child = tree_build_hierarchy(item.children[i], all_nodes)
    child.parent_node = Some(node)
    node.children.push(child)
    i += 1
  }
  node
}

// ----- Traversal helpers (corresponds to traversalHelper.ts) -----

///|
/// Traverse tree bottom-up (postorder).
fn tree_each_after(root : TreeNode, callback : (TreeNode) -> Unit) -> Unit {
  let nodes : Array[TreeNode] = [root]
  let next : Array[TreeNode] = []
  while nodes.length() > 0 {
    let node = nodes.pop().unwrap()
    next.push(node)
    if node.is_expand {
      let mut i = 0
      while i < node.children.length() {
        nodes.push(node.children[i])
        i += 1
      }
    }
  }
  while next.length() > 0 {
    let node = next.pop().unwrap()
    callback(node)
  }
}

///|
/// Traverse tree top-down (preorder).
fn tree_each_before(root : TreeNode, callback : (TreeNode) -> Unit) -> Unit {
  let nodes : Array[TreeNode] = [root]
  while nodes.length() > 0 {
    let node = nodes.pop().unwrap()
    callback(node)
    if node.is_expand {
      let mut i = node.children.length() - 1
      while i >= 0 {
        nodes.push(node.children[i])
        i -= 1
      }
    }
  }
}

// ----- Layout helpers (Reingold-Tilford, corresponds to layoutHelper.ts) -----

///|
/// Initialize hierNode fields for all expanded subtree nodes.
fn tree_layout_init(in_root : TreeNode) -> Unit {
  in_root.default_ancestor = None
  in_root.ancestor = Some(in_root)
  in_root.prelim = 0.0
  in_root.modifier = 0.0
  in_root.change = 0.0
  in_root.shift = 0.0
  in_root.hier_i = 0
  in_root.thread = None
  let nodes : Array[TreeNode] = [in_root]
  while nodes.length() > 0 {
    let node = nodes.pop().unwrap()
    let children = node.children
    if node.is_expand && children.length() > 0 {
      let mut i = children.length() - 1
      while i >= 0 {
        let child = children[i]
        child.default_ancestor = None
        child.ancestor = Some(child)
        child.prelim = 0.0
        child.modifier = 0.0
        child.change = 0.0
        child.shift = 0.0
        child.hier_i = i
        child.thread = None
        nodes.push(child)
        i -= 1
      }
    }
  }
}

///|
fn tree_default_separation(node1 : TreeNode, node2 : TreeNode) -> Double {
  match (node1.parent_node, node2.parent_node) {
    (Some(p1), Some(p2)) => if physical_equal(p1, p2) { 1.0 } else { 2.0 }
    _ => 2.0
  }
}

///|
fn tree_execute_shifts(node : TreeNode) -> Unit {
  let children = node.children
  let mut n = children.length() - 1
  let mut shift = 0.0
  let mut change = 0.0
  while n >= 0 {
    let child = children[n]
    child.prelim = child.prelim + shift
    child.modifier = child.modifier + shift
    change = change + child.change
    shift = shift + child.shift + change
    n -= 1
  }
}

///|
fn tree_next_right(node : TreeNode) -> TreeNode? {
  let children = node.children
  if children.length() > 0 && node.is_expand {
    Some(children[children.length() - 1])
  } else {
    node.thread
  }
}

///|
fn tree_next_left(node : TreeNode) -> TreeNode? {
  let children = node.children
  if children.length() > 0 && node.is_expand {
    Some(children[0])
  } else {
    node.thread
  }
}

///|
fn tree_next_ancestor(
  node_in_left : TreeNode,
  node : TreeNode,
  ancestor : TreeNode,
) -> TreeNode {
  match node_in_left.ancestor {
    Some(anc) =>
      match anc.parent_node {
        Some(anc_parent) =>
          match node.parent_node {
            Some(node_parent) =>
              if physical_equal(anc_parent, node_parent) {
                anc
              } else {
                ancestor
              }
            _ => ancestor
          }
        _ => ancestor
      }
    _ => ancestor
  }
}

///|
fn tree_move_subtree(wl : TreeNode, wr : TreeNode, shift : Double) -> Unit {
  let diff = wr.hier_i - wl.hier_i
  let change = if diff != 0 { shift / diff.to_double() } else { 0.0 }
  wr.change = wr.change - change
  wr.shift = wr.shift + shift
  wr.modifier = wr.modifier + shift
  wr.prelim = wr.prelim + shift
  wl.change = wl.change + change
}

///|
fn tree_apportion(
  subtree_v : TreeNode,
  subtree_w : TreeNode?,
  ancestor : TreeNode,
) -> TreeNode {
  match subtree_w {
    None => ancestor
    Some(sw) => {
      let mut node_out_right = subtree_v
      let mut node_in_right = subtree_v
      let mut node_in_left = sw
      let node_out_left_opt = match node_in_right.parent_node {
        Some(p) =>
          if p.children.length() > 0 {
            Some(p.children[0])
          } else {
            None
          }
        None => None
      }
      let mut node_out_left = match node_out_left_opt {
        Some(n) => n
        None => return ancestor
      }
      let mut sum_out_right = node_out_right.modifier
      let mut sum_in_right = node_in_right.modifier
      let mut sum_out_left = node_out_left.modifier
      let mut sum_in_left = node_in_left.modifier
      let mut result_ancestor = ancestor
      // Traverse inner contours
      while true {
        let next_in_left = tree_next_right(node_in_left)
        let next_in_right = tree_next_left(node_in_right)
        match (next_in_left, next_in_right) {
          (Some(nil), Some(nir)) => {
            node_in_left = nil
            node_in_right = nir
            match tree_next_right(node_out_right) {
              Some(nor) => node_out_right = nor
              None => break
            }
            match tree_next_left(node_out_left) {
              Some(nol) => node_out_left = nol
              None => break
            }
            node_out_right.ancestor = Some(subtree_v)
            let shift = node_in_left.prelim +
              sum_in_left -
              node_in_right.prelim -
              sum_in_right +
              tree_default_separation(node_in_left, node_in_right)
            if shift > 0.0 {
              tree_move_subtree(
                tree_next_ancestor(node_in_left, subtree_v, result_ancestor),
                subtree_v,
                shift,
              )
              sum_in_right = sum_in_right + shift
              sum_out_right = sum_out_right + shift
            }
            sum_in_left = sum_in_left + node_in_left.modifier
            sum_in_right = sum_in_right + node_in_right.modifier
            sum_out_right = sum_out_right + node_out_right.modifier
            sum_out_left = sum_out_left + node_out_left.modifier
          }
          _ => break
        }
      }
      // Set threads
      match tree_next_right(node_in_left) {
        Some(nil) =>
          match tree_next_right(node_out_right) {
            None => {
              node_out_right.thread = Some(nil)
              node_out_right.modifier = node_out_right.modifier +
                sum_in_left -
                sum_out_right
            }
            Some(_) => ()
          }
        None => ()
      }
      match tree_next_left(node_in_right) {
        Some(nir) =>
          match tree_next_left(node_out_left) {
            None => {
              node_out_left.thread = Some(nir)
              node_out_left.modifier = node_out_left.modifier +
                sum_in_right -
                sum_out_left
              result_ancestor = subtree_v
            }
            Some(_) => ()
          }
        None => ()
      }
      result_ancestor
    }
  }
}

///|
/// Reingold-Tilford first walk (postorder)
fn tree_first_walk(node : TreeNode) -> Unit {
  let children = if node.is_expand { node.children } else { [] }
  let siblings = match node.parent_node {
    Some(p) => p.children
    None => []
  }
  let subtree_w : TreeNode? = if node.hier_i > 0 {
    Some(siblings[node.hier_i - 1])
  } else {
    None
  }
  if children.length() > 0 {
    tree_execute_shifts(node)
    let midpoint = (children[0].prelim + children[children.length() - 1].prelim) /
      2.0
    match subtree_w {
      Some(sw) => {
        node.prelim = sw.prelim + tree_default_separation(node, sw)
        node.modifier = node.prelim - midpoint
      }
      None => node.prelim = midpoint
    }
  } else {
    match subtree_w {
      Some(sw) => node.prelim = sw.prelim + tree_default_separation(node, sw)
      None => ()
    }
  }
  match node.parent_node {
    Some(parent) =>
      parent.default_ancestor = Some(
        tree_apportion(
          node,
          subtree_w,
          parent.default_ancestor.unwrap_or(siblings[0]),
        ),
      )
    None => ()
  }
}

///|
/// Reingold-Tilford second walk (preorder)
fn tree_second_walk(node : TreeNode) -> Unit {
  let parent_modifier = match node.parent_node {
    Some(p) => p.modifier
    None => 0.0
  }
  let node_x = node.prelim + parent_modifier
  node.layout_x = node_x
  node.modifier = node.modifier + parent_modifier
}

///|
fn tree_radial_coordinate(rad : Double, r : Double) -> (Double, Double) {
  let a = rad - @math.PI / 2.0
  (r * @math.cos(a), r * @math.sin(a))
}

// ----- Expand/collapse logic (corresponds to TreeSeries.getInitialData) -----

///|
fn tree_set_expand_state(
  root : TreeNode,
  expand_and_collapse : Bool,
  initial_depth : Int,
) -> Unit {
  // Find max depth - traverse ALL nodes regardless of current expand state
  let mut max_depth = 0
  let nodes : Array[TreeNode] = [root]
  while nodes.length() > 0 {
    let node = nodes.pop().unwrap()
    if node.depth > max_depth {
      max_depth = node.depth
    }
    let mut i = 0
    while i < node.children.length() {
      nodes.push(node.children[i])
      i += 1
    }
  }
  let expand_depth = if expand_and_collapse && initial_depth >= 0 {
    initial_depth + root.depth // make relative to root's depth
  } else {
    max_depth
  }
  // Set expand state for all nodes
  let nodes2 : Array[TreeNode] = [root]
  while nodes2.length() > 0 {
    let node = nodes2.pop().unwrap()
    node.is_expand = match node.item.collapsed {
      Some(c) => not(c)
      None => node.depth <= expand_depth
    }
    let mut i = 0
    while i < node.children.length() {
      nodes2.push(node.children[i])
      i += 1
    }
  }
}

// ----- Main layout (corresponds to treeLayout.ts) -----

///|
fn tree_common_layout(
  virtual_root : TreeNode,
  layout_info_x : Double,
  layout_info_y : Double,
  layout_info_width : Double,
  layout_info_height : Double,
  layout : String,
  orient : String,
) -> Unit {
  let real_root = if virtual_root.children.length() > 0 {
    virtual_root.children[0]
  } else {
    return
  }
  let mut width = 0.0
  let mut height = 0.0
  if layout == "radial" {
    width = 2.0 * @math.PI
    let min_dim = if layout_info_height < layout_info_width {
      layout_info_height
    } else {
      layout_info_width
    }
    height = min_dim / 2.0
  } else {
    width = layout_info_width
    height = layout_info_height
  }
  // init + first walk + second walk
  tree_layout_init(virtual_root)
  tree_each_after(real_root, fn(node) { tree_first_walk(node) })
  virtual_root.modifier = -real_root.prelim
  tree_each_before(real_root, fn(node) { tree_second_walk(node) })
  // find bounds
  let mut left_node = real_root
  let mut right_node = real_root
  let mut bottom_node = real_root
  tree_each_before(real_root, fn(node) {
    if node.layout_x < left_node.layout_x {
      left_node = node
    }
    if node.layout_x > right_node.layout_x {
      right_node = node
    }
    if node.depth > bottom_node.depth {
      bottom_node = node
    }
  })
  let delta = if physical_equal(left_node, right_node) {
    1.0
  } else {
    tree_default_separation(left_node, right_node) / 2.0
  }
  let tx = delta - left_node.layout_x
  let depth_range = (bottom_node.depth - 1).to_double()
  let depth_divisor = if depth_range == 0.0 { 1.0 } else { depth_range }
  if layout == "radial" {
    let kx = width / (right_node.layout_x + delta + tx)
    let ky = height / depth_divisor
    tree_each_before(real_root, fn(node) {
      let coor_x = (node.layout_x + tx) * kx
      let coor_y = (node.depth - 1).to_double() * ky
      let (fx, fy) = tree_radial_coordinate(coor_x, coor_y)
      node.layout_x = fx
      node.layout_y = fy
      node.raw_x = coor_x
      node.raw_y = coor_y
    })
  } else if orient == "RL" || orient == "LR" {
    let ky = height / (right_node.layout_x + delta + tx)
    let kx = width / depth_divisor
    tree_each_before(real_root, fn(node) {
      let coor_y = (node.layout_x + tx) * ky
      let coor_x = if orient == "LR" {
        (node.depth - 1).to_double() * kx
      } else {
        width - (node.depth - 1).to_double() * kx
      }
      node.layout_x = coor_x
      node.layout_y = coor_y
    })
  } else {
    // TB or BT
    let kx = width / (right_node.layout_x + delta + tx)
    let ky = height / depth_divisor
    tree_each_before(real_root, fn(node) {
      let coor_x = (node.layout_x + tx) * kx
      let coor_y = if orient == "TB" {
        (node.depth - 1).to_double() * ky
      } else {
        height - (node.depth - 1).to_double() * ky
      }
      node.layout_x = coor_x
      node.layout_y = coor_y
    })
  }
  // offset to layout info position
  let offset_x = layout_info_x
  let offset_y = layout_info_y
  if layout == "radial" {
    let cx = layout_info_x + layout_info_width / 2.0
    let cy = layout_info_y + layout_info_height / 2.0
    tree_each_before(real_root, fn(node) {
      node.layout_x = node.layout_x + cx
      node.layout_y = node.layout_y + cy
    })
  } else {
    tree_each_before(real_root, fn(node) {
      node.layout_x = node.layout_x + offset_x
      node.layout_y = node.layout_y + offset_y
    })
  }
}

// ----- Edge drawing (corresponds to TreeView.ts getEdgeShape/drawEdge) -----

///|
fn tree_get_edge_shape_curve(
  orient : String,
  curvature : Double,
  source_x : Double,
  source_y : Double,
  target_x : Double,
  target_y : Double,
) -> String {
  let mut cpx1 = 0.0
  let mut cpy1 = 0.0
  let mut cpx2 = 0.0
  let mut cpy2 = 0.0
  if orient == "LR" || orient == "RL" {
    cpx1 = source_x + (target_x - source_x) * curvature
    cpy1 = source_y
    cpx2 = target_x + (source_x - target_x) * curvature
    cpy2 = target_y
  } else {
    // TB or BT
    cpx1 = source_x
    cpy1 = source_y + (target_y - source_y) * curvature
    cpx2 = target_x
    cpy2 = target_y + (source_y - target_y) * curvature
  }
  "M\{tree_r4(source_x)} \{tree_r4(source_y)}C\{tree_r4(cpx1)} \{tree_r4(cpy1)} \{tree_r4(cpx2)} \{tree_r4(cpy2)} \{tree_r4(target_x)} \{tree_r4(target_y)}"
}

///|
fn tree_get_edge_shape_curve_radial(
  curvature : Double,
  source_raw_x : Double,
  source_raw_y : Double,
  target_raw_x : Double,
  target_raw_y : Double,
  offset_x : Double,
  offset_y : Double,
) -> String {
  let (x1, y1) = tree_radial_coordinate(source_raw_x, source_raw_y)
  let mid_raw_y1 = source_raw_y + (target_raw_y - source_raw_y) * curvature
  let (cx1, cy1) = tree_radial_coordinate(source_raw_x, mid_raw_y1)
  let mid_raw_y2 = target_raw_y + (source_raw_y - target_raw_y) * curvature
  let (cx2, cy2) = tree_radial_coordinate(target_raw_x, mid_raw_y2)
  let (x2, y2) = tree_radial_coordinate(target_raw_x, target_raw_y)
  "M\{tree_r4(x1 + offset_x)} \{tree_r4(y1 + offset_y)}C\{tree_r4(cx1 + offset_x)} \{tree_r4(cy1 + offset_y)} \{tree_r4(cx2 + offset_x)} \{tree_r4(cy2 + offset_y)} \{tree_r4(x2 + offset_x)} \{tree_r4(y2 + offset_y)}"
}

///|
fn tree_get_edge_shape_polyline(
  orient : String,
  fork_position_pct : Double,
  parent_x : Double,
  parent_y : Double,
  child_points : Array[(Double, Double)],
) -> String {
  if child_points.length() == 0 {
    return ""
  }
  if child_points.length() == 1 {
    let (cx, cy) = child_points[0]
    return "M\{tree_r4(parent_x)} \{tree_r4(parent_y)}L\{tree_r4(cx)} \{tree_r4(cy)}"
  }
  let fork_dim_is_x = orient == "TB" || orient == "BT"
  let buf = StringBuilder::new()
  // parent -> fork point
  let (first_cx, first_cy) = child_points[0]
  let (last_cx, last_cy) = child_points[child_points.length() - 1]
  let mut fork_x = 0.0
  let mut fork_y = 0.0
  if fork_dim_is_x {
    fork_x = parent_x
    fork_y = parent_y + (last_cy - parent_y) * fork_position_pct
  } else {
    fork_x = parent_x + (last_cx - parent_x) * fork_position_pct
    fork_y = parent_y
  }
  buf.write_string(
    "M\{tree_r4(parent_x)} \{tree_r4(parent_y)}L\{tree_r4(fork_x)} \{tree_r4(fork_y)}",
  )
  // horizontal/vertical line through first->last child
  buf.write_string("M\{tree_r4(first_cx)} \{tree_r4(first_cy)}")
  if fork_dim_is_x {
    buf.write_string(
      "L\{tree_r4(first_cx)} \{tree_r4(fork_y)}L\{tree_r4(last_cx)} \{tree_r4(fork_y)}L\{tree_r4(last_cx)} \{tree_r4(last_cy)}",
    )
  } else {
    buf.write_string(
      "L\{tree_r4(fork_x)} \{tree_r4(first_cy)}L\{tree_r4(fork_x)} \{tree_r4(last_cy)}L\{tree_r4(last_cx)} \{tree_r4(last_cy)}",
    )
  }
  // branches for middle children
  let mut i = 1
  while i < child_points.length() - 1 {
    let (cx, cy) = child_points[i]
    buf.write_string("M\{tree_r4(cx)} \{tree_r4(cy)}")
    if fork_dim_is_x {
      buf.write_string("L\{tree_r4(cx)} \{tree_r4(fork_y)}")
    } else {
      buf.write_string("L\{tree_r4(fork_x)} \{tree_r4(cy)}")
    }
    i += 1
  }
  buf.to_string()
}

///|
fn tree_r4(v : Double) -> String {
  let rounded = (v * 10000.0).round() / 10000.0
  if rounded == rounded.to_int().to_double() {
    rounded.to_int().to_string()
  } else {
    rounded.to_string()
  }
}

///|
fn tree_circle_fill_stroke(
  cx : Double,
  cy : Double,
  r : Double,
  fill_str : String,
  stroke_str : String,
  stroke_width : Double,
) -> @graphic.Element {
  @graphic.Element::circle_fill_stroke(
    cx, cy, r, fill_str, stroke_str, stroke_width,
  )
}

///|
fn tree_parse_percent(s : String, base : Double) -> Double {
  if s.length() > 0 && s[s.length() - 1] == '%' {
    let pct_str = s[:s.length() - 1].to_string()
    let parsed = try? @strconv.parse_double(pct_str)
    match parsed {
      Ok(n) => n / 100.0 * base
      Err(_) => 0.0
    }
  } else {
    let parsed = try? @strconv.parse_double(s)
    match parsed {
      Ok(n) => n
      Err(_) => 0.0
    }
  }
}

// ----- Render function (corresponds to TreeView.ts render) -----

///|
pub fn render_trees(
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
      Tree => ()
      _ => {
        color_idx += 1
        continue
      }
    }
    let series_elems = render_tree_series(
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
    color_idx += 1
  }
  elems
}

///|
fn render_tree_series(
  series : @option.SeriesOption,
  series_index : Int,
  chart_width : Double,
  chart_height : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  if series.data.length() == 0 {
    return elems
  }
  // Build tree
  let virtual_root = tree_build(series.data, series.name)
  let real_root = if virtual_root.children.length() > 0 {
    virtual_root.children[0]
  } else {
    return elems
  }
  // Expand/collapse
  tree_set_expand_state(
    real_root,
    series.tree_expand_and_collapse,
    series.tree_initial_depth,
  )
  // Also ensure virtual_root is always expanded
  virtual_root.is_expand = true
  // Compute layout rect
  let layout = series.tree_layout
  let orient = tree_resolve_orient(series.tree_orient)
  let left = tree_parse_percent(series.tree_left, chart_width)
  let top = tree_parse_percent(series.tree_top, chart_height)
  let right = tree_parse_percent(series.tree_right, chart_width)
  let bottom = tree_parse_percent(series.tree_bottom, chart_height)
  let lx = left
  let ly = top
  let lw = chart_width - left - right
  let lh = chart_height - top - bottom
  // Run layout
  tree_common_layout(virtual_root, lx, ly, lw, lh, layout, orient)
  // Rendering
  let curvature = series.line_style_curveness.unwrap_or(0.5)
  let line_width = series.line_style_width.unwrap_or(1.5)
  let edge_shape = series.tree_edge_shape
  let edge_color = series.line_style_color.unwrap_or("#cfd2d7") // tokens.color.borderTint
  let symbol_size = series.symbol_size
  let fork_pct = tree_parse_percent(series.tree_edge_fork_position, 1.0)
  // Draw edges first, then nodes on top
  // curve edges: from parent to each child
  if edge_shape == "curve" {
    tree_each_before(real_root, fn(node) {
      if node.is_expand {
        let mut ci = 0
        while ci < node.children.length() {
          let child = node.children[ci]
          ci += 1
          let path_d = if layout == "radial" {
            let cx = lx + lw / 2.0
            let cy = ly + lh / 2.0
            tree_get_edge_shape_curve_radial(
              curvature,
              node.raw_x,
              node.raw_y,
              child.raw_x,
              child.raw_y,
              cx,
              cy,
            )
          } else {
            tree_get_edge_shape_curve(
              orient,
              curvature,
              node.layout_x,
              node.layout_y,
              child.layout_x,
              child.layout_y,
            )
          }
          elems.push(
            @graphic.Element::path_stroke_custom(
              path_d, edge_color, line_width, "butt", "miter", 1.0,
            ),
          )
        }
      }
    })
  } else if edge_shape == "polyline" && layout != "radial" {
    // polyline edges: from parent node, fan out to all children
    tree_each_before(real_root, fn(node) {
      if node.is_expand && node.children.length() > 0 {
        let child_points : Array[(Double, Double)] = []
        let mut ci = 0
        while ci < node.children.length() {
          let c = node.children[ci]
          child_points.push((c.layout_x, c.layout_y))
          ci += 1
        }
        let path_d = tree_get_edge_shape_polyline(
          orient,
          fork_pct,
          node.layout_x,
          node.layout_y,
          child_points,
        )
        elems.push(
          @graphic.Element::path_stroke_custom(
            path_d, edge_color, line_width, "butt", "miter", 1.0,
          ),
        )
      }
    })
  }
  // Draw nodes
  tree_each_before(real_root, fn(node) {
    let x = node.layout_x
    let y = node.layout_y
    // symbolInnerColor: collapsed non-leaf → visualColor, otherwise → neutral00
    let is_collapsed_nonleaf = not(node.is_expand) && node.children.length() > 0
    let fill_color = if is_collapsed_nonleaf {
      "#b0c4de" // lightsteelblue (default itemStyle.color)
    } else {
      "#fff" // tokens.color.neutral00
    }
    let stroke_color = "#b0c4de" // lightsteelblue (default itemStyle.color / visualColor)
    let is_leaf = node.children.length() == 0
    let half_size = symbol_size / 2.0
    if layout == "radial" {
      let cx = lx + lw / 2.0
      let cy = ly + lh / 2.0
      elems.push(
        tree_circle_fill_stroke(
          x + cx,
          y + cy,
          half_size,
          fill_color,
          stroke_color,
          1.5,
        ),
      )
    } else {
      elems.push(
        tree_circle_fill_stroke(x, y, half_size, fill_color, stroke_color, 1.5),
      )
    }
    // Node label
    let label_text = node.name
    if label_text.length() > 0 {
      let (lbl_x, lbl_y, anchor) : (Double, Double, @graphic.TextAnchor) = if layout ==
        "radial" {
        let cx = lx + lw / 2.0
        let cy = ly + lh / 2.0
        (x + cx, y + cy - half_size - 4.0, @graphic.TextAnchor::Middle)
      } else if orient == "LR" || orient == "RL" {
        if is_leaf {
          if orient == "LR" {
            (x + half_size + 5.0, y, @graphic.TextAnchor::Start)
          } else {
            (x - half_size - 5.0, y, @graphic.TextAnchor::End)
          }
        } else if orient == "LR" {
          (x - half_size - 5.0, y, @graphic.TextAnchor::End)
        } else {
          (x + half_size + 5.0, y, @graphic.TextAnchor::Start)
        }
        // TB or BT
      } else if is_leaf {
        if orient == "TB" {
          (x, y + half_size + 12.0, @graphic.TextAnchor::Middle)
        } else {
          (x, y - half_size - 4.0, @graphic.TextAnchor::Middle)
        }
      } else if orient == "TB" {
        (x, y - half_size - 4.0, @graphic.TextAnchor::Middle)
      } else {
        (x, y + half_size + 12.0, @graphic.TextAnchor::Middle)
      }
      let baseline : @graphic.TextBaseline = if layout == "radial" ||
        orient == "LR" ||
        orient == "RL" {
        @graphic.TextBaseline::Middle
      } else {
        @graphic.TextBaseline::Auto
      }
      elems.push(
        @graphic.Element::text_colored(
          lbl_x, lbl_y, label_text, anchor, baseline, "#333",
        ),
      )
    }
  })
  elems
}

///|
fn tree_resolve_orient(orient : String) -> String {
  if orient == "horizontal" {
    "LR"
  } else if orient == "vertical" {
    "TB"
  } else {
    orient
  }
}

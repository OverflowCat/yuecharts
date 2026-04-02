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
    id: None,
    name: series_name,
    source: None,
    target: None,
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

///|
priv struct TreeResolvedNodeStyle {
  visual_color : String
  stroke_color : String
  stroke_width : Double
  symbol_size : Double
}

///|
priv struct TreeResolvedLineStyle {
  color : String
  width : Double
  opacity : Double
  curveness : Double
}

///|
priv struct TreeResolvedLabelStyle {
  show : Bool
  color : String
  position : String?
  distance : Double
  font_weight : String
  rotate : Double?
  font_size : Double
  font_family : String
}

///|
fn tree_json_field(j : Json, key : String) -> Json? {
  match j {
    Object(map) => map.get(key)
    _ => None
  }
}

///|
fn tree_raw_field(item : @option.DataItem, key : String) -> Json? {
  match item.raw_item {
    Some(raw) => tree_json_field(raw, key)
    None => None
  }
}

///|
fn tree_raw_number_opt(item : @option.DataItem, key : String) -> Double? {
  match tree_raw_field(item, key) {
    Some(Number(n, ..)) => Some(n)
    _ => None
  }
}

///|
fn tree_raw_style_string_opt(
  item : @option.DataItem,
  style_key : String,
  key : String,
) -> String? {
  match tree_raw_field(item, style_key) {
    Some(style_json) =>
      match tree_json_field(style_json, key) {
        Some(String(s)) => Some(s)
        _ => None
      }
    None => None
  }
}

///|
fn tree_raw_style_number_opt(
  item : @option.DataItem,
  style_key : String,
  key : String,
) -> Double? {
  match tree_raw_field(item, style_key) {
    Some(style_json) =>
      match tree_json_field(style_json, key) {
        Some(Number(n, ..)) => Some(n)
        _ => None
      }
    None => None
  }
}

///|
fn tree_uses_leaves_model(node : TreeNode) -> Bool {
  node.children.length() == 0 || not(node.is_expand)
}

///|
fn tree_patch_visual_color(style : @option.GeoItemStylePatchOption?) -> String? {
  match style {
    Some(patch) =>
      match patch.color {
        Some(color) => Some(color)
        None => patch.area_color
      }
    None => None
  }
}

///|
fn tree_patch_border_color(style : @option.GeoItemStylePatchOption?) -> String? {
  match style {
    Some(patch) => patch.border_color
    None => None
  }
}

///|
fn tree_patch_border_width(style : @option.GeoItemStylePatchOption?) -> Double? {
  match style {
    Some(patch) => patch.border_width
    None => None
  }
}

///|
fn tree_resolve_node_style(
  series : @option.SeriesOption,
  node : TreeNode,
) -> TreeResolvedNodeStyle {
  let leaves_style = if tree_uses_leaves_model(node) {
    series.tree_leaves_geo_item_style
  } else {
    None
  }
  let series_visual_color = tree_patch_visual_color(series.geo_item_style).unwrap_or(
    series.item_style.unwrap_or("#b0c4de"),
  )
  let visual_color = tree_patch_visual_color(node.item.item_style).unwrap_or(
    tree_patch_visual_color(leaves_style).unwrap_or(series_visual_color),
  )
  let stroke_color = tree_patch_border_color(node.item.item_style).unwrap_or(
    tree_patch_border_color(leaves_style).unwrap_or(
      tree_patch_border_color(series.geo_item_style).unwrap_or(visual_color),
    ),
  )
  let stroke_width = tree_patch_border_width(node.item.item_style).unwrap_or(
    tree_patch_border_width(leaves_style).unwrap_or(
      tree_patch_border_width(series.geo_item_style).unwrap_or(1.5),
    ),
  )
  let symbol_size = tree_raw_number_opt(node.item, "symbolSize").unwrap_or(
    if tree_uses_leaves_model(node) {
      series.tree_leaves_symbol_size.unwrap_or(series.symbol_size)
    } else {
      series.symbol_size
    },
  )
  { visual_color, stroke_color, stroke_width, symbol_size }
}

///|
fn tree_resolve_line_style(
  series : @option.SeriesOption,
  node : TreeNode,
) -> TreeResolvedLineStyle {
  let use_leaves = tree_uses_leaves_model(node)
  let color = tree_raw_style_string_opt(node.item, "lineStyle", "color").unwrap_or(
    if use_leaves {
      series.tree_leaves_line_style_color.unwrap_or(
        series.line_style_color.unwrap_or("#cfd2d7"),
      )
    } else {
      series.line_style_color.unwrap_or("#cfd2d7")
    },
  )
  let width = tree_raw_style_number_opt(node.item, "lineStyle", "width").unwrap_or(
    if use_leaves {
      series.tree_leaves_line_style_width.unwrap_or(
        series.line_style_width.unwrap_or(1.5),
      )
    } else {
      series.line_style_width.unwrap_or(1.5)
    },
  )
  let opacity = tree_raw_style_number_opt(node.item, "lineStyle", "opacity").unwrap_or(
    if use_leaves {
      series.tree_leaves_line_style_opacity.unwrap_or(
        series.line_style_opacity.unwrap_or(1.0),
      )
    } else {
      series.line_style_opacity.unwrap_or(1.0)
    },
  )
  let curveness = tree_raw_style_number_opt(node.item, "lineStyle", "curveness").unwrap_or(
    if use_leaves {
      series.tree_leaves_line_style_curveness.unwrap_or(
        series.line_style_curveness.unwrap_or(0.5),
      )
    } else {
      series.line_style_curveness.unwrap_or(0.5)
    },
  )
  { color, width, opacity, curveness }
}

///|
fn tree_apply_label_patch(
  base : TreeResolvedLabelStyle,
  patch : @option.GeoLabelPatchOption?,
) -> TreeResolvedLabelStyle {
  match patch {
    Some(p) =>
      {
        show: p.show.unwrap_or(base.show),
        color: p.color.unwrap_or(base.color),
        position: match p.position {
          Some(position) => Some(position)
          None => base.position
        },
        distance: p.distance.unwrap_or(base.distance),
        font_weight: p.font_weight.unwrap_or(base.font_weight),
        rotate: match p.rotate {
          Some(rotate) => Some(rotate)
          None => base.rotate
        },
        font_size: p.font_size.unwrap_or(base.font_size),
        font_family: p.font_family.unwrap_or(base.font_family),
      }
    None => base
  }
}

///|
fn tree_resolve_label_style(
  series : @option.SeriesOption,
  node : TreeNode,
) -> TreeResolvedLabelStyle {
  let base_label = match series.label {
    Some(label) => label
    None => { ..@option.GeoLabelOption::default(), show: true }
  }
  let base = {
    show: base_label.show,
    color: base_label.color,
    position: base_label.position,
    distance: base_label.distance.unwrap_or(5.0),
    font_weight: base_label.font_weight.unwrap_or("normal"),
    rotate: base_label.rotate,
    font_size: base_label.font_size,
    font_family: base_label.font_family,
  }
  let with_leaves = if tree_uses_leaves_model(node) {
    tree_apply_label_patch(base, series.tree_leaves_label)
  } else {
    base
  }
  tree_apply_label_patch(with_leaves, node.item.label)
}

///|
fn tree_label_position(
  x : Double,
  y : Double,
  half_size : Double,
  distance : Double,
  position : String,
) -> (Double, Double, @graphic.TextAnchor, @graphic.TextBaseline) {
  let offset = half_size + distance
  match position {
    "left" =>
      (x - offset, y, @graphic.TextAnchor::End, @graphic.TextBaseline::Middle)
    "right" =>
      (x + offset, y, @graphic.TextAnchor::Start, @graphic.TextBaseline::Middle)
    "top" =>
      (
        x,
        y - offset,
        @graphic.TextAnchor::Middle,
        @graphic.TextBaseline::Bottom,
      )
    "bottom" =>
      (
        x,
        y + offset,
        @graphic.TextAnchor::Middle,
        @graphic.TextBaseline::Hanging,
      )
    "inside" =>
      (x, y, @graphic.TextAnchor::Middle, @graphic.TextBaseline::Middle)
    "middle" =>
      (x, y, @graphic.TextAnchor::Middle, @graphic.TextBaseline::Middle)
    "center" =>
      (x, y, @graphic.TextAnchor::Middle, @graphic.TextBaseline::Middle)
    _ =>
      (x + offset, y, @graphic.TextAnchor::Start, @graphic.TextBaseline::Middle)
  }
}

///|
fn tree_radial_direction(
  real_root : TreeNode,
  node : TreeNode,
) -> (Bool, Double) {
  let root_x = real_root.layout_x
  let root_y = real_root.layout_y
  let target_x = node.layout_x
  let target_y = node.layout_y
  let mut rad = 0.0
  let mut is_left = false
  if target_x == root_x && node.is_expand && real_root.children.length() > 0 {
    let length = real_root.children.length()
    let center_x = (
        real_root.children[0].layout_x + real_root.children[length - 1].layout_x
      ) /
      2.0
    let center_y = (
        real_root.children[0].layout_y + real_root.children[length - 1].layout_y
      ) /
      2.0
    rad = @math.atan2(center_y - root_y, center_x - root_x)
    if rad < 0.0 {
      rad = 2.0 * @math.PI + rad
    }
    is_left = center_x < root_x
    if is_left {
      rad = rad - @math.PI
    }
  } else {
    rad = @math.atan2(target_y - root_y, target_x - root_x)
    if rad < 0.0 {
      rad = 2.0 * @math.PI + rad
    }
    if node.children.length() == 0 ||
      (node.children.length() != 0 && not(node.is_expand)) {
      is_left = target_x < root_x
      if is_left {
        rad = rad - @math.PI
      }
    } else {
      is_left = target_x > root_x
      if not(is_left) {
        rad = rad - @math.PI
      }
    }
  }
  (is_left, rad)
}

///|
fn tree_make_label_element(
  x : Double,
  y : Double,
  text : String,
  label_style : TreeResolvedLabelStyle,
  anchor : @graphic.TextAnchor,
  baseline : @graphic.TextBaseline,
  rotation_rad : Double?,
) -> @graphic.Element {
  let text_elem = @graphic.Element::text_custom(
    0.0,
    0.0,
    text,
    anchor,
    baseline,
    label_style.color,
    label_style.font_size,
    label_style.font_family,
    label_style.font_weight,
  )
  match rotation_rad {
    Some(rot) =>
      @graphic.Element::group_transformed(
        [text_elem],
        @graphic.Matrix::translate(x, y).then(@graphic.Matrix::rotate(rot)),
      )
    None =>
      @graphic.Element::text_custom(
        x,
        y,
        text,
        anchor,
        baseline,
        label_style.color,
        label_style.font_size,
        label_style.font_family,
        label_style.font_weight,
      )
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
  _series_index : Int,
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
  let edge_shape = series.tree_edge_shape
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
          let line_style = tree_resolve_line_style(series, child)
          let path_d = if layout == "radial" {
            let cx = lx + lw / 2.0
            let cy = ly + lh / 2.0
            tree_get_edge_shape_curve_radial(
              line_style.curveness,
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
              line_style.curveness,
              node.layout_x,
              node.layout_y,
              child.layout_x,
              child.layout_y,
            )
          }
          elems.push(
            @graphic.Element::path_stroke_custom(
              path_d,
              line_style.color,
              line_style.width,
              "butt",
              "miter",
              line_style.opacity,
            ),
          )
        }
      }
    })
  } else if edge_shape == "polyline" && layout != "radial" {
    // polyline edges: from parent node, fan out to all children
    tree_each_before(real_root, fn(node) {
      if node.is_expand && node.children.length() > 0 {
        let line_style = tree_resolve_line_style(series, node)
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
            path_d,
            line_style.color,
            line_style.width,
            "butt",
            "miter",
            line_style.opacity,
          ),
        )
      }
    })
  }
  // Draw nodes
  tree_each_before(real_root, fn(node) {
    let x = node.layout_x
    let y = node.layout_y
    let node_style = tree_resolve_node_style(series, node)
    let label_style = tree_resolve_label_style(series, node)
    // symbolInnerColor: collapsed non-leaf → visualColor, otherwise → neutral00
    let is_collapsed_nonleaf = not(node.is_expand) && node.children.length() > 0
    let fill_color = if is_collapsed_nonleaf {
      node_style.visual_color
    } else {
      "#fff" // tokens.color.neutral00
    }
    let is_leaf = node.children.length() == 0
    let half_size = node_style.symbol_size / 2.0
    elems.push(
      tree_circle_fill_stroke(
        x,
        y,
        half_size,
        fill_color,
        node_style.stroke_color,
        node_style.stroke_width,
      ),
    )
    // Node label
    let label_text = node.name
    if label_text.length() > 0 && label_style.show {
      if layout == "radial" {
        let (is_left, default_rad) = tree_radial_direction(real_root, node)
        let default_position = if is_left { "left" } else { "right" }
        let position = label_style.position.unwrap_or(default_position)
        let (lbl_x, lbl_y, anchor, baseline) = tree_label_position(
          x,
          y,
          half_size,
          label_style.distance,
          position,
        )
        let rotation_rad = match label_style.rotate {
          Some(deg) => Some(deg * @math.PI / 180.0)
          None => Some(-default_rad)
        }
        elems.push(
          tree_make_label_element(
            lbl_x, lbl_y, label_text, label_style, anchor, baseline, rotation_rad,
          ),
        )
      } else {
        let default_position = if orient == "LR" || orient == "RL" {
          if is_leaf {
            if orient == "LR" {
              "right"
            } else {
              "left"
            }
          } else if orient == "LR" {
            "left"
          } else {
            "right"
          }
        } else if is_leaf {
          if orient == "TB" {
            "bottom"
          } else {
            "top"
          }
        } else if orient == "TB" {
          "top"
        } else {
          "bottom"
        }
        let position = label_style.position.unwrap_or(default_position)
        let (lbl_x, lbl_y, anchor, baseline) = tree_label_position(
          x,
          y,
          half_size,
          label_style.distance,
          position,
        )
        let rotation_rad = match label_style.rotate {
          Some(deg) => Some(deg * @math.PI / 180.0)
          None => None
        }
        elems.push(
          tree_make_label_element(
            lbl_x, lbl_y, label_text, label_style, anchor, baseline, rotation_rad,
          ),
        )
      }
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

// Corresponds to: echarts/src/coord/matrix/Matrix.ts
//                  echarts/src/coord/matrix/MatrixModel.ts
//                  echarts/src/coord/matrix/MatrixDim.ts
//                  echarts/src/coord/matrix/MatrixBodyCorner.ts
//                  echarts/src/coord/matrix/matrixCoordHelper.ts
//                  echarts/src/coord/matrix/prepareCustom.ts

///|
pub(all) struct MatrixCell {
  bbox : @graphic.BBox
  value : String?
  item_style : @option.MatrixItemStyleOption
  label : @option.MatrixLabelOption
  level : Int
  index : Int
  span : Int
  span_x : Int
  span_y : Int
}

///|
pub(all) struct MatrixDataLayout {
  rect : @graphic.BBox
  content_rect : @graphic.BBox
}

///|
pub(all) struct MatrixPrepareCoordSysInfo {
  type_name : String
  x : Double
  y : Double
  width : Double
  height : Double
}

///|
pub(all) struct MatrixPreparedCustom {
  coord_sys : MatrixPrepareCoordSysInfo
}

///|
pub(all) struct Matrix {
  rect : @graphic.BBox
  body_rect : @graphic.BBox
  corner_rect : @graphic.BBox
  x_cells : Array[MatrixCell]
  y_cells : Array[MatrixCell]
  body_cells : Array[MatrixCell]
  corner_cells : Array[MatrixCell]
  x_leaf_cells : Array[MatrixCell]
  y_leaf_cells : Array[MatrixCell]
  body_border_width : Double
  x_name_to_index : Array[(String, Int)]
  y_name_to_index : Array[(String, Int)]
  x_depth : Int
  y_depth : Int
  x_level_sizes : Array[Double]
  y_level_sizes : Array[Double]
  body_cell_map : Array[(String, MatrixCell)]
  corner_cell_map : Array[(String, MatrixCell)]
}

///|
priv struct MatrixCoordResolved {
  start : Int
  end : Int
}

///|
priv struct MatrixLocatorRange {
  x0 : Int
  x1 : Int
  y0 : Int
  y1 : Int
}

///|
priv struct MatrixBuiltArea {
  visible_cells : Array[MatrixCell]
  cell_map : Array[(String, MatrixCell)]
}

///|
pub fn Matrix::prepare_custom(self : Matrix) -> MatrixPreparedCustom {
  {
    coord_sys: {
      type_name: "matrix",
      x: self.rect.x,
      y: self.rect.y,
      width: self.rect.width,
      height: self.rect.height,
    },
  }
}

///|
pub fn Matrix::build(opt : @option.ChartOption) -> Matrix? {
  if opt.matrix.length() == 0 {
    return None
  }
  let model = opt.matrix[0]
  let rect = matrix_resolve_rect(model, opt)
  let x_source = matrix_dimension_roots(model.x)
  let y_source = matrix_dimension_roots(model.y)
  let x_depth = if model.x.show { matrix_tree_depth(x_source) } else { 0 }
  let y_depth = if model.y.show { matrix_tree_depth(y_source) } else { 0 }
  let x_level_sizes = matrix_level_sizes(model.x, x_depth, rect.height, 32.0)
  let y_level_sizes = matrix_level_sizes(model.y, y_depth, rect.width, 56.0)
  let x_header_height = matrix_sum_doubles(x_level_sizes)
  let y_header_width = matrix_sum_doubles(y_level_sizes)
  let body_rect = @graphic.BBox::new(
    rect.x + y_header_width,
    rect.y + x_header_height,
    if rect.width - y_header_width > 0.0 {
      rect.width - y_header_width
    } else {
      0.0
    },
    if rect.height - x_header_height > 0.0 {
      rect.height - x_header_height
    } else {
      0.0
    },
  )
  let corner_rect = @graphic.BBox::new(
    rect.x,
    rect.y,
    y_header_width,
    x_header_height,
  )
  let x_leaves = matrix_collect_leaves(x_source, model.x)
  let y_leaves = matrix_collect_leaves(y_source, model.y)
  let x_leaf_widths = matrix_leaf_sizes(x_leaves, body_rect.width)
  let y_leaf_heights = matrix_leaf_sizes(y_leaves, body_rect.height)
  let x_leaf_cells = matrix_build_x_leaf_cells(
    x_leaves, x_leaf_widths, body_rect,
  )
  let y_leaf_cells = matrix_build_y_leaf_cells(
    y_leaves, y_leaf_heights, body_rect,
  )
  let x_cells = matrix_build_x_header_cells(
    x_source,
    x_leaf_cells,
    model.x,
    rect,
    y_header_width,
    x_level_sizes,
  )
  let y_cells = matrix_build_y_header_cells(
    y_source,
    y_leaf_cells,
    model.y,
    rect,
    x_header_height,
    y_level_sizes,
  )
  let body_area = matrix_build_body_cells(
    model.body,
    x_leaf_cells,
    y_leaf_cells,
  )
  let corner_area = matrix_build_corner_cells(
    model.corner,
    rect,
    x_level_sizes,
    y_level_sizes,
    x_cells,
    y_cells,
    x_leaf_cells.length(),
    y_leaf_cells.length(),
    x_depth,
    y_depth,
  )
  Some({
    rect,
    body_rect,
    corner_rect,
    x_cells,
    y_cells,
    body_cells: body_area.visible_cells,
    corner_cells: corner_area.visible_cells,
    x_leaf_cells,
    y_leaf_cells,
    body_border_width: model.body.item_style.border_width,
    x_name_to_index: matrix_name_to_index(x_leaf_cells),
    y_name_to_index: matrix_name_to_index(y_leaf_cells),
    x_depth,
    y_depth,
    x_level_sizes,
    y_level_sizes,
    body_cell_map: body_area.cell_map,
    corner_cell_map: corner_area.cell_map,
  })
}

///|
pub fn Matrix::resolve_x(
  self : Matrix,
  value : @option.MatrixCoordValue,
) -> Int? {
  matrix_resolve_coord_value(
    self.x_name_to_index,
    value,
    self.x_leaf_cells.length(),
  )
}

///|
pub fn Matrix::resolve_y(
  self : Matrix,
  value : @option.MatrixCoordValue,
) -> Int? {
  matrix_resolve_coord_value(
    self.y_name_to_index,
    value,
    self.y_leaf_cells.length(),
  )
}

///|
pub fn Matrix::data_to_layout(
  self : Matrix,
  x_index : Int,
  y_index : Int,
  clamp? : Bool = true,
) -> MatrixDataLayout {
  if clamp &&
    (
      x_index < 0 ||
      y_index < 0 ||
      x_index >= self.x_leaf_cells.length() ||
      y_index >= self.y_leaf_cells.length()
    ) {
    let nan = 0.0 / 0.0
    let empty = @graphic.BBox::new(nan, nan, nan, nan)
    return { rect: empty, content_rect: empty }
  }
  let xi = matrix_clamp_index(x_index, self.x_leaf_cells.length())
  let yi = matrix_clamp_index(y_index, self.y_leaf_cells.length())
  let rect = match matrix_find_cell_by_locator(self.body_cell_map, xi, yi) {
    Some(cell) => cell.bbox
    None => {
      let x_cell = self.x_leaf_cells[xi]
      let y_cell = self.y_leaf_cells[yi]
      @graphic.BBox::new(
        x_cell.bbox.x,
        y_cell.bbox.y,
        x_cell.bbox.width,
        y_cell.bbox.height,
      )
    }
  }
  let inset = self.body_border_width / 2.0
  let content_rect = @graphic.BBox::new(
    rect.x + inset,
    rect.y + inset,
    if rect.width - self.body_border_width > 0.0 {
      rect.width - self.body_border_width
    } else {
      0.0
    },
    if rect.height - self.body_border_width > 0.0 {
      rect.height - self.body_border_width
    } else {
      0.0
    },
  )
  { rect, content_rect }
}

///|
fn matrix_clamp_index(index : Int, len : Int) -> Int {
  if len <= 0 {
    0
  } else if index < 0 {
    0
  } else if index >= len {
    len - 1
  } else {
    index
  }
}

///|
fn matrix_resolve_coord_value(
  name_map : Array[(String, Int)],
  value : @option.MatrixCoordValue,
  length : Int,
) -> Int? {
  match value {
    Locator(idx) => if idx >= 0 && idx < length { Some(idx) } else { None }
    Name(name) => {
      let mut i = 0
      while i < name_map.length() {
        let (candidate, idx) = name_map[i]
        if candidate == name {
          return Some(idx)
        }
        i += 1
      }
      None
    }
    Missing => None
  }
}

///|
fn matrix_name_to_index(cells : Array[MatrixCell]) -> Array[(String, Int)] {
  let out : Array[(String, Int)] = []
  let mut i = 0
  while i < cells.length() {
    match cells[i].value {
      Some(value) => out.push((value, i))
      None => ()
    }
    i += 1
  }
  out
}

///|
fn matrix_resolve_rect(
  model : @option.MatrixOption,
  opt : @option.ChartOption,
) -> @graphic.BBox {
  let left = matrix_resolve_size_opt(model.left, opt.width, opt.width * 0.1)
  let top = matrix_resolve_size_opt(model.top, opt.height, opt.height * 0.1)
  let right = matrix_resolve_size_opt(model.right, opt.width, opt.width * 0.1)
  let bottom = matrix_resolve_size_opt(
    model.bottom,
    opt.height,
    opt.height * 0.1,
  )
  let width = match model.width {
    Some(spec) => matrix_resolve_size(spec, opt.width)
    None => opt.width - left - right
  }
  let height = match model.height {
    Some(spec) => matrix_resolve_size(spec, opt.height)
    None => opt.height - top - bottom
  }
  @graphic.BBox::new(left, top, width, height)
}

///|
fn matrix_resolve_size(spec : @option.SizeSpec, total : Double) -> Double {
  match spec {
    @option.Px(px) => px
    @option.Pct(pct) => total * pct / 100.0
  }
}

///|
fn matrix_resolve_size_opt(
  spec : @option.SizeSpec?,
  total : Double,
  fallback : Double,
) -> Double {
  match spec {
    Some(value) => matrix_resolve_size(value, total)
    None => fallback
  }
}

///|
priv struct MatrixTreeNode {
  option : @option.MatrixDimensionCellOption
  leaf_span : Int
  depth : Int
  first_leaf : Int
}

///|
fn matrix_dimension_roots(
  option : @option.MatrixDimensionOption,
) -> Array[MatrixTreeNode] {
  let raw = if option.data.length() > 0 {
    option.data
  } else {
    matrix_make_length_cells(option.length.unwrap_or(0))
  }
  let nodes : Array[MatrixTreeNode] = []
  let mut first_leaf = 0
  let mut i = 0
  while i < raw.length() {
    let node = matrix_make_tree_node(raw[i], first_leaf)
    first_leaf += node.leaf_span
    nodes.push(node)
    i += 1
  }
  nodes
}

///|
fn matrix_make_length_cells(
  length : Int,
) -> Array[@option.MatrixDimensionCellOption] {
  let out : Array[@option.MatrixDimensionCellOption] = []
  let mut i = 0
  while i < length {
    out.push({
      value: Some(i.to_string()),
      size: None,
      children: [],
      item_style: None,
      label: None,
    })
    i += 1
  }
  out
}

///|
fn matrix_make_tree_node(
  option : @option.MatrixDimensionCellOption,
  first_leaf : Int,
) -> MatrixTreeNode {
  if option.children.length() == 0 {
    { option, leaf_span: 1, depth: 1, first_leaf }
  } else {
    let mut span = 0
    let mut max_depth = 0
    let mut i = 0
    let mut child_first_leaf = first_leaf
    while i < option.children.length() {
      let child = matrix_make_tree_node(option.children[i], child_first_leaf)
      span += child.leaf_span
      child_first_leaf += child.leaf_span
      if child.depth > max_depth {
        max_depth = child.depth
      }
      i += 1
    }
    { option, leaf_span: span, depth: max_depth + 1, first_leaf }
  }
}

///|
fn matrix_tree_depth(nodes : Array[MatrixTreeNode]) -> Int {
  let mut depth = 0
  let mut i = 0
  while i < nodes.length() {
    if nodes[i].depth > depth {
      depth = nodes[i].depth
    }
    i += 1
  }
  depth
}

///|
fn matrix_level_sizes(
  option : @option.MatrixDimensionOption,
  depth : Int,
  total : Double,
  default_px : Double,
) -> Array[Double] {
  let out : Array[Double] = []
  let mut level = 0
  while level < depth {
    let size = if level < option.levels.length() {
      match option.levels[level].level_size {
        Some(spec) => matrix_resolve_size(spec, total)
        None =>
          match option.level_size {
            Some(spec) => matrix_resolve_size(spec, total)
            None => default_px
          }
      }
    } else {
      match option.level_size {
        Some(spec) => matrix_resolve_size(spec, total)
        None => default_px
      }
    }
    out.push(size)
    level += 1
  }
  out
}

///|
fn matrix_sum_doubles(values : Array[Double]) -> Double {
  let mut sum = 0.0
  let mut i = 0
  while i < values.length() {
    sum += values[i]
    i += 1
  }
  sum
}

///|
fn matrix_collect_leaves(
  nodes : Array[MatrixTreeNode],
  option : @option.MatrixDimensionOption,
) -> Array[@option.MatrixDimensionCellOption] {
  let out : Array[@option.MatrixDimensionCellOption] = []
  let mut i = 0
  while i < nodes.length() {
    matrix_collect_leaves_from_node(nodes[i], option, out)
    i += 1
  }
  out
}

///|
fn matrix_collect_leaves_from_node(
  node : MatrixTreeNode,
  option : @option.MatrixDimensionOption,
  out : Array[@option.MatrixDimensionCellOption],
) -> Unit {
  if node.option.children.length() == 0 {
    out.push({
      ..node.option,
      item_style: match node.option.item_style {
        Some(value) => Some(value)
        None => Some(option.item_style)
      },
      label: match node.option.label {
        Some(value) => Some(value)
        None => Some(option.label)
      },
    })
    return
  }
  let mut i = 0
  while i < node.option.children.length() {
    matrix_collect_leaves_from_node(
      matrix_make_tree_node(node.option.children[i], 0),
      option,
      out,
    )
    i += 1
  }
}

///|
fn matrix_leaf_sizes(
  leaves : Array[@option.MatrixDimensionCellOption],
  total : Double,
) -> Array[Double] {
  let sizes : Array[Double] = []
  let mut rest = total
  let mut unspecified = 0
  let mut i = 0
  while i < leaves.length() {
    match leaves[i].size {
      Some(spec) => {
        let resolved = matrix_resolve_size(spec, total)
        sizes.push(resolved)
        rest -= resolved
      }
      None => {
        sizes.push(-1.0)
        unspecified += 1
      }
    }
    i += 1
  }
  let auto_size = if unspecified > 0 && rest > 0.0 {
    rest / unspecified.to_double()
  } else if unspecified > 0 {
    0.0
  } else {
    0.0
  }
  let mut j = 0
  while j < sizes.length() {
    if sizes[j] < 0.0 {
      sizes[j] = auto_size
    }
    j += 1
  }
  sizes
}

///|
fn matrix_build_x_leaf_cells(
  leaves : Array[@option.MatrixDimensionCellOption],
  widths : Array[Double],
  body_rect : @graphic.BBox,
) -> Array[MatrixCell] {
  let out : Array[MatrixCell] = []
  let mut x = body_rect.x
  let mut i = 0
  while i < leaves.length() {
    let item_style = leaves[i].item_style.unwrap_or(
      @option.MatrixItemStyleOption::default(),
    )
    let label = leaves[i].label.unwrap_or(@option.MatrixLabelOption::default())
    let width = if i < widths.length() { widths[i] } else { 0.0 }
    out.push({
      bbox: @graphic.BBox::new(x, body_rect.y, width, body_rect.height),
      value: leaves[i].value,
      item_style,
      label,
      level: 0,
      index: i,
      span: 1,
      span_x: 1,
      span_y: 1,
    })
    x += width
    i += 1
  }
  out
}

///|
fn matrix_build_y_leaf_cells(
  leaves : Array[@option.MatrixDimensionCellOption],
  heights : Array[Double],
  body_rect : @graphic.BBox,
) -> Array[MatrixCell] {
  let out : Array[MatrixCell] = []
  let mut y = body_rect.y
  let mut i = 0
  while i < leaves.length() {
    let item_style = leaves[i].item_style.unwrap_or(
      @option.MatrixItemStyleOption::default(),
    )
    let label = leaves[i].label.unwrap_or(@option.MatrixLabelOption::default())
    let height = if i < heights.length() { heights[i] } else { 0.0 }
    out.push({
      bbox: @graphic.BBox::new(body_rect.x, y, body_rect.width, height),
      value: leaves[i].value,
      item_style,
      label,
      level: 0,
      index: i,
      span: 1,
      span_x: 1,
      span_y: 1,
    })
    y += height
    i += 1
  }
  out
}

///|
fn matrix_build_x_header_cells(
  nodes : Array[MatrixTreeNode],
  leaf_cells : Array[MatrixCell],
  option : @option.MatrixDimensionOption,
  rect : @graphic.BBox,
  y_header_width : Double,
  level_sizes : Array[Double],
) -> Array[MatrixCell] {
  let out : Array[MatrixCell] = []
  let mut i = 0
  while i < nodes.length() {
    matrix_append_x_header_cells(
      out,
      nodes[i],
      0,
      leaf_cells,
      option,
      rect,
      y_header_width,
      level_sizes,
    )
    i += 1
  }
  out
}

///|
fn matrix_append_x_header_cells(
  out : Array[MatrixCell],
  node : MatrixTreeNode,
  level : Int,
  leaf_cells : Array[MatrixCell],
  option : @option.MatrixDimensionOption,
  rect : @graphic.BBox,
  y_header_width : Double,
  level_sizes : Array[Double],
) -> Unit {
  let first = leaf_cells[node.first_leaf]
  let last = leaf_cells[node.first_leaf + node.leaf_span - 1]
  let y = rect.y + matrix_prefix_sum(level_sizes, level)
  let height = if level < level_sizes.length() {
    level_sizes[level]
  } else {
    0.0
  }
  let item_style = node.option.item_style.unwrap_or(option.item_style)
  let label = node.option.label.unwrap_or(option.label)
  let _ = y_header_width
  out.push({
    bbox: @graphic.BBox::new(
      first.bbox.x,
      y,
      last.bbox.right() - first.bbox.x,
      height,
    ),
    value: node.option.value,
    item_style,
    label,
    level,
    index: node.first_leaf,
    span: node.leaf_span,
    span_x: node.leaf_span,
    span_y: 1,
  })
  let mut i = 0
  while i < node.option.children.length() {
    matrix_append_x_header_cells(
      out,
      matrix_make_tree_node(
        node.option.children[i],
        node.first_leaf + matrix_child_offset(node.option.children, i),
      ),
      level + 1,
      leaf_cells,
      option,
      rect,
      y_header_width,
      level_sizes,
    )
    i += 1
  }
}

///|
fn matrix_build_y_header_cells(
  nodes : Array[MatrixTreeNode],
  leaf_cells : Array[MatrixCell],
  option : @option.MatrixDimensionOption,
  rect : @graphic.BBox,
  x_header_height : Double,
  level_sizes : Array[Double],
) -> Array[MatrixCell] {
  let out : Array[MatrixCell] = []
  let mut i = 0
  while i < nodes.length() {
    matrix_append_y_header_cells(
      out,
      nodes[i],
      0,
      leaf_cells,
      option,
      rect,
      x_header_height,
      level_sizes,
    )
    i += 1
  }
  out
}

///|
fn matrix_append_y_header_cells(
  out : Array[MatrixCell],
  node : MatrixTreeNode,
  level : Int,
  leaf_cells : Array[MatrixCell],
  option : @option.MatrixDimensionOption,
  rect : @graphic.BBox,
  x_header_height : Double,
  level_sizes : Array[Double],
) -> Unit {
  let first = leaf_cells[node.first_leaf]
  let last = leaf_cells[node.first_leaf + node.leaf_span - 1]
  let x = rect.x + matrix_prefix_sum(level_sizes, level)
  let width = if level < level_sizes.length() {
    level_sizes[level]
  } else {
    0.0
  }
  let item_style = node.option.item_style.unwrap_or(option.item_style)
  let label = node.option.label.unwrap_or(option.label)
  let _ = x_header_height
  out.push({
    bbox: @graphic.BBox::new(
      x,
      first.bbox.y,
      width,
      last.bbox.bottom() - first.bbox.y,
    ),
    value: node.option.value,
    item_style,
    label,
    level,
    index: node.first_leaf,
    span: node.leaf_span,
    span_x: 1,
    span_y: node.leaf_span,
  })
  let mut i = 0
  while i < node.option.children.length() {
    matrix_append_y_header_cells(
      out,
      matrix_make_tree_node(
        node.option.children[i],
        node.first_leaf + matrix_child_offset(node.option.children, i),
      ),
      level + 1,
      leaf_cells,
      option,
      rect,
      x_header_height,
      level_sizes,
    )
    i += 1
  }
}

///|
fn matrix_child_offset(
  children : Array[@option.MatrixDimensionCellOption],
  idx : Int,
) -> Int {
  let mut offset = 0
  let mut i = 0
  while i < idx {
    offset += matrix_raw_leaf_span(children[i])
    i += 1
  }
  offset
}

///|
fn matrix_raw_leaf_span(cell : @option.MatrixDimensionCellOption) -> Int {
  if cell.children.length() == 0 {
    1
  } else {
    let mut sum = 0
    let mut i = 0
    while i < cell.children.length() {
      sum += matrix_raw_leaf_span(cell.children[i])
      i += 1
    }
    sum
  }
}

///|
fn matrix_prefix_sum(values : Array[Double], end_exclusive : Int) -> Double {
  let mut sum = 0.0
  let mut i = 0
  while i < end_exclusive && i < values.length() {
    sum += values[i]
    i += 1
  }
  sum
}

///|
fn matrix_build_body_cells(
  option : @option.MatrixBodyOption,
  x_leaf_cells : Array[MatrixCell],
  y_leaf_cells : Array[MatrixCell],
) -> MatrixBuiltArea {
  let defaults : Array[MatrixCell] = []
  let mut y = 0
  while y < y_leaf_cells.length() {
    let mut x = 0
    while x < x_leaf_cells.length() {
      defaults.push({
        bbox: @graphic.BBox::new(
          x_leaf_cells[x].bbox.x,
          y_leaf_cells[y].bbox.y,
          x_leaf_cells[x].bbox.width,
          y_leaf_cells[y].bbox.height,
        ),
        value: None,
        item_style: option.item_style,
        label: option.label,
        level: y,
        index: x,
        span: 1,
        span_x: 1,
        span_y: 1,
      })
      x += 1
    }
    y += 1
  }
  matrix_apply_sparse_cells(
    defaults,
    option,
    option.data,
    x_leaf_cells,
    y_leaf_cells,
    [],
    [],
    x_leaf_cells.length(),
    y_leaf_cells.length(),
    0,
    0,
    true,
  )
}

///|
fn matrix_build_corner_cells(
  option : @option.MatrixBodyOption,
  rect : @graphic.BBox,
  x_level_sizes : Array[Double],
  y_level_sizes : Array[Double],
  x_cells : Array[MatrixCell],
  y_cells : Array[MatrixCell],
  x_leaf_count : Int,
  y_leaf_count : Int,
  x_depth : Int,
  y_depth : Int,
) -> MatrixBuiltArea {
  let defaults : Array[MatrixCell] = []
  let mut yi = 0
  let mut y = rect.y
  while yi < x_level_sizes.length() {
    let mut xi = 0
    let mut x = rect.x
    while xi < y_level_sizes.length() {
      defaults.push({
        bbox: @graphic.BBox::new(x, y, y_level_sizes[xi], x_level_sizes[yi]),
        value: None,
        item_style: option.item_style,
        label: option.label,
        level: yi - x_depth,
        index: xi - y_depth,
        span: 1,
        span_x: 1,
        span_y: 1,
      })
      x += y_level_sizes[xi]
      xi += 1
    }
    y += x_level_sizes[yi]
    yi += 1
  }
  matrix_apply_sparse_cells(
    defaults,
    option,
    option.data,
    [],
    [],
    x_cells,
    y_cells,
    x_leaf_count,
    y_leaf_count,
    x_depth,
    y_depth,
    false,
  )
}

///|
fn matrix_apply_sparse_cells(
  defaults : Array[MatrixCell],
  area_option : @option.MatrixBodyOption,
  data : Array[@option.MatrixBodyCellOption],
  x_leaf_cells : Array[MatrixCell],
  y_leaf_cells : Array[MatrixCell],
  x_header_cells : Array[MatrixCell],
  y_header_cells : Array[MatrixCell],
  x_leaf_count : Int,
  y_leaf_count : Int,
  x_depth : Int,
  y_depth : Int,
  is_body : Bool,
) -> MatrixBuiltArea {
  let visible : Array[MatrixCell] = defaults
  let cell_map : Array[(String, MatrixCell)] = []
  let unit_cell_map : Array[(String, MatrixCell)] = []
  let merge_ranges : Array[MatrixLocatorRange] = []
  let covered : Array[(String, Int)] = []
  let mut i = 0
  while i < visible.length() {
    let cell = visible[i]
    let key = matrix_locator_key(cell.index, cell.level)
    cell_map.push((key, cell))
    unit_cell_map.push((key, cell))
    i += 1
  }
  i = 0
  while i < data.length() {
    let parsed = matrix_parse_body_option_range(
      data[i],
      x_leaf_cells,
      y_leaf_cells,
      x_header_cells,
      y_header_cells,
      x_leaf_count,
      y_leaf_count,
      x_depth,
      y_depth,
      is_body,
    )
    match parsed {
      Some(range0) => {
        let range = if data[i].merge_cells {
          matrix_expand_range_by_existing_merges(range0, merge_ranges)
        } else {
          range0
        }
        if data[i].merge_cells {
          matrix_remove_intersecting_merge_ranges(merge_ranges, range)
          merge_ranges.push(range)
        }
        let item_style = data[i].item_style.unwrap_or(area_option.item_style)
        let label = data[i].label.unwrap_or(area_option.label)
        let value = data[i].value
        let bbox = matrix_locator_range_to_bbox(range, unit_cell_map)
        if !bbox.x.is_nan() && !bbox.y.is_nan() {
          let owner = {
            bbox,
            value,
            item_style,
            label,
            level: range.y0,
            index: range.x0,
            span: if range.x1 - range.x0 + 1 > range.y1 - range.y0 + 1 {
              range.x1 - range.x0 + 1
            } else {
              range.y1 - range.y0 + 1
            },
            span_x: range.x1 - range.x0 + 1,
            span_y: range.y1 - range.y0 + 1,
          }
          matrix_replace_range_cells(visible, cell_map, covered, range, owner)
        }
      }
      None => ()
    }
    i += 1
  }
  let _ = merge_ranges
  { visible_cells: visible, cell_map }
}

///|
fn matrix_replace_range_cells(
  visible : Array[MatrixCell],
  cell_map : Array[(String, MatrixCell)],
  covered : Array[(String, Int)],
  range : MatrixLocatorRange,
  owner : MatrixCell,
) -> Unit {
  let mut y = range.y0
  while y <= range.y1 {
    let mut x = range.x0
    while x <= range.x1 {
      let key = matrix_locator_key(x, y)
      if x == range.x0 && y == range.y0 {
        matrix_remove_visible_cell(visible, key)
        visible.push(owner)
        matrix_set_cell_map(cell_map, key, owner)
      } else {
        matrix_remove_visible_cell(visible, key)
        matrix_set_cell_map(cell_map, key, owner)
        matrix_mark_covered(covered, key)
      }
      x += 1
    }
    y += 1
  }
}

///|
fn matrix_remove_visible_cell(
  visible : Array[MatrixCell],
  key : String,
) -> Unit {
  let mut i = visible.length() - 1
  while i >= 0 && i < visible.length() {
    let cell = visible[i]
    let cell_key = matrix_locator_key(cell.index, cell.level)
    if cell_key == key {
      let mut j = i
      while j + 1 < visible.length() {
        visible[j] = visible[j + 1]
        j += 1
      }
      let _ = visible.pop()
      return
    }
    if i == 0 {
      return
    }
    i -= 1
  }
}

///|
fn matrix_set_cell_map(
  cell_map : Array[(String, MatrixCell)],
  key : String,
  cell : MatrixCell,
) -> Unit {
  let mut i = 0
  while i < cell_map.length() {
    let (existing, _) = cell_map[i]
    if existing == key {
      cell_map[i] = (key, cell)
      return
    }
    i += 1
  }
  cell_map.push((key, cell))
}

///|
fn matrix_mark_covered(covered : Array[(String, Int)], key : String) -> Unit {
  let mut i = 0
  while i < covered.length() {
    if covered[i].0 == key {
      return
    }
    i += 1
  }
  covered.push((key, 1))
}

///|
fn matrix_parse_body_option_range(
  cell : @option.MatrixBodyCellOption,
  x_leaf_cells : Array[MatrixCell],
  y_leaf_cells : Array[MatrixCell],
  x_header_cells : Array[MatrixCell],
  y_header_cells : Array[MatrixCell],
  x_leaf_count : Int,
  y_leaf_count : Int,
  x_depth : Int,
  y_depth : Int,
  is_body : Bool,
) -> MatrixLocatorRange? {
  if cell.coord.length() < 2 {
    return None
  }
  let x_range = matrix_parse_coord_part_range(
    cell.coord[0],
    x_leaf_cells,
    x_header_cells,
    true,
    x_leaf_count,
    y_depth,
    cell.coord_clamp,
    is_body,
  )
  let y_range = matrix_parse_coord_part_range(
    cell.coord[1],
    y_leaf_cells,
    y_header_cells,
    false,
    y_leaf_count,
    x_depth,
    cell.coord_clamp,
    is_body,
  )
  match (x_range, y_range) {
    (Some(xr), Some(yr)) =>
      Some({ x0: xr.start, x1: xr.end, y0: yr.start, y1: yr.end })
    _ => None
  }
}

///|
fn matrix_parse_coord_part_range(
  part : @option.MatrixCoordPart,
  leaf_cells : Array[MatrixCell],
  header_cells : Array[MatrixCell],
  is_x : Bool,
  leaf_count : Int,
  other_depth : Int,
  coord_clamp : Bool,
  is_body : Bool,
) -> MatrixCoordResolved? {
  let _ = is_x
  let mut fallback = None
  if coord_clamp {
    fallback = if is_body {
      Some({ start: 0, end: leaf_count - 1 })
    } else {
      Some({ start: -other_depth, end: -1 })
    }
  }
  match part {
    Missing => fallback
    Value(value) =>
      match
        matrix_resolve_axis_value(
          value, leaf_cells, header_cells, is_x, leaf_count, other_depth,
        ) {
        Some(resolved) => Some(resolved)
        None => fallback
      }
    Range(a, b) => {
      let ar = matrix_resolve_axis_value(
        a, leaf_cells, header_cells, is_x, leaf_count, other_depth,
      )
      let br = matrix_resolve_axis_value(
        b, leaf_cells, header_cells, is_x, leaf_count, other_depth,
      )
      match (ar, br) {
        (Some(ra), Some(rb)) =>
          Some({
            start: if ra.start < rb.start {
              ra.start
            } else {
              rb.start
            },
            end: if ra.end > rb.end {
              ra.end
            } else {
              rb.end
            },
          })
        _ => fallback
      }
    }
  }
}

///|
fn matrix_resolve_axis_value(
  value : @option.MatrixCoordValue,
  leaf_cells : Array[MatrixCell],
  header_cells : Array[MatrixCell],
  _is_x : Bool,
  leaf_count : Int,
  other_depth : Int,
) -> MatrixCoordResolved? {
  match value {
    Locator(idx) =>
      if idx >= 0 {
        if idx < leaf_count {
          Some({ start: idx, end: idx })
        } else {
          None
        }
      } else if idx >= -other_depth {
        Some({ start: idx, end: idx })
      } else {
        None
      }
    Name(name) => matrix_find_axis_name_range(name, leaf_cells, header_cells)
    Missing => None
  }
}

///|
fn matrix_find_axis_name_range(
  name : String,
  leaf_cells : Array[MatrixCell],
  header_cells : Array[MatrixCell],
) -> MatrixCoordResolved? {
  let mut i = 0
  while i < header_cells.length() {
    let cell = header_cells[i]
    match cell.value {
      Some(value) if value == name =>
        return Some({ start: cell.index, end: cell.index + cell.span - 1 })
      _ => ()
    }
    i += 1
  }
  i = 0
  while i < leaf_cells.length() {
    let cell = leaf_cells[i]
    match cell.value {
      Some(value) if value == name =>
        return Some({ start: cell.index, end: cell.index })
      _ => ()
    }
    i += 1
  }
  None
}

///|
fn matrix_expand_range_by_existing_merges(
  init : MatrixLocatorRange,
  merge_ranges : Array[MatrixLocatorRange],
) -> MatrixLocatorRange {
  let mut out = init
  let mut expanded = true
  while expanded {
    expanded = false
    let mut i = 0
    while i < merge_ranges.length() {
      let other = merge_ranges[i]
      if matrix_ranges_intersect(out, other) {
        let next = {
          x0: if out.x0 < other.x0 {
            out.x0
          } else {
            other.x0
          },
          x1: if out.x1 > other.x1 {
            out.x1
          } else {
            other.x1
          },
          y0: if out.y0 < other.y0 {
            out.y0
          } else {
            other.y0
          },
          y1: if out.y1 > other.y1 {
            out.y1
          } else {
            other.y1
          },
        }
        if next.x0 != out.x0 ||
          next.x1 != out.x1 ||
          next.y0 != out.y0 ||
          next.y1 != out.y1 {
          out = next
          expanded = true
        }
      }
      i += 1
    }
  }
  out
}

///|
fn matrix_remove_intersecting_merge_ranges(
  merge_ranges : Array[MatrixLocatorRange],
  target : MatrixLocatorRange,
) -> Unit {
  let mut i = merge_ranges.length()
  while i > 0 {
    i -= 1
    if matrix_ranges_intersect(merge_ranges[i], target) {
      let mut j = i
      while j + 1 < merge_ranges.length() {
        merge_ranges[j] = merge_ranges[j + 1]
        j += 1
      }
      let _ = merge_ranges.pop()
    }
  }
}

///|
fn matrix_ranges_intersect(
  a : MatrixLocatorRange,
  b : MatrixLocatorRange,
) -> Bool {
  !(a.x1 < b.x0 || a.x0 > b.x1 || a.y1 < b.y0 || a.y0 > b.y1)
}

///|
fn matrix_locator_range_to_bbox(
  range : MatrixLocatorRange,
  unit_cell_map : Array[(String, MatrixCell)],
) -> @graphic.BBox {
  let top_left = matrix_find_cell_by_locator(unit_cell_map, range.x0, range.y0)
  let bottom_right = matrix_find_cell_by_locator(
    unit_cell_map,
    range.x1,
    range.y1,
  )
  match (top_left, bottom_right) {
    (Some(a), Some(b)) =>
      @graphic.BBox::new(
        a.bbox.x,
        a.bbox.y,
        b.bbox.right() - a.bbox.x,
        b.bbox.bottom() - a.bbox.y,
      )
    _ => {
      let nan = 0.0 / 0.0
      @graphic.BBox::new(nan, nan, nan, nan)
    }
  }
}

///|
fn matrix_find_cell_by_locator(
  cell_map : Array[(String, MatrixCell)],
  x : Int,
  y : Int,
) -> MatrixCell? {
  let key = matrix_locator_key(x, y)
  let mut i = 0
  while i < cell_map.length() {
    let (candidate, cell) = cell_map[i]
    if candidate == key {
      return Some(cell)
    }
    i += 1
  }
  None
}

///|
fn matrix_locator_key(x : Int, y : Int) -> String {
  "\{x}|\{y}"
}

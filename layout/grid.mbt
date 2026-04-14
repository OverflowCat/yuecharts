// Corresponds to: echarts/src/coord/cartesian/Grid.ts
// and echarts/src/layout/barGrid.ts
// and echarts/src/util/layout.ts#getLayoutRect

///|
/// Resolve a SizeSpec into pixels given a total dimension.
pub fn resolve_size(spec : @option.SizeSpec, total : Double) -> Double {
  match spec {
    Px(px) => px
    Pct(pct) => total * pct / 100.0
  }
}

///|
fn grid_layout_value(value : String, total : Double) -> Double {
  if value == "center" ||
    value == "middle" ||
    value == "right" ||
    value == "bottom" {
    0.0 / 0.0
  } else if value.has_suffix("%") {
    let pct_str = value[:value.length() - 1]
    let parsed = try? @strconv.parse_double(pct_str.to_string())
    match parsed {
      Ok(pct) => total * pct / 100.0
      Err(_) => 0.0 / 0.0
    }
  } else {
    let parsed = try? @strconv.parse_double(value)
    match parsed {
      Ok(px) => px
      Err(_) => 0.0 / 0.0
    }
  }
}

///|
/// Compute the plot-area bounding box from a GridOption and chart dimensions.
/// This is the rectangle *inside* the axis tick marks and labels.
pub fn compute_grid_bbox(
  grid : @option.GridOption,
  width : Double,
  height : Double,
) -> @graphic.BBox {
  let mut left = grid_layout_value(grid.left, width)
  let right = grid_layout_value(grid.right, width)
  let mut top = grid_layout_value(grid.top, height)
  let bottom = grid_layout_value(grid.bottom, height)
  let mut bbox_w = match grid.width {
    Some(value) => grid_layout_value(value, width)
    None => 0.0 / 0.0
  }
  let mut bbox_h = match grid.height {
    Some(value) => grid_layout_value(value, height)
    None => 0.0 / 0.0
  }

  if bbox_w.is_nan() {
    bbox_w = width - left - right
  }
  if bbox_h.is_nan() {
    bbox_h = height - top - bottom
  }

  match grid.left {
    "center" => left = width / 2.0 - bbox_w / 2.0
    "right" => left = width - bbox_w - right
    _ => ()
  }
  match grid.top {
    "center" | "middle" => top = height / 2.0 - bbox_h / 2.0
    "bottom" => top = height - bbox_h - bottom
    _ => ()
  }

  if left.is_nan() {
    left = width - right - bbox_w
  }
  if top.is_nan() {
    top = height - bottom - bbox_h
  }
  left = if left.is_nan() { 0.0 } else { left }
  top = if top.is_nan() { 0.0 } else { top }
  if bbox_w.is_nan() {
    bbox_w = width - left - right
  }
  if bbox_h.is_nan() {
    bbox_h = height - top - bottom
  }
  @graphic.BBox::new(left, top, bbox_w, bbox_h)
}

///|
/// Resolve the plot-area bounding box for a specific grid index.
/// Falls back to grid 0 when the requested index is missing.
pub fn grid_bbox_for_index(
  opt : @option.ChartOption,
  grid_index : Int,
) -> @graphic.BBox {
  if opt.grid.length() == 0 {
    return compute_grid_bbox(
      @option.GridOption::default(),
      opt.width,
      opt.height,
    )
  }
  let index = if grid_index >= 0 && grid_index < opt.grid.length() {
    grid_index
  } else {
    0
  }
  compute_grid_bbox(opt.grid[index], opt.width, opt.height)
}

///|
/// Build x-axis ordinal scales for all series that reference the given x-axis.
/// `data` is the category array from AxisOption.
pub fn make_ordinal_x_scale(
  data : Array[String],
  bbox : @graphic.BBox,
) -> @scale.OrdinalScale {
  let s = @scale.OrdinalScale::new(data, bbox.x, bbox.x + bbox.width, 0.1)
  s
}

///|
/// Build a linear y-axis scale fitted to the data range.
pub fn make_linear_y_scale(
  data_min : Double,
  data_max : Double,
  bbox : @graphic.BBox,
) -> @scale.LinearScale {
  // Y axis is inverted: data_max maps to bbox.y (top), data_min maps to bbox.y+height (bottom)
  @scale.LinearScale::new(data_min, data_max, bbox.y + bbox.height, bbox.y)
}

///|
/// Build a linear x-axis scale fitted to the data range.
pub fn make_linear_x_scale(
  data_min : Double,
  data_max : Double,
  bbox : @graphic.BBox,
) -> @scale.LinearScale {
  @scale.LinearScale::new(data_min, data_max, bbox.x, bbox.x + bbox.width)
}

///|
/// Build a Cartesian2D from the parsed chart option.
/// Each axis is resolved against its own `gridIndex`, with grid 0 as fallback.
pub fn build_cartesian(opt : @option.ChartOption) -> @coord.Cartesian2D {
  let bbox = grid_bbox_for_index(opt, 0)
  // Build x scales using explicit index loop
  let x_scales : Array[@coord.XScale] = []
  let mut xi = 0
  while xi < opt.x_axis.length() {
    let ax = opt.x_axis[xi]
    xi += 1
    let axis_grid_index = ax.grid_index.unwrap_or(0)
    let axis_bbox = grid_bbox_for_index(opt, axis_grid_index)
    let xs : @coord.XScale = match ax.axis_type {
      Category =>
        @coord.XScale::make_ordinal(make_ordinal_x_scale(ax.data, axis_bbox))
      Value | Log | Time => {
        let (dmin, dmax) = series_x_range(opt, xi - 1)
        let lo = ax.min.unwrap_or(dmin.min(0.0))
        let hi = ax.max.unwrap_or(dmax)
        @coord.XScale::make_linear(make_linear_x_scale(lo, hi, axis_bbox))
      }
    }
    x_scales.push(xs)
  }
  // Build y scales using explicit index loop
  let y_scales : Array[@coord.YScale] = []
  let mut yi = 0
  while yi < opt.y_axis.length() {
    let ax = opt.y_axis[yi]
    let axis_grid_index = ax.grid_index.unwrap_or(0)
    let axis_bbox = grid_bbox_for_index(opt, axis_grid_index)
    let ys : @coord.YScale = match ax.axis_type {
      Value | Log | Time => {
        let (dmin, dmax) = series_y_range(opt, yi)
        // ECharts default: scale=false means include 0 in the extent.
        // scale=true: fit axis to actual data range (do not force include 0).
        let lo = ax.min.unwrap_or(
          if ax.scale {
            dmin
          } else if dmin > 0.0 {
            0.0
          } else {
            dmin
          },
        )
        let hi = ax.max.unwrap_or(dmax)
        @coord.YScale::make_linear(make_linear_y_scale(lo, hi, axis_bbox))
      }
      Category =>
        @coord.YScale::make_ordinal(
          @scale.OrdinalScale::new(
            ax.data,
            axis_bbox.y + axis_bbox.height,
            axis_bbox.y,
            0.1,
          ),
        )
    }
    y_scales.push(ys)
    yi += 1
  }
  @coord.Cartesian2D::new(bbox, x_scales, y_scales)
}

///|
/// Collect the numeric y-data range across all series bound to the given y-axis
/// index.
fn series_y_range(opt : @option.ChartOption, y_idx : Int) -> (Double, Double) {
  let mut lo = 0.0
  let mut hi = 1.0
  let mut first = true
  let ns = opt.series.length()
  let mut si = 0
  while si < ns {
    let s = opt.series[si]
    si += 1
    if s.y_axis_index != y_idx {
      continue
    }
    let nd = s.data.length()
    let mut di = 0
    while di < nd {
      let item = s.data[di]
      di += 1
      match item.value {
        Num(n) =>
          if first {
            lo = n
            hi = n
            first = false
          } else {
            if n < lo {
              lo = n
            }
            if n > hi {
              hi = n
            }
          }
        Vec(arr) =>
          // For [x, y] scatter-style data, use arr[1] as the y value.
          // For OHLC/boxplot 4+-value arrays, ALL values are on the y-axis.
          if arr.length() >= 4 {
            let mut ai = 0
            while ai < arr.length() {
              let v = arr[ai]
              ai += 1
              if first {
                lo = v
                hi = v
                first = false
              } else {
                if v < lo {
                  lo = v
                }
                if v > hi {
                  hi = v
                }
              }
            }
          } else {
            let v_opt : Double? = if arr.length() >= 2 {
              Some(arr[1])
            } else if arr.length() == 1 {
              Some(arr[0])
            } else {
              None
            }
            match v_opt {
              None => ()
              Some(v) =>
                if first {
                  lo = v
                  hi = v
                  first = false
                } else {
                  if v < lo {
                    lo = v
                  }
                  if v > hi {
                    hi = v
                  }
                }
            }
          }
        DateValue(_, n) =>
          if first {
            lo = n
            hi = n
            first = false
          } else {
            if n < lo {
              lo = n
            }
            if n > hi {
              hi = n
            }
          }
        Null => ()
      }
    }
  }
  if first {
    (0.0, 1.0)
  } else {
    (lo, hi)
  }
}

///|
/// Collect the numeric x-data range across all series bound to the given x-axis
/// index.
fn series_x_range(opt : @option.ChartOption, x_idx : Int) -> (Double, Double) {
  let mut lo = 0.0
  let mut hi = 1.0
  let mut first = true
  let ns = opt.series.length()
  let mut si = 0
  while si < ns {
    let s = opt.series[si]
    si += 1
    if s.x_axis_index != x_idx {
      continue
    }
    let nd = s.data.length()
    let mut di = 0
    while di < nd {
      let item = s.data[di]
      di += 1
      let v_opt : Double? = match item.value {
        Num(n) => Some(n)
        Vec(arr) => if arr.length() > 0 { Some(arr[0]) } else { None }
        DateValue(_, n) => Some(n)
        Null => None
      }
      match v_opt {
        None => ()
        Some(v) =>
          if first {
            lo = v
            hi = v
            first = false
          } else {
            if v < lo {
              lo = v
            }
            if v > hi {
              hi = v
            }
          }
      }
    }
  }
  if first {
    (0.0, 1.0)
  } else {
    (lo, hi)
  }
}

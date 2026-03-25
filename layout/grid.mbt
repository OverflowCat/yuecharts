// Corresponds to: echarts/src/coord/cartesian/Grid.ts
// and echarts/src/layout/barGrid.ts

///|
/// Resolve a SizeSpec into pixels given a total dimension.
pub fn resolve_size(spec : @option.SizeSpec, total : Double) -> Double {
  match spec {
    Px(px) => px
    Pct(pct) => total * pct / 100.0
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
  let left = resolve_size(grid.left, width)
  let right = resolve_size(grid.right, width)
  let top = resolve_size(grid.top, height)
  let bottom = resolve_size(grid.bottom, height)
  let x = left
  let y = top
  let w = width - left - right
  let h = height - top - bottom
  @graphic.BBox::new(x, y, w, h)
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
/// Uses the first grid by default.
pub fn build_cartesian(opt : @option.ChartOption) -> @coord.Cartesian2D {
  let grid = if opt.grid.length() > 0 {
    opt.grid[0]
  } else {
    @option.GridOption::default()
  }
  let bbox = compute_grid_bbox(grid, opt.width, opt.height)
  // Build x scales using explicit index loop
  let x_scales : Array[@coord.XScale] = []
  let mut xi = 0
  while xi < opt.x_axis.length() {
    let ax = opt.x_axis[xi]
    xi = xi + 1
    let xs : @coord.XScale = match ax.axis_type {
      Category =>
        @coord.XScale::make_ordinal(make_ordinal_x_scale(ax.data, bbox))
      Value | Log | Time => {
        let (dmin, dmax) = series_x_range(opt, 0)
        @coord.XScale::make_linear(make_linear_x_scale(dmin, dmax, bbox))
      }
    }
    x_scales.push(xs)
  }
  // Build y scales using explicit index loop
  let y_scales : Array[@coord.YScale] = []
  let mut yi = 0
  while yi < opt.y_axis.length() {
    let ax = opt.y_axis[yi]
    let ys : @coord.YScale = match ax.axis_type {
      Value | Log | Time => {
        let (dmin, dmax) = series_y_range(opt, yi)
        // ECharts default: scale=false means include 0 in the extent.
        // If data min is positive, start axis from 0 (matches ECharts behavior).
        let lo = match ax.min {
          Some(v) => v
          None => if dmin > 0.0 { 0.0 } else { dmin }
        }
        let hi = match ax.max {
          Some(v) => v
          None => dmax
        }
        @coord.YScale::make_linear(make_linear_y_scale(lo, hi, bbox))
      }
      Category =>
        @coord.YScale::make_ordinal(
          @scale.OrdinalScale::new(ax.data, bbox.y + bbox.height, bbox.y, 0.1),
        )
    }
    y_scales.push(ys)
    yi = yi + 1
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
    si = si + 1
    if s.y_axis_index != y_idx {
      continue
    }
    let nd = s.data.length()
    let mut di = 0
    while di < nd {
      let item = s.data[di]
      di = di + 1
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
        Vec(arr) => {
          let mut ai = 0
          while ai < arr.length() {
            let v = arr[ai]
            ai = ai + 1
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
    si = si + 1
    if s.x_axis_index != x_idx {
      continue
    }
    let nd = s.data.length()
    let mut di = 0
    while di < nd {
      let item = s.data[di]
      di = di + 1
      let v_opt : Double? = match item.value {
        Num(n) => Some(n)
        Vec(arr) => if arr.length() > 0 { Some(arr[0]) } else { None }
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

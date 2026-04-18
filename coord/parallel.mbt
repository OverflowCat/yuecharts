// Corresponds to: echarts/src/coord/parallel/Parallel.ts
//                  echarts/src/coord/parallel/ParallelModel.ts
//                  echarts/src/coord/parallel/AxisModel.ts
//                  echarts/src/coord/parallel/ParallelAxis.ts

///|
pub(all) enum ParallelAxisScale {
  Ordinal(@scale.OrdinalScale)
  Linear(@scale.LinearScale)
}

///|
pub(all) struct ParallelAxis {
  dim_name : String
  dim_index : Int
  axis_type : @option.AxisType
  name : String?
  scale : ParallelAxisScale
  inverse : Bool
  show : Bool
}

///|
pub(all) struct ParallelAxisLayout {
  position : @graphic.Point
  rotation : Double
  axis_name_available_width : Double
  axis_label_show : Bool
}

///|
pub(all) struct Parallel {
  bbox : @graphic.BBox
  layout : String
  parallel_index : Int
  dimensions : Array[String]
  axes : Array[ParallelAxis]
  axis_layouts : Array[ParallelAxisLayout]
}

///|
pub fn Parallel::build(opt : @option.ChartOption) -> Parallel? {
  if opt.parallel_axis.length() == 0 {
    return None
  }
  // echarts/src/component/parallel/ParallelModel.ts: default parallel component
  let parallel_opt = if opt.parallel.length() > 0 {
    opt.parallel[0]
  } else {
    @option.ParallelOption::default()
  }
  let bbox = parallel_compute_bbox(parallel_opt, opt.width, opt.height)
  let axis_opts = parallel_collect_axis_options(opt, 0)
  if axis_opts.length() == 0 {
    return None
  }
  let axes : Array[ParallelAxis] = []
  let dimensions : Array[String] = []
  let mut i = 0
  while i < axis_opts.length() {
    let axis_opt = axis_opts[i]
    let dim_name = "dim\{axis_opt.dim}"
    dimensions.push(dim_name)
    axes.push(parallel_build_axis(axis_opt, bbox, parallel_opt.layout, opt))
    i += 1
  }
  let axis_layouts = parallel_build_axis_layouts(
    parallel_opt,
    bbox,
    axes.length(),
  )
  Some({
    bbox,
    layout: parallel_opt.layout,
    parallel_index: 0,
    dimensions,
    axes,
    axis_layouts,
  })
}

///|
pub fn Parallel::get_axis(self : Parallel, dim : String) -> ParallelAxis? {
  let mut i = 0
  while i < self.axes.length() {
    if self.axes[i].dim_name == dim {
      return Some(self.axes[i])
    }
    i += 1
  }
  None
}

///|
pub fn Parallel::get_axis_layout(
  self : Parallel,
  dim : String,
) -> ParallelAxisLayout? {
  let mut i = 0
  while i < self.axes.length() && i < self.axis_layouts.length() {
    if self.axes[i].dim_name == dim {
      return Some(self.axis_layouts[i])
    }
    i += 1
  }
  None
}

///|
pub fn Parallel::data_to_point(
  self : Parallel,
  item : @option.DataItem,
  dim : String,
) -> @graphic.Point? {
  let mut i = 0
  while i < self.axes.length() && i < self.axis_layouts.length() {
    let axis = self.axes[i]
    if axis.dim_name == dim {
      let layout = self.axis_layouts[i]
      match axis.data_to_coord(item.value, item.raw_value_parts) {
        Some(coord) =>
          return Some(
            if self.layout == "vertical" {
              @graphic.Point::new(coord, layout.position.y)
            } else {
              @graphic.Point::new(layout.position.x, coord)
            },
          )
        None => return None
      }
    }
    i += 1
  }
  None
}

///|
pub fn ParallelAxis::data_to_coord(
  self : ParallelAxis,
  value : @option.DataValue,
  raw_parts : Array[Json]?,
) -> Double? {
  match self.scale {
    Linear(scale) =>
      match parallel_value_to_double(value, self.dim_index) {
        Some(numeric) => Some(scale.data_to_pixel(numeric))
        None => None
      }
    Ordinal(scale) => {
      // echarts/src/coord/parallel/Parallel.ts: category axis string lookup
      let index = parallel_category_index(value, self.dim_index, raw_parts, scale.categories)
      match index {
        Some(index) => {
          let max_index = scale.categories.length() - 1
          let normalized = if max_index < 0 {
            0
          } else if index < 0 {
            0
          } else if index > max_index {
            max_index
          } else {
            index
          }
          Some(scale.band_center(normalized))
        }
        None => None
      }
    }
  }
}

///|
pub fn ParallelAxis::ticks(self : ParallelAxis) -> Array[@scale.Tick] {
  match self.scale {
    Linear(scale) => scale.ticks(5)
    Ordinal(scale) => scale.ticks()
  }
}

///|
fn parallel_compute_bbox(
  opt : @option.ParallelOption,
  width : Double,
  height : Double,
) -> @graphic.BBox {
  let left = parallel_resolve_size(opt.left, width)
  let right = parallel_resolve_size(opt.right, width)
  let top = parallel_resolve_size(opt.top, height)
  let bottom = parallel_resolve_size(opt.bottom, height)
  @graphic.BBox::new(left, top, width - left - right, height - top - bottom)
}

///|
fn parallel_resolve_size(spec : @option.SizeSpec, total : Double) -> Double {
  match spec {
    @option.SizeSpec::Px(px) => px
    @option.SizeSpec::Pct(pct) => total * pct / 100.0
  }
}

///|
fn parallel_collect_axis_options(
  opt : @option.ChartOption,
  parallel_index : Int,
) -> Array[@option.ParallelAxisOption] {
  let axes : Array[@option.ParallelAxisOption] = []
  let mut i = 0
  while i < opt.parallel_axis.length() {
    let axis = opt.parallel_axis[i]
    if axis.parallel_index == parallel_index {
      axes.push(axis)
    }
    i += 1
  }
  parallel_sort_axis_options(axes)
}

///|
fn parallel_sort_axis_options(
  axes : Array[@option.ParallelAxisOption],
) -> Array[@option.ParallelAxisOption] {
  let result : Array[@option.ParallelAxisOption] = []
  let used : Array[Bool] = []
  let mut i = 0
  while i < axes.length() {
    used.push(false)
    i += 1
  }
  let mut picked = 0
  while picked < axes.length() {
    let mut best = -1
    let mut j = 0
    while j < axes.length() {
      if !used[j] && (best == -1 || axes[j].dim < axes[best].dim) {
        best = j
      }
      j += 1
    }
    if best >= 0 {
      used[best] = true
      result.push(axes[best])
    }
    picked += 1
  }
  result
}

///|
fn parallel_build_axis(
  axis_opt : @option.ParallelAxisOption,
  bbox : @graphic.BBox,
  layout : String,
  opt : @option.ChartOption,
) -> ParallelAxis {
  let scale : ParallelAxisScale = match axis_opt.axis_type {
    @option.AxisType::Category => {
      let (range_min, range_max) = parallel_axis_range(
        bbox,
        layout,
        axis_opt.inverse,
      )
      Ordinal(
        @scale.OrdinalScale::new(axis_opt.data, range_min, range_max, 0.0),
      )
    }
    _ => {
      let (series_min, series_max) = parallel_axis_series_range(
        opt,
        axis_opt.dim,
        axis_opt.parallel_index,
      )
      let data_min = match axis_opt.min {
        Some(value) => value
        None => if series_min > 0.0 { 0.0 } else { series_min }
      }
      let data_max = match axis_opt.max {
        Some(value) => value
        None => series_max
      }
      let (range_min, range_max) = parallel_axis_range(
        bbox,
        layout,
        axis_opt.inverse,
      )
      Linear(@scale.LinearScale::new(data_min, data_max, range_min, range_max))
    }
  }
  {
    dim_name: "dim\{axis_opt.dim}",
    dim_index: axis_opt.dim,
    axis_type: axis_opt.axis_type,
    name: axis_opt.name,
    scale,
    inverse: axis_opt.inverse,
    show: axis_opt.show,
  }
}

///|
fn parallel_axis_range(
  bbox : @graphic.BBox,
  layout : String,
  inverse : Bool,
) -> (Double, Double) {
  if layout == "vertical" {
    if inverse {
      (bbox.x + bbox.width, bbox.x)
    } else {
      (bbox.x, bbox.x + bbox.width)
    }
  } else if inverse {
    (bbox.y, bbox.y + bbox.height)
  } else {
    (bbox.y + bbox.height, bbox.y)
  }
}

///|
fn parallel_axis_series_range(
  opt : @option.ChartOption,
  dim_index : Int,
  parallel_index : Int,
) -> (Double, Double) {
  let mut lo = 0.0
  let mut hi = 1.0
  let mut first = true
  let mut i = 0
  while i < opt.series.length() {
    let series = opt.series[i]
    if series.series_type == @option.SeriesType::Parallel &&
      series.parallel_index == parallel_index {
      let mut j = 0
      while j < series.data.length() {
        let item = series.data[j]
        let value = parallel_item_dimension_value(item, dim_index)
        match value {
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
          None => ()
        }
        j += 1
      }
    }
    i += 1
  }
  if first {
    (0.0, 1.0)
  } else {
    (lo, hi)
  }
}

///|
fn parallel_item_dimension_value(
  item : @option.DataItem,
  dim_index : Int,
) -> Double? {
  match item.value {
    @option.Num(n) => if dim_index == 0 { Some(n) } else { None }
    @option.DateValue(_, n) => if dim_index == 0 { Some(n) } else { None }
    @option.Vec(arr) =>
      if dim_index < arr.length() {
        Some(arr[dim_index])
      } else {
        None
      }
    @option.Null => None
  }
}

///|
fn parallel_value_to_double(
  value : @option.DataValue,
  dim_index : Int,
) -> Double? {
  match value {
    @option.Num(n) => if dim_index == 0 { Some(n) } else { None }
    @option.DateValue(_, n) => if dim_index == 0 { Some(n) } else { None }
    @option.Vec(arr) =>
      if dim_index < arr.length() {
        Some(arr[dim_index])
      } else {
        None
      }
    @option.Null => None
  }
}

///|
// echarts/src/coord/parallel/Parallel.ts: category axis — try string name lookup
// from raw_parts first, then fall back to numeric index
fn parallel_category_index(
  value : @option.DataValue,
  dim_index : Int,
  raw_parts : Array[Json]?,
  categories : Array[String],
) -> Int? {
  // Step 1: try to get string from raw_parts
  let str_val : String? = match raw_parts {
    Some(arr) if dim_index < arr.length() =>
      match arr[dim_index] {
        String(s) => Some(s)
        _ => None
      }
    _ => None
  }
  // Step 2: if we have a string, look it up in categories
  match str_val {
    Some(s) => {
      let mut k = 0
      while k < categories.length() {
        if categories[k] == s {
          return Some(k)
        }
        k += 1
      }
      None
    }
    // Step 3: fall back to numeric index in value
    None =>
      match parallel_value_to_double(value, dim_index) {
        Some(numeric) => Some(numeric.to_int())
        None => None
      }
  }
}

///|
fn parallel_build_axis_layouts(
  parallel_opt : @option.ParallelOption,
  bbox : @graphic.BBox,
  axis_count : Int,
) -> Array[ParallelAxisLayout] {
  let layouts : Array[ParallelAxisLayout] = []
  if axis_count <= 0 {
    return layouts
  }
  let step = if axis_count <= 1 {
    0.0
  } else if parallel_opt.layout == "vertical" {
    bbox.height / (axis_count - 1).to_double()
  } else {
    bbox.width / (axis_count - 1).to_double()
  }
  let rotation = if parallel_opt.layout == "vertical" {
    0.0
  } else {
    @math.PI / 2.0
  }
  let mut i = 0
  while i < axis_count {
    let position = if parallel_opt.layout == "vertical" {
      @graphic.Point::new(bbox.x, bbox.y + step * i.to_double())
    } else {
      @graphic.Point::new(bbox.x + step * i.to_double(), bbox.y + bbox.height)
    }
    layouts.push({
      position,
      rotation,
      axis_name_available_width: step,
      axis_label_show: true,
    })
    i += 1
  }
  layouts
}

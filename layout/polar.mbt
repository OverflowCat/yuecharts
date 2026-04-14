// Corresponds to: echarts/src/coord/polar/polarCreator.ts
//                  echarts/src/component/polar/install.ts

///|
fn parse_pct_or_px(value : String, reference : Double) -> Double {
  if value.has_suffix("%") {
    let inner = value[:value.length() - 1]
    let result = try? @strconv.parse_double(inner.to_string())
    match result {
      Ok(parsed) => parsed / 100.0 * reference
      Err(_) => 0.0
    }
  } else {
    let result = try? @strconv.parse_double(value)
    match result {
      Ok(parsed) => parsed
      Err(_) => 0.0
    }
  }
}

///|
fn build_angle_axis(
  opt : @option.ChartOption,
  polar_index : Int,
) -> @coord.PolarAxis {
  let axis_option = if opt.angle_axis.length() > polar_index {
    opt.angle_axis[polar_index]
  } else {
    {
      ..@option.AxisOption::default_y(),
      start_angle: Some(90.0),
      clockwise: Some(true),
    }
  }
  let start_angle = axis_option.start_angle.unwrap_or(90.0)
  let clockwise = axis_option.clockwise.unwrap_or(true)
  let end_angle = axis_option.end_angle.unwrap_or(
    start_angle +
    (if axis_option.inverse != clockwise { -360.0 } else { 360.0 }),
  )
  let inverse = axis_option.inverse != clockwise
  let base_axis_type = polar_base_axis_type(opt, polar_index)
  let scale = match axis_option.axis_type {
    @option.Category =>
      @scale.OrdinalScale::new(axis_option.data, start_angle, end_angle, 0.0)
      |> @coord.PolarAxisScale::Ordinal
    _ => {
      let (data_min, data_max) = polar_axis_series_range(
        opt,
        polar_index,
        "angle",
        axis_option.axis_type,
        base_axis_type,
      )
      let lo = axis_option.min.unwrap_or(data_min)
      let hi = axis_option.max.unwrap_or(data_max)
      @scale.LinearScale::new(lo, hi, start_angle, end_angle)
      |> @coord.PolarAxisScale::Linear
    }
  }
  {
    dim: "angle",
    axis_type: axis_option.axis_type,
    scale,
    extent_start: start_angle,
    extent_end: end_angle,
    on_band: false,
    inverse,
  }
}

///|
fn build_radius_axis(
  opt : @option.ChartOption,
  polar_index : Int,
  chart_size : Double,
  polar_option : @option.PolarOption,
) -> @coord.PolarAxis {
  let axis_option = if opt.radius_axis.length() > polar_index {
    opt.radius_axis[polar_index]
  } else {
    @option.AxisOption::default_y()
  }
  let radius = if polar_option.radius.length() >= 2 {
    polar_option.radius
  } else if polar_option.radius.length() == 1 {
    ["0", polar_option.radius[0]]
  } else {
    ["0", "80%"]
  }
  let radius_extent_start = parse_pct_or_px(radius[0], chart_size)
  let radius_extent_end = parse_pct_or_px(radius[1], chart_size)
  let (range_start, range_end) = if axis_option.inverse {
    (radius_extent_end, radius_extent_start)
  } else {
    (radius_extent_start, radius_extent_end)
  }
  let base_axis_type = polar_base_axis_type(opt, polar_index)
  let scale = match axis_option.axis_type {
    @option.Category =>
      @coord.PolarAxisScale::Ordinal(
        @scale.OrdinalScale::new(axis_option.data, range_start, range_end, 0.0),
      )
    _ => {
      let (data_min, data_max) = polar_axis_series_range(
        opt,
        polar_index,
        "radius",
        axis_option.axis_type,
        base_axis_type,
      )
      let lo = axis_option.min.unwrap_or(
        if data_min > 0.0 {
          0.0
        } else {
          data_min
        },
      )
      let hi = axis_option.max.unwrap_or(data_max)
      @coord.PolarAxisScale::Linear(
        @scale.LinearScale::new(lo, hi, range_start, range_end),
      )
    }
  }
  {
    dim: "radius",
    axis_type: axis_option.axis_type,
    scale,
    extent_start: range_start,
    extent_end: range_end,
    on_band: false,
    inverse: axis_option.inverse,
  }
}

///|
pub fn build_polar(opt : @option.ChartOption) -> @coord.Polar? {
  if opt.polar.length() == 0 {
    return None
  }
  let polar_option = opt.polar[0]
  let center = if polar_option.center.length() >= 2 {
    polar_option.center
  } else {
    ["50%", "50%"]
  }
  let cx = parse_pct_or_px(center[0], opt.width)
  let cy = parse_pct_or_px(center[1], opt.height)
  let chart_size = (if opt.width < opt.height { opt.width } else { opt.height }) /
    2.0
  let angle_axis = build_angle_axis(opt, 0)
  let radius_axis = build_radius_axis(opt, 0, chart_size, polar_option)
  Some({ cx, cy, angle_axis, radius_axis })
}

///|
fn polar_axis_series_range(
  opt : @option.ChartOption,
  polar_index : Int,
  dim : String,
  axis_type : @option.AxisType,
  base_axis_type : @option.AxisType,
) -> (Double, Double) {
  let mut lo = 0.0
  let mut hi = if dim == "angle" { 360.0 } else { 1.0 }
  let mut first = true
  let range_stack_groups : Array[PolarRangeStackGroup] = []
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si += 1
    if series.coordinate_system != Some("polar") ||
      series.polar_index != polar_index {
      continue
    }
    let stack_group_index = if series.series_type == @option.SeriesType::Bar &&
      series.stack != None {
      let stack_id = polar_series_stack_id(series, si - 1)
      let existing = polar_find_range_stack_group_index(
        range_stack_groups, stack_id,
      )
      if existing >= 0 {
        existing
      } else {
        range_stack_groups.push({ stack_id, bases: [] })
        range_stack_groups.length() - 1
      }
    } else {
      -1
    }
    let mut di = 0
    while di < series.data.length() {
      let item = series.data[di]
      let value_opt = polar_dimension_value(item.value, dim, axis_type, di)
      match value_opt {
        Some(value) => {
          let range = polar_update_range(lo, hi, value, first)
          lo = range.0
          hi = range.1
          first = range.2
          if stack_group_index >= 0 {
            let base = polar_base_value(item.value, base_axis_type, di)
            let bases = range_stack_groups[stack_group_index].bases
            let base_index = polar_find_range_stack_base_index(bases, base)
            if base_index >= 0 {
              if value >= 0.0 {
                range_stack_groups[stack_group_index].bases[base_index].positive
                += value
              } else {
                range_stack_groups[stack_group_index].bases[base_index].negative
                += value
              }
            } else {
              range_stack_groups[stack_group_index].bases.push({
                base,
                positive: if value >= 0.0 {
                  value
                } else {
                  0.0
                },
                negative: if value < 0.0 {
                  value
                } else {
                  0.0
                },
              })
            }
          }
        }
        None => ()
      }
      di += 1
    }
  }
  let mut gi = 0
  while gi < range_stack_groups.length() {
    let bases = range_stack_groups[gi].bases
    let mut bi = 0
    while bi < bases.length() {
      let entry = bases[bi]
      let range_pos = polar_update_range(lo, hi, entry.positive, first)
      lo = range_pos.0
      hi = range_pos.1
      first = range_pos.2
      let range_neg = polar_update_range(lo, hi, entry.negative, first)
      lo = range_neg.0
      hi = range_neg.1
      first = range_neg.2
      bi += 1
    }
    gi += 1
  }
  if first {
    if dim == "angle" {
      (0.0, 360.0)
    } else {
      (0.0, 1.0)
    }
  } else {
    (lo, hi)
  }
}

///|
fn polar_dimension_value(
  value : @option.DataValue,
  dim : String,
  axis_type : @option.AxisType,
  fallback_index : Int,
) -> Double? {
  match value {
    @option.Vec(arr) =>
      if arr.length() >= 2 {
        Some(if dim == "radius" { arr[0] } else { arr[1] })
      } else if arr.length() == 1 {
        Some(arr[0])
      } else {
        None
      }
    @option.Num(n) =>
      if dim == "radius" {
        Some(n)
      } else if axis_type == @option.Category {
        Some(fallback_index.to_double())
      } else {
        Some(n)
      }
    @option.DateValue(_, n) => Some(n)
    @option.Null => None
  }
}

///|
priv struct PolarRangeStackBase {
  base : Double
  mut positive : Double
  mut negative : Double
}

///|
priv struct PolarRangeStackGroup {
  stack_id : String
  bases : Array[PolarRangeStackBase]
}

///|
fn polar_series_stack_id(
  series : @option.SeriesOption,
  series_index : Int,
) -> String {
  match series.stack {
    Some(stack) => stack
    None => "__ec_stack_\{series_index}"
  }
}

///|
fn polar_find_range_stack_group_index(
  groups : Array[PolarRangeStackGroup],
  stack_id : String,
) -> Int {
  let mut i = 0
  while i < groups.length() {
    if groups[i].stack_id == stack_id {
      return i
    }
    i += 1
  }
  -1
}

///|
fn polar_find_range_stack_base_index(
  bases : Array[PolarRangeStackBase],
  base : Double,
) -> Int {
  let mut i = 0
  while i < bases.length() {
    if bases[i].base == base {
      return i
    }
    i += 1
  }
  -1
}

///|
fn polar_base_value(
  value : @option.DataValue,
  axis_type : @option.AxisType,
  fallback_index : Int,
) -> Double {
  match axis_type {
    @option.Category => fallback_index.to_double()
    _ =>
      match value {
        @option.Num(n) => n
        @option.Vec(arr) =>
          if arr.length() > 0 {
            arr[0]
          } else {
            fallback_index.to_double()
          }
        @option.DateValue(_, n) => n
        @option.Null => fallback_index.to_double()
      }
  }
}

///|
fn polar_update_range(
  current_min : Double,
  current_max : Double,
  value : Double,
  first : Bool,
) -> (Double, Double, Bool) {
  if first {
    (value, value, false)
  } else {
    (
      if value < current_min {
        value
      } else {
        current_min
      },
      if value > current_max {
        value
      } else {
        current_max
      },
      false,
    )
  }
}

///|
fn polar_base_axis_type(
  opt : @option.ChartOption,
  polar_index : Int,
) -> @option.AxisType {
  let angle_type = if opt.angle_axis.length() > polar_index {
    opt.angle_axis[polar_index].axis_type
  } else {
    @option.AxisOption::default_y().axis_type
  }
  let radius_type = if opt.radius_axis.length() > polar_index {
    opt.radius_axis[polar_index].axis_type
  } else {
    @option.AxisOption::default_y().axis_type
  }
  if angle_type == @option.AxisType::Category ||
    angle_type == @option.AxisType::Time {
    angle_type
  } else if radius_type == @option.AxisType::Category ||
    radius_type == @option.AxisType::Time {
    radius_type
  } else {
    angle_type
  }
}

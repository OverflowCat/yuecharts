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
) -> (Double, Double) {
  let mut lo = 0.0
  let mut hi = if dim == "angle" { 360.0 } else { 1.0 }
  let mut first = true
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si += 1
    if series.coordinate_system != Some("polar") ||
      series.polar_index != polar_index {
      continue
    }
    let mut di = 0
    while di < series.data.length() {
      let item = series.data[di]
      let value_opt = polar_dimension_value(item.value, dim, axis_type, di)
      match value_opt {
        Some(value) =>
          if first {
            lo = value
            hi = value
            first = false
          } else {
            if value < lo {
              lo = value
            }
            if value > hi {
              hi = value
            }
          }
        None => ()
      }
      di += 1
    }
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

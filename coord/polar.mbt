// Corresponds to: echarts/src/coord/polar/Polar.ts
//                  echarts/src/coord/polar/AngleAxis.ts
//                  echarts/src/coord/polar/RadiusAxis.ts
//                  echarts/src/coord/polar/PolarModel.ts
//                  echarts/src/coord/polar/AxisModel.ts
//                  echarts/src/coord/polar/prepareCustom.ts

///|
pub(all) enum PolarAxisScale {
  Ordinal(@scale.OrdinalScale)
  Linear(@scale.LinearScale)
}

///|
pub(all) struct PolarAxis {
  dim : String
  axis_type : @option.AxisType
  scale : PolarAxisScale
  extent_start : Double
  extent_end : Double
  on_band : Bool
  inverse : Bool
}

///|
pub(all) struct Polar {
  cx : Double
  cy : Double
  radius_axis : PolarAxis
  angle_axis : PolarAxis
}

///|
pub(all) struct PolarArea {
  cx : Double
  cy : Double
  r0 : Double
  r : Double
  start_angle : Double
  end_angle : Double
  clockwise : Bool
}

///|
pub fn Polar::get_axis(self : Polar, dim : String) -> PolarAxis {
  if dim == "radius" {
    self.radius_axis
  } else {
    self.angle_axis
  }
}

///|
pub fn Polar::get_angle_axis(self : Polar) -> PolarAxis {
  self.angle_axis
}

///|
pub fn Polar::get_radius_axis(self : Polar) -> PolarAxis {
  self.radius_axis
}

///|
pub fn Polar::get_other_axis(self : Polar, axis : PolarAxis) -> PolarAxis {
  if axis.dim == "angle" {
    self.radius_axis
  } else {
    self.angle_axis
  }
}

///|
pub fn Polar::get_base_axis(self : Polar) -> PolarAxis {
  let angle = self.angle_axis
  let radius = self.radius_axis
  match angle.axis_type {
    @option.Category | @option.Time => angle
    _ =>
      match radius.axis_type {
        @option.Category | @option.Time => radius
        _ => angle
      }
  }
}

///|
pub fn PolarAxis::get_extent(self : PolarAxis) -> (Double, Double) {
  (self.extent_start, self.extent_end)
}

///|
pub fn PolarAxis::data_to_coord(
  self : PolarAxis,
  value : @option.DataValue,
  fallback_index : Int,
) -> Double {
  match self.scale {
    Linear(scale) => {
      let numeric = match value {
        @option.Num(n) => n
        @option.Vec(arr) =>
          if arr.length() > 0 {
            arr[0]
          } else {
            fallback_index.to_double()
          }
        @option.DateValue(_, n) => n
        @option.Null => 0.0
      }
      scale.data_to_pixel(numeric)
    }
    Ordinal(scale) => {
      let key = match value {
        @option.Num(n) => n.to_int().to_string()
        @option.Vec(arr) =>
          if arr.length() > 0 {
            arr[0].to_int().to_string()
          } else {
            fallback_index.to_string()
          }
        @option.DateValue(date, _) => date
        @option.Null => fallback_index.to_string()
      }
      match scale.index_of(key) {
        Some(index) =>
          if self.dim == "angle" && !self.on_band {
            scale.range_min + index.to_double() * scale.band_step()
          } else {
            scale.band_center(index)
          }
        None =>
          if self.dim == "angle" && !self.on_band {
            scale.range_min + fallback_index.to_double() * scale.band_step()
          } else {
            scale.band_center(fallback_index)
          }
      }
    }
  }
}

///|
pub fn PolarAxis::coord_to_data(self : PolarAxis, coord : Double) -> Double {
  match self.scale {
    Linear(scale) => scale.pixel_to_data(coord)
    Ordinal(scale) =>
      if scale.band_step() == 0.0 {
        0.0
      } else {
        ((coord - scale.range_min) / scale.band_step()).floor()
      }
  }
}

///|
pub fn PolarAxis::ticks(
  self : PolarAxis,
) -> Array[@OverflowCat/yuecharts/scale.Tick] {
  match self.scale {
    Linear(scale) =>
      scale
      .ticks(5)
      .map(fn(tick) {
        { value: scale.data_to_pixel(tick.value), label: tick.label }
      })
    Ordinal(scale) =>
      scale.ticks().map(fn(tick) { { value: tick.value, label: tick.label } })
  }
}

///|
pub fn Polar::coord_to_point(
  self : Polar,
  radius : Double,
  angle_deg : Double,
) -> @graphic.Point {
  let radian = angle_deg / 180.0 * @math.PI
  {
    x: @math.cos(radian) * radius + self.cx,
    y: -@math.sin(radian) * radius + self.cy,
  }
}

///|
pub fn Polar::data_to_point(
  self : Polar,
  radius_value : @option.DataValue,
  angle_value : @option.DataValue,
  fallback_index : Int,
) -> @graphic.Point {
  let radius = self.radius_axis.data_to_coord(radius_value, fallback_index)
  let angle = self.angle_axis.data_to_coord(angle_value, fallback_index)
  self.coord_to_point(radius, angle)
}

///|
pub fn Polar::point_to_coord(
  self : Polar,
  point : @graphic.Point,
) -> (Double, Double) {
  let mut dx = point.x - self.cx
  let mut dy = point.y - self.cy
  let mut min_angle = self.angle_axis.extent_start
  let mut max_angle = self.angle_axis.extent_end
  if min_angle > max_angle {
    let tmp = min_angle
    min_angle = max_angle
    max_angle = tmp
  }
  if self.angle_axis.inverse {
    min_angle = max_angle - 360.0
  } else {
    max_angle = min_angle + 360.0
  }
  let radius = (dx * dx + dy * dy).sqrt()
  if radius != 0.0 {
    dx /= radius
    dy /= radius
  }
  let mut angle = @math.atan2(-dy, dx) / @math.PI * 180.0
  let dir = if angle < min_angle { 1.0 } else { -1.0 }
  while angle < min_angle || angle > max_angle {
    angle += dir * 360.0
  }
  (radius, angle)
}

///|
pub fn Polar::get_area(self : Polar) -> PolarArea {
  let mut r0 = self.radius_axis.extent_start
  let mut r = self.radius_axis.extent_end
  if r0 > r {
    let tmp = r0
    r0 = r
    r = tmp
  }
  {
    cx: self.cx,
    cy: self.cy,
    r0,
    r,
    start_angle: -self.angle_axis.extent_start / 180.0 * @math.PI,
    end_angle: -self.angle_axis.extent_end / 180.0 * @math.PI,
    clockwise: self.angle_axis.inverse,
  }
}

///|
pub(all) struct PolarPrepareCoordSysInfo {
  type_name : String
  cx : Double
  cy : Double
  r : Double
  r0 : Double
}

///|
pub(all) struct PolarPreparedCustom {
  coord_sys : PolarPrepareCoordSysInfo
}

///|
pub fn Polar::prepare_custom(self : Polar) -> PolarPreparedCustom {
  let radius = self.radius_axis.get_extent()
  let r0 = if radius.0 < radius.1 { radius.0 } else { radius.1 }
  let r = if radius.0 < radius.1 { radius.1 } else { radius.0 }
  { coord_sys: { type_name: "polar", cx: self.cx, cy: self.cy, r, r0 } }
}

///|
pub fn Polar::data_to_coord_size(
  self : Polar,
  data_size : Array[Double],
  data_item : Array[Double]?,
) -> Array[Double] {
  let item = match data_item {
    Some(value) => value
    None => [0.0, 0.0]
  }
  let result : Array[Double] = []
  let mut idx = 0
  while idx < 2 {
    let axis = if idx == 0 { self.radius_axis } else { self.angle_axis }
    let val = if idx < item.length() { item[idx] } else { 0.0 }
    let half_size = if idx < data_size.length() {
      data_size[idx] / 2.0
    } else {
      0.0
    }
    let mut size = match axis.scale {
      Ordinal(scale) => scale.band_width()
      Linear(scale) =>
        (scale.data_to_pixel(val - half_size) -
        scale.data_to_pixel(val + half_size)).abs()
    }
    if idx == 1 {
      size = size * @math.PI / 180.0
    }
    result.push(size)
    idx += 1
  }
  result
}

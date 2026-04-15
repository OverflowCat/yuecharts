// Corresponds to: echarts/src/coord/cartesian/Cartesian2D.ts
// and echarts/src/coord/cartesian/Axis2D.ts

///|
/// A resolved Cartesian 2D coordinate system: holds the grid bounding box
/// and the scales for the X and Y axes.
pub struct Cartesian2D {
  /// Pixel bounding box of the plot area (inside axis labels).
  bbox : @graphic.BBox
  /// Each x-axis scale (one per x-axis in the chart option).
  x_scales : Array[XScale]
  /// Each y-axis scale (one per y-axis).
  y_scales : Array[YScale]
}

///|
pub fn Cartesian2D::new(
  bbox : @graphic.BBox,
  x_scales : Array[XScale],
  y_scales : Array[YScale],
) -> Cartesian2D {
  { bbox, x_scales, y_scales }
}

///|
/// Scale for a single X axis: either ordinal (category) or linear (value).
pub enum XScale {
  Ordinal(@scale.OrdinalScale)
  Linear(@scale.LinearScale)
}

///|
/// Scale for a single Y axis.
pub enum YScale {
  Ordinal(@scale.OrdinalScale)
  Linear(@scale.LinearScale)
  BreakLinear(@scale.BreakLinearScale)
}

///|
pub fn XScale::make_ordinal(s : @scale.OrdinalScale) -> XScale {
  Ordinal(s)
}

///|
pub fn XScale::make_linear(s : @scale.LinearScale) -> XScale {
  Linear(s)
}

///|
pub fn YScale::make_ordinal(s : @scale.OrdinalScale) -> YScale {
  Ordinal(s)
}

///|
pub fn YScale::make_linear(s : @scale.LinearScale) -> YScale {
  Linear(s)
}

///|
pub fn YScale::make_break_linear(s : @scale.BreakLinearScale) -> YScale {
  BreakLinear(s)
}

///|
/// Map a category value to pixel X in the given x-axis.
pub fn Cartesian2D::cat_x(
  self : Cartesian2D,
  index : Int,
  cat : String,
) -> Double {
  if index < 0 || index >= self.x_scales.length() {
    return self.bbox.x
  }
  match self.x_scales[index] {
    Ordinal(s) =>
      match s.data_to_pixel(cat) {
        Some(px) => px
        None => self.bbox.x
      }
    Linear(_) => self.bbox.x
  }
}

///|
/// Map a numeric value to pixel X in the given x-axis.
pub fn Cartesian2D::num_x(
  self : Cartesian2D,
  index : Int,
  v : Double,
) -> Double {
  if index < 0 || index >= self.x_scales.length() {
    return self.bbox.x
  }
  match self.x_scales[index] {
    Linear(s) => s.data_to_pixel(v)
    Ordinal(_) => self.bbox.x
  }
}

///|
/// Map a numeric value to pixel Y in the given y-axis.
pub fn Cartesian2D::num_y(
  self : Cartesian2D,
  index : Int,
  v : Double,
) -> Double {
  if index < 0 || index >= self.y_scales.length() {
    return self.bbox.bottom()
  }
  match self.y_scales[index] {
    Linear(s) => s.data_to_pixel(v)
    BreakLinear(s) => s.data_to_pixel(v)
    Ordinal(s) =>
      match s.data_to_pixel(v.to_string()) {
        Some(px) => px
        None => self.bbox.bottom()
      }
  }
}

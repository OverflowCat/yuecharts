///|
/// Default ECharts 5 color palette.
pub let echarts_palette : Array[String] = [
  "#5470c6", "#91cc75", "#fac858", "#ee6666", "#73c0de", "#3ba272", "#fc8452", "#9a60b4",
  "#ea7ccc",
]

///|
/// Get a palette color by series index (wraps around).
pub fn palette_color(index : Int) -> String {
  echarts_palette[index % echarts_palette.length()]
}

///|
/// Item style merged with defaults.
pub struct ItemStyle {
  color : String?
  border_color : String?
  border_width : Double?
  opacity : Double?
}

///|
pub fn ItemStyle::default() -> ItemStyle {
  { color: None, border_color: None, border_width: None, opacity: None }
}

///|
pub fn ItemStyle::resolved_color(self : ItemStyle, index : Int) -> String {
  match self.color {
    Some(c) => c
    None => palette_color(index)
  }
}

///|
pub fn ItemStyle::resolved_opacity(self : ItemStyle) -> Double {
  match self.opacity {
    Some(o) => o
    None => 1.0
  }
}

///|
/// Line style merged with defaults.
pub struct LineStyle {
  color : String?
  width : Double?
  dash : Array[Double]?
}

///|
pub fn LineStyle::default() -> LineStyle {
  { color: None, width: None, dash: None }
}

///|
pub fn LineStyle::resolved_width(self : LineStyle) -> Double {
  match self.width {
    Some(w) => w
    None => 2.0
  }
}

///|
pub fn LineStyle::resolved_color(self : LineStyle, index : Int) -> String {
  match self.color {
    Some(c) => c
    None => palette_color(index)
  }
}

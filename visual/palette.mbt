// Corresponds to: echarts/src/visual/style.ts
// and echarts/src/theme/default.ts (color palette definitions)

///|
/// Default ECharts 6 color palette (from echarts/src/visual/tokens.ts).
pub let echarts_palette : Array[String] = [
  "#5070dd", "#b6d634", "#505372", "#ff994d", "#0ca8df", "#ffd10a", "#fb628b", "#785db0",
  "#3fbe95",
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
} derive(Default)

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
} derive(Default)

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

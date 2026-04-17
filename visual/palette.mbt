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

///|
/// Parse a 3- or 6-digit hex color string to (r, g, b).
/// Returns None if unparsable.
/// <=> zrender/src/tool/color.ts:parse (hex path)
fn parse_hex_color(hex : String) -> (Int, Int, Int)? {
  let s = if hex.length() > 0 && hex[0].to_int() == 0x23 {
    // '#' == 0x23
    hex.substring(start=1)
  } else {
    hex
  }
  if s.length() == 3 {
    let r = parse_hex_nibble(s[0])
    let g = parse_hex_nibble(s[1])
    let b = parse_hex_nibble(s[2])
    match (r, g, b) {
      (Some(rv), Some(gv), Some(bv)) => Some((rv * 17, gv * 17, bv * 17))
      _ => None
    }
  } else if s.length() == 6 {
    let r0 = parse_hex_nibble(s[0])
    let r1 = parse_hex_nibble(s[1])
    let g0 = parse_hex_nibble(s[2])
    let g1 = parse_hex_nibble(s[3])
    let b0 = parse_hex_nibble(s[4])
    let b1 = parse_hex_nibble(s[5])
    match (r0, r1, g0, g1, b0, b1) {
      (Some(r0v), Some(r1v), Some(g0v), Some(g1v), Some(b0v), Some(b1v)) =>
        Some((r0v * 16 + r1v, g0v * 16 + g1v, b0v * 16 + b1v))
      _ => None
    }
  } else {
    None
  }
}

///|
fn parse_hex_nibble(c : UInt16) -> Int? {
  let n = c.to_int()
  if n >= 0x30 && n <= 0x39 {
    Some(n - 0x30) // '0'-'9'
  } else if n >= 0x41 && n <= 0x46 {
    Some(n - 0x41 + 10) // 'A'-'F'
  } else if n >= 0x61 && n <= 0x66 {
    Some(n - 0x61 + 10) // 'a'-'f'
  } else {
    None
  }
}

///|
fn int_to_hex2(n : Int) -> String {
  let hi = n / 16
  let lo = n % 16
  nibble_str(hi) + nibble_str(lo)
}

///|
fn nibble_str(v : Int) -> String {
  if v < 10 {
    v.to_string()
  } else {
    match v {
      10 => "a"
      11 => "b"
      12 => "c"
      13 => "d"
      14 => "e"
      _ => "f"
    }
  }
}

///|
/// Lift (brighten) a hex color by multiplying each channel by 1.1, clamped to 255.
/// Returns the original string if unparsable (graceful fallback).
/// <=> zrender/src/tool/color.ts:lift(color, -0.1)
/// Used for emphasis (highlight) state visual effect.
pub fn lift_hex_color(color : String) -> String {
  match parse_hex_color(color) {
    Some((r, g, b)) => {
      let lift = fn(v : Int) -> Int {
        let lifted = (v.to_double() * 1.1).to_int()
        if lifted > 255 {
          255
        } else {
          lifted
        }
      }
      "#" + int_to_hex2(lift(r)) + int_to_hex2(lift(g)) + int_to_hex2(lift(b))
    }
    None => color
  }
}

///|
/// Check if any DataItem in the array has highlighted == Some(true).
/// Used to decide whether to apply blur opacity to non-highlighted items.
/// <=> echarts/src/util/states.ts:enterBlur (implicit: blur is applied when any sibling is in emphasis)
pub fn has_any_highlighted(data : Array[@option.DataItem]) -> Bool {
  for item in data {
    if item.highlighted == Some(true) {
      return true
    }
  }
  false
}

///|
/// Resolve fill color and opacity for a DataItem under emphasis/blur state.
/// - If this item is highlighted: lift fill color, opacity=1.0
/// - If another item is highlighted (blur): keep fill color, opacity=0.1
/// - Otherwise (normal): keep fill color, opacity=1.0
/// <=> echarts/src/util/states.ts:createEmphasisDefaultState / createBlurDefaultState
pub fn resolve_item_emphasis_color_opacity(
  item : @option.DataItem,
  any_highlighted : Bool,
  base_color : String,
  base_opacity : Double,
) -> (String, Double) {
  match item.highlighted {
    Some(true) => (lift_hex_color(base_color), base_opacity)
    _ =>
      if any_highlighted {
        (base_color, base_opacity * 0.1)
      } else {
        (base_color, base_opacity)
      }
  }
}

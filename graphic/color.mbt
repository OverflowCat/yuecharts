// Corresponds to: zrender/src/tool/color.ts

///|
/// RGBA color representation (each channel 0-255, alpha 0-255).
pub struct Color {
  r : Int
  g : Int
  b : Int
  a : Int
} derive(Eq)

///|
/// Predefined transparent color constant.
pub let transparent : Color = { r: 0, g: 0, b: 0, a: 0 }

///|
/// Predefined black color constant.
pub let black : Color = { r: 0, g: 0, b: 0, a: 255 }

///|
/// Predefined white color constant.
pub let white : Color = { r: 255, g: 255, b: 255, a: 255 }

///|
/// Create a color from RGB values (fully opaque).
pub fn Color::rgb(r : Int, g : Int, b : Int) -> Color {
  { r, g, b, a: 255 }
}

///|
/// Create a color from RGBA values.
pub fn Color::rgba(r : Int, g : Int, b : Int, a : Int) -> Color {
  { r, g, b, a }
}

///|
/// Linearly interpolate between two colors with t ∈ [0, 1].
/// Ref: zrender/src/tool/color.ts — lerp / mix
pub fn Color::lerp(a : Color, b : Color, t : Double) -> Color {
  let ch = fn(x : Int, y : Int) -> Int {
    (x.to_double() + (y - x).to_double() * t).to_int()
  }
  { r: ch(a.r, b.r), g: ch(a.g, b.g), b: ch(a.b, b.b), a: ch(a.a, b.a) }
}

///|
/// Corresponds to: zrender/src/tool/color.ts lift
pub fn Color::lift(self : Color, level : Double) -> Color {
  let lift_channel = fn(channel : Int) -> Int {
    let next = if level < 0.0 {
      (channel.to_double() * (1.0 - level)).to_int()
    } else {
      ((255 - channel).to_double() * level + channel.to_double()).to_int()
    }
    if next < 0 {
      0
    } else if next > 255 {
      255
    } else {
      next
    }
  }
  {
    r: lift_channel(self.r),
    g: lift_channel(self.g),
    b: lift_channel(self.b),
    a: self.a,
  }
}

///|
/// Corresponds to: zrender/src/tool/color.ts liftColor
pub fn Color::lift_color_string(color_str : String) -> String? {
  Color::from_string(color_str).map(color => color.lift(-0.1).to_svg())
}

///|
/// Parse a hex color string like "#rgb", "#rrggbb", or "#rrggbbaa".
/// Returns None if the string is not a valid hex color.
pub fn Color::from_hex(s : String) -> Color? {
  let off = if s.has_prefix("#") { 1 } else { 0 }
  let len = s.length() - off
  if len == 3 {
    let r = hex_digit(s[off + 0].to_int()) * 17
    let g = hex_digit(s[off + 1].to_int()) * 17
    let b = hex_digit(s[off + 2].to_int()) * 17
    if r < 0 || g < 0 || b < 0 {
      None
    } else {
      Some({ r, g, b, a: 255 })
    }
  } else if len == 6 {
    let r = hex_byte(s, off + 0)
    let g = hex_byte(s, off + 2)
    let b = hex_byte(s, off + 4)
    if r < 0 || g < 0 || b < 0 {
      None
    } else {
      Some({ r, g, b, a: 255 })
    }
  } else if len == 8 {
    let r = hex_byte(s, off + 0)
    let g = hex_byte(s, off + 2)
    let b = hex_byte(s, off + 4)
    let a = hex_byte(s, off + 6)
    if r < 0 || g < 0 || b < 0 || a < 0 {
      None
    } else {
      Some({ r, g, b, a })
    }
  } else {
    None
  }
}

///|
/// Parse a CSS named color or hex string.
pub fn Color::from_string(s : String) -> Color? {
  let compact = strip_ascii_spaces(s)
  if compact.has_prefix("rgba(") && compact.has_suffix(")") {
    parse_css_rgba_like(compact, true)
  } else if compact.has_prefix("rgb(") && compact.has_suffix(")") {
    parse_css_rgba_like(compact, false)
  } else {
    match s {
      "none" => Some(transparent)
      "transparent" => Some(transparent)
      "black" => Some(black)
      "white" => Some(white)
      "red" => Some(Color::rgb(255, 0, 0))
      "green" => Some(Color::rgb(0, 128, 0))
      "blue" => Some(Color::rgb(0, 0, 255))
      "yellow" => Some(Color::rgb(255, 255, 0))
      "orange" => Some(Color::rgb(255, 165, 0))
      "purple" => Some(Color::rgb(128, 0, 128))
      "pink" => Some(Color::rgb(255, 192, 203))
      "brown" => Some(Color::rgb(165, 42, 42))
      "gray" | "grey" => Some(Color::rgb(128, 128, 128))
      "lightgray" | "lightgrey" => Some(Color::rgb(211, 211, 211))
      "lightsteelblue" => Some(Color::rgb(176, 196, 222))
      "darkgray" | "darkgrey" => Some(Color::rgb(169, 169, 169))
      "cyan" => Some(Color::rgb(0, 255, 255))
      "magenta" => Some(Color::rgb(255, 0, 255))
      "lime" => Some(Color::rgb(0, 255, 0))
      "maroon" => Some(Color::rgb(128, 0, 0))
      "navy" => Some(Color::rgb(0, 0, 128))
      "olive" => Some(Color::rgb(128, 128, 0))
      "silver" => Some(Color::rgb(192, 192, 192))
      "teal" => Some(Color::rgb(0, 128, 128))
      _ => Color::from_hex(s)
    }
  }
}

///|
fn strip_ascii_spaces(text : String) -> String {
  let next = text.replace(old=" ", new="")
  if next == text {
    text
  } else {
    strip_ascii_spaces(next)
  }
}

///|
fn parse_css_rgba_like(text : String, has_alpha : Bool) -> Color? {
  let inner = if has_alpha {
    text[5:text.length() - 1].to_string()
  } else {
    text[4:text.length() - 1].to_string()
  }
  let first_comma = match inner.find(",") {
    Some(i) => i
    None => return None
  }
  let second_part = inner[first_comma + 1:]
  let second_comma = match second_part.find(",") {
    Some(i) => first_comma + 1 + i
    None => return None
  }
  let r = match parse_css_rgb_component(inner[0:first_comma].to_string()) {
    Some(v) => v
    None => return None
  }
  let g = match
    parse_css_rgb_component(inner[first_comma + 1:second_comma].to_string()) {
    Some(v) => v
    None => return None
  }
  if has_alpha {
    let third_part = inner[second_comma + 1:]
    let third_comma = match third_part.find(",") {
      Some(i) => second_comma + 1 + i
      None => return None
    }
    let b = match
      parse_css_rgb_component(inner[second_comma + 1:third_comma].to_string()) {
      Some(v) => v
      None => return None
    }
    let a = match
      parse_css_alpha_component(inner[third_comma + 1:].to_string()) {
      Some(v) => v
      None => return None
    }
    Some({ r, g, b, a })
  } else {
    let b = match
      parse_css_rgb_component(inner[second_comma + 1:].to_string()) {
      Some(v) => v
      None => return None
    }
    Some({ r, g, b, a: 255 })
  }
}

///|
fn parse_css_rgb_component(value : String) -> Int? {
  let parsed = try? @string.parse_double(value)
  match parsed {
    Ok(v) => Some(color_channel_from_double(v))
    Err(_) => None
  }
}

///|
fn parse_css_alpha_component(value : String) -> Int? {
  let parsed = try? @string.parse_double(value)
  match parsed {
    Ok(v) => Some(color_alpha_from_double(v))
    Err(_) => None
  }
}

///|
fn color_channel_from_double(v : Double) -> Int {
  let n = v.round().to_int()
  if n < 0 {
    0
  } else if n > 255 {
    255
  } else {
    n
  }
}

///|
fn color_alpha_from_double(v : Double) -> Int {
  let scaled = if v <= 1.0 { v * 255.0 } else { v }
  color_channel_from_double(scaled)
}

///|
/// Serialize to SVG color string. Outputs "none" for transparent,
/// "#rrggbb" for opaque, and "rgba(r,g,b,a)" for semi-transparent.
pub fn Color::to_svg(self : Color) -> String {
  if self.a == 0 {
    "none"
  } else if self.a == 255 {
    let r = int_to_hex2(self.r)
    let g = int_to_hex2(self.g)
    let b = int_to_hex2(self.b)
    "#" + r + g + b
  } else {
    let af = self.a.to_double() / 255.0
    "rgba(\{self.r},\{self.g},\{self.b},\{double_to_str(af)})"
  }
}

///|
/// Serialize to an SVG attribute color value.
///
/// Matches zrender's SVG attr normalization:
/// - transparent -> "none"
/// - opaque -> "#rrggbb"
/// - semi-transparent -> "rgb(r,g,b)" with a separate opacity attr
pub fn Color::to_svg_attr(self : Color) -> String {
  if self.a == 0 {
    "none"
  } else if self.a == 255 {
    let r = int_to_hex2(self.r)
    let g = int_to_hex2(self.g)
    let b = int_to_hex2(self.b)
    "#" + r + g + b
  } else {
    "rgb(\{self.r},\{self.g},\{self.b})"
  }
}

///|
/// SVG attribute opacity for semi-transparent colors.
///
/// Returns None for transparent/opaque colors because the attr value already
/// encodes the desired visibility.
pub fn Color::svg_opacity(self : Color) -> Double? {
  if self.a == 0 || self.a == 255 {
    None
  } else {
    Some(self.a.to_double() / 255.0)
  }
}

///|
/// Format an opacity value (0.0–1.0) for SVG, rounding to 2 decimal places
/// to match zrender's SVG output (e.g. 128/255 ≈ 0.502 → "0.5").
pub fn format_opacity(f : Double) -> String {
  let i = (f * 100.0).round().to_int()
  if i % 100 == 0 {
    (i / 100).to_string()
  } else if i % 10 == 0 {
    let whole = i / 100
    let frac = i % 100 / 10
    "\{whole}.\{frac}"
  } else {
    let whole = i / 100
    let frac = i % 100
    let frac_s = if frac < 10 { "0\{frac}" } else { frac.to_string() }
    "\{whole}.\{frac_s}"
  }
}

///|
pub impl Show for Color with output(self, logger) {
  logger.write_string(self.to_svg())
}

// ---- internal helpers ----

///|
/// Takes a character code point (Int) and returns the hex digit value (0-15), or -1 if invalid.
fn hex_digit(code : Int) -> Int {
  if code >= '0'.to_int() && code <= '9'.to_int() {
    code - '0'.to_int()
  } else if code >= 'a'.to_int() && code <= 'f'.to_int() {
    code - 'a'.to_int() + 10
  } else if code >= 'A'.to_int() && code <= 'F'.to_int() {
    code - 'A'.to_int() + 10
  } else {
    -1
  }
}

///|
fn hex_byte(s : String, offset : Int) -> Int {
  let hi = hex_digit(s[offset].to_int())
  let lo = hex_digit(s[offset + 1].to_int())
  if hi < 0 || lo < 0 {
    -1
  } else {
    hi * 16 + lo
  }
}

///|
fn int_to_hex2(n : Int) -> String {
  let n = if n < 0 { 0 } else if n > 255 { 255 } else { n }
  let hi = n / 16
  let lo = n % 16
  hex_char(hi).to_string() + hex_char(lo).to_string()
}

///|
fn hex_char(n : Int) -> Char {
  if n < 10 {
    Int::unsafe_to_char('0'.to_int() + n)
  } else {
    Int::unsafe_to_char('a'.to_int() + n - 10)
  }
}

///|
fn double_to_str(f : Double) -> String {
  // Format to 3 decimal digits max, trimming trailing zeros
  let i = (f * 1000.0).round().to_int()
  if i % 1000 == 0 {
    (i / 1000).to_string()
  } else if i % 100 == 0 {
    let whole = i / 1000
    let frac = i % 1000 / 100
    "\{whole}.\{frac}"
  } else if i % 10 == 0 {
    let whole = i / 1000
    let frac = i % 1000 / 10
    let frac_s = if frac < 10 { "0\{frac}" } else { frac.to_string() }
    "\{whole}.\{frac_s}"
  } else {
    let whole = i / 1000
    let frac = i % 1000
    let frac_s = if frac < 10 {
      "00\{frac}"
    } else if frac < 100 {
      "0\{frac}"
    } else {
      frac.to_string()
    }
    "\{whole}.\{frac_s}"
  }
}

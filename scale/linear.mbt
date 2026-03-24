///|
/// A tick mark on a scale axis.
pub struct Tick {
  value : Double
  label : String
}

///|
pub impl Show for Tick with output(self, logger) {
  logger.write_string("Tick(\{self.value}, \"\{self.label}\")")
}

///|
/// Linear scale: maps a numeric domain [min, max] to a pixel range [range_min, range_max].
pub struct LinearScale {
  mut min : Double
  mut max : Double
  mut nice_min : Double
  mut nice_max : Double
  range_min : Double
  range_max : Double
}

///|
pub fn LinearScale::new(
  min : Double,
  max : Double,
  range_min : Double,
  range_max : Double,
) -> LinearScale {
  let scale = { min, max, nice_min: min, nice_max: max, range_min, range_max }
  scale.nice()
  scale
}

///|
/// Extend the domain to include the given value.
pub fn LinearScale::extend(self : LinearScale, value : Double) -> Unit {
  if value < self.min {
    self.min = value
    self.nice()
  } else if value > self.max {
    self.max = value
    self.nice()
  }
}

///|
/// Round the domain extent to "nice" values suitable for axis display.
pub fn LinearScale::nice(self : LinearScale) -> Unit {
  if self.min == self.max {
    self.nice_min = self.min - 1.0
    self.nice_max = self.max + 1.0
  } else {
    let range = self.max - self.min
    let rough_step = range / 6.0
    let power = f64_pow10(@math.log10(rough_step).floor().to_int())
    let normalized = rough_step / power
    let nice_step = (if normalized < 1.5 {
        1.0
      } else if normalized < 3.0 {
        2.0
      } else if normalized < 7.0 {
        5.0
      } else {
        10.0
      }) *
      power
    self.nice_min = (self.min / nice_step).floor() * nice_step
    self.nice_max = (self.max / nice_step).ceil() * nice_step
  }
}

///|
/// Compute the step size for the given number of ticks.
pub fn LinearScale::step(self : LinearScale, tick_count : Int) -> Double {
  let range = self.nice_max - self.nice_min
  let rough_step = range / tick_count.to_double()
  let power = f64_pow10(@math.log10(rough_step).floor().to_int())
  let normalized = rough_step / power
  (if normalized < 1.5 {
    1.0
  } else if normalized < 3.0 {
    2.0
  } else if normalized < 7.0 {
    5.0
  } else {
    10.0
  }) *
  power
}

///|
/// Generate evenly-spaced ticks within the nice extent.
pub fn LinearScale::ticks(self : LinearScale, count : Int) -> Array[Tick] {
  let step = self.step(count)
  let result = []
  let mut value = self.nice_min
  let limit = self.nice_max + step * 0.0001
  while value <= limit {
    let label = format_tick(value, step)
    result.push({ value, label })
    value = value + step
  }
  result
}

///|
/// Map a data value to a pixel coordinate.
pub fn LinearScale::data_to_pixel(self : LinearScale, value : Double) -> Double {
  let domain = self.nice_max - self.nice_min
  if domain == 0.0 {
    self.range_min
  } else {
    let t = (value - self.nice_min) / domain
    self.range_min + t * (self.range_max - self.range_min)
  }
}

///|
/// Map a pixel coordinate back to a data value.
pub fn LinearScale::pixel_to_data(self : LinearScale, px : Double) -> Double {
  let range = self.range_max - self.range_min
  if range == 0.0 {
    self.nice_min
  } else {
    let t = (px - self.range_min) / range
    self.nice_min + t * (self.nice_max - self.nice_min)
  }
}

// ---- helpers ----

///|
fn f64_pow10(exp : Int) -> Double {
  if exp >= 0 {
    let mut result = 1.0
    for _ in 0..<exp {
      result = result * 10.0
    }
    result
  } else {
    let mut result = 1.0
    for _ in 0..<-exp {
      result = result / 10.0
    }
    result
  }
}

///|
fn int_pow10(exp : Int) -> Int {
  let mut result = 1
  if exp > 0 {
    for _ in 0..<exp {
      result = result * 10
    }
  }
  result
}

///|
/// Format a tick value based on the step size.
fn format_tick(value : Double, step : Double) -> String {
  if step >= 1.0 {
    let i = value.round().to_int()
    i.to_string()
  } else {
    // Count decimal digits needed
    let decimals = (-@math.log10(step).floor()).to_int()
    format_double(value, decimals)
  }
}

///|
fn format_double(value : Double, decimals : Int) -> String {
  if decimals <= 0 {
    value.round().to_int().to_string()
  } else {
    let factor_int = int_pow10(decimals)
    let factor = factor_int.to_double()
    let rounded = (value * factor).round().to_int()
    let whole = rounded / factor_int
    let frac = (rounded % factor_int).abs()
    let frac_str = pad_left(frac.to_string(), decimals, '0')
    "\{whole}.\{frac_str}"
  }
}

///|
fn pad_left(s : String, width : Int, pad : Char) -> String {
  if s.length() >= width {
    s
  } else {
    let buf = StringBuilder::new()
    for _ in 0..<(width - s.length()) {
      buf.write_char(pad)
    }
    buf.write_string(s)
    buf.to_string()
  }
}

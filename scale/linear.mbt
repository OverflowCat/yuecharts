// Corresponds to: echarts/src/scale/Interval.ts
// (Linear scale is a type of interval scale)

///|
/// A tick mark on a scale axis.
pub(all) struct Tick {
  value : Double
  label : String
} derive(Show)

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
/// Matches ECharts intervalScaleNiceTicks with default splitNumber=5.
pub fn LinearScale::nice(self : LinearScale) -> Unit {
  if self.min == self.max {
    self.nice_min = self.min - 1.0
    self.nice_max = self.max + 1.0
  } else {
    let range = self.max - self.min
    // Use splitNumber=5 (ECharts default) to select the nice interval.
    let rough_step = range / 5.0
    let power = f64_pow10(@math.log10(rough_step).floor().to_int())
    let normalized = rough_step / power
    // Thresholds match ECharts util/number.ts nice(val, round=true):
    // <1.5→1, <2.5→2, <4→3, <7→5, else→10
    let nice_step = (if normalized < 1.5 {
        1.0
      } else if normalized < 2.5 {
        2.0
      } else if normalized < 4.0 {
        3.0
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
/// Thresholds match ECharts util/number.ts nice(val, round=true).
pub fn LinearScale::step(self : LinearScale, tick_count : Int) -> Double {
  let range = self.nice_max - self.nice_min
  let rough_step = range / tick_count.to_double()
  let power = f64_pow10(@math.log10(rough_step).floor().to_int())
  let normalized = rough_step / power
  (if normalized < 1.5 {
    1.0
  } else if normalized < 2.5 {
    2.0
  } else if normalized < 4.0 {
    3.0
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
    value += step
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

///| ---- helpers ----

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
/// New syntax: https://www.moonbitlang.com/updates/2026/03/10/index#language-updates
fn int_pow10_new(exp : Int) -> Int {
  for _ in 0..<exp; res = 1 {
    continue res * 10
  } nobreak {
    res
  }
}

///|
test "int_pow10_new matches int_pow10" {
  let expected = [(0, 1), (1, 10), (2, 100), (3, 1000), (6, 1000000)]

  for item in expected {
    let (exp, value) = item
    assert_eq(int_pow10(exp), value)
    assert_eq(int_pow10_new(exp), value)
  }

  for exp in 0..<10 {
    assert_eq(int_pow10_new(exp), int_pow10(exp))
  }
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
    let factor_int = int_pow10_new(decimals)
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

///| ---- public number utilities (from echarts/src/util/number.ts) ----

///|
/// Get the decimal precision of a floating-point value by string inspection.
/// Handles scientific notation (e.g. 3.4e-10 → 11).
/// Corresponds to: `getPrecisionSafe` in echarts/src/util/number.ts
pub fn get_precision_safe(val : Double) -> Int {
  if val.is_nan() || val.is_inf() {
    return 0
  }
  // Stringify and lowercase.
  let s = val.to_string().to_lower()
  // Find the exponent marker 'e'.
  let e_idx : Int = match s.find("e") {
    Some(i) => i
    None => -1
  }
  let exp : Int = if e_idx >= 0 {
    let slice = s[e_idx + 1:]
    let res = try? @strconv.parse_int(slice)
    match res {
      Ok(n) => n
      Err(_) => 0
    }
  } else {
    0
  }
  let significand_len = if e_idx >= 0 { e_idx } else { s.length() }
  // Convert to String before calling find to avoid StringView coercion issues.
  let significand = s[0:significand_len].to_string()
  let dot_idx : Int = match significand.find(".") {
    Some(i) => i
    None => -1
  }
  let decimal_len = if dot_idx < 0 { 0 } else { significand_len - 1 - dot_idx }
  let result = decimal_len - exp
  if result < 0 {
    0
  } else {
    result
  }
}

///|
/// Linear mapping: maps `val` from domain [d0, d1] to range [r0, r1].
/// When `clamp` is true the output is clamped to [r0, r1] (or [r1, r0]).
/// When domain is zero-width, returns the midpoint of the range.
/// Corresponds to: `linearMap` in echarts/src/util/number.ts
pub fn linear_map(
  val : Double,
  d0 : Double,
  d1 : Double,
  r0 : Double,
  r1 : Double,
  clamp : Bool,
) -> Double {
  let sub_domain = d1 - d0
  let sub_range = r1 - r0
  if sub_domain == 0.0 {
    return if sub_range == 0.0 { r0 } else { (r0 + r1) / 2.0 }
  }
  if clamp {
    if sub_domain > 0.0 {
      if val <= d0 {
        return r0
      } else if val >= d1 {
        return r1
      }
    } else if val >= d0 {
      return r0
    } else if val <= d1 {
      return r1
    }
  } else {
    if val == d0 {
      return r0
    }
    if val == d1 {
      return r1
    }
  }
  (val - d0) / sub_domain * sub_range + r0
}

///|
/// Floating-point-safe addition: avoids accumulation of rounding errors.
/// For NaN/Inf inputs the result follows IEEE 754 (a + b).
/// Corresponds to: `addSafe` in echarts/src/util/number.ts
pub fn add_safe(a : Double, b : Double) -> Double {
  // For non-finite values, IEEE 754 semantics give the right result.
  if a.is_nan() || b.is_nan() || a.is_inf() || b.is_inf() {
    return a + b
  }
  let pa = get_precision_safe(a)
  let pb = get_precision_safe(b)
  let max_prec = if pa > pb { pa } else { pb }
  if max_prec > 20 {
    return a + b
  }
  let multiplier = f64_pow10(max_prec)
  ((a * multiplier).round() + (b * multiplier).round()) / multiplier
}

// ---- Axis Break Scale ----
// Corresponds to: echarts/src/scale/breakImpl.ts (ScaleBreakContextImpl)
//                 echarts/src/scale/Interval.ts (with break support)

///|
/// A parsed axis break: the data range [vmin, vmax] that is replaced by a visual gap.
/// Corresponds to: echarts/src/util/types.ts ParsedAxisBreak
pub(all) struct ParsedBreak {
  vmin : Double
  vmax : Double
  /// gap_pct: Some(fraction) if gap is percentage-based (e.g. "1.5%" → 0.015).
  gap_pct : Double?
  /// gap_abs: Some(value) if gap is absolute in data units.
  gap_abs : Double?
  /// Computed gap size in data units (set by update_gap_real).
  mut gap_real : Double
}

///|
/// A LinearScale that compresses break regions to small visual gaps.
/// Corresponds to: echarts/src/scale/breakImpl.ts ScaleBreakContextImpl
///                 echarts/src/scale/Interval.ts (break-aware ticks/normalize)
pub struct BreakLinearScale {
  inner : LinearScale
  breaks : Array[ParsedBreak]
  mut elapsed_min : Double
  mut elapsed_max : Double
}

///|
/// Parse a gap string ("1.5%", "50") into a ParsedBreak.
/// <=> echarts/src/scale/breakImpl.ts parseAxisBreakOption
pub fn ParsedBreak::from_option(
  vmin : Double,
  vmax : Double,
  gap_str : String,
) -> ParsedBreak {
  let brk : ParsedBreak = {
    vmin,
    vmax,
    gap_pct: None,
    gap_abs: None,
    gap_real: 0.0,
  }
  let s = gap_str.trim_space()
  if s.ends_with("%") {
    let num_str = s[0:s.length() - 1].to_string()
    let parsed = try? @strconv.parse_double(num_str)
    match parsed {
      Ok(pct) => { ..brk, gap_pct: Some(pct / 100.0) }
      Err(_) => brk
    }
  } else {
    let parsed = try? @strconv.parse_double(s)
    match parsed {
      Ok(abs) => { ..brk, gap_abs: Some(abs) }
      Err(_) => brk
    }
  }
}

///|
/// Compute the actual gap_real for each break given the scale extent.
/// <=> echarts/src/scale/breakImpl.ts updateAxisBreakGapReal (simplified: fully-in-extent case)
fn update_gap_real(
  breaks : Array[ParsedBreak],
  extent_min : Double,
  extent_max : Double,
) -> Unit {
  let full_span = extent_max - extent_min
  // Compute sums for percent-based breaks
  let mut gap_pct_sum = 0.0
  let mut pct_span_sum = 0.0
  let mut abs_gap_sum = 0.0
  let mut abs_span_sum = 0.0
  for brk in breaks {
    let vmin = brk.vmin.max(extent_min)
    let vmax = brk.vmax.min(extent_max)
    if vmin >= vmax {
      continue
    }
    let span = vmax - vmin
    match brk.gap_pct {
      Some(pct) => {
        gap_pct_sum += pct
        pct_span_sum += span
      }
      None => ()
    }
    match brk.gap_abs {
      Some(abs) => {
        abs_gap_sum += abs
        abs_span_sum += span
      }
      None => ()
    }
  }
  // prctBrksGapRealSum formula from ECharts breakImpl.ts:
  //   = gapPrctSum * (full_span + (abs_gap - abs_span) - pct_span) / (1 - gapPrctSum)
  let denom = 1.0 - gap_pct_sum
  let prct_gap_real_sum = if denom > 1.0e-10 {
    gap_pct_sum *
    (full_span + (abs_gap_sum - abs_span_sum) - pct_span_sum) /
    denom
  } else {
    0.0
  }
  for brk in breaks {
    let gap_real = match brk.gap_pct {
      Some(pct) =>
        if gap_pct_sum > 1.0e-10 {
          (if prct_gap_real_sum < 0.0 { 0.0 } else { prct_gap_real_sum }) *
          pct /
          gap_pct_sum
        } else {
          0.0
        }
      None =>
        match brk.gap_abs {
          Some(abs) => abs
          None => 0.0
        }
    }
    brk.gap_real = gap_real
  }
}

///|
/// Elapse a data value: compress break regions to their gap_real size.
/// <=> echarts/src/scale/breakImpl.ts ScaleBreakContextImpl#elapse
fn elapse(breaks : Array[ParsedBreak], val : Double) -> Double {
  let mut elapsed = 0.0
  let mut last_end = 0.0
  let mut still_over = true
  for brk in breaks {
    if val <= brk.vmax {
      if val > brk.vmin {
        elapsed += brk.vmin -
          last_end +
          (val - brk.vmin) / (brk.vmax - brk.vmin) * brk.gap_real
      } else {
        elapsed += val - last_end
      }
      last_end = brk.vmax
      still_over = false
      break
    }
    elapsed += brk.vmin - last_end + brk.gap_real
    last_end = brk.vmax
  }
  if still_over {
    elapsed += val - last_end
  }
  elapsed
}

///|
/// Unelapse: map elapsed value back to data value.
/// <=> echarts/src/scale/breakImpl.ts ScaleBreakContextImpl#unelapse
fn unelapse(breaks : Array[ParsedBreak], elapsed_val : Double) -> Double {
  let mut last_elapsed_end = 0.0
  let mut last_break_end = 0.0
  let mut still_over = true
  let mut result = 0.0
  for brk in breaks {
    let elapsed_start = last_elapsed_end + brk.vmin - last_break_end
    let elapsed_end = elapsed_start + brk.gap_real
    if elapsed_val <= elapsed_end {
      if elapsed_val > elapsed_start {
        result = brk.vmin +
          (elapsed_val - elapsed_start) /
          (elapsed_end - elapsed_start) *
          (brk.vmax - brk.vmin)
      } else {
        result = last_break_end + elapsed_val - last_elapsed_end
      }
      last_break_end = brk.vmax
      still_over = false
      break
    }
    last_elapsed_end = elapsed_end
    last_break_end = brk.vmax
  }
  if still_over {
    result = last_break_end + elapsed_val - last_elapsed_end
  }
  result
}

///|
/// Create a BreakLinearScale from a LinearScale and a list of ParsedBreaks.
/// <=> echarts/src/scale/Interval.ts (setBreaks + update calls)
pub fn BreakLinearScale::new(
  inner : LinearScale,
  breaks : Array[ParsedBreak],
) -> BreakLinearScale {
  let s : BreakLinearScale = {
    inner,
    breaks,
    elapsed_min: 0.0,
    elapsed_max: 0.0,
  }
  s.update()
  s
}

///|
fn BreakLinearScale::update(self : BreakLinearScale) -> Unit {
  // Step 1: compute gap_real from the RAW data extent (inner.min, inner.max).
  // Using nice_min/nice_max here would over-inflate gap_real and skew the step.
  // <=> echarts/src/scale/breakImpl.ts updateAxisBreakGapReal called with scaleExtent
  update_gap_real(self.breaks, self.inner.min, self.inner.max)
  // Step 2: compute elapsed span from the raw extent.
  // This is what ECharts calls `_getExtentSpanWithBreaks()`:
  //   elapsedExtent[1] - elapsedExtent[0]
  // <=> echarts/src/scale/Interval.ts calcNiceTicks: span = this._getExtentSpanWithBreaks()
  let elapsed_lo = elapse(self.breaks, self.inner.min)
  let elapsed_hi = elapse(self.breaks, self.inner.max)
  let elapsed_span = elapsed_hi - elapsed_lo
  // Step 3: compute a nice step from the elapsed span (same thresholds as LinearScale::nice),
  //         then re-extend inner.nice_min/nice_max to multiples of that step.
  // <=> echarts/src/scale/helper.ts intervalScaleNiceTicks (spanWithBreaks version)
  if elapsed_span > 0.0 {
    let rough_step = elapsed_span / 5.0
    let power = f64_pow10(@math.log10(rough_step).floor().to_int())
    let normalized = rough_step / power
    let nice_step = (if normalized < 1.5 {
        1.0
      } else if normalized < 2.5 {
        2.0
      } else if normalized < 4.0 {
        3.0
      } else if normalized < 7.0 {
        5.0
      } else {
        10.0
      }) *
      power
    // Apply the break-aware step to the RAW data min/max (not the overly-rounded nice values).
    self.inner.nice_min = (self.inner.min / nice_step).floor() * nice_step
    self.inner.nice_max = (self.inner.max / nice_step).ceil() * nice_step
    // Step 4: recompute gap_real with the corrected nice extent.
    update_gap_real(self.breaks, self.inner.nice_min, self.inner.nice_max)
  }
  self.elapsed_min = elapse(self.breaks, self.inner.nice_min)
  self.elapsed_max = elapse(self.breaks, self.inner.nice_max)
}

///|
/// Map a data value to a pixel coordinate, compressing break regions.
/// <=> echarts/src/scale/Interval.ts#normalize + Scale#parse used in dataToCoord
pub fn BreakLinearScale::data_to_pixel(
  self : BreakLinearScale,
  value : Double,
) -> Double {
  let elapsed_span = self.elapsed_max - self.elapsed_min
  if elapsed_span == 0.0 {
    return self.inner.range_min
  }
  let t = (elapse(self.breaks, value) - self.elapsed_min) / elapsed_span
  self.inner.range_min + t * (self.inner.range_max - self.inner.range_min)
}

///|
/// Generate break-aware ticks, skipping values inside break regions.
/// Break boundary ticks are added for label rendering.
/// <=> echarts/src/scale/Interval.ts getTicks (with breakTicks logic)
pub fn BreakLinearScale::ticks(
  self : BreakLinearScale,
  count : Int,
) -> Array[Tick] {
  // Compute step from ELAPSED span (as ECharts does via _getExtentSpanWithBreaks).
  // This gives a small interval that makes sense for the non-break data density.
  // <=> echarts/src/scale/helper.ts intervalScaleNiceTicks (spanWithBreaks version)
  let elapsed_span = self.elapsed_max - self.elapsed_min
  let step = if elapsed_span > 0.0 {
    let rough_step = elapsed_span / count.to_double()
    let power = f64_pow10(@math.log10(rough_step).floor().to_int())
    let normalized = rough_step / power
    (if normalized < 1.5 {
      1.0
    } else if normalized < 2.5 {
      2.0
    } else if normalized < 4.0 {
      3.0
    } else if normalized < 7.0 {
      5.0
    } else {
      10.0
    }) *
    power
  } else {
    1.0
  }
  let result : Array[Tick] = []
  let mut value = self.inner.nice_min
  let limit = self.inner.nice_max + step * 0.0001
  while value <= limit {
    // Skip ticks that fall inside a break region (within 3/4 step of boundary)
    let gap = step * 0.75
    let mut in_break = false
    for brk in self.breaks {
      if value > brk.vmin - gap && value < brk.vmax + gap {
        in_break = true
        break
      }
    }
    if !in_break {
      let label = format_tick(value, step)
      result.push({ value, label })
    }
    value += step
  }
  // Add break boundary ticks
  for brk in self.breaks {
    if brk.vmin >= self.inner.nice_min && brk.vmin <= self.inner.nice_max {
      let label = format_tick(brk.vmin, step)
      result.push({ value: brk.vmin, label })
    }
    if brk.vmax >= self.inner.nice_min && brk.vmax <= self.inner.nice_max {
      let label = format_tick(brk.vmax, step)
      result.push({ value: brk.vmax, label })
    }
  }
  // Sort by value
  result.sort_by(fn(a, b) { Double::compare(a.value, b.value) })
  result
}

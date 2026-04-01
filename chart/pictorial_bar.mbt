// Corresponds to: echarts/src/chart/bar/installPictorialBar.ts
// and echarts/src/chart/bar/PictorialBarSeries.ts
// and echarts/src/chart/bar/PictorialBarView.ts

///|
fn pictorial_symbol_color(
  series : @option.SeriesOption,
  series_index : Int,
) -> String {
  series.color.unwrap_or(@visual.palette_color(series_index))
}

///|
fn pictorial_symbol_opacity(series : @option.SeriesOption) -> Double {
  series.item_opacity.unwrap_or(1.0)
}

///|
fn pictorial_bar_repeat_times(
  series : @option.SeriesOption,
  bar_length : Double,
  unit_length : Double,
) -> Int {
  match series.symbol_repeat_count {
    Some(count) => count.max(1)
    None =>
      match series.symbol_repeat {
        Some("true") | Some("fixed") => {
          let unit = if unit_length > 0.0 { unit_length } else { 1.0 }
          let times = (bar_length / unit).to_int()
          times.max(1)
        }
        _ => 1
      }
  }
}

///|
fn pictorial_margin_px(series : @option.SeriesOption, unit : Double) -> Double {
  match series.symbol_margin {
    Some(margin) => {
      let margin_value = if margin.has_suffix("!") {
        margin[:margin.length() - 1].to_string()
      } else {
        margin
      }
      if margin_value.has_suffix("%") {
        let pct_str = margin_value[:margin_value.length() - 1]
        let parsed = try? @strconv.parse_double(pct_str.to_string())
        match parsed {
          Ok(pct) => unit * pct / 100.0
          Err(_) => unit * 0.15
        }
      } else {
        let parsed = try? @strconv.parse_double(margin_value)
        match parsed {
          Ok(px) => px
          Err(_) => unit * 0.15
        }
      }
    }
    None => unit * 0.15
  }
}

///|
fn has_end_gap(series : @option.SeriesOption) -> Bool {
  series.symbol_margin.unwrap_or("").has_suffix("!")
}

///|
fn parse_offset_component(value : String, reference : Double) -> Double {
  if value.has_suffix("%") {
    let pct_str = value[:value.length() - 1]
    let parsed = try? @strconv.parse_double(pct_str.to_string())
    parsed.unwrap_or(0.0) * reference / 100.0
  } else {
    let parsed = try? @strconv.parse_double(value)
    parsed.unwrap_or(0.0)
  }
}

///|
fn parse_symbol_size_component(value : String, reference : Double) -> Double {
  if value.has_suffix("%") {
    let pct_str = value[:value.length() - 1]
    let parsed = try? @strconv.parse_double(pct_str.to_string())
    match parsed {
      Ok(pct) => reference * pct / 100.0
      Err(_) => reference
    }
  } else {
    let parsed = try? @strconv.parse_double(value)
    parsed.unwrap_or(reference)
  }
}

///|
fn parse_percent_like(value : String, reference : Double) -> Double {
  parse_offset_component(value, reference)
}

///|
fn pictorial_symbol_size(
  series : @option.SeriesOption,
  category_size : Double,
  bounding_length : Double,
  symbol_repeat : Bool,
) -> (Double, Double) {
  let value_reference = if symbol_repeat {
    category_size
  } else {
    bounding_length.abs()
  }
  match series.symbol_size_values {
    Some(values) => {
      let width = if values.length() > 0 {
        parse_symbol_size_component(values[0], category_size)
      } else {
        category_size
      }
      let height = if values.length() > 1 {
        parse_symbol_size_component(values[1], value_reference)
      } else if values.length() > 0 {
        parse_symbol_size_component(values[0], value_reference)
      } else {
        value_reference
      }
      (width, height)
    }
    None => (category_size, value_reference)
  }
}

///|
fn pictorial_symbol_offset(
  series : @option.SeriesOption,
  symbol_w : Double,
  symbol_h : Double,
) -> (Double, Double) {
  match series.symbol_offset {
    Some(values) => {
      let dx = if values.length() > 0 {
        parse_offset_component(values[0], symbol_w)
      } else {
        0.0
      }
      let dy = if values.length() > 1 {
        parse_offset_component(values[1], symbol_h)
      } else {
        dx
      }
      (dx, dy)
    }
    None => (0.0, 0.0)
  }
}

///|
fn value_axis_zero_y(coord : @coord.Cartesian2D, y_idx : Int) -> Double {
  coord.num_y(y_idx, 0.0)
}

///|
fn pictorial_bounding_length(
  series : @option.SeriesOption,
  coord : @coord.Cartesian2D,
  y_idx : Int,
  actual_length : Double,
  zero_y : Double,
) -> Double {
  match series.symbol_bounding_data {
    Some(@option.Single(value)) => (coord.num_y(y_idx, value) - zero_y).abs()
    Some(@option.Pair(a, b)) => {
      let da = (coord.num_y(y_idx, a) - zero_y).abs()
      let db = (coord.num_y(y_idx, b) - zero_y).abs()
      da.max(db)
    }
    None =>
      match series.symbol_repeat {
        Some("true") | Some("fixed") | Some("number") =>
          (coord.bbox.y - zero_y).abs()
        _ => actual_length
      }
  }
}

///|
fn effective_repeat_slot(
  series : @option.SeriesOption,
  slot_index : Int,
  repeat_times : Int,
) -> Int {
  match series.symbol_repeat_direction {
    Some("start") => slot_index
    _ => repeat_times - 1 - slot_index
  }
}

///|
fn single_symbol_y(
  series : @option.SeriesOption,
  zero_y : Double,
  bounding_length : Double,
  symbol_h : Double,
) -> Double {
  match series.symbol_position {
    Some("center") => zero_y - bounding_length / 2.0 - symbol_h / 2.0
    Some("end") => zero_y - bounding_length
    _ => zero_y - symbol_h
  }
}

///|
fn to_int_times(times : Double) -> Int {
  let rounded = times.round().to_int()
  if (times - rounded.to_double()).abs() < 0.0001 {
    rounded
  } else {
    times.ceil().to_int()
  }
}

///|
fn render_pictorial_bar_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  bar_index : Int,
  total_bars : Int,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let zero_y = value_axis_zero_y(coord, y_idx)
  let symbol = series.symbol.unwrap_or("circle")
  if x_idx >= coord.x_scales.length() {
    return elems
  }
  guard coord.x_scales[x_idx] is Ordinal(s) else { elems }
  let band_step = s.band_step()
  let n = if total_bars > 0 { total_bars } else { 1 }
  let default_category_gap_pct = if 35 - n * 4 > 15 { 35 - n * 4 } else { 15 }
  let category_gap_str = match series.bar_category_gap {
    Some(gap) => gap
    None => "\{default_category_gap_pct}%"
  }
  let bar_gap_percent = match series.bar_gap {
    Some(gap) => parse_percent_like(gap, 1.0)
    None => -1.0
  }
  let category_gap = parse_percent_like(category_gap_str, band_step)
  let bar_w = ((band_step - category_gap) /
  (n.to_double() + (n - 1).to_double() * bar_gap_percent)).max(0.0)
  let width_sum = if n > 0 {
    n.to_double() * bar_w * (1.0 + bar_gap_percent) - bar_w * bar_gap_percent
  } else {
    0.0
  }
  let offset_base = -width_sum / 2.0
  let nd = series.data.length()
  let mut di = 0
  while di < nd {
    let item = series.data[di]
    let data_index = di
    di += 1
    let item_symbol = item.symbol.unwrap_or(symbol)
    let cat_px = if data_index < s.categories.length() {
      s.band_center(data_index)
    } else {
      coord.bbox.x
    }
    let bar_x = cat_px +
      offset_base +
      bar_index.to_double() * bar_w * (1.0 + bar_gap_percent)
    let value = match item.value {
      Num(n) => n
      Vec(arr) => if arr.length() > 1 { arr[1] } else { 0.0 }
      DateValue(_, n) => n
      Null => 0.0
    }
    let value_y = coord.num_y(y_idx, value)
    let actual_length = (zero_y - value_y).abs()
    if actual_length <= 0.0 {
      continue
    }
    let bounding_length = pictorial_bounding_length(
      series, coord, y_idx, actual_length, zero_y,
    )
    let symbol_repeat = match series.symbol_repeat {
      Some("true") | Some("fixed") | Some("number") => true
      _ => false
    }
    let (symbol_w, base_symbol_h) = pictorial_symbol_size(
      series, bar_w, bounding_length, symbol_repeat,
    )
    let mut repeat_times = if symbol_repeat {
      pictorial_bar_repeat_times(series, bounding_length.abs(), base_symbol_h)
    } else {
      1
    }
    let mut symbol_h = if base_symbol_h > 1.0 { base_symbol_h } else { 1.0 }
    let mut margin = pictorial_margin_px(series, symbol_h)
    let mut unit = symbol_h + margin * 2.0
    if symbol_repeat {
      let end_gap = has_end_gap(series)
      let end_fix = if end_gap { 0.0 } else { margin * 2.0 }
      let denom = match (end_gap, repeat_times) {
        (_, _..=1) => 1
        (true, _) => repeat_times
        (false, _) => repeat_times - 1
      }
      let m_diff = bounding_length.abs() - repeat_times.to_double() * symbol_h
      margin = m_diff / 2.0 / denom.to_double()
      unit = symbol_h + margin * 2.0
      if series.symbol_repeat != Some("fixed") &&
        series.symbol_repeat_count is None {
        let adjusted_times = to_int_times(
          (actual_length.abs() + end_fix) / unit,
        )
        if adjusted_times > 0 {
          let denom2 = if end_gap {
            adjusted_times
          } else if adjusted_times > 1 {
            adjusted_times - 1
          } else {
            1
          }
          let m_diff2 = bounding_length.abs() -
            adjusted_times.to_double() * symbol_h
          margin = m_diff2 / 2.0 / denom2.to_double()
          unit = symbol_h + margin * 2.0
          repeat_times = adjusted_times
        }
      }
    } else {
      symbol_h = bounding_length.abs()
      margin = 0.0
      unit = symbol_h
    }
    // ECharts positions pictorial symbol bundles at the zero baseline.
    // bundlePosition[valueDim] = layout[valueDim.xy], which for vertical bars
    // is the y-coordinate where the bar starts (the zero line for positive values).
    let bundle_y = zero_y

    // Calculate pathPosition based on symbolPosition and the symbol bundle extent.
    // sizeFix = pxSign * (pathLen / 2), where pathLen is total symbol extent
    // and pxSign is -1 for vertical bars (values grow upward, y decreases).
    let total_path_len = if repeat_times > 1 {
      repeat_times.to_double() * unit -
      (if has_end_gap(series) { 0.0 } else { margin * 2.0 })
    } else {
      symbol_h
    }
    let pxSign = -1.0 // vertical bars grow upward (y decreases)
    let size_fix = pxSign * (total_path_len / 2.0)

    // pathPosition[valueDim] relative to bundle_y, based on symbolPosition
    let path_pos_y = match series.symbol_position {
      Some("center") => 0.0
      Some("end") => -bounding_length + size_fix
      _ => size_fix // "start" is default
    }

    // Apply symbolOffset to pathPosition (not individual symbols!)
    let (offset_x, offset_y) = pictorial_symbol_offset(
      series, symbol_w, symbol_h,
    )
    let final_path_y = path_pos_y + offset_y

    // When symbolClip is true, collect symbols into a sub-array and wrap
    // with an SVG clipPath that clips to [bundle_y, bundle_y + actual_length].
    // Note: for vertical bars, actual_length is negative, so the clip rect
    // extends from value_y upward to zero_y.
    let symbol_buf : Array[@graphic.Element] = []
    let mut ri = 0
    while ri < repeat_times {
      // Position each symbol relative to the path center.
      // In JS: position[valueDim] = unit * (i - repeatTimes/2 + 0.5) + pathPosition[valueDim]
      // The reversal logic in JS is:
      // if (symbolRepeatDirection === 'start' ? pxSign > 0 : pxSign < 0)
      //   i = repeatTimes - 1 - index
      // For vertical bars, pxSign = -1, so:
      // - if direction='start': check pxSign > 0 => false => i = index
      // - if direction='end' (default): check pxSign < 0 => true => i = repeatTimes - 1 - index
      let i = if series.symbol_repeat_direction == Some("start") {
        ri
      } else if pxSign < 0.0 {
        repeat_times - 1 - ri
      } else {
        ri
      }
      let symbol_rel_y = unit *
        (i.to_double() - repeat_times.to_double() / 2.0 + 0.5)
      let raw_symbol_y = bundle_y + final_path_y + symbol_rel_y

      let sym = @graphic.make_symbol(
        item_symbol,
        bar_x + offset_x,
        raw_symbol_y,
        symbol_w,
        symbol_h,
        pictorial_symbol_color(series, series_index),
        series |> pictorial_symbol_opacity,
      )
      symbol_buf.push(sym)
      ri += 1
    }
    if symbol_buf.length() > 0 {
      if series.symbol_clip {
        // Clip to the actual data value extent.
        // For vertical bars: clip from value_y (top) to zero_y (bottom).
        // The clip rect y is the min of the two, and height is the absolute difference.
        let clip_top = if value_y < zero_y { value_y } else { zero_y }
        let clip_height = actual_length.abs()
        let clip_rect = @graphic.BBox::new(
          -10000.0, clip_top, 20000.0, clip_height,
        )
        elems.push(@graphic.Element::group_clipped(symbol_buf, clip_rect))
      } else {
        for sym in symbol_buf {
          elems.push(sym)
        }
      }
    }
  }

  elems
}

///|
pub fn render_pictorial_bars(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut color_idx = 0
  let max_xi = opt.x_axis.length()
  let pictorial_counts : Array[Int] = []
  let pictorial_rank_cursor : Array[Int] = []
  let mut xi_init = 0
  while xi_init <= max_xi {
    pictorial_counts.push(0)
    pictorial_rank_cursor.push(0)
    xi_init = xi_init + 1
  }
  let mut count_i = 0
  while count_i < opt.series.length() {
    let s = opt.series[count_i]
    count_i = count_i + 1
    match s.series_type {
      PictorialBar => {
        let xi = if s.x_axis_index < max_xi { s.x_axis_index } else { 0 }
        pictorial_counts[xi] = pictorial_counts[xi] + 1
      }
      _ => ()
    }
  }
  let mut sr = 0
  color_idx = 0
  while sr < opt.series.length() {
    let series = opt.series[sr]
    sr = sr + 1
    match series.series_type {
      PictorialBar => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let xi = if series.x_axis_index < max_xi { series.x_axis_index } else { 0 }
    let total = pictorial_counts[xi]
    let rank = pictorial_rank_cursor[xi]
    pictorial_rank_cursor[xi] = rank + 1
    let series_elems = render_pictorial_bar_series(
      series, color_idx, coord, rank, total,
    )
    elems.append(series_elems)
  }
  elems
}

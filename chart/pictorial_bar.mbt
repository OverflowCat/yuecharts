/// <=> echarts/src/chart/bar/installPictorialBar.ts
/// <=> echarts/src/chart/bar/PictorialBarSeries.ts
/// <=> echarts/src/chart/bar/PictorialBarView.ts

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
fn pictorial_margin_px(series : @option.SeriesOption, unit : Double) -> Double {
  match series.symbol_margin {
    Some(margin) => {
      let margin_value = if margin.has_suffix("!") {
        margin[:margin.length() - 1]
      } else {
        margin[:]
      }
      if margin_value.has_suffix("%") {
        let pct_str = margin_value[:margin_value.length() - 1]
        let parsed = try? @string.parse_double(pct_str)
        match parsed {
          Ok(pct) => unit * pct / 100.0
          Err(_) => unit * 0.15
        }
      } else {
        let parsed = try? @string.parse_double(margin_value)
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
    let parsed = try? @string.parse_double(pct_str.to_string())
    parsed.unwrap_or(0.0) * reference / 100.0
  } else {
    let parsed = try? @string.parse_double(value)
    parsed.unwrap_or(0.0)
  }
}

///|
fn parse_symbol_size_component(value : String, reference : Double) -> Double {
  if value.has_suffix("%") {
    let pct_str = value[:value.length() - 1]
    let parsed = try? @string.parse_double(pct_str.to_string())
    match parsed {
      Ok(pct) => reference * pct / 100.0
      Err(_) => reference
    }
  } else {
    let parsed = try? @string.parse_double(value)
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
fn pictorial_is_vertical(
  series : @option.SeriesOption,
  coord : @coord.Cartesian2D,
) -> Bool {
  if series.x_axis_index >= 0 && series.x_axis_index < coord.x_scales.length() {
    match coord.x_scales[series.x_axis_index] {
      Ordinal(_) => true
      Linear(_) | BreakLinear(_) => false
    }
  } else if
    series.y_axis_index >= 0 && series.y_axis_index < coord.y_scales.length() {
    match coord.y_scales[series.y_axis_index] {
      Ordinal(_) => false
      Linear(_) | BreakLinear(_) => true
    }
  } else {
    true
  }
}

///|
fn pictorial_value_and_category(
  item : @option.DataItem,
  data_index : Int,
  is_vertical : Bool,
) -> (Double, Int) {
  match item.value {
    Num(n) => (n, data_index)
    Vec(arr) => {
      if is_vertical {
        let value = if arr.length() > 1 {
          arr[1]
        } else if arr.length() > 0 {
          arr[0]
        } else {
          0.0
        }
        let category = if arr.length() > 0 {
          arr[0].to_int()
        } else {
          data_index
        }
        (value, category)
      } else {
        let value = if arr.length() > 0 {
          arr[0]
        } else {
          0.0
        }
        let category = if arr.length() > 1 {
          arr[1].to_int()
        } else {
          data_index
        }
        (value, category)
      }
    }
    DateValue(_, n) => (n, data_index)
    Null => (0.0, data_index)
  }
}

///|
fn pictorial_bounding_length(
  series : @option.SeriesOption,
  coord : @coord.Cartesian2D,
  axis_idx : Int,
  is_vertical : Bool,
  actual_length : Double,
  zero_px : Double,
  value_px : Double,
) -> Double {
  match series.symbol_bounding_data {
    Some(@option.Single(value)) => {
      let p = if is_vertical {
        coord.num_y(axis_idx, value)
      } else {
        coord.num_x(axis_idx, value)
      }
      (p - zero_px).abs()
    }
    Some(@option.Pair(a, b)) => {
      let pa = if is_vertical {
        coord.num_y(axis_idx, a)
      } else {
        coord.num_x(axis_idx, a)
      }
      let pb = if is_vertical {
        coord.num_y(axis_idx, b)
      } else {
        coord.num_x(axis_idx, b)
      }
      (pa - zero_px).abs().max((pb - zero_px).abs())
    }
    None =>
      match series.symbol_repeat {
        Some("true") | Some("fixed") | Some("number") => {
          if is_vertical {
            if value_px <= zero_px {
              (coord.bbox.y - zero_px).abs()
            } else {
              (coord.bbox.bottom() - zero_px).abs()
            }
          } else if value_px >= zero_px {
            (coord.bbox.right() - zero_px).abs()
          } else {
            (coord.bbox.x - zero_px).abs()
          }
        }
        _ => actual_length
      }
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
  let is_vertical = pictorial_is_vertical(series, coord)
  let symbol = series.symbol.unwrap_or("circle")
  let any_highlighted = @visual.has_any_highlighted(series.data)
  let emphasis_style : @graphic.DisplayStateStyle = {
    fill: Some(
      @visual.lift_hex_color(pictorial_symbol_color(series, series_index)),
    ),
    stroke: None,
    line_width: None,
    stroke_no_scale: false,
  }
  let blur_style : @graphic.DisplayStateStyle = {
    fill: None,
    stroke: None,
    line_width: None,
    stroke_no_scale: false,
  }
  let band_step = if is_vertical {
    if x_idx >= coord.x_scales.length() {
      return elems
    }
    match coord.x_scales[x_idx] {
      Ordinal(sx) => sx.band_step()
      Linear(_) | BreakLinear(_) => return elems
    }
  } else {
    if y_idx >= coord.y_scales.length() {
      return elems
    }
    match coord.y_scales[y_idx] {
      Ordinal(sy) => sy.band_step()
      Linear(_) | BreakLinear(_) => return elems
    }
  }
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
    let (value, cat_index) = pictorial_value_and_category(
      item,
      data_index,
      is_vertical,
    )
    let zero_px = if is_vertical {
      coord.num_y(y_idx, 0.0)
    } else {
      coord.num_x(x_idx, 0.0)
    }
    let value_px = if is_vertical {
      coord.num_y(y_idx, value)
    } else {
      coord.num_x(x_idx, value)
    }
    let actual_length = (value_px - zero_px).abs()
    if actual_length <= 0.0 {
      continue
    }
    let bounding_length = pictorial_bounding_length(
      series,
      coord,
      if is_vertical { y_idx } else { x_idx },
      is_vertical,
      actual_length,
      zero_px,
      value_px,
    )
    let symbol_repeat = match series.symbol_repeat {
      Some("true") | Some("fixed") | Some("number") => true
      _ => false
    }
    let (base_symbol_w, base_symbol_h0) = pictorial_symbol_size(
      series,
      bar_w,
      bounding_length,
      symbol_repeat,
    )
    let (symbol_w, base_symbol_h) = if is_vertical {
      (base_symbol_w, base_symbol_h0)
    } else {
      (base_symbol_h0, base_symbol_w)
    }
    let mut repeat_times = 1
    let mut symbol_h = if base_symbol_h > 1.0 { base_symbol_h } else { 1.0 }
    let unit_base = if is_vertical { symbol_h } else { symbol_w.max(1.0) }
    let mut margin = pictorial_margin_px(series, unit_base)
    let mut unit = unit_base + margin * 2.0
    if symbol_repeat {
      let end_gap = has_end_gap(series)
      let end_fix0 = if end_gap { 0.0 } else { margin * 2.0 }
      let init_times = match series.symbol_repeat_count {
        Some(count) => count.max(1)
        None => to_int_times((bounding_length.abs() + end_fix0) / unit.max(1.0))
      }
      repeat_times = init_times
      let m_diff = bounding_length.abs() - repeat_times.to_double() * unit_base
      let denom = if end_gap {
        repeat_times.max(1)
      } else {
        (repeat_times - 1).max(1)
      }
      margin = m_diff / 2.0 / denom.to_double()
      unit = unit_base + margin * 2.0
      let end_fix = if end_gap { 0.0 } else { margin * 2.0 }
      if series.symbol_repeat != Some("fixed") &&
        series.symbol_repeat_count is None {
        let cut_times = to_int_times(
          (actual_length.abs() + end_fix) / unit.max(1.0),
        )
        repeat_times = cut_times.max(0)
      }
    } else {
      if is_vertical {
        symbol_h = bounding_length.abs()
      }
      margin = 0.0
      unit = if is_vertical { symbol_h } else { symbol_w.max(1.0) }
    }
    let total_path_len = if repeat_times > 1 {
      repeat_times.to_double() * unit -
      (if has_end_gap(series) { 0.0 } else { margin * 2.0 })
    } else {
      if is_vertical { symbol_h } else { symbol_w.max(1.0) }
    }
    let pxSign = if is_vertical { -1.0 } else { 1.0 }
    let size_fix = pxSign * (total_path_len / 2.0)
    let (offset_x, offset_y) = pictorial_symbol_offset(
      series, symbol_w, symbol_h,
    )
    let symbol_buf : Array[@graphic.Element] = []
    if is_vertical {
      let cat_px = if cat_index < 0 {
        coord.bbox.x
      } else if x_idx < coord.x_scales.length() {
        match coord.x_scales[x_idx] {
          Ordinal(sx) => sx.band_center(cat_index)
          Linear(_) | BreakLinear(_) => coord.bbox.x
        }
      } else {
        coord.bbox.x
      }
      let bar_x = cat_px +
        offset_base +
        bar_index.to_double() * bar_w * (1.0 + bar_gap_percent)
      let zero_y = coord.num_y(y_idx, 0.0)
      let value_y = coord.num_y(y_idx, value)
      let bundle_y = zero_y
      let path_pos_y = match series.symbol_position {
        Some("center") => -bounding_length / 2.0
        Some("end") => -bounding_length - size_fix
        _ => size_fix
      }
      let final_path_y = path_pos_y + offset_y
      let mut ri = 0
      while ri < repeat_times {
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
          raw_symbol_y - symbol_h / 2.0,
          symbol_w,
          symbol_h,
          pictorial_symbol_color(series, series_index),
          series |> pictorial_symbol_opacity,
        )
        let final_sym = if any_highlighted {
          sym.with_emphasis_style(emphasis_style).with_blur_style(blur_style)
        } else {
          sym
        }
        symbol_buf.push(final_sym)
        ri += 1
      }
      if symbol_buf.length() > 0 {
        if series.symbol_clip {
          let clip_top = if value_y < zero_y { value_y } else { zero_y }
          let clip_height = actual_length.abs()
          let clip_rect = @graphic.BBox::new(
            -10000.0,
            clip_top,
            20000.0,
            clip_height,
          )
          elems.push(@graphic.Element::group_clipped(symbol_buf, clip_rect))
        } else {
          for sym in symbol_buf {
            elems.push(sym)
          }
        }
      }
    } else {
      let cat_px = if cat_index < 0 {
        coord.bbox.y
      } else if y_idx < coord.y_scales.length() {
        match coord.y_scales[y_idx] {
          Ordinal(sy) => sy.band_center(cat_index)
          Linear(_) | BreakLinear(_) => coord.bbox.y
        }
      } else {
        coord.bbox.y
      }
      let bar_y = cat_px +
        offset_base +
        bar_index.to_double() * bar_w * (1.0 + bar_gap_percent)
      let zero_x = coord.num_x(x_idx, 0.0)
      let value_x = coord.num_x(x_idx, value)
      let bundle_x = zero_x
      let path_pos_x = match series.symbol_position {
        Some("center") => bounding_length / 2.0
        Some("end") => bounding_length - size_fix
        _ => size_fix
      }
      let final_path_x = path_pos_x + offset_x
      let mut ri = 0
      while ri < repeat_times {
        let i = if series.symbol_repeat_direction == Some("start") {
          ri
        } else if pxSign < 0.0 {
          repeat_times - 1 - ri
        } else {
          ri
        }
        let symbol_rel_x = unit *
          (i.to_double() - repeat_times.to_double() / 2.0 + 0.5)
        let raw_symbol_x = bundle_x + final_path_x + symbol_rel_x
        let sym = @graphic.make_symbol(
          item_symbol,
          raw_symbol_x - symbol_w / 2.0,
          bar_y + offset_y - symbol_h / 2.0,
          symbol_w,
          symbol_h,
          pictorial_symbol_color(series, series_index),
          series |> pictorial_symbol_opacity,
        )
        let final_sym = if any_highlighted {
          sym.with_emphasis_style(emphasis_style).with_blur_style(blur_style)
        } else {
          sym
        }
        symbol_buf.push(final_sym)
        ri += 1
      }
      if symbol_buf.length() > 0 {
        if series.symbol_clip {
          let clip_left = if value_x < zero_x { value_x } else { zero_x }
          let clip_width = actual_length.abs()
          let clip_rect = @graphic.BBox::new(
            clip_left,
            -10000.0,
            clip_width,
            20000.0,
          )
          elems.push(@graphic.Element::group_clipped(symbol_buf, clip_rect))
        } else {
          for sym in symbol_buf {
            elems.push(sym)
          }
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
  let max_yi = opt.y_axis.length()
  let key_cap = max_xi + max_yi + 2
  let pictorial_counts : Array[Int] = []
  let pictorial_rank_cursor : Array[Int] = []
  let mut key_init = 0
  while key_init < key_cap {
    pictorial_counts.push(0)
    pictorial_rank_cursor.push(0)
    key_init = key_init + 1
  }
  let mut count_i = 0
  while count_i < opt.series.length() {
    let s = opt.series[count_i]
    count_i = count_i + 1
    match s.series_type {
      PictorialBar => {
        let key = if pictorial_is_vertical(s, coord) {
          if s.x_axis_index >= 0 && s.x_axis_index < max_xi {
            s.x_axis_index
          } else {
            0
          }
        } else {
          let yi = if s.y_axis_index >= 0 && s.y_axis_index < max_yi {
            s.y_axis_index
          } else {
            0
          }
          max_xi + yi
        }
        pictorial_counts[key] = pictorial_counts[key] + 1
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
    let key = if pictorial_is_vertical(series, coord) {
      if series.x_axis_index >= 0 && series.x_axis_index < max_xi {
        series.x_axis_index
      } else {
        0
      }
    } else {
      let yi = if series.y_axis_index >= 0 && series.y_axis_index < max_yi {
        series.y_axis_index
      } else {
        0
      }
      max_xi + yi
    }
    let total = pictorial_counts[key]
    let rank = pictorial_rank_cursor[key]
    pictorial_rank_cursor[key] = rank + 1
    let series_elems = render_pictorial_bar_series(
      series, color_idx, coord, rank, total,
    )
    elems.append(series_elems)
  }
  elems
}

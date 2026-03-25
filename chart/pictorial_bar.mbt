// Corresponds to: echarts/src/chart/bar/installPictorialBar.ts
// and echarts/src/chart/bar/PictorialBarSeries.ts
// and echarts/src/chart/bar/PictorialBarView.ts

///|
fn pictorial_symbol_color(
  series : @option.SeriesOption,
  series_index : Int,
) -> String {
  match series.color {
    Some(c) => c
    None => @visual.palette_color(series_index)
  }
}

///|
fn pictorial_bar_repeat_times(
  series : @option.SeriesOption,
  bar_length : Double,
  unit_length : Double,
) -> Int {
  match series.symbol_repeat_count {
    Some(count) => if count > 0 { count } else { 1 }
    None =>
      match series.symbol_repeat {
        Some("true") | Some("fixed") => {
          let unit = if unit_length > 0.0 { unit_length } else { 1.0 }
          let times = (bar_length / unit).to_int()
          if times > 0 {
            times
          } else {
            1
          }
        }
        _ => 1
      }
  }
}

///|
fn pictorial_margin_px(series : @option.SeriesOption, unit : Double) -> Double {
  match series.symbol_margin {
    Some(margin) =>
      if margin.has_suffix("%") {
        let pct_str = margin[:margin.length() - 1]
        let parsed = try? @strconv.parse_double(pct_str.to_string())
        match parsed {
          Ok(pct) => unit * pct / 100.0
          Err(_) => unit * 0.15
        }
      } else {
        let parsed = try? @strconv.parse_double(margin)
        match parsed {
          Ok(px) => px
          Err(_) => unit * 0.15
        }
      }
    None => unit * 0.15
  }
}

///|
fn parse_offset_component(value : String, reference : Double) -> Double {
  if value.has_suffix("%") {
    let pct_str = value[:value.length() - 1]
    let parsed = try? @strconv.parse_double(pct_str.to_string())
    match parsed {
      Ok(pct) => reference * pct / 100.0
      Err(_) => 0.0
    }
  } else {
    let parsed = try? @strconv.parse_double(value)
    match parsed {
      Ok(px) => px
      Err(_) => 0.0
    }
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
      if da > db {
        da
      } else {
        db
      }
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
fn clipped_symbol_rect(
  zero_y : Double,
  actual_length : Double,
  y : Double,
  h : Double,
) -> (Double, Double)? {
  let clip_top = zero_y - actual_length
  let clip_bottom = zero_y
  let top = if y > clip_top { y } else { clip_top }
  let bottom = if y + h < clip_bottom { y + h } else { clip_bottom }
  if bottom <= top {
    None
  } else {
    Some((top, bottom - top))
  }
}

///|
fn round_rect_path(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  r : Double,
) -> String {
  let rr = if r < w / 2.0 {
    if r < h / 2.0 {
      r
    } else {
      h / 2.0
    }
  } else if w / 2.0 < h / 2.0 {
    w / 2.0
  } else {
    h / 2.0
  }
  "M \{x + rr} \{y} L \{x + w - rr} \{y} Q \{x + w} \{y} \{x + w} \{y + rr} L \{x + w} \{y + h - rr} Q \{x + w} \{y + h} \{x + w - rr} \{y + h} L \{x + rr} \{y + h} Q \{x} \{y + h} \{x} \{y + h - rr} L \{x} \{y + rr} Q \{x} \{y} \{x + rr} \{y} Z"
}

///|
fn make_symbol_element(
  symbol : String,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  color : String,
) -> @graphic.Element {
  match symbol {
    "rect" => @graphic.Element::rect_colored(x, y, w, h, color)
    "roundRect" => {
      let d = round_rect_path(
        x,
        y,
        w,
        h,
        if w < h {
          w * 0.25
        } else {
          h * 0.25
        },
      )
      @graphic.Element::path_filled(d, color, 1.0)
    }
    _ => {
      let r = if w < h { w / 2.0 } else { h / 2.0 }
      @graphic.Element::circle_colored(x + w / 2.0, y + h / 2.0, r, color)
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
  let color = pictorial_symbol_color(series, series_index)
  let zero_y = value_axis_zero_y(coord, y_idx)
  let symbol = match series.symbol {
    Some(s) => s
    None => "circle"
  }
  if x_idx >= coord.x_scales.length() {
    return elems
  }
  match coord.x_scales[x_idx] {
    Ordinal(s) => {
      let band_step = s.band_step()
      let n = if total_bars > 0 { total_bars } else { 1 }
      let cat_gap_pct = if 35 - n * 4 > 15 {
        (35 - n * 4).to_double()
      } else {
        15.0
      }
      let total_span = band_step * (1.0 - cat_gap_pct / 100.0)
      let bar_w = total_span / n.to_double() / 1.3
      let nd = series.data.length()
      let mut di = 0
      while di < nd {
        let item = series.data[di]
        let data_index = di
        di = di + 1
        let cat_px = if data_index < s.categories.length() {
          s.band_center(data_index)
        } else {
          coord.bbox.x
        }
        let bar_x = cat_px -
          total_span / 2.0 +
          bar_index.to_double() * bar_w * 1.3
        let value = match item.value {
          Num(n) => n
          Vec(arr) => if arr.length() > 1 { arr[1] } else { 0.0 }
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
        let repeat_times = pictorial_bar_repeat_times(
          series, bounding_length, bar_w,
        )
        let unit_h = bounding_length / repeat_times.to_double()
        let margin = pictorial_margin_px(series, unit_h)
        let symbol_h = if repeat_times > 1 {
          let candidate = unit_h - margin
          if candidate > 1.0 {
            candidate
          } else {
            unit_h
          }
        } else {
          bounding_length
        }
        let (offset_x, offset_y) = pictorial_symbol_offset(
          series, bar_w, symbol_h,
        )
        let mut ri = 0
        while ri < repeat_times {
          let slot_index = effective_repeat_slot(series, ri, repeat_times)
          let slot_top = zero_y - (slot_index + 1).to_double() * unit_h
          let raw_symbol_y = if repeat_times > 1 {
            slot_top + margin / 2.0 + offset_y
          } else {
            single_symbol_y(series, zero_y, bounding_length, symbol_h) +
            offset_y
          }
          let visible = if series.symbol_clip {
            clipped_symbol_rect(zero_y, actual_length, raw_symbol_y, symbol_h)
          } else {
            Some((raw_symbol_y, symbol_h))
          }
          match visible {
            Some((symbol_y, visible_h)) =>
              elems.push(
                make_symbol_element(
                  symbol,
                  bar_x + offset_x,
                  symbol_y,
                  bar_w,
                  visible_h,
                  color,
                ),
              )
            None => ()
          }
          ri = ri + 1
        }
      }
    }
    Linear(_) => ()
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
    let mut ei = 0
    while ei < series_elems.length() {
      elems.push(series_elems[ei])
      ei = ei + 1
    }
    color_idx = color_idx + 1
  }
  elems
}

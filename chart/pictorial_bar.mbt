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
  match series.symbol_margin {
    Some(margin) => margin.has_suffix("!")
    None => false
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
    match parsed {
      Ok(px) => px
      Err(_) => reference
    }
  }
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
fn is_path_command(ch : Char) -> Bool {
  ch == 'M' || ch == 'm' || ch == 'L' || ch == 'l' || ch == 'H' ||
  ch == 'h' || ch == 'V' || ch == 'v' || ch == 'C' || ch == 'c' ||
  ch == 'S' || ch == 's' || ch == 'Q' || ch == 'q' || ch == 'T' ||
  ch == 't' || ch == 'A' || ch == 'a' || ch == 'Z' || ch == 'z'
}

///|
fn is_number_char(ch : Char) -> Bool {
  (ch >= '0' && ch <= '9') || ch == '-' || ch == '+' || ch == '.' ||
  ch == 'e' || ch == 'E'
}

///|
fn skip_path_separators(d : String, start : Int) -> Int {
  let mut i = start
  while i < d.length() {
    let ch = d[i].unsafe_to_char()
    if ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t' || ch == ',' {
      i = i + 1
    } else {
      break
    }
  }
  i
}

///|
fn parse_path_number(d : String, start : Int) -> (Double, Int)? {
  let i0 = skip_path_separators(d, start)
  if i0 >= d.length() || !is_number_char(d[i0].unsafe_to_char()) {
    return None
  }
  let mut i = i0
  if d[i].unsafe_to_char() == '+' || d[i].unsafe_to_char() == '-' {
    i = i + 1
  }
  while i < d.length() &&
    d[i].unsafe_to_char() >= '0' &&
    d[i].unsafe_to_char() <= '9' {
    i = i + 1
  }
  if i < d.length() && d[i].unsafe_to_char() == '.' {
    i = i + 1
    while i < d.length() &&
      d[i].unsafe_to_char() >= '0' &&
      d[i].unsafe_to_char() <= '9' {
      i = i + 1
    }
  }
  if i < d.length() &&
    (d[i].unsafe_to_char() == 'e' || d[i].unsafe_to_char() == 'E') {
    i = i + 1
    if i < d.length() &&
      (d[i].unsafe_to_char() == '+' || d[i].unsafe_to_char() == '-') {
      i = i + 1
    }
    while i < d.length() &&
      d[i].unsafe_to_char() >= '0' &&
      d[i].unsafe_to_char() <= '9' {
      i = i + 1
    }
  }
  match (try? @strconv.parse_double(d[i0:i].to_string())) {
    Ok(value) => Some((value, i))
    Err(_) => None
  }
}

///|
fn update_path_bbox(
  point : (Double, Double),
  bbox : (Double, Double, Double, Double)?,
) -> (Double, Double, Double, Double) {
  let (x, y) = point
  match bbox {
    Some((min_x, min_y, max_x, max_y)) => (
      if x < min_x { x } else { min_x },
      if y < min_y { y } else { min_y },
      if x > max_x { x } else { max_x },
      if y > max_y { y } else { max_y },
    )
    None => (x, y, x, y)
  }
}

///|
fn path_symbol_bbox(d : String) -> (Double, Double, Double, Double)? {
  let mut i = 0
  let mut cmd = ' '
  let mut bbox : (Double, Double, Double, Double)? = None
  let mut cur_x = 0.0
  let mut cur_y = 0.0
  let mut start_x = 0.0
  let mut start_y = 0.0
  while i < d.length() {
    i = skip_path_separators(d, i)
    if i >= d.length() {
      break
    }
    if is_path_command(d[i].unsafe_to_char()) {
      cmd = d[i].unsafe_to_char()
      i = i + 1
      if cmd == 'Z' || cmd == 'z' {
        cur_x = start_x
        cur_y = start_y
      }
      continue
    }
    match cmd {
      'M' | 'm' => {
        let first = parse_path_number(d, i)
        match first {
          Some((x0, i1)) =>
            match parse_path_number(d, i1) {
              Some((y0, i2)) => {
                let x = if cmd == 'm' { cur_x + x0 } else { x0 }
                let y = if cmd == 'm' { cur_y + y0 } else { y0 }
                cur_x = x
                cur_y = y
                start_x = x
                start_y = y
                bbox = Some(update_path_bbox((x, y), bbox))
                i = i2
                cmd = if cmd == 'm' { 'l' } else { 'L' }
              }
              None => break
            }
          None => break
        }
      }
      'L' | 'l' => {
        let first = parse_path_number(d, i)
        match first {
          Some((x0, i1)) =>
            match parse_path_number(d, i1) {
              Some((y0, i2)) => {
                let x = if cmd == 'l' { cur_x + x0 } else { x0 }
                let y = if cmd == 'l' { cur_y + y0 } else { y0 }
                bbox = Some(update_path_bbox((x, y), bbox))
                cur_x = x
                cur_y = y
                i = i2
              }
              None => break
            }
          None => break
        }
      }
      'H' | 'h' => {
        match parse_path_number(d, i) {
          Some((x0, i1)) => {
            let x = if cmd == 'h' { cur_x + x0 } else { x0 }
            bbox = Some(update_path_bbox((x, cur_y), bbox))
            cur_x = x
            i = i1
          }
          None => break
        }
      }
      'V' | 'v' => {
        match parse_path_number(d, i) {
          Some((y0, i1)) => {
            let y = if cmd == 'v' { cur_y + y0 } else { y0 }
            bbox = Some(update_path_bbox((cur_x, y), bbox))
            cur_y = y
            i = i1
          }
          None => break
        }
      }
      'C' | 'c' => {
        match parse_path_number(d, i) {
          Some((x1, i1)) =>
            match parse_path_number(d, i1) {
              Some((y1, i2)) =>
                match parse_path_number(d, i2) {
                  Some((x2, i3)) =>
                    match parse_path_number(d, i3) {
                      Some((y2, i4)) =>
                        match parse_path_number(d, i4) {
                          Some((x3, i5)) =>
                            match parse_path_number(d, i5) {
                              Some((y3, i6)) => {
                                let ax1 = if cmd == 'c' { cur_x + x1 } else { x1 }
                                let ay1 = if cmd == 'c' { cur_y + y1 } else { y1 }
                                let ax2 = if cmd == 'c' { cur_x + x2 } else { x2 }
                                let ay2 = if cmd == 'c' { cur_y + y2 } else { y2 }
                                let ax3 = if cmd == 'c' { cur_x + x3 } else { x3 }
                                let ay3 = if cmd == 'c' { cur_y + y3 } else { y3 }
                                bbox = Some(update_path_bbox((ax1, ay1), bbox))
                                bbox = Some(update_path_bbox((ax2, ay2), bbox))
                                bbox = Some(update_path_bbox((ax3, ay3), bbox))
                                cur_x = ax3
                                cur_y = ay3
                                i = i6
                              }
                              None => break
                            }
                          None => break
                        }
                      None => break
                    }
                  None => break
                }
              None => break
            }
          None => break
        }
      }
      'S' | 's' | 'Q' | 'q' => {
        let needed = if cmd == 'S' || cmd == 's' { 4 } else { 4 }
        let values : Array[Double] = []
        let mut next_i = i
        let mut ok = true
        let mut vi = 0
        while vi < needed {
          match parse_path_number(d, next_i) {
            Some((value, parsed_i)) => {
              values.push(value)
              next_i = parsed_i
            }
            None => {
              ok = false
              vi = needed
            }
          }
          vi = vi + 1
        }
        if !ok {
          break
        }
        let pairs = if cmd == 'S' || cmd == 's' {
          [(values[0], values[1]), (values[2], values[3])]
        } else {
          [(values[0], values[1]), (values[2], values[3])]
        }
        let mut pi = 0
        while pi < pairs.length() {
          let (px0, py0) = pairs[pi]
          let px = if cmd == 's' || cmd == 'q' { cur_x + px0 } else { px0 }
          let py = if cmd == 's' || cmd == 'q' { cur_y + py0 } else { py0 }
          bbox = Some(update_path_bbox((px, py), bbox))
          if pi == pairs.length() - 1 {
            cur_x = px
            cur_y = py
          }
          pi = pi + 1
        }
        i = next_i
      }
      'T' | 't' => {
        match parse_path_number(d, i) {
          Some((x0, i1)) =>
            match parse_path_number(d, i1) {
              Some((y0, i2)) => {
                let x = if cmd == 't' { cur_x + x0 } else { x0 }
                let y = if cmd == 't' { cur_y + y0 } else { y0 }
                bbox = Some(update_path_bbox((x, y), bbox))
                cur_x = x
                cur_y = y
                i = i2
              }
              None => break
            }
          None => break
        }
      }
      'A' | 'a' => {
        let values : Array[Double] = []
        let mut next_i = i
        let mut ok = true
        let mut vi = 0
        while vi < 7 {
          match parse_path_number(d, next_i) {
            Some((value, parsed_i)) => {
              values.push(value)
              next_i = parsed_i
            }
            None => {
              ok = false
              vi = 7
            }
          }
          vi = vi + 1
        }
        if !ok {
          break
        }
        let end_x = if cmd == 'a' { cur_x + values[5] } else { values[5] }
        let end_y = if cmd == 'a' { cur_y + values[6] } else { values[6] }
        bbox = Some(update_path_bbox((end_x, end_y), bbox))
        bbox = Some(update_path_bbox((end_x + values[0], end_y + values[1]), bbox))
        bbox = Some(update_path_bbox((end_x - values[0], end_y - values[1]), bbox))
        cur_x = end_x
        cur_y = end_y
        i = next_i
      }
      _ => {
        i = i + 1
      }
    }
  }
  bbox
}

///|
fn fallback_path_bbox(d : String) -> (Double, Double, Double, Double)? {
  let values : Array[Double] = []
  let mut i = 0
  while i < d.length() {
    match parse_path_number(d, i) {
      Some((value, next_i)) => {
        values.push(value)
        i = next_i
      }
      None => i = i + 1
    }
  }
  if values.length() < 2 {
    return None
  }
  let mut bbox : (Double, Double, Double, Double)? = None
  let mut vi = 0
  while vi + 1 < values.length() {
    bbox = Some(update_path_bbox((values[vi], values[vi + 1]), bbox))
    vi = vi + 2
  }
  bbox
}

///|
fn normalized_path_symbol(
  d : String,
  color : String,
) -> @graphic.Element {
  match path_symbol_bbox(d) {
    Some(bounds) => normalized_path_symbol_with_bounds(d, color, bounds)
    None =>
      match fallback_path_bbox(d) {
        Some(bounds) => normalized_path_symbol_with_bounds(d, color, bounds)
        None => @graphic.Element::path_filled(d, color, 1.0)
      }
  }
}

///|
fn normalized_path_symbol_with_bounds(
  d : String,
  color : String,
  bounds : (Double, Double, Double, Double),
) -> @graphic.Element {
  let (min_x, min_y, max_x, max_y) = bounds
  let width = max_x - min_x
  let height = max_y - min_y
  let sx = if width.abs() > 0.000001 { 2.0 / width } else { 1.0 }
  let sy = if height.abs() > 0.000001 { 2.0 / height } else { 1.0 }
  let transform = @graphic.Matrix::translate(
    -1.0 - min_x * sx,
    -1.0 - min_y * sy,
  ).then(@graphic.Matrix::scale(sx, sy))
  @graphic.Element::group_transformed(
    [@graphic.Element::path_filled(d, color, 1.0)],
    transform,
  )
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
    _ if symbol.has_prefix("path://") => {
      let d = symbol[7:].to_string()
      let transform = @graphic.Matrix::translate(x + w / 2.0, y + h / 2.0)
        .then(@graphic.Matrix::scale(w / 2.0, h / 2.0))
      @graphic.Element::group_transformed(
        [normalized_path_symbol(d, color)],
        transform,
      )
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
        let item_symbol = match item.symbol {
          Some(s) => s
          None => symbol
        }
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
        let symbol_repeat = match series.symbol_repeat {
          Some("true") | Some("fixed") | Some("number") => true
          _ => false
        }
        let (symbol_w, base_symbol_h) = pictorial_symbol_size(
          series, bar_w, bounding_length, symbol_repeat,
        )
        let repeat_times = if symbol_repeat {
          pictorial_bar_repeat_times(
            series,
            bounding_length.abs(),
            base_symbol_h,
          )
        } else {
          1
        }
        let mut symbol_h = if base_symbol_h > 1.0 { base_symbol_h } else { 1.0 }
        let mut margin = pictorial_margin_px(series, symbol_h)
        let mut unit = symbol_h + margin * 2.0
        if symbol_repeat {
          let end_gap = has_end_gap(series)
          let end_fix = if end_gap { 0.0 } else { margin * 2.0 }
          let denom = if end_gap {
            if repeat_times > 0 {
              repeat_times
            } else {
              1
            }
          } else if repeat_times > 1 {
            repeat_times - 1
          } else {
            1
          }
          let m_diff = bounding_length.abs() -
            repeat_times.to_double() * symbol_h
          margin = m_diff / 2.0 / denom.to_double()
          unit = symbol_h + margin * 2.0
          if series.symbol_repeat != Some("fixed") &&
            series.symbol_repeat_count is None {
            let adjusted_times = to_int_times(
              (actual_length.abs() + end_fix) / unit,
            )
            if adjusted_times > 0 {
              let denom = if end_gap {
                adjusted_times
              } else if adjusted_times > 1 {
                adjusted_times - 1
              } else {
                1
              }
              let m_diff = bounding_length.abs() -
                adjusted_times.to_double() * symbol_h
              margin = m_diff / 2.0 / denom.to_double()
              unit = symbol_h + margin * 2.0
            }
          }
        } else {
          symbol_h = bounding_length.abs()
          margin = 0.0
          unit = symbol_h
        }
        let (offset_x, offset_y) = pictorial_symbol_offset(
          series, symbol_w, symbol_h,
        )
        let mut ri = 0
        while ri < repeat_times {
          let slot_index = effective_repeat_slot(series, ri, repeat_times)
          let slot_top = zero_y - (slot_index + 1).to_double() * unit
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
                  item_symbol,
                  bar_x + offset_x,
                  symbol_y,
                  symbol_w,
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

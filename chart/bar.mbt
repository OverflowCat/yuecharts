// Corresponds to: echarts/src/chart/bar/BarView.ts
//                  echarts/src/layout/barGrid.ts
//                  echarts/src/layout/barPolar.ts

///|
fn bar_r4(v : Double) -> String {
  ((v * 10000.0).round() / 10000.0).to_string()
}

///|
fn bar_sector_path(
  cx : Double,
  cy : Double,
  r0 : Double,
  r1 : Double,
  start_angle_deg : Double,
  end_angle_deg : Double,
) -> String {
  let a0 = -start_angle_deg / 180.0 * @math.PI
  let a1 = -end_angle_deg / 180.0 * @math.PI
  let x0 = cx + r1 * @math.cos(a0)
  let y0 = cy + r1 * @math.sin(a0)
  let x1 = cx + r1 * @math.cos(a1)
  let y1 = cy + r1 * @math.sin(a1)
  let xi0 = cx + r0 * @math.cos(a0)
  let yi0 = cy + r0 * @math.sin(a0)
  let xi1 = cx + r0 * @math.cos(a1)
  let yi1 = cy + r0 * @math.sin(a1)
  let large_arc = if (a1 - a0).abs() > @math.PI { 1 } else { 0 }
  if r0 <= 0.0 {
    "M \{bar_r4(cx)} \{bar_r4(cy)} L \{bar_r4(x0)} \{bar_r4(y0)} A \{bar_r4(r1)} \{bar_r4(r1)} 0 \{large_arc} 1 \{bar_r4(x1)} \{bar_r4(y1)} Z"
  } else {
    "M \{bar_r4(x0)} \{bar_r4(y0)} A \{bar_r4(r1)} \{bar_r4(r1)} 0 \{large_arc} 1 \{bar_r4(x1)} \{bar_r4(y1)} L \{bar_r4(xi1)} \{bar_r4(yi1)} A \{bar_r4(r0)} \{bar_r4(r0)} 0 \{large_arc} 0 \{bar_r4(xi0)} \{bar_r4(yi0)} Z"
  }
}

///|
fn bar_xy_value(item : @option.DataItem, data_index : Int) -> (Double, Double) {
  match item.value {
    Num(n) => (data_index.to_double(), n)
    Vec(arr) =>
      if arr.length() > 1 {
        (arr[0], arr[1])
      } else if arr.length() > 0 {
        (data_index.to_double(), arr[0])
      } else {
        (data_index.to_double(), 0.0)
      }
    DateValue(_, n) => (data_index.to_double(), n)
    Null => (data_index.to_double(), 0.0)
  }
}

///|
priv struct PolarBarStackLayout {
  stack_id : String
  mut width : Double
  mut offset : Double
}

///|
priv struct PolarBarStackCoord {
  p : Double
  n : Double
}

///|
priv struct PolarBarStackState {
  stack_id : String
  coords : Array[PolarBarStackCoord]
}

///|
priv struct PolarBarLayout {
  band_width : Double
  stacks : Array[PolarBarStackLayout]
}

///|
fn bar_series_stack_id(
  series : @option.SeriesOption,
  series_order : Int,
) -> String {
  match series.stack {
    Some(stack) => stack
    None => "__ec_stack_\{series_order}"
  }
}

///|
fn bar_fill_color(series : @option.SeriesOption, series_index : Int) -> String {
  match series.item_style {
    Some(color) => color
    None =>
      match series.color {
        Some(color) => color
        None => @visual.palette_color(series_index)
      }
  }
}

///|
fn bar_fill_opacity(series : @option.SeriesOption) -> Double {
  series.item_opacity.unwrap_or(1.0)
}

///|
fn bar_parse_percent_like(value : String, reference : Double) -> Double {
  if value.has_suffix("%") {
    let pct_str = value[:value.length() - 1].to_string()
    let parsed = try? @strconv.parse_double(pct_str)
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
fn bar_find_stack_layout_index(
  stacks : Array[PolarBarStackLayout],
  stack_id : String,
) -> Int {
  let mut i = 0
  while i < stacks.length() {
    if stacks[i].stack_id == stack_id {
      return i
    }
    i += 1
  }
  -1
}

///|
fn bar_find_stack_state_index(
  states : Array[PolarBarStackState],
  stack_id : String,
) -> Int {
  let mut i = 0
  while i < states.length() {
    if states[i].stack_id == stack_id {
      return i
    }
    i += 1
  }
  -1
}

///|
fn bar_polar_band_width(
  series : @option.SeriesOption,
  base_axis : @coord.PolarAxis,
) -> Double {
  match base_axis.scale {
    Ordinal(scale) => scale.band_width()
    Linear(_) => {
      let extent = base_axis.get_extent()
      let count = if series.data.length() > 0 {
        series.data.length()
      } else {
        1
      }
      (extent.1 - extent.0).abs() / count.to_double()
    }
  }
}

///|
fn bar_cal_radial_layout(
  series_list : Array[@option.SeriesOption],
  polar : @coord.Polar,
) -> PolarBarLayout {
  let base_axis = polar.get_base_axis()
  let mut band_width = 0.0
  let mut remained_width = 0.0
  let mut auto_width_count = 0
  let mut category_gap = "20%"
  let mut gap = "30%"
  let stacks : Array[PolarBarStackLayout] = []
  let mut i = 0
  while i < series_list.length() {
    let series = series_list[i]
    i += 1
    if series.series_type != @option.SeriesType::Bar ||
      series.coordinate_system != Some("polar") {
      continue
    }
    if band_width == 0.0 {
      band_width = bar_polar_band_width(series, base_axis)
      remained_width = band_width
    }
    let stack_id = bar_series_stack_id(series, i - 1)
    if bar_find_stack_layout_index(stacks, stack_id) < 0 {
      stacks.push({ stack_id, width: 0.0, offset: 0.0 })
      auto_width_count += 1
    }
    if series.bar_gap != None {
      gap = series.bar_gap.unwrap_or(gap)
    }
    if series.bar_category_gap != None {
      category_gap = series.bar_category_gap.unwrap_or(category_gap)
    }
  }
  if band_width == 0.0 {
    return { band_width: 0.0, stacks: [] }
  }
  let category_gap_px = bar_parse_percent_like(category_gap, band_width)
  let bar_gap_percent = bar_parse_percent_like(gap, 1.0)
  let auto_width = if auto_width_count > 0 {
    let denom = auto_width_count.to_double() +
      (auto_width_count - 1).to_double() * bar_gap_percent
    if denom == 0.0 {
      0.0
    } else {
      ((remained_width - category_gap_px) / denom).max(0.0)
    }
  } else {
    0.0
  }
  let mut width_sum = 0.0
  let mut last_width = 0.0
  let mut j = 0
  while j < stacks.length() {
    if stacks[j].width <= 0.0 {
      stacks[j].width = auto_width
    }
    width_sum += stacks[j].width * (1.0 + bar_gap_percent)
    last_width = stacks[j].width
    j += 1
  }
  if stacks.length() > 0 {
    width_sum -= last_width * bar_gap_percent
  }
  let mut offset = -width_sum / 2.0
  let mut k = 0
  while k < stacks.length() {
    stacks[k].offset = offset
    offset += stacks[k].width * (1.0 + bar_gap_percent)
    k += 1
  }
  { band_width, stacks }
}

///|
fn render_bar_series_polar(
  series : @option.SeriesOption,
  series_index : Int,
  series_order : Int,
  polar : @coord.Polar,
  layout : PolarBarLayout,
  polar_stack_states : Array[PolarBarStackState],
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let color = bar_fill_color(series, series_index)
  let opacity = bar_fill_opacity(series)
  let base_axis = polar.get_base_axis()
  let value_axis = polar.get_other_axis(base_axis)
  let stack_id = bar_series_stack_id(series, series_order)
  let stack_layout_index = bar_find_stack_layout_index(layout.stacks, stack_id)
  let stack_layout = if stack_layout_index >= 0 {
    layout.stacks[stack_layout_index]
  } else {
    { stack_id, width: layout.band_width, offset: 0.0 }
  }
  let value_axis_start = value_axis.data_to_coord(Num(0.0), 0)
  let bar_min_height = series.bar_min_height
  let bar_min_angle = series.bar_min_angle
  let stacked = series.stack != None
  let stack_state_index = if stacked {
    let existing = bar_find_stack_state_index(polar_stack_states, stack_id)
    if existing >= 0 {
      existing
    } else {
      polar_stack_states.push({ stack_id, coords: [] })
      polar_stack_states.length() - 1
    }
  } else {
    -1
  }
  let mut di = 0
  while di < series.data.length() {
    let item = series.data[di]
    let (data0, data1) = bar_xy_value(item, di)
    let center = base_axis.data_to_coord(Num(data0), di)
    let mut base_coord = value_axis_start
    if stacked {
      while polar_stack_states[stack_state_index].coords.length() <= di {
        polar_stack_states[stack_state_index].coords.push({
          p: value_axis_start,
          n: value_axis_start,
        })
      }
      let stack_coord = polar_stack_states[stack_state_index].coords[di]
      base_coord = if data1 >= 0.0 { stack_coord.p } else { stack_coord.n }
    }
    if value_axis.dim == "radius" {
      let mut radius_span = value_axis.data_to_coord(Num(data1), di) -
        value_axis_start
      if radius_span.abs() < bar_min_height {
        radius_span = if radius_span < 0.0 {
          -bar_min_height
        } else {
          bar_min_height
        }
      }
      let r0_raw = base_coord
      let r1_raw = base_coord + radius_span
      let r0 = if r0_raw < r1_raw { r0_raw } else { r1_raw }
      let r1 = if r0_raw < r1_raw { r1_raw } else { r0_raw }
      let start_angle = center - stack_layout.offset
      let end_angle = start_angle - stack_layout.width
      if stacked {
        if stack_state_index >= 0 {
          let stack_coord = polar_stack_states[stack_state_index].coords[di]
          polar_stack_states[stack_state_index].coords[di] = {
            p: if data1 >= 0.0 {
              r1_raw
            } else {
              stack_coord.p
            },
            n: if data1 < 0.0 {
              r1_raw
            } else {
              stack_coord.n
            },
          }
        }
      }
      elems.push(
        @graphic.Element::path_filled(
          bar_sector_path(polar.cx, polar.cy, r0, r1, start_angle, end_angle),
          color,
          opacity,
        ),
      )
    } else {
      let mut angle_span = value_axis.data_to_coord(Num(data1), di) -
        value_axis_start
      if angle_span.abs() < bar_min_angle {
        angle_span = if angle_span < 0.0 {
          -bar_min_angle
        } else {
          bar_min_angle
        }
      }
      let r0 = center + stack_layout.offset
      let r1 = r0 + stack_layout.width
      let start_angle = base_coord
      let end_angle = base_coord + angle_span
      if stacked {
        if stack_state_index >= 0 {
          let stack_coord = polar_stack_states[stack_state_index].coords[di]
          polar_stack_states[stack_state_index].coords[di] = {
            p: if data1 >= 0.0 {
              end_angle
            } else {
              stack_coord.p
            },
            n: if data1 < 0.0 {
              end_angle
            } else {
              stack_coord.n
            },
          }
        }
      }
      elems.push(
        @graphic.Element::path_filled(
          bar_sector_path(polar.cx, polar.cy, r0, r1, start_angle, end_angle),
          color,
          opacity,
        ),
      )
    }
    di += 1
  }
  elems
}

///|
pub fn render_bar_series_cartesian(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  bar_index : Int,
  total_bars : Int,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let color = bar_fill_color(series, series_index)
  let opacity = bar_fill_opacity(series)
  let base_y = coord.bbox.y + coord.bbox.height
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
        di += 1
        let cat_px = if di - 1 < s.categories.length() {
          s.band_center(di - 1)
        } else {
          coord.bbox.x
        }
        let bar_x = cat_px -
          total_span / 2.0 +
          bar_index.to_double() * bar_w * 1.3
        let value = match item.value {
          Num(n) => n
          Vec(arr) => if arr.length() > 1 { arr[1] } else { 0.0 }
          DateValue(_, n) => n
          Null => 0.0
        }
        let top_y = coord.num_y(y_idx, value)
        let bar_h = base_y - top_y
        if bar_h > 0.0 {
          elems.push(
            @graphic.Element::rect_colored_opacity(
              bar_x, top_y, bar_w, bar_h, color, opacity,
            ),
          )
        }
      }
    }
    Linear(s) => {
      let nd = series.data.length()
      let bar_w = 10.0
      let mut di = 0
      while di < nd {
        let item = series.data[di]
        di += 1
        let (x_val, y_val) = match item.value {
          Num(n) => (di.to_double(), n)
          Vec(arr) =>
            if arr.length() > 1 {
              (arr[0], arr[1])
            } else if arr.length() > 0 {
              (di.to_double(), arr[0])
            } else {
              (di.to_double(), 0.0)
            }
          DateValue(_, n) => (di.to_double(), n)
          Null => (di.to_double(), 0.0)
        }
        let bar_x = s.data_to_pixel(x_val) - bar_w * 0.5
        let top_y = coord.num_y(y_idx, y_val)
        let bar_h = base_y - top_y
        if bar_h > 0.0 {
          elems.push(
            @graphic.Element::rect_colored_opacity(
              bar_x, top_y, bar_w, bar_h, color, opacity,
            ),
          )
        }
      }
    }
  }
  elems
}

///|
pub fn render_bars(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut color_idx = 0
  let max_xi = opt.x_axis.length()
  let bar_counts : Array[Int] = []
  let bar_rank_cursor : Array[Int] = []
  let mut xi_init = 0
  while xi_init <= max_xi {
    bar_counts.push(0)
    bar_rank_cursor.push(0)
    xi_init += 1
  }
  let polar_layout = match polar {
    Some(p) => Some(bar_cal_radial_layout(opt.series, p))
    None => None
  }
  let polar_stack_states : Array[PolarBarStackState] = []
  let mut count_i = 0
  while count_i < opt.series.length() {
    let s = opt.series[count_i]
    count_i += 1
    match s.series_type {
      Bar =>
        if s.coordinate_system != Some("polar") {
          let xi = if s.x_axis_index < max_xi { s.x_axis_index } else { 0 }
          bar_counts[xi] += 1
        }
      _ => ()
    }
  }
  let mut sr = 0
  color_idx = 0
  while sr < opt.series.length() {
    let series = opt.series[sr]
    sr += 1
    match series.series_type {
      Bar => ()
      _ => {
        color_idx += 1
        continue
      }
    }
    if series.coordinate_system == Some("polar") {
      match (polar, polar_layout) {
        (Some(p), Some(layout)) => {
          let series_elems = render_bar_series_polar(
            series,
            color_idx,
            sr - 1,
            p,
            layout,
            polar_stack_states,
          )
          elems.append(series_elems)
        }
        _ => ()
      }
    } else {
      let xi = if series.x_axis_index < max_xi {
        series.x_axis_index
      } else {
        0
      }
      let total = bar_counts[xi]
      let rank = bar_rank_cursor[xi]
      bar_rank_cursor[xi] = rank + 1
      let series_elems = render_bar_series_cartesian(
        series, color_idx, coord, rank, total,
      )
      elems.append(series_elems)
    }
    color_idx += 1
  }
  elems
}

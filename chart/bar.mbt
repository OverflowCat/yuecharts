// Corresponds to: echarts/src/chart/bar/BarView.ts
//                  echarts/src/layout/barGrid.ts
//                  echarts/src/layout/barPolar.ts

///|
fn bar_r4(v : Double) -> String {
  ((v * 10000.0).round() / 10000.0).to_string()
}

///|
fn bar_r1(v : Double) -> String {
  ((v * 10.0).round() / 10.0).to_string()
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
  let pi2 = @math.PI * 2.0
  let clockwise = start_angle_deg >= end_angle_deg
  let mut arc = (a1 - a0).abs()
  let mod_arc = if arc > pi2 { arc % pi2 } else { arc }
  if mod_arc > 0.0001 {
    arc = mod_arc
  }
  let full_circle = arc > pi2 - 0.0001
  let x0 = cx + r1 * @math.cos(a0)
  let y0 = cy + r1 * @math.sin(a0)
  let xi1 = cx + r0 * @math.cos(a1)
  let yi1 = cy + r0 * @math.sin(a1)
  let buf = StringBuilder::new()
  if full_circle {
    buf.write_string("M \{bar_r4(x0)} \{bar_r4(y0)}")
    bar_svg_arc(buf, cx, cy, r1, a0, a1, !clockwise)
    if r0 > 0.0 {
      buf.write_string(" M \{bar_r4(xi1)} \{bar_r4(yi1)}")
      bar_svg_arc(buf, cx, cy, r0, a1, a0, clockwise)
    } else {
      buf.write_string(" L \{bar_r4(cx)} \{bar_r4(cy)}")
    }
    buf.write_string(" Z")
    buf.to_string()
  } else if r0 <= 0.0 {
    buf.write_string("M \{bar_r4(x0)} \{bar_r4(y0)}")
    bar_svg_arc(buf, cx, cy, r1, a0, a1, !clockwise)
    buf.write_string(" L \{bar_r4(cx)} \{bar_r4(cy)} Z")
    buf.to_string()
  } else {
    buf.write_string("M \{bar_r4(x0)} \{bar_r4(y0)}")
    bar_svg_arc(buf, cx, cy, r1, a0, a1, !clockwise)
    buf.write_string(" L \{bar_r4(xi1)} \{bar_r4(yi1)}")
    bar_svg_arc(buf, cx, cy, r0, a1, a0, clockwise)
    buf.write_string(" Z")
    buf.to_string()
  }
}

///|
fn bar_svg_arc(
  buf : StringBuilder,
  cx : Double,
  cy : Double,
  r : Double,
  start_angle : Double,
  end_angle : Double,
  counterclockwise : Bool,
) -> Unit {
  let pi2 = @math.PI * 2.0
  let d_theta = end_angle - start_angle
  let clockwise = !counterclockwise
  let d_theta_positive = d_theta.abs()
  let circle_span_exceeds = if clockwise {
    d_theta >= pi2
  } else {
    -d_theta >= pi2
  }
  let is_circle = (d_theta_positive - pi2).abs() < 0.0001 || circle_span_exceeds
  let unified_theta = if d_theta > 0.0 {
    d_theta % pi2
  } else {
    d_theta % pi2 + pi2
  }
  let large = if is_circle {
    true
  } else if d_theta_positive < 0.0001 {
    false
  } else {
    (unified_theta >= @math.PI) == clockwise
  }
  let sweep = if clockwise { 1 } else { 0 }
  let large_flag = if large { 1 } else { 0 }
  let circle_sweep = sweep
  let x0 = cx + r * @math.cos(start_angle)
  let y0 = cy + r * @math.sin(start_angle)
  if is_circle {
    let gap = 0.0001
    let delta = if clockwise { pi2 - gap } else { -pi2 + gap }
    let x1 = cx + r * @math.cos(start_angle + delta)
    let y1 = cy + r * @math.sin(start_angle + delta)
    buf.write_string(
      " A \{bar_r4(r)} \{bar_r4(r)} 0 1 \{circle_sweep} \{bar_r4(x1)} \{bar_r4(y1)}",
    )
    buf.write_string(
      " A \{bar_r4(r)} \{bar_r4(r)} 0 0 \{circle_sweep} \{bar_r4(x0)} \{bar_r4(y0)}",
    )
  } else {
    let x = cx + r * @math.cos(end_angle)
    let y = cy + r * @math.sin(end_angle)
    buf.write_string(
      " A \{bar_r4(r)} \{bar_r4(r)} 0 \{large_flag} \{sweep} \{bar_r4(x)} \{bar_r4(y)}",
    )
  }
}

///|
fn bar_sausage_path(
  cx : Double,
  cy : Double,
  r0 : Double,
  r1 : Double,
  start_angle_deg : Double,
  end_angle_deg : Double,
) -> String {
  let start_angle = -start_angle_deg / 180.0 * @math.PI
  let end_angle = -end_angle_deg / 180.0 * @math.PI
  let clockwise = start_angle_deg >= end_angle_deg
  let pi2 = @math.PI * 2.0
  let less_than_circle = if clockwise {
    end_angle - start_angle < pi2
  } else {
    start_angle - end_angle < pi2
  }
  let mut norm_start_angle = start_angle
  let norm_end_angle = end_angle
  if !less_than_circle {
    let adjust = if clockwise { pi2 } else { -pi2 }
    norm_start_angle = norm_end_angle - adjust
  }
  let dr = ((r1 - r0) * 0.5).max(0.0)
  let r_center = r0 + dr
  let unit_start_x = @math.cos(norm_start_angle)
  let unit_start_y = @math.sin(norm_start_angle)
  let unit_end_x = @math.cos(norm_end_angle)
  let unit_end_y = @math.sin(norm_end_angle)
  let buf = StringBuilder::new()
  if less_than_circle {
    buf.write_string(
      "M \{bar_r4(unit_start_x * r0 + cx)} \{bar_r4(unit_start_y * r0 + cy)}",
    )
    bar_svg_arc(
      buf,
      unit_start_x * r_center + cx,
      unit_start_y * r_center + cy,
      dr,
      -@math.PI + norm_start_angle,
      norm_start_angle,
      !clockwise,
    )
  } else {
    buf.write_string(
      "M \{bar_r4(unit_start_x * r1 + cx)} \{bar_r4(unit_start_y * r1 + cy)}",
    )
  }
  bar_svg_arc(buf, cx, cy, r1, norm_start_angle, norm_end_angle, !clockwise)
  bar_svg_arc(
    buf,
    unit_end_x * r_center + cx,
    unit_end_y * r_center + cy,
    dr,
    norm_end_angle - pi2,
    norm_end_angle - @math.PI,
    !clockwise,
  )
  if r0 != 0.0 {
    bar_svg_arc(buf, cx, cy, r0, norm_end_angle, norm_start_angle, clockwise)
  }
  buf.to_string()
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
  match series.geo_item_style {
    Some(style) =>
      match style.color {
        Some(color) => color
        None =>
          match series.item_style {
            Some(color) => color
            None =>
              match series.color {
                Some(color) => color
                None => @visual.palette_color(series_index)
              }
          }
      }
    None =>
      match series.item_style {
        Some(color) => color
        None =>
          match series.color {
            Some(color) => color
            None => @visual.palette_color(series_index)
          }
      }
  }
}

///|
fn bar_fill_opacity(series : @option.SeriesOption) -> Double {
  match series.item_opacity {
    Some(opacity) => opacity
    None =>
      match series.geo_item_style {
        Some(style) => style.opacity.unwrap_or(1.0)
        None => 1.0
      }
  }
}

///|
priv struct BarResolvedStyle {
  fill_color : String
  opacity : Double
  border_color : String?
  border_width : Double
}

///|
fn bar_resolve_data_style(
  series : @option.SeriesOption,
  item : @option.DataItem,
  series_index : Int,
) -> BarResolvedStyle {
  let series_fill = bar_fill_color(series, series_index)
  let series_opacity = bar_fill_opacity(series)
  let series_border_color = series.geo_item_style.bind(style => {
    style.border_color
  })
  let series_border_width = series.geo_item_style
    .bind(style => style.border_width)
    .unwrap_or(0.0)
  let item_style = item.item_style
  let fill_color = match item_style {
    Some(style) =>
      match style.color {
        Some(color) => color
        None => series_fill
      }
    None => series_fill
  }
  let opacity = match item_style {
    Some(style) =>
      match style.opacity {
        Some(opacity) => opacity
        None => series_opacity
      }
    None => series_opacity
  }
  let border_color = match item_style {
    Some(style) =>
      match style.border_color {
        Some(color) => Some(color)
        None => series_border_color
      }
    None => series_border_color
  }
  let border_width = match item_style {
    Some(style) =>
      match style.border_width {
        Some(width) => width
        None => series_border_width
      }
    None => series_border_width
  }
  { fill_color, opacity, border_color, border_width }
}

///|
fn bar_resolve_background_style(
  series : @option.SeriesOption,
) -> BarResolvedStyle {
  let default_fill = "rgba(180, 180, 180, 0.2)"
  let background_style = match series.background_style {
    Some(style) => style
    None => @option.GeoItemStylePatchOption::default()
  }
  let fill_color = match background_style.color {
    Some(color) => color
    None =>
      match background_style.area_color {
        Some(color) => color
        None => default_fill
      }
  }
  {
    fill_color,
    opacity: background_style.opacity.unwrap_or(1.0),
    border_color: background_style.border_color,
    border_width: background_style.border_width.unwrap_or(0.0),
  }
}

///|
fn bar_rect_path(x : Double, y : Double, w : Double, h : Double) -> String {
  "M\{bar_r1(x)} \{bar_r1(y)}l\{bar_r1(w)} 0l0 \{bar_r1(h)}l\{bar_r1(-w)} 0Z"
}

///|
fn bar_render_path(d : String, style : BarResolvedStyle) -> @graphic.Element {
  match style.border_color {
    Some(border_color) if style.border_width > 0.0 =>
      @graphic.Element::path_fill_stroke(
        d,
        style.fill_color,
        border_color,
        style.border_width,
        style.opacity,
      )
    _ => @graphic.Element::path_filled(d, style.fill_color, style.opacity)
  }
}

///|
/// <=> echarts/src/core/Scheduler.ts
fn bar_series_is_large(series : @option.SeriesOption) -> Bool {
  series.large && series.data.length() >= series.large_threshold
}

///|
/// <=> echarts/src/chart/bar/BaseBarSeries.ts:defaultOption.progressive
fn bar_large_render_limit() -> Int {
  3000
}

///|
fn bar_append_rect_path(
  buf : StringBuilder,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Unit {
  buf.write_string(
    "M\{bar_r1(x)} \{bar_r1(y)}l\{bar_r1(w)} 0l0 \{bar_r1(h)}l\{bar_r1(-w)} 0Z",
  )
}

///|
/// <=> echarts/src/layout/barGrid.ts:createProgressiveLayout
/// <=> echarts/src/chart/bar/BarView.ts:_renderLarge
fn bar_render_series_cartesian_large_impl(
  series : @option.SeriesOption,
  series_index : Int,
  series_order : Int,
  coord : @coord.Cartesian2D,
  bar_index : Int,
  total_bars : Int,
  draw_background : Bool,
  draw_bars : Bool,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let base_y = coord.bbox.y + coord.bbox.height
  if x_idx >= coord.x_scales.length() {
    return elems
  }
  match coord.x_scales[x_idx] {
    Ordinal(s) => {
      let band_width = s.band_width()
      let n = if total_bars > 0 { total_bars } else { 1 }
      let cat_gap_pct = if 35 - n * 4 > 15 {
        (35 - n * 4).to_double()
      } else {
        15.0
      }
      let category_gap = band_width * cat_gap_pct / 100.0
      let gap_percent = if series.bar_gap != None {
        bar_parse_percent_like(series.bar_gap.unwrap_or("10%"), 1.0)
      } else {
        0.1
      }
      let auto_width = if n > 0 {
        ((band_width - category_gap) /
        (n.to_double() + (n - 1).to_double() * gap_percent)).max(0.0)
      } else {
        0.0
      }
      let bar_w = if auto_width < 0.5 { 0.5 } else { auto_width }
      let total_span = if n > 0 {
        bar_w * n.to_double() + bar_w * gap_percent * (n - 1).to_double()
      } else {
        bar_w
      }
      let nd = series.data.length()
      let render_nd = if nd > bar_large_render_limit() {
        bar_large_render_limit()
      } else {
        nd
      }
      let bar_fill = bar_fill_color(series, series_index)
      let bar_opacity = bar_fill_opacity(series)
      let bg_style = bar_resolve_background_style(series)
      let chunk_limit = 1000
      let mut fg_buf = StringBuilder::new()
      let mut bg_buf = StringBuilder::new()
      let mut fg_count = 0
      let mut bg_count = 0
      let children : Array[@graphic.Element] = []
      let mut di = 0
      while di < render_nd {
        let item = series.data[di]
        di += 1
        let cat_px = if di - 1 < s.categories.length() {
          s.band_center(di - 1)
        } else {
          coord.bbox.x
        }
        let bar_x = cat_px -
          total_span / 2.0 +
          bar_index.to_double() * bar_w * (1.0 + gap_percent)
        if draw_background && series.show_background {
          bar_append_rect_path(
            bg_buf,
            bar_x,
            coord.bbox.y,
            bar_w,
            coord.bbox.height,
          )
          bg_count += 1
          if bg_count >= chunk_limit {
            children.push(
              @graphic.Element::path_filled(
                bg_buf.to_string(),
                bg_style.fill_color,
                bg_style.opacity,
              ).with_silent(true),
            )
            bg_buf = StringBuilder::new()
            bg_count = 0
          }
        }
        if !draw_bars {
          continue
        }
        let value = match item.value {
          Num(n) => n
          Vec(arr) => if arr.length() > 1 { arr[1] } else { 0.0 }
          DateValue(_, n) => n
          Null => 0.0
        }
        let top_y = coord.num_y(y_idx, value)
        let bar_h = top_y - base_y
        bar_append_rect_path(fg_buf, bar_x, base_y, bar_w, bar_h)
        fg_count += 1
        if fg_count >= chunk_limit {
          children.push(
            bar_render_path(fg_buf.to_string(), {
              fill_color: bar_fill,
              opacity: bar_opacity,
              border_color: None,
              border_width: 0.0,
            }).with_ecmeta_attr("series_index", series_order.to_string()),
          )
          fg_buf = StringBuilder::new()
          fg_count = 0
        }
      }
      if draw_background && series.show_background {
        if bg_count > 0 {
          children.push(
            @graphic.Element::path_filled(
              bg_buf.to_string(),
              bg_style.fill_color,
              bg_style.opacity,
            ).with_silent(true),
          )
        }
      }
      if draw_bars && fg_count > 0 {
        children.push(
          bar_render_path(fg_buf.to_string(), {
            fill_color: bar_fill,
            opacity: bar_opacity,
            border_color: None,
            border_width: 0.0,
          }).with_ecmeta_attr("series_index", series_order.to_string()),
        )
      }
      if children.length() > 0 {
        elems.push(@graphic.Element::group_clipped(children, coord.bbox))
      }
    }
    Linear(s) => {
      let nd = series.data.length()
      let render_nd = if nd > bar_large_render_limit() {
        bar_large_render_limit()
      } else {
        nd
      }
      let bar_w = 10.0
      let bar_fill = bar_fill_color(series, series_index)
      let bar_opacity = bar_fill_opacity(series)
      let fg_buf = StringBuilder::new()
      let mut di = 0
      while di < render_nd {
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
        if !draw_bars {
          continue
        }
        let top_y = coord.num_y(y_idx, y_val)
        let bar_h = top_y - base_y
        bar_append_rect_path(fg_buf, bar_x, base_y, bar_w, bar_h)
      }
      if draw_bars {
        let children : Array[@graphic.Element] = [
          bar_render_path(fg_buf.to_string(), {
            fill_color: bar_fill,
            opacity: bar_opacity,
            border_color: None,
            border_width: 0.0,
          }).with_ecmeta_attr("series_index", series_order.to_string()),
        ]
        elems.push(@graphic.Element::group_clipped(children, coord.bbox))
      }
    }
  }
  elems
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
fn bar_render_series_polar_impl(
  series : @option.SeriesOption,
  series_index : Int,
  series_order : Int,
  polar : @coord.Polar,
  layout : PolarBarLayout,
  polar_stack_states : Array[PolarBarStackState],
  draw_background : Bool,
  draw_bars : Bool,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
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
  let stack_state_index = if draw_bars && stacked {
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
    if draw_bars && stacked {
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
      let start_angle = center - stack_layout.offset
      let end_angle = start_angle - stack_layout.width
      if draw_background && series.show_background {
        let coord_area = polar.get_area()
        let bg_d = bar_sector_path(
          polar.cx,
          polar.cy,
          coord_area.r0,
          coord_area.r,
          start_angle,
          end_angle,
        )
        elems.push(
          bar_render_path(bg_d, bar_resolve_background_style(series)).with_silent(
            true,
          ),
        )
      }
      if draw_bars {
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
        if stacked && stack_state_index >= 0 {
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
        let d = bar_sector_path(
          polar.cx,
          polar.cy,
          r0,
          r1,
          start_angle,
          end_angle,
        )
        elems.push(
          bar_render_path(d, bar_resolve_data_style(series, item, series_index)),
        )
      }
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
      if draw_background && series.show_background {
        let bg_d = bar_sector_path(polar.cx, polar.cy, r0, r1, 0.0, 360.0)
        elems.push(
          bar_render_path(bg_d, bar_resolve_background_style(series)).with_silent(
            true,
          ),
        )
      }
      if draw_bars {
        if stacked && stack_state_index >= 0 {
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
        let d = if series.round_cap {
          bar_sausage_path(polar.cx, polar.cy, r0, r1, start_angle, end_angle)
        } else {
          bar_sector_path(polar.cx, polar.cy, r0, r1, start_angle, end_angle)
        }
        elems.push(
          bar_render_path(d, bar_resolve_data_style(series, item, series_index)),
        )
      }
    }
    di += 1
  }
  elems
}

///|
fn bar_render_series_cartesian_impl(
  series : @option.SeriesOption,
  series_index : Int,
  series_order : Int,
  coord : @coord.Cartesian2D,
  bar_index : Int,
  total_bars : Int,
  draw_background : Bool,
  draw_bars : Bool,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
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
      let bar_w = total_span / n.to_double()
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
        if draw_background && series.show_background {
          elems.push(
            bar_render_path(
              bar_rect_path(bar_x, coord.bbox.y, bar_w, coord.bbox.height),
              bar_resolve_background_style(series),
            ).with_silent(true),
          )
        }
        if !draw_bars {
          continue
        }
        let style = bar_resolve_data_style(series, item, series_index)
        let value = match item.value {
          Num(n) => n
          Vec(arr) => if arr.length() > 1 { arr[1] } else { 0.0 }
          DateValue(_, n) => n
          Null => 0.0
        }
        let top_y = coord.num_y(y_idx, value)
        let bar_h = top_y - base_y
        elems.push(
          bar_render_path(bar_rect_path(bar_x, base_y, bar_w, bar_h), style)
          .with_ecmeta_attr("series_index", series_order.to_string())
          .with_ecmeta_attr("data_index", (di - 1).to_string())
          .with_ecmeta_attr("ssr_type", "chart"),
        )
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
        if draw_background && series.show_background {
          elems.push(
            bar_render_path(
              bar_rect_path(bar_x, coord.bbox.y, bar_w, coord.bbox.height),
              bar_resolve_background_style(series),
            ).with_silent(true),
          )
        }
        if !draw_bars {
          continue
        }
        let style = bar_resolve_data_style(series, item, series_index)
        let top_y = coord.num_y(y_idx, y_val)
        let bar_h = top_y - base_y
        elems.push(
          bar_render_path(bar_rect_path(bar_x, base_y, bar_w, bar_h), style)
          .with_ecmeta_attr("series_index", series_order.to_string())
          .with_ecmeta_attr("data_index", (di - 1).to_string())
          .with_ecmeta_attr("ssr_type", "chart"),
        )
      }
    }
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
  if bar_series_is_large(series) {
    bar_render_series_cartesian_large_impl(
      series, series_index, series_index, coord, bar_index, total_bars, true, true,
    )
  } else {
    bar_render_series_cartesian_impl(
      series, series_index, series_index, coord, bar_index, total_bars, true, true,
    )
  }
}

///|
pub fn render_bars(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
) -> Array[@graphic.Element] {
  let background_elems : Array[@graphic.Element] = []
  let foreground_elems : Array[@graphic.Element] = []
  let mut color_idx = 0
  let max_xi = opt.x_axis.length()
  let bar_counts : Array[Int] = []
  let bar_rank_cursor_bg : Array[Int] = []
  let bar_rank_cursor_fg : Array[Int] = []
  let mut xi_init = 0
  while xi_init <= max_xi {
    bar_counts.push(0)
    bar_rank_cursor_bg.push(0)
    bar_rank_cursor_fg.push(0)
    xi_init += 1
  }
  let polar_layout = match polar {
    Some(p) => Some(bar_cal_radial_layout(opt.series, p))
    None => None
  }
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
  let mut sr_bg = 0
  color_idx = 0
  while sr_bg < opt.series.length() {
    let series = opt.series[sr_bg]
    sr_bg += 1
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
          let series_elems = bar_render_series_polar_impl(
            series,
            color_idx,
            sr_bg - 1,
            p,
            layout,
            [],
            true,
            false,
          )
          background_elems.append(series_elems)
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
      let rank = bar_rank_cursor_bg[xi]
      bar_rank_cursor_bg[xi] = rank + 1
      let series_elems = if bar_series_is_large(series) {
        bar_render_series_cartesian_large_impl(
          series,
          color_idx,
          sr_bg - 1,
          coord,
          rank,
          total,
          true,
          false,
        )
      } else {
        bar_render_series_cartesian_impl(
          series,
          color_idx,
          sr_bg - 1,
          coord,
          rank,
          total,
          true,
          false,
        )
      }
      background_elems.append(series_elems)
    }
    color_idx += 1
  }
  let polar_stack_states : Array[PolarBarStackState] = []
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
          let series_elems = bar_render_series_polar_impl(
            series,
            color_idx,
            sr - 1,
            p,
            layout,
            polar_stack_states,
            false,
            true,
          )
          foreground_elems.append(series_elems)
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
      let rank = bar_rank_cursor_fg[xi]
      bar_rank_cursor_fg[xi] = rank + 1
      let series_elems = if bar_series_is_large(series) {
        bar_render_series_cartesian_large_impl(
          series,
          color_idx,
          sr - 1,
          coord,
          rank,
          total,
          false,
          true,
        )
      } else {
        bar_render_series_cartesian_impl(
          series,
          color_idx,
          sr - 1,
          coord,
          rank,
          total,
          false,
          true,
        )
      }
      foreground_elems.append(series_elems)
    }
    color_idx += 1
  }
  background_elems.append(foreground_elems)
  background_elems
}

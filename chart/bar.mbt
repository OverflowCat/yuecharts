/// <=> echarts/src/chart/bar/BarView.ts
/// <=> echarts/src/layout/barGrid.ts
/// <=> echarts/src/layout/barPolar.ts

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
fn bar_item_value(item : @option.DataItem) -> Double {
  match item.value {
    Num(n) => n
    Vec(arr) =>
      if arr.length() > 1 {
        arr[1]
      } else if arr.length() > 0 {
        arr[0]
      } else {
        0.0
      }
    DateValue(_, n) => n
    Null => 0.0
  }
}

///|
/// <=> echarts/src/layout/barGrid.ts:getSeriesStackId
fn bar_series_cartesian_key_for_axis(
  series : @option.SeriesOption,
  series_order : Int,
  category_axis_index : Int,
) -> String {
  match series.stack {
    Some(stack) => "\{category_axis_index}::stack::\{stack}"
    None => "\{category_axis_index}::series::\{series_order}"
  }
}

///|
/// <=> echarts/src/layout/barGrid.ts:makeColumnLayout
fn bar_series_cartesian_is_horizontal(
  series : @option.SeriesOption,
  coord : @coord.Cartesian2D,
) -> Bool {
  if series.x_axis_index < coord.x_scales.length() &&
    series.y_axis_index < coord.y_scales.length() {
    match coord.x_scales[series.x_axis_index] {
      Ordinal(_) => false
      Linear(_) =>
        match coord.y_scales[series.y_axis_index] {
          Ordinal(_) => true
          Linear(_) => false
          BreakLinear(_) => false
        }
    }
  } else {
    false
  }
}

///|
/// <=> echarts/src/layout/barGrid.ts:makeColumnLayout
fn bar_series_cartesian_category_axis_index(
  series : @option.SeriesOption,
  coord : @coord.Cartesian2D,
) -> Int {
  if bar_series_cartesian_is_horizontal(series, coord) {
    series.y_axis_index
  } else {
    series.x_axis_index
  }
}

///|
fn bar_find_string_index(arr : Array[String], key : String) -> Int {
  arr.search_by(s => s == key).unwrap_or(-1)
}

///|
fn bar_find_cartesian_stack_state_index(
  states : Array[BarCartesianStackState],
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
/// <=> echarts/src/layout/barGrid.ts:getSeriesStackId
fn bar_category_series_stack_id(
  series : @option.SeriesOption,
  series_order : Int,
) -> String {
  bar_series_stack_id(series, series_order)
}

///|
/// <=> echarts/src/layout/barGrid.ts:doCalBarWidthAndOffset
fn bar_find_category_stack_layout_index(
  stacks : Array[BarCategoryStackLayout],
  stack_id : String,
) -> Int {
  stacks.search_by(s => s.stack_id == stack_id).unwrap_or(-1)
}

///|
/// <=> echarts/src/layout/barGrid.ts:doCalBarWidthAndOffset
fn bar_category_axis_layout_default(
  band_width : Double,
) -> BarCategoryAxisLayout {
  {
    band_width,
    remained_width: band_width,
    auto_width_count: 0,
    category_gap: None,
    gap: "10%",
    stacks: [],
  }
}

///|
/// <=> echarts/src/layout/barGrid.ts:retrieveColumnLayout
fn bar_category_layout_get_stack(
  layouts : Array[BarCategoryAxisLayout],
  axis_index : Int,
  series : @option.SeriesOption,
  series_order : Int,
) -> BarCategoryStackLayout? {
  if axis_index < 0 || axis_index >= layouts.length() {
    return None
  }
  let stack_id = bar_category_series_stack_id(series, series_order)
  let stack_index = bar_find_category_stack_layout_index(
    layouts[axis_index].stacks,
    stack_id,
  )
  if stack_index < 0 {
    None
  } else {
    Some(layouts[axis_index].stacks[stack_index])
  }
}

///|
/// <=> echarts/src/layout/barGrid.ts:doCalBarWidthAndOffset
fn bar_finalize_category_axis_layout(
  axis_layout : BarCategoryAxisLayout,
) -> BarCategoryAxisLayout {
  let result = axis_layout
  if result.band_width <= 0.0 || result.stacks.length() == 0 {
    return result
  }
  let column_count = result.stacks.length()
  let default_category_gap = if 35 - column_count * 4 > 15 {
    35 - column_count * 4
  } else {
    15
  }
  let category_gap_percent = result.category_gap.unwrap_or(
    "\{default_category_gap}%",
  )
  let category_gap = bar_parse_percent_like(
    category_gap_percent,
    result.band_width,
  )
  let bar_gap_percent = bar_parse_percent_like(result.gap, 1.0)
  let mut remained_width = result.remained_width
  let mut auto_width_count = result.auto_width_count
  let mut auto_width = if auto_width_count > 0 {
    let denom = auto_width_count.to_double() +
      (auto_width_count - 1).to_double() * bar_gap_percent
    if denom == 0.0 {
      0.0
    } else {
      ((remained_width - category_gap) / denom).max(0.0)
    }
  } else {
    0.0
  }
  for i, stack in result.stacks {
    if stack.width == 0.0 {
      let mut final_width = auto_width
      if stack.max_width > 0.0 && stack.max_width < final_width {
        final_width = if stack.max_width < remained_width {
          stack.max_width
        } else {
          remained_width
        }
      }
      if stack.min_width != None {
        let min_width = stack.min_width.unwrap_or(0.0)
        if min_width > final_width {
          final_width = min_width
        }
      }
      if final_width != auto_width {
        result.stacks[i].width = final_width
        remained_width -= final_width + bar_gap_percent * final_width
        auto_width_count -= 1
      }
    } else {
      let mut final_width = stack.width
      if stack.max_width > 0.0 {
        final_width = if final_width < stack.max_width {
          final_width
        } else {
          stack.max_width
        }
      }
      if stack.min_width != None {
        let min_width = stack.min_width.unwrap_or(0.0)
        if min_width > final_width {
          final_width = min_width
        }
      }
      result.stacks[i].width = final_width
      remained_width -= final_width + bar_gap_percent * final_width
      auto_width_count -= 1
    }
  }
  auto_width = if auto_width_count > 0 {
    let denom = auto_width_count.to_double() +
      (auto_width_count - 1).to_double() * bar_gap_percent
    if denom == 0.0 {
      0.0
    } else {
      ((remained_width - category_gap) / denom).max(0.0)
    }
  } else {
    0.0
  }
  let mut width_sum = 0.0
  let mut last_width = 0.0
  let mut j = 0
  while j < result.stacks.length() {
    if result.stacks[j].width == 0.0 {
      result.stacks[j].width = auto_width
    }
    last_width = result.stacks[j].width
    width_sum += result.stacks[j].width * (1.0 + bar_gap_percent)
    j += 1
  }
  if result.stacks.length() > 0 {
    width_sum -= last_width * bar_gap_percent
  }
  let mut offset = -width_sum / 2.0
  let mut k = 0
  while k < result.stacks.length() {
    result.stacks[k].offset = offset
    offset += result.stacks[k].width * (1.0 + bar_gap_percent)
    k += 1
  }
  result
}

///|
/// <=> echarts/src/layout/barGrid.ts:makeColumnLayout
fn bar_make_category_layout(
  series_list : Array[@option.SeriesOption],
  coord : @coord.Cartesian2D,
) -> Array[BarCategoryAxisLayout] {
  let layouts : Array[BarCategoryAxisLayout] = []
  let mut xi = 0
  while xi < coord.x_scales.length() {
    match coord.x_scales[xi] {
      Ordinal(s) =>
        layouts.push(bar_category_axis_layout_default(s.band_width()))
      Linear(_) => layouts.push(bar_category_axis_layout_default(0.0))
    }
    xi += 1
  }
  let mut si = 0
  while si < series_list.length() {
    let series = series_list[si]
    si += 1
    if series.series_type != Bar || series.coordinate_system == Some("polar") {
      continue
    }
    let x_idx = if series.x_axis_index < layouts.length() {
      series.x_axis_index
    } else {
      0
    }
    if x_idx < 0 || x_idx >= coord.x_scales.length() {
      continue
    }
    match coord.x_scales[x_idx] {
      Ordinal(_) => {
        let axis_layout = layouts[x_idx]
        let stack_id = bar_category_series_stack_id(series, si - 1)
        let stack_index = bar_find_category_stack_layout_index(
          axis_layout.stacks,
          stack_id,
        )
        if stack_index < 0 {
          axis_layout.auto_width_count += 1
          axis_layout.stacks.push({
            stack_id,
            width: 0.0,
            max_width: 0.0,
            min_width: None,
            offset: 0.0,
          })
        }
        let stack_index = bar_find_category_stack_layout_index(
          axis_layout.stacks,
          stack_id,
        )
        if stack_index >= 0 {
          if series.bar_width != None &&
            axis_layout.stacks[stack_index].width == 0.0 {
            let bar_width = bar_parse_percent_like(
              series.bar_width.unwrap_or("0"),
              axis_layout.band_width,
            )
            if bar_width > 0.0 {
              let used_width = if bar_width < axis_layout.remained_width {
                bar_width
              } else {
                axis_layout.remained_width
              }
              axis_layout.stacks[stack_index].width = used_width
              axis_layout.remained_width -= used_width
            }
          }
          if series.bar_max_width != None {
            axis_layout.stacks[stack_index].max_width = bar_parse_percent_like(
              series.bar_max_width.unwrap_or("0"),
              axis_layout.band_width,
            )
          }
          if series.bar_min_width != None {
            axis_layout.stacks[stack_index].min_width = Some(
              bar_parse_percent_like(
                series.bar_min_width.unwrap_or("0"),
                axis_layout.band_width,
              ),
            )
          }
        }
        if series.bar_gap != None {
          axis_layout.gap = series.bar_gap.unwrap_or(axis_layout.gap)
        }
        if series.bar_category_gap != None {
          axis_layout.category_gap = series.bar_category_gap
        }
        layouts[x_idx] = axis_layout
      }
      Linear(_) => ()
    }
  }
  let mut xi2 = 0
  while xi2 < layouts.length() {
    layouts[xi2] = bar_finalize_category_axis_layout(layouts[xi2])
    xi2 += 1
  }
  layouts
}

///|
/// <=> echarts/src/layout/barGrid.ts:makeColumnLayout
fn bar_make_category_layout_y(
  series_list : Array[@option.SeriesOption],
  coord : @coord.Cartesian2D,
) -> Array[BarCategoryAxisLayout] {
  let layouts : Array[BarCategoryAxisLayout] = []
  let mut yi = 0
  while yi < coord.y_scales.length() {
    match coord.y_scales[yi] {
      Ordinal(s) =>
        layouts.push(bar_category_axis_layout_default(s.band_width()))
      Linear(_) => layouts.push(bar_category_axis_layout_default(0.0))
      BreakLinear(_) => layouts.push(bar_category_axis_layout_default(0.0))
    }
    yi += 1
  }
  let mut si = 0
  while si < series_list.length() {
    let series = series_list[si]
    si += 1
    if series.series_type != Bar || series.coordinate_system == Some("polar") {
      continue
    }
    let y_idx = if series.y_axis_index < layouts.length() {
      series.y_axis_index
    } else {
      0
    }
    if y_idx < 0 || y_idx >= coord.y_scales.length() {
      continue
    }
    match coord.y_scales[y_idx] {
      Ordinal(_) => {
        let axis_layout = layouts[y_idx]
        let stack_id = bar_category_series_stack_id(series, si - 1)
        let stack_index = bar_find_category_stack_layout_index(
          axis_layout.stacks,
          stack_id,
        )
        if stack_index < 0 {
          axis_layout.auto_width_count += 1
          axis_layout.stacks.push({
            stack_id,
            width: 0.0,
            max_width: 0.0,
            min_width: None,
            offset: 0.0,
          })
        }
        let stack_index = bar_find_category_stack_layout_index(
          axis_layout.stacks,
          stack_id,
        )
        if stack_index >= 0 {
          if series.bar_width != None &&
            axis_layout.stacks[stack_index].width == 0.0 {
            let bar_width = bar_parse_percent_like(
              series.bar_width.unwrap_or("0"),
              axis_layout.band_width,
            )
            if bar_width > 0.0 {
              let used_width = if bar_width < axis_layout.remained_width {
                bar_width
              } else {
                axis_layout.remained_width
              }
              axis_layout.stacks[stack_index].width = used_width
              axis_layout.remained_width -= used_width
            }
          }
          if series.bar_max_width != None {
            axis_layout.stacks[stack_index].max_width = bar_parse_percent_like(
              series.bar_max_width.unwrap_or("0"),
              axis_layout.band_width,
            )
          }
          if series.bar_min_width != None {
            axis_layout.stacks[stack_index].min_width = Some(
              bar_parse_percent_like(
                series.bar_min_width.unwrap_or("0"),
                axis_layout.band_width,
              ),
            )
          }
        }
        if series.bar_gap != None {
          axis_layout.gap = series.bar_gap.unwrap_or(axis_layout.gap)
        }
        if series.bar_category_gap != None {
          axis_layout.category_gap = series.bar_category_gap
        }
        layouts[y_idx] = axis_layout
      }
      Linear(_) => ()
      BreakLinear(_) => ()
    }
  }
  let mut yi2 = 0
  while yi2 < layouts.length() {
    layouts[yi2] = bar_finalize_category_axis_layout(layouts[yi2])
    yi2 += 1
  }
  layouts
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
priv struct BarCartesianStackCoord {
  p : Double
  n : Double
}

///|
priv struct BarCartesianStackState {
  stack_id : String
  coords : Array[BarCartesianStackCoord]
}

///|
priv struct BarCategoryStackLayout {
  stack_id : String
  mut width : Double
  mut max_width : Double
  mut min_width : Double?
  mut offset : Double
}

///|
priv struct BarCategoryAxisLayout {
  band_width : Double
  mut remained_width : Double
  mut auto_width_count : Int
  mut category_gap : String?
  mut gap : String
  stacks : Array[BarCategoryStackLayout]
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
  series.geo_item_style
  .bind(style => style.color)
  .unwrap_or(
    series.item_style.unwrap_or(
      series.color.unwrap_or(@visual.palette_color(series_index)),
    ),
  )
}

///|
fn bar_fill_opacity(series : @option.SeriesOption) -> Double {
  series.item_opacity.unwrap_or(
    series.geo_item_style.bind(style => style.opacity).unwrap_or(1.0),
  )
}

///|
priv struct BarResolvedStyle {
  fill_color : String
  opacity : Double
  border_color : String?
  border_width : Double
  border_radius : Array[Double]? // [tl, tr, br, bl]
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
  let fill_color = item_style.bind(style => style.color).unwrap_or(series_fill)
  let opacity = item_style
    .bind(style => style.opacity)
    .unwrap_or(series_opacity)
  let border_color = match item_style.bind(style => style.border_color) {
    Some(color) => Some(color)
    None => series_border_color
  }
  let border_width = item_style
    .bind(style => style.border_width)
    .unwrap_or(series_border_width)
  let border_radius = match item_style.bind(style => style.border_radius) {
    Some(v) => Some(v)
    None => series.geo_item_style.bind(style => style.border_radius)
  }
  { fill_color, opacity, border_color, border_width, border_radius }
}

///|
fn bar_resolve_background_style(
  series : @option.SeriesOption,
) -> BarResolvedStyle {
  let default_fill = "rgba(180, 180, 180, 0.2)"
  let background_style = series.background_style.unwrap_or(
    @option.GeoItemStylePatchOption::default(),
  )
  let fill_color = background_style.color.unwrap_or(
    background_style.area_color.unwrap_or(default_fill),
  )
  {
    fill_color,
    opacity: background_style.opacity.unwrap_or(1.0),
    border_color: background_style.border_color,
    border_width: background_style.border_width.unwrap_or(0.0),
    border_radius: background_style.border_radius,
  }
}

///|
/// <=> echarts/src/chart/bar/BarView.ts:updateStyle (polar label)
/// <=> echarts/src/label/sectorLabel.ts:createSectorCalculateTextPosition
/// <=> echarts/src/label/sectorLabel.ts:setSectorTextRotation
fn bar_render_polar_middle_label(
  series : @option.SeriesOption,
  item : @option.DataItem,
  base_axis : @coord.PolarAxis,
  data_index : Int,
  value : Double,
  cx : Double,
  cy : Double,
  r0 : Double,
  r1 : Double,
  start_angle_deg : Double,
  end_angle_deg : Double,
) -> @graphic.Element? {
  let series_label = series.label.unwrap_or(@option.GeoLabelOption::default())
  let item_label = item.label
  let show = item_label.bind(l => l.show).unwrap_or(series_label.show)
  if !show {
    return None
  }

  let position = item_label
    .bind(l => l.position)
    .unwrap_or(series_label.position.unwrap_or("outside"))
  if position != "middle" {
    return None
  }

  let formatter = match item_label.bind(l => l.formatter) {
    Some(value) => Some(value)
    None => series_label.formatter
  }

  let item_name = match item.name {
    Some(name) => name
    None =>
      match base_axis.scale {
        Ordinal(scale) =>
          if data_index >= 0 && data_index < scale.categories.length() {
            scale.categories[data_index]
          } else {
            ""
          }
        _ => ""
      }
  }
  let value_str = if value.to_int().to_double() == value {
    value.to_int().to_string()
  } else {
    value.to_string()
  }
  let text = @option.apply_label_formatter(
    Some({ ..series_label, formatter, }),
    series.name.unwrap_or(""),
    item_name,
    value_str,
    None,
  )
  if text == "" {
    return None
  }

  let middle_r = (r0 + r1) / 2.0
  let middle_angle_deg = (start_angle_deg + end_angle_deg) / 2.0
  let middle_angle = -middle_angle_deg / 180.0 * @math.PI
  let x = cx + middle_r * @math.cos(middle_angle)
  let y = cy + middle_r * @math.sin(middle_angle)

  let start_angle = -start_angle_deg / 180.0 * @math.PI
  let end_angle = -end_angle_deg / 180.0 * @math.PI
  let clockwise = start_angle_deg >= end_angle_deg
  let start_for_rot = if clockwise { start_angle } else { end_angle }
  let end_for_rot = if clockwise { end_angle } else { start_angle }
  let middle_angle = (start_for_rot + end_for_rot) / 2.0
  let mut rotate = @math.PI * 1.5 - middle_angle
  if rotate > @math.PI / 2.0 && rotate < @math.PI * 1.5 {
    rotate -= @math.PI
  }

  let color = match item_label.bind(l => l.color) {
    Some(c) => c
    None =>
      if series_label.color == "#54555a" {
        "#eee"
      } else {
        series_label.color
      }
  }
  let font_size = item_label
    .bind(l => l.font_size)
    .unwrap_or(series_label.font_size)
  let font_family = item_label
    .bind(l => l.font_family)
    .unwrap_or(series_label.font_family)
  let font_weight = item_label
    .bind(l => l.font_weight)
    .unwrap_or(series_label.font_weight.unwrap_or("normal"))

  let text_elem = @graphic.Element::text_custom(
    0.0,
    0.0,
    text,
    @graphic.TextAnchor::Middle,
    @graphic.TextBaseline::Central,
    color,
    font_size,
    font_family,
    font_weight,
  )
  Some(
    @graphic.Element::group_transformed(
      [text_elem],
      @graphic.Matrix::translate(x, y).then(@graphic.Matrix::rotate(rotate)),
    ),
  )
}

///|
fn bar_rect_path(x : Double, y : Double, w : Double, h : Double) -> String {
  "M\{bar_r1(x)} \{bar_r1(y)}l\{bar_r1(w)} 0l0 \{bar_r1(h)}l\{bar_r1(-w)} 0Z"
}

///|
/// Rounded-rectangle SVG path with per-corner radii, mirroring zrender Rect `r`.
/// r = [tl, tr, br, bl] applied to the bounding box corners (CSS order).
/// Works for any sign of w/h by normalising to a positive-dimension bbox first.
fn bar_rounded_rect_path(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  r : Array[Double],
) -> String {
  // Normalise to positive-dimension bounding box
  let x0 = if w >= 0.0 { x } else { x + w }
  let y0 = if h >= 0.0 { y } else { y + h }
  let rw = w.abs()
  let rh = h.abs()
  // Expand r shorthand to 4 values (CSS convention)
  let n = r.length()
  let r0 = r[0]
  let r1 = if n > 1 { r[1] } else { r[0] }
  let r2 = if n > 2 { r[2] } else { r[0] }
  let r3 = if n > 3 { r[3] } else if n > 1 { r[1] } else { r[0] }
  // Clamp each radius so corners don't overlap
  let half_w = rw / 2.0
  let half_h = rh / 2.0
  let r_tl = r0.min(half_w).min(half_h)
  let r_tr = r1.min(half_w).min(half_h)
  let r_br = r2.min(half_w).min(half_h)
  let r_bl = r3.min(half_w).min(half_h)
  if r_tl == 0.0 && r_tr == 0.0 && r_br == 0.0 && r_bl == 0.0 {
    return bar_rect_path(x, y, w, h)
  }
  let x1 = x0 + rw
  let y1 = y0 + rh
  let buf = StringBuilder::new()
  // Start on top edge just right of TL corner, draw clockwise
  buf.write_string("M\{bar_r1(x0 + r_tl)} \{bar_r1(y0)}")
  // Top edge → TR corner
  if r_tr > 0.0 {
    buf.write_string("L\{bar_r1(x1 - r_tr)} \{bar_r1(y0)}")
    buf.write_string(
      "A\{bar_r1(r_tr)} \{bar_r1(r_tr)} 0 0 1 \{bar_r1(x1)} \{bar_r1(y0 + r_tr)}",
    )
  } else {
    buf.write_string("L\{bar_r1(x1)} \{bar_r1(y0)}")
  }
  // Right edge → BR corner
  if r_br > 0.0 {
    buf.write_string("L\{bar_r1(x1)} \{bar_r1(y1 - r_br)}")
    buf.write_string(
      "A\{bar_r1(r_br)} \{bar_r1(r_br)} 0 0 1 \{bar_r1(x1 - r_br)} \{bar_r1(y1)}",
    )
  } else {
    buf.write_string("L\{bar_r1(x1)} \{bar_r1(y1)}")
  }
  // Bottom edge → BL corner
  if r_bl > 0.0 {
    buf.write_string("L\{bar_r1(x0 + r_bl)} \{bar_r1(y1)}")
    buf.write_string(
      "A\{bar_r1(r_bl)} \{bar_r1(r_bl)} 0 0 1 \{bar_r1(x0)} \{bar_r1(y1 - r_bl)}",
    )
  } else {
    buf.write_string("L\{bar_r1(x0)} \{bar_r1(y1)}")
  }
  // Left edge → TL corner
  if r_tl > 0.0 {
    buf.write_string("L\{bar_r1(x0)} \{bar_r1(y0 + r_tl)}")
    buf.write_string(
      "A\{bar_r1(r_tl)} \{bar_r1(r_tl)} 0 0 1 \{bar_r1(x0 + r_tl)} \{bar_r1(y0)}",
    )
  } else {
    buf.write_string("L\{bar_r1(x0)} \{bar_r1(y0)}")
  }
  buf.write_string("Z")
  buf.to_string()
}

///|
/// Choose between a plain rect path and a rounded rect path based on style.
fn bar_style_rect_path(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  border_radius : Array[Double]?,
) -> String {
  match border_radius {
    Some(r) if r.length() > 0 => bar_rounded_rect_path(x, y, w, h, r)
    _ => bar_rect_path(x, y, w, h)
  }
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
  stack_layout : BarCategoryStackLayout?,
  draw_background : Bool,
  draw_bars : Bool,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let base_y = coord.bbox.y + coord.bbox.height
  let is_horizontal = false
  let category_axis_index = series.x_axis_index
  let cartesian_stack_states : Array[BarCartesianStackState] = []
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
        let bar_x = match stack_layout {
          Some(layout) => cat_px + layout.offset
          None =>
            cat_px -
            total_span / 2.0 +
            bar_index.to_double() * bar_w * (1.0 + gap_percent)
        }
        let render_bar_w = match stack_layout {
          Some(layout) => layout.width
          None => bar_w
        }
        if draw_background && series.show_background {
          bar_append_rect_path(
            bg_buf,
            bar_x,
            coord.bbox.y,
            render_bar_w,
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
        bar_append_rect_path(fg_buf, bar_x, base_y, render_bar_w, bar_h)
        fg_count += 1
        if fg_count >= chunk_limit {
          children.push(
            bar_render_path(fg_buf.to_string(), {
              fill_color: bar_fill,
              opacity: bar_opacity,
              border_color: None,
              border_width: 0.0,
              border_radius: None,
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
            border_radius: None,
          }).with_ecmeta_attr("series_index", series_order.to_string()),
        )
      }
      if children.length() > 0 {
        elems.push(@graphic.Element::group_clipped(children, coord.bbox))
      }
    }
    Linear(s) =>
      if is_horizontal {
        match coord.y_scales[y_idx] {
          Ordinal(sy) => {
            let nd = series.data.length()
            let render_nd = if nd > bar_large_render_limit() {
              bar_large_render_limit()
            } else {
              nd
            }
            let band_width = sy.band_width()
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
            let bar_h = if auto_width < 0.5 { 0.5 } else { auto_width }
            let total_span = if n > 0 {
              bar_h * n.to_double() + bar_h * gap_percent * (n - 1).to_double()
            } else {
              bar_h
            }
            let _ = coord.num_x(x_idx, 0.0)
            let _ = bar_fill_color(series, series_index)
            let _ = bar_fill_opacity(series)
            let mut di = 0
            while di < render_nd {
              let item = series.data[di]
              di += 1
              let cat_px = if di - 1 < sy.categories.length() {
                sy.band_center(di - 1)
              } else {
                coord.bbox.y
              }
              let render_bar_h = match stack_layout {
                Some(layout) => layout.width
                None => bar_h
              }
              let bar_y = match stack_layout {
                Some(layout) => cat_px + layout.offset
                None =>
                  cat_px -
                  total_span / 2.0 +
                  bar_index.to_double() * bar_h * (1.0 + gap_percent)
              }
              if draw_background && series.show_background {
                let bg_style = bar_resolve_background_style(series)
                elems.push(
                  bar_render_path(
                    bar_style_rect_path(
                      coord.bbox.x,
                      bar_y,
                      coord.bbox.width,
                      render_bar_h,
                      bg_style.border_radius,
                    ),
                    bg_style,
                  ).with_silent(true),
                )
              }
              if !draw_bars {
                continue
              }
              let style = bar_resolve_data_style(series, item, series_index)
              let value = bar_item_value(item)
              let stacked = series.stack != None
              let stack_state_index = if stacked {
                let stack_key = bar_series_cartesian_key_for_axis(
                  series, series_order, category_axis_index,
                )
                let existing = bar_find_cartesian_stack_state_index(
                  cartesian_stack_states, stack_key,
                )
                if existing >= 0 {
                  existing
                } else {
                  cartesian_stack_states.push({
                    stack_id: stack_key,
                    coords: [],
                  })
                  cartesian_stack_states.length() - 1
                }
              } else {
                -1
              }
              let mut base_value = 0.0
              if stack_state_index >= 0 {
                while cartesian_stack_states[stack_state_index].coords.length() <=
                      di - 1 {
                  cartesian_stack_states[stack_state_index].coords.push({
                    p: 0.0,
                    n: 0.0,
                  })
                }
                let stack_coord = cartesian_stack_states[stack_state_index].coords[di -
                  1]
                base_value = if value >= 0.0 {
                  stack_coord.p
                } else {
                  stack_coord.n
                }
              }
              let top_value = base_value + value
              let top_x = coord.num_x(x_idx, top_value)
              let base_coord = coord.num_x(x_idx, base_value)
              let bar_w = top_x - base_coord
              if stack_state_index >= 0 {
                let stack_coord = cartesian_stack_states[stack_state_index].coords[di -
                  1]
                cartesian_stack_states[stack_state_index].coords[di - 1] = {
                  p: if value >= 0.0 {
                    top_value
                  } else {
                    stack_coord.p
                  },
                  n: if value < 0.0 {
                    top_value
                  } else {
                    stack_coord.n
                  },
                }
              }
              elems.push(
                bar_render_path(
                  bar_rect_path(base_coord, bar_y, bar_w, render_bar_h),
                  style,
                )
                .with_ecmeta_attr("series_index", series_order.to_string())
                .with_ecmeta_attr("data_index", (di - 1).to_string())
                .with_ecmeta_attr("ssr_type", "chart"),
              )
            }
          }
          Linear(_) | BreakLinear(_) => {
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
              let base_y = coord.bbox.y + coord.bbox.height
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
                  border_radius: None,
                }).with_ecmeta_attr("series_index", series_order.to_string()),
              ]
              elems.push(@graphic.Element::group_clipped(children, coord.bbox))
            }
          }
        }
      } else {
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
          let base_y = coord.bbox.y + coord.bbox.height
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
              border_radius: None,
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
    let parsed = try? @string.parse_double(pct_str)
    match parsed {
      Ok(pct) => reference * pct / 100.0
      Err(_) => 0.0
    }
  } else {
    let parsed = try? @string.parse_double(value)
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
        let style = bar_resolve_data_style(series, item, series_index)
        let d = bar_sector_path(
          polar.cx,
          polar.cy,
          r0,
          r1,
          start_angle,
          end_angle,
        )
        elems.push(bar_render_path(d, style))
        match
          bar_render_polar_middle_label(
            series,
            item,
            base_axis,
            di,
            data1,
            polar.cx,
            polar.cy,
            r0,
            r1,
            start_angle,
            end_angle,
          ) {
          Some(label_elem) => elems.push(label_elem)
          None => ()
        }
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
        let style = bar_resolve_data_style(series, item, series_index)
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
        elems.push(bar_render_path(d, style))
        match
          bar_render_polar_middle_label(
            series,
            item,
            base_axis,
            di,
            data1,
            polar.cx,
            polar.cy,
            r0,
            r1,
            start_angle,
            end_angle,
          ) {
          Some(label_elem) => elems.push(label_elem)
          None => ()
        }
      }
    }
    di += 1
  }
  elems
}

///|
/// <=> echarts/src/chart/bar/BarView.ts:_renderNormal
fn bar_render_series_cartesian_impl(
  series : @option.SeriesOption,
  series_index : Int,
  series_order : Int,
  coord : @coord.Cartesian2D,
  bar_index : Int,
  total_bars : Int,
  category_axis_index : Int,
  is_horizontal : Bool,
  stack_layout : BarCategoryStackLayout?,
  draw_background : Bool,
  draw_bars : Bool,
  cartesian_stack_states : Array[BarCartesianStackState],
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let base_y = coord.num_y(y_idx, 0.0)
  if x_idx >= coord.x_scales.length() {
    return elems
  }
  match coord.x_scales[x_idx] {
    Ordinal(s) => {
      let band_step = s.band_step()
      let n = if total_bars > 0 { total_bars } else { 1 }
      let cat_gap_pct = (35 - n * 4).max(15).to_double()
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
        let render_bar_w = match stack_layout {
          Some(layout) => layout.width
          None => bar_w
        }
        let bar_x = match stack_layout {
          Some(layout) => cat_px + layout.offset
          None =>
            cat_px - total_span / 2.0 + bar_index.to_double() * bar_w * 1.3
        }
        if draw_background && series.show_background {
          let bg_style = bar_resolve_background_style(series)
          let p = bar_render_path(
            bar_style_rect_path(
              bar_x,
              coord.bbox.y,
              render_bar_w,
              coord.bbox.height,
              bg_style.border_radius,
            ),
            bg_style,
          ).with_silent(true)
          elems.push(p)
        }
        if !draw_bars {
          continue
        }
        let style = bar_resolve_data_style(series, item, series_index)
        let value = bar_item_value(item)
        let stacked = series.stack != None
        let stack_state_index = if stacked {
          let stack_key = bar_series_cartesian_key_for_axis(
            series, series_order, category_axis_index,
          )
          let existing = bar_find_cartesian_stack_state_index(
            cartesian_stack_states, stack_key,
          )
          if existing >= 0 {
            existing
          } else {
            cartesian_stack_states.push({ stack_id: stack_key, coords: [] })
            cartesian_stack_states.length() - 1
          }
        } else {
          -1
        }
        let mut base_value = 0.0
        if stack_state_index >= 0 {
          while cartesian_stack_states[stack_state_index].coords.length() <=
                di - 1 {
            cartesian_stack_states[stack_state_index].coords.push({
              p: 0.0,
              n: 0.0,
            })
          }
          let stack_coord = cartesian_stack_states[stack_state_index].coords[di -
            1]
          base_value = if value >= 0.0 { stack_coord.p } else { stack_coord.n }
        }
        let top_value = base_value + value
        let top_y = coord.num_y(y_idx, top_value)
        let base_coord = coord.num_y(y_idx, base_value)
        let bar_h = top_y - base_coord
        if stack_state_index >= 0 {
          let stack_coord = cartesian_stack_states[stack_state_index].coords[di -
            1]
          cartesian_stack_states[stack_state_index].coords[di - 1] = {
            p: if value >= 0.0 {
              top_value
            } else {
              stack_coord.p
            },
            n: if value < 0.0 {
              top_value
            } else {
              stack_coord.n
            },
          }
        }
        elems.push(
          bar_render_path(
            bar_style_rect_path(
              bar_x,
              base_coord,
              render_bar_w,
              bar_h,
              style.border_radius,
            ),
            style,
          )
          .with_ecmeta_attr("series_index", series_order.to_string())
          .with_ecmeta_attr("data_index", (di - 1).to_string())
          .with_ecmeta_attr("ssr_type", "chart"),
        )
      }
    }
    Linear(s) =>
      if is_horizontal {
        match coord.y_scales[y_idx] {
          Ordinal(sy) => {
            let nd = series.data.length()
            let _ = 10.0
            let render_nd = if nd > bar_large_render_limit() {
              bar_large_render_limit()
            } else {
              nd
            }
            let band_width = sy.band_width()
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
            let bar_h = if auto_width < 0.5 { 0.5 } else { auto_width }
            let total_span = if n > 0 {
              bar_h * n.to_double() + bar_h * gap_percent * (n - 1).to_double()
            } else {
              bar_h
            }
            let _ = coord.num_x(x_idx, 0.0)
            let mut di = 0
            while di < render_nd {
              let item = series.data[di]
              di += 1
              let cat_px = if di - 1 < sy.categories.length() {
                sy.band_center(di - 1)
              } else {
                coord.bbox.y
              }
              let render_bar_h = match stack_layout {
                Some(layout) => layout.width
                None => bar_h
              }
              let bar_y = match stack_layout {
                Some(layout) => cat_px + layout.offset
                None =>
                  cat_px -
                  total_span / 2.0 +
                  bar_index.to_double() * bar_h * (1.0 + gap_percent)
              }
              if draw_background && series.show_background {
                let bg_style = bar_resolve_background_style(series)
                elems.push(
                  bar_render_path(
                    bar_style_rect_path(
                      coord.bbox.x,
                      bar_y,
                      coord.bbox.width,
                      render_bar_h,
                      bg_style.border_radius,
                    ),
                    bg_style,
                  ).with_silent(true),
                )
              }
              if !draw_bars {
                continue
              }
              let style = bar_resolve_data_style(series, item, series_index)
              let value = bar_item_value(item)
              let stacked = series.stack != None
              let stack_state_index = if stacked {
                let stack_key = bar_series_cartesian_key_for_axis(
                  series, series_order, category_axis_index,
                )
                let existing = bar_find_cartesian_stack_state_index(
                  cartesian_stack_states, stack_key,
                )
                if existing >= 0 {
                  existing
                } else {
                  cartesian_stack_states.push({
                    stack_id: stack_key,
                    coords: [],
                  })
                  cartesian_stack_states.length() - 1
                }
              } else {
                -1
              }
              let mut base_value = 0.0
              if stack_state_index >= 0 {
                while cartesian_stack_states[stack_state_index].coords.length() <=
                      di - 1 {
                  cartesian_stack_states[stack_state_index].coords.push({
                    p: 0.0,
                    n: 0.0,
                  })
                }
                let stack_coord = cartesian_stack_states[stack_state_index].coords[di -
                  1]
                base_value = if value >= 0.0 {
                  stack_coord.p
                } else {
                  stack_coord.n
                }
              }
              let top_value = base_value + value
              let top_x = coord.num_x(x_idx, top_value)
              let base_coord = coord.num_x(x_idx, base_value)
              let bar_w = top_x - base_coord
              if stack_state_index >= 0 {
                let stack_coord = cartesian_stack_states[stack_state_index].coords[di -
                  1]
                cartesian_stack_states[stack_state_index].coords[di - 1] = {
                  p: if value >= 0.0 {
                    top_value
                  } else {
                    stack_coord.p
                  },
                  n: if value < 0.0 {
                    top_value
                  } else {
                    stack_coord.n
                  },
                }
              }
              elems.push(
                bar_render_path(
                  bar_style_rect_path(
                    base_coord,
                    bar_y,
                    bar_w,
                    render_bar_h,
                    style.border_radius,
                  ),
                  style,
                )
                .with_ecmeta_attr("series_index", series_order.to_string())
                .with_ecmeta_attr("data_index", (di - 1).to_string())
                .with_ecmeta_attr("ssr_type", "chart"),
              )
            }
          }
          _ => ()
        }
      } else {
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
            let bg_style = bar_resolve_background_style(series)
            elems.push(
              bar_render_path(
                bar_style_rect_path(
                  bar_x,
                  coord.bbox.y,
                  bar_w,
                  coord.bbox.height,
                  bg_style.border_radius,
                ),
                bg_style,
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
            bar_render_path(
              bar_style_rect_path(
                bar_x,
                base_y,
                bar_w,
                bar_h,
                style.border_radius,
              ),
              style,
            )
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
/// <=> echarts/src/chart/bar/BarView.ts:render
/// <=> echarts/src/layout/barGrid.ts:layout
pub fn render_bar_series_cartesian(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  bar_index : Int,
  total_bars : Int,
) -> Array[@graphic.Element] {
  let cartesian_stack_states : Array[BarCartesianStackState] = []
  let is_horizontal = bar_series_cartesian_is_horizontal(series, coord)
  let category_axis_index = bar_series_cartesian_category_axis_index(
    series, coord,
  )
  if bar_series_is_large(series) {
    bar_render_series_cartesian_large_impl(
      series,
      series_index,
      series_index,
      coord,
      bar_index,
      total_bars,
      None,
      true,
      true,
    )
  } else {
    bar_render_series_cartesian_impl(
      series,
      series_index,
      series_index,
      coord,
      bar_index,
      total_bars,
      category_axis_index,
      is_horizontal,
      None,
      true,
      true,
      cartesian_stack_states,
    )
  }
}

///|
/// <=> echarts/src/chart/bar/BarView.ts:render
/// <=> echarts/src/layout/barGrid.ts:layout
pub fn render_bars(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
) -> Array[@graphic.Element] {
  let background_elems : Array[@graphic.Element] = []
  let foreground_elems : Array[@graphic.Element] = []
  let max_xi = opt.x_axis.length()
  let max_yi = opt.y_axis.length()
  let x_category_layouts = bar_make_category_layout(opt.series, coord)
  let y_category_layouts = bar_make_category_layout_y(opt.series, coord)
  let bar_column_keys_by_x_axis : Array[Array[String]] = []
  let mut xi_init = 0
  while xi_init <= max_xi {
    bar_column_keys_by_x_axis.push([])
    xi_init += 1
  }
  let bar_column_keys_by_y_axis : Array[Array[String]] = []
  let mut yi_init = 0
  while yi_init <= max_yi {
    bar_column_keys_by_y_axis.push([])
    yi_init += 1
  }
  let polar_layout = polar.map(p => bar_cal_radial_layout(opt.series, p))
  let cartesian_stack_states : Array[BarCartesianStackState] = []
  let mut count_i = 0
  while count_i < opt.series.length() {
    let s = opt.series[count_i]
    count_i += 1
    match s.series_type {
      Bar =>
        if s.coordinate_system != Some("polar") {
          let is_horizontal = bar_series_cartesian_is_horizontal(s, coord)
          let axis_index = if is_horizontal {
            if s.y_axis_index < max_yi {
              s.y_axis_index
            } else {
              0
            }
          } else if s.x_axis_index < max_xi {
            s.x_axis_index
          } else {
            0
          }
          let key = bar_series_cartesian_key_for_axis(
            s,
            count_i - 1,
            axis_index,
          )
          if is_horizontal {
            if bar_find_string_index(bar_column_keys_by_y_axis[axis_index], key) <
              0 {
              bar_column_keys_by_y_axis[axis_index].push(key)
            }
          } else if bar_find_string_index(
              bar_column_keys_by_x_axis[axis_index],
              key,
            ) <
            0 {
            bar_column_keys_by_x_axis[axis_index].push(key)
          }
        }
      _ => ()
    }
  }

  let mut sr_bg = 0
  let mut color_idx = 0
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
      let is_horizontal = bar_series_cartesian_is_horizontal(series, coord)
      let axis_index = if is_horizontal {
        if series.y_axis_index < max_yi {
          series.y_axis_index
        } else {
          0
        }
      } else if series.x_axis_index < max_xi {
        series.x_axis_index
      } else {
        0
      }
      let category_layouts = if is_horizontal {
        y_category_layouts
      } else {
        x_category_layouts
      }
      let stack_layout = bar_category_layout_get_stack(
        category_layouts,
        axis_index,
        series,
        sr_bg - 1,
      )
      let key = bar_series_cartesian_key_for_axis(series, sr_bg - 1, axis_index)
      let keys_by_axis = if is_horizontal {
        bar_column_keys_by_y_axis
      } else {
        bar_column_keys_by_x_axis
      }
      let rank = bar_find_string_index(keys_by_axis[axis_index], key)
      let total = keys_by_axis[axis_index].length()
      let series_elems = if bar_series_is_large(series) {
        bar_render_series_cartesian_large_impl(
          series,
          color_idx,
          sr_bg - 1,
          coord,
          rank,
          total,
          stack_layout,
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
          axis_index,
          is_horizontal,
          stack_layout,
          true,
          false,
          cartesian_stack_states,
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
      let is_horizontal = bar_series_cartesian_is_horizontal(series, coord)
      let axis_index = if is_horizontal {
        if series.y_axis_index < max_yi {
          series.y_axis_index
        } else {
          0
        }
      } else if series.x_axis_index < max_xi {
        series.x_axis_index
      } else {
        0
      }
      let category_layouts = if is_horizontal {
        y_category_layouts
      } else {
        x_category_layouts
      }
      let stack_layout = bar_category_layout_get_stack(
        category_layouts,
        axis_index,
        series,
        sr - 1,
      )
      let key = bar_series_cartesian_key_for_axis(series, sr - 1, axis_index)
      let keys_by_axis = if is_horizontal {
        bar_column_keys_by_y_axis
      } else {
        bar_column_keys_by_x_axis
      }
      let rank = bar_find_string_index(keys_by_axis[axis_index], key)
      let total = keys_by_axis[axis_index].length()
      let series_elems = if bar_series_is_large(series) {
        bar_render_series_cartesian_large_impl(
          series,
          color_idx,
          sr - 1,
          coord,
          rank,
          total,
          stack_layout,
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
          axis_index,
          is_horizontal,
          stack_layout,
          false,
          true,
          cartesian_stack_states,
        )
      }
      foreground_elems.append(series_elems)
    }
    color_idx += 1
  }

  background_elems.append(foreground_elems)
  background_elems
}

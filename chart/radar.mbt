// Corresponds to: echarts/src/chart/radar/RadarView.ts
//                  echarts/src/chart/radar/radarLayout.ts
//                  echarts/src/coord/radar/Radar.ts
//
// Radar (spider web) chart renderer.
//
// Coordinate system (Radar.ts):
//   angle[i] = startAngle_rad + sign * i * 2π/N
//   where:
//     startAngle_rad = startAngle_option * π/180   (default startAngle=90)
//     sign = clockwise ? -1 : 1                    (default clockwise=false → sign=1)
//   Screen points:
//     x = cx + coord * cos(angle[i])
//     y = cy - coord * sin(angle[i])       ← MINUS y (ECharts screen convention)
//
// Data format: each series data item is either:
//   - Vec([v0, v1, ..., vN])     one value per indicator
//   - an object with "value" array
//
// Background rendering (RadarModel / RadarView):
//   - splitNumber concentric polygon rings
//   - N radial spoke lines from center to outer radius
//   - indicator name labels at each spoke tip

///|
/// Compute angle for indicator index i in screen coords.
fn radar_angle(
  i : Int,
  n : Int,
  start_angle_rad : Double,
  sign : Double,
) -> Double {
  start_angle_rad + sign * i.to_double() * @math.PI * 2.0 / n.to_double()
}

///|
/// Convert (coord, angle) to screen (x, y).
fn radar_point(
  cx : Double,
  cy : Double,
  coord : Double,
  angle : Double,
) -> (Double, Double) {
  let x = cx + coord * @math.cos(angle)
  let y = cy - coord * @math.sin(angle) // note: minus sign for screen y
  (x, y)
}

///|
/// Parse percentage or pixel string relative to a reference (min dim / 2).
fn radar_parse_r(s : String, ref_val : Double) -> Double {
  if s.has_suffix("%") {
    let inner = s[:s.length() - 1]
    let r = try? @string.parse_double(inner.to_string())
    match r {
      Ok(v) => v / 100.0 * ref_val
      Err(_) => ref_val * 0.75
    }
  } else {
    let r = try? @string.parse_double(s)
    match r {
      Ok(v) => v
      Err(_) => ref_val * 0.75
    }
  }
}

///|
fn radar_parse_center(s : String, ref_val : Double) -> Double {
  if s.has_suffix("%") {
    let inner = s[:s.length() - 1]
    let r = try? @string.parse_double(inner.to_string())
    match r {
      Ok(v) => v / 100.0 * ref_val
      Err(_) => ref_val * 0.5
    }
  } else {
    let r = try? @string.parse_double(s)
    match r {
      Ok(v) => v
      Err(_) => ref_val * 0.5
    }
  }
}

///|
/// Render all radar series plus the radar coordinate background.
pub fn render_radars(opt : @option.ChartOption) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  // Render each radar component background, then each series

  for ri, _ in opt.radar {
    let radar_opt = opt.radar[ri]
    let bg_elems = render_radar_background(radar_opt, opt.width, opt.height)
    elems.append(bg_elems)
  }
  // Find first visualMap that applies to all series (series_index = None)
  // <=> echarts/src/component/visualMap/VisualMapModel.ts seriesIndex handling
  let mut vm_opt : @option.VisualMapOption? = None

  for vmi, _ in opt.visual_map {
    let v = opt.visual_map[vmi]
    match v.series_index {
      None => {
        vm_opt = Some(v)
        break
      }
      _ => ()
    }
  }
  // Auto-compute min/max from all radar series data at vm.dimension
  // <=> echarts/src/component/visualMap/VisualMapModel.ts _resetTarget
  let (vm_min, vm_max) = match vm_opt {
    None => (0.0, 100.0)
    Some(vm) => {
      let mut mn = 0.0
      let mut mx = 0.0
      let mut found = false
      for s in opt.series {
        match s.series_type {
          Radar => ()
          _ => continue
        }
        for item in s.data {
          match data_value_dimension(item.value, vm.dimension) {
            Some(v2) => {
              if !found || v2 < mn {
                mn = v2
              }
              if !found || v2 > mx {
                mx = v2
              }
              found = true
            }
            None => ()
          }
        }
      }
      if !found {
        (0.0, 100.0)
      } else {
        (mn, mx)
      }
    }
  }
  // Render each radar series
  let mut color_idx = 0
  for si, _ in opt.series {
    let series = opt.series[si]
    match series.series_type {
      Radar => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    // Pick the radar coordinate system
    let ri_idx = series.radar_index
    if ri_idx >= opt.radar.length() {
      color_idx = color_idx + 1
      continue
    }
    let radar_opt = opt.radar[ri_idx]
    let series_elems = render_radar_series(
      opt,
      series,
      color_idx,
      radar_opt,
      opt.width,
      opt.height,
      vm_opt,
      vm_min,
      vm_max,
    )
    elems.append(series_elems)
    color_idx = color_idx + 1
  }
  elems
}

///|
/// Render the radar background: concentric polygon rings, spoke lines, labels.
fn render_radar_background(
  radar_opt : @option.RadarOption,
  chart_width : Double,
  chart_height : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let n = radar_opt.indicator.length()
  if n == 0 {
    return elems
  }
  let ref_r = (if chart_width < chart_height {
      chart_width
    } else {
      chart_height
    }) /
    2.0
  let cx = if radar_opt.center.length() >= 1 {
    radar_parse_center(radar_opt.center[0], chart_width)
  } else {
    chart_width * 0.5
  }
  let cy = if radar_opt.center.length() >= 2 {
    radar_parse_center(radar_opt.center[1], chart_height)
  } else {
    chart_height * 0.5
  }
  let r = radar_parse_r(radar_opt.radius, ref_r)
  let start_angle_rad = radar_opt.start_angle * @math.PI / 180.0
  let sign = if radar_opt.clockwise { -1.0 } else { 1.0 }
  let split_n = radar_opt.split_number

  // Colors from ECharts tokens
  // neutral15 = #dbdee4 for ring stroke, neutral20 = #cfd2d7 for spokes
  let ring_stroke_color = "#dbdee4" // neutral15
  let spoke_color = "#cfd2d7" // neutral20
  let label_color = "#54555a" // neutral70
  // Alternating ring fill: odd rings get a light gray fill, even rings transparent
  let ring_fill_odd = @graphic.Color::rgba(234, 237, 245, 128) // ~50% opacity light gray

  // Concentric polygon rings (from inner to outer)
  let mut level = 1
  while level <= split_n {
    let level_r = r * level.to_double() / split_n.to_double()
    let ring_pts : Array[@graphic.Point] = []
    let mut i = 0
    while i < n {
      let angle = radar_angle(i, n, start_angle_rad, sign)
      let (px, py) = radar_point(cx, cy, level_r, angle)
      ring_pts.push(@graphic.Point::new(px, py))
      i += 1
    }
    let ring_color_val = @graphic.Color::from_string(ring_stroke_color).unwrap_or(
      @graphic.black,
    )
    // Odd levels get a light gray fill; even levels are transparent
    if level % 2 == 1 {
      elems.push(
        @graphic.Element::polygon_fill_stroke(
          ring_pts, ring_fill_odd, ring_color_val, 1.0, 1.0,
        ),
      )
    } else {
      elems.push(
        @graphic.Element::polygon_fill_stroke(
          ring_pts, @graphic.transparent, ring_color_val, 1.0, 1.0,
        ),
      )
    }
    level = level + 1
  }

  // Spoke lines from center to outer ring
  let mut i = 0
  while i < n {
    let angle = radar_angle(i, n, start_angle_rad, sign)
    let (px, py) = radar_point(cx, cy, r, angle)
    elems.push(@graphic.Element::line_colored(cx, cy, px, py, spoke_color, 1.0))
    i += 1
  }

  // Indicator labels at tip + a small offset
  let mut i2 = 0
  while i2 < n {
    let angle = radar_angle(i2, n, start_angle_rad, sign)
    let label_r = r + 15.0
    let (lx, ly) = radar_point(cx, cy, label_r, angle)
    let anchor = if @math.cos(angle) > 0.05 {
      @graphic.TextAnchor::Start
    } else if @math.cos(angle) < -0.05 {
      @graphic.TextAnchor::End
    } else {
      @graphic.TextAnchor::Middle
    }
    let indicator = radar_opt.indicator[i2]
    elems.push(
      @graphic.Element::text_colored(
        lx,
        ly,
        indicator.name,
        anchor,
        @graphic.TextBaseline::Middle,
        label_color,
      ),
    )
    i2 += 1
  }
  elems
}

///|
/// Radar default uses colorBy:'data', so palette assignment advances across all
/// radar data items in chart order rather than restarting per series.
/// <=> echarts/src/chart/radar/RadarSeries.ts:defaultOption
/// <=> echarts/src/visual/style.ts:dataColorPaletteTask
fn radar_palette_data_index(
  opt : @option.ChartOption,
  series_index : Int,
  data_index : Int,
) -> Int {
  let mut ordinal = 0
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    if series.series_type == Radar {
      if si == series_index {
        return ordinal + data_index
      }
      ordinal = ordinal + series.data.length()
    }
    si += 1
  }
  ordinal + data_index
}

///|
/// Render a single radar series.
/// Each data item is rendered as a filled polygon (opacity 0.7) +
/// a stroked polyline, matching RadarView.ts behaviour.
/// <=> echarts/src/chart/radar/RadarView.ts
pub fn render_radar_series(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
  series_index : Int,
  radar_opt : @option.RadarOption,
  chart_width : Double,
  chart_height : Double,
  vm_opt : @option.VisualMapOption?,
  vm_min : Double,
  vm_max : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let n = radar_opt.indicator.length()
  if n == 0 {
    return elems
  }
  let any_highlighted = @visual.has_any_highlighted(series.data)
  let ref_r = (if chart_width < chart_height {
      chart_width
    } else {
      chart_height
    }) /
    2.0
  let cx = if radar_opt.center.length() >= 1 {
    radar_parse_center(radar_opt.center[0], chart_width)
  } else {
    chart_width * 0.5
  }
  let cy = if radar_opt.center.length() >= 2 {
    radar_parse_center(radar_opt.center[1], chart_height)
  } else {
    chart_height * 0.5
  }
  let r = radar_parse_r(radar_opt.radius, ref_r)
  let start_angle_rad = radar_opt.start_angle * @math.PI / 180.0
  let sign = if radar_opt.clockwise { -1.0 } else { 1.0 }
  // lineStyle.width, default 1 matching ECharts radar default
  let line_width = series.line_style_width.unwrap_or(1.0)

  // For each data item — each gets its own palette color (series_index + data_index)

  for di, _ in series.data {
    let item = series.data[di]
    let palette_idx = radar_palette_data_index(opt, series_index, di)
    // Resolve item color: visualMap > series.color > palette
    // <=> echarts/src/chart/radar/RadarView.ts data.getItemVisual(idx, 'style').fill
    let data_color_str = match vm_opt {
      Some(vm) =>
        match data_value_dimension(item.value, vm.dimension) {
          Some(val) => {
            let span = vm_max - vm_min
            let ratio = if span == 0.0 {
              0.0
            } else {
              clamp01((val - vm_min) / span)
            }
            match color_stops_color(vm.in_range.color, ratio) {
              Some(c) => c
              None =>
                match series.color {
                  Some(c) => c
                  None => @visual.palette_color(palette_idx)
                }
            }
          }
          None =>
            match series.color {
              Some(c) => c
              None => @visual.palette_color(palette_idx)
            }
        }
      None =>
        match series.color {
          Some(c) => c
          None => @visual.palette_color(palette_idx)
        }
    }
    let color = @graphic.Color::from_string(data_color_str).unwrap_or(
      @graphic.black,
    )
    let values = match item.value {
      Vec(arr) => arr
      _ => continue
    }
    // Build polygon points for this data item
    let pts : Array[@graphic.Point] = []
    let mut i = 0
    while i < n {
      let v = if i < values.length() { values[i] } else { 0.0 }
      // Determine max for this indicator
      let max_val = match radar_opt.indicator[i].max {
        Some(m) => m
        None => 100.0
      }
      let min_val = match radar_opt.indicator[i].min {
        Some(m) => m
        None => 0.0
      }
      let coord = if max_val > min_val {
        (v - min_val) / (max_val - min_val) * r
      } else {
        0.0
      }
      let angle = radar_angle(i, n, start_angle_rad, sign)
      let (px, py) = radar_point(cx, cy, coord, angle)
      pts.push(@graphic.Point::new(px, py))
      i += 1
    }
    if pts.length() < 2 {
      continue
    }
    let item_highlighted = item.highlighted == Some(true)
    let emphasis_color = if item_highlighted {
      @visual.lift_hex_color(data_color_str)
    } else {
      data_color_str
    }
    let emphasis_style : @graphic.DisplayStateStyle = {
      fill: Some(emphasis_color),
      stroke: Some(emphasis_color),
      line_width: None,
      stroke_no_scale: false,
    }
    let blur_style : @graphic.DisplayStateStyle = {
      fill: None,
      stroke: None,
      line_width: None,
      stroke_no_scale: false,
    }
    // Fill polygon only when areaStyle is specified (area_style = true)
    // ECharts: areaStyle.opacity defaults to 0 (no fill unless areaStyle is set)
    // <=> echarts/src/chart/radar/RadarView.ts polygon.useStyle({fill:..., opacity:...})
    if series.area_style {
      let fill_elem = @graphic.Element::polygon_filled(pts, color, 0.7)
      elems.push(
        if any_highlighted {
          fill_elem
          .with_emphasis_style(emphasis_style)
          .with_blur_style(blur_style)
        } else {
          fill_elem
        },
      )
    }
    // Border polyline (opacity 1.0) — matches polyline.useStyle({stroke: color, fill: 'none'})
    let stroke_elem = @graphic.Element::polygon_stroked_round(
      pts, color, line_width,
    )
    elems.push(
      if any_highlighted {
        stroke_elem
        .with_emphasis_style(emphasis_style)
        .with_blur_style(blur_style)
      } else {
        stroke_elem
      },
    )
    // Symbols at each vertex — ECharts renders 'emptyCircle' by default at symbolSize=8
    // <=> echarts/src/chart/radar/RadarView.ts SymbolDraw.updateData()
    for pt in pts {
      let symbol_elem = @graphic.Element::circle_colored(
        pt.x,
        pt.y,
        series.symbol_size * 0.5,
        data_color_str,
      )
      elems.push(
        if any_highlighted {
          symbol_elem
          .with_emphasis_style(emphasis_style)
          .with_blur_style(blur_style)
        } else {
          symbol_elem
        },
      )
    }
  }
  elems
}

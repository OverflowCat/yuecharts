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
    let r = try? @strconv.parse_double(inner.to_string())
    match r {
      Ok(v) => v / 100.0 * ref_val
      Err(_) => ref_val * 0.75
    }
  } else {
    let r = try? @strconv.parse_double(s)
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
    let r = try? @strconv.parse_double(inner.to_string())
    match r {
      Ok(v) => v / 100.0 * ref_val
      Err(_) => ref_val * 0.5
    }
  } else {
    let r = try? @strconv.parse_double(s)
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
  let mut ri = 0
  while ri < opt.radar.length() {
    let radar_opt = opt.radar[ri]
    ri += 1
    let bg_elems = render_radar_background(radar_opt, opt.width, opt.height)
    elems.append(bg_elems)
  }
  // Find first visualMap that applies to all series (series_index = None)
  // <=> echarts/src/component/visualMap/VisualMapModel.ts seriesIndex handling
  let mut vm_opt : @option.VisualMapOption? = None
  let mut vmi = 0
  while vmi < opt.visual_map.length() {
    let v = opt.visual_map[vmi]
    match v.series_index {
      None => {
        vm_opt = Some(v)
        break
      }
      _ => ()
    }
    vmi += 1
  }
  // Auto-compute min/max from all radar series data at vm.dimension
  // <=> echarts/src/component/visualMap/VisualMapModel.ts _resetTarget
  let (vm_min, vm_max) = match vm_opt {
    None => (0.0, 100.0)
    Some(vm) => {
      let mut mn = 0.0
      let mut mx = 0.0
      let mut found = false
      let mut s2 = 0
      while s2 < opt.series.length() {
        let s = opt.series[s2]
        s2 += 1
        match s.series_type {
          Radar => ()
          _ => continue
        }
        let mut di = 0
        while di < s.data.length() {
          let item = s.data[di]
          di += 1
          match data_value_dimension(item.value, vm.dimension) {
            Some(v2) => {
              if not(found) || v2 < mn {
                mn = v2
              }
              if not(found) || v2 > mx {
                mx = v2
              }
              found = true
            }
            None => ()
          }
        }
      }
      if not(found) {
        (0.0, 100.0)
      } else {
        (mn, mx)
      }
    }
  }
  // Render each radar series
  let mut si = 0
  let mut color_idx = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si += 1
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
/// Render a single radar series.
/// Each data item is rendered as a filled polygon (opacity 0.7) +
/// a stroked polyline, matching RadarView.ts behaviour.
/// <=> echarts/src/chart/radar/RadarView.ts
pub fn render_radar_series(
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
  let mut di = 0
  while di < series.data.length() {
    let item = series.data[di]
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
                  None => @visual.palette_color(series_index + di)
                }
            }
          }
          None =>
            match series.color {
              Some(c) => c
              None => @visual.palette_color(series_index + di)
            }
        }
      None =>
        match series.color {
          Some(c) => c
          None => @visual.palette_color(series_index + di)
        }
    }
    let color = @graphic.Color::from_string(data_color_str).unwrap_or(
      @graphic.black,
    )
    di += 1
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
    // Fill polygon (opacity 0.7) — matches polygon.useStyle({fill: color, opacity: 0.7})
    elems.push(@graphic.Element::polygon_filled(pts, color, 0.7))
    // Border polyline (opacity 1.0) — matches polyline.useStyle({stroke: color, fill: 'none'})
    elems.push(@graphic.Element::polygon_stroked_round(pts, color, line_width))
  }
  elems
}

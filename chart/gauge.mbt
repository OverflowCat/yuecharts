/// <=> echarts/src/chart/gauge/GaugeView.ts
/// <=> echarts/src/chart/gauge/GaugeSeries.ts
//
// Gauge chart renderer.
//
// ECharts defaults (GaugeSeries.ts):
//   center = ['50%', '50%']
//   radius = '75%'
//   startAngle = 225 (option degrees)
//   endAngle = -45  (option degrees)
//   clockwise = true
//   min = 0, max = 100, splitNumber = 10
//   axisLine.lineStyle.width = 10 (gauge track width)
//   pointer.length = '60%' of r, pointer.width = 6
//   splitLine.length = 10, lineStyle.width = 3 (color = axisTick neutral70 #54555a)
//   axisTick.length = 6, lineStyle.width = 1
//
// Angle convention (GaugeView.ts):
//   angle_rad = -option_degrees / 180 * PI
//   x = cx + r * Math.cos(angle_rad)
//   y = cy + r * Math.sin(angle_rad)   ← PLUS sin (y-down screen coords, like pie chart)
//
// With these defaults:
//   startAngle_rad = -225/180*PI = -5PI/4  → lower-left → 7-8 o'clock ✓
//   endAngle_rad   = +45/180*PI  = +PI/4   → lower-right → 4-5 o'clock ✓
//   Gauge axisLine/progress is rendered as a ring sector like GaugeView.ts,
//   with outer SVG sweep-flag=1 and inner reverse arc sweep-flag=0.

///|
/// Build SVG sector path for the gauge axis line / progress ring.
/// Corresponds to the graphic.Sector path used in echarts/src/chart/gauge/GaugeView.ts.
fn gauge_sector_path(
  cx : Double,
  cy : Double,
  r0 : Double,
  r : Double,
  a0 : Double,
  a1 : Double,
) -> String {
  let outer_x0 = cx + r * @math.cos(a0)
  let outer_y0 = cy + r * @math.sin(a0)
  let outer_x1 = cx + r * @math.cos(a1)
  let outer_y1 = cy + r * @math.sin(a1)
  let span = {
    let d = a1 - a0
    if d < 0.0 {
      -d
    } else {
      d
    }
  }
  let large_arc = if span > @math.PI { 1 } else { 0 }
  let inner_x0 = cx + r0 * @math.cos(a0)
  let inner_y0 = cy + r0 * @math.sin(a0)
  let inner_x1 = cx + r0 * @math.cos(a1)
  let inner_y1 = cy + r0 * @math.sin(a1)
  "M \{r4(outer_x0)} \{r4(outer_y0)} A \{r4(r)} \{r4(r)} 0 \{large_arc} 1 \{r4(outer_x1)} \{r4(outer_y1)} L \{r4(inner_x1)} \{r4(inner_y1)} A \{r4(r0)} \{r4(r0)} 0 \{large_arc} 0 \{r4(inner_x0)} \{r4(inner_y0)} Z"
}

///|
/// Add round-cap circles at both endpoints of a sector arc.
/// Corresponds to: echarts/src/chart/gauge/GaugeView.ts Sausage shape.
/// In SVG we approximate by placing filled circles of radius cap_r = (r - r0) / 2
/// at the midpoint of each cap (r_mid = (r + r0) / 2 along the arc endpoints).
fn gauge_round_cap_circles(
  elems : Array[@graphic.Element],
  cx : Double,
  cy : Double,
  r0 : Double,
  r : Double,
  a0 : Double,
  a1 : Double,
  color : String,
) -> Unit {
  let cap_r = (r - r0) / 2.0
  let r_mid = (r + r0) / 2.0
  // Start cap
  let sc_x = cx + r_mid * @math.cos(a0)
  let sc_y = cy + r_mid * @math.sin(a0)
  elems.push(@graphic.Element::circle_colored(sc_x, sc_y, cap_r, color))
  // End cap
  let ec_x = cx + r_mid * @math.cos(a1)
  let ec_y = cy + r_mid * @math.sin(a1)
  elems.push(@graphic.Element::circle_colored(ec_x, ec_y, cap_r, color))
}

///|
/// Format a gauge tick label value: integer if whole, else two decimal places.
fn fmt_gauge_val(v : Double) -> String {
  let iv = v.to_int()
  let fv = if v >= 0.0 { v - iv.to_double() } else { -(-v - (-iv).to_double()) }
  let diff = if fv < 0.0 { -fv } else { fv }
  if diff < 1.0e-6 {
    iv.to_string()
  } else {
    // two decimal places
    let scaled = (v * 100.0 + 0.5).to_int()
    let whole = scaled / 100
    let frac = {
      let f = scaled % 100
      if f < 0 {
        -f
      } else {
        f
      }
    }
    let frac_str = if frac < 10 { "0\{frac}" } else { frac.to_string() }
    "\{whole}.\{frac_str}"
  }
}

///|
/// Approximate bounding box of an SVG path by scanning all numeric tokens.
/// Returns (min_x, min_y, width, height). Treats alternating token pairs as (x,y).
/// Corresponds to: zrender getBoundingRect for icons used by createSymbol.
fn svg_path_bbox(path_data : String) -> (Double, Double, Double, Double) {
  let n = path_data.length()
  let nums : Array[Double] = []
  let mut i = 0
  while i < n {
    let ch = path_data[i].to_int()
    // 48='0' 57='9' 45='-' 46='.'
    if ch == 45 || (ch >= 48 && ch <= 57) || ch == 46 {
      let start = i
      if ch == 45 {
        i = i + 1
      }
      while i < n {
        let c = path_data[i].to_int()
        if (c >= 48 && c <= 57) || c == 46 {
          i = i + 1
        } else {
          break
        }
      }
      if i > start {
        let tok = path_data.substring(start=start, end=i)
        let r = try? @strconv.parse_double(tok)
        match r {
          Ok(v) => nums.push(v)
          Err(_) => ()
        }
      }
    } else {
      i = i + 1
    }
  }
  if nums.length() < 2 {
    return (0.0, 0.0, 1.0, 1.0)
  }
  let mut min_x = nums[0]
  let mut max_x = nums[0]
  let mut min_y = nums[1]
  let mut max_y = nums[1]
  let mut j = 2
  while j + 1 < nums.length() {
    let x = nums[j]
    let y = nums[j + 1]
    if x < min_x {
      min_x = x
    }
    if x > max_x {
      max_x = x
    }
    if y < min_y {
      min_y = y
    }
    if y > max_y {
      max_y = y
    }
    j = j + 2
  }
  let bw = max_x - min_x
  let bh = max_y - min_y
  (min_x, min_y, if bw > 0.0 { bw } else { 1.0 }, if bh > 0.0 { bh } else { 1.0 })
}

///|
/// Render all gauge series in the chart option.
pub fn render_gauges(opt : @option.ChartOption) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut si = 0
  let mut color_idx = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si += 1
    match series.series_type {
      @option.Gauge => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let gauge_elems = render_gauge_series(
      series,
      color_idx,
      opt.width,
      opt.height,
    )
    let mut i = 0
    while i < gauge_elems.length() {
      elems.push(gauge_elems[i])
      i += 1
    }
    color_idx = color_idx + 1
  }
  elems
}

///|
/// Render a single gauge series.
/// Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderMain
pub fn render_gauge_series(
  series : @option.SeriesOption,
  series_index : Int,
  chart_width : Double,
  chart_height : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let _ = series_index

  // --- Center ---
  let cx = if series.center.length() >= 1 {
    parse_pct_or_px(series.center[0], chart_width)
  } else {
    chart_width * 0.5
  }
  let cy = if series.center.length() >= 2 {
    parse_pct_or_px(series.center[1], chart_height)
  } else {
    chart_height * 0.5
  }

  // --- Radius (relative to min(width,height)/2) ---
  let ref_r = (if chart_width < chart_height {
      chart_width
    } else {
      chart_height
    }) /
    2.0
  let r = if series.radius.length() >= 1 {
    parse_pct_or_px(series.radius[0], ref_r)
  } else {
    ref_r * 0.75
  }

  // --- Angles in radians (ECharts convention: angle_rad = -option_deg * PI/180) ---
  let start_rad = -(series.start_angle * @math.PI / 180.0)
  let end_rad_raw = -(series.end_angle * @math.PI / 180.0)
  let end_rad = if end_rad_raw > start_rad {
    end_rad_raw
  } else {
    end_rad_raw + 2.0 * @math.PI
  }
  let angle_span = end_rad - start_rad

  let min_v = series.min_val
  let max_v = series.max_val

  // --- Read styled fields ---
  // Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderMain
  let track_width = series.gauge_axis_line_width
  let track_inner_r = r - track_width
  let split_len = series.gauge_split_line_length
  let split_dist = series.gauge_split_line_distance
  let split_color = series.gauge_split_line_color
  let split_line_width = series.gauge_split_line_width
  let tick_len = series.gauge_axis_tick_length
  let tick_dist = series.gauge_axis_tick_distance
  let tick_color = series.gauge_axis_tick_color
  let tick_line_width = series.gauge_axis_tick_width
  let label_color = series.gauge_axis_label_color
  let label_dist = series.gauge_axis_label_distance
  let label_font_size = series.gauge_axis_label_font_size
  let split_n = if series.split_number > 0 { series.split_number } else { 10 }

  // --- 1. axisLine: colored sectors ---
  // Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderMain axisLine sectors
  // colorList = [[offset, color], ...] each sector spans prevEnd..startAngle+span*offset
  {
    let color_list = series.gauge_axis_line_colors
    let mut prev_end = start_rad
    for entry in color_list {
      let (pct, seg_color) = entry
      let pct_clamped = if pct < 0.0 {
        0.0
      } else if pct > 1.0 {
        1.0
      } else {
        pct
      }
      let seg_end = start_rad + angle_span * pct_clamped
      let arc = gauge_sector_path(cx, cy, track_inner_r, r, prev_end, seg_end)
      elems.push(@graphic.Element::path_filled(arc, seg_color, 1.0))
      prev_end = seg_end
    }
    if series.gauge_round_cap {
      let last_color = if color_list.length() > 0 {
        color_list[color_list.length() - 1].1
      } else {
        "#e8ebf0"
      }
      gauge_round_cap_circles(
        elems, cx, cy, track_inner_r, r, start_rad, end_rad, last_color,
      )
    }
  }

  // --- 2. Progress arcs (one per data item) ---
  // Corresponds to: GaugeView.ts _renderPointer createProgress()
  let data_count = series.data.length()
  if series.gauge_progress_show && data_count > 0 {
    // Render in reverse order so higher-value arcs appear on top (overlap mode)
    // Corresponds to: z2 = linearMap(value, [min, max], [100, 0]) in GaugeView.ts
    let prog_width = series.gauge_progress_width
    let mut di = data_count - 1
    while di >= 0 {
      let item = series.data[di]
      let value = match item.value {
        @option.Num(n) => n
        @option.Vec(arr) => if arr.length() > 0 { arr[0] } else { min_v }
        @option.DateValue(_, n) => n
        @option.Null => min_v
      }
      let pct = if max_v > min_v {
        let p = (value - min_v) / (max_v - min_v)
        if p < 0.0 {
          0.0
        } else if p > 1.0 {
          1.0
        } else {
          p
        }
      } else {
        0.0
      }
      if pct > 0.0 {
        let value_rad = start_rad + angle_span * pct
        // overlap=true: all arcs share the same r0..r band (just stacked by z2)
        // overlap=false: each arc gets a narrower sub-band
        let mut arc_r = r
        let mut arc_r0 = r - prog_width
        if series.gauge_progress_overlap {
          arc_r = r
          arc_r0 = r - prog_width
        } else {
          arc_r = r - di.to_double() * prog_width
          arc_r0 = r - (di.to_double() + 1.0) * prog_width
        }
        let prog_color = @visual.palette_color(di)
        let prog_arc = gauge_sector_path(
          cx, cy, arc_r0, arc_r, start_rad, value_rad,
        )
        elems.push(@graphic.Element::path_filled(prog_arc, prog_color, 1.0))
        // progress.roundCap: add circles at arc endpoints.
        // Corresponds to: GaugeView.ts Sausage shape for progress.
        if series.gauge_progress_round_cap {
          gauge_round_cap_circles(
            elems, cx, cy, arc_r0, arc_r, start_rad, value_rad, prog_color,
          )
        }
      }
      di -= 1
    }
  } else if data_count > 0 && not(series.gauge_progress_show) {
    // Legacy single-value progress (backwards compat when progress.show=false)
    let value = match series.data[0].value {
      @option.Num(n) => n
      @option.Vec(arr) => if arr.length() > 0 { arr[0] } else { min_v }
      @option.DateValue(_, n) => n
      @option.Null => min_v
    }
    let pct = if max_v > min_v {
      let p = (value - min_v) / (max_v - min_v)
      if p < 0.0 {
        0.0
      } else if p > 1.0 {
        1.0
      } else {
        p
      }
    } else {
      0.0
    }
    if pct > 0.0 {
      let value_rad = start_rad + angle_span * pct
      let prog_color = @visual.palette_color(0)
      let prog_arc = gauge_sector_path(
        cx, cy, track_inner_r, r, start_rad, value_rad,
      )
      elems.push(@graphic.Element::path_filled(prog_arc, prog_color, 1.0))
    }
  }

  // --- 3. Split lines and labels ---
  // Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderTicks splitLine/axisLabel
  // JS formula:
  //   splitLine outer = r - (splitLineDistance + axisLineWidth)
  //   splitLine inner = r - splitLineLen - (splitLineDistance + axisLineWidth)
  //   label textX = unitX * (r - splitLineLen - (labelDistance + splitLineDistance)) + cx
  let sl_offset = split_dist + track_width
  let lbl_dist_total = label_dist + split_dist
  let mut ssi = 0
  while ssi <= split_n {
    let a = start_rad + angle_span * ssi.to_double() / split_n.to_double()
    let ux = @math.cos(a)
    let uy = @math.sin(a)
    if series.gauge_split_line_show {
      let sl_outer_r = r - sl_offset
      let sl_inner_r = r - split_len - sl_offset
      let ox = cx + sl_outer_r * ux
      let oy = cy + sl_outer_r * uy
      let ix = cx + sl_inner_r * ux
      let iy = cy + sl_inner_r * uy
      elems.push(
        @graphic.Element::line_colored(ox, oy, ix, iy, split_color, split_line_width),
      )
    }
    if series.gauge_axis_label_show {
      let split_val = min_v +
        (max_v - min_v) * ssi.to_double() / split_n.to_double()
      let lbl_r = r - split_len - lbl_dist_total
      let lx = cx + lbl_r * ux
      let ly = cy + lbl_r * uy
      elems.push(
        @graphic.Element::text_custom(
          lx,
          ly,
          fmt_gauge_val(split_val),
          @graphic.TextAnchor::Middle,
          @graphic.TextBaseline::Middle,
          label_color,
          label_font_size,
          "sans-serif",
          "normal",
        ),
      )
    }
    ssi = ssi + 1
  }

  // --- 4. Minor ticks ---
  // Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderTicks axisTick
  // JS formula:
  //   axisTick outer = r - (tickDistance + axisLineWidth)
  //   axisTick inner = r - tickLen - (tickDistance + axisLineWidth)
  let sub_n = series.gauge_axis_tick_split_number
  let tick_offset = tick_dist + track_width
  if series.gauge_axis_tick_show {
    let minor_total = split_n * sub_n
    let mut ti = 0
    while ti < minor_total {
      if ti % sub_n == 0 {
        ti += 1
        continue
      }
      let a = start_rad + angle_span * ti.to_double() / minor_total.to_double()
      let ux = @math.cos(a)
      let uy = @math.sin(a)
      let tk_outer_r = r - tick_offset
      let tk_inner_r = r - tick_len - tick_offset
      let ox = cx + tk_outer_r * ux
      let oy = cy + tk_outer_r * uy
      let ix = cx + tk_inner_r * ux
      let iy = cy + tk_inner_r * uy
      elems.push(
        @graphic.Element::line_colored(
          ox, oy, ix, iy, tick_color, tick_line_width,
        ),
      )
      ti += 1
    }
  }

  // --- 5. Pointer ---
  // Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderPointer createPointer()
  // pointer.show=false => skip
  if series.gauge_pointer_show {
    let ptr_value = if data_count > 0 {
      match series.data[0].value {
        @option.Num(n) => n
        @option.Vec(arr) => if arr.length() > 0 { arr[0] } else { min_v }
        @option.DateValue(_, n) => n
        @option.Null => min_v
      }
    } else {
      min_v
    }
    let ptr_pct = if max_v > min_v {
      let p = (ptr_value - min_v) / (max_v - min_v)
      if p < 0.0 { 0.0 } else if p > 1.0 { 1.0 } else { p }
    } else {
      0.0
    }
    let value_rad = start_rad + angle_span * ptr_pct
    let ptr_color = match series.gauge_pointer_color {
      Some(c) => c
      None => @visual.palette_color(series_index)
    }
    // offsetCenter in pixels relative to cx/cy
    let off_x = if series.gauge_pointer_offset_center.length() >= 1 {
      parse_pct_or_px(series.gauge_pointer_offset_center[0], r)
    } else {
      0.0
    }
    let off_y = if series.gauge_pointer_offset_center.length() >= 2 {
      parse_pct_or_px(series.gauge_pointer_offset_center[1], r)
    } else {
      0.0
    }
    let ptr_len = parse_pct_or_px(series.gauge_pointer_length, r)
    let ptr_w = series.gauge_pointer_width
    // Rotation for the needle: -(value_rad + PI/2)
    // JS: pointer.rotation = -(angle + PI/2); pointer.x = cx; pointer.y = cy
    let rot = -(value_rad + @math.PI / 2.0)
    let cos_r = @math.cos(rot)
    let sin_r = @math.sin(rot)
    match series.gauge_pointer_icon {
      Some(icon_str) if icon_str.has_prefix("path://") => {
        // Custom SVG path icon pointer.
        // Corresponds to: GaugeView.ts createPointer using createSymbol("path://...")
        // The path is normalized to fit bounding box [offX-w/2, offY-len, w, len]
        // then matrix-transformed by rotation around (cx, cy).
        //
        // We approximate: translate(cx+offX, cy+offY) then rotate(rot) then
        // translate (-offX, -offY) to center the path on the offset point.
        // For simplicity, compute the full affine transform:
        //   final transform = translate(cx, cy) * rotate(rot) (since createSymbol
        //   already builds path in [offX-w/2, offY-len, w, len] space)
        let path_data = icon_str.substring(start=7) // strip "path://"
        // Compute SVG path bounding box heuristically from coordinate values
        // and scale to target box [offX-w/2, offY-ptr_len, ptr_w, ptr_len]
        let bbox = svg_path_bbox(path_data)
        let target_x = off_x - ptr_w / 2.0
        let target_y = off_y - ptr_len
        let target_w = ptr_w
        let target_h = ptr_len
        let (bx, by, bw, bh) = bbox
        let sx = if bw > 0.0 { target_w / bw } else { 1.0 }
        let sy = if bh > 0.0 { target_h / bh } else { 1.0 }
        let tx = target_x - bx * sx
        let ty = target_y - by * sy
        // Combined transform: translate(cx,cy) * rotate(rot) applied to the
        // path which is already in local space from createSymbol output.
        // Full matrix = rotate(rot) * scale(sx,sy) * translate(tx_local, ty_local)
        // But we also need to account for the rotation center being (cx, cy).
        // The path is in createSymbol space (already scaled/translated).
        // Then pointer.rotation = rot, pointer.x = cx, pointer.y = cy means:
        //   transformedPoint = rotate(rot) * localPoint + (cx, cy)
        // So we need: rotate(rot) * (scale(sx,sy)*originalPoint + (tx,ty)) + (cx,cy)
        //          = rot_mat * scale * original + rot_mat * (tx, ty) + (cx, cy)
        // Matrix: [sx*cos_r, sx*sin_r; -sy*sin_r, sy*cos_r] with
        //         translate = rot*(tx,ty) + (cx,cy)
        let m_a = sx * cos_r
        let m_b = sx * sin_r
        let m_c = -sy * sin_r
        let m_d = sy * cos_r
        let m_e = cos_r * tx - sin_r * ty + cx
        let m_f = sin_r * tx + cos_r * ty + cy
        let mat = @graphic.Matrix::from_values(m_a, m_b, m_c, m_d, m_e, m_f)
        let path_elem = @graphic.Element::path_filled(path_data, ptr_color, 1.0)
        elems.push(@graphic.Element::group_transformed([path_elem], mat))
      }
      _ => {
        // Default PointerPath: triangle pointing from back through tip.
        // JS PointerPath shape: angle=-PI/2 means pointing up before rotation.
        // Base at (offX, offY), tip at (offX, offY-ptr_len).
        // We replicate with a simple thin triangle path in rotated space.
        let base_half_w = ptr_w / 2.0
        // local coords (before rotation): tip=(offX, offY-ptr_len), base width at offY
        // map: rotate by (rot) then translate(cx,cy)
        let points = [
          (off_x, off_y - ptr_len), // tip
          (off_x + base_half_w, off_y), // base right
          (off_x - base_half_w, off_y), // base left
        ]
        let to_world = fn(lx : Double, ly : Double) -> (Double, Double) {
          (cos_r * lx - sin_r * ly + cx, sin_r * lx + cos_r * ly + cy)
        }
        let (tx0, ty0) = to_world(points[0].0, points[0].1)
        let (tx1, ty1) = to_world(points[1].0, points[1].1)
        let (tx2, ty2) = to_world(points[2].0, points[2].1)
        let back_x = cx + r * 0.1 * @math.cos(value_rad)
        let back_y = cy + r * 0.1 * @math.sin(value_rad)
        let _ = (back_x, back_y)
        let ptr_d = "M \{r4(tx0)} \{r4(ty0)} L \{r4(tx1)} \{r4(ty1)} L \{r4(tx2)} \{r4(ty2)} Z"
        elems.push(@graphic.Element::path_filled(ptr_d, ptr_color, 1.0))
      }
    }
  }

  // --- 6. Anchor ---
  // Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderAnchor
  // anchor is a circle of radius = size/2 at (cx, cy), styled by itemStyle.
  if series.gauge_anchor_show {
    let anc_r = series.gauge_anchor_size / 2.0
    let anc_fill = match series.gauge_anchor_color {
      Some(c) => c
      None => "#ffffff"
    }
    let anc_border = match series.gauge_anchor_border_color {
      Some(c) => c
      None => @visual.palette_color(series_index)
    }
    let anc_border_w = series.gauge_anchor_border_width
    elems.push(
      @graphic.Element::circle_fill_stroke(
        cx, cy, anc_r, anc_fill, anc_border, anc_border_w,
      ),
    )
  }

  // --- 7. Per-item title and detail ---
  // Corresponds to: GaugeView.ts _renderTitleAndDetail
  let mut di = 0
  while di < data_count {
    let item = series.data[di]
    let value = match item.value {
      @option.Num(n) => n
      @option.Vec(arr) => if arr.length() > 0 { arr[0] } else { min_v }
      @option.DateValue(_, n) => n
      @option.Null => min_v
    }
    let item_color = @visual.palette_color(di)

    // Title text (item name)
    let title_oc : Array[String] = match item.title_offset_center {
      Some(oc) => oc
      None => series.gauge_title_offset_center
    }
    let title_x = if title_oc.length() >= 1 {
      cx + parse_pct_or_px(title_oc[0], r)
    } else {
      cx
    }
    let title_y = if title_oc.length() >= 2 {
      cy + parse_pct_or_px(title_oc[1], r)
    } else {
      cy
    }
    let item_name = item.name.unwrap_or("")
    if item_name != "" {
      elems.push(
        @graphic.Element::text_custom(
          title_x,
          title_y,
          item_name,
          @graphic.TextAnchor::Middle,
          @graphic.TextBaseline::Middle,
          item_color,
          series.gauge_title_font_size,
          "sans-serif",
          "normal",
        ),
      )
    }

    // Detail text (formatted value)
    let detail_oc : Array[String] = match item.detail_offset_center {
      Some(oc) => oc
      None => series.gauge_detail_offset_center
    }
    let detail_x = if detail_oc.length() >= 1 {
      cx + parse_pct_or_px(detail_oc[0], r)
    } else {
      cx
    }
    let detail_y = if detail_oc.length() >= 2 {
      cy + parse_pct_or_px(detail_oc[1], r)
    } else {
      cy
    }
    // Format the value using detail.formatter if set
    // Corresponds to: GaugeView.ts formatLabel(value, formatter)
    let val_str = fmt_gauge_val(value)
    let detail_text = match series.gauge_detail_formatter {
      Some(fmt) => fmt.replace(old="{value}", new=val_str)
      None => val_str
    }
    let detail_color = match series.gauge_detail_color {
      Some(c) => if c == "inherit" { item_color } else { c }
      None => item_color
    }
    elems.push(
      @graphic.Element::text_custom(
        detail_x,
        detail_y,
        detail_text,
        @graphic.TextAnchor::Middle,
        @graphic.TextBaseline::Middle,
        detail_color,
        series.gauge_detail_font_size,
        "sans-serif",
        "bold",
      ),
    )
    di += 1
  }

  elems
}

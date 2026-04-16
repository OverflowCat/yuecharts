/// <=> echarts/src/chart/themeRiver/ThemeRiverView.ts
/// <=> echarts/src/chart/themeRiver/themeRiverLayout.ts
/// <=> echarts/src/chart/themeRiver/ThemeRiverSeries.ts
/// <=> echarts/src/chart/themeRiver/install.ts
//
// ThemeRiver (stream graph) renderer.
//
// Data format: series.data = [[date_string, value, name], ...]
// Each triplet represents a (time, value, stream-name) observation.
//
// Layout algorithm (themeRiverLayout.ts):
//  1. Group data by stream name (getLayerSeries).
//  2. For each stream/time, map date -> pixel x via Single coord.
//  3. Compute stacked baseline using Lee Byron's geometry: y0[k] = (max - sum[k])/2
//     so that layers are centered on the single axis.
//  4. Each item gets layout: { x, y0, y } where y0 is the cumulative baseline
//     and y is the proportional height.
//
// Rendering (ThemeRiverView.ts):
//  - Each stream is an ECPolygon with smooth=0.4 bezier curves.
//  - lower edge: (x, y0) points
//  - upper edge: (x, y0 + y) points
//  - Polygon path: forward along lower, reverse along upper, close.
//  - Label placed at the rightmost point, vertically centered on the stream.

///|
pub(all) struct ThemeRiverView {}

///|
pub fn ThemeRiverView::render(
  _self : ThemeRiverView,
  ctx : @core.RenderContext,
) -> Array[@graphic.Element] {
  render_theme_rivers(ctx.option, ctx.single)
}

///|
priv struct TRLayerItem {
  x : Double
  y0 : Double
  y : Double
}

///|
priv struct TRLayer {
  name : String
  color : String
  items : Array[TRLayerItem]
}

///|
priv struct TRDataRow {
  time : String
  value : Double
  name : String
}

///|
priv struct TRLayerData {
  name : String
  data_list : Array[TRDataRow]
}

///|
/// Parse a series with themeRiver data into layers grouped by name.
/// Corresponds to: ThemeRiverSeries.getLayerSeries()
fn theme_river_get_layers(
  series : @option.SeriesOption,
  single : @coord.Single,
  palette_offset : Int,
) -> Array[TRLayer] {
  let fixed_rows = theme_river_fix_rows(series)
  let grouped = theme_river_group_rows_by_name(fixed_rows)
  let n_layers = grouped.length()
  if n_layers == 0 {
    return []
  }
  let mut li = 0
  for li, _ in grouped {
    theme_river_sort_layer_by_time(grouped[li], single)
  }
  let point_count = theme_river_common_point_count(grouped)
  if point_count == 0 {
    return []
  }
  let values : Array[Array[Double]] = []
  li = 0
  while li < n_layers {
    let row : Array[Double] = []
    let mut j = 0
    while j < point_count {
      row.push(grouped[li].data_list[j].value)
      j += 1
    }
    values.push(row)
    li += 1
  }
  // Compute baseline using Lee Byron's algorithm (themeRiverLayout.ts computeBaseline)
  // sums[j] = sum of all layer values at time j
  let sums : Array[Double] = []
  let mut di = 0
  while di < point_count {
    let mut s = 0.0
    li = 0
    while li < n_layers {
      s += values[li][di]
      li += 1
    }
    sums.push(s)
    di += 1
  }
  let mut max_sum = 0.0
  di = 0
  while di < point_count {
    if sums[di] > max_sum {
      max_sum = sums[di]
    }
    di += 1
  }
  // y0[j] = (max_sum - sums[j]) / 2  (centering)
  let baseline : Array[Double] = []
  di = 0
  while di < point_count {
    baseline.push((max_sum - sums[di]) / 2.0)
    di += 1
  }
  // Re-compute max as max(sums[j] + baseline[j])
  let mut global_max = 0.0
  di = 0
  while di < point_count {
    let v = sums[di] + baseline[di]
    if v > global_max {
      global_max = v
    }
    di += 1
  }
  // ky = available_height / global_max  (scale factor for values -> pixels)
  let bbox = single.bbox
  let orthogonal_total = if single.orient == "horizontal" {
    bbox.height
  } else {
    bbox.width
  }
  let gap_start = theme_river_parse_gap_px(series, 0, orthogonal_total)
  let gap_end = theme_river_parse_gap_px(series, 1, orthogonal_total)
  let avail = if single.orient == "horizontal" {
    bbox.height - gap_start - gap_end
  } else {
    bbox.width - gap_start - gap_end
  }
  let ky = if global_max <= 0.0 { 1.0 } else { avail / global_max }
  // Determine group origin (top-left of the drawing area including baseline)
  // In ThemeRiverView: group.y = rect.y + boundaryGap[0]
  let group_origin_x = bbox.x
  let group_origin_y = bbox.y + gap_start
  // Build layers with computed layout items
  let layers : Array[TRLayer] = []
  li = 0
  while li < n_layers {
    let color = @visual.palette_color(palette_offset + li)
    let items : Array[TRLayerItem] = []
    let mut running_y0 = 0.0
    di = 0
    while di < point_count {
      let base_y0 = baseline[di] * ky
      // For layer 0: y0 = base_y0
      // For layer li: y0 = base_y0 + sum of previous layers
      // Recompute per the iterative structure in themeRiverLayout.ts
      running_y0 = if li == 0 {
        base_y0
      } else {
        // sum previous layers
        let mut accum = base_y0
        let mut prev = 0
        while prev < li {
          accum += values[prev][di] * ky
          prev += 1
        }
        accum
      }
      let scaled_y = values[li][di] * ky
      let time_str = grouped[li].data_list[di].time
      items.push({
        x: if single.orient == "horizontal" {
          single.data_to_pixel(time_str)
        } else {
          group_origin_x + running_y0
        },
        y0: if single.orient == "horizontal" {
          group_origin_y + running_y0
        } else {
          single.data_to_pixel(time_str)
        },
        y: scaled_y,
      })
      di += 1
    }
    layers.push({ name: grouped[li].name, color, items })
    li += 1
  }
  layers
}

///|
fn theme_river_group_rows_by_name(
  rows : Array[TRDataRow],
) -> Array[TRLayerData] {
  let grouped : Array[TRLayerData] = []

  for i, _ in rows {
    let row = rows[i]
    let mut found = -1

    for j, _ in grouped {
      if grouped[j].name == row.name {
        found = j
        break
      }
    }
    if found == -1 {
      grouped.push({ name: row.name, data_list: [row] })
    } else {
      grouped[found].data_list.push(row)
    }
  }
  grouped
}

///|
/// Corresponds to ThemeRiverSeries.fixData(): fill missing time keys with 0 per layer.
fn theme_river_fix_rows(series : @option.SeriesOption) -> Array[TRDataRow] {
  let filtered : Array[TRDataRow] = []
  let mut i = 0
  for i, _ in series.data {
    let item = series.data[i]
    match (item.value, item.name) {
      (@option.DataValue::DateValue(time, value), Some(name)) =>
        filtered.push({ time, value, name })
      _ => ()
    }
  }
  let time_keys : Array[String] = []
  i = 0
  while i < filtered.length() {
    let time = filtered[i].time
    if !time_keys.contains(time) {
      time_keys.push(time)
    }
    i += 1
  }
  let layers = theme_river_group_rows_by_name(filtered)
  let mut k = 0
  for k, _ in layers {
    let layer_name = layers[k].name

    for time in time_keys {
      if !theme_river_layer_has_time(layers[k], time) {
        layers[k].data_list.push({ time, value: 0.0, name: layer_name })
      }
    }
  }
  let result : Array[TRDataRow] = []
  k = 0
  while k < layers.length() {
    for j, _ in layers[k].data_list {
      result.push(layers[k].data_list[j])
    }
    k += 1
  }
  result
}

///|
fn theme_river_layer_has_time(layer : TRLayerData, time : String) -> Bool {
  for i, _ in layer.data_list {
    if layer.data_list[i].time == time {
      return true
    }
  }
  false
}

///|
/// Corresponds to ThemeRiverSeries.getLayerSeries() time sort.
fn theme_river_sort_layer_by_time(
  layer : TRLayerData,
  single : @coord.Single,
) -> Unit {
  let mut i = 1
  while i < layer.data_list.length() {
    let key = layer.data_list[i]
    let key_val = single.value_num(key.time)
    let mut j = i - 1
    while j >= 0 && single.value_num(layer.data_list[j].time) > key_val {
      layer.data_list[j + 1] = layer.data_list[j]
      j -= 1
    }
    layer.data_list[j + 1] = key
    i += 1
  }
}

///|
fn theme_river_common_point_count(grouped : Array[TRLayerData]) -> Int {
  if grouped.length() == 0 {
    return 0
  }
  let mut min_len = grouped[0].data_list.length()
  let mut i = 1
  while i < grouped.length() {
    if grouped[i].data_list.length() < min_len {
      min_len = grouped[i].data_list.length()
    }
    i += 1
  }
  min_len
}

///|
fn theme_river_parse_gap_px(
  series : @option.SeriesOption,
  index : Int,
  total : Double,
) -> Double {
  let fallback = if index == 0 || index == 1 { "10%" } else { "0" }
  let raw = if index < series.boundary_gap.length() {
    series.boundary_gap[index]
  } else {
    fallback
  }
  if raw.has_suffix("%") {
    let pct_str = raw[:raw.length() - 1].to_string()
    let parsed = try? @string.parse_double(pct_str)
    match parsed {
      Ok(pct) => total * pct / 100.0
      Err(_) => 0.0
    }
  } else {
    let parsed = try? @string.parse_double(raw)
    match parsed {
      Ok(px) => px
      Err(_) => 0.0
    }
  }
}

///|
/// Build a smooth cubic bezier SVG path through an array of (x, y) points.
/// Corresponds to: ECPolygon smooth=0.4 in ThemeRiverView.ts
/// Uses catmull-rom to bezier conversion with smooth factor = 0.4.
fn smooth_path(points : Array[(Double, Double)], smooth : Double) -> String {
  let n = points.length()
  if n == 0 {
    return ""
  }
  if n == 1 {
    return "M \{points[0].0} \{points[0].1}"
  }
  if n == 2 {
    return "M \{points[0].0} \{points[0].1} L \{points[1].0} \{points[1].1}"
  }
  // Helper to get point with boundary clamping
  fn get_point(i : Int) -> (Double, Double) {
    if i < 0 {
      points[0]
    } else if i >= n {
      points[n - 1]
    } else {
      points[i]
    }
  }
  let buf = StringBuilder::new()
  buf.write_string("M \{points[0].0} \{points[0].1}")
  let mut i = 0
  while i < n - 1 {
    let p0 = get_point(i - 1)
    let p1 = get_point(i)
    let p2 = get_point(i + 1)
    let p3 = get_point(i + 2)
    // CP1: P1 + smooth * (P2 - P0) / 2
    let cp1x = p1.0 + smooth * (p2.0 - p0.0) / 2.0
    let cp1y = p1.1 + smooth * (p2.1 - p0.1) / 2.0
    // CP2: P2 - smooth * (P3 - P1) / 2
    let cp2x = p2.0 - smooth * (p3.0 - p1.0) / 2.0
    let cp2y = p2.1 - smooth * (p3.1 - p1.1) / 2.0
    buf.write_string(" C \{cp1x} \{cp1y} \{cp2x} \{cp2y} \{p2.0} \{p2.1}")
    i += 1
  }
  buf.to_string()
}

///|
/// Build the closed area path for one ThemeRiver layer.
/// Upper contour goes left→right, lower (reversed) contour goes right→left.
/// Corresponds to: ECPolygon with points/stackedOnPoints in ThemeRiverView.ts
fn theme_river_layer_path(layer : TRLayer) -> String {
  let n = layer.items.length()
  if n == 0 {
    return ""
  }
  let smooth = 0.4
  // lower edge: (x, y0) — forward left to right
  let lo_pts : Array[(Double, Double)] = []
  // upper edge: (x, y0 + y) — forward left to right (reversed for path)
  let hi_pts : Array[(Double, Double)] = []
  let mut i = 0
  while i < n {
    let item = layer.items[i]
    lo_pts.push((item.x, item.y0))
    hi_pts.push((item.x, item.y0 + item.y))
    i += 1
  }
  // Build path: smooth curve along hi (top of band), then reverse smooth along lo
  // Start at lo[0], curve to lo[n-1], then curve back to hi[n-1]..hi[0], close
  // ECharts uses stackedOnPoints for the "below" edge — let's use lo_pts as below (y0)
  // and hi_pts as above (y0 + y).
  // Path: M lo[0] → smooth curve through lo points → L hi[n-1] → smooth curve back → Z
  let lo_path = smooth_path(lo_pts, smooth)
  // Reverse hi_pts for the return segment
  let hi_rev : Array[(Double, Double)] = []
  i = n - 1
  while i >= 0 {
    hi_rev.push(hi_pts[i])
    i -= 1
  }
  let hi_rev_path = smooth_path(hi_rev, smooth)
  // Replace the "M x y" in the hi_rev_path with "L x y" to continue the path
  let hi_segment = if hi_rev_path.has_prefix("M ") {
    "L " + hi_rev_path[2:].to_string()
  } else {
    hi_rev_path
  }
  "\{lo_path} \{hi_segment} Z"
}

///|
/// Compute the label position for a layer: first x, midpoint y.
/// Corresponds to: ThemeRiverView.ts labelEl.x = textLayout.x - margin
/// where textLayout is from indices[0] (first data point of the layer).
fn theme_river_label_pos(layer : TRLayer) -> (Double, Double)? {
  let n = layer.items.length()
  if n == 0 {
    return None
  }
  // Use first point, with margin offset (default margin = 4)
  let margin = 4.0
  let item = layer.items[0]
  Some((item.x - margin, item.y0 + item.y / 2.0))
}

///|
/// Render all themeRiver series.
pub fn render_theme_rivers(
  opt : @option.ChartOption,
  single_opt : @coord.Single?,
) -> Array[@graphic.Element] {
  let single = match single_opt {
    Some(s) => s
    None => return []
  }
  let elems : Array[@graphic.Element] = []

  let mut color_offset = 0
  for si, _ in opt.series {
    let series = opt.series[si]
    match series.series_type {
      ThemeRiver => ()
      _ => {
        color_offset += 1
        continue
      }
    }
    let layers = theme_river_get_layers(series, single, color_offset)
    // Render each layer as a filled polygon

    for li, _ in layers {
      let layer = layers[li]
      let path_data = theme_river_layer_path(layer)
      if path_data == "" {
        continue
      }
      elems.push(
        @graphic.Element::path_fill_stroke(
          path_data,
          layer.color,
          layer.color,
          0.5,
          1.0,
        ),
      )
      // Render stream label at leftmost point with margin
      match theme_river_label_pos(layer) {
        Some((lx, ly)) =>
          elems.push(
            @graphic.Element::text_colored(
              lx,
              ly,
              layer.name,
              @graphic.TextAnchor::Start,
              @graphic.TextBaseline::Middle,
              "#333",
            ),
          )
        None => ()
      }
    }
    color_offset += layers.length()
  }
  elems
}

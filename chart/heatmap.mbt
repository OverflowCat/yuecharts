// Corresponds to: echarts/src/chart/heatmap/HeatmapView.ts
//
// Cartesian heatmap: data format per item is Vec([x_index, y_index, value])
// where x_index and y_index are 0-based integer indices into the x/y categories.
// Color is driven by the `visualMap` option.
//
// ECharts default visualMap gradient (when no inRange.color is specified):
//   [lightThemeColor, themeColor] = [#d4dcf7, #5070dd]
//   lightThemeColor = modifyHSL('#5070dd', null, null, 0.9) ≈ rgb(212,220,247)
//   themeColor = '#5070dd' = rgb(80,112,221)
// See: echarts/src/model/globalDefault.ts  (gradientColor)
//      echarts/src/component/visualMap/VisualMapModel.ts

///|
fn heatmap_visual_map_color(t : Double) -> @graphic.Color {
  let light = @graphic.Color::rgba(212, 220, 247, 255)
  let deep = @graphic.Color::rgba(80, 112, 221, 255)
  @graphic.Color::lerp(light, deep, t)
}

///|
pub fn render_heatmap_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  vm_min : Double,
  vm_max : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let _ = series_index
  let v_span = if vm_max > vm_min { vm_max - vm_min } else { 1.0 }
  let cell_w = if x_idx < coord.x_scales.length() {
    match coord.x_scales[x_idx] {
      Ordinal(s) => {
        let step = s.band_step()
        (if step < 0.0 { -step } else { step }) + 0.5
      }
      Linear(s) => {
        let diff = s.range_max - s.range_min
        (if diff < 0.0 { -diff } else { diff }) / 10.0
      }
    }
  } else {
    10.0
  }
  let cell_h = if y_idx < coord.y_scales.length() {
    match coord.y_scales[y_idx] {
      Ordinal(s) => {
        let step = s.band_step()
        (if step < 0.0 { -step } else { step }) + 0.5
      }
      Linear(s) => {
        let diff = s.range_max - s.range_min
        (if diff < 0.0 { -diff } else { diff }) / 10.0
      }
    }
  } else {
    10.0
  }
  let mut di = 0
  while di < series.data.length() {
    let item = series.data[di]
    di += 1
    match item.value {
      Vec(arr) if arr.length() >= 3 => {
        let xi = arr[0].to_int()
        let yi = arr[1].to_int()
        let v = arr[2]
        let t = (v - vm_min) / v_span
        let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
        let color_str = heatmap_visual_map_color(t_clamped).to_svg()
        let cx = if x_idx < coord.x_scales.length() {
          match coord.x_scales[x_idx] {
            Ordinal(s) => s.band_center(xi)
            Linear(s) => s.data_to_pixel(arr[0])
          }
        } else {
          coord.bbox.x + (xi.to_double() + 0.5) * cell_w
        }
        let cy = if y_idx < coord.y_scales.length() {
          match coord.y_scales[y_idx] {
            Ordinal(s) => s.band_center(yi)
            Linear(s) => s.data_to_pixel(arr[1])
          }
        } else {
          coord.bbox.y + (yi.to_double() + 0.5) * cell_h
        }
        elems.push(
          @graphic.Element::rect_colored(
            cx - cell_w * 0.5,
            cy - cell_h * 0.5,
            cell_w,
            cell_h,
            color_str,
          ),
        )
      }
      _ => ()
    }
  }
  elems
}

///|
fn render_calendar_heatmap_series(
  series : @option.SeriesOption,
  series_index : Int,
  calendar : @coord.Calendar,
  vm_min : Double,
  vm_max : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let _ = series_index
  let v_span = if vm_max > vm_min { vm_max - vm_min } else { 1.0 }
  let mut di = 0
  while di < series.data.length() {
    let item = series.data[di]
    di += 1
    match item.value {
      DateValue(date, v) => {
        let layout = calendar.data_to_layout(date)
        let shape = layout.content_rect
        if shape.x.is_nan() || shape.y.is_nan() {
          ()
        } else {
          let t = (v - vm_min) / v_span
          let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
          elems.push(
            @graphic.Element::rect_colored(
              shape.x,
              shape.y,
              shape.width,
              shape.height,
              heatmap_visual_map_color(t_clamped).to_svg(),
            ),
          )
        }
      }
      _ => ()
    }
  }
  elems
}

///|
fn render_matrix_heatmap_series(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
  series_index : Int,
  matrix : @coord.Matrix,
  vm_min : Double,
  vm_max : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let _ = series_index
  let v_span = if vm_max > vm_min { vm_max - vm_min } else { 1.0 }
  let mut di = 0
  while di < series.data.length() {
    let item = series.data[di]
    di += 1
    match matrix_heatmap_item_layout(item, matrix) {
      Some((shape, v)) =>
        if shape.x.is_nan() || shape.y.is_nan() {
          ()
        } else {
          let t = (v - vm_min) / v_span
          let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
          let (fill, stroke, stroke_width, opacity) = matrix_heatmap_rect_style(
            opt, series_index, item, t_clamped,
          )
          elems.push(
            @graphic.Element::rect_fill_stroke_opacity(
              shape.x,
              shape.y,
              shape.width,
              shape.height,
              fill,
              stroke,
              stroke_width,
              opacity,
            ),
          )
        }
      _ => ()
    }
  }
  elems
}

///|
fn matrix_heatmap_item_layout(
  item : @option.DataItem,
  matrix : @coord.Matrix,
) -> (@graphic.BBox, Double)? {
  match item.raw_value_parts {
    Some(parts) if parts.length() >= 3 => {
      let x = matrix_heatmap_coord_value(parts[0])
      let y = matrix_heatmap_coord_value(parts[1])
      let v = matrix_heatmap_number(parts[2])
      match (x, y, v) {
        (Some(xv), Some(yv), Some(value)) => {
          let xi = match xv {
            @option.Locator(idx) => Some(idx)
            _ => matrix.resolve_x(xv)
          }
          let yi = match yv {
            @option.Locator(idx) => Some(idx)
            _ => matrix.resolve_y(yv)
          }
          match (xi, yi) {
            (Some(xi), Some(yi)) => {
              let layout = matrix.data_to_layout(xi, yi)
              Some((layout.rect, value))
            }
            _ => None
          }
        }
        _ => None
      }
    }
    None =>
      match item.value {
        Vec(arr) if arr.length() >= 3 => {
          let layout = matrix.data_to_layout(arr[0].to_int(), arr[1].to_int())
          Some((layout.rect, arr[2]))
        }
        _ => None
      }
    _ => None
  }
}

///|
fn matrix_heatmap_rect_style(
  opt : @option.ChartOption,
  series_index : Int,
  item : @option.DataItem,
  ratio : Double,
) -> (String, String, Double, Double) {
  let mut fill = heatmap_visual_map_color(ratio).to_svg()
  let mut stroke = "none"
  let mut stroke_width = 0.0
  let mut opacity = matrix_heatmap_visual_opacity(opt, series_index, ratio)
  match item.raw_item {
    Some(raw_item) =>
      match heatmap_j_field(raw_item, "itemStyle") {
        Some(item_style) => {
          match heatmap_j_string_opt(item_style, "color") {
            Some(color) => fill = color
            None =>
              match heatmap_j_field(item_style, "decal") {
                Some(decal) =>
                  match heatmap_j_string_opt(decal, "backgroundColor") {
                    Some(color) => fill = color
                    None =>
                      match heatmap_j_string_opt(decal, "color") {
                        Some(color) => fill = color
                        None => ()
                      }
                  }
                None => ()
              }
          }
          match heatmap_j_string_opt(item_style, "borderColor") {
            Some(color) => stroke = color
            None => ()
          }
          match heatmap_j_number_opt(item_style, "borderWidth") {
            Some(width) => stroke_width = width
            None => ()
          }
          match heatmap_j_number_opt(item_style, "opacity") {
            Some(item_opacity) => opacity *= item_opacity
            None => ()
          }
        }
        None => ()
      }
    None => ()
  }
  (fill, stroke, stroke_width, opacity)
}

///|
fn matrix_heatmap_visual_opacity(
  opt : @option.ChartOption,
  series_index : Int,
  ratio : Double,
) -> Double {
  let mut i = 0
  while i < opt.visual_map.length() {
    let visual_map = opt.visual_map[i]
    i += 1
    if visual_map.series_index != None &&
      visual_map.series_index != Some(series_index) {
      continue
    }
    if visual_map.in_range.opacity.length() >= 2 {
      let min_opacity = visual_map.in_range.opacity[0]
      let max_opacity = visual_map.in_range.opacity[1]
      return min_opacity + (max_opacity - min_opacity) * ratio
    }
  }
  1.0
}

///|
fn heatmap_j_field(j : Json, key : String) -> Json? {
  match j {
    Object(m) => m.get(key)
    _ => None
  }
}

///|
fn heatmap_j_string_opt(j : Json, key : String) -> String? {
  match heatmap_j_field(j, key) {
    Some(String(s)) => Some(s)
    Some(Number(n, ..)) => Some("\{n}")
    _ => None
  }
}

///|
fn heatmap_j_number_opt(j : Json, key : String) -> Double? {
  match heatmap_j_field(j, key) {
    Some(Number(n, ..)) => Some(n)
    _ => None
  }
}

///|
fn matrix_heatmap_coord_value(j : Json) -> @option.MatrixCoordValue? {
  match j {
    String(s) => Some(@option.Name(s))
    Number(n, ..) => Some(@option.Locator(n.to_int()))
    _ => None
  }
}

///|
fn matrix_heatmap_number(j : Json) -> Double? {
  match j {
    Number(n, ..) => Some(n)
    _ => None
  }
}

///|
fn resolve_heatmap_visual_range(opt : @option.ChartOption) -> (Double, Double) {
  if opt.visual_map.length() > 0 {
    let vm = opt.visual_map[0]
    return (vm.min, vm.max)
  }
  let mut first = true
  let mut dmin = 0.0
  let mut dmax = 0.0
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si += 1
    if @option.Heatmap != series.series_type {
      continue
    }
    for item in series.data {
      match item.value {
        Vec(arr) if arr.length() >= 3 => {
          let v = arr[2]
          if first {
            dmin = v
            dmax = v
            first = false
          } else {
            if v < dmin {
              dmin = v
            }
            if v > dmax {
              dmax = v
            }
          }
        }
        DateValue(_, v) =>
          if first {
            dmin = v
            dmax = v
            first = false
          } else {
            if v < dmin {
              dmin = v
            }
            if v > dmax {
              dmax = v
            }
          }
        _ => ()
      }
    }
  }
  if first {
    (0.0, 1.0)
  } else {
    (dmin, dmax)
  }
}

///|
pub fn render_heatmaps(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  calendar? : @coord.Calendar,
  matrix? : @coord.Matrix,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let (vm_min, vm_max) = resolve_heatmap_visual_range(opt)
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si += 1
    if @option.Heatmap != series.series_type {
      continue
    }
    let series_elems = if series.coordinate_system == Some("calendar") {
      match calendar {
        Some(calendar) =>
          render_calendar_heatmap_series(
            series,
            si - 1,
            calendar,
            vm_min,
            vm_max,
          )
        None => []
      }
    } else if series.coordinate_system == Some("matrix") {
      match matrix {
        Some(matrix) =>
          render_matrix_heatmap_series(
            opt,
            series,
            si - 1,
            matrix,
            vm_min,
            vm_max,
          )
        None => []
      }
    } else {
      render_heatmap_series(series, si - 1, coord, vm_min, vm_max)
    }
    elems.append(series_elems)
  }
  elems
}

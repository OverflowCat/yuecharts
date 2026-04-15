/// <=> echarts/src/chart/heatmap/HeatmapView.ts
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
/// Default ECharts gradientColor stops (light → deep blue).
/// Corresponds to: echarts/src/model/globalDefault.ts gradientColor
fn heatmap_default_gradient_colors() -> Array[String] {
  ["#d4dcf7", "#5070dd"]
}

///|
/// Reverse a color stop array to match `visualMap.color` compatibility.
/// Corresponds to: echarts/src/component/visualMap/VisualMapModel.ts completeSingle()
fn heatmap_reverse_colors(colors : Array[String]) -> Array[String] {
  let result : Array[String] = []
  let mut i = colors.length()
  while i > 0 {
    i -= 1
    result.push(colors[i])
  }
  result
}

///|
/// Clamp t to [0, 1].
fn heatmap_clamp01(t : Double) -> Double {
  if t < 0.0 {
    0.0
  } else if t > 1.0 {
    1.0
  } else {
    t
  }
}

///|
/// Resolve the active in-range colors for heatmap series rendering.
/// Corresponds to: echarts/src/component/visualMap/VisualMapModel.ts completeVisualOption()
fn heatmap_vm_in_range_colors(vm : @option.VisualMapOption?) -> Array[String] {
  match vm {
    None => heatmap_default_gradient_colors()
    Some(vm_opt) =>
      if vm_opt.in_range.color.length() > 0 {
        vm_opt.in_range.color
      } else if vm_opt.color.length() > 0 {
        heatmap_reverse_colors(vm_opt.color)
      } else {
        heatmap_default_gradient_colors()
      }
  }
}

///|
/// Resolve the inactive color used for out-of-range heatmap values.
/// Corresponds to: echarts/src/component/visualMap/VisualMapModel.ts completeInactive()
fn heatmap_vm_out_of_range_color(vm : @option.VisualMapOption?) -> String {
  match vm {
    Some(vm_opt) =>
      match vm_opt.out_of_range {
        Some(out_range) if out_range.color.length() > 0 => out_range.color[0]
        _ => "none"
      }
    None => "none"
  }
}

///|
/// Interpolate along a multi-stop color array at ratio t ∈ [0,1].
/// Corresponds to: VisualMapping.mapVisual for 'color' in echarts/src/visual/VisualMapping.ts
fn heatmap_color_at_ratio(colors : Array[String], ratio : Double) -> String {
  if colors.length() == 0 {
    return @graphic.Color::rgba(212, 220, 247, 255).to_svg()
  }
  if colors.length() == 1 {
    return colors[0]
  }
  let t = heatmap_clamp01(ratio)
  let total = colors.length() - 1
  let scaled = t * total.to_double()
  let idx = scaled.floor().to_int()
  let next = if idx + 1 < colors.length() { idx + 1 } else { idx }
  let local_t = scaled - idx.to_double()
  let c0 = @graphic.Color::from_string(colors[idx]).unwrap_or(@graphic.black)
  let c1 = @graphic.Color::from_string(colors[next]).unwrap_or(c0)
  @graphic.Color::lerp(c0, c1, local_t).to_svg()
}

///|
/// Find the visualMap that targets a specific series_index (or any series if None).
/// Corresponds to: HeatmapView.ts ecModel.eachComponent('visualMap', ...) binding loop.
fn heatmap_find_vm(
  opt : @option.ChartOption,
  series_index : Int,
) -> @option.VisualMapOption? {
  let mut matched : @option.VisualMapOption? = None
  let mut i = 0
  while i < opt.visual_map.length() {
    let vm = opt.visual_map[i]
    i += 1
    match vm.series_index {
      None => matched = Some(vm)
      Some(si) if si == series_index => matched = Some(vm)
      _ => ()
    }
  }
  matched
}

///|
/// Mirror PiecewiseModel's selected-state lookup for static heatmap coloring.
/// Corresponds to: echarts/src/component/visualMap/PiecewiseModel.ts getValueState()
fn heatmap_vm_piece_selected(
  vm : @option.VisualMapOption,
  key : String,
) -> Bool {
  let mut i = 0
  while i < vm.selected.length() {
    let sel = vm.selected[i]
    if sel.key == key {
      return sel.selected
    }
    i += 1
  }
  true
}

///|
/// Resolve color string for value v in [vm_min, vm_max] using visualMap option.
/// Supports continuous (in_range.color stops) and piecewise (pieces[].color / selected).
/// Corresponds to: HeatmapView.ts _renderOnGridLike data.getItemVisual(idx,'style').fill
fn heatmap_vm_color_for_value(
  vm : @option.VisualMapOption?,
  v : Double,
  vm_min : Double,
  vm_max : Double,
) -> String {
  let v_span = if vm_max > vm_min { vm_max - vm_min } else { 1.0 }
  let ratio = heatmap_clamp01((v - vm_min) / v_span)
  match vm {
    None => heatmap_color_at_ratio(heatmap_default_gradient_colors(), ratio)
    Some(vm_opt) =>
      // Piecewise: match value to a piece interval and respect selected state.
      if vm_opt.pieces.length() > 0 {
        let mut pi = 0
        while pi < vm_opt.pieces.length() {
          let piece = vm_opt.pieces[pi]
          pi += 1
          let lo = match (piece.gte, piece.gt, piece.min) {
            (Some(n), _, _) => n
            (_, Some(n), _) => n + 1.0e-300 // exclusive lower bound
            (_, _, Some(n)) => n
            _ => vm_min
          }
          let hi = match (piece.lte, piece.lt, piece.max) {
            (Some(n), _, _) => n
            (_, Some(n), _) => n - 1.0e-300 // exclusive upper bound
            (_, _, Some(n)) => n
            _ => vm_max
          }
          if v >= lo && v <= hi {
            let piece_index = pi - 1
            let color = heatmap_vm_out_of_range_color(vm)
            if !heatmap_vm_piece_selected(vm_opt, piece_index.to_string()) {
              return color
            }
            match piece.color {
              Some(c) if c != "" => return c
              _ =>
                return heatmap_color_at_ratio(
                  heatmap_vm_in_range_colors(vm),
                  ratio,
                )
            }
          }
        }
        heatmap_vm_out_of_range_color(vm)
      } else if v < vm_min || v > vm_max {
        heatmap_vm_out_of_range_color(vm)
      } else {
        heatmap_color_at_ratio(heatmap_vm_in_range_colors(vm), ratio)
      }
  }
}

///|
pub fn render_heatmap_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  vm_min : Double,
  vm_max : Double,
  vm_opt? : @option.VisualMapOption? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let _ = series_index
  let _v_span = if vm_max > vm_min { vm_max - vm_min } else { 1.0 }
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
      BreakLinear(s) => {
        let diff = s.inner.range_max - s.inner.range_min
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
        let color_str = heatmap_vm_color_for_value(vm_opt, v, vm_min, vm_max)
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
            BreakLinear(s) => s.data_to_pixel(arr[1]) // ?
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
  vm_opt : @option.VisualMapOption?,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let _ = series_index
  let _v_span = if vm_max > vm_min { vm_max - vm_min } else { 1.0 }
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
          elems.push(
            @graphic.Element::rect_colored(
              shape.x,
              shape.y,
              shape.width,
              shape.height,
              heatmap_vm_color_for_value(vm_opt, v, vm_min, vm_max),
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
  vm_opt : @option.VisualMapOption?,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let _ = series_index
  let v_span = if vm_max > vm_min { vm_max - vm_min } else { 1.0 }
  let _ = v_span
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
            opt, series_index, item, t_clamped, vm_opt, vm_min, vm_max,
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
  vm_opt : @option.VisualMapOption?,
  vm_min : Double,
  vm_max : Double,
) -> (String, String, Double, Double) {
  let v = vm_min + ratio * (vm_max - vm_min)
  let mut fill = heatmap_vm_color_for_value(vm_opt, v, vm_min, vm_max)
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
  let mut opacity = 1.0
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
      opacity = min_opacity + (max_opacity - min_opacity) * ratio
    } else {
      opacity = 1.0
    }
  }
  opacity
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
/// Resolve per-series vm_min/vm_max from the matched visualMap (or data extent).
/// Corresponds to: HeatmapView.ts visualMapOfThisSeries binding.
fn heatmap_resolve_vm_range(
  opt : @option.ChartOption,
  series_index : Int,
  series : @option.SeriesOption,
) -> (Double, Double) {
  match heatmap_find_vm(opt, series_index) {
    Some(vm) => (vm.min, vm.max)
    None => {
      // Fallback: infer from data
      let mut first = true
      let mut dmin = 0.0
      let mut dmax = 0.0
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
      if first {
        (0.0, 1.0)
      } else {
        (dmin, dmax)
      }
    }
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
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si += 1
    if @option.Heatmap != series.series_type {
      continue
    }
    let series_idx = si - 1
    let vm_opt = heatmap_find_vm(opt, series_idx)
    let (vm_min, vm_max) = heatmap_resolve_vm_range(opt, series_idx, series)
    let series_elems = if series.coordinate_system == Some("calendar") {
      match calendar {
        Some(calendar) =>
          render_calendar_heatmap_series(
            series, series_idx, calendar, vm_min, vm_max, vm_opt,
          )
        None => []
      }
    } else if series.coordinate_system == Some("matrix") {
      match matrix {
        Some(matrix) =>
          render_matrix_heatmap_series(
            opt, series, series_idx, matrix, vm_min, vm_max, vm_opt,
          )
        None => []
      }
    } else {
      render_heatmap_series(series, series_idx, coord, vm_min, vm_max, vm_opt~)
    }
    elems.append(series_elems)
  }
  elems
}

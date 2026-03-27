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
    } else {
      render_heatmap_series(series, si - 1, coord, vm_min, vm_max)
    }
    elems.append(series_elems)
  }
  elems
}
